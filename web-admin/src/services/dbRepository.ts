// ============================================================================
// DATA REPOSITORY LAYER & LOCALSTORAGE AUTO-RESET (26 TABEL WISGO V2)
// Sinkron dengan skema final PostgreSQL 16 + PostGIS 3.4
// ============================================================================

import {
  Category,
  Destination,
  DestinationCheckpoint,
  OfflineEmergencyContact,
  IndikatorMedan,
  AturanDestinasi,
  OfficialTariff,
  PanoramaScene,
  PanoramaHotspot,
  OfflineBundle,
  GaodeBehaviorRanking,
  PungliReport,
  DestinationReview,
  ApiTelemetryLog,
  VisitPoint,
  HazardAlert,
  SosSignal,
  MinangPhrase,
  EmergencyContact,
  CulturalEvent,
  SavedPlace,
  StempVisit,
  NewTour,
  Challenge,
  UserChallengeReward,
  User,
  OpenTrip,
  Notifikasi,
  OpenTripOrganizer,
  OpenTripTransaction,
  PackingTemplate,
  WeatherMonitoringItem,
  AdventurerLevelConfig,
  UserProfileExperience,
  PostingShareTemplate,
} from '../types/contract';

import {
  SEED_CATEGORIES,
  SEED_DESTINATIONS,
  SEED_INDIKATOR_MEDAN,
  SEED_ATURAN_DESTINASI,
  SEED_OFFICIAL_TARIFFS,
  SEED_PANORAMA_SCENES,
  SEED_PANORAMA_HOTSPOTS,
  SEED_OFFLINE_BUNDLES,
  SEED_GAODE_RANKINGS,
  SEED_PUNGLI_REPORTS,
  SEED_DESTINATION_REVIEWS,
  SEED_API_TELEMETRY_LOGS,
  SEED_VISIT_POINTS,
  SEED_HAZARD_ALERTS,
  SEED_SOS_SIGNALS,
  SEED_MINANG_PHRASES,
  SEED_EMERGENCY_CONTACTS,
  SEED_CULTURAL_EVENTS,
  SEED_SAVED_PLACES,
  SEED_STEMP_VISITS,
  SEED_NEW_TOURS,
  SEED_CHALLENGES,
  SEED_USER_CHALLENGE_REWARDS,
  SEED_USERS,
  SEED_OPEN_TRIPS,
  SEED_NOTIFIKASI,
  SEED_ORGANIZERS,
  SEED_OPEN_TRIP_TRANSACTIONS,
  SEED_PACKING_TEMPLATES,
  SEED_WEATHER_MONITORING,
  SEED_ADVENTURER_LEVELS,
  SEED_USER_PROFILES,
  SEED_POSTING_TEMPLATES,
} from '../data/mockDatabaseV2';

import { safeSetLocalStorage } from '../utils/imageOptimizer';

const DB_VERSION_KEY = 'wisgo_v2_db_version';
const CURRENT_DB_VERSION = '2.1.0';

// Prefiks tabel penyimpanan lokal baru
export const DB_KEYS = {
  CATEGORIES: 'wisgo_v2_db_categories',
  DESTINATIONS: 'wisgo_v2_db_destinations',
  INDIKATOR_MEDAN: 'wisgo_v2_db_indikator_medan',
  ATURAN_DESTINASI: 'wisgo_v2_db_aturan_destinasi',
  OFFICIAL_TARIFFS: 'wisgo_v2_db_official_tariffs',
  PANORAMA_SCENES: 'wisgo_v2_db_panorama_scenes',
  PANORAMA_HOTSPOTS: 'wisgo_v2_db_panorama_hotspots',
  OFFLINE_BUNDLES: 'wisgo_v2_db_offline_bundles',
  GAODE_RANKINGS: 'wisgo_v2_db_gaode_rankings',
  PUNGLI_REPORTS: 'wisgo_v2_db_pungli_reports',
  DESTINATION_REVIEWS: 'wisgo_v2_db_destination_reviews',
  API_TELEMETRY_LOGS: 'wisgo_v2_db_api_telemetry_logs',
  VISIT_POINTS: 'wisgo_v2_db_visit_points',
  HAZARD_ALERTS: 'wisgo_v2_db_hazard_alerts',
  SOS_SIGNALS: 'wisgo_v2_db_sos_signals',
  MINANG_PHRASES: 'wisgo_v2_db_minang_phrases',
  EMERGENCY_CONTACTS: 'wisgo_v2_db_emergency_contacts',
  CULTURAL_EVENTS: 'wisgo_v2_db_cultural_events',
  SAVED_PLACES: 'wisgo_v2_db_saved_places',
  STEMP_VISITS: 'wisgo_v2_db_stemp_visits',
  NEW_TOURS: 'wisgo_v2_db_new_tours',
  CHALLENGES: 'wisgo_v2_db_challenges',
  USER_CHALLENGE_REWARDS: 'wisgo_v2_db_user_challenge_rewards',
  USERS: 'wisgo_v2_db_users',
  OPEN_TRIPS: 'wisgo_v2_db_open_trips',
  NOTIFIKASI: 'wisgo_v2_db_notifikasi',
  ORGANIZERS: 'wisgo_v2_db_organizers',
  OPEN_TRIP_TRANSACTIONS: 'wisgo_v2_db_open_trip_transactions',
  PACKING_TEMPLATES: 'wisgo_v2_db_packing_templates',
  WEATHER_MONITORING: 'wisgo_v2_db_weather_monitoring',
  ADVENTURER_LEVELS: 'wisgo_v2_db_adventurer_levels',
  USER_PROFILES: 'wisgo_v2_db_user_profiles',
  POSTING_TEMPLATES: 'wisgo_v2_db_posting_templates',
  REVIEW_SETTINGS: 'wisgo_v2_db_review_settings',
} as const;

