package group

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// Handler menangani request HTTP untuk domain Private Group Room & Fitur Rombongan (Gin Framework)
type Handler struct {
	service Service
}

// NewHandler membuat instance handler baru
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mendaftarkan rute-rute group ke Gin RouterGroup
func (h *Handler) RegisterRoutes(rg *gin.RouterGroup) {
	rg.POST("/groups", h.CreateGroup)
	rg.GET("/groups/:code", h.GetGroup)
	rg.GET("/groups/detail", h.GetGroup)
	rg.POST("/groups/:code/join", h.JoinGroup)
	rg.POST("/groups/:code/vote", h.Vote)
	rg.POST("/groups/vote", h.Vote)
	rg.GET("/groups/:code/results", h.GetVoteResults)
	rg.GET("/groups/results", h.GetVoteResults)
	rg.POST("/groups/:code/split-bill", h.SplitBill)
	rg.POST("/groups/split-bill", h.SplitBill)
	rg.POST("/groups/:code/radar", h.RadarPing)
	rg.POST("/groups/:code/radar-ping", h.RadarPing)
	rg.GET("/groups/:code/radar", h.GetRadarFeed)
}

func (h *Handler) getRoomCode(c *gin.Context) string {
	code := c.Param("code")
	if code == "" {
		code = c.Query("code")
	}
	if code == "" {
		code = "RANCAK-MINANG-88"
	}
	return code
}

// CreateGroup menangani POST /api/v1/groups
func (h *Handler) CreateGroup(c *gin.Context) {
	var req CreateGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "leader_id dan title wajib diisi")
		return
	}

	room, inviteLink, err := h.service.CreateGroup(req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusCreated, "Ruang rombongan berhasil dibuat", map[string]interface{}{
		"room":        room,
		"invite_link": inviteLink,
	})
}

// GetGroup menangani GET /api/v1/groups/:code
func (h *Handler) GetGroup(c *gin.Context) {
	code := h.getRoomCode(c)

	room, members, err := h.service.GetGroup(code)
	if err != nil {
		common.Error(c, http.StatusNotFound, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Detail ruang rombongan berhasil dimuat", map[string]interface{}{
		"room":    room,
		"members": members,
	})
}

// JoinGroup menangani POST /api/v1/groups/:code/join
func (h *Handler) JoinGroup(c *gin.Context) {
	code := h.getRoomCode(c)

	var req JoinGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "user_id wajib diisi")
		return
	}

	room, members, err := h.service.JoinGroup(code, req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Berhasil bergabung ke ruang rombongan", map[string]interface{}{
		"room":    room,
		"members": members,
	})
}

// Vote menangani POST /api/v1/groups/:code/vote
func (h *Handler) Vote(c *gin.Context) {
	code := h.getRoomCode(c)

	var req GroupVoteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "user_id, destination_id, dan vote_type ('upvote'/'downvote') wajib diisi")
		return
	}

	if req.VoteType != "upvote" && req.VoteType != "downvote" {
		common.Error(c, http.StatusBadRequest, "vote_type harus 'upvote' atau 'downvote'")
		return
	}

	if err := h.service.Vote(code, req); err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Voting destinasi rombongan berhasil dicatat", map[string]interface{}{
		"destination_id": req.DestinationID,
		"vote_type":      req.VoteType,
	})
}

// GetVoteResults menangani GET /api/v1/groups/:code/results
func (h *Handler) GetVoteResults(c *gin.Context) {
	code := h.getRoomCode(c)

	results, err := h.service.GetVoteResults(code)
	if err != nil {
		common.Error(c, http.StatusNotFound, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Hasil rekapitulasi voting live rombongan berhasil dimuat", results)
}

// SplitBill menangani POST /api/v1/groups/:code/split-bill
func (h *Handler) SplitBill(c *gin.Context) {
	code := h.getRoomCode(c)

	var req SplitBillRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "total_amount (harus > 0) dan description wajib diisi")
		return
	}

	res, err := h.service.CalculateSplitBill(code, req)
	if err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Kalkulasi pembagian tagihan rombongan berhasil", res)
}

// RadarPing menangani POST /api/v1/groups/:code/radar-ping
func (h *Handler) RadarPing(c *gin.Context) {
	code := h.getRoomCode(c)

	var req RadarPingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "user_id, latitude, dan longitude wajib diisi")
		return
	}

	if err := h.service.RadarPing(code, req); err != nil {
		common.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Ping koordinat radar anggota berhasil diperbarui", map[string]interface{}{
		"user_id":   req.UserID,
		"latitude":  req.Latitude,
		"longitude": req.Longitude,
	})
}

// GetRadarFeed menangani GET /api/v1/groups/:code/radar
func (h *Handler) GetRadarFeed(c *gin.Context) {
	code := h.getRoomCode(c)

	list, err := h.service.GetRadarFeed(code)
	if err != nil {
		common.Error(c, http.StatusNotFound, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Feed radar live rombongan berhasil dimuat", map[string]interface{}{
		"active_members": len(list),
		"locations":      list,
	})
}

