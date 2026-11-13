package be1_core

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
const SQLQueryFindAllPostGIS = `
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
`

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

// RepositoryBE1 mengelola akses data spasial PostGIS Sprint 1, Sprint 2, & Sprint 3 milik BE-1
type RepositoryBE1 struct {
	mu             sync.RWMutex
	destinations   []models.Destination
	scenes360      map[string][]models.Scene360
	shunluPOIs     []models.ShunluPOI
	microMaps      map[string]models.ScenicMicroMap
	pungliReports  []models.PungliReport
	gaodeRankings  []models.GaodeBehaviorRanking
	hazardAlerts   []models.HazardAlert
	sosSignals     []models.SOSSignal
	minangPhrases  []models.MinangPhrase
	culturalEvents []models.CulturalEvent
}

func NewRepositoryBE1() *RepositoryBE1 {
	return &RepositoryBE1{
		destinations:   Seed20DestinationsSumbar(),
		scenes360:      SeedSprint2Scenes360(),
		shunluPOIs:     SeedSprint2ShunluPOIs(),
		microMaps:      SeedSprint2MicroMaps(),
		pungliReports:  SeedSprint2PungliReports(),
		gaodeRankings:  SeedSprint3GaodeRankings(),
		hazardAlerts:   SeedSprint3HazardAlerts(),
		sosSignals:     SeedSprint3SOSSignals(),
		minangPhrases:  SeedSprint3MinangPhrases(),
		culturalEvents: SeedSprint3CulturalEvents(),
	}
}

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
		if scenes, ok := r.scenes360[d.ID]; ok {
			item.Scenes360 = scenes
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

// FindAggregateDetail (Hari 4 & Sprint 2) menyatukan 4 Statistik + 5 Indikator Medan + Tips + Tarif + Scenes 360°
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
			if scenes, ok := r.scenes360[d.ID]; ok {
				item.Scenes360 = scenes
			}
			if mm, ok := r.microMaps[d.ID]; ok {
				mmCopy := mm
				item.MicroMap = &mmCopy
			}
			return &item, nil
		}
	}
	return nil, errors.New("DESTINATION_NOT_FOUND")
}

// CreateCMS (Hari 5 — Sinkronisasi FS-1)
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

// UpdateCMS (Hari 5 — Sinkronisasi FS-1)
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

// SyncTariffsCMS (Hari 5 — Sinkronisasi FS-1)
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

// DeleteCMS (Hari 5 — Sinkronisasi FS-1)
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
}

// --- Method Repository Sprint 2 (Minggu 2: Hari 6–10) ---

// GetScenes360ByDestinationID (Hari 7) mengambil daftar Scene 360° Aerial & Ground beserta 4 Pin Interaktif
func (r *RepositoryBE1) GetScenes360ByDestinationID(destID string) []models.Scene360 {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if scenes, ok := r.scenes360[destID]; ok && len(scenes) > 0 {
		return scenes
	}
	// Fallback otomatis untuk destinasi yang belum memiliki kustomisasi 360° spesifik
	return []models.Scene360{
		{
			ID:              fmt.Sprintf("scene-%s-aerial-01", destID),
			DestinationID:   destID,
			Title:           "Panorama Udara Kawasan Wisata (Drone 150m)",
			Type:            "aerial",
			PanoramaURL:     fmt.Sprintf("https://cdn.rancak.in/360/%s-aerial.jpg", destID),
			UploadFormat:    "url",
			SpatialAudioURL: "https://cdn.rancak.in/audio/ambient-alam-sumbar.mp3",
			InitialPitch:    -10.0,
			InitialYaw:      180.0,
			IsDefaultScene:  true,
			Hotspots: []models.Hotspot360{
				{
					ID:          fmt.Sprintf("pin-%s-nav-01", destID),
					SceneID:     fmt.Sprintf("scene-%s-aerial-01", destID),
					Type:        "navigasi",
					ColorToken:  "#2563EB",
					Pitch:       -24.0,
					Yaw:         180.0,
					Title:       "Turun ke Spot Utama Darat (Ground 360°)",
					TargetRef:   fmt.Sprintf("scene-%s-ground-01", destID),
					Description: "Transisi mulus dari udara ke titik kunjungan utama.",
				},
				{
					ID:          fmt.Sprintf("pin-%s-mitra-01", destID),
					SceneID:     fmt.Sprintf("scene-%s-aerial-01", destID),
					Type:        "mitra",
					ColorToken:  "#E85D1A",
					Pitch:       -8.0,
					Yaw:         135.0,
					Title:       "Pesan Pemandu & Kuliner Mitra Nagari Setempat",
					TargetRef:   "partner-001",
					Description: "Buka Quick Booking Drawer Mitra Nagari resmi.",
				},
			},
		},
	}
}

