package be2_group

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

func TestRequestAndVerifyOTP(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Uji Request OTP Sukses
	reqBody, _ := json.Marshal(models.OTPRequest{
		PhoneNumber: "081211112222",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader(reqBody))
	w := httptest.NewRecorder()
	h.RequestOTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}

	var reqResp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &reqResp)
	if reqResp.Status != "success" {
		t.Fatalf("Expected status success, got %s", reqResp.Status)
	}

	// 2. Uji Verify OTP dengan kode master dev "1234"
	verifyBody, _ := json.Marshal(models.OTPVerifyRequest{
		PhoneNumber: "081211112222",
		OTPCode:     "1234",
	})
	reqVerify := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(verifyBody))
	wVerify := httptest.NewRecorder()
	h.VerifyOTP(wVerify, reqVerify)

	if wVerify.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", wVerify.Code)
	}

	var verifyResp ResponseStandar
	_ = json.Unmarshal(wVerify.Body.Bytes(), &verifyResp)
	if verifyResp.Status != "success" {
		t.Fatalf("Expected verify success, got %s", verifyResp.Status)
	}
}

func TestRequestOTP_InvalidPayload(t *testing.T) {
	h := NewHandlerBE2()

	// Request dengan phone number kosong
	reqBody, _ := json.Marshal(models.OTPRequest{
		PhoneNumber: "",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader(reqBody))
	w := httptest.NewRecorder()
	h.RequestOTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("Expected status 400 for empty phone, got %d", w.Code)
	}
}

func TestVerifyOTP_WrongCode(t *testing.T) {
	h := NewHandlerBE2()

	// Verify dengan kode salah
	verifyBody, _ := json.Marshal(models.OTPVerifyRequest{
		PhoneNumber: "081211112222",
		OTPCode:     "9999",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(verifyBody))
	w := httptest.NewRecorder()
	h.VerifyOTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("Expected status 401 for wrong OTP, got %d", w.Code)
	}
}