/**
 * Mekanisme Auto-Reset & Migration:
 * Membersihkan cache localStorage versi lama (v1/rancakin) yang strukturnya bentrok,
 * lalu menginisialisasi dengan dataset 26 tabel versi 2.1.0.
 */
export function initializeAndMigrateDatabase(): void {
  try {
    const installedVersion = localStorage.getItem(DB_VERSION_KEY);

    if (installedVersion !== CURRENT_DB_VERSION) {
      // Hapus seluruh cache lama
      const legacyKeys = [
        'wisgo_dispar_destinations_v2',
        'rancakin_dispar_destinations_v2',
        'wisgo_dispar_pungli_v2',
        'wisgo_dispar_sos_v2',
        'wisgo_dispar_hazard_v2',
        'wisgo_dispar_groups_v2',
        'wisgo_community_submissions_v2',
        'wisgo_tourist_challenges',
        'wisgo_checklist_challenges',
        'wisgo_checklist_claims',
        'wisgo_tourist_ugc_submissions',
        'wisgo_tourist_reviews',
        'wisgo_minang_phrases_v1',
        'wisgo_culture_events_v1',
        'wisgo_gaode_rankings_v1',
        'wisgo_open_trips_v1',
        'wisgo_emergency_contacts',
      ];

      for (const k of legacyKeys) {
        localStorage.removeItem(k);
      }

      // Tulis seed baru
      safeSetLocalStorage(DB_KEYS.CATEGORIES, JSON.stringify(SEED_CATEGORIES));
      safeSetLocalStorage(DB_KEYS.DESTINATIONS, JSON.stringify(SEED_DESTINATIONS));
      safeSetLocalStorage(DB_KEYS.INDIKATOR_MEDAN, JSON.stringify(SEED_INDIKATOR_MEDAN));
      safeSetLocalStorage(DB_KEYS.ATURAN_DESTINASI, JSON.stringify(SEED_ATURAN_DESTINASI));
      safeSetLocalStorage(DB_KEYS.OFFICIAL_TARIFFS, JSON.stringify(SEED_OFFICIAL_TARIFFS));
      safeSetLocalStorage(DB_KEYS.PANORAMA_SCENES, JSON.stringify(SEED_PANORAMA_SCENES));
      safeSetLocalStorage(DB_KEYS.PANORAMA_HOTSPOTS, JSON.stringify(SEED_PANORAMA_HOTSPOTS));
      safeSetLocalStorage(DB_KEYS.OFFLINE_BUNDLES, JSON.stringify(SEED_OFFLINE_BUNDLES));
      safeSetLocalStorage(DB_KEYS.GAODE_RANKINGS, JSON.stringify(SEED_GAODE_RANKINGS));
      safeSetLocalStorage(DB_KEYS.PUNGLI_REPORTS, JSON.stringify(SEED_PUNGLI_REPORTS));
      safeSetLocalStorage(DB_KEYS.DESTINATION_REVIEWS, JSON.stringify(SEED_DESTINATION_REVIEWS));
      safeSetLocalStorage(DB_KEYS.API_TELEMETRY_LOGS, JSON.stringify(SEED_API_TELEMETRY_LOGS));
      safeSetLocalStorage(DB_KEYS.VISIT_POINTS, JSON.stringify(SEED_VISIT_POINTS));
      safeSetLocalStorage(DB_KEYS.HAZARD_ALERTS, JSON.stringify(SEED_HAZARD_ALERTS));
      safeSetLocalStorage(DB_KEYS.SOS_SIGNALS, JSON.stringify(SEED_SOS_SIGNALS));
      safeSetLocalStorage(DB_KEYS.MINANG_PHRASES, JSON.stringify(SEED_MINANG_PHRASES));
      safeSetLocalStorage(DB_KEYS.EMERGENCY_CONTACTS, JSON.stringify(SEED_EMERGENCY_CONTACTS));
      safeSetLocalStorage(DB_KEYS.CULTURAL_EVENTS, JSON.stringify(SEED_CULTURAL_EVENTS));
      safeSetLocalStorage(DB_KEYS.SAVED_PLACES, JSON.stringify(SEED_SAVED_PLACES));
      safeSetLocalStorage(DB_KEYS.STEMP_VISITS, JSON.stringify(SEED_STEMP_VISITS));
      safeSetLocalStorage(DB_KEYS.NEW_TOURS, JSON.stringify(SEED_NEW_TOURS));
      safeSetLocalStorage(DB_KEYS.CHALLENGES, JSON.stringify(SEED_CHALLENGES));
      safeSetLocalStorage(DB_KEYS.USER_CHALLENGE_REWARDS, JSON.stringify(SEED_USER_CHALLENGE_REWARDS));
      safeSetLocalStorage(DB_KEYS.USERS, JSON.stringify(SEED_USERS));
      safeSetLocalStorage(DB_KEYS.OPEN_TRIPS, JSON.stringify(SEED_OPEN_TRIPS));
      safeSetLocalStorage(DB_KEYS.NOTIFIKASI, JSON.stringify(SEED_NOTIFIKASI));
      safeSetLocalStorage(DB_KEYS.ORGANIZERS, JSON.stringify(SEED_ORGANIZERS));
      safeSetLocalStorage(DB_KEYS.OPEN_TRIP_TRANSACTIONS, JSON.stringify(SEED_OPEN_TRIP_TRANSACTIONS));
      safeSetLocalStorage(DB_KEYS.PACKING_TEMPLATES, JSON.stringify(SEED_PACKING_TEMPLATES));
      safeSetLocalStorage(DB_KEYS.WEATHER_MONITORING, JSON.stringify(SEED_WEATHER_MONITORING));
      safeSetLocalStorage(DB_KEYS.ADVENTURER_LEVELS, JSON.stringify(SEED_ADVENTURER_LEVELS));
      safeSetLocalStorage(DB_KEYS.USER_PROFILES, JSON.stringify(SEED_USER_PROFILES));
      safeSetLocalStorage(DB_KEYS.POSTING_TEMPLATES, JSON.stringify(SEED_POSTING_TEMPLATES));
      safeSetLocalStorage(DB_KEYS.REVIEW_SETTINGS, JSON.stringify({ min_character_limit: 40 }));

      localStorage.setItem(DB_VERSION_KEY, CURRENT_DB_VERSION);
    }
  } catch (err) {
    console.error('Failed to initialize or migrate database cache:', err);
  }
}

