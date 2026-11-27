package group

// CreateGroupRequest payload pembuatan ruang rombongan baru
type CreateGroupRequest struct {
	LeaderID string `json:"leader_id" binding:"required"`
	Title    string `json:"title" binding:"required"`
}

// JoinGroupRequest payload bergabung ke grup rombongan
type JoinGroupRequest struct {
	UserID   string `json:"user_id" binding:"required"`
	FullName string `json:"full_name"`
}

// GroupVoteRequest payload voting destinasi atau homestay
type GroupVoteRequest struct {
	GroupRoomID   string `json:"group_room_id"`
	UserID        string `json:"user_id" binding:"required"`
	DestinationID string `json:"destination_id" binding:"required"`
	VoteType      string `json:"vote_type" binding:"required"` // "upvote" atau "downvote"
}

// VoteResultItem rekapitulasi hasil voting live per destinasi
type VoteResultItem struct {
	DestinationID   string  `json:"destination_id"`
	DestinationName string  `json:"destination_name"`
	Upvotes         int     `json:"upvotes"`
	Downvotes       int     `json:"downvotes"`
	ApprovalPercent float64 `json:"approval_percent"`
}

// SplitBillRequest payload kalkulator patungan rombongan
type SplitBillRequest struct {
	TotalAmount float64  `json:"total_amount" binding:"required,gt=0"`
	Description string   `json:"description" binding:"required"`
	MemberIDs   []string `json:"member_ids,omitempty"`
}

// SplitBillMemberShare porsi pembayaran tagihan per individu
type SplitBillMemberShare struct {
	UserID      string  `json:"user_id"`
	Amount      float64 `json:"amount"`
	PaymentLink string  `json:"payment_link"`
}

// SplitBillResponse rincian pembagian tagihan rombongan
type SplitBillResponse struct {
	TotalAmount     float64                `json:"total_amount"`
	MemberCount     int                    `json:"member_count"`
	AmountPerPerson float64                `json:"amount_per_person"`
	Description     string                 `json:"description"`
	Shares          []SplitBillMemberShare `json:"shares"`
}

// RadarPingRequest koordinat GPS opt-in anggota rombongan
type RadarPingRequest struct {
	UserID    string  `json:"user_id" binding:"required"`
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
}

