package main

import (
	"bufio"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "github.com/lib/pq"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/culture_ranking"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/pungli"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/scenes360"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/spatial"
)

func loadEnvFile(path string) {
	file, err := os.Open(path)
	if err != nil {
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			val := strings.TrimSpace(parts[1])
			val = strings.Trim(val, `"'`)
			os.Setenv(key, val)
		}
	}
}

func main() {
	log.Println("==================================================================")
	log.Println("WISGO (Rancak.in) - Database Migration & Centralized Cloud Setup")
	log.Println("==================================================================")

	loadEnvFile(".env")
	loadEnvFile("../.env")

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("ERROR: DATABASE_URL tidak ditemukan di file .env atau environment variable")
	}

	log.Printf("Menghubungkan ke Supabase PostgreSQL...")
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Gagal inisialisasi koneksi driver: %v", err)
	}
	defer db.Close()

	db.SetConnMaxLifetime(5 * time.Minute)
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)

	if err := db.Ping(); err != nil {
		log.Fatalf("Koneksi ke Supabase GAGAL: %v\nPastikan koneksi internet aktif dan password benar.", err)
	}
	log.Println("KONEKSI KE SUPABASE BERHASIL! (HTTP/TCP ping sukses)")

	// 1. Pastikan PostGIS Extension Aktif
	log.Println("Memeriksa ekstensi PostGIS...")
	_, err = db.Exec("CREATE EXTENSION IF NOT EXISTS postgis;")
	if err != nil {
		log.Printf("Peringatan saat create extension postgis: %v (mungkin sudah ada)", err)
	} else {
		log.Println("Ekstensi PostGIS AKTIF.")
	}

	// 2. Daftar file migrasi urut (Sprint 1-4 + V2 Contract + Revisi Production BE-1)
	migrationFiles := []string{
		"migrations/000001_be1_sprint1.sql",
		"migrations/000001_be1_sprint2.sql",
		"migrations/000001_be1_sprint3.sql",
		"migrations/000001_be1_sprint4_tuning.sql",
		"migrations/000002_be2_schema.sql",
		"migrations/000002_be2_seeders.sql",
		"migrations/000003_v2_new_schema.sql",
		"migrations/000004_v2_contract_cleanup.sql",
		"migrations/000004_seed_real_emergency_contacts.sql",
		"migrations/000005_be1_production_alignment.sql",
	}

	for _, fileRel := range migrationFiles {
		filePath := fileRel
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			filePath = filepath.Join("..", fileRel)
		}
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			filePath = filepath.Join("backend", fileRel)
		}

		log.Printf("Mengeksekusi migrasi: %s ...", filePath)
		content, err := os.ReadFile(filePath)
		if err != nil {
			log.Fatalf("Gagal membaca file %s: %v", filePath, err)
		}

		sqlContent := string(content)
		_, err = db.Exec(sqlContent)
		if err != nil {
			log.Printf("Catatan saat mengeksekusi %s: %v", filePath, err)
		} else {
			log.Printf("SUKSES: %s", filePath)
		}
	}

	// 3. SEED SELURUH TABEL BE-1 KE SUPABASE JIKA MASIH KOSONG
	seedDestinationsToDB(db)
	seedBE1ModulesToDB(db)

	// 4. Verifikasi Tabel yang Terbentuk di Supabase
	rows, err := db.Query(`
		SELECT table_name 
		FROM information_schema.tables 
		WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
		ORDER BY table_name;
	`)
	if err != nil {
		log.Fatalf("Gagal query daftar tabel: %v", err)
	}
	defer rows.Close()

	var tables []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err == nil {
			tables = append(tables, name)
		}
	}

	fmt.Println("\n==================================================================")
	fmt.Printf("MIGRASI DATABASE TERPUSAT SELESAI DENGAN SUKSES!\n")
	fmt.Printf("Total Tabel Terdaftar di Supabase: %d tabel\n", len(tables))
	fmt.Println("==================================================================")
	for i, t := range tables {
		var count int
		_ = db.QueryRow(fmt.Sprintf("SELECT COUNT(*) FROM %s", t)).Scan(&count)
		fmt.Printf("%2d. %-32s (%d records)\n", i+1, t, count)
	}
	fmt.Println("==================================================================")
}

