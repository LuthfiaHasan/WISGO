import React, { useId, useState } from 'react';
import {
  AlertTriangle,
  Battery,
  CheckCircle2,
  CloudSun,
  Droplets,
  Edit3,
  ExternalLink,
  FileText,
  Flashlight,
  LifeBuoy,
  MapPin,
  Navigation,
  Phone,
  RefreshCw,
  Search,
  Send,
  ShieldAlert,
  Thermometer,
  Truck,
  Volume2,
  Wind,
  X,
} from 'lucide-react';
import {
  HazardAlert,
  HazardSeverity,
  PungliReport,
  PungliStatus,
  SosSignal,
  SosStatus,
  WeatherMonitoringItem,
} from '../types/contract';
import {
  HAZARD_SEVERITIES,
  PUNGLI_STATUSES,
  TOLL_FREE_EMERGENCY_NUMBERS,
} from '../data/mockDestinations';
import {
  HazardAlertsRepo,
  PungliReportsRepo,
  SosSignalsRepo,
  WeatherMonitoringRepo,
} from '../services/dbRepository';
import { EmergencyContactsManager } from '../components/EmergencyContactsManager';

interface CommandCenterPageProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  onUpdateBadgeCount?: (openPungli: number, activeHazardCount: number) => void;
}

export const CommandCenterPage: React.FC<CommandCenterPageProps> = ({
  showToast,
  onUpdateBadgeCount,
}) => {
  const searchInputId = useId();
  const [activeTab, setActiveTab] = useState<'pungli' | 'sos' | 'hazard' | 'weather'>('pungli');

  const [pungliReports, setPungliReports] = useState<PungliReport[]>(() =>
    PungliReportsRepo.getAll()
  );
  const [sosSignals, setSosSignals] = useState<SosSignal[]>(() => SosSignalsRepo.getAll());
  const [hazardAlerts, setHazardAlerts] = useState<HazardAlert[]>(() =>
    HazardAlertsRepo.getAll()
  );
  const [weatherList, setWeatherList] = useState<WeatherMonitoringItem[]>(() =>
    WeatherMonitoringRepo.getAll()
  );
  const [isRefreshingMeteo, setIsRefreshingMeteo] = useState(false);

  // Filters Tab 1
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | PungliStatus>('all');
  const [typeFilter, setTypeFilter] = useState<'all' | 'pungli' | 'fasilitas'>('all');

  // Modals
  const [selectedPungli, setSelectedPungli] = useState<PungliReport | null>(null);
  const [adminNoteInput, setAdminNoteInput] = useState('');

  const [selectedSos, setSelectedSos] = useState<SosSignal | null>(null);
  const [assignedSarUnit, setAssignedSarUnit] = useState('');
  const [selectedSosStatus, setSelectedSosStatus] = useState<SosStatus>('Tim SAR Meluncur');

  const [selectedHazard, setSelectedHazard] = useState<HazardAlert | null>(null);
  const [hazardSeverity, setHazardSeverity] = useState<HazardSeverity>('Normal');
  const [hazardMessage, setHazardMessage] = useState('');
  const [hazardDetour, setHazardDetour] = useState('');

  const [editingWeather, setEditingWeather] = useState<WeatherMonitoringItem | null>(null);
  const [weatherCondInput, setWeatherCondInput] = useState('');
  const [weatherTempInput, setWeatherTempInput] = useState(26);
  const [weatherExtremeInput, setWeatherExtremeInput] = useState(false);
  const [weatherWarnInput, setWeatherWarnInput] = useState('');

  const syncSidebarBadge = (reports: PungliReport[], hazards: HazardAlert[]) => {
    const openPungli = reports.filter((r) => r.status !== 'Selesai').length;
    const activeHazards = hazards.filter(
      (h) => h.severity === 'Siaga' || h.severity === 'Awas Tutup Total'
    ).length;
    onUpdateBadgeCount?.(openPungli, activeHazards);
  };

  const handleUpdatePungliStatus = (newStatus: PungliStatus) => {
    if (!selectedPungli) return;
    const updated = PungliReportsRepo.save({
      ...selectedPungli,
      status: newStatus,
      admin_action_notes: adminNoteInput.trim() || selectedPungli.admin_action_notes,
    });
    setPungliReports(updated);
    setSelectedPungli(null);
    syncSidebarBadge(updated, hazardAlerts);
    showToast(`Status aduan ${selectedPungli.ticket_code} diperbarui menjadi: ${newStatus}`, 'success');
  };

  const handleUpdateSosStatus = () => {
    if (!selectedSos) return;
    const updated = SosSignalsRepo.save({
      ...selectedSos,
      status: selectedSosStatus,
      sar_unit_assigned: assignedSarUnit.trim() || selectedSos.sar_unit_assigned,
    });
    setSosSignals(updated);
    setSelectedSos(null);
    showToast(`Log koordinasi SOS ${selectedSos.sos_code} diperbarui: ${selectedSosStatus}`, 'success');
  };

  const handleSaveHazardAlert = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedHazard) return;
    const updated = HazardAlertsRepo.save({
      ...selectedHazard,
      severity: hazardSeverity,
      message: hazardMessage.trim(),
      detour_route: hazardDetour.trim(),
    });
    setHazardAlerts(updated);
    setSelectedHazard(null);
    syncSidebarBadge(pungliReports, updated);
    showToast(`Status koridor "${selectedHazard.location}" diperbarui: ${hazardSeverity}`, 'success');
  };

  const handleRefreshOpenMeteo = async () => {
    setIsRefreshingMeteo(true);
    try {
      const { items, liveSuccessCount } = await WeatherMonitoringRepo.refreshFromOpenMeteo();
      setWeatherList(items);
      showToast(
        liveSuccessCount > 0
          ? `Cuaca berhasil disegarkan langsung dari Open-Meteo Live (${liveSuccessCount}/${items.length} wilayah).`
          : 'Koneksi Open-Meteo tidak tersedia — menampilkan Regional Cache tersinkronisasi.',
        liveSuccessCount > 0 ? 'success' : 'info'
      );
    } finally {
      setIsRefreshingMeteo(false);
    }
  };

  const handleSaveWeatherEdit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingWeather) return;
    const updated = WeatherMonitoringRepo.updateCondition(
      editingWeather.id,
      weatherCondInput.trim() || editingWeather.condition,
      Number(weatherTempInput),
      weatherExtremeInput,
      weatherWarnInput.trim()
    );
    setWeatherList(updated);
    setEditingWeather(null);
    showToast(`Kondisi cuaca ${editingWeather.city_regency} berhasil diperbarui.`, 'success');
  };

  const handleBroadcastWeatherHazard = (wtr: WeatherMonitoringItem) => {
    const updatedHazards = WeatherMonitoringRepo.broadcastHazardAlert(wtr);
    setHazardAlerts(updatedHazards);
    syncSidebarBadge(pungliReports, updatedHazards);
    showToast(
      `Peringatan cuaca (${wtr.condition}) untuk ${wtr.destination_name} berhasil disiarkan ke Tab Jalur Rawan!`,
      'success'
    );
  };

  // KPI Pungli
  const countMasuk = pungliReports.filter((r) => r.status === 'Masuk').length;
  const countVerif = pungliReports.filter((r) => r.status === 'Diverifikasi').length;
  const countTindak = pungliReports.filter((r) => r.status === 'Ditindaklanjuti').length;
  const countSelesai = pungliReports.filter((r) => r.status === 'Selesai').length;
  const extremeWeatherCount = weatherList.filter((w) => w.is_extreme_weather).length;

  const filteredPungli = pungliReports.filter((r) => {
    const q = searchQuery.trim().toLowerCase();
    const matchQ =
      !q ||
      r.destination_name.toLowerCase().includes(q) ||
      r.reporter_name.toLowerCase().includes(q) ||
      r.kab_kota.toLowerCase().includes(q) ||
      r.description.toLowerCase().includes(q) ||
      r.ticket_code.toLowerCase().includes(q);
    const matchStatus = statusFilter === 'all' || r.status === statusFilter;
    const matchType = typeFilter === 'all' || (r.report_type || 'pungli') === typeFilter;
    return matchQ && matchStatus && matchType;
  });

  const getPungliStatusMeta = (status: PungliStatus) => {
    switch (status) {
      case 'Masuk':
        return 'bg-[#F26B4B]/15 text-[#D95637] border-[#F26B4B]/30';
      case 'Diverifikasi':
        return 'bg-amber-100 text-amber-900 border-amber-300';
      case 'Ditindaklanjuti':
        return 'bg-blue-100 text-blue-900 border-blue-300';
      case 'Selesai':
        return 'bg-emerald-100 text-emerald-900 border-emerald-300';
    }
  };

  const getHazardSeverityMeta = (sev: HazardSeverity) => {
    switch (sev) {
      case 'Normal':
        return { badge: 'bg-emerald-100 text-emerald-900 border-emerald-300', dot: 'bg-emerald-600' };
      case 'Waspada':
        return { badge: 'bg-amber-100 text-amber-900 border-amber-300', dot: 'bg-amber-500' };
      case 'Siaga':
        return { badge: 'bg-orange-100 text-orange-900 border-orange-300', dot: 'bg-orange-600' };
      case 'Awas Tutup Total':
        return { badge: 'bg-red-100 text-red-900 border-red-300', dot: 'bg-red-600' };
    }
  };

  return (
    <div className="space-y-6">
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            Pusat Komando Terpadu Pungli, SOS &amp; Cuaca Sumbar
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Penindakan pungli &amp; fasilitas rusak, 6 kontak darurat real Sumbar (000004), 4 koridor rawan, dan cuaca Open-Meteo Live.
          </p>
        </div>
        <div className="flex items-center gap-2 text-xs font-semibold text-[#234B24] bg-white px-3 py-1.5 rounded-xl border border-[#234B24]/10 shadow-2xs shrink-0">
          <span className="w-2 h-2 rounded-full bg-[#1E9E5A] animate-pulse" />
          <span>Siaga 24/7 · Satgas &amp; BPBD Sumbar</span>
        </div>
      </header>

      <nav
        aria-label="Tab Pusat Komando"
        className="flex overflow-x-auto no-scrollbar whitespace-nowrap shrink-0 gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-2xs"
      >
        <button
          type="button"
          onClick={() => setActiveTab('pungli')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold flex items-center gap-2 ${activeTab === 'pungli' ? 'bg-[#234B24] text-white' : 'text-[#4A5248] hover:bg-[#234B24]/5'
            }`}
        >
          <ShieldAlert className="w-3.5 h-3.5" />
          <span>Aduan Pungli &amp; Fasilitas</span>
          {countMasuk > 0 && (
            <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-[#F26B4B] text-white font-bold">
              {countMasuk} Masuk
            </span>
          )}
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('sos')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold flex items-center gap-2 ${activeTab === 'sos' ? 'bg-[#234B24] text-white' : 'text-[#4A5248] hover:bg-[#234B24]/5'
            }`}
        >
          <Phone className="w-3.5 h-3.5 text-[#F26B4B]" />
          <span>Kontak Darurat &amp; Alat SOS</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('hazard')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold flex items-center gap-2 ${activeTab === 'hazard' ? 'bg-[#234B24] text-white' : 'text-[#4A5248] hover:bg-[#234B24]/5'
            }`}
        >
          <AlertTriangle className="w-3.5 h-3.5 text-[#CA8A04]" />
          <span>Jalur Rawan (4 Koridor)</span>
          <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-white/20 font-bold">
            {hazardAlerts.length}
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('weather')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold flex items-center gap-2 ${activeTab === 'weather' ? 'bg-[#234B24] text-white' : 'text-[#4A5248] hover:bg-[#234B24]/5'
            }`}
        >
          <CloudSun className="w-3.5 h-3.5 text-[#3B82F6]" />
          <span>Cuaca Open-Meteo Live</span>
          {extremeWeatherCount > 0 && (
            <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-red-600 text-white font-bold">
              {extremeWeatherCount} Ekstrem
            </span>
          )}
        </button>
      </nav>

      {/* ==================================================================== */}
      {/* TAB 1: ADUAN PUNGLI & FASILITAS RUSAK                                */}
      {/* ==================================================================== */}
      {activeTab === 'pungli' && (
        <div className="space-y-5">
          <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
            <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-xs">
              <span className="text-xs font-bold text-[#D95637]">Masuk</span>
              <div className="mt-2 text-2xl font-extrabold">{countMasuk}</div>
              <p className="text-[11px] text-[#4A5248] mt-1">Menunggu verifikasi bukti</p>
            </div>
            <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-xs">
              <span className="text-xs font-bold text-amber-800">Diverifikasi</span>
              <div className="mt-2 text-2xl font-extrabold">{countVerif}</div>
              <p className="text-[11px] text-[#4A5248] mt-1">Pengecekan lapangan &amp; Perda</p>
            </div>
            <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-xs">
              <span className="text-xs font-bold text-blue-800">Ditindaklanjuti</span>
              <div className="mt-2 text-2xl font-extrabold">{countTindak}</div>
              <p className="text-[11px] text-[#4A5248] mt-1">Satgas / Pol PP bertindak</p>
            </div>
            <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-xs">
              <span className="text-xs font-bold text-emerald-800">Selesai</span>
              <div className="mt-2 text-2xl font-extrabold">{countSelesai}</div>
              <p className="text-[11px] text-[#4A5248] mt-1">Tertib &amp; perbaikan tuntas</p>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-4 border border-[#234B24]/10 flex flex-col md:flex-row gap-3">
            <div className="relative flex-1">
              <label htmlFor={searchInputId} className="sr-only">
                Cari laporan
              </label>
              <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
              <input
                id={searchInputId}
                type="search"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Cari kode tiket, destinasi, pelapor, atau uraian..."
                className="w-full min-h-[42px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
              />
            </div>

            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as 'all' | PungliStatus)}
              className="min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
            >
              <option value="all">Semua Status</option>
              {PUNGLI_STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>

            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value as 'all' | 'pungli' | 'fasilitas')}
              className="min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
            >
              <option value="all">Semua Tipe Aduan</option>
              <option value="pungli">Aduan Pungli Tarif</option>
              <option value="fasilitas">Fasilitas Rusak</option>
            </select>
          </div>

          <div className="bg-white rounded-2xl border border-[#234B24]/10 overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead className="bg-[#F6F3EC] text-[#234B24] text-[11px] font-extrabold uppercase border-b border-[#CFD8BE]">
                  <tr>
                    <th className="py-3.5 px-4">Tiket &amp; Tanggal</th>
                    <th className="py-3.5 px-4">Destinasi &amp; Wilayah</th>
                    <th className="py-3.5 px-4">Pelapor</th>
                    <th className="py-3.5 px-4">Kategori</th>
                    <th className="py-3.5 px-4">Dipungut vs Perda</th>
                    <th className="py-3.5 px-4">Status</th>
                    <th className="py-3.5 px-4 text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {filteredPungli.map((report) => {
                    const isFasilitas = report.report_type === 'fasilitas';
                    return (
                      <tr key={report.id} className="hover:bg-[#F6F3EC]/40">
                        <td className="py-3.5 px-4 whitespace-nowrap">
                          <span className="font-mono font-bold text-[#234B24]">
                            {report.ticket_code}
                          </span>
                          <div className="text-[10px] text-[#767676]">
                            {new Date(report.created_at).toLocaleDateString('id-ID', {
                              day: '2-digit',
                              month: 'short',
                              year: 'numeric',
                            })}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <div className="font-extrabold">{report.destination_name}</div>
                          <div className="text-[11px] text-[#4A5248] flex items-center gap-1">
                            <MapPin className="w-3 h-3 text-[#234B24]" /> {report.kab_kota}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <div className="font-bold">{report.reporter_name}</div>
                          <div className="text-[10px] font-mono text-[#767676]">
                            {report.reporter_phone || '-'}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <span
                            className={`px-2.5 py-1 rounded-lg text-[10px] font-bold ${isFasilitas
                                ? 'bg-purple-100 text-purple-800'
                                : 'bg-[#E4E9DA] text-[#234B24]'
                              }`}
                          >
                            {report.incident_category}
                          </span>
                        </td>
                        <td className="py-3.5 px-4">
                          {isFasilitas ? (
                            <span className="text-[11px] text-[#4A5248] font-medium">
                              Laporan Sarana Fisik
                            </span>
                          ) : (
                            <div>
                              <div className="font-extrabold text-[#D95637]">
                                Rp {report.charged_amount_idr.toLocaleString('id-ID')}
                              </div>
                              <div className="text-[10px] text-[#166534]">
                                Perda: Rp {report.official_perda_price_idr.toLocaleString('id-ID')} (+Rp{' '}
                                {report.overcharge_amount_idr.toLocaleString('id-ID')})
                              </div>
                            </div>
                          )}
                        </td>
                        <td className="py-3.5 px-4">
                          <span
                            className={`px-2.5 py-1 rounded-full text-[11px] font-bold border ${getPungliStatusMeta(
                              report.status
                            )}`}
                          >
                            {report.status}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-right">
                          <button
                            type="button"
                            onClick={() => {
                              setSelectedPungli(report);
                              setAdminNoteInput(report.admin_action_notes || '');
                            }}
                            className="px-3.5 py-1.5 rounded-xl bg-[#234B24] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1"
                          >
                            <FileText className="w-3.5 h-3.5" /> Tindak Lanjut
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* TAB 2: KONTAK DARURAT REAL (000004) + HOTLINE BEBAS PULSA + ALAT SOS */}
      {/* ==================================================================== */}
      {activeTab === 'sos' && (
        <div className="space-y-6">
          {/* 4 Hotline Bebas Pulsa Nasional */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            {TOLL_FREE_EMERGENCY_NUMBERS.map((item) => (
              <a
                key={item.number}
                href={`tel:${item.number}`}
                className="p-4 rounded-2xl bg-[#234B24] text-[#F6F3EC] hover:bg-[#1B3B1C] transition flex items-center justify-between gap-3 shadow-sm"
              >
                <div>
                  <span className="text-[10px] font-bold uppercase text-[#A7F3D0]">
                    Bebas Pulsa 24/7
                  </span>
                  <div className="text-2xl font-black font-mono text-white">{item.number}</div>
                  <div className="text-xs font-bold">{item.label}</div>
                  <div className="text-[10px] text-white/70">{item.desc}</div>
                </div>
                <Phone className="w-6 h-6 text-[#F26B4B] shrink-0" />
              </a>
            ))}
          </div>

          {/* Alat Darurat Fisik Offline di Mobile (FE-2 e269e94) */}
          <div className="bg-white rounded-2xl p-5 border border-[#234B24]/10 shadow-xs grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shrink-0">
                <Volume2 className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-xs font-extrabold text-[#1B1F1A]">
                  Sirine Audio Darurat 110dB (Alat Fisik Mobile)
                </h4>
                <p className="text-[11px] text-[#4A5248] mt-1">
                  Membunyikan frekuensi peluit penyelamatan secara luring untuk menarik perhatian warga atau tim penyelamat di sekitar lokasi.
                </p>
              </div>
            </div>
            <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-start gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0">
                <Flashlight className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-xs font-extrabold text-[#1B1F1A]">
                  Senter Isyarat Kode Morse S-O-S (· · · — — — · · ·)
                </h4>
                <p className="text-[11px] text-[#4A5248] mt-1">
                  Kedipan lampu kilat LED otomatis sesuai standar penyelamatan internasional untuk visibilitas malam hari di medan alam.
                </p>
              </div>
            </div>
          </div>

          {/* Direktori 6 Kontak Darurat Real Sumbar */}
          <EmergencyContactsManager showToast={showToast} />

          {/* Sekunder: Log Sinkronisasi SOS (Audit BE-1) */}
          <details className="bg-white rounded-2xl p-5 border border-[#234B24]/10 shadow-xs">
            <summary className="cursor-pointer font-extrabold text-sm text-[#234B24] flex items-center justify-between">
              <span className="flex items-center gap-2">
                <LifeBuoy className="w-4 h-4 text-[#F26B4B]" />
                Log Sinkronisasi SOS Lapangan (Audit Endpoint BE-1 · {sosSignals.length} Catatan)
              </span>
              <span className="text-xs text-[#4A5248] font-semibold">Klik untuk buka/tutup</span>
            </summary>

            <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
              {sosSignals.map((sig) => (
                <div
                  key={sig.id}
                  className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2.5 text-xs"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <span className="font-mono font-bold text-[#234B24]">{sig.sos_code}</span>
                      <h4 className="font-extrabold text-[#1B1F1A] text-sm">{sig.tourist_name}</h4>
                      <div className="text-[11px] text-[#4A5248]">
                        {sig.phone_number} · {sig.passengers_count} Orang · {sig.emergency_type}
                      </div>
                    </div>
                    <span className="px-2.5 py-1 rounded-full text-[10px] font-extrabold bg-[#234B24] text-white">
                      {sig.status}
                    </span>
                  </div>

                  <div className="p-3 rounded-xl bg-white border border-[#CFD8BE] space-y-1">
                    <div className="flex items-center justify-between">
                      <span className="font-bold">
                        {sig.destination_name || sig.nearest_corridor} ({sig.city_regency || 'Sumbar'})
                      </span>
                      <a
                        href={`https://maps.google.com/?q=${sig.latitude},${sig.longitude}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-700 font-bold inline-flex items-center gap-1"
                      >
                        Maps <ExternalLink className="w-3 h-3" />
                      </a>
                    </div>
                    <div className="flex items-center justify-between text-[11px] text-[#4A5248]">
                      <span className="inline-flex items-center gap-1 font-mono">
                        <Battery className="w-3.5 h-3.5 text-emerald-600" /> Baterai {sig.battery_percent}%
                      </span>
                      <span>
                        Posko: {sig.nearest_rescue_post} ({sig.distance_to_rescue_km} km · ETA {sig.eta_rescue_minutes} mnt)
                      </span>
                    </div>
                  </div>

                  <p className="text-[11px] text-[#1B1F1A]">{sig.notes}</p>
                  {sig.sar_unit_assigned && (
                    <div className="text-[11px] font-bold text-blue-800 flex items-center gap-1">
                      <Truck className="w-3.5 h-3.5" /> Unit: {sig.sar_unit_assigned}
                    </div>
                  )}

                  <div className="pt-2 border-t border-[#CFD8BE] flex justify-end">
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedSos(sig);
                        setAssignedSarUnit(sig.sar_unit_assigned || '');
                        setSelectedSosStatus(sig.status);
                      }}
                      className="px-3 py-1.5 rounded-xl bg-[#234B24] text-white text-xs font-bold"
                    >
                      Perbarui Koordinasi
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </details>
        </div>
      )}

      {/* ==================================================================== */}
      {/* TAB 3: JALUR RAWAN (4 KORIDOR BAKU + BROADCAST CUACA)                */}
      {/* ==================================================================== */}
      {activeTab === 'hazard' && (
        <div className="space-y-5">
          <div className="bg-[#234B24] text-[#F6F3EC] rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-11 h-11 rounded-2xl bg-[#F26B4B] text-white flex items-center justify-center shrink-0">
                <AlertTriangle className="w-6 h-6" />
              </div>
              <div>
                <span className="text-[10px] font-extrabold uppercase tracking-wider text-[#A7F3D0]">
                  4 KORIDOR JALUR EKSTREM SUMATERA BARAT
                </span>
                <h2 className="text-lg font-extrabold text-white mt-0.5">
                  Sitinjau Lauik · Lembah Anai · Kelok 9 · Kelok 44
                </h2>
                <p className="text-xs text-[#E4E9DA]/85 mt-1">
                  Tingkat siaga baku: Normal, Waspada, Siaga, dan Awas Tutup Total. Tersinkron dengan siaran cuaca Open-Meteo.
                </p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {hazardAlerts.map((hazard) => {
              const meta = getHazardSeverityMeta(hazard.severity);
              return (
                <div
                  key={hazard.id}
                  className="p-5 rounded-2xl bg-white border border-[#CFD8BE] flex flex-col justify-between space-y-3 shadow-xs"
                >
                  <div>
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <span className="text-[10px] font-mono font-bold text-[#4A5248]">
                          {hazard.corridor_code} · {hazard.city_regency}
                        </span>
                        <h4 className="text-sm font-extrabold text-[#1B1F1A] mt-0.5">
                          {hazard.location}
                        </h4>
                        <div className="text-[11px] text-[#767676]">{hazard.road_segment}</div>
                      </div>
                      <span
                        className={`px-2.5 py-0.5 rounded-full text-[11px] font-extrabold border shrink-0 inline-flex items-center gap-1.5 ${meta.badge}`}
                      >
                        <span className={`w-2 h-2 rounded-full ${meta.dot}`} />
                        {hazard.severity}
                      </span>
                    </div>

                    <p className="mt-2.5 text-xs text-[#4A5248] leading-relaxed">{hazard.message}</p>

                    <div className="mt-2.5 p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs">
                      <span className="font-bold text-[#234B24]">Rute Alternatif: </span>
                      <span>{hazard.detour_route}</span>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-[#E4E9DA] flex items-center justify-between text-[11px]">
                    <span className="text-[#4A5248]">
                      Posko: <strong>{hazard.nearest_rescue_post}</strong> ({hazard.emergency_contact})
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedHazard(hazard);
                        setHazardSeverity(hazard.severity);
                        setHazardMessage(hazard.message);
                        setHazardDetour(hazard.detour_route);
                      }}
                      className="px-3.5 py-1.5 rounded-xl bg-[#234B24] text-white font-bold text-xs inline-flex items-center gap-1"
                    >
                      <Navigation className="w-3.5 h-3.5" /> Ubah Status
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* TAB 4: CUACA OPEN-METEO LIVE (REFRESH ON-DEMAND + 6 SLOT + EDIT)     */}
      {/* ==================================================================== */}
      {activeTab === 'weather' && (
        <div className="space-y-5">
          <div className="bg-white rounded-2xl p-5 border border-[#234B24]/10 flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-xs">
            <div>
              <h3 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <CloudSun className="w-5 h-5 text-sky-600" />
                <span>Pemantauan Cuaca Real-Time Destinasi (Open-Meteo Live API)</span>
              </h3>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Menyediakan data suhu, kelembapan, angin, peluang hujan, dan prakiraan 6 jam ke depan ke Direktori Destinasi &amp; Plang Smart QR.
              </p>
            </div>
            <button
              type="button"
              disabled={isRefreshingMeteo}
              onClick={handleRefreshOpenMeteo}
              className="min-h-[42px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold inline-flex items-center gap-2 shrink-0 disabled:opacity-60"
            >
              <RefreshCw className={`w-4 h-4 text-[#A7F3D0] ${isRefreshingMeteo ? 'animate-spin' : ''}`} />
              <span>
                {isRefreshingMeteo ? 'Menarik Open-Meteo...' : 'Segarkan dari Open-Meteo Live'}
              </span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {weatherList.map((item) => (
              <div
                key={item.id}
                className={`p-5 rounded-3xl border flex flex-col justify-between space-y-4 ${item.is_extreme_weather
                    ? 'border-red-300 bg-red-50/30'
                    : 'border-[#CFD8BE] bg-white'
                  }`}
              >
                <div className="space-y-3">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <span className="text-[10px] font-black uppercase text-[#767676]">
                        {item.city_regency} · {item.source}
                      </span>
                      <h4 className="text-sm font-extrabold text-[#1B1F1A]">{item.destination_name}</h4>
                    </div>
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-black shrink-0 ${item.is_extreme_weather
                          ? 'bg-red-600 text-white'
                          : item.weather_status === 'Waspada Hujan'
                            ? 'bg-amber-100 text-amber-900'
                            : 'bg-emerald-100 text-emerald-900'
                        }`}
                    >
                      {item.weather_status}
                    </span>
                  </div>

                  <div className="p-3.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <Thermometer className="w-6 h-6 text-[#F26B4B]" />
                      <div>
                        <div className="text-2xl font-black text-[#234B24] font-mono">
                          {item.current_temp_c}°C
                        </div>
                        <span className="text-xs font-bold text-[#4A5248]">{item.condition}</span>
                      </div>
                    </div>
                    <div className="text-right text-[11px] text-[#4A5248] space-y-0.5">
                      <div className="flex items-center justify-end gap-1">
                        <Droplets className="w-3.5 h-3.5 text-sky-600" />
                        <span>{item.humidity_pct}% · Hujan {item.rain_probability}%</span>
                      </div>
                      <div className="flex items-center justify-end gap-1">
                        <Wind className="w-3.5 h-3.5 text-slate-500" />
                        <span>{item.wind_speed_kmh} km/jam</span>
                      </div>
                    </div>
                  </div>

                  {item.extreme_warning_text && (
                    <div className="p-2.5 rounded-xl bg-red-100/70 border border-red-200 text-[11px] text-red-900">
                      <strong>Catatan:</strong> {item.extreme_warning_text}
                    </div>
                  )}

                  {/* Honest 6 Hourly Forecast Slots */}
                  <div>
                    <span className="text-[10px] font-extrabold uppercase text-[#4A5248] block mb-1.5">
                      Prakiraan 6 Jam ke Depan:
                    </span>
                    <div className="grid grid-cols-3 gap-1.5 text-center">
                      {item.hourly_forecast.slice(0, 6).map((hf, i) => (
                        <div key={i} className="p-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                          <span className="text-[10px] font-mono text-[#767676] block">{hf.hour}</span>
                          <strong className="text-xs font-extrabold text-[#234B24] block">
                            {hf.temp_c}°C
                          </strong>
                          <span className="text-[9px] text-[#4A5248] block truncate">
                            {hf.condition}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="pt-3 border-t border-[#E4E9DA] flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setEditingWeather(item);
                      setWeatherCondInput(item.condition);
                      setWeatherTempInput(item.current_temp_c);
                      setWeatherExtremeInput(item.is_extreme_weather);
                      setWeatherWarnInput(item.extreme_warning_text || '');
                    }}
                    className="px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#234B24] inline-flex items-center gap-1"
                  >
                    <Edit3 className="w-3.5 h-3.5" /> Edit
                  </button>
                  <button
                    type="button"
                    onClick={() => handleBroadcastWeatherHazard(item)}
                    className={`flex-1 py-2 px-3 rounded-xl font-bold text-xs inline-flex items-center justify-center gap-1.5 ${item.is_extreme_weather
                        ? 'bg-red-600 text-white'
                        : 'bg-[#234B24] text-white'
                      }`}
                  >
                    <Send className="w-3.5 h-3.5" /> Siarkan ke Jalur Rawan
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* MODAL TINDAK LANJUT PUNGLI */}
      {selectedPungli && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <div className="bg-white rounded-[28px] w-full max-w-2xl p-6 shadow-2xl max-h-[90vh] overflow-y-auto space-y-4">
            <div className="flex items-center justify-between pb-3 border-b">
              <div>
                <h3 className="text-base font-extrabold">
                  Verifikasi Laporan {selectedPungli.ticket_code}
                </h3>
                <p className="text-xs text-[#4A5248]">
                  {selectedPungli.destination_name} · {selectedPungli.kab_kota}
                </p>
              </div>
              <button type="button" onClick={() => setSelectedPungli(null)}>
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <img
                src={selectedPungli.photo_evidence}
                alt="Bukti aduan"
                className="w-full aspect-[4/3] object-cover rounded-2xl border border-[#CFD8BE]"
              />
              <div className="space-y-3 text-xs">
                <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                  <div className="font-extrabold">{selectedPungli.reporter_name}</div>
                  <div className="font-mono text-[#4A5248]">{selectedPungli.reporter_phone}</div>
                  <div className="text-[#767676] mt-1">
                    GPS: {selectedPungli.latitude.toFixed(4)}, {selectedPungli.longitude.toFixed(4)}
                  </div>
                </div>
                <p className="p-3 rounded-xl bg-amber-50 border border-amber-200">
                  &ldquo;{selectedPungli.description}&rdquo;
                </p>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold mb-1">Catatan Tindakan Satgas / Admin</label>
              <textarea
                rows={2}
                value={adminNoteInput}
                onChange={(e) => setAdminNoteInput(e.target.value)}
                className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
              />
            </div>

            <div className="grid grid-cols-3 gap-2 pt-2 border-t">
              <button
                type="button"
                onClick={() => handleUpdatePungliStatus('Diverifikasi')}
                className="py-2.5 rounded-xl bg-amber-100 text-amber-900 font-bold text-xs"
              >
                Diverifikasi
              </button>
              <button
                type="button"
                onClick={() => handleUpdatePungliStatus('Ditindaklanjuti')}
                className="py-2.5 rounded-xl bg-blue-100 text-blue-900 font-bold text-xs"
              >
                Ditindaklanjuti
              </button>
              <button
                type="button"
                onClick={() => handleUpdatePungliStatus('Selesai')}
                className="py-2.5 rounded-xl bg-[#234B24] text-white font-bold text-xs inline-flex items-center justify-center gap-1"
              >
                <CheckCircle2 className="w-4 h-4" /> Selesai
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL UPDATE SOS LOG */}
      {selectedSos && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <div className="bg-white rounded-[28px] w-full max-w-md p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-extrabold">Perbarui Log SOS {selectedSos.sos_code}</h3>
            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-bold mb-1">Unit BPBD / Basarnas Ditugaskan</label>
                <input
                  type="text"
                  value={assignedSarUnit}
                  onChange={(e) => setAssignedSarUnit(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
              <div className="grid grid-cols-3 gap-2">
                {(['Dipancarkan', 'Tim SAR Meluncur', 'Evakuasi Selesai'] as const).map((st) => (
                  <button
                    key={st}
                    type="button"
                    onClick={() => setSelectedSosStatus(st)}
                    className={`py-2 px-2 rounded-xl font-bold border text-[11px] ${selectedSosStatus === st
                        ? 'bg-[#234B24] text-white border-[#234B24]'
                        : 'bg-[#F6F3EC] text-[#4A5248] border-[#CFD8BE]'
                      }`}
                  >
                    {st}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex justify-end gap-2 pt-2 border-t">
              <button
                type="button"
                onClick={() => setSelectedSos(null)}
                className="px-4 py-2 text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleUpdateSosStatus}
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL UBAH STATUS JALUR RAWAN */}
      {selectedHazard && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <form onSubmit={handleSaveHazardAlert} className="bg-white rounded-[28px] w-full max-w-lg p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-extrabold">
              Ubah Status Koridor: {selectedHazard.location}
            </h3>
            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-bold mb-1">Tingkat Siaga Jalur</label>
                <select
                  value={hazardSeverity}
                  onChange={(e) => setHazardSeverity(e.target.value as HazardSeverity)}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-bold"
                >
                  {HAZARD_SEVERITIES.map((sev) => (
                    <option key={sev} value={sev}>
                      {sev}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block font-bold mb-1">Pesan Peringatan Wisatawan</label>
                <textarea
                  rows={2}
                  value={hazardMessage}
                  onChange={(e) => setHazardMessage(e.target.value)}
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
              <div>
                <label className="block font-bold mb-1">Rute Alternatif / Pengalihan</label>
                <input
                  type="text"
                  value={hazardDetour}
                  onChange={(e) => setHazardDetour(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
            </div>
            <div className="flex justify-end gap-2 pt-2 border-t">
              <button
                type="button"
                onClick={() => setSelectedHazard(null)}
                className="px-4 py-2 text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan &amp; Siarkan Status
              </button>
            </div>
          </form>
        </div>
      )}

      {/* MODAL EDIT KONDISI CUACA */}
      {editingWeather && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <form onSubmit={handleSaveWeatherEdit} className="bg-white rounded-[28px] w-full max-w-md p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-extrabold">
              Edit Kondisi Cuaca — {editingWeather.city_regency}
            </h3>
            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-bold mb-1">Kondisi Cuaca</label>
                <input
                  type="text"
                  value={weatherCondInput}
                  onChange={(e) => setWeatherCondInput(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
              <div>
                <label className="block font-bold mb-1">Suhu (°C)</label>
                <input
                  type="number"
                  value={weatherTempInput}
                  onChange={(e) => setWeatherTempInput(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                />
              </div>
              <label className="flex items-center gap-2 font-bold text-red-700 cursor-pointer">
                <input
                  type="checkbox"
                  checked={weatherExtremeInput}
                  onChange={(e) => setWeatherExtremeInput(e.target.checked)}
                />
                <span>Tandai sebagai Cuaca Ekstrem / Siaga</span>
              </label>
              <div>
                <label className="block font-bold mb-1">Catatan Peringatan (Opsional)</label>
                <textarea
                  rows={2}
                  value={weatherWarnInput}
                  onChange={(e) => setWeatherWarnInput(e.target.value)}
                  className="w-full p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
            </div>
            <div className="flex justify-end gap-2 pt-2 border-t">
              <button
                type="button"
                onClick={() => setEditingWeather(null)}
                className="px-4 py-2 text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan Cuaca
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
