package be1_core

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// GetMinangAudioPhrases — GET /api/v1/culture/minang-phrases
// Hari 14 (Kamis): Kamus Saku Audio Bahasa Minang sehari-hari + Adab Kato Nan Ampek (Pilar 1 — P1.4)
func (h *HandlerBE1) GetMinangAudioPhrases(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	category := strings.TrimSpace(r.URL.Query().Get("category"))
	searchQuery := strings.TrimSpace(r.URL.Query().Get("q"))

	phrases := h.repo.ListMinangPhrases(category, searchQuery)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "ok",
		"design_token":   "--indigo-500 (#5B6AE8) · Lencana Budaya & Nagari",
		"cultural_guide": "Gunakan prinsip Kato Nan Ampek (Kato Mandaki kepada yang tua, Kato Mendatar kepada sebaya, Kato Malereang saat berbasa-basi sopan di Nagari).",
		"total":          len(phrases),
		"phrases":        phrases,
	})
}

// GetCulturalEventsCalendar — GET /api/v1/culture/events
// Hari 14 (Kamis): Kalender Budaya Sumatera Barat & Jadwal Hari Pakan (Pasar Tradisional Nagari)
func (h *HandlerBE1) GetCulturalEventsCalendar(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	eventType := strings.TrimSpace(r.URL.Query().Get("type"))
	cityFilter := strings.TrimSpace(r.URL.Query().Get("city_regency"))
	hasGPS, userLat, userLng := parseGPSQuery(r)

	events := h.repo.ListCulturalEvents(eventType, cityFilter, hasGPS, userLat, userLng)

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":       "ok",
		"design_token": "--indigo-500 (#5B6AE8) · Kalender Budaya & Hari Pakan Nagari",
		"total":        len(events),
		"events":       events,
	})
}

// --- Method Repository untuk Kamus Saku Audio Minang & Kalender Budaya (Hari 14) ---

func (r *RepositoryBE1) ListMinangPhrases(category, searchQuery string) []models.MinangPhrase {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qCat := strings.ToLower(category)
	qSearch := strings.ToLower(searchQuery)

	var list []models.MinangPhrase
	for _, p := range r.minangPhrases {
		if qCat != "" && !strings.Contains(strings.ToLower(p.Category), qCat) {
			continue
		}
		if qSearch != "" {
			matched := strings.Contains(strings.ToLower(p.IndonesianText), qSearch) ||
				strings.Contains(strings.ToLower(p.MinangText), qSearch) ||
				strings.Contains(strings.ToLower(p.UsageContextTip), qSearch)
			if !matched {
				continue
			}
		}
		list = append(list, p)
	}
	return list
}

func (r *RepositoryBE1) ListCulturalEvents(eventType, cityFilter string, hasGPS bool, userLat, userLng float64) []models.CulturalEvent {
	r.mu.RLock()
	defer r.mu.RUnlock()

	qType := strings.ToLower(eventType)
	qCity := strings.ToLower(cityFilter)

	var list []models.CulturalEvent
	for _, ev := range r.culturalEvents {
		if qType != "" && !strings.Contains(strings.ToLower(ev.EventType), qType) {
			continue
		}
		if qCity != "" && !strings.Contains(strings.ToLower(ev.CityRegency), qCity) && !strings.Contains(strings.ToLower(ev.NagariLocation), qCity) {
			continue
		}
		item := ev
		if hasGPS {
			item.DistanceKm = CalculateSpatialDistanceKm(userLat, userLng, ev.Latitude, ev.Longitude)
		} else {
			item.DistanceKm = CalculateSpatialDistanceKm(-0.9471, 100.4172, ev.Latitude, ev.Longitude)
		}
		list = append(list, item)
	}
	return list
}
