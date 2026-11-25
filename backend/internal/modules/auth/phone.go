package auth

import (
	"errors"
	"regexp"
	"strings"
)

var nonDigitRegex = regexp.MustCompile(`\D`)

// NormalizePhoneNumber mengonversi ragam format input ke format kanonikal E.164 (628xxx)
func NormalizePhoneNumber(raw string) (string, error) {
	cleaned := nonDigitRegex.ReplaceAllString(strings.TrimSpace(raw), "")

	// 1. Tangani standar internasional awalan 00 (misal: 0062812... -> 62812...)
	if strings.HasPrefix(cleaned, "00") {
		cleaned = cleaned[2:]
	}

	// 2. Tangani kebiasaan user mengetik +62 diikuti 08... (6208xxx -> 628xxx)
	if strings.HasPrefix(cleaned, "6208") {
		cleaned = "62" + cleaned[3:]
	} else if strings.HasPrefix(cleaned, "08") {
		cleaned = "62" + cleaned[1:]
	} else if strings.HasPrefix(cleaned, "8") {
		cleaned = "62" + cleaned
	} else if strings.HasPrefix(cleaned, "628") {
		// format kanonikal sudah tepat
	} else {
		return "", errors.New("nomor telepon harus menggunakan awalan 08, 8, atau 628")
	}

	// 3. Validasi rentang panjang digit numerik nasional (10 - 15 digit)
	if len(cleaned) < 10 || len(cleaned) > 15 {
		return "", errors.New("panjang nomor telepon tidak valid (harus 10-15 digit)")
	}

	return cleaned, nil
}
