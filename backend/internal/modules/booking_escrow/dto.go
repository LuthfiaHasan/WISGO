package booking_escrow

import (
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// CreateBookingRequest payload pemesanan via Quick Drawer 360°
type CreateBookingRequest struct {
	PartnerID   string  `json:"partner_id" binding:"required"`
	UserID      string  `json:"user_id"`
	TotalAmount float64 `json:"total_amount" binding:"required,gt=0"`
	Currency    string  `json:"currency"` // IDR / MYR
}

// CreateBookingResponse respon pembuatan pesanan dan simulasi WA bot
type CreateBookingResponse struct {
	Booking             models.BookingEscrow `json:"booking"`
	PartnerWhatsApp     string               `json:"partner_whatsapp"`
	WAMessageSimulation string               `json:"wa_message_simulation"`
}

// WAWebhookRequest payload respon Bot WhatsApp mitra ("1" = Terima, "0" = Tolak)
type WAWebhookRequest struct {
	BookingID string `json:"booking_id" binding:"required"`
	Action    string `json:"action" binding:"required"` // "1" atau "0"
	Notes     string `json:"notes,omitempty"`
}

// WAWebhookResponse respon hasil pemrosesan balasan WhatsApp
type WAWebhookResponse struct {
	BookingID    string `json:"booking_id"`
	Status       string `json:"status"`
	QRCodeTicket string `json:"qr_code_ticket,omitempty"`
	EscrowLocked bool   `json:"escrow_locked,omitempty"`
	Refunded     bool   `json:"refunded,omitempty"`
	Note         string `json:"note,omitempty"`
}

// TicketQRResponse respon detail E-Ticket QR
type TicketQRResponse struct {
	BookingID    string  `json:"booking_id"`
	QRCodeTicket string  `json:"qr_code_ticket"`
	Status       string  `json:"status"`
	PartnerID    string  `json:"partner_id"`
	TotalAmount  float64 `json:"total_amount"`
	Currency     string  `json:"currency"`
}

// ScanRedeemRequest payload scan QR E-Ticket saat tamu tiba di lokasi
type ScanRedeemRequest struct {
	PartnerID    string `json:"partner_id"`
	QRCodeTicket string `json:"qr_code_ticket" binding:"required"`
}

// ScanRedeemResponse respon pencairan dana escrow ke rekening mitra
type ScanRedeemResponse struct {
	BookingID       string  `json:"booking_id"`
	Status          string  `json:"status"`
	DisbursedAmount float64 `json:"disbursed_amount"`
	Currency        string  `json:"currency"`
	RedeemedAt      string  `json:"redeemed_at"`
}

// MYRConversionResponse kurs konversi resmi DuitNow / QRIS Minangkabau
type MYRConversionResponse struct {
	BaseCurrency    string   `json:"base_currency"`
	TargetCurrency  string   `json:"target_currency"`
	RateMYRtoIDR    float64  `json:"rate_myr_to_idr"`
	RateIDRtoMYR    float64  `json:"rate_idr_to_myr"`
	SupportedMethod []string `json:"supported_method"`
	UpdatedAt       string   `json:"updated_at"`
}

