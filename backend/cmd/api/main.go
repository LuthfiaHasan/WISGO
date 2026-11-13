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

	// --- Route BE-1 (Core & Spasial) ---
	mux.HandleFunc("GET /api/v1/destinations", be1.GetDestinations)
	mux.HandleFunc("GET /api/v1/destinations/detail", be1.GetDestinationDetail)
	mux.HandleFunc("POST /api/v1/spatial/shunlu", be1.PostShunluSearch)
	mux.HandleFunc("POST /api/v1/pungli/report", be1.PostReportPungli)

	// --- Route BE-2 (Grup, Mitra, Escrow & Komunitas) ---
	mux.HandleFunc("POST /api/v1/auth/request-otp", be2.RequestOTP)
	mux.HandleFunc("POST /api/v1/auth/verify-otp", be2.VerifyOTP)
	mux.HandleFunc("GET /api/v1/partners", be2.GetPartnersKatalog)
	mux.HandleFunc("GET /api/v1/partners/detail", be2.GetPartnerDetail)
	mux.HandleFunc("GET /api/v1/users/saved", be2.GetSavedPlaces)
	mux.HandleFunc("POST /api/v1/users/saved", be2.ToggleSavedPlace)
	mux.HandleFunc("GET /api/v1/itineraries", be2.GetItineraries)
	mux.HandleFunc("POST /api/v1/itineraries", be2.CreateItinerary)
	mux.HandleFunc("POST /api/v1/itineraries/auto-generate", be2.AutoGenerateItinerary)
	mux.HandleFunc("POST /api/v1/groups", be2.CreateGroupRoom)
	mux.HandleFunc("GET /api/v1/groups/{code}", be2.GetGroupRoom)
	mux.HandleFunc("POST /api/v1/groups/{code}/join", be2.JoinGroupRoom)
	mux.HandleFunc("POST /api/v1/groups/{code}/vote", be2.VoteGroupDestination)
	mux.HandleFunc("GET /api/v1/groups/{code}/results", be2.GetGroupVoteResults)
	mux.HandleFunc("GET /api/v1/groups/detail", be2.GetGroupRoom)
	mux.HandleFunc("POST /api/v1/groups/vote", be2.VoteGroupDestination)
	mux.HandleFunc("GET /api/v1/groups/results", be2.GetGroupVoteResults)
	mux.HandleFunc("POST /api/v1/groups/{code}/split-bill", be2.SplitBill)
	mux.HandleFunc("POST /api/v1/groups/split-bill", be2.SplitBill)
	mux.HandleFunc("POST /api/v1/groups/{code}/radar-ping", be2.RadarPing)
	mux.HandleFunc("GET /api/v1/groups/{code}/radar", be2.GetGroupRadar)
	mux.HandleFunc("GET /api/v1/community/places", be2.GetCommunityPlaces)
	mux.HandleFunc("POST /api/v1/community/places", be2.CreateCommunityPlace)
	mux.HandleFunc("GET /api/v1/community/shared-trips", be2.GetSharedTrips)
	mux.HandleFunc("POST /api/v1/community/shared-trips", be2.CreateSharedTrip)
	mux.HandleFunc("POST /api/v1/bookings/create", be2.CreateBooking)
	mux.HandleFunc("POST /api/v1/bookings/wa-webhook", be2.WAWebhookSimulation)
	mux.HandleFunc("GET /api/v1/bookings/{id}/ticket-qr", be2.GetBookingTicketQR)
	mux.HandleFunc("GET /api/v1/bookings/ticket-qr", be2.GetBookingTicketQR)
	mux.HandleFunc("POST /api/v1/escrow/scan-redeem", be2.ScanRedeemEscrow)
	mux.HandleFunc("GET /api/v1/escrow/currency/myr-rate", be2.GetMYRConversionRate)

	// Registrasi Route BE-2: Minggu 4 (Gamifikasi Paspor Digital, Anti-Fake GPS, Sertifikat & Analitik Dispar)
	mux.HandleFunc("POST /api/v1/gamification/checkin", be2.ValidateGPSCheckIn)
	mux.HandleFunc("GET /api/v1/gamification/passport", be2.GetDigitalPassport)
	mux.HandleFunc("POST /api/v1/gamification/certificate", be2.GenerateGovernorCertificate)
	mux.HandleFunc("GET /api/v1/gamification/certificate", be2.GenerateGovernorCertificate)
	mux.HandleFunc("GET /api/v1/analytics/dispar/summary", be2.GetDisparAnalyticsSummary)

	// Health check
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","app":"Rancak.in Backend API","env":"%s"}`, cfg.Environment)
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

