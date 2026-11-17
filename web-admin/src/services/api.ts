import axios from 'axios';
import {
  AdminAuthCredentials,
  AdminAuthResponse,
  BenchmarkRunResult,
  CommunityHiddenGemSubmission,
  CultureCalendarEvent,
  Destination,
  DigitalPassportMetrics,
  EscrowTransaction,
  GaodeRankingItem,
  GaodeWeightConfig,
  GroupRoomPreview,
  HazardSeverity,
  HazardZoneAlert,
  HotspotPin,
  MinangAudioPhrase,
  OpenTripItem,
  OpenTripStatus,
  PanoramaScene,
  Partner,
  PungliReport,
  PungliStatus,
  RegencyHeatmapData,
  SosEmergencyStatus,
  SosEmergencyTicket,
  SystemBenchmarkMetrics,
  WAWebhookResponse,
} from '../types/contract';
import {
  INITIAL_COMMUNITY_SUBMISSIONS,
  INITIAL_CULTURE_EVENTS,
  INITIAL_DIGITAL_PASSPORT_METRICS,
  INITIAL_GAODE_RANKINGS,
  INITIAL_GROUP_ROOMS,
  INITIAL_HAZARD_ALERTS,
  INITIAL_MINANG_PHRASES,
  INITIAL_OPEN_TRIPS,
  INITIAL_PARTNERS,
  INITIAL_PUNGLI_REPORTS,
  INITIAL_REGENCY_HEATMAP,
  INITIAL_SOS_TICKETS,
  INITIAL_SYSTEM_BENCHMARK,
  MOCK_20_DESTINATIONS,
  toDestinationSlug,
} from '../data/mockDestinations';
import { safeSetLocalStorage } from '../utils/imageOptimizer';

const TOKEN_STORAGE_KEY = 'wisgo_admin_jwt';
const USER_STORAGE_KEY = 'wisgo_admin_user';
const DESTINATIONS_STORAGE_KEY = 'wisgo_dispar_destinations_v2';
const PARTNERS_STORAGE_KEY = 'wisgo_dispar_partners_v2';
const PUNGLI_STORAGE_KEY = 'wisgo_dispar_pungli_v2';
const SOS_STORAGE_KEY = 'wisgo_dispar_sos_v2';
const HAZARD_STORAGE_KEY = 'wisgo_dispar_hazard_v2';
const GROUPS_STORAGE_KEY = 'wisgo_dispar_groups_v2';
const SUBMISSIONS_STORAGE_KEY = 'wisgo_community_submissions_v2';
const HEATMAP_STORAGE_KEY = 'wisgo_regency_heatmap_v2';
const PASSPORT_METRICS_KEY = 'wisgo_passport_metrics_v2';
const PHRASES_STORAGE_KEY = 'wisgo_minang_phrases_v1';
const EVENTS_STORAGE_KEY = 'wisgo_culture_events_v1';
const GAODE_STORAGE_KEY = 'wisgo_gaode_rankings_v1';
const GAODE_CONFIG_KEY = 'wisgo_gaode_config_v1';
const OPENTRIPS_STORAGE_KEY = 'wisgo_open_trips_v1';
const BENCHMARK_STORAGE_KEY = 'wisgo_system_benchmark_v1';

function getStoredWithFallback(newKey: string, legacyKey: string): string | null {
  return localStorage.getItem(newKey) || localStorage.getItem(legacyKey);
}

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 4500,
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_STORAGE_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

function readStoredDestinations(): Destination[] | null {
  try {
    const raw = getStoredWithFallback(
      DESTINATIONS_STORAGE_KEY,
      'rancakin_dispar_destinations_v2'
    );
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed) && parsed.length > 0) {
      return parsed;
    }
    return null;
  } catch {
    return null;
  }
}

export function writeStoredDestinations(destinations: Destination[]): void {
  safeSetLocalStorage(DESTINATIONS_STORAGE_KEY, JSON.stringify(destinations));
}

/**
 * Cek koneksi langsung ke server utama (/health)
 */
export async function checkBackendHealth(): Promise<{
  online: boolean;
  env?: string;
}> {
  try {
    const res = await axios.get('/health', { timeout: 2500 });
    return {
      online: res.data?.status === 'ok',
      env: res.data?.env || 'production',
    };
  } catch {
    return { online: false };
  }
}

/**
 * Otentikasi Administrator Utama — Pusat Komando Terpadu WISGO (Single Admin JWT Auth)
 */
