package destination

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis destinasi, detail agregat, offline bundle, dan CMS
type Service interface {
	FindAllWithSpatial(params SpatialFilterParams) []models.Destination
	FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error)
	GetCategories() *CategoriesResponse
	GetTariffs(idOrSlug string) (*TariffsResponse, error)
	GetOfflineBundle(idOrSlug string) (*OfflineBundleResponse, error)
	CreateCMS(input models.Destination) (models.Destination, error)
	CreateHiddenGem(input CreateHiddenGemInput) (models.Destination, error)
	GetPendingSubmissions() []models.Destination
	VerifySubmission(id string, status string) (*models.Destination, error)
	UpdateCMS(id string, payload models.Destination) (*models.Destination, error)
	DeleteCMS(id string) (string, error)
	SyncTariffsCMS(id string, tariffs []models.OfficialTariff) (*models.Destination, error)
}

type service struct {
	repo Repository
}

// NewService membuat instance service baru
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) FindAllWithSpatial(params SpatialFilterParams) []models.Destination {
	return s.repo.FindAllWithSpatial(params)
}

func (s *service) FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error) {
	return s.repo.FindByID(idOrSlugOrQR, hasUserGPS, userLat, userLng)
}

func (s *service) GetCategories() *CategoriesResponse {
	categories := s.repo.GetCategories()
	return &CategoriesResponse{
		Status:     "success",
		Total:      len(categories),
		Categories: categories,
	}
}

func (s *service) GetTariffs(idOrSlug string) (*TariffsResponse, error) {
	dest, err := s.repo.FindByID(idOrSlug, false, 0, 0)
	if err != nil {
		return nil, err
	}

	return &TariffsResponse{
		DestinationID:   dest.ID,
		DestinationName: dest.Name,
		CityRegency:     dest.CityRegency,
		Tariffs:         dest.Tariffs,
	}, nil
}

func (s *service) GetOfflineBundle(idOrSlug string) (*OfflineBundleResponse, error) {
	dest, err := s.repo.FindByID(idOrSlug, false, 0, 0)
	if err != nil {
		return nil, err
	}

	microMap := &models.ScenicMicroMap{
		ID:                  fmt.Sprintf("micromap-%s", dest.ID),
		DestinationID:       dest.ID,
		DestinationName:     dest.Name,
		AreaSizeHectare:     15.0,
		WalkwayGeoJSON:      fmt.Sprintf(`{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"Jalur Pejalan Kaki %s"},"geometry":{"type":"LineString","coordinates":[[%f,%f],[%f,%f]]}}]}`, dest.Name, dest.Longitude, dest.Latitude, dest.Longitude+0.0008, dest.Latitude+0.0008),
		ChildFriendlyPath:   true,
		ElderlyFriendlyPath: true,
		InternalPOIs:        []models.MicroMapPOI{},
		AudioTriggers: []models.AudioTriggerPoint{
			{
				ID:              fmt.Sprintf("audio-%s-01", dest.ID),
				DestinationID:   dest.ID,
				Title:           fmt.Sprintf("Pintu Masuk %s", dest.Name),
				Latitude:        dest.Latitude,
				Longitude:       dest.Longitude,
				TriggerRadiusM:  15.0,
				AudioURLID:      fmt.Sprintf("https://cdn.wisgo.sumbarprov.go.id/audio/%s-intro.mp3", dest.Slug),
				TranscriptShort: fmt.Sprintf("Selamat datang di %s nan rancak.", dest.Name),
			},
		},
	}

	contacts := models.GetDefaultEmergencyContacts()
	callProtocol := models.GetDefaultEmergencyCallProtocol()

	return &OfflineBundleResponse{
		BundleVersion:         "v2.1-offline-sos",
		GeneratedAt:           time.Now().Format(time.RFC3339),
		LocalStorageSDK:       "Flutter Hive / Sqflite Ready",
		OfflineBanner:         "⚡ Mode offline aktif · Tempat & Nomor Darurat siap dibuka tanpa sinyal.",
		Destination:           dest,
		Scenes360:             dest.Scenes360,
		MicroMap:              microMap,
		AudioTriggers:         microMap.AudioTriggers,
		EmergencyContacts:     contacts,
		EmergencyCallProtocol: &callProtocol,
	}, nil
}

func (s *service) CreateCMS(input models.Destination) (models.Destination, error) {
	if strings.TrimSpace(input.Name) == "" {
		return models.Destination{}, errors.New("Body JSON tidak valid; field 'name' wajib diisi.")
	}
	if input.VerificationStatus == "" {
		input.VerificationStatus = "verified"
	}
	return s.repo.CreateCMS(input), nil
}

func (s *service) UpdateCMS(id string, payload models.Destination) (*models.Destination, error) {
	return s.repo.UpdateCMS(id, payload)
}

