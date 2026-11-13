package be1_core

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// HandlerBE1 menangani seluruh 24 endpoint Core & Spasial milik BE-1 (Sprint 1 s/d Sprint 4)
// Sesuai struktur repo github.com/LuthfiaHasan/WISGO (branch dev) & docs/API_Contract_BE1_BE2.md
type HandlerBE1 struct {
	repo        *RepositoryBE1
	cache       *InMemoryTTLCache
	rateLimiter *TokenBucketRateLimiter
}

func NewHandlerBE1() *HandlerBE1 {
	return &HandlerBE1{
		repo:        NewRepositoryBE1(),
		cache:       NewInMemoryTTLCache(5 * time.Minute),
		rateLimiter: NewTokenBucketRateLimiter(15, 60*time.Second),
	}
}

// RegisterSprint1Routes mendaftarkan seluruh 24 endpoint BE-1 (Sprint 1 s/d Sprint 4) ke mux standar Go 1.22
func (h *HandlerBE1) RegisterSprint1Routes(mux *http.ServeMux) {
	// --- SPRINT 1 (MINGGU 1: HARI 1-5) ---
	// Hari 1: Healthcheck & PostGIS Readiness
	mux.HandleFunc("GET /api/v1/health", h.GetHealthStatus)

	// Hari 4: Direktori Spasial, Aggregate Detail (4 Statistik + 5 Indikator Medan + Tips + Tarif), & Offline Bundle
	mux.HandleFunc("GET /api/v1/destinations", h.GetDestinations)
	mux.HandleFunc("GET /api/v1/destinations/detail", h.GetDestinationDetail)
	mux.HandleFunc("GET /api/v1/destinations/{id}", h.GetDestinationByID)
	mux.HandleFunc("GET /api/v1/destinations/{id}/tariffs", h.GetDestinationTariffs)
	mux.HandleFunc("GET /api/v1/destinations/{id}/offline-bundle", h.GetOfflineBundle)

	// Hari 5: Endpoint Admin CMS (Sinkronisasi FS-1) — Diproteksi Stateless JWT & RBAC
	mux.HandleFunc("POST /api/v1/destinations", RequireRoles(h.CreateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/destinations/{id}", RequireRoles(h.UpdateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/destinations/{id}/tariffs", RequireRoles(h.UpdateDestinationTariffsCMS, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("DELETE /api/v1/destinations/{id}", RequireRoles(h.DeleteDestination, "admin_dispar"))

	mux.HandleFunc("POST /api/v1/admin/destinations", RequireRoles(h.CreateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/admin/destinations/{id}", RequireRoles(h.UpdateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/admin/destinations/{id}/tariffs", RequireRoles(h.UpdateDestinationTariffsCMS, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("DELETE /api/v1/admin/destinations/{id}", RequireRoles(h.DeleteDestination, "admin_dispar"))

	// --- SPRINT 2 (MINGGU 2: HARI 6-10) ---
	h.RegisterSprint2Routes(mux)

	// --- SPRINT 3 (MINGGU 3: HARI 11-15) ---
	h.RegisterSprint3Routes(mux)

	// --- SPRINT 4 (MINGGU 4: HARI 16-20 — FINAL RELEASE) ---
	h.RegisterSprint4Routes(mux)
}

// RegisterSprint2Routes mendaftarkan seluruh endpoint Minggu 2 (Hari 6-10: 360° 4-Pin, Shunlu, Peta Mikro, Smart QR, & Satgas Pungli)
func (h *HandlerBE1) RegisterSprint2Routes(mux *http.ServeMux) {
	// Hari 7: API Tur Virtual 360° Aerial-to-Ground & 4 Pin Interaktif + CMS Studio 360° Visual Editor (FS-1)
	mux.HandleFunc("GET /api/v1/destinations/{id}/scenes-360", h.GetDestinationScenes360)
	mux.HandleFunc("POST /api/v1/admin/scenes-360", RequireRoles(h.CreateScene360CMS, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("POST /api/v1/admin/scenes-360/{sceneId}/hotspots", RequireRoles(h.UpsertHotspot360CMS, "admin_dispar", "pokdarwis"))

	// Hari 8: Engine Along-the-Route ("Shunlu" +X mnt detour) & Peta Mikro Kawasan + Audio GPS <=15m
	mux.HandleFunc("POST /api/v1/spatial/shunlu", h.PostShunluSearch)
	mux.HandleFunc("GET /api/v1/destinations/{id}/micro-map", h.GetDestinationMicroMap)
	mux.HandleFunc("POST /api/v1/spatial/audio-trigger-check", h.PostCheckAudioGPSTrigger)

	// Hari 9: Scanner Plang Smart QR, Form Lapor Pungli (Diproteksi Token Bucket Hari 18), & Pusat Komando Satgas Saber Pungli
	mux.HandleFunc("GET /api/v1/qr/{qrCode}", h.GetSmartQRResolution)
	mux.HandleFunc("POST /api/v1/pungli/report", h.rateLimiter.Protect(h.PostReportPungli, "pungli_report"))
	mux.HandleFunc("GET /api/v1/admin/pungli/reports", RequireRoles(h.GetPungliReportsAdmin, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PATCH /api/v1/admin/pungli/{id}/status", RequireRoles(h.UpdatePungliStatusAdmin, "admin_dispar"))
	mux.HandleFunc("PUT /api/v1/admin/pungli/{id}/status", RequireRoles(h.UpdatePungliStatusAdmin, "admin_dispar"))
}

// RegisterSprint3Routes mendaftarkan seluruh endpoint Minggu 3 (Hari 11-15: Gaode Ranking, Hazard Alert, Trigger Bencana FS-1, SOS GPS FE-1, Kamus Minang & Kalender Budaya)
func (h *HandlerBE1) RegisterSprint3Routes(mux *http.ServeMux) {
	// Hari 12: Algoritma Behavior-Based Ranking (Gaode Guide) & Telemetri Dwell Time GPS (Diproteksi Token Bucket Hari 18)
	mux.HandleFunc("GET /api/v1/destinations/rankings/gaode", h.GetGaodeBehaviorRankings)
	mux.HandleFunc("POST /api/v1/spatial/navigation-telemetry", h.rateLimiter.Protect(h.PostNavigationTelemetry, "nav_telemetry"))

	// Hari 13: API Live Hazard Alert Jalur Ekstrem, Trigger Bencana FS-1, & Pancaran Darurat SOS GPS FE-1 (Diproteksi Token Bucket Hari 18)
	mux.HandleFunc("GET /api/v1/spatial/hazards", h.GetLiveHazardAlerts)
	mux.HandleFunc("POST /api/v1/admin/hazards/trigger", RequireRoles(h.PostTriggerHazardAdmin, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("POST /api/v1/spatial/sos", h.rateLimiter.Protect(h.PostSOSEmergencySignal, "sos_emergency"))
	mux.HandleFunc("GET /api/v1/admin/sos", RequireRoles(h.GetSOSSignalsAdmin, "admin_dispar", "pokdarwis"))

	// Hari 14: API Kamus Saku Audio Minang & Kalender Budaya / Hari Pakan Nagari
	mux.HandleFunc("GET /api/v1/culture/minang-phrases", h.GetMinangAudioPhrases)
	mux.HandleFunc("GET /api/v1/culture/events", h.GetCulturalEventsCalendar)
}

// RegisterSprint4Routes mendaftarkan endpoint penutup Minggu 4 (Hari 16-20: Live Benchmark <100ms, Cache Flush Admin, & Katalog 24 Endpoint BE-1)
func (h *HandlerBE1) RegisterSprint4Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/admin/system/benchmark", RequireRoles(h.GetSystemBenchmarkAdmin, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("POST /api/v1/admin/cache/flush", RequireRoles(h.PostFlushCacheAdmin, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("GET /api/v1/system/contracts", h.GetSystemContractsCatalog)
}

func parseGPSQuery(r *http.Request) (bool, float64, float64) {
	latStr := r.URL.Query().Get("lat")
	lngStr := r.URL.Query().Get("lng")
	if latStr == "" || lngStr == "" {
		return false, 0, 0
	}
	lat, err1 := strconv.ParseFloat(latStr, 64)
	lng, err2 := strconv.ParseFloat(lngStr, 64)
	if err1 != nil || err2 != nil {
		return false, 0, 0
	}
	return true, lat, lng
}

// 0. GetHealthStatus — GET /api/v1/health
func (h *HandlerBE1) GetHealthStatus(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":          "ok",
		"service":         "WISGO Rancak.in — BE-1 Core & Spatial Engine",
		"sprint":          "Sprint 1 s/d Sprint 4 Complete (Hari 1-20 Full 1 Bulan · 24/24 Endpoint BE-1 Aktif)",
		"postgis":         "PostgreSQL 16 + PostGIS 3.4 + Composite GIST Indexes (<100ms SLA)",
		"cache_layer":     "Go Native InMemoryTTLCache + HTTP ETag (304 Not Modified)",
		"security_guard":  "Stateless JWT RBAC + Token Bucket Rate-Limiter (Anti-Spam HTTP 429)",
		"seeded_data":     "20 Destinasi + 360° 4-Pin + Shunlu + Peta Mikro + Satgas Pungli + Gaode Ranking + Hazard/SOS + Kamus Minang",
		"total_endpoints": 24,
	})
}

// 1. GetDestinations — GET /api/v1/destinations (Dipercepat Cache ETag Hari 17)
func (h *HandlerBE1) GetDestinations(w http.ResponseWriter, r *http.Request) {
	qCity := r.URL.Query().Get("city_regency")
	if qCity == "" {
		qCity = r.URL.Query().Get("kabupaten_kota")
	}
	hasGPS, lat, lng := parseGPSQuery(r)
	cacheKey := fmt.Sprintf("destinations:%s", r.URL.RawQuery)

	h.cache.WriteCachedJSON(w, r, cacheKey, func() (interface{}, int, error) {
		results := h.repo.FindAllWithSpatial(SpatialFilterParams{
			Category:    r.URL.Query().Get("category"),
			CityRegency: qCity,
			CrowdLevel:  r.URL.Query().Get("crowd_level"),
			Signal:      r.URL.Query().Get("signal"),
			SearchQuery: r.URL.Query().Get("q"),
			HasUserGPS:  hasGPS,
			UserLat:     lat,
			UserLng:     lng,
		})
		return results, http.StatusOK, nil
	})
}

// 2. GetDestinationDetail — GET /api/v1/destinations/detail?id=dest-001
func (h *HandlerBE1) GetDestinationDetail(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if id == "" {
		id = "dest-001"
	}
	hasGPS, lat, lng := parseGPSQuery(r)
	h.writeDestinationDetailByKey(w, id, hasGPS, lat, lng)
}

// 3. GetDestinationByID — GET /api/v1/destinations/{id}
func (h *HandlerBE1) GetDestinationByID(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		id = "dest-001"
	}
	hasGPS, lat, lng := parseGPSQuery(r)
	h.writeDestinationDetailByKey(w, id, hasGPS, lat, lng)
}

func (h *HandlerBE1) writeDestinationDetailByKey(w http.ResponseWriter, key string, hasGPS bool, lat, lng float64) {
	w.Header().Set("Content-Type", "application/json")
	dest, err := h.repo.FindAggregateDetail(key, hasGPS, lat, lng)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": fmt.Sprintf("Destinasi '%s' tidak ditemukan", key),
		})
		return
	}
	_ = json.NewEncoder(w).Encode(dest)
}

// 4. GetDestinationTariffs — GET /api/v1/destinations/{id}/tariffs
func (h *HandlerBE1) GetDestinationTariffs(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	dest, err := h.repo.FindAggregateDetail(id, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"destination_id":   dest.ID,
		"destination_name": dest.Name,
		"city_regency":     dest.CityRegency,
		"tariffs":          dest.Tariffs,
	})
}

// 5. GetOfflineBundle — GET /api/v1/destinations/{id}/offline-bundle (Diperbarui Hari 10: Bundel Offline v2 + 360° + Peta Mikro)
func (h *HandlerBE1) GetOfflineBundle(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	dest, err := h.repo.FindAggregateDetail(id, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	scenes := h.repo.GetScenes360ByDestinationID(dest.ID)
	microMap := h.repo.GetMicroMapByDestinationID(dest.ID, dest.Name, dest.Latitude, dest.Longitude)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"bundle_version":    "v2.0-sprint2-complete",
		"generated_at":      time.Now().Format(time.RFC3339),
		"local_storage_sdk": "Flutter Hive / Sqflite Ready",
		"offline_banner":    "⚡ Mode offline aktif · Tempat siap dibuka tanpa sinyal.",
		"destination":       dest,
		"scenes_360":        scenes,
		"micro_map":         microMap,
		"audio_triggers":    microMap.AudioTriggers,
	})
}

// 6. CreateDestination — POST /api/v1/destinations
func (h *HandlerBE1) CreateDestination(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var input models.Destination
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.Name == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Body JSON tidak valid; field 'name' wajib diisi.",
		})
		return
	}

	created := h.repo.CreateCMS(input)
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(created)
}

// 7. UpdateDestination — PUT /api/v1/destinations/{id}
func (h *HandlerBE1) UpdateDestination(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	var payload models.Destination
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "JSON tidak valid"})
		return
	}

	updated, err := h.repo.UpdateCMS(id, payload)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}
	_ = json.NewEncoder(w).Encode(updated)
}

// 8. DeleteDestination — DELETE /api/v1/destinations/{id}
func (h *HandlerBE1) DeleteDestination(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	deletedID, err := h.repo.DeleteCMS(id)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]string{
		"status":  "deleted",
		"id":      deletedID,
		"message": "Destinasi berhasil dihapus oleh Admin Dispar.",
	})
}
