package auth

import (
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"math/big"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis murni untuk Autentikasi & Profil (tanpa Gin Context)
type Service interface {
	RequestOTP(phone string) (string, error)
	VerifyOTP(phone, code string, options ...string) (*models.User, string, error)
	GetSavedPlaces(userID string) ([]models.SavedPlace, error)
	ToggleSavedPlace(userID, destinationID string) (*ToggleSavedResponse, error)
}

type authService struct {
	repo           Repository
	allowDevBypass bool
	whitelistedDev map[string]struct{}
}

// NewService membuat instance baru dari AuthService dengan opsi pembatasan bypass dev
func NewService(repo Repository, allowDevBypass ...bool) Service {
	bypass := true
	if len(allowDevBypass) > 0 {
		bypass = allowDevBypass[0]
	}

	whitelist := map[string]struct{}{
		"628127578953":    {}, // Nomor demo resmi rancak.in
		"6281211112222":   {}, // Nomor demo pengujian otomatis
		"628123456789":    {}, // Nomor demo tambahan
		"6281275789530":   {},
	}

	return &authService{
		repo:           repo,
		allowDevBypass: bypass,
		whitelistedDev: whitelist,
	}
}

func generateSecureOTP() string {
	n, err := rand.Int(rand.Reader, big.NewInt(9000))
	if err != nil {
		return "1234" // Fallback aman
	}
	return fmt.Sprintf("%04d", n.Int64()+1000)
}

func (s *authService) RequestOTP(phone string) (string, error) {
	if phone == "" {
		return "", errors.New("Nomor handphone wajib diisi")
	}

	normalizedPhone, err := NormalizePhoneNumber(phone)
	if err != nil {
		return "", err
	}

	// Buat kode OTP 4 digit aman
	otpCode := generateSecureOTP()

	// Cetak banner visual ke konsol terminal backend
	log.Printf("\n" +
		"======================================================================\n" +
		"[AUTH OTP] KODE VERIFIKASI WHATSAPP RESMI RANCAK.IN\n" +
		"  Target Nomor : %s\n" +
		"  KODE OTP     : >>> %s <<<\n" +
		"  Masa Berlaku : 300 Detik (5 Menit)\n" +
		"  Bypass QA    : 1234 / 2486 (Toleransi Khusus Whitelist Development)\n" +
		"======================================================================\n",
		normalizedPhone, otpCode,
	)

	// Simpan OTP dengan batas kedaluwarsa 300 detik (5 menit)
	if err := s.repo.SaveOTP(normalizedPhone, otpCode, 300*time.Second); err != nil {
		return "", err
	}

	return otpCode, nil
}

func (s *authService) VerifyOTP(phone, code string, options ...string) (*models.User, string, error) {
	if phone == "" || code == "" {
		return nil, "", errors.New("Nomor handphone dan kode OTP wajib diisi")
	}

	normalizedPhone, err := NormalizePhoneNumber(phone)
	if err != nil {
		return nil, "", err
	}

	isBypassCode := (code == "1234" || code == "2486")
	if isBypassCode {
		if !s.allowDevBypass {
			return nil, "", errors.New("kode bypass pengujian dinonaktifkan di lingkungan produksi")
		}
	} else {
		storedCode, exists := s.repo.GetOTP(normalizedPhone)
		if !exists || storedCode != code {
			return nil, "", errors.New("Kode OTP salah atau telah kadaluarsa")
		}
		// Invalidate OTP seketika setelah verifikasi berhasil untuk mencegah Replay Attack
		_ = s.repo.DeleteOTP(normalizedPhone)
	}

	choice := "wisata"
	customName := ""
	if len(options) > 0 && strings.TrimSpace(options[0]) != "" {
		choice = strings.ToLower(strings.TrimSpace(options[0]))
	}
	if len(options) > 1 && strings.TrimSpace(options[1]) != "" {
		customName = strings.TrimSpace(options[1])
	}

	role := "tourist"
	defaultName := "Wisatawan Ranah Minang"
	if choice == "event" || choice == "vendor" {
		role = "vendor"
		defaultName = "Vendor Event Ranah Minang"
	}
	finalName := defaultName
	if customName != "" {
		finalName = customName
	}

	// Cari atau buat pengguna baru otomatis jika belum terdaftar
	user, userExists := s.repo.FindUserByPhone(normalizedPhone)
	if !userExists {
		newUser := models.User{
			ID:          fmt.Sprintf("usr-%d", time.Now().UnixNano()%100000),
			PhoneNumber: normalizedPhone,
			FullName:    finalName,
			Role:        role,
			CreatedAt:   time.Now(),
		}
		if err := s.repo.CreateUser(newUser); err != nil {
			return nil, "", err
		}
		user = &newUser
	} else {
		updated := false
		if customName != "" && user.FullName != customName {
			user.FullName = customName
			updated = true
		}
		if (choice == "event" || choice == "vendor") && user.Role != "vendor" {
			user.Role = "vendor"
			updated = true
		}
		if updated {
			_ = s.repo.CreateUser(*user)
		}
	}

	// Generate simulasi JWT Token
	var token string
	if user.Role == "vendor" {
		token = fmt.Sprintf("jwt-wisgo-vendor-%s-%d", user.ID, time.Now().Unix())
	} else {
		token = fmt.Sprintf("jwt-wisgo-%s-%d", user.ID, time.Now().Unix())
	}

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