export async function loginAdminJWT(
  credentials: AdminAuthCredentials
): Promise<AdminAuthResponse> {
  await new Promise((resolve) => setTimeout(resolve, 350));

  const emailLower = credentials.email.trim().toLowerCase();
  if (!emailLower.includes('@') || credentials.password.length < 6) {
    throw new Error(
      'Alamat email dinas tidak valid atau kata sandi kurang dari 6 karakter.'
    );
  }

  const jwtToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
    btoa(
      JSON.stringify({
        sub: 'usr-admin-komando-01',
        email: emailLower,
        role: 'admin_utama',
        iat: Math.floor(Date.now() / 1000),
      })
    ) +
    '.wisgo-komando-sig-2026';

  const authResponse: AdminAuthResponse = {
    token: jwtToken,
    expires_at: new Date(Date.now() + 12 * 3600 * 1000).toISOString(),
    user: {
      id: 'usr-admin-komando-01',
      phone_number: '6281166002026',
      full_name: 'Administrator Utama — Pusat Komando Terpadu',
      role: 'admin_utama',
      email: emailLower,
      agency:
        'Pusat Komando Terpadu WISGO (Dispar Sumbar • Penindakan Pungli • Siaga SAR)',
      created_at: new Date().toISOString(),
    },
  };

  localStorage.setItem(TOKEN_STORAGE_KEY, authResponse.token);
  localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(authResponse.user));
  return authResponse;
}

export function getStoredAdminSession(): AdminAuthResponse | null {
  const token = getStoredWithFallback(TOKEN_STORAGE_KEY, 'rancakin_admin_jwt');
  const rawUser = getStoredWithFallback(USER_STORAGE_KEY, 'rancakin_admin_user');
  if (!token || !rawUser) return null;
  try {
    return {
      token,
      expires_at: '',
      user: JSON.parse(rawUser),
    };
  } catch {
    return null;
  }
}

export function logoutAdminJWT(): void {
  localStorage.removeItem(TOKEN_STORAGE_KEY);
  localStorage.removeItem(USER_STORAGE_KEY);
  localStorage.removeItem('rancakin_admin_jwt');
  localStorage.removeItem('rancakin_admin_user');
}

/**
 * Ambil data destinasi dengan persistensi localStorage & sinkronisasi ke server Go Gin
 */
export async function fetchDestinationsWithBridge(): Promise<{
  destinations: Destination[];
  online: boolean;
}> {
  const stored = readStoredDestinations();
  const baseList = stored || MOCK_20_DESTINATIONS;

  try {
    const [listRes, detailRes] = await Promise.all([
      apiClient.get<Destination[]>('/destinations'),
      apiClient.get<Destination>('/destinations/detail').catch(() => null),
    ]);

    const apiItems = Array.isArray(listRes.data) ? listRes.data : [];
    const detailItem = detailRes?.data;

    // Jika user belum punya modifikasi lokal, sinkronkan pembaruan dari Go Gin
    if (!stored) {
      const mergedMap = new Map<string, Destination>();
      for (const item of baseList) {
        mergedMap.set(item.id, item);
      }

      for (const apiDest of apiItems) {
        const existing = mergedMap.get(apiDest.id);
        mergedMap.set(apiDest.id, {
          ...existing,
          ...apiDest,
          slug:
            apiDest.slug ||
            existing?.slug ||
            toDestinationSlug(apiDest.name || 'destinasi'),
          medan_indicator: {
            ...existing?.medan_indicator,
            ...(detailItem && detailItem.id === apiDest.id
              ? detailItem.medan_indicator
              : apiDest.medan_indicator),
          } as Destination['medan_indicator'],
          tariffs: apiDest.tariffs || existing?.tariffs || [],
          tips: apiDest.tips || existing?.tips || [],
          scenes_360: apiDest.scenes_360 || existing?.scenes_360 || [],
        });
      }

      const merged = Array.from(mergedMap.values());
      writeStoredDestinations(merged);
      return { destinations: merged, online: true };
    }

    return { destinations: stored, online: true };
  } catch {
    if (!stored) {
      writeStoredDestinations(MOCK_20_DESTINATIONS);
    }
    return {
      destinations: baseList,
      online: false,
    };
  }
}

/**
 * Simpan destinasi baru atau perbarui destinasi ke localStorage + kirim POST/PUT ke Go Gin
 */
export async function saveDestinationWithBridge(
  destination: Destination,
  currentList: Destination[]
): Promise<{ updatedList: Destination[]; syncedRemote: boolean }> {
  const normalized: Destination = {
    ...destination,
    slug: destination.slug || toDestinationSlug(destination.name),
    updated_at: new Date().toISOString(),
  };

  const exists = currentList.some((d) => d.id === normalized.id);
  const updatedList = exists
    ? currentList.map((d) => (d.id === normalized.id ? normalized : d))
    : [normalized, ...currentList];

  writeStoredDestinations(updatedList);

  try {
    if (exists) {
      await apiClient.put(`/destinations/${normalized.id}`, normalized);
    } else {
      await apiClient.post('/destinations', normalized);
    }
    return { updatedList, syncedRemote: true };
  } catch {
    return { updatedList, syncedRemote: false };
  }
}

/**
 * Hapus destinasi dari localStorage + kirim DELETE ke Go Gin
 */
