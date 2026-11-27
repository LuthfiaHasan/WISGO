import React, { useEffect, useId, useMemo, useState } from 'react';
import {
  ShieldAlert,
  LifeBuoy,
  Compass,
  MapPin,
  CheckCircle2,
  QrCode,
  ChevronLeft,
  Send,
  Phone,
  DollarSign,
  Info,
  CloudSun,
  Droplets,
  Wind,
  PhoneCall,
} from 'lucide-react';
import { Destination } from '../types/contract';
import { resolveSmartQRWithBridge, submitPungliReport } from '../services/api';
import { EmergencyContactsRepo, SosSignalsRepo } from '../services/dbRepository';
import { TOLL_FREE_EMERGENCY_NUMBERS } from '../data/mockDestinations';
import { ImageDropzone } from '../components/ImageDropzone';

type PublicPungliCategory =
  | 'Parkir Liar'
  | 'Tiket Di Atas Perda'
  | 'Pemaksaan Pemandu/Kapal'
  | 'Fasilitas Rusak';

interface PublicSmartQRViewProps {
  destination: Destination;
  allDestinations?: Destination[];
  onBackToAdmin?: () => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const PublicSmartQRView: React.FC<PublicSmartQRViewProps> = ({
  destination,
  allDestinations,
  onBackToAdmin,
  showToast,
}) => {
  const [currentDest, setCurrentDest] = useState<Destination>(destination);
  const [qrSyncedLive, setQrSyncedLive] = useState<boolean>(false);

  useEffect(() => {
    setCurrentDest(destination);
  }, [destination]);

  useEffect(() => {
    let active = true;
    const key = currentDest.qr_placard_code || currentDest.slug || currentDest.id;
    resolveSmartQRWithBridge(key).then((res) => {
      if (!active) return;
      setQrSyncedLive(res.online);
      if (res.online && res.destination) {
        setCurrentDest(res.destination);
      }
    });
    return () => {
      active = false;
    };
  }, [currentDest.id, currentDest.qr_placard_code, currentDest.slug]);

  const reporterNameId = useId();
  const reporterPhoneId = useId();
  const reporterCatId = useId();
  const reporterAmountId = useId();
  const reporterDescId = useId();
  const sosNameId = useId();
  const sosPhoneId = useId();
  const sosNotesId = useId();

  const [activeSection, setActiveSection] = useState<'tariffs' | 'medan' | 'report' | 'sos'>(
    'tariffs'
  );

  // Pungli Report State
  const [reportName, setReportName] = useState('');
  const [reportPhone, setReportPhone] = useState('');
  const [reportCategory, setReportCategory] = useState<PublicPungliCategory>('Parkir Liar');
  const [reportAmount, setReportAmount] = useState<number>(20000);
  const [reportDesc, setReportDesc] = useState('');
  const [reportPhoto, setReportPhoto] = useState<string>('');
  const [submittingReport, setSubmittingReport] = useState(false);
  const [reportSuccess, setReportSuccess] = useState(false);

  // SOS Log State
  const [sosName, setSosName] = useState('');
  const [sosPhone, setSosPhone] = useState('');
  const [sosNotes, setSosNotes] = useState('');
  const [submittingSos, setSubmittingSos] = useState(false);
  const [sosSuccess, setSosSuccess] = useState(false);

  const emergencyContacts = useMemo(
    () => EmergencyContactsRepo.getAll().filter((c) => c.is_active),
    []
  );

  const handleSubmitReport = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reportName.trim() || !reportPhone.trim()) {
      showToast('Nama dan nomor kontak WhatsApp wajib diisi.', 'warning');
      return;
    }

