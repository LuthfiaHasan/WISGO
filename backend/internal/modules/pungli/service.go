package pungli

import (
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/scenes360"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/spatial"
)

// Service antarmuka logika bisnis Smart QR dan Satgas Saber Pungli
type Service interface {
	ResolveSmartQR(qrCode string) (*SmartQRResolutionResponse, error)
	SubmitPungliReport(req CreatePungliReportRequest, uploadFormat string) (*CreatePungliReportResponse, error)
	GetPungliReports(statusFilter string) []models.PungliReport
	UpdateReportStatus(idOrTicket string, req UpdatePungliStatusRequest) (*UpdatePungliStatusResponse, error)
}

type service struct {
	repo        Repository
	destRepo    destination.Repository
	scenesRepo  scenes360.Repository
	spatialRepo spatial.Repository
}

// NewService membuat instance Service baru untuk modul pungli
func NewService(repo Repository, destRepo destination.Repository, scenesRepo scenes360.Repository, spatialRepo spatial.Repository) Service {
	return &service{
		repo:        repo,
		destRepo:    destRepo,
		scenesRepo:  scenesRepo,
		spatialRepo: spatialRepo,
	}
}

func (s *service) ResolveSmartQR(qrCode string) (*SmartQRResolutionResponse, error) {
	dest, err := s.destRepo.FindByID(qrCode, false, 0, 0)
	if err != nil {
		return nil, errors.New("QR_PLACARD_NOT_FOUND")
	}

	scenes := s.scenesRepo.GetScenes360ByDestinationID(dest.ID, dest.Name, dest.CityRegency)
	microMap := s.spatialRepo.GetMicroMapByDestinationID(dest.ID, dest.Name, dest.Latitude, dest.Longitude)

	return &SmartQRResolutionResponse{
		Status:             "resolved",
		QRPlacardCode:      dest.QRPlacardCode,
		InstantWebPreview:  fmt.Sprintf("https://rancak.in/qr/%s", dest.QRPlacardCode),
		FairPriceVerified:  true,
		Destination:        dest,
		Scenes360:          scenes,
		MicroMap:           microMap,
	}, nil
}

func (s *service) SubmitPungliReport(req CreatePungliReportRequest, uploadFormat string) (*CreatePungliReportResponse, error) {
	if strings.TrimSpace(req.DestinationID) == "" {
		req.DestinationID = "dest-003"
	}
	if strings.TrimSpace(req.ReporterName) == "" {
		req.ReporterName = "Wisatawan Anonim"
	}
	if strings.TrimSpace(req.IncidentCategory) == "" {
		req.IncidentCategory = "parkir_liar"
	}
	if strings.TrimSpace(req.PhotoEvidence) == "" {
		req.PhotoEvidence = "https://cdn.rancak.in/evidence/foto-bukti-lapangan.jpg"
	}
	if strings.TrimSpace(req.Description) == "" {
		req.Description = "Tagihan parkir/tiket di lapangan melebihi ketentuan Tabel Fair-Price Barometer Perda."
	}

	destName := req.DestinationID
	officialPrice := 5000.0

	dest, err := s.destRepo.FindByID(req.DestinationID, false, 0, 0)
	if err == nil {
		destName = dest.Name
		req.DestinationID = dest.ID
		if req.Latitude == 0 && req.Longitude == 0 {
			req.Latitude = dest.Latitude
			req.Longitude = dest.Longitude
		}
		if len(dest.Tariffs) > 0 {
			officialPrice = dest.Tariffs[0].Price
			for _, t := range dest.Tariffs {
				if strings.Contains(strings.ToLower(req.IncidentCategory), "parkir") && strings.Contains(strings.ToLower(t.ItemName), "mobil") {
					officialPrice = t.Price
					break
				}
			}
		}
	}

	overcharge := 0.0
	if req.ChargedAmountIDR > officialPrice {
		overcharge = req.ChargedAmountIDR - officialPrice
	}

	created := s.repo.CreatePungliReport(models.PungliReport{
		DestinationID:         req.DestinationID,
		DestinationName:       destName,
		ReporterName:          req.ReporterName,
		IncidentCategory:      req.IncidentCategory,
		ChargedAmountIDR:      req.ChargedAmountIDR,
		OfficialPerdaPriceIDR: officialPrice,
		OverchargeAmountIDR:   overcharge,
		PhotoEvidence:         req.PhotoEvidence,
		UploadFormat:          uploadFormat,
		Latitude:              req.Latitude,
		Longitude:             req.Longitude,
		Description:           req.Description,
	})

	return &CreatePungliReportResponse{
		Status:  "success",
		Ticket:  created.TicketCode,
		Message: "Laporan berhasil diteruskan ke Satgas Saber Pungli Dispar Sumbar",
		Report:  created,
	}, nil
}

func (s *service) GetPungliReports(statusFilter string) []models.PungliReport {
	return s.repo.ListPungliReports(statusFilter)
}

func (s *service) UpdateReportStatus(idOrTicket string, req UpdatePungliStatusRequest) (*UpdatePungliStatusResponse, error) {
	if strings.TrimSpace(req.Status) == "" {
		return nil, errors.New("INVALID_STATUS_PAYLOAD")
	}

	updated, err := s.repo.UpdatePungliReportStatus(idOrTicket, req.Status, req.SatgasNotes)
	if err != nil {
		return nil, errors.New("REPORT_NOT_FOUND")
	}

	ratio := math.Round((updated.OverchargeAmountIDR / math.Max(1, updated.OfficialPerdaPriceIDR)) * 100)

	return &UpdatePungliStatusResponse{
		Status:          "updated",
		UpdatedAt:       time.Now().Format(time.RFC3339),
		Report:          updated,
		OverchargeRatio: ratio,
	}, nil
}
