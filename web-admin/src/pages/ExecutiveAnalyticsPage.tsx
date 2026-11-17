import React, { useState, useEffect, useMemo } from 'react';
import {
  BarChart3,
  MapPin,
  TrendingUp,
  Download,
  Printer,
  ShieldCheck,
  CheckCircle2,
  XCircle,
  Eye,
  EyeOff,
  Users,
  Compass,
  DollarSign,
  Award,
  Sparkles,
  Building2,
  FileSpreadsheet,
  Layers,
  Filter,
} from 'lucide-react';
import {
  CommunityHiddenGemSubmission,
  Destination,
  DigitalPassportMetrics,
  Partner,
  RegencyCrowdStatus,
  RegencyHeatmapData,
} from '../types/contract';
import {
  fetchCommunitySubmissions,
  fetchDigitalPassportMetrics,
  fetchRegencyHeatmap,
  updateCommunitySubmission,
} from '../services/api';

interface ExecutiveAnalyticsPageProps {
  destinations: Destination[];
  partners: Partner[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const ExecutiveAnalyticsPage: React.FC<ExecutiveAnalyticsPageProps> = ({
  destinations,
  partners,
  showToast,
}) => {
  const [heatmapData, setHeatmapData] = useState<RegencyHeatmapData[]>([]);
  const [submissions, setSubmissions] = useState<CommunityHiddenGemSubmission[]>([]);
  const [passportMetrics, setPassportMetrics] =
    useState<DigitalPassportMetrics | null>(null);
  const [loading, setLoading] = useState(true);

  // Filters for Heatmap
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchRegency, setSearchRegency] = useState<string>('');

  useEffect(() => {
    const loadAnalytics = async () => {
      setLoading(true);
      try {
        const [heat, subs, passport] = await Promise.all([
          fetchRegencyHeatmap(),
          fetchCommunitySubmissions(),
          fetchDigitalPassportMetrics(),
        ]);
        setHeatmapData(heat);
        setSubmissions(subs);
        setPassportMetrics(passport);
      } catch {
        showToast('Gagal memuat analitik eksekutif.', 'error');
      } finally {
        setLoading(false);
      }
    };
    loadAnalytics();
  }, []);

  // Filtered Regencies
  const filteredRegencies = useMemo(() => {
    return heatmapData.filter((item) => {
      const matchSearch = item.name.toLowerCase().includes(searchRegency.toLowerCase());
      const matchStatus =
        statusFilter === 'all'
          ? true
          : statusFilter === 'high'
          ? item.crowd_status === 'Ramai' || item.crowd_status === 'Overload'
          : item.crowd_status === statusFilter;
      return matchSearch && matchStatus;
    });
  }, [heatmapData, searchRegency, statusFilter]);

  // Aggregate Metrics
  const totalWeeklyVisitors = useMemo(
    () => heatmapData.reduce((acc, r) => acc + r.visitor_count_week, 0),
    [heatmapData]
  );

  const totalEscrowCirculation = useMemo(
    () => heatmapData.reduce((acc, r) => acc + r.escrow_circulation, 0),
    [heatmapData]
  );

  // Toggle Masking Action
  const handleToggleMasking = async (sub: CommunityHiddenGemSubmission) => {
    const newMasked = !sub.is_masked;
    try {
      const updated = await updateCommunitySubmission(sub.id, {
        is_masked: newMasked,
      });
      setSubmissions(updated);
      showToast(
        `Koordinat "${sub.title}" sekarang ${newMasked ? 'DIBURAMKAN (Wajib Pemandu)' : 'DIBUKA PUBLIK'}.`,
        'info'
      );
    } catch {
      showToast('Gagal memperbarui status proteksi koordinat.', 'error');
    }
  };

  // Approve / Reject Submission
  const handleUpdateStatus = async (
    sub: CommunityHiddenGemSubmission,
    newStatus: 'APPROVED' | 'REJECTED'
  ) => {
    try {
      const updated = await updateCommunitySubmission(sub.id, {
        status: newStatus,
        reviewer_notes:
          newStatus === 'APPROVED'
            ? 'Disetujui Dinas Pariwisata Sumbar dengan proteksi koordinat lokal.'
            : 'Usulan ditolak karena belum memenuhi standar kajian dampak lingkungan.',
      });
      setSubmissions(updated);
      showToast(
        `Usulan destinasi "${sub.title}" berhasil ${newStatus === 'APPROVED' ? 'DISETUJUI' : 'DITOLAK'}.`,
        newStatus === 'APPROVED' ? 'success' : 'warning'
      );
    } catch {
      showToast('Gagal memproses moderasi usulan.', 'error');
    }
  };

  // Export to CSV Function
  const handleExportCSV = () => {
    const headers = [
      'ID Wilayah',
      'Kabupaten/Kota',
      'Status Kepadatan',
      'Kunjungan Mingguan',
      'Wisatawan Domestik (%)',
      'Wisatawan Asing MYR (%)',
      'Destinasi Terpopuler',
      'Perputaran Escrow (IDR)',
    ];

    const rows = heatmapData.map((r) => [
      r.code,
      `"${r.name}"`,
      r.crowd_status,
      r.visitor_count_week,
      `${r.domestic_pct}%`,
      `${r.foreign_myr_pct}%`,
      `"${r.top_destination}"`,
      r.escrow_circulation,
    ]);

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute(
      'download',
      `WISGO_Laporan_Eksekutif_Dispar_Sumbar_${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    showToast('Laporan analitik CSV berhasil diunduh.', 'success');
  };

  return (
    <div className="space-y-6">
      {/* Printable Official Header (Hanya tampil saat Print) */}
      <div className="hidden print:block p-8 border-b-2 border-black text-center mb-6">
        <h2 className="text-xl font-bold uppercase tracking-wider">
          PEMERINTAH PROVINSI SUMATERA BARAT
        </h2>
        <h3 className="text-2xl font-black uppercase">DINAS PARIWISATA</h3>
        <p className="text-xs mt-1">
          Jl. Khatib Sulaiman No. 22, Padang, Sumatera Barat · Portal Ekosistem Wisata Pintar (WISGO)
        </p>
        <div className="mt-4 pt-2 border-t border-black text-xs font-bold flex justify-between">
          <span>LAPORAN EKSEKUTIF KEPADATAN 19 KAB/KOTA &amp; EKONOMI ESCROW NAGARI</span>
          <span>Dicetak: {new Date().toLocaleDateString('id-ID', { dateStyle: 'full' })}</span>
        </div>
      </div>

      {/* Header Utama Layar Admin */}
      <header className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] no-print">
        <div className="flex flex-col gap-5">
          {/* Baris 1: Judul Halaman & Penjelasan Eksekutif */}
          <div className="flex items-start gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm shrink-0 mt-0.5">
              <BarChart3 className="w-6 h-6" aria-hidden="true" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                  Analitik Eksekutif Dinas Pariwisata Sumbar
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  WISGO Command Intel
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1 max-w-3xl leading-relaxed">
                Visualisasi data pergerakan 19 Kabupaten/Kota, monitoring perputaran dana Escrow UMKM Nagari, moderasi tempat sensitif komunitas, dan pelaporan berkala.
              </p>
            </div>
          </div>

          {/* Baris 2: Informasi Wilayah & Tombol Ekspor */}
          <div className="pt-4 border-t border-[#234B24]/10 flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2 text-xs text-[#4A5248]">
              <span>Cakupan Intelijen:</span>
              <strong className="text-[#234B24]">19 Kabupaten/Kota Provinsi Sumatera Barat</strong>
            </div>

            <div className="flex flex-wrap items-center gap-2.5 shrink-0">
              <button
                type="button"
                onClick={handleExportCSV}
                className="min-h-[44px] px-4 py-2 rounded-xl bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24] text-xs font-bold flex items-center gap-2 border border-[#CFD8BE] transition shadow-xs"
              >
                <Download className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                <span>Unduh Data CSV</span>
              </button>
              <button
                type="button"
                onClick={() => window.print()}
                className="min-h-[44px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm transition"
              >
                <Printer className="w-4 h-4 text-[#A7F3D0]" aria-hidden="true" />
                <span>Cetak / Ekspor PDF Resmi</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* 4 Ringkasan Metrik Makro */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Total Kunjungan Mingguan</span>
            <Users className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
          </div>
          <div className="mt-2 text-3xl font-extrabold text-[#234B24]">
            {totalWeeklyVisitors.toLocaleString('id-ID')}
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            19 Kabupaten/Kota Aktif
          </p>
        </div>

        <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Perputaran Escrow Nagari</span>
            <DollarSign className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
          </div>
          <div className="mt-2 text-2xl lg:text-3xl font-extrabold text-[#234B24]">
            Rp {(totalEscrowCirculation / 1000000).toFixed(0)} Jt
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            100% Mengalir ke Kas Nagari
          </p>
        </div>

        <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Wisatawan Check-in Anti-Fake</span>
            <ShieldCheck className="w-4 h-4 text-[#1E9E5A]" aria-hidden="true" />
          </div>
          <div className="mt-2 text-3xl font-extrabold text-[#1E9E5A]">
            {passportMetrics?.total_gps_checkins_verified.toLocaleString('id-ID') || '8.420'}
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Radius Validasi &le; 200m
          </p>
        </div>

        <div className="bg-white rounded-[20px] p-5 shadow-sm border border-[#E4E9DA]">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Sertifikat Digital Gubernur</span>
            <Award className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
          </div>
          <div className="mt-2 text-3xl font-extrabold text-[#F26B4B]">
            {passportMetrics?.total_governor_certificates_issued.toLocaleString('id-ID') || '3.150'}
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Paspor Jelajah Minang Terbit
          </p>
        </div>
      </div>

      {/* ==================================================================== */}
      {/* BAGIAN 1: HEATMAP KEPADATAN 19 KABUPATEN/KOTA & KUNJUNGAN WISATAWAN  */}
      {/* ==================================================================== */}
      <section className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <Compass className="w-5 h-5 text-[#234B24]" aria-hidden="true" />
              <span>1. Heatmap Kepadatan &amp; Kunjungan 19 Kabupaten/Kota Sumbar</span>
            </h2>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Peta visual persebaran beban kunjungan untuk mencegah *over-tourism* dan mendistribusikan wisatawan ke nagari penyangga.
            </p>
          </div>

          {/* Filter Bar */}
          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={() => setStatusFilter('all')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition ${
                statusFilter === 'all'
                  ? 'bg-[#234B24] text-white'
                  : 'bg-[#F6F3EC] text-[#4A5248] hover:bg-[#E4E9DA]'
              }`}
            >
              Semua ({heatmapData.length})
            </button>
            <button
              type="button"
              onClick={() => setStatusFilter('high')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition ${
                statusFilter === 'high'
                  ? 'bg-[#F26B4B] text-white'
                  : 'bg-[#F6F3EC] text-[#4A5248] hover:bg-[#E4E9DA]'
              }`}
            >
              Ramai / Overload
            </button>
            <button
              type="button"
              onClick={() => setStatusFilter('Sedang')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition ${
                statusFilter === 'Sedang'
                  ? 'bg-[#CA8A04] text-white'
                  : 'bg-[#F6F3EC] text-[#4A5248] hover:bg-[#E4E9DA]'
              }`}
            >
              Sedang
            </button>
            <button
              type="button"
              onClick={() => setStatusFilter('Sepi')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition ${
                statusFilter === 'Sepi'
                  ? 'bg-[#1E9E5A] text-white'
                  : 'bg-[#F6F3EC] text-[#4A5248] hover:bg-[#E4E9DA]'
              }`}
            >
              Sepi (Potensi)
            </button>
          </div>
        </div>

        {/* Grid Heatmap 19 Kab/Kota */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filteredRegencies.map((reg) => {
            const isOverload = reg.crowd_status === 'Overload';
            const isRamai = reg.crowd_status === 'Ramai';
            const isSedang = reg.crowd_status === 'Sedang';

            const statusClass = isOverload
              ? 'bg-[#FEE2E2] text-[#991B1B] border-[#FCA5A5]'
              : isRamai
              ? 'bg-[#FFEDD5] text-[#C2410C] border-[#FDBA74]'
              : isSedang
              ? 'bg-[#FEF08A] text-[#854D0E] border-[#FDE047]'
              : 'bg-[#DCFCE7] text-[#166534] border-[#86EFAC]';

            return (
              <div
                key={reg.id}
                className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col justify-between hover:shadow-md transition space-y-3"
              >
                <div>
                  <div className="flex items-start justify-between gap-1">
                    <div>
                      <span className="font-mono text-[10px] text-[#767676] uppercase">
                        {reg.code}
                      </span>
                      <h3 className="font-extrabold text-sm text-[#1B1F1A]">
                        {reg.name}
                      </h3>
                    </div>
                    <span
                      className={`px-2 py-0.5 rounded-full text-[10px] font-extrabold border shrink-0 ${statusClass}`}
                    >
                      {reg.crowd_status}
                    </span>
                  </div>

                  <div className="mt-3 space-y-1 text-xs">
                    <div className="flex justify-between items-center text-[#4A5248]">
                      <span>Kunjungan:</span>
                      <span className="font-extrabold text-[#1B1F1A]">
                        {reg.visitor_count_week.toLocaleString('id-ID')} turis/mg
                      </span>
                    </div>

                    {/* Progress Bar Domestik vs Wisman MYR */}
                    <div className="w-full bg-[#E4E9DA] h-2 rounded-full overflow-hidden flex mt-1">
                      <div
                        style={{ width: `${reg.domestic_pct}%` }}
                        className="bg-[#234B24]"
                        title={`Domestik: ${reg.domestic_pct}%`}
                      />
                      <div
                        style={{ width: `${reg.foreign_myr_pct}%` }}
                        className="bg-[#F26B4B]"
                        title={`Wisman (MYR): ${reg.foreign_myr_pct}%`}
                      />
                    </div>
                    <div className="flex justify-between text-[10px] text-[#767676]">
                      <span>Nusantara {reg.domestic_pct}%</span>
                      <span>Wisman {reg.foreign_myr_pct}%</span>
                    </div>
                  </div>
                </div>

                <div className="pt-2 border-t border-[#CFD8BE] text-[11px] text-[#4A5248]">
                  <div className="truncate">
                    <span className="font-bold text-[#234B24]">Top: </span>
                    <span>{reg.top_destination}</span>
                  </div>
                  <div className="text-[10px] font-bold text-[#1E9E5A] mt-0.5">
                    Escrow: Rp {(reg.escrow_circulation / 1000000).toFixed(1)} Jt
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* ==================================================================== */}
      {/* BAGIAN 2: GRAFIK PERPUTARAN EKONOMI UMKM NAGARI & PASPOR DIGITAL     */}
      {/* ==================================================================== */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Kolom Kiri: Breakdown Escrow 5 Kategori Mitra (Col 7) */}
        <section className="lg:col-span-7 bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-4">
          <div>
            <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-[#234B24]" aria-hidden="true" />
              <span>2. Perputaran Ekonomi Escrow pada 5 Kategori UMKM Nagari</span>
            </h2>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Distribusi realisasi dana yang telah ditransaksikan wisatawan melalui sistem rekening bersama.
            </p>
          </div>

          <div className="space-y-3.5 pt-2">
            {passportMetrics?.escrow_by_category.map((cat) => {
              const maxAmount = 350000000;
              const pct = Math.min(100, Math.round((cat.total_amount / maxAmount) * 100));

              return (
                <div key={cat.category} className="space-y-1.5">
                  <div className="flex justify-between items-center text-xs">
                    <span className="font-extrabold text-[#1B1F1A] flex items-center gap-1.5">
                      <span>{cat.category}</span>
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                        {cat.count} Mitra
                      </span>
                    </span>
                    <span className="font-extrabold text-[#234B24]">
                      Rp {cat.total_amount.toLocaleString('id-ID')}
                    </span>
                  </div>
                  <div className="w-full bg-[#F6F3EC] h-3 rounded-full overflow-hidden border border-[#CFD8BE]">
                    <div
                      style={{ width: `${pct}%` }}
                      className="bg-[#234B24] h-full rounded-full transition-all duration-500"
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        {/* Kolom Kanan: Top 5 Nagari Penerima Escrow & Paspor Digital (Col 5) */}
        <section className="lg:col-span-5 bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-4 flex flex-col justify-between">
          <div>
            <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <Award className="w-5 h-5 text-[#F26B4B]" aria-hidden="true" />
              <span>Top 5 Nagari Mandiri Ekonomi Digital</span>
            </h2>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Nagari dengan integrasi pemesanan WhatsApp bot dan serapan escrow tertinggi.
            </p>

            <div className="mt-4 space-y-2.5">
              {passportMetrics?.top_nagari_escrow.map((nagari, index) => (
                <div
                  key={nagari.nagari}
                  className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs"
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <div className="w-6 h-6 rounded-lg bg-[#234B24] text-white font-extrabold text-xs flex items-center justify-center shrink-0">
                      {index + 1}
                    </div>
                    <span className="font-bold text-[#1B1F1A] truncate">{nagari.nagari}</span>
                  </div>
                  <span className="font-extrabold text-[#1E9E5A] shrink-0">
                    Rp {(nagari.amount / 1000000).toFixed(0)} Jt
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="p-4 rounded-2xl bg-[#E4E9DA]/80 border border-[#CFD8BE] text-xs space-y-1">
            <span className="font-extrabold text-[#234B24] flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
              <span>Sertifikasi Gubernur Anti-Fake GPS:</span>
            </span>
            <p className="text-[#4A5248] leading-relaxed">
              Wisatawan wajib berada dalam radius &le; 200 meter dari plang Smart QR fisik untuk membuka lencana cap paspor digital demi validitas data kunjungan riil.
            </p>
          </div>
        </section>
      </div>

      {/* ==================================================================== */}
      {/* BAGIAN 3: MEJA KURASI TEMPAT SENSITIF KOMUNITAS (MASKING LOKASI)    */}
      {/* ==================================================================== */}
      <section className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-[#234B24]" aria-hidden="true" />
              <span>3. Meja Kurasi Tempat Sensitif Komunitas (Proteksi Masking Koordinat)</span>
            </h2>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Moderasi usulan destinasi baru / *hidden gem* dari Pokdarwis nagari. Sakelar masking menyembunyikan titik GPS presisi untuk menjaga kelestarian adat &amp; mewajibkan pemandu lokal.
            </p>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="bg-[#234B24] text-[#F6F3EC] rounded-xl">
                <th className="p-3.5 rounded-l-xl">Usulan Destinasi</th>
                <th className="p-3.5">Pokdarwis Pengusul</th>
                <th className="p-3.5">Wilayah</th>
                <th className="p-3.5">Proteksi Koordinat GPS</th>
                <th className="p-3.5">Status Moderasi</th>
                <th className="p-3.5 rounded-r-xl text-center">Tindakan Admin</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#CFD8BE]">
              {submissions.map((sub) => (
                <tr key={sub.id} className="hover:bg-[#F6F3EC]/80 transition">
                  <td className="p-3.5">
                    <div className="font-extrabold text-[#1B1F1A] text-sm">
                      {sub.title}
                    </div>
                    <div className="text-[11px] text-[#4A5248] mt-0.5 max-w-xs leading-snug">
                      {sub.description}
                    </div>
                  </td>

                  <td className="p-3.5 font-semibold text-[#234B24]">
                    {sub.pokdarwis_name}
                  </td>

                  <td className="p-3.5 text-[#4A5248]">
                    {sub.city_regency}
                  </td>

                  {/* Sakelar Masking Koordinat */}
                  <td className="p-3.5">
                    <button
                      type="button"
                      onClick={() => handleToggleMasking(sub)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition ${
                        sub.is_masked
                          ? 'bg-[#DBEAFE] text-[#1D4ED8] border border-[#93C5FD]'
                          : 'bg-[#F6F3EC] text-[#767676] border border-[#CFD8BE]'
                      }`}
                    >
                      {sub.is_masked ? (
                        <>
                          <EyeOff className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Koordinat Diburamkan (Masked)</span>
                        </>
                      ) : (
                        <>
                          <Eye className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Koordinat Terbuka Bebas</span>
                        </>
                      )}
                    </button>
                    <span className="text-[10px] text-[#767676] block mt-1">
                      {sub.is_masked
                        ? 'Wajib didampingi pemandu resmi ber-SK Nagari'
                        : 'Bisa diakses mandiri oleh wisatawan'}
                    </span>
                  </td>

                  {/* Status Moderasi */}
                  <td className="p-3.5">
                    <span
                      className={`px-2.5 py-1 rounded-full text-[11px] font-extrabold ${
                        sub.status === 'APPROVED'
                          ? 'bg-[#DCFCE7] text-[#166534]'
                          : sub.status === 'REJECTED'
                          ? 'bg-[#FEE2E2] text-[#991B1B]'
                          : 'bg-[#FEF08A] text-[#854D0E]'
                      }`}
                    >
                      {sub.status === 'APPROVED'
                        ? 'Disetujui Dispar'
                        : sub.status === 'REJECTED'
                        ? 'Ditolak'
                        : 'Menunggu Review'}
                    </span>
                  </td>

                  {/* Tombol Setujui / Tolak */}
                  <td className="p-3.5 text-center">
                    <div className="flex items-center justify-center gap-1.5">
                      {sub.status !== 'APPROVED' && (
                        <button
                          type="button"
                          onClick={() => handleUpdateStatus(sub, 'APPROVED')}
                          className="px-3 py-1.5 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold text-xs shadow-xs transition"
                        >
                          Setujui
                        </button>
                      )}
                      {sub.status !== 'REJECTED' && (
                        <button
                          type="button"
                          onClick={() => handleUpdateStatus(sub, 'REJECTED')}
                          className="px-3 py-1.5 rounded-lg bg-white hover:bg-gray-100 text-[#991B1B] font-bold text-xs border border-[#FCA5A5] shadow-xs transition"
                        >
                          Tolak
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* Kolom Tanda Tangan Cetak PDF (Hanya Tampil Saat Print) */}
      <div className="hidden print:block pt-12 text-xs">
        <div className="flex justify-between items-start">
          <div className="text-center w-64">
            <p>Mengetahui,</p>
            <p className="font-bold">Kepala Dinas Pariwisata</p>
            <p>Provinsi Sumatera Barat</p>
            <div className="h-20" />
            <p className="font-extrabold underline">( DRS. H. LUHUR BUDIANDA, M.SI )</p>
            <p>NIP. 19710815 199603 1 004</p>
          </div>
          <div className="text-center w-64">
            <p>Padang, {new Date().toLocaleDateString('id-ID', { dateStyle: 'long' })}</p>
            <p className="font-bold">Administrator Utama</p>
            <p>Pusat Komando Terpadu WISGO Sumbar</p>
            <div className="h-20" />
            <p className="font-extrabold underline">( SATGAS PUSAT KOMANDO WISGO )</p>
            <p>ID Otoritas: USR-ADMIN-KOMANDO-01</p>
          </div>
        </div>
      </div>
    </div>
  );
};
