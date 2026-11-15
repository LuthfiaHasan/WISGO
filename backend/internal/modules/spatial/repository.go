package spatial

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

// Repository antarmuka akses data spasial, shunlu, micro-map, hazard, dan SOS
type Repository interface {
	SearchShunluAlongRoute(req ShunluSearchRequest) []models.ShunluPOI
	GetMicroMapByDestinationID(destID, destName string, lat, lng float64) models.ScenicMicroMap
	ListHazardAlerts(severityFilter, corridorFilter string) []models.HazardAlert
	TriggerHazardCorridor(input TriggerHazardInput) (*models.HazardAlert, error)
	CreateSOSSignal(input SOSEmergencyInput) models.SOSSignal
	ListSOSSignals() []models.SOSSignal
	RecordNavigationTelemetry(input NavigationTelemetryInput) (*models.GaodeBehaviorRanking, error)
}

// CalculateSpatialDistanceKm menghitung jarak spasial GPS dalam km (faktor jalan berliku Minangkabau 1.32x)
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

// HaversineMeter menghitung jarak presisi dalam satuan meter untuk pemicu Audio GPS <= 15m
func HaversineMeter(lat1, lon1, lat2, lon2 float64) float64 {
	const earthRadiusM = 6371000.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLon := (lon2 - lon1) * math.Pi / 180.0
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180.0)*math.Cos(lat2*math.Pi/180.0)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return math.Round(earthRadiusM*c*10) / 10
}

type inMemoryRepository struct {
	mu           sync.RWMutex
	shunluPOIs   []models.ShunluPOI
	microMaps    map[string]models.ScenicMicroMap
	hazardAlerts []models.HazardAlert
	sosSignals   []models.SOSSignal
	telemetries  map[string]*models.GaodeBehaviorRanking
}

// NewRepository membuat instance repositori spasial baru dengan seeder awal
func NewRepository() Repository {
	return &inMemoryRepository{
		shunluPOIs:   SeedShunluPOIs(),
		microMaps:    SeedMicroMaps(),
		hazardAlerts: SeedHazardAlerts(),
		sosSignals:   SeedSOSSignals(),
		telemetries:  make(map[string]*models.GaodeBehaviorRanking),
	}
}

func (r *inMemoryRepository) SearchShunluAlongRoute(req ShunluSearchRequest) []models.ShunluPOI {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(req.Category))
	var matches []models.ShunluPOI

	for _, poi := range r.shunluPOIs {
		if qCat != "" && strings.ToLower(poi.Category) != qCat {
			continue
		}
		if req.MaxDetourMin > 0 && poi.DetourMinutes > req.MaxDetourMin {
			continue
		}
		matches = append(matches, poi)
	}

	sort.Slice(matches, func(i, j int) bool {
		return matches[i].DetourMinutes < matches[j].DetourMinutes
	})

	return matches
}

func (r *inMemoryRepository) GetMicroMapByDestinationID(destID, destName string, lat, lng float64) models.ScenicMicroMap {
	r.mu.RLock()
	defer r.mu.RUnlock()

	normalizedID := strings.ToLower(strings.TrimSpace(destID))
	if mm, ok := r.microMaps[normalizedID]; ok {
		return mm
	}

	// Fallback dinamis peta mikro kawasan
	return models.ScenicMicroMap{
		ID:                  fmt.Sprintf("micromap-%s", normalizedID),
		DestinationID:       destID,
		DestinationName:     destName,
		AreaSizeHectare:     15.0,
		WalkwayGeoJSON:      fmt.Sprintf(`{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"Jalur Pejalan Kaki Utama %s"},"geometry":{"type":"LineString","coordinates":[[%f,%f],[%f,%f]]}}]}`, destName, lng, lat, lng+0.0008, lat+0.0008),
		ChildFriendlyPath:   true,
		ElderlyFriendlyPath: true,
		InternalPOIs: []models.MicroMapPOI{
			{ID: fmt.Sprintf("poi-%s-01", normalizedID), Name: fmt.Sprintf("Gerbang Masuk %s", destName), Type: "gerbang", Latitude: lat, Longitude: lng, Description: "Titik kedatangan & loket tiket resmi."},
		},
		AudioTriggers: []models.AudioTriggerPoint{
			{
				ID:              fmt.Sprintf("audiotrig-%s-01", normalizedID),
				DestinationID:   destID,
				Title:           fmt.Sprintf("Selamat Datang di Kawasan %s", destName),
				Latitude:        lat,
				Longitude:       lng,
				TriggerRadiusM:  15.0,
				AudioURLID:      fmt.Sprintf("https://cdn.rancak.in/audio/gps-%s-intro-id.mp3", normalizedID),
				AudioURLMinang:  fmt.Sprintf("https://cdn.rancak.in/audio/gps-%s-intro-minang.mp3", normalizedID),
				TranscriptShort: fmt.Sprintf("Anda telah memasuki kawasan %s. Selamat menikmati keindahan alam dan budaya Minangkabau.", destName),
			},
		},
	}
}

