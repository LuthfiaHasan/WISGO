package destination

import (
	"database/sql"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db       *sql.DB
	fallback Repository
}

// NewPostgresRepository membuat instance repository destinasi berbasis PostgreSQL + PostGIS (Supabase)
// Dilengkapi fallback aman dan sinkronisasi penuh category_id, indikator_medan, aturan_destinasi, & scenes_360
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{
		db:       db,
		fallback: NewRepository(),
	}
}

func mapCategoryNameToID(categoryName, destName string, isHiddenGem bool) string {
	c := strings.ToLower(strings.TrimSpace(categoryName))
	n := strings.ToLower(strings.TrimSpace(destName))
	switch {
	case strings.Contains(c, "religi") || strings.Contains(n, "masjid") || strings.Contains(n, "surau"):
		return "cat-religi"
	case strings.Contains(c, "kuliner") || strings.Contains(n, "kuliner") || strings.Contains(n, "kapau") || strings.Contains(n, "sate") || strings.Contains(n, "rendang"):
		return "cat-kuliner"
	case isHiddenGem || strings.Contains(c, "hidden"):
		return "cat-hidden-gem"
	case strings.Contains(c, "budaya") || strings.Contains(c, "sejarah") || strings.Contains(c, "nagari") ||
		strings.Contains(n, "istano") || strings.Contains(n, "jam gadang") || strings.Contains(n, "pariangan") ||
		strings.Contains(n, "sawahlunto") || strings.Contains(n, "pandai sikek") || strings.Contains(n, "rumah gadang"):
		return "cat-budaya-nagari"
	default:
		return "cat-alam-geopark"
	}
}

func mapCategoryIDToName(catID string) string {
	switch strings.ToLower(strings.TrimSpace(catID)) {
	case "cat-budaya-nagari", "cat_dst_budaya", "cat_dst_sejarah":
		return "Budaya & Nagari"
	case "cat-hidden-gem":
		return "Hidden Gem"
	case "cat-religi":
		return "Religi"
	case "cat-kuliner", "cat_dst_kuliner":
		return "Kuliner"
	default:
		return "Alam & Geopark"
	}
}

func (r *postgresRepository) FindAllWithSpatial(params SpatialFilterParams) []models.Destination {
	query := `
		SELECT 
			d.id, d.slug, d.name, COALESCE(d.category_id, ''), d.category, d.city_regency, d.description,
			d.latitude, d.longitude, d.elevation_m, d.cover_image, d.crowd_level,
			d.distance_km, d.travel_time_min, d.estimated_cost, d.is_hidden_gem,
			COALESCE(d.verification_status, 'verified'),
			d.qr_placard_code, d.opening_hours, d.created_at, d.updated_at
		FROM destinations d
		WHERE 1=1
	`
	var args []interface{}
	argIdx := 1

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
		// Fallback ke query tanpa kolom baru jika migrasi 000005 belum dijalankan
		return r.fallback.FindAllWithSpatial(params)
	}
	defer rows.Close()

	qCatID := strings.ToLower(strings.TrimSpace(params.CategoryID))
	qCat := strings.ToLower(strings.TrimSpace(params.Category))
	qSignal := strings.ToLower(strings.TrimSpace(params.Signal))
	qVerStatus := strings.ToLower(strings.TrimSpace(params.VerificationStatus))

	var results []models.Destination
	for rows.Next() {
		var d models.Destination
		if err := rows.Scan(
			&d.ID, &d.Slug, &d.Name, &d.CategoryID, &d.Category, &d.CityRegency, &d.Description,
			&d.Latitude, &d.Longitude, &d.ElevationM, &d.CoverImage, &d.CrowdLevel,
			&d.DistanceKm, &d.TravelTimeMin, &d.EstimatedCost, &d.IsHiddenGem,
			&d.VerificationStatus,
			&d.QRPlacardCode, &d.OpeningHours, &d.CreatedAt, &d.UpdatedAt,
		); err == nil {
			// Normalisasi Auto-Category Mapping ke 5 Master Categories (Poin 6)
			if d.CategoryID == "" || !strings.HasPrefix(d.CategoryID, "cat-") {
				d.CategoryID = mapCategoryNameToID(d.Category, d.Name, d.IsHiddenGem)
			}
			d.Category = mapCategoryIDToName(d.CategoryID)

			if !params.IncludePending && d.VerificationStatus != "" && d.VerificationStatus != "verified" {
				continue
			}
			if qVerStatus != "" && strings.ToLower(d.VerificationStatus) != qVerStatus {
				continue
			}
			if qCatID != "" && strings.ToLower(d.CategoryID) != qCatID {
				continue
			}
			if qCat != "" && !strings.Contains(strings.ToLower(d.Category), qCat) && !strings.Contains(strings.ToLower(d.CategoryID), qCat) {
				continue
			}

			r.populateRelations(&d)

			if qSignal != "" && d.MedanIndicator != nil {
				if !strings.Contains(strings.ToLower(d.MedanIndicator.CellularSignal), qSignal) {
					continue
				}
			}

			if params.HasUserGPS {
				d.DistanceKm = CalculateSpatialDistanceKm(params.UserLat, params.UserLng, d.Latitude, d.Longitude)
				d.TravelTimeMin = EstimateSumbarTravelMinutes(d.DistanceKm)
			}

			results = append(results, d)
		}
	}

	if params.HasUserGPS {
		sort.Slice(results, func(i, j int) bool {
			return results[i].DistanceKm < results[j].DistanceKm
		})
	}

	return results
}

