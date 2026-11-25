package gamification

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
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

func TestGPSCheckIn_AntiFakeGPS_ValidAndInvalid(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Valid Check-In: Wisatawan berada di Jam Gadang Bukittinggi (radius ~15 meter)
	// Jam Gadang resmi: -0.3051, 100.3695
	validBody, _ := json.Marshal(CheckInRequest{
		UserID:        "usr-001",
		DestinationID: "spot-jam-gadang",
		Latitude:      -0.3052,
		Longitude:     100.3696,
	})
	reqValid := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(validBody))
	reqValid.Header.Set("Content-Type", "application/json")
	wValid := httptest.NewRecorder()
	r.ServeHTTP(wValid, reqValid)

	if wValid.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for valid GPS check-in, got %d. Body: %s", wValid.Code, wValid.Body.String())
	}

	var respValid common.ResponseStandar
	_ = json.Unmarshal(wValid.Body.Bytes(), &respValid)
	checkInData := respValid.Data.(map[string]interface{})
	if checkInData["is_within_radius"].(bool) != true {
		t.Fatalf("Expected is_within_radius=true")
	}
	if checkInData["badge_earned"].(string) != "Lencana Penjaga Waktu Minang" {
		t.Fatalf("Expected badge 'Lencana Penjaga Waktu Minang', got %v", checkInData["badge_earned"])
	}

	// 2. Fake GPS Check-In: Lokasi di Padang (-0.9634, 100.3547) mencoba check-in di Jam Gadang (~70km)
	fakeBody, _ := json.Marshal(CheckInRequest{
		UserID:        "usr-001",
		DestinationID: "spot-jam-gadang",
		Latitude:      -0.9634,
		Longitude:     100.3547,
	})
	reqFake := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(fakeBody))
	reqFake.Header.Set("Content-Type", "application/json")
	wFake := httptest.NewRecorder()
	r.ServeHTTP(wFake, reqFake)

	if wFake.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request for fake GPS check-in > 200m, got %d", wFake.Code)
	}

	var respFake common.ResponseStandar
	_ = json.Unmarshal(wFake.Body.Bytes(), &respFake)
	if !strings.Contains(respFake.Message, "Anti-Fake GPS") {
		t.Fatalf("Expected error message to mention Anti-Fake GPS, got: %s", respFake.Message)
	}
}

func TestDigitalPassport_ProgressAndSummary(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Check-in ke spot Jam Gadang
	c1, _ := json.Marshal(CheckInRequest{
		UserID:        "usr-001",
		DestinationID: "spot-jam-gadang",
		Latitude:      -0.3051,
		Longitude:     100.3695,
	})
	req1 := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(c1))
	req1.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(httptest.NewRecorder(), req1)

	// 2. Ambil paspor digital
	getReq := httptest.NewRequest(http.MethodGet, "/api/v1/gamification/passport?user_id=usr-001", nil)
	getW := httptest.NewRecorder()
	r.ServeHTTP(getW, getReq)

	if getW.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on GetDigitalPassport, got %d", getW.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(getW.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	if int(data["total_stamps"].(float64)) != 1 {
		t.Fatalf("Expected total_stamps=1, got %v", data["total_stamps"])
	}
	if int(data["required_stamps"].(float64)) != 10 {
		t.Fatalf("Expected required_stamps=10, got %v", data["required_stamps"])
	}
	if data["completion_percentage"].(float64) != 10.0 {
		t.Fatalf("Expected 10.0%% completion, got %v", data["completion_percentage"])
	}
}

