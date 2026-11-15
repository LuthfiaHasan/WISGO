package auth

import (
	"database/sql"
	"fmt"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db       *sql.DB
	mu       sync.RWMutex
	otpStore map[string]string // OTP disimpan in-memory aman bertenggat waktu
}

// NewPostgresRepository membuat instance repository berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{
		db:       db,
		otpStore: make(map[string]string),
	}
}

func (r *postgresRepository) SaveOTP(phone string, code string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.otpStore[phone] = code
	return nil
}

func (r *postgresRepository) GetOTP(phone string) (string, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	code, exists := r.otpStore[phone]
	return code, exists
}

func (r *postgresRepository) FindUserByPhone(phone string) (*models.User, bool) {
	query := `SELECT id, phone_number, full_name, role, created_at FROM users WHERE phone_number = $1;`
	var u models.User
	err := r.db.QueryRow(query, phone).Scan(&u.ID, &u.PhoneNumber, &u.FullName, &u.Role, &u.CreatedAt)
	if err != nil {
		return nil, false
	}
	return &u, true
}

func (r *postgresRepository) FindUserByID(id string) (*models.User, bool) {
	query := `SELECT id, phone_number, full_name, role, created_at FROM users WHERE id = $1;`
	var u models.User
	err := r.db.QueryRow(query, id).Scan(&u.ID, &u.PhoneNumber, &u.FullName, &u.Role, &u.CreatedAt)
	if err != nil {
		return nil, false
	}
	return &u, true
}

func (r *postgresRepository) CreateUser(user models.User) error {
	query := `
		INSERT INTO users (id, phone_number, full_name, role, created_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
	`
	now := time.Now()
	if user.CreatedAt.IsZero() {
		user.CreatedAt = now
	}
	_, err := r.db.Exec(query, user.ID, user.PhoneNumber, user.FullName, user.Role, user.CreatedAt)
	return err
}

func (r *postgresRepository) GetSavedPlaces(userID string) ([]models.SavedPlace, error) {
	query := `
		SELECT id, user_id, destination_id, created_at
		FROM saved_places
		WHERE user_id = $1
		ORDER BY created_at DESC;
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return []models.SavedPlace{}, err
	}
	defer rows.Close()

	var results []models.SavedPlace
	for rows.Next() {
		var sp models.SavedPlace
		if err := rows.Scan(&sp.ID, &sp.UserID, &sp.DestinationID, &sp.CreatedAt); err == nil {
			results = append(results, sp)
		}
	}
	return results, nil
}

func (r *postgresRepository) ToggleSavedPlace(userID, destinationID string) (bool, int, error) {
	// 1. Cek apakah sudah pernah disimpan
	var existingID string
	err := r.db.QueryRow(`
		SELECT id FROM saved_places WHERE user_id = $1 AND destination_id = $2;
	`, userID, destinationID).Scan(&existingID)

	if err == nil {
		// Ditemukan -> Hapus dari favorit
		_, _ = r.db.Exec(`DELETE FROM saved_places WHERE id = $1;`, existingID)
		var total int
		_ = r.db.QueryRow(`SELECT COUNT(*) FROM saved_places WHERE user_id = $1;`, userID).Scan(&total)
		return false, total, nil
	}

	// Tidak ditemukan -> Tambahkan ke favorit
	newID := fmt.Sprintf("sp-%d", time.Now().UnixNano()%1000000)
	_, _ = r.db.Exec(`
		INSERT INTO saved_places (id, user_id, destination_id, created_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT DO NOTHING;
	`, newID, userID, destinationID)

	var total int
	_ = r.db.QueryRow(`SELECT COUNT(*) FROM saved_places WHERE user_id = $1;`, userID).Scan(&total)
	return true, total, nil
}
