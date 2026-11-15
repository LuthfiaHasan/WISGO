package scenes360

import (
	"errors"
	"fmt"
	"strings"
	"sync"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka penyimpanan kanvas tur virtual 360° dan pin interaktif
type Repository interface {
	GetScenes360ByDestinationID(destID, destName, cityRegency string) []models.Scene360
	AddScene360CMS(scene models.Scene360) models.Scene360
	AddHotspotToSceneCMS(sceneID string, pin models.Hotspot360) (*models.Scene360, models.Hotspot360, error)
	FindSceneByID(sceneID string) (*models.Scene360, error)
	GetHotspotsBySceneID(sceneID string) ([]models.Hotspot360, error)
	DeleteHotspotCMS(hotspotID string) error
}

type inMemoryRepository struct {
	mu        sync.RWMutex
	scenes360 map[string][]models.Scene360
}

// NewRepository membuat instance baru repository Scenes360 dengan seeder awal
func NewRepository() Repository {
	return &inMemoryRepository{
		scenes360: SeedScenes360(),
	}
}

func (r *inMemoryRepository) GetScenes360ByDestinationID(destID, destName, cityRegency string) []models.Scene360 {
	r.mu.RLock()
	defer r.mu.RUnlock()

	normalizedID := strings.ToLower(strings.TrimSpace(destID))
	if scenes, ok := r.scenes360[normalizedID]; ok && len(scenes) > 0 {
		// Buat salinan agar thread-safe
		result := make([]models.Scene360, len(scenes))
		copy(result, scenes)
		return result
	}

	// Fallback dinamis jika destinasi belum memiliki kanvas 360 spesifik
	return []models.Scene360{
		{
			ID:              fmt.Sprintf("scene-%s-aerial-01", normalizedID),
			DestinationID:   destID,
			Title:           fmt.Sprintf("Panorama Udara %s (Drone 150m)", destName),
			Type:            "aerial",
			PanoramaURL:     fmt.Sprintf("https://cdn.rancak.in/360/%s-aerial.jpg", normalizedID),
			UploadFormat:    "url",
			SpatialAudioURL: "https://cdn.rancak.in/audio/ambient-alam-sumbar.mp3",
			InitialPitch:    -10.0,
			InitialYaw:      180.0,
			IsDefaultScene:  true,
			Hotspots: []models.Hotspot360{
				{
					ID:          fmt.Sprintf("pin-%s-nav-01", normalizedID),
					SceneID:     fmt.Sprintf("scene-%s-aerial-01", normalizedID),
					Type:        "navigasi",
					ColorToken:  "#2563EB",
					Pitch:       -24.0,
					Yaw:         180.0,
					Title:       "Turun ke Spot Utama Darat (Ground 360°)",
					TargetRef:   fmt.Sprintf("scene-%s-ground-01", normalizedID),
					Description: "Transisi mulus dari udara ke titik kunjungan utama.",
				},
				{
					ID:          fmt.Sprintf("pin-%s-mitra-01", normalizedID),
					SceneID:     fmt.Sprintf("scene-%s-aerial-01", normalizedID),
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

func (r *inMemoryRepository) AddScene360CMS(scene models.Scene360) models.Scene360 {
	r.mu.Lock()
	defer r.mu.Unlock()

	destKey := strings.ToLower(strings.TrimSpace(scene.DestinationID))
	existing := r.scenes360[destKey]
	if scene.ID == "" {
		scene.ID = fmt.Sprintf("scene-%s-%02d", destKey, len(existing)+1)
	}
	r.scenes360[destKey] = append(r.scenes360[destKey], scene)
	return scene
}

func (r *inMemoryRepository) AddHotspotToSceneCMS(sceneID string, pin models.Hotspot360) (*models.Scene360, models.Hotspot360, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	targetID := strings.ToLower(strings.TrimSpace(sceneID))
	if targetID == "scn-001" || targetID == "scene-001" || targetID == "scene-1" {
		targetID = "scene-harau-aerial-01"
	}

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

func (r *inMemoryRepository) FindSceneByID(sceneID string) (*models.Scene360, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	targetID := strings.ToLower(strings.TrimSpace(sceneID))
	if targetID == "scn-001" || targetID == "scene-001" || targetID == "scene-1" {
		targetID = "scene-harau-aerial-01"
	}

	for _, scenes := range r.scenes360 {
		for _, sc := range scenes {
			if strings.ToLower(sc.ID) == targetID {
				cpy := sc
				return &cpy, nil
			}
		}
	}
	return nil, errors.New("SCENE_NOT_FOUND")
}

func (r *inMemoryRepository) GetHotspotsBySceneID(sceneID string) ([]models.Hotspot360, error) {
	sc, err := r.FindSceneByID(sceneID)
	if err != nil {
		return nil, err
	}
	return sc.Hotspots, nil
}

func (r *inMemoryRepository) DeleteHotspotCMS(hotspotID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	targetPinID := strings.ToLower(strings.TrimSpace(hotspotID))
	for destID, scenes := range r.scenes360 {
		for sIdx, sc := range scenes {
			for hIdx, pin := range sc.Hotspots {
				if strings.ToLower(pin.ID) == targetPinID {
					sc.Hotspots = append(sc.Hotspots[:hIdx], sc.Hotspots[hIdx+1:]...)
					r.scenes360[destID][sIdx] = sc
					return nil
				}
			}
		}
	}
	return errors.New("HOTSPOT_NOT_FOUND")
}