export async function deleteDestinationWithBridge(
  destinationId: string,
  currentList: Destination[]
): Promise<{ updatedList: Destination[]; syncedRemote: boolean }> {
  const updatedList = currentList.filter((d) => d.id !== destinationId);
  writeStoredDestinations(updatedList);

  try {
    await apiClient.delete(`/destinations/${destinationId}`);
    return { updatedList, syncedRemote: true };
  } catch {
    return { updatedList, syncedRemote: false };
  }
}

/**
 * Kembalikan 20 destinasi standar Sumatera Barat ke kondisi awal
 */
export function resetDestinationsToDefault(): Destination[] {
  writeStoredDestinations(MOCK_20_DESTINATIONS);
  return MOCK_20_DESTINATIONS;
}

// ============================================================================
// CMS STUDIO VIRTUAL 360° (FS1-M2-02)
// ============================================================================

export async function saveDestinationScene(
  destId: string,
  scene: PanoramaScene,
  destinationsList: Destination[]
): Promise<Destination[]> {
  const updated = destinationsList.map((dest) => {
    if (dest.id !== destId) return dest;
    const currentScenes = dest.scenes_360 || [];
    const exists = currentScenes.some((s) => s.id === scene.id);
    const updatedScenes = exists
      ? currentScenes.map((s) => (s.id === scene.id ? scene : s))
      : [...currentScenes, scene];
    return {
      ...dest,
      scenes_360: updatedScenes,
      updated_at: new Date().toISOString(),
    };
  });
  writeStoredDestinations(updated);
  return updated;
}

export async function deleteDestinationScene(
  destId: string,
  sceneId: string,
  destinationsList: Destination[]
): Promise<Destination[]> {
  const updated = destinationsList.map((dest) => {
    if (dest.id !== destId) return dest;
    const currentScenes = dest.scenes_360 || [];
    return {
      ...dest,
      scenes_360: currentScenes.filter((s) => s.id !== sceneId),
      updated_at: new Date().toISOString(),
    };
  });
  writeStoredDestinations(updated);
  return updated;
}

export async function saveSceneHotspot(
  destId: string,
  sceneId: string,
  hotspot: HotspotPin,
  destinationsList: Destination[]
): Promise<Destination[]> {
  const updated = destinationsList.map((dest) => {
    if (dest.id !== destId) return dest;
    const currentScenes = dest.scenes_360 || [];
    const updatedScenes = currentScenes.map((scene) => {
      if (scene.id !== sceneId) return scene;
      const currentHotspots = scene.hotspots || [];
      const exists = currentHotspots.some((h) => h.id === hotspot.id);
      const updatedHotspots = exists
        ? currentHotspots.map((h) => (h.id === hotspot.id ? hotspot : h))
        : [...currentHotspots, hotspot];
      return {
        ...scene,
        hotspots: updatedHotspots,
      };
    });
    return {
      ...dest,
      scenes_360: updatedScenes,
      updated_at: new Date().toISOString(),
    };
  });
  writeStoredDestinations(updated);
  return updated;
}

export async function deleteSceneHotspot(
  destId: string,
  sceneId: string,
  hotspotId: string,
  destinationsList: Destination[]
): Promise<Destination[]> {
  const updated = destinationsList.map((dest) => {
    if (dest.id !== destId) return dest;
    const currentScenes = dest.scenes_360 || [];
    const updatedScenes = currentScenes.map((scene) => {
      if (scene.id !== sceneId) return scene;
      const currentHotspots = scene.hotspots || [];
      return {
        ...scene,
        hotspots: currentHotspots.filter((h) => h.id !== hotspotId),
      };
    });
    return {
      ...dest,
      scenes_360: updatedScenes,
      updated_at: new Date().toISOString(),
    };
  });
  writeStoredDestinations(updated);
  return updated;
}

// ============================================================================
// PUSAT KOMANDO TERPADU: PENINDAKAN PUNGLI & SIAGA SOS TIM SAR (FS1-M2-03)
// ============================================================================

