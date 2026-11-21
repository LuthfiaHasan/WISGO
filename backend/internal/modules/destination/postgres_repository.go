package destination

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db *sql.DB
}

// NewPostgresRepository membuat instance repository destinasi berbasis PostgreSQL + PostGIS (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) FindAllWithSpatial(params SpatialFilterParams) []models.Destination {
	query := `
		SELECT 
			d.id, d.slug, d.name, d.category, d.city_regency, d.description,
			d.latitude, d.longitude, d.elevation_m, d.cover_image, d.crowd_level,
			d.distance_km, d.travel_time_min, d.estimated_cost, d.is_hidden_gem,
			d.qr_placard_code, d.opening_hours, d.created_at, d.updated_at
		FROM destinations d
		WHERE 1=1
	`
	var args []interface{}
	argIdx := 1

	if strings.TrimSpace(params.Category) != "" {
		query += fmt.Sprintf(" AND LOWER(d.category) LIKE LOWER($%d)", argIdx)
		args = append(args, "%"+strings.TrimSpace(params.Category)+"%")
		argIdx++
	}

	if strings.TrimSpace(params.CityRegency) != "" {
		query += fmt.Sprintf(" AND LOWER(d.city_regency) LIKE LOWER($%d)", argIdx)
		args = append(args, "%"+strings.TrimSpace(params.CityRegency)+"%")
		argIdx++
	}

	if strings.TrimSpace(params.CrowdLevel) != "" {
		query += fmt.Sprintf(" AND LOWER(d.crowd_level) = LOWER($%d)", argIdx)
		args = append(args, strings.TrimSpace(params.CrowdLevel))
		argIdx++
	}

	if strings.TrimSpace(params.SearchQuery) != "" {
		q := "%" + strings.ToLower(strings.TrimSpace(params.SearchQuery)) + "%"
		query += fmt.Sprintf(" AND (LOWER(d.name) LIKE $%d OR LOWER(d.city_regency) LIKE $%d OR LOWER(d.description) LIKE $%d)", argIdx, argIdx, argIdx)
		args = append(args, q)
		argIdx++
	}

	query += " ORDER BY d.id ASC;"

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil
	}
	defer rows.Close()

	var results []models.Destination
	for rows.Next() {
		var d models.Destination
		if err := rows.Scan(
			&d.ID, &d.Slug, &d.Name, &d.Category, &d.CityRegency, &d.Description,
			&d.Latitude, &d.Longitude, &d.ElevationM, &d.CoverImage, &d.CrowdLevel,
			&d.DistanceKm, &d.TravelTimeMin, &d.EstimatedCost, &d.IsHiddenGem,
			&d.QRPlacardCode, &d.OpeningHours, &d.CreatedAt, &d.UpdatedAt,
		); err == nil {
			r.populateRelations(&d)
			results = append(results, d)
		}
	}
	return results
}

func (r *postgresRepository) FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error) {
	key := strings.ToLower(strings.TrimSpace(idOrSlugOrQR))
	query := `
		SELECT 
			id, slug, name, category, city_regency, description,
			latitude, longitude, elevation_m, cover_image, crowd_level,
			distance_km, travel_time_min, estimated_cost, is_hidden_gem,
			qr_placard_code, opening_hours, created_at, updated_at
		FROM destinations
		WHERE LOWER(id) = $1 OR LOWER(slug) = $1 OR LOWER(qr_placard_code) = $1
		LIMIT 1;
	`
	var d models.Destination
	err := r.db.QueryRow(query, key).Scan(
		&d.ID, &d.Slug, &d.Name, &d.Category, &d.CityRegency, &d.Description,
		&d.Latitude, &d.Longitude, &d.ElevationM, &d.CoverImage, &d.CrowdLevel,
		&d.DistanceKm, &d.TravelTimeMin, &d.EstimatedCost, &d.IsHiddenGem,
		&d.QRPlacardCode, &d.OpeningHours, &d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("Destinasi '%s' tidak ditemukan", idOrSlugOrQR)
	}

	if hasUserGPS {
		d.DistanceKm = CalculateSpatialDistanceKm(userLat, userLng, d.Latitude, d.Longitude)
		d.TravelTimeMin = EstimateSumbarTravelMinutes(d.DistanceKm)
	}

	r.populateRelations(&d)
	return &d, nil
}

