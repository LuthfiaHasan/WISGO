package main

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
	"github.com/LuthfiaHasan/WISGO/backend/internal/database"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/analytics"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/auth"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/community"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/culture_ranking"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/gamification"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/pungli"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/scenes360"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/spatial"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/system_core"
)

// setupRouter menginisialisasi router Gin dengan seluruh modul Clean 3-Layer Architecture (BE-1 & BE-2)
func setupRouter(cfg *config.Config) *gin.Engine {
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()
	r.Use(middleware.CORSMiddleware())

	db := database.GetDB()

	// Health Check
	r.GET("/health", func(c *gin.Context) {
		dbStatus := "connected"
		if !database.IsConnected() {
			dbStatus = "offline"
		}
		c.JSON(http.StatusOK, gin.H{
			"status":   "ok",
			"app":      "Rancak.in Backend API",
			"env":      cfg.Environment,
			"database": dbStatus,
			"engine":   "Gin Web Framework v1.10.0 (Clean Architecture)",
		})
	})

	v1 := r.Group("/api/v1")
	v1.Use(middleware.DatabaseGuardMiddleware(cfg.Environment))

	// ==========================================
	// 1. INFRASTRUCTURE & SHARED MIDDLEWARE
	// ==========================================
	cache := middleware.NewInMemoryTTLCache(5 * time.Minute)
	rateLimiter := middleware.NewTokenBucketRateLimiter(60, 60*time.Second)

	// ==========================================
	// 2. MODUL BE-1 (CORE & SPASIAL RANAH MINANG)
	// ==========================================
	// Modul D1: Katalog 20 Destinasi Prioritas, Detail, Tarif, & Offline Bundle v2 (Pilar 2 & 7)
	var destRepo destination.Repository
	if db != nil && database.IsConnected() {
		destRepo = destination.NewPostgresRepository(db)
	} else {
		destRepo = destination.NewRepository()
	}
	destService := destination.NewService(destRepo)
	destHandler := destination.NewHandler(destService, cache)
	destHandler.RegisterRoutes(v1)

	// Modul D2: Tur Imersif 360° Aerial-to-Ground & CMS Studio 4-Pin (Pilar 1)
	scenesRepo := scenes360.NewRepository()
	scenesService := scenes360.NewService(scenesRepo, destRepo)
	scenesHandler := scenes360.NewHandler(scenesService, cache)
	scenesHandler.RegisterRoutes(v1)

	// Modul D3: Engine Along-the-Route "Shunlu", Peta Mikro, Audio GPS <=15m, Radar Bencana & SOS (Pilar 1, 2, 7)
	spatialRepo := spatial.NewRepository()
	spatialService := spatial.NewService(spatialRepo, destRepo)
	spatialHandler := spatial.NewHandler(spatialService, rateLimiter)
	spatialHandler.RegisterRoutes(v1)

	// Modul D4: Scanner Plang Smart QR, Lapor Pungli Anonim, & Pusat Komando Satgas Saber Pungli (Pilar 3)
	pungliRepo := pungli.NewRepository()
	pungliService := pungli.NewService(pungliRepo, destRepo, scenesRepo, spatialRepo)
	pungliHandler := pungli.NewHandler(pungliService, rateLimiter)
	pungliHandler.RegisterRoutes(v1)

	// Modul D5: Gaode Behavior-Based Ranking, Kamus Saku Audio Minang, & Kalender Budaya Hari Pakan (Pilar 1 & 2)
	cultureRepo := culture_ranking.NewRepository()
	cultureService := culture_ranking.NewService(cultureRepo)
	cultureHandler := culture_ranking.NewHandler(cultureService)
	cultureHandler.RegisterRoutes(v1)

	// Modul D6: Live SLA Benchmark <100ms, Manual Cache Flush, & Katalog Kontrak 24 Endpoint (Sprint 4)
	systemRepo := system_core.NewRepository(destRepo, scenesRepo, spatialRepo, cultureRepo)
	systemService := system_core.NewService(systemRepo, cache, rateLimiter)
	systemHandler := system_core.NewHandler(systemService)
	systemHandler.RegisterRoutes(v1)

	// ==========================================
	// 3. MODUL BE-2 (GROUP, ESCROW, ITINERARY, DLL)
	// ==========================================
	// Modul B1: Autentikasi OTP & Simpan Tempat Favorit (Pilar 4 & 5)
	var authRepo auth.Repository
	if db != nil && database.IsConnected() {
		authRepo = auth.NewPostgresRepository(db)
	} else {
		authRepo = auth.NewRepository()
	}
	authService := auth.NewService(authRepo)
	authHandler := auth.NewHandler(authService)
	authHandler.RegisterRoutes(v1)

	// Modul B2: Komunitas, Hidden Gem, Masking GPS, & Open Trips (Pilar 6 - eks B6)
	var communityRepo community.Repository
	if db != nil && database.IsConnected() {
		communityRepo = community.NewPostgresRepository(db)
	} else {
		communityRepo = community.NewRepository()
	}
	communityService := community.NewService(communityRepo)
	communityHandler := community.NewHandler(communityService)
	communityHandler.RegisterRoutes(v1)

	// Modul B7: Paspor Digital Minang, Anti-Fake GPS & Sertifikat Gubernur (Pilar 6)
	var gamificationRepo gamification.Repository
	if db != nil && database.IsConnected() {
		gamificationRepo = gamification.NewPostgresRepository(db)
	} else {
		gamificationRepo = gamification.NewRepository()
	}
	gamificationService := gamification.NewService(gamificationRepo)
	gamificationHandler := gamification.NewHandler(gamificationService)
	gamificationHandler.RegisterRoutes(v1)

	// Modul B8: Executive Dashboard Dispar Sumbar (Pilar 8)
	analyticsRepo := analytics.NewRepository()
	analyticsService := analytics.NewService(analyticsRepo)
	analyticsHandler := analytics.NewHandler(analyticsService)
	analyticsHandler.RegisterRoutes(v1)

	return r
}

func main() {
	cfg := config.LoadConfig()
	database.InitDB(cfg)

	r := setupRouter(cfg)

	addr := ":" + cfg.Port
	log.Printf("==================================================")
	log.Printf("  Rancak.in API Server (Gin Web Framework 3-Layer)")
	log.Printf("  Port: %s | Environment: %s                      ", cfg.Port, cfg.Environment)
	log.Printf("  Seluruh Modul BE-1 & BE-2 Aktif (Native Gin)    ")
	log.Printf("==================================================")

	if err := r.Run(addr); err != nil {
		log.Fatalf("Gagal menjalankan server: %v", err)
	}
}
