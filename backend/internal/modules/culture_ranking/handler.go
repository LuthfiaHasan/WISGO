package culture_ranking

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
)

// Handler menangani endpoint HTTP Gin untuk Gaode Ranking, Kamus Minang, dan Kalender Budaya
type Handler struct {
	service Service
}

// NewHandler membuat instance Handler baru
func NewHandler(service Service) *Handler {
	return &Handler{
		service: service,
	}
}

// RegisterRoutes mendaftarkan route Gaode Ranking dan Culture ke router group
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/destinations/rankings/gaode", h.GetGaodeBehaviorRankings)
	rg.GET("/rankings/gaode", h.GetGaodeBehaviorRankings)
	rg.GET("/culture/minang-phrases", h.GetMinangAudioPhrases)
	rg.GET("/culture/audio-phrases", h.GetMinangAudioPhrases)
	rg.GET("/culture/events", h.GetCulturalEventsCalendar)

	// Input Event oleh Vendor (Aktor Vendor dengan pilihan login 'input event' atau Wisatawan/Publik)
	rg.POST("/culture/events", h.CreateCulturalEventVendor)

	// CRUD Event oleh Admin Dispar (Use Case: CRUD event - RBAC: admin_dispar, pokdarwis)
	adminAuth := middleware.RequireRoles("admin_dispar", "pokdarwis")
	rg.GET("/admin/culture/events", adminAuth, h.GetCulturalEventsCalendar)
	rg.POST("/admin/culture/events", adminAuth, h.CreateCulturalEventAdmin)
	rg.PUT("/admin/culture/events/:id", adminAuth, h.UpdateCulturalEventAdmin)
	rg.DELETE("/admin/culture/events/:id", adminAuth, h.DeleteCulturalEventAdmin)
}

// GetGaodeBehaviorRankings GET /api/v1/destinations/rankings/gaode
func (h *Handler) GetGaodeBehaviorRankings(c *gin.Context) {
	category := strings.TrimSpace(c.Query("category"))
	resp := h.service.GetGaodeRankings(category)
	c.JSON(http.StatusOK, resp)
}

// GetMinangAudioPhrases GET /api/v1/culture/minang-phrases
func (h *Handler) GetMinangAudioPhrases(c *gin.Context) {
	category := strings.TrimSpace(c.Query("category"))
	searchQuery := strings.TrimSpace(c.Query("q"))

	resp := h.service.GetMinangPhrases(category, searchQuery)
	c.JSON(http.StatusOK, resp)
}

// GetCulturalEventsCalendar GET /api/v1/culture/events
func (h *Handler) GetCulturalEventsCalendar(c *gin.Context) {
	eventType := strings.TrimSpace(c.Query("type"))
	cityFilter := strings.TrimSpace(c.Query("city_regency"))
	hasGPS, lat, lng := parseGPS(c)

	resp := h.service.GetCulturalEvents(eventType, cityFilter, hasGPS, lat, lng)
	c.JSON(http.StatusOK, resp)
}

// CreateCulturalEventVendor menangani POST /api/v1/culture/events oleh Vendor (atau Wisatawan)
func (h *Handler) CreateCulturalEventVendor(c *gin.Context) {
	// Validasi opsional token jika disertakan
	authHeader := c.GetHeader("Authorization")
	var role string = "vendor"
	var userID string
	if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		if token == middleware.TokenVendor {
			role = "vendor"
			userID = "user-vendor-01"
		} else if token == middleware.TokenTourist {
			role = "tourist"
			userID = "user-tourist-01"
		} else if token == middleware.TokenAdminDispar {
			role = "admin_dispar"
			userID = "user-admin-dispar-01"
		}
	}

	var req CreateCulturalEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "INVALID_EVENT_PAYLOAD",
			"message": "Payload JSON tidak valid.",
		})
		return
	}

	created, err := h.service.CreateEvent(req, userID, role)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Event kebudayaan/pasar nagari berhasil didaftarkan oleh Vendor ke kalender budaya Sumbar.",
		"data":    created,
	})
}

// CreateCulturalEventAdmin menangani POST /api/v1/admin/culture/events oleh Admin Dispar
func (h *Handler) CreateCulturalEventAdmin(c *gin.Context) {
	var req CreateCulturalEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "INVALID_EVENT_PAYLOAD",
			"message": "Payload JSON tidak valid.",
		})
		return
	}

	created, err := h.service.CreateEvent(req, "admin-dispar-01", "admin_dispar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Event budaya resmi berhasil dibuat oleh Admin Dispar.",
		"data":    created,
	})
}

// UpdateCulturalEventAdmin menangani PUT /api/v1/admin/culture/events/:id oleh Admin Dispar
func (h *Handler) UpdateCulturalEventAdmin(c *gin.Context) {
	id := c.Param("id")
	var req CreateCulturalEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Payload JSON tidak valid.",
		})
		return
	}

	updated, err := h.service.UpdateEvent(id, req)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Event budaya berhasil diperbarui oleh Admin Dispar.",
		"data":    updated,
	})
}

// DeleteCulturalEventAdmin menangani DELETE /api/v1/admin/culture/events/:id oleh Admin Dispar
func (h *Handler) DeleteCulturalEventAdmin(c *gin.Context) {
	id := c.Param("id")
	err := h.service.DeleteEvent(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Event budaya berhasil dihapus dari sistem.",
	})
}

func parseGPS(c *gin.Context) (bool, float64, float64) {
	latStr := c.Query("lat")
	lngStr := c.Query("lng")
	if latStr == "" || lngStr == "" {
		return false, 0, 0
	}
	lat, err1 := strconv.ParseFloat(latStr, 64)
	lng, err2 := strconv.ParseFloat(lngStr, 64)
	if err1 != nil || err2 != nil {
		return false, 0, 0
	}
	return true, lat, lng
}
