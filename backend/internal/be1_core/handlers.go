package be1_core

import (
	"encoding/json"
	"net/http"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// HandlerBE1 menangani endpoint Core & Spasial (Pilar 1, 2, 3, 7)
type HandlerBE1 struct{}

func NewHandlerBE1() *HandlerBE1 {
	return &HandlerBE1{}
}

// GetDestinations handler untuk daftar destinasi
func (h *HandlerBE1) GetDestinations(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	sample := []models.Destination{
		{
			ID:          "dest-001",
			Name:        "Lembah Harau",
			Category:    "Alam & Tebing",
			CityRegency: "Kab. Lima Puluh Kota",
			Description: "Lembah subur dengan tebing granit terjal setinggi 100-500 meter.",
			Latitude:    -0.1023,
			Longitude:   100.6728,
			CrowdLevel:  "Sedang",
		},
	}
	json.NewEncoder(w).Encode(sample)
}

// GetDestinationDetail handler untuk 4 statistik & 5 indikator medan
func (h *HandlerBE1) GetDestinationDetail(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	detail := models.Destination{
		ID:          "dest-001",
		Name:        "Lembah Harau",
		Category:    "Alam & Tebing",
		CityRegency: "Kab. Lima Puluh Kota",
		CrowdLevel:  "Sedang",
		MedanIndicator: &models.MedanIndicator{
			VehicleAccess:  "Mobil OK",
			TrekkingLevel:  "Datar / Mudah",
			CellularSignal: "Blank Spot",
			Facilities:     "Toilet & Musala Lengkap",
			GuideNeed:      "Mandiri",
		},
	}
	json.NewEncoder(w).Encode(detail)
}

// PostShunluSearch mencari titik singgah searah rute + kalkulasi detour
func (h *HandlerBE1) PostShunluSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"query":           "SPBU & RM Padang",
		"detour_time_min": 8,
		"detour_distance": "650 m dari rute utama",
		"recommended":     "RM Simpang Raya Bukittinggi",
	}
	json.NewEncoder(w).Encode(response)
}

// PostReportPungli menerima laporan pungli anonim dari wisatawan
func (h *HandlerBE1) PostReportPungli(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]string{
		"status":  "success",
		"ticket":  "PGL-202611-0091",
		"message": "Laporan berhasil diteruskan ke Satgas Saber Pungli Dispar Sumbar",
	}
	json.NewEncoder(w).Encode(response)
}

