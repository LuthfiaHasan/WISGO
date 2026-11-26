package pungli

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
)

// Handler menangani endpoint HTTP Gin untuk Smart QR dan Satgas Pungli
type Handler struct {
	service     Service
	rateLimiter *middleware.TokenBucketRateLimiter
}

// NewHandler membuat instance Handler baru
func NewHandler(service Service, rateLimiter *middleware.TokenBucketRateLimiter) *Handler {
	return &Handler{
		service:     service,
		rateLimiter: rateLimiter,
	}
}

// RegisterRoutes mendaftarkan seluruh route pungli ke router group
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	// Publik / Wisatawan (beserta alias Mobile api_service.dart & Web Admin api.ts)
	rg.GET("/qr/:qrCode", h.GetSmartQRResolution)
	rg.GET("/pungli/verify-qr/:qrCode", h.GetSmartQRResolution)
	rg.POST("/pungli/report", h.rateLimiter.Protect("pungli_report"), h.PostReportPungli)
	rg.POST("/reports/pungli", h.rateLimiter.Protect("pungli_report"), h.PostReportPungli)

	// Admin Command Center Satgas Saber Pungli (Kontrak Langsung & Admin Prefix)
	authSatgas := middleware.RequireRoles("admin_dispar", "pokdarwis")
	authAdminOnly := middleware.RequireRoles("admin_dispar")

	// Rute Langsung Sesuai API_Contract_BE1_BE2.md & Web Admin api.ts
	rg.GET("/pungli/reports", authSatgas, h.GetPungliReportsAdmin)
	rg.GET("/reports/pungli", authSatgas, h.GetPungliReportsAdmin)
	rg.PATCH("/pungli/reports/:id/status", authAdminOnly, h.UpdatePungliStatusAdmin)
	rg.PUT("/pungli/reports/:id/status", authAdminOnly, h.UpdatePungliStatusAdmin)
	rg.PATCH("/reports/pungli/:id/status", authSatgas, h.UpdatePungliStatusAdmin)
	rg.PUT("/reports/pungli/:id/status", authSatgas, h.UpdatePungliStatusAdmin)

	// Admin Prefix
	admin := rg.Group("/admin/pungli")
	admin.Use(authSatgas)
	{
		admin.GET("/reports", h.GetPungliReportsAdmin)
		admin.PATCH("/:id/status", authAdminOnly, h.UpdatePungliStatusAdmin)
		admin.PUT("/:id/status", authAdminOnly, h.UpdatePungliStatusAdmin)
	}
}

// GetSmartQRResolution GET /api/v1/qr/:qrCode
func (h *Handler) GetSmartQRResolution(c *gin.Context) {
	qrCode := strings.TrimSpace(c.Param("qrCode"))

	resp, err := h.service.ResolveSmartQR(qrCode)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "QR_PLACARD_NOT_FOUND",
			"message": fmt.Sprintf("Kode Plang Smart QR '%s' tidak terdaftar di database Dispar Sumbar.", qrCode),
		})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// PostReportPungli POST /api/v1/pungli/report
func (h *Handler) PostReportPungli(c *gin.Context) {
	var req CreatePungliReportRequest
	contentType := c.GetHeader("Content-Type")
	uploadFormat := "url"

	if strings.HasPrefix(contentType, "multipart/form-data") {
		_ = c.Request.ParseMultipartForm(10 << 20)
		req.DestinationID = c.PostForm("destination_id")
		req.ReporterName = c.PostForm("reporter_name")
		req.IncidentCategory = c.PostForm("incident_category")
		req.PhotoEvidence = c.PostForm("photo_evidence")
		req.Description = c.PostForm("description")
		if v, err := strconv.ParseFloat(c.PostForm("charged_amount_idr"), 64); err == nil {
			req.ChargedAmountIDR = v
		}
		if v, err := strconv.ParseFloat(c.PostForm("latitude"), 64); err == nil {
			req.Latitude = v
		}
		if v, err := strconv.ParseFloat(c.PostForm("longitude"), 64); err == nil {
			req.Longitude = v
		}
		uploadFormat = "multipart"
		if req.PhotoEvidence == "" {
			req.PhotoEvidence = "https://cdn.rancak.in/evidence/multipart-karcis-pungli.jpg"
		}
	} else {
		_ = c.ShouldBindJSON(&req)
		if req.IncidentCategory == "" && req.IncidentType != "" {
			req.IncidentCategory = req.IncidentType
		}
		if req.ChargedAmountIDR <= 0 && (req.OfficialPriceIDR > 0 || req.OverchargeIDR > 0) {
			req.ChargedAmountIDR = req.OfficialPriceIDR + req.OverchargeIDR
		}
		if req.PhotoBase64 != "" {
			uploadFormat = "base64"
			if req.PhotoEvidence == "" {
				req.PhotoEvidence = "data:image/jpeg;base64," + req.PhotoBase64
			}
		}
	}

	resp, err := h.service.SubmitPungliReport(req, uploadFormat)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// GetPungliReportsAdmin GET /api/v1/admin/pungli/reports
func (h *Handler) GetPungliReportsAdmin(c *gin.Context) {
	statusFilter := strings.TrimSpace(c.Query("status"))
	reports := h.service.GetPungliReports(statusFilter)

	c.JSON(http.StatusOK, gin.H{
		"status":        "ok",
		"filter_status": statusFilter,
		"total_reports": len(reports),
		"reports":       reports,
	})
}

// UpdatePungliStatusAdmin PATCH & PUT /api/v1/admin/pungli/:id/status
func (h *Handler) UpdatePungliStatusAdmin(c *gin.Context) {
	idOrTicket := c.Param("id")

	var req UpdatePungliStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Status) == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"code":    "INVALID_STATUS_PAYLOAD",
			"message": "Field 'status' wajib diisi (Masuk, Diverifikasi, Ditindaklanjuti, atau Selesai).",
		})
		return
	}

	if req.SatgasNotes == "" && req.AdminActionNotes != "" {
		req.SatgasNotes = req.AdminActionNotes
	}
	resp, err := h.service.UpdateReportStatus(idOrTicket, req)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"code":    "REPORT_NOT_FOUND",
			"message": fmt.Sprintf("Tiket laporan pungli '%s' tidak ditemukan.", idOrTicket),
		})
		return
	}

	c.JSON(http.StatusOK, resp)
}
