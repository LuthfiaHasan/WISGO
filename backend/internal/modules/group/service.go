package group

import (
	"crypto/rand"
	"errors"
	"fmt"
	"math"
	"net/url"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Service antarmuka logika bisnis murni untuk Private Group Room, Voting, Split-Bill & Radar (Pilar 4)
type Service interface {
	CreateGroup(req CreateGroupRequest) (*models.GroupRoom, string, error)
	GetGroup(code string) (*models.GroupRoom, []models.GroupMember, error)
	JoinGroup(code string, req JoinGroupRequest) (*models.GroupRoom, []models.GroupMember, error)
	Vote(code string, req GroupVoteRequest) error
	GetVoteResults(code string) ([]VoteResultItem, error)
	CalculateSplitBill(code string, req SplitBillRequest) (*SplitBillResponse, error)
	RadarPing(code string, req RadarPingRequest) error
	GetRadarFeed(code string) ([]models.MemberRadarLocation, error)
}

type groupService struct {
	repo Repository
}

// NewService membuat instance baru dari GroupService
func NewService(repo Repository) Service {
	return &groupService{repo: repo}
}

func (s *groupService) CreateGroup(req CreateGroupRequest) (*models.GroupRoom, string, error) {
	if req.LeaderID == "" || req.Title == "" {
		return nil, "", errors.New("leader_id dan title wajib diisi")
	}

	b := make([]byte, 2)
	_, _ = rand.Read(b)
	roomCode := fmt.Sprintf("RANCAK-%04X", b)

	room := models.GroupRoom{
		ID:        fmt.Sprintf("grp-%d", time.Now().UnixNano()%100000),
		RoomCode:  roomCode,
		Title:     req.Title,
		LeaderID:  req.LeaderID,
		CreatedAt: time.Now(),
	}

	leaderUser := models.User{
		ID:          req.LeaderID,
		PhoneNumber: "6281211112222",
		FullName:    "Leader Rombongan",
		Role:        "tourist",
		CreatedAt:   time.Now(),
	}

	if err := s.repo.CreateRoom(room, leaderUser); err != nil {
		return nil, "", err
	}

	inviteText := fmt.Sprintf("Halo dunsanak! Mari bergabung ke ruang rombongan wisata WISGO '%s'. Klik tautan ini: https://wisgo.sumbarprov.go.id/group/%s", req.Title, roomCode)
	whatsappInviteLink := fmt.Sprintf("https://wa.me/?text=%s", url.QueryEscape(inviteText))

	return &room, whatsappInviteLink, nil
}

func (s *groupService) GetGroup(code string) (*models.GroupRoom, []models.GroupMember, error) {
	if code == "" {
		code = "RANCAK-MINANG-88"
	}
	return s.repo.FindRoomByCode(code)
}

func (s *groupService) JoinGroup(code string, req JoinGroupRequest) (*models.GroupRoom, []models.GroupMember, error) {
	if code == "" || req.UserID == "" {
		return nil, nil, errors.New("room_code dan user_id wajib diisi")
	}

	fullName := req.FullName
	if fullName == "" {
		fullName = "Anggota Rombongan Baru"
	}

	user := models.User{
		ID:          req.UserID,
		PhoneNumber: "6281200001111",
		FullName:    fullName,
		Role:        "tourist",
		CreatedAt:   time.Now(),
	}

	if err := s.repo.AddMember(code, user); err != nil {
		return nil, nil, err
	}

	return s.repo.FindRoomByCode(code)
}

func (s *groupService) Vote(code string, req GroupVoteRequest) error {
	if code == "" || req.DestinationID == "" || req.UserID == "" {
		return errors.New("room_code, destination_id, dan user_id wajib diisi")
	}

	vote := models.GroupVote{
		ID:            fmt.Sprintf("vote-%d", time.Now().UnixNano()%100000),
		GroupRoomID:   code,
		UserID:        req.UserID,
		DestinationID: req.DestinationID,
		VoteType:      req.VoteType,
	}

	return s.repo.RecordVote(code, vote)
}

func (s *groupService) GetVoteResults(code string) ([]VoteResultItem, error) {
	if code == "" {
		code = "RANCAK-MINANG-88"
	}

	votes, err := s.repo.GetVotes(code)
	if err != nil {
		return nil, err
	}

	destinationNames := map[string]string{
		"dest-01": "Jam Gadang Bukittinggi",
		"dest-02": "Lembah Harau Payakumbuh",
		"dest-03": "Istano Basa Pagaruyung",
		"dest-04": "Danau Maninjau & Kelok 44",
		"dest-05": "Kawasan Bahari Mandeh",
	}

	type tally struct {
		up   int
		down int
	}
	tallies := make(map[string]*tally)

	for _, v := range votes {
		if tallies[v.DestinationID] == nil {
			tallies[v.DestinationID] = &tally{}
		}
		if v.VoteType == "upvote" {
			tallies[v.DestinationID].up++
		} else if v.VoteType == "downvote" {
			tallies[v.DestinationID].down++
		}
	}

	var results []VoteResultItem
	for destID, t := range tallies {
		total := t.up + t.down
		approval := 0.0
		if total > 0 {
			approval = (float64(t.up) / float64(total)) * 100.0
		}

		name := destinationNames[destID]
		if name == "" {
			name = "Destinasi Pilihan Rombongan"
		}

		results = append(results, VoteResultItem{
			DestinationID:   destID,
			DestinationName: name,
			Upvotes:         t.up,
			Downvotes:       t.down,
			ApprovalPercent: math.Round(approval*10) / 10,
		})
	}

	return results, nil
}

func (s *groupService) CalculateSplitBill(code string, req SplitBillRequest) (*SplitBillResponse, error) {
	if code == "" {
		code = "RANCAK-MINANG-88"
	}

	_, members, err := s.repo.FindRoomByCode(code)
	if err != nil {
		return nil, err
	}

	memberCount := len(members)
	if memberCount == 0 {
		memberCount = 1
	}

	amountPerPerson := math.Round((req.TotalAmount/float64(memberCount))*100) / 100

	var shares []SplitBillMemberShare
	for _, m := range members {
		shares = append(shares, SplitBillMemberShare{
			UserID:      m.UserID,
			Amount:      amountPerPerson,
			PaymentLink: fmt.Sprintf("https://qris.id/pay/qr-split-%s-%s-%.0f", code, m.UserID, amountPerPerson),
		})
	}

	return &SplitBillResponse{
		TotalAmount:     req.TotalAmount,
		MemberCount:     memberCount,
		AmountPerPerson: amountPerPerson,
		Description:     req.Description,
		Shares:          shares,
	}, nil
}

func (s *groupService) RadarPing(code string, req RadarPingRequest) error {
	if code == "" || req.UserID == "" {
		return errors.New("room_code dan user_id wajib diisi")
	}

	loc := models.MemberRadarLocation{
		UserID:    req.UserID,
		Latitude:  req.Latitude,
		Longitude: req.Longitude,
		UpdatedAt: time.Now(),
	}

	return s.repo.SaveRadarPing(code, loc)
}

func (s *groupService) GetRadarFeed(code string) ([]models.MemberRadarLocation, error) {
	if code == "" {
		code = "RANCAK-MINANG-88"
	}

	feedMap, err := s.repo.GetRadarFeed(code)
	if err != nil {
		return nil, err
	}

	var list []models.MemberRadarLocation
	for _, loc := range feedMap {
		list = append(list, loc)
	}

	return list, nil
}

