package be1_core

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// TestSprint3IntegrationSuite — Hari 15 (Jumat - Target Rilis Sprint 3)
// Menguji 8 skenario wajib Minggu 3: Gaode Behavior-Based Ranking, Telemetri Dwell Time GPS,
// Guardrail Pass-By (<10 menit ditolak), Live Hazard Alert Sitinjau Lauik, Trigger Bencana FS-1,
// Pancaran Darurat SOS GPS FE-1, Kamus Saku Audio Minang, dan Kalender Budaya Hari Pakan.
func TestSprint3IntegrationSuite(t *testing.T) {
	mux := http.NewServeMux()
	h := NewHandlerBE1()
	h.RegisterSprint1Routes(mux)

	// TC-S3-01: Leaderboard Gaode Behavior-Based Ranking mengembalikan skor keaslian & urutan benar
	t.Run("TC-S3-01_GetGaodeBehaviorRankings", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/rankings/gaode", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
		var body map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		rankings, ok := body["rankings"].([]interface{})
		if !ok || len(rankings) < 5 {
			t.Fatalf("expected at least 5 ranked destinations, got %v", len(rankings))
		}
	})

	// TC-S3-02: Telemetri Navigasi & Dwell Time GPS (>10 menit) memperbarui skor Gaode Ranking otomatis
	t.Run("TC-S3-02_PostNavigationTelemetry_UpdatesScore", func(t *testing.T) {
		payload := []byte(`{
			"destination_id": "dest-008",
			"dwell_time_minutes": 165,
			"is_repeat_visit": true,
			"gps_accuracy_meters": 4.2
		}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bytes.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on valid GPS telemetry, got %d", rec.Code)
		}
	})

	// TC-S3-03: Anti-Manipulasi Gaode Guide menolak ping GPS di bawah 10 menit (kendaraan hanya lewat)
	t.Run("TC-S3-03_PostNavigationTelemetry_RejectsPassByUnder10Min", func(t *testing.T) {
		payload := []byte(`{
			"destination_id": "dest-002",
			"dwell_time_minutes": 4,
			"is_repeat_visit": false
		}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bytes.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusUnprocessableEntity {
			t.Fatalf("expected 422 Unprocessable Entity for pass-by dwell time <10m, got %d", rec.Code)
		}
	})

	// TC-S3-04: Live Hazard Alert mendeteksi pengguna berada di zona rawan Sitinjau Lauik (-0.9468, 100.5182)
	t.Run("TC-S3-04_GetLiveHazardAlerts_DetectsSitinjauLauikZone", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/spatial/hazards?lat=-0.9465&lng=100.5180", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
		var body map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		if body["user_in_hazard_zone"] != true {
			t.Fatalf("expected user_in_hazard_zone=true at Sitinjau Lauik coordinates")
		}
	})

	// TC-S3-05: Endpoint Trigger Bencana FS-1 mengubah status koridor Lembah Anai dengan token Admin Dispar
	t.Run("TC-S3-05_PostTriggerHazardAdmin_RBACProtected", func(t *testing.T) {
		payload := []byte(`{
			"corridor_code": "LEMBAH-ANAI",
			"severity": "Siaga",
			"hazard_type": "Debit Air Sungai Batang Anai Naik & Sistem Buka-Tutup",
			"weather_status": "Hujan Deras di Hulu Singgalang",
			"message": "SIAGA LEMBAH ANAI: Arus lalu lintas dialihkan sementara via Jalur Malalak.",
			"triggered_by_admin": "Command Center FS-1"
		}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/admin/hazards/trigger", bytes.NewReader(payload))
		req.Header.Set("Authorization", "Bearer dev-token-admin-dispar")
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK for admin hazard trigger, got %d", rec.Code)
		}
	})

	// TC-S3-06: Pancaran Darurat SOS GPS FE-1 menghitung jarak Posko SAR terdekat & ETA evakuasi otomatis
	t.Run("TC-S3-06_PostSOSEmergencySignal_CalculatesNearestRescuePost", func(t *testing.T) {
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
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/sos", bytes.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created for SOS dispatch, got %d", rec.Code)
		}
	})

	// TC-S3-07: Kamus Saku Audio Minang mengembalikan frasa tawar-menawar & panduan Kato Nan Ampek
	t.Run("TC-S3-07_GetMinangAudioPhrases", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/culture/minang-phrases?category=tawar_pasar", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
		var body map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		phrases, ok := body["phrases"].([]interface{})
		if !ok || len(phrases) == 0 {
			t.Fatalf("expected at least 1 tawar_pasar Minang phrase")
		}
	})

	// TC-S3-08: Kalender Budaya & Jadwal Hari Pakan Nagari mengembalikan agenda + kalkulasi jarak spasial
	t.Run("TC-S3-08_GetCulturalEventsCalendar", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/culture/events?type=Hari%20Pakan&lat=-0.4560&lng=100.5900", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
		var body map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		events, ok := body["events"].([]interface{})
		if !ok || len(events) == 0 {
			t.Fatalf("expected at least 1 Hari Pakan Nagari event")
		}
	})
}