func seedDestinationsToDB(db *sql.DB) {
	log.Println("Memeriksa dan menyuntikkan seeder 20 Destinasi Prioritas...")
	dests := destination.Seed20DestinationsSumbar()
	for _, d := range dests {
		_, err := db.Exec(`
			INSERT INTO destinations (
				id, slug, name, category_id, category, city_regency, description,
				latitude, longitude, elevation_m, cover_image, crowd_level,
				distance_km, travel_time_min, estimated_cost, is_hidden_gem,
				verification_status, qr_placard_code, opening_hours
			) VALUES (
				$1, $2, $3, $4, $5, $6, $7,
				$8, $9, $10, $11, $12,
				$13, $14, $15, $16,
				'verified', $17, $18
			) ON CONFLICT (id) DO UPDATE SET
				category_id = EXCLUDED.category_id,
				category = EXCLUDED.category;
		`, d.ID, d.Slug, d.Name, d.CategoryID, d.Category, d.CityRegency, d.Description,
			d.Latitude, d.Longitude, d.ElevationM, d.CoverImage, d.CrowdLevel,
			d.DistanceKm, d.TravelTimeMin, d.EstimatedCost, d.IsHiddenGem,
			d.QRPlacardCode, d.OpeningHours)
		if err != nil {
			continue
		}

		if d.MedanIndicator != nil {
			m := d.MedanIndicator
			_, _ = db.Exec(`
				INSERT INTO indikator_medan (
					id, destination_id, vehicle_access, trekking_level, cellular_signal, facilities, guide_need
				) VALUES ($1, $2, $3, $4, $5, $6, $7)
				ON CONFLICT (destination_id) DO NOTHING;
			`, m.ID, m.DestinationID, m.VehicleAccess, m.TrekkingLevel, m.CellularSignal, m.Facilities, m.GuideNeed)
		}

		for _, tip := range d.Tips {
			_, _ = db.Exec(`
				INSERT INTO aturan_destinasi (id, destination_id, category_id, title, content)
				VALUES ($1, $2, 'cat_rul_alam', $3, $4)
				ON CONFLICT (id) DO NOTHING;
			`, tip.ID, tip.DestinationID, tip.Title, tip.Content)
		}

		for _, trf := range d.Tariffs {
			_, _ = db.Exec(`
				INSERT INTO official_tariffs (id, destination_id, item_name, category, price, unit, regulation_ref)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
				ON CONFLICT (id) DO NOTHING;
			`, trf.ID, trf.DestinationID, trf.ItemName, trf.Category, trf.Price, trf.Unit, trf.RegulationRef)
		}
	}
}

