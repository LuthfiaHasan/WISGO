import React, { useEffect, useState, useId } from 'react';
import {
  Radio,
  ShieldAlert,
  AlertTriangle,
  LifeBuoy,
  CheckCircle2,
  Clock,
  Phone,
  MapPin,
  ExternalLink,
  Battery,
  Wifi,
  Search,
  Check,
  ChevronRight,
  Eye,
  FileText,
  AlertCircle,
  Truck,
  ArrowRight,
  X,
  Save,
  Navigation,
} from 'lucide-react';
import {
  HazardSeverity,
  HazardZoneAlert,
  PungliCategoryType,
  PungliReport,
  PungliStatus,
  SosEmergencyStatus,
  SosEmergencyTicket,
} from '../types/contract';
import {
  fetchHazardAlerts,
  fetchPungliReports,
  fetchSosTickets,
  updateHazardAlert,
  updatePungliReportStatus,
  updateSosTicketStatus,
} from '../services/api';

interface CommandCenterPageProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  onUpdateBadgeCount?: (openPungli: number, openSos: number) => void;
}

export const CommandCenterPage: React.FC<CommandCenterPageProps> = ({
  showToast,
  onUpdateBadgeCount,
}) => {
  const searchInputId = useId();
  const statusFilterId = useId();
  const categoryFilterId = useId();
  const sarUnitInputId = useId();
  const hazardSeverityId = useId();
  const hazardMsgId = useId();
  const hazardDetourId = useId();

  // Active Tab: 3 Operational Panels
  const [activeTab, setActiveTab] = useState<'pungli' | 'sos' | 'hazard'>('pungli');

  // Data States
  const [pungliReports, setPungliReports] = useState<PungliReport[]>([]);
  const [sosTickets, setSosTickets] = useState<SosEmergencyTicket[]>([]);
  const [hazardAlerts, setHazardAlerts] = useState<HazardZoneAlert[]>([]);
  const [loading, setLoading] = useState(true);

  // Tab 1 Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');

  // Selected Pungli Ticket for Action Modal
  const [selectedPungli, setSelectedPungli] = useState<PungliReport | null>(null);
  const [adminNoteInput, setAdminNoteInput] = useState('');
  const [isUpdatingPungli, setIsUpdatingPungli] = useState(false);

  // Selected SOS Ticket for Dispatch Modal
  const [selectedSos, setSelectedSos] = useState<SosEmergencyTicket | null>(null);
  const [assignedSarUnit, setAssignedSarUnit] = useState('');
  const [selectedSosStatus, setSelectedSosStatus] =
    useState<SosEmergencyStatus>('Tim SAR Dikerahkan');
  const [isUpdatingSos, setIsUpdatingSos] = useState(false);

  // Selected Hazard Alert for Status Modal
  const [selectedHazard, setSelectedHazard] = useState<HazardZoneAlert | null>(null);
  const [hazardSeverity, setHazardSeverity] = useState<HazardSeverity>('Aman Terkendali');
  const [hazardMessage, setHazardMessage] = useState('');
  const [hazardDetour, setHazardDetour] = useState('');

  // Load Data
  const loadData = async () => {
    setLoading(true);
    try {
      const [reports, tickets, hazards] = await Promise.all([
        fetchPungliReports(),
        fetchSosTickets(),
        fetchHazardAlerts(),
      ]);
      setPungliReports(reports);
      setSosTickets(tickets);
      setHazardAlerts(hazards);

      const openPungli = reports.filter((r) => r.status !== 'Selesai').length;
      const openSos = tickets.filter((t) => t.status !== 'Penanganan Selesai').length;
      onUpdateBadgeCount?.(openPungli, openSos);
    } catch {
      showToast('Gagal memuat data pusat komando.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Update Pungli Status Action
  const handleUpdatePungliStatus = async (newStatus: PungliStatus) => {
    if (!selectedPungli) return;
    setIsUpdatingPungli(true);
    try {
      const updated = await updatePungliReportStatus(
        selectedPungli.id,
        newStatus,
        adminNoteInput.trim() || selectedPungli.admin_notes
      );
      setPungliReports(updated);
      setSelectedPungli(null);
      const openCount = updated.filter((r) => r.status !== 'Selesai').length;
      const openSosCount = sosTickets.filter((t) => t.status !== 'Penanganan Selesai').length;
      onUpdateBadgeCount?.(openCount, openSosCount);
      showToast(`Status laporan berhasil diubah menjadi: ${newStatus}`, 'success');
    } catch {
      showToast('Gagal memperbarui status laporan pungli.', 'error');
    } finally {
      setIsUpdatingPungli(false);
    }
  };

  // Update SOS Status Action
  const handleUpdateSosStatus = async () => {
    if (!selectedSos) return;
    setIsUpdatingSos(true);
    try {
      const updated = await updateSosTicketStatus(
        selectedSos.id,
        selectedSosStatus,
        assignedSarUnit.trim() || undefined
      );
      setSosTickets(updated);
      setSelectedSos(null);
      const openSosCount = updated.filter((t) => t.status !== 'Penanganan Selesai').length;
      const openPungliCount = pungliReports.filter((r) => r.status !== 'Selesai').length;
      onUpdateBadgeCount?.(openPungliCount, openSosCount);
      showToast(
        `Status koordinasi SAR berhasil diperbarui: ${selectedSosStatus}`,
        'success'
      );
    } catch {
      showToast('Gagal memperbarui status darurat SAR.', 'error');
    } finally {
      setIsUpdatingSos(false);
    }
  };

  // Update Hazard Zone Alert Action
  const handleSaveHazardAlert = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedHazard) return;
    try {
      const updated = await updateHazardAlert(
        selectedHazard.id,
        hazardSeverity,
        hazardMessage.trim(),
        hazardDetour.trim()
      );
      setHazardAlerts(updated);
      setSelectedHazard(null);
      showToast(
        `Status jalur rawan "${selectedHazard.location}" berhasil diperbarui: ${hazardSeverity}`,
        'success'
      );
    } catch {
      showToast('Gagal memperbarui peringatan jalur rawan.', 'error');
    }
  };

  // Helper Stats Tab 1
  const countBaru = pungliReports.filter((r) => r.status === 'Laporan Baru').length;
  const countVerif = pungliReports.filter((r) => r.status === 'Sedang Diverifikasi').length;
  const countTindak = pungliReports.filter((r) => r.status === 'Ditindaklanjuti Lapangan').length;
  const countSelesai = pungliReports.filter((r) => r.status === 'Selesai').length;

  // Filtered Pungli Reports
  const filteredPungli = pungliReports.filter((r) => {
    const matchQuery =
      r.destination_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.reporter_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.kab_kota.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.description.toLowerCase().includes(searchQuery.toLowerCase());

    const matchStatus =
      statusFilter === 'all' ? true : r.status === statusFilter;
    const matchCat =
      categoryFilter === 'all' ? true : r.category === categoryFilter;

    return matchQuery && matchStatus && matchCat;
  });

  // Active SOS Tickets
  const activeSosCount = sosTickets.filter(
    (t) => t.status !== 'Penanganan Selesai'
  ).length;

  // Pungli Status Style
  const getPungliStatusMeta = (status: PungliStatus) => {
    switch (status) {
      case 'Laporan Baru':
        return {
          bg: 'bg-[#F26B4B]/15',
          text: 'text-[#D95637]',
          border: 'border-[#F26B4B]/30',
        };
      case 'Sedang Diverifikasi':
        return {
          bg: 'bg-[#FEF08A]/80',
          text: 'text-[#854D0E]',
          border: 'border-[#EAB308]/40',
        };
      case 'Ditindaklanjuti Lapangan':
        return {
          bg: 'bg-[#BFDBFE]/80',
          text: 'text-[#1E40AF]',
          border: 'border-[#3B82F6]/40',
        };
      case 'Selesai':
        return {
          bg: 'bg-[#DCFCE7]',
          text: 'text-[#166534]',
          border: 'border-[#22C55E]/40',
        };
    }
  };

  // SOS Status Style
  const getSosStatusMeta = (status: SosEmergencyStatus) => {
    switch (status) {
      case 'Sinyal SOS Masuk':
        return {
          bg: 'bg-[#F26B4B]',
          text: 'text-white',
          pulse: true,
        };
      case 'Tim SAR Dikerahkan':
        return {
          bg: 'bg-[#EA580C]',
          text: 'text-white',
          pulse: true,
        };
      case 'Evakuasi Berjalan':
        return {
          bg: 'bg-[#2563EB]',
          text: 'text-white',
          pulse: false,
        };
      case 'Penanganan Selesai':
        return {
          bg: 'bg-[#16A34A]',
          text: 'text-white',
          pulse: false,
        };
    }
  };

  // Hazard Severity Style
  const getHazardSeverityMeta = (sev: HazardSeverity) => {
    switch (sev) {
      case 'Aman Terkendali':
        return {
          badge: 'bg-[#DCFCE7] text-[#166534] border-[#86EFAC]',
          dot: 'bg-[#16A34A]',
        };
      case 'Waspada Bencana':
        return {
          badge: 'bg-[#FEF08A] text-[#854D0E] border-[#FDE047]',
          dot: 'bg-[#CA8A04]',
        };
      case 'Buka-Tutup Jalur':
        return {
          badge: 'bg-[#FFEDD5] text-[#C2410C] border-[#FDBA74]',
          dot: 'bg-[#EA580C]',
        };
      case 'Tutup Total':
        return {
          badge: 'bg-[#FEE2E2] text-[#991B1B] border-[#FCA5A5]',
          dot: 'bg-[#DC2626]',
        };
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Utama Pusat Komando */}
      <header className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA]">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm shrink-0">
              <Radio className="w-6 h-6" aria-hidden="true" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                  Pusat Komando Terpadu Pungli &amp; SOS SAR
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  Siaga 24/7 Sumbar
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1">
                Kendali penuh Administrator Utama: Penindakan aduan pungli &amp; pelanggaran tarif resmi Perda, respon sinyal darurat SOS GPS wisatawan, dan pemantauan jalur ekstrem rawan bencana di 19 Kabupaten/Kota.
              </p>
            </div>
          </div>

          {/* Switcher Tab 1 vs Tab 2 */}
          <div className="flex items-center p-1.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] shrink-0 self-start lg:self-center">
            <button
              type="button"
              onClick={() => setActiveTab('pungli')}
              className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                activeTab === 'pungli'
                  ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
                  : 'text-[#4A5248] hover:text-[#1B1F1A]'
              }`}
            >
              <ShieldAlert className="w-4 h-4" aria-hidden="true" />
              <span>Aduan Pungli &amp; Fasilitas</span>
              {countBaru > 0 && (
                <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-[#F26B4B] text-white">
                  {countBaru} Baru
                </span>
              )}
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('sos')}
              className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                activeTab === 'sos'
                  ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
                  : 'text-[#4A5248] hover:text-[#1B1F1A]'
              }`}
            >
              <LifeBuoy className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
              <span>Siaga Darurat SOS &amp; SAR</span>
              {activeSosCount > 0 && (
                <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-[#F26B4B] text-white animate-pulse">
                  {activeSosCount} Sinyal
                </span>
              )}
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('hazard')}
              className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                activeTab === 'hazard'
                  ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
                  : 'text-[#4A5248] hover:text-[#1B1F1A]'
              }`}
            >
              <AlertTriangle className="w-4 h-4 text-[#CA8A04]" aria-hidden="true" />
              <span>Peringatan Jalur Rawan</span>
              <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24] font-bold">
                {hazardAlerts.length} Jalur
              </span>
            </button>
          </div>
        </div>
      </header>

      {/* ==================================================================== */}
      {/* TAB 1: PENINDAKAN ADUAN PUNGLI & FASILITAS                           */}
      {/* ==================================================================== */}
      {activeTab === 'pungli' && (
        <div className="space-y-6">
          {/* 4 Kartu KPI Ringkasan Aduan */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-[#D95637]">Laporan Baru</span>
                <span className="w-2.5 h-2.5 rounded-full bg-[#F26B4B] animate-ping" />
              </div>
              <div className="mt-3 text-3xl font-extrabold text-[#1B1F1A]">
                {countBaru}
              </div>
              <p className="mt-1 text-[11px] text-[#4A5248]">
                Menunggu verifikasi bukti
              </p>
            </div>

            <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
              <span className="text-xs font-bold text-[#854D0E]">
                Sedang Diverifikasi
              </span>
              <div className="mt-3 text-3xl font-extrabold text-[#1B1F1A]">
                {countVerif}
              </div>
              <p className="mt-1 text-[11px] text-[#4A5248]">
                Pengecekan lapangan &amp; Perda
              </p>
            </div>

            <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
              <span className="text-xs font-bold text-[#1E40AF]">
                Ditindaklanjuti Lapangan
              </span>
              <div className="mt-3 text-3xl font-extrabold text-[#1B1F1A]">
                {countTindak}
              </div>
              <p className="mt-1 text-[11px] text-[#4A5248]">
                Satgas / Pol PP bertindak
              </p>
            </div>

            <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
              <span className="text-xs font-bold text-[#166534]">
                Selesai Ditertibkan
              </span>
              <div className="mt-3 text-3xl font-extrabold text-[#1B1F1A]">
                {countSelesai}
              </div>
              <p className="mt-1 text-[11px] text-[#4A5248]">
                Sanksi &amp; perbaikan terlaksana
              </p>
            </div>
          </div>

          {/* Filter Bar & Search */}
          <div className="bg-white rounded-[24px] p-5 shadow-sm border border-[#E4E9DA] flex flex-col md:flex-row md:items-center justify-between gap-3">
            <div className="relative flex-1">
              <label htmlFor={searchInputId} className="sr-only">
                Cari laporan aduan
              </label>
              <Search
                className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]"
                aria-hidden="true"
              />
              <input
                id={searchInputId}
                type="search"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Cari nama wisatawan, destinasi, kab/kota, atau isi aduan..."
                className="w-full min-h-[44px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
              />
            </div>

            <div className="flex flex-wrap items-center gap-2.5">
              <label htmlFor={statusFilterId} className="sr-only">
                Filter Status
              </label>
              <select
                id={statusFilterId}
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                <option value="all">Semua Status</option>
                <option value="Laporan Baru">Laporan Baru</option>
                <option value="Sedang Diverifikasi">Sedang Diverifikasi</option>
                <option value="Ditindaklanjuti Lapangan">Ditindaklanjuti Lapangan</option>
                <option value="Selesai">Selesai</option>
              </select>

              <label htmlFor={categoryFilterId} className="sr-only">
                Filter Kategori
              </label>
              <select
                id={categoryFilterId}
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                <option value="all">Semua Kategori</option>
                <option value="Parkir Liar">Parkir Liar</option>
                <option value="Tiket Di Atas Perda">Tiket Di Atas Perda</option>
                <option value="Pemaksaan Pemandu/Kapal">Pemaksaan Pemandu/Kapal</option>
                <option value="Fasilitas Rusak">Fasilitas Rusak</option>
              </select>
            </div>
          </div>

          {/* Tabel Tiket Aduan Pungli & Fasilitas */}
          <div className="bg-white rounded-[24px] shadow-sm border border-[#E4E9DA] overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-[#E4E9DA] bg-[#F6F3EC]/70 text-[11px] font-bold text-[#4A5248] uppercase tracking-wider">
                    <th scope="col" className="py-3.5 px-4">
                      Tiket / Tanggal
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Lokasi Destinasi
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Wisatawan Pelapor
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Kategori Aduan
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Dipungut vs Perda
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Status Tindakan
                    </th>
                    <th scope="col" className="py-3.5 px-4 text-right">
                      Aksi Verifikasi
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA] text-xs text-[#1B1F1A]">
                  {filteredPungli.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-xs text-[#767676]">
                        Tidak ada aduan pungli yang cocok dengan kriteria filter.
                      </td>
                    </tr>
                  ) : (
                    filteredPungli.map((report) => {
                      const statusMeta = getPungliStatusMeta(report.status);
                      const isOvercharge =
                        report.reported_amount > report.official_amount;

                      return (
                        <tr
                          key={report.id}
                          className="hover:bg-[#F6F3EC]/40 transition"
                        >
                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <span className="font-mono font-bold text-[#234B24]">
                              {report.id.toUpperCase()}
                            </span>
                            <div className="text-[10px] text-[#767676] mt-0.5">
                              {new Date(report.created_at).toLocaleDateString(
                                'id-ID',
                                {
                                  day: '2-digit',
                                  month: 'short',
                                  year: 'numeric',
                                  hour: '2-digit',
                                  minute: '2-digit',
                                }
                              )}
                            </div>
                          </td>

                          <td className="py-3.5 px-4 min-w-[180px]">
                            <div className="font-extrabold text-[#1B1F1A]">
                              {report.destination_name}
                            </div>
                            <div className="text-[11px] text-[#4A5248] flex items-center gap-1 mt-0.5">
                              <MapPin className="w-3 h-3 text-[#234B24]" aria-hidden="true" />
                              <span>{report.kab_kota}</span>
                            </div>
                          </td>

                          <td className="py-3.5 px-4 min-w-[160px]">
                            <div className="font-bold text-[#1B1F1A]">
                              {report.reporter_name}
                            </div>
                            <div className="text-[11px] text-[#767676] flex items-center gap-1 mt-0.5">
                              <Phone className="w-3 h-3 text-[#767676]" aria-hidden="true" />
                              <span>{report.reporter_phone}</span>
                            </div>
                          </td>

                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <span className="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                              {report.category}
                            </span>
                          </td>

                          <td className="py-3.5 px-4 min-w-[170px]">
                            {report.category === 'Fasilitas Rusak' ? (
                              <span className="text-[11px] text-[#767676]">
                                Laporan Fisik Sarana
                              </span>
                            ) : (
                              <div>
                                <div className="font-extrabold text-[#D95637]">
                                  Rp {report.reported_amount.toLocaleString('id-ID')}
                                </div>
                                <div className="text-[10px] text-[#166534]">
                                  Resmi: Rp {report.official_amount.toLocaleString('id-ID')}
                                </div>
                                {isOvercharge && (
                                  <div className="text-[9px] font-bold text-[#D95637]">
                                    (Selisih +Rp{' '}
                                    {(
                                      report.reported_amount - report.official_amount
                                    ).toLocaleString('id-ID')}
                                    )
                                  </div>
                                )}
                              </div>
                            )}
                          </td>

                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <span
                              className={`px-2.5 py-1 rounded-full text-[11px] font-bold border ${statusMeta.bg} ${statusMeta.text} ${statusMeta.border}`}
                            >
                              {report.status}
                            </span>
                          </td>

                          <td className="py-3.5 px-4 text-right whitespace-nowrap">
                            <button
                              type="button"
                              onClick={() => {
                                setSelectedPungli(report);
                                setAdminNoteInput(report.admin_notes || '');
                              }}
                              className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 transition shadow-xs"
                            >
                              <FileText className="w-3.5 h-3.5" aria-hidden="true" />
                              <span>Tindak Lanjut</span>
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* TAB 2: SIAGA DARURAT SOS GPS & KOORDINASI TIM SAR                   */}
      {/* ==================================================================== */}
      {activeTab === 'sos' && (
        <div className="space-y-6">
          {/* Alert Peringatan Siaga SAR Aktif */}
          {activeSosCount > 0 ? (
            <div className="p-5 rounded-[24px] bg-[#F26B4B]/15 border-2 border-[#F26B4B] flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex items-center gap-3.5">
                <div className="w-12 h-12 rounded-2xl bg-[#F26B4B] text-white flex items-center justify-center animate-bounce shrink-0">
                  <LifeBuoy className="w-6 h-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-base font-extrabold text-[#1B1F1A]">
                    Terdapat {activeSosCount} Sinyal Darurat SOS Wisatawan Aktif di Lapangan!
                  </h2>
                  <p className="text-xs text-[#4A5248]">
                    Segera lakukan konfirmasi kontak dan koordinasi pengerahan tim evakuasi Basarnas Padang / BPBD wilayah terdekat.
                  </p>
                </div>
              </div>
              <div className="px-3.5 py-1.5 rounded-full bg-[#F26B4B] text-white text-xs font-extrabold self-start sm:self-center">
                SIAGA MERAH TINGKAT 1
              </div>
            </div>
          ) : (
            <div className="p-4 rounded-[20px] bg-[#DCFCE7] border border-[#86EFAC] flex items-center gap-3">
              <CheckCircle2 className="w-5 h-5 text-[#16A34A] shrink-0" aria-hidden="true" />
              <p className="text-xs font-bold text-[#166534]">
                Kondisi Lapangan Terkendali — Tidak ada sinyal darurat SOS wisatawan aktif saat ini.
              </p>
            </div>
          )}

          {/* Daftar Tiket Sinyal Darurat SOS */}
          <div className="bg-white rounded-[24px] p-6 shadow-sm border border-[#E4E9DA] space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <LifeBuoy className="w-5 h-5 text-[#F26B4B]" aria-hidden="true" />
                  <span>Daftar Tiket Sinyal Darurat SOS GPS ({sosTickets.length})</span>
                </h2>
                <p className="text-xs text-[#4A5248]">
                  Data telemetri langsung dari aplikasi wisatawan: Titik GPS, sisa baterai ponsel, dan kondisi sinyal kawasan.
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {sosTickets.map((ticket) => {
                const statusMeta = getSosStatusMeta(ticket.status);
                const isBatteryLow = ticket.battery_level < 20;

                return (
                  <div
                    key={ticket.id}
                    className="p-5 rounded-2xl border-2 border-[#CFD8BE] hover:border-[#234B24] transition bg-[#F6F3EC]/50 flex flex-col justify-between space-y-4"
                  >
                    <div>
                      {/* Baris Atas: Status & Tiket */}
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <span className="font-mono text-xs font-bold text-[#234B24]">
                            {ticket.id.toUpperCase()}
                          </span>
                          <h3 className="text-sm font-extrabold text-[#1B1F1A] mt-0.5">
                            {ticket.tourist_name}
                          </h3>
                          <div className="text-xs text-[#4A5248] flex items-center gap-1.5 mt-0.5">
                            <Phone className="w-3.5 h-3.5 text-[#234B24]" aria-hidden="true" />
                            <span>{ticket.tourist_phone}</span>
                          </div>
                        </div>

                        <span
                          className={`px-3 py-1 rounded-full text-xs font-extrabold shadow-xs ${
                            statusMeta.bg
                          } ${statusMeta.text} ${
                            statusMeta.pulse ? 'animate-pulse' : ''
                          }`}
                        >
                          {ticket.status}
                        </span>
                      </div>

                      {/* Lokasi & Telemetri */}
                      <div className="mt-3 p-3 rounded-xl bg-white border border-[#E4E9DA] space-y-2">
                        <div className="flex items-start justify-between gap-2 text-xs">
                          <div className="flex items-center gap-1.5 font-bold text-[#1B1F1A]">
                            <MapPin className="w-3.5 h-3.5 text-[#F26B4B]" aria-hidden="true" />
                            <span>
                              {ticket.destination_name} ({ticket.kab_kota})
                            </span>
                          </div>
                          <a
                            href={`https://maps.google.com/?q=${ticket.lat},${ticket.lng}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-[11px] font-bold text-[#1D4ED8] hover:underline flex items-center gap-1 shrink-0"
                          >
                            <span>Buka Maps</span>
                            <ExternalLink className="w-3 h-3" aria-hidden="true" />
                          </a>
                        </div>

                        <div className="flex items-center justify-between text-xs pt-1 border-t border-black/5">
                          <div className="flex items-center gap-1.5">
                            <Battery
                              className={`w-3.5 h-3.5 ${
                                isBatteryLow ? 'text-[#D95637]' : 'text-[#16A34A]'
                              }`}
                              aria-hidden="true"
                            />
                            <span
                              className={`font-mono font-bold ${
                                isBatteryLow ? 'text-[#D95637]' : 'text-[#1B1F1A]'
                              }`}
                            >
                              Baterai: {ticket.battery_level}%
                            </span>
                          </div>

                          <div className="flex items-center gap-1.5 text-[11px] text-[#4A5248]">
                            <Wifi className="w-3 h-3 text-[#234B24]" aria-hidden="true" />
                            <span>{ticket.signal_status}</span>
                          </div>
                        </div>
                      </div>

                      {/* Catatan Medis & Situasi Darurat */}
                      <div className="mt-3 p-3 rounded-xl bg-[#FEF08A]/40 border border-[#FDE047]/60">
                        <div className="text-[11px] font-bold text-[#854D0E] flex items-center gap-1 mb-1">
                          <AlertTriangle className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Kondisi Medis &amp; Darurat Lapangan:</span>
                        </div>
                        <p className="text-xs text-[#1B1F1A] font-medium leading-relaxed">
                          {ticket.medical_notes}
                        </p>
                      </div>

                      {ticket.sar_unit_assigned && (
                        <div className="mt-2 text-xs font-bold text-[#1E40AF] flex items-center gap-1.5">
                          <Truck className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Unit Ditugaskan: {ticket.sar_unit_assigned}</span>
                        </div>
                      )}
                    </div>

                    <div className="pt-3 border-t border-[#CFD8BE] flex items-center justify-between gap-2">
                      <span className="text-[10px] text-[#767676]">
                        Dilaporkan:{' '}
                        {new Date(ticket.created_at).toLocaleTimeString('id-ID', {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedSos(ticket);
                          setAssignedSarUnit(ticket.sar_unit_assigned || '');
                          setSelectedSosStatus(ticket.status);
                        }}
                        className="min-h-[40px] px-4 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
                      >
                        <LifeBuoy className="w-3.5 h-3.5 text-[#F26B4B]" aria-hidden="true" />
                        <span>Kerahkan / Perbarui SAR</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* TAB 3: TRIGGER PERINGATAN JALUR RAWAN / BENCANA (LIVE HAZARD ALERT)  */}
      {/* ==================================================================== */}
      {activeTab === 'hazard' && (
        <div className="space-y-6">
          {/* Banner Peringatan Siaga Darurat */}
          <div className="bg-[#234B24] text-[#F6F3EC] rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#1E9E5A] flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 rounded-2xl bg-[#F26B4B] text-white flex items-center justify-center shrink-0 shadow-md">
                <AlertTriangle className="w-6 h-6 animate-pulse" aria-hidden="true" />
              </div>
              <div>
                <span className="px-3 py-1 rounded-full text-[10px] font-extrabold uppercase tracking-wider bg-white/15 text-[#A7F3D0]">
                  SISTEM BROADCAST KESELAMATAN JALUR SUMBAR (LIVE)
                </span>
                <h2 className="text-lg lg:text-xl font-extrabold mt-1.5 text-white">
                  Pusat Kendali 5 Jalur Rawan Bencana &amp; Titik Ekstrem
                </h2>
                <p className="text-xs text-[#E4E9DA]/90 mt-1 max-w-2xl leading-relaxed">
                  Setiap perubahan status jalur di bawah ini langsung disiarkan secara *real-time* ke aplikasi mobile wisatawan, notifikasi offline pocket, dan plang Smart QR destinasi terkait.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 shrink-0">
              <span className="text-xs font-bold text-[#A7F3D0] flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#1E9E5A] animate-ping" />
                Live Broadcast Aktif
              </span>
            </div>
          </div>

          {/* Panel Kontrol Status Jalur Rawan Bencana (Hazard Zone Alerts) */}
          <div className="bg-white rounded-[24px] p-6 shadow-sm border border-[#E4E9DA] space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div>
                <h3 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Navigation className="w-5 h-5 text-[#234B24]" aria-hidden="true" />
                  <span>Daftar 5 Jalur Ekstrem Rawan Longsor &amp; Bencana Sumbar</span>
                </h3>
                <p className="text-xs text-[#4A5248]">
                  Pembaruan status Sitinjau Lauik, Lembah Anai, Kelok 9, Malalak, dan Kelok 44 beserta rute alternatif resmi.
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {hazardAlerts.map((hazard) => {
                const meta = getHazardSeverityMeta(hazard.severity);

                return (
                  <div
                    key={hazard.id}
                    className="p-5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col justify-between space-y-3 hover:shadow-md transition"
                  >
                    <div>
                      <div className="flex items-start justify-between gap-2">
                        <h4 className="text-sm font-extrabold text-[#1B1F1A] leading-snug">
                          {hazard.location}
                        </h4>
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-extrabold border shrink-0 flex items-center gap-1.5 ${meta.badge}`}
                        >
                          <span className={`w-2 h-2 rounded-full ${meta.dot}`} />
                          <span>{hazard.severity}</span>
                        </span>
                      </div>

                      <p className="mt-2 text-xs text-[#4A5248] leading-relaxed">
                        {hazard.message}
                      </p>

                      <div className="mt-2.5 p-2.5 rounded-xl bg-white border border-[#CFD8BE] text-xs">
                        <span className="font-bold text-[#234B24]">Jalur Pengalihan: </span>
                        <span className="text-[#1B1F1A]">{hazard.detour_route}</span>
                      </div>
                    </div>

                    <div className="pt-3 border-t border-[#CFD8BE] flex items-center justify-between">
                      <span className="text-[10px] text-[#767676]">
                        Diperbarui:{' '}
                        {new Date(hazard.updated_at).toLocaleTimeString('id-ID', {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedHazard(hazard);
                          setHazardSeverity(hazard.severity);
                          setHazardMessage(hazard.message);
                          setHazardDetour(hazard.detour_route);
                        }}
                        className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold text-xs shadow-xs transition"
                      >
                        Ubah Status Jalur
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL VERIFIKASI & PENINDAKAN LAPORAN PUNGLI                        */}
      {/* ==================================================================== */}
      {selectedPungli && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="pungli-modal-title"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-2xl p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shadow-xs">
                  <ShieldAlert className="w-5 h-5" aria-hidden="true" />
                </div>
                <div>
                  <h3
                    id="pungli-modal-title"
                    className="text-base font-extrabold text-[#1B1F1A]"
                  >
                    Verifikasi Laporan {selectedPungli.id.toUpperCase()}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Destinasi: {selectedPungli.destination_name} · {selectedPungli.kab_kota}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedPungli(null)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <div className="mt-5 space-y-4">
              {/* Bukti Foto & Koordinat Lokasi */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <span className="block text-xs font-bold text-[#1B1F1A] mb-1.5">
                    Bukti Foto Kejadian / Karcis
                  </span>
                  <div className="w-full aspect-[4/3] rounded-2xl overflow-hidden bg-black/10 border border-[#CFD8BE]">
                    <img
                      src={selectedPungli.photo_url}
                      alt="Bukti foto laporan"
                      className="w-full h-full object-cover"
                    />
                  </div>
                </div>

                <div className="space-y-3">
                  <div>
                    <span className="block text-xs font-bold text-[#1B1F1A] mb-1">
                      Data Pelapor
                    </span>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs">
                      <div className="font-extrabold text-[#1B1F1A]">
                        {selectedPungli.reporter_name}
                      </div>
                      <div className="text-[11px] text-[#4A5248] mt-0.5">
                        Kontak: {selectedPungli.reporter_phone}
                      </div>
                      <div className="text-[11px] text-[#767676] mt-0.5">
                        Dilaporkan:{' '}
                        {new Date(selectedPungli.created_at).toLocaleString('id-ID')}
                      </div>
                    </div>
                  </div>

                  <div>
                    <span className="block text-xs font-bold text-[#1B1F1A] mb-1">
                      Titik Koordinat GPS Kejadian
                    </span>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs flex items-center justify-between">
                      <span className="font-mono text-[#234B24]">
                        {selectedPungli.lat.toFixed(4)}, {selectedPungli.lng.toFixed(4)}
                      </span>
                      <a
                        href={`https://maps.google.com/?q=${selectedPungli.lat},${selectedPungli.lng}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-[11px] font-bold text-[#1D4ED8] flex items-center gap-1"
                      >
                        <span>Lihat Google Maps</span>
                        <ExternalLink className="w-3 h-3" aria-hidden="true" />
                      </a>
                    </div>
                  </div>
                </div>
              </div>

              {/* Rincian Pelanggaran & Selisih Tarif */}
              <div className="p-4 rounded-2xl bg-[#FFEDD5]/60 border border-[#FDBA74]">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-bold text-[#C2410C]">
                    Kategori: {selectedPungli.category}
                  </span>
                  <span className="text-xs font-bold text-[#D95637]">
                    Nominal Dipungut: Rp{' '}
                    {selectedPungli.reported_amount.toLocaleString('id-ID')}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs text-[#166534] font-bold pt-1 border-t border-[#FDBA74]">
                  <span>Standar Tarif Resmi Perda:</span>
                  <span>
                    Rp {selectedPungli.official_amount.toLocaleString('id-ID')}
                  </span>
                </div>
                {selectedPungli.reported_amount > selectedPungli.official_amount && (
                  <div className="mt-1 text-right text-xs font-extrabold text-[#D95637]">
                    Selisih Pungli Oknum: +Rp{' '}
                    {(
                      selectedPungli.reported_amount - selectedPungli.official_amount
                    ).toLocaleString('id-ID')}
                  </div>
                )}
                <p className="mt-2 text-xs text-[#1B1F1A] leading-relaxed">
                  &quot;{selectedPungli.description}&quot;
                </p>
              </div>

              {/* Form Input Catatan Tindakan Resmi Admin */}
              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Catatan Tindakan Resmi Administrator / Tim Saber Pungli
                </label>
                <textarea
                  rows={3}
                  value={adminNoteInput}
                  onChange={(e) => setAdminNoteInput(e.target.value)}
                  placeholder="Contoh: Petugas lapangan telah menertibkan juru parkir tanpa karcis resmi dan menyita rompi liar..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              {/* Tombol Perubahan Status Laporan */}
              <div className="pt-4 border-t border-[#E4E9DA]">
                <span className="block text-xs font-bold text-[#1B1F1A] mb-2.5">
                  Tindakan Otoritas &amp; Pembaruan Status Tiket:
                </span>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                  <button
                    type="button"
                    disabled={isUpdatingPungli}
                    onClick={() => handleUpdatePungliStatus('Sedang Diverifikasi')}
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-[#FEF08A] hover:bg-[#FDE047] text-[#854D0E] font-bold text-xs flex items-center justify-center gap-1.5 transition"
                  >
                    <span>Verifikasi Laporan</span>
                  </button>

                  <button
                    type="button"
                    disabled={isUpdatingPungli}
                    onClick={() =>
                      handleUpdatePungliStatus('Ditindaklanjuti Lapangan')
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-[#BFDBFE] hover:bg-[#93C5FD] text-[#1E40AF] font-bold text-xs flex items-center justify-center gap-1.5 transition"
                  >
                    <span>Tindak di Lapangan</span>
                  </button>

                  <button
                    type="button"
                    disabled={isUpdatingPungli}
                    onClick={() => handleUpdatePungliStatus('Selesai')}
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center justify-center gap-1.5 transition shadow-sm"
                  >
                    <CheckCircle2 className="w-4 h-4 text-[#A7F3D0]" aria-hidden="true" />
                    <span>Selesaikan Laporan</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL PENUGASAN TIM SAR & UPDATE EVAKUASI                            */}
      {/* ==================================================================== */}
      {selectedSos && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="sos-modal-title"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA]">
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shadow-xs">
                  <LifeBuoy className="w-5 h-5" aria-hidden="true" />
                </div>
                <div>
                  <h3
                    id="sos-modal-title"
                    className="text-base font-extrabold text-[#1B1F1A]"
                  >
                    Koordinasi Evakuasi SAR — {selectedSos.id.toUpperCase()}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Wisatawan: {selectedSos.tourist_name} ({selectedSos.tourist_phone})
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedSos(null)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <div className="mt-5 space-y-4">
              <div className="p-3.5 rounded-xl bg-[#FEF08A]/40 border border-[#FDE047] text-xs space-y-1.5">
                <div className="font-bold text-[#854D0E]">
                  Lokasi: {selectedSos.destination_name} ({selectedSos.kab_kota})
                </div>
                <div className="text-[#1B1F1A]">
                  Catatan Medis: <em>&quot;{selectedSos.medical_notes}&quot;</em>
                </div>
                <div className="font-mono text-[#234B24] font-bold">
                  GPS: {selectedSos.lat.toFixed(5)}, {selectedSos.lng.toFixed(5)} · Baterai: {selectedSos.battery_level}%
                </div>
              </div>

              <div>
                <label
                  htmlFor={sarUnitInputId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Unit SAR / BPBD / Pokdarwis yang Ditugaskan
                </label>
                <input
                  id={sarUnitInputId}
                  type="text"
                  value={assignedSarUnit}
                  onChange={(e) => setAssignedSarUnit(e.target.value)}
                  placeholder="Contoh: Pos SAR Basarnas Padang Pariaman & Relawan Pokdarwis (6 Personil)"
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Status Evakuasi SAR
                </label>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    'Sinyal SOS Masuk',
                    'Tim SAR Dikerahkan',
                    'Evakuasi Berjalan',
                    'Penanganan Selesai',
                  ].map((st) => (
                    <button
                      key={st}
                      type="button"
                      onClick={() =>
                        setSelectedSosStatus(st as SosEmergencyStatus)
                      }
                      className={`min-h-[42px] px-3 py-1.5 rounded-xl text-xs font-bold transition border ${
                        selectedSosStatus === st
                          ? 'bg-[#234B24] text-[#F6F3EC] border-[#234B24]'
                          : 'bg-[#F6F3EC] text-[#4A5248] border-[#CFD8BE] hover:bg-[#E4E9DA]'
                      }`}
                    >
                      {st}
                    </button>
                  ))}
                </div>
              </div>

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#E4E9DA]">
                <button
                  type="button"
                  onClick={() => setSelectedSos(null)}
                  className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="button"
                  disabled={isUpdatingSos}
                  onClick={handleUpdateSosStatus}
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm"
                >
                  <Save className="w-4 h-4" aria-hidden="true" />
                  <span>Simpan Status SAR</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL PERBARUI STATUS JALUR RAWAN (HAZARD ZONE)                     */}
      {/* ==================================================================== */}
      {selectedHazard && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="hazard-modal-title"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA]">
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-xs">
                  <Navigation className="w-5 h-5" aria-hidden="true" />
                </div>
                <div>
                  <h3
                    id="hazard-modal-title"
                    className="text-base font-extrabold text-[#1B1F1A]"
                  >
                    Status Peringatan: {selectedHazard.location}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Informasi ini langsung terbit di peta peringatan dini wisatawan
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedHazard(null)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <form onSubmit={handleSaveHazardAlert} className="mt-5 space-y-4">
              <div>
                <label
                  htmlFor={hazardSeverityId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Tingkat Status Jalur
                </label>
                <select
                  id={hazardSeverityId}
                  value={hazardSeverity}
                  onChange={(e) =>
                    setHazardSeverity(e.target.value as HazardSeverity)
                  }
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="Aman Terkendali">Aman Terkendali (Lalu Lintas Lancar)</option>
                  <option value="Waspada Bencana">Waspada Bencana (Curah Hujan Tinggi/Potensi Longsor)</option>
                  <option value="Buka-Tutup Jalur">Buka-Tutup Jalur (Pembersihan Material Jalan)</option>
                  <option value="Tutup Total">Tutup Total (Akses Terputus/Darurat)</option>
                </select>
              </div>

              <div>
                <label
                  htmlFor={hazardMsgId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Pesan Peringatan kepada Wisatawan
                </label>
                <textarea
                  id={hazardMsgId}
                  rows={3}
                  value={hazardMessage}
                  onChange={(e) => setHazardMessage(e.target.value)}
                  required
                  placeholder="Jelaskan kondisi jalan, curah hujan, atau himbauan ke pengemudi..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div>
                <label
                  htmlFor={hazardDetourId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Rute Pengalihan / Jalur Alternatif
                </label>
                <input
                  id={hazardDetourId}
                  type="text"
                  value={hazardDetour}
                  onChange={(e) => setHazardDetour(e.target.value)}
                  placeholder="Contoh: Jalur Utama Beroperasi Normal / Alternatif via Malalak"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#E4E9DA]">
                <button
                  type="button"
                  onClick={() => setSelectedHazard(null)}
                  className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm"
                >
                  <Save className="w-4 h-4" aria-hidden="true" />
                  <span>Simpan Status Jalur</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
