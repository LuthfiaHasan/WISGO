package community

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis tempat komunitas dan shared trips
type Service interface {
	CreateCommunityPlace(req CreateCommunityPlaceRequest) (*CreateCommunityPlaceResponse, error)
	GetCommunityPlaces() ([]models.CommunityPlace, error)
	CreateSharedTrip(req CreateSharedTripRequest) (*models.SharedTrip, error)
	GetSharedTrips() ([]models.SharedTrip, error)
}

type service struct {
	repo Repository
}

// NewService membuat instance service baru
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) CreateCommunityPlace(req CreateCommunityPlaceRequest) (*CreateCommunityPlaceResponse, error) {
	if strings.TrimSpace(req.Name) == "" {
		return nil, errors.New("Payload tidak valid: nama tempat wajib diisi")
	}

	// PRD P6.1: Field tips_menjaga adalah MANDATORY untuk kelestarian alam hidden gem
	if strings.TrimSpace(req.TipsMenjaga) == "" {
		return nil, errors.New("Aturan PRD P6.1: Field 'tips_menjaga' wajib diisi demi kelestarian alam Ranah Minang")
	}

	userID := req.UserID
	if userID == "" {
		userID = "usr-001"
	}

	finalLat := req.Latitude
	finalLng := req.Longitude
	maskingApplied := false

	// Masking koordinat perkiraan (~800m) jika lokasi ditandai sensitif / terpencil
	if req.IsSensitive {
		maskingApplied = true
		finalLat += 0.0075 // Jitter latitude ~800m
		finalLng += 0.0075
	}

	newPlace := models.CommunityPlace{
		ID:          fmt.Sprintf("cp-%d", time.Now().UnixNano()%100000),
		UserID:      userID,
		Name:        req.Name,
		Category:    req.Category,
		CityRegency: req.CityRegency,
		Description: req.Description,
		Latitude:    finalLat,
		Longitude:   finalLng,
		TipsMenjaga: req.TipsMenjaga,
		IsSensitive: req.IsSensitive,
		Status:      "PENDING_CURATION", // Wajib dikurasi Pokdarwis sebelum publik
		CreatedAt:   time.Now(),
	}

	if err := s.repo.SaveCommunityPlace(newPlace); err != nil {
		return nil, err
	}

	note := ""
	if maskingApplied {
		note = "Koordinat telah disamarkan sementara untuk perlindungan lingkungan"
	}

	return &CreateCommunityPlaceResponse{
		Place:          newPlace,
		MaskingApplied: maskingApplied,
		Note:           note,
	}, nil
}

func (s *service) GetCommunityPlaces() ([]models.CommunityPlace, error) {
	return s.repo.GetCommunityPlaces(), nil
}

func (s *service) CreateSharedTrip(req CreateSharedTripRequest) (*models.SharedTrip, error) {
	if strings.TrimSpace(req.Title) == "" || strings.TrimSpace(req.DestinationRoute) == "" {
		return nil, errors.New("Payload tidak valid: title dan destination_route wajib diisi")
	}

	userID := req.UserID
	if userID == "" {
		userID = "usr-001"
	}

	seats := req.AvailableSeats
	if seats <= 0 {
		seats = 1
	}

	var depDate time.Time
	if req.DepartureDate != "" {
		parsedDate, err := time.Parse(time.RFC3339, req.DepartureDate)
		if err != nil {
			parsedDate, err = time.Parse("2006-01-02", req.DepartureDate)
		}
		if err == nil {
			depDate = parsedDate
		} else {
			depDate = time.Now().Add(24 * time.Hour)
		}
	} else {
		depDate = time.Now().Add(24 * time.Hour)
	}

	newTrip := models.SharedTrip{
		ID:               fmt.Sprintf("st-%d", time.Now().UnixNano()%100000),
		UserID:           userID,
		Title:            req.Title,
		DestinationRoute: req.DestinationRoute,
		DepartureDate:    depDate,
		AvailableSeats:   seats,
		CostPerPerson:    req.CostPerPerson,
		ContactWA:        req.ContactWA,
		CreatedAt:        time.Now(),
	}

	if err := s.repo.SaveSharedTrip(newTrip); err != nil {
		return nil, err
	}

	return &newTrip, nil
}

func (s *service) GetSharedTrips() ([]models.SharedTrip, error) {
	return s.repo.GetSharedTrips(), nil
}

