package scenes360

import (
	"errors"
	"fmt"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
)

// Service antarmuka logika bisnis penjelajah 360° dan CMS Studio
type Service interface {
	GetScenesByDestination(idOrSlug string) (*Scenes360Response, error)
	CreateSceneCMS(req CreateScene360Request, uploadFormat string) (*models.Scene360, error)
	AddHotspotCMS(sceneID string, pin models.Hotspot360) (*models.Scene360, *models.Hotspot360, error)
	GetHotspots(sceneID string) ([]models.Hotspot360, error)
	DeleteHotspot(hotspotID string) error
}

type service struct {
	repo     Repository
	destRepo destination.Repository
}

// NewService membuat instance Service baru untuk modul scenes360
func NewService(repo Repository, destRepo destination.Repository) Service {
	return &service{
		repo:     repo,
		destRepo: destRepo,
	}
}

func (s *service) GetScenesByDestination(idOrSlug string) (*Scenes360Response, error) {
	dest, err := s.destRepo.FindByID(idOrSlug, false, 0, 0)
	if err != nil {
		return nil, errors.New("DESTINATION_NOT_FOUND")
	}

	scenes := s.repo.GetScenes360ByDestinationID(dest.ID, dest.Name, dest.CityRegency)

	return &Scenes360Response{
		DestinationID:   dest.ID,
		DestinationName: dest.Name,
		CityRegency:     dest.CityRegency,
		TotalScenes:     len(scenes),
		PinLegend: map[string]string{
			"navigasi":  "#2563EB (Biru — Transisi Aerial-to-Ground)",
			"audio":     "#D97706 (Emas — Cerita Sejarah & Adat Minang)",
			"fasilitas": "#1E9E5A (Hijau — Info Toilet, Musala & Parkir)",
			"mitra":     "#E85D1A (Oranye — Quick Booking Mitra Nagari)",
		},
		Scenes360: scenes,
	}, nil
}

func (s *service) CreateSceneCMS(req CreateScene360Request, uploadFormat string) (*models.Scene360, error) {
	if strings.TrimSpace(req.DestinationID) == "" || strings.TrimSpace(req.Title) == "" {
		return nil, errors.New("MISSING_REQUIRED_FIELDS")
	}

	sceneType := strings.ToLower(strings.TrimSpace(req.Type))
	if sceneType == "" {
		sceneType = "ground"
	}

	panoramaURL := strings.TrimSpace(req.PanoramaURL)
	if panoramaURL == "" {
		panoramaURL = "https://cdn.rancak.in/360/default-sumbar-equirectangular.jpg"
	}

	scene := models.Scene360{
		DestinationID:   req.DestinationID,
		Title:           req.Title,
		Type:            sceneType,
		PanoramaURL:     panoramaURL,
		UploadFormat:    uploadFormat,
		SpatialAudioURL: req.SpatialAudioURL,
		InitialPitch:    req.InitialPitch,
		InitialYaw:      req.InitialYaw,
		IsDefaultScene:  req.IsDefaultScene,
		Hotspots:        []models.Hotspot360{},
	}

	created := s.repo.AddScene360CMS(scene)
	return &created, nil
}

func (s *service) AddHotspotCMS(sceneID string, pin models.Hotspot360) (*models.Scene360, *models.Hotspot360, error) {
	if strings.TrimSpace(pin.Title) == "" {
		return nil, nil, errors.New("INVALID_HOTSPOT_PAYLOAD")
	}

	if pin.Pitch < -90.0 || pin.Pitch > 90.0 || pin.Yaw < 0.0 || pin.Yaw > 360.0 {
		return nil, nil, errors.New("INVALID_SPHERICAL_COORDS")
	}

	pinType := strings.ToLower(strings.TrimSpace(pin.Type))
	if pinType == "" {
		pinType = "navigasi"
	}
	pin.Type = pinType
	pin.ColorToken = ResolvePinColorToken(pinType)

	updatedScene, createdPin, err := s.repo.AddHotspotToSceneCMS(sceneID, pin)
	if err != nil {
		return nil, nil, fmt.Errorf("SCENE_NOT_FOUND: %w", err)
	}

	return updatedScene, &createdPin, nil
}

func (s *service) GetHotspots(sceneID string) ([]models.Hotspot360, error) {
	return s.repo.GetHotspotsBySceneID(sceneID)
}

func (s *service) DeleteHotspot(hotspotID string) error {
	return s.repo.DeleteHotspotCMS(hotspotID)
}
