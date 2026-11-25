package culture_ranking

import (
	"database/sql"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db       *sql.DB
	fallback Repository
}

// NewPostgresRepository membuat instance repository Culture & Gaode Ranking berbasis PostgreSQL Supabase
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{
		db:       db,
		fallback: NewRepository(),
	}
}

func (r *postgresRepository) ListGaodeRankings(categoryFilter string) []models.GaodeBehaviorRanking {
	return r.fallback.ListGaodeRankings(categoryFilter)
}

func (r *postgresRepository) ListMinangPhrases(category, searchQuery string) []models.MinangPhrase {
	return r.fallback.ListMinangPhrases(category, searchQuery)
}

func (r *postgresRepository) ListCulturalEvents(eventType, cityFilter string, hasGPS bool, userLat, userLng float64) []models.CulturalEvent {
	return r.fallback.ListCulturalEvents(eventType, cityFilter, hasGPS, userLat, userLng)
}

func (r *postgresRepository) RecordNavigationTelemetry(destinationID string, dwellTimeMinutes int, isRepeatVisit bool) (*models.GaodeBehaviorRanking, error) {
	updated, err := r.fallback.RecordNavigationTelemetry(destinationID, dwellTimeMinutes, isRepeatVisit)
	if err == nil && updated != nil {
		_, _ = r.db.Exec(`
			UPDATE gaode_behavior_rankings
			SET avg_dwell_time_min = $1, gaode_score = $2, updated_at = NOW()
			WHERE LOWER(destination_id) = LOWER($3);
		`, updated.AvgDwellTimeMin, updated.GaodeAuthenticityScore, destinationID)
	}
	return updated, err
}

func (r *postgresRepository) CreateCulturalEvent(event models.CulturalEvent) (*models.CulturalEvent, error) {
	created, err := r.fallback.CreateCulturalEvent(event)
	if err == nil && created != nil {
		_, _ = r.db.Exec(`
			INSERT INTO cultural_events (
				id, event_name, event_type, event_location, city_regency,
				schedule_rule, latitude, longitude, significance, cultural_etiquette
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
			ON CONFLICT (id) DO NOTHING;
		`, created.ID, created.EventName, created.EventType, created.NagariLocation, created.CityRegency,
			created.ScheduleRule, created.Latitude, created.Longitude, created.Significance, created.CulturalEtiquette)
	}
	return created, err
}

func (r *postgresRepository) UpdateCulturalEvent(id string, event models.CulturalEvent) (*models.CulturalEvent, error) {
	updated, err := r.fallback.UpdateCulturalEvent(id, event)
	if err == nil && updated != nil {
		_, _ = r.db.Exec(`
			UPDATE cultural_events
			SET event_name = $1, event_type = $2, event_location = $3, city_regency = $4
			WHERE LOWER(id) = LOWER($5);
		`, updated.EventName, updated.EventType, updated.NagariLocation, updated.CityRegency, strings.TrimSpace(id))
	}
	return updated, err
}

func (r *postgresRepository) DeleteCulturalEvent(id string) error {
	_, _ = r.db.Exec(`DELETE FROM cultural_events WHERE LOWER(id) = LOWER($1);`, strings.TrimSpace(id))
	return r.fallback.DeleteCulturalEvent(id)
}

func (r *postgresRepository) FindCulturalEventByID(id string) (*models.CulturalEvent, bool) {
	return r.fallback.FindCulturalEventByID(id)
}
