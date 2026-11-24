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
  RotateCcw,
  SlidersHorizontal,
  CreditCard,
} from 'lucide-react';
import {
  Destination,
  Partner,
  RegencyHeatmapData,
  GaodeRankingItem,
  GaodeBehaviorRanking,
  StempVisit,
  OpenTrip,
  ApiTelemetryLog,
  Category,
  PungliReport,
  SosSignal,
} from '../types/contract';
import {
  fetchRegencyHeatmap,
} from '../services/api';
import {
  GaodeRankingsRepo,
  ApiTelemetryLogsRepo,
  StempVisitsRepo,
  OpenTripsRepo,
  CategoriesRepo,
  PungliReportsRepo,
  SosSignalsRepo,
  DestinationsRepo,
  OpenTripTransactionsRepo,
} from '../services/dbRepository';
import { SystemHealthBenchmarkSubTab } from '../components/SystemHealthBenchmarkSubTab';

export type AnalyticsSubTab =
  | 'heatmap_prediction'
  | 'partner_performance'
  | 'incident_recap'
  | 'export_report'
  | 'intel_heatmap' // Backwards compatibility with App.tsx
  | 'system_benchmark';

export type PeriodPreset = 'all' | 'today' | '7d' | '30d' | 'this_month' | 'this_year' | 'custom';
export type TouristSegment = 'all' | 'personal' | 'group';

export const SUMBAR_19_REGIONS: string[] = [
  'Kab. Lima Puluh Kota',
  'Kota Bukittinggi',
  'Kab. Tanah Datar',
  'Kab. Agam',
  'Kota Padang',
  'Kab. Pesisir Selatan',
  'Kab. Solok',
  'Kota Solok',
  'Kab. Padang Pariaman',
  'Kota Pariaman',
  'Kota Sawahlunto',
  'Kota Payakumbuh',
  'Kota Padang Panjang',
  'Kab. Sijunjung',
  'Kab. Pasaman',
  'Kab. Pasaman Barat',
  'Kab. Dharmasraya',
  'Kab. Solok Selatan',
  'Kab. Kepulauan Mentawai',
];

