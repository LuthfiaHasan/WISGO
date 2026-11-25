package gamification

import (
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// GPSCheckInError error saat jarak GPS melampaui batas maksimal radius validasi 200m
type GPSCheckInError struct {
	Distance float64
	SpotName string
}

func (e *GPSCheckInError) Error() string {
	return fmt.Sprintf("Check-in ditolak (Anti-Fake GPS): Lokasi Anda berjarak %.1f meter dari %s (Maksimal radius valid 200 meter)", e.Distance, e.SpotName)
}

// IneligibleCertificateError error saat stempel belum mencukupi untuk penerbitan sertifikat
type IneligibleCertificateError struct {
	Collected int
	Required  int
}

func (e *IneligibleCertificateError) Error() string {
	return fmt.Sprintf("Sertifikat belum dapat diterbitkan. Anda baru mengumpulkan %d dari %d stempel titik ikonik Minangkabau.", e.Collected, e.Required)
}

// Service antarmuka logika bisnis Paspor Digital Minang, Anti-Fake GPS, dan Sertifikat Gubernur
type Service interface {
	ValidateGPSCheckIn(req CheckInRequest) (*CheckInResponse, error)
	GetDigitalPassport(userID string) (*PassportSummaryResponse, error)
	GenerateGovernorCertificate(req CertificateRequest) (*CertificateResponse, bool, error) // bool isAlreadyIssued
}

type service struct {
	repo Repository
}

// NewService membuat instance service baru
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) ValidateGPSCheckIn(req CheckInRequest) (*CheckInResponse, error) {
	if req.UserID == "" || req.DestinationID == "" {
		return nil, errors.New("user_id dan destination_id wajib diisi")
	}

	// Normalisasi koordinat jika dikirim sebagai user_latitude / user_longitude
	if req.Latitude == 0 && req.UserLatitude != 0 {
		req.Latitude = req.UserLatitude
	}
	if req.Longitude == 0 && req.UserLongitude != 0 {
		req.Longitude = req.UserLongitude
	}

	if req.Latitude == 0 && req.Longitude == 0 {
		return nil, errors.New("koordinat GPS (latitude dan longitude) wajib disertakan")
	}

	targetSpot, exists := s.repo.GetSpotByID(req.DestinationID)
	if !exists {
		return nil, fmt.Errorf("titik destinasi '%s' tidak ditemukan dalam daftar Paspor Digital Minang", req.DestinationID)
	}

	// Hitung jarak Haversine dalam meter
	distance := common.CalculateHaversineDistance(req.Latitude, req.Longitude, targetSpot.Latitude, targetSpot.Longitude)

	// Validasi Anti-Fake GPS (radius <= 200.0m)
	if distance > 200.0 {
		return nil, &GPSCheckInError{
			Distance: distance,
			SpotName: targetSpot.Name,
		}
	}

	now := time.Now()
	s.repo.AddPassportStamp(req.UserID, targetSpot.ID, now)
	userStamps := s.repo.GetUserPassportStamps(req.UserID)
	allSpots := s.repo.GetIconicSpots()

	return &CheckInResponse{
		DestinationID:   targetSpot.ID,
		DestinationName: targetSpot.Name,
		DistanceMeters:  math.Round(distance*10) / 10,
		IsWithinRadius:  true,
		CheckedInAt:     now,
		BadgeEarned:     targetSpot.BadgeName,
		TotalStamps:     len(userStamps),
		MaxStamps:       len(allSpots),
	}, nil
}

func (s *service) GetDigitalPassport(userID string) (*PassportSummaryResponse, error) {
	if userID == "" {
		userID = "usr-001"
	}

	allSpots := s.repo.GetIconicSpots()
	userStamps := s.repo.GetUserPassportStamps(userID)
	totalStamps := len(userStamps)
	totalRequired := len(allSpots)
	if totalRequired == 0 {
		totalRequired = 10
	}

	spots := make([]models.IconicSpotItem, len(allSpots))
	for i, spot := range allSpots {
		item := spot
		if stampTime, ok := userStamps[spot.ID]; ok {
			item.IsCompleted = true
			t := stampTime
			item.CompletedAt = &t
		} else {
			item.IsCompleted = false
			item.CompletedAt = nil
		}
		spots[i] = item
	}

	percent := (float64(totalStamps) / float64(totalRequired)) * 100.0
	if percent > 100.0 {
		percent = 100.0
	}

	return &PassportSummaryResponse{
		UserID:                   userID,
		TotalStamps:              totalStamps,
		RequiredStamps:           totalRequired,
		CompletionPercentage:     math.Round(percent*10) / 10,
		IsEligibleForCertificate: totalStamps >= totalRequired,
		Spots:                    spots,
	}, nil
}

func (s *service) GenerateGovernorCertificate(req CertificateRequest) (*CertificateResponse, bool, error) {
	userID := req.UserID
	if userID == "" {
		userID = "usr-001"
	}

	fullName := strings.TrimSpace(req.FullName)
	if fullName == "" {
		fullName = "Wisatawan Teladan Ranah Minang"
	}

	// Cek apakah sudah pernah diterbitkan sebelumnya
	if cert, exists := s.repo.GetCertificate(userID); exists {
		return cert, true, nil
	}

	userStamps := s.repo.GetUserPassportStamps(userID)
	totalStamps := len(userStamps)
	allSpots := s.repo.GetIconicSpots()
	requiredStamps := len(allSpots)
	if requiredStamps == 0 {
		requiredStamps = 10
	}

	// Validasi kelayakan: harus sudah mengumpulkan seluruh 10 stempel
	if totalStamps < requiredStamps {
		return nil, false, &IneligibleCertificateError{
			Collected: totalStamps,
			Required:  requiredStamps,
		}
	}

	certID := fmt.Sprintf("WISGO-GUB-SB-%d-%04d", time.Now().Year(), time.Now().UnixNano()%10000)
	now := time.Now()

	cert := CertificateResponse{
		CertificateID:     certID,
		RecipientName:     fullName,
		IssuedAt:          now,
		TotalSpotsVisited: totalStamps,
		SignatoryTitle:    "Gubernur Sumatera Barat & Kepala Dinas Pariwisata Prov. Sumbar",
		SignatoryName:     "H. Mahyeldi Ansharullah, S.P. (Gubernur Sumbar)",
		VerificationURL:   fmt.Sprintf("https://wisgo.sumbarprov.go.id/verify/cert/%s", certID),
		QRCodeURL:         fmt.Sprintf("https://api.wisgo.sumbarprov.go.id/api/v1/certificates/verify-qr?id=%s", certID),
		PDFDownloadURL:    fmt.Sprintf("https://api.wisgo.sumbarprov.go.id/api/v1/certificates/download-pdf?id=%s", certID),
	}

	s.repo.SaveCertificate(userID, cert)
	return &cert, false, nil
}

