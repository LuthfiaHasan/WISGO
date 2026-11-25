package group

import (
	"database/sql"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db          *sql.DB
	mu          sync.RWMutex
	groupRadars map[string]map[string]models.MemberRadarLocation // Ephemeral radar telemetry (RAM)
}

// NewPostgresRepository membuat instance repository berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{
		db:          db,
		groupRadars: make(map[string]map[string]models.MemberRadarLocation),
	}
}

func (r *postgresRepository) CreateRoom(room models.GroupRoom, leader models.User) error {
	now := time.Now()
	if room.CreatedAt.IsZero() {
		room.CreatedAt = now
	}

	// 1. Pastikan user leader terdaftar di users
	_, _ = r.db.Exec(`
		INSERT INTO users (id, phone_number, full_name, role, created_at)
		VALUES ($1, $2, $3, 'tourist', NOW())
		ON CONFLICT (id) DO NOTHING;
	`, leader.ID, leader.PhoneNumber, leader.FullName)

	// 2. Simpan room
	_, err := r.db.Exec(`
		INSERT INTO group_rooms (id, room_code, title, leader_id, created_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (room_code) DO NOTHING;
	`, room.ID, room.RoomCode, room.Title, leader.ID, room.CreatedAt)
	if err != nil {
		return err
	}

	// 3. Simpan leader sebagai member pertama
	memID := fmt.Sprintf("mem-%d", time.Now().UnixNano()%100000)
	_, err = r.db.Exec(`
		INSERT INTO group_members (id, group_room_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, 'leader', $4)
		ON CONFLICT DO NOTHING;
	`, memID, room.ID, leader.ID, room.CreatedAt)
	return err
}

func (r *postgresRepository) FindRoomByCode(code string) (*models.GroupRoom, []models.GroupMember, error) {
	var room models.GroupRoom
	err := r.db.QueryRow(`
		SELECT id, room_code, title, leader_id, created_at
		FROM group_rooms
		WHERE room_code = $1;
	`, code).Scan(&room.ID, &room.RoomCode, &room.Title, &room.LeaderID, &room.CreatedAt)
	if err != nil {
		return nil, nil, errors.New("Ruang rombongan tidak ditemukan")
	}

	// Ambil members beserta info user
	rows, err := r.db.Query(`
		SELECT gm.id, gm.group_room_id, gm.user_id, gm.role, gm.joined_at,
		       COALESCE(u.phone_number, ''), COALESCE(u.full_name, ''), COALESCE(u.role, 'tourist')
		FROM group_members gm
		LEFT JOIN users u ON u.id = gm.user_id
		WHERE gm.group_room_id = $1
		ORDER BY gm.joined_at ASC;
	`, room.ID)
	if err != nil {
		return &room, []models.GroupMember{}, nil
	}
	defer rows.Close()

	var members []models.GroupMember
	for rows.Next() {
		var m models.GroupMember
		var phone, name, uRole string
		if err := rows.Scan(&m.ID, &m.GroupRoomID, &m.UserID, &m.Role, &m.JoinedAt, &phone, &name, &uRole); err == nil {
			m.User = &models.User{
				ID:          m.UserID,
				PhoneNumber: phone,
				FullName:    name,
				Role:        uRole,
			}
			members = append(members, m)
		}
	}
	return &room, members, nil
}

func (r *postgresRepository) AddMember(code string, user models.User) error {
	room, _, err := r.FindRoomByCode(code)
	if err != nil {
		return err
	}

	// Pastikan user ada di tabel users
	_, _ = r.db.Exec(`
		INSERT INTO users (id, phone_number, full_name, role, created_at)
		VALUES ($1, $2, $3, 'tourist', NOW())
		ON CONFLICT (id) DO NOTHING;
	`, user.ID, user.PhoneNumber, user.FullName)

	memID := fmt.Sprintf("mem-%d", time.Now().UnixNano()%100000)
	_, err = r.db.Exec(`
		INSERT INTO group_members (id, group_room_id, user_id, role, joined_at)
		VALUES ($1, $2, $3, 'member', NOW())
		ON CONFLICT (group_room_id, user_id) DO NOTHING;
	`, memID, room.ID, user.ID)
	return err
}

func (r *postgresRepository) RecordVote(code string, vote models.GroupVote) error {
	room, _, err := r.FindRoomByCode(code)
	if err != nil {
		return err
	}

	voteID := fmt.Sprintf("vt-%d", time.Now().UnixNano()%100000)
	_, err = r.db.Exec(`
		INSERT INTO group_votes (id, group_room_id, user_id, destination_id, vote_type, created_at)
		VALUES ($1, $2, $3, $4, $5, NOW())
		ON CONFLICT (group_room_id, user_id, destination_id) DO UPDATE SET vote_type = EXCLUDED.vote_type;
	`, voteID, room.ID, vote.UserID, vote.DestinationID, vote.VoteType)
	return err
}

func (r *postgresRepository) GetVotes(code string) ([]models.GroupVote, error) {
	room, _, err := r.FindRoomByCode(code)
	if err != nil {
		return nil, err
	}

	rows, err := r.db.Query(`
		SELECT id, group_room_id, user_id, destination_id, vote_type
		FROM group_votes
		WHERE group_room_id = $1;
	`, room.ID)
	if err != nil {
		return []models.GroupVote{}, nil
	}
	defer rows.Close()

	var votes []models.GroupVote
	for rows.Next() {
		var v models.GroupVote
		if err := rows.Scan(&v.ID, &v.GroupRoomID, &v.UserID, &v.DestinationID, &v.VoteType); err == nil {
			votes = append(votes, v)
		}
	}
	return votes, nil
}

func (r *postgresRepository) SaveRadarPing(code string, location models.MemberRadarLocation) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.groupRadars[code] == nil {
		r.groupRadars[code] = make(map[string]models.MemberRadarLocation)
	}
	r.groupRadars[code][location.UserID] = location
	return nil
}

func (r *postgresRepository) GetRadarFeed(code string) (map[string]models.MemberRadarLocation, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	feed := r.groupRadars[code]
	if feed == nil {
		feed = make(map[string]models.MemberRadarLocation)
	}
	return feed, nil
}
