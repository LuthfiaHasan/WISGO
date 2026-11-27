package booking_escrow

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

func setupTestRouter() (*gin.Engine, *Handler) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	repo := NewRepository()
	service := NewService(repo)
	handler := NewHandler(service)

	v1 := r.Group("/api/v1")
	handler.RegisterRoutes(v1)

	return r, handler
}

func TestCreateBooking_SuccessAndPartnerNotFound(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Success case: partner ptr-01 (Homestay Etek Nur)
	body, _ := json.Marshal(CreateBookingRequest{
		PartnerID:   "ptr-01",
		UserID:      "usr-001",
		TotalAmount: 250000.0,
		Currency:    "IDR",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/create", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	booking := data["booking"].(map[string]interface{})

	if booking["status"] != "PENDING_WA" {
		t.Fatalf("Expected status PENDING_WA, got %v", booking["status"])
	}
	if data["partner_whatsapp"] != "6281234567890" {
		t.Fatalf("Expected partner WhatsApp 6281234567890, got %v", data["partner_whatsapp"])
	}

	// 2. Not found case: invalid partner ID
	badBody, _ := json.Marshal(CreateBookingRequest{
		PartnerID:   "ptr-tidak-ada",
		TotalAmount: 100000.0,
	})
	badReq := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/create", bytes.NewReader(badBody))
	badReq.Header.Set("Content-Type", "application/json")
	badW := httptest.NewRecorder()
	r.ServeHTTP(badW, badReq)

	if badW.Code != http.StatusNotFound {
		t.Fatalf("Expected 404 Not Found for non-existent partner, got %d", badW.Code)
	}
}

func TestWAWebhook_AcceptAction1_LocksEscrowAndIssuesQR(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(WAWebhookRequest{
		BookingID: "bkg-test-01",
		Action:    "1",
		Notes:     "Kamar homestay siap dihuni",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/wa-webhook", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on WA webhook action 1, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	if data["status"] != "ESCROW_LOCKED" {
		t.Fatalf("Expected status ESCROW_LOCKED, got %v", data["status"])
	}
	if data["qr_code_ticket"] != "QR-RANCAK-TKT-bkg-test-01" {
		t.Fatalf("Expected QR code QR-RANCAK-TKT-bkg-test-01, got %v", data["qr_code_ticket"])
	}
	if data["escrow_locked"] != true {
		t.Fatalf("Expected escrow_locked true")
	}
}

func TestWAWebhook_RejectAction0_RefundsEscrow(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(WAWebhookRequest{
		BookingID: "bkg-test-02",
		Action:    "0",
		Notes:     "Kamar penuh",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/bookings/wa-webhook", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on WA webhook action 0, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	if data["status"] != "REFUNDED" {
		t.Fatalf("Expected status REFUNDED, got %v", data["status"])
	}
	if data["refunded"] != true {
		t.Fatalf("Expected refunded true")
	}
}

func TestGetBookingTicketQR_States(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Existing seed booking bkg-demo-01 has status ESCROW_LOCKED -> should succeed
	req := httptest.NewRequest(http.MethodGet, "/api/v1/bookings/bkg-demo-01/ticket-qr", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for locked booking ticket, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	if data["qr_code_ticket"] != "QR-RANCAK-TKT-bkg-demo-01" {
		t.Fatalf("Expected QR code QR-RANCAK-TKT-bkg-demo-01, got %v", data["qr_code_ticket"])
	}

	// 2. Non-existent booking ID -> 404
	badReq := httptest.NewRequest(http.MethodGet, "/api/v1/bookings/bkg-nonexistent/ticket-qr", nil)
	badW := httptest.NewRecorder()
	r.ServeHTTP(badW, badReq)

	if badW.Code != http.StatusNotFound {
		t.Fatalf("Expected 404 Not Found for non-existent booking, got %d", badW.Code)
	}
}

func TestScanRedeemEscrow_SuccessAndDoubleRedeem(t *testing.T) {
	r, _ := setupTestRouter()

	// Seed booking has QR: QR-RANCAK-TKT-bkg-demo-01
	body, _ := json.Marshal(ScanRedeemRequest{
		QRCodeTicket: "QR-RANCAK-TKT-bkg-demo-01",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/escrow/scan-redeem", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on ScanRedeem, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	if data["status"] != "REDEEMED" {
		t.Fatalf("Expected status REDEEMED, got %v", data["status"])
	}

	// Double redeem attempt: should fail with 400 Bad Request
	req2 := httptest.NewRequest(http.MethodPost, "/api/v1/escrow/scan-redeem", bytes.NewReader(body))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	r.ServeHTTP(w2, req2)

	if w2.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request for double redeem, got %d", w2.Code)
	}

	// Non-existent QR ticket: should fail with 404 Not Found
	badBody, _ := json.Marshal(ScanRedeemRequest{
		QRCodeTicket: "QR-PALSU-9999",
	})
	badReq := httptest.NewRequest(http.MethodPost, "/api/v1/escrow/scan-redeem", bytes.NewReader(badBody))
	badReq.Header.Set("Content-Type", "application/json")
	badW := httptest.NewRecorder()
	r.ServeHTTP(badW, badReq)

	if badW.Code != http.StatusNotFound {
		t.Fatalf("Expected 404 Not Found for fake QR ticket, got %d", badW.Code)
	}
}

func TestMYRConversionRate(t *testing.T) {
	r, _ := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/escrow/currency/myr-rate", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on MYR rate, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})

	if data["base_currency"] != "MYR" || data["target_currency"] != "IDR" {
		t.Fatalf("Expected MYR to IDR, got %v to %v", data["base_currency"], data["target_currency"])
	}
	if data["rate_myr_to_idr"].(float64) <= 0 {
		t.Fatalf("Expected positive exchange rate, got %v", data["rate_myr_to_idr"])
	}
}
