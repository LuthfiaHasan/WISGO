package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Autentikasi & Profil (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute-rute auth ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/auth/request-otp", h.RequestOTP)
	rg.POST("/auth/verify-otp", h.VerifyOTP)
	rg.GET("/users/saved", h.GetSavedPlaces)
	rg.POST("/users/saved", h.ToggleSavedPlace)
	rg.POST("/users/saved/:destination_id", h.ToggleSavedPlace)
}

// RequestOTP menangani POST /api/v1/auth/request-otp
func (h *Handler) RequestOTP(c *gin.Context) {
	var req OTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Nomor handphone wajib diisi dengan benar")
		return
	}

	otpCode, err := h.service.RequestOTP(req.PhoneNumber)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Kode OTP 4 digit telah dikirimkan via WhatsApp/SMS", map[string]interface{}{
		"phone_number": req.PhoneNumber,
		"otp_code_dev": otpCode,
		"expires_in":   300,
	})
}

// VerifyOTP menangani POST /api/v1/auth/verify-otp
func (h *Handler) VerifyOTP(c *gin.Context) {
	var req OTPVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Nomor handphone dan kode OTP wajib diisi")
		return
	}

	user, token, err := h.service.VerifyOTP(req.PhoneNumber, req.OTPCode)
	if err != nil {
		common.Error(c, http.StatusUnauthorized, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Verifikasi OTP berhasil, selamat datang di Rancak.in!", AuthResponse{
		Token: token,
		User:  *user,
	})
}

// GetSavedPlaces menangani GET /api/v1/users/saved
func (h *Handler) GetSavedPlaces(c *gin.Context) {
	userID := c.DefaultQuery("user_id", "usr-001")

	list, err := h.service.GetSavedPlaces(userID)
	if err != nil {
		common.Error(c, http.StatusInternalServerError, "Gagal memuat tempat tersimpan")
		return
	}

	common.Success(c, http.StatusOK, "Daftar tempat tersimpan berhasil dimuat", list)
}

// ToggleSavedPlace menangani POST /api/v1/users/saved dan POST /api/v1/users/saved/:destination_id
func (h *Handler) ToggleSavedPlace(c *gin.Context) {
	var req ToggleSavedRequest
	_ = c.ShouldBindJSON(&req)

	if req.DestinationID == "" {
		req.DestinationID = c.Param("destination_id")
	}
	if req.UserID == "" {
		req.UserID = c.Query("user_id")
		if req.UserID == "" {
			req.UserID = "usr-001" // fallback default tourist
		}
	}

	if req.DestinationID == "" {
		common.Error(c, http.StatusBadRequest, "user_id dan destination_id wajib diisi")
		return
	}

	res, err := h.service.ToggleSavedPlace(req.UserID, req.DestinationID)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	msg := "Tempat berhasil ditambahkan ke favorit"
	if !res.IsSaved {
		msg = "Tempat berhasil dihapus dari favorit"
	}

	common.Success(c, http.StatusOK, msg, res)
}