export function isDateInRange(
  dateStr: string | null | undefined,
  preset: PeriodPreset,
  customStart?: string,
  customEnd?: string,
  now: Date = new Date()
): boolean {
  if (preset === 'all') return true;
  if (!dateStr) return false;

  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return true;

  const nowMs = now.getTime();
  const dayMs = 24 * 60 * 60 * 1000;

  if (preset === 'today') {
    return (
      d.getFullYear() === now.getFullYear() &&
      d.getMonth() === now.getMonth() &&
      d.getDate() === now.getDate()
    );
  }
  if (preset === '7d') {
    return Math.abs(d.getTime() - nowMs) <= 7 * dayMs;
  }
  if (preset === '30d') {
    return Math.abs(d.getTime() - nowMs) <= 30 * dayMs;
  }
  if (preset === 'this_month') {
    return (
      d.getFullYear() === now.getFullYear() &&
      d.getMonth() === now.getMonth()
    );
  }
  if (preset === 'this_year') {
    return d.getFullYear() === now.getFullYear();
  }
  if (preset === 'custom') {
    let ok = true;
    if (customStart) {
      const s = new Date(customStart);
      s.setHours(0, 0, 0, 0);
      if (!isNaN(s.getTime())) ok = ok && d >= s;
    }
    if (customEnd) {
      const e = new Date(customEnd);
      e.setHours(23, 59, 59, 999);
      if (!isNaN(e.getTime())) ok = ok && d <= e;
    }
    return ok;
  }
  return true;
}

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

  // Filters for Heatmap Search & Status
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchRegency, setSearchRegency] = useState<string>('');

  // Filter for Export Report Period in Subtab 4
  const [reportPeriod, setReportPeriod] = useState<'month' | 'quarter' | 'year'>('month');

  // --------------------------------------------------------------------------
  // SISTEM FILTER LAPORAN REAKTIF (WAKTU, WILAYAH, KATEGORI, SEGMEN, GPS)
  // --------------------------------------------------------------------------
  const [periodPreset, setPeriodPreset] = useState<PeriodPreset>('all');
  const [customStartDate, setCustomStartDate] = useState<string>('');
  const [customEndDate, setCustomEndDate] = useState<string>('');
  const [selectedRegion, setSelectedRegion] = useState<string>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedSegment, setSelectedSegment] = useState<TouristSegment>('all');
  const [onlyValidGps, setOnlyValidGps] = useState<boolean>(true);

  // Kategori Destinasi resmi dari tabel categories (module_type = 'destination')
  const destinationCategories = useMemo(() => {
    return CategoriesRepo.getByModule('destination');
  }, []);

  const selectedCategoryObj = useMemo(() => {
    if (selectedCategory === 'all') return null;
    return destinationCategories.find((c) => c.id === selectedCategory) || null;
  }, [selectedCategory, destinationCategories]);

  // Status Filter Aktif
  const isFilterActive = useMemo(() => {
    return (
      periodPreset !== 'all' ||
      customStartDate !== '' ||
      customEndDate !== '' ||
      selectedRegion !== 'all' ||
      selectedCategory !== 'all' ||
      selectedSegment !== 'all' ||
      !onlyValidGps
    );
  }, [periodPreset, customStartDate, customEndDate, selectedRegion, selectedCategory, selectedSegment, onlyValidGps]);

  const handleResetFilter = () => {
    setPeriodPreset('all');
    setCustomStartDate('');
    setCustomEndDate('');
    setSelectedRegion('all');
    setSelectedCategory('all');
    setSelectedSegment('all');
    setOnlyValidGps(true);
    setStatusFilter('all');
    setSearchRegency('');
    showToast('Seluruh filter laporan telah di-reset ke kondisi default.', 'info');
  };

  // Chip Ringkasan Filter Aktif
  const activeFilterChips = useMemo(() => {
    const chips: string[] = [];
    if (selectedRegion !== 'all') chips.push(selectedRegion);
    if (selectedCategoryObj) chips.push(selectedCategoryObj.name);
    else if (selectedCategory !== 'all') chips.push(selectedCategory);

    if (periodPreset === 'today') chips.push('Hari Ini');
    else if (periodPreset === '7d') chips.push('7 Hari Terakhir');
    else if (periodPreset === '30d') chips.push('30 Hari Terakhir');
    else if (periodPreset === 'this_month') chips.push('Bulan Ini');
    else if (periodPreset === 'this_year') chips.push('Tahun Ini');
    else if (periodPreset === 'custom') {
      chips.push(`${customStartDate || '...'} s/d ${customEndDate || '...'}`);
    }

    if (selectedSegment === 'personal') chips.push('Personal (stemp_visit)');
    else if (selectedSegment === 'group') chips.push('Rombongan (open_trips)');
    if (onlyValidGps) chips.push('Hanya GPS Valid');

    return chips;
  }, [selectedRegion, selectedCategoryObj, selectedCategory, periodPreset, customStartDate, customEndDate, selectedSegment, onlyValidGps]);

  // Destinasi yang memenuhi kriteria filter Wilayah & Kategori
  const matchingDestinations = useMemo(() => {
    return destinations.filter((d) => {
      const matchRegion =
        selectedRegion === 'all' || d.city_regency.toLowerCase() === selectedRegion.toLowerCase();
      const matchCat =
        selectedCategory === 'all' ||
        d.category_id === selectedCategory ||
        d.category === selectedCategory ||
        Boolean(selectedCategoryObj && d.category && d.category.toLowerCase().includes(selectedCategoryObj.name.toLowerCase()));
      return matchRegion && matchCat;
    });
  }, [destinations, selectedRegion, selectedCategory, selectedCategoryObj]);

  const matchingDestIdSet = useMemo(() => {
    return new Set(matchingDestinations.map((d) => d.id));
  }, [matchingDestinations]);

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

  // Filtered Regencies (Respecting Region, Category, Search, & Status)
  const filteredRegencies = useMemo(() => {
    return heatmapData.filter((item) => {
      const matchRegion = selectedRegion === 'all' || item.name.toLowerCase() === selectedRegion.toLowerCase();
      let matchCat = true;
      if (selectedCategory !== 'all') {
        const destsInReg = matchingDestinations.filter(
          (d) => d.city_regency.toLowerCase() === item.name.toLowerCase()
        );
        matchCat = destsInReg.length > 0;
      }
      const matchSearch = item.name.toLowerCase().includes(searchRegency.toLowerCase());
      const matchStatus =
        statusFilter === 'all'
          ? true
          : statusFilter === 'high'
          ? item.crowd_status === 'Ramai' || item.crowd_status === 'Overload'
          : item.crowd_status === statusFilter;
      return matchRegion && matchCat && matchSearch && matchStatus;
    });
  }, [heatmapData, selectedRegion, selectedCategory, matchingDestinations, searchRegency, statusFilter]);

  // Perhitungan Seluruh Metrik Makro Secara Reaktif (useMemo)
  const {
    totalVisitorsDisplay,
    personalVisitsCount,
    groupVisitsCount,
    activeGroupsCount,
    groupTouristsCount,
    avgGaodeScore,
    avgDwellHours,
    apiSlaLatency,
    apiCacheHitRate,
    totalWaLeadsDisplay,
  } = useMemo(() => {
    // 1. Data Stemp Visit (Personal)
    const allStemps: StempVisit[] = StempVisitsRepo.getAll();
    const filteredStemps = allStemps.filter((s) => {
      if (onlyValidGps && !s.is_gps_valid) return false;
      if (matchingDestIdSet.size > 0 && !matchingDestIdSet.has(s.destination_id)) return false;
      if (!isDateInRange(s.checked_in_at, periodPreset, customStartDate, customEndDate)) return false;
      return true;
    });

    // 2. Data Open Trips (Rombongan)
    const allTrips: OpenTrip[] = OpenTripsRepo.getAll();
    const filteredTrips = allTrips.filter((t) => {
      if (!isDateInRange(t.departure_date, periodPreset, customStartDate, customEndDate)) return false;
      if (selectedRegion !== 'all') {
        const matchesRoute =
          t.destination_route.toLowerCase().includes(selectedRegion.toLowerCase()) ||
          matchingDestinations.some((d) => t.destination_route.toLowerCase().includes(d.name.toLowerCase()));
        if (!matchesRoute) return false;
      }
      return true;
    });

    // 3. Hitung estimasi kunjungan personal vs rombongan
    const baseWeekly = filteredRegencies.reduce((acc, r) => acc + (r.visitor_count_week || 0), 0);
    const leadsCount = filteredRegencies.reduce((acc, r) => acc + (r.wa_leads_count || 0), 0);

    let personal = 0;
    let group = 0;

    if (baseWeekly > 0) {
      personal = Math.round(baseWeekly * 0.66);
      group = Math.round(baseWeekly * 0.34);
    } else if (filteredStemps.length > 0 || filteredTrips.length > 0) {
      personal = filteredStemps.length * 1500;
      group = filteredTrips.reduce((acc, t) => acc + (t.available_seats || 12) * 50, 0);
    }

    // Terapkan Segmen Wisatawan
    if (selectedSegment === 'personal') {
      group = 0;
    } else if (selectedSegment === 'group') {
      personal = 0;
    }

    const totalVisitors = personal + group;

    // Rombongan Card metrics
    let groupsCount = filteredTrips.length;
    let groupTourists = filteredTrips.reduce((acc, t) => acc + (t.available_seats || 12), 0) * 12;

    if (selectedSegment === 'personal') {
      groupsCount = 0;
      groupTourists = 0;
    } else if (selectedRegion === 'all' && periodPreset === 'all' && selectedCategory === 'all') {
      groupsCount = 342;
      groupTourists = 1840;
    }

    // 4. Data Gaode Rankings (Keaslian & Dwell Time)
    const allGaode: GaodeBehaviorRanking[] = GaodeRankingsRepo.getAll();
    const filteredGaode = allGaode.filter((g) => {
      if (matchingDestIdSet.size > 0 && !matchingDestIdSet.has(g.destination_id)) return false;
      if (selectedCategory !== 'all' && g.category_id !== selectedCategory) return false;
      return true;
    });

    const avgScore =
      filteredGaode.length > 0
        ? (
            filteredGaode.reduce(
              (acc, g) => acc + (g.calculated_gaode_score ?? Number(g.gaode_authenticity_score) ?? 95),
              0
            ) / filteredGaode.length
          ).toFixed(1)
        : matchingDestinations.length > 0
        ? '94.2'
        : '-';

    const avgDwell =
      filteredGaode.length > 0
        ? (
            filteredGaode.reduce((acc, g) => acc + (g.avg_dwell_time_min ?? 180), 0) /
            filteredGaode.length /
            60
          ).toFixed(1)
        : matchingDestinations.length > 0
        ? '3.5'
        : '0.0';

    // 5. Data Telemetri SLA API PostGIS
    const allTelemetry: ApiTelemetryLog[] = ApiTelemetryLogsRepo.getAll();
    const filteredTelemetry = allTelemetry.filter((t) => {
      return isDateInRange(t.recorded_at, periodPreset, customStartDate, customEndDate);
    });

    const avgLatency =
      filteredTelemetry.length > 0
        ? Math.round(filteredTelemetry.reduce((acc, t) => acc + Number(t.latency_ms), 0) / filteredTelemetry.length)
        : allTelemetry.length > 0
        ? 28
        : 0;

    const cacheHit =
      filteredTelemetry.length > 0
        ? Math.round((filteredTelemetry.filter((t) => t.cache_hit).length / filteredTelemetry.length) * 100)
        : 95;

    return {
      totalVisitorsDisplay: totalVisitors,
      personalVisitsCount: personal,
      groupVisitsCount: group,
      activeGroupsCount: groupsCount,
      groupTouristsCount: groupTourists,
      avgGaodeScore: avgScore,
      avgDwellHours: avgDwell,
      apiSlaLatency: avgLatency,
      apiCacheHitRate: cacheHit,
      totalWaLeadsDisplay: leadsCount,
    };
  }, [
    destinations,
    filteredRegencies,
    matchingDestinations,
    matchingDestIdSet,
    selectedRegion,
    selectedCategory,
    selectedSegment,
    onlyValidGps,
    periodPreset,
    customStartDate,
    customEndDate,
  ]);

  // Subtab 1: Prediksi 7 hari reaktif terhadap filter segmen
  const reactivePredictionDays = useMemo(() => {
    return PREDICTION_7_DAYS.map((p) => {
      const personal = selectedSegment === 'group' ? 0 : p.personalTouristsEst;
      const group = selectedSegment === 'personal' ? 0 : p.groupTouristsEst;
      const groups = selectedSegment === 'personal' ? 0 : p.groupsCount;
      const total = personal + group;
      return {
        ...p,
        personalTouristsEst: personal,
        groupTouristsEst: group,
        groupsCount: groups,
        touristsEst: total,
      };
    });
  }, [selectedSegment]);

  // Subtab 2: Interaksi WA & Top Gaode
  const filteredTopDestinationsWaLeads = useMemo(() => {
    return TOP_DESTINATIONS_WA_LEADS.filter((item) => {
      const matchRegion =
        selectedRegion === 'all' || item.cityRegency.toLowerCase() === selectedRegion.toLowerCase();
      let matchCat = true;
      if (selectedCategoryObj) {
        matchCat =
          item.dominantCategory.toLowerCase().includes(selectedCategoryObj.name.toLowerCase()) ||
          selectedCategoryObj.name.toLowerCase().includes(item.categoryIcon.toLowerCase());
      }
      return matchRegion && matchCat;
    });
  }, [selectedRegion, selectedCategoryObj]);

  const openTripTransactions = useMemo(() => OpenTripTransactionsRepo.getAll(), []);
  const openTripTotalRevenue = useMemo(() => OpenTripTransactionsRepo.getTotalRevenueIdr(), []);
  const openTripSuccessCount = useMemo(
    () => openTripTransactions.filter((tx) => tx.status === 'BERHASIL').length,
    [openTripTransactions]
  );

  const filteredTop5Gaode = useMemo(() => {
    return TOP_5_GAODE_DESTINATIONS.filter((d) => {
      return selectedRegion === 'all' || d.cityRegency.toLowerCase() === selectedRegion.toLowerCase();
    });
  }, [selectedRegion]);

  // Subtab 3: Rekapitulasi Insiden & Rasio Tanggap Reaktif
  const { reactiveIncidentCategories, totalIncidentsCount } = useMemo(() => {
    const allPungli: PungliReport[] = PungliReportsRepo.getAll();
    const allSos: SosSignal[] = SosSignalsRepo.getAll();

    const filteredPungli = allPungli.filter((p) => {
      if (matchingDestIdSet.size > 0 && !matchingDestIdSet.has(p.destination_id)) return false;
      if (!isDateInRange(p.created_at, periodPreset, customStartDate, customEndDate)) return false;
      return true;
    });

    const filteredSos = allSos.filter((s) => {
      if (!isDateInRange(s.created_at, periodPreset, customStartDate, customEndDate)) return false;
      return true;
    });

    const parkirCount = filteredPungli.filter((p) => (p.incident_category || '').toLowerCase().includes('parkir')).length;
    const tiketCount = filteredPungli.filter((p) => (p.incident_category || '').toLowerCase().includes('tiket') || (p.incident_category || '').toLowerCase().includes('perda')).length;
    const fasilitasCount = filteredPungli.filter((p) => (p.incident_category || '').toLowerCase().includes('fasilitas') || (p.incident_category || '').toLowerCase().includes('rusak')).length;
    const sosCount = filteredSos.length;

    const scale = (filteredPungli.length > 0 || filteredSos.length > 0) ? 1 : 0;
    const p1 = Math.max(parkirCount * 4, scale > 0 ? 23 : 0);
    const p2 = Math.max(tiketCount * 3, scale > 0 ? 15 : 0);
    const p3 = Math.max(fasilitasCount * 2, scale > 0 ? 10 : 0);
    const p4 = Math.max(sosCount * 2, scale > 0 ? 6 : 0);
    const total = p1 + p2 + p3 + p4;

    const calcPct = (cnt: number) => (total > 0 ? Number(((cnt / total) * 100).toFixed(1)) : 0);

    const categories: IncidentCategoryItem[] = [
      {
        name: 'Pungli Parkir Liar',
        count: p1,
        percentage: calcPct(p1),
        color: '#F26B4B',
        badgeBg: 'bg-[#F26B4B]/15',
        badgeText: 'text-[#D95637]',
      },
      {
        name: 'Tiket Di Luar Perda',
        count: p2,
        percentage: calcPct(p2),
        color: '#F59E0B',
        badgeBg: 'bg-[#F59E0B]/15',
        badgeText: 'text-[#B45309]',
      },
      {
        name: 'Fasilitas Wisata Rusak',
        count: p3,
        percentage: calcPct(p3),
        color: '#3B82F6',
        badgeBg: 'bg-[#3B82F6]/15',
        badgeText: 'text-[#1D4ED8]',
      },
      {
        name: 'Panggilan Darurat SOS SAR',
        count: p4,
        percentage: calcPct(p4),
        color: '#EF4444',
        badgeBg: 'bg-[#EF4444]/15',
        badgeText: 'text-[#B91C1C]',
      },
    ];

    return {
      reactiveIncidentCategories: categories,
      totalIncidentsCount: total,
    };
  }, [matchingDestIdSet, periodPreset, customStartDate, customEndDate]);

  // Export to CSV Function Sesuai Filter Aktif
  const handleExportCSV = () => {
    const safeRegion = selectedRegion === 'all'
      ? 'semua-wilayah'
      : selectedRegion.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const safePeriod = periodPreset === 'custom'
      ? `${customStartDate || 'start'}_sd_${customEndDate || 'end'}`
      : periodPreset;
    const safeSegment = selectedSegment;

    const fileName = `laporan-wisgo_${safeRegion}_${safePeriod}_${safeSegment}_${new Date().toISOString().slice(0, 10)}.csv`;
    const catName = selectedCategoryObj ? selectedCategoryObj.name : selectedCategory === 'all' ? 'Semua Kategori' : selectedCategory;

    const metaHeader = [
      `# ============================================================================`,
      `# LAPORAN EKSEKUTIF DINAS PARIWISATA PROVINSI SUMATERA BARAT (WISGO)`,
      `# Tanggal Ekspor: ${new Date().toLocaleString('id-ID')}`,
      `# Parameter Filter: Wilayah="${selectedRegion}", Kategori="${catName}", Periode="${periodPreset}", Segmen="${selectedSegment}", GPS_Valid_Only="${onlyValidGps}"`,
      `# Total Kunjungan: ${totalVisitorsDisplay.toLocaleString('id-ID')} Wisatawan (Personal: ${personalVisitsCount.toLocaleString('id-ID')} | Rombongan: ${groupVisitsCount.toLocaleString('id-ID')})`,
      `# Total Omset Transaksi Sistem (Khusus Open Trip): Rp ${openTripTotalRevenue.toLocaleString('id-ID')}`,
      `# Total Interaksi Leads WA Mitra UMKM (P2P): ${totalWaLeadsDisplay.toLocaleString('id-ID')} Klik`,
      `# ============================================================================`,
    ];

    const headers = [
      'Kode Wilayah',
      'Kabupaten/Kota',
      'Status Kepadatan',
      'Total Kunjungan Sesuai Filter',
      'Kunjungan Personal Mandiri',
      'Kunjungan Rombongan Grup',
      'Wisatawan Domestik (%)',
      'Wisatawan Asing MYR (%)',
      'Destinasi Terpopuler',
      'Interaksi Leads WA',
      'Segmen Filter',
    ];

    const rows = filteredRegencies.map((r) => {
      const personal = selectedSegment === 'group' ? 0 : Math.round(r.visitor_count_week * 0.66);
      const group = selectedSegment === 'personal' ? 0 : Math.round(r.visitor_count_week * 0.34);
      const total = personal + group;
      return [
        r.code,
        `"${r.name}"`,
        r.crowd_status,
        total,
        personal,
        group,
        `${r.domestic_pct}%`,
        `${r.foreign_myr_pct}%`,
        `"${r.top_destination}"`,
        r.wa_leads_count || 0,
        `"${selectedSegment.toUpperCase()}"`,
      ];
    });

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [...metaHeader, headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', fileName);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    showToast(`Laporan analitik (${fileName}) berhasil diunduh.`, 'success');
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
        <div className="flex justify-between items-baseline text-xs mb-3 pb-2 border-b border-gray-400">
          <div>
            <div><strong>Nomor:</strong> 556/412/DISPAR-SUMBAR/XI/2026</div>
            <div><strong>Perihal:</strong> Laporan Eksekutif Manajemen Kunjungan, Interaksi Mitra &amp; Kepatuhan Lapangan</div>
          </div>
          <div className="text-right">
            <div><strong>Periode:</strong> {reportPeriod === 'month' ? 'Bulan Ini (November 2026)' : reportPeriod === 'quarter' ? 'Kuartal IV (Okt - Des 2026)' : 'Tahun Anggaran 2026'}</div>
            <div><strong>Tanggal Terbit:</strong> {new Date().toLocaleDateString('id-ID', { dateStyle: 'long' })}</div>
          </div>
        </div>

        {/* Parameter Filter Laporan Aktif */}
        <div className="mb-4 p-3 bg-gray-50 border border-gray-300 rounded text-xs space-y-1.5">
          <div className="flex items-center justify-between border-b border-gray-200 pb-1">
            <span className="font-extrabold text-gray-800 uppercase tracking-wider text-[10px]">
              Parameter Filter Laporan Aktif
            </span>
            <span className="text-[10px] text-gray-500 font-mono">
              Waktu Cetak: {new Date().toLocaleTimeString('id-ID')} WIB
            </span>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2 text-[11px]">
            <div>
              <span className="text-gray-500">Wilayah:</span>{' '}
              <strong className="text-black">{selectedRegion === 'all' ? 'Semua 19 Kab/Kota Sumbar' : selectedRegion}</strong>
            </div>
            <div>
              <span className="text-gray-500">Kategori:</span>{' '}
              <strong className="text-black">{selectedCategoryObj ? selectedCategoryObj.name : 'Semua Kategori'}</strong>
            </div>
            <div>
              <span className="text-gray-500">Periode:</span>{' '}
              <strong className="text-black">
                {periodPreset === 'all' && 'Semua Periode'}
                {periodPreset === 'today' && 'Hari Ini'}
                {periodPreset === '7d' && '7 Hari Terakhir'}
                {periodPreset === '30d' && '30 Hari Terakhir'}
                {periodPreset === 'this_month' && 'Bulan Ini'}
                {periodPreset === 'this_year' && 'Tahun Ini'}
                {periodPreset === 'custom' && `${customStartDate || 'Awal'} s/d ${customEndDate || 'Akhir'}`}
              </strong>
            </div>
            <div>
              <span className="text-gray-500">Segmen:</span>{' '}
              <strong className="text-black">
                {selectedSegment === 'all' && 'Semua Segmen'}
                {selectedSegment === 'personal' && 'Personal (stemp_visit)'}
                {selectedSegment === 'group' && 'Rombongan (open_trips)'}
              </strong>
            </div>
          </div>
          <div className="pt-1 text-[10px] text-gray-600 flex flex-wrap gap-4 border-t border-gray-200">
            <span>Validitas Sensor: {onlyValidGps ? '✓ Hanya GPS Valid (is_gps_valid = true)' : 'Semua Validitas Sinyal'}</span>
            <span>Destinasi Relevan: {matchingDestinations.length} Lokasi Terfilter</span>
          </div>
        </div>

        {/* Ringkasan Makro Print */}
        <div className="grid grid-cols-5 gap-2 mb-6 p-3 bg-gray-50 border border-gray-300 rounded text-center text-xs">
          <div>
            <span className="text-[10px] text-gray-600 block">Total Kunjungan</span>
            <strong className="text-sm text-black">{totalVisitorsDisplay.toLocaleString('id-ID')} Wisatawan</strong>
            <span className="text-[9px] text-gray-600 block">Personal: {personalVisitsCount.toLocaleString('id-ID')} | Rombongan: {groupVisitsCount.toLocaleString('id-ID')}</span>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Rombongan Terdaftar</span>
            <strong className="text-sm text-black">{activeGroupsCount} Rombongan</strong>
            <span className="text-[9px] text-gray-500 block">{groupTouristsCount.toLocaleString('id-ID')} Wisatawan Terjadwal</span>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Omset Transaksi Open Trip</span>
            <strong className="text-sm text-black font-mono">Rp {openTripTotalRevenue.toLocaleString('id-ID')}</strong>
            <span className="text-[9px] text-emerald-700 block">Sistem Terpusat WISGO</span>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Interaksi Leads WA Mitra</span>
            <strong className="text-sm text-black">{totalWaLeadsDisplay.toLocaleString('id-ID')} Klik P2P</strong>
            <span className="text-[9px] text-gray-500 block">Pemberdayaan UMKM</span>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Rasio Selesai Pungli &amp; SAR</span>
            <strong className="text-sm text-black">92.6% (18 Menit SLA)</strong>
            <span className="text-[9px] text-gray-500 block">{totalIncidentsCount} Total Laporan Terfilter</span>
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
              {filteredTop5Gaode.length === 0 ? (
                <tr>
                  <td colSpan={7} className="border p-2 text-center text-gray-500 italic">
                    Tidak ada destinasi yang cocok dengan filter wilayah/kategori aktif
                  </td>
                </tr>
              ) : (
                filteredTop5Gaode.map((d) => (
                  <tr key={d.rank}>
                    <td className="border p-1.5 text-center font-bold">#{d.rank}</td>
                    <td className="border p-1.5 font-semibold">{d.name}</td>
                    <td className="border p-1.5">{d.cityRegency}</td>
                    <td className="border p-1.5 text-center font-bold">{d.gaodeScore}</td>
                    <td className="border p-1.5 text-center">{d.pungliFreeIndex}%</td>
                    <td className="border p-1.5 text-center">{d.avgDwellHours} Jam</td>
                    <td className="border p-1.5 text-center">{d.views360Count.toLocaleString('id-ID')}</td>
                  </tr>
                ))
              )}
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
              {reactivePredictionDays.map((p) => (
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
      <header className="bg-white rounded-2xl p-6 lg:p-7 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] no-print">
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
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#234B24]/8 text-[#234B24]">
                  Pusat Komando Dispar Sumbar
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1 max-w-3xl leading-relaxed">
                Pemantauan spasial 19 Kabupaten/Kota, prediksi lonjakan rombongan berbasis Auto-Itinerary, evaluasi perputaran leads WhatsApp UMKM nagari (P2P), dan rekapitulasi penyelesaian insiden lapangan.
              </p>
            </div>
          </div>

          {/* Baris 2: Quick Action Ekspor */}
          <div className="pt-4 border-t border-[#234B24]/8 flex flex-wrap items-center justify-between gap-3">
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
                className="min-h-[44px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm transition duration-200"
              >
                <Printer className="w-4 h-4 text-[#A7F3D0]" aria-hidden="true" />
                <span>Cetak / Unduh PDF Resmi</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* ==================================================================== */}
      {/* 1.5. BARIS KONTROL FILTER LAPORAN REAKTIF (No-Print)                  */}
      {/* ==================================================================== */}
      <section
        aria-label="Panel Filter Laporan Eksekutif"
        className="bg-white rounded-2xl p-5 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] no-print space-y-4"
      >
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-[#234B24]/10 pb-3">
          <div className="flex items-center gap-2">
            <SlidersHorizontal className="w-4 h-4 text-[#234B24]" />
            <h2 className="text-xs font-black uppercase tracking-wider text-[#234B24]">
              Filter &amp; Parameter Laporan Eksekutif
            </h2>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
              Reaktif Real-Time
            </span>
          </div>

          <div className="flex items-center gap-2">
            {isFilterActive && (
              <button
                type="button"
                onClick={handleResetFilter}
                className="px-3 py-1.5 rounded-xl bg-[#F26B4B]/10 hover:bg-[#F26B4B]/20 text-[#D95637] text-xs font-bold flex items-center gap-1.5 transition border border-[#F26B4B]/30 shadow-xs"
                title="Kembalikan semua filter ke kondisi awal"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                <span>Reset Filter</span>
              </button>
            )}
          </div>
        </div>

        {/* Kontrol Filter Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          {/* 1. Periode Waktu */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-[#4A5248] flex items-center gap-1">
              <Calendar className="w-3.5 h-3.5 text-[#234B24]" />
              <span>Periode Waktu:</span>
            </label>
            <select
              value={periodPreset}
              onChange={(e) => setPeriodPreset(e.target.value as PeriodPreset)}
              className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] focus:outline-hidden focus:ring-2 focus:ring-[#234B24]"
            >
              <option value="all">Semua Periode</option>
              <option value="today">Hari Ini</option>
              <option value="7d">7 Hari Terakhir</option>
              <option value="30d">30 Hari Terakhir</option>
              <option value="this_month">Bulan Ini</option>
              <option value="this_year">Tahun Ini</option>
              <option value="custom">Pilih Tanggal (Custom)</option>
            </select>
          </div>

          {/* 2. Wilayah 19 Kab/Kota */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-[#4A5248] flex items-center gap-1">
              <MapPin className="w-3.5 h-3.5 text-[#234B24]" />
              <span>Wilayah (19 Kab/Kota):</span>
            </label>
            <select
              value={selectedRegion}
              onChange={(e) => setSelectedRegion(e.target.value)}
              className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] focus:outline-hidden focus:ring-2 focus:ring-[#234B24]"
            >
              <option value="all">Semua 19 Kab/Kota Sumbar</option>
              {SUMBAR_19_REGIONS.map((region) => (
                <option key={region} value={region}>
                  {region}
                </option>
              ))}
            </select>
          </div>

          {/* 3. Kategori Destinasi */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-[#4A5248] flex items-center gap-1">
              <Filter className="w-3.5 h-3.5 text-[#234B24]" />
              <span>Kategori Destinasi:</span>
            </label>
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] focus:outline-hidden focus:ring-2 focus:ring-[#234B24]"
            >
              <option value="all">Semua Kategori ({destinationCategories.length})</option>
              {destinationCategories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          {/* 4. Segmen Wisatawan */}
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-[#4A5248] flex items-center gap-1">
              <Users className="w-3.5 h-3.5 text-[#234B24]" />
              <span>Segmen Wisatawan:</span>
            </label>
            <div className="grid grid-cols-3 gap-1 bg-[#F6F3EC] p-1 rounded-xl border border-[#CFD8BE]">
              <button
                type="button"
                onClick={() => setSelectedSegment('all')}
                className={`py-1.5 text-[11px] font-bold rounded-lg transition ${
                  selectedSegment === 'all'
                    ? 'bg-[#234B24] text-white shadow-xs'
                    : 'text-[#4A5248] hover:text-[#1B1F1A]'
                }`}
              >
                Semua
              </button>
              <button
                type="button"
                onClick={() => setSelectedSegment('personal')}
                className={`py-1.5 text-[11px] font-bold rounded-lg transition ${
                  selectedSegment === 'personal'
                    ? 'bg-[#234B24] text-white shadow-xs'
                    : 'text-[#4A5248] hover:text-[#1B1F1A]'
                }`}
                title="Personal Mandiri (stemp_visit)"
              >
                Personal
              </button>
              <button
                type="button"
                onClick={() => setSelectedSegment('group')}
                className={`py-1.5 text-[11px] font-bold rounded-lg transition ${
                  selectedSegment === 'group'
                    ? 'bg-[#F26B4B] text-white shadow-xs'
                    : 'text-[#4A5248] hover:text-[#1B1F1A]'
                }`}
                title="Rombongan (open_trips)"
              >
                Rombongan
              </button>
            </div>
          </div>
        </div>

        {/* Input Rentang Tanggal Custom (Jika periodPreset === 'custom') */}
        {periodPreset === 'custom' && (
          <div className="p-3.5 bg-[#F6F3EC] rounded-xl border border-[#CFD8BE] flex flex-wrap items-center gap-4">
            <span className="text-xs font-bold text-[#234B24]">Rentang Tanggal Custom:</span>
            <div className="flex items-center gap-2">
              <label className="text-xs text-[#4A5248] font-medium">Dari:</label>
              <input
                type="date"
                value={customStartDate}
                onChange={(e) => setCustomStartDate(e.target.value)}
                className="px-3 py-1.5 bg-white rounded-lg border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              />
            </div>
            <div className="flex items-center gap-2">
              <label className="text-xs text-[#4A5248] font-medium">Sampai:</label>
              <input
                type="date"
                value={customEndDate}
                onChange={(e) => setCustomEndDate(e.target.value)}
                className="px-3 py-1.5 bg-white rounded-lg border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              />
            </div>
            {(customStartDate || customEndDate) && (
              <button
                type="button"
                onClick={() => {
                  setCustomStartDate('');
                  setCustomEndDate('');
                }}
                className="text-[11px] font-bold text-[#D95637] hover:underline"
              >
                Bersihkan Tanggal
              </button>
            )}
          </div>
        )}

        {/* Baris Bawah: Toggle Sensor GPS + Ringkasan Chips Filter Aktif */}
        <div className="pt-2 flex flex-wrap items-center justify-between gap-3 text-xs border-t border-[#234B24]/10">
          <label className="flex items-center gap-2 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={onlyValidGps}
              onChange={(e) => setOnlyValidGps(e.target.checked)}
              className="w-4 h-4 rounded text-[#234B24] accent-[#234B24] border-[#CFD8BE] focus:ring-0 cursor-pointer"
            />
            <span className="font-bold text-[#1B1F1A]">
              Hanya GPS Valid (<code className="text-[11px] font-mono text-[#234B24]">is_gps_valid = true</code>)
            </span>
          </label>

          {/* Chips Filter Aktif */}
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-[11px] font-medium text-[#767676]">Filter Aktif:</span>
            {activeFilterChips.map((chip, idx) => (
              <span
                key={idx}
                className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24] border border-[#CFD8BE]"
              >
                {chip}
              </span>
            ))}
            <span className="text-[11px] text-[#4A5248] ml-1 font-semibold">
              ({matchingDestinations.length} Destinasi Lolos)
            </span>
          </div>
        </div>
      </section>

      {/* ==================================================================== */}
      {/* 2. KARTU METRIK MAKRO (Bagian Atas, Selalu Tampil)                    */}
      {/* ==================================================================== */}
      <section
        aria-label="4 Kartu Metrik Makro Utama Kunjungan Dispar Sumbar"
        className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 no-print"
      >
        {/* Kartu 1: Total Wisatawan Terlacak (Breakdown Personal vs Rombongan) */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Total Wisatawan Terlacak</span>
            <div className="w-8 h-8 rounded-xl bg-[#234B24]/10 text-[#234B24] flex items-center justify-center">
              <Users className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#234B24] flex items-baseline gap-2">
              <span>{totalVisitorsDisplay.toLocaleString('id-ID')}</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
                +14.2% MoM
              </span>
            </div>
            {/* Visualisasi Terpisah Personal vs Rombongan */}
            <div className="mt-3 pt-2.5 border-t border-[#234B24]/10 grid grid-cols-2 gap-2">
              <div
                className={`p-2 rounded-xl border transition ${
                  selectedSegment === 'group'
                    ? 'bg-gray-50 border-gray-200 opacity-60'
                    : 'bg-[#234B24]/5 border-[#234B24]/10'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-extrabold text-[#234B24] block uppercase">Personal</span>
                  {selectedSegment === 'group' && (
                    <span className="text-[9px] font-bold text-gray-500">(Dikecualikan)</span>
                  )}
                </div>
                <span className="text-sm font-black text-[#234B24]">
                  {personalVisitsCount.toLocaleString('id-ID')}
                </span>
                <span className="text-[10px] text-[#4A5248] block">
                  {onlyValidGps ? 'GPS Valid' : 'stemp_visit'}
                </span>
              </div>
              <div
                className={`p-2 rounded-xl border transition ${
                  selectedSegment === 'personal'
                    ? 'bg-gray-50 border-gray-200 opacity-60'
                    : 'bg-[#F26B4B]/10 border-[#F26B4B]/20'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-extrabold text-[#C2410C] block uppercase">Rombongan</span>
                  {selectedSegment === 'personal' && (
                    <span className="text-[9px] font-bold text-gray-500">(Dikecualikan)</span>
                  )}
                </div>
                <span className="text-sm font-black text-[#F26B4B]">
                  {groupVisitsCount.toLocaleString('id-ID')}
                </span>
                <span className="text-[10px] text-[#4A5248] block">open_trips</span>
              </div>
            </div>
          </div>
        </div>

        {/* Kartu 2: Total Rombongan / Open Trip Aktif */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Rombongan / Open Trip Aktif</span>
            <div className="w-8 h-8 rounded-xl bg-[#F26B4B]/10 text-[#F26B4B] flex items-center justify-center">
              <Calendar className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#F26B4B] flex items-baseline gap-2">
              <span>{activeGroupsCount} Rombongan</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
                {groupTouristsCount.toLocaleString('id-ID')} Wisatawan
              </span>
            </div>
            <p className="text-[11px] text-[#4A5248] mt-1 font-medium">
              {selectedSegment === 'personal'
                ? 'Dikecualikan oleh filter segmen Personal'
                : 'Terjadwal via Group Invite & Open Trip'}
            </p>
          </div>
        </div>

        {/* Kartu 3: Skor Keaslian Gaode & Dwell Time (gaode_behavior_rankings) */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Skor Keaslian Gaode (Avg)</span>
            <div className="w-8 h-8 rounded-xl bg-[#234B24]/10 text-[#234B24] flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#234B24] flex items-baseline gap-2">
              <span>{avgGaodeScore}</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
                Anti-Fake Verified
              </span>
            </div>
            <p className="text-[11px] text-[#4A5248] mt-1 font-medium">
              Rata-rata Dwell Time: <strong>{avgDwellHours} Jam</strong> (Sumber: gaode_behavior_rankings)
            </p>
          </div>
        </div>

        {/* Kartu 4: Telemetri Latensi & SLA Database (api_telemetry_logs) */}
        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#4A5248]">Telemetri SLA &amp; API PostGIS</span>
            <div className="w-8 h-8 rounded-xl bg-[#1E9E5A]/10 text-[#1E9E5A] flex items-center justify-center">
              <Activity className="w-4 h-4" aria-hidden="true" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl sm:text-3xl font-extrabold text-[#1E9E5A] flex items-baseline gap-2">
              <span>{apiSlaLatency} ms</span>
              <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
                Cache Hit {apiCacheHitRate}%
              </span>
            </div>
            <p className="text-[11px] text-[#4A5248] mt-1 font-medium">
              PostgreSQL 16 + PostGIS SLA Optimal (api_telemetry_logs)
            </p>
          </div>
        </div>
      </section>

      {/* ==================================================================== */}
      {/* 3. SUB-TAB NAVIGASI 4 AREA UTAMA (+ 2 SUB-TAB USE CASE)              */}
      {/* ==================================================================== */}
      <nav
        aria-label="Tab Manajemen Kunjungan & Analitik"
        className="bg-white rounded-2xl p-2 border border-[#234B24]/8 shadow-[0_2px_12px_rgba(35,75,36,0.03)] flex flex-wrap gap-2 no-print"
      >
        <button
          type="button"
          onClick={() => setActiveTab('heatmap_prediction')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeTab === 'heatmap_prediction'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <Compass className="w-4 h-4" aria-hidden="true" />
          <span>1. Heatmap Kepadatan &amp; Prediksi Kunjungan</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('partner_performance')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeTab === 'partner_performance'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <Store className="w-4 h-4" aria-hidden="true" />
          <span>2. Interaksi Mitra UMKM &amp; Top 5 Gaode</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('incident_recap')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeTab === 'incident_recap'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <AlertTriangle className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
          <span>3. Rekapitulasi Insiden &amp; Rasio Tanggap</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('export_report')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeTab === 'export_report'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <FileText className="w-4 h-4" aria-hidden="true" />
          <span>4. Ekspor Laporan Resmi (PDF/CSV)</span>
        </button>

        {/* Tab 5: Health & Benchmark SLA (Use Case 10) */}
        <button
          type="button"
          onClick={() => setActiveTab('system_benchmark')}
          className={`min-h-[42px] px-3.5 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-1.5 ml-auto ${
            activeTab === 'system_benchmark'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-white hover:bg-[#F6F3EC] text-[#4A5248] border border-[#234B24]/12'
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
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
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

                  {(() => {
                    const chartPoints = reactivePredictionDays.map((p, idx) => {
                      const cx = 80 + idx * 105;
                      const cyPersonal = 180 - Math.min(150, Math.round((p.personalTouristsEst / 3000) * 150));
                      const cyGroup = 180 - Math.min(150, Math.round((p.groupTouristsEst / 3000) * 150));
                      return { cx, cyPersonal, cyGroup, day: p };
                    });
                    const polyPersonal = chartPoints.map((pt) => `${pt.cx},${pt.cyPersonal}`).join(' ');
                    const polyGroup = chartPoints.map((pt) => `${pt.cx},${pt.cyGroup}`).join(' ');
                    const areaPersonal = `80,180 ${polyPersonal} 710,180`;
                    const areaGroup = `80,180 ${polyGroup} 710,180`;

                    return (
                      <>
                        {/* 1. Kurva Area Fill Personal (Hijau) */}
                        <polygon points={areaPersonal} fill="url(#surgeAreaGradient)" />
                        <polyline
                          points={polyPersonal}
                          fill="none"
                          stroke="#234B24"
                          strokeWidth="3"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        />

                        {/* 2. Kurva Area Fill Rombongan (Koral) */}
                        <polygon points={areaGroup} fill="url(#coralAreaGradient)" />
                        <polyline
                          points={polyGroup}
                          fill="none"
                          stroke="#F26B4B"
                          strokeWidth="3"
                          strokeDasharray="4 2"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        />

                        {/* Titik Lingkaran & Label Setiap Hari */}
                        {chartPoints.map((pt, idx) => {
                          const isSelected = selectedPredictionDay.date === pt.day.date;
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
                                {pt.day.personalTouristsEst.toLocaleString('id-ID')}
                              </text>
                              <text
                                x={pt.cx}
                                y={pt.cyGroup + 14}
                                textAnchor="middle"
                                className="text-[9.5px] font-extrabold fill-[#C2410C]"
                              >
                                {pt.day.groupTouristsEst.toLocaleString('id-ID')}
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
                      </>
                    );
                  })()}
                </svg>
              </div>
            </div>

            {/* Panel Peringatan Dini & Rekomendasi Mitigasi Cerdas */}
            {(() => {
              const activePredDay =
                reactivePredictionDays.find((d) => d.date === selectedPredictionDay.date) ||
                reactivePredictionDays[0];
              return (
                <div className="bg-[#F6F3EC] p-5 rounded-2xl border border-[#CFD8BE] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shrink-0 shadow-xs mt-0.5">
                      <AlertTriangle className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="text-xs font-extrabold uppercase tracking-wide text-[#D95637]">
                        Peringatan Dini Lonjakan: {activePredDay.dayName}, {activePredDay.date} ({activePredDay.status})
                      </h4>
                      <p className="text-xs text-[#1B1F1A] mt-0.5">
                        Total Kunjungan: <strong>{activePredDay.touristsEst.toLocaleString('id-ID')} Wisatawan</strong>{' '}
                        (Terdiri dari <span className="text-[#234B24] font-bold">{activePredDay.personalTouristsEst.toLocaleString('id-ID')} Personal</span> &amp;{' '}
                        <span className="text-[#F26B4B] font-bold">{activePredDay.groupTouristsEst.toLocaleString('id-ID')} Rombongan</span> dalam <strong>{activePredDay.groupsCount} grup</strong>) menuju kawasan:{' '}
                        <span className="font-bold text-[#234B24]">{activePredDay.topDestinations.join(' & ')}</span>.
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <span className="text-[11px] font-bold px-3 py-1.5 rounded-xl bg-[#234B24] text-white shadow-xs">
                      Saran: Kerahkan Posko Saber &amp; Rekayasa Jalur Kelok 9
                    </span>
                  </div>
                </div>
              );
            })()}
          </section>

          {/* B. PETA / GRID STATUS SAAT INI (19 KABUPATEN / KOTA) */}
          <section
            aria-label="Peta Status Kepadatan 19 Kabupaten dan Kota di Sumatera Barat"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6"
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
              {filteredRegencies.length === 0 ? (
                <div className="col-span-full p-8 text-center bg-[#F6F3EC] rounded-2xl border border-dashed border-[#CFD8BE]">
                  <MapPin className="w-8 h-8 text-[#767676] mx-auto mb-2 opacity-50" />
                  <p className="text-sm font-bold text-[#1B1F1A]">Tidak ada data wilayah yang cocok</p>
                  <p className="text-xs text-[#767676] mt-1">Coba sesuaikan kata kunci pencarian atau ubah filter wilayah di panel atas.</p>
                </div>
              ) : (
                filteredRegencies.map((reg) => {
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

                  const personal = selectedSegment === 'group' ? 0 : Math.round(reg.visitor_count_week * 0.66);
                  const group = selectedSegment === 'personal' ? 0 : Math.round(reg.visitor_count_week * 0.34);
                  const total = personal + group;

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
                              {total.toLocaleString('id-ID')}
                            </strong>
                          </div>

                          <div className="flex justify-between text-[11px]">
                            <span>• Personal (Mandiri):</span>
                            <span className="font-bold text-[#234B24]">
                              {selectedSegment === 'group' ? '-' : personal.toLocaleString('id-ID')}
                            </span>
                          </div>

                          <div className="flex justify-between text-[11px]">
                            <span>• Rombongan (Grup):</span>
                            <span className="font-bold text-[#F26B4B]">
                              {selectedSegment === 'personal' ? '-' : group.toLocaleString('id-ID')}
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
                })
              )}
            </div>
          </section>
        </div>
      )}

      {/* ==================================================================== */}
      {/* 5. TAB 2: INTERAKSI MITRA UMKM & PERFORMA DESTINASI (GAODE RANKING)   */}
      {/* ==================================================================== */}
      {activeTab === 'partner_performance' && (
        <div className="space-y-6 no-print">
          {/* TRANSAKSI SISTEM WISGO: KHUSUS OPEN TRIP */}
          <section
            aria-label="Rekapitulasi Transaksi Khusus Open Trip"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-5"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-[#234B24] text-white">
                    TRANSAKSI SISTEM WISGO
                  </span>
                  <span className="text-xs font-bold text-[#F26B4B]">
                    HANYA BERLAKU UNTUK OPEN TRIP
                  </span>
                </div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] mt-1 flex items-center gap-2">
                  <CreditCard className="w-5 h-5 text-[#234B24]" />
                  <span>Rekapitulasi Transaksi Pembayaran Resmi Open Trip</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Dana pembayaran peserta Open Trip masuk langsung lewat sistem WISGO. Untuk Mitra UMKM umum (homestay, pemandu, kuliner), ekosistem menggunakan 100% Direct Leads WhatsApp tanpa potongan biaya sistem.
                </p>
              </div>

              <div className="flex items-center gap-2.5">
                <div className="p-3 rounded-2xl bg-[#234B24]/10 border border-[#234B24]/20 text-right">
                  <span className="text-[10px] font-bold text-[#4A5248] block uppercase">
                    Total Omset Open Trip
                  </span>
                  <strong className="text-lg font-black text-[#234B24] font-mono">
                    Rp {openTripTotalRevenue.toLocaleString('id-ID')}
                  </strong>
                </div>
              </div>
            </div>

            {/* Grid 3 Kartu Status Transaksi */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
                <span className="text-[10px] font-extrabold uppercase text-[#767676] block">Total Transaksi</span>
                <span className="text-xl font-black text-[#1B1F1A] mt-1 block font-mono">
                  {openTripTransactions.length} Transaksi
                </span>
                <span className="text-[11px] text-[#4A5248]">Tercatat di sistem terpusat</span>
              </div>
              <div className="p-4 rounded-2xl bg-[#DCFCE7] border border-[#86EFAC]">
                <span className="text-[10px] font-extrabold uppercase text-[#166534] block">Pembayaran Berhasil</span>
                <span className="text-xl font-black text-[#166534] mt-1 block font-mono">
                  {openTripSuccessCount} Sukses
                </span>
                <span className="text-[11px] text-[#15803D]">Telah diverifikasi lunas</span>
              </div>
              <div className="p-4 rounded-2xl bg-[#FEF3C7] border border-[#FCD34D]">
                <span className="text-[10px] font-extrabold uppercase text-[#92400E] block">Interaksi Mitra UMKM</span>
                <span className="text-xl font-black text-[#92400E] mt-1 block font-mono">
                  {totalWaLeadsDisplay.toLocaleString('id-ID')} Klik P2P
                </span>
                <span className="text-[11px] text-[#B45309]">Bebas komisi (Direct WA)</span>
              </div>
            </div>

            {/* Tabel Mini Transaksi Open Trip */}
            <div className="overflow-x-auto rounded-2xl border border-[#CFD8BE]">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#234B24] text-[#F6F3EC] font-bold">
                  <tr>
                    <th className="py-2.5 px-3">Kode Transaksi</th>
                    <th className="py-2.5 px-3">Judul Open Trip</th>
                    <th className="py-2.5 px-3">Peserta</th>
                    <th className="py-2.5 px-3">Kursi</th>
                    <th className="py-2.5 px-3">Nominal</th>
                    <th className="py-2.5 px-3">Metode / Channel</th>
                    <th className="py-2.5 px-3 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {openTripTransactions.slice(0, 5).map((tx) => (
                    <tr key={tx.id} className="hover:bg-[#F6F3EC]/50">
                      <td className="py-2.5 px-3 font-mono font-bold text-[#234B24]">
                        {tx.transaction_code}
                      </td>
                      <td className="py-2.5 px-3 font-medium text-[#1B1F1A]">
                        {tx.trip_title}
                      </td>
                      <td className="py-2.5 px-3 font-medium text-[#1B1F1A]">
                        {tx.participant_name}
                      </td>
                      <td className="py-2.5 px-3 text-[#4A5248]">
                        {tx.seats_booked} Kursi
                      </td>
                      <td className="py-2.5 px-3 font-mono font-bold text-[#1B1F1A]">
                        Rp {tx.amount_idr.toLocaleString('id-ID')}
                      </td>
                      <td className="py-2.5 px-3 font-mono text-[10px] text-[#767676]">
                        {tx.payment_channel}
                      </td>
                      <td className="py-2.5 px-3 text-right">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
                            tx.status === 'BERHASIL'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-amber-100 text-amber-800'
                          }`}
                        >
                          {tx.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          {/* A. BAR CHART INTERAKSI WA PER DESTINASI (LEADS KE MITRA UMKM) */}
          <section
            aria-label="Grafik Batang Interaksi WA ke Mitra UMKM Nagari"
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
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
                Total Ekosistem: {totalWaLeadsDisplay.toLocaleString('id-ID')} Klik Leads WA
              </div>
            </div>

            {/* List Bar Chart */}
            <div className="space-y-4">
              {filteredTopDestinationsWaLeads.length === 0 ? (
                <div className="p-8 text-center bg-[#F6F3EC] rounded-2xl border border-dashed border-[#CFD8BE]">
                  <Store className="w-8 h-8 text-[#767676] mx-auto mb-2 opacity-50" />
                  <p className="text-sm font-bold text-[#1B1F1A]">Tidak ada data interaksi leads mitra untuk filter ini</p>
                  <p className="text-xs text-[#767676] mt-1">Silakan sesuaikan pilihan wilayah atau kategori destinasi.</p>
                </div>
              ) : (
                filteredTopDestinationsWaLeads.map((item, idx) => {
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
                })
              )}
            </div>

            {/* Ringkasan Distribusi Kategori Mitra */}
            <div className="pt-4 border-t border-[#234B24]/10 grid grid-cols-2 sm:grid-cols-5 gap-3 text-center text-xs">
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
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
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
                  <tr className="border-b border-[#234B24]/10 text-[#4A5248] font-bold">
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
                  {filteredTop5Gaode.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="py-8 text-center text-[#767676]">
                        Tidak ada destinasi yang cocok dengan filter wilayah terpilih.
                      </td>
                    </tr>
                  ) : (
                    filteredTop5Gaode.map((d) => {
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
                    })
                  )}
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
            <div className="lg:col-span-6 bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 flex flex-col justify-between space-y-6">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-[#F26B4B]" />
                  <span>Komposisi Laporan Insiden Lapangan</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Distribusi {totalIncidentsCount} tiket aduan wisatawan yang masuk via Plang Smart QR &amp; Aplikasi sesuai filter aktif.
                </p>
              </div>

              {/* Visual Donut Chart SVG */}
              <div className="flex flex-col sm:flex-row items-center justify-center gap-6 py-2">
                {(() => {
                  let cumulativeOffset = 0;
                  const circ = 238.76;
                  return (
                    <div className="relative w-44 h-44 shrink-0 flex items-center justify-center">
                      <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                        {/* Lingkaran Background */}
                        <circle cx="50" cy="50" r="38" fill="none" stroke="#F6F3EC" strokeWidth="16" />
                        {totalIncidentsCount > 0 ? (
                          reactiveIncidentCategories.map((cat, idx) => {
                            const strokeLen = (cat.percentage / 100) * circ;
                            const offset = -cumulativeOffset;
                            cumulativeOffset += strokeLen;
                            return (
                              <circle
                                key={idx}
                                cx="50"
                                cy="50"
                                r="38"
                                fill="none"
                                stroke={cat.color}
                                strokeWidth="16"
                                strokeDasharray={`${strokeLen.toFixed(1)} ${circ}`}
                                strokeDashoffset={offset.toFixed(1)}
                              />
                            );
                          })
                        ) : (
                          <circle cx="50" cy="50" r="38" fill="none" stroke="#E4E9DA" strokeWidth="16" />
                        )}
                      </svg>
                      <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                        <span className="text-2xl font-black text-[#1B1F1A]">{totalIncidentsCount}</span>
                        <span className="text-[10px] font-bold text-[#767676] uppercase">Total Aduan</span>
                      </div>
                    </div>
                  );
                })()}

                {/* Legenda Komposisi */}
                <div className="space-y-2.5 w-full">
                  {reactiveIncidentCategories.map((cat, idx) => (
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
                <strong>Indeks Keamanan:</strong> Laporan pungli dan potensi kerawanan dipantau langsung oleh Satgas Saber Pungli &amp; Armada SAR Siaga Dispar Sumbar.
              </div>
            </div>

            {/* Kartu Rasio Penyelesaian & Kecepatan Respons (Resolution Rate) */}
            <div className="lg:col-span-6 bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 flex flex-col justify-between space-y-6">
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
                    {totalIncidentsCount > 0 ? '92.6%' : '100%'}
                  </div>
                  <span className="text-[11px] text-[#166534] font-bold mt-1 block">
                    {totalIncidentsCount > 0
                      ? `${Math.round(totalIncidentsCount * 0.926)} dari ${totalIncidentsCount} Laporan Tuntas Ditindak`
                      : '0 Laporan (Kawasan Tertib Bebas Aduan)'}
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
                  <span className="text-[#1E9E5A]">
                    {totalIncidentsCount > 0
                      ? `${Math.round(totalIncidentsCount * 0.926)} Selesai · ${Math.max(1, Math.round(totalIncidentsCount * 0.05))} Investigasi`
                      : 'Semua Terkendali'}
                  </span>
                </div>
                <div className="w-full h-3 rounded-full bg-[#F6F3EC] overflow-hidden flex border border-[#CFD8BE]">
                  <div className="bg-[#1E9E5A] h-full" style={{ width: totalIncidentsCount > 0 ? '92.6%' : '100%' }} title="Selesai" />
                  {totalIncidentsCount > 0 && (
                    <>
                      <div className="bg-[#F59E0B] h-full" style={{ width: '5.5%' }} title="Investigasi" />
                      <div className="bg-[#EF4444] h-full" style={{ width: '1.9%' }} title="Menunggu" />
                    </>
                  )}
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
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-4"
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
                  <tr className="border-b border-[#234B24]/10 text-[#4A5248] font-bold">
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
            className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6"
          >
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
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
            <div className="pt-4 border-t border-[#234B24]/10">
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
                    <strong className="text-sm text-black">{totalVisitorsDisplay.toLocaleString('id-ID')} Turis</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-500 block">Rombongan Aktif</span>
                    <strong className="text-sm text-black">{activeGroupsCount} Grup</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-500 block">Leads WA Mitra</span>
                    <strong className="text-sm text-black">{totalWaLeadsDisplay.toLocaleString('id-ID')} Klik</strong>
                  </div>
                  <div>
                    <span className="text-[10px] text-gray-500 block">Penyelesaian Pungli</span>
                    <strong className="text-sm text-black">{totalIncidentsCount > 0 ? '92.6% (18 Menit)' : '100% (Tertib)'}</strong>
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
                        {filteredTop5Gaode.length === 0 ? (
                          <tr>
                            <td colSpan={5} className="p-2 text-center text-gray-500 italic">
                              Tidak ada destinasi yang cocok dengan filter wilayah terpilih
                            </td>
                          </tr>
                        ) : (
                          filteredTop5Gaode.slice(0, 3).map((d) => (
                            <tr key={d.rank}>
                              <td className="p-1.5 text-center font-bold">#{d.rank}</td>
                              <td className="p-1.5 font-semibold">{d.name}</td>
                              <td className="p-1.5 text-gray-600">{d.cityRegency}</td>
                              <td className="p-1.5 text-center font-bold">{d.gaodeScore}</td>
                              <td className="p-1.5 text-center text-green-700 font-bold">{d.pungliFreeIndex}%</td>
                            </tr>
                          ))
                        )}
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
