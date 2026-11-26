// ============================================================================
// DATA REPOSITORY LAYER & LOCALSTORAGE MIGRATION (WISGO V3.0.0)
// Satu Sumber Kebenaran (Single Source of Truth) untuk Seluruh Web Admin
// ============================================================================

import {
  AdventurerLevelConfig,
  ApiTelemetryLog,
  AturanDestinasi,
  Category,
  Challenge,
  CulturalEvent,
  DenahPoint,
  Destination,
  DestinationContributor,
  DestinationReview,
  DestinationWeatherSnapshot,
  DigitalPassportSpot,
  EmergencyContact,
  GaodeBehaviorRanking,
  GaodeWeightConfig,
  HazardAlert,
  IndikatorMedan,
  MinangPhrase,
  NewTour,
  Notifikasi,
  OfficialTariff,
  OpenTrip,
  OpenTripOrganizer,
  OpenTripTransaction,
  PackingTemplate,
  PanoramaScene,
  Partner,
  PostingShareTemplate,
  PungliReport,
  RegencyHeatmapData,
  SavedPlace,
  SosSignal,
  StempVisit,
  SystemBenchmarkMetrics,
  User,
  UserChallengeReward,
  UserProfileExperience,
  WeatherMonitoringItem,
} from '../types/contract';

import {
  SEED_ADVENTURER_LEVELS,
  SEED_API_TELEMETRY_LOGS,
  SEED_ATURAN_DESTINASI,
  SEED_CATEGORIES,
  SEED_CHALLENGES,
  SEED_CULTURAL_EVENTS,
  SEED_DENAH_POINTS,
  SEED_DESTINATION_REVIEWS,
  SEED_DESTINATIONS,
  SEED_EMERGENCY_CONTACTS,
  SEED_GAODE_RANKINGS,
  SEED_HAZARD_ALERTS,
  SEED_INDIKATOR_MEDAN,
  SEED_MINANG_PHRASES,
  SEED_NEW_TOURS,
  SEED_NOTIFIKASI,
  SEED_OFFICIAL_TARIFFS,
  SEED_OPEN_TRIPS,
  SEED_OPEN_TRIP_TRANSACTIONS,
  SEED_ORGANIZERS,
  SEED_PACKING_TEMPLATES,
  SEED_PANORAMA_SCENES,
  SEED_PARTNERS,
  SEED_PASSPORT_SPOTS,
  SEED_POSTING_TEMPLATES,
  SEED_PUNGLI_REPORTS,
  SEED_REGENCY_HEATMAP,
  SEED_SAVED_PLACES,
  SEED_SOS_SIGNALS,
  SEED_STEMP_VISITS,
  SEED_USERS,
  SEED_USER_CHALLENGE_REWARDS,
  SEED_USER_PROFILES,
  SEED_WEATHER_MONITORING,
  categoryNameToId,
} from '../data/mockDatabaseV2';

import {
  INITIAL_SYSTEM_BENCHMARK,
  calculateAdventurerLevel,
  normalizeDestinationCategory,
  normalizeHazardSeverity,
  normalizePartnerCategory,
  normalizePungliStatus,
  normalizeTariffCategory,
  tariffCategoryToId,
  toDestinationSlug,
} from '../data/mockDestinations';

import { safeSetLocalStorage } from '../utils/imageOptimizer';

const DB_VERSION_KEY = 'wisgo_v2_db_version';
export const CURRENT_DB_VERSION = '3.2.0';

export const DB_KEYS = {
  CATEGORIES: 'wisgo_v3_db_categories',
  DESTINATIONS: 'wisgo_v3_db_destinations',
  INDIKATOR_MEDAN: 'wisgo_v3_db_indikator_medan',
  ATURAN_DESTINASI: 'wisgo_v3_db_aturan_destinasi',
  OFFICIAL_TARIFFS: 'wisgo_v3_db_official_tariffs',
  PANORAMA_SCENES: 'wisgo_v3_db_panorama_scenes',
  DENAH_POINTS: 'wisgo_v3_db_denah_points',
  PARTNERS: 'wisgo_v3_db_partners',
  GAODE_RANKINGS: 'wisgo_v3_db_gaode_rankings',
  GAODE_CONFIG: 'wisgo_v3_db_gaode_config',
  PUNGLI_REPORTS: 'wisgo_v3_db_pungli_reports',
  DESTINATION_REVIEWS: 'wisgo_v3_db_destination_reviews',
  API_TELEMETRY_LOGS: 'wisgo_v3_db_api_telemetry_logs',
  HAZARD_ALERTS: 'wisgo_v3_db_hazard_alerts',
  SOS_SIGNALS: 'wisgo_v3_db_sos_signals',
  MINANG_PHRASES: 'wisgo_v3_db_minang_phrases',
  EMERGENCY_CONTACTS: 'wisgo_v3_db_emergency_contacts',
  CULTURAL_EVENTS: 'wisgo_v3_db_cultural_events',
  SAVED_PLACES: 'wisgo_v3_db_saved_places',
  STEMP_VISITS: 'wisgo_v3_db_stemp_visits',
  NEW_TOURS: 'wisgo_v3_db_new_tours',
  CHALLENGES: 'wisgo_v3_db_challenges',
  USER_CHALLENGE_REWARDS: 'wisgo_v3_db_user_challenge_rewards',
  USERS: 'wisgo_v3_db_users',
  OPEN_TRIPS: 'wisgo_v3_db_open_trips',
  NOTIFIKASI: 'wisgo_v3_db_notifikasi',
  ORGANIZERS: 'wisgo_v3_db_organizers',
  OPEN_TRIP_TRANSACTIONS: 'wisgo_v3_db_open_trip_transactions',
  PACKING_TEMPLATES: 'wisgo_v3_db_packing_templates',
  WEATHER_MONITORING: 'wisgo_v3_db_weather_monitoring',
  ADVENTURER_LEVELS: 'wisgo_v3_db_adventurer_levels',
  USER_PROFILES: 'wisgo_v3_db_user_profiles',
  POSTING_TEMPLATES: 'wisgo_v3_db_posting_templates',
  REVIEW_SETTINGS: 'wisgo_v3_db_review_settings',
  REGENCY_HEATMAP: 'wisgo_v3_db_regency_heatmap',
  SYSTEM_BENCHMARK: 'wisgo_v3_db_system_benchmark',
} as const;

const LEGACY_KEYS_TO_PURGE = [
  'wisgo_dispar_destinations_v2',
  'rancakin_dispar_destinations_v2',
  'wisgo_dispar_partners_v2',
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
  'wisgo_gaode_config_v1',
  'wisgo_open_trips_v1',
  'wisgo_emergency_contacts',
  'wisgo_system_benchmark_v1',
  'wisgo_regency_heatmap_v2',
  'wisgo_passport_metrics_v2',
  'wisgo_system_notifications',
  'wisgo_v2_db_categories',
  'wisgo_v2_db_destinations',
  'wisgo_v2_db_indikator_medan',
  'wisgo_v2_db_aturan_destinasi',
  'wisgo_v2_db_official_tariffs',
  'wisgo_v2_db_panorama_scenes',
  'wisgo_v2_db_panorama_hotspots',
  'wisgo_v2_db_offline_bundles',
  'wisgo_v2_db_visit_points',
  'wisgo_v2_db_gaode_rankings',
  'wisgo_v2_db_pungli_reports',
  'wisgo_v2_db_destination_reviews',
  'wisgo_v2_db_api_telemetry_logs',
  'wisgo_v2_db_hazard_alerts',
  'wisgo_v2_db_sos_signals',
  'wisgo_v2_db_minang_phrases',
  'wisgo_v2_db_emergency_contacts',
  'wisgo_v2_db_cultural_events',
  'wisgo_v2_db_saved_places',
  'wisgo_v2_db_stemp_visits',
  'wisgo_v2_db_new_tours',
  'wisgo_v2_db_challenges',
  'wisgo_v2_db_user_challenge_rewards',
  'wisgo_v2_db_users',
  'wisgo_v2_db_open_trips',
  'wisgo_v2_db_notifikasi',
  'wisgo_v2_db_organizers',
  'wisgo_v2_db_open_trip_transactions',
  'wisgo_v2_db_packing_templates',
  'wisgo_v2_db_weather_monitoring',
  'wisgo_v2_db_adventurer_levels',
  'wisgo_v2_db_user_profiles',
  'wisgo_v2_db_posting_templates',
  'wisgo_v2_db_review_settings',
];

