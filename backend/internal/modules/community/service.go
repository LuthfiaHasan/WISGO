package community

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// DestinationLookup antarmuka read-only minimal untuk mencocokkan destinasi BE-1 (dipenuhi destination.Repository)
type DestinationLookup interface {
	FindByID(idOrSlugOrQR string, hasUserGPS bool, userLat, userLng float64) (*models.Destination, error)
}

// Service antarmuka logika bisnis tempat komunitas dan shared trips
type Service interface {
	CreateCommunityPlace(req CreateCommunityPlaceRequest) (*CreateCommunityPlaceResponse, error)
	GetCommunityPlaces() ([]models.CommunityPlace, error)
	CreateSharedTrip(req CreateSharedTripRequest) (*models.SharedTrip, error)
	GetSharedTrips() ([]models.SharedTrip, error)
	JoinSharedTrip(id, userID string) (*models.SharedTrip, error)
	DeleteSharedTrip(id, userID string) error
}

type service struct {
	repo       Repository
	destLookup DestinationLookup
}

// NewService membuat instance service baru (backward compatible tanpa lookup destinasi BE-1)
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

// NewServiceWithDestinations membuat instance service dengan lookup read-only ke katalog destinasi BE-1
func NewServiceWithDestinations(repo Repository, destLookup DestinationLookup) Service {
	return &service{
		repo:       repo,
		destLookup: destLookup,
	}
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
	title := strings.TrimSpace(req.Title)
	destID := strings.TrimSpace(req.DestinationID)
	destRoute := strings.TrimSpace(req.DestinationRoute)
	category := strings.TrimSpace(req.Category)

	if title == "" {
		return nil, errors.New("Payload tidak valid: title wajib diisi")
	}
	if destID == "" && destRoute == "" {
		return nil, errors.New("Payload tidak valid: destination_id atau destination_route wajib diisi")
	}

	// Kunci 1 destinasi dari katalog BE-1 dan isi kategori + rute otomatis bila destination_id dikirim
	if destID != "" && s.destLookup != nil {
		dest, err := s.destLookup.FindByID(destID, false, 0, 0)
		if err != nil || dest == nil {
			return nil, fmt.Errorf("Destinasi '%s' tidak ditemukan di katalog BE-1", destID)
		}
		destID = dest.ID
		category = dest.Category
		if destRoute == "" {
			destRoute = dest.Name
		}
	}

	userID := strings.TrimSpace(req.UserID)
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
		Title:            title,
		DestinationID:    destID,
		Category:         category,
		DestinationRoute: destRoute,
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

func (s *service) JoinSharedTrip(id, userID string) (*models.SharedTrip, error) {
	tripID := strings.TrimSpace(id)
	uid := strings.TrimSpace(userID)
	if uid == "" {
		return nil, ErrJoinUserIDRequired
	}
	if tripID == "" {
		return nil, ErrSharedTripNotFound
	}
	return s.repo.JoinSharedTrip(tripID, uid)
}

func (s *service) DeleteSharedTrip(id, userID string) error {
	tripID := strings.TrimSpace(id)
	uid := strings.TrimSpace(userID)
	if uid == "" {
		return ErrDeleteUserIDRequired
	}
	if tripID == "" {
		return ErrSharedTripNotFound
	}
	return s.repo.DeleteSharedTrip(tripID, uid)
}

