package culture_ranking

import (
	"math"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ComputeGaodeScore menghitung skor keaslian Gaode Guide (0 - 100)
// Rumus: (0.45 * NormalizedNav) + (0.40 * NormalizedDwellTime) + (0.15 * ReturnVisitRate)
func ComputeGaodeScore(activeNavCount, avgDwellMin int, returnRatePct float64) float64 {
	normNav := math.Min(100.0, (float64(activeNavCount)/5000.0)*100.0)
	normDwell := math.Min(100.0, (float64(avgDwellMin)/140.0)*100.0)
	normReturn := math.Min(100.0, (returnRatePct/40.0)*100.0)

	rawScore := (0.45 * normNav) + (0.40 * normDwell) + (0.15 * normReturn)
	// Skala ke rentang populer 82.0 - 99.8 untuk visualisasi leaderboard
	scaled := 82.0 + (rawScore/100.0)*17.5
	return math.Round(math.Min(99.8, scaled)*10) / 10
}

// GaodeRankingsResponse respon peringkat destinasi berbasis perilaku nyata GPS
type GaodeRankingsResponse struct {
	Status         string                        `json:"status"`
	Algorithm      string                        `json:"algorithm"`
	AntiFakePolicy string                        `json:"anti_fake_policy"`
	CategoryFilter string                        `json:"category_filter,omitempty"`
	Total          int                           `json:"total"`
	Rankings       []models.GaodeBehaviorRanking `json:"rankings"`
}

// MinangPhrasesResponse respon kamus saku audio Minangkabau
type MinangPhrasesResponse struct {
	Status        string                `json:"status"`
	DesignToken   string                `json:"design_token"`
	CulturalGuide string                `json:"cultural_guide"`
	Total         int                   `json:"total"`
	Phrases       []models.MinangPhrase `json:"phrases"`
}

// CulturalEventsResponse respon kalender budaya dan hari pakan nagari
type CulturalEventsResponse struct {
	Status      string                 `json:"status"`
	DesignToken string                 `json:"design_token"`
	Total       int                    `json:"total"`
	Events      []models.CulturalEvent `json:"events"`
}

// CreateCulturalEventRequest payload untuk input event oleh Vendor atau Admin Dispar (ERD Revisi #15)
type CreateCulturalEventRequest struct {
	Title             string  `json:"title"`
	EventName         string  `json:"event_name,omitempty"`
	EventType         string  `json:"event_type"` // Hari Pakan Nagari, Festival Budaya, Tradisi Adat
	NagariLocation    string  `json:"nagari_location"`
	EventLocation     string  `json:"event_location,omitempty"`
	CityRegency       string  `json:"city_regency"`
	ScheduleRule      string  `json:"schedule_rule"`
	NextEventDate     string  `json:"next_event_date"`
	Latitude          float64 `json:"latitude"`
	Longitude         float64 `json:"longitude"`
	HighlightItem     string  `json:"highlight_item"`
	Significance      string  `json:"significance,omitempty"`
	CulturalEtiquette string  `json:"cultural_etiquette"`
	UserID            string  `json:"user_id,omitempty"` // ID vendor/user penginput
}
