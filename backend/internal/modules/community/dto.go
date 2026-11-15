package community

import (
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// CreateCommunityPlaceRequest payload kontribusi tempat baru komunitas
type CreateCommunityPlaceRequest struct {
	UserID      string  `json:"user_id"`
	Name        string  `json:"name" binding:"required"`
	Category    string  `json:"category"`
	CityRegency string  `json:"city_regency"`
	Description string  `json:"description"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	TipsMenjaga string  `json:"tips_menjaga" binding:"required"` // Wajib untuk kelestarian alam hidden gem
	IsSensitive bool    `json:"is_sensitive"`                   // Proteksi koordinat radius perkiraan
}

// CreateCommunityPlaceResponse respon pengajuan tempat baru komunitas
type CreateCommunityPlaceResponse struct {
	Place          models.CommunityPlace `json:"place"`
	MaskingApplied bool                  `json:"masking_applied"`
	Note           string                `json:"note,omitempty"`
}

// CreateSharedTripRequest payload postingan cari barengan sewa armada / trip
type CreateSharedTripRequest struct {
	UserID           string  `json:"user_id"`
	Title            string  `json:"title" binding:"required"`
	DestinationRoute string  `json:"destination_route" binding:"required"`
	DepartureDate    string  `json:"departure_date"`
	AvailableSeats   int     `json:"available_seats"`
	CostPerPerson    float64 `json:"cost_per_person"`
	ContactWA        string  `json:"contact_wa"`
}

