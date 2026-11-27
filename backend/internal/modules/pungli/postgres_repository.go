package pungli

import (
	"database/sql"
	"strings"

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
	rows, err := r.db.Query(`
		SELECT p.id, p.ticket_code, p.destination_id, COALESCE(d.name, p.destination_id),
		       p.reporter_name, p.incident_category, p.charged_amount_idr, p.official_perda_price_idr,
		       p.overcharge_amount_idr, p.photo_evidence, p.upload_format, p.latitude, p.longitude,
		       p.description, p.status, p.satgas_notes, p.created_at, p.updated_at
		FROM pungli_reports p
		LEFT JOIN destinations d ON d.id = p.destination_id
		ORDER BY p.created_at DESC;
	`)
	if err != nil {
		return r.fallback.ListPungliReports(statusFilter)
	}
	defer rows.Close()

	filter := strings.ToLower(strings.TrimSpace(statusFilter))
	var list []models.PungliReport
	for rows.Next() {
		var rep models.PungliReport
		if err := rows.Scan(
			&rep.ID, &rep.TicketCode, &rep.DestinationID, &rep.DestinationName,
			&rep.ReporterName, &rep.IncidentCategory, &rep.ChargedAmountIDR, &rep.OfficialPerdaPriceIDR,
			&rep.OverchargeAmountIDR, &rep.PhotoEvidence, &rep.UploadFormat, &rep.Latitude, &rep.Longitude,
			&rep.Description, &rep.Status, &rep.SatgasNotes, &rep.CreatedAt, &rep.UpdatedAt,
		); err == nil {
			if filter != "" && !strings.EqualFold(rep.Status, filter) {
				continue
			}
			list = append(list, rep)
		}
	}

	if len(list) == 0 {
		return r.fallback.ListPungliReports(statusFilter)
	}
	return list
}

func (r *postgresRepository) UpdatePungliReportStatus(idOrTicket, newStatus, satgasNotes string) (*models.PungliReport, error) {
	updated, err := r.fallback.UpdatePungliReportStatus(idOrTicket, newStatus, satgasNotes)
	if err == nil && updated != nil {
		_, _ = r.db.Exec(`
			UPDATE pungli_reports
			SET status = $1, satgas_notes = $2, updated_at = NOW()
			WHERE LOWER(id) = LOWER($3) OR LOWER(ticket_code) = LOWER($3);
		`, updated.Status, updated.SatgasNotes, updated.ID)
	}
	return updated, err
}
