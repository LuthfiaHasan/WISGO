package community

import (
	"database/sql"
	"errors"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db *sql.DB
}

// NewPostgresRepository membuat instance repository komunitas berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	if db != nil {
		_, _ = db.Exec(`ALTER TABLE open_trips ADD COLUMN IF NOT EXISTS destination_id VARCHAR(100) DEFAULT '';`)
		_, _ = db.Exec(`ALTER TABLE open_trips ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT '';`)
	}
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

	categoryID := "cat_dst_alam"
	if p.Category != "" {
		if len(p.Category) > 4 && p.Category[:4] == "cat_" {
			categoryID = p.Category
		} else {
			switch p.Category {
			case "Budaya", "budaya":
				categoryID = "cat_dst_budaya"
			case "Kuliner", "kuliner":
				categoryID = "cat_dst_kuliner"
			case "Bahari", "bahari":
				categoryID = "cat_dst_bahari"
			default:
				categoryID = "cat_dst_alam"
			}
		}
	}

	// Migrated to v2: new_tour
	_, err := r.db.Exec(`
		INSERT INTO new_tour (
			id, user_id, name, category_id, city_regency, description,
			latitude, longitude, tips_menjaga, is_sensitive, status, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name, description = EXCLUDED.description;
	`, p.ID, p.UserID, p.Name, categoryID, p.CityRegency, p.Description,
		p.Latitude, p.Longitude, p.TipsMenjaga, p.IsSensitive, p.Status, p.CreatedAt)

	return err
}

func (r *postgresRepository) GetCommunityPlaces() []models.CommunityPlace {
	// Migrated to v2: new_tour with categories join
	query := `
		SELECT n.id, n.user_id, n.name, COALESCE(c.name, 'Alam & Geopark'), n.city_regency, COALESCE(n.description, ''),
		       n.latitude, n.longitude, n.tips_menjaga, n.is_sensitive, n.status, n.created_at
		FROM new_tour n
		LEFT JOIN categories c ON n.category_id = c.id
		ORDER BY n.created_at DESC;
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

	// Migrated to v2: open_trips
	_, err := r.db.Exec(`
		INSERT INTO open_trips (
			id, user_id, title, destination_id, category, destination_route, departure_date,
			available_seats, cost_per_person, contact_wa, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		ON CONFLICT (id) DO NOTHING;
	`, trip.ID, trip.UserID, trip.Title, trip.DestinationID, trip.Category, trip.DestinationRoute, trip.DepartureDate,
		trip.AvailableSeats, trip.CostPerPerson, trip.ContactWA, trip.CreatedAt)

	return err
}

func (r *postgresRepository) GetSharedTrips() []models.SharedTrip {
	// Migrated to v2: open_trips
	query := `
		SELECT id, user_id, title, COALESCE(destination_id, ''), COALESCE(category, ''), destination_route, departure_date,
		       available_seats, cost_per_person, contact_wa, created_at
		FROM open_trips
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
			&t.ID, &t.UserID, &t.Title, &t.DestinationID, &t.Category, &t.DestinationRoute, &t.DepartureDate,
			&t.AvailableSeats, &t.CostPerPerson, &t.ContactWA, &t.CreatedAt,
		); err == nil {
			results = append(results, t)
		}
	}
	return results
}

func (r *postgresRepository) JoinSharedTrip(id, userID string) (*models.SharedTrip, error) {
	var ownerID string
	var seats int
	err := r.db.QueryRow(`
		SELECT user_id, available_seats
		FROM open_trips
		WHERE id = $1;
	`, id).Scan(&ownerID, &seats)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrSharedTripNotFound
		}
		return nil, err
	}

	if ownerID == userID {
		return nil, ErrHostCannotJoinOwnTrip
	}
	if seats <= 0 {
		return nil, ErrSharedTripFull
	}

	var updated models.SharedTrip
	err = r.db.QueryRow(`
		UPDATE open_trips
		SET available_seats = available_seats - 1
		WHERE id = $1 AND available_seats > 0
		RETURNING id, user_id, title, COALESCE(destination_id, ''), COALESCE(category, ''), destination_route, departure_date,
		          available_seats, cost_per_person, contact_wa, created_at;
	`, id).Scan(
		&updated.ID, &updated.UserID, &updated.Title, &updated.DestinationID, &updated.Category,
		&updated.DestinationRoute, &updated.DepartureDate, &updated.AvailableSeats,
		&updated.CostPerPerson, &updated.ContactWA, &updated.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrSharedTripFull
		}
		return nil, err
	}

	return &updated, nil
}

func (r *postgresRepository) DeleteSharedTrip(id, userID string) error {
	var ownerID string
	err := r.db.QueryRow(`
		SELECT user_id
		FROM open_trips
		WHERE id = $1;
	`, id).Scan(&ownerID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrSharedTripNotFound
		}
		return err
	}

	if ownerID != userID {
		return ErrUnauthorizedDelete
	}

	res, err := r.db.Exec(`
		DELETE FROM open_trips
		WHERE id = $1 AND user_id = $2;
	`, id, userID)
	if err != nil {
		return err
	}
	if rows, err := res.RowsAffected(); err == nil && rows == 0 {
		return ErrSharedTripNotFound
	}
	return nil
}