// Inisialisasi otomatis saat modul ini dimuat
initializeAndMigrateDatabase();

// ============================================================================
// REPOSITORY HELPERS (Generic Read & Write)
// ============================================================================
function readTable<T>(key: string, fallback: T[]): T[] {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.length > 0 ? parsed : fallback;
  } catch {
    return fallback;
  }
}

function writeTable<T>(key: string, data: T[]): void {
  safeSetLocalStorage(key, JSON.stringify(data));
}

// ============================================================================
// 1. REPOSITORY: CATEGORIES
// ============================================================================
export const CategoriesRepo = {
  getAll: (): Category[] => readTable<Category>(DB_KEYS.CATEGORIES, SEED_CATEGORIES),
  getByModule: (moduleType: string): Category[] =>
    CategoriesRepo.getAll().filter((c) => c.module_type === moduleType),
  getById: (id: string): Category | undefined =>
    CategoriesRepo.getAll().find((c) => c.id === id),
};

// ============================================================================
// 2. REPOSITORY: DESTINATIONS & RELASI (1-to-1 Medan, Aturan, Tarif)
// ============================================================================
export const DestinationsRepo = {
  getAll: (): Destination[] => {
    const dests = readTable<Destination>(DB_KEYS.DESTINATIONS, SEED_DESTINATIONS);
    const medans = readTable<IndikatorMedan>(DB_KEYS.INDIKATOR_MEDAN, SEED_INDIKATOR_MEDAN);
    const aturans = readTable<AturanDestinasi>(DB_KEYS.ATURAN_DESTINASI, SEED_ATURAN_DESTINASI);
    const tariffs = readTable<OfficialTariff>(DB_KEYS.OFFICIAL_TARIFFS, SEED_OFFICIAL_TARIFFS);
    const scenes = readTable<PanoramaScene>(DB_KEYS.PANORAMA_SCENES, SEED_PANORAMA_SCENES);
    const hotspots = readTable<PanoramaHotspot>(DB_KEYS.PANORAMA_HOTSPOTS, SEED_PANORAMA_HOTSPOTS);

    return dests.map((d) => ({
      ...d,
      medan_indicator: medans.find((m) => m.destination_id === d.id),
      aturan_destinasi: aturans.filter((a) => a.destination_id === d.id),
      tariffs: tariffs.filter((t) => t.destination_id === d.id),
      official_tariffs: tariffs.filter((t) => t.destination_id === d.id),
      scenes_360: scenes
        .filter((s) => s.destination_id === d.id)
        .map((s) => ({
          ...s,
          hotspots: hotspots.filter((h) => h.scene_id === s.id),
        })),
    }));
  },
  getById: (id: string): Destination | undefined => {
    return DestinationsRepo.getAll().find((d) => d.id === id);
  },
  getBySlug: (slug: string): Destination | undefined => {
    return DestinationsRepo.getAll().find((d) => d.slug === slug || d.id === slug);
  },
  save: (item: Destination): Destination[] => {
    const current = readTable<Destination>(DB_KEYS.DESTINATIONS, SEED_DESTINATIONS);
    const idx = current.findIndex((d) => d.id === item.id);
    const updated = [...current];
    const timestamp = new Date().toISOString();

    const normalized: Destination = {
      ...item,
      updated_at: timestamp,
      created_at: item.created_at || timestamp,
    };

    if (idx >= 0) {
      updated[idx] = normalized;
    } else {
      updated.unshift(normalized);
    }
    writeTable(DB_KEYS.DESTINATIONS, updated);

    // Sinkronkan 1-to-1 Indikator Medan
    if (item.medan_indicator || item.indikator_medan) {
      const med = item.medan_indicator || item.indikator_medan;
      if (med) {
        IndikatorMedanRepo.save({
          ...med,
          id: med.id || `med-${item.id}`,
          destination_id: item.id,
        });
      }
    }

    // Sinkronkan Aturan
    if (item.aturan_destinasi && Array.isArray(item.aturan_destinasi)) {
      writeTable(
        DB_KEYS.ATURAN_DESTINASI,
        [
          ...readTable<AturanDestinasi>(DB_KEYS.ATURAN_DESTINASI, SEED_ATURAN_DESTINASI).filter(
            (a) => a.destination_id !== item.id
          ),
          ...item.aturan_destinasi,
        ]
      );
    }

    // Sinkronkan Tarif
    if (item.official_tariffs || item.tariffs) {
      const trfs = item.official_tariffs || item.tariffs || [];
      writeTable(
        DB_KEYS.OFFICIAL_TARIFFS,
        [
          ...readTable<OfficialTariff>(DB_KEYS.OFFICIAL_TARIFFS, SEED_OFFICIAL_TARIFFS).filter(
            (t) => t.destination_id !== item.id
          ),
          ...trfs,
        ]
      );
    }

    return DestinationsRepo.getAll();
  },
  delete: (id: string): Destination[] => {
    const current = readTable<Destination>(DB_KEYS.DESTINATIONS, SEED_DESTINATIONS);
    const filtered = current.filter((d) => d.id !== id);
    writeTable(DB_KEYS.DESTINATIONS, filtered);
    return DestinationsRepo.getAll();
  },
};

