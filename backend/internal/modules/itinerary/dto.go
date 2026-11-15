package itinerary

import "github.com/LuthfiaHasan/WISGO/backend/internal/models"

// AutoItineraryRequest payload permintaan generator jadwal otomatis 1-7 hari
type AutoItineraryRequest struct {
	UserID       string   `json:"user_id" binding:"required"`
	DurationDays int      `json:"duration_days" binding:"required,min=1,max=7"` // 1 - 7 hari
	ArrivalPoint string   `json:"arrival_point"`                                // "BIM" atau "Darat"
	TravelerType string   `json:"traveler_type"`                                // "family", "backpacker", "culinary", "open_trip"
	Preferences  []string `json:"preferences,omitempty"`
}

// CreateItineraryRequest payload pembuatan rencana perjalanan manual
type CreateItineraryRequest struct {
	UserID    string                 `json:"user_id" binding:"required"`
	Title     string                 `json:"title" binding:"required"`
	StartDate string                 `json:"start_date" binding:"required"` // Format: YYYY-MM-DD
	EndDate   string                 `json:"end_date" binding:"required"`   // Format: YYYY-MM-DD
	TotalDays int                    `json:"total_days"`
	Items     []models.ItineraryItem `json:"items,omitempty"`
}