func TestGovernorCertificate_RequirementAndIssuance(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Permintaan sertifikat sebelum 10 titik terpenuhi (harus ditolak 400 Bad Request)
	certReqPremature, _ := json.Marshal(CertificateRequest{
		UserID:   "usr-001",
		FullName: "Rahmat Hidayat",
	})
	reqPremature := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/certificate", bytes.NewReader(certReqPremature))
	reqPremature.Header.Set("Content-Type", "application/json")
	wPremature := httptest.NewRecorder()
	r.ServeHTTP(wPremature, reqPremature)

	if wPremature.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request when stamps < 10, got %d", wPremature.Code)
	}

	// 2. Check-in ke seluruh 10 titik ikonik Minangkabau
	spots := []struct {
		id  string
		lat float64
		lon float64
	}{
		{"spot-jam-gadang", -0.3051, 100.3695},
		{"spot-pagaruyung", -0.4712, 100.6214},
		{"spot-lembah-harau", -0.1062, 100.6657},
		{"spot-danau-maninjau", -0.2980, 100.1878},
		{"spot-danau-singkarak", -0.6175, 100.5367},
		{"spot-kawasan-mandeh", -1.2186, 100.4192},
		{"spot-ngarai-sianok", -0.3106, 100.3619},
		{"spot-kota-tua-padang", -0.9634, 100.3547},
		{"spot-desa-pariangan", -0.4357, 100.4939},
		{"spot-tambang-ombilin", -0.6806, 100.7767},
	}

	for _, s := range spots {
		b, _ := json.Marshal(CheckInRequest{
			UserID:        "usr-001",
			DestinationID: s.id,
			Latitude:      s.lat,
			Longitude:     s.lon,
		})
		rCheck := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(b))
		rCheck.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, rCheck)
		if w.Code != http.StatusOK {
			t.Fatalf("Failed checkin for %s: %s", s.id, w.Body.String())
		}
	}

	// 3. Klaim sertifikat setelah 10 titik terpenuhi (harus sukses 201 Created)
	certReq, _ := json.Marshal(CertificateRequest{
		UserID:   "usr-001",
		FullName: "Rahmat Hidayat (Wisatawan Teladan)",
	})
	reqCert := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/certificate", bytes.NewReader(certReq))
	reqCert.Header.Set("Content-Type", "application/json")
	wCert := httptest.NewRecorder()
	r.ServeHTTP(wCert, reqCert)

	if wCert.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created for certificate, got %d. Body: %s", wCert.Code, wCert.Body.String())
	}

	var respCert common.ResponseStandar
	_ = json.Unmarshal(wCert.Body.Bytes(), &respCert)
	certData := respCert.Data.(map[string]interface{})
	if !strings.HasPrefix(certData["certificate_id"].(string), "WISGO-GUB-SB") {
		t.Fatalf("Expected certificate_id to start with 'WISGO-GUB-SB', got %v", certData["certificate_id"])
	}
	if int(certData["total_spots_visited"].(float64)) != 10 {
		t.Fatalf("Expected total_spots_visited=10, got %v", certData["total_spots_visited"])
	}

	// 4. Klaim ulang sertifikat: harus mengembalikan sertifikat yang sama (200 OK)
	wCertRepeat := httptest.NewRecorder()
	reqCertRepeat := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/certificate", bytes.NewReader(certReq))
	reqCertRepeat.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wCertRepeat, reqCertRepeat)

	if wCertRepeat.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for repeated certificate request, got %d", wCertRepeat.Code)
	}
}

func TestValidateGPSCheckIn_RejectMissingOrEmptyUserId(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Missing user_id field
	noUserPayload := []byte(`{
		"destination_id": "spot-jam-gadang",
		"latitude": -0.3051,
		"longitude": 100.3695
	}`)
	reqNoUser := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(noUserPayload))
	reqNoUser.Header.Set("Content-Type", "application/json")
	wNoUser := httptest.NewRecorder()
	r.ServeHTTP(wNoUser, reqNoUser)

	if wNoUser.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request for check-in with missing user_id, got %d. Body: %s", wNoUser.Code, wNoUser.Body.String())
	}

	// 2. Whitespace user_id
	emptyUserPayload := []byte(`{
		"user_id": "   ",
		"destination_id": "spot-jam-gadang",
		"latitude": -0.3051,
		"longitude": 100.3695
	}`)
	reqEmptyUser := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(emptyUserPayload))
	reqEmptyUser.Header.Set("Content-Type", "application/json")
	wEmptyUser := httptest.NewRecorder()
	r.ServeHTTP(wEmptyUser, reqEmptyUser)

	if wEmptyUser.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request for check-in with whitespace user_id, got %d. Body: %s", wEmptyUser.Code, wEmptyUser.Body.String())
	}
}

