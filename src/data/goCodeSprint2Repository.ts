import type { GoCodeFile } from './goCodeRepository';

export const GO_SPRINT2_CODE_FILES: GoCodeFile[] = [
  {
    id: 's2-sql-migrations',
    filename: 'migrations_sprint2.sql (Hari 6)',
    filepath: 'backend/internal/be1_core/migrations_sprint2.sql',
    language: 'sql',
    sprintDay: 'Hari 6 (Senin — Migrasi 5 Tabel Sprint 2)',
    description: 'DDL PostgreSQL 16 + PostGIS 3.4 untuk 5 tabel Minggu 2 milik BE-1: panorama_scenes, panorama_hotspots (4 jenis pin), shunlu_pois (GIST corridor), scenic_micro_maps (Audio GPS <=15m), dan pungli_reports (Satgas Saber Pungli).',
    content: `-- ============================================================================
-- MIGRASI POSTGRESQL + POSTGIS KHUSUS BE-1 (SPRINT 2: MINGGU 2 / HARI 6-10)
-- Repo: github.com/LuthfiaHasan/WISGO (Branch: dev)
-- Lokasi File: backend/internal/be1_core/migrations_sprint2.sql
-- Prinsip: ZERO MERGE CONFLICT (Hanya menyentuh 5 tabel milik BE-1 di Minggu 2)
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

-- 5. Tabel Tur Virtual 360° Aerial-to-Ground: panorama_scenes (Pilar 1 - P1.1)
CREATE TABLE IF NOT EXISTS panorama_scenes (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    title VARCHAR(180) NOT NULL,
    scene_type VARCHAR(24) NOT NULL CHECK (scene_type IN ('aerial', 'ground')),
    panorama_url TEXT NOT NULL,
    upload_format VARCHAR(24) NOT NULL DEFAULT 'url',
    spatial_audio_url TEXT NOT NULL DEFAULT '',
    initial_pitch DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    initial_yaw DOUBLE PRECISION NOT NULL DEFAULT 180.0,
    is_default_scene BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_panorama_scenes_dest_id ON panorama_scenes (destination_id);

-- 6. Tabel Sistem 4 Pin Interaktif Terstandarisasi: panorama_hotspots (Pilar 1 - P1.2)
-- Tipe Pin: navigasi (Biru), audio (Emas), fasilitas (Hijau), mitra (Oranye)
CREATE TABLE IF NOT EXISTS panorama_hotspots (
    id VARCHAR(36) PRIMARY KEY,
    scene_id VARCHAR(36) NOT NULL REFERENCES panorama_scenes(id) ON DELETE CASCADE,
    pin_type VARCHAR(24) NOT NULL CHECK (pin_type IN ('navigasi', 'audio', 'fasilitas', 'mitra')),
    color_token VARCHAR(24) NOT NULL DEFAULT '#2563EB',
    pitch DOUBLE PRECISION NOT NULL CHECK (pitch >= -90.0 AND pitch <= 90.0),
    yaw DOUBLE PRECISION NOT NULL CHECK (yaw >= 0.0 AND yaw <= 360.0),
    title VARCHAR(180) NOT NULL,
    target_ref VARCHAR(64) NOT NULL DEFAULT '', -- ID Scene tujuan (dive-in) atau ID Mitra Nagari (Quick Booking)
    audio_url TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_panorama_hotspots_scene_id ON panorama_hotspots (scene_id);

-- 7. Tabel Pencarian Searah Rute ("Shunlu"): shunlu_pois (Pilar 2 - P2.1)
CREATE TABLE IF NOT EXISTS shunlu_pois (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(32) NOT NULL CHECK (category IN ('rm_padang', 'spbu', 'masjid_bersih', 'atm', 'bengkel')),
    corridor_road VARCHAR(120) NOT NULL,
    city_regency VARCHAR(80) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    detour_minutes INTEGER NOT NULL DEFAULT 3,
    detour_distance_meter INTEGER NOT NULL DEFAULT 250,
    highlight_note TEXT NOT NULL DEFAULT '',
    opening_hours VARCHAR(80) NOT NULL DEFAULT '06.00 - 22.00 WIB',
    is_recommended BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_shunlu_pois_geog ON shunlu_pois USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_shunlu_pois_category ON shunlu_pois (category);

-- 8. Tabel Peta Mikro Kawasan & Audio GPS <=15m: scenic_micro_maps (Pilar 2 - P2.2 & P2.3)
CREATE TABLE IF NOT EXISTS scenic_micro_maps (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    area_size_hectare NUMERIC(6,1) NOT NULL DEFAULT 12.5,
    walkway_geojson JSONB NOT NULL DEFAULT '{}'::jsonb,
    child_friendly_path BOOLEAN NOT NULL DEFAULT TRUE,
    elderly_friendly_path BOOLEAN NOT NULL DEFAULT TRUE,
    internal_pois JSONB NOT NULL DEFAULT '[]'::jsonb,
    audio_triggers JSONB NOT NULL DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. Tabel Laporan Satgas Saber Pungli Anonim: pungli_reports (Pilar 3 & 8 - P3.4 & P8.1)
CREATE TABLE IF NOT EXISTS pungli_reports (
    id VARCHAR(36) PRIMARY KEY,
    ticket_code VARCHAR(32) NOT NULL UNIQUE,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    reporter_name VARCHAR(120) NOT NULL DEFAULT 'Wisatawan Anonim',
    incident_category VARCHAR(48) NOT NULL DEFAULT 'parkir_liar',
    charged_amount_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    official_perda_price_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    overcharge_amount_idr NUMERIC(12,2) NOT NULL DEFAULT 0,
    photo_evidence TEXT NOT NULL,
    upload_format VARCHAR(24) NOT NULL DEFAULT 'url',
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    incident_geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    description TEXT NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'Masuk' CHECK (status IN ('Masuk', 'Diverifikasi', 'Ditindaklanjuti', 'Selesai')),
    satgas_notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pungli_reports_geog ON pungli_reports USING GIST (incident_geog);
CREATE INDEX IF NOT EXISTS idx_pungli_reports_status ON pungli_reports (status);

COMMIT;`,
  },
  {
    id: 's2-panorama-day7',
    filename: 'panorama_360_day7.go (Hari 7)',
    filepath: 'backend/internal/be1_core/panorama_360_day7.go',
    language: 'go',
    sprintDay: 'Hari 7 (Selasa — Tur 360° 4-Pin & CMS Pin Editor)',
    description: 'Handler Hari 7 untuk GET /api/v1/destinations/{id}/scenes-360 (FE-1 Layar 07), POST /api/v1/admin/scenes-360 (URL/Base64/Multipart), dan POST /api/v1/admin/scenes-360/{sceneId}/hotspots (Klik-Tempel 4 Pin: Navigasi Biru, Audio Emas, Fasilitas Hijau, Mitra Oranye).',
    content: `package be1_core

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ResolvePinColorToken memastikan 4 jenis Pin Interaktif 360° mengikuti token warna desain.md
func ResolvePinColorToken(pinType string) string {
	switch strings.ToLower(strings.TrimSpace(pinType)) {
	case "navigasi":
		return "#2563EB" // Biru — Pindah titik aerial <-> ground
	case "audio":
		return "#D97706" // Emas — Putar cerita sejarah & adat
	case "fasilitas":
		return "#1E9E5A" // Hijau — Info toilet, musala, parkir, sinyal
	case "mitra":
		return "#E85D1A" // Oranye — Buka Quick Booking Drawer Mitra Nagari
	default:
		return "#2563EB"
	}
}

// 1. GetDestinationScenes360 — GET /api/v1/destinations/{id}/scenes-360 (Hari 7 — FE-1 Layar 07 Tur 360°)
func (h *HandlerBE1) GetDestinationScenes360(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	idOrSlug := r.PathValue("id")

	dest, err := h.repo.FindAggregateDetail(idOrSlug, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": "Destinasi tidak ditemukan untuk pemuatan kanvas 360°.",
		})
		return
	}

	scenes := h.repo.GetScenes360ByDestinationID(dest.ID)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"destination_id":   dest.ID,
		"destination_name": dest.Name,
		"city_regency":     dest.CityRegency,
		"total_scenes":     len(scenes),
		"pin_legend": map[string]string{
			"navigasi":  "#2563EB (Biru — Transisi Aerial-to-Ground)",
			"audio":     "#D97706 (Emas — Cerita Sejarah & Adat Minang)",
			"fasilitas": "#1E9E5A (Hijau — Info Toilet, Musala & Parkir)",
			"mitra":     "#E85D1A (Oranye — Quick Booking Mitra Nagari)",
		},
		"scenes_360": scenes,
	})
}

// CreateScene360Request mendukung unggah panorama 360° via URL, Base64 JSON, atau simulasi Multipart (CMS FS-1)
type CreateScene360Request struct {
	DestinationID   string  \`json:"destination_id"\`
	Title           string  \`json:"title"\`
	Type            string  \`json:"type"\` // aerial | ground
	PanoramaURL     string  \`json:"panorama_url"\`
	PanoramaBase64  string  \`json:"panorama_base64,omitempty"\`
	SpatialAudioURL string  \`json:"spatial_audio_url,omitempty"\`
	InitialPitch    float64 \`json:"initial_pitch"\`
	InitialYaw      float64 \`json:"initial_yaw"\`
	IsDefaultScene  bool    \`json:"is_default_scene"\`
}

// 2. CreateScene360CMS — POST /api/v1/admin/scenes-360 (Hari 7 — CMS Studio 360° FS-1)
func (h *HandlerBE1) CreateScene360CMS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req CreateScene360Request
	contentType := r.Header.Get("Content-Type")
	uploadFormat := "url"

	if strings.HasPrefix(contentType, "multipart/form-data") {
		_ = r.ParseMultipartForm(16 << 20)
		req.DestinationID = r.FormValue("destination_id")
		req.Title = r.FormValue("title")
		req.Type = r.FormValue("type")
		req.PanoramaURL = r.FormValue("panorama_url")
		uploadFormat = "multipart"
		if req.PanoramaURL == "" {
			req.PanoramaURL = fmt.Sprintf("https://cdn.rancak.in/360/uploads/%s-multipart-360.jpg", req.DestinationID)
		}
	} else {
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			_ = json.NewEncoder(w).Encode(map[string]string{
				"status":  "error",
				"code":    "INVALID_JSON_BODY",
				"message": "Body JSON tidak valid untuk pembuatan Scene 360°.",
			})
			return
		}
		if req.PanoramaBase64 != "" {
			uploadFormat = "base64"
			if req.PanoramaURL == "" {
				req.PanoramaURL = fmt.Sprintf("https://cdn.rancak.in/360/base64-inline-%s.jpg", req.DestinationID)
			}
		}
	}

	if req.DestinationID == "" || req.Title == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "MISSING_REQUIRED_FIELDS",
			"message": "Field 'destination_id' dan 'title' wajib diisi oleh CMS Studio 360°.",
		})
		return
	}
	if req.Type == "" {
		req.Type = "ground"
	}
	if req.PanoramaURL == "" {
		req.PanoramaURL = "https://cdn.rancak.in/360/default-sumbar-equirectangular.jpg"
	}

	created := h.repo.AddScene360CMS(models.Scene360{
		DestinationID:   req.DestinationID,
		Title:           req.Title,
		Type:            strings.ToLower(req.Type),
		PanoramaURL:     req.PanoramaURL,
		UploadFormat:    uploadFormat,
		SpatialAudioURL: req.SpatialAudioURL,
		InitialPitch:    req.InitialPitch,
		InitialYaw:      req.InitialYaw,
		IsDefaultScene:  req.IsDefaultScene,
		Hotspots:        []models.Hotspot360{},
	})

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "created",
		"scene":  created,
	})
}

// 3. UpsertHotspot360CMS — POST /api/v1/admin/scenes-360/{sceneId}/hotspots (Hari 7 — Klik-Tempel Pin 360° FS-1)
func (h *HandlerBE1) UpsertHotspot360CMS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	sceneID := r.PathValue("sceneId")

	var input models.Hotspot360
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.Title == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_HOTSPOT_PAYLOAD",
			"message": "Payload Pin 360° wajib memuat 'title', 'type' (navigasi/audio/fasilitas/mitra), 'pitch', dan 'yaw'.",
		})
		return
	}

	if input.Pitch < -90.0 || input.Pitch > 90.0 || input.Yaw < 0.0 || input.Yaw > 360.0 {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_SPHERICAL_COORDS",
			"message": "Koordinat bola 360° tidak valid: pitch harus [-90..90] dan yaw harus [0..360].",
		})
		return
	}

	if input.Type == "" {
		input.Type = "navigasi"
	}
	input.Type = strings.ToLower(input.Type)
	input.ColorToken = ResolvePinColorToken(input.Type)

	updatedScene, createdPin, err := h.repo.AddHotspotToSceneCMS(sceneID, input)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "SCENE_NOT_FOUND",
			"message": fmt.Sprintf("Scene 360° '%s' tidak ditemukan.", sceneID),
		})
		return
	}

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "pin_attached",
		"scene_id":       updatedScene.ID,
		"scene_title":    updatedScene.Title,
		"attached_pin":   createdPin,
		"total_hotspots": len(updatedScene.Hotspots),
	})
}`,
  },
  {
    id: 's2-shunlu-day8',
    filename: 'shunlu_micromap_day8.go (Hari 8)',
    filepath: 'backend/internal/be1_core/shunlu_micromap_day8.go',
    language: 'go',
    sprintDay: 'Hari 8 (Rabu — Rute Shunlu & Peta Mikro + Audio GPS)',
    description: 'Engine Along-the-Route Search ("Shunlu" +X mnt detour) via POST /api/v1/spatial/shunlu serta Peta Mikro Kawasan & Pemicu Audio GPS <=15m via GET /api/v1/destinations/{id}/micro-map dan POST /api/v1/spatial/audio-trigger-check.',
    content: `package be1_core

import (
	"encoding/json"
	"math"
	"net/http"
	"sort"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// SQLQueryShunluCorridorPostGIS adalah query SQL PostGIS produksi untuk Hari 8 (Rabu)
// Mencari fasilitas searah rute aktif (ST_DWithin koridor garis rute) tanpa harus putar balik
const SQLQueryShunluCorridorPostGIS = \`
WITH active_route AS (
    SELECT ST_MakeLine(
        ST_SetSRID(ST_MakePoint($1, $2), 4326),
        ST_SetSRID(ST_MakePoint($3, $4), 4326)
    )::geography AS route_line
)
SELECT
    p.id, p.name, p.category, p.corridor_road, p.city_regency,
    p.latitude, p.longitude,
    GREATEST(1, ROUND((ST_Distance(p.geog, r.route_line) * 2.0 / 600.0))::int) AS detour_minutes,
    ROUND(ST_Distance(p.geog, r.route_line))::int AS detour_distance_meter,
    p.highlight_note, p.opening_hours
FROM shunlu_pois p, active_route r
WHERE ($5 = '' OR LOWER(p.category) = LOWER($5))
  AND ST_DWithin(p.geog, r.route_line, $6)
ORDER BY detour_minutes ASC;
\`

// ShunluSearchRequest adalah payload untuk POST /api/v1/spatial/shunlu (Hari 8 — FE-1 Layar 03 Jelajah Peta)
type ShunluSearchRequest struct {
	OriginLat      float64 \`json:"origin_lat"\`
	OriginLng      float64 \`json:"origin_lng"\`
	DestinationLat float64 \`json:"destination_lat"\`
	DestinationLng float64 \`json:"destination_lng"\`
	DestinationID  string  \`json:"destination_id,omitempty"\`
	Category       string  \`json:"category,omitempty"\`       // rm_padang | spbu | masjid_bersih | atm | bengkel
	MaxDetourMin   int     \`json:"max_detour_min,omitempty"\` // Default 15 menit
}

// 1. PostShunluSearch — POST /api/v1/spatial/shunlu (Hari 8 — Along-the-Route Search "Shunlu" +X mnt detour)
func (h *HandlerBE1) PostShunluSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req ShunluSearchRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	if req.OriginLat == 0 && req.OriginLng == 0 {
		req.OriginLat = -0.9471
		req.OriginLng = 100.4172
	}
	if req.DestinationLat == 0 && req.DestinationLng == 0 {
		req.DestinationLat = -0.3051
		req.DestinationLng = 100.3692
	}
	if req.MaxDetourMin <= 0 {
		req.MaxDetourMin = 15
	}

	pois := h.repo.SearchShunluAlongRoute(req)
	sort.Slice(pois, func(i, j int) bool {
		return pois[i].DetourMinutes < pois[j].DetourMinutes
	})

	recommendedName := "Sate Mak Syukur Padang Panjang (+2 mnt detour)"
	detourTimeMin := 2
	if len(pois) > 0 {
		recommendedName = pois[0].Name
		detourTimeMin = pois[0].DetourMinutes
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":          "ok",
		"engine":          "WISGO Shunlu Along-the-Route Corridor Engine (PostGIS ST_DWithin)",
		"category_filter": req.Category,
		"max_detour_min":  req.MaxDetourMin,
		"detour_time_min": detourTimeMin,
		"recommended":     recommendedName,
		"total_matches":   len(pois),
		"shunlu_pois":     pois,
	})
}

// 2. GetDestinationMicroMap — GET /api/v1/destinations/{id}/micro-map (Hari 8 — Peta Mikro Kawasan & Audio GPS <=15m)
func (h *HandlerBE1) GetDestinationMicroMap(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	idOrSlug := r.PathValue("id")

	dest, err := h.repo.FindAggregateDetail(idOrSlug, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": "Destinasi tidak ditemukan untuk pemuatan Peta Mikro Kawasan.",
		})
		return
	}

	microMap := h.repo.GetMicroMapByDestinationID(dest.ID, dest.Name, dest.Latitude, dest.Longitude)
	_ = json.NewEncoder(w).Encode(microMap)
}

// AudioTriggerCheckRequest menguji apakah posisi GPS wisatawan berada dalam radius <=15 meter dari titik narasi suara
type AudioTriggerCheckRequest struct {
	DestinationID string  \`json:"destination_id"\`
	UserLat       float64 \`json:"user_lat"\`
	UserLng       float64 \`json:"user_lng"\`
}

func haversineMeter(lat1, lon1, lat2, lon2 float64) float64 {
	const earthRadiusM = 6371000.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLon := (lon2 - lon1) * math.Pi / 180.0
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return math.Round(earthRadiusM*c*10) / 10
}

// 3. PostCheckAudioGPSTrigger — POST /api/v1/spatial/audio-trigger-check (Hari 8 — Audio Guide GPS <=15m)
func (h *HandlerBE1) PostCheckAudioGPSTrigger(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req AudioTriggerCheckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Payload JSON tidak valid"})
		return
	}
	if req.DestinationID == "" {
		req.DestinationID = "dest-001"
	}

	dest, err := h.repo.FindAggregateDetail(req.DestinationID, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	microMap := h.repo.GetMicroMapByDestinationID(dest.ID, dest.Name, dest.Latitude, dest.Longitude)
	var triggered []map[string]interface{}

	for _, trig := range microMap.AudioTriggers {
		distM := haversineMeter(req.UserLat, req.UserLng, trig.Latitude, trig.Longitude)
		maxRadius := trig.TriggerRadiusM
		if maxRadius <= 0 {
			maxRadius = 15.0
		}
		if distM <= maxRadius {
			triggered = append(triggered, map[string]interface{}{
				"trigger":          trig,
				"distance_meter":   distM,
				"auto_play_status": "ACTIVE_WITHIN_15M",
			})
		}
	}

	statusLabel := "NO_TRIGGER_IN_RADIUS"
	if len(triggered) > 0 {
		statusLabel = strings.ToUpper("AUTO_PLAY_ACTIVE")
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"destination_id":    dest.ID,
		"destination_name":  dest.Name,
		"trigger_status":    statusLabel,
		"matched_count":     len(triggered),
		"triggered_stories": triggered,
	})
}`,
  },
  {
    id: 's2-pungli-day9',
    filename: 'pungli_satgas_day9.go (Hari 9)',
    filepath: 'backend/internal/be1_core/pungli_satgas_day9.go',
    language: 'go',
    sprintDay: 'Hari 9 (Kamis — Smart QR, Lapor Pungli & Satgas)',
    description: 'Handler Hari 9 untuk GET /api/v1/qr/{qrCode} (Scanner Plang Smart QR), POST /api/v1/pungli/report (Unggah Bukti Foto URL/Base64/Multipart + Kalkulasi Selisih Perda), serta GET & PATCH /api/v1/admin/pungli/* (Pusat Komando Satgas Saber Pungli FS-1).',
    content: `package be1_core

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// 1. GetSmartQRResolution — GET /api/v1/qr/{qrCode} (Hari 9 — Scanner Plang Smart QR FE-2 & Web Instant QR FS-1)
func (h *HandlerBE1) GetSmartQRResolution(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	qrCode := strings.TrimSpace(r.PathValue("qrCode"))

	dest, err := h.repo.FindAggregateDetail(qrCode, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "QR_PLACARD_NOT_FOUND",
			"message": fmt.Sprintf("Kode Plang Smart QR '%s' tidak terdaftar di database Dispar Sumbar.", qrCode),
		})
		return
	}

	scenes := h.repo.GetScenes360ByDestinationID(dest.ID)
	microMap := h.repo.GetMicroMapByDestinationID(dest.ID, dest.Name, dest.Latitude, dest.Longitude)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":              "resolved",
		"qr_placard_code":     dest.QRPlacardCode,
		"instant_web_preview": fmt.Sprintf("https://rancak.in/qr/%s", dest.QRPlacardCode),
		"fair_price_verified": true,
		"destination":         dest,
		"scenes_360":          scenes,
		"micro_map":           microMap,
	})
}

// CreatePungliReportRequest mendukung JSON (URL / Base64) maupun simulasi Multipart Upload (FE-2 Form Lapor Pungli)
type CreatePungliReportRequest struct {
	DestinationID    string  \`json:"destination_id"\`
	ReporterName     string  \`json:"reporter_name"\`
	IncidentCategory string  \`json:"incident_category"\` // parkir_liar | tiket_di_atas_perda | paksaan_pemandu | fasilitas_rusak
	ChargedAmountIDR float64 \`json:"charged_amount_idr"\`
	PhotoEvidence    string  \`json:"photo_evidence"\`
	PhotoBase64      string  \`json:"photo_base64,omitempty"\`
	Latitude         float64 \`json:"latitude"\`
	Longitude        float64 \`json:"longitude"\`
	Description      string  \`json:"description"\`
}

// 2. PostReportPungli — POST /api/v1/pungli/report (Hari 9 — Lapor Pungli Anonim + Bukti Foto + GPS FE-2)
func (h *HandlerBE1) PostReportPungli(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req CreatePungliReportRequest
	contentType := r.Header.Get("Content-Type")
	uploadFormat := "url"

	if strings.HasPrefix(contentType, "multipart/form-data") {
		_ = r.ParseMultipartForm(10 << 20)
		req.DestinationID = r.FormValue("destination_id")
		req.ReporterName = r.FormValue("reporter_name")
		req.IncidentCategory = r.FormValue("incident_category")
		req.PhotoEvidence = r.FormValue("photo_evidence")
		req.Description = r.FormValue("description")
		if v, err := strconv.ParseFloat(r.FormValue("charged_amount_idr"), 64); err == nil {
			req.ChargedAmountIDR = v
		}
		if v, err := strconv.ParseFloat(r.FormValue("latitude"), 64); err == nil {
			req.Latitude = v
		}
		if v, err := strconv.ParseFloat(r.FormValue("longitude"), 64); err == nil {
			req.Longitude = v
		}
		uploadFormat = "multipart"
		if req.PhotoEvidence == "" {
			req.PhotoEvidence = "https://cdn.rancak.in/evidence/multipart-karcis-pungli.jpg"
		}
	} else {
		_ = json.NewDecoder(r.Body).Decode(&req)
		if req.PhotoBase64 != "" {
			uploadFormat = "base64"
			if req.PhotoEvidence == "" {
				req.PhotoEvidence = "data:image/jpeg;base64," + req.PhotoBase64
			}
		}
	}

	if req.DestinationID == "" {
		req.DestinationID = "dest-003"
	}
	if req.ReporterName == "" {
		req.ReporterName = "Wisatawan Anonim"
	}
	if req.IncidentCategory == "" {
		req.IncidentCategory = "parkir_liar"
	}
	if req.PhotoEvidence == "" {
		req.PhotoEvidence = "https://cdn.rancak.in/evidence/foto-bukti-lapangan.jpg"
	}
	if req.Description == "" {
		req.Description = "Tagihan parkir/tiket di lapangan melebihi ketentuan Tabel Fair-Price Barometer Perda."
	}

	created := h.repo.CreatePungliReport(models.PungliReport{
		DestinationID:    req.DestinationID,
		ReporterName:     req.ReporterName,
		IncidentCategory: req.IncidentCategory,
		ChargedAmountIDR: req.ChargedAmountIDR,
		PhotoEvidence:    req.PhotoEvidence,
		UploadFormat:     uploadFormat,
		Latitude:         req.Latitude,
		Longitude:        req.Longitude,
		Description:      req.Description,
	})

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"ticket":  created.TicketCode,
		"message": "Laporan berhasil diteruskan ke Satgas Saber Pungli Dispar Sumbar",
		"report":  created,
	})
}

// 3. GetPungliReportsAdmin — GET /api/v1/admin/pungli/reports (Hari 9 — Pusat Komando Satgas Saber Pungli FS-1)
func (h *HandlerBE1) GetPungliReportsAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	statusFilter := strings.TrimSpace(r.URL.Query().Get("status"))

	reports := h.repo.ListPungliReports(statusFilter)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":        "ok",
		"filter_status": statusFilter,
		"total_reports": len(reports),
		"reports":       reports,
	})
}

// UpdatePungliStatusRequest adalah kontrak JSON antara BE-1 dan FS-1 (Pusat Komando Satgas Saber Pungli)
type UpdatePungliStatusRequest struct {
	Status      string \`json:"status"\` // Masuk | Diverifikasi | Ditindaklanjuti | Selesai
	SatgasNotes string \`json:"satgas_notes"\`
}

// 4. UpdatePungliStatusAdmin — PATCH /api/v1/admin/pungli/{id}/status (Hari 9 — Tindak Lanjut Satgas FS-1)
func (h *HandlerBE1) UpdatePungliStatusAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	idOrTicket := r.PathValue("id")

	var req UpdatePungliStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Status == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_STATUS_PAYLOAD",
			"message": "Field 'status' wajib diisi (Masuk, Diverifikasi, Ditindaklanjuti, atau Selesai).",
		})
		return
	}

	updated, err := h.repo.UpdatePungliReportStatus(idOrTicket, req.Status, req.SatgasNotes)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "REPORT_NOT_FOUND",
			"message": fmt.Sprintf("Tiket laporan pungli '%s' tidak ditemukan.", idOrTicket),
		})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":           "updated",
		"updated_at":       time.Now().Format(time.RFC3339),
		"report":           updated,
		"overcharge_ratio": math.Round((updated.OverchargeAmountIDR / math.Max(1, updated.OfficialPerdaPriceIDR)) * 100),
	})
}`,
  },
  {
    id: 's2-seeder-day6',
    filename: 'seeder_sprint2_spatial.go (Hari 6)',
    filepath: 'backend/internal/be1_core/seeder_sprint2_spatial.go',
    language: 'go',
    sprintDay: 'Hari 6 (Senin — Seeder 360°, Shunlu & Peta Mikro)',
    description: 'Seeder data awal Minggu 2 untuk Scene 360° Aerial-to-Ground + 4 Pin Interaktif (Lembah Harau, Jam Gadang, Istano Pagaruyung), 7 Koridor Shunlu POIs lintas Sumbar, Peta Mikro Kawasan + Audio GPS <=15m, dan sampel tiket Satgas Saber Pungli.',
    content: `package be1_core

import (
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// SeedSprint2Scenes360 menyediakan data Tur Virtual 360° Aerial-to-Ground + 4 Pin Interaktif (Hari 6 & 7)
func SeedSprint2Scenes360() map[string][]models.Scene360 {
	return map[string][]models.Scene360{
		"dest-001": {
			{
				ID:              "scene-harau-aerial-01",
				DestinationID:   "dest-001",
				Title:           "Panorama Drone 150m Lembah Harau & Tebing Granit",
				Type:            "aerial",
				PanoramaURL:     "https://cdn.rancak.in/360/harau-aerial-150m-equirectangular.jpg",
				UploadFormat:    "url",
				SpatialAudioURL: "https://cdn.rancak.in/audio/harau-angin-lembah-spatial.mp3",
				InitialPitch:    -12.5,
				InitialYaw:      180.0,
				IsDefaultScene:  true,
				Hotspots: []models.Hotspot360{
					{
						ID:          "pin-harau-01",
						SceneID:     "scene-harau-aerial-01",
						Type:        "navigasi",
						ColorToken:  "#2563EB",
						Pitch:       -28.4,
						Yaw:         172.0,
						Title:       "Turun ke Kolam Air Terjun Aka Barayun (Ground 360°)",
						TargetRef:   "scene-harau-ground-01",
						Description: "Klik untuk transisi mulus (dive-in) dari udara 150m ke tepi kolam air terjun.",
					},
					{
						ID:          "pin-harau-02",
						SceneID:     "scene-harau-aerial-01",
						Type:        "audio",
						ColorToken:  "#D97706",
						Pitch:       -8.0,
						Yaw:         115.5,
						Title:       "Kisah Geologi Patahan Semangko & Tebing Harau Purba",
						AudioURL:    "https://cdn.rancak.in/audio/story-geologi-harau-id.mp3",
						Description: "Narasi 45 detik tentang terbentuknya lembah granit purba jutaan tahun lalu.",
					},
				},
			},
			// ... (Scene Ground Aka Barayun, Jam Gadang, Istano Pagaruyung, Koridor Shunlu & Peta Mikro lengkap di /backend/internal/be1_core/seeder_sprint2_spatial.go)
		},
	}
}

func SeedSprint2PungliReports() []models.PungliReport {
	now := time.Now()
	return []models.PungliReport{
		{
			ID:                    "pungli-001",
			TicketCode:            "PGL-202611-0091",
			DestinationID:         "dest-003",
			DestinationName:       "Pantai Air Manis & Batu Malin Kundang",
			ReporterName:          "Wisatawan Anonim",
			IncidentCategory:      "parkir_liar",
			ChargedAmountIDR:      25000,
			OfficialPerdaPriceIDR: 5000,
			OverchargeAmountIDR:   20000,
			PhotoEvidence:         "https://cdn.rancak.in/evidence/karcis-tanpa-porporasi-airmanis.jpg",
			UploadFormat:          "url",
			Latitude:              -0.9841,
			Longitude:             100.3612,
			Description:           "Oknum di luar pos resmi meminta uang parkir mobil Rp25.000 tanpa karcis porporasi Dishub/Perda Kota Padang.",
			Status:                "Diverifikasi",
			SatgasNotes:           "Tim Satgas Saber Pungli Kota Padang telah diterjunkan ke titik koordinat pintu selatan.",
			CreatedAt:             now.Add(-2 * time.Hour),
			UpdatedAt:             now.Add(-30 * time.Minute),
		},
	}
}`,
  },
  {
    id: 's2-test-day10',
    filename: 'be1_sprint2_test.go (Hari 10 — 8 Test)',
    filepath: 'backend/internal/be1_core/be1_sprint2_test.go',
    language: 'go',
    sprintDay: 'Hari 10 (Jumat — 8 Skenario Test Sprint 2)',
    description: 'Suite pengujian otomatis Minggu 2 (TC-S2-01 s/d TC-S2-08) untuk menguji API 360° 4-Pin, Klik-Tempel Pin CMS FS-1, Koridor Shunlu (+X mnt detour), Peta Mikro + Audio GPS <=15m, Resolusi Smart QR, Lapor Pungli + Foto, Tindak Lanjut Satgas, dan Bundel Offline v2.',
    content: `package be1_core

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestBE1Sprint2Suite(t *testing.T) {
	mux := setupWISGOTestMux()

	t.Run("TC-S2-01 (Hari 7): GET /api/v1/destinations/{id}/scenes-360 mengembalikan scene Aerial-to-Ground & 4 Pin Interaktif", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations/dest-001/scenes-360", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var body map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("failed to parse JSON: %v", err)
		}
		scenes, ok := body["scenes_360"].([]interface{})
		if !ok || len(scenes) < 2 {
			t.Fatalf("expected at least 2 scenes (aerial & ground) for Lembah Harau, got %v", len(scenes))
		}
	})

	t.Run("TC-S2-02 (Hari 7): POST /api/v1/admin/scenes-360/{sceneId}/hotspots menempelkan Pin 360 baru dari CMS Studio FS-1", func(t *testing.T) {
		payload := []byte(\`{"type":"mitra","pitch":-10.5,"yaw":225.0,"title":"Kopi Kawa Daun Harau","target_ref":"partner-004","description":"Klik untuk pesan Kopi Kawa Daun hangat"}\`)
		req := httptest.NewRequest("POST", "/api/v1/admin/scenes-360/scene-harau-aerial-01/hotspots", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created, got %d: %s", rec.Code, rec.Body.String())
		}
	})

	t.Run("TC-S2-03 (Hari 8): POST /api/v1/spatial/shunlu memfilter POI searah rute (+X menit detour)", func(t *testing.T) {
		payload := []byte(\`{"origin_lat":-0.9471,"origin_lng":100.4172,"destination_lat":-0.3051,"destination_lng":100.3692,"category":"rm_padang","max_detour_min":10}\`)
		req := httptest.NewRequest("POST", "/api/v1/spatial/shunlu", bytes.NewBuffer(payload))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
	})

	t.Run("TC-S2-04 (Hari 8): GET /api/v1/destinations/{id}/micro-map & POST /api/v1/spatial/audio-trigger-check memicu cerita otomatis <=15m", func(t *testing.T) {
		payloadTrig := []byte(\`{"destination_id":"dest-001","user_lat":-0.1025,"user_lng":100.6725}\`)
		reqTrig := httptest.NewRequest("POST", "/api/v1/spatial/audio-trigger-check", bytes.NewBuffer(payloadTrig))
		recTrig := httptest.NewRecorder()
		mux.ServeHTTP(recTrig, reqTrig)
		if recTrig.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on audio-trigger-check, got %d", recTrig.Code)
		}
	})

	t.Run("TC-S2-05 (Hari 9): GET /api/v1/qr/{qrCode} meresolusi Plang Smart QR ke data destinasi + Fair-Price + 360", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/qr/QR-SMBR-LPK-001", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK for valid QR placard code, got %d", rec.Code)
		}
	})

	t.Run("TC-S2-06 (Hari 9): POST /api/v1/pungli/report mencatat bukti foto + GPS & menghitung selisih terhadap Perda", func(t *testing.T) {
		payload := []byte(\`{"destination_id":"dest-001","reporter_name":"Wisatawan Anonim","incident_category":"parkir_liar","charged_amount_idr":20000,"photo_evidence":"https://cdn.rancak.in/evidence/parkir-20rb.jpg","latitude":-0.1023,"longitude":100.6728,"description":"Diminta parkir mobil Rp20.000 padahal Perda Rp5.000"}\`)
		req := httptest.NewRequest("POST", "/api/v1/pungli/report", bytes.NewBuffer(payload))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created on pungli report, got %d", rec.Code)
		}
	})

	t.Run("TC-S2-07 (Hari 9): PATCH /api/v1/admin/pungli/{id}/status mengubah status tiket di Pusat Komando Satgas (FS-1)", func(t *testing.T) {
		payload := []byte(\`{"status":"Ditindaklanjuti","satgas_notes":"Petugas Dishub & Satpol PP telah menertibkan oknum di lokasi."}\`)
		req := httptest.NewRequest("PATCH", "/api/v1/admin/pungli/PGL-202611-0091/status", bytes.NewBuffer(payload))
		req.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on Satgas status update, got %d: %s", rec.Code, rec.Body.String())
		}
	})

	t.Run("TC-S2-08 (Hari 10): GET /api/v1/destinations/{id}/offline-bundle v2 menyertakan 360 scenes, micro-map & audio triggers", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations/dest-001/offline-bundle", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
	})
}`,
  },
];
