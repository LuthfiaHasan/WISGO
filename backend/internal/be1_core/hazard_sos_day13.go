package be1_core

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// TriggerHazardInput payload simulasi trigger bencana dari Panel Command Center FS-1
type TriggerHazardInput struct {
	CorridorCode     string `json:"corridor_code"` // SITINJAU-LAUIK, LEMBAH-ANAI, KELOK-9, KELOK-44
	Severity         string `json:"severity"`      // Normal, Waspada, Siaga, Awas Tutup Total
	HazardType       string `json:"hazard_type"`
	WeatherStatus    string `json:"weather_status"`
	Message          string `json:"message"`
	DetourRoute      string `json:"detour_route"`
	TriggeredByAdmin string `json:"triggered_by_admin"`
}

// SOSEmergencyInput payload pancaran darurat SOS GPS dari wisatawan (FE-1)
type SOSEmergencyInput struct {
	TouristName     string  `json:"tourist_name"`
	PhoneNumber     string  `json:"phone_number"`
	EmergencyType   string  `json:"emergency_type"`
	Latitude        float64 `json:"latitude"`
	Longitude       float64 `json:"longitude"`
	BatteryPercent  int     `json:"battery_percent"`
	PassengersCount int     `json:"passengers_count"`
	Notes           string  `json:"notes"`
}

// GetLiveHazardAlerts — GET /api/v1/spatial/hazards
// Hari 13 (Rabu): Mengembalikan status koridor jalur ekstrem (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44)
// serta memeriksa apakah koordinat GPS pengguna berada di dekat zona bahaya (ST_DWithin)
func (h *HandlerBE1) GetLiveHazardAlerts(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	severityFilter := strings.TrimSpace(r.URL.Query().Get("severity"))
	corridorFilter := strings.TrimSpace(r.URL.Query().Get("corridor"))
	hasGPS, userLat, userLng := parseGPSQuery(r)

	hazards := h.repo.ListHazardAlerts(severityFilter, corridorFilter)

	var intersectingBanner *models.HazardAlert
	if hasGPS {
		for i := range hazards {
			distKm := CalculateSpatialDistanceKm(userLat, userLng, hazards[i].Latitude, hazards[i].Longitude)
			if distKm*1000.0 <= float64(hazards[i].RadiusMeter)*1.5 {
				alertCopy := hazards[i]
				intersectingBanner = &alertCopy
				break
			}
		}
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":                    "ok",
		"monitored_corridors_count": len(hazards),
		"user_in_hazard_zone":       intersectingBanner != nil,
		"fe1_active_warning_banner": intersectingBanner,
		"hazards":                   hazards,
	})
}

// PostTriggerHazardAdmin — POST /api/v1/admin/hazards/trigger
// Hari 13 (Rabu — Sinkronisasi Panel Trigger Bencana FS-1 & Banner Peringatan FE-1)
func (h *HandlerBE1) PostTriggerHazardAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var input TriggerHazardInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || input.CorridorCode == "" || input.Severity == "" {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Field 'corridor_code' (misal: SITINJAU-LAUIK) dan 'severity' (Normal/Waspada/Siaga/Awas Tutup Total) wajib diisi.",
		})
		return
	}

	updated, err := h.repo.TriggerHazardCorridor(input)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": fmt.Sprintf("Koridor jalur ekstrem '%s' tidak ditemukan.", input.CorridorCode),
		})
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":        "hazard_triggered",
		"broadcast_target": "FE-1 Banner Peringatan Jalur Rawan & Rute Pengalihan Otomatis",
		"hazard_alert":  updated,
	})
}

// PostSOSEmergencySignal — POST /api/v1/spatial/sos
// Hari 13 (Rabu): Pancaran sinyal darurat SOS GPS dari FE-1 ke Posko SAR / Pokdarwis terdekat
func (h *HandlerBE1) PostSOSEmergencySignal(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var input SOSEmergencyInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil || (input.Latitude == 0 && input.Longitude == 0) {
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": "Koordinat GPS ('latitude' & 'longitude') wajib disertakan saat memancarkan sinyal darurat SOS.",
		})
		return
	}

	created := h.repo.CreateSOSSignal(input)
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":              "sos_dispatched",
		"message":             fmt.Sprintf("Sinyal darurat %s diterima oleh %s. Estimasi tiba %d menit.", created.SOSCode, created.NearestRescuePost, created.ETARescueMinutes),
		"sos_signal":          created,
		"survival_instruction": "Tetap berada di titik aman di luar badan jalan tikungan, nyalakan lampu hazard, dan hemat baterai ponsel Anda.",
	})
}