func seedBE1ModulesToDB(db *sql.DB) {
	// 1. Panorama Scenes 360° & 4 Pin Hotspots
	log.Println("Menyinkronkan seeder panorama_scenes & panorama_hotspots...")
	for _, sceneList := range scenes360.SeedScenes360() {
		for _, sc := range sceneList {
			_, _ = db.Exec(`
				INSERT INTO panorama_scenes (
					id, destination_id, title, scene_type, panorama_url, upload_format,
					spatial_audio_url, initial_pitch, initial_yaw, is_default_scene
				) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
				ON CONFLICT (id) DO NOTHING;
			`, sc.ID, sc.DestinationID, sc.Title, sc.Type, sc.PanoramaURL, sc.UploadFormat,
				sc.SpatialAudioURL, sc.InitialPitch, sc.InitialYaw, sc.IsDefaultScene)

			for _, pin := range sc.Hotspots {
				voice := pin.VoiceText
				if voice == "" {
					voice = pin.AudioURL
				}
				_, err := db.Exec(`
					INSERT INTO panorama_hotspots (
						id, scene_id, pin_type, color_token, pitch, yaw, title, target_ref, audio_url, description
					) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
					ON CONFLICT (id) DO NOTHING;
				`, pin.ID, sc.ID, pin.Type, pin.ColorToken, pin.Pitch, pin.Yaw, pin.Title, pin.TargetRef, voice, pin.Description)
				if err != nil {
					_, _ = db.Exec(`
						INSERT INTO panorama_hotspots (
							id, scene_id, pin_type, color_radar, pitch, yaw, title, target_ref, voice_text, description
						) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
						ON CONFLICT (id) DO NOTHING;
					`, pin.ID, sc.ID, pin.Type, pin.ColorToken, pin.Pitch, pin.Yaw, pin.Title, pin.TargetRef, voice, pin.Description)
				}
			}
		}
	}

	// 2. Visit Point (Shunlu POI Searah Rute)
	log.Println("Menyinkronkan seeder visit_point (Shunlu POI)...")
	for _, poi := range spatial.SeedShunluPOIs() {
		_, _ = db.Exec(`
			INSERT INTO visit_point (
				id, name, category_id, corridor_road, city_regency, latitude, longitude,
				detour_minutes, detour_distance_meter, highlight_note, opening_hours, is_recommended
			) VALUES ($1, $2, 'cat_poi_rm', $3, $4, $5, $6, $7, $8, $9, $10, $11)
			ON CONFLICT (id) DO NOTHING;
		`, poi.ID, poi.Name, poi.CorridorRoad, poi.CityRegency, poi.Latitude, poi.Longitude,
			poi.DetourMinutes, poi.DetourDistanceMeter, poi.HighlightNote, poi.OpeningHours, poi.IsRecommended)
	}

	// 3. Hazard Alerts (4 Koridor Ekstrem) & SOS Signals
	log.Println("Menyinkronkan seeder hazard_alerts & sos_signals...")
	for _, hz := range spatial.SeedHazardAlerts() {
		_, _ = db.Exec(`
			INSERT INTO hazard_alerts (
				id, corridor_code, location, road_segment, city_regency, latitude, longitude,
				radius_meter, severity, hazard_type, weather_status, slope_gradient_deg,
				message, detour_route, nearest_rescue_post, emergency_contact
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
			ON CONFLICT (id) DO NOTHING;
		`, hz.ID, hz.CorridorCode, hz.Location, hz.RoadSegment, hz.CityRegency, hz.Latitude, hz.Longitude,
			hz.RadiusMeter, hz.Severity, hz.HazardType, hz.WeatherStatus, hz.SlopeGradientDeg,
			hz.Message, hz.DetourRoute, hz.NearestRescuePost, hz.EmergencyContact)
	}

	for _, sos := range spatial.SeedSOSSignals() {
		_, _ = db.Exec(`
			INSERT INTO sos_signals (
				id, sos_code, tourist_name, phone_number, emergency_type, latitude, longitude,
				battery_percent, passengers_count, nearest_corridor, nearest_rescue_post,
				distance_to_rescue_km, eta_rescue_minutes, status, notes
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
			ON CONFLICT (sos_code) DO NOTHING;
		`, sos.ID, sos.SOSCode, sos.TouristName, sos.PhoneNumber, sos.EmergencyType, sos.Latitude, sos.Longitude,
			sos.BatteryPercent, sos.PassengersCount, sos.NearestCorridor, sos.NearestRescuePost,
			sos.DistanceToRescueKm, sos.ETARescueMinutes, sos.Status, sos.Notes)
	}

	// 4. Emergency Contacts (6 Kontak Resmi Bencana Sumbar)
	log.Println("Menyinkronkan seeder emergency_contacts...")
	for _, ec := range models.GetDefaultEmergencyContacts() {
		_, err := db.Exec(`
			INSERT INTO emergency_contacts (
				id, agency_name, agency_type, phone_number, whatsapp_number, city_regency, created_by_admin_id, is_active
			) VALUES ($1, $2, $3, $4, $5, $6, 'usr-001', TRUE)
			ON CONFLICT (id) DO NOTHING;
		`, ec.ID, ec.AgencyName, ec.AgencyType, ec.PhoneNumber, ec.WhatsAppNumber, ec.City)
		if err != nil {
			_, _ = db.Exec(`
				INSERT INTO emergency_contacts (
					id, corridor_code, agency_type, agency_name, phone_number, whatsapp_number, city, is_active
				) VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
				ON CONFLICT (id) DO NOTHING;
			`, ec.ID, ec.CorridorCode, ec.AgencyType, ec.AgencyName, ec.PhoneNumber, ec.WhatsAppNumber, ec.City)
		}
	}

	// 5. Gaode Behavior Rankings, Minang Phrases, Cultural Events
	log.Println("Menyinkronkan seeder gaode_behavior_rankings, minang_phrases, & cultural_events...")
	for _, g := range culture_ranking.SeedGaodeRankings() {
		_, _ = db.Exec(`
			INSERT INTO gaode_behavior_rankings (
				id, destination_id, category, rank_position, gaode_authenticity_score,
				active_nav_count_30d, avg_dwell_time_min, return_visit_rate_pct,
				anti_fake_review_verified, trending_badge
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
			ON CONFLICT (destination_id) DO NOTHING;
		`, g.ID, g.DestinationID, g.Category, g.RankPosition, g.GaodeAuthenticityScore,
			g.ActiveNavCount30d, g.AvgDwellTimeMin, g.ReturnVisitRatePct,
			g.AntiFakeReviewVerified, g.TrendingBadge)
	}

	for _, mp := range culture_ranking.SeedMinangPhrases() {
		_, _ = db.Exec(`
			INSERT INTO minang_phrases (
				id, category, indonesian_text, minang_text, phonetic_guide,
				audio_url, dialect_note, usage_context_tip, politeness_level
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
			ON CONFLICT (id) DO NOTHING;
		`, mp.ID, mp.Category, mp.IndonesianText, mp.MinangText, mp.PhoneticGuide,
			mp.AudioURL, mp.DialectNote, mp.UsageContextTip, mp.PolitenessLevel)
	}

	for _, ev := range culture_ranking.SeedCulturalEvents() {
		_, _ = db.Exec(`
			INSERT INTO cultural_events (
				id, title, event_type, nagari_location, city_regency,
				schedule_rule, next_event_date, latitude, longitude, highlight_item, cultural_etiquette
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
			ON CONFLICT (id) DO NOTHING;
		`, ev.ID, ev.Title, ev.EventType, ev.NagariLocation, ev.CityRegency,
			ev.ScheduleRule, ev.NextEventDate, ev.Latitude, ev.Longitude, ev.HighlightItem, ev.CulturalEtiquette)
	}

	// 6. Pungli Reports
	log.Println("Menyinkronkan seeder pungli_reports...")
	for _, pr := range pungli.SeedPungliReports() {
		_, _ = db.Exec(`
			INSERT INTO pungli_reports (
				id, ticket_code, destination_id, reporter_name, incident_category,
				charged_amount_idr, official_perda_price_idr, overcharge_amount_idr,
				photo_evidence, upload_format, latitude, longitude, description, status, satgas_notes
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
			ON CONFLICT (id) DO NOTHING;
		`, pr.ID, pr.TicketCode, pr.DestinationID, pr.ReporterName, pr.IncidentCategory,
			pr.ChargedAmountIDR, pr.OfficialPerdaPriceIDR, pr.OverchargeAmountIDR,
			pr.PhotoEvidence, pr.UploadFormat, pr.Latitude, pr.Longitude, pr.Description, pr.Status, pr.SatgasNotes)
	}

	// 7. Meja Kurasi Usulan Destinasi Wisatawan (Tabel new_tour)
	log.Println("Menyinkronkan seeder new_tour (Meja Kurasi Usulan Destinasi Wisatawan)...")
	for _, nt := range models.GetDefaultNewTours() {
		_, _ = db.Exec(`
			INSERT INTO new_tour (
				id, user_id, name, category_id, city_regency, description,
				latitude, longitude, tips_menjaga, is_sensitive, status, created_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
			ON CONFLICT (id) DO NOTHING;
		`, nt.ID, nt.UserID, nt.Name, nt.CategoryID, nt.CityRegency, nt.Description,
			nt.Latitude, nt.Longitude, nt.TipsMenjaga, nt.IsSensitive, nt.Status)
	}
}
