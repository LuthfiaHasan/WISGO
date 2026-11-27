package group

import (
	"bytes"
	"encoding/json"
	"fmt"
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

func TestCreateAndGetGroup(t *testing.T) {
	r, _ := setupTestRouter()

	// 1. Create Room
	body, _ := json.Marshal(CreateGroupRequest{
		LeaderID: "usr-lead",
		Title:    "Rombongan Wisata Danau Singkarak",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("Expected 201 Created, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	room := data["room"].(map[string]interface{})
	roomCode := room["room_code"].(string)

	if roomCode == "" {
		t.Fatalf("Expected room_code to be generated")
	}

	// 2. Get Group Detail
	getReq := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/groups/%s", roomCode), nil)
	getW := httptest.NewRecorder()
	r.ServeHTTP(getW, getReq)

	if getW.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on GetGroup, got %d", getW.Code)
	}

	var getResp common.ResponseStandar
	_ = json.Unmarshal(getW.Body.Bytes(), &getResp)
	getData := getResp.Data.(map[string]interface{})
	members := getData["members"].([]interface{})
	if len(members) != 1 {
		t.Fatalf("Expected 1 leader member initially, got %d", len(members))
	}
}

func TestJoinGroup(t *testing.T) {
	r, _ := setupTestRouter()

	// Create room first
	body, _ := json.Marshal(CreateGroupRequest{
		LeaderID: "usr-lead",
		Title:    "Rombongan Harau Explorer",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	room := data["room"].(map[string]interface{})
	roomCode := room["room_code"].(string)

	// Join room
	joinBody, _ := json.Marshal(JoinGroupRequest{
		UserID:   "usr-member-02",
		FullName: "Ahmad Fadli",
	})
	joinReq := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/groups/%s/join", roomCode), bytes.NewReader(joinBody))
	joinReq.Header.Set("Content-Type", "application/json")
	joinW := httptest.NewRecorder()
	r.ServeHTTP(joinW, joinReq)

	if joinW.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on JoinGroup, got %d. Body: %s", joinW.Code, joinW.Body.String())
	}

	var joinResp common.ResponseStandar
	_ = json.Unmarshal(joinW.Body.Bytes(), &joinResp)
	joinData := joinResp.Data.(map[string]interface{})
	members := joinData["members"].([]interface{})
	if len(members) != 2 {
		t.Fatalf("Expected 2 members after join, got %d", len(members))
	}
}

func TestVotingAndResults(t *testing.T) {
	r, _ := setupTestRouter()

	// Default seeder room code is RANCAK-MINANG-88
	voteBody, _ := json.Marshal(GroupVoteRequest{
		UserID:        "usr-001",
		DestinationID: "poi-001",
		VoteType:      "upvote",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups/RANCAK-MINANG-88/vote", bytes.NewReader(voteBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on Vote, got %d", w.Code)
	}

	// Get Vote Results
	resReq := httptest.NewRequest(http.MethodGet, "/api/v1/groups/RANCAK-MINANG-88/results", nil)
	resW := httptest.NewRecorder()
	r.ServeHTTP(resW, resReq)

	if resW.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on GetVoteResults, got %d", resW.Code)
	}

	var resResp common.ResponseStandar
	_ = json.Unmarshal(resW.Body.Bytes(), &resResp)
	results := resResp.Data.([]interface{})
	if len(results) == 0 {
		t.Fatalf("Expected at least 1 destination in vote results")
	}
}

func TestSplitBill(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(SplitBillRequest{
		TotalAmount: 500000,
		Description: "Makan Malam Rumah Makan Lamun Ombak",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups/RANCAK-MINANG-88/split-bill", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on SplitBill, got %d. Body: %s", w.Code, w.Body.String())
	}

	var resp common.ResponseStandar
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp.Data.(map[string]interface{})
	if data["total_amount"].(float64) != 500000 {
		t.Fatalf("Expected total_amount 500000, got %v", data["total_amount"])
	}
	if data["amount_per_person"].(float64) <= 0 {
		t.Fatalf("Expected positive amount_per_person")
	}
}

func TestRadarPingAndFeed(t *testing.T) {
	r, _ := setupTestRouter()

	body, _ := json.Marshal(RadarPingRequest{
		UserID:    "usr-001",
		Latitude:  -0.3055,
		Longitude: 100.3692,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/groups/RANCAK-MINANG-88/radar-ping", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on RadarPing, got %d", w.Code)
	}

	// Get Radar Feed
	feedReq := httptest.NewRequest(http.MethodGet, "/api/v1/groups/RANCAK-MINANG-88/radar", nil)
	feedW := httptest.NewRecorder()
	r.ServeHTTP(feedW, feedReq)

	if feedW.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK on GetRadarFeed, got %d", feedW.Code)
	}

	var feedResp common.ResponseStandar
	_ = json.Unmarshal(feedW.Body.Bytes(), &feedResp)
	feedData := feedResp.Data.(map[string]interface{})
	if feedData["active_members"].(float64) < 1 {
		t.Fatalf("Expected at least 1 active member on radar feed")
	}
}

