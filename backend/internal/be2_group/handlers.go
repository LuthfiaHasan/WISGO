package be2_group

import (
	"encoding/json"
	"net/http"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// HandlerBE2 menangani endpoint Grup, Mitra, Escrow & Komunitas (Pilar 4, 5, 6, 8)
// CATATAN: File ini milik BE-2 — dibiarkan utuh 100% sesuai branch dev agar Zero Merge Conflict.
type HandlerBE2 struct{}

func NewHandlerBE2() *HandlerBE2 {
	return &HandlerBE2{}
}

func (h *HandlerBE2) RequestOTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	resp := map[string]string{
		"status":   "OTP_SENT",
		"otp_mock": "1234",
		"message":  "Kode OTP 4 digit telah dikirim ke WhatsApp Anda",
	}
	json.NewEncoder(w).Encode(resp)
}

func (h *HandlerBE2) CreateGroupRoom(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	room := models.GroupRoom{
		ID:       "grp-001",
		RoomCode: "RANCAK-772",
		Title:    "Liburan Keluarga Besar ke Bukittinggi",
		LeaderID: "usr-001",
	}
	json.NewEncoder(w).Encode(room)
}

func (h *HandlerBE2) GetPartnersKatalog(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	partners := []models.PartnerNagari{
		{
			ID:          "ptn-001",
			Name:        "Homestay Rumah Gadang Uda Zul",
			Category:    "Homestay Rumah Gadang",
			WhatsApp:    "6281234567890",
			IsVerified:  true,
			StandardFee: 250000,
			NagariName:  "Nagari Koto Gadang",
		},
	}
	json.NewEncoder(w).Encode(partners)
}

func (h *HandlerBE2) WAWebhookSimulation(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	resp := map[string]string{
		"action":      "1",
		"status":      "CONFIRMED",
		"ticket_qr":   "QR-RANCAK-TKT-991823",
		"escrow_info": "Dana diamankan di rekening bersama hingga QR di-scan di lokasi",
	}
	json.NewEncoder(w).Encode(resp)
}