func TestGetPartnersKatalogAndFilterSpicy(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Uji filter kuliner dengan level pedas 4 (Itiak Lado Mudo)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners?category=Kuliner&spicy_level=4", nil)
	w := httptest.NewRecorder()
	h.GetPartnersKatalog(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	dataMap := resp.Data.(map[string]interface{})
	total := int(dataMap["total"].(float64))
	if total != 1 {
		t.Fatalf("Expected 1 partner for spicy level 4, got %d", total)
	}

	// 2. Uji filter nagari
	reqNagari := httptest.NewRequest(http.MethodGet, "/api/v1/partners?nagari=Sungai+Buluah", nil)
	wNagari := httptest.NewRecorder()
	h.GetPartnersKatalog(wNagari, reqNagari)

	var respNagari ResponseStandar
	_ = json.Unmarshal(wNagari.Body.Bytes(), &respNagari)
	dataNagari := respNagari.Data.(map[string]interface{})
	totalNagari := int(dataNagari["total"].(float64))
	if totalNagari != 1 {
		t.Fatalf("Expected 1 partner for Sungai Buluah, got %d", totalNagari)
	}
}

func TestGetPartnerDetail(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Temukan mitra yang valid
	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners/detail?id=ptr-01", nil)
	w := httptest.NewRecorder()
	h.GetPartnerDetail(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}

	// 2. Mitra tidak ditemukan
	reqNotFound := httptest.NewRequest(http.MethodGet, "/api/v1/partners/detail?id=ptr-9999", nil)
	wNotFound := httptest.NewRecorder()
	h.GetPartnerDetail(wNotFound, reqNotFound)

	if wNotFound.Code != http.StatusNotFound {
		t.Fatalf("Expected status 404, got %d", wNotFound.Code)
	}
}

func TestToggleSavedPlaces(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Simpan destinasi baru (dest-002 Jam Gadang)
	toggleBody, _ := json.Marshal(map[string]string{
		"user_id":        "usr-001",
		"destination_id": "dest-002",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/users/saved", bytes.NewReader(toggleBody))
	w := httptest.NewRecorder()
	h.ToggleSavedPlace(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}

	// 2. Ambil daftar tersimpan (awalnya 1 ditambah 1 = 2)
	reqGet := httptest.NewRequest(http.MethodGet, "/api/v1/users/saved?user_id=usr-001", nil)
	wGet := httptest.NewRecorder()
	h.GetSavedPlaces(wGet, reqGet)

	var getResp ResponseStandar
	_ = json.Unmarshal(wGet.Body.Bytes(), &getResp)
	dataMap := getResp.Data.(map[string]interface{})
	totalSaved := int(dataMap["total_saved"].(float64))
	if totalSaved != 2 {
		t.Fatalf("Expected 2 saved places, got %d", totalSaved)
	}

	// 3. Toggle kembali (Unsave dest-002)
	reqUnsave := httptest.NewRequest(http.MethodPost, "/api/v1/users/saved", bytes.NewReader(toggleBody))
	wUnsave := httptest.NewRecorder()
	h.ToggleSavedPlace(wUnsave, reqUnsave)

	if wUnsave.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", wUnsave.Code)
	}

	var unsaveResp ResponseStandar
	_ = json.Unmarshal(wUnsave.Body.Bytes(), &unsaveResp)
	unsaveData := unsaveResp.Data.(map[string]interface{})
	if unsaveData["is_saved"].(bool) != false {
		t.Fatalf("Expected is_saved to be false after toggle off")
	}
}

// =============================================================================
// UNIT TESTS MINGGU 2 (ITINERARY, GROUP ROOM, VOTING & COMMUNITY)
// =============================================================================

func TestAutoGenerateItinerary(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Auto generate jadwal 3 hari
	reqBody, _ := json.Marshal(models.AutoItineraryRequest{
		UserID:       "usr-001",
		DurationDays: 3,
		ArrivalPoint: "BIM",
		TravelerType: "family",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/itineraries/auto-generate", bytes.NewReader(reqBody))
	w := httptest.NewRecorder()
	h.AutoGenerateItinerary(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "success" {
		t.Fatalf("Expected status success, got %s", resp.Status)
	}

	// 2. Cek history itinerary
	reqHistory := httptest.NewRequest(http.MethodGet, "/api/v1/itineraries?user_id=usr-001", nil)
	wHistory := httptest.NewRecorder()
	h.GetItineraries(wHistory, reqHistory)

	var histResp ResponseStandar
	_ = json.Unmarshal(wHistory.Body.Bytes(), &histResp)
	histData := histResp.Data.(map[string]interface{})
	totalTrips := int(histData["total_trips"].(float64))
	if totalTrips < 2 { // Awalnya ada 1, ditambah 1 dari auto-generate = minimal 2
		t.Fatalf("Expected at least 2 itineraries, got %d", totalTrips)
	}
}

func TestCreateGroupRoomAndGet(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Buat room baru
	reqBody, _ := json.Marshal(models.CreateGroupRequest{
		LeaderID: "usr-001",
		Title:    "Liburan Alumni Minang 2026",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups", bytes.NewReader(reqBody))
	w := httptest.NewRecorder()
	h.CreateGroupRoom(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	dataMap := resp.Data.(map[string]interface{})
	roomMap := dataMap["room"].(map[string]interface{})
	roomCode := roomMap["room_code"].(string)

	if !strings.HasPrefix(roomCode, "RANCAK-") {
		t.Fatalf("Expected room_code to start with RANCAK-, got %s", roomCode)
	}

	// 2. Ambil detail room lewat kode
	reqGet := httptest.NewRequest(http.MethodGet, "/api/v1/groups/detail?code="+roomCode, nil)
	wGet := httptest.NewRecorder()
	h.GetGroupRoom(wGet, reqGet)

	if wGet.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for GetGroupRoom, got %d", wGet.Code)
	}
}

func TestGroupVotingAndResults(t *testing.T) {
	h := NewHandlerBE2()
	roomCode := "RANCAK-MINANG-88"

	// 1. User 1 Upvote Lembah Harau
	vote1, _ := json.Marshal(models.GroupVoteRequest{
		GroupRoomID:   roomCode,
		UserID:        "usr-001",
		DestinationID: "dest-001",
		VoteType:      "upvote",
	})
	req1 := httptest.NewRequest(http.MethodPost, "/api/v1/groups/vote", bytes.NewReader(vote1))
	w1 := httptest.NewRecorder()
	h.VoteGroupDestination(w1, req1)
	if w1.Code != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", w1.Code)
	}

	// 2. User 2 Downvote dest-002
	vote2, _ := json.Marshal(models.GroupVoteRequest{
		GroupRoomID:   roomCode,
		UserID:        "usr-002",
		DestinationID: "dest-002",
		VoteType:      "downvote",
	})
	req2 := httptest.NewRequest(http.MethodPost, "/api/v1/groups/vote", bytes.NewReader(vote2))
	w2 := httptest.NewRecorder()
	h.VoteGroupDestination(w2, req2)

	// 3. Ambil rekapitulasi voting
	reqResults := httptest.NewRequest(http.MethodGet, "/api/v1/groups/results?code="+roomCode, nil)
	wResults := httptest.NewRecorder()
	h.GetGroupVoteResults(wResults, reqResults)

	if wResults.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for results, got %d", wResults.Code)
	}

	var resResp ResponseStandar
	_ = json.Unmarshal(wResults.Body.Bytes(), &resResp)
	resData := resResp.Data.(map[string]interface{})
	totalVotes := int(resData["total_votes"].(float64))
	if totalVotes != 2 {
		t.Fatalf("Expected 2 votes, got %d", totalVotes)
	}
}

func TestCommunityPlace_MandatoryTipsAndMasking(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Uji Validasi: Gagal jika tips_menjaga kosong (PRD P6.1)
	failBody, _ := json.Marshal(models.CommunityPlaceRequest{
		Name:        "Air Terjun Sarasah Barasok (Hidden Gem)",
		Category:    "Alam",
		TipsMenjaga: "", // Kosong!
	})
	reqFail := httptest.NewRequest(http.MethodPost, "/api/v1/community/places", bytes.NewReader(failBody))
	wFail := httptest.NewRecorder()
	h.CreateCommunityPlace(wFail, reqFail)

	if wFail.Code != http.StatusBadRequest {
		t.Fatalf("Expected status 400 when tips_menjaga is empty, got %d", wFail.Code)
	}

	// 2. Uji Sukses & Masking Koordinat jika is_sensitive = true
	successBody, _ := json.Marshal(models.CommunityPlaceRequest{
		Name:        "Goa Kelelawar Lubuk Bonta",
		Category:    "Alam & Goa",
		CityRegency: "Kab. Padang Pariaman",
		Latitude:    -0.5678,
		Longitude:   100.3456,
		TipsMenjaga: "Wajib bawa kembali sampah plastik dan dilarang merokok di area goa",
		IsSensitive: true, // Sensitif -> Masking aktif!
	})
	reqSuccess := httptest.NewRequest(http.MethodPost, "/api/v1/community/places", bytes.NewReader(successBody))
	wSuccess := httptest.NewRecorder()
	h.CreateCommunityPlace(wSuccess, reqSuccess)

	if wSuccess.Code != http.StatusCreated {
		t.Fatalf("Expected status 201 Created, got %d", wSuccess.Code)
	}

	var succResp ResponseStandar
	_ = json.Unmarshal(wSuccess.Body.Bytes(), &succResp)
	succData := succResp.Data.(map[string]interface{})
	if succData["masking_applied"].(bool) != true {
		t.Fatalf("Expected masking_applied to be true for sensitive location")
	}
}

func TestCreateManualItinerary(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Simpan rencana perjalanan manual
	manualTrip := models.Itinerary{
		UserID:    "usr-001",
		Title:     "Trip Solo Photography Lembah Harau",
		StartDate: "2026-12-01",
		EndDate:   "2026-12-03",
		TotalDays: 3,
		Items: []models.ItineraryItem{
			{
				DayNumber:     1,
				TimeSlot:      "06:30",
				DestinationID: "dest-001",
				Notes:         "Golden hour sunrise foto tebing Harau",
			},
		},
	}
	body, _ := json.Marshal(manualTrip)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/itineraries", bytes.NewReader(body))
	w := httptest.NewRecorder()
	h.CreateItinerary(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected status 201 Created for manual itinerary, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Status != "success" {
		t.Fatalf("Expected success status, got %s", resp.Status)
	}
}

func TestJoinGroupRoom(t *testing.T) {
	h := NewHandlerBE2()
	roomCode := "RANCAK-MINANG-88"

	// 1. User baru bergabung via link WA
	joinBody, _ := json.Marshal(map[string]string{
		"user_id":   "usr-005",
		"full_name": "Siti Fatimah (Anggota Baru)",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups/"+roomCode+"/join", bytes.NewReader(joinBody))
	req.SetPathValue("code", roomCode)
	w := httptest.NewRecorder()
	h.JoinGroupRoom(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for joining group, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	roomData := resp.Data.(map[string]interface{})
	members := roomData["members"].([]interface{})
	if len(members) < 2 { // Leader (1) + Anggota Baru (1) = minimal 2
		t.Fatalf("Expected at least 2 members after joining, got %d", len(members))
	}
}

// =============================================================================
// UNIT TESTS MINGGU 3: ESCROW LIFECYCLE, BOT WA, SPLIT-BILL & RADAR
// =============================================================================

func TestBookingEscrowEndToEndLifecycle(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Wisatawan Checkout Booking Homestay (Status: PENDING_WA)
	bookingReq, _ := json.Marshal(models.CreateBookingRequest{
		PartnerID:   "ptr-01",
		UserID:      "usr-001",
		TotalAmount: 250000.00,
		Currency:    "IDR",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/create", bytes.NewReader(bookingReq))
	w := httptest.NewRecorder()
	h.CreateBooking(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected status 201 Created, got %d", w.Code)
	}

	var createResp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &createResp)
	createData := createResp.Data.(map[string]interface{})
	bookingData := createData["booking"].(map[string]interface{})
	bookingID := bookingData["id"].(string)

	if bookingData["status"].(string) != "PENDING_WA" {
		t.Fatalf("Expected initial status PENDING_WA, got %s", bookingData["status"])
	}

	// 2. Wisatawan mencoba ambil QR Ticket saat masih PENDING_WA (Harus Gagal 400)
	reqPrematureQR := httptest.NewRequest(http.MethodGet, "/api/v1/bookings/"+bookingID+"/ticket-qr", nil)
	reqPrematureQR.SetPathValue("id", bookingID)
	wPrematureQR := httptest.NewRecorder()
	h.GetBookingTicketQR(wPrematureQR, reqPrematureQR)

	if wPrematureQR.Code != http.StatusBadRequest {
		t.Fatalf("Expected status 400 when QR not yet confirmed, got %d", wPrematureQR.Code)
	}

	// 3. Mitra Balas WhatsApp '1' (Terima) via Webhook Simulator
	webhookReq, _ := json.Marshal(models.WAWebhookRequest{
		BookingID: bookingID,
		Action:    "1", // Terima!
	})
	reqWH := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/wa-webhook", bytes.NewReader(webhookReq))
	wWH := httptest.NewRecorder()
	h.WAWebhookSimulation(wWH, reqWH)

	if wWH.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for WA webhook accept, got %d", wWH.Code)
	}

	var whResp ResponseStandar
	_ = json.Unmarshal(wWH.Body.Bytes(), &whResp)
	whData := whResp.Data.(map[string]interface{})
	if whData["status"].(string) != "ESCROW_LOCKED" {
		t.Fatalf("Expected status ESCROW_LOCKED after accept, got %s", whData["status"])
	}
	qrTicket := whData["qr_code_ticket"].(string)
	if !strings.HasPrefix(qrTicket, "QR-RANCAK-TKT-") {
		t.Fatalf("Expected valid QR format, got %s", qrTicket)
	}

	// 4. Ambil E-Ticket QR Wisatawan (Sekarang Sukses 200)
	reqValidQR := httptest.NewRequest(http.MethodGet, "/api/v1/bookings/"+bookingID+"/ticket-qr", nil)
	reqValidQR.SetPathValue("id", bookingID)
	wValidQR := httptest.NewRecorder()
	h.GetBookingTicketQR(wValidQR, reqValidQR)

	if wValidQR.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for confirmed QR ticket, got %d", wValidQR.Code)
	}

	// 5. Wisatawan Tiba di Lokasi & Mitra Scan QR untuk Mencairkan Escrow (Status -> REDEEMED)
	redeemReq, _ := json.Marshal(models.ScanRedeemRequest{
		PartnerID:    "ptr-01",
		QRCodeTicket: qrTicket,
	})
	reqRedeem := httptest.NewRequest(http.MethodPost, "/api/v1/escrow/scan-redeem", bytes.NewReader(redeemReq))
	wRedeem := httptest.NewRecorder()
	h.ScanRedeemEscrow(wRedeem, reqRedeem)

	if wRedeem.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for escrow redeem, got %d", wRedeem.Code)
	}

	var redeemResp ResponseStandar
	_ = json.Unmarshal(wRedeem.Body.Bytes(), &redeemResp)
	redeemData := redeemResp.Data.(map[string]interface{})
	if redeemData["status"].(string) != "REDEEMED" {
		t.Fatalf("Expected status REDEEMED, got %s", redeemData["status"])
	}

	// 6. Mitra Mencoba Scan Ulang Tiket yang Sama (Harus Gagal 400 Tiket Sudah Dicairkan)
	wDuplicateRedeem := httptest.NewRecorder()
	reqDuplicate := httptest.NewRequest(http.MethodPost, "/api/v1/escrow/scan-redeem", bytes.NewReader(redeemReq))
	h.ScanRedeemEscrow(wDuplicateRedeem, reqDuplicate)

	if wDuplicateRedeem.Code != http.StatusBadRequest {
		t.Fatalf("Expected status 400 for duplicate redeem attempt, got %d", wDuplicateRedeem.Code)
	}
}

func TestBookingEscrowRejectRefund(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Buat booking baru
	bookingReq, _ := json.Marshal(models.CreateBookingRequest{
		PartnerID:   "ptr-02",
		UserID:      "usr-001",
		TotalAmount: 90000.00,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/create", bytes.NewReader(bookingReq))
	w := httptest.NewRecorder()
	h.CreateBooking(w, req)

	var createResp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &createResp)
	bkgID := createResp.Data.(map[string]interface{})["booking"].(map[string]interface{})["id"].(string)

	// 2. Mitra Balas '0' (Tolak)
	rejectReq, _ := json.Marshal(models.WAWebhookRequest{
		BookingID: bkgID,
		Action:    "0", // Tolak!
	})
	reqReject := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/wa-webhook", bytes.NewReader(rejectReq))
	wReject := httptest.NewRecorder()
	h.WAWebhookSimulation(wReject, reqReject)

	if wReject.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for WA webhook reject, got %d", wReject.Code)
	}

	var rejResp ResponseStandar
	_ = json.Unmarshal(wReject.Body.Bytes(), &rejResp)
	rejData := rejResp.Data.(map[string]interface{})
	if rejData["status"].(string) != "REFUNDED" {
		t.Fatalf("Expected status REFUNDED after reject, got %s", rejData["status"])
	}
}

func TestMYRConversionRate(t *testing.T) {
	h := NewHandlerBE2()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/escrow/currency/myr-rate", nil)
	w := httptest.NewRecorder()
	h.GetMYRConversionRate(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for MYR rate, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	rateData := resp.Data.(map[string]interface{})
	if rateData["rate_myr_to_idr"].(float64) <= 0 {
		t.Fatalf("Expected positive exchange rate")
	}
}

func TestSplitBillCalculation(t *testing.T) {
	h := NewHandlerBE2()
	roomCode := "RANCAK-MINANG-88"

	// Bagi tagihan sewa mobil Rp 400.000 untuk 4 orang anggota
	splitReq, _ := json.Marshal(models.SplitBillRequest{
		TotalAmount: 400000.00,
		Description: "Sewa Mobil Toyota HiAce Padang - Bukittinggi",
		MemberIDs:   []string{"usr-001", "usr-002", "usr-003", "usr-004"},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups/"+roomCode+"/split-bill", bytes.NewReader(splitReq))
	req.SetPathValue("code", roomCode)
	w := httptest.NewRecorder()
	h.SplitBill(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for split bill, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	dataMap := resp.Data.(map[string]interface{})
	amountPerPerson := dataMap["amount_per_person"].(float64)
	if amountPerPerson != 100000.00 {
		t.Fatalf("Expected Rp 100.000 per person, got %.2f", amountPerPerson)
	}

	shares := dataMap["shares"].([]interface{})
	if len(shares) != 4 {
		t.Fatalf("Expected 4 shares, got %d", len(shares))
	}
}

func TestGroupRadarPingAndGet(t *testing.T) {
	h := NewHandlerBE2()
	roomCode := "RANCAK-MINANG-88"

	// 1. Anggota ping lokasi di Lembah Harau
	pingReq, _ := json.Marshal(models.RadarPingRequest{
		UserID:    "usr-001",
		Latitude:  -0.1023,
		Longitude: 100.6728,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups/"+roomCode+"/radar-ping", bytes.NewReader(pingReq))
	req.SetPathValue("code", roomCode)
	w := httptest.NewRecorder()
	h.RadarPing(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for radar ping, got %d", w.Code)
	}

	// 2. Ambil seluruh radar lokasi rombongan
	reqGet := httptest.NewRequest(http.MethodGet, "/api/v1/groups/"+roomCode+"/radar", nil)
	reqGet.SetPathValue("code", roomCode)
	wGet := httptest.NewRecorder()
	h.GetGroupRadar(wGet, reqGet)

	if wGet.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for get radar, got %d", wGet.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(wGet.Body.Bytes(), &resp)
	dataMap := resp.Data.(map[string]interface{})
	activeMembers := int(dataMap["active_members"].(float64))
	if activeMembers != 1 {
		t.Fatalf("Expected 1 active radar member, got %d", activeMembers)
	}
}

func TestSharedTripsBoard(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Ambil feed cari barengan (sudah ada 1 seeder)
	reqGet := httptest.NewRequest(http.MethodGet, "/api/v1/community/shared-trips", nil)
	wGet := httptest.NewRecorder()
	h.GetSharedTrips(wGet, reqGet)

	if wGet.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for get shared trips, got %d", wGet.Code)
	}

	// 2. Buat postingan cari barengan baru
	newTripReq, _ := json.Marshal(models.CreateSharedTripRequest{
		UserID:           "usr-002",
		Title:            "Patungan Sewa Perahu Pulau Pasumpahan & Sironjong",
		DestinationRoute: "Dermaga Bungus -> Pulau Pasumpahan -> Sironjong Ketek",
		DepartureDate:    time.Now().AddDate(0, 0, 3),
		AvailableSeats:   4,
		CostPerPerson:    60000.00,
		ContactWA:        "6281233334444",
	})
	reqPost := httptest.NewRequest(http.MethodPost, "/api/v1/community/shared-trips", bytes.NewReader(newTripReq))
	wPost := httptest.NewRecorder()
	h.CreateSharedTrip(wPost, reqPost)

	if wPost.Code != http.StatusCreated {
		t.Fatalf("Expected status 201 Created for shared trip, got %d", wPost.Code)
	}
}

// =============================================================================
// UNIT TESTS MINGGU 4: GAMIFIKASI PASPOR DIGITAL, ANTI-FAKE GPS & ANALITIK DISPAR
// =============================================================================

func TestGPSCheckIn_AntiFakeGPS_ValidAndInvalid(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Check-In VALID: Wisatawan berada di Jam Gadang Bukittinggi (radius ~15 meter)
	// Jam Gadang koordinat resmi: -0.3051, 100.3695
	validCheckIn, _ := json.Marshal(models.CheckInRequest{
		UserID:        "usr-001",
		DestinationID: "spot-jam-gadang",
		Latitude:      -0.3052,
		Longitude:     100.3696,
	})
	reqValid := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(validCheckIn))
	wValid := httptest.NewRecorder()
	h.ValidateGPSCheckIn(wValid, reqValid)

	if wValid.Code != http.StatusOK {
		t.Fatalf("Expected status 200 OK for valid GPS check-in, got %d. Body: %s", wValid.Code, wValid.Body.String())
	}

	var respValid ResponseStandar
	_ = json.Unmarshal(wValid.Body.Bytes(), &respValid)
	checkInData := respValid.Data.(map[string]interface{})
	if checkInData["is_within_radius"].(bool) != true {
		t.Fatalf("Expected is_within_radius=true")
	}
	if checkInData["badge_earned"].(string) != "Lencana Penjaga Waktu Minang" {
		t.Fatalf("Expected badge 'Lencana Penjaga Waktu Minang', got %v", checkInData["badge_earned"])
	}

	// 2. Check-In TIDAK VALID / FAKE GPS: Wisatawan berada di Padang (~70km) mencoba check-in di Jam Gadang
	fakeGPSCheckIn, _ := json.Marshal(models.CheckInRequest{
		UserID:        "usr-001",
		DestinationID: "spot-jam-gadang",
		Latitude:      -0.9634, // Padang
		Longitude:     100.3547,
	})
	reqFake := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(fakeGPSCheckIn))
	wFake := httptest.NewRecorder()
	h.ValidateGPSCheckIn(wFake, reqFake)

	if wFake.Code != http.StatusBadRequest {
		t.Fatalf("Expected status 400 Bad Request for fake GPS check-in > 200m, got %d", wFake.Code)
	}

	var respFake ResponseStandar
	_ = json.Unmarshal(wFake.Body.Bytes(), &respFake)
	if !strings.Contains(respFake.Message, "Anti-Fake GPS") {
		t.Fatalf("Expected error message to mention Anti-Fake GPS, got: %s", respFake.Message)
	}
}

func TestDigitalPassport_ProgressAndSummary(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Awalnya belum ada stempel
	reqInit := httptest.NewRequest(http.MethodGet, "/api/v1/gamification/passport?user_id=usr-001", nil)
	wInit := httptest.NewRecorder()
	h.GetDigitalPassport(wInit, reqInit)

	if wInit.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for passport summary, got %d", wInit.Code)
	}

	var respInit ResponseStandar
	_ = json.Unmarshal(wInit.Body.Bytes(), &respInit)
	passportData := respInit.Data.(map[string]interface{})
	if int(passportData["total_stamps"].(float64)) != 0 {
		t.Fatalf("Expected 0 initial stamps, got %v", passportData["total_stamps"])
	}
	if passportData["is_eligible_for_certificate"].(bool) != false {
		t.Fatalf("Expected not eligible for certificate initially")
	}

	// 2. Check-in ke 2 destinasi (Jam Gadang & Pagaruyung)
	// Jam Gadang: -0.3051, 100.3695
	c1, _ := json.Marshal(models.CheckInRequest{UserID: "usr-001", DestinationID: "spot-jam-gadang", Latitude: -0.3051, Longitude: 100.3695})
	req1 := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(c1))
	h.ValidateGPSCheckIn(httptest.NewRecorder(), req1)

	// Pagaruyung: -0.4712, 100.6214
	c2, _ := json.Marshal(models.CheckInRequest{UserID: "usr-001", DestinationID: "spot-pagaruyung", Latitude: -0.4712, Longitude: 100.6214})
	req2 := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(c2))
	h.ValidateGPSCheckIn(httptest.NewRecorder(), req2)

	// 3. Ambil rekapitulasi paspor setelah 2 stempel
	reqAfter := httptest.NewRequest(http.MethodGet, "/api/v1/gamification/passport?user_id=usr-001", nil)
	wAfter := httptest.NewRecorder()
	h.GetDigitalPassport(wAfter, reqAfter)

	var respAfter ResponseStandar
	_ = json.Unmarshal(wAfter.Body.Bytes(), &respAfter)
	afterData := respAfter.Data.(map[string]interface{})
	if int(afterData["total_stamps"].(float64)) != 2 {
		t.Fatalf("Expected 2 stamps, got %v", afterData["total_stamps"])
	}
	if afterData["completion_percentage"].(float64) != 20.0 {
		t.Fatalf("Expected 20%% completion, got %v", afterData["completion_percentage"])
	}
}

func TestGovernorCertificate_RequirementAndIssuance(t *testing.T) {
	h := NewHandlerBE2()

	// 1. Coba klaim sertifikat saat stempel belum genap 10 (Harus Gagal 400)
	certReqPremature, _ := json.Marshal(models.CertificateRequest{
		UserID:   "usr-001",
		FullName: "Rahmat Hidayat",
	})
	reqPremature := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/certificate", bytes.NewReader(certReqPremature))
	wPremature := httptest.NewRecorder()
	h.GenerateGovernorCertificate(wPremature, reqPremature)

	if wPremature.Code != http.StatusBadRequest {
		t.Fatalf("Expected status 400 Bad Request when stamps < 10, got %d", wPremature.Code)
	}

	// 2. Check-in ke seluruh 10 titik ikonik Minangkabau
	spots := []struct {
		id  string
		lat float64
		lon float64
	}{
		{"spot-jam-gadang", -0.3051, 100.3695},
		{"spot-pagaruyung", -0.4712, 100.6214},
		{"spot-lembah-harau", -0.1062, 100.6657},
		{"spot-danau-maninjau", -0.2980, 100.1878},
		{"spot-danau-singkarak", -0.6175, 100.5367},
		{"spot-kawasan-mandeh", -1.2186, 100.4192},
		{"spot-ngarai-sianok", -0.3106, 100.3619},
		{"spot-kota-tua-padang", -0.9634, 100.3547},
		{"spot-desa-pariangan", -0.4357, 100.4939},
		{"spot-tambang-ombilin", -0.6806, 100.7767},
	}

	for _, s := range spots {
		payload, _ := json.Marshal(models.CheckInRequest{
			UserID:        "usr-001",
			DestinationID: s.id,
			Latitude:      s.lat,
			Longitude:     s.lon,
		})
		r := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/checkin", bytes.NewReader(payload))
		w := httptest.NewRecorder()
		h.ValidateGPSCheckIn(w, r)
		if w.Code != http.StatusOK {
			t.Fatalf("Failed checkin for %s: %s", s.id, w.Body.String())
		}
	}

	// 3. Klaim sertifikat setelah 10 titik terpenuhi (Harus Sukses 201 Created)
	certReq, _ := json.Marshal(models.CertificateRequest{
		UserID:   "usr-001",
		FullName: "Rahmat Hidayat (Wisatawan Teladan)",
	})
	reqCert := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/certificate", bytes.NewReader(certReq))
	wCert := httptest.NewRecorder()
	h.GenerateGovernorCertificate(wCert, reqCert)

	if wCert.Code != http.StatusCreated {
		t.Fatalf("Expected status 201 Created for certificate, got %d. Body: %s", wCert.Code, wCert.Body.String())
	}

	var respCert ResponseStandar
	_ = json.Unmarshal(wCert.Body.Bytes(), &respCert)
	certData := respCert.Data.(map[string]interface{})
	if !strings.HasPrefix(certData["certificate_id"].(string), "WISGO-GUB-SB") {
		t.Fatalf("Expected certificate_id to start with 'WISGO-GUB-SB', got %v", certData["certificate_id"])
	}
	if int(certData["total_spots_visited"].(float64)) != 10 {
		t.Fatalf("Expected total_spots_visited=10, got %v", certData["total_spots_visited"])
	}

	// 4. Uji Idempotensi: Klaim ulang harus mengembalikan 200 OK dengan sertifikat yang sama
	reqCertRepeat := httptest.NewRequest(http.MethodPost, "/api/v1/gamification/certificate", bytes.NewReader(certReq))
	wCertRepeat := httptest.NewRecorder()
	h.GenerateGovernorCertificate(wCertRepeat, reqCertRepeat)

	if wCertRepeat.Code != http.StatusOK {
		t.Fatalf("Expected status 200 OK for repeated certificate request, got %d", wCertRepeat.Code)
	}
}

func TestDisparAnalyticsSummary_19RegenciesAndEconomicMetrics(t *testing.T) {
	h := NewHandlerBE2()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/analytics/dispar/summary", nil)
	w := httptest.NewRecorder()
	h.GetDisparAnalyticsSummary(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected status 200 for Dispar summary, got %d", w.Code)
	}

	var resp ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	// Cek perputaran ekonomi & scan QR
	if data["total_escrow_turnover"].(float64) <= 0 {
		t.Fatalf("Expected positive escrow turnover")
	}
	if int(data["total_qr_scans"].(float64)) <= 0 {
		t.Fatalf("Expected positive total QR scans")
	}

	// Cek kelengkapan 19 Kabupaten/Kota di Sumatera Barat
	heatmap := data["regency_density_heatmap"].([]interface{})
	if len(heatmap) != 19 {
		t.Fatalf("Expected 19 regencies in Sumbar density heatmap, got %d", len(heatmap))
	}

	// Cek top destinasi
	topDest := data["top_destinations"].([]interface{})
	if len(topDest) == 0 {
		t.Fatalf("Expected non-empty top destinations")
	}
}

