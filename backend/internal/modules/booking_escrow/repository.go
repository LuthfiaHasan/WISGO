package booking_escrow

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository interface untuk penyimpanan data booking, escrow, dan relasi mitra
type Repository interface {
	SaveBooking(booking *models.BookingEscrow) error
	GetBookingByID(id string) (*models.BookingEscrow, bool)
	GetBookingByQRCode(qrCode string) (*models.BookingEscrow, bool)
	UpdateBooking(booking *models.BookingEscrow) error
	GetPartnerByID(partnerID string) (*models.PartnerNagari, bool)
}

type inMemoryRepository struct {
	mu       sync.RWMutex
	bookings map[string]*models.BookingEscrow
	partners map[string]models.PartnerNagari
}

// NewRepository membuat instance repository baru dengan initial seeder
func NewRepository() Repository {
	repo := &inMemoryRepository{
		bookings: make(map[string]*models.BookingEscrow),
		partners: make(map[string]models.PartnerNagari),
	}
	repo.seedData()
	return repo
}

func (r *inMemoryRepository) seedData() {
	// Seeder 5 Mitra Nagari (Pilar 5)
	seedPartners := []models.PartnerNagari{
		{
			ID:          "ptr-01",
			Name:        "Homestay Rumah Gadang Etek Nur",
			Category:    "Homestay Rumah Gadang",
			WhatsApp:    "6281234567890",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 250000.00,
			NagariName:  "Nagari Sungai Buluah",
		},
		{
			ID:          "ptr-02",
			Name:        "Itiak Lado Mudo Ngarai Sianok",
			Category:    "Kuliner Halal",
			WhatsApp:    "6281298765432",
			SpicyLevel:  4,
			IsVerified:  true,
			StandardFee: 45000.00,
			NagariName:  "Nagari Koto Gadang",
		},
		{
			ID:          "ptr-03",
			Name:        "Perahu Wisata Bahari Pulau Mandeh",
			Category:    "Transport & Perahu",
			WhatsApp:    "6281311223344",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 350000.00,
			NagariName:  "Nagari Tarusan Mandeh",
		},
		{
			ID:          "ptr-04",
			Name:        "Pemandu Trekking Lembah Harau (Pokdarwis)",
			Category:    "Pemandu Pokdarwis",
			WhatsApp:    "6281355667788",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 150000.00,
			NagariName:  "Nagari Harau",
		},
		{
			ID:          "ptr-05",
			Name:        "Sanggar Busana Saluak & Suntiang Rang Minang",
			Category:    "Sewa Baju Adat",
			WhatsApp:    "6281399887766",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 75000.00,
			NagariName:  "Kota Bukittinggi",
		},
	}

	for _, p := range seedPartners {
		r.partners[p.ID] = p
	}

	// Seeder sample booking
	sampleBooking := &models.BookingEscrow{
		ID:           "bkg-demo-01",
		PartnerID:    "ptr-01",
		UserID:       "usr-001",
		TotalAmount:  250000.00,
		Currency:     "IDR",
		Status:       "ESCROW_LOCKED",
		QRCodeTicket: "QR-RANCAK-TKT-bkg-demo-01",
		CreatedAt:    time.Now().Add(-2 * time.Hour),
	}
	r.bookings[sampleBooking.ID] = sampleBooking

	booking001 := &models.BookingEscrow{
		ID:           "bkg-001",
		PartnerID:    "ptr-01",
		UserID:       "usr-001",
		TotalAmount:  350000.00,
		Currency:     "IDR",
		Status:       "ESCROW_LOCKED",
		QRCodeTicket: "QR-RANCAK-TKT-bkg-001",
		CreatedAt:    time.Now().Add(-1 * time.Hour),
	}
	r.bookings[booking001.ID] = booking001
}

func (r *inMemoryRepository) SaveBooking(booking *models.BookingEscrow) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.bookings[booking.ID] = booking
	return nil
}

func (r *inMemoryRepository) GetBookingByID(id string) (*models.BookingEscrow, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	b, exists := r.bookings[id]
	return b, exists
}

func (r *inMemoryRepository) GetBookingByQRCode(qrCode string) (*models.BookingEscrow, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	norm := strings.TrimSpace(qrCode)
	for _, b := range r.bookings {
		if b.QRCodeTicket == norm ||
			strings.EqualFold(b.QRCodeTicket, norm) ||
			norm == fmt.Sprintf("QR-TICKET-%s", b.ID) ||
			norm == fmt.Sprintf("QR-RANCAK-TKT-%s", b.ID) ||
			norm == b.ID {
			return b, true
		}
	}
	return nil, false
}

func (r *inMemoryRepository) UpdateBooking(booking *models.BookingEscrow) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.bookings[booking.ID]; !exists {
		return errors.New("pesanan tidak ditemukan")
	}
	r.bookings[booking.ID] = booking
	return nil
}

func (r *inMemoryRepository) GetPartnerByID(partnerID string) (*models.PartnerNagari, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	normID := strings.ToLower(strings.TrimSpace(partnerID))
	p, exists := r.partners[partnerID]
	if !exists {
		// Cek alias
		aliasMap := map[string]string{
			"prt-001":     "ptr-01",
			"partner-001": "ptr-01",
			"prt-002":     "ptr-02",
			"partner-002": "ptr-02",
			"prt-003":     "ptr-03",
			"partner-003": "ptr-03",
			"prt-004":     "ptr-04",
			"partner-004": "ptr-04",
			"prt-005":     "ptr-05",
			"partner-005": "ptr-05",
		}
		if mappedID, ok := aliasMap[normID]; ok {
			p, exists = r.partners[mappedID]
		}
	}
	if !exists {
		return nil, false
	}
	return &p, true
}

