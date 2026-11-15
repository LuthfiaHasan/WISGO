package pungli

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/scenes360"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/spatial"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()

	destRepo := destination.NewRepository()
	scenesRepo := scenes360.NewRepository()
	spatialRepo := spatial.NewRepository()
	repo := NewRepository()

	service := NewService(repo, destRepo, scenesRepo, spatialRepo)
	rateLimiter := middleware.NewTokenBucketRateLimiter(60, 60*time.Second)
	handler := NewHandler(service, rateLimiter)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r
}

func TestPungliSuite(t *testing.T) {
	r := setupTestRouter()

	t.Run("TC-S5-01: GET /api/v1/qr/:qrCode meresolusi Plang Smart QR ke destinasi + Fair-Price + 360", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/qr/QR-SMBR-LPK-001", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res SmartQRResolutionResponse
		if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to parse JSON: %v", err)
		}
		if res.QRPlacardCode != "QR-SMBR-LPK-001" {
			t.Fatalf("expected QR-SMBR-LPK-001, got %s", res.QRPlacardCode)
		}
		if !res.FairPriceVerified {
			t.Fatal("expected fair_price_verified=true")
		}
		if len(res.Scenes360) == 0 {
			t.Fatal("expected scenes_360 to be returned")
		}
		if res.MicroMap.ID == "" {
			t.Fatal("expected non-empty micro_map")
		}
	})

	t.Run("TC-S5-02: GET /api/v1/qr/:qrCode kode tidak ditemukan (404 Not Found)", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/qr/QR-INVALID-999", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("expected 404 Not Found, got %d", rec.Code)
		}
	})

	t.Run("TC-S5-03: POST /api/v1/pungli/report mencatat bukti foto + GPS & menghitung selisih terhadap Perda", func(t *testing.T) {
		payload := []byte(`{
			"destination_id": "dest-001",
			"reporter_name": "Wisatawan Anonim",
			"incident_category": "parkir_liar",
			"charged_amount_idr": 20000,
			"photo_evidence": "https://cdn.rancak.in/evidence/parkir-20rb.jpg",
			"latitude": -0.1023,
			"longitude": 100.6728,
			"description": "Diminta parkir mobil Rp20.000 padahal Perda Rp5.000"
		}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/pungli/report", bytes.NewBuffer(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created on pungli report, got %d: %s", rec.Code, rec.Body.String())
		}

		var res CreatePungliReportResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Status != "success" {
			t.Fatalf("expected status=success, got %s", res.Status)
		}
		if res.Report.OverchargeAmountIDR <= 0 {
			t.Fatalf("expected positive overcharge amount, got %v", res.Report.OverchargeAmountIDR)
		}
	})

	t.Run("TC-S5-04: Rate-Limiter HTTP 429 pada Lapor Pungli saat Burst Spam", func(t *testing.T) {
		body := []byte(`{"destination_id":"dest-001","incident_category":"parkir_liar","charged_amount_idr":25000}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/pungli/report", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Simulate-RateLimit", "burst")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusTooManyRequests {
			t.Fatalf("expected 429 Too Many Requests, got %d", rec.Code)
		}
	})

	t.Run("TC-S5-05: GET /api/v1/admin/pungli/reports proteksi RBAC JWT", func(t *testing.T) {
		// 401 tanpa token
		reqAnon := httptest.NewRequest(http.MethodGet, "/api/v1/admin/pungli/reports", nil)
		recAnon := httptest.NewRecorder()
		r.ServeHTTP(recAnon, reqAnon)
		if recAnon.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", recAnon.Code)
		}

		// 403 role tourist
		reqTourist := httptest.NewRequest(http.MethodGet, "/api/v1/admin/pungli/reports", nil)
		reqTourist.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		recTourist := httptest.NewRecorder()
		r.ServeHTTP(recTourist, reqTourist)
		if recTourist.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden, got %d", recTourist.Code)
		}

		// 200 OK Admin Dispar
		reqAdmin := httptest.NewRequest(http.MethodGet, "/api/v1/admin/pungli/reports", nil)
		reqAdmin.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		recAdmin := httptest.NewRecorder()
		r.ServeHTTP(recAdmin, reqAdmin)
		if recAdmin.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", recAdmin.Code)
		}
	})

	t.Run("TC-S5-06: PATCH /api/v1/admin/pungli/:id/status mengubah status tiket di Pusat Komando Satgas", func(t *testing.T) {
		payload := []byte(`{"status":"Ditindaklanjuti","satgas_notes":"Petugas Dishub & Satpol PP telah menertibkan oknum di lokasi."}`)
		req := httptest.NewRequest(http.MethodPatch, "/api/v1/admin/pungli/PGL-202611-0091/status", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on Satgas status update, got %d: %s", rec.Code, rec.Body.String())
		}

		var res UpdatePungliStatusResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Report.Status != "Ditindaklanjuti" {
			t.Fatalf("expected status=Ditindaklanjuti, got %s", res.Report.Status)
		}
	})

	t.Run("TC-S5-07: PUT /api/v1/admin/pungli/:id/status backward compatibility", func(t *testing.T) {
		payload := []byte(`{"status":"Selesai","satgas_notes":"Penertiban selesai."}`)
		req := httptest.NewRequest(http.MethodPut, "/api/v1/admin/pungli/PGL-202611-0091/status", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on PUT Satgas status update, got %d", rec.Code)
		}
	})

	t.Run("TC-S5-08: PATCH pada tiket tidak dikenal mengembalikan 404 Not Found", func(t *testing.T) {
		payload := []byte(`{"status":"Selesai"}`)
		req := httptest.NewRequest(http.MethodPatch, "/api/v1/admin/pungli/NONEXISTENT-999/status", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("expected 404 Not Found, got %d", rec.Code)
		}
	})
}
