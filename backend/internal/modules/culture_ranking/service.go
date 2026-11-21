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
	// Input Event (Vendor / Wisatawan) & CRUD Event (Admin Dispar)
	CreateEvent(req CreateCulturalEventRequest, creatorID string, creatorRole string) (*models.CulturalEvent, error)
	UpdateEvent(id string, req CreateCulturalEventRequest) (*models.CulturalEvent, error)
	DeleteEvent(id string) error
	GetEventByID(id string) (*models.CulturalEvent, error)
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

func (s *service) CreateEvent(req CreateCulturalEventRequest, creatorID string, creatorRole string) (*models.CulturalEvent, error) {
	title := strings.TrimSpace(req.Title)
	if title == "" {
		title = strings.TrimSpace(req.EventName)
	}
	if title == "" {
		return nil, errors.New("Field 'title' atau 'event_name' wajib diisi untuk menginput event budaya.")
	}

	nagari := strings.TrimSpace(req.NagariLocation)
	if nagari == "" {
		nagari = strings.TrimSpace(req.EventLocation)
	}
	if nagari == "" {
		nagari = "Sumatera Barat"
	}

	evType := strings.TrimSpace(req.EventType)
	if evType == "" {
		evType = "Festival Budaya"
	}

	city := strings.TrimSpace(req.CityRegency)
	if city == "" {
		city = "Sumatera Barat"
	}

	userID := creatorID
	if userID == "" {
		userID = req.UserID
		if userID == "" {
			if creatorRole == "vendor" {
				userID = "user-vendor-01"
			} else {
				userID = "usr-001"
			}
		}
	}

	newEvent := models.CulturalEvent{
		UserID:            userID,
		Title:             title,
		EventName:         title,
		EventType:         evType,
		NagariLocation:    nagari,
		EventLocation:     nagari,
		CityRegency:       city,
		ScheduleRule:      req.ScheduleRule,
		NextEventDate:     req.NextEventDate,
		Latitude:          req.Latitude,
		Longitude:         req.Longitude,
		HighlightItem:     req.HighlightItem,
		Significance:      req.Significance,
		CulturalEtiquette: req.CulturalEtiquette,
	}

	return s.repo.CreateCulturalEvent(newEvent)
}

func (s *service) UpdateEvent(id string, req CreateCulturalEventRequest) (*models.CulturalEvent, error) {
	existing, found := s.repo.FindCulturalEventByID(id)
	if !found {
		return nil, errors.New("Event budaya tidak ditemukan")
	}

	title := strings.TrimSpace(req.Title)
	if title == "" {
		title = strings.TrimSpace(req.EventName)
	}
	if title != "" {
		existing.Title = title
		existing.EventName = title
	}
	if req.EventType != "" {
		existing.EventType = req.EventType
	}
	if req.NagariLocation != "" {
		existing.NagariLocation = req.NagariLocation
		existing.EventLocation = req.NagariLocation
	} else if req.EventLocation != "" {
		existing.NagariLocation = req.EventLocation
		existing.EventLocation = req.EventLocation
	}
	if req.CityRegency != "" {
		existing.CityRegency = req.CityRegency
	}
	if req.ScheduleRule != "" {
		existing.ScheduleRule = req.ScheduleRule
	}
	if req.NextEventDate != "" {
		existing.NextEventDate = req.NextEventDate
	}
	if req.Latitude != 0 {
		existing.Latitude = req.Latitude
	}
	if req.Longitude != 0 {
		existing.Longitude = req.Longitude
	}
	if req.HighlightItem != "" {
		existing.HighlightItem = req.HighlightItem
	}
	if req.Significance != "" {
		existing.Significance = req.Significance
	}
	if req.CulturalEtiquette != "" {
		existing.CulturalEtiquette = req.CulturalEtiquette
	}

	return s.repo.UpdateCulturalEvent(id, *existing)
}

func (s *service) DeleteEvent(id string) error {
	return s.repo.DeleteCulturalEvent(id)
}

func (s *service) GetEventByID(id string) (*models.CulturalEvent, error) {
	ev, found := s.repo.FindCulturalEventByID(id)
	if !found {
		return nil, errors.New("Event budaya tidak ditemukan")
	}
	return ev, nil
}
