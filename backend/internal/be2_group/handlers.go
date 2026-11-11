package be2_group

import (
	"encoding/json"
	"net/http"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// HandlerBE2 menangani endpoint Grup, Mitra, Escrow & Gamifikasi (Pilar 4, 5, 6, 8)
type HandlerBE2 struct{}

func NewHandlerBE2() *HandlerBE2 {
	return &HandlerBE2{}
}

// RequestOTP mengirim kode OTP 4 kotak ke nomor HP
func (h *HandlerBE2) RequestOTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	resp := map[string]string{
		"status":  "sent",
		"message": "Kode OTP 4 digit telah dikirimkan via WhatsApp/SMS",
	}
	json.NewEncoder(w).Encode(resp)
}

// CreateGroupRoom membuat private group room perjalanan
func (h *HandlerBE2) CreateGroupRoom(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	room := models.GroupRoom{
		ID:       "grp-9912",
		RoomCode: "RANCAK-MINANG-88",
		Title:    "Liburan Keluarga Lembah Harau - Bukittinggi",
	}
	json.NewEncoder(w).Encode(room)
}

// GetPartnersKatalog katalog 5 mitra nagari + level pedas
func (h *HandlerBE2) GetPartnersKatalog(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	partners := []models.PartnerNagari{
		{
			ID:          "ptr-01",
			Name:        "Homestay Rumah Gadang Etek Nur",
			Category:    "Homestay Rumah Gadang",
			WhatsApp:    "6281234567890",
			IsVerified:  true,
			StandardFee: 250000,
			NagariName:  "Nagari Sungai Buluah",
		},
		{
			ID:          "ptr-02",
			Name:        "Itiak Lado Mudo Ngarai Sianok",
			Category:    "Kuliner Halal",
			WhatsApp:    "6281298765432",
			SpicyLevel:  4, // Level Pedas 4
			IsVerified:  true,
			StandardFee: 45000,
			NagariName:  "Nagari Koto Gadang",
		},
	}
	json.NewEncoder(w).Encode(partners)
}

// WAWebhookSimulation simulator respon Bot WA Mitra (1 Terima, 0 Tolak)
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

