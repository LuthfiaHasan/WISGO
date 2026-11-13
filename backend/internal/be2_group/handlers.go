package be2_group

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// ResponseStandar format respon JSON baku sesuai GEMINI.md
type ResponseStandar struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// HandlerBE2 menangani endpoint Grup, Mitra, Escrow & Gamifikasi (Pilar 4, 5, 6, 8)
type HandlerBE2 struct {
	mu              sync.RWMutex
	users           map[string]models.User
	partners        []models.PartnerNagari
	savedPlaces     map[string][]models.SavedPlace // key: user_id
	otpStore        map[string]string              // key: phone, val: otp
	itineraries     map[string][]models.Itinerary  // key: user_id
	groupRooms      map[string]models.GroupRoom    // key: room_code
	groupVotes      map[string][]models.GroupVote  // key: room_code
	communityPlaces []models.CommunityPlace
	bookings        map[string]*models.BookingEscrow                 // key: booking_id
	groupRadars     map[string]map[string]models.MemberRadarLocation // key: room_code -> user_id -> location
	sharedTrips     []models.SharedTrip
	iconicSpots     []models.IconicSpotItem
	passports       map[string]map[string]time.Time       // key: user_id -> dest_id -> timestamp
	certificates    map[string]models.CertificateResponse // key: user_id -> cert
}

// NewHandlerBE2 menginisialisasi handler dengan data awal seeder
func NewHandlerBE2() *HandlerBE2 {
	h := &HandlerBE2{
		users:           make(map[string]models.User),
		savedPlaces:     make(map[string][]models.SavedPlace),
		otpStore:        make(map[string]string),
		itineraries:     make(map[string][]models.Itinerary),
		groupRooms:      make(map[string]models.GroupRoom),
		groupVotes:      make(map[string][]models.GroupVote),
		communityPlaces: make([]models.CommunityPlace, 0),
		bookings:        make(map[string]*models.BookingEscrow),
		groupRadars:     make(map[string]map[string]models.MemberRadarLocation),
		sharedTrips:     make([]models.SharedTrip, 0),
		passports:       make(map[string]map[string]time.Time),
		certificates:    make(map[string]models.CertificateResponse),
	}

	// 10 Titik Ikonik Paspor Digital Minangkabau (Pilar 6 - Validasi GPS <= 200m)
	h.iconicSpots = []models.IconicSpotItem{
		{
			ID:        "spot-jam-gadang",
			Name:      "Jam Gadang Bukittinggi",
			Regency:   "Kota Bukittinggi",
			Latitude:  -0.3051,
			Longitude: 100.3695,
			BadgeName: "Lencana Penjaga Waktu Minang",
		},
		{
			ID:        "spot-pagaruyung",
			Name:      "Istano Basa Pagaruyung",
			Regency:   "Kab. Tanah Datar",
			Latitude:  -0.4712,
			Longitude: 100.6214,
			BadgeName: "Lencana Pusaka Pagaruyung",
		},
		{
			ID:        "spot-lembah-harau",
			Name:      "Lembah Harau & Kelok 9",
			Regency:   "Kab. Lima Puluh Kota",
			Latitude:  -0.1062,
			Longitude: 100.6657,
			BadgeName: "Lencana Ngarai Batagak Harau",
		},
		{
			ID:        "spot-danau-maninjau",
			Name:      "Danau Maninjau & Kelok 44",
			Regency:   "Kab. Agam",
			Latitude:  -0.2980,
			Longitude: 100.1878,
			BadgeName: "Lencana Ranah Rang Agam",
		},
		{
			ID:        "spot-danau-singkarak",
			Name:      "Danau Singkarak",
			Regency:   "Kab. Solok",
			Latitude:  -0.6175,
			Longitude: 100.5367,
			BadgeName: "Lencana Bareh Danau Solok",
		},
		{
			ID:        "spot-kawasan-mandeh",
			Name:      "Kawasan Bahari Terpadu Mandeh",
			Regency:   "Kab. Pesisir Selatan",
			Latitude:  -1.2186,
			Longitude: 100.4192,
			BadgeName: "Lencana Raja Ampat Pasisie",
		},
		{
			ID:        "spot-ngarai-sianok",
			Name:      "Ngarai Sianok & Panorama",
			Regency:   "Kota Bukittinggi",
			Latitude:  -0.3106,
			Longitude: 100.3619,
			BadgeName: "Lencana Lembah Hijau Sianok",
		},
		{
			ID:        "spot-kota-tua-padang",
			Name:      "Kota Tua Padang & Muaro",
			Regency:   "Kota Padang",
			Latitude:  -0.9634,
			Longitude: 100.3547,
			BadgeName: "Lencana Ranah Bandaro Muaro",
		},
		{
			ID:        "spot-desa-pariangan",
			Name:      "Desa Nagari Tuo Pariangan",
			Regency:   "Kab. Tanah Datar",
			Latitude:  -0.4357,
			Longitude: 100.4939,
			BadgeName: "Lencana Asal Balai Nan Panjang",
		},
		{
			ID:        "spot-tambang-ombilin",
			Name:      "Tambang Batubara Ombilin (UNESCO)",
			Regency:   "Kota Sawahlunto",
			Latitude:  -0.6806,
			Longitude: 100.7767,
			BadgeName: "Lencana Warisan Dunia Ombilin",
		},
	}

	// Inisialisasi User Awal
	h.users["usr-001"] = models.User{
		ID:          "usr-001",
		PhoneNumber: "6281211112222",
		FullName:    "Rahmat Hidayat (Wisatawan Mandiri)",
		Role:        "tourist",
		CreatedAt:   time.Now(),
	}

	// Inisialisasi 5 Kategori Mitra Nagari Minangkabau Otentik (Pilar 5)
	h.partners = []models.PartnerNagari{
		{
			ID:          "ptr-01",
			Name:        "Homestay Rumah Gadang Etek Nur",
			Category:    "Homestay Rumah Gadang",
			WhatsApp:    "6281234567890",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 250000.00,
			NagariName:  "Nagari Sungai Buluah",
		},
		{
			ID:          "ptr-02",
			Name:        "Itiak Lado Mudo Ngarai Sianok",
			Category:    "Kuliner Halal",
			WhatsApp:    "6281298765432",
			SpicyLevel:  4, // Level Pedas 4
			IsVerified:  true,
			StandardFee: 45000.00,
			NagariName:  "Nagari Koto Gadang",
		},
		{
			ID:          "ptr-03",
			Name:        "Perahu Wisata Bahari Pulau Mandeh",
			Category:    "Transport & Perahu",
			WhatsApp:    "6281311223344",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 350000.00,
			NagariName:  "Nagari Tarusan Mandeh",
		},
		{
			ID:          "ptr-04",
			Name:        "Pemandu Trekking Lembah Harau (Pokdarwis)",
			Category:    "Pemandu Pokdarwis",
			WhatsApp:    "6281355667788",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 150000.00,
			NagariName:  "Nagari Harau",
		},
		{
			ID:          "ptr-05",
			Name:        "Sanggar Busana Saluak & Suntiang Rang Minang",
			Category:    "Sewa Baju Adat",
			WhatsApp:    "6281399887766",
			SpicyLevel:  0,
			IsVerified:  true,
			StandardFee: 75000.00,
			NagariName:  "Kota Bukittinggi",
		},
	}

	// Inisialisasi Tempat Tersimpan Awal
	h.savedPlaces["usr-001"] = []models.SavedPlace{
		{
			ID:            "sp-001",
			UserID:        "usr-001",
			DestinationID: "dest-001",
			CreatedAt:     time.Now(),
			Destination: &models.Destination{
				ID:          "dest-001",
				Name:        "Lembah Harau",
				Category:    "Alam & Tebing",
				CityRegency: "Kab. Lima Puluh Kota",
				CrowdLevel:  "Sedang",
			},
		},
	}

	// Inisialisasi Group Room Awal
	initialRoom := models.GroupRoom{
		ID:        "grp-001",
		RoomCode:  "RANCAK-MINANG-88",
		Title:     "Trip Rombongan Ranah Minang 2026",
		LeaderID:  "usr-001",
		CreatedAt: time.Now(),
		Members: []models.GroupMember{
			{
				ID:          "gm-001",
				GroupRoomID: "grp-001",
				UserID:      "usr-001",
				Role:        "leader",
				JoinedAt:    time.Now(),
				User: &models.User{
					ID:          "usr-001",
					PhoneNumber: "6281211112222",
					FullName:    "Rahmat Hidayat (Wisatawan Mandiri)",
					Role:        "tourist",
				},
			},
		},
	}
	h.groupRooms[initialRoom.RoomCode] = initialRoom

	// Inisialisasi Itinerary Awal
	h.itineraries["usr-001"] = []models.Itinerary{
		{
			ID:        "itn-001",
			UserID:    "usr-001",
			Title:     "Jelajah Luhak Nan Tigo (Padang - Bukittinggi - Harau)",
			StartDate: "2026-11-20",
			EndDate:   "2026-11-26",
			TotalDays: 7,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
			Items: []models.ItineraryItem{
				{
					ID:            "iti-001",
					ItineraryID:   "itn-001",
					DayNumber:     1,
					TimeSlot:      "09:00",
					DestinationID: "dest-001",
					Notes:         "Trekking santai tebing granit & sarapan katupek pical",
					Destination: &models.Destination{
						ID:   "dest-001",
						Name: "Lembah Harau",
					},
				},
				{
					ID:            "iti-002",
					ItineraryID:   "itn-001",
					DayNumber:     1,
					TimeSlot:      "13:00",
					DestinationID: "dest-002",
					Notes:         "Menara Jam Gadang & belanja songket Pasar Ateh",
					TrafficAlert:  "Waspada macet Pasar Koto Baru pukul 12:00-14:00",
					Destination: &models.Destination{
						ID:   "dest-002",
						Name: "Jam Gadang Bukittinggi",
					},
				},
			},
		},
	}

	return h
}

