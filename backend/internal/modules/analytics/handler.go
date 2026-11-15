package analytics

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Analitik Eksekutif Dispar Sumbar (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler analitik baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute analitik ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/analytics/dispar/summary", h.GetDisparAnalyticsSummary)
}

// GetDisparAnalyticsSummary menangani GET /api/v1/analytics/dispar/summary
func (h *Handler) GetDisparAnalyticsSummary(c *gin.Context) {
	summary, err := h.service.GetDisparAnalyticsSummary()
	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Ringkasan analitik eksekutif Dispar Sumbar berhasil dimuat", summary)
}