// GetSOSSignalsAdmin — GET /api/v1/admin/sos
// Hari 13 (Rabu): Monitoring antrean sinyal SOS GPS pada Command Center FS-1
func (h *HandlerBE1) GetSOSSignalsAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	signals := h.repo.ListSOSSignals()
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "ok",
		"total_sos":   len(signals),
		"sos_signals": signals,
	})
}

// --- Method Repository untuk Hazard Alert & SOS GPS (Hari 13) ---

func (r *RepositoryBE1) ListHazardAlerts(severityFilter, corridorFilter string) []models.HazardAlert {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qSev := strings.ToLower(strings.TrimSpace(severityFilter))
	qCor := strings.ToLower(strings.TrimSpace(corridorFilter))

	var list []models.HazardAlert
	for _, h := range r.hazardAlerts {
		if qSev != "" && !strings.Contains(strings.ToLower(h.Severity), qSev) {
			continue
		}
		if qCor != "" && !strings.Contains(strings.ToLower(h.CorridorCode), qCor) && !strings.Contains(strings.ToLower(h.Location), qCor) {
			continue
		}
		list = append(list, h)
	}
	return list
}

func (r *RepositoryBE1) TriggerHazardCorridor(input TriggerHazardInput) (*models.HazardAlert, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	target := strings.ToLower(strings.TrimSpace(input.CorridorCode))
	for i, h := range r.hazardAlerts {
		if strings.ToLower(h.CorridorCode) == target || strings.ToLower(h.ID) == target {
			h.Severity = input.Severity
			if input.HazardType != "" {
				h.HazardType = input.HazardType
			}
			if input.WeatherStatus != "" {
				h.WeatherStatus = input.WeatherStatus
			}
			if input.Message != "" {
				h.Message = input.Message
			}
			if input.DetourRoute != "" {
				h.DetourRoute = input.DetourRoute
			}
			if input.TriggeredByAdmin != "" {
				h.TriggeredByAdmin = input.TriggeredByAdmin
			} else {
				h.TriggeredByAdmin = "Panel Trigger Bencana FS-1 (Admin Dispar)"
			}
			h.UpdatedAt = time.Now()
			r.hazardAlerts[i] = h
			return &h, nil
		}
	}
	return nil, http.ErrNoLocation
}

func (r *RepositoryBE1) CreateSOSSignal(input SOSEmergencyInput) models.SOSSignal {
	r.mu.Lock()
	defer r.mu.Unlock()

	if input.TouristName == "" {
		input.TouristName = "Wisatawan Darurat Rancak.in"
	}
	if input.EmergencyType == "" {
		input.EmergencyType = "Kendaraan Mogok / Darurat di Jalur Ekstrem"
	}
	if input.BatteryPercent <= 0 {
		input.BatteryPercent = 35
	}
	if input.PassengersCount <= 0 {
		input.PassengersCount = 2
	}

	// Cari koridor & Posko SAR terdekat berdasarkan kalkulasi jarak spasial
	nearestCorridor := "Koridor Sitinjau Lauik"
	nearestPost := "Posko Terpadu PKJR & BPBD Panorama 1 Sitinjau Lauik"
	minDistKm := 9999.0

	for _, hz := range r.hazardAlerts {
		d := CalculateSpatialDistanceKm(input.Latitude, input.Longitude, hz.Latitude, hz.Longitude)
		if d < minDistKm {
			minDistKm = d
			nearestCorridor = hz.Location
			nearestPost = hz.NearestRescuePost
		}
	}
	if minDistKm > 50 {
		minDistKm = 2.4
	}
	etaMin := int(math.Max(5, math.Round(minDistKm*4.5)))

	seq := len(r.sosSignals) + 1
	signal := models.SOSSignal{
		ID:                 fmt.Sprintf("sos-%03d", seq),
		SOSCode:            fmt.Sprintf("SOS-SUMBAR-202611-%03d", seq),
		TouristName:        input.TouristName,
		PhoneNumber:        input.PhoneNumber,
		EmergencyType:      input.EmergencyType,
		Latitude:           input.Latitude,
		Longitude:          input.Longitude,
		BatteryPercent:     input.BatteryPercent,
		PassengersCount:    input.PassengersCount,
		NearestCorridor:    nearestCorridor,
		NearestRescuePost:  nearestPost,
		DistanceToRescueKm: math.Round(minDistKm*10) / 10,
		ETARescueMinutes:   etaMin,
		Status:             "Dipancarkan",
		Notes:              input.Notes,
		CreatedAt:          time.Now(),
	}

	r.sosSignals = append([]models.SOSSignal{signal}, r.sosSignals...)
	return signal
}

func (r *RepositoryBE1) ListSOSSignals() []models.SOSSignal {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.sosSignals
}
