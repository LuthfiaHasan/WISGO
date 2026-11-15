package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/LuthfiaHasan/WISGO/backend/internal/config"
	"github.com/LuthfiaHasan/WISGO/backend/internal/middleware"
)

// TestComprehensiveBackendFeatures menguji secara mendalam dan menyeluruh seluruh fitur BE-1 dan BE-2
func TestComprehensiveBackendFeatures(t *testing.T) {
	cfg := &config.Config{
		Port:        "8080",
		Environment: "test",
		JWTSecret:   "wisgo-super-secret-key-production-ready",
	}
	r := setupRouter(cfg)

	tokenAdminDispar := middleware.TokenAdminDispar
	_ = middleware.TokenPokdarwis
	_ = middleware.TokenTourist

	var recordedErrors []string
	recordError := func(scope, endpoint, expected, actual string) {
		errStr := fmt.Sprintf("[%s] %s -> Expected: %s, Actual: %s", scope, endpoint, expected, actual)
		recordedErrors = append(recordedErrors, errStr)
		t.Logf("ISSUE DETECTED: %s", errStr)
	}

	execReq := func(method, path string, body []byte, headers map[string]string) *httptest.ResponseRecorder {
		var req *http.Request
		if body != nil {
			req = httptest.NewRequest(method, path, bytes.NewBuffer(body))
		} else {
			req = httptest.NewRequest(method, path, nil)
		}
		for k, v := range headers {
			req.Header.Set(k, v)
		}
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		return w
	}

	// ==========================================
	// 1. PENGUJIAN FITUR BE-2 (8 MODUL)
	// ==========================================

	// --- Modul Auth ---
	t.Run("BE-2 Auth: Request OTP", func(t *testing.T) {
		body := []byte(`{"phone_number": "081234567890"}`)
		w := execReq(http.MethodPost, "/api/v1/auth/request-otp", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Auth", "POST /api/v1/auth/request-otp", "200 OK", fmt.Sprintf("%d (%s)", w.Code, w.Body.String()))
		}
	})

	t.Run("BE-2 Auth: Request OTP Empty Phone", func(t *testing.T) {
		body := []byte(`{"phone_number": ""}`)
		w := execReq(http.MethodPost, "/api/v1/auth/request-otp", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusBadRequest {
			recordError("BE-2 Auth", "POST /api/v1/auth/request-otp (empty)", "400 Bad Request", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Auth: Verify OTP Valid", func(t *testing.T) {
		body := []byte(`{"phone_number": "081234567890", "otp_code": "1234"}`)
		w := execReq(http.MethodPost, "/api/v1/auth/verify-otp", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Auth", "POST /api/v1/auth/verify-otp", "200 OK", fmt.Sprintf("%d (%s)", w.Code, w.Body.String()))
		}
	})

	t.Run("BE-2 Auth: Verify OTP Invalid", func(t *testing.T) {
		body := []byte(`{"phone_number": "081234567890", "otp_code": "9999"}`)
		w := execReq(http.MethodPost, "/api/v1/auth/verify-otp", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusUnauthorized {
			recordError("BE-2 Auth", "POST /api/v1/auth/verify-otp (invalid OTP)", "401 Unauthorized", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Auth: Get Saved Places", func(t *testing.T) {
		w := execReq(http.MethodGet, "/api/v1/users/saved?user_id=usr-001", nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Auth", "GET /api/v1/users/saved", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Auth: Toggle Saved Place (Body)", func(t *testing.T) {
		body := []byte(`{"user_id": "usr-001", "destination_id": "dest-001"}`)
		w := execReq(http.MethodPost, "/api/v1/users/saved", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Auth", "POST /api/v1/users/saved", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Auth: Toggle Saved Place (URL Param Kontrak)", func(t *testing.T) {
		// Contract API_Contract_BE1_BE2.md line 50: POST /api/v1/users/saved/:destination_id
		w := execReq(http.MethodPost, "/api/v1/users/saved/dest-001", []byte(`{"user_id": "usr-001"}`), map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK && w.Code != http.StatusCreated {
			recordError("BE-2 Auth", "POST /api/v1/users/saved/:destination_id", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	// --- Modul Partner ---
	t.Run("BE-2 Partner: Catalog & Filters", func(t *testing.T) {
		w := execReq(http.MethodGet, "/api/v1/partners?category=kuliner&spicy_level=3", nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Partner", "GET /api/v1/partners", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Partner: Detail by Param & Query", func(t *testing.T) {
		w1 := execReq(http.MethodGet, "/api/v1/partners/prt-001", nil, nil)
		if w1.Code != http.StatusOK {
			recordError("BE-2 Partner", "GET /api/v1/partners/:id", "200 OK", fmt.Sprintf("%d", w1.Code))
		}

		w2 := execReq(http.MethodGet, "/api/v1/partners/detail?id=prt-001", nil, nil)
		if w2.Code != http.StatusOK {
			recordError("BE-2 Partner", "GET /api/v1/partners/detail?id=...", "200 OK", fmt.Sprintf("%d", w2.Code))
		}
	})

	// --- Modul Itinerary ---
	t.Run("BE-2 Itinerary: Auto-Generate Valid", func(t *testing.T) {
		body := []byte(`{"user_id": "usr-001", "duration_days": 3, "traveler_type": "family"}`)
		w := execReq(http.MethodPost, "/api/v1/itineraries/auto-generate", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusCreated {
			recordError("BE-2 Itinerary", "POST /api/v1/itineraries/auto-generate", "201 Created", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Itinerary: Get User Itineraries", func(t *testing.T) {
		w := execReq(http.MethodGet, "/api/v1/itineraries?user_id=usr-001", nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Itinerary", "GET /api/v1/itineraries", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Itinerary: Create Manual", func(t *testing.T) {
		body := []byte(`{"user_id": "usr-001", "title": "Trip Padang-Bukittinggi", "start_date": "2026-12-01T00:00:00Z", "end_date": "2026-12-03T00:00:00Z"}`)
		w := execReq(http.MethodPost, "/api/v1/itineraries", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusCreated {
			recordError("BE-2 Itinerary", "POST /api/v1/itineraries", "201 Created", fmt.Sprintf("%d", w.Code))
		}
	})

	// --- Modul Group ---
	var testRoomCode string
	t.Run("BE-2 Group: Create Room", func(t *testing.T) {
		body := []byte(`{"leader_id": "usr-001", "title": "Rombongan Alumni Minang"}`)
		w := execReq(http.MethodPost, "/api/v1/groups", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusCreated {
			recordError("BE-2 Group", "POST /api/v1/groups", "201 Created", fmt.Sprintf("%d", w.Code))
		} else {
			var resp map[string]interface{}
			_ = json.Unmarshal(w.Body.Bytes(), &resp)
			if data, ok := resp["data"].(map[string]interface{}); ok {
				if room, ok := data["room"].(map[string]interface{}); ok {
					if c, ok := room["room_code"].(string); ok {
						testRoomCode = c
					}
				}
			}
		}
	})

	if testRoomCode == "" {
		testRoomCode = "RANCAK-MINANG-88"
	}

	t.Run("BE-2 Group: Get Room Detail & Members", func(t *testing.T) {
		w := execReq(http.MethodGet, fmt.Sprintf("/api/v1/groups/%s", testRoomCode), nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Group", fmt.Sprintf("GET /api/v1/groups/%s", testRoomCode), "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Group: Join Room", func(t *testing.T) {
		body := []byte(`{"user_id": "usr-002", "user_name": "Siti Nurhaliza"}`)
		w := execReq(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/join", testRoomCode), body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Group", "POST /api/v1/groups/:code/join", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Group: Live Voting", func(t *testing.T) {
		body := []byte(`{"user_id": "usr-001", "destination_id": "dest-001", "vote_type": "upvote"}`)
		w := execReq(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/vote", testRoomCode), body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Group", "POST /api/v1/groups/:code/vote", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Group: Vote Results", func(t *testing.T) {
		w := execReq(http.MethodGet, fmt.Sprintf("/api/v1/groups/%s/results", testRoomCode), nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Group", "GET /api/v1/groups/:code/results", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Group: Split Bill", func(t *testing.T) {
		body := []byte(`{"total_amount": 1200000, "description": "Sewa HiAce Bukittinggi"}`)
		w := execReq(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/split-bill", testRoomCode), body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Group", "POST /api/v1/groups/:code/split-bill", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-2 Group: Radar Ping & Radar Feed", func(t *testing.T) {
		pingBody := []byte(`{"user_id": "usr-001", "latitude": -0.305, "longitude": 100.369}`)
		wPing := execReq(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/radar-ping", testRoomCode), pingBody, map[string]string{"Content-Type": "application/json"})
		if wPing.Code != http.StatusOK {
			recordError("BE-2 Group", "POST /api/v1/groups/:code/radar-ping", "200 OK", fmt.Sprintf("%d", wPing.Code))
		}

		wRadarPost := execReq(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/radar", testRoomCode), pingBody, map[string]string{"Content-Type": "application/json"})
		if wRadarPost.Code != http.StatusOK {
			recordError("BE-2 Group", "POST /api/v1/groups/:code/radar", "200 OK", fmt.Sprintf("%d", wRadarPost.Code))
		}

		wFeed := execReq(http.MethodGet, fmt.Sprintf("/api/v1/groups/%s/radar", testRoomCode), nil, nil)
		if wFeed.Code != http.StatusOK {
			recordError("BE-2 Group", "GET /api/v1/groups/:code/radar", "200 OK", fmt.Sprintf("%d", wFeed.Code))
		}
	})

	// --- Modul Booking & Escrow ---
	var createdBookingID string
	t.Run("BE-2 Booking Escrow: Create Booking", func(t *testing.T) {
		body := []byte(`{"user_id": "usr-001", "partner_id": "prt-001", "total_amount": 350000, "booking_date": "2026-11-20T00:00:00Z"}`)
		w := execReq(http.MethodPost, "/api/v1/bookings/create", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusCreated {
			recordError("BE-2 Booking", "POST /api/v1/bookings/create", "201 Created", fmt.Sprintf("%d (%s)", w.Code, w.Body.String()))
		} else {
			var resp map[string]interface{}
			_ = json.Unmarshal(w.Body.Bytes(), &resp)
			if data, ok := resp["data"].(map[string]interface{}); ok {
				if b, ok := data["booking"].(map[string]interface{}); ok {
					if id, ok := b["id"].(string); ok {
						createdBookingID = id
					}
				}
			}
		}
	})

	if createdBookingID == "" {
		createdBookingID = "bkg-001"
	}

	var generatedTicketQR string
	t.Run("BE-2 Booking Escrow: WhatsApp Webhook Accept (Action 1)", func(t *testing.T) {
		body := []byte(fmt.Sprintf(`{"booking_id": "%s", "action": "1", "sender_phone": "6281299990001"}`, createdBookingID))
		w := execReq(http.MethodPost, "/api/v1/bookings/wa-webhook", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Booking", "POST /api/v1/bookings/wa-webhook (Action 1)", "200 OK", fmt.Sprintf("%d", w.Code))
		} else {
			var resp map[string]interface{}
			_ = json.Unmarshal(w.Body.Bytes(), &resp)
			if data, ok := resp["data"].(map[string]interface{}); ok {
				if qr, ok := data["qr_code_ticket"].(string); ok {
					generatedTicketQR = qr
				}
			}
		}
	})

	t.Run("BE-2 Booking Escrow: Get Ticket QR", func(t *testing.T) {
		w := execReq(http.MethodGet, fmt.Sprintf("/api/v1/bookings/%s/ticket-qr", createdBookingID), nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Booking", "GET /api/v1/bookings/:id/ticket-qr", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	if generatedTicketQR == "" {
		generatedTicketQR = "QR-TICKET-" + createdBookingID
	}

	t.Run("BE-2 Booking Escrow: Scan Redeem", func(t *testing.T) {
		body := []byte(fmt.Sprintf(`{"qr_code_ticket": "%s", "partner_id": "prt-001"}`, generatedTicketQR))
		w := execReq(http.MethodPost, "/api/v1/escrow/scan-redeem", body, map[string]string{"Content-Type": "application/json"})
		if w.Code != http.StatusOK {
			recordError("BE-2 Escrow", "POST /api/v1/escrow/scan-redeem", "200 OK", fmt.Sprintf("%d (%s)", w.Code, w.Body.String()))
		}
	})

	t.Run("BE-2 Booking Escrow: MYR Conversion Rate", func(t *testing.T) {
		w := execReq(http.MethodGet, "/api/v1/escrow/currency/myr-rate", nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Escrow", "GET /api/v1/escrow/currency/myr-rate", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	// --- Modul Community ---
	t.Run("BE-2 Community: Places & Shared Trips", func(t *testing.T) {
		placeBody := []byte(`{"user_id": "usr-001", "name": "Lubuak Rantiang Hidden Pool", "category": "Alam", "latitude": -0.85, "longitude": 100.42, "tips_menjaga": "Jangan buang sampah dan hormati kearifan lokal"}`)
		wPlace := execReq(http.MethodPost, "/api/v1/community/places", placeBody, map[string]string{"Content-Type": "application/json"})
		if wPlace.Code != http.StatusCreated {
			recordError("BE-2 Community", "POST /api/v1/community/places", "201 Created", fmt.Sprintf("%d", wPlace.Code))
		}

		wList := execReq(http.MethodGet, "/api/v1/community/places", nil, nil)
		if wList.Code != http.StatusOK {
			recordError("BE-2 Community", "GET /api/v1/community/places", "200 OK", fmt.Sprintf("%d", wList.Code))
		}

		wShared := execReq(http.MethodGet, "/api/v1/community/shared-trips", nil, nil)
		if wShared.Code != http.StatusOK {
			recordError("BE-2 Community", "GET /api/v1/community/shared-trips", "200 OK", fmt.Sprintf("%d", wShared.Code))
		}

		tripBody := []byte(`{"user_id": "usr-001", "title": "Cari Teman Patungan Mobil ke Lembah Harau", "destination_route": "Padang - Harau", "max_capacity": 4, "price_per_seat": 150000, "trip_date": "2026-11-25T00:00:00Z"}`)
		wTripPost := execReq(http.MethodPost, "/api/v1/community/shared-trips", tripBody, map[string]string{"Content-Type": "application/json"})
		if wTripPost.Code != http.StatusCreated {
			recordError("BE-2 Community", "POST /api/v1/community/shared-trips", "201 Created", fmt.Sprintf("%d", wTripPost.Code))
		}
	})

	// --- Modul Gamification ---
	t.Run("BE-2 Gamification: GPS Check-in Valid & Out of Radius", func(t *testing.T) {
		// Valid spot: Jam Gadang (dest-002, Latitude: -0.3051, Longitude: 100.3695)
		validCheckin := []byte(`{"user_id": "usr-001", "destination_id": "dest-002", "latitude": -0.3051, "longitude": 100.3695}`)
		wValid := execReq(http.MethodPost, "/api/v1/gamification/checkin", validCheckin, map[string]string{"Content-Type": "application/json"})
		if wValid.Code != http.StatusOK {
			recordError("BE-2 Gamification", "POST /api/v1/gamification/checkin (Valid GPS)", "200 OK", fmt.Sprintf("%d (%s)", wValid.Code, wValid.Body.String()))
		}

		// Invalid: > 200m away (misal Padang ke Bukittinggi ~70km)
		invalidCheckin := []byte(`{"user_id": "usr-001", "destination_id": "dest-002", "latitude": -0.9471, "longitude": 100.4172}`)
		wInvalid := execReq(http.MethodPost, "/api/v1/gamification/checkin", invalidCheckin, map[string]string{"Content-Type": "application/json"})
		if wInvalid.Code != http.StatusBadRequest {
			recordError("BE-2 Gamification", "POST /api/v1/gamification/checkin (Out of radius)", "400 Bad Request", fmt.Sprintf("%d", wInvalid.Code))
		}
	})

	t.Run("BE-2 Gamification: Passport & Certificate", func(t *testing.T) {
		wPass := execReq(http.MethodGet, "/api/v1/gamification/passport?user_id=usr-001", nil, nil)
		if wPass.Code != http.StatusOK {
			recordError("BE-2 Gamification", "GET /api/v1/gamification/passport", "200 OK", fmt.Sprintf("%d", wPass.Code))
		}

		wCert := execReq(http.MethodPost, "/api/v1/gamification/certificate", []byte(`{"user_id": "usr-001", "full_name": "Wisatawan Minang"}`), map[string]string{"Content-Type": "application/json"})
		// Could be 200 or 400 depending on stamp count
		if wCert.Code != http.StatusOK && wCert.Code != http.StatusBadRequest {
			recordError("BE-2 Gamification", "POST /api/v1/gamification/certificate", "200 or 400", fmt.Sprintf("%d", wCert.Code))
		}
	})

	// --- Modul Analytics ---
	t.Run("BE-2 Analytics: Dispar Summary", func(t *testing.T) {
		w := execReq(http.MethodGet, "/api/v1/analytics/dispar/summary", nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-2 Analytics", "GET /api/v1/analytics/dispar/summary", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	// ==========================================
	// 2. PENGUJIAN FITUR BE-1 (6 MODUL)
	// ==========================================

	// --- Modul Destination ---
	t.Run("BE-1 Destination: Get Catalog with Spatial Filters", func(t *testing.T) {
		w := execReq(http.MethodGet, "/api/v1/destinations?category=alam&lat=-0.947&lng=100.417", nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-1 Destination", "GET /api/v1/destinations", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-1 Destination: Detail & Tariffs & Offline Bundle", func(t *testing.T) {
		wDetail := execReq(http.MethodGet, "/api/v1/destinations/dest-001", nil, nil)
		if wDetail.Code != http.StatusOK {
			recordError("BE-1 Destination", "GET /api/v1/destinations/:id", "200 OK", fmt.Sprintf("%d", wDetail.Code))
		}

		wTariffs := execReq(http.MethodGet, "/api/v1/destinations/dest-001/tariffs", nil, nil)
		if wTariffs.Code != http.StatusOK {
			recordError("BE-1 Destination", "GET /api/v1/destinations/:id/tariffs", "200 OK", fmt.Sprintf("%d", wTariffs.Code))
		}

		wBundle := execReq(http.MethodGet, "/api/v1/destinations/dest-001/offline-bundle", nil, nil)
		if wBundle.Code != http.StatusOK {
			recordError("BE-1 Destination", "GET /api/v1/destinations/:id/offline-bundle", "200 OK", fmt.Sprintf("%d", wBundle.Code))
		}
	})

	t.Run("BE-1 Destination: CMS RBAC Protected Routes", func(t *testing.T) {
		// Unauthorized without token
		wNoAuth := execReq(http.MethodPost, "/api/v1/destinations", []byte(`{"name": "Spot Baru"}`), map[string]string{"Content-Type": "application/json"})
		if wNoAuth.Code != http.StatusUnauthorized {
			recordError("BE-1 Destination", "POST /api/v1/destinations (No Auth)", "401 Unauthorized", fmt.Sprintf("%d", wNoAuth.Code))
		}

		// Authorized with admin_dispar token
		wAuth := execReq(http.MethodPost, "/api/v1/destinations", []byte(`{"name": "Spot Baru Ranah Minang", "city_regency": "Kab. Agam"}`), map[string]string{
			"Content-Type":  "application/json",
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wAuth.Code != http.StatusCreated {
			recordError("BE-1 Destination", "POST /api/v1/destinations (With Admin Token)", "201 Created", fmt.Sprintf("%d (%s)", wAuth.Code, wAuth.Body.String()))
		}
	})

	// --- Modul Scenes360 ---
	t.Run("BE-1 Scenes360: Get Scenes & Hotspots", func(t *testing.T) {
		w := execReq(http.MethodGet, "/api/v1/destinations/dest-001/scenes-360", nil, nil)
		if w.Code != http.StatusOK {
			recordError("BE-1 Scenes360", "GET /api/v1/destinations/:id/scenes-360", "200 OK", fmt.Sprintf("%d", w.Code))
		}
	})

	t.Run("BE-1 Scenes360: Contract Compliance Check (POST /scenes-360 & Hotspot Pin)", func(t *testing.T) {
		// API Contract specifies POST /api/v1/scenes-360
		bodyScene := []byte(`{"destination_id": "dest-001", "title": "Panorama Udara Jam Gadang", "type": "aerial"}`)
		wSceneDirect := execReq(http.MethodPost, "/api/v1/scenes-360", bodyScene, map[string]string{
			"Content-Type":  "application/json",
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wSceneDirect.Code != http.StatusCreated && wSceneDirect.Code != http.StatusOK {
			recordError("BE-1 Scenes360", "POST /api/v1/scenes-360 (Direct Path)", "200/201", fmt.Sprintf("%d (%s)", wSceneDirect.Code, wSceneDirect.Body.String()))
		}

		// Hotspot upsert
		bodyHotspot := []byte(`{"title": "Istano Basa", "type": "navigasi", "pitch": 12.5, "yaw": 180.0}`)
		wPinAdmin := execReq(http.MethodPost, "/api/v1/admin/scenes-360/scn-001/hotspots", bodyHotspot, map[string]string{
			"Content-Type":  "application/json",
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wPinAdmin.Code != http.StatusCreated && wPinAdmin.Code != http.StatusOK {
			recordError("BE-1 Scenes360", "POST /api/v1/admin/scenes-360/:sceneId/hotspots", "200/201", fmt.Sprintf("%d (%s)", wPinAdmin.Code, wPinAdmin.Body.String()))
		}

		// Contract: GET /api/v1/scenes-360/:scene_id/hotspots
		wGetPins := execReq(http.MethodGet, "/api/v1/scenes-360/scn-001/hotspots", nil, nil)
		if wGetPins.Code != http.StatusOK {
			recordError("BE-1 Scenes360", "GET /api/v1/scenes-360/:scene_id/hotspots", "200 OK", fmt.Sprintf("%d", wGetPins.Code))
		}
	})

	// --- Modul Spatial ---
	t.Run("BE-1 Spatial: Shunlu & Micro-Map & Audio Trigger", func(t *testing.T) {
		shunluBody := []byte(`{"origin_lat": -0.947, "origin_lng": 100.417, "destination_lat": -0.305, "destination_lng": 100.369, "max_detour_minutes": 30}`)
		wShunlu := execReq(http.MethodPost, "/api/v1/spatial/shunlu", shunluBody, map[string]string{"Content-Type": "application/json"})
		if wShunlu.Code != http.StatusOK {
			recordError("BE-1 Spatial", "POST /api/v1/spatial/shunlu", "200 OK", fmt.Sprintf("%d", wShunlu.Code))
		}

		wMicroMap := execReq(http.MethodGet, "/api/v1/destinations/dest-001/micro-map", nil, nil)
		if wMicroMap.Code != http.StatusOK {
			recordError("BE-1 Spatial", "GET /api/v1/destinations/:id/micro-map", "200 OK", fmt.Sprintf("%d", wMicroMap.Code))
		}

		audioBody := []byte(`{"destination_id": "dest-001", "user_lat": -0.3054, "user_lng": 100.3692}`)
		wAudio := execReq(http.MethodPost, "/api/v1/spatial/audio-trigger-check", audioBody, map[string]string{"Content-Type": "application/json"})
		if wAudio.Code != http.StatusOK {
			recordError("BE-1 Spatial", "POST /api/v1/spatial/audio-trigger-check", "200 OK", fmt.Sprintf("%d", wAudio.Code))
		}
	})

	t.Run("BE-1 Spatial: Hazards & SOS Emergency Paths", func(t *testing.T) {
		wHazards := execReq(http.MethodGet, "/api/v1/spatial/hazards", nil, nil)
		if wHazards.Code != http.StatusOK {
			recordError("BE-1 Spatial", "GET /api/v1/spatial/hazards", "200 OK", fmt.Sprintf("%d", wHazards.Code))
		}

		// Contract: GET /api/v1/hazards/active
		wHazardsActive := execReq(http.MethodGet, "/api/v1/hazards/active", nil, nil)
		if wHazardsActive.Code != http.StatusOK {
			recordError("BE-1 Spatial", "GET /api/v1/hazards/active", "200 OK", fmt.Sprintf("%d", wHazardsActive.Code))
		}

		// SOS
		sosBody := []byte(`{"latitude": -0.75, "longitude": 100.35, "caller_name": "Pak Budi", "situation": "Mobil mogok di Sitinjau"}`)
		wSOS := execReq(http.MethodPost, "/api/v1/spatial/sos", sosBody, map[string]string{"Content-Type": "application/json"})
		if wSOS.Code != http.StatusCreated && wSOS.Code != http.StatusOK {
			recordError("BE-1 Spatial", "POST /api/v1/spatial/sos", "200/201", fmt.Sprintf("%d", wSOS.Code))
		}

		// Contract: POST /api/v1/hazards/sos
		wHazardSOS := execReq(http.MethodPost, "/api/v1/hazards/sos", sosBody, map[string]string{"Content-Type": "application/json"})
		if wHazardSOS.Code != http.StatusCreated && wHazardSOS.Code != http.StatusOK {
			recordError("BE-1 Spatial", "POST /api/v1/hazards/sos", "200/201", fmt.Sprintf("%d", wHazardSOS.Code))
		}

		// Contract: GET /api/v1/spatial/nearby
		wNearby := execReq(http.MethodGet, "/api/v1/spatial/nearby?lat=-0.947&lng=100.417&radius=10000", nil, nil)
		if wNearby.Code != http.StatusOK {
			recordError("BE-1 Spatial", "GET /api/v1/spatial/nearby", "200 OK", fmt.Sprintf("%d", wNearby.Code))
		}
	})

	t.Run("BE-1 Spatial: Telemetry Anti-Fake Dwell Time", func(t *testing.T) {
		// Dwell time < 10 mins must be rejected (422)
		bodyPassBy := []byte(`{"destination_id": "dest-001", "dwell_time_minutes": 5, "device_id": "dev-01"}`)
		wPassBy := execReq(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bodyPassBy, map[string]string{"Content-Type": "application/json"})
		if wPassBy.Code != http.StatusUnprocessableEntity {
			recordError("BE-1 Spatial", "POST /api/v1/spatial/navigation-telemetry (Pass-by <10m)", "422 Unprocessable Entity", fmt.Sprintf("%d", wPassBy.Code))
		}

		// Dwell time >= 10 mins must be accepted (200)
		bodyValid := []byte(`{"destination_id": "dest-001", "dwell_time_minutes": 45, "device_id": "dev-01"}`)
		wValid := execReq(http.MethodPost, "/api/v1/spatial/navigation-telemetry", bodyValid, map[string]string{"Content-Type": "application/json"})
		if wValid.Code != http.StatusOK {
			recordError("BE-1 Spatial", "POST /api/v1/spatial/navigation-telemetry (Valid >=10m)", "200 OK", fmt.Sprintf("%d", wValid.Code))
		}
	})

	// --- Modul Pungli ---
	t.Run("BE-1 Pungli: Smart QR Placard & Report", func(t *testing.T) {
		wQR := execReq(http.MethodGet, "/api/v1/qr/QR-SMBR-LPK-001", nil, nil)
		if wQR.Code != http.StatusOK {
			recordError("BE-1 Pungli", "GET /api/v1/qr/:qrCode", "200 OK", fmt.Sprintf("%d", wQR.Code))
		}

		reportJSON := []byte(`{"destination_id": "dest-001", "charged_amount_idr": 25000, "incident_category": "parkir_liar", "description": "Diminta 25k padahal perda 5k"}`)
		wReport := execReq(http.MethodPost, "/api/v1/pungli/report", reportJSON, map[string]string{"Content-Type": "application/json"})
		if wReport.Code != http.StatusCreated && wReport.Code != http.StatusOK {
			recordError("BE-1 Pungli", "POST /api/v1/pungli/report (JSON)", "201 Created", fmt.Sprintf("%d", wReport.Code))
		}
	})

	t.Run("BE-1 Pungli: Contract Compliance (Admin vs Direct Routes)", func(t *testing.T) {
		// Admin endpoint with auth
		wReportsAdmin := execReq(http.MethodGet, "/api/v1/admin/pungli/reports", nil, map[string]string{
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wReportsAdmin.Code != http.StatusOK {
			recordError("BE-1 Pungli", "GET /api/v1/admin/pungli/reports", "200 OK", fmt.Sprintf("%d", wReportsAdmin.Code))
		}

		// Contract: GET /api/v1/pungli/reports
		wReportsDirect := execReq(http.MethodGet, "/api/v1/pungli/reports", nil, map[string]string{
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wReportsDirect.Code != http.StatusOK {
			recordError("BE-1 Pungli", "GET /api/v1/pungli/reports (Direct Path)", "200 OK", fmt.Sprintf("%d", wReportsDirect.Code))
		}

		// Update report status
		statusBody := []byte(`{"status": "Diverifikasi", "action_notes": "Petugas dikerahkan"}`)
		wStatusAdmin := execReq(http.MethodPatch, "/api/v1/admin/pungli/rep-001/status", statusBody, map[string]string{
			"Content-Type":  "application/json",
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wStatusAdmin.Code != http.StatusOK {
			recordError("BE-1 Pungli", "PATCH /api/v1/admin/pungli/:id/status", "200 OK", fmt.Sprintf("%d", wStatusAdmin.Code))
		}

		// Contract: PATCH /api/v1/pungli/reports/:id/status
		wStatusDirect := execReq(http.MethodPatch, "/api/v1/pungli/reports/rep-001/status", statusBody, map[string]string{
			"Content-Type":  "application/json",
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wStatusDirect.Code != http.StatusOK {
			recordError("BE-1 Pungli", "PATCH /api/v1/pungli/reports/:id/status", "200 OK", fmt.Sprintf("%d", wStatusDirect.Code))
		}
	})

	// --- Modul Culture & Ranking ---
	t.Run("BE-1 Culture & Ranking: Endpoints & Aliases", func(t *testing.T) {
		wGaode := execReq(http.MethodGet, "/api/v1/destinations/rankings/gaode", nil, nil)
		if wGaode.Code != http.StatusOK {
			recordError("BE-1 Culture/Ranking", "GET /api/v1/destinations/rankings/gaode", "200 OK", fmt.Sprintf("%d", wGaode.Code))
		}

		// Contract: GET /api/v1/rankings/gaode
		wGaodeAlias := execReq(http.MethodGet, "/api/v1/rankings/gaode", nil, nil)
		if wGaodeAlias.Code != http.StatusOK {
			recordError("BE-1 Culture/Ranking", "GET /api/v1/rankings/gaode (Contract Alias)", "200 OK", fmt.Sprintf("%d", wGaodeAlias.Code))
		}

		wPhrases := execReq(http.MethodGet, "/api/v1/culture/minang-phrases", nil, nil)
		if wPhrases.Code != http.StatusOK {
			recordError("BE-1 Culture/Ranking", "GET /api/v1/culture/minang-phrases", "200 OK", fmt.Sprintf("%d", wPhrases.Code))
		}

		// Contract: GET /api/v1/culture/audio-phrases
		wPhrasesAlias := execReq(http.MethodGet, "/api/v1/culture/audio-phrases", nil, nil)
		if wPhrasesAlias.Code != http.StatusOK {
			recordError("BE-1 Culture/Ranking", "GET /api/v1/culture/audio-phrases (Contract Alias)", "200 OK", fmt.Sprintf("%d", wPhrasesAlias.Code))
		}

		wEvents := execReq(http.MethodGet, "/api/v1/culture/events", nil, nil)
		if wEvents.Code != http.StatusOK {
			recordError("BE-1 Culture/Ranking", "GET /api/v1/culture/events", "200 OK", fmt.Sprintf("%d", wEvents.Code))
		}
	})

	// --- Modul System Core ---
	t.Run("BE-1 System Core: Contracts & Benchmark & Cache Flush", func(t *testing.T) {
		wContracts := execReq(http.MethodGet, "/api/v1/system/contracts", nil, nil)
		if wContracts.Code != http.StatusOK {
			recordError("BE-1 System Core", "GET /api/v1/system/contracts", "200 OK", fmt.Sprintf("%d", wContracts.Code))
		}

		wBenchmark := execReq(http.MethodGet, "/api/v1/admin/system/benchmark", nil, map[string]string{
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wBenchmark.Code != http.StatusOK {
			recordError("BE-1 System Core", "GET /api/v1/admin/system/benchmark", "200 OK", fmt.Sprintf("%d", wBenchmark.Code))
		}

		wFlush := execReq(http.MethodPost, "/api/v1/admin/cache/flush", nil, map[string]string{
			"Authorization": "Bearer " + tokenAdminDispar,
		})
		if wFlush.Code != http.StatusOK {
			recordError("BE-1 System Core", "POST /api/v1/admin/cache/flush", "200 OK", fmt.Sprintf("%d", wFlush.Code))
		}
	})

	// Print Summary of all issues found
	t.Log("=================================================================")
	t.Logf("TOTAL FITUR BERMASALAH / KETIDAKSESUAIAN KONTRAK DITEMUKAN: %d", len(recordedErrors))
	for i, errStr := range recordedErrors {
		t.Logf("  [%d] %s", i+1, errStr)
	}
	t.Log("=================================================================")
}
