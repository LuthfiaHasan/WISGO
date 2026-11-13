package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/LuthfiaHasan/WISGO/backend/internal/be1_core"
	"github.com/LuthfiaHasan/WISGO/backend/internal/be2_group"
	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
	"github.com/LuthfiaHasan/WISGO/backend/internal/database"
)

func main() {
	cfg := config.LoadConfig()
	database.InitDB(cfg)

	mux := http.NewServeMux()

	// Inisialisasi Handler Tim BE-1 & BE-2
	be1 := be1_core.NewHandlerBE1()
	be2 := be2_group.NewHandlerBE2()

	// --- Route BE-1 (Core & Spasial — Sprint 1 Lengkap) ---
	be1.RegisterSprint1Routes(mux)

	// --- Route BE-2 (Grup, Mitra, Escrow — Dibiarkan Utuh Zero Conflict) ---
	mux.HandleFunc("POST /api/v1/auth/request-otp", be2.RequestOTP)
	mux.HandleFunc("POST /api/v1/groups", be2.CreateGroupRoom)
	mux.HandleFunc("GET /api/v1/partners", be2.GetPartnersKatalog)
	mux.HandleFunc("POST /api/v1/bookings/wa-webhook", be2.WAWebhookSimulation)

	// Health check
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","app":"Rancak.in Backend API","env":"%s","be1_sprint1":"active_20_destinations"}`, cfg.Environment)
	})

	addr := ":" + cfg.Port
	log.Printf("==================================================")
	log.Printf("  Rancak.in API Server (Go Gin/Net-HTTP Engine)  ")
	log.Printf("  Port: %s | Environment: %s                      ", cfg.Port, cfg.Environment)
	log.Printf("  BE-1 & BE-2 Modular Architecture Active         ")
	log.Printf("==================================================")

	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("Gagal menjalankan server: %v", err)
	}
}
