package spatial

import (
	"database/sql"
	"sort"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db       *sql.DB
	fallback Repository
}

// NewPostgresRepository membuat instance repository spasial berbasis PostgreSQL + PostGIS (Supabase)
// Dilengkapi fallback in-memory otomatis agar tahan gangguan jaringan
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{
		db:       db,
		fallback: NewRepository(),
	}
}

func (r *postgresRepository) SearchShunluAlongRoute(req ShunluSearchRequest) []models.ShunluPOI {
	rows, err := r.db.Query(`
		SELECT id, name, COALESCE(category_id, 'rm_padang'), corridor_road, city_regency,
		       latitude, longitude, detour_minutes, detour_distance_meter, highlight_note, opening_hours, is_recommended
		FROM visit_point
		ORDER BY detour_minutes ASC;
	`)
	if err != nil {
		rows, err = r.db.Query(`
			SELECT id, name, COALESCE(category_id, 'rm_padang'), corridor_road, city_regency,
			       latitude, longitude, detour_estimated_minute, detour_distance_meter, highlight_note, opening_hours, is_recommended
			FROM visit_point
			ORDER BY detour_estimated_minute ASC;
		`)
	}
	if err != nil {
		return r.fallback.SearchShunluAlongRoute(req)
	}
	defer rows.Close()

	qCat := strings.ToLower(strings.TrimSpace(req.Category))
	var matches []models.ShunluPOI
	for rows.Next() {
		var p models.ShunluPOI
		if err := rows.Scan(
			&p.ID, &p.Name, &p.Category, &p.CorridorRoad, &p.CityRegency,
			&p.Latitude, &p.Longitude, &p.DetourMinutes, &p.DetourDistanceMeter,
			&p.HighlightNote, &p.OpeningHours, &p.IsRecommended,
		); err == nil {
			if qCat != "" && !strings.Contains(strings.ToLower(p.Category), qCat) {
				continue
			}
			if req.MaxDetourMin > 0 && p.DetourMinutes > req.MaxDetourMin {
				continue
			}
			matches = append(matches, p)
		}
	}

	if len(matches) == 0 {
		return r.fallback.SearchShunluAlongRoute(req)
	}
	sort.Slice(matches, func(i, j int) bool {
		return matches[i].DetourMinutes < matches[j].DetourMinutes
	})
	return matches
}

func (r *postgresRepository) GetMicroMapByDestinationID(destID, destName string, lat, lng float64) models.ScenicMicroMap {
	return r.fallback.GetMicroMapByDestinationID(destID, destName, lat, lng)
}

func (r *postgresRepository) ListHazardAlerts(severityFilter, corridorFilter string) []models.HazardAlert {
	rows, err := r.db.Query(`
		SELECT id, corridor_code, title, road_segment, city_regency, latitude, longitude,
		       severity_level, hazard_status, weather_status, steep_gradient_deg, message,
		       detour_route, nearest_rescue_post, emergency_contact, COALESCE(triggered_by_admin, ''), updated_at
		FROM hazard_alerts
		ORDER BY id ASC;
	`)
	if err != nil {
		return r.fallback.ListHazardAlerts(severityFilter, corridorFilter)
	}
	defer rows.Close()

	qSev := strings.ToLower(strings.TrimSpace(severityFilter))
	qCor := strings.ToLower(strings.TrimSpace(corridorFilter))

	var list []models.HazardAlert
	for rows.Next() {
		var h models.HazardAlert
		if err := rows.Scan(
			&h.ID, &h.CorridorCode, &h.Location, &h.RoadSegment, &h.CityRegency, &h.Latitude, &h.Longitude,
			&h.Severity, &h.HazardType, &h.WeatherStatus, &h.SlopeGradientDeg, &h.Message,
			&h.DetourRoute, &h.NearestRescuePost, &h.EmergencyContact, &h.TriggeredByAdmin, &h.UpdatedAt,
		); err == nil {
			h.RadiusMeter = 3000
			if qSev != "" && !strings.Contains(strings.ToLower(h.Severity), qSev) {
				continue
			}
			if qCor != "" && !strings.Contains(strings.ToLower(h.CorridorCode), qCor) && !strings.Contains(strings.ToLower(h.Location), qCor) {
				continue
			}
			list = append(list, h)
		}
	}

	if len(list) == 0 {
		return r.fallback.ListHazardAlerts(severityFilter, corridorFilter)
	}
	return list
}

