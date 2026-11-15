package community

import (
	"database/sql"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db *sql.DB
}

// NewPostgresRepository membuat instance repository komunitas berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) SaveCommunityPlace(p models.CommunityPlace) error {
	now := time.Now()
	if p.CreatedAt.IsZero() {
		p.CreatedAt = now
	}

	// Pastikan user ada di tabel users
	_, _ = r.db.Exec(`
		INSERT INTO users (id, phone_number, full_name, role, created_at)
		VALUES ($1, '628120000000', 'Kontributor Komunitas', 'tourist', NOW())
		ON CONFLICT (id) DO NOTHING;
	`, p.UserID)

	_, err := r.db.Exec(`
		INSERT INTO community_places (
			id, user_id, name, category, city_regency, description,
			latitude, longitude, tips_menjaga, is_sensitive, status, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name, description = EXCLUDED.description;
	`, p.ID, p.UserID, p.Name, p.Category, p.CityRegency, p.Description,
		p.Latitude, p.Longitude, p.TipsMenjaga, p.IsSensitive, p.Status, p.CreatedAt)

	return err
}

func (r *postgresRepository) GetCommunityPlaces() []models.CommunityPlace {
	query := `
		SELECT id, user_id, name, category, city_regency, COALESCE(description, ''),
		       latitude, longitude, tips_menjaga, is_sensitive, status, created_at
		FROM community_places
		ORDER BY created_at DESC;
	`
	rows, err := r.db.Query(query)
	if err != nil {
		return []models.CommunityPlace{}
	}
	defer rows.Close()

	var results []models.CommunityPlace
	for rows.Next() {
		var p models.CommunityPlace
		if err := rows.Scan(
			&p.ID, &p.UserID, &p.Name, &p.Category, &p.CityRegency, &p.Description,
			&p.Latitude, &p.Longitude, &p.TipsMenjaga, &p.IsSensitive, &p.Status, &p.CreatedAt,
		); err == nil {
			results = append(results, p)
		}
	}
	return results
}

func (r *postgresRepository) SaveSharedTrip(trip models.SharedTrip) error {
	now := time.Now()
	if trip.CreatedAt.IsZero() {
		trip.CreatedAt = now
	}

	// Pastikan user ada di tabel users
	_, _ = r.db.Exec(`
		INSERT INTO users (id, phone_number, full_name, role, created_at)
		VALUES ($1, '628120000000', 'Inisiator Tebengan', 'tourist', NOW())
		ON CONFLICT (id) DO NOTHING;
	`, trip.UserID)

	_, err := r.db.Exec(`
		INSERT INTO shared_trips (
			id, user_id, title, destination_route, departure_date,
			available_seats, cost_per_person, contact_wa, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (id) DO NOTHING;
	`, trip.ID, trip.UserID, trip.Title, trip.DestinationRoute, trip.DepartureDate,
		trip.AvailableSeats, trip.CostPerPerson, trip.ContactWA, trip.CreatedAt)

	return err
}

func (r *postgresRepository) GetSharedTrips() []models.SharedTrip {
	query := `
		SELECT id, user_id, title, destination_route, departure_date,
		       available_seats, cost_per_person, contact_wa, created_at
		FROM shared_trips
		ORDER BY departure_date ASC;
	`
	rows, err := r.db.Query(query)
	if err != nil {
		return []models.SharedTrip{}
	}
	defer rows.Close()

	var results []models.SharedTrip
	for rows.Next() {
		var t models.SharedTrip
		if err := rows.Scan(
			&t.ID, &t.UserID, &t.Title, &t.DestinationRoute, &t.DepartureDate,
			&t.AvailableSeats, &t.CostPerPerson, &t.ContactWA, &t.CreatedAt,
		); err == nil {
			results = append(results, t)
		}
	}
	return results
}
