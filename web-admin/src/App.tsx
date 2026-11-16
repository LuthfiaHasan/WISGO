import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  CheckCircle2,
  X,
  Store,
  ShieldAlert,
  Camera,
  BarChart3,
  ArrowRight,
  RotateCcw,
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

  if (!session) {
    return (
      <LoginPage
        onLoginSuccess={(newSession) => {
          setSession(newSession);
          showToast(
            `Selamat datang, ${newSession.user.full_name}. Sesi otoritas aktif.`
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

        {activeMenu === 'tariffs_qr' && (
          <TariffsAndQRPage
            destinations={destinations}
            selectedDestinationId={selectedTariffDestId}
            onSelectDestinationId={setSelectedTariffDestId}
            onSaveDestination={handleSaveDestination}
          />
        )}

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

        {(activeMenu === 'cms_360' ||
          activeMenu === 'saber_pungli' ||
          activeMenu === 'dispar_analytics') && (
          <div className="p-6 lg:p-8 space-y-6">
            <div className="bg-white rounded-3xl p-8 border border-[#E4E9DA] shadow-sm max-w-3xl">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24] text-xs font-bold">
                {activeMenu === 'cms_360' && (
                  <Camera className="w-3.5 h-3.5" aria-hidden="true" />
                )}
                {activeMenu === 'saber_pungli' && (
                  <ShieldAlert className="w-3.5 h-3.5" aria-hidden="true" />
                )}
                {activeMenu === 'dispar_analytics' && (
                  <BarChart3 className="w-3.5 h-3.5" aria-hidden="true" />
                )}
                <span>MODUL OPERASIONAL TERINTEGRASI</span>
              </div>

              <h2 className="mt-3 text-2xl font-extrabold text-[#1B1F1A]">
                {activeMenu === 'cms_360' &&
                  'Studio Virtual 360° & Kurasi Titik Interaktif'}
                {activeMenu === 'saber_pungli' &&
                  'Pusat Komando Satgas Saber Pungli Pariwisata'}
                {activeMenu === 'dispar_analytics' &&
                  'Dashboard Analitik Eksekutif 19 Kabupaten/Kota'}
              </h2>

              <p className="mt-2 text-sm text-[#4A5248] leading-relaxed">
                Seluruh fondasi data destinasi, pemetaan 5 indikator kesiapan
                medan lapangan, penetapan standar tarif resmi Perda (Fair-Price
                Barometer), dan pencetakan Plang Smart QR telah aktif dan
                tersinkronisasi untuk {destinations.length} destinasi Sumatera
                Barat.
              </p>

              <div className="mt-6 flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() => setActiveMenu('destinations')}
                  className="h-[52px] px-6 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-sm inline-flex items-center gap-2 shadow-sm transition"
                >
                  <span>Buka Manajemen Destinasi &amp; Medan</span>
                  <ArrowRight className="w-4 h-4" aria-hidden="true" />
                </button>

                <button
                  type="button"
                  onClick={() => setActiveMenu('tariffs_qr')}
                  className="h-[52px] px-6 rounded-pill bg-white border border-[#234B24] text-[#234B24] font-bold text-sm inline-flex items-center gap-2 transition"
                >
                  <span>Kelola Standar Tarif Perda &amp; QR</span>
                </button>

                <button
                  type="button"
                  onClick={handleRestoreDefaultData}
                  className="min-h-[48px] px-4 rounded-pill bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#4A5248] hover:text-[#1B1F1A] inline-flex items-center gap-1.5"
                >
                  <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
                  <span>Pulihkan 20 Data Standar</span>
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