export async function fetchPungliReports(): Promise<PungliReport[]> {
  try {
    const raw = localStorage.getItem(PUNGLI_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    // Remote bridge fallback
    const res = await apiClient.get<PungliReport[]>('/reports/pungli').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      localStorage.setItem(PUNGLI_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Fallback to initial
  }
  localStorage.setItem(PUNGLI_STORAGE_KEY, JSON.stringify(INITIAL_PUNGLI_REPORTS));
  return INITIAL_PUNGLI_REPORTS;
}

export async function updatePungliReportStatus(
  reportId: string,
  status: PungliStatus,
  adminNotes?: string
): Promise<PungliReport[]> {
  const current = await fetchPungliReports();
  const updated = current.map((r) => {
    if (r.id !== reportId) return r;
    return {
      ...r,
      status,
      admin_notes: adminNotes !== undefined ? adminNotes : r.admin_notes,
    };
  });
  localStorage.setItem(PUNGLI_STORAGE_KEY, JSON.stringify(updated));

  try {
    await apiClient.put(`/reports/pungli/${reportId}/status`, {
      status,
      admin_notes: adminNotes,
    });
  } catch {
    // Offline mode
  }
  return updated;
}

export async function submitPungliReport(
  reportData: Omit<PungliReport, 'id' | 'created_at'>
): Promise<PungliReport> {
  const newReport: PungliReport = {
    ...reportData,
    id: `rep-${Date.now().toString(36)}`,
    created_at: new Date().toISOString(),
  };

  const current = await fetchPungliReports();
  const updated = [newReport, ...current];
  localStorage.setItem(PUNGLI_STORAGE_KEY, JSON.stringify(updated));

  try {
    await apiClient.post('/reports/pungli', newReport);
  } catch {
    // Offline mode
  }
  return newReport;
}

export async function fetchSosTickets(): Promise<SosEmergencyTicket[]> {
  try {
    const raw = localStorage.getItem(SOS_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    const res = await apiClient.get<SosEmergencyTicket[]>('/sos/tickets').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      localStorage.setItem(SOS_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Fallback
  }
  localStorage.setItem(SOS_STORAGE_KEY, JSON.stringify(INITIAL_SOS_TICKETS));
  return INITIAL_SOS_TICKETS;
}

export async function updateSosTicketStatus(
  ticketId: string,
  status: SosEmergencyStatus,
  sarUnitAssigned?: string
): Promise<SosEmergencyTicket[]> {
  const current = await fetchSosTickets();
  const updated = current.map((t) => {
    if (t.id !== ticketId) return t;
    return {
      ...t,
      status,
      sar_unit_assigned: sarUnitAssigned || t.sar_unit_assigned,
    };
  });
  localStorage.setItem(SOS_STORAGE_KEY, JSON.stringify(updated));

  try {
    await apiClient.put(`/sos/tickets/${ticketId}/status`, {
      status,
      sar_unit_assigned: sarUnitAssigned,
    });
  } catch {
    // Offline mode
  }
  return updated;
}

export async function submitSosEmergency(
  data: Omit<SosEmergencyTicket, 'id' | 'created_at'>
): Promise<SosEmergencyTicket> {
  const newTicket: SosEmergencyTicket = {
    ...data,
    id: `sos-${Date.now().toString(36)}`,
    created_at: new Date().toISOString(),
  };

  const current = await fetchSosTickets();
  const updated = [newTicket, ...current];
  localStorage.setItem(SOS_STORAGE_KEY, JSON.stringify(updated));

  try {
    await apiClient.post('/sos/trigger', newTicket);
  } catch {
    // Offline mode
  }
  return newTicket;
}

export async function fetchHazardAlerts(): Promise<HazardZoneAlert[]> {
  try {
    const raw = localStorage.getItem(HAZARD_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    const res = await apiClient.get<HazardZoneAlert[]>('/hazards').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      localStorage.setItem(HAZARD_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Fallback
  }
  localStorage.setItem(HAZARD_STORAGE_KEY, JSON.stringify(INITIAL_HAZARD_ALERTS));
  return INITIAL_HAZARD_ALERTS;
}

export async function updateHazardAlert(
  alertId: string,
  severity: HazardSeverity,
  message: string,
  detourRoute: string
): Promise<HazardZoneAlert[]> {
  const current = await fetchHazardAlerts();
  const updated = current.map((h) => {
    if (h.id !== alertId) return h;
    return {
      ...h,
      severity,
      message,
      detour_route: detourRoute,
      updated_at: new Date().toISOString(),
    };
  });
  localStorage.setItem(HAZARD_STORAGE_KEY, JSON.stringify(updated));

  try {
    await apiClient.put(`/hazards/${alertId}`, {
      severity,
      message,
      detour_route: detourRoute,
    });
  } catch {
    // Offline mode
  }
  return updated;
}

// ============================================================================
// WEB GROUP INVITE & PRIVATE ROOM (FS1-M2-04)
// ============================================================================

export async function fetchGroupRoom(
  groupCode: string
): Promise<GroupRoomPreview | null> {
  const code = groupCode.trim().toUpperCase();
  try {
    const raw = localStorage.getItem(GROUPS_STORAGE_KEY);
    const groups: Record<string, GroupRoomPreview> = raw
      ? JSON.parse(raw)
      : INITIAL_GROUP_ROOMS;

    if (groups[code]) return groups[code];

    const res = await apiClient
      .get<GroupRoomPreview>(`/groups/${code}`)
      .catch(() => null);
    if (res?.data) {
      groups[code] = res.data;
      localStorage.setItem(GROUPS_STORAGE_KEY, JSON.stringify(groups));
      return res.data;
    }

    if (INITIAL_GROUP_ROOMS[code]) return INITIAL_GROUP_ROOMS[code];
    return null;
  } catch {
    return INITIAL_GROUP_ROOMS[code] || null;
  }
}

export async function voteGroupItem(
  groupCode: string,
  itemId: string
): Promise<GroupRoomPreview | null> {
  const code = groupCode.trim().toUpperCase();
  const current = await fetchGroupRoom(code);
  if (!current) return null;

  const updatedVoting = current.voting_items.map((item) => {
    if (item.id !== itemId) return item;
    return {
      ...item,
      votes_count: item.votes_count + 1,
    };
  });

  const updatedGroup: GroupRoomPreview = {
    ...current,
    voting_items: updatedVoting,
  };

  const raw = localStorage.getItem(GROUPS_STORAGE_KEY);
  const groups: Record<string, GroupRoomPreview> = raw
    ? JSON.parse(raw)
    : { ...INITIAL_GROUP_ROOMS };
  groups[code] = updatedGroup;
  localStorage.setItem(GROUPS_STORAGE_KEY, JSON.stringify(groups));

  return updatedGroup;
}

// ============================================================================
// MITRA UMKM NAGARI & ESCROW
// ============================================================================

export async function fetchPartnersCatalog(): Promise<Partner[]> {
  try {
    const raw = localStorage.getItem(PARTNERS_STORAGE_KEY);
    const cached: Partner[] | null = raw ? JSON.parse(raw) : null;
    const res = await apiClient.get<Partner[]>('/partners');
    if (Array.isArray(res.data) && res.data.length > 0) {
      const merged = [...res.data];
      for (const initPtr of INITIAL_PARTNERS) {
        if (!merged.some((p) => p.id === initPtr.id)) {
          merged.push(initPtr);
        }
      }
      localStorage.setItem(PARTNERS_STORAGE_KEY, JSON.stringify(merged));
      return merged;
    }
    return cached || INITIAL_PARTNERS;
  } catch {
    const raw = localStorage.getItem(PARTNERS_STORAGE_KEY);
    if (raw) {
      try {
        return JSON.parse(raw);
      } catch {
        return INITIAL_PARTNERS;
      }
    }
    localStorage.setItem(PARTNERS_STORAGE_KEY, JSON.stringify(INITIAL_PARTNERS));
    return INITIAL_PARTNERS;
  }
}

export async function triggerWAWebhookSimulation(
  action: '1' | '0'
): Promise<WAWebhookResponse> {
  const res = await apiClient.post<WAWebhookResponse>('/bookings/wa-webhook', {
    action,
  });
  return res.data;
}

export async function savePartnerWithBridge(
  partner: Partner,
  currentList: Partner[]
): Promise<{ updatedList: Partner[]; syncedRemote: boolean }> {
  const exists = currentList.some((p) => p.id === partner.id);
  const updatedList = exists
    ? currentList.map((p) => (p.id === partner.id ? partner : p))
    : [partner, ...currentList];

  safeSetLocalStorage(PARTNERS_STORAGE_KEY, JSON.stringify(updatedList));

  try {
    if (exists) {
      await apiClient.put(`/partners/${partner.id}`, partner);
    } else {
      await apiClient.post('/partners', partner);
    }
    return { updatedList, syncedRemote: true };
  } catch {
    return { updatedList, syncedRemote: false };
  }
}

export async function deletePartnerWithBridge(
  partnerId: string,
  currentList: Partner[]
): Promise<{ updatedList: Partner[]; syncedRemote: boolean }> {
  const updatedList = currentList.filter((p) => p.id !== partnerId);
  safeSetLocalStorage(PARTNERS_STORAGE_KEY, JSON.stringify(updatedList));

  try {
    await apiClient.delete(`/partners/${partnerId}`);
    return { updatedList, syncedRemote: true };
  } catch {
    return { updatedList, syncedRemote: false };
  }
}

export async function trackPartnerWaLead(partnerId: string): Promise<Partner | null> {
  const currentPartners = await fetchPartnersCatalog();
  const updatedPartners = currentPartners.map((p) => {
    if (p.id !== partnerId) return p;
    return {
      ...p,
      wa_click_count: (p.wa_click_count || 0) + 1,
    };
  });
  safeSetLocalStorage(PARTNERS_STORAGE_KEY, JSON.stringify(updatedPartners));
  const target = updatedPartners.find((p) => p.id === partnerId) || null;
  return target;
}

// ============================================================================
// SIMULATOR INTERAKSI WA MITRA & CHAT P2P LANGSUNG (MINGGU 3 & REVISI P2P)
// ============================================================================

export async function processWASimulationAction(
  action: '1' | '0' | 'chat',
  partnerIdOrBookingCode: string,
  inquiryMessage?: string
): Promise<{
  action: '1' | '0' | 'chat';
  status: 'CONFIRMED' | 'REJECTED' | 'INQUIRY_SENT';
  message: string;
  wa_chat_url?: string;
  updatedPartner?: Partner;
}> {
  const currentPartners = await fetchPartnersCatalog();
  let targetPartner = currentPartners.find(
    (p) => p.id === partnerIdOrBookingCode || p.name.includes(partnerIdOrBookingCode)
  );

  if (!targetPartner) {
    targetPartner = currentPartners[0] || INITIAL_PARTNERS[0];
  }

  let returnStatus: 'CONFIRMED' | 'REJECTED' | 'INQUIRY_SENT' = 'CONFIRMED';
  let resultMsg = '';
  const waNumber = targetPartner.whatsapp.replace(/\D/g, '');
  const defaultText = `Halo ${targetPartner.name}, saya melihat profil Anda di WISGO 360°. Apakah layanan ini tersedia untuk jadwal kunjungan saya?`;
  const encodedText = encodeURIComponent(inquiryMessage || defaultText);
  const waChatUrl = `https://wa.me/${waNumber}?text=${encodedText}`;

  if (action === '1') {
    returnStatus = 'CONFIRMED';
    resultMsg = `Pesan konfirmasi ketersediaan dan rincian pembayaran langsung (P2P QRIS/Transfer Bank Nagari) berhasil dikirimkan oleh ${targetPartner.name} kepada wisatawan via WhatsApp.`;
  } else if (action === '0') {
    returnStatus = 'REJECTED';
    resultMsg = `Mitra ${targetPartner.name} mengabarkan slot penuh/jadwal bentrok dengan ramah via WhatsApp. Alternatif mitra UMKM nagari sejenis telah disarankan.`;
  } else {
    returnStatus = 'INQUIRY_SENT';
    resultMsg = `Permintaan informasi wisatawan berhasil diteruskan ke chat WhatsApp resmi mitra (+${targetPartner.whatsapp}). Transaksi 100% mandiri (P2P).`;
  }

  // Increment wa_click_count for the partner
  const updatedPartners = currentPartners.map((p) => {
    if (p.id !== targetPartner!.id) return p;
    return {
      ...p,
      wa_click_count: (p.wa_click_count || 0) + 1,
    };
  });

  safeSetLocalStorage(PARTNERS_STORAGE_KEY, JSON.stringify(updatedPartners));

  try {
    await apiClient.post('/bookings/wa-webhook', {
      action,
      partner_id: targetPartner.id,
      inquiry: inquiryMessage,
    });
  } catch {
    // Offline mode
  }

  const updatedTarget = updatedPartners.find((p) => p.id === targetPartner!.id);

  return {
    action,
    status: returnStatus,
    message: resultMsg,
    wa_chat_url: waChatUrl,
    updatedPartner: updatedTarget,
  };
}

// ============================================================================
// ANALITIK EKSEKUTIF, HEATMAP 19 KAB/KOTA & MEJA KURASI (MINGGU 3 & 4)
// ============================================================================

export async function fetchRegencyHeatmap(): Promise<RegencyHeatmapData[]> {
  try {
    const raw = localStorage.getItem(HEATMAP_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    const res = await apiClient.get<RegencyHeatmapData[]>('/analytics/heatmap').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      localStorage.setItem(HEATMAP_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Fallback
  }
  localStorage.setItem(HEATMAP_STORAGE_KEY, JSON.stringify(INITIAL_REGENCY_HEATMAP));
  return INITIAL_REGENCY_HEATMAP;
}

export async function fetchCommunitySubmissions(): Promise<CommunityHiddenGemSubmission[]> {
  try {
    const raw = localStorage.getItem(SUBMISSIONS_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    const res = await apiClient.get<CommunityHiddenGemSubmission[]>('/curation/submissions').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      localStorage.setItem(SUBMISSIONS_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Fallback
  }
  localStorage.setItem(SUBMISSIONS_STORAGE_KEY, JSON.stringify(INITIAL_COMMUNITY_SUBMISSIONS));
  return INITIAL_COMMUNITY_SUBMISSIONS;
}

export async function updateCommunitySubmission(
  submissionId: string,
  updates: Partial<CommunityHiddenGemSubmission>
): Promise<CommunityHiddenGemSubmission[]> {
  const current = await fetchCommunitySubmissions();
  const updated = current.map((sub) => {
    if (sub.id !== submissionId) return sub;
    return { ...sub, ...updates };
  });
  safeSetLocalStorage(SUBMISSIONS_STORAGE_KEY, JSON.stringify(updated));

  try {
    await apiClient.put(`/curation/submissions/${submissionId}`, updates);
  } catch {
    // Offline mode
  }
  return updated;
}

export async function fetchDigitalPassportMetrics(): Promise<DigitalPassportMetrics> {
  try {
    const raw = localStorage.getItem(PASSPORT_METRICS_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed?.total_gps_checkins_verified) return parsed;
    }
    const res = await apiClient.get<DigitalPassportMetrics>('/analytics/passport').catch(() => null);
    if (res?.data?.total_gps_checkins_verified) {
      localStorage.setItem(PASSPORT_METRICS_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Fallback
  }
  localStorage.setItem(PASSPORT_METRICS_KEY, JSON.stringify(INITIAL_DIGITAL_PASSPORT_METRICS));
  return INITIAL_DIGITAL_PASSPORT_METRICS;
}

// ============================================================================
// 1. KAMUS SAKU AUDIO MINANG (USE CASE ADMIN DISPAR)
// ============================================================================

export async function fetchMinangPhrases(): Promise<MinangAudioPhrase[]> {
  try {
    const raw = localStorage.getItem(PHRASES_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    const res = await apiClient.get<MinangAudioPhrase[]>('/culture/phrases').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      safeSetLocalStorage(PHRASES_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Offline mode
  }
  safeSetLocalStorage(PHRASES_STORAGE_KEY, JSON.stringify(INITIAL_MINANG_PHRASES));
  return INITIAL_MINANG_PHRASES;
}

export async function saveMinangPhrase(phrase: MinangAudioPhrase): Promise<MinangAudioPhrase[]> {
  const current = await fetchMinangPhrases();
  const exists = current.some((p) => p.id === phrase.id);
  const updated = exists
    ? current.map((p) => (p.id === phrase.id ? phrase : p))
    : [phrase, ...current];
  safeSetLocalStorage(PHRASES_STORAGE_KEY, JSON.stringify(updated));
  try {
    await apiClient.post('/culture/phrases', phrase);
  } catch {
    // Offline mode
  }
  return updated;
}

export async function deleteMinangPhrase(phraseId: string): Promise<MinangAudioPhrase[]> {
  const current = await fetchMinangPhrases();
  const updated = current.filter((p) => p.id !== phraseId);
  safeSetLocalStorage(PHRASES_STORAGE_KEY, JSON.stringify(updated));
  try {
    await apiClient.delete(`/culture/phrases/${phraseId}`);
  } catch {
    // Offline mode
  }
  return updated;
}

// ============================================================================
// 2. KALENDER BUDAYA SUMATERA BARAT (19 KAB/KOTA)
// ============================================================================

export async function fetchCultureEvents(): Promise<CultureCalendarEvent[]> {
  try {
    const raw = localStorage.getItem(EVENTS_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    const res = await apiClient.get<CultureCalendarEvent[]>('/culture/events').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      safeSetLocalStorage(EVENTS_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Offline mode
  }
  safeSetLocalStorage(EVENTS_STORAGE_KEY, JSON.stringify(INITIAL_CULTURE_EVENTS));
  return INITIAL_CULTURE_EVENTS;
}

export async function saveCultureEvent(event: CultureCalendarEvent): Promise<CultureCalendarEvent[]> {
  const current = await fetchCultureEvents();
  const exists = current.some((e) => e.id === event.id);
  const updated = exists
    ? current.map((e) => (e.id === event.id ? event : e))
    : [event, ...current];
  safeSetLocalStorage(EVENTS_STORAGE_KEY, JSON.stringify(updated));
  try {
    await apiClient.post('/culture/events', event);
  } catch {
    // Offline mode
  }
  return updated;
}

export async function deleteCultureEvent(eventId: string): Promise<CultureCalendarEvent[]> {
  const current = await fetchCultureEvents();
  const updated = current.filter((e) => e.id !== eventId);
  safeSetLocalStorage(EVENTS_STORAGE_KEY, JSON.stringify(updated));
  try {
    await apiClient.delete(`/culture/events/${eventId}`);
  } catch {
    // Offline mode
  }
  return updated;
}

// ============================================================================
// 3. REKALKULASI GAODE RANKING DESTINASI WISATA
// ============================================================================

export const DEFAULT_GAODE_CONFIG: GaodeWeightConfig = {
  satisfaction_weight: 35,
  pungli_free_weight: 30,
  medan_access_weight: 20,
  visit_volume_weight: 15,
};

export async function fetchGaodeConfig(): Promise<GaodeWeightConfig> {
  try {
    const raw = localStorage.getItem(GAODE_CONFIG_KEY);
    if (raw) return JSON.parse(raw);
  } catch {
    // fallback
  }
  return DEFAULT_GAODE_CONFIG;
}

export async function fetchGaodeRankings(): Promise<GaodeRankingItem[]> {
  try {
    const raw = localStorage.getItem(GAODE_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
  } catch {
    // fallback
  }
  safeSetLocalStorage(GAODE_STORAGE_KEY, JSON.stringify(INITIAL_GAODE_RANKINGS));
  return INITIAL_GAODE_RANKINGS;
}

export async function recalculateGaodeRankings(config: GaodeWeightConfig): Promise<GaodeRankingItem[]> {
  const current = await fetchGaodeRankings();
  safeSetLocalStorage(GAODE_CONFIG_KEY, JSON.stringify(config));

  // Hitung ulang skor setiap destinasi berdasarkan formula berbobot
  const recalculated = current.map((item) => {
    // normalisasi komponen ke skala 0 - 100
    const satScore = item.satisfaction_rate; // 0 - 100
    const pungliScore = item.pungli_free_index; // 0 - 100
    const medanScore = (item.medan_score / 5) * 100; // 0 - 100
    // visit score logaritmik (maksimal 15.000 kunjungan)
    const visitScore = Math.min(100, (item.weekly_visits / 12500) * 100);

    const totalWeight =
      config.satisfaction_weight +
      config.pungli_free_weight +
      config.medan_access_weight +
      config.visit_volume_weight || 100;

    const weightedScore =
      (satScore * config.satisfaction_weight +
        pungliScore * config.pungli_free_weight +
        medanScore * config.medan_access_weight +
        visitScore * config.visit_volume_weight) /
      totalWeight;

    // jitter sedikit agar terjadi dinamika pemeringkatan
    const finalScore = Number(weightedScore.toFixed(1));

    return {
      ...item,
      calculated_gaode_score: finalScore,
      previous_rank: item.current_rank,
    };
  });

  // Urutkan menurun berdasarkan skor akhir
  recalculated.sort((a, b) => b.calculated_gaode_score - a.calculated_gaode_score);

  // Perbarui current_rank dan tren
  const finalized = recalculated.map((item, index) => {
    const rank = index + 1;
    let trend: 'up' | 'down' | 'same' = 'same';
    if (rank < item.previous_rank) trend = 'up';
    else if (rank > item.previous_rank) trend = 'down';

    return {
      ...item,
      current_rank: rank,
      trend,
    };
  });

  safeSetLocalStorage(GAODE_STORAGE_KEY, JSON.stringify(finalized));
  return finalized;
}

// ============================================================================
// 4. PANTAU OPEN TRIP / CARI BARENGAN WISATAWAN
// ============================================================================

export async function fetchOpenTrips(): Promise<OpenTripItem[]> {
  try {
    const raw = localStorage.getItem(OPENTRIPS_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed) && parsed.length > 0) return parsed;
    }
    const res = await apiClient.get<OpenTripItem[]>('/trips/open').catch(() => null);
    if (res?.data && Array.isArray(res.data) && res.data.length > 0) {
      safeSetLocalStorage(OPENTRIPS_STORAGE_KEY, JSON.stringify(res.data));
      return res.data;
    }
  } catch {
    // Offline mode
  }
  safeSetLocalStorage(OPENTRIPS_STORAGE_KEY, JSON.stringify(INITIAL_OPEN_TRIPS));
  return INITIAL_OPEN_TRIPS;
}

export async function updateOpenTripStatus(tripId: string, status: OpenTripStatus): Promise<OpenTripItem[]> {
  const current = await fetchOpenTrips();
  const updated = current.map((t) => (t.id === tripId ? { ...t, status } : t));
  safeSetLocalStorage(OPENTRIPS_STORAGE_KEY, JSON.stringify(updated));
  try {
    await apiClient.put(`/trips/open/${tripId}/status`, { status });
  } catch {
    // Offline mode
  }
  return updated;
}

// ============================================================================
// 5. HEALTH & BENCHMARK SISTEM ENDPOINT
// ============================================================================

export async function fetchSystemBenchmark(): Promise<SystemBenchmarkMetrics> {
  try {
    const raw = localStorage.getItem(BENCHMARK_STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed?.backend_version) return parsed;
    }
  } catch {
    // fallback
  }
  safeSetLocalStorage(BENCHMARK_STORAGE_KEY, JSON.stringify(INITIAL_SYSTEM_BENCHMARK));
  return INITIAL_SYSTEM_BENCHMARK;
}

export async function runSystemBenchmark(concurrency: number = 20): Promise<SystemBenchmarkMetrics> {
  const current = await fetchSystemBenchmark();

  // Simulasi pengujian latensi query spasial PostGIS (<100ms) & Go Gin
  const latencyP50 = Math.floor(14 + Math.random() * 8); // 14-22 ms
  const latencyP95 = Math.floor(35 + Math.random() * 15); // 35-50 ms
  const latencyP99 = Math.floor(65 + Math.random() * 20); // 65-85 ms
  const throughput = Math.floor(480 + Math.random() * 150); // 480-630 QPS
  const spatialMs = Math.floor(32 + Math.random() * 25); // 32-57 ms (<100ms)

  const newRun: BenchmarkRunResult = {
    total_requests: 100,
    concurrency,
    latency_p50_ms: latencyP50,
    latency_p95_ms: latencyP95,
    latency_p99_ms: latencyP99,
    error_rate_pct: 0,
    throughput_qps: throughput,
    timestamp: new Date().toISOString(),
  };

  const updated: SystemBenchmarkMetrics = {
    ...current,
    server_status: 'ONLINE',
    go_engine_latency_ms: latencyP50,
    postgres_spatial_query_ms: spatialMs,
    requests_per_second: throughput,
    last_benchmark_time: newRun.timestamp,
    benchmark_history: [newRun, ...(current.benchmark_history || []).slice(0, 4)],
  };

  safeSetLocalStorage(BENCHMARK_STORAGE_KEY, JSON.stringify(updated));
  return updated;
}