function seedFreshV3Tables(): void {
  safeSetLocalStorage(DB_KEYS.CATEGORIES, JSON.stringify(SEED_CATEGORIES));
  safeSetLocalStorage(DB_KEYS.DESTINATIONS, JSON.stringify(SEED_DESTINATIONS));
  safeSetLocalStorage(DB_KEYS.INDIKATOR_MEDAN, JSON.stringify(SEED_INDIKATOR_MEDAN));
  safeSetLocalStorage(DB_KEYS.ATURAN_DESTINASI, JSON.stringify(SEED_ATURAN_DESTINASI));
  safeSetLocalStorage(DB_KEYS.OFFICIAL_TARIFFS, JSON.stringify(SEED_OFFICIAL_TARIFFS));
  safeSetLocalStorage(DB_KEYS.PANORAMA_SCENES, JSON.stringify(SEED_PANORAMA_SCENES));
  safeSetLocalStorage(DB_KEYS.DENAH_POINTS, JSON.stringify(SEED_DENAH_POINTS));
  safeSetLocalStorage(DB_KEYS.PARTNERS, JSON.stringify(SEED_PARTNERS));
  safeSetLocalStorage(DB_KEYS.GAODE_RANKINGS, JSON.stringify(SEED_GAODE_RANKINGS));
  safeSetLocalStorage(DB_KEYS.PUNGLI_REPORTS, JSON.stringify(SEED_PUNGLI_REPORTS));
  safeSetLocalStorage(DB_KEYS.DESTINATION_REVIEWS, JSON.stringify(SEED_DESTINATION_REVIEWS));
  safeSetLocalStorage(DB_KEYS.API_TELEMETRY_LOGS, JSON.stringify(SEED_API_TELEMETRY_LOGS));
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
  safeSetLocalStorage(DB_KEYS.REVIEW_SETTINGS, JSON.stringify({ min_character_limit: 30 }));
  safeSetLocalStorage(DB_KEYS.REGENCY_HEATMAP, JSON.stringify(SEED_REGENCY_HEATMAP));
  safeSetLocalStorage(DB_KEYS.SYSTEM_BENCHMARK, JSON.stringify(INITIAL_SYSTEM_BENCHMARK));
}

export function initializeAndMigrateDatabase(forceReset = false): void {
  try {
    const installedVersion = localStorage.getItem(DB_VERSION_KEY);
    if (forceReset || installedVersion !== CURRENT_DB_VERSION) {
      for (const k of LEGACY_KEYS_TO_PURGE) {
        localStorage.removeItem(k);
      }
      seedFreshV3Tables();
      localStorage.setItem(DB_VERSION_KEY, CURRENT_DB_VERSION);
    }
  } catch (err) {
    console.error('Failed to initialize or migrate WISGO V3 database:', err);
  }
}

initializeAndMigrateDatabase();

// ============================================================================
// GENERIC TABLE HELPERS
// ============================================================================
function readTable<T>(key: string, fallback: T[]): T[] {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : fallback;
  } catch {
    return fallback;
  }
}

function writeTable<T>(key: string, data: T[]): void {
  safeSetLocalStorage(key, JSON.stringify(data));
}

function stripLegacyMedanFields(raw: IndikatorMedan & Record<string, unknown>, destId: string): IndikatorMedan {
  return {
    id: raw.id || `med-${destId}`,
    destination_id: destId,
    vehicle_access: raw.vehicle_access || 'Mobil OK',
    trekking_level: raw.trekking_level || 'Mudah (Datar)',
    facilities: raw.facilities || 'Toilet, Musala & Parkir Lengkap',
    guide_need: raw.guide_need || 'Mandiri',
    terrain_note: raw.terrain_note || raw.readiness_notes || '',
    readiness_notes: raw.readiness_notes || raw.terrain_note || '',
  };
}

function stripLegacyDestinationFields(raw: Destination & Record<string, unknown>): Destination {
  const normalizedCategory = normalizeDestinationCategory(raw.category);
  const clean: Destination = {
    id: raw.id,
    slug: raw.slug || toDestinationSlug(raw.name || raw.id),
    name: raw.name,
    category_id: raw.category_id && raw.category_id.startsWith('cat-') && !raw.category_id.startsWith('cat-dest-')
      ? raw.category_id
      : categoryNameToId(normalizedCategory),
    category: normalizedCategory,
    city_regency: raw.city_regency || 'Kota Padang',
    description: raw.description || '',
    latitude: Number(raw.latitude ?? -0.9471),
    longitude: Number(raw.longitude ?? 100.3543),
    geog: raw.geog || `SRID=4326;POINT(${Number(raw.longitude ?? 100.3543).toFixed(6)} ${Number(raw.latitude ?? -0.9471).toFixed(6)})`,
    elevation_m: raw.elevation_m,
    cover_image: raw.cover_image || '/assets/synced/panorama_sumbar_default.jpg',
    gallery_images: Array.isArray(raw.gallery_images) ? raw.gallery_images : undefined,
    contributors: Array.isArray(raw.contributors) ? raw.contributors : undefined,
    crowd_level: raw.crowd_level || 'Sedang',
    distance_km: Number(raw.distance_km ?? 20),
    travel_time_min: Number(raw.travel_time_min ?? 40),
    estimated_cost: Number(raw.estimated_cost ?? 15000),
    ticket_price_summary: raw.ticket_price_summary,
    is_hidden_gem: Boolean(raw.is_hidden_gem || normalizedCategory === 'Hidden Gem'),
    qr_placard_code: raw.qr_placard_code,
    opening_hours: raw.opening_hours || '08.00 - 17.00 WIB',
    weather_status: raw.weather_status,
    created_at: raw.created_at,
    updated_at: raw.updated_at,
    checkpoints: raw.checkpoints,
  };
  return clean;
}

// ============================================================================
// 1. CATEGORIES REPO
// ============================================================================
export const CategoriesRepo = {
  getAll: (): Category[] => readTable<Category>(DB_KEYS.CATEGORIES, SEED_CATEGORIES),
  getByModule: (moduleType: string): Category[] =>
    CategoriesRepo.getAll().filter((c) => c.module_type === moduleType),
  getById: (id: string): Category | undefined =>
    CategoriesRepo.getAll().find((c) => c.id === id),
};

// ============================================================================
// 2. INDIKATOR MEDAN REPO (4 Indikator Kanonik)
// ============================================================================
export const IndikatorMedanRepo = {
  getAll: (): IndikatorMedan[] =>
    readTable<IndikatorMedan>(DB_KEYS.INDIKATOR_MEDAN, SEED_INDIKATOR_MEDAN).map((m) =>
      stripLegacyMedanFields(m as IndikatorMedan & Record<string, unknown>, m.destination_id)
    ),
  getByDestinationId: (destId: string): IndikatorMedan | undefined =>
    IndikatorMedanRepo.getAll().find((m) => m.destination_id === destId),
  save: (item: IndikatorMedan): void => {
    const clean = stripLegacyMedanFields(
      item as IndikatorMedan & Record<string, unknown>,
      item.destination_id
    );
    const list = IndikatorMedanRepo.getAll();
    const idx = list.findIndex((m) => m.destination_id === clean.destination_id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = clean;
    else updated.push(clean);
    writeTable(DB_KEYS.INDIKATOR_MEDAN, updated);
  },
};

// ============================================================================
// 3. ATURAN DESTINASI REPO (Sinkron Dua Arah dengan tips)
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
  replaceForDestination: (destId: string, items: AturanDestinasi[]): void => {
    const others = AturanDestinasiRepo.getAll().filter((a) => a.destination_id !== destId);
    const normalized = items.map((a, index) => ({
      ...a,
      id: a.id || `art-${destId}-${Date.now()}-${index}`,
      destination_id: destId,
    }));
    writeTable(DB_KEYS.ATURAN_DESTINASI, [...others, ...normalized]);
  },
  delete: (id: string): void => {
    writeTable(
      DB_KEYS.ATURAN_DESTINASI,
      AturanDestinasiRepo.getAll().filter((a) => a.id !== id)
    );
  },
};

