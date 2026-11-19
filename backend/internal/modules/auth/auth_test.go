package auth

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

func setupTestRouter() (*gin.Engine, *Handler) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	repo := NewRepository()
	service := NewService(repo)
	handler := NewHandler(service)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r, handler
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

	// 1. Minta OTP
	reqOTP, _ := json.Marshal(OTPRequest{PhoneNumber: "6281234567890"})
	w1 := httptest.NewRecorder()
	r.ServeHTTP(w1, httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader(reqOTP)))

	// 2. Verifikasi dengan kode salah (Harus 401)
	wrongVerify, _ := json.Marshal(OTPVerifyRequest{PhoneNumber: "6281234567890", OTPCode: "9999"})
	wWrong := httptest.NewRecorder()
	r.ServeHTTP(wWrong, httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(wrongVerify)))

	if wWrong.Code != http.StatusUnauthorized {
		t.Fatalf("Expected 401 Unauthorized for wrong OTP, got %d", wWrong.Code)
	}

	// 3. Verifikasi dengan kode master "1234" (Harus 200 OK)
	validVerify, _ := json.Marshal(OTPVerifyRequest{PhoneNumber: "6281234567890", OTPCode: "1234"})
	wValid := httptest.NewRecorder()
	r.ServeHTTP(wValid, httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(validVerify)))

	if wValid.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for valid OTP, got %d", wValid.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(wValid.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	if data["token"] == "" {
		t.Fatalf("Expected non-empty JWT token")
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
		t.Fatalf("Expected 200 OK, got %d", wGet.Code)
	}

	// 2. Tambah favorit baru ("dest-02")
	toggleAdd, _ := json.Marshal(ToggleSavedRequest{UserID: "usr-001", DestinationID: "dest-02"})
	wAdd := httptest.NewRecorder()
	r.ServeHTTP(wAdd, httptest.NewRequest(http.MethodPost, "/api/v1/users/saved", bytes.NewReader(toggleAdd)))

	if wAdd.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for toggle add, got %d", wAdd.Code)
	}

	var respAdd common.ResponseStandar
	_ = json.Unmarshal(wAdd.Body.Bytes(), &respAdd)
	dataAdd := respAdd.Data.(map[string]interface{})
	if dataAdd["is_saved"].(bool) != true {
		t.Fatalf("Expected is_saved=true")
	}

	// 3. Hapus favorit ("dest-02") dengan toggle ulang
	wRemove := httptest.NewRecorder()
	r.ServeHTTP(wRemove, httptest.NewRequest(http.MethodPost, "/api/v1/users/saved", bytes.NewReader(toggleAdd)))

	var respRemove common.ResponseStandar
	_ = json.Unmarshal(wRemove.Body.Bytes(), &respRemove)
	dataRemove := respRemove.Data.(map[string]interface{})
	if dataRemove["is_saved"].(bool) != false {
		t.Fatalf("Expected is_saved=false after removing")
	}
}

