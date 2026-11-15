package partner

import (
	"errors"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis murni untuk Mitra Nagari Minangkabau (Pilar 5)
type Service interface {
	GetPartners(category string, spicyLevel *int, nagari string) ([]models.PartnerNagari, error)
	GetPartnerDetail(id string) (*models.PartnerNagari, error)
}

type partnerService struct {
	repo Repository
}

// NewService membuat instance baru dari PartnerService
func NewService(repo Repository) Service {
	return &partnerService{repo: repo}
}

func (s *partnerService) GetPartners(category string, spicyLevel *int, nagari string) ([]models.PartnerNagari, error) {
	if spicyLevel != nil && (*spicyLevel < 0 || *spicyLevel > 5) {
		return nil, errors.New("Level pedas harus berada dalam rentang 0 sampai 5")
	}
	return s.repo.FindAll(category, spicyLevel, nagari)
}

func (s *partnerService) GetPartnerDetail(id string) (*models.PartnerNagari, error) {
	if id == "" {
		return nil, errors.New("ID mitra wajib diisi")
	}
	return s.repo.FindByID(id)
}

