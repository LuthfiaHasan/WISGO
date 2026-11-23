package gamification

import (
	"errors"
	"fmt"
	"math"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Paspor Digital Minang, Anti-Fake GPS, dan Sertifikat Gubernur (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute-rute gamifikasi ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/gamification/checkin", h.ValidateGPSCheckIn)
	rg.GET("/gamification/passport", h.GetDigitalPassport)
	rg.POST("/gamification/certificate", h.GenerateGovernorCertificate)
	rg.GET("/gamification/certificate", h.GenerateGovernorCertificate)
}

// ValidateGPSCheckIn menangani POST /api/v1/gamification/checkin
func (h *Handler) ValidateGPSCheckIn(c *gin.Context) {
	var req CheckInRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Payload check-in tidak valid atau user_id belum diisi")
		return
	}

	if strings.TrimSpace(req.UserID) == "" {
		common.Error(c, http.StatusBadRequest, "user_id wajib disertakan untuk melakukan check-in GPS paspor digital", gin.H{
			"code": "MISSING_USER_ID",
		})
		return
	}

	res, err := h.service.ValidateGPSCheckIn(req)
	if err != nil {
		var gpsErr *GPSCheckInError
		if errors.As(err, &gpsErr) {
			common.Error(c, http.StatusBadRequest, gpsErr.Error(), map[string]interface{}{
				"is_within_radius": false,
				"distance_meters":  math.Round(gpsErr.Distance*10) / 10,
				"max_radius":       200.0,
				"destination_name": gpsErr.SpotName,
			})
			return
		}

		if strings.Contains(err.Error(), "tidak ditemukan") {
			common.Error(c, http.StatusNotFound, err.Error())
			return
		}

		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, fmt.Sprintf("Check-in GPS Valid! Anda berhasil membuka stempel '%s' (%d/10 titik)", res.BadgeEarned, res.TotalStamps), res)
}

// GetDigitalPassport menangani GET /api/v1/gamification/passport
func (h *Handler) GetDigitalPassport(c *gin.Context) {
	userID := c.Query("user_id")
	if userID == "" {
		userID = "usr-001"
	}

	res, err := h.service.GetDigitalPassport(userID)
	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, fmt.Sprintf("Rekapitulasi Paspor Digital Minang: %d dari %d titik ikonik terkumpul", res.TotalStamps, res.RequiredStamps), res)
}

// GenerateGovernorCertificate menangani POST & GET /api/v1/gamification/certificate
func (h *Handler) GenerateGovernorCertificate(c *gin.Context) {
	var req CertificateRequest
	if c.Request.Method == http.MethodPost {
		_ = c.ShouldBindJSON(&req)
	}
	if req.UserID == "" {
		req.UserID = c.Query("user_id")
	}
	if req.FullName == "" {
		req.FullName = c.Query("full_name")
	}

	cert, isAlreadyIssued, err := h.service.GenerateGovernorCertificate(req)
	if err != nil {
		var ineligErr *IneligibleCertificateError
		if errors.As(err, &ineligErr) {
			common.Error(c, http.StatusBadRequest, ineligErr.Error(), map[string]interface{}{
				"stamps_collected": ineligErr.Collected,
				"stamps_required":  ineligErr.Required,
				"is_eligible":      false,
			})
			return
		}

		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	if isAlreadyIssued {
		common.Success(c, http.StatusOK, "Sertifikat Digital Gubernur Anda sudah aktif dan terverifikasi", cert)
		return
	}

	common.Success(c, http.StatusCreated, "Selamat! Sertifikat Digital Resmi Gubernur Sumatera Barat berhasil diterbitkan", cert)
}

