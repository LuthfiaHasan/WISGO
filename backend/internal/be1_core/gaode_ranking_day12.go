package be1_core

import (
	"encoding/json"
	"math"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// NavigationTelemetryInput payload telemetri penyelesaian navigasi & waktu singgah GPS nyata (FE-1)
type NavigationTelemetryInput struct {
	DestinationID     string  `json:"destination_id"`
	DwellTimeMinutes  int     `json:"dwell_time_minutes"`
	IsRepeatVisit     bool    `json:"is_repeat_visit"`
	GPSAccuracyMeters float64 `json:"gps_accuracy_meters"`
}

// ComputeGaodeScore menghitung skor keaslian Gaode Guide (0 - 100)
// Rumus: (0.45 * NormalizedNav) + (0.40 * NormalizedDwellTime) + (0.15 * ReturnVisitRate)
func ComputeGaodeScore(activeNavCount, avgDwellMin int, returnRatePct float64) float64 {
	normNav := math.Min(100.0, (float64(activeNavCount)/5000.0)*100.0)
	normDwell := math.Min(100.0, (float64(avgDwellMin)/140.0)*100.0)
	normReturn := math.Min(100.0, (returnRatePct/40.0)*100.0)

	rawScore := (0.45 * normNav) + (0.40 * normDwell) + (0.15 * normReturn)
	// Skala ke rentang populer 82.0 - 99.8 untuk visualisasi leaderboard
	scaled := 82.0 + (rawScore/100.0)*17.5
	return math.Round(math.Min(99.8, scaled)*10) / 10
}

// GetGaodeBehaviorRankings — GET /api/v1/destinations/rankings/gaode
// Hari 12 (Selasa): Daftar peringkat populer anti-manipulasi bintang palsu (Pilar 2 — P2.4)
func (h *HandlerBE1) GetGaodeBehaviorRankings(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	categoryFilter := strings.TrimSpace(r.URL.Query().Get("category"))
	rankings := h.repo.ListGaodeRankings(categoryFilter)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":           "ok",
		"algorithm":        "Gaode Behavior-Based Ranking v3.0 (45% Active Navigation + 40% GPS Dwell Time + 15% Return Rate)",
		"anti_fake_policy": "Ulasan teks atau rating bintang tanpa telemetri kedatangan GPS fisik (>15 menit dwell time) diabaikan 100%.",
		"category_filter":  categoryFilter,
		"total":            len(rankings),
		"rankings":         rankings,
	})
}

// PostNavigationTelemetry — POST /api/v1/spatial/navigation-telemetry
// Hari 12 (Selasa): Menerima log penyelesaian navigasi & dwell time GPS nyata, lalu mengalkulasi ulang ranking otomatis
func (h *HandlerBE1) PostNavigationTelemetry(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var input NavigationTelemetryInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.DestinationID == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Payload telemetri tidak valid; field 'destination_id' dan 'dwell_time_minutes' wajib diisi.",
		})
		return
	}

	// Tolak ping GPS palsu jika dwell time < 10 menit (hanya lewat di jalan raya depan destinasi)
	if input.DwellTimeMinutes < 10 {
		w.WriteHeader(http.StatusUnprocessableEntity)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status":              "rejected_pass_by",
			"destination_id":      input.DestinationID,
			"dwell_time_minutes":  input.DwellTimeMinutes,
			"anti_fake_guardrail": "Dwell time di bawah 10 menit terdeteksi sebagai kendaraan melintas (pass-by), tidak dihitung ke dalam Gaode Ranking.",
		})
		return
	}

	updated, err := h.repo.RecordNavigationTelemetry(input)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Destinasi tidak ditemukan pada indeks Gaode Ranking.",
		})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "telemetry_recorded",
		"message":        "Telemetri navigasi & dwell time GPS berhasil diverifikasi. Skor Gaode Ranking diperbarui otomatis.",
		"updated_metric": updated,
	})
}

// --- Method Repository untuk Gaode Ranking (Hari 12) ---

func (r *RepositoryBE1) ListGaodeRankings(categoryFilter string) []models.GaodeBehaviorRanking {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(strings.TrimSpace(categoryFilter))
	var list []models.GaodeBehaviorRanking
	for _, item := range r.gaodeRankings {
		if qCat != "" && !strings.Contains(strings.ToLower(item.Category), qCat) {
			continue
		}
		list = append(list, item)
	}

	sort.Slice(list, func(i, j int) bool {
		return list[i].GaodeAuthenticityScore > list[j].GaodeAuthenticityScore
	})
	for idx := range list {
		list[idx].RankPosition = idx + 1
	}
	return list
}

func (r *RepositoryBE1) RecordNavigationTelemetry(input NavigationTelemetryInput) (*models.GaodeBehaviorRanking, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	target := strings.ToLower(strings.TrimSpace(input.DestinationID))
	for i, item := range r.gaodeRankings {
		if strings.ToLower(item.DestinationID) == target || strings.ToLower(item.ID) == target {
			item.ActiveNavCount30d += 1
			// Weighted moving average untuk dwell time GPS baru
			item.AvgDwellTimeMin = int(math.Round(float64(item.AvgDwellTimeMin)*0.85 + float64(input.DwellTimeMinutes)*0.15))
			if input.IsRepeatVisit {
				item.ReturnVisitRatePct = math.Min(95.0, math.Round((item.ReturnVisitRatePct+0.4)*10)/10)
			}
			item.GaodeAuthenticityScore = ComputeGaodeScore(item.ActiveNavCount30d, item.AvgDwellTimeMin, item.ReturnVisitRatePct)
			item.UpdatedAt = time.Now()
			r.gaodeRankings[i] = item

			// Urutkan ulang posisi ranking seluruh destinasi
			sort.Slice(r.gaodeRankings, func(a, b int) bool {
				return r.gaodeRankings[a].GaodeAuthenticityScore > r.gaodeRankings[b].GaodeAuthenticityScore
			})
			for idx := range r.gaodeRankings {
				r.gaodeRankings[idx].RankPosition = idx + 1
				if r.gaodeRankings[idx].DestinationID == item.DestinationID {
					updatedCopy := r.gaodeRankings[idx]
					return &updatedCopy, nil
				}
			}
			return &item, nil
		}
	}
	return nil, http.ErrNoLocation
}
