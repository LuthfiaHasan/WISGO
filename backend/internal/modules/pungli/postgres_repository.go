package pungli

import (
	"database/sql"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db       *sql.DB
	fallback Repository
}

// NewPostgresRepository membuat instance repository Satgas Saber Pungli berbasis PostgreSQL Supabase
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{
		db:       db,
		fallback: NewRepository(),
	}
}

func (r *postgresRepository) CreatePungliReport(input models.PungliReport) models.PungliReport {
	created := r.fallback.CreatePungliReport(input)

	_, _ = r.db.Exec(`
		INSERT INTO pungli_reports (
			id, ticket_code, destination_id, reporter_name, incident_category,
			charged_amount_idr, official_perda_price_idr, overcharge_amount_idr,
			photo_evidence, upload_format, latitude, longitude, description, status, satgas_notes, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5,
			$6, $7, $8,
			$9, $10, $11, $12, $13, $14, $15, $16, $17
		) ON CONFLICT (id) DO NOTHING;
	`, created.ID, created.TicketCode, created.DestinationID, created.ReporterName, created.IncidentCategory,
		created.ChargedAmountIDR, created.OfficialPerdaPriceIDR, created.OverchargeAmountIDR,
		created.PhotoEvidence, created.UploadFormat, created.Latitude, created.Longitude,
		created.Description, created.Status, created.SatgasNotes, created.CreatedAt, created.UpdatedAt)

	return created
}

func (r *postgresRepository) ListPungliReports(statusFilter string) []models.PungliReport {
	return r.fallback.ListPungliReports(statusFilter)
}

func (r *postgresRepository) UpdatePungliReportStatus(idOrTicket, newStatus, satgasNotes string) (*models.PungliReport, error) {
	updated, err := r.fallback.UpdatePungliReportStatus(idOrTicket, newStatus, satgasNotes)
	if err == nil && updated != nil {
		_, _ = r.db.Exec(`
			UPDATE pungli_reports
			SET status = $1, satgas_notes = $2, updated_at = NOW()
			WHERE LOWER(id) = LOWER($3);
		`, updated.Status, updated.SatgasNotes, updated.ID)
	}
	return updated, err
}
