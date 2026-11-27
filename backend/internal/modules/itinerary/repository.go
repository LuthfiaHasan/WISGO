package itinerary

import (
	"errors"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka data access untuk modul Rencana Perjalanan (Itinerary)
type Repository interface {
	FindByUserID(userID string) ([]models.Itinerary, error)
	FindByID(id string) (*models.Itinerary, error)
	Save(itinerary models.Itinerary) error
}

type inMemoryRepository struct {
	mu          sync.RWMutex
	itineraries map[string][]models.Itinerary // key: user_id -> list itinerary
}

// NewRepository menginisialisasi repository baru dengan data seeder
func NewRepository() Repository {
	repo := &inMemoryRepository{
		itineraries: make(map[string][]models.Itinerary),
	}

	// Seeder Itinerary Awal untuk usr-001
	now := time.Now()
	sampleItinerary := models.Itinerary{
		ID:        "itin-001",
		UserID:    "usr-001",
		Title:     "Eksplorasi Pesona Ranah Minang 3 Hari",
		StartDate: now.Format("2006-01-02"),
		EndDate:   now.AddDate(0, 0, 3).Format("2006-01-02"),
		TotalDays: 3,
		CreatedAt: now.Add(-24 * time.Hour),
		UpdatedAt: now.Add(-24 * time.Hour),
		Items: []models.ItineraryItem{
			{
				ID:            "item-01",
				ItineraryID:   "itin-001",
				DayNumber:     1,
				TimeSlot:      "09:00",
				DestinationID: "dest-01",
				Notes:         "Tiba di Jam Gadang Bukittinggi, foto pemandangan & jalan santai",
				TrafficAlert:  "Pasar Koto Baru Padang Panjang rawan macet pasar tumpah",
			},
		},
	}
	repo.itineraries["usr-001"] = []models.Itinerary{sampleItinerary}

	return repo
}

func (r *inMemoryRepository) FindByUserID(userID string) ([]models.Itinerary, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	list, exists := r.itineraries[userID]
	if !exists {
		return []models.Itinerary{}, nil
	}
	return list, nil
}

func (r *inMemoryRepository) FindByID(id string) (*models.Itinerary, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, userList := range r.itineraries {
		for _, itin := range userList {
			if itin.ID == id {
				return &itin, nil
			}
		}
	}
	return nil, errors.New("Itinerary tidak ditemukan")
}

func (r *inMemoryRepository) Save(itinerary models.Itinerary) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	list := r.itineraries[itinerary.UserID]
	// Cek apakah update atau create baru
	found := false
	for i, existing := range list {
		if existing.ID == itinerary.ID {
			list[i] = itinerary
			found = true
			break
		}
	}

	if !found {
		list = append([]models.Itinerary{itinerary}, list...)
	}

	r.itineraries[itinerary.UserID] = list
	return nil
}