func (r *postgresRepository) TriggerHazardCorridor(input TriggerHazardInput) (*models.HazardAlert, error) {
	updated, err := r.fallback.TriggerHazardCorridor(input)
	if err != nil {
		return nil, err
	}

	_, _ = r.db.Exec(`
		UPDATE hazard_alerts
		SET severity_level = $1, hazard_status = $2, weather_status = $3, message = $4,
		    detour_route = $5, triggered_by_admin = $6, updated_at = $7
		WHERE LOWER(corridor_code) = LOWER($8) OR LOWER(id) = LOWER($8);
	`, updated.Severity, updated.HazardType, updated.WeatherStatus, updated.Message,
		updated.DetourRoute, updated.TriggeredByAdmin, time.Now(), input.CorridorCode)

	return updated, nil
}

func (r *postgresRepository) CreateSOSSignal(input SOSEmergencyInput) models.SOSSignal {
	signal := r.fallback.CreateSOSSignal(input)

	_, _ = r.db.Exec(`
		INSERT INTO sos_signals (
			id, sos_code, tourist_name, phone_number, emergency_type,
			latitude, longitude, battery_percent, passengers_count,
			current_corridor, nearest_rescue_post, distance_to_rescue_km,
			eta_rescue_minutes, status, notes, created_at
		) VALUES (
			$1, $2, $3, $4, $5,
			$6, $7, $8, $9,
			$10, $11, $12,
			$13, $14, $15, $16
		) ON CONFLICT (sos_code) DO NOTHING;
	`, signal.ID, signal.SOSCode, signal.TouristName, signal.PhoneNumber, signal.EmergencyType,
		signal.Latitude, signal.Longitude, signal.BatteryPercent, signal.PassengersCount,
		signal.NearestCorridor, signal.NearestRescuePost, signal.DistanceToRescueKm,
		signal.ETARescueMinutes, signal.Status, signal.Notes, signal.CreatedAt)

	return signal
}

func (r *postgresRepository) ListSOSSignals() []models.SOSSignal {
	rows, err := r.db.Query(`
		SELECT id, sos_code, tourist_name, phone_number, emergency_type,
		       latitude, longitude, battery_percent, passengers_count,
		       current_corridor, nearest_rescue_post, distance_to_rescue_km,
		       eta_rescue_minutes, status, COALESCE(notes, ''), created_at
		FROM sos_signals
		ORDER BY created_at DESC;
	`)
	if err != nil {
		return r.fallback.ListSOSSignals()
	}
	defer rows.Close()

	var list []models.SOSSignal
	for rows.Next() {
		var s models.SOSSignal
		if err := rows.Scan(
			&s.ID, &s.SOSCode, &s.TouristName, &s.PhoneNumber, &s.EmergencyType,
			&s.Latitude, &s.Longitude, &s.BatteryPercent, &s.PassengersCount,
			&s.NearestCorridor, &s.NearestRescuePost, &s.DistanceToRescueKm,
			&s.ETARescueMinutes, &s.Status, &s.Notes, &s.CreatedAt,
		); err == nil {
			s.EmergencyCallAction = "tel:112"
			list = append(list, s)
		}
	}

	if len(list) == 0 {
		return r.fallback.ListSOSSignals()
	}
	return list
}

func (r *postgresRepository) RecordNavigationTelemetry(input NavigationTelemetryInput) (*models.GaodeBehaviorRanking, error) {
	return r.fallback.RecordNavigationTelemetry(input)
}