func (r *postgresRepository) FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error) {
	key := strings.ToLower(strings.TrimSpace(idOrSlugOrQR))
	query := `
		SELECT 
			id, slug, name, COALESCE(category_id, ''), category, city_regency, description,
			latitude, longitude, elevation_m, cover_image, crowd_level,
			distance_km, travel_time_min, estimated_cost, is_hidden_gem,
			COALESCE(verification_status, 'verified'),
			qr_placard_code, opening_hours, created_at, updated_at
		FROM destinations
		WHERE LOWER(id) = $1 OR LOWER(slug) = $1 OR LOWER(qr_placard_code) = $1
		LIMIT 1;
	`
	var d models.Destination
	err := r.db.QueryRow(query, key).Scan(
		&d.ID, &d.Slug, &d.Name, &d.CategoryID, &d.Category, &d.CityRegency, &d.Description,
		&d.Latitude, &d.Longitude, &d.ElevationM, &d.CoverImage, &d.CrowdLevel,
		&d.DistanceKm, &d.TravelTimeMin, &d.EstimatedCost, &d.IsHiddenGem,
		&d.VerificationStatus,
		&d.QRPlacardCode, &d.OpeningHours, &d.CreatedAt, &d.UpdatedAt,
	)
	if err != nil {
		return r.fallback.FindByID(idOrSlugOrQR, hasUserGPS, userLat, userLng)
	}

	if d.CategoryID == "" || !strings.HasPrefix(d.CategoryID, "cat-") {
		d.CategoryID = mapCategoryNameToID(d.Category, d.Name, d.IsHiddenGem)
	}
	d.Category = mapCategoryIDToName(d.CategoryID)

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
		input.ID = fmt.Sprintf("dest-%d", time.Now().UnixNano()%1000000)
	}
	if input.Slug == "" {
		input.Slug = strings.ToLower(strings.ReplaceAll(input.Name, " ", "-"))
	}
	if input.CategoryID == "" {
		input.CategoryID = mapCategoryNameToID(input.Category, input.Name, input.IsHiddenGem)
	}
	input.Category = mapCategoryIDToName(input.CategoryID)
	if input.VerificationStatus == "" {
		input.VerificationStatus = "verified"
	}
	if input.QRPlacardCode == "" {
		input.QRPlacardCode = fmt.Sprintf("QR-RANCAK-%s", strings.ToUpper(input.ID))
	}
	if input.OpeningHours == "" {
		input.OpeningHours = "08.00 - 17.30 WIB"
	}
	input.CreatedAt = now
	input.UpdatedAt = now

	_, _ = r.db.Exec(`
		INSERT INTO destinations (
			id, slug, name, category_id, category, city_regency, description,
			latitude, longitude, elevation_m, cover_image, crowd_level,
			distance_km, travel_time_min, estimated_cost, is_hidden_gem,
			verification_status, qr_placard_code, opening_hours, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12,
			$13, $14, $15, $16,
			$17, $18, $19, $20, $21
		) ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name, category_id = EXCLUDED.category_id, category = EXCLUDED.category,
			verification_status = EXCLUDED.verification_status, updated_at = NOW();
	`, input.ID, input.Slug, input.Name, input.CategoryID, input.Category, input.CityRegency, input.Description,
		input.Latitude, input.Longitude, input.ElevationM, input.CoverImage, input.CrowdLevel,
		input.DistanceKm, input.TravelTimeMin, input.EstimatedCost, input.IsHiddenGem,
		input.VerificationStatus, input.QRPlacardCode, input.OpeningHours, input.CreatedAt, input.UpdatedAt)

	// Persist indikator_medan jika disertakan
	if input.MedanIndicator != nil {
		mID := input.MedanIndicator.ID
		if mID == "" {
			mID = fmt.Sprintf("medan-%s", input.ID)
		}
		_, _ = r.db.Exec(`
			INSERT INTO indikator_medan (id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			ON CONFLICT (destination_id) DO UPDATE SET
				vehicle_access = EXCLUDED.vehicle_access,
				trekking_level = EXCLUDED.trekking_level,
				cellular_signal = EXCLUDED.cellular_signal,
				facilities = EXCLUDED.facilities,
				guide_need = EXCLUDED.guide_need;
		`, mID, input.ID, input.MedanIndicator.VehicleAccess, input.MedanIndicator.TrekkingLevel,
			input.MedanIndicator.CellularSignal, input.MedanIndicator.Facilities, input.MedanIndicator.GuideNeed)
	}

	// Persist aturan_destinasi / tips jika disertakan
	for idx, tip := range input.Tips {
		tID := tip.ID
		if tID == "" {
			tID = fmt.Sprintf("tip-%s-%d", input.ID, idx+1)
		}
		content := tip.Aturan
		if content == "" {
			content = tip.Content
		}
		_, _ = r.db.Exec(`
			INSERT INTO aturan_destinasi (id, destination_id, category_id, title, content)
			VALUES ($1, $2, 'cat_rul_alam', $3, $4)
			ON CONFLICT (id) DO NOTHING;
		`, tID, input.ID, tip.Title, content)
	}

	_ = r.fallback.CreateCMS(input)
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
	if payload.CategoryID != "" {
		d.CategoryID = payload.CategoryID
		d.Category = mapCategoryIDToName(payload.CategoryID)
	} else if payload.Category != "" {
		d.Category = payload.Category
		d.CategoryID = mapCategoryNameToID(payload.Category, d.Name, d.IsHiddenGem)
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
	if payload.CoverImage != "" {
		d.CoverImage = payload.CoverImage
	}
	if payload.Latitude != 0 {
		d.Latitude = payload.Latitude
	}
	if payload.Longitude != 0 {
		d.Longitude = payload.Longitude
	}
	if payload.EstimatedCost > 0 {
		d.EstimatedCost = payload.EstimatedCost
	}
	if payload.OpeningHours != "" {
		d.OpeningHours = payload.OpeningHours
	}
	d.UpdatedAt = time.Now()

	_, _ = r.db.Exec(`
		UPDATE destinations
		SET name = $1, category_id = $2, category = $3, city_regency = $4, description = $5,
		    crowd_level = $6, cover_image = $7, latitude = $8, longitude = $9,
		    estimated_cost = $10, opening_hours = $11, updated_at = $12
		WHERE id = $13;
	`, d.Name, d.CategoryID, d.Category, d.CityRegency, d.Description,
		d.CrowdLevel, d.CoverImage, d.Latitude, d.Longitude,
		d.EstimatedCost, d.OpeningHours, d.UpdatedAt, d.ID)

	if payload.MedanIndicator != nil {
		mID := payload.MedanIndicator.ID
		if mID == "" {
			mID = fmt.Sprintf("med-%s", d.ID)
		}
		sig := payload.MedanIndicator.CellularSignal
		if sig == "" {
			sig = "4G Kuat"
		}
		_, _ = r.db.Exec(`
			INSERT INTO indikator_medan (id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			ON CONFLICT (destination_id) DO UPDATE SET
				vehicle_access = EXCLUDED.vehicle_access,
				trekking_level = EXCLUDED.trekking_level,
				cellular_signal = EXCLUDED.cellular_signal,
				facilities = EXCLUDED.facilities,
				guide_need = EXCLUDED.guide_need;
		`, mID, d.ID, payload.MedanIndicator.VehicleAccess, payload.MedanIndicator.TrekkingLevel,
			sig, payload.MedanIndicator.Facilities, payload.MedanIndicator.GuideNeed)
		d.MedanIndicator = payload.MedanIndicator
	}

	if len(payload.Tips) > 0 {
		_, _ = r.db.Exec(`DELETE FROM aturan_destinasi WHERE destination_id = $1;`, d.ID)
		for idx, tip := range payload.Tips {
			tID := tip.ID
			if tID == "" {
				tID = fmt.Sprintf("art-%s-%d", d.ID, idx+1)
			}
			content := tip.Content
			if content == "" {
				content = tip.Aturan
			}
			catID := tip.CategoryID
			if catID == "" {
				catID = "cat_rul_alam"
			}
			_, _ = r.db.Exec(`
				INSERT INTO aturan_destinasi (id, destination_id, category_id, title, content)
				VALUES ($1, $2, $3, $4, $5)
				ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content;
			`, tID, d.ID, catID, tip.Title, content)
		}
		d.Tips = payload.Tips
	}

	_, _ = r.fallback.UpdateCMS(id, payload)
	return d, nil
}

