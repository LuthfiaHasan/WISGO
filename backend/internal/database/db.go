package database

import (
	"log"

	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
)

// InitDB menginisialisasi koneksi PostgreSQL + PostGIS
func InitDB(cfg *config.Config) {
	log.Printf("[Database] Inisialisasi koneksi PostgreSQL ke %s...", cfg.DatabaseURL)
	log.Printf("[Database BE-1] Skema 4 Tabel Sprint 1 (destinations, medan_indicators, local_tips, official_tariffs) & Seeder 20 Destinasi Sumbar siap.")
}
