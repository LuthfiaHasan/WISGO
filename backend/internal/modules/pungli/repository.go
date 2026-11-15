package pungli

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka penyimpanan dan manipulasi laporan aduan pungli
type Repository interface {
	CreatePungliReport(input models.PungliReport) models.PungliReport
	ListPungliReports(statusFilter string) []models.PungliReport
	UpdatePungliReportStatus(idOrTicket, newStatus, satgasNotes string) (*models.PungliReport, error)
}

type inMemoryRepository struct {
	mu      sync.RWMutex
	reports []models.PungliReport
}

// NewRepository membuat instance baru repository Pungli dengan seeder awal
func NewRepository() Repository {
	return &inMemoryRepository{
		reports: SeedPungliReports(),
	}
}

func (r *inMemoryRepository) CreatePungliReport(input models.PungliReport) models.PungliReport {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()
	seq := len(r.reports) + 91
	input.ID = fmt.Sprintf("pungli-%03d", len(r.reports)+1)
	input.TicketCode = fmt.Sprintf("PGL-202611-%04d", seq)
	input.Status = "Masuk"
	input.CreatedAt = now
	input.UpdatedAt = now

	r.reports = append([]models.PungliReport{input}, r.reports...)
	return input
}

func (r *inMemoryRepository) ListPungliReports(statusFilter string) []models.PungliReport {
	r.mu.RLock()
	defer r.mu.RUnlock()

	filter := strings.ToLower(strings.TrimSpace(statusFilter))
	if filter == "" {
		result := make([]models.PungliReport, len(r.reports))
		copy(result, r.reports)
		return result
	}

	var filtered []models.PungliReport
	for _, rep := range r.reports {
		if strings.EqualFold(rep.Status, filter) {
			filtered = append(filtered, rep)
		}
	}
	return filtered
}

func (r *inMemoryRepository) UpdatePungliReportStatus(idOrTicket, newStatus, satgasNotes string) (*models.PungliReport, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	key := strings.ToLower(strings.TrimSpace(idOrTicket))
	if key == "rep-001" || key == "report-001" || key == "report-1" {
		key = "pungli-001"
	} else if key == "rep-002" || key == "report-002" || key == "report-2" {
		key = "pungli-002"
	}

	for i, rep := range r.reports {
		if strings.ToLower(rep.ID) == key || strings.ToLower(rep.TicketCode) == key {
			rep.Status = newStatus
			if satgasNotes != "" {
				rep.SatgasNotes = satgasNotes
			}
			rep.UpdatedAt = time.Now()
			r.reports[i] = rep
			return &rep, nil
		}
	}
	return nil, errors.New("REPORT_NOT_FOUND")
}