func (r *postgresRepository) CreateCMS(input models.Destination) models.Destination {
	now := time.Now()
	if input.ID == "" {
		input.ID = fmt.Sprintf("dest-%d", time.Now().UnixNano())
	}
	if input.Slug == "" {
		input.Slug = strings.ToLower(strings.ReplaceAll(input.Name, " ", "-"))
	}
	input.CreatedAt = now
	input.UpdatedAt = now

	_, _ = r.db.Exec(`
		INSERT INTO destinations (
			id, slug, name, category, city_regency, description,
			latitude, longitude, elevation_m, cover_image, crowd_level,
			distance_km, travel_time_min, estimated_cost, is_hidden_gem,
			qr_placard_code, opening_hours, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11,
			$12, $13, $14, $15,
			$16, $17, $18, $19
		) ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name, category = EXCLUDED.category, updated_at = NOW();
	`, input.ID, input.Slug, input.Name, input.Category, input.CityRegency, input.Description,
		input.Latitude, input.Longitude, input.ElevationM, input.CoverImage, input.CrowdLevel,
		input.DistanceKm, input.TravelTimeMin, input.EstimatedCost, input.IsHiddenGem,
		input.QRPlacardCode, input.OpeningHours, input.CreatedAt, input.UpdatedAt)

	return input
}

func (r *postgresRepository) UpdateCMS(id string, payload models.Destination) (*models.Destination, error) {
	d, err := r.FindByID(id, false, 0, 0)
	if err != nil {
		return nil, err
	}

	if payload.Name != "" {
		d.Name = payload.Name
	}
	if payload.Category != "" {
		d.Category = payload.Category
	}
	if payload.CityRegency != "" {
		d.CityRegency = payload.CityRegency
	}
	if payload.Description != "" {
		d.Description = payload.Description
	}
	if payload.CrowdLevel != "" {
		d.CrowdLevel = payload.CrowdLevel
	}
	d.UpdatedAt = time.Now()

	_, err = r.db.Exec(`
		UPDATE destinations
		SET name = $1, category = $2, city_regency = $3, description = $4, crowd_level = $5, updated_at = $6
		WHERE id = $7;
	`, d.Name, d.Category, d.CityRegency, d.Description, d.CrowdLevel, d.UpdatedAt, d.ID)
	if err != nil {
		return nil, err
	}

	return d, nil
}

func (r *postgresRepository) DeleteCMS(id string) (string, error) {
	d, err := r.FindByID(id, false, 0, 0)
	if err != nil {
		return "", err
	}

	_, err = r.db.Exec(`DELETE FROM destinations WHERE id = $1;`, d.ID)
	if err != nil {
		return "", err
	}
	return d.ID, nil
}

func (r *postgresRepository) SyncTariffsCMS(id string, tariffs []models.OfficialTariff) (*models.Destination, error) {
	d, err := r.FindByID(id, false, 0, 0)
	if err != nil {
		return nil, err
	}

	_, _ = r.db.Exec(`DELETE FROM official_tariffs WHERE destination_id = $1;`, d.ID)
	for _, trf := range tariffs {
		if trf.ID == "" {
			trf.ID = fmt.Sprintf("trf-%d", time.Now().UnixNano())
		}
		_, _ = r.db.Exec(`
			INSERT INTO official_tariffs (id, destination_id, item_name, category, price, unit, regulation_ref)
			VALUES ($1, $2, $3, $4, $5, $6, $7);
		`, trf.ID, d.ID, trf.ItemName, trf.Category, trf.Price, trf.Unit, trf.RegulationRef)
	}

	d.Tariffs = tariffs
	return d, nil
}