// writeJSON helper pengirim response JSON standar
func writeJSON(w http.ResponseWriter, statusCode int, resp ResponseStandar) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(resp)
}

// =============================================================================
// 1. KLASTER AUTENTIKASI OTP (FE-2 Layar 05)
// =============================================================================

// RequestOTP mengirim kode OTP 4 kotak ke nomor HP wisatawan
func (h *HandlerBE2) RequestOTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.OTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.PhoneNumber) == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: nomor handphone wajib diisi",
		})
		return
	}

	phone := strings.TrimSpace(req.PhoneNumber)
	phone = strings.ReplaceAll(phone, "+", "")
	phone = strings.ReplaceAll(phone, "-", "")
	phone = strings.ReplaceAll(phone, " ", "")

	// Standarisasi awalan no HP Indonesia
	if strings.HasPrefix(phone, "08") {
		phone = "628" + phone[2:]
	}

	// Generate OTP 4 digit (default "1234" untuk dev, atau random)
	otpCode := "1234"
	if len(phone) > 4 {
		b := make([]byte, 2)
		_, _ = rand.Read(b)
		otpCode = fmt.Sprintf("%04d", (int(b[0])<<8|int(b[1]))%9000+1000)
	}

	h.mu.Lock()
	h.otpStore[phone] = otpCode
	h.mu.Unlock()

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Kode OTP 4 digit berhasil dikirimkan via WhatsApp/SMS ke %s", phone),
		Data: map[string]interface{}{
			"phone_number": phone,
			"otp_preview":  otpCode, // Mempermudah integrasi pengujian FE-2 & simulator FS-1
			"expires_in":   300,     // 5 menit
		},
	})
}

// VerifyOTP memvalidasi 4 kotak OTP & menerbitkan JWT Token
func (h *HandlerBE2) VerifyOTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.OTPVerifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PhoneNumber == "" || req.OTPCode == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: phone_number dan otp_code wajib diisi",
		})
		return
	}

	phone := strings.TrimSpace(req.PhoneNumber)
	phone = strings.ReplaceAll(phone, "+", "")
	if strings.HasPrefix(phone, "08") {
		phone = "628" + phone[2:]
	}

	h.mu.RLock()
	storedOTP, exists := h.otpStore[phone]
	h.mu.RUnlock()

	// Kode "1234" selalu diterima sebagai master OTP pengujian dev
	if (!exists || storedOTP != req.OTPCode) && req.OTPCode != "1234" {
		writeJSON(w, http.StatusUnauthorized, ResponseStandar{
			Status:  "error",
			Message: "Kode OTP 4 digit salah atau telah kedaluwarsa",
		})
		return
	}

	// Cari user atau auto-register wisatawan baru
	h.mu.Lock()
	var currentUser models.User
	userFound := false
	for _, u := range h.users {
		if u.PhoneNumber == phone {
			currentUser = u
			userFound = true
			break
		}
	}

	if !userFound {
		newID := fmt.Sprintf("usr-%d", time.Now().UnixNano()%100000)
		currentUser = models.User{
			ID:          newID,
			PhoneNumber: phone,
			FullName:    "Wisatawan Ranah Minang",
			Role:        "tourist",
			CreatedAt:   time.Now(),
		}
		h.users[newID] = currentUser
	}
	delete(h.otpStore, phone)
	h.mu.Unlock()

	simulatedToken := fmt.Sprintf("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.user_%s_%d", currentUser.ID, time.Now().Unix())

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Autentikasi OTP berhasil, selamat datang di Ranah Minang!",
		Data: models.AuthResponse{
			Token: simulatedToken,
			User:  currentUser,
		},
	})
}

// =============================================================================
// 2. KLASTER MITRA NAGARI & KATALOG (Pilar 5)
// =============================================================================

// GetPartnersKatalog katalog 5 mitra nagari dengan filter kategori & level pedas
func (h *HandlerBE2) GetPartnersKatalog(w http.ResponseWriter, r *http.Request) {
	category := strings.TrimSpace(r.URL.Query().Get("category"))
	spicyStr := strings.TrimSpace(r.URL.Query().Get("spicy_level"))
	nagari := strings.TrimSpace(r.URL.Query().Get("nagari"))

	h.mu.RLock()
	defer h.mu.RUnlock()

	var filtered []models.PartnerNagari
	for _, p := range h.partners {
		if category != "" && !strings.Contains(strings.ToLower(p.Category), strings.ToLower(category)) {
			continue
		}

		if spicyStr != "" {
			reqSpicy, err := strconv.Atoi(spicyStr)
			if err == nil && p.SpicyLevel != reqSpicy {
				continue
			}
		}

		if nagari != "" && !strings.Contains(strings.ToLower(p.NagariName), strings.ToLower(nagari)) {
			continue
		}

		filtered = append(filtered, p)
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Daftar katalog mitra nagari berhasil dimuat",
		Data: map[string]interface{}{
			"total":    len(filtered),
			"partners": filtered,
		},
	})
}

// GetPartnerDetail mengambil detail satu profil mitra nagari
func (h *HandlerBE2) GetPartnerDetail(w http.ResponseWriter, r *http.Request) {
	partnerID := r.URL.Query().Get("id")
	if partnerID == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Parameter id mitra wajib diisi (misal: ?id=ptr-01)",
		})
		return
	}

	h.mu.RLock()
	defer h.mu.RUnlock()

	for _, p := range h.partners {
		if p.ID == partnerID {
			writeJSON(w, http.StatusOK, ResponseStandar{
				Status:  "success",
				Message: "Detail profil mitra nagari ditemukan",
				Data:    p,
			})
			return
		}
	}

	writeJSON(w, http.StatusNotFound, ResponseStandar{
		Status:  "error",
		Message: fmt.Sprintf("Mitra nagari dengan ID '%s' tidak ditemukan", partnerID),
	})
}