// ============================================================================
// 4. OFFICIAL TARIFFS REPO
// ============================================================================
export const OfficialTariffsRepo = {
  getAll: (): OfficialTariff[] =>
    readTable<OfficialTariff>(DB_KEYS.OFFICIAL_TARIFFS, SEED_OFFICIAL_TARIFFS).map((t) => {
      const cat = normalizeTariffCategory(t.category);
      return {
        ...t,
        category: cat,
        category_id: t.category_id || tariffCategoryToId(cat),
      };
    }),
  getByDestinationId: (destId: string): OfficialTariff[] =>
    OfficialTariffsRepo.getAll().filter((t) => t.destination_id === destId),
  save: (item: OfficialTariff): void => {
    const cat = normalizeTariffCategory(item.category);
    const normalized: OfficialTariff = {
      ...item,
      category: cat,
      category_id: item.category_id || tariffCategoryToId(cat),
    };
    const list = OfficialTariffsRepo.getAll();
    const idx = list.findIndex((t) => t.id === normalized.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = normalized;
    else updated.push(normalized);
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
// 5. STUDIO PANORAMA 360° REPO (Pure Panorama — Nol Hotspot)
// ============================================================================
export const Studio360Repo = {
  getScenes: (destId?: string): PanoramaScene[] => {
    const scenes = readTable<PanoramaScene>(DB_KEYS.PANORAMA_SCENES, SEED_PANORAMA_SCENES);
    return destId ? scenes.filter((s) => s.destination_id === destId) : scenes;
  },
  saveScene: (scene: PanoramaScene): PanoramaScene[] => {
    const list = readTable<PanoramaScene>(DB_KEYS.PANORAMA_SCENES, SEED_PANORAMA_SCENES);
    const idx = list.findIndex((s) => s.id === scene.id);
    const updated = [...list];
    const normalized: PanoramaScene = {
      id: scene.id,
      destination_id: scene.destination_id,
      title: scene.title,
      scene_type: scene.scene_type === 'aerial' ? 'aerial' : 'ground',
      view_mode: scene.view_mode || 'photo_panorama',
      image_resolution: scene.image_resolution || '4K Equirectangular Panorama',
      panorama_url: scene.panorama_url || '/assets/synced/panorama_sumbar_default.jpg',
      upload_format: scene.upload_format || 'equirectangular',
      initial_pitch: Number(scene.initial_pitch ?? 0),
      initial_yaw: Number(scene.initial_yaw ?? 0),
      is_default_scene: Boolean(scene.is_default_scene),
      created_at: scene.created_at || new Date().toISOString(),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.push(normalized);
    writeTable(DB_KEYS.PANORAMA_SCENES, updated);
    return updated;
  },
  deleteScene: (sceneId: string): PanoramaScene[] => {
    const filtered = readTable<PanoramaScene>(DB_KEYS.PANORAMA_SCENES, SEED_PANORAMA_SCENES).filter(
      (s) => s.id !== sceneId
    );
    writeTable(DB_KEYS.PANORAMA_SCENES, filtered);
    return filtered;
  },
};

// ============================================================================
// 6. DENAH KAWASAN 2D REPO (PARKIR, UMKM, TOILET, MUSHOLLA, LOKET)
// ============================================================================
export const DenahPointsRepo = {
  getAll: (): DenahPoint[] => readTable<DenahPoint>(DB_KEYS.DENAH_POINTS, SEED_DENAH_POINTS),
  getByDestinationId: (destId: string): DenahPoint[] =>
    DenahPointsRepo.getAll().filter((p) => p.destination_id === destId),
  save: (point: DenahPoint): DenahPoint[] => {
    const list = DenahPointsRepo.getAll();
    const idx = list.findIndex((p) => p.id === point.id);
    const updated = [...list];
    const normalized: DenahPoint = {
      ...point,
      x: Math.max(2, Math.min(98, Number(point.x ?? 50))),
      y: Math.max(2, Math.min(98, Number(point.y ?? 50))),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.push(normalized);
    writeTable(DB_KEYS.DENAH_POINTS, updated);
    return updated;
  },
  delete: (id: string): DenahPoint[] => {
    const filtered = DenahPointsRepo.getAll().filter((p) => p.id !== id);
    writeTable(DB_KEYS.DENAH_POINTS, filtered);
    return filtered;
  },
};

// ============================================================================
// 7. MITRA UMKM REPO (5 Kategori Kanonik Mobile — Direct P2P 0% Komisi)
// ============================================================================
export const PartnersRepo = {
  getAll: (): Partner[] =>
    readTable<Partner>(DB_KEYS.PARTNERS, SEED_PARTNERS).map((p) => ({
      ...p,
      category: normalizePartnerCategory(p.category),
      wa_click_count: Number(p.wa_click_count ?? 0),
      direct_payment_methods: Array.isArray(p.direct_payment_methods)
        ? p.direct_payment_methods
        : ['QRIS Bank Nagari', 'Tunai di Tempat'],
    })),
  save: (partner: Partner): Partner[] => {
    const list = PartnersRepo.getAll();
    const idx = list.findIndex((p) => p.id === partner.id);
    const updated = [...list];
    const normalized: Partner = {
      ...partner,
      category: normalizePartnerCategory(partner.category),
      whatsapp: partner.whatsapp.replace(/\D/g, ''),
      wa_click_count: Number(partner.wa_click_count ?? 0),
      fee_myr_estimate:
        partner.fee_myr_estimate ?? Number((partner.standard_fee / 3300).toFixed(1)),
      created_at: partner.created_at || new Date().toISOString(),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
    writeTable(DB_KEYS.PARTNERS, updated);
    return updated;
  },
  delete: (id: string): Partner[] => {
    const filtered = PartnersRepo.getAll().filter((p) => p.id !== id);
    writeTable(DB_KEYS.PARTNERS, filtered);
    return filtered;
  },
  incrementWaClicks: (id: string): Partner | null => {
    const list = PartnersRepo.getAll();
    let matched: Partner | null = null;
    const updated = list.map((p) => {
      if (p.id !== id) return p;
      matched = { ...p, wa_click_count: (p.wa_click_count || 0) + 1 };
      return matched;
    });
    if (matched) {
      writeTable(DB_KEYS.PARTNERS, updated);
    }
    return matched;
  },
};

// ============================================================================
// 8. WEATHER MONITORING REPO (Open-Meteo Live + Sync Hazard Alerts)
// ============================================================================
function mapWmoCodeToIndonesian(code: number): {
  condition: string;
  weather_status: 'Aman' | 'Waspada Hujan' | 'Siaga Cuaca Ekstrem';
  is_extreme: boolean;
} {
  if (code === 0) return { condition: 'Cerah', weather_status: 'Aman', is_extreme: false };
  if (code <= 3) return { condition: 'Cerah Berawan', weather_status: 'Aman', is_extreme: false };
  if (code === 45 || code === 48) return { condition: 'Berkabut Tebal', weather_status: 'Waspada Hujan', is_extreme: false };
  if (code >= 51 && code <= 63) return { condition: 'Hujan Ringan – Sedang', weather_status: 'Waspada Hujan', is_extreme: false };
  if (code >= 65 && code <= 82) return { condition: 'Hujan Lebat', weather_status: 'Siaga Cuaca Ekstrem', is_extreme: true };
  if (code >= 95) return { condition: 'Badai Petir & Angin Kencang', weather_status: 'Siaga Cuaca Ekstrem', is_extreme: true };
  return { condition: 'Berawan', weather_status: 'Aman', is_extreme: false };
}

export const WeatherMonitoringRepo = {
  getAll: (): WeatherMonitoringItem[] =>
    readTable<WeatherMonitoringItem>(DB_KEYS.WEATHER_MONITORING, SEED_WEATHER_MONITORING),
  getSnapshotForRegency: (cityRegency: string): DestinationWeatherSnapshot => {
    const list = WeatherMonitoringRepo.getAll();
    const matched =
      list.find((w) => w.city_regency.toLowerCase() === cityRegency.toLowerCase()) ||
      list[0] ||
      SEED_WEATHER_MONITORING[0];
    return {
      city_regency: matched.city_regency,
      temperature_c: matched.current_temp_c,
      condition: matched.condition,
      weather_status: matched.weather_status,
      humidity_percent: matched.humidity_pct,
      wind_speed_kmh: matched.wind_speed_kmh,
      rain_probability: matched.rain_probability,
      forecast: matched.hourly_forecast?.[0]?.condition || matched.condition,
      alert_note: matched.extreme_warning_text,
      source: matched.source,
      last_updated: matched.updated_at,
    };
  },
  updateCondition: (
    id: string,
    condition: string,
    temp_c: number,
    is_extreme: boolean,
    warning_text?: string
  ): WeatherMonitoringItem[] => {
    const list = WeatherMonitoringRepo.getAll();
    const status: WeatherMonitoringItem['weather_status'] = is_extreme
      ? 'Siaga Cuaca Ekstrem'
      : condition.toLowerCase().includes('hujan')
      ? 'Waspada Hujan'
      : 'Aman';
    const updated = list.map((w) =>
      w.id === id
        ? {
            ...w,
            condition,
            current_temp_c: temp_c,
            weather_status: status,
            is_extreme_weather: is_extreme,
            extreme_warning_text: warning_text !== undefined ? warning_text : w.extreme_warning_text,
            updated_at: new Date().toISOString(),
          }
        : w
    );
    writeTable(DB_KEYS.WEATHER_MONITORING, updated);
    return updated;
  },
  refreshFromOpenMeteo: async (): Promise<{
    items: WeatherMonitoringItem[];
    liveSuccessCount: number;
  }> => {
    const list = WeatherMonitoringRepo.getAll();
    let liveSuccessCount = 0;

    const refreshed = await Promise.all(
      list.map(async (item) => {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 3000);
        try {
          const url = `https://api.open-meteo.com/v1/forecast?latitude=${item.latitude}&longitude=${item.longitude}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&hourly=temperature_2m,precipitation_probability,weather_code&forecast_days=1&timezone=Asia%2FJakarta`;
          const res = await fetch(url, { signal: controller.signal });
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          const data = await res.json();
          const current = data?.current;
          if (!current) throw new Error('Missing current payload');

          const mapped = mapWmoCodeToIndonesian(Number(current.weather_code ?? 1));
          const hourlyTimes: string[] = data?.hourly?.time || [];
          const hourlyTemps: number[] = data?.hourly?.temperature_2m || [];
          const hourlyRain: number[] = data?.hourly?.precipitation_probability || [];
          const hourlyCodes: number[] = data?.hourly?.weather_code || [];

          const nowHour = new Date().getHours();
          const startIdx = Math.max(0, Math.min(Math.max(0, hourlyTimes.length - 6), nowHour));
          const hourly_forecast = hourlyTimes.slice(startIdx, startIdx + 6).map((t, i) => {
            const idx = startIdx + i;
            const slotCode = mapWmoCodeToIndonesian(Number(hourlyCodes[idx] ?? current.weather_code ?? 1));
            return {
              hour: String(t).slice(11, 16) || `${String((nowHour + i) % 24).padStart(2, '0')}:00`,
              temp_c: Math.round(Number(hourlyTemps[idx] ?? current.temperature_2m)),
              condition: slotCode.condition,
              rain_prob: Math.round(Number(hourlyRain[idx] ?? 20)),
            };
          });

          liveSuccessCount += 1;
          return {
            ...item,
            current_temp_c: Math.round(Number(current.temperature_2m ?? item.current_temp_c)),
            humidity_pct: Math.round(Number(current.relative_humidity_2m ?? item.humidity_pct)),
            wind_speed_kmh: Math.round(Number(current.wind_speed_10m ?? item.wind_speed_kmh)),
            rain_probability: hourly_forecast[0]?.rain_prob ?? item.rain_probability,
            condition: mapped.condition,
            weather_status: mapped.weather_status,
            is_extreme_weather: mapped.is_extreme,
            extreme_warning_text: mapped.is_extreme
              ? `Peringatan Open-Meteo: ${mapped.condition} di kawasan ${item.destination_name}.`
              : item.extreme_warning_text,
            hourly_forecast: hourly_forecast.length > 0 ? hourly_forecast : item.hourly_forecast,
            source: 'Open-Meteo Live' as const,
            updated_at: new Date().toISOString(),
          };
        } catch {
          return {
            ...item,
            source: 'Regional Cache' as const,
          };
        } finally {
          clearTimeout(timeout);
        }
      })
    );

    writeTable(DB_KEYS.WEATHER_MONITORING, refreshed);
    return { items: refreshed, liveSuccessCount };
  },
  broadcastHazardAlert: (item: WeatherMonitoringItem): HazardAlert[] => {
    const severity: HazardAlert['severity'] = item.is_extreme_weather
      ? 'Siaga'
      : item.weather_status === 'Waspada Hujan'
      ? 'Waspada'
      : 'Normal';

    const newAlert: HazardAlert = {
      id: `hz-wtr-${Date.now()}`,
      corridor_code: `CUACA-${item.city_regency.replace(/[^A-Z0-9]/gi, '').slice(0, 8).toUpperCase()}-${Date.now().toString().slice(-3)}`,
      location: item.destination_name,
      road_segment: `Kawasan ${item.destination_name}`,
      city_regency: item.city_regency,
      latitude: item.latitude,
      longitude: item.longitude,
      geog: `SRID=4326;POINT(${item.longitude.toFixed(6)} ${item.latitude.toFixed(6)})`,
      radius_meter: 4000,
      severity,
      hazard_type: `Peringatan Cuaca: ${item.condition}`,
      weather_status: `${item.condition} (${item.current_temp_c}°C)`,
      slope_gradient_deg: 15,
      message:
        item.extreme_warning_text ||
        `Pantauan Open-Meteo: ${item.condition} (${item.current_temp_c}°C, curah hujan ${item.rain_probability}%). Harap berhati-hati di jalur wisata.`,
      detour_route: 'Patuhi rambu petugas posko BPBD & Dishub setempat.',
      detour_route_geojson: null,
      nearest_rescue_post: `Posko Siaga BPBD ${item.city_regency}`,
      emergency_contact: '(0751) 890721',
      triggered_by_admin: 'usr-admin-01',
      updated_at: new Date().toISOString(),
    };
    return HazardAlertsRepo.save(newAlert);
  },
};

// ============================================================================
// 9. DESTINATIONS REPO (Join 4 Indikator Medan, Aturan/Tips, Tarif, 360°, Denah 2D, Cuaca)
// ============================================================================
export const DestinationsRepo = {
  getAll: (): Destination[] => {
    const dests = readTable<Destination>(DB_KEYS.DESTINATIONS, SEED_DESTINATIONS);
    const medans = IndikatorMedanRepo.getAll();
    const aturans = AturanDestinasiRepo.getAll();
    const tariffs = OfficialTariffsRepo.getAll();
    const scenes = Studio360Repo.getScenes();
    const denahPoints = DenahPointsRepo.getAll();

    return dests.map((rawDest) => {
      const d = stripLegacyDestinationFields(rawDest as Destination & Record<string, unknown>);
      const rules = aturans.filter((a) => a.destination_id === d.id);
      const destTariffs = tariffs.filter((t) => t.destination_id === d.id);
      const weather = WeatherMonitoringRepo.getSnapshotForRegency(d.city_regency);
      const medan =
        medans.find((m) => m.destination_id === d.id) ||
        stripLegacyMedanFields(
          {
            id: `med-${d.id}`,
            destination_id: d.id,
            vehicle_access: 'Mobil OK',
            trekking_level: 'Mudah (Datar)',
            facilities: 'Toilet, Musala & Parkir Lengkap',
            guide_need: 'Mandiri',
            terrain_note: 'Akses standar terpantau Dinas Pariwisata.',
          },
          d.id
        );

      return {
        ...d,
        weather,
        weather_status: d.weather_status || weather.weather_status,
        medan_indicator: medan,
        aturan_destinasi: rules,
        tips: rules,
        tariffs: destTariffs,
        official_tariffs: destTariffs,
        scenes_360: scenes.filter((s) => s.destination_id === d.id),
        denah_points: denahPoints.filter((p) => p.destination_id === d.id),
      };
    });
  },
  getById: (id: string): Destination | undefined =>
    DestinationsRepo.getAll().find((d) => d.id === id),
  getBySlug: (slug: string): Destination | undefined =>
    DestinationsRepo.getAll().find((d) => d.slug === slug || d.id === slug),
  save: (item: Destination): Destination[] => {
    const currentRaw = readTable<Destination>(DB_KEYS.DESTINATIONS, SEED_DESTINATIONS);
    const idx = currentRaw.findIndex((d) => d.id === item.id);
    const updated = [...currentRaw];
    const timestamp = new Date().toISOString();

    const cleanCore = stripLegacyDestinationFields({
      ...(item as Destination & Record<string, unknown>),
      updated_at: timestamp,
      created_at: item.created_at || timestamp,
    });

    if (idx >= 0) updated[idx] = cleanCore;
    else updated.unshift(cleanCore);
    writeTable(DB_KEYS.DESTINATIONS, updated);

    // 1. Sinkronisasi 4 Indikator Medan kanonik
    if (item.medan_indicator) {
      IndikatorMedanRepo.save({
        ...item.medan_indicator,
        id: item.medan_indicator.id || `med-${item.id}`,
        destination_id: item.id,
      });
    }

    // 2. Sinkronisasi Dua Arah: tips <-> aturan_destinasi
    const existingRules = AturanDestinasiRepo.getByDestinationId(item.id);
    const hasTips = Array.isArray(item.tips);
    const hasAturan = Array.isArray(item.aturan_destinasi);
    if (hasTips || hasAturan) {
      const existingSig = JSON.stringify(existingRules);
      const tipsSig = hasTips ? JSON.stringify(item.tips) : existingSig;
      const aturanSig = hasAturan ? JSON.stringify(item.aturan_destinasi) : existingSig;

      if (hasTips && tipsSig !== existingSig) {
        AturanDestinasiRepo.replaceForDestination(item.id, item.tips!);
      } else if (hasAturan && aturanSig !== existingSig) {
        AturanDestinasiRepo.replaceForDestination(item.id, item.aturan_destinasi!);
      } else if (idx < 0) {
        AturanDestinasiRepo.replaceForDestination(item.id, item.tips || item.aturan_destinasi || []);
      }
    }

    // 3. Sinkronisasi Tarif Resmi
    const existingTariffs = OfficialTariffsRepo.getByDestinationId(item.id);
    const hasTariffs = Array.isArray(item.tariffs);
    const hasOfficialTariffs = Array.isArray(item.official_tariffs);
    if (hasTariffs || hasOfficialTariffs) {
      const existingSig = JSON.stringify(existingTariffs);
      const tariffsSig = hasTariffs ? JSON.stringify(item.tariffs) : existingSig;
      const officialSig = hasOfficialTariffs ? JSON.stringify(item.official_tariffs) : existingSig;

      let nextTariffs: OfficialTariff[] | null = null;
      if (hasTariffs && tariffsSig !== existingSig) {
        nextTariffs = item.tariffs!;
      } else if (hasOfficialTariffs && officialSig !== existingSig) {
        nextTariffs = item.official_tariffs!;
      } else if (idx < 0) {
        nextTariffs = item.tariffs || item.official_tariffs || [];
      }

      if (nextTariffs !== null) {
        const otherTariffs = OfficialTariffsRepo.getAll().filter((t) => t.destination_id !== item.id);
        const normalizedTariffs = nextTariffs.map((t) => {
          const cat = normalizeTariffCategory(t.category);
          return {
            ...t,
            destination_id: item.id,
            category: cat,
            category_id: t.category_id || tariffCategoryToId(cat),
          };
        });
        writeTable(DB_KEYS.OFFICIAL_TARIFFS, [...otherTariffs, ...normalizedTariffs]);
      }
    }

    return DestinationsRepo.getAll();
  },
  delete: (id: string): Destination[] => {
    const filtered = readTable<Destination>(DB_KEYS.DESTINATIONS, SEED_DESTINATIONS).filter(
      (d) => d.id !== id
    );
    writeTable(DB_KEYS.DESTINATIONS, filtered);
    writeTable(
      DB_KEYS.INDIKATOR_MEDAN,
      IndikatorMedanRepo.getAll().filter((m) => m.destination_id !== id)
    );
    writeTable(
      DB_KEYS.ATURAN_DESTINASI,
      AturanDestinasiRepo.getAll().filter((a) => a.destination_id !== id)
    );
    writeTable(
      DB_KEYS.OFFICIAL_TARIFFS,
      OfficialTariffsRepo.getAll().filter((t) => t.destination_id !== id)
    );
    writeTable(
      DB_KEYS.PANORAMA_SCENES,
      Studio360Repo.getScenes().filter((s) => s.destination_id !== id)
    );
    writeTable(
      DB_KEYS.DENAH_POINTS,
      DenahPointsRepo.getAll().filter((p) => p.destination_id !== id)
    );
    return DestinationsRepo.getAll();
  },
  resetToDefault: (): Destination[] => {
    safeSetLocalStorage(DB_KEYS.DESTINATIONS, JSON.stringify(SEED_DESTINATIONS));
    safeSetLocalStorage(DB_KEYS.INDIKATOR_MEDAN, JSON.stringify(SEED_INDIKATOR_MEDAN));
    safeSetLocalStorage(DB_KEYS.ATURAN_DESTINASI, JSON.stringify(SEED_ATURAN_DESTINASI));
    safeSetLocalStorage(DB_KEYS.OFFICIAL_TARIFFS, JSON.stringify(SEED_OFFICIAL_TARIFFS));
    safeSetLocalStorage(DB_KEYS.PANORAMA_SCENES, JSON.stringify(SEED_PANORAMA_SCENES));
    safeSetLocalStorage(DB_KEYS.DENAH_POINTS, JSON.stringify(SEED_DENAH_POINTS));
    return DestinationsRepo.getAll();
  },
  syncFromBackend: (remoteDestinations: Destination[]): Destination[] => {
    if (!Array.isArray(remoteDestinations) || remoteDestinations.length === 0) {
      return DestinationsRepo.getAll();
    }

    const existingLocal = DestinationsRepo.getAll();
    const localById = new Map(existingLocal.map((d) => [d.id, d]));
    const localBySlug = new Map(existingLocal.map((d) => [d.slug, d]));

    const nextCores: Destination[] = [];
    const existingMedans = IndikatorMedanRepo.getAll();
    const medanMap = new Map(existingMedans.map((m) => [m.destination_id, m]));
    const existingRules = AturanDestinasiRepo.getAll();
    const rulesByDest = new Map<string, AturanDestinasi[]>();
    existingRules.forEach((r) => {
      const arr = rulesByDest.get(r.destination_id) || [];
      arr.push(r);
      rulesByDest.set(r.destination_id, arr);
    });
    const existingTariffs = OfficialTariffsRepo.getAll();
    const tariffsByDest = new Map<string, OfficialTariff[]>();
    existingTariffs.forEach((t) => {
      const arr = tariffsByDest.get(t.destination_id) || [];
      arr.push(t);
      tariffsByDest.set(t.destination_id, arr);
    });

    for (const raw of remoteDestinations) {
      const localMatch = localById.get(raw.id) || (raw.slug ? localBySlug.get(raw.slug) : undefined);
      const cleanCore = stripLegacyDestinationFields({
        ...(localMatch || {}),
        ...(raw as Destination & Record<string, unknown>),
        contributors: raw.contributors || localMatch?.contributors,
        gallery_images: raw.gallery_images || localMatch?.gallery_images,
        checkpoints: raw.checkpoints || localMatch?.checkpoints,
        ticket_price_summary:
          raw.ticket_price_summary ||
          localMatch?.ticket_price_summary ||
          (raw.estimated_cost ? `Rp ${Number(raw.estimated_cost).toLocaleString('id-ID')}` : undefined),
      });
      nextCores.push(cleanCore);

      if (raw.medan_indicator) {
        medanMap.set(
          cleanCore.id,
          stripLegacyMedanFields(
            raw.medan_indicator as IndikatorMedan & Record<string, unknown>,
            cleanCore.id
          )
        );
      }

      const incomingTips = Array.isArray(raw.tips) && raw.tips.length > 0
        ? raw.tips
        : Array.isArray(raw.aturan_destinasi) && raw.aturan_destinasi.length > 0
        ? raw.aturan_destinasi
        : null;
      if (incomingTips) {
        rulesByDest.set(
          cleanCore.id,
          incomingTips.map((t, idx) => ({
            ...t,
            id: t.id || `art-${cleanCore.id}-${idx}`,
            destination_id: cleanCore.id,
          }))
        );
      }

      const incomingTariffs = Array.isArray(raw.tariffs) && raw.tariffs.length > 0
        ? raw.tariffs
        : Array.isArray(raw.official_tariffs) && raw.official_tariffs.length > 0
        ? raw.official_tariffs
        : null;
      if (incomingTariffs) {
        tariffsByDest.set(
          cleanCore.id,
          incomingTariffs.map((t, idx) => {
            const cat = normalizeTariffCategory(t.category || t.item_name);
            return {
              ...t,
              id: t.id || `trf-${cleanCore.id}-${idx}`,
              destination_id: cleanCore.id,
              category: cat,
              category_id: t.category_id || tariffCategoryToId(cat),
              regulation_ref: t.regulation_ref || `Perda ${cleanCore.city_regency}`,
            };
          })
        );
      }
    }

    writeTable(DB_KEYS.DESTINATIONS, nextCores);
    writeTable(DB_KEYS.INDIKATOR_MEDAN, Array.from(medanMap.values()));
    writeTable(DB_KEYS.ATURAN_DESTINASI, Array.from(rulesByDest.values()).flat());
    writeTable(DB_KEYS.OFFICIAL_TARIFFS, Array.from(tariffsByDest.values()).flat());

    return DestinationsRepo.getAll();
  },
};

// ============================================================================
// 10. PUNGLI & FASILITAS REPO
// ============================================================================
export const PungliReportsRepo = {
  getAll: (): PungliReport[] =>
    readTable<PungliReport>(DB_KEYS.PUNGLI_REPORTS, SEED_PUNGLI_REPORTS).map((r) => ({
      ...r,
      status: normalizePungliStatus(r.status),
    })),
  save: (report: PungliReport): PungliReport[] => {
    const list = PungliReportsRepo.getAll();
    const idx = list.findIndex((r) => r.id === report.id);
    const updated = [...list];
    const timestamp = new Date().toISOString();
    const normalized: PungliReport = {
      ...report,
      status: normalizePungliStatus(report.status),
      photo_evidence:
        report.photo_evidence ||
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
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
// 11. MODERASI ULASAN & KONDISI LAPANGAN REPO
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
    const updated = DestinationReviewsRepo.getAll().map((r) =>
      r.id === reviewId ? { ...r, is_important: !r.is_important } : r
    );
    writeTable(DB_KEYS.DESTINATION_REVIEWS, updated);
    return updated;
  },
  toggleVisibility: (reviewId: string): DestinationReview[] => {
    const updated = DestinationReviewsRepo.getAll().map((r) =>
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
// 12. USULAN DESTINASI BARU REPO (Deteksi Duplikat, Gabung Usulan & Kontributor)
// ============================================================================
function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function normalizeTourTokens(name: string): string[] {
  const stopWords = new Set(['air', 'terjun', 'wisata', 'pantai', 'bukit', 'danau', 'desa', 'nagari', 'tersembunyi', 'dan', 'di']);
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length >= 3 && !stopWords.has(w));
}

function isLikelyDuplicateTour(a: NewTour, b: NewTour): boolean {
  if (a.id === b.id) return false;
  const sameRegency = a.city_regency.toLowerCase() === b.city_regency.toLowerCase();
  const distMeters = haversineMeters(a.latitude, a.longitude, b.latitude, b.longitude);
  if (distMeters <= 500) return true;
  if (!sameRegency) return false;

  const normA = a.name.trim().toLowerCase();
  const normB = b.name.trim().toLowerCase();
  if (normA === normB || normA.includes(normB) || normB.includes(normA)) return true;

  const tokensA = normalizeTourTokens(a.name);
  const tokensB = new Set(normalizeTourTokens(b.name));
  const shared = tokensA.filter((t) => tokensB.has(t));
  return shared.length >= 2 || (shared.length === 1 && tokensA.length <= 2 && tokensB.size <= 2);
}

export const NewTourRepo = {
  getAll: (): NewTour[] => readTable<NewTour>(DB_KEYS.NEW_TOURS, SEED_NEW_TOURS),
  save: (item: NewTour): NewTour[] => {
    const normalizedCategory = normalizeDestinationCategory(item.category);
    const normalized: NewTour = {
      ...item,
      category: normalizedCategory,
      category_id: categoryNameToId(normalizedCategory),
    };
    const list = NewTourRepo.getAll();
    const idx = list.findIndex((n) => n.id === normalized.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
    writeTable(DB_KEYS.NEW_TOURS, updated);
    return updated;
  },
  findDuplicateGroups: (sourceList?: NewTour[]): NewTour[][] => {
    const pending = (sourceList || NewTourRepo.getAll()).filter((n) => n.status === 'pending');
    const visited = new Set<string>();
    const groups: NewTour[][] = [];

    for (const item of pending) {
      if (visited.has(item.id)) continue;
      const cluster: NewTour[] = [item];
      visited.add(item.id);
      for (const other of pending) {
        if (visited.has(other.id)) continue;
        if (cluster.some((member) => isLikelyDuplicateTour(member, other))) {
          cluster.push(other);
          visited.add(other.id);
        }
      }
      if (cluster.length >= 2) {
        groups.push(cluster);
      }
    }
    return groups;
  },
  rejectWithNotice: (id: string, reason: string): NewTour[] => {
    const list = NewTourRepo.getAll();
    const target = list.find((n) => n.id === id);
    const updated = list.map((n) =>
      n.id === id ? { ...n, status: 'rejected' as const, admin_notes: reason } : n
    );
    writeTable(DB_KEYS.NEW_TOURS, updated);
    if (target) {
      NotifikasiRepo.create({
        id: `notif-${Date.now()}`,
        user_id: target.user_id,
        notification_type: 'new_tour_rejected',
        title: `Usulan Tempat "${target.name}" Belum Dapat Disetujui`,
        message: `Alasan kurator Dispar Sumbar: ${reason}`,
        reference_id: target.id,
        is_read: false,
        created_at: new Date().toISOString(),
      });
    }
    return updated;
  },
  approveToDestinations: (tour: NewTour): Destination => {
    const newId = `dest-${Date.now()}`;
    const list = NewTourRepo.getAll().map((n) =>
      n.id === tour.id
        ? {
            ...n,
            status: 'approved' as const,
            merged_into_destination_id: newId,
            merged_role: 'Pengusul Utama',
          }
        : n
    );
    writeTable(DB_KEYS.NEW_TOURS, list);

    const normalizedCategory = normalizeDestinationCategory(tour.category);
    const parsedPrice = Number((tour.estimated_price || '').replace(/\D/g, '')) || 10000;
    const tourLat = Number(tour.latitude ?? -0.9471);
    const tourLng = Number(tour.longitude ?? 100.3543);
    const facilitiesList = tour.facilities || [];
    const facilitiesLevel =
      facilitiesList.length >= 4
        ? 'Toilet, Musala & Parkir Lengkap'
        : facilitiesList.length >= 1
        ? 'Terbatas'
        : 'Belum Ada';

    const contributors: DestinationContributor[] = [
      {
        name: tour.submitter_name,
        phone: tour.submitter_phone,
        role: 'Pengusul Utama',
        submission_id: tour.id,
      },
    ];

    const newDest: Destination = {
      id: newId,
      slug: toDestinationSlug(tour.name),
      name: tour.name,
      category_id: categoryNameToId(normalizedCategory),
      category: normalizedCategory,
      city_regency: tour.city_regency,
      description: tour.description || 'Destinasi yang diusulkan oleh komunitas wisatawan WISGO.',
      latitude: tourLat,
      longitude: tourLng,
      geog: `SRID=4326;POINT(${tourLng.toFixed(6)} ${tourLat.toFixed(6)})`,
      elevation_m: 250,
      cover_image:
        tour.photo_url ||
        'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=1200&q=80',
      contributors,
      crowd_level: 'Sepi',
      distance_km: 35,
      travel_time_min: 55,
      estimated_cost: parsedPrice,
      ticket_price_summary: tour.estimated_price || `Rp ${parsedPrice.toLocaleString('id-ID')}`,
      is_hidden_gem: normalizedCategory === 'Hidden Gem' || tour.is_sensitive,
      qr_placard_code: `WISGO-PLG-${Date.now().toString().slice(-4)}`,
      opening_hours: '08.00 - 17.00 WIB',
      medan_indicator: {
        id: `med-${newId}`,
        destination_id: newId,
        vehicle_access: facilitiesList.includes('Area Parkir') ? 'Mobil OK' : 'Hanya Motor',
        trekking_level: facilitiesList.includes('Jalur Trekking') ? 'Sedang' : 'Mudah (Datar)',
        facilities: facilitiesLevel,
        guide_need: facilitiesList.includes('Pemandu Lokal') ? 'Disarankan' : 'Mandiri',
        terrain_note: `Hasil kurasi usulan komunitas oleh ${tour.submitter_name}. Fasilitas terpantau: ${facilitiesList.join(', ') || 'Alami'}.`,
      },
      tips: [
        {
          id: `art-${Date.now()}`,
          destination_id: newId,
          category_id: 'cat-rule-lingkungan',
          title: 'Tips Menjaga Tempat Ini',
          content: tour.tips_menjaga || 'Jaga kebersihan lingkungan wisata dan hormati kearifan lokal.',
          is_important: true,
        },
      ],
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    DestinationsRepo.save(newDest);
    return DestinationsRepo.getById(newId) || newDest;
  },
  mergeAndApproveToDestination: (params: {
    submissions: NewTour[];
    primaryDataSubmissionId: string;
    coverPhotoSubmissionId: string;
    customName?: string;
    customDescription?: string;
    customTips?: string;
  }): Destination => {
    const { submissions, primaryDataSubmissionId, coverPhotoSubmissionId } = params;
    const primarySub =
      submissions.find((s) => s.id === primaryDataSubmissionId) || submissions[0];
    const photoSub =
      submissions.find((s) => s.id === coverPhotoSubmissionId) || primarySub;

    const newId = `dest-${Date.now()}`;
    const finalName = (params.customName || primarySub.name).trim();
    const finalDescription = (params.customDescription || primarySub.description).trim();
    const normalizedCategory = normalizeDestinationCategory(primarySub.category);
    const parsedPrice = Number((primarySub.estimated_price || '').replace(/\D/g, '')) || 10000;
    const tourLat = Number(primarySub.latitude ?? -0.9471);
    const tourLng = Number(primarySub.longitude ?? 100.3543);

    // Gabungkan seluruh fasilitas unik dari semua pengusul
    const mergedFacilities = Array.from(
      new Set(submissions.flatMap((s) => s.facilities || []))
    );
    const facilitiesLevel =
      mergedFacilities.length >= 4
        ? 'Toilet, Musala & Parkir Lengkap'
        : mergedFacilities.length >= 1
        ? 'Terbatas'
        : 'Belum Ada';

    // Kumpulkan foto cover + galeri tambahan dari kontributor lain
    const coverImage =
      photoSub.photo_url ||
      primarySub.photo_url ||
      'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=1200&q=80';
    const galleryImages = Array.from(
      new Set(
        submissions
          .map((s) => s.photo_url)
          .filter((url): url is string => Boolean(url) && url !== coverImage)
      )
    );

    // Susun kredit kontributor yang adil untuk seluruh pengusul
    const contributors: DestinationContributor[] = submissions.map((s) => {
      const isPrimaryData = s.id === primarySub.id;
      const isCoverPhoto = s.id === photoSub.id;
      let role: DestinationContributor['role'] = 'Pengusul Bersama';
      if (isPrimaryData && isCoverPhoto) role = 'Pengusul Utama';
      else if (isPrimaryData) role = 'Kontributor Data & Tips';
      else if (isCoverPhoto) role = 'Kontributor Foto';
      return {
        name: s.submitter_name,
        phone: s.submitter_phone,
        role,
        submission_id: s.id,
      };
    });

    // Gabungkan Tips Menjaga Tempat Ini dari semua pengusul
    const tipsEntries: AturanDestinasi[] = params.customTips?.trim()
      ? [
          {
            id: `art-${Date.now()}-0`,
            destination_id: newId,
            category_id: 'cat-rule-lingkungan',
            title: 'Tips Menjaga Tempat Ini (Gabungan Kontributor)',
            content: params.customTips.trim(),
            is_important: true,
          },
        ]
      : submissions
          .filter((s) => s.tips_menjaga?.trim())
          .map((s, idx) => ({
            id: `art-${Date.now()}-${idx}`,
            destination_id: newId,
            category_id: 'cat-rule-lingkungan',
            title: `Tips Menjaga (oleh ${s.submitter_name})`,
            content: s.tips_menjaga.trim(),
            is_important: idx === 0,
          }));

    const contributorNames = contributors.map((c) => `${c.name} (${c.role})`).join(', ');

    const newDest: Destination = {
      id: newId,
      slug: toDestinationSlug(finalName),
      name: finalName,
      category_id: categoryNameToId(normalizedCategory),
      category: normalizedCategory,
      city_regency: primarySub.city_regency,
      description: finalDescription || 'Destinasi hasil kolaborasi usulan komunitas WISGO.',
      latitude: tourLat,
      longitude: tourLng,
      geog: `SRID=4326;POINT(${tourLng.toFixed(6)} ${tourLat.toFixed(6)})`,
      elevation_m: 250,
      cover_image: coverImage,
      gallery_images: galleryImages.length > 0 ? galleryImages : undefined,
      contributors,
      crowd_level: 'Sepi',
      distance_km: 35,
      travel_time_min: 55,
      estimated_cost: parsedPrice,
      ticket_price_summary: primarySub.estimated_price || `Rp ${parsedPrice.toLocaleString('id-ID')}`,
      is_hidden_gem: normalizedCategory === 'Hidden Gem' || submissions.some((s) => s.is_sensitive),
      qr_placard_code: `WISGO-PLG-${Date.now().toString().slice(-4)}`,
      opening_hours: '08.00 - 17.00 WIB',
      medan_indicator: {
        id: `med-${newId}`,
        destination_id: newId,
        vehicle_access: mergedFacilities.includes('Area Parkir') ? 'Mobil OK' : 'Hanya Motor',
        trekking_level: mergedFacilities.includes('Jalur Trekking') ? 'Sedang' : 'Mudah (Datar)',
        facilities: facilitiesLevel,
        guide_need: mergedFacilities.includes('Pemandu Lokal') ? 'Disarankan' : 'Mandiri',
        terrain_note: `Kurasi gabungan komunitas oleh ${contributorNames}. Fasilitas terpantau: ${mergedFacilities.join(', ') || 'Alami'}.`,
      },
      tips: tipsEntries,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    DestinationsRepo.save(newDest);

    // Tandai SEMUA usulan yang digabung sebagai approved (tidak ada yang ditolak) & kirim notifikasi apresiasi
    const roleBySubId = new Map(contributors.map((c) => [c.submission_id, c.role]));
    const updatedList = NewTourRepo.getAll().map((n) => {
      const assignedRole = roleBySubId.get(n.id);
      if (!assignedRole) return n;
      return {
        ...n,
        status: 'approved' as const,
        merged_into_destination_id: newId,
        merged_role: assignedRole,
        admin_notes: `Digabungkan menjadi destinasi "${finalName}" sebagai ${assignedRole}.`,
      };
    });
    writeTable(DB_KEYS.NEW_TOURS, updatedList);

    const now = new Date().toISOString();
    submissions.forEach((s, idx) => {
      const role = roleBySubId.get(s.id) || 'Pengusul Bersama';
      NotifikasiRepo.create({
        id: `notif-mrg-${Date.now()}-${idx}`,
        user_id: s.user_id,
        notification_type: 'system',
        title: `Usulan "${finalName}" Resmi Terbit!`,
        message:
          role === 'Kontributor Foto'
            ? `Terima kasih ${s.submitter_name}! Foto Anda terpilih sebagai Foto Utama destinasi "${finalName}" dan nama Anda tercantum sebagai Kontributor Foto.`
            : `Terima kasih ${s.submitter_name}! Usulan Anda untuk "${finalName}" telah diterbitkan bersama kontributor lain (${role}).`,
        reference_id: newId,
        is_read: false,
        created_at: now,
      });
    });

    return DestinationsRepo.getById(newId) || newDest;
  },
};

// ============================================================================
// 13. CHALLENGES, REWARDS & PASPOR DIGITAL REPO
// ============================================================================
export const ChallengesRepo = {
  getAll: (): Challenge[] => readTable<Challenge>(DB_KEYS.CHALLENGES, SEED_CHALLENGES),
  save: (item: Challenge): Challenge[] => {
    const list = ChallengesRepo.getAll();
    const idx = list.findIndex((c) => c.id === item.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = { ...item, updated_at: new Date().toISOString() };
    else updated.unshift({ ...item, created_at: item.created_at || new Date().toISOString() });
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
  validateAndSendReward: (claimId: string, notes?: string): UserChallengeReward[] => {
    const list = UserChallengeRewardsRepo.getAll();
    const timestamp = new Date().toISOString();
    const certCode = `WG-CERT-2026-${Date.now().toString().slice(-5)}`;
    const updated = list.map((claim) =>
      claim.id === claimId
        ? {
            ...claim,
            status: 'HADIAH_TERKIRIM' as const,
            certificate_code: claim.certificate_code || certCode,
            certificate_url:
              claim.certificate_url || `https://wisgo.sumbarprov.go.id/certs/${certCode}.pdf`,
            completed_at: claim.completed_at || timestamp,
            reward_notes: notes || claim.reward_notes || 'Diterbitkan otomatis oleh Admin Dispar Sumbar.',
          }
        : claim
    );
    writeTable(DB_KEYS.USER_CHALLENGE_REWARDS, updated);
    return updated;
  },
};

export const PassportSpotsRepo = {
  getAll: (): DigitalPassportSpot[] => SEED_PASSPORT_SPOTS,
};

export const StempVisitsRepo = {
  getAll: (): StempVisit[] => readTable<StempVisit>(DB_KEYS.STEMP_VISITS, SEED_STEMP_VISITS),
  save: (visit: StempVisit): StempVisit[] => {
    const list = StempVisitsRepo.getAll();
    const updated = [visit, ...list];
    writeTable(DB_KEYS.STEMP_VISITS, updated);
    return updated;
  },
  getByUserId: (userId: string): StempVisit[] =>
    StempVisitsRepo.getAll().filter((s) => s.user_id === userId),
  countValidPersonalVisits: (): number =>
    StempVisitsRepo.getAll().filter((s) => s.is_gps_valid).length,
};

// ============================================================================
// 14. NOTIFIKASI REPO
// ============================================================================
export const NotifikasiRepo = {
  getAll: (): Notifikasi[] => readTable<Notifikasi>(DB_KEYS.NOTIFIKASI, SEED_NOTIFIKASI),
  create: (item: Notifikasi): Notifikasi[] => {
    const updated = [item, ...NotifikasiRepo.getAll()];
    writeTable(DB_KEYS.NOTIFIKASI, updated);
    return updated;
  },
  markAsRead: (id: string): void => {
    const updated = NotifikasiRepo.getAll().map((n) => (n.id === id ? { ...n, is_read: true } : n));
    writeTable(DB_KEYS.NOTIFIKASI, updated);
  },
};

// ============================================================================
// 15. KOMANDO SOS: HAZARDS, SOS LOGS & 6 KONTAK DARURAT REAL
// ============================================================================
export const HazardAlertsRepo = {
  getAll: (): HazardAlert[] =>
    readTable<HazardAlert>(DB_KEYS.HAZARD_ALERTS, SEED_HAZARD_ALERTS).map((h) => ({
      ...h,
      severity: normalizeHazardSeverity(h.severity),
    })),
  save: (alert: HazardAlert): HazardAlert[] => {
    const list = HazardAlertsRepo.getAll();
    const idx = list.findIndex((h) => h.id === alert.id || h.corridor_code === alert.corridor_code);
    const updated = [...list];
    const normalized: HazardAlert = {
      ...alert,
      severity: normalizeHazardSeverity(alert.severity),
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
    const normalized: EmergencyContact = {
      ...contact,
      updated_at: new Date().toISOString(),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.push(normalized);
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
// 16. TRIP GO, PENYELENGGARA, ESCROW & PACKING TEMPLATES
// ============================================================================
export const OpenTripsRepo = {
  getAll: (): OpenTrip[] => readTable<OpenTrip>(DB_KEYS.OPEN_TRIPS, SEED_OPEN_TRIPS),
  save: (trip: OpenTrip): OpenTrip[] => {
    const list = OpenTripsRepo.getAll();
    const idx = list.findIndex((t) => t.id === trip.id);
    const updated = [...list];
    const normalized: OpenTrip = {
      ...trip,
      travel_category: normalizeDestinationCategory(trip.travel_category),
      created_at: trip.created_at || new Date().toISOString(),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
    writeTable(DB_KEYS.OPEN_TRIPS, updated);
    return updated;
  },
  delete: (id: string): OpenTrip[] => {
    const filtered = OpenTripsRepo.getAll().filter((t) => t.id !== id);
    writeTable(DB_KEYS.OPEN_TRIPS, filtered);
    return filtered;
  },
  updateEscrowStatus: (
    id: string,
    escrow_status: 'DITAHAN_DI_ESCROW' | 'DICAIRKAN_KE_PENYELENGGARA' | 'DILAPORKAN_INSIDEN'
  ): OpenTrip[] => {
    const updated = OpenTripsRepo.getAll().map((t) =>
      t.id === id ? { ...t, escrow_status } : t
    );
    writeTable(DB_KEYS.OPEN_TRIPS, updated);
    return updated;
  },
};

export const OpenTripOrganizersRepo = {
  getAll: (): OpenTripOrganizer[] =>
    readTable<OpenTripOrganizer>(DB_KEYS.ORGANIZERS, SEED_ORGANIZERS),
  updateStatus: (
    id: string,
    status: 'Menunggu' | 'Terverifikasi' | 'Ditolak',
    notes?: string
  ): OpenTripOrganizer[] => {
    const updated = OpenTripOrganizersRepo.getAll().map((org) =>
      org.id === id
        ? {
            ...org,
            status,
            is_verified: status === 'Terverifikasi',
            verification_badge:
              status === 'Terverifikasi'
                ? 'Penyelenggara Terverifikasi WISGO'
                : status === 'Ditolak'
                ? 'Verifikasi Ditolak'
                : 'Menunggu Verifikasi Legalitas',
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
  getTotalRevenueIdr: (): number =>
    OpenTripTransactionsRepo.getAll()
      .filter((t) => t.status === 'BERHASIL')
      .reduce((sum, t) => sum + t.amount_idr, 0),
};

export const PackingTemplatesRepo = {
  getAll: (): PackingTemplate[] =>
    readTable<PackingTemplate>(DB_KEYS.PACKING_TEMPLATES, SEED_PACKING_TEMPLATES),
  getByCategory: (categoryName: string): PackingTemplate[] =>
    PackingTemplatesRepo.getAll().filter((p) => p.category_name === categoryName),
  save: (template: PackingTemplate): PackingTemplate[] => {
    const list = PackingTemplatesRepo.getAll();
    const idx = list.findIndex((p) => p.id === template.id);
    const updated = [...list];
    const normalized: PackingTemplate = {
      ...template,
      category_name: normalizeDestinationCategory(template.category_name),
    };
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
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
// 17. GAODE RANKING, KAMUS MINANG, KALENDER BUDAYA, TELEMETRI & HEATMAP
// ============================================================================
export const DEFAULT_GAODE_WEIGHTS: GaodeWeightConfig = {
  satisfaction_weight: 35,
  pungli_free_weight: 30,
  medan_access_weight: 20,
  visit_volume_weight: 15,
};

export const GaodeRankingsRepo = {
  getAll: (): GaodeBehaviorRanking[] =>
    readTable<GaodeBehaviorRanking>(DB_KEYS.GAODE_RANKINGS, SEED_GAODE_RANKINGS),
  saveAll: (items: GaodeBehaviorRanking[]): void => {
    writeTable(DB_KEYS.GAODE_RANKINGS, items);
  },
  getWeights: (): GaodeWeightConfig => {
    try {
      const raw = localStorage.getItem(DB_KEYS.GAODE_CONFIG);
      if (raw) return JSON.parse(raw);
    } catch {
      // fallback
    }
    return DEFAULT_GAODE_WEIGHTS;
  },
  recalculate: (config: GaodeWeightConfig): GaodeBehaviorRanking[] => {
    safeSetLocalStorage(DB_KEYS.GAODE_CONFIG, JSON.stringify(config));
    const current = GaodeRankingsRepo.getAll();
    const totalWeight =
      config.satisfaction_weight +
        config.pungli_free_weight +
        config.medan_access_weight +
        config.visit_volume_weight || 100;

    const recalculated = current.map((item) => {
      const satScore = item.satisfaction_rate ?? 95;
      const pungliScore = item.pungli_free_index ?? 98;
      const medanScore = ((item.medan_score ?? 4) / 5) * 100;
      const visitScore = Math.min(100, ((item.weekly_visits ?? 4000) / 14500) * 100);
      const weighted =
        (satScore * config.satisfaction_weight +
          pungliScore * config.pungli_free_weight +
          medanScore * config.medan_access_weight +
          visitScore * config.visit_volume_weight) /
        totalWeight;
      const score = Number(weighted.toFixed(1));
      return {
        ...item,
        previous_rank: item.current_rank,
        calculated_gaode_score: score,
        gaode_authenticity_score: score,
        updated_at: new Date().toISOString(),
      };
    });

    recalculated.sort((a, b) => b.calculated_gaode_score - a.calculated_gaode_score);
    const finalized = recalculated.map((item, idx) => {
      const nextRank = idx + 1;
      const trend: 'up' | 'down' | 'same' =
        nextRank < item.previous_rank ? 'up' : nextRank > item.previous_rank ? 'down' : 'same';
      return {
        ...item,
        rank_position: nextRank,
        current_rank: nextRank,
        trend,
      };
    });

    GaodeRankingsRepo.saveAll(finalized);
    return finalized;
  },
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
    const normalized = { ...phrase, updated_at: new Date().toISOString() };
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
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
  getAll: (): CulturalEvent[] =>
    readTable<CulturalEvent>(DB_KEYS.CULTURAL_EVENTS, SEED_CULTURAL_EVENTS),
  save: (event: CulturalEvent): CulturalEvent[] => {
    const list = CulturalEventsRepo.getAll();
    const idx = list.findIndex((e) => e.id === event.id);
    const updated = [...list];
    const normalized = { ...event, updated_at: new Date().toISOString() };
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
    writeTable(DB_KEYS.CULTURAL_EVENTS, updated);
    return updated;
  },
  delete: (id: string): CulturalEvent[] => {
    const filtered = CulturalEventsRepo.getAll().filter((e) => e.id !== id);
    writeTable(DB_KEYS.CULTURAL_EVENTS, filtered);
    return filtered;
  },
};

export const RegencyHeatmapRepo = {
  getAll: (): RegencyHeatmapData[] =>
    readTable<RegencyHeatmapData>(DB_KEYS.REGENCY_HEATMAP, SEED_REGENCY_HEATMAP),
};

export const SystemBenchmarkRepo = {
  get: (): SystemBenchmarkMetrics => {
    try {
      const raw = localStorage.getItem(DB_KEYS.SYSTEM_BENCHMARK);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed.go_engine_latency_ms === 'number') {
          return parsed;
        }
      }
    } catch {
      // fallback
    }
    return INITIAL_SYSTEM_BENCHMARK;
  },
  save: (metrics: SystemBenchmarkMetrics): SystemBenchmarkMetrics => {
    safeSetLocalStorage(DB_KEYS.SYSTEM_BENCHMARK, JSON.stringify(metrics));
    return metrics;
  },
};

// ============================================================================
// 18. LEVEL PETUALANG, PROFIL JEJAK WISGO & TEMPLATE SHARE
// ============================================================================
const LEVEL_NAME_ID_MAP: Record<number, { name: AdventurerLevelConfig['name']; title: string }> = {
  1: { name: 'Pemula', title: 'Level 1 – Pemula' },
  2: { name: 'Penjelajah', title: 'Level 2 – Penjelajah' },
  3: { name: 'Petualang', title: 'Level 3 – Petualang' },
  4: { name: 'Perintis', title: 'Level 4 – Perintis' },
  5: { name: 'Pengelana', title: 'Level 5 – Pengelana' },
};

export const AdventurerLevelsRepo = {
  getAll: (): AdventurerLevelConfig[] =>
    readTable<AdventurerLevelConfig>(DB_KEYS.ADVENTURER_LEVELS, SEED_ADVENTURER_LEVELS).map((lvl) => {
      const canonical = LEVEL_NAME_ID_MAP[lvl.level];
      if (!canonical) return lvl;
      const isEnglish = /^(Beginner|Explorer|Adventurer|Trailblazer|Wanderer)$/i.test(lvl.name);
      return {
        ...lvl,
        name: canonical.name,
        title: isEnglish || /(Beginner|Explorer|Adventurer|Trailblazer|Wanderer)/i.test(lvl.title)
          ? canonical.title
          : lvl.title,
      };
    }),
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

export const UserProfilesRepo = {
  getAll: (): UserProfileExperience[] =>
    readTable<UserProfileExperience>(DB_KEYS.USER_PROFILES, SEED_USER_PROFILES).map((u) => {
      const calc = calculateAdventurerLevel(u.total_xp);
      const { total_distance_km: _drop, ...clean } = u as UserProfileExperience & {
        total_distance_km?: unknown;
      };
      void _drop;
      return {
        ...clean,
        current_level: calc.level,
        level_name: calc.name,
      };
    }),
  getById: (id: string): UserProfileExperience | undefined =>
    UserProfilesRepo.getAll().find((u) => u.id === id || u.user_id === id),
  save: (profile: UserProfileExperience): UserProfileExperience[] => {
    const calc = calculateAdventurerLevel(profile.total_xp);
    const { total_distance_km: _drop, ...clean } = profile as UserProfileExperience & {
      total_distance_km?: unknown;
    };
    void _drop;
    const normalized: UserProfileExperience = {
      ...clean,
      current_level: calc.level,
      level_name: calc.name,
    };
    const list = UserProfilesRepo.getAll();
    const idx = list.findIndex((u) => u.id === normalized.id);
    const updated = [...list];
    if (idx >= 0) updated[idx] = normalized;
    else updated.unshift(normalized);
    writeTable(DB_KEYS.USER_PROFILES, updated);
    return updated;
  },
};

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

export const SavedPlacesRepo = {
  getAll: (): SavedPlace[] => readTable<SavedPlace>(DB_KEYS.SAVED_PLACES, SEED_SAVED_PLACES),
};

export const UsersRepo = {
  getAll: (): User[] => readTable<User>(DB_KEYS.USERS, SEED_USERS),
};
