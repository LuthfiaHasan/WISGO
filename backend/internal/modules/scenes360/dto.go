package scenes360

import (
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ResolvePinColorToken memastikan 4 jenis Pin Interaktif 360° mengikuti token warna desain sistem WISGO
func ResolvePinColorToken(pinType string) string {
	switch strings.ToLower(strings.TrimSpace(pinType)) {
	case "navigasi":
		return "#2563EB" // Biru — Pindah titik aerial <-> ground
	case "audio":
		return "#D97706" // Emas — Putar cerita sejarah & adat
	case "fasilitas":
		return "#1E9E5A" // Hijau — Info toilet, musala, parkir, sinyal
	case "mitra":
		return "#E85D1A" // Oranye — Buka Quick Booking Drawer Mitra Nagari
	default:
		return "#2563EB"
	}
}

// Scenes360Response respon terstandarisasi untuk kanvas penjelajah tur panorama view (Poin 9)
type Scenes360Response struct {
	DestinationID   string            `json:"destination_id"`
	DestinationName string            `json:"destination_name"`
	CityRegency     string            `json:"city_regency"`
	ViewMode        string            `json:"view_mode"`        // photo_panorama (Pilar 1 - Penyederhanaan panorama view ringan)
	ImageResolution string            `json:"image_resolution"` // 4K Equirectangular Panorama
	TotalScenes     int               `json:"total_scenes"`
	PinLegend       map[string]string `json:"pin_legend"`
	Scenes360       []models.Scene360 `json:"scenes_360"`
}

// CreateScene360Request payload pembuatan kanvas 360° baru dari CMS Studio Web Admin FS-1
type CreateScene360Request struct {
	DestinationID   string  `json:"destination_id"`
	Title           string  `json:"title"`
	Type            string  `json:"type"` // aerial | ground
	PanoramaURL     string  `json:"panorama_url"`
	PanoramaBase64  string  `json:"panorama_base64,omitempty"`
	SpatialAudioURL string  `json:"spatial_audio_url,omitempty"`
	InitialPitch    float64 `json:"initial_pitch"`
	InitialYaw      float64 `json:"initial_yaw"`
	IsDefaultScene  bool    `json:"is_default_scene"`
}

// AttachHotspotResponse respon sukses penempelan Pin 360° pada CMS Studio
type AttachHotspotResponse struct {
	Status        string          `json:"status"`
	SceneID       string          `json:"scene_id"`
	SceneTitle    string          `json:"scene_title"`
	AttachedPin   models.Hotspot360 `json:"attached_pin"`
	TotalHotspots int             `json:"total_hotspots"`
}