// =============================================================================
// 3. KLASTER TEMPAT TERSIMPAN / FAVORIT (FE-2 Layar 04)
// =============================================================================

// GetSavedPlaces mengambil daftar destinasi yang disimpan/dibookmark wisatawan
func (h *HandlerBE2) GetSavedPlaces(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		userID = "usr-001"
	}

	h.mu.RLock()
	list, exists := h.savedPlaces[userID]
	h.mu.RUnlock()

	if !exists {
		list = []models.SavedPlace{}
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Daftar destinasi tersimpan berhasil dimuat",
		Data: map[string]interface{}{
			"user_id":      userID,
			"total_saved":  len(list),
			"saved_places": list,
		},
	})
}

// ToggleSavedPlace toggle simpan atau hapus destinasi dari bookmark
func (h *HandlerBE2) ToggleSavedPlace(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req struct {
		UserID        string `json:"user_id"`
		DestinationID string `json:"destination_id"`
	}

	_ = json.NewDecoder(r.Body).Decode(&req)
	if req.DestinationID == "" {
		req.DestinationID = r.URL.Query().Get("destination_id")
	}

	if req.DestinationID == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "destination_id wajib diisi",
		})
		return
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	currentList := h.savedPlaces[req.UserID]
	foundIndex := -1
	for i, sp := range currentList {
		if sp.DestinationID == req.DestinationID {
			foundIndex = i
			break
		}
	}

	if foundIndex >= 0 {
		h.savedPlaces[req.UserID] = append(currentList[:foundIndex], currentList[foundIndex+1:]...)
		writeJSON(w, http.StatusOK, ResponseStandar{
			Status:  "success",
			Message: "Destinasi berhasil dihapus dari daftar tersimpan",
			Data: map[string]interface{}{
				"is_saved":       false,
				"destination_id": req.DestinationID,
			},
		})
	} else {
		newSaved := models.SavedPlace{
			ID:            fmt.Sprintf("sp-%d", time.Now().UnixNano()%100000),
			UserID:        req.UserID,
			DestinationID: req.DestinationID,
			CreatedAt:     time.Now(),
			Destination: &models.Destination{
				ID:          req.DestinationID,
				Name:        "Destinasi Minangkabau",
				CityRegency: "Sumatera Barat",
				CrowdLevel:  "Sedang",
			},
		}
		h.savedPlaces[req.UserID] = append(currentList, newSaved)
		writeJSON(w, http.StatusOK, ResponseStandar{
			Status:  "success",
			Message: "Destinasi berhasil ditambahkan ke daftar tersimpan",
			Data: map[string]interface{}{
				"is_saved":       true,
				"destination_id": req.DestinationID,
				"item":           newSaved,
			},
		})
	}
}

// =============================================================================
// 4. KLASTER TRIP PLANNER & AUTO-ITINERARY GENERATOR (Pilar 4 — Minggu 2)
// =============================================================================

// AutoGenerateItinerary menyusun rencana perjalanan harian otomatis 1-7 hari
func (h *HandlerBE2) AutoGenerateItinerary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.AutoItineraryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid",
		})
		return
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}
	if req.DurationDays < 1 {
		req.DurationDays = 3 // default 3 hari
	} else if req.DurationDays > 7 {
		req.DurationDays = 7
	}

	title := fmt.Sprintf("Itinerary Pintar %d Hari Ranah Minang", req.DurationDays)
	now := time.Now()
	startDate := now.Format("2006-01-02")
	endDate := now.AddDate(0, 0, req.DurationDays).Format("2006-01-02")

	// Peta Destinasi Unggulan per Hari (Menghindari bolak-balik & mempertimbangkan tanjakan)
	dailySchedules := []struct {
		DestinationID   string
		DestinationName string
		TimeSlot        string
		Notes           string
		TrafficAlert    string
	}{
		// Hari 1: Padang & Lembah Anai
		{"dest-003", "Air Terjun Lembah Anai", "10:00", "Spot foto gerbang masuk Luhak Nan Tigo & istirahat sejenak", ""},
		{"dest-002", "Jam Gadang Bukittinggi", "14:00", "Pusat kota Bukittinggi & cagar budaya", "Peringatan macet Pasar Koto Baru pukul 12:00-14:00"},
		// Hari 2: Geopark Ngarai Sianok & Pagaruyung
		{"dest-004", "Ngarai Sianok & Panorama", "09:00", "Pemandangan tebing ngarai purba & sarapan Itiak Lado Mudo", ""},
		{"dest-005", "Istano Basa Pagaruyung", "14:00", "Eksplorasi budaya Minangkabau & foto baju adat", ""},
		// Hari 3: Geopark Lembah Harau & Kelok 9
		{"dest-001", "Lembah Harau & Tebing Granit", "09:00", "Jelajah lembah tebing batu granit 100-500m & air terjun", ""},
		{"dest-006", "Jembatan Layang Kelok 9", "14:00", "Ikon infrastruktur modern berpadu keelokan alam", ""},
		// Hari 4: Danau Maninjau & Kelok 44
		{"dest-007", "Kelok 44 & Danau Maninjau", "10:00", "Menuruni kelok legendaris pemandangan danau vulkanik", "Waspada tikungan tajam & kabut"},
		// Hari 5: Danau Singkarak & Kuliner Ikan Bilih
		{"dest-008", "Danau Singkarak", "11:00", "Pesisir danau terluas Sumbar & makan siang Ikan Bilih", ""},
		// Hari 6: Bahari Mandeh (Raja Ampat Sumbar)
		{"dest-009", "Kawasan Wisata Bahari Mandeh", "08:30", "Island hopping pulau-pulau eksotis & snorkeling", ""},
		// Hari 7: Kota Padang & Belanja Oleh-Oleh
		{"dest-010", "Pantai Padang & Pasar Ateh", "11:00", "Sunset Pantai Padang & belanja keripik sanjai balado", ""},
	}

	var items []models.ItineraryItem
	itemCount := 0
	for day := 1; day <= req.DurationDays; day++ {
		// Alokasikan 1-2 destinasi logis per hari
		for k := 0; k < 2 && itemCount < len(dailySchedules); k++ {
			sched := dailySchedules[itemCount]
			items = append(items, models.ItineraryItem{
				ID:            fmt.Sprintf("iti-%d", time.Now().UnixNano()%100000+int64(itemCount)),
				DayNumber:     day,
				TimeSlot:      sched.TimeSlot,
				DestinationID: sched.DestinationID,
				Notes:         sched.Notes,
				TrafficAlert:  sched.TrafficAlert,
				Destination: &models.Destination{
					ID:   sched.DestinationID,
					Name: sched.DestinationName,
				},
			})
			itemCount++
			if day > 3 && k == 0 { // Untuk hari ke-4 ke atas cukup 1 kawasan utama per hari
				break
			}
		}
	}

	newItinerary := models.Itinerary{
		ID:        fmt.Sprintf("itn-%d", time.Now().UnixNano()%100000),
		UserID:    req.UserID,
		Title:     title,
		StartDate: startDate,
		EndDate:   endDate,
		TotalDays: req.DurationDays,
		CreatedAt: now,
		UpdatedAt: now,
		Items:     items,
	}

	h.mu.Lock()
	h.itineraries[req.UserID] = append(h.itineraries[req.UserID], newItinerary)
	h.mu.Unlock()

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Jadwal perjalanan cerdas %d hari berhasil disusun otomatis", req.DurationDays),
		Data:    newItinerary,
	})
}

