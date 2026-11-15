package community

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Komunitas, Hidden Gem, dan Shared Trips (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute-rute komunitas ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/community/places", h.GetCommunityPlaces)
	rg.POST("/community/places", h.CreateCommunityPlace)
	rg.GET("/community/shared-trips", h.GetSharedTrips)
	rg.POST("/community/shared-trips", h.CreateSharedTrip)
}

// GetCommunityPlaces menangani GET /api/v1/community/places
func (h *Handler) GetCommunityPlaces(c *gin.Context) {
	list, err := h.service.GetCommunityPlaces()
	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Daftar tempat komunitas berhasil dimuat", map[string]interface{}{
		"total":  len(list),
		"places": list,
	})
}

// CreateCommunityPlace menangani POST /api/v1/community/places
func (h *Handler) CreateCommunityPlace(c *gin.Context) {
	var req CreateCommunityPlaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Payload tidak valid: nama tempat dan tips_menjaga wajib diisi")
		return
	}

	res, err := h.service.CreateCommunityPlace(req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	data := map[string]interface{}{
		"place":           res.Place,
		"masking_applied": res.MaskingApplied,
	}
	if res.Note != "" {
		data["note"] = res.Note
	}

	common.Success(c, http.StatusCreated, "Tempat baru berhasil diajukan dan sedang menunggu kurasi Pokdarwis", data)
}

// GetSharedTrips menangani GET /api/v1/community/shared-trips
func (h *Handler) GetSharedTrips(c *gin.Context) {
	list, err := h.service.GetSharedTrips()
	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Papan cari barengan berhasil dimuat", map[string]interface{}{
		"total": len(list),
		"trips": list,
	})
}

// CreateSharedTrip menangani POST /api/v1/community/shared-trips
func (h *Handler) CreateSharedTrip(c *gin.Context) {
	var req CreateSharedTripRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Payload tidak valid: title dan destination_route wajib diisi")
		return
	}

	trip, err := h.service.CreateSharedTrip(req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusCreated, "Postingan cari barengan berhasil diterbitkan di papan komunitas", map[string]interface{}{
		"trip": trip,
	})
}

