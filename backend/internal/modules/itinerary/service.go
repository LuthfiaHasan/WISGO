package itinerary

import (
	"errors"
	"fmt"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis murni untuk Rencana Perjalanan & Auto-Generator (Pilar 4)
type Service interface {
	AutoGenerate(req AutoItineraryRequest) (*models.Itinerary, error)
	GetUserItineraries(userID string) ([]models.Itinerary, error)
	CreateManual(req CreateItineraryRequest) (*models.Itinerary, error)
}

type itineraryService struct {
	repo Repository
}

// NewService membuat instance baru dari ItineraryService
func NewService(repo Repository) Service {
	return &itineraryService{repo: repo}
}

func (s *itineraryService) AutoGenerate(req AutoItineraryRequest) (*models.Itinerary, error) {
	if req.UserID == "" {
		return nil, errors.New("user_id wajib diisi")
	}

	days := req.DurationDays
	if days < 1 {
		days = 1
	} else if days > 7 {
		days = 7
	}

	startDate := time.Now().AddDate(0, 0, 1) // Mulai besok
	endDate := startDate.AddDate(0, 0, days)
	itineraryID := fmt.Sprintf("itin-auto-%d", time.Now().UnixNano()%100000)

	// Koridor Geografis Sumatera Barat Terpadu (Tanpa Rute Bolak-Balik)
	dayPlans := []struct {
		dayNumber    int
		destination  string
		destID       string
		timeSlot     string
		notes        string
		trafficAlert string
	}{
		// Hari 1: Koridor BIM -> Lembah Anai -> Padang Panjang -> Bukittinggi
		{1, "Lembah Anai & PDIKM Padang Panjang", "dest-anai", "09:30", "Mendarat di BIM, singgah di Air Terjun Lembah Anai & Pusat Budaya Minangkabau", "Jalur Lembah Anai / Silaiang rawan basah & licin pasca hujan"},
		{1, "Jam Gadang & Ngarai Sianok Bukittinggi", "dest-jamgadang", "15:00", "Check-in hotel di Bukittinggi, jalan sore ke Jam Gadang & Ngarai Sianok", "Pasar Koto Baru Padang Panjang rawan macet pasar tumpah pagi-siang"},

		// Hari 2: Koridor Payakumbuh -> Lembah Harau -> Kelok 9 -> Istano Pagaruyung
		{2, "Lembah Harau & Jembatan Kelok 9", "dest-harau", "08:30", "Eksplorasi tebing granit Lembah Harau dan mahakarya Kelok 9", "Kelok 9 ramai saat akhir pekan & libur nasional"},
		{2, "Istano Basa Pagaruyung Batusangkar", "dest-pagaruyung", "14:30", "Mengenakan pakaian adat Minang di Istana Kerajaan Pagaruyung", "Jalur Batusangkar berliku namun aspal mulus"},

		// Hari 3: Koridor Danau Singkarak -> Solok -> Danau Kembar
		{3, "Danau Singkarak & Dermaga Singkarak", "dest-singkarak", "09:00", "Menikmati ikan bilih goreng khas Singkarak dengan panorama danau terluas", "Truk muatan besar melintas di jalur lintas Solok"},
		{3, "Danau Kembar & Kebun Teh Alahan Panjang", "dest-kembar", "14:00", "Udara sejuk pegunungan di Danau Diatas & Dibawah serta hamparan kebun teh", "Suhu dingin berkabut pada sore hari (16-18°C)"},

		// Hari 4: Bahari Mandeh (Pesisir Selatan)
		{4, "Kawasan Wisata Bahari Mandeh", "dest-mandeh", "08:30", "Eksplorasi Raja Ampat-nya Sumbar: Pulau Setan, Sironjong Ketek & Hutan Mangrove", "Patuhi pemakaian life jacket saat menaiki kapal perahu"},

		// Hari 5: Maninjau -> Kelok 44 -> Desa Pariangan
		{5, "Danau Maninjau via Kelok 44", "dest-maninjau", "09:00", "Sensasi turunan ekstrem 44 kelokan legendaris menghadap danau vulkanik", "Gunakan gigi rendah saat menuruni Kelok 44 (rawan rem blong)"},
		{5, "Nagari Tuo Pariangan (Desa Terindah)", "dest-pariangan", "14:30", "Menyusuri desa tertua asal muasal peradaban Minang di lereng Marapi", "Patuhi norma adat nagari & kenakan pakaian sopan"},

		// Hari 6: Kota Tua Padang & Pantai
		{6, "Kota Tua Padang & Jembatan Siti Nurbaya", "dest-kotatua", "10:00", "Wisata heritage kolonial pecinan Padang & cerita legendaris Siti Nurbaya", "Lalu lintas kota Padang padat saat jam pulang kantor"},
		{6, "Pantai Padang (Taplau) & Sunset", "dest-taplau", "16:30", "Menikmati kelapa muda, pisang bakar, & matahari terbenam Samudera Hindia", "Parkir di kantong resmi yang ditetapkan Perda Dispar Padang"},

		// Hari 7: Belanja Oleh-Oleh & Kepulangan BIM
		{7, "Pusat Oleh-Oleh Keripik Balado Sanjai", "dest-oleholeh", "09:00", "Belanja keripik sanjai balado, rendang kemasan, & songket Minang", "Siapkan bagasi ekstra untuk kemasan kardus oleh-oleh"},
		{7, "Pintu Keberangkatan Bandara BIM", "dest-bim", "13:00", "Pengantaran kembali ke Bandara Internasional Minangkabau", "Tiba di BIM minimal 2 jam sebelum jadwal boarding pesawat"},
	}

	var items []models.ItineraryItem
	itemCount := 1
	for _, dp := range dayPlans {
		if dp.dayNumber <= days {
			items = append(items, models.ItineraryItem{
				ID:            fmt.Sprintf("item-%d-%02d", time.Now().UnixNano()%10000, itemCount),
				ItineraryID:   itineraryID,
				DayNumber:     dp.dayNumber,
				TimeSlot:      dp.timeSlot,
				DestinationID: dp.destID,
				Notes:         fmt.Sprintf("%s (%s)", dp.destination, dp.notes),
				TrafficAlert:  dp.trafficAlert,
			})
			itemCount++
		}
	}

	title := fmt.Sprintf("Jelajah Eksotisme Ranah Minang (%d Hari Pintar)", days)
	if req.TravelerType == "family" {
		title = fmt.Sprintf("Wisata Keluarga Ramah Anak Ranah Minang (%d Hari)", days)
	} else if req.TravelerType == "culinary" {
		title = fmt.Sprintf("Wisata Kuliner Rendang & Warisan Minang (%d Hari)", days)
	}

	itinerary := models.Itinerary{
		ID:        itineraryID,
		UserID:    req.UserID,
		Title:     title,
		StartDate: startDate.Format("2006-01-02"),
		EndDate:   endDate.Format("2006-01-02"),
		TotalDays: days,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		Items:     items,
	}

	if err := s.repo.Save(itinerary); err != nil {
		return nil, err
	}

	return &itinerary, nil
}

func (s *itineraryService) GetUserItineraries(userID string) ([]models.Itinerary, error) {
	if userID == "" {
		userID = "usr-001"
	}
	return s.repo.FindByUserID(userID)
}

func (s *itineraryService) CreateManual(req CreateItineraryRequest) (*models.Itinerary, error) {
	if req.UserID == "" || req.Title == "" {
		return nil, errors.New("user_id dan title wajib diisi")
	}

	start, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		start = time.Now()
	}

	end, err := time.Parse("2006-01-02", req.EndDate)
	if err != nil {
		end = start.AddDate(0, 0, 1)
	}

	totalDays := req.TotalDays
	if totalDays <= 0 {
		totalDays = int(end.Sub(start).Hours()/24) + 1
	}

	itineraryID := fmt.Sprintf("itin-man-%d", time.Now().UnixNano()%100000)
	itinerary := models.Itinerary{
		ID:        itineraryID,
		UserID:    req.UserID,
		Title:     req.Title,
		StartDate: req.StartDate,
		EndDate:   req.EndDate,
		TotalDays: totalDays,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		Items:     req.Items,
	}

	if err := s.repo.Save(itinerary); err != nil {
		return nil, err
	}

	return &itinerary, nil
}
