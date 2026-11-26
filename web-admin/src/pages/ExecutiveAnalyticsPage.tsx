import React, { useState, useEffect, useMemo } from 'react';
import {
  BarChart3,
  MapPin,
  TrendingUp,
  Download,
  Printer,
  ShieldCheck,
  AlertTriangle,
  Clock,
  Store,
  Calendar,
  Flame,
  Activity,
  Sparkles,
  Star,
  FileText,
  Search,
  Users,
  Compass,
  FileSpreadsheet,
  RotateCcw,
  CreditCard,
} from 'lucide-react';
import {
  Destination,
  Partner,
  RegencyHeatmapData,
  GaodeBehaviorRanking,
  StempVisit,
  OpenTrip,
  ApiTelemetryLog,
  PungliReport,
  SosSignal,
  HazardAlert,
} from '../types/contract';
import { fetchRegencyHeatmap } from '../services/api';
import {
  GaodeRankingsRepo,
  ApiTelemetryLogsRepo,
  StempVisitsRepo,
  OpenTripsRepo,
  CategoriesRepo,
  PungliReportsRepo,
  SosSignalsRepo,
  HazardAlertsRepo,
  OpenTripTransactionsRepo,
  UserChallengeRewardsRepo,
} from '../services/dbRepository';
import {
  PARTNER_CATEGORIES,
  SUMBAR_REGENCIES,
} from '../data/mockDestinations';
import { SystemHealthBenchmarkSubTab } from '../components/SystemHealthBenchmarkSubTab';

export type AnalyticsSubTab =
  | 'heatmap_prediction'
  | 'partner_performance'
  | 'incident_recap'
  | 'export_report'
  | 'intel_heatmap'
  | 'system_benchmark';

export type PeriodPreset =
  | 'all'
  | 'today'
  | '7d'
  | '30d'
  | 'this_month'
  | 'this_year'
  | 'custom';

export type TouristSegment = 'all' | 'personal' | 'group';

const SUMBAR_19_REGIONS = SUMBAR_REGENCIES.filter((r) => r !== 'Semua Kab/Kota');

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
  if (preset === '7d') return Math.abs(d.getTime() - nowMs) <= 7 * dayMs;
  if (preset === '30d') return Math.abs(d.getTime() - nowMs) <= 30 * dayMs;
  if (preset === 'this_month') {
    return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
  }
  if (preset === 'this_year') return d.getFullYear() === now.getFullYear();
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

interface IncidentCategoryItem {
  name: string;
  count: number;
  percentage: number;
  color: string;
  badgeBg: string;
  badgeText: string;
}

interface UnifiedIncidentActionRow {
  id: string;
  time: string;
  destination: string;
  incidentType: string;
  officer: string;
  actionTaken: string;
  status: string;
}

interface ExecutiveAnalyticsPageProps {
  destinations: Destination[];
  partners: Partner[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  initialSubTab?: AnalyticsSubTab;
}

const DAY_NAMES_ID = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
const DAY_WEIGHTS = [1.45, 0.72, 0.68, 0.78, 0.95, 1.25, 1.58]; // Sun..Sat seasonal demand multipliers

export const ExecutiveAnalyticsPage: React.FC<ExecutiveAnalyticsPageProps> = ({
  destinations,
  partners,
  showToast,
  initialSubTab = 'heatmap_prediction',
}) => {
  const normalizedInitialTab =
    initialSubTab === 'intel_heatmap'
      ? 'heatmap_prediction'
      : initialSubTab || 'heatmap_prediction';

  const [activeTab, setActiveTab] = useState<AnalyticsSubTab>(normalizedInitialTab);
  const [heatmapData, setHeatmapData] = useState<RegencyHeatmapData[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchRegency, setSearchRegency] = useState<string>('');
  const [reportPeriod, setReportPeriod] = useState<'month' | 'quarter' | 'year'>('month');

  // Reactive Filter State
  const [periodPreset, setPeriodPreset] = useState<PeriodPreset>('all');
  const [customStartDate, setCustomStartDate] = useState<string>('');
  const [customEndDate, setCustomEndDate] = useState<string>('');
  const [selectedRegion, setSelectedRegion] = useState<string>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedSegment, setSelectedSegment] = useState<TouristSegment>('all');
  const [onlyValidGps, setOnlyValidGps] = useState<boolean>(true);
  const [selectedDayIndex, setSelectedDayIndex] = useState<number>(5);

  const todayFormatted = useMemo(
    () =>
      new Date().toLocaleDateString('id-ID', {
        day: 'numeric',
        month: 'long',
        year: 'numeric',
      }),
    []
  );

  // 5 Canonical Destination Categories from CategoriesRepo
  const destinationCategories = useMemo(
    () => CategoriesRepo.getByModule('destination'),
    []
  );

  const selectedCategoryObj = useMemo(() => {
    if (selectedCategory === 'all') return null;
    return (
      destinationCategories.find(
        (c) => c.id === selectedCategory || c.name === selectedCategory
      ) || null
    );
  }, [selectedCategory, destinationCategories]);

  const isFilterActive = useMemo(
    () =>
      periodPreset !== 'all' ||
      customStartDate !== '' ||
      customEndDate !== '' ||
      selectedRegion !== 'all' ||
      selectedCategory !== 'all' ||
      selectedSegment !== 'all' ||
      !onlyValidGps,
    [
      periodPreset,
      customStartDate,
      customEndDate,
      selectedRegion,
      selectedCategory,
      selectedSegment,
      onlyValidGps,
    ]
  );

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

  useEffect(() => {
    if (initialSubTab) {
      setActiveTab(initialSubTab === 'intel_heatmap' ? 'heatmap_prediction' : initialSubTab);
    }
  }, [initialSubTab]);

  useEffect(() => {
    const loadAnalytics = async () => {
      try {
        const heat = await fetchRegencyHeatmap();
        setHeatmapData(heat);
      } catch {
        showToast('Gagal memuat data sebaran wilayah.', 'error');
      }
    };
    loadAnalytics();
  }, [showToast]);

  // Matching destinations per region & 5 master categories
  const matchingDestinations = useMemo(() => {
    return destinations.filter((d) => {
      const matchRegion =
        selectedRegion === 'all' ||
        d.city_regency.toLowerCase() === selectedRegion.toLowerCase();
      const matchCat =
        selectedCategory === 'all' ||
        d.category_id === selectedCategory ||
        d.category === selectedCategory ||
        Boolean(selectedCategoryObj && d.category === selectedCategoryObj.name);
      return matchRegion && matchCat;
    });
  }, [destinations, selectedRegion, selectedCategory, selectedCategoryObj]);

  const matchingDestIdSet = useMemo(
    () => new Set(matchingDestinations.map((d) => d.id)),
    [matchingDestinations]
  );

  // Enrich heatmap regencies with live partner WA clicks
  const enrichedHeatmapData = useMemo(() => {
    const clicksByRegency: Record<string, number> = {};
    partners.forEach((p) => {
      const key = (p.city_regency || '').toLowerCase();
      clicksByRegency[key] = (clicksByRegency[key] || 0) + Number(p.wa_click_count || 0);
    });
    return heatmapData.map((r) => {
      const livePartnerClicks = clicksByRegency[r.name.toLowerCase()] || 0;
      return {
        ...r,
        wa_leads_count: Math.max(r.wa_leads_count || 0, livePartnerClicks),
      };
    });
  }, [heatmapData, partners]);

