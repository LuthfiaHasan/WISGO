package auth

import (
	"fmt"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// OTPEntry menyimpan kode OTP beserta batas waktu kedaluwarsa (TTL)
type OTPEntry struct {
	Code      string
	ExpiresAt time.Time
}

// Repository antarmuka data access layer untuk modul Auth & Profil
type Repository interface {
	SaveOTP(phone string, code string, ttl time.Duration) error
	GetOTP(phone string) (string, bool)
	DeleteOTP(phone string) error
	FindUserByPhone(phone string) (*models.User, bool)
	FindUserByID(id string) (*models.User, bool)
	CreateUser(user models.User) error
	GetSavedPlaces(userID string) ([]models.SavedPlace, error)
	ToggleSavedPlace(userID, destinationID string) (bool, int, error)
}

type inMemoryRepository struct {
	mu          sync.RWMutex
	otpStore    map[string]OTPEntry            // key: phone -> OTPEntry
	users       map[string]models.User         // key: id -> User
	phoneToID   map[string]string              // key: phone -> id
	savedPlaces map[string][]models.SavedPlace // key: user_id -> slice
}

// NewRepository menginisialisasi repository baru dengan user seeder awal
func NewRepository() Repository {
	repo := &inMemoryRepository{
		otpStore:    make(map[string]OTPEntry),
		users:       make(map[string]models.User),
		phoneToID:   make(map[string]string),
		savedPlaces: make(map[string][]models.SavedPlace),
	}

	// Rutinitas pembersihan otomatis setiap 5 menit untuk mencegah kebocoran memori
	go repo.startCleanupTicker(5 * time.Minute)

	// Seeder User Awal
	initialUser := models.User{
		ID:          "usr-001",
		PhoneNumber: "6281211112222",
		FullName:    "Rahmat Hidayat (Wisatawan Mandiri)",
		Role:        "tourist",
		CreatedAt:   time.Now(),
	}
	repo.users[initialUser.ID] = initialUser
	repo.phoneToID[initialUser.PhoneNumber] = initialUser.ID

	// Seeder Tempat Tersimpan Awal
	repo.savedPlaces[initialUser.ID] = []models.SavedPlace{
		{
			ID:            "sp-001",
			UserID:        initialUser.ID,
			DestinationID: "dest-01",
			CreatedAt:     time.Now().Add(-2 * time.Hour),
		},
	}

	return repo
}

func (r *inMemoryRepository) SaveOTP(phone string, code string, ttl time.Duration) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.otpStore[phone] = OTPEntry{
		Code:      code,
		ExpiresAt: time.Now().Add(ttl),
	}
	return nil
}

func (r *inMemoryRepository) GetOTP(phone string) (string, bool) {
	r.mu.Lock()
	defer r.mu.Unlock()
	entry, exists := r.otpStore[phone]
	if !exists {
		return "", false
	}
	// Cek TTL kadaluarsa
	if time.Now().After(entry.ExpiresAt) {
		delete(r.otpStore, phone)
		return "", false
	}
	return entry.Code, true
}

func (r *inMemoryRepository) DeleteOTP(phone string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.otpStore, phone)
	return nil
}

func (r *inMemoryRepository) startCleanupTicker(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for range ticker.C {
		r.mu.Lock()
		now := time.Now()
		for phone, entry := range r.otpStore {
			if now.After(entry.ExpiresAt) {
				delete(r.otpStore, phone)
			}
		}
		r.mu.Unlock()
	}
}

func (r *inMemoryRepository) FindUserByPhone(phone string) (*models.User, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	id, ok := r.phoneToID[phone]
	if !ok {
		return nil, false
	}
	user, exists := r.users[id]
	if !exists {
		return nil, false
	}
	return &user, true
}

func (r *inMemoryRepository) FindUserByID(id string) (*models.User, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	user, exists := r.users[id]
	if !exists {
		return nil, false
	}
	return &user, true
}

func (r *inMemoryRepository) CreateUser(user models.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.users[user.ID] = user
	r.phoneToID[user.PhoneNumber] = user.ID
	return nil
}

func (r *inMemoryRepository) GetSavedPlaces(userID string) ([]models.SavedPlace, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	list, exists := r.savedPlaces[userID]
	if !exists {
		return []models.SavedPlace{}, nil
	}
	return list, nil
}

func (r *inMemoryRepository) ToggleSavedPlace(userID, destinationID string) (bool, int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	current := r.savedPlaces[userID]
	idx := -1
	for i, sp := range current {
		if sp.DestinationID == destinationID {
			idx = i
			break
		}
	}

	if idx >= 0 {
		// Hapus dari favorit
		r.savedPlaces[userID] = append(current[:idx], current[idx+1:]...)
		return false, len(r.savedPlaces[userID]), nil
	}

	// Tambahkan ke favorit
	newSaved := models.SavedPlace{
		ID:            fmt.Sprintf("sp-%d", time.Now().UnixNano()%1000000),
		UserID:        userID,
		DestinationID: destinationID,
		CreatedAt:     time.Now(),
	}
	r.savedPlaces[userID] = append(r.savedPlaces[userID], newSaved)
	return true, len(r.savedPlaces[userID]), nil
}
