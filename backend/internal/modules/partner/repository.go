package partner

import (
	"errors"
	"strings"
	"sync"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka data access untuk modul Mitra Nagari Minangkabau
type Repository interface {
	FindAll(category string, spicyLevel *int, nagari string) ([]models.PartnerNagari, error)
	FindByID(id string) (*models.PartnerNagari, error)
}

type inMemoryRepository struct {
	mu       sync.RWMutex
	partners []models.PartnerNagari
}

// NewRepository menginisialisasi repository dengan 5 Kategori Mitra Nagari Minangkabau Otentik
func NewRepository() Repository {
	return &inMemoryRepository{
		partners: []models.PartnerNagari{
			{
				ID:          "ptr-01",
				Name:        "Homestay Rumah Gadang Etek Nur",
				Category:    "Homestay Rumah Gadang",
				WhatsApp:    "6281234567890",
				SpicyLevel:  0,
				IsVerified:  true,
				StandardFee: 250000.00,
				NagariName:  "Nagari Koto Gadang (Agam)",
			},
			{
				ID:          "ptr-02",
				Name:        "Rumah Makan Rendang Payakumbuah Asli",
				Category:    "Kuliner Halal",
				WhatsApp:    "6281298765432",
				SpicyLevel:  5, // Sangat Pedas Minang Otentik
				IsVerified:  true,
				StandardFee: 45000.00,
				NagariName:  "Kota Payakumbuh",
			},
			{
				ID:          "ptr-03",
				Name:        "Sewa Armada HiAce & Avanza Minang Tour",
				Category:    "Transport & Perahu",
				WhatsApp:    "6281311223344",
				SpicyLevel:  0,
				IsVerified:  true,
				StandardFee: 650000.00,
				NagariName:  "Kota Padang - Bukittinggi",
			},
			{
				ID:          "ptr-04",
				Name:        "Pemandu Geopark Ngarai Sianok Pokdarwis",
				Category:    "Pemandu Pokdarwis",
				WhatsApp:    "6281355667788",
				SpicyLevel:  0,
				IsVerified:  true,
				StandardFee: 150000.00,
				NagariName:  "Kota Bukittinggi",
			},
			{
				ID:          "ptr-05",
				Name:        "Sewa Pakaian Adat Minang Suntiang & Deta",
				Category:    "Sewa Baju Adat",
				WhatsApp:    "6281399887766",
				SpicyLevel:  0,
				IsVerified:  true,
				StandardFee: 75000.00,
				NagariName:  "Istano Basa Pagaruyung (Tanah Datar)",
			},
		},
	}
}

func (r *inMemoryRepository) FindAll(category string, spicyLevel *int, nagari string) ([]models.PartnerNagari, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []models.PartnerNagari
	for _, p := range r.partners {
		// Filter Kategori
		if category != "" {
			catMatch := strings.Contains(strings.ToLower(p.Category), strings.ToLower(category))
			if !catMatch {
				continue
			}
		}

		// Filter Spicy Level (khusus kuliner)
		if spicyLevel != nil {
			if p.SpicyLevel != *spicyLevel {
				continue
			}
		}

		// Filter Nagari / Lokasi
		if nagari != "" {
			if !strings.Contains(strings.ToLower(p.NagariName), strings.ToLower(nagari)) {
				continue
			}
		}

		result = append(result, p)
	}

	return result, nil
}

func (r *inMemoryRepository) FindByID(id string) (*models.PartnerNagari, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	normID := strings.ToLower(strings.TrimSpace(id))
	for _, p := range r.partners {
		pNorm := strings.ToLower(p.ID)
		if pNorm == normID ||
			(normID == "prt-001" && pNorm == "ptr-01") ||
			(normID == "partner-001" && pNorm == "ptr-01") ||
			(normID == "prt-002" && pNorm == "ptr-02") ||
			(normID == "prt-003" && pNorm == "ptr-03") ||
			(normID == "prt-004" && pNorm == "ptr-04") ||
			(normID == "prt-005" && pNorm == "ptr-05") {
			return &p, nil
		}
	}
	return nil, errors.New("Mitra tidak ditemukan")
}