// GetItineraries mengambil seluruh riwayat jadwal trip pengguna
func (h *HandlerBE2) GetItineraries(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		userID = "usr-001"
	}

	h.mu.RLock()
	list, exists := h.itineraries[userID]
	h.mu.RUnlock()

	if !exists {
		list = []models.Itinerary{}
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Daftar rencana perjalanan berhasil dimuat",
		Data: map[string]interface{}{
			"user_id":     userID,
			"total_trips": len(list),
			"itineraries": list,
		},
	})
}

// CreateItinerary menyimpan rencana perjalanan manual (Pilar 4)
func (h *HandlerBE2) CreateItinerary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.Itinerary
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.Title) == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: title itinerary wajib diisi",
		})
		return
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}
	if req.ID == "" {
		req.ID = fmt.Sprintf("itn-%d", time.Now().UnixNano()%100000)
	}
	if req.TotalDays <= 0 {
		req.TotalDays = len(req.Items)
		if req.TotalDays == 0 {
			req.TotalDays = 1
		}
	}
	now := time.Now()
	req.CreatedAt = now
	req.UpdatedAt = now

	h.mu.Lock()
	h.itineraries[req.UserID] = append(h.itineraries[req.UserID], req)
	h.mu.Unlock()

	writeJSON(w, http.StatusCreated, ResponseStandar{
		Status:  "success",
		Message: "Rencana perjalanan manual berhasil disimpan",
		Data:    req,
	})
}

// =============================================================================
// 5. KLASTER PRIVATE GROUP ROOM & LIVE VOTING (Pilar 4 — Minggu 2)
// =============================================================================

// CreateGroupRoom membuat private group room perjalanan & menerbitkan kode link WA
func (h *HandlerBE2) CreateGroupRoom(w http.ResponseWriter, r *http.Request) {
	var req models.CreateGroupRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	if req.LeaderID == "" {
		req.LeaderID = "usr-001"
	}
	if req.Title == "" {
		req.Title = "Rombongan Liburan Ranah Minang"
	}

	// Generate kode acak unik (misal: RANCAK-7291)
	b := make([]byte, 2)
	_, _ = rand.Read(b)
	roomCode := fmt.Sprintf("RANCAK-%04d", (int(b[0])<<8|int(b[1]))%9000+1000)

	newRoom := models.GroupRoom{
		ID:        fmt.Sprintf("grp-%d", time.Now().UnixNano()%100000),
		RoomCode:  roomCode,
		Title:     req.Title,
		LeaderID:  req.LeaderID,
		CreatedAt: time.Now(),
		Members: []models.GroupMember{
			{
				ID:          fmt.Sprintf("gm-%d", time.Now().UnixNano()%100000),
				GroupRoomID: roomCode,
				UserID:      req.LeaderID,
				Role:        "leader",
				JoinedAt:    time.Now(),
			},
		},
	}

	h.mu.Lock()
	h.groupRooms[roomCode] = newRoom
	h.mu.Unlock()

	inviteLink := fmt.Sprintf("https://wisgo.sumbar.go.id/join/%s", roomCode)

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Ruang koordinasi rombongan berhasil dibuat",
		Data: map[string]interface{}{
			"room":        newRoom,
			"invite_link": inviteLink,
			"wa_share_text": fmt.Sprintf("Halo dunsanak! Yuk gabung ke rencana liburan '%s' di Ranah Minang lewat tautan ini: %s",
				req.Title, inviteLink),
		},
	})
}

// GetGroupRoom mengambil informasi ruang rombongan berdasarkan kode unik
func (h *HandlerBE2) GetGroupRoom(w http.ResponseWriter, r *http.Request) {
	code := r.PathValue("code")
	if code == "" {
		code = r.URL.Query().Get("code")
	}
	if code == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Parameter code wajib diisi (misal: /api/v1/groups/RANCAK-MINANG-88 atau ?code=...)",
		})
		return
	}

	h.mu.RLock()
	room, exists := h.groupRooms[code]
	h.mu.RUnlock()

	if !exists {
		writeJSON(w, http.StatusNotFound, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Ruang rombongan dengan kode '%s' tidak ditemukan", code),
		})
		return
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Data ruang rombongan ditemukan",
		Data:    room,
	})
}

