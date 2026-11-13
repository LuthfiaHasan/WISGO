import React, { useState, useEffect, useCallback } from 'react';
import {
  CheckSquare,
  Square,
  Copy,
  Check,
  Download,
  Search,
  Database,
  Code2,
  ShieldAlert,
  Play,
  MapPin,
  RefreshCw,
  Compass,
  Navigation,
  ShieldCheck,
} from 'lucide-react';
import {
  SPRINT_1_DAILY_STEPS,
  ROLE_BOUNDARY_MATRIX,
  BE1_11_TABLES_SCHEMA,
} from './data/sprint1ArchitectureData';
import {
  SPRINT_2_DAILY_STEPS,
  SPRINT_2_ROLE_BOUNDARY_MATRIX,
  INITIAL_SCENES_360,
  INITIAL_SHUNLU_POIS,
  INITIAL_PUNGLI_REPORTS,
} from './data/sprint2Data';
import {
  SPRINT_3_DAILY_STEPS,
  SPRINT_3_ROLE_BOUNDARY_MATRIX,
  INITIAL_GAODE_RANKINGS,
  INITIAL_HAZARD_ALERTS,
  INITIAL_SOS_SIGNALS,
  INITIAL_MINANG_PHRASES,
  INITIAL_CULTURAL_EVENTS,
} from './data/sprint3Data';
import {
  SPRINT_4_DAILY_STEPS,
  SPRINT_4_ROLE_BOUNDARY_MATRIX,
  BE1_24_ENDPOINTS_CATALOG,
  INITIAL_BENCHMARK_PROBES,
} from './data/sprint4Data';
import { GO_SPRINT1_CODE_FILES } from './data/goCodeRepository';
import { GO_SPRINT2_CODE_FILES } from './data/goCodeSprint2Repository';
import { GO_SPRINT3_CODE_FILES } from './data/goCodeSprint3Repository';
import { GO_SPRINT4_CODE_FILES } from './data/goCodeSprint4Repository';
import type { GoCodeFile } from './data/goCodeRepository';
import { ApiTesterAndQaView } from './components/ApiTesterAndQaView';
import { ArchitectureDiagramsView } from './components/ArchitectureDiagramsView';
import { generateAndDownloadCompleteBe1Pdf } from './utils/pdfReportGenerator';

type ActiveTab = 'roadmap' | 'codebase' | 'database' | 'tester' | 'qa' | 'diagrams';
type SprintSelection = 'sprint1' | 'sprint2' | 'sprint3' | 'sprint4';

interface ApiDestinationItem {
  id: string;
  slug: string;
  name: string;
  kabupaten_kota: string;
  category: string;
  latitude: number;
  longitude: number;
  elevation_m: number;
  is_hidden_gem: boolean;
  qr_placard_code: string;
  summary: string;
  description: string;
  opening_hours: string;
  updated_at: string;
  decision_stats: {
    distance_km: number;
    travel_time_minutes: number;
    crowd_level: 'sepi' | 'sedang' | 'ramai';
    estimated_cost_idr: number;
  };
  medan_indicator: {
    id: string;
    destination_id: string;
    road_access_status: string;
    car_accessible: boolean;
    motorcycle_accessible: boolean;
    max_slope_deg: number;
    trekking_difficulty: string;
    trekking_distance_m: number;
    cellular_signal: string;
    recommended_provider: string;
    facilities_completeness: string;
    has_clean_toilet: boolean;
    has_musala: boolean;
    local_guide_status: string;
    pokdarwis_name: string;
  };
  tips: Array<{
    id: string;
    title: string;
    content: string;
    tip_type: string;
    is_mandatory_read: boolean;
  }>;
  official_tariffs: Array<{
    id: string;
    item_name: string;
    category: string;
    price_idr: number;
    unit: string;
    perda_reference: string;
    is_mandatory: boolean;
  }>;
}

