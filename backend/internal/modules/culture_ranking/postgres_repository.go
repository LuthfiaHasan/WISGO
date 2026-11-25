package culture_ranking

import (
	"database/sql"
	"sort"
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
	rows, err := r.db.Query(`
		SELECT g.id, g.destination_id, COALESCE(d.name, g.destination_id), COALESCE(d.city_regency, 'Sumatera Barat'),
		       g.category, g.rank_position, g.gaode_authenticity_score, g.active_nav_count_30d,
		       g.avg_dwell_time_min, g.return_visit_rate_pct, g.anti_fake_review_verified, g.trending_badge, g.updated_at
		FROM gaode_behavior_rankings g
		LEFT JOIN destinations d ON d.id = g.destination_id
		ORDER BY g.gaode_authenticity_score DESC;
	`)
	if err != nil {
		return r.fallback.ListGaodeRankings(categoryFilter)
	}
	defer rows.Close()

	qCat := strings.ToLower(strings.TrimSpace(categoryFilter))
	var list []models.GaodeBehaviorRanking
	for rows.Next() {
		var item models.GaodeBehaviorRanking
		if err := rows.Scan(
			&item.ID, &item.DestinationID, &item.DestinationName, &item.CityRegency,
			&item.Category, &item.RankPosition, &item.GaodeAuthenticityScore, &item.ActiveNavCount30d,
			&item.AvgDwellTimeMin, &item.ReturnVisitRatePct, &item.AntiFakeReviewVerified, &item.TrendingBadge, &item.UpdatedAt,
		); err == nil {
			if qCat != "" && !strings.Contains(strings.ToLower(item.Category), qCat) {
				continue
			}
			list = append(list, item)
		}
	}

	if len(list) == 0 {
		return r.fallback.ListGaodeRankings(categoryFilter)
	}

	sort.Slice(list, func(i, j int) bool {
		return list[i].GaodeAuthenticityScore > list[j].GaodeAuthenticityScore
	})
	for idx := range list {
		list[idx].RankPosition = idx + 1
	}
	return list
}

func (r *postgresRepository) ListMinangPhrases(category, searchQuery string) []models.MinangPhrase {
	rows, err := r.db.Query(`
		SELECT id, category, indonesian_text, minang_text, phonetic_guide,
		       audio_url, dialect_note, usage_context_tip, politeness_level
		FROM minang_phrases
		ORDER BY id ASC;
	`)
	if err != nil {
		return r.fallback.ListMinangPhrases(category, searchQuery)
	}
	defer rows.Close()

	qCat := strings.ToLower(strings.TrimSpace(category))
	qSearch := strings.ToLower(strings.TrimSpace(searchQuery))

	var list []models.MinangPhrase
	for rows.Next() {
		var p models.MinangPhrase
		if err := rows.Scan(
			&p.ID, &p.Category, &p.IndonesianText, &p.MinangText, &p.PhoneticGuide,
			&p.AudioURL, &p.DialectNote, &p.UsageContextTip, &p.PolitenessLevel,
		); err == nil {
			p.IndonesianMeaning = p.IndonesianText
			p.MinangPhraseText = p.MinangText
			p.VoiceText = p.AudioURL
			p.ContextUsage = p.UsageContextTip
			p.KatoType = p.PolitenessLevel
			if qCat != "" && !strings.Contains(strings.ToLower(p.Category), qCat) {
				continue
			}
			if qSearch != "" {
				matched := strings.Contains(strings.ToLower(p.IndonesianText), qSearch) ||
					strings.Contains(strings.ToLower(p.MinangText), qSearch) ||
					strings.Contains(strings.ToLower(p.UsageContextTip), qSearch)
				if !matched {
					continue
				}
			}
			list = append(list, p)
		}
	}

	if len(list) == 0 {
		return r.fallback.ListMinangPhrases(category, searchQuery)
	}
	return list
}

