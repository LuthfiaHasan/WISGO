package culture_ranking

import (
	"errors"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis modul culture & ranking
type Service interface {
	GetGaodeRankings(categoryFilter string) *GaodeRankingsResponse
	GetMinangPhrases(category, searchQuery string) *MinangPhrasesResponse
	GetCulturalEvents(eventType, cityFilter string, hasGPS bool, userLat, userLng float64) *CulturalEventsResponse
	RecordTelemetry(destinationID string, dwellTimeMinutes int, isRepeatVisit bool) (*models.GaodeBehaviorRanking, error)
}

type service struct {
	repo Repository
}

// NewService membuat instance Service baru untuk modul culture_ranking
func NewService(repo Repository) Service {
	return &service{
		repo: repo,
	}
}

func (s *service) GetGaodeRankings(categoryFilter string) *GaodeRankingsResponse {
	rankings := s.repo.ListGaodeRankings(categoryFilter)

	return &GaodeRankingsResponse{
		Status:         "ok",
		Algorithm:      "Gaode Behavior-Based Ranking v3.0 (45% Active Navigation + 40% GPS Dwell Time + 15% Return Rate)",
		AntiFakePolicy: "Ulasan teks atau rating bintang tanpa telemetri kedatangan GPS fisik (>15 menit dwell time) diabaikan 100%.",
		CategoryFilter: categoryFilter,
		Total:          len(rankings),
		Rankings:       rankings,
	}
}

func (s *service) GetMinangPhrases(category, searchQuery string) *MinangPhrasesResponse {
	phrases := s.repo.ListMinangPhrases(category, searchQuery)

	return &MinangPhrasesResponse{
		Status:        "ok",
		DesignToken:   "--indigo-500 (#5B6AE8) · Lencana Budaya & Nagari",
		CulturalGuide: "Gunakan prinsip Kato Nan Ampek (Kato Mandaki kepada yang tua, Kato Mendatar kepada sebaya, Kato Malereang saat berbasa-basi sopan di Nagari).",
		Total:         len(phrases),
		Phrases:       phrases,
	}
}

func (s *service) GetCulturalEvents(eventType, cityFilter string, hasGPS bool, userLat, userLng float64) *CulturalEventsResponse {
	events := s.repo.ListCulturalEvents(eventType, cityFilter, hasGPS, userLat, userLng)

	return &CulturalEventsResponse{
		Status:      "ok",
		DesignToken: "--indigo-500 (#5B6AE8) · Kalender Budaya & Hari Pakan Nagari",
		Total:       len(events),
		Events:      events,
	}
}

func (s *service) RecordTelemetry(destinationID string, dwellTimeMinutes int, isRepeatVisit bool) (*models.GaodeBehaviorRanking, error) {
	if strings.TrimSpace(destinationID) == "" {
		return nil, errors.New("MISSING_DESTINATION_ID")
	}
	if dwellTimeMinutes < 10 {
		return nil, errors.New("REJECTED_PASS_BY")
	}
	return s.repo.RecordNavigationTelemetry(destinationID, dwellTimeMinutes, isRepeatVisit)
}
