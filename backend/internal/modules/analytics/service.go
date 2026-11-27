package analytics

import (
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis ringkasan eksekutif analitik Dispar Sumbar
type Service interface {
	GetDisparAnalyticsSummary() (models.DisparAnalyticsSummary, error)
}

type service struct {
	repo Repository
}

// NewService membuat instance service analitik baru
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) GetDisparAnalyticsSummary() (models.DisparAnalyticsSummary, error) {
	return s.repo.GetSummary()
}