func (r *inMemoryRepository) ListHazardAlerts(severityFilter, corridorFilter string) []models.HazardAlert {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qSev := strings.ToLower(strings.TrimSpace(severityFilter))
	qCor := strings.ToLower(strings.TrimSpace(corridorFilter))

	var list []models.HazardAlert
	for _, h := range r.hazardAlerts {
		if qSev != "" && !strings.Contains(strings.ToLower(h.Severity), qSev) {
			continue
		}
		if qCor != "" && !strings.Contains(strings.ToLower(h.CorridorCode), qCor) && !strings.Contains(strings.ToLower(h.Location), qCor) {
			continue
		}
		list = append(list, h)
	}
	return list
}

func (r *inMemoryRepository) TriggerHazardCorridor(input TriggerHazardInput) (*models.HazardAlert, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	target := strings.ToLower(strings.TrimSpace(input.CorridorCode))
	for i, h := range r.hazardAlerts {
		if strings.ToLower(h.CorridorCode) == target || strings.ToLower(h.ID) == target {
			h.Severity = input.Severity
			if input.HazardType != "" {
				h.HazardType = input.HazardType
			}
			if input.WeatherStatus != "" {
				h.WeatherStatus = input.WeatherStatus
			}
			if input.Message != "" {
				h.Message = input.Message
			}
			if input.DetourRoute != "" {
				h.DetourRoute = input.DetourRoute
			}
			if input.TriggeredByAdmin != "" {
				h.TriggeredByAdmin = input.TriggeredByAdmin
			} else {
				h.TriggeredByAdmin = "Panel Trigger Bencana FS-1 (Admin Dispar)"
			}
			h.UpdatedAt = time.Now()
			r.hazardAlerts[i] = h
			return &h, nil
		}
	}
	return nil, errors.New("CORRIDOR_NOT_FOUND")
}

func (r *inMemoryRepository) CreateSOSSignal(input SOSEmergencyInput) models.SOSSignal {
	r.mu.Lock()
	defer r.mu.Unlock()

	if input.TouristName == "" {
		input.TouristName = "Wisatawan Darurat Rancak.in"
	}
	if input.EmergencyType == "" {
		input.EmergencyType = "Kendaraan Mogok / Darurat di Jalur Ekstrem"
	}
	if input.BatteryPercent <= 0 {
		input.BatteryPercent = 35
	}
	if input.PassengersCount <= 0 {
		input.PassengersCount = 2
	}

	nearestCorridor := "Koridor Sitinjau Lauik"
	nearestPost := "Posko Terpadu PKJR & BPBD Panorama 1 Sitinjau Lauik"
	minDistKm := 9999.0

	for _, hz := range r.hazardAlerts {
		d := CalculateSpatialDistanceKm(input.Latitude, input.Longitude, hz.Latitude, hz.Longitude)
		if d < minDistKm {
			minDistKm = d
			nearestCorridor = hz.Location
			nearestPost = hz.NearestRescuePost
		}
	}
	if minDistKm > 50 {
		minDistKm = 2.4
	}
	etaMin := int(math.Max(5, math.Round(minDistKm*4.5)))

	seq := len(r.sosSignals) + 1
	signal := models.SOSSignal{
		ID:                 fmt.Sprintf("sos-%03d", seq),
		SOSCode:            fmt.Sprintf("SOS-SUMBAR-202611-%03d", seq),
		TouristName:        input.TouristName,
		PhoneNumber:        input.PhoneNumber,
		EmergencyType:      input.EmergencyType,
		Latitude:           input.Latitude,
		Longitude:          input.Longitude,
		BatteryPercent:     input.BatteryPercent,
		PassengersCount:    input.PassengersCount,
		NearestCorridor:    nearestCorridor,
		NearestRescuePost:  nearestPost,
		DistanceToRescueKm: math.Round(minDistKm*10) / 10,
		ETARescueMinutes:   etaMin,
		Status:             "Dipancarkan",
		Notes:              input.Notes,
		CreatedAt:          time.Now(),
	}

	r.sosSignals = append([]models.SOSSignal{signal}, r.sosSignals...)
	return signal
}

func (r *inMemoryRepository) ListSOSSignals() []models.SOSSignal {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.sosSignals
}

func (r *inMemoryRepository) RecordNavigationTelemetry(input NavigationTelemetryInput) (*models.GaodeBehaviorRanking, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	normID := strings.ToLower(strings.TrimSpace(input.DestinationID))
	metric, exists := r.telemetries[normID]
	if !exists {
		metric = &models.GaodeBehaviorRanking{
			ID:                     fmt.Sprintf("gaode-%s", normID),
			DestinationID:          input.DestinationID,
			DestinationName:        input.DestinationID,
			ActiveNavCount30d:      2450,
			AvgDwellTimeMin:        input.DwellTimeMinutes,
			ReturnVisitRatePct:     18.5,
			GaodeAuthenticityScore: 88.5,
			Category:               "Wisata Alam",
			TrendingBadge:          "Favorit Wisatawan",
			AntiFakeReviewVerified: true,
			UpdatedAt:              time.Now(),
		}
		r.telemetries[normID] = metric
	} else {
		metric.ActiveNavCount30d++
		metric.AvgDwellTimeMin = (metric.AvgDwellTimeMin + input.DwellTimeMinutes) / 2
		metric.UpdatedAt = time.Now()
	}

	return metric, nil
}
