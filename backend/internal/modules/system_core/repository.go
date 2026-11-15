package system_core

import (
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/culture_ranking"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/destination"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/scenes360"
	"github.com/LuthfiaHasan/WISGO/backend/internal/modules/spatial"
)

// Repository antarmuka pengambilan katalog kontrak dan probe benchmark sistem
type Repository interface {
	GetContracts(sprintFilter string) []EndpointContractItem
	RunBenchmarkProbes() (spatialDirDur, aggregateDur, scenes360Dur, gaodeHazardDur time.Duration)
}

type inMemoryRepository struct {
	contracts   []EndpointContractItem
	destRepo    destination.Repository
	scenesRepo  scenes360.Repository
	spatialRepo spatial.Repository
	cultureRepo culture_ranking.Repository
}

// NewRepository membuat instance Repository baru untuk modul system_core
func NewRepository(
	destRepo destination.Repository,
	scenesRepo scenes360.Repository,
	spatialRepo spatial.Repository,
	cultureRepo culture_ranking.Repository,
) Repository {
	return &inMemoryRepository{
		contracts:   GetBE1Catalog24Endpoints(),
		destRepo:    destRepo,
		scenesRepo:  scenesRepo,
		spatialRepo: spatialRepo,
		cultureRepo: cultureRepo,
	}
}

func (r *inMemoryRepository) GetContracts(sprintFilter string) []EndpointContractItem {
	filter := strings.ToLower(strings.TrimSpace(sprintFilter))
	if filter == "" {
		result := make([]EndpointContractItem, len(r.contracts))
		copy(result, r.contracts)
		return result
	}

	var filtered []EndpointContractItem
	for _, c := range r.contracts {
		if strings.Contains(strings.ToLower(c.Sprint), filter) {
			filtered = append(filtered, c)
		}
	}
	return filtered
}

func (r *inMemoryRepository) RunBenchmarkProbes() (spatialDirDur, aggregateDur, scenes360Dur, gaodeHazardDur time.Duration) {
	// 1. Ukur latensi direktori spasial 20 destinasi
	t0 := time.Now()
	_ = r.destRepo.FindAllWithSpatial(destination.SpatialFilterParams{
		HasUserGPS: true,
		UserLat:    -0.9471,
		UserLng:    100.4172,
	})
	spatialDirDur = time.Since(t0)

	// 2. Ukur latensi agregasi detail destinasi
	t1 := time.Now()
	_, _ = r.destRepo.FindByID("dest-001", true, -0.9471, 100.4172)
	aggregateDur = time.Since(t1)

	// 3. Ukur latensi kanvas tur 360° + pin interaktif
	t2 := time.Now()
	_ = r.scenesRepo.GetScenes360ByDestinationID("dest-001", "Lembah Harau", "Kab. Lima Puluh Kota")
	scenes360Dur = time.Since(t2)

	// 4. Ukur latensi Gaode Behavior Ranking + Live Hazard Alert
	t3 := time.Now()
	_ = r.cultureRepo.ListGaodeRankings("")
	_ = r.spatialRepo.ListHazardAlerts("", "")
	gaodeHazardDur = time.Since(t3)

	return spatialDirDur, aggregateDur, scenes360Dur, gaodeHazardDur
}
