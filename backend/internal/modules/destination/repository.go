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
	GetCategories() []models.Category
	CreateCMS(input models.Destination) models.Destination
	UpdateCMS(id string, payload models.Destination) (*models.Destination, error)
	DeleteCMS(id string) (string, error)
	SyncTariffsCMS(id string, tariffs []models.OfficialTariff) (*models.Destination, error)
	FindPending() []models.Destination
	VerifyDestination(id string, status string) (*models.Destination, error)
	SaveOfflineBundle(destID, version string, payloadJSON []byte)

	// Meja Kurasi Usulan Destinasi Wisatawan (Tabel new_tour)
	ListNewTours(statusFilter string) []models.NewTour
	UpsertNewTour(tour models.NewTour) models.NewTour
	ApproveNewTourToDestination(id string) (*models.Destination, *models.NewTour, error)
	RejectNewTour(id string, reason string) (*models.NewTour, error)
	MergeNewToursToDestination(req MergeNewToursInput) (*models.Destination, []models.NewTour, error)
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
	newTours     []models.NewTour
}

// NewRepository membuat instance repository baru dengan initial seeder 20 Destinasi Sumbar + new_tour
func NewRepository() Repository {
	return &inMemoryRepository{
		destinations: Seed20DestinationsSumbar(),
		newTours:     models.GetDefaultNewTours(),
	}
}

func (r *inMemoryRepository) FindAllWithSpatial(params SpatialFilterParams) []models.Destination {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(params.Category))
	qCatID := strings.ToLower(strings.TrimSpace(params.CategoryID))
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

		if qCatID != "" && strings.ToLower(d.CategoryID) != qCatID {
			continue
		}
		if qCat != "" && !strings.Contains(strings.ToLower(d.Category), qCat) && strings.ToLower(d.CategoryID) != qCat {
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
			if item.Weather == nil {
				item.Weather = GetRealtimeWeather(d.Latitude, d.Longitude, item.CityRegency)
				if item.Weather != nil {
					item.WeatherStatus = item.Weather.WeatherStatus
				}
			}
			return &item, nil
		}
	}
	return nil, fmt.Errorf("Destinasi '%s' tidak ditemukan", idOrSlugOrQR)
}

