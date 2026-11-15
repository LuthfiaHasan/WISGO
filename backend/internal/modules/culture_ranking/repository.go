package culture_ranking

import (
	"errors"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka penyimpanan dan query data Gaode Ranking, Kamus Minang, dan Kalender Budaya
type Repository interface {
	ListGaodeRankings(categoryFilter string) []models.GaodeBehaviorRanking
	ListMinangPhrases(category, searchQuery string) []models.MinangPhrase
	ListCulturalEvents(eventType, cityFilter string, hasGPS bool, userLat, userLng float64) []models.CulturalEvent
	RecordNavigationTelemetry(destinationID string, dwellTimeMinutes int, isRepeatVisit bool) (*models.GaodeBehaviorRanking, error)
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

type inMemoryRepository struct {
	mu             sync.RWMutex
	gaodeRankings  []models.GaodeBehaviorRanking
	minangPhrases  []models.MinangPhrase
	culturalEvents []models.CulturalEvent
}

// NewRepository membuat instance baru repository culture & ranking dengan seeder awal
func NewRepository() Repository {
	return &inMemoryRepository{
		gaodeRankings:  SeedGaodeRankings(),
		minangPhrases:  SeedMinangPhrases(),
		culturalEvents: SeedCulturalEvents(),
	}
}

func (r *inMemoryRepository) ListGaodeRankings(categoryFilter string) []models.GaodeBehaviorRanking {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(categoryFilter))
	var list []models.GaodeBehaviorRanking
	for _, item := range r.gaodeRankings {
		if qCat != "" && !strings.Contains(strings.ToLower(item.Category), qCat) {
			continue
		}
		list = append(list, item)
	}

	sort.Slice(list, func(i, j int) bool {
		return list[i].GaodeAuthenticityScore > list[j].GaodeAuthenticityScore
	})
	for idx := range list {
		list[idx].RankPosition = idx + 1
	}
	return list
}

func (r *inMemoryRepository) RecordNavigationTelemetry(destinationID string, dwellTimeMinutes int, isRepeatVisit bool) (*models.GaodeBehaviorRanking, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	target := strings.ToLower(strings.TrimSpace(destinationID))
	for i, item := range r.gaodeRankings {
		if strings.ToLower(item.DestinationID) == target || strings.ToLower(item.ID) == target {
			item.ActiveNavCount30d += 1
			item.AvgDwellTimeMin = int(math.Round(float64(item.AvgDwellTimeMin)*0.85 + float64(dwellTimeMinutes)*0.15))
			if isRepeatVisit {
				item.ReturnVisitRatePct = math.Min(95.0, math.Round((item.ReturnVisitRatePct+0.4)*10)/10)
			}
			item.GaodeAuthenticityScore = ComputeGaodeScore(item.ActiveNavCount30d, item.AvgDwellTimeMin, item.ReturnVisitRatePct)
			item.UpdatedAt = time.Now()
			r.gaodeRankings[i] = item

			sort.Slice(r.gaodeRankings, func(a, b int) bool {
				return r.gaodeRankings[a].GaodeAuthenticityScore > r.gaodeRankings[b].GaodeAuthenticityScore
			})
			for idx := range r.gaodeRankings {
				r.gaodeRankings[idx].RankPosition = idx + 1
				if r.gaodeRankings[idx].DestinationID == item.DestinationID {
					updatedCopy := r.gaodeRankings[idx]
					return &updatedCopy, nil
				}
			}
			return &item, nil
		}
	}
	return nil, errors.New("DESTINATION_NOT_FOUND")
}

func (r *inMemoryRepository) ListMinangPhrases(category, searchQuery string) []models.MinangPhrase {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(category))
	qSearch := strings.ToLower(strings.TrimSpace(searchQuery))

	var list []models.MinangPhrase
	for _, p := range r.minangPhrases {
		if qCat != "" && !strings.Contains(strings.ToLower(p.Category), qCat) {
			continue
		}
		if qSearch != "" {
			matched := strings.Contains(strings.ToLower(p.IndonesianText), qSearch) ||
				strings.Contains(strings.ToLower(p.MinangText), qSearch) ||
				strings.Contains(strings.ToLower(p.UsageContextTip), qSearch)
			if !matched {
				continue
			}
		}
		list = append(list, p)
	}
	return list
}

func (r *inMemoryRepository) ListCulturalEvents(eventType, cityFilter string, hasGPS bool, userLat, userLng float64) []models.CulturalEvent {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qType := strings.ToLower(strings.TrimSpace(eventType))
	qCity := strings.ToLower(strings.TrimSpace(cityFilter))

	var list []models.CulturalEvent
	for _, ev := range r.culturalEvents {
		if qType != "" && !strings.Contains(strings.ToLower(ev.EventType), qType) {
			continue
		}
		if qCity != "" && !strings.Contains(strings.ToLower(ev.CityRegency), qCity) && !strings.Contains(strings.ToLower(ev.NagariLocation), qCity) {
			continue
		}
		item := ev
		if hasGPS {
			item.DistanceKm = CalculateSpatialDistanceKm(userLat, userLng, ev.Latitude, ev.Longitude)
		} else {
			item.DistanceKm = CalculateSpatialDistanceKm(-0.9471, 100.4172, ev.Latitude, ev.Longitude)
		}
		list = append(list, item)
	}
	return list
}
