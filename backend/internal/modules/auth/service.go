package auth

import (
	"crypto/rand"
	"errors"
	"fmt"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis murni untuk Autentikasi & Profil (tanpa Gin Context)
type Service interface {
	RequestOTP(phone string) (string, error)
	VerifyOTP(phone, code string) (*models.User, string, error)
	GetSavedPlaces(userID string) ([]models.SavedPlace, error)
	ToggleSavedPlace(userID, destinationID string) (*ToggleSavedResponse, error)
}

type authService struct {
	repo Repository
}

// NewService membuat instance baru dari AuthService
func NewService(repo Repository) Service {
	return &authService{repo: repo}
}

func (s *authService) RequestOTP(phone string) (string, error) {
	if phone == "" {
		return "", errors.New("Nomor handphone wajib diisi")
	}

	// Buat kode OTP 4 digit
	b := make([]byte, 2)
	_, _ = rand.Read(b)
	otpCode := fmt.Sprintf("%04d", int(b[0])%10000)
	if otpCode == "0000" || otpCode == "" {
		otpCode = "1234"
	}

	if err := s.repo.SaveOTP(phone, otpCode); err != nil {
		return "", err
	}

	return otpCode, nil
}

func (s *authService) VerifyOTP(phone, code string) (*models.User, string, error) {
	if phone == "" || code == "" {
		return nil, "", errors.New("Nomor handphone dan kode OTP wajib diisi")
	}

	storedCode, exists := s.repo.GetOTP(phone)

	// Validasi kode: harus cocok dengan yang digenerate ATAU bypass master dev "1234"
	if (!exists || storedCode != code) && code != "1234" {
		return nil, "", errors.New("Kode OTP salah atau telah kadaluarsa")
	}

	// Cari atau buat pengguna baru otomatis jika belum terdaftar
	user, userExists := s.repo.FindUserByPhone(phone)
	if !userExists {
		newUser := models.User{
			ID:          fmt.Sprintf("usr-%d", time.Now().UnixNano()%100000),
			PhoneNumber: phone,
			FullName:    "Wisatawan Ranah Minang",
			Role:        "tourist",
			CreatedAt:   time.Now(),
		}
		if err := s.repo.CreateUser(newUser); err != nil {
			return nil, "", err
		}
		user = &newUser
	}

	// Generate simulasi JWT Token
	token := fmt.Sprintf("jwt-wisgo-%s-%d", user.ID, time.Now().Unix())

	return user, token, nil
}

func (s *authService) GetSavedPlaces(userID string) ([]models.SavedPlace, error) {
	if userID == "" {
		userID = "usr-001" // fallback default
	}
	return s.repo.GetSavedPlaces(userID)
}

func (s *authService) ToggleSavedPlace(userID, destinationID string) (*ToggleSavedResponse, error) {
	if userID == "" || destinationID == "" {
		return nil, errors.New("user_id dan destination_id wajib diisi")
	}

	isSaved, total, err := s.repo.ToggleSavedPlace(userID, destinationID)
	if err != nil {
		return nil, err
	}

	return &ToggleSavedResponse{
		DestinationID: destinationID,
		IsSaved:       isSaved,
		TotalSaved:    total,
	}, nil
}

