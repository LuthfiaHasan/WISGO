package auth

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

func setupTestRouter() (*gin.Engine, *Handler) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	repo := NewRepository()
	service := NewService(repo, true) // allow dev bypass in test
	handler := NewHandler(service)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r, handler
}

func TestNormalizePhoneNumber(t *testing.T) {
	cases := []struct {
		input    string
		expected string
		isErr    bool
	}{
		{"0812-7578-953", "628127578953", false},
		{"+62 812 7578 953", "628127578953", false},
		{"6208127578953", "628127578953", false},
		{"00628127578953", "628127578953", false},
		{"8127578953", "628127578953", false},
		{"12345", "", true},
		{"0711123456", "", true}, // bukan 08
	}

	for _, c := range cases {
		out, err := NormalizePhoneNumber(c.input)
		if c.isErr && err == nil {
			t.Errorf("Expected error for input %s, got %s", c.input, out)
		} else if !c.isErr && out != c.expected {
			t.Errorf("Expected %s for input %s, got %s (err: %v)", c.expected, c.input, out, err)
		}
	}
}

func TestRequestOTP_Success(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(OTPRequest{PhoneNumber: "6281299998888"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "success" {
		t.Fatalf("Expected status success, got %s", resp.Status)
	}
}

func TestRequestOTP_InvalidPayload(t *testing.T) {
	r, _ := setupTestRouter()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader([]byte("{}")))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request, got %d", w.Code)
	}
}

func TestVerifyOTP_SuccessAndWrongCode(t *testing.T) {
	r, _ := setupTestRouter()

	phone := "0812-7578-953"

	// 1. Minta OTP
	reqOTP, _ := json.Marshal(OTPRequest{PhoneNumber: phone})
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader(reqOTP)))

	// 2. Verifikasi dengan kode salah (Harus 401)
	wrongVerify, _ := json.Marshal(OTPVerifyRequest{PhoneNumber: phone, OTPCode: "9999"})
	wWrong := httptest.NewRecorder()
	r.ServeHTTP(wWrong, httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(wrongVerify)))

	if wWrong.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401 Unauthorized for wrong OTP, got %d", wWrong.Code)
	}

	// 3. Verifikasi dengan kode master "1234" (Harus 200 OK)
	validVerify, _ := json.Marshal(OTPVerifyRequest{
		PhoneNumber: phone,
		OTPCode:     "1234",
		FullName:    "Ahmad Fauzi (Wisatawan)",
	})
	wValid := httptest.NewRecorder()
	r.ServeHTTP(wValid, httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(validVerify)))

	if wValid.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for valid OTP, got %d. Body: %s", wValid.Code, wValid.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(wValid.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	if data["token"] == "" {
		t.Fatalf("Expected non-empty JWT token")
	}
	user := data["user"].(map[string]interface{})
	if user["full_name"] != "Ahmad Fauzi (Wisatawan)" {
		t.Fatalf("Expected full_name 'Ahmad Fauzi (Wisatawan)', got '%v'", user["full_name"])
	}

	// 4. Test code "2486" (FE prototype code)
	validVerify2, _ := json.Marshal(OTPVerifyRequest{
		PhoneNumber: phone,
		OTPCode:     "2486",
	})
	wValid2 := httptest.NewRecorder()
	r.ServeHTTP(wValid2, httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(validVerify2)))
	if wValid2.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for 2486 dev bypass, got %d", wValid2.Code)
	}
}

func TestOTP_ExpirationAndReplayProtection(t *testing.T) {
	repo := NewRepository()
	service := NewService(repo, true)

	phone := "628127578953"
	// Simpan OTP dengan TTL kedaluwarsa seketika
	_ = repo.SaveOTP(phone, "7777", -1*time.Second)

	_, _, err := service.VerifyOTP(phone, "7777")
	if err == nil {
		t.Fatalf("Expected error for expired OTP")
	}

	// Simpan OTP valid
	_ = repo.SaveOTP(phone, "8888", 300*time.Second)
	user, _, err := service.VerifyOTP(phone, "8888")
	if err != nil || user == nil {
		t.Fatalf("Expected successful verification, got err: %v", err)
	}

	// Verifikasi kedua dengan kode sama harus ditolak (Anti-Replay)
	_, _, err2 := service.VerifyOTP(phone, "8888")
	if err2 == nil {
		t.Fatalf("Expected error on second verification with same OTP (replay attack)")
	}
}

func TestVerifyOTP_WisatawanVsVendorChoices(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Wisatawan Login dengan opsi input wisata
	verifyWisatawan, _ := json.Marshal(OTPVerifyRequest{
		PhoneNumber: "6281299990001",
		OTPCode:     "1234",
		LoginChoice: "wisata",
	})
	wWisatawan := httptest.NewRecorder()
	r.ServeHTTP(wWisatawan, httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(verifyWisatawan)))

	if wWisatawan.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for Wisatawan OTP, got %d", wWisatawan.Code)
	}

	var resWisatawan struct {
		Data AuthResponse `json:"data"`
	}
	_ = json.Unmarshal(wWisatawan.Body.Bytes(), &resWisatawan)
	if resWisatawan.Data.User.Role != "tourist" {
		t.Fatalf("Expected role tourist, got %s", resWisatawan.Data.User.Role)
	}
	if resWisatawan.Data.LoginChoice != "wisata" {
		t.Fatalf("Expected login_choice wisata, got %s", resWisatawan.Data.LoginChoice)
	}

	// 2. Vendor Login dengan opsi input event
	verifyVendor, _ := json.Marshal(OTPVerifyRequest{
		PhoneNumber: "6281299990002",
		OTPCode:     "1234",
		LoginChoice: "event",
	})
	wVendor := httptest.NewRecorder()
	r.ServeHTTP(wVendor, httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(verifyVendor)))

	if wVendor.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for Vendor OTP, got %d", wVendor.Code)
	}

	var resVendor struct {
		Data AuthResponse `json:"data"`
	}
	_ = json.Unmarshal(wVendor.Body.Bytes(), &resVendor)
	if resVendor.Data.User.Role != "vendor" {
		t.Fatalf("Expected role vendor, got %s", resVendor.Data.User.Role)
	}
	if resVendor.Data.LoginChoice != "event" {
		t.Fatalf("Expected login_choice event, got %s", resVendor.Data.LoginChoice)
	}
}

func TestSavedPlaces_GetAndToggle(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Ambil daftar tersimpan awal (harus dapat 1 dari seeder)
	wGet := httptest.NewRecorder()
	r.ServeHTTP(wGet, httptest.NewRequest(http.MethodGet, "/api/v1/users/saved?user_id=usr-001", nil))

	if wGet.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for GetSavedPlaces, got %d", wGet.Code)
	}

	// 2. Toggle simpan tempat baru "dest-02"
	toggleReq, _ := json.Marshal(ToggleSavedRequest{UserID: "usr-001", DestinationID: "dest-02"})
	wToggle := httptest.NewRecorder()
	r.ServeHTTP(wToggle, httptest.NewRequest(http.MethodPost, "/api/v1/users/saved", bytes.NewReader(toggleReq)))

	if wToggle.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for ToggleSavedPlace, got %d", wToggle.Code)
	}

	// 3. Toggle hapus kembali "dest-02"
	wToggle2 := httptest.NewRecorder()
	r.ServeHTTP(wToggle2, httptest.NewRequest(http.MethodPost, "/api/v1/users/saved/dest-02?user_id=usr-001", nil))

	if wToggle2.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for ToggleSavedPlace (Delete), got %d", wToggle2.Code)
	}
}
