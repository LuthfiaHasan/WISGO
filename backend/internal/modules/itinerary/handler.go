package itinerary

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Rencana Perjalanan (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute-rute itinerary ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/itineraries/auto-generate", h.AutoGenerate)
	rg.GET("/itineraries", h.GetItineraries)
	rg.POST("/itineraries", h.CreateManual)
}

// AutoGenerate menangani POST /api/v1/itineraries/auto-generate
func (h *Handler) AutoGenerate(c *gin.Context) {
	var req AutoItineraryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Payload generator jadwal tidak valid (user_id wajib, duration_days 1-7)")
		return
	}

	itinerary, err := h.service.AutoGenerate(req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusCreated, "Jadwal perjalanan pintar berhasil digenerate otomatis", itinerary)
}

// GetItineraries menangani GET /api/v1/itineraries
func (h *Handler) GetItineraries(c *gin.Context) {
	userID := c.DefaultQuery("user_id", "usr-001")

	list, err := h.service.GetUserItineraries(userID)
	if err != nil {
		common.Error(c, http.StatusInternalServerError, "Gagal memuat daftar rencana perjalanan")
		return
	}

	common.Success(c, http.StatusOK, "Daftar rencana perjalanan berhasil dimuat", list)
}

// CreateManual menangani POST /api/v1/itineraries
func (h *Handler) CreateManual(c *gin.Context) {
	var req CreateItineraryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "user_id, title, start_date, dan end_date wajib diisi")
		return
	}

	itinerary, err := h.service.CreateManual(req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusCreated, "Rencana perjalanan manual berhasil disimpan", itinerary)
}