// ============================================================================
// 3. REPOSITORY: INDIKATOR MEDAN (indikator_medan)
// ============================================================================
export const IndikatorMedanRepo = {
  getAll: (): IndikatorMedan[] => readTable<IndikatorMedan>(DB_KEYS.INDIKATOR_MEDAN, SEED_INDIKATOR_MEDAN),
  getByDestinationId: (destId: string): IndikatorMedan | undefined =>
    IndikatorMedanRepo.getAll().find((m) => m.destination_id === destId),
  save: (item: IndikatorMedan): void => {
    const list = IndikatorMedanRepo.getAll();
    const idx = list.findIndex((m) => m.destination_id === item.destination_id);
    const updated = [...list];
    if (idx >= 0) {
      updated[idx] = item;
    } else {
      updated.push(item);
    }
    writeTable(DB_KEYS.INDIKATOR_MEDAN, updated);
  },
};

// ============================================================================
// 4. REPOSITORY: ATURAN DESTINASI (aturan_destinasi)
// ============================================================================
export const AturanDestinasiRepo = {
  getAll: (): AturanDestinasi[] => readTable<AturanDestinasi>(DB_KEYS.ATURAN_DESTINASI, SEED_ATURAN_DESTINASI),
  getByDestinationId: (destId: string): AturanDestinasi[] =>
    AturanDestinasiRepo.getAll().filter((a) => a.destination_id === destId),
  save: (item: AturanDestinasi): void => {
    const list = AturanDestinasiRepo.getAll();
    const idx = list.findIndex((a) => a.id === item.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = item;
    else updated.push(item);
    writeTable(DB_KEYS.ATURAN_DESTINASI, updated);
  },
  delete: (id: string): void => {
    writeTable(
      DB_KEYS.ATURAN_DESTINASI,
      AturanDestinasiRepo.getAll().filter((a) => a.id !== id)
    );
  },
};

// ============================================================================
// 5. REPOSITORY: OFFICIAL TARIFFS (official_tariffs)
// ============================================================================
export const OfficialTariffsRepo = {
  getAll: (): OfficialTariff[] => readTable<OfficialTariff>(DB_KEYS.OFFICIAL_TARIFFS, SEED_OFFICIAL_TARIFFS),
  getByDestinationId: (destId: string): OfficialTariff[] =>
    OfficialTariffsRepo.getAll().filter((t) => t.destination_id === destId),
  save: (item: OfficialTariff): void => {
    const list = OfficialTariffsRepo.getAll();
    const idx = list.findIndex((t) => t.id === item.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = item;
    else updated.push(item);
    writeTable(DB_KEYS.OFFICIAL_TARIFFS, updated);
  },
  delete: (id: string): void => {
    writeTable(
      DB_KEYS.OFFICIAL_TARIFFS,
      OfficialTariffsRepo.getAll().filter((t) => t.id !== id)
    );
  },
};

// ============================================================================
// 6. REPOSITORY: PANORAMA SCENES & HOTSPOTS (360)
// ============================================================================
export const Studio360Repo = {
  getScenes: (destId?: string): PanoramaScene[] => {
    const scenes = readTable<PanoramaScene>(DB_KEYS.PANORAMA_SCENES, SEED_PANORAMA_SCENES);
    const hotspots = readTable<PanoramaHotspot>(DB_KEYS.PANORAMA_HOTSPOTS, SEED_PANORAMA_HOTSPOTS);
    const filtered = destId ? scenes.filter((s) => s.destination_id === destId) : scenes;
    return filtered.map((s) => ({
      ...s,
      hotspots: hotspots.filter((h) => h.scene_id === s.id),
    }));
  },
  saveScene: (scene: PanoramaScene): void => {
    const list = readTable<PanoramaScene>(DB_KEYS.PANORAMA_SCENES, SEED_PANORAMA_SCENES);
    const idx = list.findIndex((s) => s.id === scene.id);
    const updated = [...list];
    const normalized: PanoramaScene = {
      ...scene,
      spatial_audio_url: scene.spatial_audio_url || '',
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.push(normalized);
    writeTable(DB_KEYS.PANORAMA_SCENES, updated);
  },
  saveHotspot: (hotspot: PanoramaHotspot): void => {
    const list = readTable<PanoramaHotspot>(DB_KEYS.PANORAMA_HOTSPOTS, SEED_PANORAMA_HOTSPOTS);
    const idx = list.findIndex((h) => h.id === hotspot.id);
    const updated = [...list];
    const normalized: PanoramaHotspot = {
      ...hotspot,
      target_ref: hotspot.target_ref || '',
      voice_text: hotspot.voice_text || '',
      created_at: hotspot.created_at || new Date().toISOString(),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.push(normalized);
    writeTable(DB_KEYS.PANORAMA_HOTSPOTS, updated);
  },
  deleteHotspot: (id: string): void => {
    const list = readTable<PanoramaHotspot>(DB_KEYS.PANORAMA_HOTSPOTS, SEED_PANORAMA_HOTSPOTS);
    writeTable(DB_KEYS.PANORAMA_HOTSPOTS, list.filter((h) => h.id !== id));
  },
};

// ============================================================================
// 7. REPOSITORY: LAPORAN PUNGLI (pungli_reports)
// ============================================================================
export const PungliReportsRepo = {
  getAll: (): PungliReport[] => readTable<PungliReport>(DB_KEYS.PUNGLI_REPORTS, SEED_PUNGLI_REPORTS),
  save: (report: PungliReport): PungliReport[] => {
    const list = PungliReportsRepo.getAll();
    const idx = list.findIndex((r) => r.id === report.id);
    const updated = [...list];
    const timestamp = new Date().toISOString();
    const normalized: PungliReport = {
      ...report,
      photo_evidence: report.photo_evidence || 'https://via.placeholder.com/400x300?text=Bukti+Pungli',
      updated_at: timestamp,
      created_at: report.created_at || timestamp,
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
    writeTable(DB_KEYS.PUNGLI_REPORTS, updated);
    return updated;
  },
};

// ============================================================================
// 8. REPOSITORY: MODERASI ULASAN (destination_reviews) & NOTIFIKASI
// ============================================================================
export const DestinationReviewsRepo = {
  getAll: (): DestinationReview[] =>
    readTable<DestinationReview>(DB_KEYS.DESTINATION_REVIEWS, SEED_DESTINATION_REVIEWS),
  save: (review: DestinationReview): DestinationReview[] => {
    const list = DestinationReviewsRepo.getAll();
    const idx = list.findIndex((r) => r.id === review.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = review;
    else updated.unshift(review);
    writeTable(DB_KEYS.DESTINATION_REVIEWS, updated);
    return updated;
  },
  toggleImportant: (reviewId: string): DestinationReview[] => {
    const list = DestinationReviewsRepo.getAll();
    const updated = list.map((r) =>
      r.id === reviewId ? { ...r, is_important: !r.is_important } : r
    );
    writeTable(DB_KEYS.DESTINATION_REVIEWS, updated);
    return updated;
  },
  toggleVisibility: (reviewId: string): DestinationReview[] => {
    const list = DestinationReviewsRepo.getAll();
    const updated = list.map((r) =>
      r.id === reviewId ? { ...r, is_hidden: !r.is_hidden } : r
    );
    writeTable(DB_KEYS.DESTINATION_REVIEWS, updated);
    return updated;
  },
  getMinCharacterLimit: (): number => {
    try {
      const raw = localStorage.getItem(DB_KEYS.REVIEW_SETTINGS);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (typeof parsed.min_character_limit === 'number') {
          return parsed.min_character_limit;
        }
      }
    } catch {
      // fallback
    }
    return 30;
  },
  setMinCharacterLimit: (limit: number): void => {
    safeSetLocalStorage(DB_KEYS.REVIEW_SETTINGS, JSON.stringify({ min_character_limit: limit }));
  },
  deleteWithNotice: (reviewId: string, adminReason?: string): DestinationReview[] => {
    const list = DestinationReviewsRepo.getAll();
    const target = list.find((r) => r.id === reviewId);
    const filtered = list.filter((r) => r.id !== reviewId);
    writeTable(DB_KEYS.DESTINATION_REVIEWS, filtered);

    // Opsional: Buat notifikasi ke user bila ulasan dihapus
    if (target) {
      NotifikasiRepo.create({
        id: `notif-${Date.now()}`,
        user_id: target.user_id,
        notification_type: 'review_moderation',
        title: 'Ulasan Anda Telah Dimoderasi',
        message: adminReason
          ? `Ulasan Anda dihapus oleh administrator: ${adminReason}`
          : 'Ulasan Anda tidak memenuhi panduan komunitas WISGO.',
        reference_id: target.id,
        is_read: false,
        created_at: new Date().toISOString(),
      });
    }

    return filtered;
  },
};

// ============================================================================
// 9. REPOSITORY: USULAN DESTINASI USER (new_tour)
// ============================================================================
export const NewTourRepo = {
  getAll: (): NewTour[] => readTable<NewTour>(DB_KEYS.NEW_TOURS, SEED_NEW_TOURS),
  save: (item: NewTour): NewTour[] => {
    const list = NewTourRepo.getAll();
    const idx = list.findIndex((n) => n.id === item.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = item;
    else updated.unshift(item);
    writeTable(DB_KEYS.NEW_TOURS, updated);
    return updated;
  },
  rejectWithNotice: (id: string, reason: string): NewTour[] => {
    const list = NewTourRepo.getAll();
    const target = list.find((n) => n.id === id);
    const updated = list.map((n) => (n.id === id ? { ...n, status: 'rejected' } : n));
    writeTable(DB_KEYS.NEW_TOURS, updated);

    if (target) {
      NotifikasiRepo.create({
        id: `notif-${Date.now()}`,
        user_id: target.user_id,
        notification_type: 'new_tour_rejected',
        title: `Usulan Tempat "${target.name}" Belum Dapat Disetujui`,
        message: `Alasan penolakan dari kurator Dispar: ${reason}`,
        reference_id: target.id,
        is_read: false,
        created_at: new Date().toISOString(),
      });
    }
    return updated;
  },
  approveToDestinations: (tour: NewTour): void => {
    // 1. Ubah status usulan menjadi approved
    const list = NewTourRepo.getAll().map((n) => (n.id === tour.id ? { ...n, status: 'approved' } : n));
    writeTable(DB_KEYS.NEW_TOURS, list);

    const tourName = tour.name || tour.title || 'Destinasi Komunitas';
    const tourLat = tour.latitude ?? -0.9492;
    const tourLng = tour.longitude ?? 100.3543;
    const tourTips = tour.tips_menjaga || 'Jaga kebersihan lingkungan wisata dan hormati kearifan lokal.';

    // 2. Daftarkan otomatis ke tabel destinations
    const newDest: Destination = {
      id: `dest-${Date.now()}`,
      slug: tourName.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
      name: tourName,
      category_id: tour.category_id || 'cat-dest-alam',
      city_regency: tour.city_regency,
      description: tour.description || 'Destinasi yang diusulkan oleh komunitas wisatawan WISGO.',
      latitude: tourLat,
      longitude: tourLng,
      geog: `SRID=4326;POINT(${tourLng.toFixed(6)} ${tourLat.toFixed(6)})`,
      elevation_m: 100,
      cover_image: 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=1200&q=80',
      crowd_level: 'Sepi',
      distance_km: 50,
      travel_time_min: 60,
      estimated_cost: 10000,
      is_hidden_gem: true,
      qr_placard_code: `WISGO-PLG-${Date.now().toString().slice(-4)}`,
      opening_hours: '08.00 - 17.00 WIB',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    DestinationsRepo.save(newDest);

    // 3. Buat aturan wajib menjaga tempat dari tips_menjaga
    AturanDestinasiRepo.save({
      id: `art-${Date.now()}`,
      destination_id: newDest.id,
      category_id: 'cat-rule-lingkungan',
      title: 'Tips Menjaga Tempat (Usulan Komunitas)',
      content: tourTips,
    });
  },
};

// ============================================================================
// 10. REPOSITORY: TANTANGAN & KLAIM HADIAH (challenges & user_challenge_rewards)
// ============================================================================
export const ChallengesRepo = {
  getAll: (): Challenge[] => readTable<Challenge>(DB_KEYS.CHALLENGES, SEED_CHALLENGES),
  save: (item: Challenge): Challenge[] => {
    const list = ChallengesRepo.getAll();
    const idx = list.findIndex((c) => c.id === item.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = item;
    else updated.unshift(item);
    writeTable(DB_KEYS.CHALLENGES, updated);
    return updated;
  },
  delete: (id: string): Challenge[] => {
    const filtered = ChallengesRepo.getAll().filter((c) => c.id !== id);
    writeTable(DB_KEYS.CHALLENGES, filtered);
    return filtered;
  },
};

export const UserChallengeRewardsRepo = {
  getAll: (): UserChallengeReward[] =>
    readTable<UserChallengeReward>(DB_KEYS.USER_CHALLENGE_REWARDS, SEED_USER_CHALLENGE_REWARDS),
  save: (item: UserChallengeReward): UserChallengeReward[] => {
    const list = UserChallengeRewardsRepo.getAll();
    const idx = list.findIndex((u) => u.id === item.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = item;
    else updated.unshift(item);
    writeTable(DB_KEYS.USER_CHALLENGE_REWARDS, updated);
    return updated;
  },
  validateAndSendReward: (claimId: string): UserChallengeReward[] => {
    const list = UserChallengeRewardsRepo.getAll();
    const timestamp = new Date().toISOString();
    const certCode = `CERT-WISGO-${Date.now().toString().slice(-6)}`;

    const updated = list.map((claim) => {
      if (claim.id === claimId) {
        return {
          ...claim,
          status: 'HADIAH_TERKIRIM',
          certificate_code: claim.certificate_code || certCode,
          certificate_url:
            claim.certificate_url || `https://wisgo.sumbarprov.go.id/certs/${certCode}.pdf`,
          completed_at: claim.completed_at || timestamp,
        };
      }
      return claim;
    });

    writeTable(DB_KEYS.USER_CHALLENGE_REWARDS, updated);
    return updated;
  },
};

// ============================================================================
// 11. REPOSITORY: NOTIFIKASI (notifikasi)
// ============================================================================
export const NotifikasiRepo = {
  getAll: (): Notifikasi[] => readTable<Notifikasi>(DB_KEYS.NOTIFIKASI, SEED_NOTIFIKASI),
  create: (item: Notifikasi): void => {
    const list = NotifikasiRepo.getAll();
    writeTable(DB_KEYS.NOTIFIKASI, [item, ...list]);
  },
  markAsRead: (id: string): void => {
    const updated = NotifikasiRepo.getAll().map((n) => (n.id === id ? { ...n, is_read: true } : n));
    writeTable(DB_KEYS.NOTIFIKASI, updated);
  },
};

// ============================================================================
// 12. REPOSITORY: JALUR EKSTREM & DARURAT (hazard_alerts, sos_signals, emergency_contacts)
// ============================================================================
export const HazardAlertsRepo = {
  getAll: (): HazardAlert[] => readTable<HazardAlert>(DB_KEYS.HAZARD_ALERTS, SEED_HAZARD_ALERTS),
  save: (alert: HazardAlert): HazardAlert[] => {
    const list = HazardAlertsRepo.getAll();
    const idx = list.findIndex((h) => h.id === alert.id || h.corridor_code === alert.corridor_code);
    const updated = [...list];
    const normalized: HazardAlert = {
      ...alert,
      updated_at: new Date().toISOString(),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
    writeTable(DB_KEYS.HAZARD_ALERTS, updated);
    return updated;
  },
};

export const SosSignalsRepo = {
  getAll: (): SosSignal[] => readTable<SosSignal>(DB_KEYS.SOS_SIGNALS, SEED_SOS_SIGNALS),
  save: (signal: SosSignal): SosSignal[] => {
    const list = SosSignalsRepo.getAll();
    const idx = list.findIndex((s) => s.id === signal.id || s.sos_code === signal.sos_code);
    const updated = [...list];
    if (idx >= 0) updated[idx] = signal;
    else updated.unshift(signal);
    writeTable(DB_KEYS.SOS_SIGNALS, updated);
    return updated;
  },
};

export const EmergencyContactsRepo = {
  getAll: (): EmergencyContact[] =>
    readTable<EmergencyContact>(DB_KEYS.EMERGENCY_CONTACTS, SEED_EMERGENCY_CONTACTS),
  save: (contact: EmergencyContact): EmergencyContact[] => {
    const list = EmergencyContactsRepo.getAll();
    const idx = list.findIndex((c) => c.id === contact.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = contact;
    else updated.push(contact);
    writeTable(DB_KEYS.EMERGENCY_CONTACTS, updated);
    return updated;
  },
  delete: (id: string): EmergencyContact[] => {
    const filtered = EmergencyContactsRepo.getAll().filter((c) => c.id !== id);
    writeTable(DB_KEYS.EMERGENCY_CONTACTS, filtered);
    return filtered;
  },
};

// ============================================================================
// 13. REPOSITORY: OPEN TRIPS (open_trips)
// ============================================================================
export const OpenTripsRepo = {
  getAll: (): OpenTrip[] => readTable<OpenTrip>(DB_KEYS.OPEN_TRIPS, SEED_OPEN_TRIPS),
  save: (trip: OpenTrip): OpenTrip[] => {
    const list = OpenTripsRepo.getAll();
    const idx = list.findIndex((t) => t.id === trip.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = trip;
    else updated.unshift(trip);
    writeTable(DB_KEYS.OPEN_TRIPS, updated);
    return updated;
  },
};

// ============================================================================
// 14. REPOSITORY: GAODE RANKINGS & VISIT STATS
// ============================================================================
export const GaodeRankingsRepo = {
  getAll: (): GaodeBehaviorRanking[] =>
    readTable<GaodeBehaviorRanking>(DB_KEYS.GAODE_RANKINGS, SEED_GAODE_RANKINGS),
  saveAll: (items: GaodeBehaviorRanking[]): void => {
    writeTable(DB_KEYS.GAODE_RANKINGS, items);
  },
};

export const StempVisitsRepo = {
  getAll: (): StempVisit[] => readTable<StempVisit>(DB_KEYS.STEMP_VISITS, SEED_STEMP_VISITS),
  countValidPersonalVisits: (): number =>
    StempVisitsRepo.getAll().filter((s) => s.is_gps_valid).length,
};

export const ApiTelemetryLogsRepo = {
  getAll: (): ApiTelemetryLog[] =>
    readTable<ApiTelemetryLog>(DB_KEYS.API_TELEMETRY_LOGS, SEED_API_TELEMETRY_LOGS),
};

export const MinangPhrasesRepo = {
  getAll: (): MinangPhrase[] => readTable<MinangPhrase>(DB_KEYS.MINANG_PHRASES, SEED_MINANG_PHRASES),
  save: (phrase: MinangPhrase): MinangPhrase[] => {
    const list = MinangPhrasesRepo.getAll();
    const idx = list.findIndex((p) => p.id === phrase.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = phrase;
    else updated.unshift(phrase);
    writeTable(DB_KEYS.MINANG_PHRASES, updated);
    return updated;
  },
  delete: (id: string): MinangPhrase[] => {
    const filtered = MinangPhrasesRepo.getAll().filter((p) => p.id !== id);
    writeTable(DB_KEYS.MINANG_PHRASES, filtered);
    return filtered;
  },
};

export const CulturalEventsRepo = {
  getAll: (): CulturalEvent[] => readTable<CulturalEvent>(DB_KEYS.CULTURAL_EVENTS, SEED_CULTURAL_EVENTS),
  save: (event: CulturalEvent): CulturalEvent[] => {
    const list = CulturalEventsRepo.getAll();
    const idx = list.findIndex((e) => e.id === event.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = event;
    else updated.unshift(event);
    writeTable(DB_KEYS.CULTURAL_EVENTS, updated);
    return updated;
  },
  delete: (id: string): CulturalEvent[] => {
    const filtered = CulturalEventsRepo.getAll().filter((e) => e.id !== id);
    writeTable(DB_KEYS.CULTURAL_EVENTS, filtered);
    return filtered;
  },
};

// ============================================================================
// 15. REPOSITORY: OPEN TRIP ORGANIZERS
// ============================================================================
export const OpenTripOrganizersRepo = {
  getAll: (): OpenTripOrganizer[] =>
    readTable<OpenTripOrganizer>(DB_KEYS.ORGANIZERS, SEED_ORGANIZERS),
  updateStatus: (id: string, status: 'Menunggu' | 'Terverifikasi' | 'Ditolak', notes?: string): OpenTripOrganizer[] => {
    const list = OpenTripOrganizersRepo.getAll();
    const updated = list.map((org) =>
      org.id === id
        ? {
            ...org,
            status,
            notes: notes !== undefined ? notes : org.notes,
            verified_at: status === 'Terverifikasi' ? new Date().toISOString() : org.verified_at,
          }
        : org
    );
    writeTable(DB_KEYS.ORGANIZERS, updated);
    return updated;
  },
  save: (organizer: OpenTripOrganizer): OpenTripOrganizer[] => {
    const list = OpenTripOrganizersRepo.getAll();
    const idx = list.findIndex((o) => o.id === organizer.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = organizer;
    else updated.unshift(organizer);
    writeTable(DB_KEYS.ORGANIZERS, updated);
    return updated;
  },
};

// ============================================================================
// 16. REPOSITORY: OPEN TRIP TRANSACTIONS
// ============================================================================
export const OpenTripTransactionsRepo = {
  getAll: (): OpenTripTransaction[] =>
    readTable<OpenTripTransaction>(DB_KEYS.OPEN_TRIP_TRANSACTIONS, SEED_OPEN_TRIP_TRANSACTIONS),
  save: (tx: OpenTripTransaction): OpenTripTransaction[] => {
    const list = OpenTripTransactionsRepo.getAll();
    const idx = list.findIndex((t) => t.id === tx.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = tx;
    else updated.unshift(tx);
    writeTable(DB_KEYS.OPEN_TRIP_TRANSACTIONS, updated);
    return updated;
  },
  getTotalRevenueIdr: (): number => {
    return OpenTripTransactionsRepo.getAll()
      .filter((t) => t.status === 'BERHASIL')
      .reduce((sum, t) => sum + t.amount_idr, 0);
  },
};

// ============================================================================
// 17. REPOSITORY: PACKING TEMPLATES
// ============================================================================
export const PackingTemplatesRepo = {
  getAll: (): PackingTemplate[] =>
    readTable<PackingTemplate>(DB_KEYS.PACKING_TEMPLATES, SEED_PACKING_TEMPLATES),
  getByCategory: (categoryName: string): PackingTemplate[] => {
    return PackingTemplatesRepo.getAll().filter((p) => p.category_name === categoryName);
  },
  save: (template: PackingTemplate): PackingTemplate[] => {
    const list = PackingTemplatesRepo.getAll();
    const idx = list.findIndex((p) => p.id === template.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = template;
    else updated.unshift(template);
    writeTable(DB_KEYS.PACKING_TEMPLATES, updated);
    return updated;
  },
  delete: (id: string): PackingTemplate[] => {
    const filtered = PackingTemplatesRepo.getAll().filter((p) => p.id !== id);
    writeTable(DB_KEYS.PACKING_TEMPLATES, filtered);
    return filtered;
  },
};

// ============================================================================
// 18. REPOSITORY: WEATHER MONITORING
// ============================================================================
export const WeatherMonitoringRepo = {
  getAll: (): WeatherMonitoringItem[] =>
    readTable<WeatherMonitoringItem>(DB_KEYS.WEATHER_MONITORING, SEED_WEATHER_MONITORING),
  updateCondition: (
    id: string,
    condition: string,
    temp_c: number,
    is_extreme: boolean,
    warning_text?: string
  ): WeatherMonitoringItem[] => {
    const list = WeatherMonitoringRepo.getAll();
    const updated = list.map((w) =>
      w.id === id
        ? {
            ...w,
            condition,
            current_temp_c: temp_c,
            is_extreme_weather: is_extreme,
            extreme_warning_text: warning_text || w.extreme_warning_text,
            updated_at: new Date().toISOString(),
          }
        : w
    );
    writeTable(DB_KEYS.WEATHER_MONITORING, updated);
    return updated;
  },
  broadcastHazardAlert: (item: WeatherMonitoringItem): HazardAlert[] => {
    const newAlert: HazardAlert = {
      id: `hz-${Date.now()}`,
      corridor_code: `CORR-WEATHER-${Date.now().toString().slice(-4)}`,
      location: item.destination_name,
      road_segment: `Kawasan ${item.destination_name}`,
      city_regency: item.city_regency,
      latitude: -0.94924,
      longitude: 100.48512,
      radius_meter: 4000,
      severity: item.is_extreme_weather ? 'Waspada' : 'Aman',
      hazard_type: `Peringatan Cuaca: ${item.condition}`,
      weather_status: `${item.condition} (${item.current_temp_c}°C)`,
      slope_gradient_deg: 18,
      message: item.extreme_warning_text || `Kondisi cuaca terkini: ${item.condition} dengan suhu ${item.current_temp_c}°C. Tetap waspada di jalur wisata.`,
      detour_route: 'Patuhi instruksi petugas posko siaga darurat setempat.',
      detour_route_geojson: null,
      nearest_rescue_post: `Posko Siaga BPBD & SAR ${item.city_regency}`,
      emergency_contact: '0811-6600-2026',
      triggered_by_admin: 'usr-admin-01',
      updated_at: new Date().toISOString(),
    };
    return HazardAlertsRepo.save(newAlert);
  },
};

// ============================================================================
// 19. REPOSITORY: 5 LEVEL & LENCANA PETUALANG
// ============================================================================
export const AdventurerLevelsRepo = {
  getAll: (): AdventurerLevelConfig[] =>
    readTable<AdventurerLevelConfig>(DB_KEYS.ADVENTURER_LEVELS, SEED_ADVENTURER_LEVELS),
  updateLevel: (updatedConfig: AdventurerLevelConfig): AdventurerLevelConfig[] => {
    const list = AdventurerLevelsRepo.getAll();
    const idx = list.findIndex((l) => l.level === updatedConfig.level);
    const updated = [...list];
    if (idx >= 0) updated[idx] = updatedConfig;
    else updated.push(updatedConfig);
    writeTable(DB_KEYS.ADVENTURER_LEVELS, updated);
    return updated;
  },
};

// ============================================================================
// 20. REPOSITORY: USER PROFILES & STRAVA-STYLE EXPERIENCES
// ============================================================================
export const UserProfilesRepo = {
  getAll: (): UserProfileExperience[] =>
    readTable<UserProfileExperience>(DB_KEYS.USER_PROFILES, SEED_USER_PROFILES),
  getById: (id: string): UserProfileExperience | undefined => {
    return UserProfilesRepo.getAll().find((u) => u.id === id || u.user_id === id);
  },
  save: (profile: UserProfileExperience): UserProfileExperience[] => {
    const list = UserProfilesRepo.getAll();
    const idx = list.findIndex((u) => u.id === profile.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = profile;
    else updated.unshift(profile);
    writeTable(DB_KEYS.USER_PROFILES, updated);
    return updated;
  },
};

// ============================================================================
// 21. REPOSITORY: POSTING TEMPLATES & QR
// ============================================================================
export const PostingTemplatesRepo = {
  getAll: (): PostingShareTemplate[] =>
    readTable<PostingShareTemplate>(DB_KEYS.POSTING_TEMPLATES, SEED_POSTING_TEMPLATES),
  save: (template: PostingShareTemplate): PostingShareTemplate[] => {
    const list = PostingTemplatesRepo.getAll();
    const idx = list.findIndex((t) => t.id === template.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = template;
    else updated.unshift(template);
    writeTable(DB_KEYS.POSTING_TEMPLATES, updated);
    return updated;
  },
};
