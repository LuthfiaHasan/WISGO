import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  CheckCircle2,
  X,
  Store,
  BarChart3,
  RotateCcw,
  Compass,
  QrCode,
  Radio,
  Building2,
  TrendingUp,
  MapPin,
  Users,
  ShieldCheck,
  Smartphone,
  ExternalLink,
} from 'lucide-react';
import {
  AdminAuthResponse,
  Destination,
  Partner,
} from './types/contract';
import {
  checkBackendHealth,
  deleteDestinationWithBridge,
  fetchDestinationsWithBridge,
  fetchPartnersCatalog,
  getStoredAdminSession,
  logoutAdminJWT,
  resetDestinationsToDefault,
  saveDestinationWithBridge,
} from './services/api';
import { INITIAL_PARTNERS, MOCK_20_DESTINATIONS } from './data/mockDestinations';
import { Sidebar, AdminMenuKey } from './components/Sidebar';
import { LoginPage } from './pages/LoginPage';
import { DestinationsPage } from './pages/DestinationsPage';
import { TariffsAndQRPage } from './pages/TariffsAndQRPage';
import { Studio360Page } from './pages/Studio360Page';
import { CommandCenterPage } from './pages/CommandCenterPage';
import { PublicSmartQRView } from './pages/PublicSmartQRView';
import { PublicGroupInviteView } from './pages/PublicGroupInviteView';
import { SmartQRPlacardModal } from './components/SmartQRPlacardModal';

