import React, { useState, useEffect, useMemo } from 'react';
import {
  BarChart3,
  MapPin,
  TrendingUp,
  Download,
  Printer,
  ShieldCheck,
  CheckCircle2,
  AlertTriangle,
  Clock,
  MessageSquare,
  Store,
  Calendar,
  Flame,
  Activity,
  Sparkles,
  Star,
  FileText,
  Search,
  Filter,
  ArrowUpRight,
  Check,
  ChevronRight,
  Users,
  Compass,
  Building2,
  Info,
  Layers,
  PhoneCall,
  Navigation,
  FileSpreadsheet,
} from 'lucide-react';
import {
  Destination,
  Partner,
  RegencyHeatmapData,
  GaodeRankingItem,
} from '../types/contract';
import {
  fetchRegencyHeatmap,
} from '../services/api';
import { SystemHealthBenchmarkSubTab } from '../components/SystemHealthBenchmarkSubTab';

export type AnalyticsSubTab =
  | 'heatmap_prediction'
  | 'partner_performance'
  | 'incident_recap'
  | 'export_report'
  | 'intel_heatmap' // Backwards compatibility with App.tsx
  | 'system_benchmark';

interface ExecutiveAnalyticsPageProps {
  destinations: Destination[];
  partners: Partner[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  initialSubTab?: AnalyticsSubTab;
}

// ----------------------------------------------------------------------------
// DATA PREDIKSI KUNJUNGAN 7 HARI KE DEPAN (BERBASIS AUTO-ITINERARY ROMBONGAN)
// ----------------------------------------------------------------------------
interface PredictionDay {
  date: string;
  dayName: string;
  groupsCount: number;
  personalTouristsEst: number;
  groupTouristsEst: number;
  touristsEst: number;
  status: 'Normal' | 'Peningkatan' | 'Padat' | 'Puncak (Peak)';
  topDestinations: string[];
}

const PREDICTION_7_DAYS: PredictionDay[] = [
  {
    date: '18 Nov 2026',
    dayName: 'Senin',
    groupsCount: 42,
    personalTouristsEst: 780,
    groupTouristsEst: 470,
    touristsEst: 1250,
    status: 'Normal',
    topDestinations: ['Jam Gadang & Pasar Atas', 'Pantai Padang'],
  },
  {
    date: '19 Nov 2026',
    dayName: 'Selasa',
    groupsCount: 38,
    personalTouristsEst: 720,
    groupTouristsEst: 400,
    touristsEst: 1120,
    status: 'Normal',
    topDestinations: ['Istano Basa Pagaruyung', 'Desa Pariangan'],
  },
  {
    date: '20 Nov 2026',
    dayName: 'Rabu',
    groupsCount: 45,
    personalTouristsEst: 840,
    groupTouristsEst: 500,
    touristsEst: 1340,
    status: 'Normal',
    topDestinations: ['Danau Maninjau', 'Ngarai Sianok'],
  },
  {
    date: '21 Nov 2026',
    dayName: 'Kamis',
    groupsCount: 68,
    personalTouristsEst: 1250,
    groupTouristsEst: 760,
    touristsEst: 2010,
    status: 'Peningkatan',
    topDestinations: ['Lembah Harau', 'Kelok 9', 'Bukittinggi'],
  },
  {
    date: '22 Nov 2026',
    dayName: 'Jumat',
    groupsCount: 95,
    personalTouristsEst: 1700,
    groupTouristsEst: 1150,
    touristsEst: 2850,
    status: 'Padat',
    topDestinations: ['Kawasan Wisata Mandeh', 'Pantai Air Manis', 'Lembah Harau'],
  },
  {
    date: '23 Nov 2026',
    dayName: 'Sabtu',
    groupsCount: 142,
    personalTouristsEst: 2600,
    groupTouristsEst: 1800,
    touristsEst: 4400,
    status: 'Puncak (Peak)',
    topDestinations: ['Lembah Harau', 'Jam Gadang & Bukittinggi', 'Danau Singkarak'],
  },
  {
    date: '24 Nov 2026',
    dayName: 'Minggu',
    groupsCount: 130,
    personalTouristsEst: 2380,
    groupTouristsEst: 1600,
    touristsEst: 3980,
    status: 'Puncak (Peak)',
    topDestinations: ['Lembah Harau', 'Puncak Lawang', 'Desa Pariangan'],
  },
];

// ----------------------------------------------------------------------------
// DATA INTERAKSI WA MITRA UMKM PER DESTINASI (LEADS P2P)
// ----------------------------------------------------------------------------
interface DestinationWaLead {
  destinationName: string;
  cityRegency: string;
  totalClicks: number;
  percentage: number;
  dominantCategory: string;
  categoryIcon: string;
}

const TOP_DESTINATIONS_WA_LEADS: DestinationWaLead[] = [
  {
    destinationName: 'Desa Wisata Pariangan',
    cityRegency: 'Kab. Tanah Datar',
    totalClicks: 2450,
    percentage: 100,
    dominantCategory: 'Homestay & Pemandu Budaya',
    categoryIcon: 'Homestay',
  },
  {
    destinationName: 'Lembah Harau & Sarasah',
    cityRegency: 'Kab. Lima Puluh Kota',
    totalClicks: 2180,
    percentage: 89,
    dominantCategory: 'Pemandu Panjat & Glamping',
    categoryIcon: 'Pemandu',
  },
  {
    destinationName: 'Danau Maninjau & Kelok 44',
    cityRegency: 'Kab. Agam',
    totalClicks: 1840,
    percentage: 75,
    dominantCategory: 'Kuliner Rinuak & Penginapan',
    categoryIcon: 'Kuliner',
  },
  {
    destinationName: 'Istano Basa Pagaruyung',
    cityRegency: 'Kab. Tanah Datar',
    totalClicks: 1620,
    percentage: 66,
    dominantCategory: 'Sewa Busana Adat Suntiang',
    categoryIcon: 'Busana',
  },
  {
    destinationName: 'Kawasan Bahari Mandeh',
    cityRegency: 'Kab. Pesisir Selatan',
    totalClicks: 1490,
    percentage: 61,
    dominantCategory: 'Sewa Kapal Motor Wisata',
    categoryIcon: 'Kapal',
  },
  {
    destinationName: 'Jam Gadang & Pasar Atas',
    cityRegency: 'Kota Bukittinggi',
    totalClicks: 1250,
    percentage: 51,
    dominantCategory: 'Kuliner Kapau & Kerajinan',
    categoryIcon: 'Kuliner',
  },
  {
    destinationName: 'Geopark Silokek',
    cityRegency: 'Kab. Sijunjung',
    totalClicks: 980,
    percentage: 40,
    dominantCategory: 'Pemandu Arung Jeram & Gua',
    categoryIcon: 'Pemandu',
  },
  {
    destinationName: 'Ngalau Indah Payakumbuh',
    cityRegency: 'Kota Payakumbuh',
    totalClicks: 770,
    percentage: 31,
    dominantCategory: 'Pemandu Caving & Kawa Daun',
    categoryIcon: 'Kuliner',
  },
];

// ----------------------------------------------------------------------------
// DATA TOP 5 GAODE RANKING (PERFORMA & KEPUASAN WISATAWAN)
// ----------------------------------------------------------------------------
interface TopGaodeDestination {
  rank: number;
  name: string;
  cityRegency: string;
  gaodeScore: number;
  pungliFreeIndex: number;
  avgDwellHours: number;
  views360Count: number;
  savedToItineraryCount: number;
  trend: 'up' | 'down' | 'same';
}

const TOP_5_GAODE_DESTINATIONS: TopGaodeDestination[] = [
  {
    rank: 1,
    name: 'Desa Terindah Pariangan',
    cityRegency: 'Kab. Tanah Datar',
    gaodeScore: 96.8,
    pungliFreeIndex: 100,
    avgDwellHours: 4.2,
    views360Count: 12450,
    savedToItineraryCount: 1820,
    trend: 'up',
  },
  {
    rank: 2,
    name: 'Lembah Harau & Sarasah',
    cityRegency: 'Kab. Lima Puluh Kota',
    gaodeScore: 94.5,
    pungliFreeIndex: 98.5,
    avgDwellHours: 5.1,
    views360Count: 15600,
    savedToItineraryCount: 2140,
    trend: 'same',
  },
  {
    rank: 3,
    name: 'Istano Basa Pagaruyung',
    cityRegency: 'Kab. Tanah Datar',
    gaodeScore: 92.4,
    pungliFreeIndex: 96.8,
    avgDwellHours: 3.2,
    views360Count: 11200,
    savedToItineraryCount: 1650,
    trend: 'up',
  },
  {
    rank: 4,
    name: 'Kawasan Wisata Bahari Mandeh',
    cityRegency: 'Kab. Pesisir Selatan',
    gaodeScore: 91.0,
    pungliFreeIndex: 95.0,
    avgDwellHours: 6.0,
    views360Count: 9800,
    savedToItineraryCount: 1420,
    trend: 'same',
  },
  {
    rank: 5,
    name: 'Danau Maninjau & Puncak Lawang',
    cityRegency: 'Kab. Agam',
    gaodeScore: 89.7,
    pungliFreeIndex: 94.5,
    avgDwellHours: 3.8,
    views360Count: 8400,
    savedToItineraryCount: 1210,
    trend: 'up',
  },
];

// ----------------------------------------------------------------------------
// DATA INSIDEN & STATUS ADUAN BULAN INI
// ----------------------------------------------------------------------------
interface IncidentCategoryItem {
  name: string;
  count: number;
  percentage: number;
  color: string;
  badgeBg: string;
  badgeText: string;
}

const INCIDENT_CATEGORIES: IncidentCategoryItem[] = [
  {
    name: 'Pungli Parkir Liar',
    count: 23,
    percentage: 42.6,
    color: '#F26B4B', // Koral
    badgeBg: 'bg-[#F26B4B]/15',
    badgeText: 'text-[#D95637]',
  },
  {
    name: 'Tiket Di Luar Perda',
    count: 15,
    percentage: 27.8,
    color: '#F59E0B', // Kuning/Oranye
    badgeBg: 'bg-[#F59E0B]/15',
    badgeText: 'text-[#B45309]',
  },
  {
    name: 'Fasilitas Wisata Rusak',
    count: 10,
    percentage: 18.5,
    color: '#3B82F6', // Biru
    badgeBg: 'bg-[#3B82F6]/15',
    badgeText: 'text-[#1D4ED8]',
  },
  {
    name: 'Panggilan Darurat SOS SAR',
    count: 6,
    percentage: 11.1,
    color: '#EF4444', // Merah Darurat
    badgeBg: 'bg-[#EF4444]/15',
    badgeText: 'text-[#B91C1C]',
  },
];

interface QuickActionLog {
  id: string;
  time: string;
  destination: string;
  incidentType: string;
  responseTimeMinutes: number;
  officer: string;
  actionTaken: string;
  status: 'Selesai' | 'Investigasi' | 'Menunggu';
}

const RECENT_INCIDENT_ACTIONS: QuickActionLog[] = [
  {
    id: 'act-01',
    time: 'Hari ini, 10:15 WIB',
    destination: 'Jam Gadang, Bukittinggi',
    incidentType: 'Parkir Liar Rp 25.000',
    responseTimeMinutes: 14,
    officer: 'Satgas Saber Pungli Bkt',
    actionTaken: 'Oknum diamankan di pos Dishub, tarif dikembalikan ke Perda Rp 5.000.',
    status: 'Selesai',
  },
  {
    id: 'act-02',
    time: 'Hari ini, 08:30 WIB',
    destination: 'Sitinjau Lauik KM 14',
    incidentType: 'SOS Darurat Rem Truk',
    responseTimeMinutes: 11,
    officer: 'Posko Siaga Sitinjau',
    actionTaken: 'Armada derek BPBD dikerahkan, jalur dialihkan sementara ke lajur darurat.',
    status: 'Selesai',
  },
  {
    id: 'act-03',
    time: 'Kemarin, 16:40 WIB',
    destination: 'Kawasan Mandeh, Pessel',
    incidentType: 'Tarif Sewa Kapal Liar',
    responseTimeMinutes: 22,
    officer: 'Tim Wasdal Dispar Pessel',
    actionTaken: 'Pemeriksaan manifest kapal boat, mediasi dengan Pokdarwis Carocok Tarusan.',
    status: 'Selesai',
  },
  {
    id: 'act-04',
    time: 'Kemarin, 11:20 WIB',
    destination: 'Pantai Padang (Taplau)',
    incidentType: 'Fasilitas Penerangan Rusak',
    responseTimeMinutes: 28,
    officer: 'Satpol PP & Dinas PUPR',
    actionTaken: 'Laporan diteruskan ke teknisi lampu taman, perbaikan dijadwalkan.',
    status: 'Investigasi',
  },
];

export const ExecutiveAnalyticsPage: React.FC<ExecutiveAnalyticsPageProps> = ({
  destinations,
  partners,
  showToast,
  initialSubTab = 'heatmap_prediction',
}) => {
  // Normalize initialSubTab: if it's legacy 'intel_heatmap', route to 'heatmap_prediction'
  const normalizedInitialTab =
    initialSubTab === 'intel_heatmap'
      ? 'heatmap_prediction'
      : initialSubTab || 'heatmap_prediction';

  const [activeTab, setActiveTab] = useState<AnalyticsSubTab>(normalizedInitialTab);
  const [heatmapData, setHeatmapData] = useState<RegencyHeatmapData[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters for Heatmap
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchRegency, setSearchRegency] = useState<string>('');

  // Filter for Export Report Period
  const [reportPeriod, setReportPeriod] = useState<'month' | 'quarter' | 'year'>('month');

  // Selected Prediction Day for tooltip/details
  const [selectedPredictionDay, setSelectedPredictionDay] = useState<PredictionDay>(
    PREDICTION_7_DAYS[5] // Default to Saturday Peak
  );

  useEffect(() => {
    if (initialSubTab) {
      if (initialSubTab === 'intel_heatmap') {
        setActiveTab('heatmap_prediction');
      } else {
        setActiveTab(initialSubTab);
      }
    }
  }, [initialSubTab]);

  useEffect(() => {
    const loadAnalytics = async () => {
      setLoading(true);
      try {
        const heat = await fetchRegencyHeatmap();
        setHeatmapData(heat);
      } catch {
        showToast('Gagal memuat data sebaran wilayah.', 'error');
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

  // Aggregate Metrics for Top Bar
  const totalWeeklyVisitors = useMemo(
    () => heatmapData.reduce((acc, r) => acc + r.visitor_count_week, 0) || 148920,
    [heatmapData]
  );

  const totalWaLeads = useMemo(
    () =>
      heatmapData.reduce((acc, r) => acc + (r.wa_leads_count || 0), 0) || 12580,
    [heatmapData]
  );

  // Export to CSV Function
  const handleExportCSV = () => {
    const headers = [
      'Kode Wilayah',
      'Kabupaten/Kota',
      'Status Kepadatan',
      'Total Kunjungan Mingguan',
      'Kunjungan Personal Mandiri (Est 66%)',
      'Kunjungan Rombongan Grup (Est 34%)',
      'Wisatawan Domestik (%)',
      'Wisatawan Asing MYR (%)',
      'Destinasi Terpopuler',
      'Interaksi Leads WA (Klik P2P)',
      'Prediksi Rombongan Liburan (Grup)',
    ];

    const rows = (heatmapData.length > 0 ? heatmapData : [
      { code: 'SB-01', name: 'Kab. Lima Puluh Kota', crowd_status: 'Ramai', visitor_count_week: 16500, domestic_pct: 85, foreign_myr_pct: 15, top_destination: 'Lembah Harau & Sarasah', wa_leads_count: 2180 },
      { code: 'SB-02', name: 'Kota Bukittinggi', crowd_status: 'Overload', visitor_count_week: 22400, domestic_pct: 82, foreign_myr_pct: 18, top_destination: 'Jam Gadang & Pasar Atas', wa_leads_count: 1250 },
      { code: 'SB-03', name: 'Kab. Tanah Datar', crowd_status: 'Sedang', visitor_count_week: 11200, domestic_pct: 88, foreign_myr_pct: 12, top_destination: 'Istano Basa Pagaruyung', wa_leads_count: 4070 },
      { code: 'SB-04', name: 'Kab. Agam', crowd_status: 'Sedang', visitor_count_week: 9800, domestic_pct: 86, foreign_myr_pct: 14, top_destination: 'Danau Maninjau & Kelok 44', wa_leads_count: 1840 },
      { code: 'SB-05', name: 'Kota Padang', crowd_status: 'Ramai', visitor_count_week: 19800, domestic_pct: 91, foreign_myr_pct: 9, top_destination: 'Pantai Air Manis & Malin Kundang', wa_leads_count: 650 },
      { code: 'SB-06', name: 'Kab. Pesisir Selatan', crowd_status: 'Ramai', visitor_count_week: 14200, domestic_pct: 87, foreign_myr_pct: 13, top_destination: 'Kawasan Wisata Bahari Mandeh', wa_leads_count: 1490 },
    ]).map((r: any) => [
      r.code,
      `"${r.name}"`,
      r.crowd_status,
      r.visitor_count_week,
      Math.round(r.visitor_count_week * 0.66),
      Math.round(r.visitor_count_week * 0.34),
      `${r.domestic_pct}%`,
      `${r.foreign_myr_pct}%`,
      `"${r.top_destination}"`,
      r.wa_leads_count || 120,
      r.crowd_status === 'Overload' ? 52 : r.crowd_status === 'Ramai' ? 34 : 14,
    ]);

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute(
      'download',
      `WISGO_Laporan_Eksekutif_Dispar_Sumbar_${reportPeriod}_${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    showToast('Laporan analitik eksekutif (CSV) berhasil diunduh.', 'success');
  };

  const handlePrintOfficialReport = () => {
    window.print();
    showToast('Membuka dialog cetak Dokumen Resmi PDF Dispar Sumbar.', 'info');
  };

  return (
    <div className="space-y-6">
      {/* ==================================================================== */}
      {/* 0. DOKUMEN CETAK RESMI (Hanya Muncul Saat Print / Unduh PDF)          */}
      {/* ==================================================================== */}
      <div id="executive-report-print" className="hidden print:block text-black bg-white">
        {/* Kop Surat Resmi */}
        <div className="border-b-4 border-double border-black pb-4 text-center mb-6">
          <div className="flex items-center justify-center gap-4 mb-2">
            <div className="text-center">
              <h2 className="text-lg font-bold tracking-wider uppercase">
                PEMERINTAH PROVINSI SUMATERA BARAT
              </h2>
              <h1 className="text-2xl font-black uppercase tracking-tight">
                DINAS PARIWISATA
              </h1>
              <p className="text-xs mt-0.5">
                Jl. Khatib Sulaiman No. 22, Padang, Sumatera Barat · Telp. (0751) 7055183 · Email: dispar@sumbarprov.go.id
              </p>
              <p className="text-[11px] font-semibold text-gray-700">
                PORTAL EKOSISTEM WISATA PINTAR SUMATERA BARAT (WISGO)
              </p>
            </div>
          </div>
        </div>

        {/* Metadata Surat Rekap */}
        <div className="flex justify-between items-baseline text-xs mb-4 pb-2 border-b border-gray-400">
          <div>
            <div><strong>Nomor:</strong> 556/412/DISPAR-SUMBAR/XI/2026</div>
            <div><strong>Perihal:</strong> Laporan Eksekutif Manajemen Kunjungan, Interaksi Mitra &amp; Kepatuhan Lapangan</div>
          </div>
          <div className="text-right">
            <div><strong>Periode:</strong> {reportPeriod === 'month' ? 'Bulan Ini (November 2026)' : reportPeriod === 'quarter' ? 'Kuartal IV (Okt - Des 2026)' : 'Tahun Anggaran 2026'}</div>
            <div><strong>Tanggal Terbit:</strong> {new Date().toLocaleDateString('id-ID', { dateStyle: 'long' })}</div>
          </div>
        </div>

        {/* Ringkasan Makro Print */}
        <div className="grid grid-cols-4 gap-3 mb-6 p-3 bg-gray-50 border border-gray-300 rounded text-center text-xs">
          <div>
            <span className="text-[10px] text-gray-600 block">Total Kunjungan Terlacak</span>
            <strong className="text-base text-black">148.920 Wisatawan</strong>
            <span className="text-[9px] text-gray-600 block">Personal: 98.200 | Rombongan: 50.720</span>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Rombongan Terdaftar</span>
            <strong className="text-base text-black">342 Rombongan</strong>
            <span className="text-[9px] text-gray-500 block">Auto-Itinerary &amp; Open Trip</span>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Interaksi Leads WA Mitra</span>
            <strong className="text-base text-black">12.580 Klik P2P</strong>
            <span className="text-[9px] text-gray-500 block">Pemberdayaan UMKM</span>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Rasio Selesai Pungli &amp; SAR</span>
            <strong className="text-base text-black">92.6% (18 Menit SLA)</strong>
            <span className="text-[9px] text-gray-500 block">Pusat Komando Saber &amp; Siaga</span>
          </div>
        </div>

        {/* Tabel Ringkasan Top 5 Gaode Print */}
        <div className="mb-6">
          <h3 className="text-xs font-bold uppercase mb-2">1. Peringkat Kualitas Destinasi (Top 5 Gaode Ranking)</h3>
          <table className="w-full text-xs border border-gray-300 border-collapse">
            <thead>
              <tr className="bg-gray-100 text-left">
                <th className="border p-1.5 text-center">Peringkat</th>
                <th className="border p-1.5">Destinasi</th>
                <th className="border p-1.5">Wilayah</th>
                <th className="border p-1.5 text-center">Skor Gaode</th>
                <th className="border p-1.5 text-center">Bebas Pungli</th>
                <th className="border p-1.5 text-center">Durasi Singgah</th>
                <th className="border p-1.5 text-center">Views 360°</th>
              </tr>
            </thead>
            <tbody>
              {TOP_5_GAODE_DESTINATIONS.map((d) => (
                <tr key={d.rank}>
                  <td className="border p-1.5 text-center font-bold">#{d.rank}</td>
                  <td className="border p-1.5 font-semibold">{d.name}</td>
                  <td className="border p-1.5">{d.cityRegency}</td>
                  <td className="border p-1.5 text-center font-bold">{d.gaodeScore}</td>
                  <td className="border p-1.5 text-center">{d.pungliFreeIndex}%</td>
                  <td className="border p-1.5 text-center">{d.avgDwellHours} Jam</td>
                  <td className="border p-1.5 text-center">{d.views360Count.toLocaleString('id-ID')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Tabel Ringkasan Prediksi 7 Hari Print */}
        <div className="mb-6">
          <h3 className="text-xs font-bold uppercase mb-2">2. Prediksi Kunjungan Personal vs Rombongan (7 Hari ke Depan)</h3>
          <table className="w-full text-xs border border-gray-300 border-collapse">
            <thead>
              <tr className="bg-gray-100 text-left">
                <th className="border p-1.5">Hari / Tanggal</th>
                <th className="border p-1.5 text-center">Personal (Mandiri)</th>
                <th className="border p-1.5 text-center">Rombongan (Grup)</th>
                <th className="border p-1.5 text-center">Total Wisatawan</th>
                <th className="border p-1.5 text-center">Status Beban</th>
                <th className="border p-1.5">Fokus Destinasi Puncak</th>
              </tr>
            </thead>
            <tbody>
              {PREDICTION_7_DAYS.map((p) => (
                <tr key={p.date}>
                  <td className="border p-1.5 font-semibold">{p.dayName}, {p.date}</td>
                  <td className="border p-1.5 text-center font-semibold text-emerald-800">{p.personalTouristsEst.toLocaleString('id-ID')} Org</td>
                  <td className="border p-1.5 text-center font-bold text-orange-700">{p.groupTouristsEst.toLocaleString('id-ID')} Org ({p.groupsCount} Grup)</td>
                  <td className="border p-1.5 text-center font-black">{p.touristsEst.toLocaleString('id-ID')} Org</td>
                  <td className="border p-1.5 text-center font-semibold">{p.status}</td>
                  <td className="border p-1.5">{p.topDestinations.join(', ')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Lembar Tanda Tangan Resmi */}
        <div className="pt-4 flex justify-between items-end text-xs">
          <div>
            <p className="text-[10px] text-gray-500 italic">
              Dokumen ini diterbitkan secara otomatis dan terverifikasi oleh Sistem WISGO Sumbar.<br/>
              Keabsahan data dapat dicek silang melalui Portal Komando Terpadu Dispar.
            </p>
          </div>
          <div className="text-center w-64">
            <p>Padang, 17 November 2026</p>
            <p className="font-bold">Kepala Dinas Pariwisata Provinsi Sumatera Barat</p>
            <div className="h-20 flex items-center justify-center">
              {/* Cap Stempel Digital */}
              <div className="w-20 h-20 rounded-full border-2 border-red-700/60 text-red-700/70 flex items-center justify-center text-[9px] font-bold uppercase tracking-tighter text-center rotate-[-12deg]">
                DINAS PARIWISATA<br/>PROV. SUMBAR<br/>★ WISGO ★
              </div>
            </div>
            <p className="font-extrabold underline text-sm">Drs. H. Luhur Budianda, S.Y., M.Si</p>
            <p className="text-[11px] text-gray-700">Pembina Utama Muda</p>
            <p className="text-[11px] text-gray-700">NIP. 19700812 199602 1 002</p>
          </div>
        </div>
      </div>

      {/* ==================================================================== */}
      {/* 1. HEADER UTAMA LAYAR ADMIN (No-Print)                               */}
      {/* ==================================================================== */}
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
                  Dasbor Manajemen Kunjungan &amp; Analitik Eksekutif
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  Pusat Komando Dispar Sumbar
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1 max-w-3xl leading-relaxed">
                Pemantauan spasial 19 Kabupaten/Kota, prediksi lonjakan rombongan berbasis Auto-Itinerary, evaluasi perputaran leads WhatsApp UMKM nagari (P2P), dan rekapitulasi penyelesaian insiden lapangan.
              </p>
            </div>
          </div>

          {/* Baris 2: Quick Action Ekspor */}
          <div className="pt-4 border-t border-[#234B24]/10 flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2 text-xs text-[#4A5248]">
              <span className="w-2.5 h-2.5 rounded-full bg-[#1E9E5A] animate-ping" />
              <span>Status Operasional:</span>
              <strong className="text-[#234B24]">Semua Sensor GPS &amp; Rombongan Wisatawan Terhubung Real-Time</strong>
            </div>

            <div className="flex flex-wrap items-center gap-2.5 shrink-0">
              <button
                type="button"
                onClick={handleExportCSV}
                className="min-h-[44px] px-4 py-2 rounded-xl bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24] text-xs font-bold flex items-center gap-2 border border-[#CFD8BE] transition shadow-xs"
              >
                <Download className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                <span>Unduh Data Mentah (CSV)</span>
              </button>
              <button
                type="button"
                onClick={handlePrintOfficialReport}
                className="min-h-[44px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm transition"
              >
                <Printer className="w-4 h-4 text-[#A7F3D0]" aria-hidden="true" />
                <span>Cetak / Unduh PDF Resmi</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* ==================================================================== */}
      {/* 2. KARTU METRIK MAKRO (Bagian Atas, Selalu Tampil)                    */}
      {/* ==================================================================== */}
      <section
        aria-label="4 Kartu Metrik Makro Utama Kunjungan Dispar Sumbar"
        className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 no-print"
      >
        {/* Kartu 1: Total Wisatawan Terlacak (Breakdown Personal vs Rombongan) */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Total Wisatawan Terlacak</span>
            <div className="w-8 h-8 rounded-xl bg-[#234B24]/10 text-[#234B24] flex items-center justify-center">
              <Users className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#234B24] flex items-baseline gap-2">
              <span>{totalWeeklyVisitors.toLocaleString('id-ID')}</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
                +14.2% MoM
              </span>
            </div>
            {/* Visualisasi Terpisah Personal vs Rombongan */}
            <div className="mt-3 pt-2.5 border-t border-[#E4E9DA] grid grid-cols-2 gap-2">
              <div className="p-2 rounded-xl bg-[#234B24]/5 border border-[#234B24]/10">
                <span className="text-[10px] font-extrabold text-[#234B24] block uppercase">Personal / Mandiri</span>
                <span className="text-sm font-black text-[#234B24]">98.200</span>
                <span className="text-[10px] text-[#4A5248] block">65.9% total</span>
              </div>
              <div className="p-2 rounded-xl bg-[#F26B4B]/10 border border-[#F26B4B]/20">
                <span className="text-[10px] font-extrabold text-[#C2410C] block uppercase">Rombongan / Grup</span>
                <span className="text-sm font-black text-[#F26B4B]">50.720</span>
                <span className="text-[10px] text-[#4A5248] block">34.1% total</span>
              </div>
            </div>
          </div>
        </div>

        {/* Kartu 2: Total Rombongan / Open Trip Aktif */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Rombongan / Open Trip Aktif</span>
            <div className="w-8 h-8 rounded-xl bg-[#F26B4B]/10 text-[#F26B4B] flex items-center justify-center">
              <Calendar className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#F26B4B] flex items-baseline gap-2">
              <span>342 Rombongan</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
                1.840 Wisatawan
              </span>
            </div>
            <p className="text-[11px] text-[#4A5248] mt-1 font-medium">
              Terjadwal via Group Invite (18 Grup berangkat hari ini)
            </p>
          </div>
        </div>

        {/* Kartu 3: Total Interaksi WA Mitra UMKM */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Total Interaksi WA Mitra (Leads)</span>
            <div className="w-8 h-8 rounded-xl bg-[#1E9E5A]/10 text-[#1E9E5A] flex items-center justify-center">
              <MessageSquare className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#1E9E5A] flex items-baseline gap-2">
              <span>{totalWaLeads.toLocaleString('id-ID')}</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
                +22.8% Naik
              </span>
            </div>
            <p className="text-[11px] text-[#4A5248] mt-1 font-medium">
              100% Direct P2P ke WhatsApp Mitra Nagari tanpa potongan
            </p>
          </div>
        </div>

        {/* Kartu 4: Indeks Keamanan Lapangan */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Indeks Keamanan Lapangan</span>
            <div className="w-8 h-8 rounded-xl bg-[#234B24]/10 text-[#234B24] flex items-center justify-center">
              <ShieldCheck className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#234B24] flex items-baseline gap-2">
              <span>94.8%</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
                Zona Hijau Tertib
              </span>
            </div>
            <p className="text-[11px] text-[#4A5248] mt-1 font-medium">
              19 dari 20 Destinasi bebas aduan Pungli &amp; Kesiagaan Tim SAR
            </p>
          </div>
        </div>
      </section>

      {/* ==================================================================== */}
      {/* 3. SUB-TAB NAVIGASI 4 AREA UTAMA (+ 2 SUB-TAB USE CASE)              */}
      {/* ==================================================================== */}
      <nav
        aria-label="Tab Manajemen Kunjungan & Analitik"
        className="bg-white rounded-2xl p-2 shadow-sm border border-[#E4E9DA] flex flex-wrap gap-2 no-print"
      >
        <button
          type="button"
          onClick={() => setActiveTab('heatmap_prediction')}
          className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'heatmap_prediction'
              ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
              : 'bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24]'
          }`}
        >
          <Compass className="w-4 h-4" aria-hidden="true" />
          <span>1. Heatmap Kepadatan &amp; Prediksi Kunjungan</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('partner_performance')}
          className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'partner_performance'
              ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
              : 'bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24]'
          }`}
        >
          <Store className="w-4 h-4" aria-hidden="true" />
          <span>2. Interaksi Mitra UMKM &amp; Top 5 Gaode</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('incident_recap')}
          className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'incident_recap'
              ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
              : 'bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24]'
          }`}
        >
          <AlertTriangle className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
          <span>3. Rekapitulasi Insiden &amp; Rasio Tanggap</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('export_report')}
          className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'export_report'
              ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
              : 'bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24]'
          }`}
        >
          <FileText className="w-4 h-4" aria-hidden="true" />
          <span>4. Ekspor Laporan Resmi (PDF/CSV)</span>
        </button>

        {/* Tab 5: Health & Benchmark SLA (Use Case 10) */}
        <button
          type="button"
          onClick={() => setActiveTab('system_benchmark')}
          className={`min-h-[44px] px-3.5 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ml-auto ${
            activeTab === 'system_benchmark'
              ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
              : 'bg-white hover:bg-[#F6F3EC] text-[#4A5248] border border-[#CFD8BE]'
          }`}
          title="Telemetri SLA & Benchmark Sistem"
        >
          <Activity className="w-4 h-4 text-[#1E9E5A]" aria-hidden="true" />
          <span>Benchmark SLA</span>
        </button>
      </nav>

      {/* ==================================================================== */}
      {/* 4. TAB 1: HEATMAP KEPADATAN & PREDIKSI KUNJUNGAN                      */}
      {/* ==================================================================== */}
      {activeTab === 'heatmap_prediction' && (
        <div className="space-y-6 no-print">
          {/* A. GRAFIK PREDIKSI LONJAKAN (LINE CHART 7 HARI KE DEPAN) */}
          <section
            aria-label="Grafik Prediksi Lonjakan Kunjungan 7 Hari ke Depan"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#E4E9DA] pb-5">
              <div>
                <div className="flex items-center gap-2">
                  <Flame className="w-5 h-5 text-[#F26B4B]" />
                  <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A]">
                    Prediksi Kunjungan &amp; Lonjakan Rombongan 7 Hari ke Depan
                  </h3>
                  <span className="px-2.5 py-0.5 rounded-full text-[10.5px] font-bold bg-[#F26B4B]/15 text-[#D95637]">
                    Predictive Analytics
                  </span>
                </div>
                <p className="text-xs text-[#4A5248] mt-1">
                  Sistem membaca jadwal Auto-Itinerary dari rombongan-rombongan grup wisatawan via Group Invite untuk mengantisipasi kepadatan destinasi.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2.5 shrink-0">
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#234B24]/10 text-[#234B24] text-xs font-bold">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#234B24]" />
                  <span>Personal (Mandiri)</span>
                </div>
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#F26B4B]/15 text-[#C2410C] text-xs font-bold">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#F26B4B]" />
                  <span>Rombongan (Grup / Open Trip)</span>
                </div>
                <span className="px-3 py-1 rounded-xl bg-[#234B24] text-white text-xs font-bold shadow-xs">
                  {selectedPredictionDay.dayName}, {selectedPredictionDay.date}
                </span>
              </div>
            </div>

            {/* Line Chart SVG Interaktif (Personal Hijau vs Rombongan Koral) */}
            <div className="w-full overflow-x-auto">
              <div className="min-w-[680px]">
                <svg
                  viewBox="0 0 760 220"
                  className="w-full h-56 select-none"
                  aria-label="Line chart prediksi kunjungan personal vs rombongan 7 hari"
                >
                  <defs>
                    <linearGradient id="surgeAreaGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#234B24" stopOpacity="0.25" />
                      <stop offset="100%" stopColor="#234B24" stopOpacity="0.0" />
                    </linearGradient>
                    <linearGradient id="coralAreaGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#F26B4B" stopOpacity="0.30" />
                      <stop offset="100%" stopColor="#F26B4B" stopOpacity="0.0" />
                    </linearGradient>
                  </defs>

                  {/* Garis Grid Horizontal & Label Ambang Batas */}
                  <line x1="50" y1="30" x2="730" y2="30" stroke="#CFD8BE" strokeDasharray="3 3" />
                  <text x="40" y="34" textAnchor="end" className="text-[10px] fill-[#767676] font-mono">3.000 Org</text>

                  <line x1="50" y1="80" x2="730" y2="80" stroke="#CFD8BE" strokeDasharray="3 3" />
                  <text x="40" y="84" textAnchor="end" className="text-[10px] fill-[#767676] font-mono">2.000 Org</text>

                  <line x1="50" y1="130" x2="730" y2="130" stroke="#CFD8BE" strokeDasharray="3 3" />
                  <text x="40" y="134" textAnchor="end" className="text-[10px] fill-[#767676] font-mono">1.000 Org</text>

                  <line x1="50" y1="180" x2="730" y2="180" stroke="#CFD8BE" />
                  <text x="40" y="184" textAnchor="end" className="text-[10px] fill-[#767676] font-mono">0</text>

                  {/* Garis Ambang Batas Kapasitas Siaga */}
                  <line x1="50" y1="65" x2="730" y2="65" stroke="#F26B4B" strokeWidth="1.5" strokeDasharray="4 4" />
                  <text x="725" y="60" textAnchor="end" className="text-[9.5px] fill-[#F26B4B] font-bold">
                    Ambang Batas Siaga Lonjakan (&gt; 2.500 Wisatawan)
                  </text>

                  {/* 1. Kurva Area Fill Personal (Hijau) */}
                  <polygon
                    points="80,180 80,141 185,144 290,138 395,118 500,95 605,50 710,61 710,180"
                    fill="url(#surgeAreaGradient)"
                  />

                  {/* 1. Garis Poligon Personal (Hijau) */}
                  <polyline
                    points="80,141 185,144 290,138 395,118 500,95 605,50 710,61"
                    fill="none"
                    stroke="#234B24"
                    strokeWidth="3"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />

                  {/* 2. Kurva Area Fill Rombongan (Koral) */}
                  <polygon
                    points="80,180 80,157 185,160 290,155 395,142 500,123 605,90 710,100 710,180"
                    fill="url(#coralAreaGradient)"
                  />

                  {/* 2. Garis Poligon Rombongan (Koral) */}
                  <polyline
                    points="80,157 185,160 290,155 395,142 500,123 605,90 710,100"
                    fill="none"
                    stroke="#F26B4B"
                    strokeWidth="3"
                    strokeDasharray="4 2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />

                  {/* Titik Lingkaran & Label Setiap Hari */}
                  {[
                    { cx: 80, cyPersonal: 141, cyGroup: 157, day: PREDICTION_7_DAYS[0] },
                    { cx: 185, cyPersonal: 144, cyGroup: 160, day: PREDICTION_7_DAYS[1] },
                    { cx: 290, cyPersonal: 138, cyGroup: 155, day: PREDICTION_7_DAYS[2] },
                    { cx: 395, cyPersonal: 118, cyGroup: 142, day: PREDICTION_7_DAYS[3] },
                    { cx: 500, cyPersonal: 95, cyGroup: 123, day: PREDICTION_7_DAYS[4] },
                    { cx: 605, cyPersonal: 50, cyGroup: 90, day: PREDICTION_7_DAYS[5] },
                    { cx: 710, cyPersonal: 61, cyGroup: 100, day: PREDICTION_7_DAYS[6] },
                  ].map((pt, idx) => {
                    const isSelected = selectedPredictionDay.date === pt.day.date;
                    const isPeak = pt.day.status === 'Puncak (Peak)';
                    return (
                      <g
                        key={idx}
                        className="cursor-pointer group"
                        onClick={() => setSelectedPredictionDay(pt.day)}
                      >
                        {/* Glow halo saat aktif */}
                        {isSelected && (
                          <circle cx={pt.cx} cy={pt.cyPersonal} r="14" fill="#F26B4B" opacity="0.25" className="animate-pulse" />
                        )}

                        {/* Titik Personal (Hijau) */}
                        <circle
                          cx={pt.cx}
                          cy={pt.cyPersonal}
                          r={isSelected ? '6' : '4.5'}
                          fill="#234B24"
                          stroke="#FFFFFF"
                          strokeWidth="2"
                        />

                        {/* Titik Rombongan (Koral) */}
                        <circle
                          cx={pt.cx}
                          cy={pt.cyGroup}
                          r={isSelected ? '6' : '4.5'}
                          fill="#F26B4B"
                          stroke="#FFFFFF"
                          strokeWidth="2"
                        />

                        {/* Badge angka di atas titik */}
                        <text
                          x={pt.cx}
                          y={pt.cyPersonal - 10}
                          textAnchor="middle"
                          className="text-[10px] font-extrabold fill-[#234B24]"
                        >
                          {pt.day.personalTouristsEst}
                        </text>
                        <text
                          x={pt.cx}
                          y={pt.cyGroup + 14}
                          textAnchor="middle"
                          className="text-[9.5px] font-extrabold fill-[#C2410C]"
                        >
                          {pt.day.groupTouristsEst}
                        </text>

                        {/* Label Hari & Tanggal di Bawah */}
                        <text
                          x={pt.cx}
                          y="198"
                          textAnchor="middle"
                          className={`text-[11px] font-bold ${
                            isSelected ? 'fill-[#234B24]' : 'fill-[#4A5248]'
                          }`}
                        >
                          {pt.day.dayName}
                        </text>
                        <text
                          x={pt.cx}
                          y="212"
                          textAnchor="middle"
                          className="text-[9.5px] fill-[#767676] font-mono"
                        >
                          {pt.day.date.slice(0, 6)}
                        </text>
                      </g>
                    );
                  })}
                </svg>
              </div>
            </div>

            {/* Panel Peringatan Dini & Rekomendasi Mitigasi Cerdas */}
            <div className="bg-[#F6F3EC] p-5 rounded-2xl border border-[#CFD8BE] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shrink-0 shadow-xs mt-0.5">
                  <AlertTriangle className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="text-xs font-extrabold uppercase tracking-wide text-[#D95637]">
                    Peringatan Dini Lonjakan: {selectedPredictionDay.dayName}, {selectedPredictionDay.date} ({selectedPredictionDay.status})
                  </h4>
                  <p className="text-xs text-[#1B1F1A] mt-0.5">
                    Total Kunjungan: <strong>{selectedPredictionDay.touristsEst.toLocaleString('id-ID')} Wisatawan</strong>{' '}
                    (Terdiri dari <span className="text-[#234B24] font-bold">{selectedPredictionDay.personalTouristsEst.toLocaleString('id-ID')} Personal</span> &amp;{' '}
                    <span className="text-[#F26B4B] font-bold">{selectedPredictionDay.groupTouristsEst.toLocaleString('id-ID')} Rombongan</span> dalam <strong>{selectedPredictionDay.groupsCount} grup</strong>) menuju kawasan:{' '}
                    <span className="font-bold text-[#234B24]">{selectedPredictionDay.topDestinations.join(' & ')}</span>.
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                <span className="text-[11px] font-bold px-3 py-1.5 rounded-xl bg-[#234B24] text-white shadow-xs">
                  Saran: Kerahkan Posko Saber &amp; Rekayasa Jalur Kelok 9
                </span>
              </div>
            </div>
          </section>

          {/* B. PETA / GRID STATUS SAAT INI (19 KABUPATEN / KOTA) */}
          <section
            aria-label="Peta Status Kepadatan 19 Kabupaten dan Kota di Sumatera Barat"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-6"
          >
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <MapPin className="w-5 h-5 text-[#234B24]" />
                  <span>Sebaran Kepadatan Real-Time di 19 Kabupaten/Kota</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Indikator daya dukung lingkungan &amp; sebaran arus wisatawan nusantara vs wisman mancanegara.
                </p>
              </div>

              {/* Filter Pencarian & Status */}
              <div className="flex flex-wrap items-center gap-2.5">
                <div className="relative">
                  <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
                  <input
                    type="search"
                    value={searchRegency}
                    onChange={(e) => setSearchRegency(e.target.value)}
                    placeholder="Cari wilayah..."
                    className="min-h-[42px] pl-9 pr-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>

                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="min-h-[42px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="all">Semua Status</option>
                  <option value="Sepi">Sepi (Hijau)</option>
                  <option value="Sedang">Sedang (Kuning)</option>
                  <option value="high">Ramai / Overload (Koral)</option>
                </select>
              </div>
            </div>

            {/* Grid 19 Kabupaten / Kota */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {filteredRegencies.map((reg) => {
                const isOverload = reg.crowd_status === 'Overload';
                const isRamai = reg.crowd_status === 'Ramai';
                const isSedang = reg.crowd_status === 'Sedang';

                const badgeBg = isOverload
                  ? 'bg-red-100 text-red-800 border-red-200'
                  : isRamai
                  ? 'bg-[#F26B4B]/15 text-[#D95637] border-[#F26B4B]/30'
                  : isSedang
                  ? 'bg-[#F59E0B]/15 text-[#B45309] border-[#F59E0B]/30'
                  : 'bg-[#1E9E5A]/15 text-[#166534] border-[#1E9E5A]/30';

                return (
                  <div
                    key={reg.id}
                    className="bg-[#F6F3EC]/70 hover:bg-[#F6F3EC] p-4 rounded-2xl border border-[#CFD8BE] shadow-xs transition flex flex-col justify-between"
                  >
                    <div>
                      <div className="flex items-start justify-between gap-2">
                        <span className="text-xs font-mono font-bold text-[#767676]">
                          {reg.code}
                        </span>
                        <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${badgeBg}`}>
                          {reg.crowd_status}
                        </span>
                      </div>

