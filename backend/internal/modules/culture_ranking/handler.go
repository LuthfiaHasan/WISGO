package culture_ranking

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
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