func (r *inMemoryRepository) GetCategories() []models.Category {
	r.mu.RLock()
	defer r.mu.RUnlock()

	categories := models.GetDefaultCategories()
	counts := make(map[string]int)
	for _, d := range r.destinations {
		if d.VerificationStatus != "pending" && d.VerificationStatus != "rejected" {
			counts[d.CategoryID]++
		}
	}

	for i := range categories {
		if cnt, ok := counts[categories[i].ID]; ok {
			categories[i].DestinationCount = cnt
		}
	}
	return categories
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

func (r *inMemoryRepository) SaveOfflineBundle(destID, version string, payloadJSON []byte) {}

func (r *inMemoryRepository) ListNewTours(statusFilter string) []models.NewTour {
	r.mu.RLock()
	defer r.mu.RUnlock()

	st := strings.ToLower(strings.TrimSpace(statusFilter))
	if st == "" || st == "all" {
		out := make([]models.NewTour, len(r.newTours))
		copy(out, r.newTours)
		return out
	}

	var results []models.NewTour
	for _, n := range r.newTours {
		if strings.ToLower(n.Status) == st {
			results = append(results, n)
		}
	}
	return results
}

func (r *inMemoryRepository) UpsertNewTour(tour models.NewTour) models.NewTour {
	r.mu.Lock()
	defer r.mu.Unlock()

	if strings.TrimSpace(tour.ID) == "" {
		tour.ID = fmt.Sprintf("nt-%d", time.Now().UnixNano()%1000000)
	}
	if strings.TrimSpace(tour.UserID) == "" {
		tour.UserID = "usr-tourist-01"
	}
	if strings.TrimSpace(tour.CategoryID) == "" {
		tour.CategoryID = mapCategoryNameToID(tour.Category, tour.Name, tour.IsSensitive)
	}
	tour.Category = mapCategoryIDToName(tour.CategoryID)
	if strings.TrimSpace(tour.Status) == "" {
		tour.Status = "pending"
	}
	if strings.TrimSpace(tour.SubmitterName) == "" {
		tour.SubmitterName = "Wisatawan Komunitas WISGO"
	}
	if strings.TrimSpace(tour.SubmitterPhone) == "" {
		tour.SubmitterPhone = "6281234567890"
	}
	if strings.TrimSpace(tour.PhotoURL) == "" {
		tour.PhotoURL = "https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=900&q=80"
	}
	if strings.TrimSpace(tour.CreatedAt) == "" {
		tour.CreatedAt = time.Now().Format(time.RFC3339)
	}

	for i, existing := range r.newTours {
		if strings.EqualFold(existing.ID, tour.ID) {
			r.newTours[i] = tour
			return tour
		}
	}
	r.newTours = append([]models.NewTour{tour}, r.newTours...)
	return tour
}

func buildDestinationFromNewTour(tour models.NewTour) models.Destination {
	newID := fmt.Sprintf("dest-%d", time.Now().UnixNano()%1000000)
	catID := tour.CategoryID
	if catID == "" {
		catID = mapCategoryNameToID(tour.Category, tour.Name, tour.IsSensitive)
	}
	catName := mapCategoryIDToName(catID)

	vehicleAccess := "Hanya Motor"
	trekkingLevel := "Mudah (Datar)"
	guideNeed := "Mandiri"
	for _, f := range tour.Facilities {
		fl := strings.ToLower(f)
		if strings.Contains(fl, "parkir") {
			vehicleAccess = "Mobil OK"
		}
		if strings.Contains(fl, "trekking") {
			trekkingLevel = "Sedang"
		}
		if strings.Contains(fl, "pemandu") {
			guideNeed = "Disarankan"
		}
	}
	facLevel := "Belum Ada"
	if len(tour.Facilities) >= 4 {
		facLevel = "Toilet, Musala & Parkir Lengkap"
	} else if len(tour.Facilities) >= 1 {
		facLevel = "Terbatas"
	}

	cover := tour.PhotoURL
	if cover == "" {
		cover = "https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=1200&q=80"
	}

	distKm := CalculateSpatialDistanceKm(-0.9471, 100.4172, tour.Latitude, tour.Longitude)
	travelMin := EstimateSumbarTravelMinutes(distKm)

	return models.Destination{
		ID:                 newID,
		Slug:               strings.ToLower(strings.ReplaceAll(strings.TrimSpace(tour.Name), " ", "-")),
		Name:               tour.Name,
		CategoryID:         catID,
		Category:           catName,
		CityRegency:        tour.CityRegency,
		Description:        tour.Description,
		Latitude:           tour.Latitude,
		Longitude:          tour.Longitude,
		ElevationM:         250,
		CoverImage:         cover,
		CrowdLevel:         "Sepi",
		DistanceKm:         distKm,
		TravelTimeMin:      travelMin,
		EstimatedCost:      10000,
		IsHiddenGem:        catID == "cat-hidden-gem" || tour.IsSensitive,
		VerificationStatus: "verified",
		QRPlacardCode:      fmt.Sprintf("WISGO-PLG-%d", time.Now().Unix()%10000),
		OpeningHours:       "08.00 - 17.00 WIB",
		MedanIndicator: &models.MedanIndicator{
			ID:             fmt.Sprintf("med-%s", newID),
			DestinationID:  newID,
			VehicleAccess:  vehicleAccess,
			TrekkingLevel:  trekkingLevel,
			CellularSignal: "4G Kuat",
			Facilities:     facLevel,
			GuideNeed:      guideNeed,
		},
		Tips: []models.LocalTip{
			{
				ID:            fmt.Sprintf("art-%d", time.Now().UnixNano()%100000),
				DestinationID: newID,
				CategoryID:    "cat-rule-lingkungan",
				Title:         "Tips Menjaga Tempat Ini",
				Content:       tour.TipsMenjaga,
				Aturan:        tour.TipsMenjaga,
				IsImportant:   true,
			},
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

func (r *inMemoryRepository) ApproveNewTourToDestination(id string) (*models.Destination, *models.NewTour, error) {
	r.mu.Lock()
	var target *models.NewTour
	targetIdx := -1
	for i, n := range r.newTours {
		if strings.EqualFold(n.ID, id) {
			cp := n
			target = &cp
			targetIdx = i
			break
		}
	}
	if target == nil {
		r.mu.Unlock()
		return nil, nil, fmt.Errorf("Usulan new_tour '%s' tidak ditemukan", id)
	}

	dest := buildDestinationFromNewTour(*target)
	target.Status = "approved"
	target.MergedIntoDestinationID = dest.ID
	target.MergedRole = "Pengusul Utama"
	r.newTours[targetIdx] = *target
	r.destinations = append([]models.Destination{dest}, r.destinations...)
	r.mu.Unlock()

	return &dest, target, nil
}

func (r *inMemoryRepository) RejectNewTour(id string, reason string) (*models.NewTour, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if strings.TrimSpace(reason) == "" {
		reason = "Belum memenuhi kriteria kurasi Dispar Sumbar."
	}
	for i, n := range r.newTours {
		if strings.EqualFold(n.ID, id) {
			r.newTours[i].Status = "rejected"
			r.newTours[i].AdminNotes = reason
			updated := r.newTours[i]
			return &updated, nil
		}
	}
	return nil, fmt.Errorf("Usulan new_tour '%s' tidak ditemukan", id)
}

func (r *inMemoryRepository) MergeNewToursToDestination(req MergeNewToursInput) (*models.Destination, []models.NewTour, error) {
	r.mu.Lock()
	var matched []models.NewTour
	idSet := make(map[string]bool)
	for _, sid := range req.SubmissionIDs {
		idSet[strings.ToLower(strings.TrimSpace(sid))] = true
	}
	for _, sub := range req.Submissions {
		idSet[strings.ToLower(strings.TrimSpace(sub.ID))] = true
	}

	for _, n := range r.newTours {
		if idSet[strings.ToLower(n.ID)] {
			matched = append(matched, n)
		}
	}
	if len(matched) == 0 && len(req.Submissions) > 0 {
		matched = req.Submissions
	}
	if len(matched) == 0 {
		r.mu.Unlock()
		return nil, nil, fmt.Errorf("Tidak ada usulan new_tour yang ditemukan untuk digabungkan")
	}

	primarySub := matched[0]
	photoSub := matched[0]
	for _, s := range matched {
		if strings.EqualFold(s.ID, req.PrimaryDataSubmissionID) {
			primarySub = s
		}
		if strings.EqualFold(s.ID, req.CoverPhotoSubmissionID) {
			photoSub = s
		}
	}

	mergedTour := primarySub
	if strings.TrimSpace(req.CustomName) != "" {
		mergedTour.Name = strings.TrimSpace(req.CustomName)
	}
	if strings.TrimSpace(req.CustomDescription) != "" {
		mergedTour.Description = strings.TrimSpace(req.CustomDescription)
	}
	if strings.TrimSpace(req.CustomTips) != "" {
		mergedTour.TipsMenjaga = strings.TrimSpace(req.CustomTips)
	}
	if photoSub.PhotoURL != "" {
		mergedTour.PhotoURL = photoSub.PhotoURL
	}

	dest := buildDestinationFromNewTour(mergedTour)
	var updatedTours []models.NewTour

	for i, n := range r.newTours {
		if idSet[strings.ToLower(n.ID)] {
			isPrimary := strings.EqualFold(n.ID, primarySub.ID)
			isPhoto := strings.EqualFold(n.ID, photoSub.ID)
			role := "Pengusul Bersama"
			if isPrimary && isPhoto {
				role = "Pengusul Utama"
			} else if isPrimary {
				role = "Kontributor Data & Tips"
			} else if isPhoto {
				role = "Kontributor Foto"
			}
			r.newTours[i].Status = "approved"
			r.newTours[i].MergedIntoDestinationID = dest.ID
			r.newTours[i].MergedRole = role
			r.newTours[i].AdminNotes = fmt.Sprintf("Digabungkan menjadi destinasi '%s' sebagai %s.", dest.Name, role)
			updatedTours = append(updatedTours, r.newTours[i])
		}
	}
	r.destinations = append([]models.Destination{dest}, r.destinations...)
	r.mu.Unlock()

	return &dest, updatedTours, nil
}


