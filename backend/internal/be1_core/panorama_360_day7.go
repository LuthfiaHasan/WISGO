package be1_core

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ResolvePinColorToken memastikan 4 jenis Pin Interaktif 360° mengikuti token warna desain.md
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

// 1. GetDestinationScenes360 — GET /api/v1/destinations/{id}/scenes-360 (Hari 7 & Dipercepat Cache ETag Hari 17)
func (h *HandlerBE1) GetDestinationScenes360(w http.ResponseWriter, r *http.Request) {
	idOrSlug := r.PathValue("id")
	cacheKey := fmt.Sprintf("scenes360:%s", idOrSlug)

	h.cache.WriteCachedJSON(w, r, cacheKey, func() (interface{}, int, error) {
		dest, err := h.repo.FindAggregateDetail(idOrSlug, false, 0, 0)
		if err != nil {
			return map[string]string{
				"status":  "error",
				"code":    "DESTINATION_NOT_FOUND",
				"message": "Destinasi tidak ditemukan untuk pemuatan kanvas 360°.",
			}, http.StatusNotFound, err
		}

		scenes := h.repo.GetScenes360ByDestinationID(dest.ID)
		return map[string]interface{}{
			"destination_id":   dest.ID,
			"destination_name": dest.Name,
			"city_regency":     dest.CityRegency,
			"total_scenes":     len(scenes),
			"pin_legend": map[string]string{
				"navigasi":  "#2563EB (Biru — Transisi Aerial-to-Ground)",
				"audio":     "#D97706 (Emas — Cerita Sejarah & Adat Minang)",
				"fasilitas": "#1E9E5A (Hijau — Info Toilet, Musala & Parkir)",
				"mitra":     "#E85D1A (Oranye — Quick Booking Mitra Nagari)",
			},
			"scenes_360": scenes,
		}, http.StatusOK, nil
	})
}

// CreateScene360Request mendukung unggah panorama 360° via URL, Base64 JSON, atau simulasi Multipart (CMS FS-1)
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

// 2. CreateScene360CMS — POST /api/v1/admin/scenes-360 (Hari 7 — CMS Studio 360° FS-1)
func (h *HandlerBE1) CreateScene360CMS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req CreateScene360Request
	contentType := r.Header.Get("Content-Type")
	uploadFormat := "url"

	if strings.HasPrefix(contentType, "multipart/form-data") {
		_ = r.ParseMultipartForm(16 << 20)
		req.DestinationID = r.FormValue("destination_id")
		req.Title = r.FormValue("title")
		req.Type = r.FormValue("type")
		req.PanoramaURL = r.FormValue("panorama_url")
		uploadFormat = "multipart"
		if req.PanoramaURL == "" {
			req.PanoramaURL = fmt.Sprintf("https://cdn.rancak.in/360/uploads/%s-multipart-360.jpg", req.DestinationID)
		}
	} else {
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			_ = json.NewEncoder(w).Encode(map[string]string{
				"status":  "error",
				"code":    "INVALID_JSON_BODY",
				"message": "Body JSON tidak valid untuk pembuatan Scene 360°.",
			})
			return
		}
		if req.PanoramaBase64 != "" {
			uploadFormat = "base64"
			if req.PanoramaURL == "" {
				req.PanoramaURL = fmt.Sprintf("https://cdn.rancak.in/360/base64-inline-%s.jpg", req.DestinationID)
			}
		}
	}

	if req.DestinationID == "" || req.Title == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "MISSING_REQUIRED_FIELDS",
			"message": "Field 'destination_id' dan 'title' wajib diisi oleh CMS Studio 360°.",
		})
		return
	}
	if req.Type == "" {
		req.Type = "ground"
	}
	if req.PanoramaURL == "" {
		req.PanoramaURL = "https://cdn.rancak.in/360/default-sumbar-equirectangular.jpg"
	}

	created := h.repo.AddScene360CMS(models.Scene360{
		DestinationID:   req.DestinationID,
		Title:           req.Title,
		Type:            strings.ToLower(req.Type),
		PanoramaURL:     req.PanoramaURL,
		UploadFormat:    uploadFormat,
		SpatialAudioURL: req.SpatialAudioURL,
		InitialPitch:    req.InitialPitch,
		InitialYaw:      req.InitialYaw,
		IsDefaultScene:  req.IsDefaultScene,
		Hotspots:        []models.Hotspot360{},
	})

	// Hari 17: Auto-invalidate In-Memory TTL Cache saat Admin mengubah kanvas 360°
	h.cache.FlushAll()

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "created",
		"scene":  created,
	})
}

// 3. UpsertHotspot360CMS — POST /api/v1/admin/scenes-360/{sceneId}/hotspots (Hari 7 — Klik-Tempel Pin 360° FS-1)
func (h *HandlerBE1) UpsertHotspot360CMS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	sceneID := r.PathValue("sceneId")

	var input models.Hotspot360
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.Title == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_HOTSPOT_PAYLOAD",
			"message": "Payload Pin 360° wajib memuat 'title', 'type' (navigasi/audio/fasilitas/mitra), 'pitch', dan 'yaw'.",
		})
		return
	}

	if input.Pitch < -90.0 || input.Pitch > 90.0 || input.Yaw < 0.0 || input.Yaw > 360.0 {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "INVALID_SPHERICAL_COORDS",
			"message": "Koordinat bola 360° tidak valid: pitch harus [-90..90] dan yaw harus [0..360].",
		})
		return
	}

	if input.Type == "" {
		input.Type = "navigasi"
	}
	input.Type = strings.ToLower(input.Type)
	input.ColorToken = ResolvePinColorToken(input.Type)

	updatedScene, createdPin, err := h.repo.AddHotspotToSceneCMS(sceneID, input)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"code":    "SCENE_NOT_FOUND",
			"message": fmt.Sprintf("Scene 360° '%s' tidak ditemukan.", sceneID),
		})
		return
	}

	// Hari 17: Auto-invalidate In-Memory TTL Cache saat pin baru ditempel
	h.cache.FlushAll()

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "pin_attached",
		"scene_id":       updatedScene.ID,
		"scene_title":    updatedScene.Title,
		"attached_pin":   createdPin,
		"total_hotspots": len(updatedScene.Hotspots),
	})
}