func (s *service) DeleteCMS(id string) (string, error) {
	return s.repo.DeleteCMS(id)
}

func (s *service) SyncTariffsCMS(id string, tariffs []models.OfficialTariff) (*models.Destination, error) {
	if len(tariffs) == 0 {
		return nil, errors.New("Wajib menyertakan minimal 1 item tarif resmi Perda pada array 'tariffs' atau 'official_tariffs'.")
	}
	return s.repo.SyncTariffsCMS(id, tariffs)
}

func (s *service) CreateHiddenGem(input CreateHiddenGemInput) (models.Destination, error) {
	if strings.TrimSpace(input.Name) == "" {
		return models.Destination{}, errors.New("Field 'name' wajib diisi untuk menginput wisata hidden gem.")
	}

	crowd := "Sepi"
	if strings.TrimSpace(input.CrowdLevel) != "" {
		crowd = input.CrowdLevel
	}

	dest := models.Destination{
		Name:               strings.TrimSpace(input.Name),
		Category:           "Hidden Gem",
		CityRegency:        strings.TrimSpace(input.CityRegency),
		Description:        strings.TrimSpace(input.Description),
		Latitude:           input.Latitude,
		Longitude:          input.Longitude,
		ElevationM:         input.ElevationM,
		CoverImage:         strings.TrimSpace(input.CoverImage),
		CrowdLevel:         crowd,
		IsHiddenGem:        true,
		VerificationStatus: "pending", // Wajib kurasi verifikasi admin sebelum tayang publik
		EstimatedCost:      0,
	}

	if dest.CityRegency == "" {
		dest.CityRegency = "Sumatera Barat"
	}

	if dest.CoverImage == "" {
		dest.CoverImage = "https://images.unsplash.com/photo-1518457607834-6e8d80c183c5?auto=format&fit=crop&w=1200&q=80"
	}

	// Buat Tips Menjaga Tempat & Kelestarian (Wajib Hidden Gem)
	var tips []models.LocalTip
	if strings.TrimSpace(input.TipsMenjaga) != "" {
		tips = append(tips, models.LocalTip{
			ID:          fmt.Sprintf("tip-%d", time.Now().UnixNano()),
			Title:       "Tips Menjaga Kelestarian Alam",
			Category:    "kelestarian_alam",
			Content:     strings.TrimSpace(input.TipsMenjaga),
			IsImportant: true,
		})
	} else {
		tips = append(tips, models.LocalTip{
			ID:          fmt.Sprintf("tip-%d", time.Now().UnixNano()),
			Title:       "Edukasi Kelestarian Hidden Gem",
			Category:    "kelestarian_alam",
			Content:     "Bawa pulang sampah Anda, jaga keasrian alam, dan hormati kearifan lokal Minangkabau.",
			IsImportant: true,
		})
	}

	if strings.TrimSpace(input.TipsAdat) != "" {
		tips = append(tips, models.LocalTip{
			ID:          fmt.Sprintf("tip-%d-adat", time.Now().UnixNano()),
			Title:       "Etika Adat Minangkabau",
			Category:    "etika_adat",
			Content:     strings.TrimSpace(input.TipsAdat),
			IsImportant: true,
		})
	}
	dest.Tips = tips

	// 5 Indikator Medan Lapangan
	medan := &models.MedanIndicator{
		VehicleAccess:  "Hanya Motor / Jalan Kaki",
		TrekkingLevel:  "Sedang",
		CellularSignal: "Blank Spot",
		Facilities:     "Belum Ada",
		GuideNeed:      "Disarankan",
	}
	if strings.TrimSpace(input.VehicleAccess) != "" {
		medan.VehicleAccess = input.VehicleAccess
	}
	if strings.TrimSpace(input.TrekkingLevel) != "" {
		medan.TrekkingLevel = input.TrekkingLevel
	}
	if strings.TrimSpace(input.CellularSignal) != "" {
		medan.CellularSignal = input.CellularSignal
	}
	if strings.TrimSpace(input.Facilities) != "" {
		medan.Facilities = input.Facilities
	}
	if strings.TrimSpace(input.GuideNeed) != "" {
		medan.GuideNeed = input.GuideNeed
	}
	dest.MedanIndicator = medan

	created := s.repo.CreateCMS(dest)
	return created, nil
}

func (s *service) GetPendingSubmissions() []models.Destination {
	return s.repo.FindPending()
}

func (s *service) VerifySubmission(id string, status string) (*models.Destination, error) {
	st := strings.ToLower(strings.TrimSpace(status))
	if st == "approved" {
		st = "verified"
	}
	if st != "verified" && st != "rejected" && st != "pending" {
		return nil, errors.New("Status verifikasi harus 'verified', 'approved', atau 'rejected'.")
	}
	return s.repo.VerifyDestination(id, st)
}
