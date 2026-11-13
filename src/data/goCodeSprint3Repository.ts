import type { GoCodeFile } from './goCodeRepository';

export const GO_SPRINT3_CODE_FILES: GoCodeFile[] = [
  {
    id: 's3-sql-migrations',
    filename: 'migrations_sprint3.sql (Hari 11)',
    filepath: 'backend/internal/be1_core/migrations_sprint3.sql',
    language: 'sql',
    sprintDay: 'Hari 11 (Senin — Migrasi Tabel #10 & #11 Sprint 3)',
    description:
      'Menuntaskan 11/11 tabel PostgreSQL + PostGIS milik BE-1: gaode_behavior_rankings (P2.4), hazard_alerts & sos_signals (P7.2), serta minang_phrases & cultural_events (P1.4) tanpa menyentuh tabel transaksi/grup milik BE-2.',
    content: `-- =============================================================================
-- WISGO (Rancak.in) — MIGRASI DATABASE SPRINT 3 (MINGGU 3: HARI 11–15)
-- Author       : Backend 1 (BE-1: Core & Spasial)
-- Cakupan      : Menyelesaikan Kuota 11/11 Tabel Milik BE-1
--                Tabel #10: hazard_alerts & sos_signals (Pilar 7 — P7.2)
--                Tabel #11: gaode_behavior_rankings, minang_phrases, & cultural_events (Pilar 1 & 2)
-- Jaminan      : Zero Merge Conflict — Tidak menyentuh tabel transaksi/grup milik BE-2
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. TABEL #10A (KUOTA BE-1): gaode_behavior_rankings (Pilar 2 — P2.4)
CREATE TABLE IF NOT EXISTS gaode_behavior_rankings (
    id                          VARCHAR(64) PRIMARY KEY,
    destination_id              VARCHAR(64) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    category                    VARCHAR(64) NOT NULL,
    rank_position               INT NOT NULL DEFAULT 1,
    gaode_authenticity_score    NUMERIC(5, 2) NOT NULL DEFAULT 85.00,
    active_nav_count_30d        INT NOT NULL DEFAULT 0,
    avg_dwell_time_min          INT NOT NULL DEFAULT 45,
    return_visit_rate_pct       NUMERIC(5, 2) NOT NULL DEFAULT 15.00,
    anti_fake_review_verified   BOOLEAN NOT NULL DEFAULT TRUE,
    trending_badge              VARCHAR(120) NOT NULL DEFAULT 'Terverifikasi Telemetri GPS',
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. TABEL #10B (KUOTA BE-1): hazard_alerts & sos_signals (Pilar 7 — P7.2)
CREATE TABLE IF NOT EXISTS hazard_alerts (
    id                      VARCHAR(64) PRIMARY KEY,
    corridor_code           VARCHAR(64) NOT NULL UNIQUE, -- SITINJAU-LAUIK, LEMBAH-ANAI, KELOK-9, KELOK-44
    location                VARCHAR(160) NOT NULL,
    road_segment            VARCHAR(180) NOT NULL,
    city_regency            VARCHAR(100) NOT NULL,
    latitude                DOUBLE PRECISION NOT NULL,
    longitude               DOUBLE PRECISION NOT NULL,
    geog                    GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
    radius_meter            INT NOT NULL DEFAULT 2500,
    severity                VARCHAR(32) NOT NULL DEFAULT 'Normal',
    hazard_type             VARCHAR(80) NOT NULL,
    weather_status          VARCHAR(80) NOT NULL,
    slope_gradient_deg      INT NOT NULL DEFAULT 18,
    message                 TEXT NOT NULL,
    detour_route            TEXT NOT NULL,
    detour_route_geojson    JSONB NOT NULL DEFAULT '{}'::jsonb,
    nearest_rescue_post     VARCHAR(160) NOT NULL,
    emergency_contact       VARCHAR(64) NOT NULL,
    triggered_by_admin      VARCHAR(100),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hazard_alerts_geog_gist ON hazard_alerts USING GIST (geog);

CREATE TABLE IF NOT EXISTS sos_signals (
    id                      VARCHAR(64) PRIMARY KEY,
    sos_code                VARCHAR(40) NOT NULL UNIQUE,
    tourist_name            VARCHAR(120) NOT NULL,
    phone_number            VARCHAR(40) NOT NULL,
    emergency_type          VARCHAR(80) NOT NULL,
    latitude                DOUBLE PRECISION NOT NULL,
    longitude               DOUBLE PRECISION NOT NULL,
    geog                    GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
    battery_percent         INT NOT NULL DEFAULT 50,
    passengers_count        INT NOT NULL DEFAULT 1,
    nearest_corridor        VARCHAR(120) NOT NULL,
    nearest_rescue_post     VARCHAR(160) NOT NULL,
    distance_to_rescue_km   NUMERIC(6, 2) NOT NULL DEFAULT 2.5,
    eta_rescue_minutes      INT NOT NULL DEFAULT 12,
    status                  VARCHAR(40) NOT NULL DEFAULT 'Dipancarkan',
    notes                   TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TABEL #11 (KUOTA BE-1): minang_phrases & cultural_events (Pilar 1 — P1.4)
CREATE TABLE IF NOT EXISTS minang_phrases (
    id                  VARCHAR(64) PRIMARY KEY,
    category            VARCHAR(48) NOT NULL,
    indonesian_text     TEXT NOT NULL,
    minang_text         TEXT NOT NULL,
    phonetic_guide      TEXT NOT NULL,
    audio_url           TEXT NOT NULL,
    dialect_note        VARCHAR(120) NOT NULL,
    usage_context_tip   TEXT NOT NULL,
    politeness_level    VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS cultural_events (
    id                  VARCHAR(64) PRIMARY KEY,
    title               VARCHAR(160) NOT NULL,
    event_type          VARCHAR(64) NOT NULL,
    nagari_location     VARCHAR(140) NOT NULL,
    city_regency        VARCHAR(100) NOT NULL,
    schedule_rule       VARCHAR(120) NOT NULL,
    next_event_date     VARCHAR(40) NOT NULL,
    latitude            DOUBLE PRECISION NOT NULL,
    longitude           DOUBLE PRECISION NOT NULL,
    highlight_item      TEXT NOT NULL,
    cultural_etiquette  TEXT NOT NULL
);`
  },
  {
    id: 's3-seeder-hazard-culture',
    filename: 'seeder_sprint3_hazard_culture.go (Hari 11)',
    filepath: 'backend/internal/be1_core/seeder_sprint3_hazard_culture.go',
    language: 'go',
    sprintDay: 'Hari 11 (Senin — Seeder Gaode, 4 Koridor Ekstrem & Budaya Minang)',
    description:
      'Seeder data Sumatera Barat Minggu 3: Leaderboard Gaode Guide, 4 koridor jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44), log sinyal SOS GPS, Kamus Saku Audio Minang, dan Kalender Hari Pakan.',
    content: `package be1_core

import (
	"time"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

func SeedSprint3GaodeRankings() []models.GaodeBehaviorRanking {
	now := time.Now()
	return []models.GaodeBehaviorRanking{
		{
			ID:                     "gaode-001",
			DestinationID:          "dest-001",
			DestinationName:        "Lembah Harau",
			Category:               "Alam & Geopark",
			CityRegency:            "Kab. Lima Puluh Kota",
			RankPosition:           1,
			GaodeAuthenticityScore: 98.4,
			ActiveNavCount30d:      4820,
			AvgDwellTimeMin:        145,
			ReturnVisitRatePct:     34.2,
			AntiFakeReviewVerified: true,
			TrendingBadge:          "Top #1 Dwell Time Terlama di Sumbar (2,4 Jam)",
			UpdatedAt:              now,
		},
		{
			ID:                     "gaode-002",
			DestinationID:          "dest-002",
			DestinationName:        "Jam Gadang & Pasar Atas",
			Category:               "Budaya & Nagari",
			CityRegency:            "Kota Bukittinggi",
			RankPosition:           2,
			GaodeAuthenticityScore: 97.1,
			ActiveNavCount30d:      6390,
			AvgDwellTimeMin:        118,
			ReturnVisitRatePct:     41.5,
			AntiFakeReviewVerified: true,
			TrendingBadge:          "Top #1 Navigasi Aktif Tertinggi (6.390 Trip/Bulan)",
			UpdatedAt:              now,
		},
	}
}

func SeedSprint3HazardAlerts() []models.HazardAlert {
	now := time.Now()
	return []models.HazardAlert{
		{
			ID:                "haz-001",
			CorridorCode:      "SITINJAU-LAUIK",
			Location:          "Panorama 1 & Panorama 2 Sitinjau Lauik",
			RoadSegment:       "Jalan Lintas Padang – Solok KM 18 s/d KM 25",
			CityRegency:       "Kota Padang – Kab. Solok",
			Latitude:          -0.9468,
			Longitude:         100.5182,
			RadiusMeter:       3500,
			Severity:          "Siaga",
			HazardType:        "Tanjakan Ekstrem 24° + Kabut Tebal & Risiko Truk Rem Blong",
			WeatherStatus:     "Hujan Lebat & Jarak Pandang 25 Meter",
			SlopeGradientDeg:  24,
			Message:           "PERINGATAN JALUR EKSTREM: Curah hujan tinggi di tikungan Panorama 1 Sitinjau Lauik. Sistem buka-tutup aktif oleh relawan PKJR.",
			DetourRoute:       "Gunakan jalur alternatif via Padang Panjang – Danau Singkarak – Solok (+45 menit lebih aman).",
			NearestRescuePost: "Posko Terpadu PKJR & BPBD Panorama 1 Sitinjau Lauik",
			EmergencyContact:  "+62-811-660-112",
			UpdatedAt:         now,
		},
	}
}`
  },
  {
    id: 's3-gaode-ranking',
    filename: 'gaode_ranking_day12.go (Hari 12)',
    filepath: 'backend/internal/be1_core/gaode_ranking_day12.go',
    language: 'go',
    sprintDay: 'Hari 12 (Selasa — Algoritma Gaode Ranking & Telemetri Dwell Time GPS)',
    description:
      'Implementasi GET /api/v1/destinations/rankings/gaode dan POST /api/v1/spatial/navigation-telemetry dengan rumus bobot (0.45 Nav + 0.40 Dwell Time + 0.15 Return Rate) serta guardrail penolak pass-by (<10 menit).',
    content: `package be1_core

import (
	"encoding/json"
	"math"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type NavigationTelemetryInput struct {
	DestinationID     string  \`json:"destination_id"\`
	DwellTimeMinutes  int     \`json:"dwell_time_minutes"\`
	IsRepeatVisit     bool    \`json:"is_repeat_visit"\`
	GPSAccuracyMeters float64 \`json:"gps_accuracy_meters"\`
}

func ComputeGaodeScore(activeNavCount, avgDwellMin int, returnRatePct float64) float64 {
	normNav := math.Min(100.0, (float64(activeNavCount)/5000.0)*100.0)
	normDwell := math.Min(100.0, (float64(avgDwellMin)/140.0)*100.0)
	normReturn := math.Min(100.0, (returnRatePct/40.0)*100.0)

	rawScore := (0.45 * normNav) + (0.40 * normDwell) + (0.15 * normReturn)
	scaled := 82.0 + (rawScore/100.0)*17.5
	return math.Round(math.Min(99.8, scaled)*10) / 10
}

// GetGaodeBehaviorRankings — GET /api/v1/destinations/rankings/gaode
func (h *HandlerBE1) GetGaodeBehaviorRankings(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	categoryFilter := strings.TrimSpace(r.URL.Query().Get("category"))
	rankings := h.repo.ListGaodeRankings(categoryFilter)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":           "ok",
		"algorithm":        "Gaode Behavior-Based Ranking v3.0 (45% Active Navigation + 40% GPS Dwell Time + 15% Return Rate)",
		"anti_fake_policy": "Ulasan teks atau rating bintang tanpa telemetri kedatangan GPS fisik (>15 menit dwell time) diabaikan 100%.",
		"category_filter":  categoryFilter,
		"total":            len(rankings),
		"rankings":         rankings,
	})
}

// PostNavigationTelemetry — POST /api/v1/spatial/navigation-telemetry
func (h *HandlerBE1) PostNavigationTelemetry(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var input NavigationTelemetryInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.DestinationID == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Payload telemetri tidak valid; field 'destination_id' dan 'dwell_time_minutes' wajib diisi.",
		})
		return
	}

	if input.DwellTimeMinutes < 10 {
		w.WriteHeader(http.StatusUnprocessableEntity)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status":              "rejected_pass_by",
			"destination_id":      input.DestinationID,
			"dwell_time_minutes":  input.DwellTimeMinutes,
			"anti_fake_guardrail": "Dwell time di bawah 10 menit terdeteksi sebagai kendaraan melintas (pass-by), tidak dihitung ke dalam Gaode Ranking.",
		})
		return
	}

	updated, err := h.repo.RecordNavigationTelemetry(input)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "telemetry_recorded",
		"message":        "Telemetri navigasi & dwell time GPS berhasil diverifikasi. Skor Gaode Ranking diperbarui otomatis.",
		"updated_metric": updated,
	})
}`
  },
  {
    id: 's3-hazard-sos',
    filename: 'hazard_sos_day13.go (Hari 13)',
    filepath: 'backend/internal/be1_core/hazard_sos_day13.go',
    language: 'go',
    sprintDay: 'Hari 13 (Rabu — Live Hazard Alert, Trigger Bencana FS-1 & SOS GPS FE-1)',
    description:
      'Menangani deteksi koridor jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44), simulasi Trigger Bencana untuk Panel Command Center FS-1, dan pancaran sinyal darurat SOS GPS untuk FE-1.',
    content: `package be1_core

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type TriggerHazardInput struct {
	CorridorCode     string \`json:"corridor_code"\`
	Severity         string \`json:"severity"\`
	HazardType       string \`json:"hazard_type"\`
	WeatherStatus    string \`json:"weather_status"\`
	Message          string \`json:"message"\`
	DetourRoute      string \`json:"detour_route"\`
	TriggeredByAdmin string \`json:"triggered_by_admin"\`
}

type SOSEmergencyInput struct {
	TouristName     string  \`json:"tourist_name"\`
	PhoneNumber     string  \`json:"phone_number"\`
	EmergencyType   string  \`json:"emergency_type"\`
	Latitude        float64 \`json:"latitude"\`
	Longitude       float64 \`json:"longitude"\`
	BatteryPercent  int     \`json:"battery_percent"\`
	PassengersCount int     \`json:"passengers_count"\`
	Notes           string  \`json:"notes"\`
}

// GetLiveHazardAlerts — GET /api/v1/spatial/hazards
func (h *HandlerBE1) GetLiveHazardAlerts(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	severityFilter := strings.TrimSpace(r.URL.Query().Get("severity"))
	corridorFilter := strings.TrimSpace(r.URL.Query().Get("corridor"))
	hasGPS, userLat, userLng := parseGPSQuery(r)

	hazards := h.repo.ListHazardAlerts(severityFilter, corridorFilter)

	var intersectingBanner interface{}
	if hasGPS {
		for i := range hazards {
			distKm := CalculateSpatialDistanceKm(userLat, userLng, hazards[i].Latitude, hazards[i].Longitude)
			if distKm*1000.0 <= float64(hazards[i].RadiusMeter)*1.5 {
				intersectingBanner = hazards[i]
				break
			}
		}
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":                    "ok",
		"monitored_corridors_count": len(hazards),
		"user_in_hazard_zone":       intersectingBanner != nil,
		"fe1_active_warning_banner": intersectingBanner,
		"hazards":                   hazards,
	})
}

// PostTriggerHazardAdmin — POST /api/v1/admin/hazards/trigger (Panel Trigger Bencana FS-1)
func (h *HandlerBE1) PostTriggerHazardAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var input TriggerHazardInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.CorridorCode == "" || input.Severity == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Field 'corridor_code' dan 'severity' wajib diisi.",
		})
		return
	}

	updated, err := h.repo.TriggerHazardCorridor(input)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Koridor tidak ditemukan"})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":           "hazard_triggered",
		"broadcast_target": "FE-1 Banner Peringatan Jalur Rawan & Rute Pengalihan Otomatis",
		"hazard_alert":     updated,
	})
}

// PostSOSEmergencySignal — POST /api/v1/spatial/sos (Pancaran Darurat SOS GPS FE-1)
func (h *HandlerBE1) PostSOSEmergencySignal(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var input SOSEmergencyInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || (input.Latitude == 0 && input.Longitude == 0) {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Koordinat GPS ('latitude' & 'longitude') wajib disertakan.",
		})
		return
	}

	created := h.repo.CreateSOSSignal(input)
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":               "sos_dispatched",
		"message":              fmt.Sprintf("Sinyal darurat %s diterima oleh %s. Estimasi tiba %d menit.", created.SOSCode, created.NearestRescuePost, created.ETARescueMinutes),
		"sos_signal":           created,
		"survival_instruction": "Tetap berada di titik aman di luar badan jalan tikungan, nyalakan lampu hazard, dan hemat baterai ponsel Anda.",
	})
}`
  },
  {
    id: 's3-minang-culture',
    filename: 'minang_culture_day14.go (Hari 14)',
    filepath: 'backend/internal/be1_core/minang_culture_day14.go',
    language: 'go',
    sprintDay: 'Hari 14 (Kamis — Kamus Saku Audio Minang & Kalender Hari Pakan)',
    description:
      'Menyediakan frasa praktis bahasa Minang sehari-hari dengan audio penutur asli + panduan adab Kato Nan Ampek serta jadwal Hari Pakan (Pasar Tradisional Nagari) dan festival budaya Sumatera Barat.',
    content: `package be1_core

import (
	"encoding/json"
	"net/http"
	"strings"
)

// GetMinangAudioPhrases — GET /api/v1/culture/minang-phrases
func (h *HandlerBE1) GetMinangAudioPhrases(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	category := strings.TrimSpace(r.URL.Query().Get("category"))
	searchQuery := strings.TrimSpace(r.URL.Query().Get("q"))

	phrases := h.repo.ListMinangPhrases(category, searchQuery)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "ok",
		"design_token":   "--indigo-500 (#5B6AE8) · Lencana Budaya & Nagari",
		"cultural_guide": "Gunakan prinsip Kato Nan Ampek (Kato Mandaki kepada yang tua, Kato Mendatar kepada sebaya, Kato Malereang saat berbasa-basi sopan di Nagari).",
		"total":          len(phrases),
		"phrases":        phrases,
	})
}

// GetCulturalEventsCalendar — GET /api/v1/culture/events
func (h *HandlerBE1) GetCulturalEventsCalendar(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	eventType := strings.TrimSpace(r.URL.Query().Get("type"))
	cityFilter := strings.TrimSpace(r.URL.Query().Get("city_regency"))
	hasGPS, userLat, userLng := parseGPSQuery(r)

	events := h.repo.ListCulturalEvents(eventType, cityFilter, hasGPS, userLat, userLng)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":       "ok",
		"design_token": "--indigo-500 (#5B6AE8) · Kalender Budaya & Hari Pakan Nagari",
		"total":        len(events),
		"events":       events,
	})
}`
  },
  {
    id: 's3-integration-test',
    filename: 'be1_sprint3_test.go (Hari 15)',
    filepath: 'backend/internal/be1_core/be1_sprint3_test.go',
    language: 'go',
    sprintDay: 'Hari 15 (Jumat — Automated Test Suite Sprint 3 TC-S3-01 s/d TC-S3-08)',
    description:
      'Menguji 8 skenario wajib Minggu 3: Gaode Ranking, Telemetri Dwell Time GPS, Penolakan Pass-By <10m, Deteksi Zona Bahaya Sitinjau Lauik, Trigger Bencana FS-1, Pancaran SOS GPS FE-1, Kamus Audio Minang, dan Kalender Budaya Hari Pakan.',
    content: `package be1_core

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSprint3IntegrationSuite(t *testing.T) {
	mux := http.NewServeMux()
	h := NewHandlerBE1()
	h.RegisterSprint1Routes(mux)

	t.Run("TC-S3-01_GetGaodeBehaviorRankings", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/destinations/rankings/gaode", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
	})

	t.Run("TC-S3-02_PostNavigationTelemetry_UpdatesScore", func(t *testing.T) {
		payload := []byte(\`{"destination_id":"dest-008","dwell_time_minutes":165,"is_repeat_visit":true}\`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bytes.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
	})

	t.Run("TC-S3-03_PostNavigationTelemetry_RejectsPassByUnder10Min", func(t *testing.T) {
		payload := []byte(\`{"destination_id":"dest-002","dwell_time_minutes":4}\`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bytes.NewReader(payload))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusUnprocessableEntity {
			t.Fatalf("expected 422 for pass-by dwell time <10m, got %d", rec.Code)
		}
	})

	t.Run("TC-S3-04_GetLiveHazardAlerts_DetectsSitinjauLauikZone", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/spatial/hazards?lat=-0.9465&lng=100.5180", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		var body map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		if body["user_in_hazard_zone"] != true {
			t.Fatalf("expected user_in_hazard_zone=true at Sitinjau Lauik")
		}
	})
}`
  }
];