func (r *postgresRepository) DeleteCMS(id string) (string, error) {
	d, err := r.FindByID(id, false, 0, 0)
	if err != nil {
		return "", err
	}

	_, _ = r.db.Exec(`DELETE FROM destinations WHERE id = $1;`, d.ID)
	_, _ = r.fallback.DeleteCMS(id)
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
	_, _ = r.fallback.SyncTariffsCMS(id, tariffs)
	return d, nil
}

func (r *postgresRepository) populateRelations(d *models.Destination) {
	// 1. Indikator Medan (tabel indikator_medan sesuai DBML v2)
	var m models.MedanIndicator
	err := r.db.QueryRow(`
		SELECT id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need
		FROM indikator_medan WHERE destination_id = $1;
	`, d.ID).Scan(
		&m.ID, &m.DestinationID, &m.VehicleAccess, &m.TrekkingLevel, &m.CellularSignal, &m.Facilities, &m.GuideNeed,
	)
	if err == nil && m.ID != "" {
		d.MedanIndicator = &m
	}

	// 2. Aturan Destinasi / Tips (tabel aturan_destinasi sesuai DBML v2)
	tipRows, err := r.db.Query(`
		SELECT id, destination_id, category_id, title, content
		FROM aturan_destinasi WHERE destination_id = $1;
	`, d.ID)
	if err != nil {
		tipRows, err = r.db.Query(`
			SELECT id, destination_id, category_id, title, aturan
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
	}

	// 3. Official Tariffs
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
	}

	// 4. Panorama Scenes 360° (Poin 9)
	scRows, err := r.db.Query(`
		SELECT id, destination_id, title, scene_type, panorama_url, upload_format, spatial_audio_url, initial_pitch, initial_yaw, is_default_scene
		FROM panorama_scenes WHERE destination_id = $1 ORDER BY is_default_scene DESC, id ASC;
	`, d.ID)
	if err == nil {
		defer scRows.Close()
		for scRows.Next() {
			var sc models.Scene360
			if err := scRows.Scan(
				&sc.ID, &sc.DestinationID, &sc.Title, &sc.Type, &sc.PanoramaURL,
				&sc.UploadFormat, &sc.SpatialAudioURL, &sc.InitialPitch, &sc.InitialYaw, &sc.IsDefaultScene,
			); err == nil {
				d.Scenes360 = append(d.Scenes360, sc)
			}
		}
	}

	// 5. Informasi Cuaca Real-Time WeatherAPI (Poin 7)
	if d.Weather == nil {
		d.Weather = GetRealtimeWeather(d.Latitude, d.Longitude, d.CityRegency)
		if d.Weather != nil {
			d.WeatherStatus = d.Weather.WeatherStatus
		}
	}
}

func (r *postgresRepository) GetCategories() []models.Category {
	categories := models.GetDefaultCategories()
	allDests := r.FindAllWithSpatial(SpatialFilterParams{})
	if len(allDests) > 0 {
		counts := make(map[string]int)
		for _, d := range allDests {
			counts[d.CategoryID]++
		}
		for i := range categories {
			categories[i].DestinationCount = counts[categories[i].ID]
		}
	}
	return categories
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
	_, _ = r.db.Exec(`UPDATE destinations SET verification_status = $1, updated_at = NOW() WHERE id = $2;`, status, d.ID)
	_, _ = r.fallback.VerifyDestination(id, status)

	return d, nil
}

func (r *postgresRepository) SaveOfflineBundle(destID, version string, payloadJSON []byte) {
	if len(payloadJSON) == 0 {
		return
	}
	bundleID := fmt.Sprintf("bundle-%s", destID)
	sizeKB := len(payloadJSON) / 1024
	if sizeKB <= 0 {
		sizeKB = 12
	}
	_, err := r.db.Exec(`
		INSERT INTO offline_bundles (id, destination_id, bundle_version, file_size_kb, map_tiles_url, compressed_payload, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6::jsonb, NOW())
		ON CONFLICT (destination_id) DO UPDATE SET
			bundle_version = EXCLUDED.bundle_version,
			file_size_kb = EXCLUDED.file_size_kb,
			compressed_payload = EXCLUDED.compressed_payload,
			updated_at = NOW();
	`, bundleID, destID, version, sizeKB, fmt.Sprintf("https://cdn.wisgo.sumbarprov.go.id/tiles/%s.mbtiles", destID), string(payloadJSON))
	if err != nil {
		_, _ = r.db.Exec(`
			INSERT INTO offline_bundles (id, destination_id, bundle_version, map_tiles_url, compressed_package)
			VALUES ($1, $2, $3, $4, $5::jsonb)
			ON CONFLICT (destination_id) DO UPDATE SET
				bundle_version = EXCLUDED.bundle_version,
				compressed_package = EXCLUDED.compressed_package;
		`, bundleID, destID, version, fmt.Sprintf("https://cdn.wisgo.sumbarprov.go.id/tiles/%s.mbtiles", destID), string(payloadJSON))
	}
}

func (r *postgresRepository) ListNewTours(statusFilter string) []models.NewTour {
	rows, err := r.db.Query(`
		SELECT id, COALESCE(user_id, 'usr-tourist-01'), name, COALESCE(category_id, 'cat-hidden-gem'),
		       city_regency, COALESCE(description, ''), latitude, longitude,
		       COALESCE(tips_menjaga, ''), COALESCE(is_sensitive, FALSE), COALESCE(status, 'pending'),
		       COALESCE(created_at::text, NOW()::text)
		FROM new_tour
		ORDER BY created_at DESC;
	`)
	if err != nil {
		return r.fallback.ListNewTours(statusFilter)
	}
	defer rows.Close()

	fallbackMap := make(map[string]models.NewTour)
	for _, fb := range r.fallback.ListNewTours("") {
		fallbackMap[strings.ToLower(fb.ID)] = fb
	}

	st := strings.ToLower(strings.TrimSpace(statusFilter))
	var list []models.NewTour
	for rows.Next() {
		var n models.NewTour
		if err := rows.Scan(
			&n.ID, &n.UserID, &n.Name, &n.CategoryID,
			&n.CityRegency, &n.Description, &n.Latitude, &n.Longitude,
			&n.TipsMenjaga, &n.IsSensitive, &n.Status, &n.CreatedAt,
		); err == nil {
			n.Category = mapCategoryIDToName(n.CategoryID)
			if fb, ok := fallbackMap[strings.ToLower(n.ID)]; ok {
				n.Facilities = fb.Facilities
				n.EstimatedPrice = fb.EstimatedPrice
				n.PhotoURL = fb.PhotoURL
				n.SubmitterName = fb.SubmitterName
				n.SubmitterPhone = fb.SubmitterPhone
				n.AdminNotes = fb.AdminNotes
				n.MergedIntoDestinationID = fb.MergedIntoDestinationID
				n.MergedRole = fb.MergedRole
			} else {
				n.Facilities = []string{"Jalur Trekking", "Spot Foto Alami"}
				n.EstimatedPrice = "Rp 10.000 / orang"
				n.PhotoURL = "https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=900&q=80"
				n.SubmitterName = "Wisatawan Komunitas WISGO"
				n.SubmitterPhone = "6281234567890"
			}
			if st != "" && st != "all" && strings.ToLower(n.Status) != st {
				continue
			}
			list = append(list, n)
		}
	}

	if len(list) == 0 {
		return r.fallback.ListNewTours(statusFilter)
	}
	return list
}

func (r *postgresRepository) UpsertNewTour(tour models.NewTour) models.NewTour {
	saved := r.fallback.UpsertNewTour(tour)
	_, _ = r.db.Exec(`
		INSERT INTO new_tour (
			id, user_id, name, category_id, city_regency, description,
			latitude, longitude, tips_menjaga, is_sensitive, status, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11, NOW()
		) ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			category_id = EXCLUDED.category_id,
			city_regency = EXCLUDED.city_regency,
			description = EXCLUDED.description,
			latitude = EXCLUDED.latitude,
			longitude = EXCLUDED.longitude,
			tips_menjaga = EXCLUDED.tips_menjaga,
			is_sensitive = EXCLUDED.is_sensitive,
			status = EXCLUDED.status;
	`, saved.ID, saved.UserID, saved.Name, saved.CategoryID, saved.CityRegency,
		saved.Description, saved.Latitude, saved.Longitude, saved.TipsMenjaga,
		saved.IsSensitive, saved.Status)
	return saved
}

func (r *postgresRepository) ApproveNewTourToDestination(id string) (*models.Destination, *models.NewTour, error) {
	dest, tour, err := r.fallback.ApproveNewTourToDestination(id)
	if err != nil {
		return nil, nil, err
	}
	_, _ = r.db.Exec(`UPDATE new_tour SET status = 'approved' WHERE LOWER(id) = LOWER($1);`, id)
	if dest != nil {
		_ = r.CreateCMS(*dest)
	}
	return dest, tour, nil
}

func (r *postgresRepository) RejectNewTour(id string, reason string) (*models.NewTour, error) {
	tour, err := r.fallback.RejectNewTour(id, reason)
	if err != nil {
		return nil, err
	}
	_, _ = r.db.Exec(`UPDATE new_tour SET status = 'rejected' WHERE LOWER(id) = LOWER($1);`, id)
	return tour, nil
}

func (r *postgresRepository) MergeNewToursToDestination(req MergeNewToursInput) (*models.Destination, []models.NewTour, error) {
	dest, tours, err := r.fallback.MergeNewToursToDestination(req)
	if err != nil {
		return nil, nil, err
	}
	for _, t := range tours {
		_, _ = r.db.Exec(`UPDATE new_tour SET status = 'approved' WHERE LOWER(id) = LOWER($1);`, t.ID)
	}
	if dest != nil {
		_ = r.CreateCMS(*dest)
	}
	return dest, tours, nil
}


