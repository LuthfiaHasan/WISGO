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
	GetTariffs(idOrSlug string) (*TariffsResponse, error)
	GetOfflineBundle(idOrSlug string) (*OfflineBundleResponse, error)
	CreateCMS(input models.Destination) (models.Destination, error)
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

	return &OfflineBundleResponse{
		BundleVersion:   "v2.0-sprint2-complete",
		GeneratedAt:     time.Now().Format(time.RFC3339),
		LocalStorageSDK: "Flutter Hive / Sqflite Ready",
		OfflineBanner:   "⚡ Mode offline aktif · Tempat siap dibuka tanpa sinyal.",
		Destination:     dest,
		Scenes360:       dest.Scenes360,
		MicroMap:        microMap,
		AudioTriggers:   microMap.AudioTriggers,
	}, nil
}

func (s *service) CreateCMS(input models.Destination) (models.Destination, error) {
	if strings.TrimSpace(input.Name) == "" {
		return models.Destination{}, errors.New("Body JSON tidak valid; field 'name' wajib diisi.")
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