// AddScene360CMS (Hari 7 — CMS Studio 360° FS-1) menambahkan scene 360° baru
func (r *RepositoryBE1) AddScene360CMS(scene models.Scene360) models.Scene360 {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing := r.scenes360[scene.DestinationID]
	if scene.ID == "" {
		scene.ID = fmt.Sprintf("scene-%s-%02d", scene.DestinationID, len(existing)+1)
	}
	r.scenes360[scene.DestinationID] = append(existing, scene)
	return scene
}

// AddHotspotToSceneCMS (Hari 7 — Klik-Tempel Pin 360° FS-1) menempelkan pin baru ke koordinat pitch/yaw
func (r *RepositoryBE1) AddHotspotToSceneCMS(sceneID string, pin models.Hotspot360) (*models.Scene360, models.Hotspot360, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	targetID := strings.ToLower(strings.TrimSpace(sceneID))
	for destID, scenes := range r.scenes360 {
		for idx, sc := range scenes {
			if strings.ToLower(sc.ID) == targetID {
				if pin.ID == "" {
					pin.ID = fmt.Sprintf("pin-%s-%02d", sc.ID, len(sc.Hotspots)+1)
				}
				pin.SceneID = sc.ID
				sc.Hotspots = append(sc.Hotspots, pin)
				r.scenes360[destID][idx] = sc
				return &sc, pin, nil
			}
		}
	}
	return nil, pin, errors.New("SCENE_NOT_FOUND")
}

// SearchShunluAlongRoute (Hari 8) mencari fasilitas searah koridor rute dengan batas waktu memutar +X menit
func (r *RepositoryBE1) SearchShunluAlongRoute(req ShunluSearchRequest) []models.ShunluPOI {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(req.Category))
	var results []models.ShunluPOI
	for _, poi := range r.shunluPOIs {
		if qCat != "" && strings.ToLower(poi.Category) != qCat {
			continue
		}
		if req.MaxDetourMin > 0 && poi.DetourMinutes > req.MaxDetourMin {
			continue
		}
		results = append(results, poi)
	}
	return results
}

// GetMicroMapByDestinationID (Hari 8) mengembalikan Peta Mikro Kawasan + titik pemicu Audio GPS <=15m
func (r *RepositoryBE1) GetMicroMapByDestinationID(destID, destName string, lat, lng float64) models.ScenicMicroMap {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if mm, ok := r.microMaps[destID]; ok {
		return mm
	}
	return models.ScenicMicroMap{
		ID:                  fmt.Sprintf("micromap-%s", destID),
		DestinationID:       destID,
		DestinationName:     destName,
		AreaSizeHectare:     15.0,
		WalkwayGeoJSON:      fmt.Sprintf(`{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"Jalur Pejalan Kaki Utama %s"},"geometry":{"type":"LineString","coordinates":[[%f,%f],[%f,%f]]}}]}`, destName, lng, lat, lng+0.0008, lat+0.0008),
		ChildFriendlyPath:   true,
		ElderlyFriendlyPath: true,
		InternalPOIs: []models.MicroMapPOI{
			{ID: fmt.Sprintf("mpoi-%s-1", destID), Name: "Gerbang Utama & Plang Smart QR", Type: "gerbang", Latitude: lat, Longitude: lng, Description: "Titik masuk utama kawasan & informasi tarif Perda."},
			{ID: fmt.Sprintf("mpoi-%s-2", destID), Name: "Musala & Toilet Bersih Kawasan", Type: "toilet_musala", Latitude: lat + 0.0004, Longitude: lng + 0.0004, Description: "Fasilitas sanitasi dan ibadah wisatawan."},
		},
		AudioTriggers: []models.AudioTriggerPoint{
			{
				ID:              fmt.Sprintf("audiotrig-%s-1", destID),
				DestinationID:   destID,
				Title:           fmt.Sprintf("Cerita Sejarah & Adat %s", destName),
				Latitude:        lat,
				Longitude:       lng,
				TriggerRadiusM:  15.0,
				AudioURLID:      fmt.Sprintf("https://cdn.rancak.in/audio/gps-%s-id.mp3", destID),
				AudioURLMinang:  fmt.Sprintf("https://cdn.rancak.in/audio/gps-%s-minang.mp3", destID),
				TranscriptShort: fmt.Sprintf("Selamat datang di kawasan wisata %s. Panduan suara ini aktif otomatis ketika GPS Anda berada dalam radius 15 meter.", destName),
			},
		},
	}
}

