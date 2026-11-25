package scenes360

import (
	"database/sql"
	"strings"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type postgresRepository struct {
	db       *sql.DB
	fallback Repository
}

// NewPostgresRepository membuat instance repository Scenes360 berbasis PostgreSQL Supabase
// Dilengkapi fallback in-memory otomatis
func NewPostgresRepository(db *sql.DB) Repository {
	return &postgresRepository{
		db:       db,
		fallback: NewRepository(),
	}
}

func (r *postgresRepository) GetScenes360ByDestinationID(destID, destName, cityRegency string) []models.Scene360 {
	key := strings.ToLower(strings.TrimSpace(destID))
	rows, err := r.db.Query(`
		SELECT id, destination_id, title, scene_type, panorama_url, upload_format,
		       spatial_audio_url, initial_pitch, initial_yaw, is_default_scene
		FROM panorama_scenes
		WHERE LOWER(destination_id) = $1
		ORDER BY is_default_scene DESC, id ASC;
	`, key)
	if err != nil {
		return r.fallback.GetScenes360ByDestinationID(destID, destName, cityRegency)
	}
	defer rows.Close()

	var scenes []models.Scene360
	for rows.Next() {
		var sc models.Scene360
		if err := rows.Scan(
			&sc.ID, &sc.DestinationID, &sc.Title, &sc.Type, &sc.PanoramaURL, &sc.UploadFormat,
			&sc.SpatialAudioURL, &sc.InitialPitch, &sc.InitialYaw, &sc.IsDefaultScene,
		); err == nil {
			sc.Hotspots = r.loadHotspots(sc.ID)
			scenes = append(scenes, sc)
		}
	}

	if len(scenes) == 0 {
		return r.fallback.GetScenes360ByDestinationID(destID, destName, cityRegency)
	}
	return scenes
}

func (r *postgresRepository) loadHotspots(sceneID string) []models.Hotspot360 {
	rows, err := r.db.Query(`
		SELECT id, scene_id, pin_type, COALESCE(color_radar, '#2563EB'), pitch, yaw, title,
		       COALESCE(target_ref, ''), COALESCE(voice_text, ''), COALESCE(description, '')
		FROM panorama_hotspots
		WHERE scene_id = $1
		ORDER BY id ASC;
	`, sceneID)
	if err != nil {
		rows, err = r.db.Query(`
			SELECT id, scene_id, pin_type, COALESCE(color_token, '#2563EB'), pitch, yaw, title,
			       COALESCE(target_ref, ''), COALESCE(audio_url, ''), COALESCE(description, '')
			FROM panorama_hotspots
			WHERE scene_id = $1
			ORDER BY id ASC;
		`, sceneID)
	}
	if err != nil {
		return nil
	}
	defer rows.Close()

	var pins []models.Hotspot360
	for rows.Next() {
		var p models.Hotspot360
		if err := rows.Scan(
			&p.ID, &p.SceneID, &p.Type, &p.ColorToken, &p.Pitch, &p.Yaw,
			&p.Title, &p.TargetRef, &p.VoiceText, &p.Description,
		); err == nil {
			p.ColorRadar = p.ColorToken
			p.AudioURL = p.VoiceText
			pins = append(pins, p)
		}
	}
	return pins
}

func (r *postgresRepository) AddScene360CMS(scene models.Scene360) models.Scene360 {
	created := r.fallback.AddScene360CMS(scene)

	_, _ = r.db.Exec(`
		INSERT INTO panorama_scenes (
			id, destination_id, title, scene_type, panorama_url, upload_format,
			spatial_audio_url, initial_pitch, initial_yaw, is_default_scene
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title, panorama_url = EXCLUDED.panorama_url;
	`, created.ID, created.DestinationID, created.Title, created.Type, created.PanoramaURL,
		created.UploadFormat, created.SpatialAudioURL, created.InitialPitch, created.InitialYaw, created.IsDefaultScene)

	return created
}

func (r *postgresRepository) AddHotspotToSceneCMS(sceneID string, pin models.Hotspot360) (*models.Scene360, models.Hotspot360, error) {
	sc, createdPin, err := r.fallback.AddHotspotToSceneCMS(sceneID, pin)
	if err != nil {
		return nil, pin, err
	}

	voice := createdPin.VoiceText
	if voice == "" {
		voice = createdPin.AudioURL
	}
	color := createdPin.ColorRadar
	if color == "" {
		color = createdPin.ColorToken
	}

	_, execErr := r.db.Exec(`
		INSERT INTO panorama_hotspots (
			id, scene_id, pin_type, color_radar, pitch, yaw, title, target_ref, voice_text, description
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title, pitch = EXCLUDED.pitch, yaw = EXCLUDED.yaw;
	`, createdPin.ID, createdPin.SceneID, createdPin.Type, color, createdPin.Pitch, createdPin.Yaw,
		createdPin.Title, createdPin.TargetRef, voice, createdPin.Description)

	if execErr != nil {
		_, _ = r.db.Exec(`
			INSERT INTO panorama_hotspots (
				id, scene_id, pin_type, color_token, pitch, yaw, title, target_ref, audio_url, description
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
			ON CONFLICT (id) DO UPDATE SET
				title = EXCLUDED.title, pitch = EXCLUDED.pitch, yaw = EXCLUDED.yaw;
		`, createdPin.ID, createdPin.SceneID, createdPin.Type, color, createdPin.Pitch, createdPin.Yaw,
			createdPin.Title, createdPin.TargetRef, voice, createdPin.Description)
	}

	return sc, createdPin, nil
}

func (r *postgresRepository) FindSceneByID(sceneID string) (*models.Scene360, error) {
	return r.fallback.FindSceneByID(sceneID)
}

func (r *postgresRepository) GetHotspotsBySceneID(sceneID string) ([]models.Hotspot360, error) {
	pins := r.loadHotspots(sceneID)
	if len(pins) > 0 {
		return pins, nil
	}
	return r.fallback.GetHotspotsBySceneID(sceneID)
}

func (r *postgresRepository) DeleteHotspotCMS(hotspotID string) error {
	_, _ = r.db.Exec(`DELETE FROM panorama_hotspots WHERE LOWER(id) = LOWER($1);`, hotspotID)
	return r.fallback.DeleteHotspotCMS(hotspotID)
}
