package community

import (
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka penyimpanan data komunitas dan papan cari barengan
type Repository interface {
	SaveCommunityPlace(place models.CommunityPlace) error
	GetCommunityPlaces() []models.CommunityPlace
	SaveSharedTrip(trip models.SharedTrip) error
	GetSharedTrips() []models.SharedTrip
}

type inMemoryRepository struct {
	mu              sync.RWMutex
	communityPlaces []models.CommunityPlace
	sharedTrips     []models.SharedTrip
}

// NewRepository membuat instance repository baru dengan initial seeder
func NewRepository() Repository {
	repo := &inMemoryRepository{
		communityPlaces: make([]models.CommunityPlace, 0),
		sharedTrips:     make([]models.SharedTrip, 0),
	}
	repo.seedData()
	return repo
}

func (r *inMemoryRepository) seedData() {
	// Seeder tempat komunitas
	r.communityPlaces = []models.CommunityPlace{
		{
			ID:          "cp-001",
			UserID:      "usr-001",
			Name:        "Air Terjun Lubuk Batang",
			Category:    "Hidden Gem Alam",
			CityRegency: "Kabupaten Lima Puluh Kota",
			Description: "Air terjun tersembunyi dengan pasir putih di tengah tebing batu alam nan asri",
			Latitude:    -0.0825,
			Longitude:   100.6550,
			TipsMenjaga: "Wajib bawa kembali sampah plastik, dilarang merusak vegetasi tebing dan hindari membuat suara bising berlebih",
			IsSensitive: true,
			Status:      "PENDING_CURATION",
			CreatedAt:   time.Now().Add(-24 * time.Hour),
		},
	}

	// Seeder shared trips
	r.sharedTrips = []models.SharedTrip{
		{
			ID:               "st-001",
			UserID:           "usr-002",
			Title:            "Barengan Sewa Avanza: Padang - Lembah Harau PP",
			DestinationRoute: "Bandara BIM / Padang Kota -> Bukittinggi -> Lembah Harau",
			DepartureDate:    time.Now().Add(48 * time.Hour),
			AvailableSeats:   3,
			CostPerPerson:    75000.0,
			ContactWA:        "6281234567890",
			CreatedAt:        time.Now().Add(-12 * time.Hour),
		},
	}
}

func (r *inMemoryRepository) SaveCommunityPlace(place models.CommunityPlace) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.communityPlaces = append(r.communityPlaces, place)
	return nil
}

func (r *inMemoryRepository) GetCommunityPlaces() []models.CommunityPlace {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]models.CommunityPlace, len(r.communityPlaces))
	copy(result, r.communityPlaces)
	return result
}

func (r *inMemoryRepository) SaveSharedTrip(trip models.SharedTrip) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.sharedTrips = append(r.sharedTrips, trip)
	return nil
}

func (r *inMemoryRepository) GetSharedTrips() []models.SharedTrip {
	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]models.SharedTrip, len(r.sharedTrips))
	copy(result, r.sharedTrips)
	return result
}