// CreatePungliReport (Hari 9) mencatat aduan pungli anonim & menghitung selisih terhadap tarif resmi Perda
func (r *RepositoryBE1) CreatePungliReport(input models.PungliReport) models.PungliReport {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()
	seq := len(r.pungliReports) + 91
	input.ID = fmt.Sprintf("pungli-%03d", len(r.pungliReports)+1)
	input.TicketCode = fmt.Sprintf("PGL-202611-%04d", seq)
	input.Status = "Masuk"
	input.CreatedAt = now
	input.UpdatedAt = now

	// Cari tarif Perda acuan dari destinasi terkait untuk menghitung overcharge secara otomatis
	officialPrice := 5000.0
	for _, d := range r.destinations {
		if strings.EqualFold(d.ID, input.DestinationID) || strings.EqualFold(d.Slug, input.DestinationID) {
			input.DestinationID = d.ID
			input.DestinationName = d.Name
			if input.Latitude == 0 && input.Longitude == 0 {
				input.Latitude = d.Latitude
				input.Longitude = d.Longitude
			}
			if len(d.Tariffs) > 0 {
				officialPrice = d.Tariffs[0].Price
				for _, t := range d.Tariffs {
					if strings.Contains(strings.ToLower(input.IncidentCategory), "parkir") && strings.Contains(strings.ToLower(t.ItemName), "mobil") {
						officialPrice = t.Price
						break
					}
				}
			}
			break
		}
	}

	input.OfficialPerdaPriceIDR = officialPrice
	if input.ChargedAmountIDR > officialPrice {
		input.OverchargeAmountIDR = input.ChargedAmountIDR - officialPrice
	}
	r.pungliReports = append([]models.PungliReport{input}, r.pungliReports...)
	return input
}

// ListPungliReports (Hari 9 — Pusat Komando Satgas FS-1)
func (r *RepositoryBE1) ListPungliReports(statusFilter string) []models.PungliReport {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if statusFilter == "" {
		return r.pungliReports
	}
	var filtered []models.PungliReport
	for _, rep := range r.pungliReports {
		if strings.EqualFold(rep.Status, statusFilter) {
			filtered = append(filtered, rep)
		}
	}
	return filtered
}

// UpdatePungliReportStatus (Hari 9 — Pusat Komando Satgas FS-1)
func (r *RepositoryBE1) UpdatePungliReportStatus(idOrTicket, newStatus, satgasNotes string) (*models.PungliReport, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(idOrTicket))
	for i, rep := range r.pungliReports {
		if strings.ToLower(rep.ID) == key || strings.ToLower(rep.TicketCode) == key {
			rep.Status = newStatus
			if satgasNotes != "" {
				rep.SatgasNotes = satgasNotes
			}
			rep.UpdatedAt = time.Now()
			r.pungliReports[i] = rep
			return &rep, nil
		}
	}
	return nil, errors.New("REPORT_NOT_FOUND")
}
