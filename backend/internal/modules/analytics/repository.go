package analytics

import (
	"sync"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka penyimpanan data dan agregasi analitik Dispar Sumbar
type Repository interface {
	GetSummary() (models.DisparAnalyticsSummary, error)
}

type inMemoryRepository struct {
	mu sync.RWMutex
}

// NewRepository membuat instance repository analitik baru
func NewRepository() Repository {
	return &inMemoryRepository{}
}

func (r *inMemoryRepository) GetSummary() (models.DisparAnalyticsSummary, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	// 1. Heatmap 19 Kabupaten/Kota di Sumatera Barat (Pilar 8)
	regencies := []models.RegencyDensityItem{
		{RegencyName: "Kota Bukittinggi", Occupancy: "tinggi", ActiveGuests: 1850},
		{RegencyName: "Kota Padang", Occupancy: "tinggi", ActiveGuests: 2340},
		{RegencyName: "Kab. Tanah Datar", Occupancy: "tinggi", ActiveGuests: 1210},
		{RegencyName: "Kab. Lima Puluh Kota", Occupancy: "sedang", ActiveGuests: 980},
		{RegencyName: "Kab. Agam", Occupancy: "sedang", ActiveGuests: 840},
		{RegencyName: "Kab. Pesisir Selatan", Occupancy: "sedang", ActiveGuests: 760},
		{RegencyName: "Kota Sawahlunto", Occupancy: "sedang", ActiveGuests: 520},
		{RegencyName: "Kab. Solok", Occupancy: "sedang", ActiveGuests: 610},
		{RegencyName: "Kota Payakumbuh", Occupancy: "sedang", ActiveGuests: 580},
		{RegencyName: "Kota Padang Panjang", Occupancy: "sedang", ActiveGuests: 490},
		{RegencyName: "Kota Pariaman", Occupancy: "normal", ActiveGuests: 380},
		{RegencyName: "Kab. Padang Pariaman", Occupancy: "normal", ActiveGuests: 410},
		{RegencyName: "Kota Solok", Occupancy: "normal", ActiveGuests: 290},
		{RegencyName: "Kab. Solok Selatan", Occupancy: "normal", ActiveGuests: 210},
		{RegencyName: "Kab. Sijunjung", Occupancy: "normal", ActiveGuests: 180},
		{RegencyName: "Kab. Dharmasraya", Occupancy: "normal", ActiveGuests: 150},
		{RegencyName: "Kab. Pasaman", Occupancy: "normal", ActiveGuests: 190},
		{RegencyName: "Kab. Pasaman Barat", Occupancy: "normal", ActiveGuests: 220},
		{RegencyName: "Kab. Kepulauan Mentawai", Occupancy: "normal", ActiveGuests: 310},
	}

	// 2. Top Destinasi
	topDestinations := []models.TopDestinationMetric{
		{DestinationID: "spot-jam-gadang", DestinationName: "Jam Gadang Bukittinggi", Regency: "Kota Bukittinggi", TotalCheckIns: 432},
		{DestinationID: "spot-pagaruyung", DestinationName: "Istano Basa Pagaruyung", Regency: "Kab. Tanah Datar", TotalCheckIns: 389},
		{DestinationID: "spot-lembah-harau", DestinationName: "Lembah Harau & Kelok 9", Regency: "Kab. Lima Puluh Kota", TotalCheckIns: 341},
		{DestinationID: "spot-kawasan-mandeh", DestinationName: "Kawasan Bahari Mandeh", Regency: "Kab. Pesisir Selatan", TotalCheckIns: 295},
		{DestinationID: "spot-danau-maninjau", DestinationName: "Danau Maninjau", Regency: "Kab. Agam", TotalCheckIns: 260},
	}

	// 3. Distribusi Kategori Mitra UMKM Minangkabau
	categoryDist := map[string]int{
		"Homestay Rumah Gadang": 1,
		"Kuliner Halal":         1,
		"Transport & Perahu":    1,
		"Pemandu Pokdarwis":     1,
		"Sewa Baju Adat":        1,
	}

	summary := models.DisparAnalyticsSummary{
		TotalVisits:               1420,
		TotalQRScans:              850,
		TotalEscrowTurnover:       45250000.0,
		TotalUMKMPartners:         5,
		RegencyDensityHeatmap:     regencies,
		TopDestinations:           topDestinations,
		MitraCategoryDistribution: categoryDist,
	}

	return summary, nil
}