    setSubmittingReport(true);
    try {
      const matchedTariff = currentDest.tariffs?.find((t) =>
        (t.category || '').toLowerCase().includes(reportCategory.toLowerCase().slice(0, 4))
      );
      const officialAmt = matchedTariff ? matchedTariff.price : 5000;

      await submitPungliReport({
        ticket_code: `PGL-${Date.now().toString().slice(-6)}`,
        user_id: 'usr-tourist-qr',
        destination_id: currentDest.id,
        destination_name: currentDest.name,
        kab_kota: currentDest.city_regency,
        tariff_id: matchedTariff?.id || null,
        report_type: reportCategory === 'Fasilitas Rusak' ? 'fasilitas' : 'pungli',
        incident_category: reportCategory,
        charged_amount_idr: reportAmount,
        official_perda_price_idr: officialAmt,
        overcharge_amount_idr: Math.max(0, reportAmount - officialAmt),
        photo_evidence:
          reportPhoto ||
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
        latitude: currentDest.latitude,
        longitude: currentDest.longitude,
        incident_geog: `SRID=4326;POINT(${currentDest.longitude} ${currentDest.latitude})`,
        reporter_name: reportName.trim(),
        reporter_phone: reportPhone.trim(),
        description:
          reportDesc.trim() || 'Laporan pungutan tidak sesuai Perda di lokasi destinasi.',
        status: 'Masuk',
        verified_by_admin_id: null,
        admin_action_notes: null,
      });

      setReportSuccess(true);
      showToast(
        'Laporan aduan berhasil dikirim langsung ke Pusat Komando Saber Pungli.',
        'success'
      );
    } catch {
      showToast('Gagal mengirim aduan.', 'error');
    } finally {
      setSubmittingReport(false);
    }
  };

  const handleSubmitSos = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sosName.trim() || !sosPhone.trim()) {
      showToast('Nama dan nomor darurat wajib diisi.', 'warning');
      return;
    }

    setSubmittingSos(true);
    try {
      SosSignalsRepo.save({
        id: `sos-${Date.now().toString(36)}`,
        sos_code: `SOS-${Date.now().toString().slice(-6)}`,
        tourist_name: sosName.trim(),
        phone_number: sosPhone.trim(),
        emergency_type: 'Evakuasi & Bantuan Lapangan',
        destination_name: currentDest.name,
        city_regency: currentDest.city_regency,
        latitude: currentDest.latitude,
        longitude: currentDest.longitude,
        battery_percent: 65,
        passengers_count: 1,
        nearest_corridor: 'SITINJAU-LAUIK',
        nearest_rescue_post: `Posko Siaga BPBD ${currentDest.city_regency}`,
        distance_to_rescue_km: 3.2,
        eta_rescue_minutes: 15,
        status: 'Dipancarkan',
        notes: sosNotes.trim() || 'Permintaan bantuan darurat dari halaman Smart QR destinasi.',
        created_at: new Date().toISOString(),
      });

      setSosSuccess(true);
      showToast(
        'Log Sinyal Darurat SOS GPS tercatat ke Pusat Komando & Posko SAR terdekat!',
        'success'
      );
    } catch {
      showToast('Gagal mengirim sinyal darurat SOS.', 'error');
    } finally {
      setSubmittingSos(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F6F3EC] text-[#1B1F1A] flex flex-col items-center justify-start pb-12">
      {onBackToAdmin && (
        <div className="w-full bg-[#234B24] text-[#F6F3EC] px-4 py-2.5 flex flex-wrap items-center justify-between gap-3 shadow-sm sticky top-0 z-40">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onBackToAdmin}
              className="flex items-center gap-1.5 text-xs font-bold text-[#A7F3D0] hover:text-white"
            >
              <ChevronLeft className="w-4 h-4" aria-hidden="true" />
              <span>Kembali ke Portal WISGO</span>
            </button>
            <span className="text-[11px] font-mono text-[#E4E9DA]/80 hidden md:inline">
              /qr/{currentDest.slug || 'destinasi'}
            </span>
          </div>

          {allDestinations && allDestinations.length > 0 && (
            <div className="flex items-center gap-2">
              <label
                htmlFor="qr-dest-select"
                className="text-xs text-[#A7F3D0] font-bold whitespace-nowrap"
              >
                Pilih Destinasi ({allDestinations.length} Lokasi):
              </label>
              <select
                id="qr-dest-select"
                value={currentDest.id}
                onChange={(e) => {
                  const found = allDestinations.find((d) => d.id === e.target.value);
                  if (found) setCurrentDest(found);
                }}
                className="px-3 py-1.5 rounded-xl bg-black/30 border border-white/20 text-xs font-bold text-[#F6F3EC]"
              >
                {allDestinations.map((d) => (
                  <option key={d.id} value={d.id} className="bg-[#234B24] text-white">
                    {d.name} ({d.city_regency})
                  </option>
                ))}
              </select>
            </div>
          )}
        </div>
      )}

      <main className="w-full max-w-md bg-white shadow-xl min-h-screen border-x border-[#D5E2D7] flex flex-col font-sans">
        <header className="bg-[#193D22] text-[#FAF3E6] p-5 relative overflow-hidden">
          <div className="flex items-center justify-between mb-3">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 border border-white/15 text-[10px] font-bold text-[#A7F3D0]">
              <img src="/logo_icon.png" alt="WISGO" className="w-3.5 h-3.5 object-contain" />
              <span>PEMPROV SUMBAR · WISGO</span>
            </div>
            <span className="text-[10px] font-mono text-[#DFECE2]/90 flex items-center gap-1">
              <QrCode className="w-3.5 h-3.5 text-[#E65F2B]" />
              <span>{currentDest.qr_placard_code || 'Smart QR Resmi'}</span>
              {qrSyncedLive && (
                <span className="ml-1 px-1.5 py-0.5 rounded bg-[#1E9E5A] text-white text-[9px] font-bold">
                  LIVE
                </span>
              )}
            </span>
          </div>

          <h1 className="text-xl font-extrabold leading-tight tracking-tight">
            {currentDest.name}
          </h1>
          <p className="text-xs text-[#E4E9DA]/90 flex items-center gap-1 mt-1">
            <MapPin className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" />
            <span>
              {currentDest.city_regency} · {currentDest.category}
            </span>
          </p>

          {/* Barometer Badges: Tarif + Cuaca Live Open-Meteo */}
          <div className="mt-4 flex flex-wrap items-center gap-2">
            <span className="px-2.5 py-1 rounded-lg bg-black/20 text-[11px] font-bold text-white border border-white/10">
              Tiket: {currentDest.ticket_price_summary || `Rp ${currentDest.estimated_cost.toLocaleString('id-ID')}`}
            </span>
            {currentDest.weather && (
              <span className="px-2.5 py-1 rounded-lg bg-white/15 text-[11px] font-bold text-[#A7F3D0] inline-flex items-center gap-1">
                <CloudSun className="w-3.5 h-3.5" />
                <span>
                  {currentDest.weather.temperature_c}°C · {currentDest.weather.condition}
                </span>
              </span>
            )}
          </div>
        </header>

        <div className="w-full aspect-[16/9] bg-black/10 overflow-hidden relative">
          <img
            src={currentDest.cover_image}
            alt={currentDest.name}
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex items-end p-4">
            <p className="text-xs text-white/95 line-clamp-2 leading-relaxed">
              {currentDest.description}
            </p>
          </div>
        </div>

        <nav
          aria-label="Navigasi Halaman Smart QR"
          className="grid grid-cols-4 bg-[#F6F3EC] border-b border-[#CFD8BE] text-xs font-bold text-center"
        >
          <button
            type="button"
            onClick={() => setActiveSection('tariffs')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'tariffs'
                ? 'border-[#234B24] text-[#234B24] bg-white font-extrabold'
                : 'border-transparent text-[#4A5248]'
            }`}
          >
            Tarif Perda
          </button>
          <button
            type="button"
            onClick={() => setActiveSection('medan')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'medan'
                ? 'border-[#234B24] text-[#234B24] bg-white font-extrabold'
                : 'border-transparent text-[#4A5248]'
            }`}
          >
            Medan
          </button>
          <button
            type="button"
            onClick={() => setActiveSection('report')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'report'
                ? 'border-[#F26B4B] text-[#D95637] bg-white font-extrabold'
                : 'border-transparent text-[#4A5248]'
            }`}
          >
            Lapor Pungli
          </button>
          <button
            type="button"
            onClick={() => setActiveSection('sos')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'sos'
                ? 'border-[#D95637] text-[#D95637] bg-[#F26B4B]/10 font-extrabold'
                : 'border-transparent text-[#D95637]'
            }`}
          >
            Darurat SOS
          </button>
        </nav>

        <div className="p-5 flex-1 space-y-5">
          {/* TAB 1: TARIF PERDA & TIPS MENJAGA TEMPAT INI */}
          {activeSection === 'tariffs' && (
            <div className="space-y-4">
              <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-1.5">
                <DollarSign className="w-4 h-4 text-[#234B24]" />
                <span>Fair-Price Barometer (Standar Tarif Perda)</span>
              </h2>
              <p className="text-[11px] text-[#4A5248] leading-relaxed">
                Tarif resmi berlandaskan Peraturan Daerah / SK Nagari. Jangan membayar melebihi rentang harga wajar di bawah ini.
              </p>

              <div className="space-y-2.5">
                {currentDest.tariffs && currentDest.tariffs.length > 0 ? (
                  currentDest.tariffs.map((t) => (
                    <div
                      key={t.id}
                      className="p-3.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-start justify-between gap-2"
                    >
                      <div>
                        <div className="text-[10px] font-bold text-[#234B24] uppercase tracking-wider">
                          {t.category}
                        </div>
                        <div className="text-xs font-extrabold text-[#1B1F1A] mt-0.5">
                          {t.item_name}
                        </div>
                        <div className="text-[10px] text-[#767676] mt-0.5">
                          {t.regulation_ref || 'Perda Resmi Sumbar'}
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-xs font-extrabold text-[#234B24]">
                          Rp {t.price.toLocaleString('id-ID')}
                        </div>
                        <div className="text-[10px] text-[#4A5248]">{t.unit}</div>
                        {t.fair_price_max && t.fair_price_max > t.price && (
                          <div className="text-[9px] text-[#D95637] font-semibold">
                            Wajar maks: Rp {t.fair_price_max.toLocaleString('id-ID')}
                          </div>
                        )}
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-4 rounded-xl bg-[#F6F3EC] text-center text-xs text-[#767676]">
                    Area publik bebas retribusi masuk.
                  </div>
                )}
              </div>

              {currentDest.tips && currentDest.tips.length > 0 && (
                <div className="p-4 rounded-2xl bg-[#E4E9DA]/80 border border-[#CFD8BE] space-y-2">
                  <div className="text-xs font-bold text-[#234B24] flex items-center gap-1.5">
                    <Info className="w-4 h-4 text-[#234B24]" />
                    <span>Tips Menjaga Tempat Ini (Etika &amp; Adat Minang)</span>
                  </div>
                  <ul className="text-xs text-[#1B1F1A] space-y-1.5 pl-4 list-disc">
                    {currentDest.tips.map((tip) => (
                      <li
                        key={tip.id}
                        className={tip.is_important ? 'font-bold text-[#D95637]' : ''}
                      >
                        {tip.content}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}

          {/* TAB 2: 4 INDIKATOR MEDAN & CUACA LIVE OPEN-METEO */}
          {activeSection === 'medan' && (
            <div className="space-y-4">
              <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-1.5">
                <Compass className="w-4 h-4 text-[#234B24]" />
                <span>4 Indikator Kesiapan Medan &amp; Cuaca Live</span>
              </h2>

              {currentDest.weather && (
                <div className="p-4 rounded-2xl bg-[#E4E9DA]/70 border border-[#CFD8BE] space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-extrabold text-[#234B24] flex items-center gap-1.5">
                      <CloudSun className="w-4 h-4 text-[#F26B4B]" />
                      <span>Cuaca Live ({currentDest.weather.source})</span>
                    </span>
                    <span className="text-sm font-black text-[#234B24] font-mono">
                      {currentDest.weather.temperature_c}°C
                    </span>
                  </div>
                  <p className="text-xs font-bold text-[#1B1F1A]">
                    {currentDest.weather.condition} · Status: {currentDest.weather.weather_status}
                  </p>
                  <div className="flex items-center gap-4 text-[11px] text-[#4A5248]">
                    <span className="inline-flex items-center gap-1">
                      <Droplets className="w-3.5 h-3.5 text-blue-600" />
                      Kelembapan {currentDest.weather.humidity_percent}%
                    </span>
                    <span className="inline-flex items-center gap-1">
                      <Wind className="w-3.5 h-3.5 text-[#234B24]" />
                      Angin {currentDest.weather.wind_speed_kmh} km/j
                    </span>
                  </div>
                </div>
              )}

              {currentDest.medan_indicator ? (
                <div className="space-y-2.5">
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">1. Akses Kendaraan</span>
                    <span className="font-extrabold text-[#234B24]">
                      {currentDest.medan_indicator.vehicle_access}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">2. Tingkat Trekking</span>
                    <span className="font-extrabold text-[#234B24]">
                      {currentDest.medan_indicator.trekking_level}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">3. Fasilitas Resmi</span>
                    <span className="font-extrabold text-[#234B24] text-right max-w-[60%]">
                      {currentDest.medan_indicator.facilities}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">4. Kebutuhan Pemandu</span>
                    <span className="font-extrabold text-[#234B24]">
                      {currentDest.medan_indicator.guide_need}
                    </span>
                  </div>

                  {(currentDest.medan_indicator.terrain_note ||
                    currentDest.medan_indicator.readiness_notes) && (
                    <div className="p-3.5 rounded-xl bg-white border border-[#CFD8BE] text-xs text-[#4A5248] italic">
                      &quot;
                      {currentDest.medan_indicator.terrain_note ||
                        currentDest.medan_indicator.readiness_notes}
                      &quot;
                    </div>
                  )}
                </div>
              ) : (
                <div className="p-4 rounded-xl bg-[#F6F3EC] text-xs text-[#767676] text-center">
                  Data 4 indikator medan sedang diperbarui.
                </div>
              )}
            </div>
          )}

          {/* TAB 3: FORM LAPOR PUNGLI */}
          {activeSection === 'report' && (
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-5 h-5 text-[#F26B4B]" />
                <h2 className="text-sm font-extrabold text-[#1B1F1A]">
                  Form Cepat Lapor Pungli &amp; Fasilitas Rusak
                </h2>
              </div>

              {reportSuccess ? (
                <div className="p-5 rounded-2xl bg-[#DCFCE7] border border-[#86EFAC] text-center space-y-2">
                  <CheckCircle2 className="w-8 h-8 text-[#16A34A] mx-auto" />
                  <h3 className="text-sm font-extrabold text-[#166534]">
                    Laporan Diterima Pusat Komando!
                  </h3>
                  <p className="text-xs text-[#166534]/90">
                    Tiket aduan langsung tersinkronisasi ke dasbor Satgas Saber Pungli Sumbar.
                  </p>
                  <button
                    type="button"
                    onClick={() => {
                      setReportSuccess(false);
                      setReportDesc('');
                    }}
                    className="mt-2 min-h-[38px] px-4 py-1.5 rounded-lg bg-[#234B24] text-[#F6F3EC] text-xs font-bold"
                  >
                    Kirim Laporan Lain
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmitReport} className="space-y-3">
                  <div>
                    <label htmlFor={reporterNameId} className="block text-xs font-bold mb-1">
                      Nama Lengkap <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id={reporterNameId}
                      type="text"
                      value={reportName}
                      onChange={(e) => setReportName(e.target.value)}
                      required
                      placeholder="Contoh: Rahmat Hidayat"
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                    />
                  </div>
                  <div>
                    <label htmlFor={reporterPhoneId} className="block text-xs font-bold mb-1">
                      Nomor WhatsApp Aktif <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id={reporterPhoneId}
                      type="tel"
                      value={reportPhone}
                      onChange={(e) => setReportPhone(e.target.value)}
                      required
                      placeholder="0812xxxxxxxx"
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                    />
                  </div>
                  <div>
                    <label htmlFor={reporterCatId} className="block text-xs font-bold mb-1">
                      Kategori Aduan
                    </label>
                    <select
                      id={reporterCatId}
                      value={reportCategory}
                      onChange={(e) => setReportCategory(e.target.value as PublicPungliCategory)}
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                    >
                      <option value="Parkir Liar">Parkir Liar (Tanpa Karcis / Di Atas Tarif)</option>
                      <option value="Tiket Di Atas Perda">Tiket Masuk Di Atas Perda</option>
                      <option value="Pemaksaan Pemandu/Kapal">Pemaksaan Sewa Kapal / Pemandu</option>
                      <option value="Fasilitas Rusak">Fasilitas Toilet / Pos Rusak</option>
                    </select>
                  </div>
                  <div>
                    <label htmlFor={reporterAmountId} className="block text-xs font-bold mb-1">
                      Nominal Diminta Oknum (IDR)
                    </label>
                    <input
                      id={reporterAmountId}
                      type="number"
                      min={0}
                      step={1000}
                      value={reportAmount}
                      onChange={(e) => setReportAmount(Number(e.target.value))}
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold text-[#D95637]"
                    />
                  </div>
                  <div>
                    <label htmlFor={reporterDescId} className="block text-xs font-bold mb-1">
                      Kronologi &amp; Titik Lokasi
                    </label>
                    <textarea
                      id={reporterDescId}
                      rows={3}
                      value={reportDesc}
                      onChange={(e) => setReportDesc(e.target.value)}
                      className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                    />
                  </div>
                  <ImageDropzone
                    label="Unggah Bukti Foto (Opsional)"
                    value={reportPhoto}
                    onChange={(url) => setReportPhoto(url)}
                    onClear={() => setReportPhoto('')}
                  />
                  <button
                    type="submit"
                    disabled={submittingReport}
                    className="w-full h-[52px] rounded-pill bg-[#F26B4B] hover:bg-[#D95637] text-white text-xs font-bold flex items-center justify-center gap-2 shadow-md transition"
                  >
                    <Send className="w-4 h-4" />
                    <span>
                      {submittingReport ? 'Mengirim Laporan...' : 'Kirim ke Satgas Saber Pungli'}
                    </span>
                  </button>
                </form>
              )}
            </div>
          )}

          {/* TAB 4: HOTLINE 112/115, 6 KONTAK REAL SUMBAR & LOG SOS */}
          {activeSection === 'sos' && (
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <LifeBuoy className="w-5 h-5 text-[#DC2626]" />
                <h2 className="text-sm font-extrabold text-[#D95637]">
                  Hotline Darurat &amp; Kontak Resmi Sumbar
                </h2>
              </div>

              {/* 4 Hotline Bebas Pulsa */}
              <div className="grid grid-cols-2 gap-2">
                {TOLL_FREE_EMERGENCY_NUMBERS.map((item) => (
                  <a
                    key={item.number}
                    href={`tel:${item.number}`}
                    className="p-3 rounded-2xl bg-red-50 border border-red-200 hover:bg-red-100 transition flex items-center justify-between"
                  >
                    <div>
                      <div className="text-base font-black text-red-700 font-mono">
                        {item.number}
                      </div>
                      <div className="text-[10px] font-bold text-[#1B1F1A]">{item.label}</div>
                    </div>
                    <PhoneCall className="w-4 h-4 text-red-600 shrink-0" />
                  </a>
                ))}
              </div>

              {/* 6 Kontak Darurat Real Sumbar */}
              <div className="space-y-2">
                <h3 className="text-[11px] font-extrabold uppercase tracking-wider text-[#234B24]">
                  Instansi Siaga 24 Jam Sumatera Barat ({emergencyContacts.length})
                </h3>
                {emergencyContacts.map((c) => (
                  <div
                    key={c.id}
                    className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between gap-2 text-xs"
                  >
                    <div>
                      <div className="font-extrabold text-[#1B1F1A]">{c.agency_name}</div>
                      <div className="text-[10px] text-[#4A5248]">
                        {c.agency_type} · {c.city_regency}
                      </div>
                    </div>
                    <a
                      href={`tel:${c.phone_number.replace(/[^0-9+]/g, '')}`}
                      className="px-2.5 py-1.5 rounded-lg bg-[#234B24] text-white text-[11px] font-mono font-bold inline-flex items-center gap-1 shrink-0"
                    >
                      <Phone className="w-3 h-3" />
                      <span>{c.phone_number}</span>
                    </a>
                  </div>
                ))}
              </div>

              {/* Form Kirim Log SOS GPS */}
              <div className="pt-3 border-t border-[#CFD8BE]">
                <h3 className="text-xs font-extrabold text-[#1B1F1A] mb-2">
                  Kirim Log Koordinat GPS ke Pusat Komando
                </h3>
                {sosSuccess ? (
                  <div className="p-4 rounded-2xl bg-[#DCFCE7] border border-[#16A34A] text-center space-y-1.5">
                    <CheckCircle2 className="w-7 h-7 text-[#16A34A] mx-auto" />
                    <p className="text-xs font-extrabold text-[#166534]">
                      Log SOS GPS Tercatat! Hubungi 112 / 115 segera bila kondisi kritis.
                    </p>
                  </div>
                ) : (
                  <form onSubmit={handleSubmitSos} className="space-y-2.5">
                    <div className="p-2.5 rounded-xl bg-[#FEF08A]/40 border border-[#FDE047] text-[11px]">
                      <strong>GPS:</strong>{' '}
                      <span className="font-mono text-[#234B24] font-bold">
                        {currentDest.latitude}, {currentDest.longitude}
                      </span>
                    </div>
                    <input
                      id={sosNameId}
                      type="text"
                      required
                      value={sosName}
                      onChange={(e) => setSosName(e.target.value)}
                      placeholder="Nama wisatawan / ketua rombongan *"
                      className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                    />
                    <input
                      id={sosPhoneId}
                      type="tel"
                      required
                      value={sosPhone}
                      onChange={(e) => setSosPhone(e.target.value)}
                      placeholder="Nomor HP aktif *"
                      className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                    />
                    <textarea
                      id={sosNotesId}
                      rows={2}
                      value={sosNotes}
                      onChange={(e) => setSosNotes(e.target.value)}
                      placeholder="Kondisi darurat / kebutuhan evakuasi..."
                      className="w-full p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                    />
                    <button
                      type="submit"
                      disabled={submittingSos}
                      className="w-full h-[46px] rounded-pill bg-[#DC2626] hover:bg-[#B91C1C] text-white text-xs font-extrabold flex items-center justify-center gap-2 shadow-md transition"
                    >
                      <LifeBuoy className="w-4 h-4" />
                      <span>{submittingSos ? 'Mengirim...' : 'Kirim Log Darurat SOS GPS'}</span>
                    </button>
                  </form>
                )}
              </div>
            </div>
          )}
        </div>

        <footer className="p-4 bg-[#F6F3EC] border-t border-[#CFD8BE] text-center text-[10px] text-[#4A5248]">
          <p className="font-semibold text-[#234B24]">
            WISGO — Dinas Pariwisata Provinsi Sumatera Barat
          </p>
          <p className="mt-0.5">Ekosistem Wisata Pintar &amp; Siaga Wisatawan 19 Kab/Kota</p>
        </footer>
      </main>
    </div>
  );
};
