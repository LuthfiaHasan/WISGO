package spatial

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
)

func setupTestRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()

	destRepo := destination.NewRepository()
	repo := NewRepository()
	service := NewService(repo, destRepo)
	rateLimiter := middleware.NewTokenBucketRateLimiter(60, 60*time.Second)
	handler := NewHandler(service, rateLimiter)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r
}

func TestSpatialSuite(t *testing.T) {
	r := setupTestRouter()

	t.Run("TC-S4-01: POST /api/v1/spatial/shunlu memfilter POI searah rute koridor (+X menit detour)", func(t *testing.T) {
		payload := []byte(`{"origin_lat":-0.9471,"origin_lng":100.4172,"destination_lat":-0.3051,"destination_lng":100.3692,"category":"rm_padang","max_detour_min":10}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/shunlu", bytes.NewBuffer(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res ShunluSearchResponse
		if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if len(res.ShunluPOIs) == 0 {
			t.Fatal("expected shunlu POIs along route to be returned")
		}
		if res.DetourTimeMin <= 0 {
			t.Fatalf("expected positive detour minutes, got %d", res.DetourTimeMin)
		}
	})

	t.Run("TC-S4-02: GET /api/v1/destinations/:id/micro-map mengembalikan peta mikro kawasan & walkway GeoJSON", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/dest-001/micro-map", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var body map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("failed to parse JSON: %v", err)
		}
		if body["destination_id"] != "dest-001" {
			t.Fatalf("expected destination_id=dest-001, got %v", body["destination_id"])
		}
		if body["walkway_geojson"] == "" {
			t.Fatal("expected non-empty walkway_geojson")
		}
	})

	t.Run("TC-S4-03: POST /api/v1/spatial/audio-trigger-check memicu narasi otomatis <=15m", func(t *testing.T) {
		payload := []byte(`{"destination_id":"dest-001","user_lat":-0.1025,"user_lng":100.6725}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/audio-trigger-check", bytes.NewBuffer(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res AudioTriggerCheckResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.TriggerStatus != "AUTO_PLAY_ACTIVE" {
			t.Fatalf("expected AUTO_PLAY_ACTIVE within 15m radius, got %s", res.TriggerStatus)
		}
		if res.MatchedCount == 0 {
			t.Fatal("expected at least 1 triggered story")
		}
	})

	t.Run("TC-S4-04: GET /api/v1/spatial/hazards mendeteksi pengguna di zona bahaya Sitinjau Lauik", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/spatial/hazards?lat=-0.9465&lng=100.5180", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res LiveHazardsResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if !res.UserInHazardZone {
			t.Fatal("expected user_in_hazard_zone=true at Sitinjau Lauik coordinates")
		}
		if res.FE1ActiveWarningBanner == nil {
			t.Fatal("expected active warning banner to be populated")
		}
	})

	t.Run("TC-S4-05: POST /api/v1/admin/hazards/trigger RBAC & aktivasi status siaga", func(t *testing.T) {
		payload := []byte(`{
			"corridor_code": "LEMBAH-ANAI",
			"severity": "Siaga",
			"hazard_type": "Debit Air Sungai Batang Anai Naik",
			"weather_status": "Hujan Deras di Hulu Singgalang",
			"message": "SIAGA LEMBAH ANAI: Arus dialihkan via Malalak.",
			"triggered_by_admin": "Command Center FS-1"
		}`)

		// 401 Unauthorized tanpa token
		reqAnon := httptest.NewRequest(http.MethodPost, "/api/v1/admin/hazards/trigger", bytes.NewBuffer(payload))
		recAnon := httptest.NewRecorder()
		r.ServeHTTP(recAnon, reqAnon)
		if recAnon.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", recAnon.Code)
		}

		// 403 Forbidden untuk tourist
		reqTourist := httptest.NewRequest(http.MethodPost, "/api/v1/admin/hazards/trigger", bytes.NewBuffer(payload))
		reqTourist.Header.Set("Authorization", "Bearer "+middleware.TokenTourist)
		recTourist := httptest.NewRecorder()
		r.ServeHTTP(recTourist, reqTourist)
		if recTourist.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden, got %d", recTourist.Code)
		}

		// 200 OK untuk Admin Dispar
		reqAdmin := httptest.NewRequest(http.MethodPost, "/api/v1/admin/hazards/trigger", bytes.NewBuffer(payload))
		reqAdmin.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		reqAdmin.Header.Set("Content-Type", "application/json")
		recAdmin := httptest.NewRecorder()
		r.ServeHTTP(recAdmin, reqAdmin)
		if recAdmin.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", recAdmin.Code, recAdmin.Body.String())
		}
	})

	t.Run("TC-S4-06: POST /api/v1/spatial/sos memancarkan sinyal darurat SOS GPS", func(t *testing.T) {
		payload := []byte(`{
			"tourist_name": "Uda Fauzan & Keluarga",
			"phone_number": "+62811665544",
			"emergency_type": "Kendaraan Mogok di Tanjakan Curam",
			"latitude": -0.9460,
			"longitude": 100.5175,
			"battery_percent": 19,
			"passengers_count": 4,
			"notes": "Posisi 150m sebelum tikungan Panorama 1 Sitinjau Lauik."
		}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/sos", bytes.NewBuffer(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created for SOS dispatch, got %d: %s", rec.Code, rec.Body.String())
		}

		var res SOSEmergencyResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Status != "sos_dispatched" {
			t.Fatalf("expected status=sos_dispatched, got %s", res.Status)
		}
		if res.SOSSignal.ETARescueMinutes <= 0 {
			t.Fatalf("expected positive ETA rescue minutes, got %d", res.SOSSignal.ETARescueMinutes)
		}
	})

	t.Run("TC-S4-07: Proteksi Token Bucket Rate Limiting (429 Too Many Requests) pada SOS burst", func(t *testing.T) {
		payload := []byte(`{"latitude": -0.9460, "longitude": 100.5175}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/sos", bytes.NewBuffer(payload))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Simulate-RateLimit", "burst")
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusTooManyRequests {
			t.Fatalf("expected 429 Too Many Requests, got %d", rec.Code)
		}
	})

	t.Run("TC-S4-08: GET /api/v1/admin/sos monitoring antrean sinyal SOS", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/admin/sos", nil)
		req.Header.Set("Authorization", "Bearer "+middleware.TokenAdminDispar)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var res map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res["status"] != "ok" {
			t.Fatalf("expected status=ok, got %v", res["status"])
		}
	})

	t.Run("TC-S4-09: POST /api/v1/spatial/navigation-telemetry anti-fake dwell time", func(t *testing.T) {
		// Dwell time < 10m -> 422 Unprocessable Entity
		passBy := []byte(`{"destination_id":"dest-002","dwell_time_minutes":4,"is_repeat_visit":false}`)
		reqPass := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bytes.NewBuffer(passBy))
		reqPass.Header.Set("Content-Type", "application/json")
		recPass := httptest.NewRecorder()
		r.ServeHTTP(recPass, reqPass)

		if recPass.Code != http.StatusUnprocessableEntity {
			t.Fatalf("expected 422 Unprocessable Entity, got %d", recPass.Code)
		}

		// Dwell time >= 10m -> 200 OK
		valid := []byte(`{"destination_id":"dest-001","dwell_time_minutes":120,"is_repeat_visit":true}`)
		reqValid := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bytes.NewBuffer(valid))
		reqValid.Header.Set("Content-Type", "application/json")
		recValid := httptest.NewRecorder()
		r.ServeHTTP(recValid, reqValid)

		if recValid.Code != http.StatusOK {
			t.Fatalf("expected 200 OK for valid dwell time, got %d", recValid.Code)
		}
	})

	t.Run("TC-S4-11: GET /api/v1/spatial/emergency-contacts memuat kontak BPBD, PMI, Damkar & Pos SAR Sumbar", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/spatial/emergency-contacts", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res EmergencyContactsResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.Total < 6 {
			t.Fatalf("expected at least 6 emergency contacts, got %d", res.Total)
		}

		hasBPBD := false
		for _, c := range res.Contacts {
			if c.PhoneNumber == "(0751) 890721" || c.PhoneNumber == "08116606113" {
				hasBPBD = true
				break
			}
		}
		if !hasBPBD {
			t.Fatal("expected real official disaster phone number to be present in emergency contacts")
		}
	})

	t.Run("TC-S4-12: POST /api/v1/spatial/sos mendukung Offline Sync dan Idempotency", func(t *testing.T) {
		payload := []byte(`{
			"sos_code": "SOS-OFFLINE-TEST-999",
			"is_offline_sync": true,
			"tourist_name": "Rombongan Malalak",
			"phone_number": "081234567890",
			"emergency_type": "Longsor Tebing Menutup Jalan",
			"latitude": -0.3200,
			"longitude": 100.2200,
			"battery_percent": 14,
			"passengers_count": 3
		}`)

		// First sync dispatch
		req1 := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/sos", bytes.NewBuffer(payload))
		req1.Header.Set("Content-Type", "application/json")
		rec1 := httptest.NewRecorder()
		r.ServeHTTP(rec1, req1)

		if rec1.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created on first offline SOS sync, got %d: %s", rec1.Code, rec1.Body.String())
		}

		var res1 SOSEmergencyResponse
		_ = json.Unmarshal(rec1.Body.Bytes(), &res1)
		if !res1.SOSSignal.IsOfflineSync {
			t.Fatal("expected is_offline_sync=true")
		}
		if res1.SOSSignal.SOSCode != "SOS-OFFLINE-TEST-999" {
			t.Fatalf("expected preserved offline sos_code, got %s", res1.SOSSignal.SOSCode)
		}

		// Second sync attempt with the same sos_code (Idempotent test)
		req2 := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/sos", bytes.NewBuffer(payload))
		req2.Header.Set("Content-Type", "application/json")
		rec2 := httptest.NewRecorder()
		r.ServeHTTP(rec2, req2)

		if rec2.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created on idempotent resend, got %d", rec2.Code)
		}
		var res2 SOSEmergencyResponse
		_ = json.Unmarshal(rec2.Body.Bytes(), &res2)
		if res2.SOSSignal.ID != res1.SOSSignal.ID {
			t.Fatalf("expected same signal ID for idempotent sync, got %s vs %s", res2.SOSSignal.ID, res1.SOSSignal.ID)
		}
	})

	t.Run("TC-S4-13: GET /api/v1/spatial/emergency-contacts menyediakan protokol panggilan suara darurat 112 & 110", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/spatial/emergency-contacts", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d: %s", rec.Code, rec.Body.String())
		}

		var res EmergencyContactsResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &res)
		if res.EmergencyCall == nil {
			t.Fatal("expected emergency_call to be present")
		}
		if res.EmergencyCall.NationalEmergency != "112" || res.EmergencyCall.Police != "110" {
			t.Fatalf("expected national emergency 112 and police 110, got %+v", res.EmergencyCall)
		}
		if res.EmergencyCall.BPBDSumbar != "(0751) 890721" {
			t.Fatalf("expected BPBD Sumbar (0751) 890721, got %s", res.EmergencyCall.BPBDSumbar)
		}
	})

	t.Run("TC-S4-14: GET & POST /api/v1/spatial/news menyajikan Berita Wisata & Bencana Sumatera Barat (sumbarkita.id & sumbar.antaranews.com)", func(t *testing.T) {
		// 1. GET semua berita wisata & bencana Sumbar
		req := httptest.NewRequest(http.MethodGet, "/api/v1/spatial/news", nil)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on GET /spatial/news, got %d: %s", rec.Code, rec.Body.String())
		}

		var res struct {
			Status  string              `json:"status"`
			Sources []string            `json:"sources"`
			Total   int                 `json:"total"`
			News    []models.SosNewsItem `json:"news"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to parse news response: %v", err)
		}
		if res.Total < 6 {
			t.Fatalf("expected at least 6 Sumbar news articles from sumbarkita.id and sumbar.antaranews.com, got %d", res.Total)
		}

		hasSumbarkita := false
		hasAntaraSumbar := false
		for _, item := range res.News {
			if item.PortalDomain == "sumbarkita.id" {
				hasSumbarkita = true
			}
			if item.PortalDomain == "sumbar.antaranews.com" {
				hasAntaraSumbar = true
			}
		}
		if !hasSumbarkita || !hasAntaraSumbar {
			t.Fatalf("expected both sumbarkita.id (%v) and sumbar.antaranews.com (%v) news articles", hasSumbarkita, hasAntaraSumbar)
		}

		// 2. Filter portal=sumbarkita.id
		reqSK := httptest.NewRequest(http.MethodGet, "/api/v1/spatial/news?portal=sumbarkita.id", nil)
		recSK := httptest.NewRecorder()
		r.ServeHTTP(recSK, reqSK)
		if recSK.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on portal filter, got %d", recSK.Code)
		}
	})
}
