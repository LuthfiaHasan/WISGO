package database

import (
	"log"

	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
)

// InitDB menginisialisasi koneksi PostgreSQL + PostGIS
func InitDB(cfg *config.Config) {
	log.Printf("[Database] Inisialisasi koneksi PostgreSQL ke %s...", cfg.DatabaseURL)
	// Database connection pool setup (GORM / pgx / database/sql)
	// Dieksekusi saat server dijalankan
}