func (r *postgresRepository) ListEmergencyContacts(corridorFilter string) []models.EmergencyContact {
	rows, err := r.db.Query(`
		SELECT id, COALESCE(corridor_code, ''), agency_type, agency_name, phone_number,
		       COALESCE(whatsapp_number, ''), city, is_active
		FROM emergency_contacts
		WHERE is_active = TRUE
		ORDER BY id ASC;
	`)
	if err != nil {
		rows, err = r.db.Query(`
			SELECT id, '', agency_type, agency_name, phone_number,
			       COALESCE(whatsapp_number, ''), city_regency, is_active
			FROM emergency_contacts
			WHERE is_active = TRUE
			ORDER BY id ASC;
		`)
	}
	if err != nil {
		return r.fallback.ListEmergencyContacts(corridorFilter)
	}
	defer rows.Close()

	q := strings.ToUpper(strings.TrimSpace(corridorFilter))
	var results []models.EmergencyContact
	for rows.Next() {
		var c models.EmergencyContact
		if err := rows.Scan(
			&c.ID, &c.CorridorCode, &c.AgencyType, &c.AgencyName, &c.PhoneNumber,
			&c.WhatsAppNumber, &c.City, &c.IsActive,
		); err == nil {
			if q != "" {
				if !strings.Contains(strings.ToUpper(c.CorridorCode), q) &&
					!strings.Contains(strings.ToUpper(c.City), q) &&
					!strings.Contains(strings.ToUpper(c.AgencyType), q) {
					continue
				}
			}
			results = append(results, c)
		}
	}

	if len(results) == 0 {
		return r.fallback.ListEmergencyContacts(corridorFilter)
	}
	return results
}

func (r *postgresRepository) FindNearestEmergencyContact(lat, lng float64) *models.EmergencyContact {
	return r.fallback.FindNearestEmergencyContact(lat, lng)
}

func (r *postgresRepository) UpdateSOSSignalStatus(idOrCode, status, sarUnit string) (*models.SOSSignal, error) {
	updated, err := r.fallback.UpdateSOSSignalStatus(idOrCode, status, sarUnit)
	if err == nil && updated != nil {
		_, _ = r.db.Exec(`
			UPDATE sos_signals
			SET status = $1, nearest_rescue_post = $2
			WHERE LOWER(id) = LOWER($3) OR LOWER(sos_code) = LOWER($3);
		`, updated.Status, updated.NearestRescuePost, idOrCode)
	}
	return updated, err
}

func (r *postgresRepository) UpsertEmergencyContact(contact models.EmergencyContact) models.EmergencyContact {
	saved := r.fallback.UpsertEmergencyContact(contact)
	_, err := r.db.Exec(`
		INSERT INTO emergency_contacts (
			id, corridor_code, agency_type, agency_name, phone_number, whatsapp_number, city, is_active
		) VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
		ON CONFLICT (id) DO UPDATE SET
			agency_type = EXCLUDED.agency_type,
			agency_name = EXCLUDED.agency_name,
			phone_number = EXCLUDED.phone_number,
			whatsapp_number = EXCLUDED.whatsapp_number,
			city = EXCLUDED.city,
			is_active = TRUE;
	`, saved.ID, saved.CorridorCode, saved.AgencyType, saved.AgencyName, saved.PhoneNumber, saved.WhatsAppNumber, saved.City)
	if err != nil {
		_, _ = r.db.Exec(`
			INSERT INTO emergency_contacts (
				id, agency_name, agency_type, phone_number, whatsapp_number, city_regency, created_by_admin_id, is_active
			) VALUES ($1, $2, $3, $4, $5, $6, 'usr-001', TRUE)
			ON CONFLICT (id) DO UPDATE SET
				agency_type = EXCLUDED.agency_type,
				agency_name = EXCLUDED.agency_name,
				phone_number = EXCLUDED.phone_number,
				whatsapp_number = EXCLUDED.whatsapp_number,
				city_regency = EXCLUDED.city_regency,
				is_active = TRUE;
		`, saved.ID, saved.AgencyName, saved.AgencyType, saved.PhoneNumber, saved.WhatsAppNumber, saved.City)
	}
	return saved
}

func (r *postgresRepository) DeleteEmergencyContact(id string) error {
	_, _ = r.db.Exec(`DELETE FROM emergency_contacts WHERE LOWER(id) = LOWER($1);`, id)
	return r.fallback.DeleteEmergencyContact(id)
}

func (r *postgresRepository) ListSosNews(portalFilter, categoryFilter string, onlyPublished bool) []models.SosNewsItem {
	return r.fallback.ListSosNews(portalFilter, categoryFilter, onlyPublished)
}

func (r *postgresRepository) UpsertSosNews(item models.SosNewsItem) models.SosNewsItem {
	return r.fallback.UpsertSosNews(item)
}

func (r *postgresRepository) DeleteSosNews(id string) error {
	return r.fallback.DeleteSosNews(id)
}

func (r *postgresRepository) SyncLivePortalNews() ([]models.SosNewsItem, int) {
	return r.fallback.SyncLivePortalNews()
}


