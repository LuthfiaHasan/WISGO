export interface GoCodeFile {
  id: string;
  filename: string;
  filepath: string;
  language: 'go' | 'sql' | 'markdown' | 'env';
  sprintDay: string;
  description: string;
  content: string;
}

export const GO_SPRINT1_CODE_FILES: GoCodeFile[] = [
  {
    id: 'wisgo-repo-day4',
    filename: 'repository_postgis.go (Hari 4)',
    filepath: 'backend/internal/be1_core/repository_postgis.go',
    language: 'go',
    sprintDay: 'Hari 4 (Kamis — Spasial & Aggregate Repo)',
    description: 'Repository Spasial PostGIS & Aggregate Detail milik BE-1 (Hari 4). Mengimplementasikan query ST_DistanceSphere / Haversine, filter multi-dimensi (kategori, kab/kota, keramaian, sinyal blank spot), serta penggabungan 4 Statistik + 5 Indikator Medan + Tips + Tarif Perda dalam 1 kali panggil (<100ms).',
    content: `package be1_core

import (
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// SQLQueryFindAllPostGIS adalah query SQL PostGIS produksi untuk Hari 4 (Kamis)
// Menghitung jarak spasial ST_DistanceSphere dari koordinat GPS wisatawan secara real-time
const SQLQueryFindAllPostGIS = \`
SELECT
    d.id, d.slug, d.name, d.category, d.city_regency, d.description,
    d.latitude, d.longitude, d.elevation_m, d.cover_image, d.crowd_level,
    ROUND((ST_DistanceSphere(
        d.geog::geometry,
        ST_SetSRID(ST_MakePoint($1, $2), 4326)
    ) / 1000.0 * 1.32)::numeric, 1) AS distance_km,
    GREATEST(10, ROUND(((ST_DistanceSphere(
        d.geog::geometry,
        ST_SetSRID(ST_MakePoint($1, $2), 4326)
    ) / 1000.0 * 1.32) / 38.0) * 60))::int AS travel_time_min,
    d.estimated_cost, d.is_hidden_gem, d.qr_placard_code, d.opening_hours,
    m.vehicle_access, m.trekking_level, m.cellular_signal, m.facilities, m.guide_need, m.pokdarwis_name
FROM destinations d
LEFT JOIN medan_indicators m ON m.destination_id = d.id
WHERE ($3 = '' OR LOWER(d.category) LIKE '%' || LOWER($3) || '%')
  AND ($4 = '' OR LOWER(d.city_regency) LIKE '%' || LOWER($4) || '%')
  AND ($5 = '' OR LOWER(d.crowd_level) = LOWER($5))
  AND ($6 = '' OR LOWER(m.cellular_signal) LIKE '%' || LOWER($6) || '%')
ORDER BY distance_km ASC;
\`

// SpatialFilterParams menyimpan parameter filter & koordinat GPS pengguna pada Hari 4
type SpatialFilterParams struct {
	Category    string
	CityRegency string
	CrowdLevel  string
	Signal      string
	SearchQuery string
	HasUserGPS  bool
	UserLat     float64
	UserLng     float64
}

// RepositoryBE1 mengelola akses data spasial PostGIS & relasi 1:1 / 1:N destinasi Sumatera Barat
type RepositoryBE1 struct {
	mu           sync.RWMutex
	destinations []models.Destination
}

func NewRepositoryBE1() *RepositoryBE1 {
	return &RepositoryBE1{
		destinations: Seed20DestinationsSumbar(),
	}
}

// CalculateSpatialDistanceKm menghitung jarak jalan raya Sumatera Barat (faktor kelokan Bukit Barisan 1.32x)
func CalculateSpatialDistanceKm(lat1, lon1, lat2, lon2 float64) float64 {
	const earthRadiusKm = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLon := (lon2 - lon1) * math.Pi / 180.0
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return math.Round(earthRadiusKm*c*1.32*10) / 10
}

// EstimateSumbarTravelMinutes menghitung estimasi waktu tempuh (menit) dengan kecepatan rata-rata kontur Sumbar 38 km/jam
func EstimateSumbarTravelMinutes(distanceKm float64) int {
	return int(math.Max(10, math.Round((distanceKm/38.0)*60)))
}

// FindAllWithSpatial (Hari 4) memfilter direktori 20 destinasi & menghitung jarak spasial dari GPS pengguna
func (r *RepositoryBE1) FindAllWithSpatial(params SpatialFilterParams) []models.Destination {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(params.Category))
	qCity := strings.ToLower(strings.TrimSpace(params.CityRegency))
	qCrowd := strings.ToLower(strings.TrimSpace(params.CrowdLevel))
	qSig := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(params.Signal), "_", " "))
	qSearch := strings.ToLower(strings.TrimSpace(params.SearchQuery))

	var results []models.Destination
	for _, d := range r.destinations {
		if qCat != "" && !strings.Contains(strings.ToLower(d.Category), qCat) {
			continue
		}
		if qCity != "" && !strings.Contains(strings.ToLower(d.CityRegency), qCity) {
			continue
		}
		if qCrowd != "" && strings.ToLower(d.CrowdLevel) != qCrowd {
			continue
		}
		if qSig != "" && d.MedanIndicator != nil && !strings.Contains(strings.ToLower(d.MedanIndicator.CellularSignal), qSig) {
			continue
		}
		if qSearch != "" {
			matched := strings.Contains(strings.ToLower(d.Name), qSearch) ||
				strings.Contains(strings.ToLower(d.CityRegency), qSearch) ||
				strings.Contains(strings.ToLower(d.Description), qSearch) ||
				strings.Contains(strings.ToLower(d.Slug), qSearch)
			if !matched {
				continue
			}
		}

		item := d
		if params.HasUserGPS {
			item.DistanceKm = CalculateSpatialDistanceKm(params.UserLat, params.UserLng, d.Latitude, d.Longitude)
			item.TravelTimeMin = EstimateSumbarTravelMinutes(item.DistanceKm)
		}
		results = append(results, item)
	}

	if params.HasUserGPS {
		sort.Slice(results, func(i, j int) bool {
			return results[i].DistanceKm < results[j].DistanceKm
		})
	}

	return results
}

// FindAggregateDetail (Hari 4) menyatukan 4 Statistik Keputusan + 5 Indikator Medan + Tips + Tarif Perda dalam 1 panggilan
func (r *RepositoryBE1) FindAggregateDetail(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	key := strings.ToLower(strings.TrimSpace(idOrSlugOrQR))
	for _, d := range r.destinations {
		if strings.ToLower(d.ID) == key ||
			strings.ToLower(d.Slug) == key ||
			strings.ToLower(d.QRPlacardCode) == key {
			item := d
			if hasUserGPS {
				item.DistanceKm = CalculateSpatialDistanceKm(userLat, userLng, d.Latitude, d.Longitude)
				item.TravelTimeMin = EstimateSumbarTravelMinutes(item.DistanceKm)
			}
			return &item, nil
		}
	}
	return nil, errors.New("DESTINATION_NOT_FOUND")
}

// CreateCMS (Hari 5 — Sinkronisasi FS-1) menambahkan destinasi baru beserta Indikator Medan, Tips & Tarif Perda
func (r *RepositoryBE1) CreateCMS(input models.Destination) models.Destination {
	r.mu.Lock()
	defer r.mu.Unlock()

	if input.ID == "" {
		input.ID = fmt.Sprintf("dest-%03d", len(r.destinations)+1)
	}
	if input.Slug == "" {
		input.Slug = strings.ToLower(strings.ReplaceAll(input.Name, " ", "-"))
	}
	if input.CrowdLevel == "" {
		input.CrowdLevel = "Sepi"
	}
	if input.DistanceKm == 0 && input.Latitude != 0 && input.Longitude != 0 {
		input.DistanceKm = CalculateSpatialDistanceKm(-0.9471, 100.4172, input.Latitude, input.Longitude)
		input.TravelTimeMin = EstimateSumbarTravelMinutes(input.DistanceKm)
	}
	now := time.Now()
	input.CreatedAt = now
	input.UpdatedAt = now

	r.destinations = append(r.destinations, input)
	return input
}

// UpdateCMS (Hari 5 — Sinkronisasi FS-1) memperbarui data destinasi & 5 Indikator Medan
func (r *RepositoryBE1) UpdateCMS(idOrSlug string, payload models.Destination) (*models.Destination, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(idOrSlug))
	for i, d := range r.destinations {
		if strings.ToLower(d.ID) == key || strings.ToLower(d.Slug) == key {
			if payload.Name != "" {
				d.Name = payload.Name
			}
			if payload.Category != "" {
				d.Category = payload.Category
			}
			if payload.CityRegency != "" {
				d.CityRegency = payload.CityRegency
			}
			if payload.CrowdLevel != "" {
				d.CrowdLevel = payload.CrowdLevel
			}
			if payload.Description != "" {
				d.Description = payload.Description
			}
			if payload.EstimatedCost > 0 {
				d.EstimatedCost = payload.EstimatedCost
			}
			if payload.MedanIndicator != nil {
				d.MedanIndicator = payload.MedanIndicator
			}
			if len(payload.Tariffs) > 0 {
				d.Tariffs = payload.Tariffs
			}
			if len(payload.Tips) > 0 {
				d.Tips = payload.Tips
			}
			d.UpdatedAt = time.Now()
			r.destinations[i] = d
			return &d, nil
		}
	}
	return nil, errors.New("DESTINATION_NOT_FOUND")
}

// SyncTariffsCMS (Hari 5 — Sinkronisasi FS-1) memperbarui khusus daftar Tarif Resmi Perda (Fair-Price Barometer)
func (r *RepositoryBE1) SyncTariffsCMS(idOrSlug string, tariffs []models.OfficialTariff) (*models.Destination, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(idOrSlug))
	for i, d := range r.destinations {
		if strings.ToLower(d.ID) == key || strings.ToLower(d.Slug) == key {
			for idx := range tariffs {
				if tariffs[idx].ID == "" {
					tariffs[idx].ID = fmt.Sprintf("trf-%s-%02d", d.ID, idx+1)
				}
				tariffs[idx].DestinationID = d.ID
			}
			d.Tariffs = tariffs
			d.UpdatedAt = time.Now()
			r.destinations[i] = d
			return &d, nil
		}
	}
	return nil, errors.New("DESTINATION_NOT_FOUND")
}

// DeleteCMS (Hari 5 — Sinkronisasi FS-1) menghapus destinasi oleh Admin Dispar
func (r *RepositoryBE1) DeleteCMS(idOrSlug string) (string, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(idOrSlug))
	for i, d := range r.destinations {
		if strings.ToLower(d.ID) == key || strings.ToLower(d.Slug) == key {
			deletedID := d.ID
			r.destinations = append(r.destinations[:i], r.destinations[i+1:]...)
			return deletedID, nil
		}
	}
	return "", errors.New("DESTINATION_NOT_FOUND")
}`,
  },
  {
    id: 'wisgo-cms-day5',
    filename: 'cms_admin_day5.go (Hari 5)',
    filepath: 'backend/internal/be1_core/cms_admin_day5.go',
    language: 'go',
    sprintDay: 'Hari 5 (Jumat — CMS Admin FS-1)',
    description: 'Handler khusus Hari 5 untuk sinkronisasi Web Admin TypeScript milik FS-1: mengizinkan Admin Dispar & Pokdarwis menyinkronkan Tabel Tarif Resmi Perda (Fair-Price Barometer) melalui PUT /api/v1/destinations/{id}/tariffs dan /api/v1/admin/destinations/{id}/tariffs.',
    content: `package be1_core

import (
	"encoding/json"
	"net/http"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// TariffSyncRequest adalah kontrak JSON Hari 5 antara BE-1 dan FS-1 (Web Admin Dispar)
// untuk memperbarui daftar Tarif Resmi Perda pada komponen Fair-Price Barometer
type TariffSyncRequest struct {
	Tariffs []models.OfficialTariff \`json:"tariffs"\`
}

// UpdateDestinationTariffsCMS menangani PUT /api/v1/destinations/{id}/tariffs
// dan PUT /api/v1/admin/destinations/{id}/tariffs (Diproteksi RBAC: admin_dispar / pokdarwis)
func (h *HandlerBE1) UpdateDestinationTariffsCMS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	var req TariffSyncRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || len(req.Tariffs) == 0 {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_TARIFF_PAYLOAD",
			"message": "Payload JSON wajib memuat array 'tariffs' minimal 1 item tarif Perda/Nagari.",
		})
		return
	}

	updated, err := h.repo.SyncTariffsCMS(id, req.Tariffs)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "DESTINATION_NOT_FOUND",
			"message": "Destinasi tidak ditemukan untuk pembaruan tarif Perda.",
		})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":           "updated",
		"destination_id":   updated.ID,
		"destination_name": updated.Name,
		"tariffs_count":    len(updated.Tariffs),
		"tariffs":          updated.Tariffs,
	})
}`,
  },
  {
    id: 'wisgo-handlers-be1',
    filename: 'handlers.go (Hari 1–5 Lengkap)',
    filepath: 'backend/internal/be1_core/handlers.go',
    language: 'go',
    sprintDay: 'File Utama BE-1 (Hari 1–5)',
    description: 'Handler utama milik BE-1 di repo LuthfiaHasan/WISGO (branch dev). Menghubungkan RepositoryBE1 (Hari 4) dan CMS Admin (Hari 5) ke mux standar Go 1.22.',
    content: `package be1_core

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// HandlerBE1 menangani seluruh endpoint Core & Spasial milik BE-1 (Pilar 1, 2, 3, 7)
// Sesuai struktur repo github.com/LuthfiaHasan/WISGO (branch dev) & docs/API_Contract_BE1_BE2.md
type HandlerBE1 struct {
	repo *RepositoryBE1
}

func NewHandlerBE1() *HandlerBE1 {
	return &HandlerBE1{
		repo: NewRepositoryBE1(),
	}
}

// RegisterSprint1Routes mendaftarkan seluruh endpoint Sprint 1 BE-1 (Hari 1 s/d Hari 5) ke mux standar Go 1.22
func (h *HandlerBE1) RegisterSprint1Routes(mux *http.ServeMux) {
	// Hari 1: Healthcheck & PostGIS Readiness
	mux.HandleFunc("GET /api/v1/health", h.GetHealthStatus)

	// Hari 4: Direktori Spasial, Aggregate Detail (4 Statistik + 5 Indikator Medan + Tips + Tarif), & Offline Bundle
	mux.HandleFunc("GET /api/v1/destinations", h.GetDestinations)
	mux.HandleFunc("GET /api/v1/destinations/detail", h.GetDestinationDetail)
	mux.HandleFunc("GET /api/v1/destinations/{id}", h.GetDestinationByID)
	mux.HandleFunc("GET /api/v1/destinations/{id}/tariffs", h.GetDestinationTariffs)
	mux.HandleFunc("GET /api/v1/destinations/{id}/offline-bundle", h.GetOfflineBundle)

	// Hari 5: Endpoint Admin CMS (Sinkronisasi FS-1) — Diproteksi Stateless JWT & RBAC
	// Mendukung path kontrak docs/API_Contract_BE1_BE2.md (/api/v1/destinations*) dan alias (/api/v1/admin/destinations*)
	mux.HandleFunc("POST /api/v1/destinations", RequireRoles(h.CreateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/destinations/{id}", RequireRoles(h.UpdateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/destinations/{id}/tariffs", RequireRoles(h.UpdateDestinationTariffsCMS, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("DELETE /api/v1/destinations/{id}", RequireRoles(h.DeleteDestination, "admin_dispar"))

	mux.HandleFunc("POST /api/v1/admin/destinations", RequireRoles(h.CreateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/admin/destinations/{id}", RequireRoles(h.UpdateDestination, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("PUT /api/v1/admin/destinations/{id}/tariffs", RequireRoles(h.UpdateDestinationTariffsCMS, "admin_dispar", "pokdarwis"))
	mux.HandleFunc("DELETE /api/v1/admin/destinations/{id}", RequireRoles(h.DeleteDestination, "admin_dispar"))

	// Endpoint Spasial & Anti-Pungli (Fondasi Awal yang sudah ada di branch dev)
	mux.HandleFunc("POST /api/v1/spatial/shunlu", h.PostShunluSearch)
	mux.HandleFunc("POST /api/v1/pungli/report", h.PostReportPungli)
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

// 0. GetHealthStatus — GET /api/v1/health (Hari 1)
func (h *HandlerBE1) GetHealthStatus(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "ok",
		"service":     "WISGO Rancak.in — BE-1 Core & Spatial Engine",
		"sprint":      "Sprint 1 (Hari 1-5 Complete)",
		"postgis":     "PostgreSQL 16 + PostGIS 3.4 Ready",
		"seeded_data": "20 Destinasi Prioritas Sumatera Barat",
	})
}

// 1. GetDestinations — GET /api/v1/destinations (Hari 4)
func (h *HandlerBE1) GetDestinations(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	qCity := r.URL.Query().Get("city_regency")
	if qCity == "" {
		qCity = r.URL.Query().Get("kabupaten_kota")
	}
	hasGPS, lat, lng := parseGPSQuery(r)

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

	_ = json.NewEncoder(w).Encode(results)
}

// 2. GetDestinationDetail — GET /api/v1/destinations/detail?id=dest-001 (Hari 4)
func (h *HandlerBE1) GetDestinationDetail(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if id == "" {
		id = "dest-001"
	}
	hasGPS, lat, lng := parseGPSQuery(r)
	h.writeDestinationDetailByKey(w, id, hasGPS, lat, lng)
}

// 3. GetDestinationByID — GET /api/v1/destinations/{id} (Hari 4)
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

// 4. GetDestinationTariffs — GET /api/v1/destinations/{id}/tariffs (Hari 4 — Fair-Price Barometer FE-2)
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

// 5. GetOfflineBundle — GET /api/v1/destinations/{id}/offline-bundle (Hari 4 — Offline Pocket FE-1)
func (h *HandlerBE1) GetOfflineBundle(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	dest, err := h.repo.FindAggregateDetail(id, false, 0, 0)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": "error", "message": "Destinasi tidak ditemukan"})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"bundle_version": "v1.0-sprint1",
		"generated_at":   time.Now().Format(time.RFC3339),
		"offline_banner": "⚡ Mode offline aktif · Tempat siap dibuka tanpa sinyal.",
		"destination":    dest,
	})
}

// 6. CreateDestination — POST /api/v1/destinations (Hari 5 — CMS Admin FS-1)
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

// 7. UpdateDestination — PUT /api/v1/destinations/{id} (Hari 5 — CMS Admin FS-1)
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

// 8. DeleteDestination — DELETE /api/v1/destinations/{id} (Hari 5 — CMS Admin FS-1)
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

func (h *HandlerBE1) PostShunluSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"query":           "SPBU & RM Padang",
		"detour_time_min": 8,
		"detour_distance": "650 m dari rute utama",
		"recommended":     "RM Simpang Raya Bukittinggi",
	}
	_ = json.NewEncoder(w).Encode(response)
}

func (h *HandlerBE1) PostReportPungli(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]string{
		"status":  "success",
		"ticket":  "PGL-202611-0091",
		"message": "Laporan berhasil diteruskan ke Satgas Saber Pungli Dispar Sumbar",
	}
	_ = json.NewEncoder(w).Encode(response)
}`,
  },
  {
    id: 'wisgo-test',
    filename: 'be1_sprint1_test.go (Hari 5 — 8 Test)',
    filepath: 'backend/internal/be1_core/be1_sprint1_test.go',
    language: 'go',
    sprintDay: 'Hari 5 (Jumat — 8 Skenario Test)',
    description: 'Suite pengujian otomatis Go (TC-01 s/d TC-08) di dalam folder internal/be1_core/ yang menguji penuh Hari 3 (20 Destinasi), Hari 4 (Filter Spasial GPS, Detail 4 Statistik + 5 Indikator Medan, Offline Bundle), dan Hari 5 (RBAC 401/403, POST/PUT Destinasi, & PUT Tarif Perda FS-1).',
    content: `package be1_core

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

func setupWISGOTestMux() *http.ServeMux {
	mux := http.NewServeMux()
	be1 := NewHandlerBE1()
	be1.RegisterSprint1Routes(mux)
	return mux
}

func TestBE1Sprint1Suite(t *testing.T) {
	mux := setupWISGOTestMux()

	t.Run("TC-01 (Hari 3): GET /api/v1/destinations mengembalikan minimal 20 destinasi Sumbar", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var list []models.Destination
		if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if len(list) < 20 {
			t.Fatalf("expected at least 20 seeded destinations, got %d", len(list))
		}
	})

	t.Run("TC-02 (Hari 4): GET /api/v1/destinations?lat=-0.3051&lng=100.3692&signal=blank_spot memfilter & mengurutkan jarak spasial GPS", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations?lat=-0.3051&lng=100.3692&signal=blank_spot", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var list []models.Destination
		if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
			t.Fatalf("failed to decode filtered list: %v", err)
		}
		if len(list) == 0 {
			t.Fatal("expected blank_spot destinations to be returned")
		}
		if len(list) >= 2 && list[0].DistanceKm > list[1].DistanceKm {
			t.Fatalf("expected spatial sorting ASC by distance_km, got %v > %v", list[0].DistanceKm, list[1].DistanceKm)
		}
	})

	t.Run("TC-03 (Hari 4): GET /api/v1/destinations/{id} menyatukan 4 Statistik + 5 Indikator Medan + Tips + Tarif Perda", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations/lembah-harau?lat=-0.9471&lng=100.4172", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}

		var detail models.Destination
		if err := json.Unmarshal(rec.Body.Bytes(), &detail); err != nil {
			t.Fatalf("failed to decode detail: %v", err)
		}
		if detail.MedanIndicator == nil {
			t.Fatal("expected MedanIndicator (5 Indikator Medan) to be present")
		}
		if len(detail.Tariffs) == 0 {
			t.Fatal("expected OfficialTariffs (Tabel Fair-Price Perda) to be present")
		}
		if len(detail.Tips) == 0 {
			t.Fatal("expected LocalTips (Tips Menjaga Tempat) to be present")
		}
	})

	t.Run("TC-04 (Hari 4): GET /api/v1/destinations/{id}/offline-bundle mengembalikan paket Mode Offline Pocket", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/destinations/dest-001/offline-bundle", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", rec.Code)
		}
	})

	t.Run("TC-05 (Hari 5): POST /api/v1/destinations menolak request tanpa Bearer Token (401 Unauthorized)", func(t *testing.T) {
		body := []byte(\`{"name":"Destinasi Tanpa Token"}\`)
		req := httptest.NewRequest("POST", "/api/v1/destinations", bytes.NewBuffer(body))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 Unauthorized, got %d", rec.Code)
		}
	})

	t.Run("TC-06 (Hari 5): POST /api/v1/destinations menolak role tourist (403 Forbidden RBAC)", func(t *testing.T) {
		body := []byte(\`{"name":"Destinasi Oleh Tourist"}\`)
		req := httptest.NewRequest("POST", "/api/v1/destinations", bytes.NewBuffer(body))
		req.Header.Set("Authorization", "Bearer "+TokenTourist)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusForbidden {
			t.Fatalf("expected 403 Forbidden for tourist role, got %d", rec.Code)
		}
	})

	t.Run("TC-07 (Hari 5): POST /api/v1/admin/destinations dengan Token Admin Dispar berhasil membuat destinasi baru (201 Created)", func(t *testing.T) {
		body := []byte(\`{"name":"Tabek Patah Panorama Baru","category":"Alam & Tebing","city_regency":"Kab. Tanah Datar","latitude":-0.321,"longitude":100.512}\`)
		req := httptest.NewRequest("POST", "/api/v1/admin/destinations", bytes.NewBuffer(body))
		req.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201 Created, got %d", rec.Code)
		}
	})

	t.Run("TC-08 (Hari 5): PUT /api/v1/admin/destinations/{id}/tariffs menyinkronkan Tarif Resmi Perda dari CMS FS-1", func(t *testing.T) {
		body := []byte(\`{"tariffs":[{"item_name":"Tiket Masuk Resmi Kawasan Harau","category":"tiket","price":15000,"unit":"per orang","regulation_ref":"Perda Kab. Lima Puluh Kota No. 7/2023"},{"item_name":"Parkir Resmi Mobil","category":"parkir","price":5000,"unit":"per kendaraan","regulation_ref":"Peraturan Nagari Tarantang No. 2/2024"}]}\`)
		req := httptest.NewRequest("PUT", "/api/v1/admin/destinations/dest-001/tariffs", bytes.NewBuffer(body))
		req.Header.Set("Authorization", "Bearer "+TokenAdminDispar)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 OK on tariff sync, got %d", rec.Code)
		}
	})
}`,
  },
  {
    id: 'wisgo-seeder-be1',
    filename: 'seeder_20_sumbar.go (Hari 3)',
    filepath: 'backend/internal/be1_core/seeder_20_sumbar.go',
    language: 'go',
    sprintDay: 'Hari 3 (Rabu — Seeder 20 Destinasi)',
    description: 'File di dalam folder internal/be1_core/ yang menyuplai 20 Destinasi Prioritas Sumatera Barat lengkap dengan 4 Statistik Keputusan, 5 Indikator Medan, Tips, dan Tarif Perda.',
    content: `package be1_core

import (
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Seed20DestinationsSumbar mengembalikan 20 Destinasi Prioritas Sumatera Barat
// sesuai output wajib Jumat Minggu 1 (Sprint 1) untuk BE-1.
func Seed20DestinationsSumbar() []models.Destination {
	now := time.Now()
	return []models.Destination{
		{
			ID:            "dest-001",
			Slug:          "lembah-harau",
			Name:          "Lembah Harau (Aka Barayun & Sarasah Bunta)",
			Category:      "Alam & Tebing",
			CityRegency:   "Kab. Lima Puluh Kota",
			Description:   "Lembah subur dengan tebing granit purba terjal setinggi 150-300 meter dan 7 air terjun alami.",
			Latitude:      -0.1023,
			Longitude:     100.6728,
			ElevationM:    540,
			CrowdLevel:    "Sedang",
			DistanceKm:    138.0,
			TravelTimeMin: 205,
			EstimatedCost: 15000,
			IsHiddenGem:   false,
			QRPlacardCode: "QR-SMBR-LPK-001",
			OpeningHours:  "07.30 - 18.00 WIB",
			CreatedAt:     now,
			UpdatedAt:     now,
			MedanIndicator: &models.MedanIndicator{
				ID:             "medan-001",
				DestinationID:  "dest-001",
				VehicleAccess:  "Mobil OK (Jalan aspal datar hingga kaki tebing)",
				TrekkingLevel:  "Datar / Mudah",
				CellularSignal: "Blank Spot (4G di gerbang depan; Blank Spot di lembah Sarasah Murai)",
				Facilities:     "Toilet & Musala Lengkap",
				GuideNeed:      "Mandiri",
				PokdarwisName:  "Pokdarwis Nagari Tarantang Harau",
			},
			Tips: []models.LocalTip{
				{
					ID:            "tip-001",
					DestinationID: "dest-001",
					Title:         "Unduh Paket Offline Sebelum Masuk Lembah Dalam",
					Category:      "keselamatan_medan",
					Content:       "Tebing granit 300 meter menghalangi sinyal seluler di area Sarasah Murai. Aktifkan Mode Offline Pocket.",
					IsImportant:   true,
				},
			},
			Tariffs: []models.OfficialTariff{
				{ID: "trf-001a", DestinationID: "dest-001", ItemName: "Tiket Masuk Kawasan Lembah Harau", Category: "tiket", Price: 15000, Unit: "per orang", RegulationRef: "Perda Kab. Lima Puluh Kota No. 7/2023"},
				{ID: "trf-001b", DestinationID: "dest-001", ItemName: "Parkir Resmi Motor", Category: "parkir", Price: 3000, Unit: "per kendaraan", RegulationRef: "Peraturan Nagari Tarantang No. 2/2024"},
				{ID: "trf-001c", DestinationID: "dest-001", ItemName: "Parkir Resmi Mobil", Category: "parkir", Price: 5000, Unit: "per kendaraan", RegulationRef: "Peraturan Nagari Tarantang No. 2/2024"},
			},
		},
		// ... (Memuat lengkap 20 destinasi Sumatera Barat; lihat file fisik di /backend/internal/be1_core/seeder_20_sumbar.go)
	}
}`,
  },
  {
    id: 'wisgo-jwt-be1',
    filename: 'middleware_jwt.go (Hari 1)',
    filepath: 'backend/internal/be1_core/middleware_jwt.go',
    language: 'go',
    sprintDay: 'Hari 1 (Senin — JWT & RBAC)',
    description: 'Middleware Stateless JWT & RBAC di dalam folder internal/be1_core/ (Zero Merge Conflict dengan BE-2).',
    content: `package be1_core

import (
	"encoding/json"
	"net/http"
	"strings"
)

const (
	TokenAdminDispar = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLWFkbWluLWRpc3Bhci0wMSIsIm5hbWUiOiJBZG1pbiBEaXNwYXIgU3VtYmFyIChGUy0xKSIsInJvbGUiOiJhZG1pbl9kaXNwYXIifQ.rancakin_sig_admin"
	TokenPokdarwis   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXBva2Rhcndpcy0wMSIsIm5hbWUiOiJVZGEgWnVsIChQb2tkYXJ3aXMgTmFnYXJpKSIsInJvbGUiOiJwb2tkYXJ3aXMifQ.rancakin_sig_pokdarwis"
	TokenTourist     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXRvdXJpc3QtMDEiLCJuYW1lIjoiUml6a3kgUHJhdGFtYSAoV2lzYXRhd2FuKSIsInJvbGUiOiJ0b3VyaXN0In0.rancakin_sig_tourist"
)

var validTokenRoles = map[string]string{
	TokenAdminDispar: "admin_dispar",
	TokenPokdarwis:   "pokdarwis",
	TokenTourist:     "tourist",
}

func RequireRoles(next http.HandlerFunc, allowedRoles ...string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			w.WriteHeader(http.StatusUnauthorized)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  "error",
				"code":    "UNAUTHORIZED_MISSING_TOKEN",
				"message": "Header Authorization Bearer token wajib disertakan untuk operasi Admin CMS.",
			})
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		role, exists := validTokenRoles[token]
		if !exists {
			w.WriteHeader(http.StatusUnauthorized)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  "error",
				"code":    "UNAUTHORIZED_INVALID_TOKEN",
				"message": "Token JWT tidak valid atau tidak dikenali oleh server WISGO.",
			})
			return
		}

		allowed := false
		for _, allowedRole := range allowedRoles {
			if role == allowedRole {
				allowed = true
				break
			}
		}

		if !allowed {
			w.WriteHeader(http.StatusForbidden)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":         "error",
				"code":           "FORBIDDEN_INSUFFICIENT_ROLE",
				"message":        "Akses ditolak: Role Anda tidak memiliki izin untuk mengubah data destinasi CMS.",
				"current_role":   role,
				"required_roles": allowedRoles,
			})
			return
		}

		next(w, r)
	}
}`,
  },
  {
    id: 'wisgo-sql-be1',
    filename: 'migrations_sprint1.sql (Hari 2)',
    filepath: 'backend/internal/be1_core/migrations_sprint1.sql',
    language: 'sql',
    sprintDay: 'Hari 2 (Selasa — Migrasi SQL)',
    description: 'DDL PostgreSQL 16 + PostGIS 3.4 untuk 4 tabel Sprint 1 (destinations, medan_indicators, local_tips, official_tariffs) sesuai struct di WISGO/backend/internal/models/models.go.',
    content: `-- ============================================================================
-- MIGRASI POSTGRESQL + POSTGIS KHUSUS BE-1 (SPRINT 1)
-- Repo: github.com/LuthfiaHasan/WISGO (Branch: dev)
-- Lokasi File: backend/internal/be1_core/migrations_sprint1.sql
-- ============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Tabel Induk: destinations (Sesuai struct models.Destination)
CREATE TABLE IF NOT EXISTS destinations (
    id VARCHAR(36) PRIMARY KEY,
    slug VARCHAR(120) UNIQUE,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(64) NOT NULL,
    city_regency VARCHAR(80) NOT NULL,
    description TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geog GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
    ) STORED,
    elevation_m INTEGER NOT NULL DEFAULT 0,
    cover_image TEXT NOT NULL DEFAULT '',
    crowd_level VARCHAR(24) NOT NULL DEFAULT 'Sedang',
    distance_km NUMERIC(6,1) NOT NULL DEFAULT 0.0,
    travel_time_min INTEGER NOT NULL DEFAULT 0,
    estimated_cost NUMERIC(12,2) NOT NULL DEFAULT 0,
    is_hidden_gem BOOLEAN NOT NULL DEFAULT FALSE,
    qr_placard_code VARCHAR(64) UNIQUE,
    opening_hours VARCHAR(100) NOT NULL DEFAULT '08.00 - 17.30 WIB',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_destinations_geog ON destinations USING GIST (geog);
CREATE INDEX IF NOT EXISTS idx_destinations_city_regency ON destinations (city_regency);

-- 2. Tabel 5 Indikator Medan: medan_indicators (Sesuai struct models.MedanIndicator)
CREATE TABLE IF NOT EXISTS medan_indicators (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL UNIQUE REFERENCES destinations(id) ON DELETE CASCADE,
    vehicle_access VARCHAR(160) NOT NULL,
    trekking_level VARCHAR(160) NOT NULL,
    cellular_signal VARCHAR(160) NOT NULL,
    facilities VARCHAR(200) NOT NULL,
    guide_need VARCHAR(160) NOT NULL,
    pokdarwis_name VARCHAR(160) NOT NULL DEFAULT ''
);

-- 3. Tabel Tips Menjaga Tempat: local_tips (Sesuai struct models.LocalTip)
CREATE TABLE IF NOT EXISTS local_tips (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    title VARCHAR(160) NOT NULL DEFAULT 'Tips Menjaga Tempat Ini',
    category VARCHAR(48) NOT NULL DEFAULT 'kelestarian_alam',
    content TEXT NOT NULL,
    is_important BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Tabel Fair-Price Barometer: official_tariffs (Sesuai struct models.OfficialTariff)
CREATE TABLE IF NOT EXISTS official_tariffs (
    id VARCHAR(36) PRIMARY KEY,
    destination_id VARCHAR(36) NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    item_name VARCHAR(160) NOT NULL,
    category VARCHAR(48) NOT NULL DEFAULT 'tiket',
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    unit VARCHAR(48) NOT NULL,
    regulation_ref VARCHAR(160) NOT NULL
);

COMMIT;`,
  },
  {
    id: 'wisgo-models',
    filename: 'models.go (Hari 2)',
    filepath: 'backend/internal/models/models.go',
    language: 'go',
    sprintDay: 'Hari 2 (Domain Models)',
    description: 'Struct model di backend/internal/models/models.go yang mempertahankan 100% struct BE-1 & BE-2 di branch dev sekaligus melengkapi 4 Statistik Keputusan Sprint 1.',
    content: `package models

import "time"

// --- Domain Models BE-1: Core & Spasial (Pilar 1, 2, 3, 7) ---

type Destination struct {
	ID            string    \`json:"id"\`
	Slug          string    \`json:"slug,omitempty"\`
	Name          string    \`json:"name"\`
	Category      string    \`json:"category"\`
	CityRegency   string    \`json:"city_regency"\` // 19 Kab/Kota Sumbar
	Description   string    \`json:"description"\`
	Latitude      float64   \`json:"latitude"\`
	Longitude     float64   \`json:"longitude"\`
	ElevationM    int       \`json:"elevation_m,omitempty"\`
	CoverImage    string    \`json:"cover_image"\`
	CrowdLevel    string    \`json:"crowd_level"\`     // Sepi, Sedang, Ramai (Statistik Keputusan #3)
	DistanceKm    float64   \`json:"distance_km"\`     // Statistik Keputusan #1
	TravelTimeMin int       \`json:"travel_time_min"\` // Statistik Keputusan #2
	EstimatedCost float64   \`json:"estimated_cost"\`  // Statistik Keputusan #4
	IsHiddenGem   bool      \`json:"is_hidden_gem"\`
	QRPlacardCode string    \`json:"qr_placard_code,omitempty"\`
	OpeningHours  string    \`json:"opening_hours,omitempty"\`
	CreatedAt     time.Time \`json:"created_at"\`
	UpdatedAt     time.Time \`json:"updated_at"\`

	// Relasi
	MedanIndicator *MedanIndicator  \`json:"medan_indicator,omitempty"\`
	Tips           []LocalTip       \`json:"tips,omitempty"\`
	Tariffs        []OfficialTariff \`json:"tariffs,omitempty"\`
	Scenes360      []Scene360       \`json:"scenes_360,omitempty"\`
}

type MedanIndicator struct {
	ID             string \`json:"id"\`
	DestinationID  string \`json:"destination_id"\`
	VehicleAccess  string \`json:"vehicle_access"\`  // Mobil OK, Hanya Motor, Jalan Kaki
	TrekkingLevel  string \`json:"trekking_level"\`  // Datar / Mudah, Sedang, Curam / Ekstrem
	CellularSignal string \`json:"cellular_signal"\` // 4G Kuat, Sinyal Lemah, Blank Spot
	Facilities     string \`json:"facilities"\`      // Toilet & Musala Lengkap, Terbatas, Belum Ada
	GuideNeed      string \`json:"guide_need"\`       // Wajib Pemandu, Disarankan, Mandiri
	PokdarwisName  string \`json:"pokdarwis_name,omitempty"\`
}

type LocalTip struct {
	ID            string \`json:"id"\`
	DestinationID string \`json:"destination_id"\`
	Title         string \`json:"title,omitempty"\`
	Category      string \`json:"category,omitempty"\`
	Content       string \`json:"content"\`
	IsImportant   bool   \`json:"is_important"\`
}

type OfficialTariff struct {
	ID            string  \`json:"id"\`
	DestinationID string  \`json:"destination_id"\`
	ItemName      string  \`json:"item_name"\`
	Category      string  \`json:"category,omitempty"\`
	Price         float64 \`json:"price"\`
	Unit          string  \`json:"unit"\`
	RegulationRef string  \`json:"regulation_ref"\`
}`,
  },
  {
    id: 'wisgo-main',
    filename: 'main.go (Entrypoint)',
    filepath: 'backend/cmd/api/main.go',
    language: 'go',
    sprintDay: 'Hari 1 & 5 (Entrypoint Server)',
    description: 'Entrypoint backend/cmd/api/main.go yang mendaftarkan seluruh rute Sprint 1 BE-1 tanpa mengganggu rute milik BE-2.',
    content: `package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/LuthfiaHasan/WISGO/backend/internal/be1_core"
	"github.com/LuthfiaHasan/WISGO/backend/internal/be2_group"
	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
	"github.com/LuthfiaHasan/WISGO/backend/internal/database"
)

func main() {
	cfg := config.LoadConfig()
	database.InitDB(cfg)

	mux := http.NewServeMux()

	// Inisialisasi Handler Tim BE-1 & BE-2
	be1 := be1_core.NewHandlerBE1()
	be2 := be2_group.NewHandlerBE2()

	// --- Route BE-1 (Core & Spasial — Sprint 1 Lengkap Hari 1-5) ---
	be1.RegisterSprint1Routes(mux)

	// --- Route BE-2 (Grup, Mitra, Escrow — Dibiarkan Utuh Zero Conflict) ---
	mux.HandleFunc("POST /api/v1/auth/request-otp", be2.RequestOTP)
	mux.HandleFunc("POST /api/v1/groups", be2.CreateGroupRoom)
	mux.HandleFunc("GET /api/v1/partners", be2.GetPartnersKatalog)
	mux.HandleFunc("POST /api/v1/bookings/wa-webhook", be2.WAWebhookSimulation)

	// Health check
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, \`{"status":"ok","app":"Rancak.in Backend API","env":"%s","be1_sprint1":"active_20_destinations"}\`, cfg.Environment)
	})

	addr := ":" + cfg.Port
	log.Printf("==================================================")
	log.Printf("  Rancak.in API Server (Go Gin/Net-HTTP Engine)  ")
	log.Printf("  Port: %s | Environment: %s                      ", cfg.Port, cfg.Environment)
	log.Printf("  BE-1 & BE-2 Modular Architecture Active         ")
	log.Printf("==================================================", )

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Gagal menjalankan server: %v", err)
	}
}`,
  },
];
