import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  Globe,
  Info,
  Menu,
  X,
  XCircle,
} from 'lucide-react';
import {
  AdminAuthResponse,
  Destination,
} from './types/contract';
import {
  checkBackendHealth,
  deleteDestinationWithBridge,
  fetchDestinationsWithBridge,
  getStoredAdminSession,
  logoutAdminJWT,
  saveDestinationWithBridge,
} from './services/api';
import {
  HazardAlertsRepo,
  OpenTripsRepo,
  PungliReportsRepo,
} from './services/dbRepository';
import { MOCK_20_DESTINATIONS } from './data/mockDestinations';
import { Sidebar, AdminMenuKey } from './components/Sidebar';
import { LoginPage } from './pages/LoginPage';
import { DestinationsPage } from './pages/DestinationsPage';
import { TariffsAndQRPage } from './pages/TariffsAndQRPage';
import { Studio360Page } from './pages/Studio360Page';
import { ChallengePage } from './pages/ChallengePage';
import { CommandCenterPage } from './pages/CommandCenterPage';
import { TripGoPage } from './pages/TripGoPage';
import { PublicSmartQRView } from './pages/PublicSmartQRView';
import { PublicLandingPage } from './pages/PublicLandingPage';
import { SmartQRPlacardModal } from './components/SmartQRPlacardModal';
import { ExecutiveAnalyticsPage } from './pages/ExecutiveAnalyticsPage';

function computeLiveEmergencyBadge(): number {
  const openPungli = PungliReportsRepo.getAll().filter((r) => r.status !== 'Selesai').length;
  const activeHazards = HazardAlertsRepo.getAll().filter(
    (h) => h.severity === 'Siaga' || h.severity === 'Awas Tutup Total'
  ).length;
  return openPungli + activeHazards;
}