func (r *postgresRepository) ListCulturalEvents(eventType, cityFilter string, hasGPS bool, userLat, userLng float64) []models.CulturalEvent {
	rows, err := r.db.Query(`
		SELECT id, title, event_type, nagari_location, city_regency,
		       schedule_rule, next_event_date::text, latitude, longitude, highlight_item, cultural_etiquette
		FROM cultural_events
		ORDER BY id ASC;
	`)
	if err != nil {
		rows, err = r.db.Query(`
			SELECT id, event_name, event_type, event_location, city_regency,
			       schedule_rule, next_event_date::text, latitude, longitude, significance, cultural_etiquette
			FROM cultural_events
			ORDER BY id ASC;
		`)
	}
	if err != nil {
		return r.fallback.ListCulturalEvents(eventType, cityFilter, hasGPS, userLat, userLng)
	}
	defer rows.Close()

	qType := strings.ToLower(strings.TrimSpace(eventType))
	qCity := strings.ToLower(strings.TrimSpace(cityFilter))

	var list []models.CulturalEvent
	for rows.Next() {
		var ev models.CulturalEvent
		if err := rows.Scan(
			&ev.ID, &ev.Title, &ev.EventType, &ev.NagariLocation, &ev.CityRegency,
			&ev.ScheduleRule, &ev.NextEventDate, &ev.Latitude, &ev.Longitude, &ev.HighlightItem, &ev.CulturalEtiquette,
		); err == nil {
			ev.EventName = ev.Title
			ev.EventLocation = ev.NagariLocation
			ev.Significance = ev.HighlightItem
			if qType != "" && !strings.Contains(strings.ToLower(ev.EventType), qType) {
				continue
			}
			if qCity != "" && !strings.Contains(strings.ToLower(ev.CityRegency), qCity) && !strings.Contains(strings.ToLower(ev.NagariLocation), qCity) {
				continue
			}
			if hasGPS {
				ev.DistanceKm = CalculateSpatialDistanceKm(userLat, userLng, ev.Latitude, ev.Longitude)
			} else {
				ev.DistanceKm = CalculateSpatialDistanceKm(-0.9471, 100.4172, ev.Latitude, ev.Longitude)
			}
			list = append(list, ev)
		}
	}

	if len(list) == 0 {
		return r.fallback.ListCulturalEvents(eventType, cityFilter, hasGPS, userLat, userLng)
	}
	return list
}

func (r *postgresRepository) RecordNavigationTelemetry(destinationID string, dwellTimeMinutes int, isRepeatVisit bool) (*models.GaodeBehaviorRanking, error) {
	updated, err := r.fallback.RecordNavigationTelemetry(destinationID, dwellTimeMinutes, isRepeatVisit)
	if err == nil && updated != nil {
		_, _ = r.db.Exec(`
			UPDATE gaode_behavior_rankings
			SET active_nav_count_30d = $1, avg_dwell_time_min = $2, return_visit_rate_pct = $3,
			    gaode_authenticity_score = $4, updated_at = NOW()
			WHERE LOWER(destination_id) = LOWER($5);
		`, updated.ActiveNavCount30d, updated.AvgDwellTimeMin, updated.ReturnVisitRatePct, updated.GaodeAuthenticityScore, destinationID)
	}
	return updated, err
}

func (r *postgresRepository) CreateCulturalEvent(event models.CulturalEvent) (*models.CulturalEvent, error) {
	created, err := r.fallback.CreateCulturalEvent(event)
	if err == nil && created != nil {
		_, execErr := r.db.Exec(`
			INSERT INTO cultural_events (
				id, title, event_type, nagari_location, city_regency,
				schedule_rule, next_event_date, latitude, longitude, highlight_item, cultural_etiquette
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
			ON CONFLICT (id) DO NOTHING;
		`, created.ID, created.Title, created.EventType, created.NagariLocation, created.CityRegency,
			created.ScheduleRule, created.NextEventDate, created.Latitude, created.Longitude, created.HighlightItem, created.CulturalEtiquette)
		if execErr != nil {
			_, _ = r.db.Exec(`
				INSERT INTO cultural_events (
					id, event_name, event_type, event_location, city_regency,
					schedule_rule, latitude, longitude, significance, cultural_etiquette
				) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
				ON CONFLICT (id) DO NOTHING;
			`, created.ID, created.EventName, created.EventType, created.NagariLocation, created.CityRegency,
				created.ScheduleRule, created.Latitude, created.Longitude, created.Significance, created.CulturalEtiquette)
		}
	}
	return created, err
}

func (r *postgresRepository) UpdateCulturalEvent(id string, event models.CulturalEvent) (*models.CulturalEvent, error) {
	updated, err := r.fallback.UpdateCulturalEvent(id, event)
	if err == nil && updated != nil {
		_, execErr := r.db.Exec(`
			UPDATE cultural_events
			SET title = $1, event_type = $2, nagari_location = $3, city_regency = $4
			WHERE LOWER(id) = LOWER($5);
		`, updated.Title, updated.EventType, updated.NagariLocation, updated.CityRegency, strings.TrimSpace(id))
		if execErr != nil {
			_, _ = r.db.Exec(`
				UPDATE cultural_events
				SET event_name = $1, event_type = $2, event_location = $3, city_regency = $4
				WHERE LOWER(id) = LOWER($5);
			`, updated.EventName, updated.EventType, updated.NagariLocation, updated.CityRegency, strings.TrimSpace(id))
		}
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
