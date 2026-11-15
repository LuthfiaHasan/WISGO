package booking_escrow

import (
	"database/sql"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db *sql.DB
}

// NewPostgresRepository membuat instance repository berbasis PostgreSQL (Supabase)
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{db: db}
}

func (r *postgresRepository) SaveBooking(b *models.BookingEscrow) error {
	query := `
		INSERT INTO booking_escrows (
			id, partner_id, user_id, total_amount, currency, status, qr_code_ticket, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9);
	`
	now := time.Now()
	if b.CreatedAt.IsZero() {
		b.CreatedAt = now
	}
	_, err := r.db.Exec(query, b.ID, b.PartnerID, b.UserID, b.TotalAmount, b.Currency, b.Status, b.QRCodeTicket, b.CreatedAt, now)
	return err
}

func (r *postgresRepository) GetBookingByID(id string) (*models.BookingEscrow, bool) {
	query := `
		SELECT id, partner_id, user_id, total_amount, currency, status, COALESCE(qr_code_ticket, ''), created_at
		FROM booking_escrows
		WHERE id = $1;
	`
	var b models.BookingEscrow
	err := r.db.QueryRow(query, id).Scan(
		&b.ID, &b.PartnerID, &b.UserID, &b.TotalAmount, &b.Currency, &b.Status, &b.QRCodeTicket, &b.CreatedAt,
	)
	if err != nil {
		return nil, false
	}
	return &b, true
}

func (r *postgresRepository) GetBookingByQRCode(qrCode string) (*models.BookingEscrow, bool) {
	norm := strings.TrimSpace(qrCode)
	cleanID := strings.TrimPrefix(norm, "QR-RANCAK-TKT-")
	cleanID = strings.TrimPrefix(cleanID, "QR-TICKET-")

	query := `
		SELECT id, partner_id, user_id, total_amount, currency, status, COALESCE(qr_code_ticket, ''), created_at
		FROM booking_escrows
		WHERE qr_code_ticket = $1
		   OR qr_code_ticket = $2
		   OR qr_code_ticket = $3
		   OR id = $4
		LIMIT 1;
	`
	var b models.BookingEscrow
	err := r.db.QueryRow(query, norm, "QR-RANCAK-TKT-"+cleanID, "QR-TICKET-"+cleanID, cleanID).Scan(
		&b.ID, &b.PartnerID, &b.UserID, &b.TotalAmount, &b.Currency, &b.Status, &b.QRCodeTicket, &b.CreatedAt,
	)
	if err != nil {
		return nil, false
	}
	return &b, true
}

func (r *postgresRepository) UpdateBooking(b *models.BookingEscrow) error {
	query := `
		UPDATE booking_escrows
		SET status = $1, qr_code_ticket = $2, updated_at = NOW()
		WHERE id = $3;
	`
	_, err := r.db.Exec(query, b.Status, b.QRCodeTicket, b.ID)
	return err
}

func (r *postgresRepository) GetPartnerByID(partnerID string) (*models.PartnerNagari, bool) {
	query := `
		SELECT id, name, category, whatsapp, spicy_level, is_verified, standard_fee, nagari_name
		FROM partners
		WHERE id = $1;
	`
	var p models.PartnerNagari
	err := r.db.QueryRow(query, partnerID).Scan(
		&p.ID, &p.Name, &p.Category, &p.WhatsApp, &p.SpicyLevel, &p.IsVerified, &p.StandardFee, &p.NagariName,
	)
	if err != nil {
		return nil, false
	}
	return &p, true
}