export const App: React.FC = () => {
  const [session, setSession] = useState<AdminAuthResponse | null>(() =>
    getStoredAdminSession()
  );
  const [activeMenu, setActiveMenu] = useState<AdminMenuKey>('destinations');
  const [backendOnline, setBackendOnline] = useState<boolean>(false);
  const [destinations, setDestinations] = useState<Destination[]>(
    MOCK_20_DESTINATIONS
  );
  const [partners, setPartners] = useState<Partner[]>(INITIAL_PARTNERS);
  const [selectedTariffDestId, setSelectedTariffDestId] =
    useState<string>('dest-001');
  const [smartQRModalDest, setSmartQRModalDest] =
    useState<Destination | null>(null);

  // Badge alert counts for Pusat Komando
  const [openPungliCount, setOpenPungliCount] = useState<number>(3);
  const [openSosCount, setOpenSosCount] = useState<number>(2);

  // Public Web Preview Mode: null | 'qr' | 'group'
  const [publicPreviewMode, setPublicPreviewMode] = useState<
    'qr' | 'group' | null
  >(null);
  const [publicPreviewDest, setPublicPreviewDest] = useState<Destination | null>(
    null
  );

  const [loading, setLoading] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string>('');

  const showToast = useCallback((msg: string) => {
    setToastMessage(msg);
  }, []);

  useEffect(() => {
    if (!toastMessage) return;
    const timer = setTimeout(() => {
      setToastMessage('');
    }, 4500);
    return () => clearTimeout(timer);
  }, [toastMessage]);

  const loadSystemData = useCallback(async (notify = false) => {
    setLoading(true);
    try {
      const [health, destResult, partnerList] = await Promise.all([
        checkBackendHealth(),
        fetchDestinationsWithBridge(),
        fetchPartnersCatalog(),
      ]);
      setBackendOnline(health.online || destResult.online);
      setDestinations(destResult.destinations);
      setPartners(partnerList);
      if (notify) {
        setToastMessage(
          health.online
            ? 'Data berhasil disinkronkan dengan Database Utama.'
            : 'Data berhasil dimuat dari penyimpanan lokal tersinkronisasi.'
        );
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadSystemData(false);
  }, [loadSystemData]);

  // Check URL pathname or hash for direct public QR or Join link
  useEffect(() => {
    const handleUrlRoute = () => {
      const path = window.location.pathname;
      const hash = window.location.hash;

      if (path.includes('/qr/') || hash.includes('/qr/')) {
        const slug = (path.split('/qr/')[1] || hash.split('/qr/')[1] || '').split('/')[0];
        const match = destinations.find((d) => d.slug === slug || d.id === slug);
        setPublicPreviewDest(match || destinations[0]);
        setPublicPreviewMode('qr');
      } else if (path.includes('/join') || hash.includes('/join')) {
        setPublicPreviewMode('group');
      }
    };
    handleUrlRoute();
  }, [destinations]);

  const handleSaveDestination = async (
    updated: Destination,
    message: string
  ) => {
    const res = await saveDestinationWithBridge(updated, destinations);
    setDestinations(res.updatedList);
    setSelectedTariffDestId(updated.id);
    showToast(message);
  };

  const handleDeleteDestination = async (
    target: Destination,
    message: string
  ) => {
    const res = await deleteDestinationWithBridge(target.id, destinations);
    setDestinations(res.updatedList);
    if (selectedTariffDestId === target.id && res.updatedList[0]) {
      setSelectedTariffDestId(res.updatedList[0].id);
    }
    showToast(message);
  };

  const handleOpenTariffManager = (destId: string) => {
    setSelectedTariffDestId(destId);
    setActiveMenu('tariffs_qr');
  };

  const handleRestoreDefaultData = () => {
    const restored = resetDestinationsToDefault();
    setDestinations(restored);
    showToast(
      'Direktori 20 destinasi unggulan Sumatera Barat berhasil dipulihkan ke standar awal.'
    );
  };

  const handleLogout = () => {
    logoutAdminJWT();
    setSession(null);
  };

  const totalTariffsCount = useMemo(
    () =>
      destinations.reduce((acc, item) => acc + (item.tariffs?.length || 0), 0),
    [destinations]
  );

  // If in Public Web Preview Mode
  if (publicPreviewMode === 'qr') {
    const previewTarget = publicPreviewDest || destinations[0] || MOCK_20_DESTINATIONS[0];
    return (
      <PublicSmartQRView
        destination={previewTarget}
        onBackToAdmin={() => setPublicPreviewMode(null)}
        showToast={showToast}
      />
    );
  }

  if (publicPreviewMode === 'group') {
    return (
      <PublicGroupInviteView
        groupCode="RANCAK-MINANG-88"
        onBackToAdmin={() => setPublicPreviewMode(null)}
        showToast={showToast}
      />
    );
  }

  if (!session) {
    return (
      <LoginPage
        onLoginSuccess={(newSession) => {
          setSession(newSession);
          showToast(
            `Selamat datang, ${newSession.user.full_name}. Sesi otoritas tunggal aktif.`
          );
        }}
        backendOnline={backendOnline}
      />
    );
  }

  return (
    <div className="min-h-screen bg-[#F6F3EC] text-[#1B1F1A] flex flex-col lg:flex-row">
      <Sidebar
        activeMenu={activeMenu}
        onSelectMenu={setActiveMenu}
        session={session}
        backendOnline={backendOnline}
        totalDestinations={destinations.length}
        totalTariffs={totalTariffsCount}
        openPungliCount={openPungliCount}
        openSosCount={openSosCount}
        onOpenPublicQR={() => {
          setPublicPreviewDest(destinations[0] || MOCK_20_DESTINATIONS[0]);
          setPublicPreviewMode('qr');
        }}
        onOpenGroupInvite={() => {
          setPublicPreviewMode('group');
        }}
        onLogout={handleLogout}
      />

      <main className="flex-1 min-w-0 overflow-x-hidden relative">
        {/* Notifikasi Toast Halus */}
        {toastMessage && (
          <div
            role="status"
            aria-live="polite"
            className="no-print fixed bottom-6 right-6 z-40 max-w-md bg-[#234B24] text-[#F6F3EC] px-5 py-3.5 rounded-2xl shadow-xl border border-[#1E9E5A] flex items-center gap-3"
          >
            <CheckCircle2
              className="w-5 h-5 text-[#1E9E5A] shrink-0"
              aria-hidden="true"
            />
            <span className="text-xs font-bold leading-snug">
              {toastMessage}
            </span>
            <button
              type="button"
              aria-label="Tutup pemberitahuan"
              onClick={() => setToastMessage('')}
              className="ml-2 p-1 rounded-lg hover:bg-white/10 text-[#E4E9DA]"
            >
              <X className="w-4 h-4" aria-hidden="true" />
            </button>
          </div>
        )}

        {/* 1. Manajemen Destinasi & Medan */}
        {activeMenu === 'destinations' && (
          <DestinationsPage
            destinations={destinations}
            backendOnline={backendOnline}
            loading={loading}
            onRefresh={() => loadSystemData(true)}
            onSaveDestination={handleSaveDestination}
            onDeleteDestination={handleDeleteDestination}
            onOpenTariffManager={handleOpenTariffManager}
            onOpenSmartQRModal={(dest) => setSmartQRModalDest(dest)}
          />
        )}

        {/* 2. Standar Tarif Perda & QR */}
        {activeMenu === 'tariffs_qr' && (
          <TariffsAndQRPage
            destinations={destinations}
            selectedDestinationId={selectedTariffDestId}
            onSelectDestinationId={setSelectedTariffDestId}
            onSaveDestination={handleSaveDestination}
          />
        )}

        {/* 3. Studio Virtual 360° (FS1-M2-02) */}
        {activeMenu === 'cms_360' && (
          <div className="p-6 lg:p-8">
            <Studio360Page
              destinations={destinations}
              onUpdateDestinations={setDestinations}
              showToast={showToast}
            />
          </div>
        )}

        {/* 4. Pusat Komando Pungli & SOS SAR (FS1-M2-03) */}
        {(activeMenu === 'command_center' || activeMenu === 'saber_pungli') && (
          <div className="p-6 lg:p-8">
            <CommandCenterPage
              showToast={showToast}
              onUpdateBadgeCount={(openPungli, openSos) => {
                setOpenPungliCount(openPungli);
                setOpenSosCount(openSos);
              }}
            />
          </div>
        )}

        {/* 5. Monitoring Mitra & Escrow */}
        {activeMenu === 'wa_simulator' && (
          <div className="p-6 lg:p-8 space-y-6">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24] text-xs font-bold">
                  <Store className="w-3.5 h-3.5 text-[#1E9E5A]" aria-hidden="true" />
                  <span>DIREKTORI MITRA UMKM NAGARI &amp; REKENING BERSAMA</span>
                </div>
                <h1 className="mt-2 text-2xl lg:text-3xl font-extrabold text-[#1B1F1A]">
                  Monitoring 5 Kategori Mitra Nagari &amp; Escrow
                </h1>
                <p className="text-sm text-[#4A5248]">
                  Daftar mitra terverifikasi Pokdarwis dan Nagari yang terhubung
                  dengan layanan konfirmasi WhatsApp dan pencairan QR E-Ticket.
                </p>
              </div>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
              {partners.map((ptr) => (
                <div
                  key={ptr.id}
                  className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                        {ptr.category}
                      </span>
                      {ptr.is_verified && (
                        <span className="text-[11px] font-bold text-[#1E9E5A] flex items-center gap-1">
                          <CheckCircle2 className="w-3.5 h-3.5" aria-hidden="true" />
                          Terverifikasi Nagari
                        </span>
                      )}
                    </div>
                    <h2 className="mt-2.5 text-base font-extrabold text-[#1B1F1A]">
                      {ptr.name}
                    </h2>
                    <p className="text-xs text-[#4A5248] mt-0.5">
                      {ptr.nagari_name}
                    </p>
                  </div>

                  <div className="mt-4 pt-3 border-t border-[#E4E9DA] flex items-center justify-between text-xs">
                    <span className="text-[#4A5248]">
                      WhatsApp: <strong>+{ptr.whatsapp}</strong>
                    </span>
                    <span className="font-extrabold text-[#234B24]">
                      Rp {ptr.standard_fee.toLocaleString('id-ID')}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 6. Analitik Eksekutif Dispar */}
        {activeMenu === 'dispar_analytics' && (
          <div className="p-6 lg:p-8 space-y-6">
            <header className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA]">
              <div className="flex items-center gap-3.5">
                <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm shrink-0">
                  <BarChart3 className="w-6 h-6" aria-hidden="true" />
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                      Analitik Eksekutif Dinas Pariwisata Sumbar
                    </h1>
                    <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                      19 Kabupaten/Kota
                    </span>
                  </div>
                  <p className="text-xs text-[#4A5248] mt-1">
                    Pemantauan persebaran {destinations.length} destinasi unggulan, kepatuhan tarif resmi Perda, zona blank spot, dan dampak ekonomi UMKM Nagari.
                  </p>
                </div>
              </div>
            </header>

            {/* Statistik Eksekutif */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
                <span className="text-xs font-bold text-[#4A5248]">Total Destinasi Terdata</span>
                <div className="mt-2 text-3xl font-extrabold text-[#234B24]">
                  {destinations.length}
                </div>
                <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
                  100% Terpetakan 5 Medan
                </p>
              </div>

              <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
                <span className="text-xs font-bold text-[#4A5248]">Item Tarif Resmi Perda</span>
                <div className="mt-2 text-3xl font-extrabold text-[#234B24]">
                  {totalTariffsCount}
                </div>
                <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
                  Tercakup Fair-Price Barometer
                </p>
              </div>

              <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
                <span className="text-xs font-bold text-[#4A5248]">Kawasan Blank Spot</span>
                <div className="mt-2 text-3xl font-extrabold text-[#F26B4B]">
                  {destinations.filter((d) => d.is_blank_spot).length}
                </div>
                <p className="text-[11px] text-[#4A5248] mt-1">
                  Wajib Offline Pocket
                </p>
              </div>

              <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
                <span className="text-xs font-bold text-[#4A5248]">Mitra UMKM Nagari</span>
                <div className="mt-2 text-3xl font-extrabold text-[#234B24]">
                  {partners.length}
                </div>
                <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
                  100% Terverifikasi Nagari
                </p>
              </div>
            </div>

            {/* Quick Actions Card */}
            <div className="bg-white rounded-[24px] p-6 shadow-sm border border-[#E4E9DA] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
              <div>
                <h3 className="text-base font-extrabold text-[#1B1F1A]">
                  Pratinjau Pengalaman Wisatawan di Lapangan
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Buka tampilan web publik yang diakses turis saat memindai Plang Smart QR atau membuka tautan rombongan.
                </p>
              </div>
              <div className="flex flex-wrap items-center gap-2.5">
                <button
                  type="button"
                  onClick={() => {
                    setPublicPreviewDest(destinations[0]);
                    setPublicPreviewMode('qr');
                  }}
                  className="min-h-[44px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 transition"
                >
                  <QrCode className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
                  <span>Pratinjau Web Smart QR</span>
                </button>
                <button
                  type="button"
                  onClick={() => setPublicPreviewMode('group')}
                  className="min-h-[44px] px-4 py-2 rounded-xl bg-[#E4E9DA] hover:bg-[#D5DFC9] text-[#234B24] text-xs font-bold flex items-center gap-2 transition"
                >
                  <Users className="w-4 h-4" aria-hidden="true" />
                  <span>Pratinjau Web Group Invite</span>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal Pratinjau & Cetak Plang Smart QR */}
        <SmartQRPlacardModal
          destination={smartQRModalDest}
          onClose={() => setSmartQRModalDest(null)}
        />
      </main>
    </div>
  );
};

export default App;
