package be1_core

import (
	"encoding/json"
	"math"
	"net/http"
	"sort"
	"strings"
)

// SQLQueryShunluCorridorPostGIS adalah query SQL PostGIS produksi untuk Hari 8 (Rabu)
// Mencari fasilitas searah rute aktif (ST_DWithin koridor garis rute) tanpa harus putar balik
const SQLQueryShunluCorridorPostGIS = `
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
`

// ShunluSearchRequest adalah payload untuk POST /api/v1/spatial/shunlu (Hari 8 — FE-1 Layar 03 Jelajah Peta)
type ShunluSearchRequest struct {
	OriginLat      float64 `json:"origin_lat"`
	OriginLng      float64 `json:"origin_lng"`
	DestinationLat float64 `json:"destination_lat"`
	DestinationLng float64 `json:"destination_lng"`
	DestinationID  string  `json:"destination_id,omitempty"`
	Category       string  `json:"category,omitempty"`       // rm_padang | spbu | masjid_bersih | atm | bengkel
	MaxDetourMin   int     `json:"max_detour_min,omitempty"` // Default 15 menit
}

// 1. PostShunluSearch — POST /api/v1/spatial/shunlu (Hari 8 — Along-the-Route Search "Shunlu" +X mnt detour)
func (h *HandlerBE1) PostShunluSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req ShunluSearchRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	// Default rute aktif: Kota Padang (-0.9471, 100.4172) -> Bukittinggi / Lembah Harau
	if req.OriginLat == 0 && req.OriginLng == 0 {
		req.OriginLat = -0.9471
		req.OriginLng = 100.4172
	}
	if req.DestinationLat == 0 && req.DestinationLng == 0 {
		if req.DestinationID != "" {
			if dest, err := h.repo.FindAggregateDetail(req.DestinationID, false, 0, 0); err == nil {
				req.DestinationLat = dest.Latitude
				req.DestinationLng = dest.Longitude
			}
		}
		if req.DestinationLat == 0 && req.DestinationLng == 0 {
			req.DestinationLat = -0.3051
			req.DestinationLng = 100.3692
		}
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
	DestinationID string  `json:"destination_id"`
	UserLat       float64 `json:"user_lat"`
	UserLng       float64 `json:"user_lng"`
}

// haversineMeter menghitung jarak presisi dalam satuan meter untuk pemicu Audio GPS <=15m
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
}