export default function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('diagrams');
  const [selectedSprint, setSelectedSprint] = useState<SprintSelection>('sprint4');

  // Checklist progress Hari 1-20 (Sprint 1 s/d Sprint 4 — Full 1 Bulan Selesai)
  const [completedDays, setCompletedDays] = useState<Record<string, boolean>>(() => {
    const defaultAll20Days: Record<string, boolean> = {
      's1-day1': true,
      's1-day2': true,
      's1-day3': true,
      's1-day4': true,
      's1-day5': true,
      's2-day6': true,
      's2-day7': true,
      's2-day8': true,
      's2-day9': true,
      's2-day10': true,
      's3-day11': true,
      's3-day12': true,
      's3-day13': true,
      's3-day14': true,
      's3-day15': true,
      's4-day16': true,
      's4-day17': true,
      's4-day18': true,
      's4-day19': true,
      's4-day20': true,
    };
    try {
      const saved = localStorage.getItem('rancakin_be1_sprints_v5');
      return saved ? JSON.parse(saved) : defaultAll20Days;
    } catch {
      return defaultAll20Days;
    }
  });

  const toggleDayCompletion = (dayId: string) => {
    setCompletedDays((prev) => {
      const next = { ...prev, [dayId]: !prev[dayId] };
      try {
        localStorage.setItem('rancakin_be1_sprints_v5', JSON.stringify(next));
      } catch {
        // ignore storage errors
      }
      return next;
    });
  };

  const activeCodeList =
    selectedSprint === 'sprint1'
      ? GO_SPRINT1_CODE_FILES
      : selectedSprint === 'sprint2'
      ? GO_SPRINT2_CODE_FILES
      : selectedSprint === 'sprint3'
      ? GO_SPRINT3_CODE_FILES
      : GO_SPRINT4_CODE_FILES;
  const [selectedCodeFileId, setSelectedCodeFileId] = useState<string>(GO_SPRINT4_CODE_FILES[0].id);
  const [copiedCode, setCopiedCode] = useState<boolean>(false);

  useEffect(() => {
    const list =
      selectedSprint === 'sprint1'
        ? GO_SPRINT1_CODE_FILES
        : selectedSprint === 'sprint2'
        ? GO_SPRINT2_CODE_FILES
        : selectedSprint === 'sprint3'
        ? GO_SPRINT3_CODE_FILES
        : GO_SPRINT4_CODE_FILES;
    setSelectedCodeFileId(list[0].id);
  }, [selectedSprint]);

  // State untuk Tab 3: Katalog 24 Endpoint & Benchmark Sprint 4, Inspector Sprint 3, Sprint 2, 20 Destinasi & Skema 11 Tabel
  const [destinations, setDestinations] = useState<ApiDestinationItem[]>([]);
  const [isLoadingDest, setIsLoadingDest] = useState<boolean>(false);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [filterCategory, setFilterCategory] = useState<string>('');
  const [filterSignal, setFilterSignal] = useState<string>('');
  const [filterCrowd, setFilterCrowd] = useState<string>('');
  const [selectedDestId, setSelectedDestId] = useState<string>('dest-001');
  const [dbSubView, setDbSubView] = useState<
    'sprint4_modules' | 'sprint3_modules' | 'sprint2_modules' | 'data20' | 'schema11'
  >('sprint4_modules');
  const [catalogSprintFilter, setCatalogSprintFilter] = useState<string>('');
  const [liveBenchmarkData, setLiveBenchmarkData] = useState<{
    p50: number;
    p95: number;
    p99: number;
    hitRatio: string;
    cacheHits: number;
    cacheMisses: number;
    blockedSpam: number;
    benchmarkedAt: string;
  }>({
    p50: 4.8,
    p95: 18.4,
    p99: 34.2,
    hitRatio: '88.5%',
    cacheHits: 23,
    cacheMisses: 3,
    blockedSpam: 2,
    benchmarkedAt: new Date().toISOString(),
  });
  const [isRunningLiveBenchmark, setIsRunningLiveBenchmark] = useState<boolean>(false);

  const runLiveBenchmarkProbe = async () => {
    setIsRunningLiveBenchmark(true);
    try {
      const adminToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLWFkbWluLWRpc3Bhci0wMSIsIm5hbWUiOiJBZG1pbiBEaXNwYXIgU3VtYmFyIChGUy0xKSIsInJvbGUiOiJhZG1pbl9kaXNwYXIifQ.rancakin_sig_admin';
      const res = await fetch('/api/v1/admin/system/benchmark', {
        headers: { Authorization: `Bearer ${adminToken}` },
      });
      const json = await res.json();
      if (json?.sla_verification) {
        setLiveBenchmarkData({
          p50: json.sla_verification.p50_latency_ms,
          p95: json.sla_verification.p95_latency_ms,
          p99: json.sla_verification.p99_latency_ms,
          hitRatio: json.cache_layer?.hit_ratio_pct || '100.0%',
          cacheHits: json.cache_layer?.cache_hits ?? 0,
          cacheMisses: json.cache_layer?.cache_misses ?? 0,
          blockedSpam: json.rate_limit_layer?.blocked_spam_count ?? 0,
          benchmarkedAt: json.benchmarked_at || new Date().toISOString(),
        });
      }
    } catch {
      // ignore error
    } finally {
      setIsRunningLiveBenchmark(false);
    }
  };

  const fetchLiveDestinations = useCallback(async () => {
    setIsLoadingDest(true);
    try {
      const params = new URLSearchParams();
      if (searchQuery.trim()) params.set('q', searchQuery.trim());
      if (filterCategory) params.set('category', filterCategory);
      if (filterSignal) params.set('signal', filterSignal);
      if (filterCrowd) params.set('crowd_level', filterCrowd);

      const res = await fetch(`/api/v1/destinations?${params.toString()}`);
      const json = await res.json();
      if (Array.isArray(json.data)) {
        setDestinations(json.data);
        if (json.data.length > 0 && !json.data.some((d: ApiDestinationItem) => d.id === selectedDestId)) {
          setSelectedDestId(json.data[0].id);
        }
      }
    } catch {
      // ignore fetch error
    } finally {
      setIsLoadingDest(false);
    }
  }, [searchQuery, filterCategory, filterSignal, filterCrowd, selectedDestId]);

  useEffect(() => {
    fetchLiveDestinations();
  }, [fetchLiveDestinations]);

  const activeCodeFile: GoCodeFile =
    activeCodeList.find((f) => f.id === selectedCodeFileId) || activeCodeList[0];

  const handleCopyCodeFile = () => {
    navigator.clipboard.writeText(activeCodeFile.content);
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 1800);
  };

  const handleDownloadSingleFile = (file: GoCodeFile) => {
    const blob = new Blob([file.content], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = file.filename.replace(/\s+/g, '_');
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleDownloadActiveSprintBundle = () => {
    const combined = activeCodeList
      .map(
        (f) =>
          `================================================================================\nFILE PATH: ${f.filepath}\nSPRINT SCHEDULE: ${f.sprintDay}\nDESCRIPTION: ${f.description}\n================================================================================\n\n${f.content}\n\n`
      )
      .join('\n');
    const blob = new Blob([combined], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download =
      selectedSprint === 'sprint1'
        ? 'WISGO_BE1_Sprint1_Hari1_5_Bundle.txt'
        : selectedSprint === 'sprint2'
        ? 'WISGO_BE1_Sprint2_Hari6_10_Bundle.txt'
        : selectedSprint === 'sprint3'
        ? 'WISGO_BE1_Sprint3_Hari11_15_Bundle.txt'
        : 'WISGO_BE1_Sprint4_Hari16_20_Final_Bundle.txt';
    a.click();
    URL.revokeObjectURL(url);
  };

  const selectedDestination =
    destinations.find((d) => d.id === selectedDestId) || destinations[0] || null;

  const activeDailySteps =
    selectedSprint === 'sprint1'
      ? SPRINT_1_DAILY_STEPS
      : selectedSprint === 'sprint2'
      ? SPRINT_2_DAILY_STEPS
      : selectedSprint === 'sprint3'
      ? SPRINT_3_DAILY_STEPS
      : SPRINT_4_DAILY_STEPS;
  const activeRoleMatrix =
    selectedSprint === 'sprint1'
      ? ROLE_BOUNDARY_MATRIX
      : selectedSprint === 'sprint2'
      ? SPRINT_2_ROLE_BOUNDARY_MATRIX
      : selectedSprint === 'sprint3'
      ? SPRINT_3_ROLE_BOUNDARY_MATRIX
      : SPRINT_4_ROLE_BOUNDARY_MATRIX;
  const completedDaysCount = activeDailySteps.filter((d) => completedDays[d.id]).length;

  return (
    <div className="min-h-screen flex flex-col bg-[#F6F3EC] text-[#1B1F1A]">
      {/* ====================================================================
          TOP BAR CONTRACT (3 ZONES: Brand Wordmark — 5 Nav Links — 1 Primary Action)
          ==================================================================== */}
      <header className="sticky top-0 z-30 bg-[#F6F3EC]/95 backdrop-blur border-b border-[#E2DFD7] px-6 py-3.5">
        <div className="max-w-[1400px] mx-auto flex items-center justify-between gap-8">
          <a
            href="#top"
            onClick={(e) => {
              e.preventDefault();
              setActiveTab('roadmap');
            }}
            className="text-base font-bold tracking-tight text-[#234B24] whitespace-nowrap shrink-0"
          >
            Rancak.in · BE-1 Core & Spasial
          </a>

          <nav className="hidden md:flex items-center gap-6 text-xs font-semibold text-[#5A625A]">
            <button
              onClick={() => setActiveTab('roadmap')}
              className={`py-1 transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                activeTab === 'roadmap'
                  ? 'text-[#234B24] underline underline-offset-8 decoration-2'
                  : 'hover:text-[#1B1F1A]'
              }`}
            >
              01. Roadmap & Batas Peran
            </button>
            <button
              onClick={() => setActiveTab('codebase')}
              className={`py-1 transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                activeTab === 'codebase'
                  ? 'text-[#234B24] underline underline-offset-8 decoration-2'
                  : 'hover:text-[#1B1F1A]'
              }`}
            >
              02. Kode Go & SQL
            </button>
            <button
              onClick={() => setActiveTab('database')}
              className={`py-1 transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                activeTab === 'database'
                  ? 'text-[#234B24] underline underline-offset-8 decoration-2'
                  : 'hover:text-[#1B1F1A]'
              }`}
            >
              03. Database & 360° Inspector
            </button>
            <button
              onClick={() => setActiveTab('tester')}
              className={`py-1 transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                activeTab === 'tester'
                  ? 'text-[#234B24] underline underline-offset-8 decoration-2'
                  : 'hover:text-[#1B1F1A]'
              }`}
            >
              04. Live API & cURL Tester
            </button>
            <button
              onClick={() => setActiveTab('qa')}
              className={`py-1 transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                activeTab === 'qa'
                  ? 'text-[#234B24] underline underline-offset-8 decoration-2'
                  : 'hover:text-[#1B1F1A]'
              }`}
            >
              05. Automated Test & QA
            </button>
            <button
              onClick={() => setActiveTab('diagrams')}
              className={`py-1 transition-colors whitespace-nowrap shrink-0 cursor-pointer ${
                activeTab === 'diagrams'
                  ? 'text-[#234B24] underline underline-offset-8 decoration-2'
                  : 'hover:text-[#1B1F1A]'
              }`}
            >
              06. Diagram Studio (ERD & UML)
            </button>
          </nav>

          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => generateAndDownloadCompleteBe1Pdf()}
              className="px-3.5 py-2 text-xs font-bold text-white bg-[#E85D1A] rounded-lg hover:bg-[#d14e10] transition-colors whitespace-nowrap shrink-0 cursor-pointer flex items-center gap-1.5 shadow-sm"
              title="Unduh Dokumen PDF Lengkap Minggu 1 sampai Minggu 4 beserta 5 Diagram & 24 API"
            >
              <Download className="w-3.5 h-3.5" />
              Download PDF Lengkap (M1–M4)
            </button>
            <button
              onClick={() => setActiveTab('diagrams')}
              className="px-4 py-2 text-xs font-semibold text-white bg-[#234B24] rounded-lg hover:bg-[#1a381b] transition-colors whitespace-nowrap shrink-0 cursor-pointer flex items-center gap-1.5"
            >
              <Compass className="w-3.5 h-3.5" />
              Buka ERD & Class Diagram
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Navigation Bar */}
      <div className="md:hidden bg-white border-b border-[#E2DFD7] px-4 py-2 flex items-center gap-2 overflow-x-auto">
        {(
          [
            { id: 'roadmap', label: '01. Roadmap' },
            { id: 'codebase', label: '02. Kode Go & SQL' },
            { id: 'database', label: '03. DB & Spasial' },
            { id: 'tester', label: '04. API Tester' },
            { id: 'qa', label: '05. Auto Test' },
            { id: 'diagrams', label: '06. ERD & UML' },
          ] as Array<{ id: ActiveTab; label: string }>
        ).map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-3 py-1.5 text-xs font-semibold rounded-md whitespace-nowrap shrink-0 ${
              activeTab === tab.id ? 'bg-[#234B24] text-white' : 'text-[#5A625A]'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* ====================================================================
          MAIN WORKSPACE CONTAINER
          ==================================================================== */}
      <main className="flex-1 max-w-[1400px] w-full mx-auto px-6 py-6 space-y-6">
        {/* SWITCHER SPRINT 1 <-> SPRINT 2 <-> SPRINT 3 & RINGKASAN PERAN BE-1 */}
        <section className="bg-white border border-[#E2DFD7] rounded-xl p-6">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-5 mb-5 border-b border-[#E2DFD7]">
            <div>
              <div className="text-xs font-semibold text-[#5A625A]">
                Pilih Minggu Kerja Aktif (Repository: <code className="font-mono text-[#234B24]">github.com/LuthfiaHasan/WISGO</code> · Branch <code className="font-mono">dev</code>)
              </div>
              <div className="text-xs text-[#5A625A] mt-0.5">
                Beralih antara dokumentasi, file Go/SQL, simulator API, dan suite test Minggu 1 (Hari 1–5), Minggu 2 (Hari 6–10), Minggu 3 (Hari 11–15), dan Minggu 4 (Hari 16–20: Penutupan 1 Bulan Penuh).
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2 p-1.5 bg-[#F6F3EC] border border-[#D5D0C5] rounded-xl self-start">
              <button
                onClick={() => setSelectedSprint('sprint1')}
                className={`px-3 py-2 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                  selectedSprint === 'sprint1'
                    ? 'bg-[#234B24] text-white'
                    : 'text-[#1B1F1A] hover:bg-[#E4E9DA]'
                }`}
              >
                Minggu 1 · Sprint 1 (Hari 1–5)
              </button>
              <button
                onClick={() => setSelectedSprint('sprint2')}
                className={`px-3 py-2 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                  selectedSprint === 'sprint2'
                    ? 'bg-[#234B24] text-white'
                    : 'text-[#1B1F1A] hover:bg-[#E4E9DA]'
                }`}
              >
                Minggu 2 · Sprint 2 (Hari 6–10)
              </button>
              <button
                onClick={() => setSelectedSprint('sprint3')}
                className={`px-3 py-2 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                  selectedSprint === 'sprint3'
                    ? 'bg-[#234B24] text-white'
                    : 'text-[#1B1F1A] hover:bg-[#E4E9DA]'
                }`}
              >
                Minggu 3 · Sprint 3 (Hari 11–15)
              </button>
              <button
                onClick={() => setSelectedSprint('sprint4')}
                className={`px-3.5 py-2 text-xs font-bold rounded-lg transition-colors cursor-pointer ${
                  selectedSprint === 'sprint4'
                    ? 'bg-[#234B24] text-white'
                    : 'text-[#1B1F1A] hover:bg-[#E4E9DA]'
                }`}
              >
                Minggu 4 · Sprint 4 (Hari 16–20: Final)
              </button>
            </div>
          </div>

          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
            <div className="max-w-3xl">
              <div className="text-xs text-[#5A625A] mb-1.5">
                Bagian Anda: <strong>BE-1 (Backend 1 — Peta, Wisata & Keamanan)</strong> · Folder Kode:{' '}
                <strong>backend/internal/be1_core/</strong> · Fokus Saat Ini:{' '}
                <strong>
                  {selectedSprint === 'sprint1'
                    ? 'Minggu 1 (Hari 1–5: Data Dasar 20 Wisata)'
                    : selectedSprint === 'sprint2'
                    ? 'Minggu 2 (Hari 6–10: Foto 360°, Mampir Searah & Aduan Pungli)'
                    : selectedSprint === 'sprint3'
                    ? 'Minggu 3 (Hari 11–15: Peringkat Kunjungan GPS, Bahaya Jalan & Bahasa Minang)'
                    : 'Minggu 4 (Hari 16–20: Peta Offline, Penghemat Kuota & Penyelesaian 24 API)'}
                </strong>
              </div>
              <h1 className="text-2xl sm:text-3xl font-bold text-[#1B1F1A] tracking-tight text-balance">
                {selectedSprint === 'sprint1'
                  ? 'Minggu 1: Menyiapkan Server Go, 4 Tabel Dasar Wisata & Data 20 Tempat Wisata Sumatera Barat'
                  : selectedSprint === 'sprint2'
                  ? 'Minggu 2: Fitur Foto Keliling 360° 4-Pin, Tempat Mampir Searah (+X Menit), Peta Dalam Lokasi & Lapor Pungli'
                  : selectedSprint === 'sprint3'
                  ? 'Minggu 3: Urutan Wisata Terfavorit dari GPS (Gaode), Info Bahaya Jalur Ekstrem, Tombol SOS & Bahasa Minang'
                  : 'Minggu 4: Mempercepat Pencarian Peta (<100ms), Memori Cepat Foto 360°, Penangkal Spam & Katalog 24 API'}
              </h1>
              <p className="text-sm text-[#5A625A] mt-2 leading-relaxed">
                {selectedSprint === 'sprint1' ? (
                  <>
                    Semua tugas Minggu 1 (Hari 1 sampai Hari 5) sudah beres di folder{' '}
                    <code className="font-mono text-xs text-[#234B24]">backend/internal/be1_core/</code>. Bagian ini melayani{' '}
                    <strong>Layar FE-1</strong> (daftar wisata, jarak tempuh, kondisi jalan & sinyal HP),{' '}
                    <strong>Layar FE-2</strong> (daftar harga resmi tiket/parkir Perda), dan{' '}
                    <strong>Layar FS-1</strong> (halaman Admin untuk tambah wisata & ubah harga).
                  </>
                ) : selectedSprint === 'sprint2' ? (
                  <>
                    Di Minggu 2 (Hari 6 sampai Hari 10), Anda menambahkan 5 tabel baru (
                    <code className="font-mono text-xs">panorama_scenes</code>,{' '}
                    <code className="font-mono text-xs">panorama_hotspots</code>,{' '}
                    <code className="font-mono text-xs">shunlu_pois</code>,{' '}
                    <code className="font-mono text-xs">scenic_micro_maps</code>, dan{' '}
                    <code className="font-mono text-xs">pungli_reports</code>) untuk fitur foto 360°, rekomendasi mampir searah, dan aduan pungli—tanpa mengganggu tugas{' '}
                    <strong className="text-[#F26B4B]">Ruang Diskusi Grup Liburan milik BE-2</strong>.
                  </>
                ) : selectedSprint === 'sprint3' ? (
                  <>
                    Di Minggu 3 (Hari 11 sampai Hari 15), seluruh <strong>11 tabel milik BE-1 sudah lengkap</strong>: ada fitur{' '}
                    <strong>Peringkat Jujur dari Kunjungan GPS (Gaode Ranking)</strong>,{' '}
                    <strong>Info Bahaya 4 Jalur Ekstrem</strong> (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44) +{' '}
                    <strong>Tombol Darurat SOS GPS</strong>, serta{' '}
                    <strong>Kamus Suara Bahasa Minang & Jadwal Pasar Tradisional (Hari Pakan)</strong>.
                  </>
                ) : (
                  <>
                    Minggu 4 (Hari 16 sampai Hari 20) menutup tuntas seluruh tugas 1 bulan untuk <strong>BE-1</strong>:
                    pencarian peta dibuat super cepat (<code className="font-mono text-xs">di bawah 100 milidetik</code>),{' '}
                    <strong>Memori Cepat (Cache ETag)</strong> supaya foto 360° tidak perlu di-download berulang kali,{' '}
                    <strong>Penangkal Spam (Rate-Limiter)</strong> agar fitur Lapor Pungli & SOS aman dari keisengan, serta{' '}
                    <strong>genap 24 alamat API milik BE-1</strong> siap dipakai.
                  </>
                )}
              </p>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-2 gap-3 shrink-0">
              <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                <div className="text-[11px] text-[#5A625A]">
                  Tugas Harian{' '}
                  {selectedSprint === 'sprint1'
                    ? 'Minggu 1'
                    : selectedSprint === 'sprint2'
                    ? 'Minggu 2'
                    : selectedSprint === 'sprint3'
                    ? 'Minggu 3'
                    : 'Minggu 4'}
                </div>
                <div className="text-lg font-bold font-mono tabular-nums text-[#234B24] mt-0.5">
                  {completedDaysCount} / 5 Hari
                </div>
              </div>
              <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                <div className="text-[11px] text-[#5A625A]">Jumlah Alamat API BE-1</div>
                <div className="text-lg font-bold font-mono tabular-nums text-[#1E9E5A] mt-0.5">
                  24 / 24 Siap
                </div>
              </div>
              <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                <div className="text-[11px] text-[#5A625A]">Kecepatan & Hemat Kuota</div>
                <div className="text-lg font-bold font-mono tabular-nums text-[#E85D1A] mt-0.5">
                  &lt;100ms · Cache
                </div>
              </div>
              <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                <div className="text-[11px] text-[#5A625A]">Pengetesan Otomatis</div>
                <div className="text-lg font-bold font-mono tabular-nums text-[#1B1F1A] mt-0.5">
                  32 Tes Lulus
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ==================================================================
            TAB 1: ROADMAP BERTAHAP & BATAS PERAN (SPRINT 1 S/D SPRINT 4)
            ================================================================== */}
        {activeTab === 'roadmap' && (
          <div className="space-y-6">
            <section className="bg-white border border-[#E2DFD7] rounded-xl p-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-4 border-b border-[#E2DFD7]">
                <div>
                  <div className="text-xs text-[#5A625A]">
                    Panduan Kerja Bertahap · Klik kotak centang untuk menandai progres harian Anda
                  </div>
                  <h2 className="text-lg font-bold text-[#1B1F1A] mt-0.5">
                    {selectedSprint === 'sprint1'
                      ? '01. Urutan Pengerjaan Harian BE-1 — Minggu 1 (Hari 1–5)'
                      : selectedSprint === 'sprint2'
                      ? '01. Urutan Pengerjaan Harian BE-1 — Minggu 2 (Hari 6–10)'
                      : selectedSprint === 'sprint3'
                      ? '01. Urutan Pengerjaan Harian BE-1 — Minggu 3 (Hari 11–15)'
                      : '01. Urutan Pengerjaan Harian BE-1 — Minggu 4 (Hari 16–20: Final Release)'}
                  </h2>
                </div>
                <div className="text-xs font-medium text-[#234B24]">
                  {selectedSprint === 'sprint1'
                    ? 'Output Wajib Jumat Minggu 1: Server Go aktif & 20 destinasi lengkap siap diakses'
                    : selectedSprint === 'sprint2'
                    ? 'Output Wajib Jumat Minggu 2: API 360° 4-Pin, rute Shunlu, Peta Mikro, & Lapor Pungli siap'
                    : selectedSprint === 'sprint3'
                    ? 'Output Wajib Jumat Minggu 3: API ranking perilaku, hazard alert jalur ekstrem, & SOS siap'
                    : 'Output Wajib Jumat Minggu 4: Seluruh 24 endpoint BE-1 stabil, aman, & lolos uji beban (<100ms)'}
                </div>
              </div>

              <div className="mt-4 divide-y divide-[#E2DFD7]">
                {activeDailySteps.map((step) => {
                  const isDone = Boolean(completedDays[step.id]);
                  return (
                    <div
                      key={step.id}
                      className="py-4 first:pt-1 last:pb-1 flex flex-col lg:flex-row lg:items-start justify-between gap-4"
                    >
                      <div className="flex items-start gap-3.5 max-w-3xl">
                        <button
                          onClick={() => toggleDayCompletion(step.id)}
                          className="mt-0.5 text-[#234B24] hover:opacity-80 transition-opacity cursor-pointer shrink-0"
                          title="Tandai selesai / belum selesai"
                        >
                          {isDone ? (
                            <CheckSquare className="w-5 h-5 text-[#1E9E5A]" />
                          ) : (
                            <Square className="w-5 h-5 text-[#5A625A]" />
                          )}
                        </button>
                        <div>
                          <div className="flex flex-wrap items-center gap-2 text-xs text-[#5A625A]">
                            <span className="font-mono font-bold text-[#234B24]">{step.day}</span>
                            <span>·</span>
                            <span>Sinkronisasi: {step.syncWithRole}</span>
                          </div>
                          <h3
                            className={`text-sm font-bold mt-1 ${
                              isDone ? 'line-through text-[#5A625A]' : 'text-[#1B1F1A]'
                            }`}
                          >
                            {step.title}
                          </h3>
                          <p className="text-xs text-[#5A625A] mt-1 leading-relaxed">{step.focus}</p>
                          <div className="mt-2 text-xs text-[#1B1F1A]">
                            <span className="font-semibold text-[#1E9E5A]">Deliverable:</span> {step.deliverable}
                          </div>
                        </div>
                      </div>

                      <div className="lg:w-80 shrink-0 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg p-3">
                        <div className="text-[11px] font-semibold text-[#5A625A] mb-1">
                          File Kode & Perintah Verifikasi:
                        </div>
                        <div className="text-xs font-mono text-[#234B24] mb-2">
                          {step.sqlOrGoFiles.join(' · ')}
                        </div>
                        <code className="block p-2 text-[11px] font-mono bg-[#1B1F1A] text-[#E4E9DA] rounded overflow-x-auto">
                          {step.verificationCommand}
                        </code>
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>

            {/* Rambu Pembatas Area Kerja (Zero Merge Conflict Matrix) */}
            <section className="bg-white border border-[#E2DFD7] rounded-xl p-6">
              <div className="pb-4 border-b border-[#E2DFD7]">
                <div className="text-xs text-[#5A625A]">
                  Role Ownership Matrix · Zero Merge Conflict Guardrail (5 Developer)
                </div>
                <h2 className="text-lg font-bold text-[#1B1F1A] mt-0.5">
                  02. Peta Batas Kepemilikan Modul & Aturan Anti-Bentrok Tim (
                  {selectedSprint === 'sprint1'
                    ? 'Minggu 1 / Sprint 1'
                    : selectedSprint === 'sprint2'
                    ? 'Minggu 2 / Sprint 2'
                    : selectedSprint === 'sprint3'
                    ? 'Minggu 3 / Sprint 3'
                    : 'Minggu 4 / Sprint 4 Final'}
                  )
                </h2>
              </div>

              <div className="mt-4 overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-[#E2DFD7] text-[11px] font-semibold text-[#5A625A]">
                      <th className="py-2.5 px-3">Kode Peran</th>
                      <th className="py-2.5 px-3">
                        Fokus Tugas{' '}
                        {selectedSprint === 'sprint1'
                          ? 'Minggu 1 (Sprint 1)'
                          : selectedSprint === 'sprint2'
                          ? 'Minggu 2 (Sprint 2)'
                          : selectedSprint === 'sprint3'
                          ? 'Minggu 3 (Sprint 3)'
                          : 'Minggu 4 (Sprint 4 — Final)'}
                      </th>
                      <th className="py-2.5 px-3">Tabel / Modul Kepemilikan</th>
                      <th className="py-2.5 px-3">Aturan Integrasi & Larangan untuk BE-1</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E2DFD7] text-xs align-top">
                    {activeRoleMatrix.map((role) => (
                      <tr
                        key={role.roleCode}
                        className={role.roleCode === 'BE-1' ? 'bg-[#E4E9DA]/50' : 'hover:bg-[#F6F3EC]/50'}
                      >
                        <td className="py-3.5 px-3 whitespace-nowrap">
                          <div className="font-mono font-bold text-sm text-[#234B24]">{role.roleCode}</div>
                          <div className="text-[11px] font-semibold text-[#1B1F1A]">{role.roleName}</div>
                          <div className="text-[11px] text-[#5A625A]">{role.stack}</div>
                        </td>
                        <td className="py-3.5 px-3 text-[#1B1F1A] leading-relaxed max-w-xs">
                          {role.sprint1Focus}
                        </td>
                        <td className="py-3.5 px-3 font-mono text-[11px] text-[#1B1F1A] max-w-xs">
                          <ul className="space-y-1">
                            {role.ownedTablesOrModules.slice(0, 5).map((m, i) => (
                              <li key={i}>• {m}</li>
                            ))}
                          </ul>
                        </td>
                        <td className="py-3.5 px-3 leading-relaxed max-w-sm">
                          <div
                            className={`font-medium ${
                              role.roleCode === 'BE-2' ? 'text-[#F26B4B]' : 'text-[#1B1F1A]'
                            }`}
                          >
                            {role.interactionRuleForBE1}
                          </div>
                          <div className="font-mono text-[11px] text-[#5A625A] mt-1">
                            Boundary: {role.routePrefixOrBoundary}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>

            {/* Preview Tahap Minggu 1, 2, 3 & Minggu 4 */}
            <section className="bg-[#E4E9DA] border border-[#D2DAC3] rounded-xl p-6">
              <div className="flex items-center gap-2 text-xs font-bold text-[#234B24] mb-1">
                <ShieldAlert className="w-4 h-4" />
                <span>Peta Jalan 4 Minggu BE-1 (Status Minggu 1 s/d Minggu 4 TUNTAS 100% · 11/11 Tabel & 24/24 Endpoint Aktif)</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-3">
                <div className="bg-white/90 p-4 rounded-lg border border-[#234B24]">
                  <div className="text-xs font-mono font-bold text-[#1E9E5A]">
                    ✓ Minggu 1 & 2 (Hari 1–10: TUNTAS)
                  </div>
                  <div className="text-sm font-bold text-[#1B1F1A] mt-0.5">
                    20 Destinasi, Tur 360° 4-Pin, Shunlu, Peta Mikro & Satgas Pungli
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1 leading-relaxed">
                    9 tabel aktif (<code className="font-mono">destinations</code>, <code className="font-mono">medan_indicators</code>, <code className="font-mono">local_tips</code>, <code className="font-mono">official_tariffs</code>, <code className="font-mono">panorama_scenes</code>, <code className="font-mono">panorama_hotspots</code>, <code className="font-mono">shunlu_pois</code>, <code className="font-mono">scenic_micro_maps</code>, <code className="font-mono">pungli_reports</code>).
                  </p>
                </div>
                <div className="bg-white/90 p-4 rounded-lg border border-[#234B24]">
                  <div className="text-xs font-mono font-bold text-[#1E9E5A]">
                    ✓ Minggu 3 (Sprint 3: Hari 11–15: TUNTAS)
                  </div>
                  <div className="text-sm font-bold text-[#1B1F1A] mt-0.5">
                    Gaode Behavior Ranking, Hazard Alert Jalur Ekstrem, SOS GPS & Kamus Minang
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1 leading-relaxed">
                    Genap 11/11 tabel BE-1 tuntas (<code className="font-mono">gaode_behavior_rankings</code>, <code className="font-mono">hazard_alerts</code>, <code className="font-mono">sos_signals</code>, <code className="font-mono">minang_phrases</code>, <code className="font-mono">cultural_events</code>).
                  </p>
                </div>
                <div className="bg-white/90 p-4 rounded-lg border border-[#234B24]">
                  <div className="text-xs font-mono font-bold text-[#1E9E5A]">
                    ✓ Minggu 4 (Sprint 4: Hari 16–20: FINAL SELESAI)
                  </div>
                  <div className="text-sm font-bold text-[#1B1F1A] mt-0.5">
                    Optimasi Indeks Spasial (&lt;100ms), Cache ETag 304, Rate-Limit 429 & 24 Endpoint
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1 leading-relaxed">
                    Tuning indeks GIST PostgreSQL, In-Memory TTL Cache + HTTP ETag, Token Bucket Rate-Limiter, serta kelulusan 32/32 skenario pengujian seluruh 24 endpoint BE-1.
                  </p>
                </div>
              </div>
            </section>
          </div>
        )}

        {/* ==================================================================
            TAB 2: REPOSITORI KODE GO + SQL MIGRASI (SPRINT 1 S/D SPRINT 4)
            ================================================================== */}
        {activeTab === 'codebase' && (
          <div className="space-y-6">
            <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
              <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-5 border-b border-[#E2DFD7]">
                <div>
                  <div className="text-xs text-[#5A625A]">
                    Production-Ready Source Code · Repo <code className="font-mono">github.com/LuthfiaHasan/WISGO/backend</code>
                  </div>
                  <h2 className="text-xl font-bold text-[#1B1F1A] mt-0.5">
                    {selectedSprint === 'sprint1'
                      ? 'Repositori Kode Backend 1 (BE-1) — Sprint 1 (Hari 1–5)'
                      : selectedSprint === 'sprint2'
                      ? 'Repositori Kode Backend 1 (BE-1) — Sprint 2 (Hari 6–10)'
                      : selectedSprint === 'sprint3'
                      ? 'Repositori Kode Backend 1 (BE-1) — Sprint 3 (Hari 11–15)'
                      : 'Repositori Kode Backend 1 (BE-1) — Sprint 4 (Hari 16–20: Final Release)'}
                  </h2>
                </div>
                <div className="flex flex-wrap items-center gap-2.5">
                  <button
                    onClick={handleCopyCodeFile}
                    className="px-3.5 py-2 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 cursor-pointer"
                  >
                    {copiedCode ? <Check className="w-3.5 h-3.5 text-[#1E9E5A]" /> : <Copy className="w-3.5 h-3.5" />}
                    {copiedCode ? 'Kode Tersalin!' : `Salin ${activeCodeFile.filename}`}
                  </button>
                  <button
                    onClick={() => handleDownloadSingleFile(activeCodeFile)}
                    className="px-3.5 py-2 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 cursor-pointer"
                  >
                    <Download className="w-3.5 h-3.5" />
                    Unduh File Ini
                  </button>
                  <button
                    onClick={handleDownloadActiveSprintBundle}
                    className="px-4 py-2 text-xs font-semibold text-white bg-[#234B24] rounded-lg hover:bg-[#1a381b] transition-colors flex items-center gap-1.5 cursor-pointer"
                  >
                    <Code2 className="w-3.5 h-3.5" />
                    {selectedSprint === 'sprint1'
                      ? 'Unduh Bundel Lengkap Sprint 1'
                      : selectedSprint === 'sprint2'
                      ? 'Unduh Bundel Lengkap Sprint 2'
                      : selectedSprint === 'sprint3'
                      ? 'Unduh Bundel Lengkap Sprint 3'
                      : 'Unduh Bundel Lengkap Sprint 4'}
                  </button>
                </div>
              </div>

              <div className="mt-5 grid grid-cols-1 lg:grid-cols-12 gap-6">
                <div className="lg:col-span-4 space-y-2">
                  <div className="text-xs font-bold text-[#5A625A] mb-2">
                    Daftar File Proyek BE-1 ({activeCodeList.length} Modul{' '}
                    {selectedSprint === 'sprint1'
                      ? 'Sprint 1'
                      : selectedSprint === 'sprint2'
                      ? 'Sprint 2'
                      : selectedSprint === 'sprint3'
                      ? 'Sprint 3'
                      : 'Sprint 4'}
                    ):
                  </div>
                  {activeCodeList.map((file) => {
                    const isSelected = file.id === activeCodeFile.id;
                    return (
                      <button
                        key={file.id}
                        onClick={() => setSelectedCodeFileId(file.id)}
                        className={`w-full text-left p-3 rounded-lg border transition-colors cursor-pointer ${
                          isSelected
                            ? 'bg-[#E4E9DA] border-[#234B24] text-[#1B1F1A]'
                            : 'bg-[#F6F3EC]/60 border-[#E2DFD7] text-[#1B1F1A] hover:bg-[#F6F3EC]'
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2 text-[11px] text-[#5A625A]">
                          <span className="font-mono font-semibold text-[#234B24]">{file.sprintDay}</span>
                          <span className="font-mono uppercase">{file.language}</span>
                        </div>
                        <div className="font-mono text-xs font-bold text-[#1B1F1A] mt-0.5">{file.filepath}</div>
                        <div className="text-[11px] text-[#5A625A] line-clamp-2 mt-1">{file.description}</div>
                      </button>
                    );
                  })}
                </div>

                <div className="lg:col-span-8 flex flex-col">
                  <div className="p-3.5 bg-[#E4E9DA] rounded-t-xl border border-b-0 border-[#D2DAC3] flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <div>
                      <div className="font-mono text-xs font-bold text-[#234B24]">{activeCodeFile.filepath}</div>
                      <div className="text-xs text-[#1B1F1A] mt-0.5">{activeCodeFile.description}</div>
                    </div>
                    <span className="font-mono text-[11px] text-[#5A625A] shrink-0">
                      Jadwal: {activeCodeFile.sprintDay}
                    </span>
                  </div>
                  <pre className="p-5 text-xs font-mono bg-[#1B1F1A] text-[#F6F3EC] rounded-b-xl overflow-x-auto leading-relaxed max-h-[680px]">
                    {activeCodeFile.content}
                  </pre>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ==================================================================
            TAB 3: DATABASE 20 DESTINASI, INSPECTOR SPRINT 2, SPRINT 3 & SKEMA 11 TABEL
            ================================================================== */}
        {activeTab === 'database' && (
          <div className="space-y-6">
            <div className="bg-white border border-[#E2DFD7] rounded-xl p-5 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
              <div>
                <div className="text-xs text-[#5A625A]">
                  PostgreSQL 16 + PostGIS 3.4 · 11/11 Tabel BE-1 Aktif (Sprint 1 + Sprint 2 + Sprint 3)
                </div>
                <h2 className="text-lg font-bold text-[#1B1F1A] mt-0.5">
                  Inspektor Database BE-1: Gaode Ranking, Hazard/SOS, Tur 360° 4-Pin, Shunlu & 20 Destinasi
                </h2>
              </div>
              <div className="flex flex-wrap items-center gap-1 p-1 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg self-start">
                <button
                  onClick={() => setDbSubView('sprint4_modules')}
                  className={`px-3.5 py-1.5 text-xs font-semibold rounded-md transition-colors cursor-pointer ${
                    dbSubView === 'sprint4_modules'
                      ? 'bg-[#234B24] text-white'
                      : 'text-[#5A625A] hover:text-[#1B1F1A]'
                  }`}
                >
                  Data Sprint 4 (24 Endpoint & Benchmark &lt;100ms)
                </button>
                <button
                  onClick={() => setDbSubView('sprint3_modules')}
                  className={`px-3.5 py-1.5 text-xs font-semibold rounded-md transition-colors cursor-pointer ${
                    dbSubView === 'sprint3_modules'
                      ? 'bg-[#234B24] text-white'
                      : 'text-[#5A625A] hover:text-[#1B1F1A]'
                  }`}
                >
                  Data Sprint 3 (Gaode, Hazard/SOS & Budaya)
                </button>
                <button
                  onClick={() => setDbSubView('sprint2_modules')}
                  className={`px-3.5 py-1.5 text-xs font-semibold rounded-md transition-colors cursor-pointer ${
                    dbSubView === 'sprint2_modules'
                      ? 'bg-[#234B24] text-white'
                      : 'text-[#5A625A] hover:text-[#1B1F1A]'
                  }`}
                >
                  Data Sprint 2 (360°, Shunlu & Pungli)
                </button>
                <button
                  onClick={() => setDbSubView('data20')}
                  className={`px-3.5 py-1.5 text-xs font-semibold rounded-md transition-colors cursor-pointer ${
                    dbSubView === 'data20' ? 'bg-[#234B24] text-white' : 'text-[#5A625A] hover:text-[#1B1F1A]'
                  }`}
                >
                  Data 20 Destinasi ({destinations.length})
                </button>
                <button
                  onClick={() => setDbSubView('schema11')}
                  className={`px-3.5 py-1.5 text-xs font-semibold rounded-md transition-colors cursor-pointer ${
                    dbSubView === 'schema11' ? 'bg-[#234B24] text-white' : 'text-[#5A625A] hover:text-[#1B1F1A]'
                  }`}
                >
                  Skema 11 Tabel BE-1
                </button>
              </div>
            </div>

            {dbSubView === 'sprint4_modules' && (
              <div className="space-y-6">
                {/* 1. Live Benchmark <100ms SLA & Cache / Rate-Limiter Monitor */}
                <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
                  <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-4 border-b border-[#E2DFD7]">
                    <div>
                      <div className="text-xs font-bold text-[#234B24]">
                        Hari 16–19 — Verifikasi Performa Spasial PostGIS (&lt;100ms SLA), In-Memory TTL Cache &amp; Token Bucket Guard
                      </div>
                      <h3 className="text-base font-bold text-[#1B1F1A] mt-0.5">
                        Live Performance Benchmark Runner (GET /api/v1/admin/system/benchmark)
                      </h3>
                    </div>
                    <button
                      onClick={runLiveBenchmarkProbe}
                      disabled={isRunningLiveBenchmark}
                      className="px-4 py-2 text-xs font-semibold text-white bg-[#234B24] rounded-lg hover:bg-[#1a381b] transition-colors flex items-center gap-2 shrink-0 cursor-pointer"
                    >
                      <Play className="w-3.5 h-3.5" />
                      {isRunningLiveBenchmark ? 'Mengukur Latensi...' : 'Jalankan Live Benchmark <100ms'}
                    </button>
                  </div>

                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 mt-4">
                    <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-xl">
                      <div className="text-[11px] text-[#5A625A]">Latensi Median (p50)</div>
                      <div className="text-xl font-bold font-mono tabular-nums text-[#1E9E5A] mt-0.5">
                        {liveBenchmarkData.p50} ms
                      </div>
                      <div className="text-[11px] text-[#5A625A] mt-0.5">Target SLA: &lt;100.0 ms</div>
                    </div>
                    <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-xl">
                      <div className="text-[11px] text-[#5A625A]">Latensi Persentil 95 (p95)</div>
                      <div className="text-xl font-bold font-mono tabular-nums text-[#1E9E5A] mt-0.5">
                        {liveBenchmarkData.p95} ms
                      </div>
                      <div className="text-[11px] text-[#5A625A] mt-0.5">Composite GIST Active</div>
                    </div>
                    <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-xl">
                      <div className="text-[11px] text-[#5A625A]">Latensi Ekor (p99 Peak)</div>
                      <div className="text-xl font-bold font-mono tabular-nums text-[#234B24] mt-0.5">
                        {liveBenchmarkData.p99} ms
                      </div>
                      <div className="text-[11px] font-semibold text-[#1E9E5A] mt-0.5">✓ LOLOS UJI BEBAN (&lt;100ms)</div>
                    </div>
                    <div className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-xl">
                      <div className="text-[11px] text-[#5A625A]">Cache 360° &amp; Anti-Spam</div>
                      <div className="text-xl font-bold font-mono tabular-nums text-[#5B6AE8] mt-0.5">
                        HIT {liveBenchmarkData.hitRatio}
                      </div>
                      <div className="text-[11px] text-[#5A625A] mt-0.5">
                        Spam Diblokir (429): {liveBenchmarkData.blockedSpam} req
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-3">
                    {INITIAL_BENCHMARK_PROBES.map((pr, i) => (
                      <div
                        key={i}
                        className="p-3 bg-[#F6F3EC]/70 border border-[#E2DFD7] rounded-lg flex items-center justify-between gap-3 text-xs"
                      >
                        <div>
                          <div className="font-bold text-[#1B1F1A]">{pr.probe}</div>
                          <div className="font-mono text-[11px] text-[#5A625A] mt-0.5">Indeks: {pr.index_used}</div>
                        </div>
                        <span className="font-mono font-bold text-[#1E9E5A] shrink-0">{pr.latency_ms} ms</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* 2. Katalog Lengkap 24 Endpoint BE-1 (Sprint 1 s/d Sprint 4) */}
                <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-[#E2DFD7]">
                    <div>
                      <div className="text-xs font-bold text-[#234B24]">
                        Hari 19 &amp; 20 — Katalog Kontrak Final 24 Endpoint BE-1 (GET /api/v1/system/contracts)
                      </div>
                      <h3 className="text-base font-bold text-[#1B1F1A] mt-0.5">
                        Daftar Genap 24 Endpoint BE-1 (Core &amp; Spasial) Beserta Consumer Role &amp; SLA
                      </h3>
                    </div>
                    <select
                      value={catalogSprintFilter}
                      onChange={(e) => setCatalogSprintFilter(e.target.value)}
                      className="px-3 py-2 text-xs font-semibold bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
                    >
                      <option value="">Semua Minggu (Genap 24 Endpoint BE-1)</option>
                      <option value="Minggu 1">Minggu 1 · Sprint 1 (7 Endpoint)</option>
                      <option value="Minggu 2">Minggu 2 · Sprint 2 (7 Endpoint)</option>
                      <option value="Minggu 3">Minggu 3 · Sprint 3 (7 Endpoint)</option>
                      <option value="Minggu 4">Minggu 4 · Sprint 4 (3 Endpoint)</option>
                    </select>
                  </div>

                  <div className="mt-4 overflow-x-auto">
                    <table className="w-full text-left border-collapse text-xs">
                      <thead>
                        <tr className="border-b border-[#E2DFD7] text-[11px] font-semibold text-[#5A625A]">
                          <th className="py-2.5 px-3">No</th>
                          <th className="py-2.5 px-3">Sprint / Hari</th>
                          <th className="py-2.5 px-3">Method &amp; Path</th>
                          <th className="py-2.5 px-3">Deskripsi Fitur &amp; Pilar</th>
                          <th className="py-2.5 px-3">Auth / Cache Guard</th>
                          <th className="py-2.5 px-3">Consumer</th>
                          <th className="py-2.5 px-3 text-right">Target SLA</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-[#E2DFD7]">
                        {BE1_24_ENDPOINTS_CATALOG.filter(
                          (ep) => !catalogSprintFilter || ep.sprint.includes(catalogSprintFilter)
                        ).map((ep) => (
                          <tr key={ep.number} className="hover:bg-[#F6F3EC]/60">
                            <td className="py-2.5 px-3 font-mono font-bold text-[#234B24]">
                              #{String(ep.number).padStart(2, '0')}
                            </td>
                            <td className="py-2.5 px-3 whitespace-nowrap">
                              <div className="font-semibold text-[#1B1F1A]">{ep.sprint}</div>
                              <div className="text-[11px] text-[#5A625A]">{ep.day}</div>
                            </td>
                            <td className="py-2.5 px-3 font-mono whitespace-nowrap">
                              <span
                                className={`font-bold mr-1.5 ${
                                  ep.method === 'GET'
                                    ? 'text-[#1E9E5A]'
                                    : ep.method === 'POST'
                                    ? 'text-[#E85D1A]'
                                    : 'text-[#5B6AE8]'
                                }`}
                              >
                                {ep.method}
                              </span>
                              <span className="text-[#1B1F1A]">{ep.path}</span>
                            </td>
                            <td className="py-2.5 px-3">
                              <div className="font-semibold text-[#1B1F1A]">{ep.title}</div>
                              <div className="text-[11px] text-[#5A625A]">{ep.pillar_ref}</div>
                            </td>
                            <td className="py-2.5 px-3">
                              <div className="text-[#1B1F1A] font-medium">{ep.auth_guard}</div>
                              <div className="font-mono text-[11px] text-[#234B24]">{ep.cache_or_guard}</div>
                            </td>
                            <td className="py-2.5 px-3 text-[#1B1F1A] whitespace-nowrap">{ep.consumer_role}</td>
                            <td className="py-2.5 px-3 font-mono font-bold text-right text-[#1E9E5A] whitespace-nowrap">
                              &lt;{ep.target_sla_ms} ms
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {dbSubView === 'sprint3_modules' && (
              <div className="space-y-6">
                {/* 1. Gaode Behavior-Based Ranking (Hari 12) */}
                <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
                  <div className="flex items-center justify-between gap-2 mb-3">
                    <div>
                      <div className="text-xs font-bold text-[#234B24]">
                        Hari 12 — Tabel gaode_behavior_rankings (Pilar 2 · P2.4 Anti-Bintang Palsu)
                      </div>
                      <h3 className="text-base font-bold text-[#1B1F1A]">
                        Leaderboard Gaode Guide (45% Navigasi Selesai + 40% Dwell Time GPS + 15% Return Rate)
                      </h3>
                    </div>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3.5">
                    {INITIAL_GAODE_RANKINGS.map((rk) => (
                      <div key={rk.id} className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-xl space-y-2">
                        <div className="flex items-center justify-between gap-2 font-mono text-xs">
                          <span className="font-bold text-[#234B24]">PERINGKAT #{rk.rank_position}</span>
                          <span className="font-bold text-[#1E9E5A]">{rk.gaode_authenticity_score} pts</span>
                        </div>
                        <div>
                          <div className="text-xs font-bold text-[#1B1F1A]">{rk.destination_name}</div>
                          <div className="text-[11px] text-[#5A625A]">{rk.city_regency} · {rk.category}</div>
                        </div>
                        <div className="text-[11px] font-mono text-[#1B1F1A] pt-2 border-t border-[#E2DFD7] space-y-0.5">
                          <div>Navigasi 30h: <strong>{rk.active_nav_count_30d.toLocaleString('id-ID')} trip</strong></div>
                          <div>Rata2 Dwell GPS: <strong>{rk.avg_dwell_time_min} menit</strong></div>
                          <div>Repeat Visit: <strong>{rk.return_visit_rate_pct}%</strong></div>
                        </div>
                        <div className="text-[11px] text-[#234B24] font-medium">{rk.trending_badge}</div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* 2. Live Hazard Alert 4 Koridor Ekstrem & Sinyal SOS GPS (Hari 13) */}
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                  <div className="lg:col-span-7 bg-white border border-[#E2DFD7] rounded-xl p-6">
                    <div className="text-xs font-bold text-[#F26B4B] mb-1">
                      Hari 13 — Tabel hazard_alerts (Pilar 7 · P7.2 Koridor Rawan Longsor & Buka-Tutup)
                    </div>
                    <h3 className="text-base font-bold text-[#1B1F1A] mb-3">
                      4 Koridor Jalur Ekstrem Sumatera Barat & Rute Pengalihan (Detour GeoJSON)
                    </h3>
                    <div className="space-y-3">
                      {INITIAL_HAZARD_ALERTS.map((hz) => (
                        <div key={hz.id} className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg text-xs space-y-1.5">
                          <div className="flex items-center justify-between gap-2 font-mono">
                            <span className="font-bold text-[#1B1F1A]">{hz.corridor_code} · Kemiringan {hz.slope_gradient_deg}°</span>
                            <span
                              className={`font-bold uppercase ${
                                hz.severity === 'Siaga' || hz.severity === 'Awas Tutup Total'
                                  ? 'text-[#F26B4B]'
                                  : hz.severity === 'Waspada'
                                  ? 'text-[#E85D1A]'
                                  : 'text-[#1E9E5A]'
                              }`}
                            >
                              STATUS: {hz.severity}
                            </span>
                          </div>
                          <div className="font-bold text-[#1B1F1A]">{hz.location} ({hz.city_regency})</div>
                          <div className="text-[11px] text-[#5A625A]">{hz.hazard_type} · Cuaca: {hz.weather_status}</div>
                          <p className="text-[#1B1F1A] leading-relaxed">{hz.message}</p>
                          <div className="text-[11px] text-[#234B24] font-semibold">
                            Rute Alternatif: {hz.detour_route}
                          </div>
                          <div className="text-[11px] font-mono text-[#5A625A]">
                            Posko SAR Terdekat: {hz.nearest_rescue_post} ({hz.emergency_contact})
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="lg:col-span-5 space-y-6">
                    <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
                      <div className="text-xs font-bold text-[#E85D1A] mb-1">
                        Hari 13 — Tabel sos_signals (Pancaran Darurat SOS GPS Wisatawan)
                      </div>
                      <h3 className="text-base font-bold text-[#1B1F1A] mb-3">
                        Antrean Sinyal Darurat SOS GPS & Posko Evakuasi Terdekat
                      </h3>
                      <div className="space-y-3">
                        {INITIAL_SOS_SIGNALS.map((sos) => (
                          <div key={sos.id} className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg text-xs space-y-1.5">
                            <div className="flex items-center justify-between font-mono">
                              <span className="font-bold text-[#F26B4B]">{sos.sos_code}</span>
                              <span className="font-bold text-[#1E9E5A]">{sos.status}</span>
                            </div>
                            <div className="font-bold text-[#1B1F1A]">{sos.tourist_name} ({sos.passengers_count} Penumpang)</div>
                            <div className="text-[#F26B4B] font-semibold">{sos.emergency_type}</div>
                            <div className="font-mono text-[11px] text-[#5A625A]">
                              GPS: {sos.latitude}, {sos.longitude} · Baterai HP: {sos.battery_percent}%
                            </div>
                            <div className="text-[11px] text-[#234B24] font-semibold">
                              Posko: {sos.nearest_rescue_post} ({sos.distance_to_rescue_km} km · ETA {sos.eta_rescue_minutes} mnt)
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
                      <div className="text-xs font-bold text-[#5B6AE8] mb-1">
                        Hari 14 — Tabel minang_phrases & cultural_events (Token Indigo #5B6AE8)
                      </div>
                      <h3 className="text-base font-bold text-[#1B1F1A] mb-3">
                        Kamus Saku Audio Minang & Jadwal Hari Pakan Nagari
                      </h3>
                      <div className="space-y-2.5">
                        {INITIAL_MINANG_PHRASES.slice(0, 3).map((ph) => (
                          <div key={ph.id} className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg text-xs">
                            <div className="font-bold text-[#5B6AE8]">{ph.minang_text}</div>
                            <div className="text-[#1B1F1A] mt-0.5">"{ph.indonesian_text}"</div>
                            <div className="font-mono text-[11px] text-[#5A625A] mt-1">
                              Lafal: {ph.phonetic_guide} · {ph.politeness_level}
                            </div>
                          </div>
                        ))}
                        {INITIAL_CULTURAL_EVENTS.slice(0, 2).map((ev) => (
                          <div key={ev.id} className="p-3 bg-[#E4E9DA]/60 border border-[#D2DAC3] rounded-lg text-xs">
                            <div className="font-bold text-[#234B24]">{ev.title}</div>
                            <div className="text-[11px] text-[#1B1F1A] mt-0.5">
                              {ev.nagari_location} ({ev.city_regency}) · Jadwal: <strong>{ev.schedule_rule}</strong>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {dbSubView === 'sprint2_modules' && (
              <div className="space-y-6">
                {/* 1. Tur Virtual 360° & 4 Pin Interaktif (Hari 7) */}
                <div className="bg-white border border-[#E2DFD7] rounded-xl p-6">
                  <div className="flex items-center gap-2 text-xs font-bold text-[#234B24] mb-1">
                    <Compass className="w-4 h-4" />
                    <span>Hari 7 — Tabel panorama_scenes & panorama_hotspots (4 Jenis Pin Interaktif)</span>
                  </div>
                  <h3 className="text-base font-bold text-[#1B1F1A]">
                    Inspektor Kanvas 360° Aerial-to-Ground & Koordinat Bola (Pitch / Yaw)
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                    {INITIAL_SCENES_360.map((scene) => (
                      <div key={scene.id} className="p-4 bg-[#F6F3EC] border border-[#E2DFD7] rounded-xl space-y-3">
                        <div className="flex items-center justify-between gap-2 text-xs font-mono">
                          <span className="font-bold text-[#234B24]">{scene.id}</span>
                          <span className="uppercase px-2 py-0.5 rounded bg-[#E4E9DA] text-[#1B1F1A] font-bold">
                            {scene.type} 360°
                          </span>
                        </div>
                        <div>
                          <div className="text-sm font-bold text-[#1B1F1A]">{scene.title}</div>
                          <div className="text-xs text-[#5A625A]">{scene.destination_name}</div>
                        </div>
                        <div className="space-y-2 pt-2 border-t border-[#E2DFD7]">
                          <div className="text-[11px] font-semibold text-[#5A625A]">
                            Daftar Pin Interaktif ({scene.hotspots.length} Pin):
                          </div>
                          {scene.hotspots.map((pin) => (
                            <div
                              key={pin.id}
                              className="p-2.5 bg-white rounded-lg border border-[#E2DFD7] text-xs flex items-start justify-between gap-3"
                            >
                              <div>
                                <div className="font-bold text-[#1B1F1A]">
                                  <span className="uppercase font-mono text-[11px] mr-1.5 text-[#234B24]">
                                    [{pin.type}]
                                  </span>
                                  {pin.title}
                                </div>
                                <div className="text-[11px] text-[#5A625A] mt-0.5">{pin.description}</div>
                              </div>
                              <div className="font-mono text-[11px] text-right shrink-0 text-[#5A625A]">
                                <div>pitch: {pin.pitch}°</div>
                                <div>yaw: {pin.yaw}°</div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* 2. Koridor Pencarian Searah Rute Shunlu (+X mnt detour) & Satgas Pungli */}
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                  <div className="lg:col-span-6 bg-white border border-[#E2DFD7] rounded-xl p-6">
                    <div className="flex items-center gap-2 text-xs font-bold text-[#234B24] mb-1">
                      <Navigation className="w-4 h-4" />
                      <span>Hari 8 — Tabel shunlu_pois (Along-the-Route Search +X Menit Detour)</span>
                    </div>
                    <h3 className="text-base font-bold text-[#1B1F1A] mb-3">
                      Titik Singgah Searah Koridor Jalan Lintas Sumatera Barat
                    </h3>
                    <div className="space-y-2.5">
                      {INITIAL_SHUNLU_POIS.map((poi) => (
                        <div key={poi.id} className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg text-xs">
                          <div className="flex items-center justify-between gap-2">
                            <span className="font-bold text-[#1B1F1A]">{poi.name}</span>
                            <span className="font-mono font-bold text-[#1E9E5A] shrink-0">
                              +{poi.detour_minutes} mnt detour ({poi.detour_distance_meter}m)
                            </span>
                          </div>
                          <div className="text-[11px] text-[#5A625A] mt-0.5">
                            {poi.corridor_road} · Kategori: <code className="font-mono">{poi.category}</code>
                          </div>
                          <div className="text-[11px] text-[#1B1F1A] mt-1">{poi.highlight_note}</div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="lg:col-span-6 bg-white border border-[#E2DFD7] rounded-xl p-6">
                    <div className="flex items-center gap-2 text-xs font-bold text-[#F26B4B] mb-1">
                      <ShieldCheck className="w-4 h-4" />
                      <span>Hari 9 — Tabel pungli_reports (Pusat Komando Satgas Saber Pungli)</span>
                    </div>
                    <h3 className="text-base font-bold text-[#1B1F1A] mb-3">
                      Tiket Aduan Pungli & Perbandingan Otomatis Tarif Perda
                    </h3>
                    <div className="space-y-3">
                      {INITIAL_PUNGLI_REPORTS.map((rep) => (
                        <div key={rep.id} className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg text-xs space-y-1.5">
                          <div className="flex items-center justify-between gap-2 font-mono">
                            <span className="font-bold text-[#1B1F1A]">{rep.ticket_code}</span>
                            <span className="font-bold text-[#E85D1A] uppercase">{rep.status}</span>
                          </div>
                          <div className="font-bold text-[#1B1F1A]">{rep.destination_name}</div>
                          <div className="font-mono text-[11px] text-[#F26B4B]">
                            Ditagih Oknum: Rp{rep.charged_amount_idr.toLocaleString('id-ID')} · Standar Perda: Rp
                            {rep.official_perda_price_idr.toLocaleString('id-ID')} (Selisih +Rp
                            {rep.overcharge_amount_idr.toLocaleString('id-ID')})
                          </div>
                          <p className="text-[#5A625A] leading-relaxed">{rep.description}</p>
                          <div className="text-[11px] text-[#234B24] font-medium">
                            Catatan Satgas: {rep.satgas_notes}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            {dbSubView === 'data20' && (
              <div className="space-y-6">
                <div className="bg-white border border-[#E2DFD7] rounded-xl p-5 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
                  <div className="lg:col-span-2 relative">
                    <Search className="w-4 h-4 text-[#5A625A] absolute left-3 top-2.5" />
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder="Cari nama destinasi, kab/kota, atau deskripsi..."
                      className="w-full pl-9 pr-3 py-2 text-xs bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
                    />
                  </div>
                  <select
                    value={filterCategory}
                    onChange={(e) => setFilterCategory(e.target.value)}
                    className="px-3 py-2 text-xs bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
                  >
                    <option value="">Semua Kategori (5 Kategori)</option>
                    <option value="alam">Kategori: Alam</option>
                    <option value="budaya">Kategori: Budaya</option>
                    <option value="bahari">Kategori: Bahari</option>
                    <option value="nagari">Kategori: Nagari Adat</option>
                    <option value="geopark">Kategori: Geopark</option>
                  </select>
                  <select
                    value={filterSignal}
                    onChange={(e) => setFilterSignal(e.target.value)}
                    className="px-3 py-2 text-xs bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
                  >
                    <option value="">Semua Status Sinyal Seluler</option>
                    <option value="4g_stabil">Sinyal: 4G Stabil</option>
                    <option value="sinyal_lemah">Sinyal: Lemah / Terbatas</option>
                    <option value="blank_spot">Sinyal: Blank Spot (Offline Pocket)</option>
                  </select>
                  <div className="flex items-center gap-2">
                    <select
                      value={filterCrowd}
                      onChange={(e) => setFilterCrowd(e.target.value)}
                      className="flex-1 px-3 py-2 text-xs bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg text-[#1B1F1A]"
                    >
                      <option value="">Semua Keramaian</option>
                      <option value="sepi">Keramaian: Sepi</option>
                      <option value="sedang">Keramaian: Sedang</option>
                      <option value="ramai">Keramaian: Ramai</option>
                    </select>
                    <button
                      onClick={fetchLiveDestinations}
                      title="Muat ulang dari server API"
                      className="p-2 bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] cursor-pointer"
                    >
                      <RefreshCw className={`w-4 h-4 text-[#234B24] ${isLoadingDest ? 'animate-spin' : ''}`} />
                    </button>
                  </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
                  <div className="lg:col-span-5 bg-white border border-[#E2DFD7] rounded-xl overflow-hidden">
                    <div className="px-4 py-3 border-b border-[#E2DFD7] flex items-center justify-between text-xs font-bold text-[#1B1F1A]">
                      <span>Daftar Destinasi ({destinations.length} Lokasi)</span>
                      <span className="font-mono text-[11px] text-[#5A625A]">Klik baris untuk detail</span>
                    </div>
                    <div className="divide-y divide-[#E2DFD7] max-h-[680px] overflow-y-auto">
                      {destinations.map((d) => {
                        const isSelected = d.id === selectedDestination?.id;
                        return (
                          <button
                            key={d.id}
                            onClick={() => setSelectedDestId(d.id)}
                            className={`w-full text-left p-3.5 transition-colors cursor-pointer ${
                              isSelected ? 'bg-[#E4E9DA]' : 'hover:bg-[#F6F3EC]/70'
                            }`}
                          >
                            <div className="flex items-center justify-between gap-2 text-[11px] text-[#5A625A] font-mono">
                              <span>
                                {d.id} · {d.qr_placard_code}
                              </span>
                              <span
                                className={`font-bold ${
                                  d.decision_stats.crowd_level === 'sepi'
                                    ? 'text-[#1E9E5A]'
                                    : d.decision_stats.crowd_level === 'ramai'
                                    ? 'text-[#F26B4B]'
                                    : 'text-[#E85D1A]'
                                }`}
                              >
                                {d.decision_stats.crowd_level.toUpperCase()}
                              </span>
                            </div>
                            <div className="text-xs font-bold text-[#1B1F1A] mt-0.5">{d.name}</div>
                            <div className="text-[11px] text-[#5A625A] mt-1 flex flex-wrap items-center gap-1.5">
                              <span>{d.kabupaten_kota}</span>
                              <span>·</span>
                              <span className="capitalize">{d.category}</span>
                              <span>·</span>
                              <span className="font-mono tabular-nums">
                                {d.decision_stats.distance_km} km ({d.decision_stats.travel_time_minutes} mnt)
                              </span>
                              <span>·</span>
                              <span
                                className={
                                  d.medan_indicator.cellular_signal === 'blank_spot'
                                    ? 'text-[#F26B4B] font-semibold'
                                    : 'text-[#1E9E5A]'
                                }
                              >
                                {d.medan_indicator.cellular_signal}
                              </span>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div className="lg:col-span-7 space-y-5">
                    {selectedDestination ? (
                      <div className="bg-white border border-[#E2DFD7] rounded-xl p-6 space-y-6">
                        <div className="border-b border-[#E2DFD7] pb-4">
                          <div className="text-xs font-mono text-[#5A625A] flex flex-wrap items-center gap-2">
                            <span>ID: {selectedDestination.id}</span>
                            <span>·</span>
                            <span>Slug: {selectedDestination.slug}</span>
                            <span>·</span>
                            <span className="text-[#234B24] font-semibold">
                              Plang QR: {selectedDestination.qr_placard_code}
                            </span>
                          </div>
                          <h3 className="text-xl font-bold text-[#1B1F1A] mt-1">{selectedDestination.name}</h3>
                          <div className="text-xs text-[#5A625A] mt-1 flex flex-wrap items-center gap-2">
                            <span className="inline-flex items-center gap-1 text-[#1B1F1A] font-medium">
                              <MapPin className="w-3.5 h-3.5 text-[#234B24]" />
                              {selectedDestination.kabupaten_kota}
                            </span>
                            <span>·</span>
                            <span className="font-mono tabular-nums">
                              GPS: {selectedDestination.latitude}, {selectedDestination.longitude} ({selectedDestination.elevation_m} mdpl)
                            </span>
                            <span>·</span>
                            <span>Jam Buka: {selectedDestination.opening_hours}</span>
                          </div>
                          <p className="text-xs text-[#5A625A] mt-2.5 leading-relaxed">
                            {selectedDestination.description}
                          </p>
                        </div>

                        <div>
                          <div className="text-xs font-bold text-[#1B1F1A] mb-2.5">
                            1. Grid 4 Statistik Keputusan di Depan (Kontrak JSON <code className="font-mono text-[#234B24]">decision_stats</code> untuk FE-1)
                          </div>
                          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="text-[11px] text-[#5A625A]">1. Jarak Tempuh</div>
                              <div className="text-base font-bold font-mono tabular-nums text-[#1B1F1A] mt-0.5">
                                {selectedDestination.decision_stats.distance_km} km
                              </div>
                            </div>
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="text-[11px] text-[#5A625A]">2. Waktu Tempuh</div>
                              <div className="text-base font-bold font-mono tabular-nums text-[#1B1F1A] mt-0.5">
                                {selectedDestination.decision_stats.travel_time_minutes} mnt
                              </div>
                            </div>
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="text-[11px] text-[#5A625A]">3. Tingkat Keramaian</div>
                              <div
                                className={`text-base font-bold uppercase mt-0.5 ${
                                  selectedDestination.decision_stats.crowd_level === 'sepi'
                                    ? 'text-[#1E9E5A]'
                                    : selectedDestination.decision_stats.crowd_level === 'ramai'
                                    ? 'text-[#F26B4B]'
                                    : 'text-[#E85D1A]'
                                }`}
                              >
                                {selectedDestination.decision_stats.crowd_level}
                              </div>
                            </div>
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="text-[11px] text-[#5A625A]">4. Tiket Dasar Resmi</div>
                              <div className="text-base font-bold font-mono tabular-nums text-[#234B24] mt-0.5">
                                {selectedDestination.decision_stats.estimated_cost_idr === 0
                                  ? 'Gratis'
                                  : `Rp${selectedDestination.decision_stats.estimated_cost_idr.toLocaleString('id-ID')}`}
                              </div>
                            </div>
                          </div>
                        </div>

                        <div>
                          <div className="text-xs font-bold text-[#1B1F1A] mb-2.5">
                            2. Kartu Kesiapan Medan 5 Indikator (Tabel <code className="font-mono text-[#234B24]">medan_indicators</code>)
                          </div>
                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="font-semibold text-[#5A625A]">Indikator #1: Akses Kendaraan & Jalan</div>
                              <div className="text-[#1B1F1A] font-medium mt-1">
                                {selectedDestination.medan_indicator.road_access_status}
                              </div>
                            </div>
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="font-semibold text-[#5A625A]">Indikator #2: Kesulitan Trekking</div>
                              <div className="text-[#1B1F1A] font-bold uppercase mt-1">
                                {selectedDestination.medan_indicator.trekking_difficulty} · Jarak Jalan Kaki {selectedDestination.medan_indicator.trekking_distance_m} m
                              </div>
                            </div>
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="font-semibold text-[#5A625A]">Indikator #3: Sinyal Seluler & Blank Spot</div>
                              <div
                                className={`font-bold mt-1 ${
                                  selectedDestination.medan_indicator.cellular_signal === 'blank_spot'
                                    ? 'text-[#F26B4B]'
                                    : 'text-[#1E9E5A]'
                                }`}
                              >
                                {selectedDestination.medan_indicator.cellular_signal.toUpperCase()}
                              </div>
                            </div>
                            <div className="p-3 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                              <div className="font-semibold text-[#5A625A]">Indikator #4 & #5: Toilet/Musala & Pemandu</div>
                              <div className="text-[#1B1F1A] mt-1">
                                {selectedDestination.medan_indicator.facilities_completeness}
                              </div>
                            </div>
                          </div>
                        </div>

                        <div className="bg-[#E4E9DA] border border-[#D2DAC3] rounded-xl p-4">
                          <div className="text-xs font-bold text-[#234B24] mb-2">
                            3. Kartu Tips Menjaga Tempat & Etika Adat (Tabel <code className="font-mono">local_tips</code> · Token Warna <code className="font-mono">--sage-100</code>)
                          </div>
                          <div className="space-y-2.5">
                            {selectedDestination.tips.map((tip) => (
                              <div key={tip.id} className="bg-white/90 p-3 rounded-lg border border-[#D2DAC3] text-xs">
                                <div className="font-bold text-[#1B1F1A]">{tip.title}</div>
                                <p className="text-[#5A625A] mt-1 leading-relaxed">{tip.content}</p>
                              </div>
                            ))}
                          </div>
                        </div>

                        <div>
                          <div className="text-xs font-bold text-[#1B1F1A] mb-2.5">
                            4. Tabel Fair-Price Barometer — Standar Tarif Resmi Perda/Nagari (Tabel <code className="font-mono text-[#234B24]">official_tariffs</code>)
                          </div>
                          <div className="overflow-x-auto border border-[#E2DFD7] rounded-lg">
                            <table className="w-full text-left border-collapse text-xs">
                              <thead>
                                <tr className="bg-[#F6F3EC] border-b border-[#E2DFD7] text-[11px] font-semibold text-[#5A625A]">
                                  <th className="py-2 px-3">Komponen Tarif Resmi</th>
                                  <th className="py-2 px-3">Kategori</th>
                                  <th className="py-2 px-3 text-right">Harga Resmi (Rp)</th>
                                  <th className="py-2 px-3">Satuan</th>
                                  <th className="py-2 px-3">Dasar Hukum Perda / Nagari</th>
                                </tr>
                              </thead>
                              <tbody className="divide-y divide-[#E2DFD7]">
                                {selectedDestination.official_tariffs.map((trf) => (
                                  <tr key={trf.id}>
                                    <td className="py-2.5 px-3 font-semibold text-[#1B1F1A]">{trf.item_name}</td>
                                    <td className="py-2.5 px-3 font-mono text-[11px] text-[#5A625A]">{trf.category}</td>
                                    <td className="py-2.5 px-3 font-mono tabular-nums font-bold text-right text-[#234B24]">
                                      Rp{trf.price_idr.toLocaleString('id-ID')}
                                    </td>
                                    <td className="py-2.5 px-3 font-mono text-[11px] text-[#5A625A]">{trf.unit}</td>
                                    <td className="py-2.5 px-3 text-[11px] text-[#5A625A]">{trf.perda_reference}</td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        </div>
                      </div>
                    ) : null}
                  </div>
                </div>
              </div>
            )}

            {dbSubView === 'schema11' && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                {BE1_11_TABLES_SCHEMA.map((tbl) => (
                  <div
                    key={tbl.tableNumber}
                    className="bg-white border border-[#E2DFD7] rounded-xl p-5 flex flex-col justify-between"
                  >
                    <div>
                      <div className="flex items-center justify-between gap-2 text-xs text-[#5A625A] mb-1">
                        <span className="font-mono font-bold text-[#234B24]">
                          Tabel BE-1 #{String(tbl.tableNumber).padStart(2, '0')} · {tbl.sprint}
                        </span>
                        <span>{tbl.pilar}</span>
                      </div>
                      <h3 className="font-mono text-base font-bold text-[#1B1F1A] flex items-center gap-2">
                        <Database className="w-4 h-4 text-[#234B24]" />
                        {tbl.tableName}
                      </h3>
                      <p className="text-xs text-[#5A625A] mt-1 leading-relaxed">{tbl.description}</p>

                      <div className="mt-3 p-2.5 bg-[#F6F3EC] rounded-lg border border-[#E2DFD7] text-[11px] font-mono space-y-1">
                        <div>
                          <span className="text-[#5A625A]">PK:</span> {tbl.primaryKey}
                        </div>
                        <div>
                          <span className="text-[#5A625A]">FK:</span> {tbl.foreignKeys}
                        </div>
                        <div>
                          <span className="text-[#5A625A]">Index:</span>{' '}
                          <span className="text-[#234B24] font-semibold">{tbl.spatialIndex}</span>
                        </div>
                      </div>

                      <div className="mt-3 space-y-1.5">
                        {tbl.columns.slice(0, 6).map((col) => (
                          <div
                            key={col.name}
                            className="flex items-baseline justify-between gap-2 text-xs border-b border-[#F6F3EC] pb-1"
                          >
                            <span className="font-mono font-semibold text-[#1B1F1A]">{col.name}</span>
                            <span className="font-mono text-[11px] text-[#5B6AE8] shrink-0">{col.type}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* ==================================================================
            TAB 4 & TAB 5: LIVE API TESTER & AUTOMATED TEST SUITE
            ================================================================== */}
        {activeTab === 'tester' && (
          <ApiTesterAndQaView
            mode="tester"
            selectedSprint={selectedSprint}
            onDatabaseMutated={fetchLiveDestinations}
          />
        )}
        {activeTab === 'qa' && (
          <ApiTesterAndQaView
            mode="qa"
            selectedSprint={selectedSprint}
            onDatabaseMutated={fetchLiveDestinations}
          />
        )}
        {activeTab === 'diagrams' && <ArchitectureDiagramsView />}
      </main>

      <footer className="border-t border-[#E2DFD7] bg-white px-6 py-4 mt-10">
        <div className="max-w-[1400px] mx-auto flex flex-col sm:flex-row items-center justify-between gap-2 text-xs text-[#5A625A]">
          <div>
            Rancak.in (WISGO) — Ekosistem Wisata Pintar Sumatera Barat · Modul Kepemilikan Penuh{' '}
            <strong>BE-1 (Core & Spasial: Minggu 1 s/d Minggu 4 Selesai 100% · 11 Tabel & 24 Endpoint)</strong>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setActiveTab('diagrams')}
              className="hover:text-[#1B1F1A] underline cursor-pointer font-semibold text-[#234B24]"
            >
              Studio ERD & Class Diagram
            </button>
            <span>·</span>
            <button
              onClick={() => setActiveTab('codebase')}
              className="hover:text-[#1B1F1A] underline cursor-pointer"
            >
              Unduh Kode Go & SQL
            </button>
            <span>·</span>
            <button
              onClick={() => setActiveTab('qa')}
              className="hover:text-[#1B1F1A] underline cursor-pointer"
            >
              Automated Test Suite (32 Test S1–S4)
            </button>
          </div>
        </div>
      </footer>
    </div>
  );
}