// JoinGroupRoom bergabung ke ruang rombongan via kode / link undangan WA
func (h *HandlerBE2) JoinGroupRoom(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	code := r.PathValue("code")
	if code == "" {
		code = r.URL.Query().Get("code")
	}

	var req struct {
		UserID   string `json:"user_id"`
		FullName string `json:"full_name"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)
	if req.UserID == "" {
		req.UserID = fmt.Sprintf("usr-%d", time.Now().UnixNano()%100000)
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	room, exists := h.groupRooms[code]
	if !exists {
		writeJSON(w, http.StatusNotFound, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Ruang rombongan dengan kode '%s' tidak ditemukan", code),
		})
		return
	}

	// Cek jika sudah terdaftar
	for _, m := range room.Members {
		if m.UserID == req.UserID {
			writeJSON(w, http.StatusOK, ResponseStandar{
				Status:  "success",
				Message: "Anda sudah menjadi anggota di rombongan ini",
				Data:    room,
			})
			return
		}
	}

	// Tambahkan anggota baru
	newMember := models.GroupMember{
		ID:          fmt.Sprintf("gm-%d", time.Now().UnixNano()%100000),
		GroupRoomID: code,
		UserID:      req.UserID,
		Role:        "member",
		JoinedAt:    time.Now(),
		User: &models.User{
			ID:       req.UserID,
			FullName: req.FullName,
			Role:     "tourist",
		},
	}
	room.Members = append(room.Members, newMember)
	h.groupRooms[code] = room

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Berhasil bergabung ke rombongan '%s'", room.Title),
		Data:    room,
	})
}

// VoteGroupDestination submit suara live voting destinasi / homestay
func (h *HandlerBE2) VoteGroupDestination(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.GroupVoteRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	// Fallback jika group_room_id dikirimkan via path URL /api/v1/groups/{code}/vote
	if req.GroupRoomID == "" {
		req.GroupRoomID = r.PathValue("code")
		if req.GroupRoomID == "" {
			req.GroupRoomID = r.URL.Query().Get("code")
		}
	}

	if req.GroupRoomID == "" || req.DestinationID == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: group_room_id dan destination_id wajib diisi",
		})
		return
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}
	if req.VoteType != "downvote" {
		req.VoteType = "upvote" // default upvote
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	// Update jika user sudah pernah vote destinasi ini
	existingVotes := h.groupVotes[req.GroupRoomID]
	updated := false
	for i, v := range existingVotes {
		if v.UserID == req.UserID && v.DestinationID == req.DestinationID {
			existingVotes[i].VoteType = req.VoteType
			updated = true
			break
		}
	}

	if !updated {
		h.groupVotes[req.GroupRoomID] = append(existingVotes, models.GroupVote{
			ID:            fmt.Sprintf("vte-%d", time.Now().UnixNano()%100000),
			GroupRoomID:   req.GroupRoomID,
			UserID:        req.UserID,
			DestinationID: req.DestinationID,
			VoteType:      req.VoteType,
		})
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Voting berhasil dicatat (%s)", req.VoteType),
		Data:    req,
	})
}

// GetGroupVoteResults menghitung rekapitulasi persentase voting destinasi rombongan
func (h *HandlerBE2) GetGroupVoteResults(w http.ResponseWriter, r *http.Request) {
	roomCode := r.PathValue("code")
	if roomCode == "" {
		roomCode = r.URL.Query().Get("code")
	}
	if roomCode == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Parameter code room wajib diisi",
		})
		return
	}

	h.mu.RLock()
	votes := h.groupVotes[roomCode]
	h.mu.RUnlock()

	destTally := make(map[string]*models.VoteResultItem)
	for _, v := range votes {
		if _, ok := destTally[v.DestinationID]; !ok {
			destTally[v.DestinationID] = &models.VoteResultItem{
				DestinationID:   v.DestinationID,
				DestinationName: "Destinasi " + v.DestinationID,
			}
		}
		if v.VoteType == "upvote" {
			destTally[v.DestinationID].Upvotes++
		} else {
			destTally[v.DestinationID].Downvotes++
		}
	}

	var results []models.VoteResultItem
	for _, item := range destTally {
		total := item.Upvotes + item.Downvotes
		if total > 0 {
			item.ApprovalPercent = math.Round((float64(item.Upvotes)/float64(total))*1000) / 10
		}
		results = append(results, *item)
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Rekapitulasi voting live rombongan berhasil dihitung",
		Data: map[string]interface{}{
			"room_code":   roomCode,
			"total_votes": len(votes),
			"results":     results,
		},
	})
}

// =============================================================================
// 6. KLASTER KOMUNITAS & PROTEKSI LOKASI SENSITIF (Pilar 6 — Minggu 2)
// =============================================================================

// CreateCommunityPlace menerima kontribusi tempat baru dengan proteksi lokasi sensitif
func (h *HandlerBE2) CreateCommunityPlace(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.CommunityPlaceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.Name) == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: nama tempat wajib diisi",
		})
		return
	}

	// PRD P6.1: Field tips_menjaga adalah MANDATORY untuk kelestarian alam hidden gem
	if strings.TrimSpace(req.TipsMenjaga) == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Aturan PRD P6.1: Field 'tips_menjaga' wajib diisi demi kelestarian alam Ranah Minang",
		})
		return
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}

	finalLat := req.Latitude
	finalLng := req.Longitude
	maskingApplied := false

	// Masking koordinat perkiraan (~800m) jika lokasi ditandai sensitif / terpencil
	if req.IsSensitive {
		maskingApplied = true
		finalLat += 0.0075 // Jitter latitude ~800m
		finalLng += 0.0075
	}

	newPlace := models.CommunityPlace{
		ID:          fmt.Sprintf("cp-%d", time.Now().UnixNano()%100000),
		UserID:      req.UserID,
		Name:        req.Name,
		Category:    req.Category,
		CityRegency: req.CityRegency,
		Description: req.Description,
		Latitude:    finalLat,
		Longitude:   finalLng,
		TipsMenjaga: req.TipsMenjaga,
		IsSensitive: req.IsSensitive,
		Status:      "PENDING_CURATION", // Wajib dikurasi Pokdarwis sebelum publik
		CreatedAt:   time.Now(),
	}

	h.mu.Lock()
	h.communityPlaces = append(h.communityPlaces, newPlace)
	h.mu.Unlock()

	writeJSON(w, http.StatusCreated, ResponseStandar{
		Status:  "success",
		Message: "Tempat baru berhasil diajukan dan sedang menunggu kurasi Pokdarwis",
		Data: map[string]interface{}{
			"place":           newPlace,
			"masking_applied": maskingApplied,
			"note":            "Koordinat telah disamarkan sementara untuk perlindungan lingkungan",
		},
	})
}

// GetCommunityPlaces daftar tempat komunitas yang sedang diajukan
func (h *HandlerBE2) GetCommunityPlaces(w http.ResponseWriter, r *http.Request) {
	h.mu.RLock()
	list := h.communityPlaces
	h.mu.RUnlock()

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Daftar tempat komunitas berhasil dimuat",
		Data: map[string]interface{}{
			"total":  len(list),
			"places": list,
		},
	})
}

// =============================================================================
// 7. KLASTER TRANSAKSI ESCROW & SIMULATOR BOT WHATSAPP (Pilar 5 — Minggu 3)
// =============================================================================

// CreateBooking memesan paket via Quick Drawer 360 & mengunci dana di Escrow
func (h *HandlerBE2) CreateBooking(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.CreateBookingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PartnerID == "" || req.TotalAmount <= 0 {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: partner_id dan total_amount (> 0) wajib diisi",
		})
		return
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}
	if req.Currency == "" {
		req.Currency = "IDR"
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	// Pastikan mitra terdaftar
	var partnerName, partnerWA string
	found := false
	for _, p := range h.partners {
		if p.ID == req.PartnerID {
			found = true
			partnerName = p.Name
			partnerWA = p.WhatsApp
			break
		}
	}

	if !found {
		writeJSON(w, http.StatusNotFound, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Mitra nagari dengan ID '%s' tidak ditemukan", req.PartnerID),
		})
		return
	}

	bookingID := fmt.Sprintf("bkg-%d", time.Now().UnixNano()%100000)
	newBooking := models.BookingEscrow{
		ID:           bookingID,
		PartnerID:    req.PartnerID,
		UserID:       req.UserID,
		TotalAmount:  req.TotalAmount,
		Currency:     req.Currency,
		Status:       "PENDING_WA", // Menunggu konfirmasi balasan Bot WA mitra
		QRCodeTicket: "",
		CreatedAt:    time.Now(),
	}

	h.bookings[bookingID] = &newBooking

	// Simulasi teks template notifikasi yang dikirim ke nomor WhatsApp mitra
	waMessageSimulation := fmt.Sprintf(
		"🔔 *PESANAN BARU MASUK (Rancak.in Escrow)*\n"+
			"Halo %s! Wisatawan telah membayar deposit senilai %s %.2f yang kini diamankan di Rekening Bersama.\n\n"+
			"Balas pesan ini:\n"+
			"👉 Balas *1* untuk MENERIMA pesanan\n"+
			"👉 Balas *0* untuk MENOLAK pesanan",
		partnerName, req.Currency, req.TotalAmount,
	)

	writeJSON(w, http.StatusCreated, ResponseStandar{
		Status:  "success",
		Message: "Pesanan berhasil dibuat, notifikasi konfirmasi dikirim ke WhatsApp mitra",
		Data: map[string]interface{}{
			"booking":               newBooking,
			"partner_whatsapp":      partnerWA,
			"wa_message_simulation": waMessageSimulation,
		},
	})
}

// WAWebhookSimulation memproses webhook balasan Bot WA Mitra (1 = Terima, 0 = Tolak)
func (h *HandlerBE2) WAWebhookSimulation(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.WAWebhookRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.BookingID == "" || req.Action == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: booking_id dan action ('1' atau '0') wajib diisi",
		})
		return
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	booking, exists := h.bookings[req.BookingID]
	if !exists {
		// Buat simulasi booking on-the-fly jika ID baru untuk kemudahan simulator FS-1
		booking = &models.BookingEscrow{
			ID:          req.BookingID,
			PartnerID:   "ptr-01",
			UserID:      "usr-001",
			TotalAmount: 250000.00,
			Currency:    "IDR",
			CreatedAt:   time.Now(),
		}
		h.bookings[req.BookingID] = booking
	}

	if req.Action == "1" {
		// Mitra Balas '1' -> Terima Pesanan -> Dana masuk status ESCROW_LOCKED -> Terbitkan QR
		booking.Status = "ESCROW_LOCKED"
		booking.QRCodeTicket = fmt.Sprintf("QR-RANCAK-TKT-%s", booking.ID)

		writeJSON(w, http.StatusOK, ResponseStandar{
			Status:  "success",
			Message: "Pesanan DITERIMA mitra (Action 1). E-Ticket QR diterbitkan & dana dikunci di Escrow.",
			Data: map[string]interface{}{
				"booking_id":     booking.ID,
				"status":         booking.Status,
				"qr_code_ticket": booking.QRCodeTicket,
				"escrow_locked":  true,
				"note":           "Tunjukkan QR ini kepada mitra saat tiba di lokasi untuk pencairan dana",
			},
		})
		return
	} else if req.Action == "0" {
		// Mitra Balas '0' -> Tolak Pesanan -> Dana dikembalikan ke wisatawan
		booking.Status = "REFUNDED"
		booking.QRCodeTicket = ""

		writeJSON(w, http.StatusOK, ResponseStandar{
			Status:  "success",
			Message: "Pesanan DITOLAK mitra (Action 0). Dana telah dikembalikan penuh ke wisatawan (REFUNDED).",
			Data: map[string]interface{}{
				"booking_id": booking.ID,
				"status":     booking.Status,
				"refunded":   true,
			},
		})
		return
	}

	writeJSON(w, http.StatusBadRequest, ResponseStandar{
		Status:  "error",
		Message: "Nilai action tidak valid, harus '1' (Terima) atau '0' (Tolak)",
	})
}

// GetBookingTicketQR mengambil payload QR E-Ticket setelah dikonfirmasi mitra
func (h *HandlerBE2) GetBookingTicketQR(w http.ResponseWriter, r *http.Request) {
	bookingID := r.PathValue("id")
	if bookingID == "" {
		bookingID = r.URL.Query().Get("id")
	}

	if bookingID == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Parameter booking id wajib diisi",
		})
		return
	}

	h.mu.RLock()
	booking, exists := h.bookings[bookingID]
	h.mu.RUnlock()

	if !exists {
		writeJSON(w, http.StatusNotFound, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Pesanan dengan ID '%s' tidak ditemukan", bookingID),
		})
		return
	}

	if booking.Status == "PENDING_WA" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Tiket QR belum terbit: Menunggu konfirmasi balasan WhatsApp dari mitra",
		})
		return
	}

	if booking.Status == "REFUNDED" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Tiket tidak aktif: Pesanan telah ditolak dan dana dikembalikan",
		})
		return
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "E-Ticket QR berhasil dimuat",
		Data: map[string]interface{}{
			"booking_id":     booking.ID,
			"qr_code_ticket": booking.QRCodeTicket,
			"status":         booking.Status,
			"partner_id":     booking.PartnerID,
			"total_amount":   booking.TotalAmount,
			"currency":       booking.Currency,
		},
	})
}

// ScanRedeemEscrow mitra memindai QR E-Ticket saat tamu tiba untuk mencairkan dana escrow
func (h *HandlerBE2) ScanRedeemEscrow(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.ScanRedeemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.QRCodeTicket == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: qr_code_ticket wajib diisi",
		})
		return
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	var targetBooking *models.BookingEscrow
	for _, b := range h.bookings {
		if b.QRCodeTicket == req.QRCodeTicket {
			targetBooking = b
			break
		}
	}

	if targetBooking == nil {
		writeJSON(w, http.StatusNotFound, ResponseStandar{
			Status:  "error",
			Message: "Tiket QR tidak valid atau tidak terdaftar di sistem",
		})
		return
	}

	if targetBooking.Status == "REDEEMED" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Peringatan: Tiket ini sudah pernah dicairkan sebelumnya (*Redeemed*)",
		})
		return
	}

	if targetBooking.Status != "ESCROW_LOCKED" && targetBooking.Status != "CONFIRMED" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Tiket tidak dapat dicairkan (Status saat ini: %s)", targetBooking.Status),
		})
		return
	}

	// Ubah status ke REDEEMED (Dana cair ke rekening mitra)
	targetBooking.Status = "REDEEMED"

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Tiket QR VALID! Kunjungan tamu terverifikasi. Dana sebesar %s %.2f berhasil dicairkan ke rekening mitra.",
			targetBooking.Currency, targetBooking.TotalAmount),
		Data: map[string]interface{}{
			"booking_id":        targetBooking.ID,
			"status":            targetBooking.Status,
			"disbursed_amount":  targetBooking.TotalAmount,
			"currency":          targetBooking.Currency,
			"redeemed_at":       time.Now().Format(time.RFC3339),
		},
	})
}

// GetMYRConversionRate kurs konversi mata uang MYR/IDR untuk wisatawan Malaysia
func (h *HandlerBE2) GetMYRConversionRate(w http.ResponseWriter, r *http.Request) {
	rateMYRtoIDR := 3550.00
	rateIDRtoMYR := math.Round((1.0/rateMYRtoIDR)*1000000) / 1000000

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Kurs konversi resmi DuitNow / QRIS Minangkabau berhasil dimuat",
		Data: map[string]interface{}{
			"base_currency":    "MYR",
			"target_currency":  "IDR",
			"rate_myr_to_idr":  rateMYRtoIDR,
			"rate_idr_to_myr":  rateIDRtoMYR,
			"supported_method": []string{"QRIS (Indonesia)", "DuitNow Cross-Border (Malaysia)"},
			"updated_at":       time.Now().Format("2006-01-02 15:04:05"),
		},
	})
}

// =============================================================================
// 8. KLASTER SPLIT-BILL & GROUP LIVE RADAR (Pilar 4 — Minggu 3)
// =============================================================================

// SplitBill menghitung pembagian rata tagihan sewa armada/homestay per orang
func (h *HandlerBE2) SplitBill(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	code := r.PathValue("code")
	if code == "" {
		code = r.URL.Query().Get("code")
	}

	var req models.SplitBillRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TotalAmount <= 0 {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: total_amount (> 0) wajib diisi",
		})
		return
	}

	h.mu.RLock()
	room, roomExists := h.groupRooms[code]
	h.mu.RUnlock()

	var members []string
	if len(req.MemberIDs) > 0 {
		members = req.MemberIDs
	} else if roomExists && len(room.Members) > 0 {
		for _, m := range room.Members {
			members = append(members, m.UserID)
		}
	} else {
		// Fallback default 4 anggota rombongan
		members = []string{"usr-001", "usr-002", "usr-003", "usr-004"}
	}

	memberCount := len(members)
	amountPerPerson := math.Round((req.TotalAmount/float64(memberCount))*100) / 100

	var shares []models.SplitBillMemberShare
	for _, mID := range members {
		shares = append(shares, models.SplitBillMemberShare{
			UserID:      mID,
			Amount:      amountPerPerson,
			PaymentLink: fmt.Sprintf("https://wisgo.sumbar.go.id/pay/qris?amount=%.2f&user=%s&ref=%s", amountPerPerson, mID, code),
		})
	}

	resp := models.SplitBillResponse{
		TotalAmount:     req.TotalAmount,
		MemberCount:     memberCount,
		AmountPerPerson: amountPerPerson,
		Description:     req.Description,
		Shares:          shares,
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Tagihan Rp %.2f berhasil dibagi rata ke %d anggota", req.TotalAmount, memberCount),
		Data:    resp,
	})
}

// RadarPing menerima ping koordinat GPS opt-in dari anggota rombongan
func (h *HandlerBE2) RadarPing(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	code := r.PathValue("code")
	if code == "" {
		code = r.URL.Query().Get("code")
	}

	var req models.RadarPingRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.UserID == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: user_id wajib diisi",
		})
		return
	}

	h.mu.Lock()
	if _, ok := h.groupRadars[code]; !ok {
		h.groupRadars[code] = make(map[string]models.MemberRadarLocation)
	}
	h.groupRadars[code][req.UserID] = models.MemberRadarLocation{
		UserID:    req.UserID,
		Latitude:  req.Latitude,
		Longitude: req.Longitude,
		UpdatedAt: time.Now(),
	}
	h.mu.Unlock()

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Koordinat radar live anggota berhasil diperbarui",
		Data:    req,
	})
}

// GetGroupRadar mengambil seluruh posisi radar anggota rombongan
func (h *HandlerBE2) GetGroupRadar(w http.ResponseWriter, r *http.Request) {
	code := r.PathValue("code")
	if code == "" {
		code = r.URL.Query().Get("code")
	}

	h.mu.RLock()
	locationsMap, exists := h.groupRadars[code]
	h.mu.RUnlock()

	var locations []models.MemberRadarLocation
	if exists {
		for _, loc := range locationsMap {
			locations = append(locations, loc)
		}
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Data Group Live Radar berhasil dimuat",
		Data: map[string]interface{}{
			"group_room_code":  code,
			"active_members":   len(locations),
			"member_locations": locations,
		},
	})
}

// =============================================================================
// 9. KLASTER PAPAN CARI BARENGAN / SHARED TRIPS (Pilar 6 — Minggu 3)
// =============================================================================

// GetSharedTrips mengambil daftar papan cari barengan sewa armada
func (h *HandlerBE2) GetSharedTrips(w http.ResponseWriter, r *http.Request) {
	h.mu.RLock()
	list := h.sharedTrips
	h.mu.RUnlock()

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Papan cari barengan berhasil dimuat",
		Data: map[string]interface{}{
			"total": len(list),
			"trips": list,
		},
	})
}

// CreateSharedTrip membuat postingan patungan armada baru
func (h *HandlerBE2) CreateSharedTrip(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan, gunakan POST",
		})
		return
	}

	var req models.CreateSharedTripRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.Title) == "" || strings.TrimSpace(req.DestinationRoute) == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload tidak valid: title dan destination_route wajib diisi",
		})
		return
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}
	if req.AvailableSeats <= 0 {
		req.AvailableSeats = 1
	}

	newTrip := models.SharedTrip{
		ID:               fmt.Sprintf("st-%d", time.Now().UnixNano()%100000),
		UserID:           req.UserID,
		Title:            req.Title,
		DestinationRoute: req.DestinationRoute,
		DepartureDate:    req.DepartureDate,
		AvailableSeats:   req.AvailableSeats,
		CostPerPerson:    req.CostPerPerson,
		ContactWA:        req.ContactWA,
		CreatedAt:        time.Now(),
	}

	h.mu.Lock()
	h.sharedTrips = append(h.sharedTrips, newTrip)
	h.mu.Unlock()

	writeJSON(w, http.StatusCreated, ResponseStandar{
		Status:  "success",
		Message: "Postingan cari barengan berhasil dipublikasikan",
		Data:    newTrip,
	})
}

// =============================================================================
// PILAR 6 & 8 (MINGGU 4): PASPOR DIGITAL MINANG, ANTI-FAKE GPS & ANALITIK DISPAR
// =============================================================================

// calculateHaversineDistance menghitung jarak antara dua koordinat GPS dalam satuan meter
func calculateHaversineDistance(lat1, lon1, lat2, lon2 float64) float64 {
	const earthRadius = 6371000.0 // meter
	dLat := (lat2 - lat1) * (math.Pi / 180.0)
	dLon := (lon2 - lon1) * (math.Pi / 180.0)

	lat1Rad := lat1 * (math.Pi / 180.0)
	lat2Rad := lat2 * (math.Pi / 180.0)

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*math.Sin(dLon/2)*math.Sin(dLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return earthRadius * c
}

// ValidateGPSCheckIn menangani POST /api/v1/gamification/checkin
// Validasi Anti-Fake GPS: wisatawan wajib berada dalam radius <= 200m dari titik ikonik
func (h *HandlerBE2) ValidateGPSCheckIn(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan",
		})
		return
	}

	var req models.CheckInRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "Payload check-in tidak valid",
		})
		return
	}

	if req.UserID == "" || req.DestinationID == "" {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: "user_id dan destination_id wajib diisi",
		})
		return
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	// Cari titik ikonik
	var targetSpot *models.IconicSpotItem
	for i := range h.iconicSpots {
		if h.iconicSpots[i].ID == req.DestinationID || strings.EqualFold(h.iconicSpots[i].Name, req.DestinationID) {
			targetSpot = &h.iconicSpots[i]
			break
		}
	}

	if targetSpot == nil {
		writeJSON(w, http.StatusNotFound, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Titik destinasi '%s' tidak ditemukan dalam daftar Paspor Digital Minang", req.DestinationID),
		})
		return
	}

	// Hitung jarak Haversine (meter)
	distance := calculateHaversineDistance(req.Latitude, req.Longitude, targetSpot.Latitude, targetSpot.Longitude)

	// Validasi Anti-Fake GPS (radius <= 200.0m)
	if distance > 200.0 {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Check-in ditolak (Anti-Fake GPS): Lokasi Anda berjarak %.1f meter dari %s (Maksimal radius valid 200 meter)", distance, targetSpot.Name),
			Data: map[string]interface{}{
				"is_within_radius": false,
				"distance_meters":  math.Round(distance*10) / 10,
				"max_radius":       200.0,
				"destination_name": targetSpot.Name,
			},
		})
		return
	}

	// Catat stempel
	if h.passports[req.UserID] == nil {
		h.passports[req.UserID] = make(map[string]time.Time)
	}
	now := time.Now()
	h.passports[req.UserID][targetSpot.ID] = now

	totalStamps := len(h.passports[req.UserID])

	respData := models.CheckInResponse{
		DestinationID:   targetSpot.ID,
		DestinationName: targetSpot.Name,
		DistanceMeters:  math.Round(distance*10) / 10,
		IsWithinRadius:  true,
		CheckedInAt:     now,
		BadgeEarned:     targetSpot.BadgeName,
		TotalStamps:     totalStamps,
		MaxStamps:       len(h.iconicSpots),
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Check-in GPS Valid! Anda berhasil membuka stempel '%s' (%d/10 titik)", targetSpot.BadgeName, totalStamps),
		Data:    respData,
	})
}

// GetDigitalPassport menangani GET /api/v1/gamification/passport
// Rekap stempel paspor digital (10 titik ikonik Minang)
func (h *HandlerBE2) GetDigitalPassport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan",
		})
		return
	}

	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		userID = "usr-001" // default fallback
	}

	h.mu.RLock()
	defer h.mu.RUnlock()

	userStamps := h.passports[userID]
	totalStamps := len(userStamps)
	totalRequired := len(h.iconicSpots)
	if totalRequired == 0 {
		totalRequired = 10
	}

	spots := make([]models.IconicSpotItem, len(h.iconicSpots))
	for i, spot := range h.iconicSpots {
		item := spot
		if stampTime, ok := userStamps[spot.ID]; ok {
			item.IsCompleted = true
			item.CompletedAt = &stampTime
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

	resp := models.PassportSummaryResponse{
		UserID:                   userID,
		TotalStamps:              totalStamps,
		RequiredStamps:           totalRequired,
		CompletionPercentage:     math.Round(percent*10) / 10,
		IsEligibleForCertificate: totalStamps >= totalRequired,
		Spots:                    spots,
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: fmt.Sprintf("Rekapitulasi Paspor Digital Minang: %d dari %d titik ikonik terkumpul", totalStamps, totalRequired),
		Data:    resp,
	})
}

// GenerateGovernorCertificate menangani POST /api/v1/gamification/certificate
// Menerbitkan Sertifikat Digital resmi Gubernur Sumbar jika sudah mengumpulkan 10 titik ikonik
func (h *HandlerBE2) GenerateGovernorCertificate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost && r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan",
		})
		return
	}

	var req models.CertificateRequest
	if r.Method == http.MethodPost {
		_ = json.NewDecoder(r.Body).Decode(&req)
	} else {
		req.UserID = r.URL.Query().Get("user_id")
		req.FullName = r.URL.Query().Get("full_name")
	}

	if req.UserID == "" {
		req.UserID = "usr-001"
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	if req.FullName == "" {
		if u, ok := h.users[req.UserID]; ok && u.FullName != "" {
			req.FullName = u.FullName
		} else {
			req.FullName = "Wisatawan Teladan Ranah Minang"
		}
	}

	// Cek apakah sudah pernah diterbitkan sebelumnya
	if cert, exists := h.certificates[req.UserID]; exists {
		writeJSON(w, http.StatusOK, ResponseStandar{
			Status:  "success",
			Message: "Sertifikat Digital Gubernur Anda sudah aktif dan terverifikasi",
			Data:    cert,
		})
		return
	}

	totalStamps := len(h.passports[req.UserID])
	requiredStamps := len(h.iconicSpots)
	if requiredStamps == 0 {
		requiredStamps = 10
	}

	// Validasi kelayakan: harus sudah mengumpulkan minimal 10 stempel
	if totalStamps < requiredStamps {
		writeJSON(w, http.StatusBadRequest, ResponseStandar{
			Status:  "error",
			Message: fmt.Sprintf("Sertifikat belum dapat diterbitkan. Anda baru mengumpulkan %d dari %d stempel titik ikonik Minangkabau.", totalStamps, requiredStamps),
			Data: map[string]interface{}{
				"stamps_collected": totalStamps,
				"stamps_required":  requiredStamps,
				"is_eligible":      false,
			},
		})
		return
	}

	// Terbitkan sertifikat baru
	certID := fmt.Sprintf("WISGO-GUB-SB-%d-%04d", time.Now().Year(), time.Now().UnixNano()%10000)
	now := time.Now()

	cert := models.CertificateResponse{
		CertificateID:     certID,
		RecipientName:     req.FullName,
		IssuedAt:          now,
		TotalSpotsVisited: totalStamps,
		SignatoryTitle:    "Gubernur Sumatera Barat & Kepala Dinas Pariwisata Prov. Sumbar",
		SignatoryName:     "H. Mahyeldi Ansharullah, S.P. (Gubernur Sumbar)",
		VerificationURL:   fmt.Sprintf("https://wisgo.sumbarprov.go.id/verify/cert/%s", certID),
		QRCodeURL:         fmt.Sprintf("https://api.wisgo.sumbarprov.go.id/api/v1/certificates/verify-qr?id=%s", certID),
		PDFDownloadURL:    fmt.Sprintf("https://api.wisgo.sumbarprov.go.id/api/v1/certificates/download-pdf?id=%s", certID),
	}

	h.certificates[req.UserID] = cert

	writeJSON(w, http.StatusCreated, ResponseStandar{
		Status:  "success",
		Message: "Selamat! Sertifikat Digital Resmi Gubernur Sumatera Barat berhasil diterbitkan",
		Data:    cert,
	})
}

// GetDisparAnalyticsSummary menangani GET /api/v1/analytics/dispar/summary
// Agregasi analitik real-time Dispar Sumbar & pimpinan daerah (Pilar 8)
func (h *HandlerBE2) GetDisparAnalyticsSummary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, ResponseStandar{
			Status:  "error",
			Message: "Method tidak diizinkan",
		})
		return
	}

	h.mu.RLock()
	defer h.mu.RUnlock()

	// 1. Agregasi Escrow Turnover & Status Booking
	var totalEscrowTurnover float64
	qrScansCount := 0
	for _, b := range h.bookings {
		if b.Status == "ESCROW_LOCKED" || b.Status == "REDEEMED" {
			totalEscrowTurnover += b.TotalAmount
		}
		if b.Status == "REDEEMED" {
			qrScansCount++
		}
	}

	// 2. Agregasi Check-In Paspor
	totalCheckIns := 0
	for _, userStamps := range h.passports {
		totalCheckIns += len(userStamps)
		qrScansCount += len(userStamps)
	}

	// 3. Total Kunjungan
	totalVisits := 1420 + totalCheckIns*15 + len(h.bookings)*8

	// 4. Kategori Mitra
	categoryDist := make(map[string]int)
	for _, p := range h.partners {
		categoryDist[p.Category]++
	}

	// 5. Heatmap 19 Kabupaten/Kota di Sumatera Barat
	regencies := []models.RegencyDensityItem{
		{RegencyName: "Kota Bukittinggi", Occupancy: "tinggi", ActiveGuests: 1850 + totalCheckIns*5},
		{RegencyName: "Kota Padang", Occupancy: "tinggi", ActiveGuests: 2340 + totalCheckIns*4},
		{RegencyName: "Kab. Tanah Datar", Occupancy: "tinggi", ActiveGuests: 1210 + totalCheckIns*3},
		{RegencyName: "Kab. Lima Puluh Kota", Occupancy: "sedang", ActiveGuests: 980},
		{RegencyName: "Kab. Agam", Occupancy: "sedang", ActiveGuests: 840},
		{RegencyName: "Kab. Pesisir Selatan", Occupancy: "sedang", ActiveGuests: 760},
		{RegencyName: "Kota Sawahlunto", Occupancy: "sedang", ActiveGuests: 520},
		{RegencyName: "Kab. Solok", Occupancy: "sedang", ActiveGuests: 610},
		{RegencyName: "Kota Payakumbuh", Occupancy: "sedang", ActiveGuests: 580},
		{RegencyName: "Kota Padang Panjang", Occupancy: "sedang", ActiveGuests: 490},
		{RegencyName: "Kota Pariaman", Occupancy: "normal", ActiveGuests: 380},
		{RegencyName: "Kab. Padang Pariaman", Occupancy: "normal", ActiveGuests: 410},
		{RegencyName: "Kota Solok", Occupancy: "normal", ActiveGuests: 290},
		{RegencyName: "Kab. Solok Selatan", Occupancy: "normal", ActiveGuests: 210},
		{RegencyName: "Kab. Sijunjung", Occupancy: "normal", ActiveGuests: 180},
		{RegencyName: "Kab. Dharmasraya", Occupancy: "normal", ActiveGuests: 150},
		{RegencyName: "Kab. Pasaman", Occupancy: "normal", ActiveGuests: 190},
		{RegencyName: "Kab. Pasaman Barat", Occupancy: "normal", ActiveGuests: 220},
		{RegencyName: "Kab. Kepulauan Mentawai", Occupancy: "normal", ActiveGuests: 310},
	}

	// 6. Top Destinasi
	topDestinations := []models.TopDestinationMetric{
		{DestinationID: "spot-jam-gadang", DestinationName: "Jam Gadang Bukittinggi", Regency: "Kota Bukittinggi", TotalCheckIns: 432 + totalCheckIns},
		{DestinationID: "spot-pagaruyung", DestinationName: "Istano Basa Pagaruyung", Regency: "Kab. Tanah Datar", TotalCheckIns: 389},
		{DestinationID: "spot-lembah-harau", DestinationName: "Lembah Harau & Kelok 9", Regency: "Kab. Lima Puluh Kota", TotalCheckIns: 341},
		{DestinationID: "spot-kawasan-mandeh", DestinationName: "Kawasan Bahari Mandeh", Regency: "Kab. Pesisir Selatan", TotalCheckIns: 295},
		{DestinationID: "spot-danau-maninjau", DestinationName: "Danau Maninjau", Regency: "Kab. Agam", TotalCheckIns: 260},
	}

	summary := models.DisparAnalyticsSummary{
		TotalVisits:               totalVisits,
		TotalQRScans:              qrScansCount + 850,
		TotalEscrowTurnover:       totalEscrowTurnover + 45250000.0,
		TotalUMKMPartners:         len(h.partners),
		RegencyDensityHeatmap:     regencies,
		TopDestinations:           topDestinations,
		MitraCategoryDistribution: categoryDist,
	}

	writeJSON(w, http.StatusOK, ResponseStandar{
		Status:  "success",
		Message: "Ringkasan analitik eksekutif Dispar Sumbar berhasil dimuat",
		Data:    summary,
	})
}

