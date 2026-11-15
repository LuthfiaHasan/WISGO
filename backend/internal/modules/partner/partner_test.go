package partner

import (
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

func TestGetPartnersKatalog_All(t *testing.T) {
	r, _ := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	list := resp.Data.([]interface{})
	if len(list) != 5 {
		t.Fatalf("Expected 5 partners in seeder, got %d", len(list))
	}
}

func TestGetPartnersKatalog_FilterSpicyAndCategory(t *testing.T) {
	r, _ := setupTestRouter()

	// Filter kuliner pedas level 5
	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners?category=kuliner&spicy_level=5", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK, got %d", w.Code)
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	list := resp.Data.([]interface{})
	if len(list) != 1 {
		t.Fatalf("Expected exactly 1 spicy kuliner partner, got %d", len(list))
	}

	first := list[0].(map[string]interface{})
	if first["name"].(string) != "Rumah Makan Rendang Payakumbuah Asli" {
		t.Fatalf("Expected 'Rumah Makan Rendang Payakumbuah Asli', got %s", first["name"])
	}
}

func TestGetPartnerDetail_SuccessAndNotFound(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Ambil detail yang valid (ptr-01)
	reqValid := httptest.NewRequest(http.MethodGet, "/api/v1/partners/ptr-01", nil)
	wValid := httptest.NewRecorder()
	r.ServeHTTP(wValid, reqValid)

	if wValid.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for ptr-01, got %d", wValid.Code)
	}

	// 2. Ambil detail dengan query param (?id=ptr-01)
	reqQuery := httptest.NewRequest(http.MethodGet, "/api/v1/partners/detail?id=ptr-01", nil)
	wQuery := httptest.NewRecorder()
	r.ServeHTTP(wQuery, reqQuery)

	if wQuery.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for detail?id=ptr-01, got %d", wQuery.Code)
	}

	// 3. ID tidak ada (ptr-999) harus 404
	reqNotFound := httptest.NewRequest(http.MethodGet, "/api/v1/partners/ptr-999", nil)
	wNotFound := httptest.NewRecorder()
	r.ServeHTTP(wNotFound, reqNotFound)

	if wNotFound.Code != http.StatusNotFound {
		t.Fatalf("Expected 404 Not Found, got %d", wNotFound.Code)
	}
}