export const App: React.FC = () => {
  const [session, setSession] = useState<AdminAuthResponse | null>(() =>
    getStoredAdminSession()
  );
  const [activeMenu, setActiveMenu] = useState<AdminMenuKey>('destinations');
  const [backendOnline, setBackendOnline] = useState<boolean>(false);
  const [destinations, setDestinations] = useState<Destination[]>(MOCK_20_DESTINATIONS);
  const [selectedTariffDestId, setSelectedTariffDestId] = useState<string>('dest-001');
  const [smartQRModalDest, setSmartQRModalDest] = useState<Destination | null>(null);

  const [activeEmergencyCount, setActiveEmergencyCount] = useState<number>(() =>
    computeLiveEmergencyBadge()
  );
  const [tripGoCount, setTripGoCount] = useState<number>(() => OpenTripsRepo.getAll().length);

  const [publicView, setPublicView] = useState<'landing' | 'login' | 'qr' | null>(() => {
    const path = window.location.pathname;
    const hash = window.location.hash;
    if (path.includes('/qr/') || hash.includes('/qr/')) return 'qr';
    if (path.includes('/login') || hash.includes('/login')) return 'login';
    if (path.includes('/admin') || hash.includes('/admin')) return null;
    const stored = getStoredAdminSession();
    return stored ? null : 'landing';
  });
  const [publicPreviewDest, setPublicPreviewDest] = useState<Destination | null>(null);

  const [studioNavTarget] = useState<{
    destId?: string;
    tab?: 'panorama';
  } | null>(null);
  const [analyticsSubTab, setAnalyticsSubTab] = useState<'intel_heatmap' | 'system_benchmark'>(
    'intel_heatmap'
  );
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState<boolean>(false);

  const [loading, setLoading] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string>('');
  const [toastType, setToastType] = useState<'success' | 'info' | 'warning' | 'error'>('info');

  const showToast = useCallback(
    (msg: string, type: 'success' | 'info' | 'warning' | 'error' = 'success') => {
      setToastMessage(msg);
      setToastType(type);
    },
    []
  );

  useEffect(() => {
    if (!toastMessage) return;
    const timer = setTimeout(() => setToastMessage(''), 4500);
    return () => clearTimeout(timer);
  }, [toastMessage]);

  const loadSystemData = useCallback(
    async (notify = false) => {
      setLoading(true);
      try {
        const [health, destResult] = await Promise.all([
          checkBackendHealth(),
          fetchDestinationsWithBridge(),
        ]);
        setBackendOnline(health.online || destResult.online);
        setDestinations(destResult.destinations);
        setActiveEmergencyCount(computeLiveEmergencyBadge());
        setTripGoCount(OpenTripsRepo.getAll().length);
        if (notify) {
          showToast(
            health.online
              ? 'Data berhasil disinkronkan dengan Database Utama WISGO.'
              : 'Data berhasil dimuat ulang dari penyimpanan lokal V3 tersinkronisasi.',
            'info'
          );
        }
      } finally {
        setLoading(false);
      }
    },
    [showToast]
  );

  useEffect(() => {
    loadSystemData(false);
  }, [loadSystemData]);

  useEffect(() => {
    const path = window.location.pathname;
    const hash = window.location.hash;
    if (path.includes('/qr/') || hash.includes('/qr/')) {
      const slug = (path.split('/qr/')[1] || hash.split('/qr/')[1] || '').split('/')[0];
      const match = destinations.find((d) => d.slug === slug || d.id === slug);
      setPublicPreviewDest(match || destinations[0]);
      setPublicView('qr');
    } else if (path.includes('/login') || hash.includes('/login')) {
      setPublicView('login');
    }
  }, [destinations]);

  const handleSaveDestination = async (updated: Destination, message: string) => {
    const res = await saveDestinationWithBridge(updated, destinations);
    setDestinations(res.updatedList);
    setSelectedTariffDestId(updated.id);
    if (res.syncedRemote) setBackendOnline(true);
    showToast(
      res.syncedRemote
        ? `${message} (Tersinkron ke Backend Go)`
        : `${message} (Tersimpan lokal — backend offline)`,
      'success'
    );
  };

  const handleDeleteDestination = async (target: Destination, message: string) => {
    const res = await deleteDestinationWithBridge(target.id, destinations);
    setDestinations(res.updatedList);
    if (selectedTariffDestId === target.id && res.updatedList[0]) {
      setSelectedTariffDestId(res.updatedList[0].id);
    }
    showToast(
      res.syncedRemote
        ? `${message} (Dihapus dari Backend Go)`
        : `${message} (Dihapus lokal — backend offline)`,
      'info'
    );
  };

  const handleOpenTariffManager = (destId: string) => {
    setSelectedTariffDestId(destId);
    setActiveMenu('tariffs_qr');
  };

  const handleLogout = () => {
    logoutAdminJWT();
    setSession(null);
  };

  const totalTariffsCount = useMemo(
    () => destinations.reduce((acc, item) => acc + (item.tariffs?.length || 0), 0),
    [destinations]
  );

  if (publicView === 'landing') {
    return (
      <PublicLandingPage
        destinations={destinations}
        onNavigateToLogin={() => setPublicView('login')}
        onNavigateToQR={(dest) => {
          if (dest) setPublicPreviewDest(dest);
          setPublicView('qr');
        }}
      />
    );
  }

  if (publicView === 'qr') {
    const previewTarget = publicPreviewDest || destinations[0] || MOCK_20_DESTINATIONS[0];
    return (
      <PublicSmartQRView
        destination={previewTarget}
        allDestinations={destinations}
        onBackToAdmin={() => setPublicView(session ? null : 'landing')}
        showToast={showToast}
      />
    );
  }

  if (publicView === 'login' || !session) {
    return (
      <LoginPage
        onLoginSuccess={(newSession) => {
          setSession(newSession);
          setPublicView(null);
          showToast(
            `Selamat datang, ${newSession.user.full_name}. Sesi otoritas tunggal aktif.`,
            'success'
          );
        }}
        onBackToLanding={() => setPublicView('landing')}
        backendOnline={backendOnline}
      />
    );
  }

  const toastStyles: Record<'success' | 'info' | 'warning' | 'error', { bg: string; icon: React.ReactNode }> = {
    success: {
      bg: 'bg-[#234B24] border-[#1E9E5A] text-[#F6F3EC]',
      icon: <CheckCircle2 className="w-5 h-5 text-[#1E9E5A] shrink-0" aria-hidden="true" />,
    },
    info: {
      bg: 'bg-[#1E3A5F] border-[#38BDF8] text-white',
      icon: <Info className="w-5 h-5 text-[#38BDF8] shrink-0" aria-hidden="true" />,
    },
    warning: {
      bg: 'bg-[#78350F] border-[#F59E0B] text-[#FFFBEB]',
      icon: <AlertTriangle className="w-5 h-5 text-[#FBBF24] shrink-0" aria-hidden="true" />,
    },
    error: {
      bg: 'bg-[#7F1D1D] border-[#F26B4B] text-white',
      icon: <XCircle className="w-5 h-5 text-[#FCA5A5] shrink-0" aria-hidden="true" />,
    },
  };

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
              initialTab={studioNavTarget?.tab}
            />
          </div>
        );
      case 'challenges':
        return (
          <div className="p-6 lg:p-8">
            <ChallengePage destinations={destinations} showToast={showToast} />
          </div>
        );
      case 'command_center':
        return (
          <div className="p-6 lg:p-8">
            <CommandCenterPage
              showToast={showToast}
              onUpdateBadgeCount={(openPungli, activeHazardCount) => {
                setActiveEmergencyCount(openPungli + activeHazardCount);
              }}
            />
          </div>
        );
      case 'trip_go':
        return (
          <div className="p-6 lg:p-8">
            <TripGoPage
              destinations={destinations}
              onTripsChanged={() => setTripGoCount(OpenTripsRepo.getAll().length)}
              onShowToast={showToast}
            />
          </div>
        );
      case 'dispar_analytics':
        return (
          <div className="p-6 lg:p-8">
            <ExecutiveAnalyticsPage
              destinations={destinations}
              showToast={showToast}
              initialSubTab={analyticsSubTab}
            />
          </div>
        );
      default:
        return null;
    }
  };

  const activeLabelMap: Record<AdminMenuKey, string> = {
    destinations: 'Destinasi',
    tariffs_qr: 'Tarif & QR',
    cms_360: 'Panorama 360°',
    challenges: 'Challenge',
    command_center: 'Komando SOS',
    trip_go: 'Trip Go',
    dispar_analytics: 'Analitik',
  };

  return (
    <div className="min-h-screen bg-[#F6F3EC] text-[#1B1F1A] flex flex-col lg:flex-row font-sans">
      <Sidebar
        activeMenu={activeMenu}
        onSelectMenu={(menu) => {
          setActiveMenu(menu);
          if (menu === 'dispar_analytics') {
            setAnalyticsSubTab('intel_heatmap');
          }
          setActiveEmergencyCount(computeLiveEmergencyBadge());
        }}
        session={session}
        backendOnline={backendOnline}
        totalDestinations={destinations.length}
        totalTariffs={totalTariffsCount}
        totalTrips={tripGoCount}
        activeEmergencyCount={activeEmergencyCount}
        onOpenLandingPage={() => setPublicView('landing')}
        onOpenPublicQR={() => {
          setPublicPreviewDest(destinations[0] || MOCK_20_DESTINATIONS[0]);
          setPublicView('qr');
        }}
        onLogout={handleLogout}
        isMobileOpen={mobileSidebarOpen}
        onCloseMobile={() => setMobileSidebarOpen(false)}
      />

      <main className="flex-1 min-w-0 overflow-x-hidden relative flex flex-col">
        <header className="no-print sticky top-0 z-30 h-14 bg-[#F6F3EC]/85 backdrop-blur-md border-b border-[#234B24]/10 px-4 lg:px-8 flex items-center justify-between gap-3 shrink-0">
          <div className="flex items-center gap-3 min-w-0">
            <button
              type="button"
              onClick={() => setMobileSidebarOpen(true)}
              className="lg:hidden p-1.5 rounded-lg bg-[#234B24] text-[#F6F3EC] hover:bg-[#1B3B1C] active:scale-95 transition-all"
              aria-label="Buka Menu Navigasi"
            >
              <Menu className="w-4 h-4" />
            </button>
            <div className="flex lg:hidden items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-[#234B24] p-1 flex items-center justify-center shrink-0">
                <img
                  src="/assets/synced/logo_icon.png"
                  alt="WISGO"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = '/logo_icon.png';
                  }}
                  className="w-full h-full object-contain brightness-0 invert"
                />
              </div>
              <span className="font-extrabold text-sm tracking-tight text-[#234B24]">
                WISGO
              </span>
            </div>
            <div className="hidden lg:flex items-center gap-2 text-xs min-w-0">
              <span className="font-semibold text-[#5A655A]">Portal Admin WISGO</span>
              <span className="text-[#234B24]/30">/</span>
              <span className="font-extrabold text-[#234B24] truncate">
                {activeLabelMap[activeMenu]}
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2.5 shrink-0">
            <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/80 border border-[#234B24]/10 text-[11px] font-bold text-[#234B24]">
              <span
                className={`w-1.5 h-1.5 rounded-full ${
                  backendOnline ? 'bg-[#1E9E5A] animate-pulse' : 'bg-[#F59E0B]'
                }`}
              />
              <span>{backendOnline ? 'Backend Live' : 'Sinkron Lokal V3'}</span>
            </span>
            <button
              type="button"
              onClick={() => setPublicView('landing')}
              className="hidden md:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white/80 hover:bg-white border border-[#234B24]/10 text-[11px] font-bold text-[#234B24] transition"
            >
              <Globe className="w-3.5 h-3.5" />
              <span>Beranda Publik</span>
            </button>
            <span className="lg:hidden px-2.5 py-1 rounded-full bg-[#234B24] text-[#F6F3EC] font-bold text-[11px]">
              {activeLabelMap[activeMenu]}
            </span>
          </div>
        </header>

        {toastMessage && (
          <div
            role="status"
            aria-live="polite"
            className={`no-print fixed bottom-6 right-6 z-50 max-w-md px-5 py-3.5 rounded-2xl shadow-xl border flex items-center gap-3 ${toastStyles[toastType].bg}`}
          >
            {toastStyles[toastType].icon}
            <span className="text-xs font-bold leading-snug">{toastMessage}</span>
            <button
              type="button"
              aria-label="Tutup pemberitahuan"
              onClick={() => setToastMessage('')}
              className="ml-2 p-1 rounded-lg hover:bg-white/10 text-current opacity-80 hover:opacity-100"
            >
              <X className="w-4 h-4" aria-hidden="true" />
            </button>
          </div>
        )}

        <div className="flex-1">{renderMainContent()}</div>

        <SmartQRPlacardModal
          destination={smartQRModalDest}
          onClose={() => setSmartQRModalDest(null)}
        />
      </main>
    </div>
  );
};

export default App;
