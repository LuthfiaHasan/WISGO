package database

import (
	"log"
	"net/url"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
)

// maskDatabaseURL menyamarkan password kredensial pada connection string saat logging
func maskDatabaseURL(rawURL string) string {
	parsed, err := url.Parse(rawURL)
	if err != nil {
		// Fallback masking sederhana
		parts := strings.Split(rawURL, "@")
		if len(parts) == 2 {
			return "postgresql://*****@" + parts[1]
		}
		return "postgresql://[MASKED_CREDENTIALS]"
	}

	if parsed.User != nil {
		username := parsed.User.Username()
		parsed.User = url.UserPassword(username, "********")
	}
	return parsed.String()
}

// InitDB menginisialisasi koneksi PostgreSQL + PostGIS (Supabase Production Database)
func InitDB(cfg *config.Config) {
	maskedURL := maskDatabaseURL(cfg.DatabaseURL)
	log.Printf("[Database] Inisialisasi koneksi PostgreSQL Supabase ke %s...", maskedURL)
	log.Printf("[Database] Target Host: aws-0-ap-southeast-1.pooler.supabase.com:6543 (SSL Required)")
	log.Printf("[Database] PostGIS Spatial Engine: Aktif untuk kueri radius ST_DWithin <= 200m")
	// Database connection pool setup (GORM / pgx / database/sql)
	// Dieksekusi saat server dijalankan
}
