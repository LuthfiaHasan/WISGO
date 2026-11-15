package gamification

import (
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// CheckInRequest payload check-in validasi Anti-Fake GPS (radius <= 200m)
type CheckInRequest struct {
	UserID         string  `json:"user_id" binding:"required"`
	DestinationID  string  `json:"destination_id" binding:"required"`
	Latitude       float64 `json:"latitude"`
	Longitude      float64 `json:"longitude"`
	UserLatitude   float64 `json:"user_latitude,omitempty"`
	UserLongitude  float64 `json:"user_longitude,omitempty"`
	IsCarvingFound bool    `json:"is_carving_found,omitempty"`
}

// CheckInResponse rincian hasil check-in dan perolehan lencana ikonik
type CheckInResponse struct {
	DestinationID   string    `json:"destination_id"`
	DestinationName string    `json:"destination_name"`
	DistanceMeters  float64   `json:"distance_meters"`
	IsWithinRadius  bool      `json:"is_within_radius"`
	CheckedInAt     time.Time `json:"checked_in_at"`
	BadgeEarned     string    `json:"badge_earned"`
	TotalStamps     int       `json:"total_stamps"`
	MaxStamps       int       `json:"max_stamps"`
}

// PassportSummaryResponse rekap stempel paspor digital wisatawan (10 titik ikonik Minang)
type PassportSummaryResponse struct {
	UserID                   string                 `json:"user_id"`
	TotalStamps              int                    `json:"total_stamps"`
	RequiredStamps           int                    `json:"required_stamps"`
	CompletionPercentage     float64                `json:"completion_percentage"`
	IsEligibleForCertificate bool                   `json:"is_eligible_for_certificate"`
	Spots                    []models.IconicSpotItem `json:"spots"`
}

// CertificateRequest permintaan penerbitan sertifikat digital resmi gubernur
type CertificateRequest struct {
	UserID   string `json:"user_id"`
	FullName string `json:"full_name"`
}

// CertificateResponse sertifikat digital resmi bertanda tangan Gubernur Sumatera Barat
type CertificateResponse struct {
	CertificateID     string    `json:"certificate_id"`
	RecipientName     string    `json:"recipient_name"`
	IssuedAt          time.Time `json:"issued_at"`
	TotalSpotsVisited int       `json:"total_spots_visited"`
	SignatoryTitle    string    `json:"signatory_title"`
	SignatoryName     string    `json:"signatory_name"`
	VerificationURL   string    `json:"verification_url"`
	QRCodeURL         string    `json:"qr_code_url"`
	PDFDownloadURL    string    `json:"pdf_download_url"`
}

