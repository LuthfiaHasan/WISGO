import axios from 'axios';
import {
  AdminAuthCredentials,
  AdminAuthResponse,
  CommunityHiddenGemSubmission,
  Destination,
  DigitalPassportMetrics,
  EscrowTransaction,
  GroupRoomPreview,
  HazardSeverity,
  HazardZoneAlert,
  HotspotPin,
  PanoramaScene,
  Partner,
  PungliReport,
  PungliStatus,
  RegencyHeatmapData,
  SosEmergencyStatus,
  SosEmergencyTicket,
  WAWebhookResponse,
} from '../types/contract';
import {
  INITIAL_COMMUNITY_SUBMISSIONS,
  INITIAL_DIGITAL_PASSPORT_METRICS,
  INITIAL_GROUP_ROOMS,
  INITIAL_HAZARD_ALERTS,
  INITIAL_PARTNERS,
  INITIAL_PUNGLI_REPORTS,
  INITIAL_REGENCY_HEATMAP,
  INITIAL_SOS_TICKETS,
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

// ============================================================================
// SIMULATOR BOT WHATSAPP MITRA & PENCAIRAN ESCROW (MINGGU 3)
// ============================================================================

export async function processWASimulationAction(
  action: '1' | '0' | 'scan',
  bookingCode: string
): Promise<{
  action: '1' | '0' | 'scan';
  status: 'CONFIRMED' | 'REJECTED' | 'REDEEMED';
  message: string;
  qr_code_ticket?: string;
  updatedPartner?: Partner;
}> {
  const currentPartners = await fetchPartnersCatalog();
  let targetPartner: Partner | null = null;
  let targetTx: EscrowTransaction | null = null;

  for (const p of currentPartners) {
    const tx = p.ledger?.find((t) => t.booking_code === bookingCode);
    if (tx) {
      targetPartner = p;
      targetTx = tx;
      break;
    }
  }

  // Jika tidak ditemukan di ledger, buat simulasi transaksi dinamis
  if (!targetPartner) {
    targetPartner = currentPartners[0] || INITIAL_PARTNERS[0];
  }

  let newStatus: 'ESCROW_LOCKED' | 'READY_PAYOUT' | 'REDEEMED' = 'ESCROW_LOCKED';
  let waStatus: 'CONFIRMED' | 'PENDING' | 'REJECTED' = 'CONFIRMED';
  let returnStatus: 'CONFIRMED' | 'REJECTED' | 'REDEEMED' = 'CONFIRMED';
  let resultMsg = '';
  const qrTicket = `QR-WISGO-ETIKET-${bookingCode}`;

  if (action === '1') {
    newStatus = 'ESCROW_LOCKED';
    waStatus = 'CONFIRMED';
    returnStatus = 'CONFIRMED';
    resultMsg = `Pesanan ${bookingCode} telah DITERIMA oleh ${targetPartner.name}. E-Ticket QR diterbitkan untuk wisatawan dan dana Rp ${(targetTx?.amount || 50000).toLocaleString('id-ID')} terkunci di Rekening Escrow WISGO.`;
  } else if (action === '0') {
    newStatus = 'REDEEMED';
    waStatus = 'REJECTED';
    returnStatus = 'REJECTED';
    resultMsg = `Pesanan ${bookingCode} DITOLAK oleh ${targetPartner.name}. Dana simulasi telah dikembalikan 100% ke saldo wisatawan.`;
  } else if (action === 'scan') {
    newStatus = 'REDEEMED';
    waStatus = 'CONFIRMED';
    returnStatus = 'REDEEMED';
    resultMsg = `QR E-Ticket ${bookingCode} berhasil dipindai di lokasi! Wisatawan telah tiba dan dana Rp ${(targetTx?.amount || 50000).toLocaleString('id-ID')} sukses DICAIRKAN ke rekening mitra nagari ${targetPartner.name}.`;
  }

  // Update transaction status in partner ledger
  const updatedPartners = currentPartners.map((p) => {
    if (p.id !== targetPartner!.id) return p;
    const ledger = p.ledger?.map((tx) => {
      if (tx.booking_code === bookingCode) {
        return {
          ...tx,
          status: newStatus,
          wa_status: waStatus,
        };
      }
      return tx;
    }) || [];
    return { ...p, ledger };
  });

  safeSetLocalStorage(PARTNERS_STORAGE_KEY, JSON.stringify(updatedPartners));

  try {
    await apiClient.post('/bookings/wa-webhook', {
      action: action === 'scan' ? '1' : action,
      booking_code: bookingCode,
    });
  } catch {
    // Offline mode
  }

  const updatedTarget = updatedPartners.find((p) => p.id === targetPartner!.id);

  return {
    action,
    status: returnStatus,
    message: resultMsg,
    qr_code_ticket: qrTicket,
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


