package database

import (
	"database/sql"
	"fmt"
	"log"
	"sync"
	"time"

	_ "github.com/lib/pq"

	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
)

var (
	// DB instance koneksi global ke PostgreSQL
	DB          *sql.DB
	isConnected bool
	mu          sync.RWMutex
)

// InitDB menginisialisasi koneksi PostgreSQL + PostGIS ke Supabase
func InitDB(cfg *config.Config) (*sql.DB, error) {
	mu.Lock()
	defer mu.Unlock()

	log.Printf("[Database] Menghubungkan ke PostgreSQL: %s ...", maskURL(cfg.DatabaseURL))

	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		isConnected = false
		log.Printf("[Database ERROR] Gagal membuka driver PostgreSQL: %v", err)
		return nil, err
	}

	db.SetConnMaxLifetime(5 * time.Minute)
	db.SetMaxOpenConns(15)
	db.SetMaxIdleConns(5)

	if err := db.Ping(); err != nil {
		isConnected = false
		log.Printf("[Database ERROR] Koneksi database GAGAL / Offline: %v", err)
		return nil, fmt.Errorf("database offline: %w", err)
	}

	DB = db
	isConnected = true
	log.Println("[Database] KONEKSI SUKSES: Terhubung ke PostgreSQL (Supabase Cloud). Database terpusat AKTIF!")
	return DB, nil
}

// IsConnected memeriksa apakah status koneksi database saat ini aktif
func IsConnected() bool {
	mu.RLock()
	defer mu.RUnlock()
	if !isConnected || DB == nil {
		return false
	}
	// Ping ringan untuk memastikan koneksi fisik masih hidup
	if err := DB.Ping(); err != nil {
		return false
	}
	return true
}

// GetDB mengembalikan instance *sql.DB yang aktif
func GetDB() *sql.DB {
	mu.RLock()
	defer mu.RUnlock()
	return DB
}

func maskURL(url string) string {
	if len(url) < 15 {
		return "***"
	}
	return url[:12] + "..." + url[len(url)-10:]
}
