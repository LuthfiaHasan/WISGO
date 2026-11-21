package auth

import (
	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// OTPRequest payload permintaan kirim kode OTP
type OTPRequest struct {
	PhoneNumber string `json:"phone_number" binding:"required"`
}

// OTPVerifyRequest payload verifikasi kode OTP
type OTPVerifyRequest struct {
	PhoneNumber string `json:"phone_number" binding:"required"`
	OTPCode     string `json:"otp_code" binding:"required"`
	FullName    string `json:"full_name,omitempty"`
	LoginChoice string `json:"login_choice,omitempty"` // "wisata" (Wisatawan: input wisata) atau "event" (Vendor: input event)
	Role        string `json:"role,omitempty"`         // "tourist" atau "vendor"
}

// AuthResponse respon sukses login & token JWT
type AuthResponse struct {
	Token       string      `json:"token"`
	User        models.User `json:"user"`
	LoginChoice string      `json:"login_choice,omitempty"` // Opsi awal login terpilih: "wisata" atau "event"
}

// ToggleSavedRequest payload simpan/hapus tempat favorit
type ToggleSavedRequest struct {
	UserID        string `json:"user_id" binding:"required"`
	DestinationID string `json:"destination_id" binding:"required"`
}

// ToggleSavedResponse respon status bookmark
type ToggleSavedResponse struct {
	DestinationID string `json:"destination_id"`
	IsSaved       bool   `json:"is_saved"`
	TotalSaved    int    `json:"total_saved"`
}
