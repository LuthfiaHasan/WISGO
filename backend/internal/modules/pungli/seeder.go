package pungli

import (
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// SeedPungliReports menyediakan sampel laporan awal Satgas Saber Pungli
func SeedPungliReports() []models.PungliReport {
	now := time.Now()
	return []models.PungliReport{
		{
			ID:                    "pungli-001",
			TicketCode:            "PGL-202611-0091",
			DestinationID:         "dest-003",
			DestinationName:       "Pantai Air Manis & Batu Malin Kundang",
			ReporterName:          "Wisatawan Anonim",
			IncidentCategory:      "parkir_liar",
			ChargedAmountIDR:      25000,
			OfficialPerdaPriceIDR: 5000,
			OverchargeAmountIDR:   20000,
			PhotoEvidence:         "https://cdn.rancak.in/evidence/karcis-tanpa-porporasi-airmanis.jpg",
			UploadFormat:          "url",
			Latitude:              -0.9841,
			Longitude:             100.3612,
			Description:           "Oknum di luar pos resmi meminta uang parkir mobil Rp25.000 tanpa karcis porporasi Dishub/Perda Kota Padang.",
			Status:                "Diverifikasi",
			SatgasNotes:           "Tim Satgas Saber Pungli Kota Padang telah diterjunkan ke titik koordinat pintu selatan.",
			CreatedAt:             now.Add(-2 * time.Hour),
			UpdatedAt:             now.Add(-30 * time.Minute),
		},
		{
			ID:                    "pungli-002",
			TicketCode:            "PGL-202611-0092",
			DestinationID:         "dest-002",
			DestinationName:       "Jam Gadang & Taman Panorama Ngarai Sianok",
			ReporterName:          "Rombongan Keluarga Pekanbaru",
			IncidentCategory:      "tiket_di_atas_perda",
			ChargedAmountIDR:      150000,
			OfficialPerdaPriceIDR: 75000,
			OverchargeAmountIDR:   75000,
			PhotoEvidence:         "https://cdn.rancak.in/evidence/bukti-tarif-bendi-non-perda.jpg",
			UploadFormat:          "url",
			Latitude:              -0.3053,
			Longitude:             100.3690,
			Description:           "Kusir non-stiker resmi meminta Rp150.000 untuk rute pendek 15 menit yang seharusnya Rp75.000 sesuai tabel Perda.",
			Status:                "Masuk",
			SatgasNotes:           "Menunggu konfirmasi Koordinator Lapangan Dishub & Dispar Bukittinggi.",
			CreatedAt:             now.Add(-45 * time.Minute),
			UpdatedAt:             now.Add(-45 * time.Minute),
		},
	}
}
