package group

import (
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// Repository antarmuka data access untuk modul Private Group Room & Fitur Rombongan
type Repository interface {
	CreateRoom(room models.GroupRoom, leader models.User) error
	FindRoomByCode(code string) (*models.GroupRoom, []models.GroupMember, error)
	AddMember(code string, user models.User) error
	RecordVote(code string, vote models.GroupVote) error
	GetVotes(code string) ([]models.GroupVote, error)
	SaveRadarPing(code string, location models.MemberRadarLocation) error
	GetRadarFeed(code string) (map[string]models.MemberRadarLocation, error)
}

type inMemoryRepository struct {
	mu          sync.RWMutex
	rooms       map[string]models.GroupRoom                      // key: room_code -> GroupRoom
	members     map[string][]models.GroupMember                  // key: room_code -> []GroupMember
	votes       map[string][]models.GroupVote                    // key: room_code -> []GroupVote
	groupRadars map[string]map[string]models.MemberRadarLocation // key: room_code -> user_id -> location
}

// NewRepository menginisialisasi repository dengan grup seeder awal
func NewRepository() Repository {
	repo := &inMemoryRepository{
		rooms:       make(map[string]models.GroupRoom),
		members:     make(map[string][]models.GroupMember),
		votes:       make(map[string][]models.GroupVote),
		groupRadars: make(map[string]map[string]models.MemberRadarLocation),
	}

	// Seeder Ruang Rombongan Awal
	roomCode := "RANCAK-MINANG-88"
	repo.rooms[roomCode] = models.GroupRoom{
		ID:        "grp-001",
		RoomCode:  roomCode,
		Title:     "Rombongan Wisata Mandiri Family Padang-Bukittinggi",
		LeaderID:  "usr-001",
		CreatedAt: time.Now().Add(-2 * time.Hour),
	}

	repo.members[roomCode] = []models.GroupMember{
		{
			ID:          "mem-01",
			GroupRoomID: "grp-001",
			UserID:      "usr-001",
			Role:        "leader",
			JoinedAt:    time.Now().Add(-2 * time.Hour),
			User: &models.User{
				ID:          "usr-001",
				PhoneNumber: "6281211112222",
				FullName:    "Rahmat Hidayat (Leader)",
			},
		},
	}

	return repo
}

func (r *inMemoryRepository) CreateRoom(room models.GroupRoom, leader models.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.rooms[room.RoomCode] = room
	r.members[room.RoomCode] = []models.GroupMember{
		{
			ID:          fmt.Sprintf("mem-%d", time.Now().UnixNano()%10000),
			GroupRoomID: room.ID,
			UserID:      leader.ID,
			Role:        "leader",
			JoinedAt:    time.Now(),
			User:        &leader,
		},
	}
	return nil
}

func (r *inMemoryRepository) FindRoomByCode(code string) (*models.GroupRoom, []models.GroupMember, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	room, exists := r.rooms[code]
	if !exists {
		return nil, nil, errors.New("Ruang rombongan tidak ditemukan")
	}

	members := r.members[code]
	return &room, members, nil
}

func (r *inMemoryRepository) AddMember(code string, user models.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	room, exists := r.rooms[code]
	if !exists {
		return errors.New("Ruang rombongan tidak ditemukan")
	}

	// Cek apakah sudah pernah bergabung
	for _, m := range r.members[code] {
		if m.UserID == user.ID {
			return nil // Sudah bergabung
		}
	}

	newMember := models.GroupMember{
		ID:          fmt.Sprintf("mem-%d", time.Now().UnixNano()%10000),
		GroupRoomID: room.ID,
		UserID:      user.ID,
		Role:        "member",
		JoinedAt:    time.Now(),
		User:        &user,
	}

	r.members[code] = append(r.members[code], newMember)
	return nil
}

func (r *inMemoryRepository) RecordVote(code string, vote models.GroupVote) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.rooms[code]; !exists {
		return errors.New("Ruang rombongan tidak ditemukan")
	}

	// Cek apakah user sudah pernah voting untuk destinasi ini di room ini
	currentVotes := r.votes[code]
	for i, v := range currentVotes {
		if v.UserID == vote.UserID && v.DestinationID == vote.DestinationID {
			currentVotes[i].VoteType = vote.VoteType // Update pilihan vote
			r.votes[code] = currentVotes
			return nil
		}
	}

	r.votes[code] = append(r.votes[code], vote)
	return nil
}

func (r *inMemoryRepository) GetVotes(code string) ([]models.GroupVote, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if _, exists := r.rooms[code]; !exists {
		return nil, errors.New("Ruang rombongan tidak ditemukan")
	}

	return r.votes[code], nil
}

func (r *inMemoryRepository) SaveRadarPing(code string, location models.MemberRadarLocation) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.rooms[code]; !exists {
		return errors.New("Ruang rombongan tidak ditemukan")
	}

	if r.groupRadars[code] == nil {
		r.groupRadars[code] = make(map[string]models.MemberRadarLocation)
	}

	r.groupRadars[code][location.UserID] = location
	return nil
}

func (r *inMemoryRepository) GetRadarFeed(code string) (map[string]models.MemberRadarLocation, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if _, exists := r.rooms[code]; !exists {
		return nil, errors.New("Ruang rombongan tidak ditemukan")
	}

	feed := r.groupRadars[code]
	if feed == nil {
		return make(map[string]models.MemberRadarLocation), nil
	}
	return feed, nil
}

