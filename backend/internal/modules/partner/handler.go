package partner

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Mitra Nagari Minangkabau (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute-rute mitra ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/partners", h.GetPartners)
	rg.GET("/partners/detail", h.GetPartnerDetail)
	rg.GET("/partners/:id", h.GetPartnerDetail)
}

// GetPartners menangani GET /api/v1/partners
func (h *Handler) GetPartners(c *gin.Context) {
	category := c.Query("category")
	nagari := c.Query("nagari")

	var spicyLevel *int
	if spicyStr := c.Query("spicy_level"); spicyStr != "" {
		if val, err := strconv.Atoi(spicyStr); err == nil {
			spicyLevel = &val
		}
	}

	list, err := h.service.GetPartners(category, spicyLevel, nagari)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Katalog mitra nagari Minangkabau berhasil dimuat", list)
}

// GetPartnerDetail menangani GET /api/v1/partners/detail?id=... atau GET /api/v1/partners/:id
func (h *Handler) GetPartnerDetail(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		id = c.Query("id")
	}

	if id == "" {
		common.Error(c, http.StatusBadRequest, "ID mitra wajib disertakan")
		return
	}

	partner, err := h.service.GetPartnerDetail(id)
	if err != nil {
		common.Error(c, http.StatusNotFound, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Detail profil mitra nagari berhasil dimuat", partner)
}

