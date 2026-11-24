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

	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
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
			// Bersihkan tanda kutip jika ada
			val = strings.Trim(val, `"'`)
			os.Setenv(key, val)
		}
	}
}

func main() {
	log.Println("==================================================================")
	log.Println("WISGO (Rancak.in) - Database Migration & Centralized Cloud Setup")
	log.Println("==================================================================")

	// Muat .env
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

	// 2. Daftar file migrasi urut
	migrationFiles := []string{
		"migrations/000001_be1_sprint1.sql",
		"migrations/000001_be1_sprint2.sql",
		"migrations/000001_be1_sprint3.sql",
		"migrations/000001_be1_sprint4_tuning.sql",
		"migrations/000002_be2_schema.sql",
		"migrations/000002_be2_seeders.sql",
		"migrations/000003_v2_new_schema.sql",
		"migrations/000004_v2_contract_cleanup.sql",
	}

	for _, fileRel := range migrationFiles {
		// Cari file apakah di ./migrations atau ../migrations
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
			log.Fatalf("Gagal mengeksekusi %s:\nERROR: %v", filePath, err)
		}
		log.Printf("SUKSES: %s", filePath)
	}

	// 3. SEED 20 DESTINASI JIKA MASIH KOSONG
	log.Println("Memeriksa dan menyuntikkan seeder 20 Destinasi Prioritas...")
	var destCount int
	_ = db.QueryRow("SELECT COUNT(*) FROM destinations;").Scan(&destCount)
	if destCount == 0 {
		seedDestinationsToDB(db)
	}

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
	dests := destination.Seed20DestinationsSumbar()
	for _, d := range dests {
		_, err := db.Exec(`
			INSERT INTO destinations (
				id, slug, name, category, city_regency, description,
				latitude, longitude, elevation_m, cover_image, crowd_level,
				distance_km, travel_time_min, estimated_cost, is_hidden_gem,
				qr_placard_code, opening_hours
			) VALUES (
				$1, $2, $3, $4, $5, $6,
				$7, $8, $9, $10, $11,
				$12, $13, $14, $15,
				$16, $17
			) ON CONFLICT (id) DO NOTHING;
		`, d.ID, d.Slug, d.Name, d.Category, d.CityRegency, d.Description,
			d.Latitude, d.Longitude, d.ElevationM, d.CoverImage, d.CrowdLevel,
			d.DistanceKm, d.TravelTimeMin, d.EstimatedCost, d.IsHiddenGem,
			d.QRPlacardCode, d.OpeningHours)
		if err != nil {
			log.Printf("Gagal insert destination %s: %v", d.ID, err)
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
	log.Printf("Sukses menyuntikkan %d destinasi ke Supabase!", len(dests))
}
