package gamification

import (
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka penyimpanan data stempel paspor digital dan titik ikonik
type Repository interface {
	GetIconicSpots() []models.IconicSpotItem
	GetSpotByID(id string) (*models.IconicSpotItem, bool)
	AddPassportStamp(userID, spotID string, t time.Time)
	GetUserPassportStamps(userID string) map[string]time.Time
	SaveCertificate(userID string, cert CertificateResponse)
	GetCertificate(userID string) (*CertificateResponse, bool)
	GetTotalStampsCount() int
}

type inMemoryRepository struct {
	mu           sync.RWMutex
	iconicSpots  []models.IconicSpotItem
	passports    map[string]map[string]time.Time       // key: user_id -> spot_id -> time
	certificates map[string]CertificateResponse        // key: user_id -> cert
}

// NewRepository membuat instance repository gamifikasi baru
func NewRepository() Repository {
	repo := &inMemoryRepository{
		iconicSpots:  make([]models.IconicSpotItem, 0),
		passports:    make(map[string]map[string]time.Time),
		certificates: make(map[string]CertificateResponse),
	}
	repo.seedData()
	return repo
}

func (r *inMemoryRepository) seedData() {
	r.iconicSpots = []models.IconicSpotItem{
		{
			ID:        "spot-jam-gadang",
			Name:      "Jam Gadang Bukittinggi",
			Regency:   "Kota Bukittinggi",
			Latitude:  -0.3051,
			Longitude: 100.3695,
			BadgeName: "Lencana Penjaga Waktu Minang",
		},
		{
			ID:        "spot-pagaruyung",
			Name:      "Istano Basa Pagaruyung",
			Regency:   "Kab. Tanah Datar",
			Latitude:  -0.4712,
			Longitude: 100.6214,
			BadgeName: "Lencana Pusaka Pagaruyung",
		},
		{
			ID:        "spot-lembah-harau",
			Name:      "Lembah Harau & Kelok 9",
			Regency:   "Kab. Lima Puluh Kota",
			Latitude:  -0.1062,
			Longitude: 100.6657,
			BadgeName: "Lencana Ngarai Batagak Harau",
		},
		{
			ID:        "spot-danau-maninjau",
			Name:      "Danau Maninjau & Kelok 44",
			Regency:   "Kab. Agam",
			Latitude:  -0.2980,
			Longitude: 100.1878,
			BadgeName: "Lencana Ranah Rang Agam",
		},
		{
			ID:        "spot-danau-singkarak",
			Name:      "Danau Singkarak",
			Regency:   "Kab. Solok",
			Latitude:  -0.6175,
			Longitude: 100.5367,
			BadgeName: "Lencana Bareh Danau Solok",
		},
		{
			ID:        "spot-kawasan-mandeh",
			Name:      "Kawasan Bahari Terpadu Mandeh",
			Regency:   "Kab. Pesisir Selatan",
			Latitude:  -1.2186,
			Longitude: 100.4192,
			BadgeName: "Lencana Raja Ampat Pasisie",
		},
		{
			ID:        "spot-ngarai-sianok",
			Name:      "Ngarai Sianok & Panorama",
			Regency:   "Kota Bukittinggi",
			Latitude:  -0.3106,
			Longitude: 100.3619,
			BadgeName: "Lencana Lembah Hijau Sianok",
		},
		{
			ID:        "spot-kota-tua-padang",
			Name:      "Kota Tua Padang & Muaro",
			Regency:   "Kota Padang",
			Latitude:  -0.9634,
			Longitude: 100.3547,
			BadgeName: "Lencana Ranah Bandaro Muaro",
		},
		{
			ID:        "spot-desa-pariangan",
			Name:      "Desa Nagari Tuo Pariangan",
			Regency:   "Kab. Tanah Datar",
			Latitude:  -0.4357,
			Longitude: 100.4939,
			BadgeName: "Lencana Asal Balai Nan Panjang",
		},
		{
			ID:        "spot-tambang-ombilin",
			Name:      "Tambang Batubara Ombilin (UNESCO)",
			Regency:   "Kota Sawahlunto",
			Latitude:  -0.6806,
			Longitude: 100.7767,
			BadgeName: "Lencana Warisan Dunia Ombilin",
		},
	}
}

func (r *inMemoryRepository) GetIconicSpots() []models.IconicSpotItem {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]models.IconicSpotItem, len(r.iconicSpots))
	copy(result, r.iconicSpots)
	return result
}

func (r *inMemoryRepository) GetSpotByID(id string) (*models.IconicSpotItem, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	normID := strings.ToLower(strings.TrimSpace(id))
	destMap := map[string]string{
		"dest-001": "spot-lembah-harau",
		"dest-002": "spot-jam-gadang",
		"dest-003": "spot-pantai-airmanis",
		"dest-004": "spot-pagaruyung",
		"dest-005": "spot-danau-maninjau",
		"dest-006": "spot-danau-singkarak",
		"dest-007": "spot-puncak-lawang",
		"dest-008": "spot-desa-pariangan",
		"dest-009": "spot-tarusan-kamang",
		"dest-010": "spot-sawahlunto-ombilin",
	}
	if mapped, ok := destMap[normID]; ok {
		normID = mapped
	}

	for i := range r.iconicSpots {
		if strings.ToLower(r.iconicSpots[i].ID) == normID || strings.EqualFold(r.iconicSpots[i].Name, id) {
			spot := r.iconicSpots[i]
			return &spot, true
		}
	}
	return nil, false
}

func (r *inMemoryRepository) AddPassportStamp(userID, spotID string, t time.Time) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.passports[userID] == nil {
		r.passports[userID] = make(map[string]time.Time)
	}
	r.passports[userID][spotID] = t
}

func (r *inMemoryRepository) GetUserPassportStamps(userID string) map[string]time.Time {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make(map[string]time.Time)
	if stamps, ok := r.passports[userID]; ok {
		for k, v := range stamps {
			result[k] = v
		}
	}
	return result
}

func (r *inMemoryRepository) SaveCertificate(userID string, cert CertificateResponse) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.certificates[userID] = cert
}

func (r *inMemoryRepository) GetCertificate(userID string) (*CertificateResponse, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	cert, ok := r.certificates[userID]
	if !ok {
		return nil, false
	}
	return &cert, true
}

func (r *inMemoryRepository) GetTotalStampsCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()

	count := 0
	for _, stamps := range r.passports {
		count += len(stamps)
	}
	return count
}