                      <h4 className="text-sm font-extrabold text-[#1B1F1A] mt-1.5">
                        {reg.name}
                      </h4>

                      <div className="mt-3 space-y-1.5 text-xs text-[#4A5248]">
                        <div className="flex justify-between">
                          <span>Total Kunjungan:</span>
                          <strong className="text-[#234B24]">
                            {reg.visitor_count_week.toLocaleString('id-ID')}
                          </strong>
                        </div>

                        <div className="flex justify-between text-[11px]">
                          <span>• Personal (Mandiri):</span>
                          <span className="font-bold text-[#234B24]">
                            {Math.round(reg.visitor_count_week * 0.66).toLocaleString('id-ID')}
                          </span>
                        </div>

                        <div className="flex justify-between text-[11px]">
                          <span>• Rombongan (Grup):</span>
                          <span className="font-bold text-[#F26B4B]">
                            {Math.round(reg.visitor_count_week * 0.34).toLocaleString('id-ID')}
                          </span>
                        </div>

                        <div className="flex justify-between pt-1 border-t border-black/5">
                          <span>Destinasi Teratas:</span>
                          <span className="font-semibold text-[#1B1F1A] truncate max-w-[130px]">
                            {reg.top_destination}
                          </span>
                        </div>

                        <div className="flex justify-between">
                          <span>Interaksi WA Mitra:</span>
                          <span className="font-bold text-[#1E9E5A]">
                            {(reg.wa_leads_count || 120).toLocaleString('id-ID')} Klik
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="mt-4 pt-3 border-t border-[#CFD8BE]/60 text-[10px] text-[#4A5248] flex items-center justify-between">
                      <span>Rasio: {reg.domestic_pct}% Domestik</span>
                      <span className="font-bold text-[#234B24]">{reg.foreign_myr_pct}% Wisman</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        </div>
      )}

      {/* ==================================================================== */}
      {/* 5. TAB 2: INTERAKSI MITRA UMKM & PERFORMA DESTINASI (GAODE RANKING)   */}
      {/* ==================================================================== */}
      {activeTab === 'partner_performance' && (
        <div className="space-y-6 no-print">
          {/* A. BAR CHART INTERAKSI WA PER DESTINASI (LEADS KE MITRA UMKM) */}
          <section
            aria-label="Grafik Batang Interaksi WA ke Mitra UMKM Nagari"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#E4E9DA] pb-5">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <BarChart3 className="w-5 h-5 text-[#234B24]" />
                  <span>Destinasi Penyumbang Klik "Hubungi WA" Tertinggi ke Mitra Nagari</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Mengukur konversi minat penjelajah digital (Tur 360° &amp; QR) menjadi interaksi langsung ke nomor WhatsApp P2P mitra UMKM (Homestay, Pemandu, Kuliner, dll).
                </p>
              </div>

              <div className="px-3.5 py-1.5 rounded-xl bg-[#1E9E5A]/15 text-[#166534] text-xs font-bold shrink-0">
                Total Ekosistem: 12.580 Klik Leads WA
              </div>
            </div>

            {/* List Bar Chart */}
            <div className="space-y-4">
              {TOP_DESTINATIONS_WA_LEADS.map((item, idx) => {
                return (
                  <div key={idx} className="space-y-1.5">
                    <div className="flex flex-wrap items-center justify-between text-xs gap-2">
                      <div className="flex items-center gap-2">
                        <span className="w-6 font-mono font-bold text-[#767676] text-right">
                          #{idx + 1}
                        </span>
                        <strong className="text-[#1B1F1A] font-bold text-sm">
                          {item.destinationName}
                        </strong>
                        <span className="text-[11px] text-[#4A5248]">({item.cityRegency})</span>
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#E4E9DA] text-[#234B24]">
                          {item.dominantCategory}
                        </span>
                      </div>

                      <div className="flex items-center gap-3">
                        <span className="text-sm font-extrabold text-[#234B24]">
                          {item.totalClicks.toLocaleString('id-ID')} Klik
                        </span>
                        <span className="text-xs text-[#767676] font-mono">
                          {item.percentage}%
                        </span>
                      </div>
                    </div>

                    {/* Progress Bar */}
                    <div className="w-full h-3 rounded-full bg-[#F6F3EC] overflow-hidden border border-[#CFD8BE]">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-[#234B24] to-[#1E9E5A] transition-all duration-500"
                        style={{ width: `${item.percentage}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Ringkasan Distribusi Kategori Mitra */}
            <div className="pt-4 border-t border-[#E4E9DA] grid grid-cols-2 sm:grid-cols-5 gap-3 text-center text-xs">
              <div className="p-3 bg-[#F6F3EC] rounded-2xl border border-[#CFD8BE]">
                <span className="text-[10px] font-bold uppercase text-[#4A5248] block">Homestay Nagari</span>
                <span className="text-base font-extrabold text-[#234B24]">38%</span>
                <span className="text-[10px] text-[#767676] block">4.780 Klik</span>
              </div>
              <div className="p-3 bg-[#F6F3EC] rounded-2xl border border-[#CFD8BE]">
                <span className="text-[10px] font-bold uppercase text-[#4A5248] block">Pemandu Pokdarwis</span>
                <span className="text-base font-extrabold text-[#234B24]">32%</span>
                <span className="text-[10px] text-[#767676] block">4.025 Klik</span>
              </div>
              <div className="p-3 bg-[#F6F3EC] rounded-2xl border border-[#CFD8BE]">
                <span className="text-[10px] font-bold uppercase text-[#4A5248] block">Kuliner Halal</span>
                <span className="text-base font-extrabold text-[#234B24]">18%</span>
                <span className="text-[10px] text-[#767676] block">2.260 Klik</span>
              </div>
              <div className="p-3 bg-[#F6F3EC] rounded-2xl border border-[#CFD8BE]">
                <span className="text-[10px] font-bold uppercase text-[#4A5248] block">Sewa Kapal Wisata</span>
                <span className="text-base font-extrabold text-[#234B24]">8%</span>
                <span className="text-[10px] text-[#767676] block">1.010 Klik</span>
              </div>
              <div className="p-3 bg-[#F6F3EC] rounded-2xl border border-[#CFD8BE]">
                <span className="text-[10px] font-bold uppercase text-[#4A5248] block">Busana Adat</span>
                <span className="text-base font-extrabold text-[#234B24]">4%</span>
                <span className="text-[10px] text-[#767676] block">505 Klik</span>
              </div>
            </div>
          </section>

          {/* B. TABEL TOP 5 GAODE RANKING (SKOR KEPUASAN & KETERTIBAN TERTINGGI) */}
          <section
            aria-label="Tabel Top 5 Gaode Ranking Destinasi Wisata"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#E4E9DA] pb-5">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Star className="w-5 h-5 text-[#F59E0B] fill-[#F59E0B]" />
                  <span>Top 5 Gaode Ranking — Destinasi Berperforma Tertinggi</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Algoritma multi-faktor: Bebas Pungli (skor kepatuhan Perda), Durasi Singgah Lama (Dwell Time), Minat Eksplorasi 360°, dan Frekuensi Disimpan ke Rencana Perjalanan.
                </p>
              </div>

              <span className="px-3.5 py-1.5 rounded-xl bg-[#234B24] text-white text-xs font-bold shrink-0">
                Pembaruan Skor: Otomatis 24 Jam
              </span>
            </div>

            {/* Tabel Top 5 */}
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-[#E4E9DA] text-[#4A5248] font-bold">
                    <th className="py-3 px-3">Peringkat</th>
                    <th className="py-3 px-3">Nama Destinasi &amp; Wilayah</th>
                    <th className="py-3 px-3 text-center">Skor Gaode</th>
                    <th className="py-3 px-3 text-center">Bebas Pungli</th>
                    <th className="py-3 px-3 text-center">Durasi Singgah</th>
                    <th className="py-3 px-3 text-center">Eksplorasi 360°</th>
                    <th className="py-3 px-3 text-center">Disimpan Itinerary</th>
                    <th className="py-3 px-3 text-center">Tren</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {TOP_5_GAODE_DESTINATIONS.map((d) => {
                    return (
                      <tr key={d.rank} className="hover:bg-[#F6F3EC]/50 transition">
                        <td className="py-4 px-3 font-extrabold text-sm">
                          {d.rank === 1 ? (
                            <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-[#F59E0B] text-white font-black shadow-xs">
                              1
                            </span>
                          ) : d.rank === 2 ? (
                            <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-slate-400 text-white font-black shadow-xs">
                              2
                            </span>
                          ) : d.rank === 3 ? (
                            <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-amber-700 text-white font-black shadow-xs">
                              3
                            </span>
                          ) : (
                            <span className="text-[#4A5248] pl-2 font-mono">#{d.rank}</span>
                          )}
                        </td>

                        <td className="py-4 px-3">
                          <strong className="text-sm font-extrabold text-[#1B1F1A] block">
                            {d.name}
                          </strong>
                          <span className="text-xs text-[#4A5248]">{d.cityRegency}</span>
                        </td>

                        <td className="py-4 px-3 text-center">
                          <span className="px-3 py-1 rounded-xl bg-[#234B24] text-white font-extrabold text-sm shadow-xs">
                            {d.gaodeScore}
                          </span>
                        </td>

                        <td className="py-4 px-3 text-center">
                          <span className="font-bold text-[#1E9E5A] bg-[#1E9E5A]/15 px-2.5 py-1 rounded-full text-xs">
                            {d.pungliFreeIndex}%
                          </span>
                        </td>

                        <td className="py-4 px-3 text-center font-bold text-[#1B1F1A]">
                          {d.avgDwellHours} Jam
                        </td>

                        <td className="py-4 px-3 text-center font-mono font-semibold text-[#234B24]">
                          {d.views360Count.toLocaleString('id-ID')} views
                        </td>

                        <td className="py-4 px-3 text-center font-bold text-[#F26B4B]">
                          {d.savedToItineraryCount.toLocaleString('id-ID')}x
                        </td>

                        <td className="py-4 px-3 text-center">
                          {d.trend === 'up' ? (
                            <span className="text-xs font-bold text-[#1E9E5A] flex items-center justify-center gap-0.5">
                              <TrendingUp className="w-3.5 h-3.5" />
                              <span>Naik</span>
                            </span>
                          ) : (
                            <span className="text-xs font-bold text-[#767676]">
                              Stabil
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      {/* ==================================================================== */}
      {/* 6. TAB 3: REKAPITULASI INSIDEN (PUNGLI & DARURAT)                    */}
      {/* ==================================================================== */}
      {activeTab === 'incident_recap' && (
        <div className="space-y-6 no-print">
          {/* GRID: DONUT CHART KOMPOSISI & KARTU RESOLUTION RATE */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Donut Chart SVG Komposisi Aduan */}
            <div className="lg:col-span-6 bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] flex flex-col justify-between space-y-6">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-[#F26B4B]" />
                  <span>Komposisi Laporan Insiden Bulan Ini</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Distribusi 54 tiket aduan wisatawan yang masuk via Plang Smart QR &amp; Aplikasi.
                </p>
              </div>

              {/* Visual Donut Chart SVG */}
              <div className="flex flex-col sm:flex-row items-center justify-center gap-6 py-2">
                <div className="relative w-44 h-44 shrink-0 flex items-center justify-center">
                  <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                    {/* Lingkaran Background */}
                    <circle cx="50" cy="50" r="38" fill="none" stroke="#F6F3EC" strokeWidth="16" />
                    {/* Segmen 1: Parkir Liar (42.6%) -> stroke-dasharray: 101.7, 238.7 */}
                    <circle
                      cx="50"
                      cy="50"
                      r="38"
                      fill="none"
                      stroke="#F26B4B"
                      strokeWidth="16"
                      strokeDasharray="101.7 238.7"
                      strokeDashoffset="0"
                    />
                    {/* Segmen 2: Tiket Liar (27.8%) -> stroke-dasharray: 66.4, 238.7 */}
                    <circle
                      cx="50"
                      cy="50"
                      r="38"
                      fill="none"
                      stroke="#F59E0B"
                      strokeWidth="16"
                      strokeDasharray="66.4 238.7"
                      strokeDashoffset="-101.7"
                    />
                    {/* Segmen 3: Fasilitas Rusak (18.5%) -> stroke-dasharray: 44.2, 238.7 */}
                    <circle
                      cx="50"
                      cy="50"
                      r="38"
                      fill="none"
                      stroke="#3B82F6"
                      strokeWidth="16"
                      strokeDasharray="44.2 238.7"
                      strokeDashoffset="-168.1"
                    />
                    {/* Segmen 4: SOS SAR (11.1%) -> stroke-dasharray: 26.5, 238.7 */}
                    <circle
                      cx="50"
                      cy="50"
                      r="38"
                      fill="none"
                      stroke="#EF4444"
                      strokeWidth="16"
                      strokeDasharray="26.5 238.7"
                      strokeDashoffset="-212.3"
                    />
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                    <span className="text-2xl font-black text-[#1B1F1A]">54</span>
                    <span className="text-[10px] font-bold text-[#767676] uppercase">Total Aduan</span>
                  </div>
                </div>

                {/* Legenda Komposisi */}
                <div className="space-y-2.5 w-full">
                  {INCIDENT_CATEGORIES.map((cat, idx) => (
                    <div key={idx} className="flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <span className="w-3 h-3 rounded-full shrink-0" style={{ backgroundColor: cat.color }} />
                        <span className="font-semibold text-[#1B1F1A]">{cat.name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="font-extrabold text-[#1B1F1A]">{cat.count} Tiket</span>
                        <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${cat.badgeBg} ${cat.badgeText}`}>
                          {cat.percentage}%
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="text-[11px] text-[#4A5248] bg-[#F6F3EC] p-3 rounded-2xl border border-[#CFD8BE]">
                <strong>Indeks Keamanan:</strong> Laporan pungli parkir liar terkonsentrasi di kawasan penyangga Jam Gadang dan gerbang Pantai Padang. Tim Saber Pungli telah menetapkan titik patroli tetap.
              </div>
            </div>

            {/* Kartu Rasio Penyelesaian & Kecepatan Respons (Resolution Rate) */}
            <div className="lg:col-span-6 bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] flex flex-col justify-between space-y-6">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <ShieldCheck className="w-5 h-5 text-[#234B24]" />
                  <span>Rasio Penyelesaian &amp; Kecepatan Penindakan (SLA)</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Standar Pelayanan Minimum (SPM) penindakan aduan pungli dan siaga darurat SAR.
                </p>
              </div>

              {/* 2 Metrik Besar */}
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-[#E4E9DA]/50 p-4 rounded-2xl border border-[#CFD8BE]">
                  <span className="text-[11px] font-bold uppercase text-[#234B24] block">
                    Tingkat Penyelesaian (Resolution Rate)
                  </span>
                  <div className="mt-2 text-3xl font-black text-[#234B24]">
                    92.6%
                  </div>
                  <span className="text-[11px] text-[#166534] font-bold mt-1 block">
                    50 dari 54 Laporan Tuntas Ditindak
                  </span>
                </div>

                <div className="bg-[#F6F3EC] p-4 rounded-2xl border border-[#CFD8BE]">
                  <span className="text-[11px] font-bold uppercase text-[#D95637] block">
                    Rata-rata Waktu Tanggap (SLA)
                  </span>
                  <div className="mt-2 text-3xl font-black text-[#D95637]">
                    18 Menit
                  </div>
                  <span className="text-[11px] text-[#4A5248] font-bold mt-1 block">
                    Batas Maksimal Standar: &lt; 30 Menit
                  </span>
                </div>
              </div>

              {/* Progress Status Tiket */}
              <div className="space-y-2">
                <div className="flex justify-between text-xs font-bold text-[#1B1F1A]">
                  <span>Status Penanganan Tiket Saat Ini</span>
                  <span className="text-[#1E9E5A]">50 Selesai · 3 Investigasi · 1 Menunggu</span>
                </div>
                <div className="w-full h-3 rounded-full bg-[#F6F3EC] overflow-hidden flex border border-[#CFD8BE]">
                  <div className="bg-[#1E9E5A] h-full" style={{ width: '92.6%' }} title="Selesai (92.6%)" />
                  <div className="bg-[#F59E0B] h-full" style={{ width: '5.5%' }} title="Investigasi (5.5%)" />
                  <div className="bg-[#EF4444] h-full" style={{ width: '1.9%' }} title="Menunggu (1.9%)" />
                </div>
              </div>

              <div className="text-[11px] text-[#4A5248] bg-[#F6F3EC] p-3 rounded-2xl border border-[#CFD8BE] flex items-center justify-between">
                <span>Tim Saber Pungli &amp; Armada SAR Siaga 24 Jam</span>
                <span className="font-bold text-[#234B24]">Status: Siaga 1 Terkendali</span>
              </div>
            </div>
          </div>

          {/* TABEL LOG AKSI CEPAT SATGAS SABER & SAR TERAKHIR */}
          <section
            aria-label="Tabel Aksi Cepat Satgas Saber Pungli & SAR"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-4"
          >
            <div className="flex items-center justify-between">
              <h4 className="text-sm lg:text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Clock className="w-4 h-4 text-[#234B24]" />
                <span>Log Aksi Cepat Satgas Saber Pungli &amp; Armada SAR Lapangan</span>
              </h4>
              <span className="text-xs font-bold text-[#1E9E5A]">4 Penindakan Tercepat</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-[#E4E9DA] text-[#4A5248] font-bold">
                    <th className="py-2.5 px-3">Waktu</th>
                    <th className="py-2.5 px-3">Lokasi Destinasi</th>
                    <th className="py-2.5 px-3">Jenis Laporan</th>
                    <th className="py-2.5 px-3 text-center">Waktu Tanggap</th>
                    <th className="py-2.5 px-3">Petugas Penindak</th>
                    <th className="py-2.5 px-3">Tindakan Lapangan</th>
                    <th className="py-2.5 px-3 text-center">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {RECENT_INCIDENT_ACTIONS.map((act) => (
                    <tr key={act.id} className="hover:bg-[#F6F3EC]/50 transition">
                      <td className="py-3 px-3 text-[#767676] font-mono">{act.time}</td>
                      <td className="py-3 px-3 font-bold text-[#1B1F1A]">{act.destination}</td>
                      <td className="py-3 px-3 font-semibold text-[#D95637]">{act.incidentType}</td>
                      <td className="py-3 px-3 text-center">
                        <span className="px-2 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#166534] font-extrabold">
                          {act.responseTimeMinutes} Menit
                        </span>
                      </td>
                      <td className="py-3 px-3 text-[#234B24] font-medium">{act.officer}</td>
                      <td className="py-3 px-3 text-[#4A5248] max-w-xs">{act.actionTaken}</td>
                      <td className="py-3 px-3 text-center">
                        <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-[#1E9E5A]/15 text-[#166534]">
                          {act.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      {/* ==================================================================== */}
      {/* 7. TAB 4: EKSPOR LAPORAN KOMPREHENSIF (PDF & CSV)                     */}
      {/* ==================================================================== */}
      {activeTab === 'export_report' && (
        <div className="space-y-6 no-print">
          {/* Panel Konfigurasi & Unduh Laporan */}
          <section
            aria-label="Panel Konfigurasi Ekspor Laporan Resmi"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#E4E9DA] pb-5">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <FileText className="w-5 h-5 text-[#234B24]" />
                  <span>Pusat Penerbitan Laporan Eksekutif Dinas Pariwisata Sumbar</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Cetak laporan resmi bertanda tangan Kepala Dinas Pariwisata Prov. Sumbar atau unduh data spasial mentah format CSV untuk olah data lanjutan.
                </p>
              </div>

              {/* Pemilih Rentang Waktu */}
              <div className="flex items-center gap-2 shrink-0">
                <span className="text-xs font-bold text-[#4A5248]">Rentang Waktu:</span>
                <select
                  value={reportPeriod}
                  onChange={(e: any) => setReportPeriod(e.target.value)}
                  className="min-h-[42px] px-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="month">Bulan Ini (November 2026)</option>
                  <option value="quarter">Kuartal IV (Okt - Des 2026)</option>
                  <option value="year">Tahun Anggaran 2026</option>
                </select>
              </div>
            </div>

            {/* 2 Pilihan Format Ekspor */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {/* Opsi 1: PDF Resmi */}
              <div className="p-6 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col justify-between space-y-4">
                <div className="space-y-2">
                  <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center">
                    <Printer className="w-5 h-5" />
                  </div>
                  <h4 className="text-base font-extrabold text-[#1B1F1A]">
                    Laporan Eksekutif Resmi Dispar (Format PDF Siap Tanda Tangan)
                  </h4>
                  <p className="text-xs text-[#4A5248]">
                    Laporan resmi ber-Kop Surat Dinas Pariwisata Provinsi Sumatera Barat lengkap dengan Rekap Prediksi Kunjungan, Total Klik WA Mitra UMKM, Rasio Kepatuhan Bebas Pungli, serta Lembar Pengesahan Pejabat.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={handlePrintOfficialReport}
                  className="min-h-[46px] w-full px-5 py-2.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold flex items-center justify-center gap-2 shadow-sm transition"
                >
                  <Printer className="w-4 h-4 text-[#A7F3D0]" />
                  <span>Cetak / Unduh PDF Resmi Dispar</span>
                </button>
              </div>

              {/* Opsi 2: CSV Data Mentah */}
              <div className="p-6 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col justify-between space-y-4">
                <div className="space-y-2">
                  <div className="w-10 h-10 rounded-xl bg-[#1E9E5A] text-white flex items-center justify-center">
                    <FileSpreadsheet className="w-5 h-5" />
                  </div>
                  <h4 className="text-base font-extrabold text-[#1B1F1A]">
                    Data Mentah Spasial &amp; Kunjungan (Format CSV / Spreadsheet)
                  </h4>
                  <p className="text-xs text-[#4A5248]">
                    Dataset tabular 19 Kabupaten/Kota, status kapasitas kepadatan, persentase turis domestik vs mancanegara, destinasi unggulan, serta metrik konversi leads WA per wilayah.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={handleExportCSV}
                  className="min-h-[46px] w-full px-5 py-2.5 rounded-xl bg-white hover:bg-gray-50 text-[#234B24] border border-[#CFD8BE] text-xs font-bold flex items-center justify-center gap-2 shadow-xs transition"
                >
                  <Download className="w-4 h-4 text-[#234B24]" />
                  <span>Unduh Berkas CSV (Excel)</span>
                </button>
              </div>
            </div>

            {/* Pratinjau Tampilan Dokumen di Layar */}
            <div className="pt-4 border-t border-[#E4E9DA]">
              <div className="flex items-center justify-between mb-3">
                <h4 className="text-xs font-bold text-[#4A5248] uppercase tracking-wider">
                  Pratinjau Dokumen Resmi Dinas Pariwisata Prov. Sumbar
                </h4>
                <span className="text-[11px] text-[#767676]">Ukuran Kertas: A4 Standar Dinas</span>
              </div>

              <div className="bg-white p-6 sm:p-8 rounded-2xl border border-gray-300 shadow-sm max-w-4xl mx-auto space-y-5 text-black">
                {/* Kop Surat Pratinjau */}
                <div className="border-b-4 border-double border-black pb-4 text-center">
                  <h2 className="text-sm sm:text-base font-bold tracking-wider uppercase">
                    PEMERINTAH PROVINSI SUMATERA BARAT
                  </h2>
                  <h1 className="text-lg sm:text-xl font-black uppercase tracking-tight">
                    DINAS PARIWISATA
                  </h1>
                  <p className="text-[11px] text-gray-700">
                    Jl. Khatib Sulaiman No. 22, Padang, Sumatera Barat · Telp. (0751) 7055183 · Email: dispar@sumbarprov.go.id
                  </p>
                  <p className="text-[10px] font-bold text-gray-600 mt-0.5">
                    PORTAL EKOSISTEM WISATA PINTAR SUMATERA BARAT (WISGO)
                  </p>
                </div>

                <div className="flex justify-between items-baseline text-xs pb-2 border-b border-gray-300">
                  <div>
                    <div><strong>Nomor:</strong> 556/412/DISPAR-SUMBAR/XI/2026</div>
                    <div><strong>Perihal:</strong> Laporan Eksekutif Manajemen Kunjungan &amp; Kepatuhan</div>
                  </div>
                  <div className="text-right">
                    <div><strong>Periode:</strong> {reportPeriod === 'month' ? 'November 2026' : reportPeriod === 'quarter' ? 'Kuartal IV 2026' : 'TA 2026'}</div>
                  </div>
                </div>

                {/* Ringkasan Angka Kunci */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 p-3 bg-gray-50 border border-gray-200 rounded text-center text-xs">
                  <div>
                    <span className="text-[10px] text-gray-500 block">Total Kunjungan</span>
                    <strong className="text-sm text-black">148.920 Turis</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-500 block">Rombongan Aktif</span>
                    <strong className="text-sm text-black">342 Grup</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-500 block">Leads WA Mitra</span>
                    <strong className="text-sm text-black">12.580 Klik</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-500 block">Penyelesaian Pungli</span>
                    <strong className="text-sm text-black">92.6% (18 Menit)</strong>
                  </div>
                </div>

                {/* Pratinjau Tabel Singkat */}
                <div className="text-xs space-y-2">
                  <p className="font-bold">Ringkasan Top 5 Destinasi Unggulan (Gaode Ranking):</p>
                  <div className="border border-gray-300 rounded overflow-hidden">
                    <table className="w-full text-left text-[11px]">
                      <thead className="bg-gray-100 font-bold border-b border-gray-300">
                        <tr>
                          <th className="p-1.5 text-center">Rank</th>
                          <th className="p-1.5">Destinasi</th>
                          <th className="p-1.5">Wilayah</th>
                          <th className="p-1.5 text-center">Skor Gaode</th>
                          <th className="p-1.5 text-center">Bebas Pungli</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200">
                        {TOP_5_GAODE_DESTINATIONS.slice(0, 3).map((d) => (
                          <tr key={d.rank}>
                            <td className="p-1.5 text-center font-bold">#{d.rank}</td>
                            <td className="p-1.5 font-semibold">{d.name}</td>
                            <td className="p-1.5 text-gray-600">{d.cityRegency}</td>
                            <td className="p-1.5 text-center font-bold">{d.gaodeScore}</td>
                            <td className="p-1.5 text-center text-green-700 font-bold">{d.pungliFreeIndex}%</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                {/* Lembar Tanda Tangan */}
                <div className="pt-4 flex justify-between items-end text-xs">
                  <div className="text-[10px] text-gray-500 italic max-w-xs">
                    * Dokumen elektronik resmi Dinas Pariwisata Provinsi Sumatera Barat.
                  </div>
                  <div className="text-center w-56">
                    <p>Padang, 17 November 2026</p>
                    <p className="font-bold text-[11px]">Kepala Dinas Pariwisata Prov. Sumbar</p>
                    <div className="h-14 flex items-center justify-center">
                      <span className="text-red-700/60 font-bold text-[10px] border border-red-700/40 px-2 py-0.5 rounded rotate-[-6deg]">
                        [TERVALIDASI ELEKTRONIK]
                      </span>
                    </div>
                    <p className="font-bold underline text-xs">Drs. H. Luhur Budianda, S.Y., M.Si</p>
                    <p className="text-[10px] text-gray-600">NIP. 19700812 199602 1 002</p>
                  </div>
                </div>
              </div>
            </div>
          </section>
        </div>
      )}

      {/* ==================================================================== */}
      {/* 8. TAB 5: HEALTH & BENCHMARK SLA SISTEM (USE CASE 10)                 */}
      {/* ==================================================================== */}
      {activeTab === 'system_benchmark' && (
        <div className="no-print">
          <SystemHealthBenchmarkSubTab showToast={showToast} />
        </div>
      )}
    </div>
  );
};