func (r *postgresRepository) populateRelations(d *models.Destination) {
	// 1. Indikator Medan (Mencoba tabel indikator_medan sesuai ERD Revisi #3, fallback medan_indicators)
	var m models.MedanIndicator
	err := r.db.QueryRow(`
		SELECT id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need
		FROM indikator_medan WHERE destination_id = $1;
	`, d.ID).Scan(
		&m.ID, &m.DestinationID, &m.VehicleAccess, &m.TrekkingLevel, &m.CellularSignal, &m.Facilities, &m.GuideNeed,
	)
	if err != nil {
		_ = r.db.QueryRow(`
			SELECT id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need, pokdarwis_name
			FROM medan_indicators WHERE destination_id = $1;
		`, d.ID).Scan(
			&m.ID, &m.DestinationID, &m.VehicleAccess, &m.TrekkingLevel, &m.CellularSignal, &m.Facilities, &m.GuideNeed, &m.PokdarwisName,
		)
	}
	if m.ID != "" {
		d.MedanIndicator = &m
	}

	// 2. Aturan Destinasi / Tips (Mencoba tabel aturan_destinasi sesuai ERD Revisi #4, fallback local_tips)
	tipRows, err := r.db.Query(`
		SELECT id, destination_id, category_id, title, aturan
		FROM aturan_destinasi WHERE destination_id = $1;
	`, d.ID)
	if err != nil {
		// Fallback jika skema aturan_destinasi menggunakan nama kolom content
		tipRows, err = r.db.Query(`
			SELECT id, destination_id, category_id, title, content
			FROM aturan_destinasi WHERE destination_id = $1;
		`, d.ID)
	}
	if err == nil {
		defer tipRows.Close()
		for tipRows.Next() {
			var t models.LocalTip
			var catID sql.NullString
			if err := tipRows.Scan(&t.ID, &t.DestinationID, &catID, &t.Title, &t.Aturan); err == nil {
				if catID.Valid {
					t.CategoryID = catID.String
					t.Category = catID.String
				}
				t.Content = t.Aturan
				t.IsImportant = true
				d.Tips = append(d.Tips, t)
			}
		}
	} else {
		legacyRows, err2 := r.db.Query(`
			SELECT id, destination_id, title, category, content, is_important
			FROM local_tips WHERE destination_id = $1;
		`, d.ID)
		if err2 == nil {
			defer legacyRows.Close()
			for legacyRows.Next() {
				var t models.LocalTip
				if err := legacyRows.Scan(&t.ID, &t.DestinationID, &t.Title, &t.Category, &t.Content, &t.IsImportant); err == nil {
					t.Aturan = t.Content
					d.Tips = append(d.Tips, t)
				}
			}
		}
	}

	// 3. Official Tariffs (+ category_id)
	trfRows, err := r.db.Query(`
		SELECT id, destination_id, category_id, item_name, price, unit, regulation_ref
		FROM official_tariffs WHERE destination_id = $1;
	`, d.ID)
	if err == nil {
		defer trfRows.Close()
		for trfRows.Next() {
			var trf models.OfficialTariff
			var catID sql.NullString
			if err := trfRows.Scan(&trf.ID, &trf.DestinationID, &catID, &trf.ItemName, &trf.Price, &trf.Unit, &trf.RegulationRef); err == nil {
				if catID.Valid {
					trf.CategoryID = catID.String
					trf.Category = catID.String
				}
				d.Tariffs = append(d.Tariffs, trf)
			}
		}
	} else {
		legacyTrf, err2 := r.db.Query(`
			SELECT id, destination_id, item_name, category, price, unit, regulation_ref
			FROM official_tariffs WHERE destination_id = $1;
		`, d.ID)
		if err2 == nil {
			defer legacyTrf.Close()
			for legacyTrf.Next() {
				var trf models.OfficialTariff
				if err := legacyTrf.Scan(&trf.ID, &trf.DestinationID, &trf.ItemName, &trf.Category, &trf.Price, &trf.Unit, &trf.RegulationRef); err == nil {
					d.Tariffs = append(d.Tariffs, trf)
				}
			}
		}
	}
}

func (r *postgresRepository) FindPending() []models.Destination {
	return r.FindAllWithSpatial(SpatialFilterParams{
		IncludePending:     true,
		VerificationStatus: "pending",
	})
}

func (r *postgresRepository) VerifyDestination(id string, status string) (*models.Destination, error) {
	d, err := r.FindByID(id, false, 0, 0)
	if err != nil {
		return nil, err
	}

	d.VerificationStatus = status
	d.UpdatedAt = time.Now()
	_, _ = r.db.Exec(`UPDATE destinations SET updated_at = NOW() WHERE id = $1;`, d.ID)

	return d, nil
}
