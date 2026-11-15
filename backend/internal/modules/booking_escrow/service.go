package booking_escrow

import (
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis transaksi booking dan rekening bersama escrow
type Service interface {
	CreateBooking(req CreateBookingRequest) (*CreateBookingResponse, error)
	ProcessWAWebhook(req WAWebhookRequest) (*WAWebhookResponse, error)
	GetTicketQR(bookingID string) (*TicketQRResponse, error)
	ScanRedeem(req ScanRedeemRequest) (*ScanRedeemResponse, error)
	GetMYRConversionRate() (*MYRConversionResponse, error)
}

type service struct {
	repo Repository
}

// NewService membuat instance service baru
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) CreateBooking(req CreateBookingRequest) (*CreateBookingResponse, error) {
	if req.PartnerID == "" || req.TotalAmount <= 0 {
		return nil, errors.New("payload tidak valid: partner_id dan total_amount (> 0) wajib diisi")
	}

	partner, exists := s.repo.GetPartnerByID(req.PartnerID)
	if !exists {
		return nil, fmt.Errorf("mitra nagari dengan ID '%s' tidak ditemukan", req.PartnerID)
	}

	userID := req.UserID
	if userID == "" {
		userID = "usr-001"
	}

	currency := req.Currency
	if currency == "" {
		currency = "IDR"
	}

	bookingID := fmt.Sprintf("bkg-%d", time.Now().UnixNano()%100000)
	booking := &models.BookingEscrow{
		ID:           bookingID,
		PartnerID:    req.PartnerID,
		UserID:       userID,
		TotalAmount:  req.TotalAmount,
		Currency:     currency,
		Status:       "PENDING_WA",
		QRCodeTicket: "",
		CreatedAt:    time.Now(),
	}

	if err := s.repo.SaveBooking(booking); err != nil {
		return nil, err
	}

	waMessageSimulation := fmt.Sprintf(
		"🔔 *PESANAN BARU MASUK (Rancak.in Escrow)*\n"+
			"Halo %s! Wisatawan telah membayar deposit senilai %s %.2f yang kini diamankan di Rekening Bersama.\n\n"+
			"Balas pesan ini:\n"+
			"👉 Balas *1* untuk MENERIMA pesanan\n"+
			"👉 Balas *0* untuk MENOLAK pesanan",
		partner.Name, currency, req.TotalAmount,
	)

	return &CreateBookingResponse{
		Booking:             *booking,
		PartnerWhatsApp:     partner.WhatsApp,
		WAMessageSimulation: waMessageSimulation,
	}, nil
}

func (s *service) ProcessWAWebhook(req WAWebhookRequest) (*WAWebhookResponse, error) {
	if req.BookingID == "" || req.Action == "" {
		return nil, errors.New("payload tidak valid: booking_id dan action ('1' atau '0') wajib diisi")
	}

	if req.Action != "1" && req.Action != "0" {
		return nil, errors.New("nilai action tidak valid, harus '1' (Terima) atau '0' (Tolak)")
	}

	booking, exists := s.repo.GetBookingByID(req.BookingID)
	if !exists {
		// Mock booking on the fly jika diuji dengan booking ID baru
		booking = &models.BookingEscrow{
			ID:          req.BookingID,
			PartnerID:   "ptr-01",
			UserID:      "usr-001",
			TotalAmount: 250000.00,
			Currency:    "IDR",
			CreatedAt:   time.Now(),
		}
		_ = s.repo.SaveBooking(booking)
	}

	if req.Action == "1" {
		booking.Status = "ESCROW_LOCKED"
		booking.QRCodeTicket = fmt.Sprintf("QR-RANCAK-TKT-%s", booking.ID)
		if err := s.repo.UpdateBooking(booking); err != nil {
			return nil, err
		}

		return &WAWebhookResponse{
			BookingID:    booking.ID,
			Status:       booking.Status,
			QRCodeTicket: booking.QRCodeTicket,
			EscrowLocked: true,
			Note:         "Tunjukkan QR ini kepada mitra saat tiba di lokasi untuk pencairan dana",
		}, nil
	}

	// Action == "0" -> REFUNDED
	booking.Status = "REFUNDED"
	booking.QRCodeTicket = ""
	if err := s.repo.UpdateBooking(booking); err != nil {
		return nil, err
	}

	return &WAWebhookResponse{
		BookingID: booking.ID,
		Status:    booking.Status,
		Refunded:  true,
	}, nil
}

func (s *service) GetTicketQR(bookingID string) (*TicketQRResponse, error) {
	if bookingID == "" {
		return nil, errors.New("parameter booking id wajib diisi")
	}

	booking, exists := s.repo.GetBookingByID(bookingID)
	if !exists {
		return nil, fmt.Errorf("pesanan dengan ID '%s' tidak ditemukan", bookingID)
	}

	if booking.Status == "PENDING_WA" {
		return nil, errors.New("tiket QR belum terbit: Menunggu konfirmasi balasan WhatsApp dari mitra")
	}

	if booking.Status == "REFUNDED" {
		return nil, errors.New("tiket tidak aktif: Pesanan telah ditolak dan dana dikembalikan")
	}

	return &TicketQRResponse{
		BookingID:    booking.ID,
		QRCodeTicket: booking.QRCodeTicket,
		Status:       booking.Status,
		PartnerID:    booking.PartnerID,
		TotalAmount:  booking.TotalAmount,
		Currency:     booking.Currency,
	}, nil
}

func (s *service) ScanRedeem(req ScanRedeemRequest) (*ScanRedeemResponse, error) {
	if req.QRCodeTicket == "" {
		return nil, errors.New("payload tidak valid: qr_code_ticket wajib diisi")
	}

	booking, exists := s.repo.GetBookingByQRCode(req.QRCodeTicket)
	if !exists {
		return nil, errors.New("tiket QR tidak valid atau tidak terdaftar di sistem")
	}

	if booking.Status == "REDEEMED" {
		return nil, errors.New("peringatan: Tiket ini sudah pernah dicairkan sebelumnya (*Redeemed*)")
	}

	if booking.Status != "ESCROW_LOCKED" && booking.Status != "CONFIRMED" {
		return nil, fmt.Errorf("tiket tidak dapat dicairkan (Status saat ini: %s)", booking.Status)
	}

	booking.Status = "REDEEMED"
	if err := s.repo.UpdateBooking(booking); err != nil {
		return nil, err
	}

	return &ScanRedeemResponse{
		BookingID:       booking.ID,
		Status:          booking.Status,
		DisbursedAmount: booking.TotalAmount,
		Currency:        booking.Currency,
		RedeemedAt:      time.Now().Format(time.RFC3339),
	}, nil
}

func (s *service) GetMYRConversionRate() (*MYRConversionResponse, error) {
	rateMYRtoIDR := 3550.00
	rateIDRtoMYR := math.Round((1.0/rateMYRtoIDR)*1000000) / 1000000

	return &MYRConversionResponse{
		BaseCurrency:    "MYR",
		TargetCurrency:  "IDR",
		RateMYRtoIDR:    rateMYRtoIDR,
		RateIDRtoMYR:    rateIDRtoMYR,
		SupportedMethod: []string{"QRIS (Indonesia)", "DuitNow Cross-Border (Malaysia)"},
		UpdatedAt:       time.Now().Format("2006-01-02 15:04:05"),
	}, nil
}