  const filteredRegencies = useMemo(() => {
    return enrichedHeatmapData.filter((item) => {
      const matchRegion =
        selectedRegion === 'all' || item.name.toLowerCase() === selectedRegion.toLowerCase();
      let matchCat = true;
      if (selectedCategory !== 'all') {
        matchCat = matchingDestinations.some(
          (d) => d.city_regency.toLowerCase() === item.name.toLowerCase()
        );
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
  }, [
    enrichedHeatmapData,
    selectedRegion,
    selectedCategory,
    matchingDestinations,
    searchRegency,
    statusFilter,
  ]);

  // Live Trip Go Transactions
  const tripGoTransactions = useMemo(() => OpenTripTransactionsRepo.getAll(), []);
  const tripGoTotalRevenue = useMemo(() => OpenTripTransactionsRepo.getTotalRevenueIdr(), []);
  const tripGoSuccessCount = useMemo(
    () => tripGoTransactions.filter((tx) => tx.status === 'BERHASIL').length,
    [tripGoTransactions]
  );

  // Live Macro Metrics
  const {
    totalVisitorsDisplay,
    personalVisitsCount,
    groupVisitsCount,
    activeTripGoCount,
    scheduledTripGoPax,
    avgGaodeScore,
    avgDwellHours,
    apiSlaLatency,
    apiCacheHitRate,
    totalWaLeadsDisplay,
    validPassportStamps,
    issuedCertCount,
  } = useMemo(() => {
    const allStemps: StempVisit[] = StempVisitsRepo.getAll();
    const filteredStemps = allStemps.filter((s) => {
      if (onlyValidGps && !s.is_gps_valid) return false;
      if (
        (selectedRegion !== 'all' || selectedCategory !== 'all') &&
        !matchingDestIdSet.has(s.destination_id)
      ) {
        return false;
      }
      if (!isDateInRange(s.checked_in_at, periodPreset, customStartDate, customEndDate)) {
        return false;
      }
      return true;
    });

    const allTrips: OpenTrip[] = OpenTripsRepo.getAll();
    const filteredTrips = allTrips.filter((t) => {
      if (!isDateInRange(t.departure_date, periodPreset, customStartDate, customEndDate)) {
        return false;
      }
      if (
        (selectedRegion !== 'all' || selectedCategory !== 'all') &&
        !matchingDestIdSet.has(t.destination_id)
      ) {
        return false;
      }
      return true;
    });

    const baseWeekly = filteredRegencies.reduce((acc, r) => acc + (r.visitor_count_week || 0), 0);
    let personal = Math.round(baseWeekly * 0.66) + filteredStemps.length;
    let group =
      Math.round(baseWeekly * 0.34) +
      filteredTrips.reduce((sum, t) => sum + (t.quota_filled || 4), 0);

    if (selectedSegment === 'personal') group = 0;
    if (selectedSegment === 'group') personal = 0;

    const totalVisitors = personal + group;

    const tripCount = selectedSegment === 'personal' ? 0 : filteredTrips.length;
    const tripPax =
      selectedSegment === 'personal'
        ? 0
        : filteredTrips.reduce(
          (sum, t) => sum + (t.quota_filled || 0) + (t.available_seats || 0),
          0
        );

    const allGaode: GaodeBehaviorRanking[] = GaodeRankingsRepo.getAll();
    const filteredGaode = allGaode.filter((g) => {
      if (
        (selectedRegion !== 'all' || selectedCategory !== 'all') &&
        !matchingDestIdSet.has(g.destination_id)
      ) {
        return false;
      }
      return true;
    });

    const avgScore =
      filteredGaode.length > 0
        ? (
          filteredGaode.reduce((acc, g) => acc + Number(g.calculated_gaode_score || 90), 0) /
          filteredGaode.length
        ).toFixed(1)
        : '-';

    const avgDwell =
      filteredGaode.length > 0
        ? (
          filteredGaode.reduce((acc, g) => acc + Number(g.avg_dwell_hours || 3.2), 0) /
          filteredGaode.length
        ).toFixed(1)
        : '0.0';

    const allTelemetry: ApiTelemetryLog[] = ApiTelemetryLogsRepo.getAll();
    const filteredTelemetry = allTelemetry.filter((t) =>
      isDateInRange(t.recorded_at, periodPreset, customStartDate, customEndDate)
    );
    const activeTelemetry = filteredTelemetry.length > 0 ? filteredTelemetry : allTelemetry;

    const avgLatency =
      activeTelemetry.length > 0
        ? Math.round(
          activeTelemetry.reduce((acc, t) => acc + Number(t.latency_ms), 0) /
          activeTelemetry.length
        )
        : 24;

    const cacheHit =
      activeTelemetry.length > 0
        ? Math.round(
          (activeTelemetry.filter((t) => t.cache_hit).length / activeTelemetry.length) * 100
        )
        : 95;

    const filteredPartners = partners.filter((p) => {
      const matchReg =
        selectedRegion === 'all' ||
        (p.city_regency || '').toLowerCase() === selectedRegion.toLowerCase();
      return matchReg;
    });
    const partnerWaSum = filteredPartners.reduce((acc, p) => acc + Number(p.wa_click_count || 0), 0);
    const heatmapWaSum = filteredRegencies.reduce((acc, r) => acc + (r.wa_leads_count || 0), 0);
    const totalWaLeads = Math.max(partnerWaSum, heatmapWaSum);

    const certs = UserChallengeRewardsRepo.getAll().filter(
      (c) => c.status === 'HADIAH_TERKIRIM'
    ).length;

    return {
      totalVisitorsDisplay: totalVisitors,
      personalVisitsCount: personal,
      groupVisitsCount: group,
      activeTripGoCount: tripCount,
      scheduledTripGoPax: tripPax,
      avgGaodeScore: avgScore,
      avgDwellHours: avgDwell,
      apiSlaLatency: avgLatency,
      apiCacheHitRate: cacheHit,
      totalWaLeadsDisplay: totalWaLeads,
      validPassportStamps: filteredStemps.length,
      issuedCertCount: certs,
    };
  }, [
    filteredRegencies,
    matchingDestIdSet,
    partners,
    selectedRegion,
    selectedCategory,
    selectedSegment,
    onlyValidGps,
    periodPreset,
    customStartDate,
    customEndDate,
  ]);

  // Dynamic 7-Day Prediction from Live Filtered Heatmap & Trips
  const reactivePredictionDays: PredictionDay[] = useMemo(() => {
    const baseDaily = Math.max(250, Math.round((totalVisitorsDisplay || 12000) / 7));
    const topDestNames = matchingDestinations.slice(0, 3).map((d) => d.name);
    const fallbackTop = topDestNames.length > 0 ? topDestNames : ['Lembah Harau', 'Jam Gadang'];
    const baseTripGroups = Math.max(1, activeTripGoCount);

    return Array.from({ length: 7 }).map((_, offset) => {
      const dt = new Date();
      dt.setDate(dt.getDate() + offset + 1);
      const dow = dt.getDay();
      const mult = DAY_WEIGHTS[dow] || 1;
      const dayEst = Math.round(baseDaily * mult);
      const personal = selectedSegment === 'group' ? 0 : Math.round(dayEst * 0.65);
      const group = selectedSegment === 'personal' ? 0 : Math.round(dayEst * 0.35);
      const total = personal + group;
      const groupsCount =
        selectedSegment === 'personal' ? 0 : Math.max(1, Math.round(baseTripGroups * mult * 2));

      const status: PredictionDay['status'] =
        mult >= 1.4
          ? 'Puncak (Peak)'
          : mult >= 1.2
            ? 'Padat'
            : mult >= 0.9
              ? 'Peningkatan'
              : 'Normal';

      return {
        date: dt.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }),
        dayName: DAY_NAMES_ID[dow],
        groupsCount,
        personalTouristsEst: personal,
        groupTouristsEst: group,
        touristsEst: total,
        status,
        topDestinations: fallbackTop,
      };
    });
  }, [totalVisitorsDisplay, matchingDestinations, activeTripGoCount, selectedSegment]);

  const activePredDay =
    reactivePredictionDays[selectedDayIndex] || reactivePredictionDays[0];

  // Live WA Leads per Destination aggregated from Partners + Destinations
  const liveDestinationWaLeads = useMemo(() => {
    const map = new Map<
      string,
      { destinationName: string; cityRegency: string; totalClicks: number; dominantCategory: string }
    >();

    partners.forEach((p) => {
      if (
        selectedRegion !== 'all' &&
        (p.city_regency || '').toLowerCase() !== selectedRegion.toLowerCase()
      ) {
        return;
      }
      const dest = destinations.find((d) => d.id === p.destination_id);
      if (selectedCategory !== 'all' && dest && !matchingDestIdSet.has(dest.id)) {
        return;
      }
      const key = p.destination_name || dest?.name || p.nagari_name;
      const prev = map.get(key);
      const clicks = Number(p.wa_click_count || 0);
      if (prev) {
        prev.totalClicks += clicks;
      } else {
        map.set(key, {
          destinationName: key,
          cityRegency: p.city_regency || 'Sumatera Barat',
          totalClicks: clicks,
          dominantCategory: p.category,
        });
      }
    });

    const sorted = Array.from(map.values()).sort((a, b) => b.totalClicks - a.totalClicks);
    const maxClicks = sorted[0]?.totalClicks || 1;
    return sorted.map((item) => ({
      ...item,
      percentage: Math.max(8, Math.round((item.totalClicks / maxClicks) * 100)),
    }));
  }, [partners, destinations, selectedRegion, selectedCategory, matchingDestIdSet]);

  // Live Distribution across 5 Canonical Partner Categories
  const partnerCategoryDistribution = useMemo(() => {
    const filtered = partners.filter(
      (p) =>
        selectedRegion === 'all' ||
        (p.city_regency || '').toLowerCase() === selectedRegion.toLowerCase()
    );
    const totalClicks = filtered.reduce((acc, p) => acc + Number(p.wa_click_count || 0), 0) || 1;
    return PARTNER_CATEGORIES.map((cat) => {
      const catPartners = filtered.filter((p) => p.category === cat);
      const clicks = catPartners.reduce((acc, p) => acc + Number(p.wa_click_count || 0), 0);
      return {
        category: cat,
        count: catPartners.length,
        clicks,
        pct: Math.round((clicks / totalClicks) * 100),
      };
    });
  }, [partners, selectedRegion]);

  // Live Top 5 Gaode Rankings from GaodeRankingsRepo
  const liveTop5Gaode = useMemo(() => {
    const allGaode = GaodeRankingsRepo.getAll();
    const filtered = allGaode.filter((g) => {
      const matchReg =
        selectedRegion === 'all' ||
        g.city_regency.toLowerCase() === selectedRegion.toLowerCase();
      const matchCat =
        selectedCategory === 'all' ||
        g.category_id === selectedCategory ||
        g.category === selectedCategory ||
        Boolean(selectedCategoryObj && g.category === selectedCategoryObj.name);
      return matchReg && matchCat;
    });
    return [...filtered]
      .sort((a, b) => b.calculated_gaode_score - a.calculated_gaode_score)
      .slice(0, 5);
  }, [selectedRegion, selectedCategory, selectedCategoryObj]);

  // Live Incident Composition, Resolution Rate, & Action Log from Pungli + Hazard + SOS Repos
  const {
    reactiveIncidentCategories,
    totalIncidentsCount,
    resolvedIncidentsCount,
    resolutionRatePct,
    liveIncidentActionLog,
  } = useMemo(() => {
    const allPungli: PungliReport[] = PungliReportsRepo.getAll();
    const allHazards: HazardAlert[] = HazardAlertsRepo.getAll();
    const allSos: SosSignal[] = SosSignalsRepo.getAll();

    const filteredPungli = allPungli.filter((p) => {
      if (
        (selectedRegion !== 'all' || selectedCategory !== 'all') &&
        !matchingDestIdSet.has(p.destination_id) &&
        (selectedRegion === 'all' ||
          (p.kab_kota || '').toLowerCase() !== selectedRegion.toLowerCase())
      ) {
        return false;
      }
      return isDateInRange(p.created_at, periodPreset, customStartDate, customEndDate);
    });

    const filteredHazards = allHazards.filter((h) => {
      if (
        selectedRegion !== 'all' &&
        h.city_regency.toLowerCase() !== selectedRegion.toLowerCase()
      ) {
        return false;
      }
      return h.severity === 'Siaga' || h.severity === 'Awas Tutup Total';
    });

    const filteredSos = allSos.filter((s) => {
      if (
        selectedRegion !== 'all' &&
        (s.city_regency || '').toLowerCase() !== selectedRegion.toLowerCase()
      ) {
        return false;
      }
      return isDateInRange(s.created_at, periodPreset, customStartDate, customEndDate);
    });

    const pungliOnly = filteredPungli.filter((p) => p.report_type !== 'fasilitas');
    const fasilitasOnly = filteredPungli.filter((p) => p.report_type === 'fasilitas');

    const total =
      pungliOnly.length + fasilitasOnly.length + filteredHazards.length + filteredSos.length;
    const resolved =
      filteredPungli.filter((p) => p.status === 'Selesai').length +
      filteredSos.filter((s) => s.status === 'Evakuasi Selesai').length;
    const rate = total > 0 ? Math.round((resolved / total) * 100) : 100;

    const calcPct = (cnt: number) => (total > 0 ? Number(((cnt / total) * 100).toFixed(1)) : 0);

    const categories: IncidentCategoryItem[] = [
      {
        name: 'Aduan Pungli & Tarif Perda',
        count: pungliOnly.length,
        percentage: calcPct(pungliOnly.length),
        color: '#F26B4B',
        badgeBg: 'bg-[#F26B4B]/15',
        badgeText: 'text-[#D95637]',
      },
      {
        name: 'Fasilitas Wisata Rusak',
        count: fasilitasOnly.length,
        percentage: calcPct(fasilitasOnly.length),
        color: '#3B82F6',
        badgeBg: 'bg-[#3B82F6]/15',
        badgeText: 'text-[#1D4ED8]',
      },
      {
        name: 'Jalur Ekstrem Siaga / Awas',
        count: filteredHazards.length,
        percentage: calcPct(filteredHazards.length),
        color: '#F59E0B',
        badgeBg: 'bg-[#F59E0B]/15',
        badgeText: 'text-[#B45309]',
      },
      {
        name: 'Log Sinkronisasi SOS SAR',
        count: filteredSos.length,
        percentage: calcPct(filteredSos.length),
        color: '#EF4444',
        badgeBg: 'bg-[#EF4444]/15',
        badgeText: 'text-[#B91C1C]',
      },
    ];

    const actionRows: UnifiedIncidentActionRow[] = [
      ...filteredPungli.map((r) => ({
        id: r.id,
        time: new Date(r.updated_at || r.created_at).toLocaleString('id-ID', {
          day: '2-digit',
          month: 'short',
          hour: '2-digit',
          minute: '2-digit',
        }),
        destination: `${r.destination_name} (${r.kab_kota})`,
        incidentType: `${r.incident_category} (${r.ticket_code})`,
        officer: 'Satgas Saber Pungli Sumbar',
        actionTaken:
          r.admin_action_notes ||
          `Pelaporan dari ${r.reporter_name} — selisih Rp ${r.overcharge_amount_idr.toLocaleString('id-ID')}.`,
        status: r.status,
      })),
      ...filteredHazards.map((h) => ({
        id: h.id,
        time: new Date(h.updated_at).toLocaleString('id-ID', {
          day: '2-digit',
          month: 'short',
          hour: '2-digit',
          minute: '2-digit',
        }),
        destination: `${h.location} (${h.city_regency})`,
        incidentType: `Jalur Ekstrem: ${h.hazard_type}`,
        officer: h.nearest_rescue_post,
        actionTaken: h.message,
        status: h.severity,
      })),
      ...filteredSos.map((s) => ({
        id: s.id,
        time: new Date(s.created_at).toLocaleString('id-ID', {
          day: '2-digit',
          month: 'short',
          hour: '2-digit',
          minute: '2-digit',
        }),
        destination: s.destination_name || s.nearest_corridor,
        incidentType: `SOS: ${s.emergency_type} (${s.sos_code})`,
        officer: s.sar_unit_assigned || s.nearest_rescue_post,
        actionTaken: s.notes,
        status: s.status,
      })),
    ];

    return {
      reactiveIncidentCategories: categories,
      totalIncidentsCount: total,
      resolvedIncidentsCount: resolved,
      resolutionRatePct: rate,
      liveIncidentActionLog: actionRows.slice(0, 8),
    };
  }, [matchingDestIdSet, selectedRegion, selectedCategory, periodPreset, customStartDate, customEndDate]);

  // CSV Export
  const handleExportCSV = () => {
    const safeRegion =
      selectedRegion === 'all'
        ? 'semua-wilayah'
        : selectedRegion.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const safePeriod =
      periodPreset === 'custom'
        ? `${customStartDate || 'start'}_sd_${customEndDate || 'end'}`
        : periodPreset;
    const fileName = `laporan-wisgo_${safeRegion}_${safePeriod}_${selectedSegment}_${new Date().toISOString().slice(0, 10)}.csv`;
    const catName = selectedCategoryObj
      ? selectedCategoryObj.name
      : selectedCategory === 'all'
        ? 'Semua 5 Kategori Master'
        : selectedCategory;

    const metaHeader = [
      `# LAPORAN EKSEKUTIF DINAS PARIWISATA PROVINSI SUMATERA BARAT (WISGO)`,
      `# Tanggal Ekspor: ${new Date().toLocaleString('id-ID')}`,
      `# Filter: Wilayah="${selectedRegion}", Kategori="${catName}", Periode="${periodPreset}", Segmen="${selectedSegment}", GPS_Valid="${onlyValidGps}"`,
      `# Total Kunjungan: ${totalVisitorsDisplay.toLocaleString('id-ID')} (Personal: ${personalVisitsCount.toLocaleString('id-ID')} | Trip Go: ${groupVisitsCount.toLocaleString('id-ID')})`,
      `# Total Escrow Trip Go: Rp ${tripGoTotalRevenue.toLocaleString('id-ID')}`,
      `# Total Leads WA P2P Mitra UMKM: ${totalWaLeadsDisplay.toLocaleString('id-ID')} Klik`,
    ];

    const headers = [
      'Kode Wilayah',
      'Kabupaten/Kota',
      'Status Kepadatan',
      'Total Kunjungan',
      'Personal',
      'Trip Go / Rombongan',
      'Domestik (%)',
      'Wisman MYR (%)',
      'Destinasi Terpopuler',
      'Leads WA P2P',
    ];

    const rows = filteredRegencies.map((r) => {
      const personal = selectedSegment === 'group' ? 0 : Math.round(r.visitor_count_week * 0.66);
      const group = selectedSegment === 'personal' ? 0 : Math.round(r.visitor_count_week * 0.34);
      return [
        r.code,
        `"${r.name}"`,
        r.crowd_status,
        personal + group,
        personal,
        group,
        `${r.domestic_pct}%`,
        `${r.foreign_myr_pct}%`,
        `"${r.top_destination}"`,
        r.wa_leads_count || 0,
      ];
    });

    const csvContent =
      'data:text/csv;charset=utf-8,' +
      [...metaHeader, headers.join(','), ...rows.map((e) => e.join(','))].join('\n');

    const link = document.createElement('a');
    link.setAttribute('href', encodeURI(csvContent));
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
      {/* 0. DOKUMEN CETAK RESMI (Print Only) */}
      <div id="executive-report-print" className="hidden print:block text-black bg-white">
        <div className="border-b-4 border-double border-black pb-4 text-center mb-6">
          <h2 className="text-lg font-bold tracking-wider uppercase">
            PEMERINTAH PROVINSI SUMATERA BARAT
          </h2>
          <h1 className="text-2xl font-black uppercase tracking-tight">DINAS PARIWISATA</h1>
          <p className="text-xs mt-0.5">
            Jl. Khatib Sulaiman No. 22, Padang, Sumatera Barat · Telp. (0751) 7055183 · Email: dispar@sumbarprov.go.id
          </p>
          <p className="text-[11px] font-semibold text-gray-700">
            PORTAL EKOSISTEM WISATA PINTAR SUMATERA BARAT (WISGO)
          </p>
        </div>

        <div className="flex justify-between items-baseline text-xs mb-3 pb-2 border-b border-gray-400">
          <div>
            <div>
              <strong>Nomor:</strong> 556/412/DISPAR-SUMBAR/XI/2026
            </div>
            <div>
              <strong>Perihal:</strong> Laporan Eksekutif Kunjungan, Mitra UMKM, Trip Go &amp; Kepatuhan Lapangan
            </div>
          </div>
          <div className="text-right">
            <div>
              <strong>Periode:</strong>{' '}
              {reportPeriod === 'month'
                ? 'Bulan Ini'
                : reportPeriod === 'quarter'
                  ? 'Kuartal Berjalan'
                  : 'Tahun Anggaran Berjalan'}
            </div>
            <div>
              <strong>Tanggal Terbit:</strong> {todayFormatted}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-5 gap-2 mb-6 p-3 bg-gray-50 border border-gray-300 rounded text-center text-xs">
          <div>
            <span className="text-[10px] text-gray-600 block">Total Kunjungan</span>
            <strong className="text-sm text-black">
              {totalVisitorsDisplay.toLocaleString('id-ID')}
            </strong>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Agenda Trip Go</span>
            <strong className="text-sm text-black">{activeTripGoCount} Trip Go</strong>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Omset Escrow Trip Go</span>
            <strong className="text-sm text-black font-mono">
              Rp {tripGoTotalRevenue.toLocaleString('id-ID')}
            </strong>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Leads WA UMKM</span>
            <strong className="text-sm text-black">
              {totalWaLeadsDisplay.toLocaleString('id-ID')} Klik
            </strong>
          </div>
          <div>
            <span className="text-[10px] text-gray-600 block">Penyelesaian Insiden</span>
            <strong className="text-sm text-black">{resolutionRatePct}%</strong>
          </div>
        </div>

        <div className="mb-6">
          <h3 className="text-xs font-bold uppercase mb-2">
            1. Peringkat Kualitas Destinasi (Top 5 Gaode Ranking Live)
          </h3>
          <table className="w-full text-xs border border-gray-300 border-collapse">
            <thead>
              <tr className="bg-gray-100 text-left">
                <th className="border p-1.5 text-center">Rank</th>
                <th className="border p-1.5">Destinasi</th>
                <th className="border p-1.5">Wilayah</th>
                <th className="border p-1.5 text-center">Skor Gaode</th>
                <th className="border p-1.5 text-center">Bebas Pungli</th>
                <th className="border p-1.5 text-center">Durasi Singgah</th>
              </tr>
            </thead>
            <tbody>
              {liveTop5Gaode.map((d, idx) => (
                <tr key={d.id}>
                  <td className="border p-1.5 text-center font-bold">#{idx + 1}</td>
                  <td className="border p-1.5 font-semibold">{d.name}</td>
                  <td className="border p-1.5">{d.city_regency}</td>
                  <td className="border p-1.5 text-center font-bold">{d.calculated_gaode_score}</td>
                  <td className="border p-1.5 text-center">{d.pungli_free_index}%</td>
                  <td className="border p-1.5 text-center">{d.avg_dwell_hours} Jam</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="pt-4 flex justify-between items-end text-xs">
          <p className="text-[10px] text-gray-500 italic">
            Dokumen ini diterbitkan secara otomatis dari data live Sistem WISGO Sumbar.
          </p>
          <div className="text-center w-64">
            <p>Padang, {todayFormatted}</p>
            <p className="font-bold">Kepala Dinas Pariwisata Provinsi Sumatera Barat</p>
            <div className="h-20 flex items-center justify-center">
              <div className="w-20 h-20 rounded-full border-2 border-red-700/60 text-red-700/70 flex items-center justify-center text-[9px] font-bold uppercase text-center rotate-[-12deg]">
                DINAS PARIWISATA
                <br />
                PROV. SUMBAR
                <br />★ WISGO ★
              </div>
            </div>
            <p className="font-extrabold underline text-sm">Drs. H. Luhur Budianda, S.Y., M.Si</p>
            <p className="text-[11px] text-gray-700">NIP. 19700812 199602 1 002</p>
          </div>
        </div>
      </div>

      {/* 1. HEADER UTAMA */}
      <header className="no-print flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">Analitik Eksekutif</h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Data live kunjungan, konversi WA P2P UMKM, Escrow Trip Go, Top Gaode &amp; kepatuhan 19 Kab/Kota Sumbar.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          <button
            type="button"
            onClick={handleExportCSV}
            className="min-h-[40px] px-3.5 py-2 rounded-xl bg-white hover:bg-[#F6F3EC] text-[#234B24] text-xs font-bold flex items-center gap-2 border border-[#234B24]/15 transition shadow-sm"
          >
            <Download className="w-3.5 h-3.5 text-[#234B24]" aria-hidden="true" />
            <span>Export CSV</span>
          </button>
          <button
            type="button"
            onClick={handlePrintOfficialReport}
            className="min-h-[40px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm transition duration-200"
          >
            <Printer className="w-3.5 h-3.5 text-[#A7F3D0]" aria-hidden="true" />
            <span>Cetak PDF</span>
          </button>
        </div>
      </header>

      {/* 1.5. BARIS KONTROL FILTER REAKTIF (+ CUSTOM DATE PICKER) */}
      <section
        aria-label="Panel Filter Laporan Eksekutif"
        className="bg-white rounded-xl p-3 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.03)] no-print flex flex-wrap items-center gap-2.5"
      >
        <select
          value={periodPreset}
          onChange={(e) => setPeriodPreset(e.target.value as PeriodPreset)}
          className="h-9 px-2.5 py-1 rounded-lg bg-[#F6F3EC] border border-[#234B24]/10 text-xs font-bold text-[#1B1F1A]"
        >
          <option value="all">Semua Periode</option>
          <option value="today">Hari Ini</option>
          <option value="7d">7 Hari Terakhir</option>
          <option value="30d">30 Hari Terakhir</option>
          <option value="this_month">Bulan Ini</option>
          <option value="this_year">Tahun Ini</option>
          <option value="custom">Pilih Rentang Tanggal</option>
        </select>

        {periodPreset === 'custom' && (
          <div className="flex items-center gap-1.5">
            <input
              type="date"
              aria-label="Tanggal Mulai"
              value={customStartDate}
              onChange={(e) => setCustomStartDate(e.target.value)}
              className="h-9 px-2 rounded-lg bg-[#F6F3EC] border border-[#234B24]/15 text-xs font-mono font-bold text-[#1B1F1A]"
            />
            <span className="text-[11px] font-bold text-[#767676]">s/d</span>
            <input
              type="date"
              aria-label="Tanggal Selesai"
              value={customEndDate}
              onChange={(e) => setCustomEndDate(e.target.value)}
              className="h-9 px-2 rounded-lg bg-[#F6F3EC] border border-[#234B24]/15 text-xs font-mono font-bold text-[#1B1F1A]"
            />
          </div>
        )}

        <select
          value={selectedRegion}
          onChange={(e) => setSelectedRegion(e.target.value)}
          className="h-9 px-2.5 py-1 rounded-lg bg-[#F6F3EC] border border-[#234B24]/10 text-xs font-bold text-[#1B1F1A]"
        >
          <option value="all">Semua Wilayah (19 Kab/Kota)</option>
          {SUMBAR_19_REGIONS.map((region) => (
            <option key={region} value={region}>
              {region}
            </option>
          ))}
        </select>

        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="h-9 px-2.5 py-1 rounded-lg bg-[#F6F3EC] border border-[#234B24]/10 text-xs font-bold text-[#1B1F1A]"
        >
          <option value="all">Semua 5 Kategori Master</option>
          {destinationCategories.map((cat) => (
            <option key={cat.id} value={cat.id}>
              {cat.name}
            </option>
          ))}
        </select>

        <div className="flex items-center gap-1 bg-[#F6F3EC] p-0.5 rounded-lg border border-[#234B24]/10">
          {(['all', 'personal', 'group'] as const).map((seg) => (
            <button
              key={seg}
              type="button"
              onClick={() => setSelectedSegment(seg)}
              className={`px-2.5 py-1 text-[11px] font-bold rounded-md transition ${selectedSegment === seg
                  ? seg === 'group'
                    ? 'bg-[#F26B4B] text-white shadow-sm'
                    : 'bg-[#234B24] text-white shadow-sm'
                  : 'text-[#4A5248] hover:text-[#1B1F1A]'
                }`}
            >
              {seg === 'all' ? 'Semua' : seg === 'personal' ? 'Personal' : 'Trip Go'}
            </button>
          ))}
        </div>

        <label className="flex items-center gap-1.5 cursor-pointer select-none text-xs font-semibold text-[#1B1F1A] ml-1">
          <input
            type="checkbox"
            checked={onlyValidGps}
            onChange={(e) => setOnlyValidGps(e.target.checked)}
            className="w-3.5 h-3.5 rounded accent-[#234B24] cursor-pointer"
          />
          <span>GPS Terverifikasi</span>
        </label>

        {isFilterActive && (
          <button
            type="button"
            onClick={handleResetFilter}
            className="h-9 px-2.5 rounded-lg bg-[#F26B4B]/10 hover:bg-[#F26B4B]/20 text-[#D95637] text-xs font-bold flex items-center gap-1 transition ml-auto"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Reset</span>
          </button>
        )}
      </section>

      {/* 2. 4 KARTU METRIK MAKRO LIVE */}
      <section className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 no-print">
        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Total Wisatawan Terlacak</span>
            <Users className="w-4 h-4 text-[#234B24]/70" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#234B24]">
            {totalVisitorsDisplay.toLocaleString('id-ID')}
          </div>
          <p className="text-xs text-slate-500">
            {personalVisitsCount.toLocaleString('id-ID')} Personal ·{' '}
            {groupVisitsCount.toLocaleString('id-ID')} Trip Go
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Trip Go &amp; Escrow Aktif</span>
            <Calendar className="w-4 h-4 text-[#F26B4B]" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#F26B4B]">
            {activeTripGoCount} Trip Go
          </div>
          <p className="text-xs text-slate-500">
            {scheduledTripGoPax} Kuota · Rp {tripGoTotalRevenue.toLocaleString('id-ID')} Escrow
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Skor Keaslian Gaode</span>
            <Sparkles className="w-4 h-4 text-[#234B24]/70" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#234B24]">
            {avgGaodeScore}
          </div>
          <p className="text-xs text-slate-500">
            Dwell time {avgDwellHours} jam · {validPassportStamps} Stempel GPS
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Telemetri SLA &amp; Paspor</span>
            <Activity className="w-4 h-4 text-[#1E9E5A]" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#1E9E5A]">
            {apiSlaLatency} ms
          </div>
          <p className="text-xs text-slate-500">
            Cache hit {apiCacheHitRate}% · {issuedCertCount} E-Sertifikat
          </p>
        </div>
      </section>

      {/* 3. SUB-TAB NAVIGASI */}
      <nav
        aria-label="Tab Analitik Eksekutif"
        className="flex overflow-x-auto no-scrollbar whitespace-nowrap shrink-0 gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-sm no-print"
      >
        <button
          type="button"
          onClick={() => setActiveTab('heatmap_prediction')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeTab === 'heatmap_prediction'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
            }`}
        >
          <Compass className="w-3.5 h-3.5" />
          <span>Heatmap &amp; Prediksi</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('partner_performance')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeTab === 'partner_performance'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
            }`}
        >
          <Store className="w-3.5 h-3.5" />
          <span>UMKM, Trip Go &amp; Gaode</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('incident_recap')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeTab === 'incident_recap'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
            }`}
        >
          <AlertTriangle className="w-3.5 h-3.5 text-[#F26B4B]" />
          <span>Insiden &amp; SOS ({totalIncidentsCount})</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('export_report')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeTab === 'export_report'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
            }`}
        >
          <FileText className="w-3.5 h-3.5" />
          <span>Laporan</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('system_benchmark')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ml-auto ${activeTab === 'system_benchmark'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
            }`}
        >
          <Activity className="w-3.5 h-3.5 text-[#1E9E5A]" />
          <span>Benchmark SLA</span>
        </button>
      </nav>

      {/* TAB 1: HEATMAP & PREDIKSI 7 HARI DINAMIS */}
      {activeTab === 'heatmap_prediction' && (
        <div className="space-y-6 no-print">
          <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-[#234B24]/10 pb-4">
              <div className="flex items-center gap-2">
                <Flame className="w-4 h-4 text-[#F26B4B]" />
                <h3 className="text-sm font-bold text-[#1B1F1A]">
                  Prediksi Kunjungan 7 Hari ke Depan (Berbasis Data Live)
                </h3>
              </div>

              <div className="flex flex-wrap items-center gap-2">
                <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#234B24]/10 text-[#234B24] text-[11px] font-bold">
                  <span className="w-2 h-2 rounded-full bg-[#234B24]" />
                  <span>Personal</span>
                </div>
                <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#F26B4B]/15 text-[#C2410C] text-[11px] font-bold">
                  <span className="w-2 h-2 rounded-full bg-[#F26B4B]" />
                  <span>Trip Go</span>
                </div>
                <span className="px-2.5 py-1 rounded-lg bg-[#234B24] text-white text-[11px] font-bold">
                  {activePredDay.dayName}, {activePredDay.date}
                </span>
              </div>
            </div>

            <div className="w-full overflow-x-auto">
              <div className="min-w-[680px]">
                {(() => {
                  const maxVal = Math.max(
                    1000,
                    ...reactivePredictionDays.map((p) =>
                      Math.max(p.personalTouristsEst, p.groupTouristsEst)
                    )
                  );
                  const chartPoints = reactivePredictionDays.map((p, idx) => {
                    const cx = 80 + idx * 105;
                    const cyPersonal = 180 - Math.min(148, Math.round((p.personalTouristsEst / maxVal) * 145));
                    const cyGroup = 180 - Math.min(148, Math.round((p.groupTouristsEst / maxVal) * 145));
                    return { cx, cyPersonal, cyGroup, day: p, idx };
                  });
                  const polyPersonal = chartPoints.map((pt) => `${pt.cx},${pt.cyPersonal}`).join(' ');
                  const polyGroup = chartPoints.map((pt) => `${pt.cx},${pt.cyGroup}`).join(' ');
                  const areaPersonal = `80,180 ${polyPersonal} 710,180`;
                  const areaGroup = `80,180 ${polyGroup} 710,180`;

                  return (
                    <svg viewBox="0 0 760 220" className="w-full h-56 select-none">
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

                      <line x1="50" y1="35" x2="730" y2="35" stroke="#CFD8BE" strokeDasharray="3 3" />
                      <text x="44" y="39" textAnchor="end" className="text-[9.5px] fill-[#767676] font-mono">
                        {maxVal.toLocaleString('id-ID')}
                      </text>
                      <line x1="50" y1="108" x2="730" y2="108" stroke="#CFD8BE" strokeDasharray="3 3" />
                      <text x="44" y="112" textAnchor="end" className="text-[9.5px] fill-[#767676] font-mono">
                        {Math.round(maxVal / 2).toLocaleString('id-ID')}
                      </text>
                      <line x1="50" y1="180" x2="730" y2="180" stroke="#CFD8BE" />
                      <text x="44" y="184" textAnchor="end" className="text-[9.5px] fill-[#767676] font-mono">
                        0
                      </text>

                      <polygon points={areaPersonal} fill="url(#surgeAreaGradient)" />
                      <polyline
                        points={polyPersonal}
                        fill="none"
                        stroke="#234B24"
                        strokeWidth="3"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />

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

                      {chartPoints.map((pt) => {
                        const isSelected = pt.idx === selectedDayIndex;
                        return (
                          <g
                            key={pt.idx}
                            className="cursor-pointer"
                            onClick={() => setSelectedDayIndex(pt.idx)}
                          >
                            {isSelected && (
                              <circle
                                cx={pt.cx}
                                cy={pt.cyPersonal}
                                r="13"
                                fill="#F26B4B"
                                opacity="0.25"
                              />
                            )}
                            <circle
                              cx={pt.cx}
                              cy={pt.cyPersonal}
                              r={isSelected ? '6' : '4.5'}
                              fill="#234B24"
                              stroke="#FFFFFF"
                              strokeWidth="2"
                            />
                            <circle
                              cx={pt.cx}
                              cy={pt.cyGroup}
                              r={isSelected ? '6' : '4.5'}
                              fill="#F26B4B"
                              stroke="#FFFFFF"
                              strokeWidth="2"
                            />
                            <text
                              x={pt.cx}
                              y={pt.cyPersonal - 10}
                              textAnchor="middle"
                              className="text-[9.5px] font-extrabold fill-[#234B24]"
                            >
                              {pt.day.personalTouristsEst.toLocaleString('id-ID')}
                            </text>
                            <text
                              x={pt.cx}
                              y={pt.cyGroup + 14}
                              textAnchor="middle"
                              className="text-[9px] font-extrabold fill-[#C2410C]"
                            >
                              {pt.day.groupTouristsEst.toLocaleString('id-ID')}
                            </text>
                            <text
                              x={pt.cx}
                              y="198"
                              textAnchor="middle"
                              className={`text-[11px] font-bold ${isSelected ? 'fill-[#234B24]' : 'fill-[#4A5248]'
                                }`}
                            >
                              {pt.day.dayName}
                            </text>
                            <text
                              x={pt.cx}
                              y="212"
                              textAnchor="middle"
                              className="text-[9px] fill-[#767676] font-mono"
                            >
                              {pt.day.date.slice(0, 6)}
                            </text>
                          </g>
                        );
                      })}
                    </svg>
                  );
                })()}
              </div>
            </div>

            <div className="bg-[#F6F3EC] p-5 rounded-2xl border border-[#CFD8BE] flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shrink-0 mt-0.5">
                  <AlertTriangle className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="text-xs font-extrabold uppercase tracking-wide text-[#D95637]">
                    Proyeksi Beban Kawasan: {activePredDay.dayName}, {activePredDay.date} (
                    {activePredDay.status})
                  </h4>
                  <p className="text-xs text-[#1B1F1A] mt-0.5">
                    Estimasi:{' '}
                    <strong>{activePredDay.touristsEst.toLocaleString('id-ID')} Wisatawan</strong> (
                    <span className="text-[#234B24] font-bold">
                      {activePredDay.personalTouristsEst.toLocaleString('id-ID')} Personal
                    </span>{' '}
                    &amp;{' '}
                    <span className="text-[#F26B4B] font-bold">
                      {activePredDay.groupTouristsEst.toLocaleString('id-ID')} Trip Go
                    </span>
                    ) ke kawasan{' '}
                    <span className="font-bold text-[#234B24]">
                      {activePredDay.topDestinations.join(', ')}
                    </span>
                    .
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Grid 19 Kabupaten/Kota */}
          <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <MapPin className="w-5 h-5 text-[#234B24]" />
                  <span>Sebaran Kepadatan 19 Kabupaten/Kota Sumatera Barat</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Terintegrasi dengan kode wilayah unik (PPJ Padang Panjang &amp; PDP Padang Pariaman) serta klik leads WA UMKM live.
                </p>
              </div>

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
                  <option value="Sepi">Sepi</option>
                  <option value="Sedang">Sedang</option>
                  <option value="high">Ramai / Overload</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {filteredRegencies.length === 0 ? (
                <div className="col-span-full p-8 text-center bg-[#F6F3EC] rounded-2xl border border-dashed border-[#CFD8BE] text-xs text-[#767676]">
                  Tidak ada data wilayah yang cocok dengan filter aktif.
                </div>
              ) : (
                filteredRegencies.map((reg) => {
                  const badgeBg =
                    reg.crowd_status === 'Overload'
                      ? 'bg-red-100 text-red-800 border-red-200'
                      : reg.crowd_status === 'Ramai'
                        ? 'bg-[#F26B4B]/15 text-[#D95637] border-[#F26B4B]/30'
                        : reg.crowd_status === 'Sedang'
                          ? 'bg-[#F59E0B]/15 text-[#B45309] border-[#F59E0B]/30'
                          : 'bg-[#1E9E5A]/15 text-[#166534] border-[#1E9E5A]/30';

                  const personal =
                    selectedSegment === 'group' ? 0 : Math.round(reg.visitor_count_week * 0.66);
                  const group =
                    selectedSegment === 'personal' ? 0 : Math.round(reg.visitor_count_week * 0.34);

                  return (
                    <div
                      key={reg.id}
                      className="bg-[#F6F3EC]/70 hover:bg-[#F6F3EC] p-4 rounded-2xl border border-[#CFD8BE] transition flex flex-col justify-between"
                    >
                      <div>
                        <div className="flex items-start justify-between gap-2">
                          <span className="text-xs font-mono font-bold text-[#767676]">
                            {reg.code}
                          </span>
                          <span
                            className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${badgeBg}`}
                          >
                            {reg.crowd_status}
                          </span>
                        </div>

                        <h4 className="text-sm font-extrabold text-[#1B1F1A] mt-1.5">{reg.name}</h4>

                        <div className="mt-3 space-y-1.5 text-xs text-[#4A5248]">
                          <div className="flex justify-between">
                            <span>Kunjungan Mingguan:</span>
                            <strong className="text-[#234B24]">
                              {(personal + group).toLocaleString('id-ID')}
                            </strong>
                          </div>
                          <div className="flex justify-between pt-1 border-t border-black/5">
                            <span>Destinasi Utama:</span>
                            <span className="font-semibold text-[#1B1F1A] truncate max-w-[130px]">
                              {reg.top_destination}
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span>Leads WA P2P:</span>
                            <span className="font-bold text-[#1E9E5A]">
                              {(reg.wa_leads_count || 0).toLocaleString('id-ID')} Klik
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="mt-4 pt-3 border-t border-[#CFD8BE]/60 text-[10px] text-[#4A5248] flex items-center justify-between">
                        <span>{reg.domestic_pct}% Domestik</span>
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

      {/* TAB 2: UMKM, TRIP GO ESCROW & TOP 5 GAODE (100% LIVE) */}
      {activeTab === 'partner_performance' && (
        <div className="space-y-6 no-print">
          {/* Rekap Transaksi Escrow Trip Go */}
          <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-5">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
              <div>
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-[#234B24] text-white">
                    REKENING ESCROW WISGO
                  </span>
                  <span className="text-xs font-bold text-[#F26B4B]">KHUSUS TRIP GO</span>
                </div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] mt-1 flex items-center gap-2">
                  <CreditCard className="w-5 h-5 text-[#234B24]" />
                  <span>Rekapitulasi Transaksi Escrow Trip Go</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Transaksi dalam aplikasi hanya berlaku untuk Trip Go. Mitra UMKM biasa 100% Direct P2P WhatsApp (0% komisi).
                </p>
              </div>

              <div className="p-3 rounded-2xl bg-[#234B24]/10 border border-[#234B24]/20 text-right">
                <span className="text-[10px] font-bold text-[#4A5248] block uppercase">
                  Total Omset Escrow Trip Go
                </span>
                <strong className="text-lg font-black text-[#234B24] font-mono">
                  Rp {tripGoTotalRevenue.toLocaleString('id-ID')}
                </strong>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
                <span className="text-[10px] font-extrabold uppercase text-[#767676] block">
                  Total Transaksi Trip Go
                </span>
                <span className="text-xl font-black text-[#1B1F1A] mt-1 block font-mono">
                  {tripGoTransactions.length} Transaksi
                </span>
              </div>
              <div className="p-4 rounded-2xl bg-[#DCFCE7] border border-[#86EFAC]">
                <span className="text-[10px] font-extrabold uppercase text-[#166534] block">
                  Pembayaran Lunas
                </span>
                <span className="text-xl font-black text-[#166534] mt-1 block font-mono">
                  {tripGoSuccessCount} Sukses
                </span>
              </div>
              <div className="p-4 rounded-2xl bg-[#FEF3C7] border border-[#FCD34D]">
                <span className="text-[10px] font-extrabold uppercase text-[#92400E] block">
                  Leads WA UMKM (0% Komisi)
                </span>
                <span className="text-xl font-black text-[#92400E] mt-1 block font-mono">
                  {totalWaLeadsDisplay.toLocaleString('id-ID')} Klik
                </span>
              </div>
            </div>

            <div className="overflow-x-auto rounded-2xl border border-[#CFD8BE]">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#234B24] text-[#F6F3EC] font-bold">
                  <tr>
                    <th className="py-2.5 px-3">Kode</th>
                    <th className="py-2.5 px-3">Agenda Trip Go</th>
                    <th className="py-2.5 px-3">Peserta</th>
                    <th className="py-2.5 px-3">Kursi</th>
                    <th className="py-2.5 px-3">Nominal</th>
                    <th className="py-2.5 px-3">Kanal</th>
                    <th className="py-2.5 px-3 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {tripGoTransactions.slice(0, 6).map((tx) => (
                    <tr key={tx.id} className="hover:bg-[#F6F3EC]/50">
                      <td className="py-2.5 px-3 font-mono font-bold text-[#234B24]">
                        {tx.transaction_code}
                      </td>
                      <td className="py-2.5 px-3 font-medium text-[#1B1F1A]">{tx.trip_title}</td>
                      <td className="py-2.5 px-3 font-medium text-[#1B1F1A]">
                        {tx.participant_name}
                      </td>
                      <td className="py-2.5 px-3 text-[#4A5248]">{tx.seats_booked} Kursi</td>
                      <td className="py-2.5 px-3 font-mono font-bold text-[#1B1F1A]">
                        Rp {tx.amount_idr.toLocaleString('id-ID')}
                      </td>
                      <td className="py-2.5 px-3 font-mono text-[10px] text-[#767676]">
                        {tx.payment_channel}
                      </td>
                      <td className="py-2.5 px-3 text-right">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-black ${tx.status === 'BERHASIL'
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

          {/* Bar Chart Leads WA P2P Mitra UMKM Live */}
          <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <BarChart3 className="w-5 h-5 text-[#234B24]" />
                  <span>Konversi Klik WA P2P Mitra UMKM per Destinasi (Live)</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Dihitung otomatis dari data direktori mitra aktif dan uji pesan WA P2P.
                </p>
              </div>
              <div className="px-3.5 py-1.5 rounded-xl bg-[#1E9E5A]/15 text-[#166534] text-xs font-bold shrink-0">
                {partners.length} Mitra Terverifikasi
              </div>
            </div>

            <div className="space-y-4">
              {liveDestinationWaLeads.length === 0 ? (
                <div className="p-8 text-center bg-[#F6F3EC] rounded-2xl border border-dashed border-[#CFD8BE] text-xs text-[#767676]">
                  Tidak ada data leads mitra UMKM untuk filter aktif.
                </div>
              ) : (
                liveDestinationWaLeads.map((item, idx) => (
                  <div key={item.destinationName} className="space-y-1.5">
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
                      <span className="text-sm font-extrabold text-[#234B24]">
                        {item.totalClicks.toLocaleString('id-ID')} Klik WA
                      </span>
                    </div>
                    <div className="w-full h-3 rounded-full bg-[#F6F3EC] overflow-hidden border border-[#CFD8BE]">
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-[#234B24] to-[#1E9E5A]"
                        style={{ width: `${item.percentage}%` }}
                      />
                    </div>
                  </div>
                ))
              )}
            </div>

            {/* 5 Kategori Kanonik Mitra UMKM */}
            <div className="pt-4 border-t border-[#234B24]/10 grid grid-cols-2 sm:grid-cols-5 gap-3 text-center text-xs">
              {partnerCategoryDistribution.map((cat) => (
                <div
                  key={cat.category}
                  className="p-3 bg-[#F6F3EC] rounded-2xl border border-[#CFD8BE]"
                >
                  <span className="text-[10px] font-bold uppercase text-[#4A5248] block">
                    {cat.category}
                  </span>
                  <span className="text-base font-extrabold text-[#234B24]">{cat.pct}%</span>
                  <span className="text-[10px] text-[#767676] block">
                    {cat.clicks.toLocaleString('id-ID')} Klik ({cat.count} Mitra)
                  </span>
                </div>
              ))}
            </div>
          </section>

          {/* Top 5 Gaode Ranking Live */}
          <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Star className="w-5 h-5 text-[#F59E0B] fill-[#F59E0B]" />
                  <span>Top 5 Gaode Ranking Live — Destinasi Berperforma Tertinggi</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Disinkronkan langsung dari bobot GaodeRankingsRepo (Kepuasan, Bebas Pungli, 4 Indikator Medan, Volume Kunjungan).
                </p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-[#234B24]/10 text-[#4A5248] font-bold">
                    <th className="py-3 px-3">Rank</th>
                    <th className="py-3 px-3">Destinasi &amp; Wilayah</th>
                    <th className="py-3 px-3 text-center">Skor Gaode</th>
                    <th className="py-3 px-3 text-center">Bebas Pungli</th>
                    <th className="py-3 px-3 text-center">Durasi Singgah</th>
                    <th className="py-3 px-3 text-center">Kunjungan / Minggu</th>
                    <th className="py-3 px-3 text-center">Tren</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {liveTop5Gaode.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-[#767676]">
                        Tidak ada destinasi yang cocok dengan filter wilayah/kategori aktif.
                      </td>
                    </tr>
                  ) : (
                    liveTop5Gaode.map((d, idx) => (
                      <tr key={d.id} className="hover:bg-[#F6F3EC]/50 transition">
                        <td className="py-4 px-3 font-extrabold text-sm">#{idx + 1}</td>
                        <td className="py-4 px-3">
                          <strong className="text-sm font-extrabold text-[#1B1F1A] block">
                            {d.name}
                          </strong>
                          <span className="text-xs text-[#4A5248]">
                            {d.city_regency} · {d.category}
                          </span>
                        </td>
                        <td className="py-4 px-3 text-center">
                          <span className="px-3 py-1 rounded-xl bg-[#234B24] text-white font-extrabold text-sm">
                            {d.calculated_gaode_score}
                          </span>
                        </td>
                        <td className="py-4 px-3 text-center">
                          <span className="font-bold text-[#1E9E5A] bg-[#1E9E5A]/15 px-2.5 py-1 rounded-full text-xs">
                            {d.pungli_free_index}%
                          </span>
                        </td>
                        <td className="py-4 px-3 text-center font-bold text-[#1B1F1A]">
                          {d.avg_dwell_hours} Jam
                        </td>
                        <td className="py-4 px-3 text-center font-mono font-semibold text-[#234B24]">
                          {(d.weekly_visits || 0).toLocaleString('id-ID')}
                        </td>
                        <td className="py-4 px-3 text-center">
                          {d.trend === 'up' ? (
                            <span className="text-xs font-bold text-[#1E9E5A] inline-flex items-center gap-0.5">
                              <TrendingUp className="w-3.5 h-3.5" />
                              <span>Naik</span>
                            </span>
                          ) : (
                            <span className="text-xs font-bold text-[#767676]">Stabil</span>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      {/* TAB 3: REKAPITULASI INSIDEN & SOS (100% LIVE) */}
      {activeTab === 'incident_recap' && (
        <div className="space-y-6 no-print">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <div className="lg:col-span-6 bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 flex flex-col justify-between space-y-6">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-[#F26B4B]" />
                  <span>Komposisi Laporan &amp; Alert Lapangan (Live)</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Agregasi langsung dari PungliReportsRepo, HazardAlertsRepo, dan SosSignalsRepo.
                </p>
              </div>

              <div className="flex flex-col sm:flex-row items-center justify-center gap-6 py-2">
                {(() => {
                  let cumulativeOffset = 0;
                  const circ = 238.76;
                  return (
                    <div className="relative w-44 h-44 shrink-0 flex items-center justify-center">
                      <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                        <circle
                          cx="50"
                          cy="50"
                          r="38"
                          fill="none"
                          stroke="#F6F3EC"
                          strokeWidth="16"
                        />
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
                          <circle
                            cx="50"
                            cy="50"
                            r="38"
                            fill="none"
                            stroke="#E4E9DA"
                            strokeWidth="16"
                          />
                        )}
                      </svg>
                      <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                        <span className="text-2xl font-black text-[#1B1F1A]">
                          {totalIncidentsCount}
                        </span>
                        <span className="text-[10px] font-bold text-[#767676] uppercase">
                          Total Item
                        </span>
                      </div>
                    </div>
                  );
                })()}

                <div className="space-y-2.5 w-full">
                  {reactiveIncidentCategories.map((cat, idx) => (
                    <div key={idx} className="flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <span
                          className="w-3 h-3 rounded-full shrink-0"
                          style={{ backgroundColor: cat.color }}
                        />
                        <span className="font-semibold text-[#1B1F1A]">{cat.name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="font-extrabold text-[#1B1F1A]">{cat.count}</span>
                        <span
                          className={`text-[10px] font-bold px-1.5 py-0.5 rounded ${cat.badgeBg} ${cat.badgeText}`}
                        >
                          {cat.percentage}%
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="lg:col-span-6 bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 flex flex-col justify-between space-y-6">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <ShieldCheck className="w-5 h-5 text-[#234B24]" />
                  <span>Rasio Penyelesaian &amp; SLA Penindakan</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Dihitung real-time dari status tiket selesai di Pusat Komando SOS.
                </p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="bg-[#E4E9DA]/50 p-4 rounded-2xl border border-[#CFD8BE]">
                  <span className="text-[11px] font-bold uppercase text-[#234B24] block">
                    Tingkat Penyelesaian Live
                  </span>
                  <div className="mt-2 text-3xl font-black text-[#234B24]">
                    {resolutionRatePct}%
                  </div>
                  <span className="text-[11px] text-[#166534] font-bold mt-1 block">
                    {resolvedIncidentsCount} dari {totalIncidentsCount} item tuntas
                  </span>
                </div>

                <div className="bg-[#F6F3EC] p-4 rounded-2xl border border-[#CFD8BE]">
                  <span className="text-[11px] font-bold uppercase text-[#D95637] block">
                    Target Standar Respons
                  </span>
                  <div className="mt-2 text-3xl font-black text-[#D95637]">&lt; 30 Menit</div>
                  <span className="text-[11px] text-[#4A5248] font-bold mt-1 block">
                    Hotline 112 / 115 + 6 Instansi Sumbar
                  </span>
                </div>
              </div>

              <div className="w-full h-3 rounded-full bg-[#F6F3EC] overflow-hidden flex border border-[#CFD8BE]">
                <div
                  className="bg-[#1E9E5A] h-full transition-all duration-500"
                  style={{ width: `${resolutionRatePct}%` }}
                />
              </div>
            </div>
          </div>

          <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-4">
            <div className="flex items-center justify-between">
              <h4 className="text-sm lg:text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Clock className="w-4 h-4 text-[#234B24]" />
                <span>Log Aksi Lapangan Live (Saber Pungli, Jalur Ekstrem &amp; SOS)</span>
              </h4>
              <span className="text-xs font-bold text-[#1E9E5A]">
                {liveIncidentActionLog.length} Catatan Terbaru
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-[#234B24]/10 text-[#4A5248] font-bold">
                    <th className="py-2.5 px-3">Waktu</th>
                    <th className="py-2.5 px-3">Lokasi</th>
                    <th className="py-2.5 px-3">Jenis Insiden</th>
                    <th className="py-2.5 px-3">Posko / Petugas</th>
                    <th className="py-2.5 px-3">Catatan Aksi</th>
                    <th className="py-2.5 px-3 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {liveIncidentActionLog.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="py-8 text-center text-[#767676]">
                        Tidak ada catatan insiden untuk filter wilayah/periode aktif.
                      </td>
                    </tr>
                  ) : (
                    liveIncidentActionLog.map((row) => (
                      <tr key={row.id} className="hover:bg-[#F6F3EC]/50">
                        <td className="py-3 px-3 font-mono text-[11px] text-[#767676] whitespace-nowrap">
                          {row.time}
                        </td>
                        <td className="py-3 px-3 font-bold text-[#1B1F1A]">{row.destination}</td>
                        <td className="py-3 px-3 font-semibold text-[#234B24]">
                          {row.incidentType}
                        </td>
                        <td className="py-3 px-3 text-[#4A5248]">{row.officer}</td>
                        <td className="py-3 px-3 text-[#4A5248] max-w-xs">{row.actionTaken}</td>
                        <td className="py-3 px-3 text-right whitespace-nowrap">
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-black ${row.status === 'Selesai' || row.status === 'Evakuasi Selesai'
                                ? 'bg-emerald-100 text-emerald-800'
                                : row.status === 'Awas Tutup Total' || row.status === 'Siaga'
                                  ? 'bg-red-100 text-red-700'
                                  : 'bg-amber-100 text-amber-800'
                              }`}
                          >
                            {row.status}
                          </span>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      {/* TAB 4: EKSPOR LAPORAN RESMI */}
      {activeTab === 'export_report' && (
        <div className="space-y-6 no-print">
          <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-6">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-[#234B24]/10 pb-5">
              <div>
                <h3 className="text-base lg:text-lg font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <FileText className="w-5 h-5 text-[#234B24]" />
                  <span>Pusat Penerbitan Laporan Eksekutif Dinas Pariwisata Sumbar</span>
                </h3>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Cetak dokumen PDF ber-Kop Surat resmi atau unduh CSV sesuai filter aktif.
                </p>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                <span className="text-xs font-bold text-[#4A5248]">Rentang:</span>
                <select
                  value={reportPeriod}
                  onChange={(e) => setReportPeriod(e.target.value as 'month' | 'quarter' | 'year')}
                  className="min-h-[42px] px-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="month">Bulan Berjalan</option>
                  <option value="quarter">Kuartal Berjalan</option>
                  <option value="year">Tahun Anggaran Berjalan</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div className="p-6 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col justify-between space-y-4">
                <div className="space-y-2">
                  <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center">
                    <Printer className="w-5 h-5" />
                  </div>
                  <h4 className="text-base font-extrabold text-[#1B1F1A]">
                    Laporan Eksekutif Resmi Dispar (PDF)
                  </h4>
                  <p className="text-xs text-[#4A5248]">
                    Ber-Kop Surat resmi, rekap kunjungan, omset Escrow Trip Go, Leads WA P2P UMKM, Top 5 Gaode live, serta pengesahan tertanggal {todayFormatted}.
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

              <div className="p-6 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col justify-between space-y-4">
                <div className="space-y-2">
                  <div className="w-10 h-10 rounded-xl bg-[#1E9E5A] text-white flex items-center justify-center">
                    <FileSpreadsheet className="w-5 h-5" />
                  </div>
                  <h4 className="text-base font-extrabold text-[#1B1F1A]">
                    Data Mentah Spasial 19 Kab/Kota (CSV)
                  </h4>
                  <p className="text-xs text-[#4A5248]">
                    Dataset tabular seluruh 19 Kab/Kota, kepadatan, rasio domestik/wisman, serta metrik konversi WA P2P UMKM.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={handleExportCSV}
                  className="min-h-[46px] w-full px-5 py-2.5 rounded-xl bg-white hover:bg-gray-50 text-[#234B24] border border-[#CFD8BE] text-xs font-bold flex items-center justify-center gap-2 shadow-sm transition"
                >
                  <Download className="w-4 h-4 text-[#234B24]" />
                  <span>Unduh Berkas CSV (Excel)</span>
                </button>
              </div>
            </div>
          </section>
        </div>
      )}

      {/* TAB 5: BENCHMARK SLA SISTEM */}
      {activeTab === 'system_benchmark' && (
        <div className="no-print">
          <SystemHealthBenchmarkSubTab showToast={showToast} />
        </div>
      )}
    </div>
  );
};
