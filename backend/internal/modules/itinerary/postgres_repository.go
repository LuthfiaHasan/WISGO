package itinerary

import (
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db *sql.DB
}

// NewPostgresRepository membuat instance repository berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) FindByUserID(userID string) ([]models.Itinerary, error) {
	query := `
		SELECT id, user_id, title, start_date::text, end_date::text, total_days, created_at, updated_at
		FROM itineraries
		WHERE user_id = $1
		ORDER BY created_at DESC;
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return []models.Itinerary{}, err
	}
	defer rows.Close()

	var results []models.Itinerary
	for rows.Next() {
		var it models.Itinerary
		if err := rows.Scan(
			&it.ID, &it.UserID, &it.Title, &it.StartDate, &it.EndDate, &it.TotalDays, &it.CreatedAt, &it.UpdatedAt,
		); err == nil {
			r.populateItems(&it)
			results = append(results, it)
		}
	}
	return results, nil
}

func (r *postgresRepository) FindByID(id string) (*models.Itinerary, error) {
	query := `
		SELECT id, user_id, title, start_date::text, end_date::text, total_days, created_at, updated_at
		FROM itineraries
		WHERE id = $1;
	`
	var it models.Itinerary
	err := r.db.QueryRow(query, id).Scan(
		&it.ID, &it.UserID, &it.Title, &it.StartDate, &it.EndDate, &it.TotalDays, &it.CreatedAt, &it.UpdatedAt,
	)
	if err != nil {
		return nil, errors.New("Itinerary tidak ditemukan")
	}
	r.populateItems(&it)
	return &it, nil
}

func (r *postgresRepository) Save(it models.Itinerary) error {
	now := time.Now()
	if it.CreatedAt.IsZero() {
		it.CreatedAt = now
	}
	it.UpdatedAt = now

	// 1. Simpan header itinerary
	_, err := r.db.Exec(`
		INSERT INTO itineraries (
			id, user_id, title, start_date, end_date, total_days, created_at, updated_at
		) VALUES ($1, $2, $3, $4::date, $5::date, $6, $7, $8)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title,
			start_date = EXCLUDED.start_date,
			end_date = EXCLUDED.end_date,
			total_days = EXCLUDED.total_days,
			updated_at = NOW();
	`, it.ID, it.UserID, it.Title, it.StartDate, it.EndDate, it.TotalDays, it.CreatedAt, it.UpdatedAt)
	if err != nil {
		return err
	}

	// 2. Simpan rincian items jika ada
	if len(it.Items) > 0 {
		_, _ = r.db.Exec(`DELETE FROM itinerary_items WHERE itinerary_id = $1;`, it.ID)
		for i, item := range it.Items {
			if item.ID == "" {
				item.ID = fmt.Sprintf("item-%s-%d", it.ID, i+1)
			}
			_, _ = r.db.Exec(`
				INSERT INTO itinerary_items (
					id, itinerary_id, day_number, time_slot, destination_id, notes, traffic_alert, created_at
				) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
				ON CONFLICT DO NOTHING;
			`, item.ID, it.ID, item.DayNumber, item.TimeSlot, item.DestinationID, item.Notes, item.TrafficAlert)
		}
	}

	return nil
}

func (r *postgresRepository) populateItems(it *models.Itinerary) {
	rows, err := r.db.Query(`
		SELECT id, itinerary_id, day_number, time_slot, destination_id, COALESCE(notes, ''), COALESCE(traffic_alert, '')
		FROM itinerary_items
		WHERE itinerary_id = $1
		ORDER BY day_number ASC, time_slot ASC;
	`, it.ID)
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var item models.ItineraryItem
		if err := rows.Scan(
			&item.ID, &item.ItineraryID, &item.DayNumber, &item.TimeSlot, &item.DestinationID, &item.Notes, &item.TrafficAlert,
		); err == nil {
			it.Items = append(it.Items, item)
		}
	}
}
