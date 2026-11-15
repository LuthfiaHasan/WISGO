package booking_escrow

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Pemesanan 360°, Escrow, dan Bot WhatsApp (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute-rute booking & escrow ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/bookings/create", h.CreateBooking)
	rg.POST("/bookings", h.CreateBooking)
	rg.POST("/bookings/wa-webhook", h.WAWebhookSimulation)
	rg.GET("/bookings/:id/ticket-qr", h.GetBookingTicketQR)
	rg.GET("/bookings/ticket-qr", h.GetBookingTicketQR)
	rg.POST("/escrow/scan-redeem", h.ScanRedeemEscrow)
	rg.GET("/escrow/currency/myr-rate", h.GetMYRConversionRate)
	rg.GET("/currency/myr-rate", h.GetMYRConversionRate)
}

// CreateBooking menangani POST /api/v1/bookings/create
func (h *Handler) CreateBooking(c *gin.Context) {
	var req CreateBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Payload tidak valid: partner_id dan total_amount (> 0) wajib diisi")
		return
	}

	res, err := h.service.CreateBooking(req)
	if err != nil {
		if strings.Contains(err.Error(), "tidak ditemukan") {
			common.Error(c, http.StatusNotFound, err.Error())
			return
		}
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusCreated, "Pesanan berhasil dibuat, notifikasi konfirmasi dikirim ke WhatsApp mitra", map[string]interface{}{
		"booking":               res.Booking,
		"partner_whatsapp":      res.PartnerWhatsApp,
		"wa_message_simulation": res.WAMessageSimulation,
	})
}

// WAWebhookSimulation menangani POST /api/v1/bookings/wa-webhook
func (h *Handler) WAWebhookSimulation(c *gin.Context) {
	var req WAWebhookRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Payload tidak valid: booking_id dan action ('1' atau '0') wajib diisi")
		return
	}

	res, err := h.service.ProcessWAWebhook(req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	if req.Action == "1" {
		common.Success(c, http.StatusOK, "Pesanan DITERIMA mitra (Action 1). E-Ticket QR diterbitkan & dana dikunci di Escrow.", map[string]interface{}{
			"booking_id":     res.BookingID,
			"status":         res.Status,
			"qr_code_ticket": res.QRCodeTicket,
			"escrow_locked":  res.EscrowLocked,
			"note":           res.Note,
		})
		return
	}

	common.Success(c, http.StatusOK, "Pesanan DITOLAK mitra (Action 0). Dana telah dikembalikan penuh ke wisatawan (REFUNDED).", map[string]interface{}{
		"booking_id": res.BookingID,
		"status":     res.Status,
		"refunded":   res.Refunded,
	})
}

// GetBookingTicketQR menangani GET /api/v1/bookings/:id/ticket-qr
func (h *Handler) GetBookingTicketQR(c *gin.Context) {
	bookingID := c.Param("id")
	if bookingID == "" {
		bookingID = c.Query("id")
	}

	if bookingID == "" {
		common.Error(c, http.StatusBadRequest, "Parameter booking id wajib diisi")
		return
	}

	res, err := h.service.GetTicketQR(bookingID)
	if err != nil {
		if strings.Contains(err.Error(), "tidak ditemukan") {
			common.Error(c, http.StatusNotFound, err.Error())
			return
		}
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "E-Ticket QR berhasil dimuat", map[string]interface{}{
		"booking_id":     res.BookingID,
		"qr_code_ticket": res.QRCodeTicket,
		"status":         res.Status,
		"partner_id":     res.PartnerID,
		"total_amount":   res.TotalAmount,
		"currency":       res.Currency,
	})
}

// ScanRedeemEscrow menangani POST /api/v1/escrow/scan-redeem
func (h *Handler) ScanRedeemEscrow(c *gin.Context) {
	var req ScanRedeemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Payload tidak valid: qr_code_ticket wajib diisi")
		return
	}

	res, err := h.service.ScanRedeem(req)
	if err != nil {
		if strings.Contains(err.Error(), "tidak terdaftar") || strings.Contains(err.Error(), "tidak ditemukan") {
			common.Error(c, http.StatusNotFound, err.Error())
			return
		}
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	msg := fmt.Sprintf("Tiket QR VALID! Kunjungan tamu terverifikasi. Dana sebesar %s %.2f berhasil dicairkan ke rekening mitra.",
		res.Currency, res.DisbursedAmount)

	common.Success(c, http.StatusOK, msg, map[string]interface{}{
		"booking_id":       res.BookingID,
		"status":           res.Status,
		"disbursed_amount": res.DisbursedAmount,
		"currency":         res.Currency,
		"redeemed_at":      res.RedeemedAt,
	})
}

// GetMYRConversionRate menangani GET /api/v1/escrow/currency/myr-rate
func (h *Handler) GetMYRConversionRate(c *gin.Context) {
	res, err := h.service.GetMYRConversionRate()
	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Kurs konversi resmi DuitNow / QRIS Minangkabau berhasil dimuat", res)
}

