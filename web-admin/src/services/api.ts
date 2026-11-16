import axios from 'axios';
import {
  AdminAuthCredentials,
  AdminAuthResponse,
  Destination,
  Partner,
  WAWebhookResponse,
} from '../types/contract';
import {
  INITIAL_PARTNERS,
  MOCK_20_DESTINATIONS,
  toDestinationSlug,
} from '../data/mockDestinations';

const TOKEN_STORAGE_KEY = 'rancakin_admin_jwt';
const USER_STORAGE_KEY = 'rancakin_admin_user';
const DESTINATIONS_STORAGE_KEY = 'rancakin_dispar_destinations_v2';
const PARTNERS_STORAGE_KEY = 'rancakin_dispar_partners_v2';

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
    const raw = localStorage.getItem(DESTINATIONS_STORAGE_KEY);
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
  try {
    localStorage.setItem(DESTINATIONS_STORAGE_KEY, JSON.stringify(destinations));
  } catch {
    // Ignore storage quota errors
  }
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
 * Otentikasi Portal Eksekutif Dispar / Satgas Saber Pungli (JWT Auth)
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

  const isSatgas =
    emailLower.includes('satgas') || credentials.role === 'satgas_pungli';
  const jwtToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
    btoa(
      JSON.stringify({
        sub: isSatgas ? 'usr-satgas-01' : 'usr-dispar-01',
        email: emailLower,
        role: isSatgas ? 'satgas_pungli' : 'admin_dispar',
        iat: Math.floor(Date.now() / 1000),
      })
    ) +
    '.rancakin-sumbar-sig-2026';

  const authResponse: AdminAuthResponse = {
    token: jwtToken,
    expires_at: new Date(Date.now() + 8 * 3600 * 1000).toISOString(),
    user: {
      id: isSatgas ? 'usr-satgas-01' : 'usr-dispar-01',
      phone_number: '6281166002026',
      full_name: isSatgas
        ? 'Komandan Satgas Saber Pungli Sumbar'
        : 'Kepala Dinas Pariwisata Prov. Sumatera Barat',
      role: isSatgas ? 'satgas_pungli' : 'admin_dispar',
      email: emailLower,
      agency: isSatgas
        ? 'Satgas Saber Pungli Pariwisata Sumatera Barat'
        : 'Dinas Pariwisata Provinsi Sumatera Barat',
      created_at: new Date().toISOString(),
    },
  };

  localStorage.setItem(TOKEN_STORAGE_KEY, authResponse.token);
  localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(authResponse.user));
  return authResponse;
}

export function getStoredAdminSession(): AdminAuthResponse | null {
  const token = localStorage.getItem(TOKEN_STORAGE_KEY);
  const rawUser = localStorage.getItem(USER_STORAGE_KEY);
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

/**
 * Ambil katalog 5 kategori Mitra UMKM Nagari dengan persistensi localStorage
 */
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

/**
 * Simulasi Webhook Bot WA Mitra (1 Terima / 0 Tolak)
 */
export async function triggerWAWebhookSimulation(
  action: '1' | '0'
): Promise<WAWebhookResponse> {
  const res = await apiClient.post<WAWebhookResponse>('/bookings/wa-webhook', {
    action,
  });
  return res.data;
}
