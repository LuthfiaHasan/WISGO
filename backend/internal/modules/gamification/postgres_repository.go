package gamification

import (
	"database/sql"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db           *sql.DB
	mu           sync.RWMutex
	iconicSpots  []models.IconicSpotItem
	certificates map[string]CertificateResponse
}

// NewPostgresRepository membuat instance repository berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	repo := &postgresRepository{
		db:           db,
		iconicSpots:  make([]models.IconicSpotItem, 0),
		certificates: make(map[string]CertificateResponse),
	}
	repo.seedIconicSpots()
	return repo
}

func (r *postgresRepository) seedIconicSpots() {
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
			Latitude:  -0.1023,
			Longitude: 100.6728,
			BadgeName: "Lencana Geopark Lembah Harau",
		},
		{
			ID:        "spot-danau-maninjau",
			Name:      "Danau Maninjau & Kelok 44",
			Regency:   "Kab. Agam",
			Latitude:  -0.2974,
			Longitude: 100.1983,
			BadgeName: "Lencana Danau Vulkanik Purba",
		},
		{
			ID:        "spot-pulau-mandeh",
			Name:      "Kawasan Bahari Terpadu Mandeh",
			Regency:   "Kab. Pesisir Selatan",
			Latitude:  -1.2833,
			Longitude: 100.4167,
			BadgeName: "Lencana Raja Ampat Ranah Minang",
		},
	}
}

func (r *postgresRepository) GetIconicSpots() []models.IconicSpotItem {
	return r.iconicSpots
}

func (r *postgresRepository) GetSpotByID(id string) (*models.IconicSpotItem, bool) {
	normID := strings.ToLower(strings.TrimSpace(id))
	destMap := map[string]string{
		"dest-001": "spot-lembah-harau",
		"dest-002": "spot-jam-gadang",
		"dest-003": "spot-pagaruyung",
		"dest-004": "spot-danau-maninjau",
		"dest-005": "spot-pulau-mandeh",
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

func (r *postgresRepository) AddPassportStamp(userID, spotID string, t time.Time) {
	// Pastikan user terdaftar
	_, _ = r.db.Exec(`
		INSERT INTO users (id, phone_number, full_name, role, created_at)
		VALUES ($1, '628120000001', 'Penjelajah Ranah Minang', 'tourist', NOW())
		ON CONFLICT (id) DO NOTHING;
	`, userID)

	passID := fmt.Sprintf("pass-%d", time.Now().UnixNano()%100000)
	_, _ = r.db.Exec(`
		INSERT INTO digital_passports (id, user_id, destination_id, checked_in_at, is_gps_valid)
		VALUES ($1, $2, $3, $4, TRUE)
		ON CONFLICT (user_id, destination_id) DO UPDATE SET checked_in_at = EXCLUDED.checked_in_at;
	`, passID, userID, spotID, t)
}

func (r *postgresRepository) GetUserPassportStamps(userID string) map[string]time.Time {
	result := make(map[string]time.Time)
	rows, err := r.db.Query(`
		SELECT destination_id, checked_in_at
		FROM digital_passports
		WHERE user_id = $1;
	`, userID)
	if err != nil {
		return result
	}
	defer rows.Close()

	for rows.Next() {
		var spotID string
		var checkIn time.Time
		if err := rows.Scan(&spotID, &checkIn); err == nil {
			result[spotID] = checkIn
		}
	}
	return result
}

func (r *postgresRepository) SaveCertificate(userID string, cert CertificateResponse) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.certificates[userID] = cert
}

func (r *postgresRepository) GetCertificate(userID string) (*CertificateResponse, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	cert, ok := r.certificates[userID]
	if !ok {
		return nil, false
	}
	return &cert, true
}

func (r *postgresRepository) GetTotalStampsCount() int {
	var count int
	_ = r.db.QueryRow(`SELECT COUNT(*) FROM digital_passports;`).Scan(&count)
	return count
}
