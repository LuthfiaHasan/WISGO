package destination

import (
	"fmt"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka penyimpanan data destinasi dan kalkulasi spasial
type Repository interface {
	FindAllWithSpatial(params SpatialFilterParams) []models.Destination
	FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error)
	CreateCMS(input models.Destination) models.Destination
	UpdateCMS(id string, payload models.Destination) (*models.Destination, error)
	DeleteCMS(id string) (string, error)
	SyncTariffsCMS(id string, tariffs []models.OfficialTariff) (*models.Destination, error)
	FindPending() []models.Destination
	VerifyDestination(id string, status string) (*models.Destination, error)
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

// EstimateSumbarTravelMinutes estimasi waktu tempuh jalan lintas Sumatera Barat (rata-rata 38 km/jam)
func EstimateSumbarTravelMinutes(distanceKm float64) int {
	return int(math.Max(10, math.Round((distanceKm/38.0)*60)))
}

type inMemoryRepository struct {
	mu           sync.RWMutex
	destinations []models.Destination
}

// NewRepository membuat instance repository baru dengan initial seeder 20 Destinasi Sumbar
func NewRepository() Repository {
	return &inMemoryRepository{
		destinations: Seed20DestinationsSumbar(),
	}
}

func (r *inMemoryRepository) FindAllWithSpatial(params SpatialFilterParams) []models.Destination {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(params.Category))
	qCity := strings.ToLower(strings.TrimSpace(params.CityRegency))
	qCrowd := strings.ToLower(strings.TrimSpace(params.CrowdLevel))
	qSig := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(params.Signal), "_", " "))
	qSearch := strings.ToLower(strings.TrimSpace(params.SearchQuery))

	var results []models.Destination
	for _, d := range r.destinations {
		// Filter status verifikasi: Default publik hanya menampilkan yang terverifikasi (bukan pending / rejected)
		if !params.IncludePending {
			if d.VerificationStatus == "pending" || d.VerificationStatus == "rejected" {
				continue
			}
		} else if params.VerificationStatus != "" && d.VerificationStatus != params.VerificationStatus {
			continue
		}

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

func (r *inMemoryRepository) FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error) {
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
	return nil, fmt.Errorf("Destinasi '%s' tidak ditemukan", idOrSlugOrQR)
}

func (r *inMemoryRepository) CreateCMS(input models.Destination) models.Destination {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()
	if input.ID == "" {
		input.ID = fmt.Sprintf("dest-%03d", len(r.destinations)+1)
	}
	if input.Slug == "" {
		input.Slug = strings.ToLower(strings.ReplaceAll(input.Name, " ", "-"))
	}
	input.CreatedAt = now
	input.UpdatedAt = now
	r.destinations = append(r.destinations, input)
	return input
}

func (r *inMemoryRepository) UpdateCMS(id string, payload models.Destination) (*models.Destination, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(id))
	for i, d := range r.destinations {
		if strings.ToLower(d.ID) == key || strings.ToLower(d.Slug) == key {
			if payload.Name != "" {
				r.destinations[i].Name = payload.Name
			}
			if payload.Category != "" {
				r.destinations[i].Category = payload.Category
			}
			if payload.CityRegency != "" {
				r.destinations[i].CityRegency = payload.CityRegency
			}
			if payload.Description != "" {
				r.destinations[i].Description = payload.Description
			}
			if payload.CrowdLevel != "" {
				r.destinations[i].CrowdLevel = payload.CrowdLevel
			}
			if payload.MedanIndicator != nil {
				r.destinations[i].MedanIndicator = payload.MedanIndicator
			}
			if len(payload.Tariffs) > 0 {
				r.destinations[i].Tariffs = payload.Tariffs
			}
			r.destinations[i].UpdatedAt = time.Now()
			res := r.destinations[i]
			return &res, nil
		}
	}
	return nil, fmt.Errorf("Destinasi '%s' tidak ditemukan", id)
}

func (r *inMemoryRepository) DeleteCMS(id string) (string, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(id))
	for i, d := range r.destinations {
		if strings.ToLower(d.ID) == key || strings.ToLower(d.Slug) == key {
			deletedID := d.ID
			r.destinations = append(r.destinations[:i], r.destinations[i+1:]...)
			return deletedID, nil
		}
	}
	return "", fmt.Errorf("Destinasi '%s' tidak ditemukan", id)
}

func (r *inMemoryRepository) SyncTariffsCMS(id string, tariffs []models.OfficialTariff) (*models.Destination, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(id))
	for i, d := range r.destinations {
		if strings.ToLower(d.ID) == key || strings.ToLower(d.Slug) == key {
			r.destinations[i].Tariffs = tariffs
			r.destinations[i].UpdatedAt = time.Now()
			res := r.destinations[i]
			return &res, nil
		}
	}
	return nil, fmt.Errorf("Destinasi '%s' tidak ditemukan", id)
}

func (r *inMemoryRepository) FindPending() []models.Destination {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var results []models.Destination
	for _, d := range r.destinations {
		if d.VerificationStatus == "pending" {
			results = append(results, d)
		}
	}
	return results
}

func (r *inMemoryRepository) VerifyDestination(id string, status string) (*models.Destination, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(id))
	for i, d := range r.destinations {
		if strings.ToLower(d.ID) == key || strings.ToLower(d.Slug) == key {
			r.destinations[i].VerificationStatus = status
			r.destinations[i].UpdatedAt = time.Now()
			res := r.destinations[i]
			return &res, nil
		}
	}
	return nil, fmt.Errorf("Destinasi '%s' tidak ditemukan untuk diverifikasi", id)
}
