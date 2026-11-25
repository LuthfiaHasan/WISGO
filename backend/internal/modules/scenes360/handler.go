package scenes360

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Handler menangani endpoint HTTP Gin untuk tur 360° dan CMS Studio
type Handler struct {
	service Service
	cache   *middleware.InMemoryTTLCache
}

// NewHandler membuat instance Handler baru
func NewHandler(service Service, cache *middleware.InMemoryTTLCache) *Handler {
	return &Handler{
		service: service,
		cache:   cache,
	}
}

// RegisterRoutes mendaftarkan seluruh route modul scenes360 ke Gin engine/group
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	// Publik: Kanvas Penjelajah 360° Aerial-to-Ground & Hotspots
	rg.GET("/destinations/:id/scenes-360", h.GetDestinationScenes360)
	rg.GET("/scenes-360/:sceneId/hotspots", h.GetSceneHotspots)

	// Admin CMS: Proteksi RBAC JWT (admin_dispar & pokdarwis)
	adminAuth := middleware.RequireRoles("admin_dispar", "pokdarwis")
	adminDisparOnly := middleware.RequireRoles("admin_dispar")

	// Rute Langsung Sesuai Kontrak API_Contract_BE1_BE2.md
	rg.POST("/scenes-360", adminAuth, h.CreateScene360CMS)
	rg.POST("/scenes-360/:sceneId/hotspots", adminAuth, h.UpsertHotspot360CMS)
	rg.DELETE("/scenes-360/hotspots/:id", adminDisparOnly, h.DeleteHotspotCMS)

	// Alias Prefix /admin/scenes-360
	admin := rg.Group("/admin/scenes-360")
	admin.Use(adminAuth)
	{
		admin.POST("", h.CreateScene360CMS)
		admin.POST("/:sceneId/hotspots", h.UpsertHotspot360CMS)
		admin.DELETE("/hotspots/:id", adminDisparOnly, h.DeleteHotspotCMS)
	}
}

// GetDestinationScenes360 GET /api/v1/destinations/:id/scenes-360
func (h *Handler) GetDestinationScenes360(c *gin.Context) {
	idOrSlug := c.Param("id")
	cacheKey := fmt.Sprintf("scenes360:%s", idOrSlug)

	h.cache.WriteCachedJSON(c, cacheKey, func() (interface{}, int, error) {
		resp, err := h.service.GetScenesByDestination(idOrSlug)
		if err != nil {
			return gin.H{
				"status":  "error",
				"code":    "DESTINATION_NOT_FOUND",
				"message": "Destinasi tidak ditemukan untuk pemuatan kanvas 360°.",
			}, http.StatusNotFound, err
		}
		return resp, http.StatusOK, nil
	})
}

// CreateScene360CMS POST /api/v1/admin/scenes-360
func (h *Handler) CreateScene360CMS(c *gin.Context) {
	var req CreateScene360Request
	contentType := c.GetHeader("Content-Type")
	uploadFormat := "url"

	if strings.HasPrefix(contentType, "multipart/form-data") {
		_ = c.Request.ParseMultipartForm(16 << 20)
		req.DestinationID = c.PostForm("destination_id")
		req.Title = c.PostForm("title")
		req.Type = c.PostForm("type")
		req.PanoramaURL = c.PostForm("panorama_url")
		uploadFormat = "multipart"
		if req.PanoramaURL == "" {
			req.PanoramaURL = fmt.Sprintf("https://cdn.rancak.in/360/uploads/%s-multipart-360.jpg", req.DestinationID)
		}
	} else {
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
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

	created, err := h.service.CreateSceneCMS(req, uploadFormat)
	if err != nil {
		if err.Error() == "MISSING_REQUIRED_FIELDS" {
			c.JSON(http.StatusBadRequest, gin.H{
				"status":  "error",
				"code":    "MISSING_REQUIRED_FIELDS",
				"message": "Field 'destination_id' dan 'title' wajib diisi oleh CMS Studio 360°.",
			})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	// Auto-invalidate In-Memory TTL Cache saat Admin mengubah kanvas 360°
	h.cache.FlushAll()

	c.JSON(http.StatusCreated, gin.H{
		"status": "created",
		"scene":  created,
	})
}

// UpsertHotspot360CMS POST /api/v1/admin/scenes-360/:sceneId/hotspots
func (h *Handler) UpsertHotspot360CMS(c *gin.Context) {
	sceneID := c.Param("sceneId")

	var input models.Hotspot360
	if err := c.ShouldBindJSON(&input); err != nil || strings.TrimSpace(input.Title) == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "INVALID_HOTSPOT_PAYLOAD",
			"message": "Payload Pin 360° wajib memuat 'title', 'type' (navigasi/audio/fasilitas/mitra), 'pitch', dan 'yaw'.",
		})
		return
	}

	if input.Pitch < -90.0 || input.Pitch > 90.0 || input.Yaw < 0.0 || input.Yaw > 360.0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "INVALID_SPHERICAL_COORDS",
			"message": "Koordinat bola 360° tidak valid: pitch harus [-90..90] dan yaw harus [0..360].",
		})
		return
	}

	updatedScene, createdPin, err := h.service.AddHotspotCMS(sceneID, input)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "SCENE_NOT_FOUND",
			"message": fmt.Sprintf("Scene 360° '%s' tidak ditemukan.", sceneID),
		})
		return
	}

	// Auto-invalidate In-Memory TTL Cache saat pin baru ditempel
	h.cache.FlushAll()

	c.JSON(http.StatusCreated, gin.H{
		"status":         "pin_attached",
		"scene_id":       updatedScene.ID,
		"scene_title":    updatedScene.Title,
		"attached_pin":   createdPin,
		"total_hotspots": len(updatedScene.Hotspots),
	})
}

// GetSceneHotspots GET /api/v1/scenes-360/:sceneId/hotspots
func (h *Handler) GetSceneHotspots(c *gin.Context) {
	sceneID := c.Param("sceneId")
	if sceneID == "" {
		sceneID = c.Param("scene_id")
	}

	pins, err := h.service.GetHotspots(sceneID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "SCENE_NOT_FOUND",
			"message": fmt.Sprintf("Scene 360° '%s' tidak ditemukan.", sceneID),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":         "ok",
		"scene_id":       sceneID,
		"total_hotspots": len(pins),
		"hotspots":       pins,
	})
}

// DeleteHotspotCMS DELETE /api/v1/scenes-360/hotspots/:id
func (h *Handler) DeleteHotspotCMS(c *gin.Context) {
	hotspotID := c.Param("id")

	if err := h.service.DeleteHotspot(hotspotID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "HOTSPOT_NOT_FOUND",
			"message": fmt.Sprintf("Pin Hotspot 360° '%s' tidak ditemukan.", hotspotID),
		})
		return
	}

	if h.cache != nil {
		h.cache.FlushAll()
	}

	c.JSON(http.StatusOK, gin.H{
		"status":     "deleted",
		"message":    fmt.Sprintf("Pin Hotspot 360° '%s' berhasil dihapus.", hotspotID),
		"hotspot_id": hotspotID,
	})
}
