package partner

import (
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db *sql.DB
}

// NewPostgresRepository membuat instance repository berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) FindAll(category string, spicyLevel *int, nagari string) ([]models.PartnerNagari, error) {
	query := `
		SELECT id, name, category, whatsapp, spicy_level, is_verified, standard_fee, nagari_name
		FROM partners
		WHERE 1=1
	`
	var args []interface{}
	argIdx := 1

	if strings.TrimSpace(category) != "" {
		query += fmt.Sprintf(" AND LOWER(category) LIKE LOWER($%d)", argIdx)
		args = append(args, "%"+strings.TrimSpace(category)+"%")
		argIdx++
	}

	if spicyLevel != nil && *spicyLevel >= 0 {
		query += fmt.Sprintf(" AND spicy_level = $%d", argIdx)
		args = append(args, *spicyLevel)
		argIdx++
	}

	if strings.TrimSpace(nagari) != "" {
		query += fmt.Sprintf(" AND LOWER(nagari_name) LIKE LOWER($%d)", argIdx)
		args = append(args, "%"+strings.TrimSpace(nagari)+"%")
		argIdx++
	}

	query += " ORDER BY name ASC;"

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.PartnerNagari
	for rows.Next() {
		var p models.PartnerNagari
		if err := rows.Scan(
			&p.ID, &p.Name, &p.Category, &p.WhatsApp, &p.SpicyLevel, &p.IsVerified, &p.StandardFee, &p.NagariName,
		); err == nil {
			results = append(results, p)
		}
	}
	return results, nil
}

func (r *postgresRepository) FindByID(id string) (*models.PartnerNagari, error) {
	query := `
		SELECT id, name, category, whatsapp, spicy_level, is_verified, standard_fee, nagari_name
		FROM partners
		WHERE id = $1;
	`
	var p models.PartnerNagari
	err := r.db.QueryRow(query, id).Scan(
		&p.ID, &p.Name, &p.Category, &p.WhatsApp, &p.SpicyLevel, &p.IsVerified, &p.StandardFee, &p.NagariName,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New("mitra tidak ditemukan")
		}
		return nil, err
	}
	return &p, nil
}
