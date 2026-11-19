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
  deletePartnerWithBridge,
  fetchDestinationsWithBridge,
  fetchPartnersCatalog,
  getStoredAdminSession,
  logoutAdminJWT,
  resetDestinationsToDefault,
  saveDestinationWithBridge,
  savePartnerWithBridge,
} from './services/api';
import { INITIAL_PARTNERS, MOCK_20_DESTINATIONS } from './data/mockDestinations';
import { Sidebar, AdminMenuKey } from './components/Sidebar';
import { LoginPage } from './pages/LoginPage';
import { DestinationsPage } from './pages/DestinationsPage';
import { TariffsAndQRPage } from './pages/TariffsAndQRPage';
import { Studio360Page } from './pages/Studio360Page';
import { ChallengePage } from './pages/ChallengePage';
import { CommandCenterPage } from './pages/CommandCenterPage';
import { PartnersPage } from './pages/PartnersPage';
import { PublicSmartQRView } from './pages/PublicSmartQRView';
import { PublicGroupInviteView } from './pages/PublicGroupInviteView';
import { SmartQRPlacardModal } from './components/SmartQRPlacardModal';
import { WhatsAppBotSimulator } from './components/WhatsAppBotSimulator';
import { ExecutiveAnalyticsPage } from './pages/ExecutiveAnalyticsPage';

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

  // Cross-Navigation between Studio 360 & Direktori Mitra UMKM
  const [studioNavTarget, setStudioNavTarget] = useState<{
    destId?: string;
    sceneId?: string;
    pinId?: string;
  } | null>(null);
  const [partnerNavTargetId, setPartnerNavTargetId] = useState<string | null>(
    null
  );

  // Layar Demo Terpadu (Split-Screen Showcase)
  const [isShowcaseMode, setIsShowcaseMode] = useState<boolean>(false);
  const [showcaseRightTab, setShowcaseRightTab] = useState<'wa' | 'qr'>('wa');
  const [analyticsSubTab, setAnalyticsSubTab] = useState<'intel_heatmap' | 'system_benchmark'>('intel_heatmap');

  const [loading, setLoading] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string>('');
  const [toastType, setToastType] = useState<
    'success' | 'info' | 'warning' | 'error'
  >('info');

  const showToast = useCallback(
    (
      msg: string,
      type: 'success' | 'info' | 'warning' | 'error' = 'info'
    ) => {
      setToastMessage(msg);
      setToastType(type);
    },
    []
  );

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

  const handleSavePartner = async (partner: Partner) => {
    const res = await savePartnerWithBridge(partner, partners);
    setPartners(res.updatedList);
  };

  const handleDeletePartner = async (partnerId: string) => {
    const res = await deletePartnerWithBridge(partnerId, partners);
    setPartners(res.updatedList);
  };

  const handleNavigateToStudio360 = (
    destId: string,
    sceneId: string,
    pinId: string
  ) => {
    setStudioNavTarget({ destId, sceneId, pinId });
    setActiveMenu('cms_360');
    showToast(
      'Membuka Studio Virtual 360° dan menyorot titik pin booking mitra.',
      'info'
    );
  };

  const handleNavigateToPartner = (partnerId?: string) => {
    if (partnerId) {
      setPartnerNavTargetId(partnerId);
    }
    setActiveMenu('wa_simulator');
    showToast(
      'Membuka modul Simulator Interaksi WA Mitra (Direct P2P).',
      'info'
    );
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
        allDestinations={destinations}
        onBackToAdmin={() => setPublicPreviewMode(null)}
        showToast={showToast}
      />
    );
  }

  if (publicPreviewMode === 'group') {
    return (
      <PublicGroupInviteView
        groupCode="WISGO-MINANG-88"
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

  const renderMainContent = () => {
    switch (activeMenu) {
      case 'destinations':
        return (
          <DestinationsPage
            destinations={destinations}
            backendOnline={backendOnline}
            loading={loading}
            onRefresh={() => loadSystemData(true)}
            onSaveDestination={handleSaveDestination}
            onDeleteDestination={handleDeleteDestination}
            onOpenTariffManager={handleOpenTariffManager}
            onOpenSmartQRModal={(dest) => setSmartQRModalDest(dest)}
            showToast={showToast}
          />
        );
      case 'tariffs_qr':
        return (
          <TariffsAndQRPage
            destinations={destinations}
            selectedDestinationId={selectedTariffDestId}
            onSelectDestinationId={setSelectedTariffDestId}
            onSaveDestination={handleSaveDestination}
          />
        );
      case 'cms_360':
        return (
          <div className="p-6 lg:p-8">
            <Studio360Page
              destinations={destinations}
              onUpdateDestinations={setDestinations}
              showToast={showToast}
              initialDestId={studioNavTarget?.destId}
              initialSceneId={studioNavTarget?.sceneId}
              initialHighlightPinId={studioNavTarget?.pinId}
              onNavigateToPartner={handleNavigateToPartner}
            />
          </div>
        );
      case 'challenges':
        return (
          <div className="p-6 lg:p-8">
            <ChallengePage
              destinations={destinations}
              showToast={showToast}
            />
          </div>
        );
      case 'command_center':
      case 'saber_pungli':
        return (
          <div className="p-6 lg:p-8">
            <CommandCenterPage
              showToast={showToast}
              onUpdateBadgeCount={(openPungli, openSos) => {
                setOpenPungliCount(openPungli);
                setOpenSosCount(openSos);
              }}
            />
          </div>
        );
      case 'partners':
        return (
          <div className="p-6 lg:p-8">
            <PartnersPage
              partners={partners}
              destinations={destinations}
              onSavePartner={handleSavePartner}
              onDeletePartner={handleDeletePartner}
              onNavigateToStudio360={handleNavigateToStudio360}
              initialSelectedPartnerId={partnerNavTargetId || undefined}
              showToast={showToast}
            />
          </div>
        );
      case 'wa_simulator':
        return (
          <div className="p-6 lg:p-8">
            <WhatsAppBotSimulator
              partners={partners}
              onPartnerUpdated={handleSavePartner}
              showToast={showToast}
            />
          </div>
        );
      case 'dispar_analytics':
        return (
          <div className="p-6 lg:p-8">
            <ExecutiveAnalyticsPage
              destinations={destinations}
              partners={partners}
              showToast={showToast}
              initialSubTab={analyticsSubTab}
            />
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF3E6] text-[#142618] flex flex-col lg:flex-row font-sans">
      <Sidebar
        activeMenu={activeMenu}
        onSelectMenu={(menu) => {
          setActiveMenu(menu);
          if (menu === 'dispar_analytics') {
            setAnalyticsSubTab('intel_heatmap');
          }
        }}
        session={session}
        backendOnline={backendOnline}
        totalDestinations={destinations.length}
        totalTariffs={totalTariffsCount}
        totalPartners={partners.length}
        openPungliCount={openPungliCount}
        openSosCount={openSosCount}
        onOpenPublicQR={() => {
          setPublicPreviewDest(destinations[0] || MOCK_20_DESTINATIONS[0]);
          setPublicPreviewMode('qr');
        }}
        onOpenGroupInvite={() => {
          setPublicPreviewMode('group');
        }}
        onOpenSystemBenchmark={() => {
          setActiveMenu('dispar_analytics');
          setAnalyticsSubTab('system_benchmark');
        }}
        isShowcaseMode={isShowcaseMode}
        onToggleShowcaseMode={() => setIsShowcaseMode((prev) => !prev)}
        onLogout={handleLogout}
      />

      <main className="flex-1 min-w-0 overflow-x-hidden relative flex flex-col">
        {/* Notifikasi Toast Halus */}
        {toastMessage && (
          <div
            role="status"
            aria-live="polite"
            className="no-print fixed bottom-6 right-6 z-50 max-w-md bg-[#193D22] text-[#FAF3E6] px-5 py-3.5 rounded-2xl shadow-xl border border-[#1E9E5A] flex items-center gap-3"
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

        {/* Normal Mode vs Split-Screen Showcase Mode */}
        {!isShowcaseMode ? (
          <div className="flex-1">
            {renderMainContent()}
          </div>
        ) : (
          <div className="flex-1 flex flex-col xl:flex-row">
            {/* Sisi Kiri: Web Admin Utama */}
            <div className="flex-1 min-w-0 border-r border-[#CFD8BE]">
              <div className="bg-[#234B24] text-white px-5 py-2.5 text-xs font-bold flex items-center justify-between no-print">
                <span className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-[#1E9E5A] animate-ping" />
                  <span>SHOWCASE PANEL KIRI: Portal Pusat Komando Web Admin WISGO</span>
                </span>
                <span className="text-[10px] text-[#A7F3D0] uppercase font-mono">
                  Mode Penguji Terpadu
                </span>
              </div>
              {renderMainContent()}
            </div>

            {/* Sisi Kanan: Showcase Live Device (Wisatawan / Bot WA Mitra) */}
            <div className="w-full xl:w-[460px] 2xl:w-[500px] shrink-0 bg-[#EFEAE2] flex flex-col border-t xl:border-t-0 xl:border-l border-[#CFD8BE]">
              {/* Header Showcase Kanan */}
              <div className="bg-[#1B3B1C] text-[#F6F3EC] px-4 py-3 flex items-center justify-between shrink-0 shadow-sm no-print">
                <div className="flex items-center gap-2">
                  <Smartphone className="w-4 h-4 text-[#A7F3D0]" />
                  <span className="text-xs font-bold">Layar HP Pengguna (Live)</span>
                </div>

                <div className="flex items-center gap-1.5">
                  <button
                    type="button"
                    onClick={() => setShowcaseRightTab('wa')}
                    className={`px-2.5 py-1 rounded-lg text-xs font-bold transition ${
                      showcaseRightTab === 'wa'
                        ? 'bg-[#128C7E] text-white shadow-xs'
                        : 'bg-white/10 hover:bg-white/20 text-[#E4E9DA]'
                    }`}
                  >
                    Bot WA Mitra
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowcaseRightTab('qr')}
                    className={`px-2.5 py-1 rounded-lg text-xs font-bold transition ${
                      showcaseRightTab === 'qr'
                        ? 'bg-[#F26B4B] text-white shadow-xs'
                        : 'bg-white/10 hover:bg-white/20 text-[#E4E9DA]'
                    }`}
                  >
                    Smart QR Wisatawan
                  </button>
                  <button
                    type="button"
                    onClick={() => setIsShowcaseMode(false)}
                    className="p-1 rounded-lg hover:bg-white/20 text-white ml-1"
                    title="Tutup Mode Showcase"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Konten Showcase Kanan */}
              <div className="flex-1 overflow-y-auto p-4 flex justify-center">
                {showcaseRightTab === 'wa' ? (
                  <div className="w-full">
                    <WhatsAppBotSimulator
                      partners={partners}
                      onPartnerUpdated={handleSavePartner}
                      showToast={showToast}
                    />
                  </div>
                ) : (
                  <div className="w-full">
                    <PublicSmartQRView
                      destination={destinations[0] || MOCK_20_DESTINATIONS[0]}
                      allDestinations={destinations}
                      showToast={showToast}
                    />
                  </div>
                )}
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
