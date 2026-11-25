import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Search,
  MapPin,
  Car,
  Mountain,
  Receipt,
  Sparkles,
  Plus,
  RefreshCw,
  Edit3,
  Trash2,
  Eye,
  QrCode,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Clock,
  Navigation,
  AlertTriangle,
  X,
  Volume2,
  Calendar,
  TrendingUp,
  Compass,
  Inbox,
  MessageSquare,
  CloudSun,
  Building2,
  UserCheck,
} from 'lucide-react';
import {
  CrowdLevel,
  Destination,
  DestinationTip,
  MasterDestinationCategory,
} from '../types/contract';
import {
  MASTER_DESTINATION_CATEGORIES,
  SUMBAR_REGENCIES,
  categoryNameToId,
  getCategorySvgPath,
  normalizeDestinationCategory,
  toDestinationSlug,
} from '../data/mockDestinations';
import { ImageDropzone } from '../components/ImageDropzone';
import { MinangDictionarySubTab } from '../components/MinangDictionarySubTab';
import { CultureCalendarSubTab } from '../components/CultureCalendarSubTab';
import { GaodeRankingSubTab } from '../components/GaodeRankingSubTab';
import { UgcSubmissionsSubTab } from '../components/UgcSubmissionsSubTab';
import { TouristReviewsSubTab } from '../components/TouristReviewsSubTab';

interface DestinationsPageProps {
  destinations: Destination[];
  backendOnline: boolean;
  loading: boolean;
  onRefresh: () => void;
  onSaveDestination: (
    dest: Destination,
    toastMessage: string
  ) => Promise<void> | void;
  onDeleteDestination: (
    dest: Destination,
    toastMessage: string
  ) => Promise<void> | void;
  onOpenTariffManager: (destId: string) => void;
  onOpenSmartQRModal: (dest: Destination) => void;
  showToast?: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

type SortColumn = 'name' | 'city_regency' | 'distance' | 'price';
type SortDirection = 'ascending' | 'descending';
type EditorTabKey = 'A' | 'B' | 'C';

const collator = new Intl.Collator('id', {
  numeric: true,
  sensitivity: 'base',
});

export type DestinationsSubTab =
  | 'directory'
  | 'minang_dictionary'
  | 'culture_calendar'
  | 'gaode_ranking'
  | 'ugc_submissions'
  | 'reviews_moderation';

export const DestinationsPage: React.FC<DestinationsPageProps> = ({
  destinations,
  loading,
  onRefresh,
  onSaveDestination,
  onDeleteDestination,
  onOpenTariffManager,
  onOpenSmartQRModal,
  showToast = () => { },
}) => {
  const [activeSubTab, setActiveSubTab] = useState<DestinationsSubTab>('directory');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRegency, setSelectedRegency] = useState<string>('Semua Kab/Kota');
  const [selectedCategory, setSelectedCategory] = useState<string>('Semua Kategori');
  const [selectedCrowd, setSelectedCrowd] = useState<string>('Semua');

  const [sortCol, setSortCol] = useState<SortColumn>('name');
  const [sortDir, setSortDir] = useState<SortDirection>('ascending');
  const [sortAnnouncement, setSortAnnouncement] = useState<string>('');

  const [editingDest, setEditingDest] = useState<Destination | null>(null);
  const [isNewDest, setIsNewDest] = useState<boolean>(false);
  const [editorTab, setEditorTab] = useState<EditorTabKey>('A');
  const [viewingDest, setViewingDest] = useState<Destination | null>(null);
  const [deletingDest, setDeletingDest] = useState<Destination | null>(null);

  const editorDialogRef = useRef<HTMLDialogElement>(null);
  const detailDialogRef = useRef<HTMLDialogElement>(null);
  const deleteDialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = editorDialogRef.current;
    if (!dialog) return;
    if (editingDest && !dialog.open) dialog.showModal();
    else if (!editingDest && dialog.open) dialog.close();
  }, [editingDest]);

  useEffect(() => {
    const dialog = detailDialogRef.current;
    if (!dialog) return;
    if (viewingDest && !dialog.open) dialog.showModal();
    else if (!viewingDest && dialog.open) dialog.close();
  }, [viewingDest]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (deletingDest && !dialog.open) dialog.showModal();
    else if (!deletingDest && dialog.open) dialog.close();
  }, [deletingDest]);

  const handleSortClick = (col: SortColumn, label: string) => {
    let nextDir: SortDirection = 'ascending';
    if (sortCol === col) {
      nextDir = sortDir === 'ascending' ? 'descending' : 'ascending';
    }
    setSortCol(col);
    setSortDir(nextDir);
    setSortAnnouncement(
      `Tabel diurutkan berdasarkan ${label} secara ${nextDir === 'ascending' ? 'menaik' : 'menurun'
      }.`
    );
  };

  const filteredAndSortedDestinations = useMemo(() => {
    const filtered = destinations.filter((item) => {
      const q = searchQuery.trim().toLowerCase();
      const matchesSearch =
        !q ||
        item.name.toLowerCase().includes(q) ||
        (item.category || '').toLowerCase().includes(q) ||
        item.city_regency.toLowerCase().includes(q) ||
        item.description.toLowerCase().includes(q) ||
        item.tariffs?.some(
          (t) =>
            t.item_name.toLowerCase().includes(q) ||
            t.regulation_ref.toLowerCase().includes(q)
        );

      const matchesRegency =
        selectedRegency === 'Semua Kab/Kota' || item.city_regency === selectedRegency;

      const matchesCategory =
        selectedCategory === 'Semua Kategori' || item.category === selectedCategory;

      const matchesCrowd =
        selectedCrowd === 'Semua' || item.crowd_level === selectedCrowd;

      return matchesSearch && matchesRegency && matchesCategory && matchesCrowd;
    });

    const factor = sortDir === 'ascending' ? 1 : -1;
    return [...filtered].sort((a, b) => {
      if (sortCol === 'name') return factor * collator.compare(a.name, b.name);
      if (sortCol === 'city_regency') return factor * collator.compare(a.city_regency, b.city_regency);
      if (sortCol === 'distance') return factor * ((a.distance_km ?? 0) - (b.distance_km ?? 0));
      if (sortCol === 'price') {
        const priceA = a.tariffs?.[0]?.price ?? a.estimated_cost ?? 0;
        const priceB = b.tariffs?.[0]?.price ?? b.estimated_cost ?? 0;
        return factor * (priceA - priceB);
      }
      return 0;
    });
  }, [destinations, searchQuery, selectedRegency, selectedCategory, selectedCrowd, sortCol, sortDir]);

  const stats = useMemo(() => {
    const total = destinations.length;
    const weatherSafe = destinations.filter(
      (d) => (d.weather_status || d.weather?.weather_status || 'Aman') === 'Aman'
    ).length;
    const weatherAlert = total - weatherSafe;
    const uniqueRegencies = new Set(destinations.map((d) => d.city_regency)).size;
    const totalTariffItems = destinations.reduce(
      (acc, d) => acc + (d.tariffs?.length || 0),
      0
    );
    return { total, weatherSafe, weatherAlert, uniqueRegencies, totalTariffItems };
  }, [destinations]);

  const formatRupiah = (amount: number) => {
    if (amount === 0) return 'Gratis (Rp 0)';
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const formatDuration = (minutes?: number) => {
    if (!minutes) return '± 45 menit';
    const hrs = Math.floor(minutes / 60);
    const mins = minutes % 60;
    if (hrs === 0) return `${mins} menit`;
    if (mins === 0) return `${hrs} jam`;
    return `${hrs}j ${mins}m`;
  };

  const renderCrowdBadge = (level: CrowdLevel | string) => {
    if (level === 'Sepi') {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#1E9E5A] text-white">
          <span className="w-1.5 h-1.5 rounded-full bg-white" />
          Sepi
        </span>
      );
    }
    if (level === 'Ramai') {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#F26B4B] text-white">
          <span className="w-1.5 h-1.5 rounded-full bg-white" />
          Ramai
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#E4E9DA] text-[#1B1F1A] border border-[#234B24]/25">
        <span className="w-1.5 h-1.5 rounded-full bg-[#234B24]" />
        Sedang
      </span>
    );
  };

  const renderWeatherBadge = (dest: Destination) => {
    const status = dest.weather_status || dest.weather?.weather_status || 'Aman';
    const temp = dest.weather?.temperature_c ?? 26;
    const cond = dest.weather?.condition || 'Cerah Berawan';
    const isWarn = status !== 'Aman';
    return (
      <span
        className={`inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full ${isWarn
            ? 'bg-amber-100 text-amber-800 border border-amber-300'
            : 'bg-sky-50 text-sky-800 border border-sky-200'
          }`}
      >
        <CloudSun className="w-3 h-3 shrink-0" aria-hidden="true" />
        <span>
          {temp}°C · {cond}
        </span>
      </span>
    );
  };

  const renderSortIcon = (col: SortColumn) => {
    if (sortCol !== col) {
      return <ArrowUpDown className="w-3.5 h-3.5 opacity-60 shrink-0" aria-hidden="true" />;
    }
    return sortDir === 'ascending' ? (
      <ArrowUp className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" aria-hidden="true" />
    ) : (
      <ArrowDown className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" aria-hidden="true" />
    );
  };

  const handleOpenNewModal = () => {
    const newId = `dest-${String(destinations.length + 1).padStart(3, '0')}`;
    setIsNewDest(true);
    setEditorTab('A');
    setEditingDest({
      id: newId,
      slug: '',
      name: '',
      category_id: 'cat-alam-geopark',
      category: 'Alam & Geopark',
      city_regency: 'Kota Bukittinggi',
      description: '',
      latitude: -0.3056,
      longitude: 100.3692,
      elevation_m: 930,
      cover_image:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
      crowd_level: 'Sepi',
      distance_km: 45,
      travel_time_min: 75,
      estimated_cost: 15000,
      ticket_price_summary: 'Rp 15.000 / orang',
      is_hidden_gem: false,
      qr_placard_code: `WISGO-${newId.toUpperCase()}`,
      opening_hours: '08:00 - 18:00 WIB',
      weather_status: 'Aman',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      medan_indicator: {
        id: `med-${newId}`,
        destination_id: newId,
        vehicle_access: 'Mobil OK',
        trekking_level: 'Mudah (Datar)',
        facilities: 'Toilet, Musala & Parkir Lengkap',
        guide_need: 'Mandiri',
        terrain_note: 'Akses jalan beraspal baik, ramah keluarga, mobil pribadi, dan bus pariwisata.',
        readiness_notes: 'Akses jalan beraspal baik, ramah keluarga, mobil pribadi, dan bus pariwisata.',
      },
      tariffs: [
        {
          id: `trf-${newId}-1`,
          destination_id: newId,
          category_id: 'cat-trf-tiket',
          item_name: 'Tiket Masuk Kawasan Dewasa',
          category: 'Tiket Masuk',
          price: 15000,
          fair_price_min: 15000,
          fair_price_max: 15000,
          unit: 'per orang',
          regulation_ref: 'Perda Kab/Kota Tahun 2024',
        },
      ],
      tips: [
        {
          id: `tip-${newId}-1`,
          destination_id: newId,
          category_id: 'cat-rule-lingkungan',
          title: 'Tips Menjaga Tempat Ini',
          content:
            'Patuhi etika adat basandi syarak, syarak basandi Kitabullah dan bawa kembali sampah pribadi.',
          is_important: true,
        },
      ],
    });
  };

  const handleOpenEditModal = (dest: Destination) => {
    setIsNewDest(false);
    setEditorTab('A');
    const normalizedCat = normalizeDestinationCategory(dest.category);
    const rules = dest.tips && dest.tips.length > 0 ? dest.tips : dest.aturan_destinasi || [];
    setEditingDest({
      ...dest,
      category: normalizedCat,
      category_id: categoryNameToId(normalizedCat),
      slug: dest.slug || toDestinationSlug(dest.name),
      distance_km: dest.distance_km ?? 30,
      travel_time_min: dest.travel_time_min ?? 60,
      estimated_cost: dest.estimated_cost ?? dest.tariffs?.[0]?.price ?? 15000,
      ticket_price_summary:
        dest.ticket_price_summary ||
        (dest.tariffs?.[0]
          ? `${formatRupiah(dest.tariffs[0].price)} / ${dest.tariffs[0].unit.replace('per ', '')}`
          : formatRupiah(dest.estimated_cost ?? 0)),
      medan_indicator: {
        id: dest.medan_indicator?.id || `med-${dest.id}`,
        destination_id: dest.id,
        vehicle_access: dest.medan_indicator?.vehicle_access || 'Mobil OK',
        trekking_level: dest.medan_indicator?.trekking_level || 'Mudah (Datar)',
        facilities: dest.medan_indicator?.facilities || 'Toilet, Musala & Parkir Lengkap',
        guide_need: dest.medan_indicator?.guide_need || 'Mandiri',
        terrain_note:
          dest.medan_indicator?.terrain_note ||
          dest.medan_indicator?.readiness_notes ||
          'Kondisi jalur terpantau aman dan siap dikunjungi wisatawan.',
        readiness_notes:
          dest.medan_indicator?.readiness_notes ||
          dest.medan_indicator?.terrain_note ||
          'Kondisi jalur terpantau aman dan siap dikunjungi wisatawan.',
      },
      tips:
        rules.length > 0
          ? rules
          : [
            {
              id: `tip-${dest.id}-1`,
              destination_id: dest.id,
              category_id: 'cat-rule-lingkungan',
              title: 'Tips Menjaga Tempat Ini',
              content: 'Jaga kebersihan lingkungan wisata dan hormati adat istiadat Nagari.',
              is_important: true,
            },
          ],
    });
  };

  const handleSaveEditorForm = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingDest) return;
    if (!editingDest.name.trim()) {
      setEditorTab('A');
      return;
    }

    const cat = normalizeDestinationCategory(editingDest.category);
    const finalDest: Destination = {
      ...editingDest,
      category: cat,
      category_id: categoryNameToId(cat),
      slug: editingDest.slug || toDestinationSlug(editingDest.name),
      aturan_destinasi: editingDest.tips,
      updated_at: new Date().toISOString(),
    };

    await onSaveDestination(
      finalDest,
      isNewDest
        ? `Destinasi baru "${finalDest.name}" (${finalDest.city_regency}) berhasil ditambahkan dan disinkronkan.`
        : `Perubahan destinasi "${finalDest.name}", 4 Indikator Medan, dan Tips Menjaga Tempat berhasil disimpan.`
    );
    setEditingDest(null);
  };

  const handleAddTipRow = () => {
    if (!editingDest) return;
    const currentTips = editingDest.tips || [];
    const newTip: DestinationTip = {
      id: `tip-${editingDest.id}-${Date.now()}`,
      destination_id: editingDest.id,
      category_id: 'cat-rule-lingkungan',
      title: 'Tips Menjaga Tempat Ini',
      content: '',
      is_important: false,
    };
    setEditingDest({ ...editingDest, tips: [...currentTips, newTip] });
  };

  const handleUpdateTipRow = (tipId: string, patch: Partial<DestinationTip>) => {
    if (!editingDest) return;
    const updated = (editingDest.tips || []).map((t) =>
      t.id === tipId ? { ...t, ...patch } : t
    );
    setEditingDest({ ...editingDest, tips: updated });
  };

  const handleRemoveTipRow = (tipId: string) => {
    if (!editingDest) return;
    const updated = (editingDest.tips || []).filter((t) => t.id !== tipId);
    setEditingDest({ ...editingDest, tips: updated });
  };

  return (
    <div className="p-6 lg:p-8 space-y-6 no-print">
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A] tracking-tight">
            Manajemen Destinasi Wisata &amp; Kesiapan Medan
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            5 Master Kategori, 4 Indikator Medan, Pantauan Cuaca Open-Meteo, Kamus Minang, Kalender Budaya, dan Gaode Ranking.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          <button
            type="button"
            onClick={onRefresh}
            disabled={loading}
            className="min-h-[40px] px-3.5 py-2 rounded-xl bg-white border border-[#234B24]/15 hover:bg-[#F6F3EC] text-[#1B1F1A] font-bold text-xs flex items-center gap-2 transition duration-200 shadow-2xs"
          >
            <RefreshCw
              className={`w-3.5 h-3.5 text-[#234B24] ${loading ? 'animate-spin' : ''}`}
              aria-hidden="true"
            />
            <span>Sinkronisasi Data</span>
          </button>

          {activeSubTab === 'directory' && (
            <button
              type="button"
              onClick={handleOpenNewModal}
              className="min-h-[40px] px-4 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center gap-2 shadow-xs transition duration-200"
            >
              <Plus className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
              <span>Tambah Destinasi</span>
            </button>
          )}
        </div>
      </header>

      <nav
        aria-label="Sub-tab Destinasi"
        className="flex overflow-x-auto no-scrollbar whitespace-nowrap shrink-0 gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-2xs"
      >
        {(
          [
            { key: 'directory', label: 'Direktori Destinasi', icon: <Compass className="w-3.5 h-3.5" />, count: destinations.length },
            { key: 'minang_dictionary', label: 'Kamus Audio Minang', icon: <Volume2 className="w-3.5 h-3.5" /> },
            { key: 'culture_calendar', label: 'Kalender Budaya', icon: <Calendar className="w-3.5 h-3.5" /> },
            { key: 'gaode_ranking', label: 'Gaode Ranking', icon: <TrendingUp className="w-3.5 h-3.5" /> },
            { key: 'ugc_submissions', label: 'Usulan Destinasi', icon: <Inbox className="w-3.5 h-3.5 text-[#F26B4B]" /> },
            { key: 'reviews_moderation', label: 'Ulasan & Kondisi Lapangan', icon: <MessageSquare className="w-3.5 h-3.5" /> },
          ] as const
        ).map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => setActiveSubTab(tab.key)}
            className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeSubTab === tab.key
                ? 'bg-[#234B24] text-white shadow-xs'
                : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
              }`}
          >
            {tab.icon}
            <span>{tab.label}</span>
            {'count' in tab && (
              <span
                className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold ${activeSubTab === tab.key
                    ? 'bg-white/20 text-white'
                    : 'bg-[#234B24]/10 text-[#234B24]'
                  }`}
              >
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </nav>

      {activeSubTab === 'directory' && (
        <>
          <section
            aria-label="Ringkasan Statistik Destinasi Sumatera Barat"
            className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4"
          >
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
              <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
                Destinasi Terdaftar
              </div>
              <div className="mt-2 flex items-baseline justify-between">
                <span className="text-2xl sm:text-3xl font-extrabold text-[#234B24]">
                  {stats.total}
                </span>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
                  5 Master Kategori
                </span>
              </div>
              <p className="mt-1 text-xs text-[#4A5248]">
                Mencakup {stats.uniqueRegencies} Kabupaten/Kota Sumatera Barat
              </p>
            </div>

            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
              <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
                Pantauan Cuaca Live
              </div>
              <div className="mt-2 flex items-baseline justify-between">
                <span className="text-2xl sm:text-3xl font-extrabold text-[#0284C7]">
                  {stats.weatherSafe} Aman
                </span>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-sky-100 text-sky-800">
                  Open-Meteo Live
                </span>
              </div>
              <p className="mt-1 text-xs text-[#4A5248]">
                {stats.weatherAlert > 0
                  ? `${stats.weatherAlert} lokasi berstatus Waspada Hujan / Siaga`
                  : 'Seluruh kawasan wisata terpantau cerah berawan'}
              </p>
            </div>

            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
              <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
                Komponen Tarif Resmi Perda
              </div>
              <div className="mt-2 flex items-baseline justify-between">
                <span className="text-2xl sm:text-3xl font-extrabold text-[#1B1F1A]">
                  {stats.totalTariffItems}
                </span>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
                  Fair-Price Barometer
                </span>
              </div>
              <p className="mt-1 text-xs text-[#4A5248]">
                Tercetak pada Plang Smart QR di tiap gerbang kawasan
              </p>
            </div>

            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
              <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
                Pemetaan Kesiapan Medan
              </div>
              <div className="mt-2 flex items-baseline justify-between">
                <span className="text-2xl sm:text-3xl font-extrabold text-[#234B24]">
                  4 Indikator
                </span>
                <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-[#234B24] text-[#F6F3EC]">
                  Standar Lapangan
                </span>
              </div>
              <p className="mt-1 text-xs text-[#4A5248]">
                Kendaraan, Trekking, Fasilitas &amp; Pemandu Lokal
              </p>
            </div>
          </section>

          <search
            aria-label="Pencarian dan Penyaringan Direktori Destinasi"
            className="bg-white p-5 lg:p-6 rounded-2xl border border-[#234B24]/10 shadow-sm"
          >
            <form
              method="get"
              action="/destinations"
              onSubmit={(e) => e.preventDefault()}
              className="flex flex-col lg:flex-row lg:items-end gap-3.5"
            >
              <div className="flex-1 min-w-[220px] flex flex-col items-start gap-1.5">
                <label
                  htmlFor="search-destination"
                  className="text-xs font-bold text-[#1B1F1A]"
                >
                  Cari Destinasi, Kategori, atau Regulasi Perda
                </label>
                <div className="relative w-full">
                  <Search
                    className="w-4 h-4 text-[#4A5248] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none"
                    aria-hidden="true"
                  />
                  <input
                    id="search-destination"
                    name="q"
                    type="search"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Ketik nama destinasi, kabupaten, atau nomor Perda..."
                    className="w-full min-h-[48px] pl-10 pr-4 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] text-sm text-[#1B1F1A] font-medium"
                  />
                </div>
              </div>

              <div className="w-full sm:w-52 shrink-0 flex flex-col items-start gap-1.5">
                <label htmlFor="filter-regency" className="text-xs font-bold text-[#1B1F1A]">
                  Wilayah Kab/Kota
                </label>
                <select
                  id="filter-regency"
                  value={selectedRegency}
                  onChange={(e) => setSelectedRegency(e.target.value)}
                  className="w-full min-h-[48px] px-3.5 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  {SUMBAR_REGENCIES.map((reg) => (
                    <option key={reg} value={reg}>
                      {reg}
                    </option>
                  ))}
                </select>
              </div>

              <div className="w-full sm:w-48 shrink-0 flex flex-col items-start gap-1.5">
                <label htmlFor="filter-category" className="text-xs font-bold text-[#1B1F1A]">
                  5 Master Kategori
                </label>
                <select
                  id="filter-category"
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="w-full min-h-[48px] px-3.5 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="Semua Kategori">Semua Kategori</option>
                  {MASTER_DESTINATION_CATEGORIES.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat}
                    </option>
                  ))}
                </select>
              </div>

              <div className="shrink-0 flex flex-col items-start gap-1.5">
                <span className="text-xs font-bold text-[#1B1F1A]">Keramaian</span>
                <div className="flex items-center gap-1 bg-[#F6F3EC] p-1 rounded-2xl border border-[#CFD8BE] min-h-[48px]">
                  {(['Semua', 'Sepi', 'Sedang', 'Ramai'] as const).map((lvl) => (
                    <button
                      key={lvl}
                      type="button"
                      onClick={() => setSelectedCrowd(lvl)}
                      className={`shrink-0 whitespace-nowrap py-2 px-3 rounded-xl text-xs font-bold transition min-h-[40px] ${selectedCrowd === lvl
                          ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
                          : 'text-[#1B1F1A] hover:bg-[#E4E9DA]/60'
                        }`}
                    >
                      {lvl}
                    </button>
                  ))}
                </div>
              </div>
            </form>

            <div
              role="status"
              aria-live="polite"
              className="mt-3.5 pt-3.5 border-t border-[#234B24]/10 flex flex-wrap items-center justify-between gap-2 text-xs text-[#4A5248]"
            >
              <span>
                Menampilkan{' '}
                <strong className="text-[#1B1F1A]">{filteredAndSortedDestinations.length}</strong>{' '}
                dari <strong>{destinations.length}</strong> destinasi terdaftar
              </span>

              {(searchQuery ||
                selectedRegency !== 'Semua Kab/Kota' ||
                selectedCategory !== 'Semua Kategori' ||
                selectedCrowd !== 'Semua') && (
                  <button
                    type="button"
                    onClick={() => {
                      setSearchQuery('');
                      setSelectedRegency('Semua Kab/Kota');
                      setSelectedCategory('Semua Kategori');
                      setSelectedCrowd('Semua');
                    }}
                    className="text-xs font-bold text-[#F26B4B] hover:underline"
                  >
                    Atur Ulang Semua Filter
                  </button>
                )}
            </div>
          </search>

          <div role="status" aria-live="polite" className="visually-hidden">
            {sortAnnouncement}
          </div>

          <div
            tabIndex={0}
            role="region"
            aria-labelledby="destinations-table-caption"
            className="table-wrapper bg-white rounded-2xl border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] overflow-hidden"
          >
            <table className="wisgo-table text-left text-sm">
              <caption
                id="destinations-table-caption"
                className="p-4 lg:px-6 text-left font-bold text-xs uppercase tracking-wider text-[#234B24] bg-[#F6F3EC]/70 border-b border-[#234B24]/8"
              >
                Direktori Resmi Destinasi Wisata Sumatera Barat — Sinkron 5 Master Kategori &amp; 4 Indikator Medan
              </caption>
              <thead className="bg-[#F6F3EC]/90 text-[#234B24] text-[11px] font-extrabold uppercase tracking-wider border-b border-[#234B24]/10">
                <tr>
                  <th scope="col" aria-sort={sortCol === 'name' ? sortDir : undefined}>
                    <button
                      type="button"
                      onClick={() => handleSortClick('name', 'Nama Destinasi')}
                    >
                      <span>Destinasi Wisata &amp; Cuaca</span>
                      {renderSortIcon('name')}
                    </button>
                  </th>
                  <th scope="col" aria-sort={sortCol === 'city_regency' ? sortDir : undefined}>
                    <button
                      type="button"
                      onClick={() => handleSortClick('city_regency', 'Wilayah Kabupaten/Kota')}
                    >
                      <span>Wilayah &amp; Kategori</span>
                      {renderSortIcon('city_regency')}
                    </button>
                  </th>
                  <th scope="col" aria-sort={sortCol === 'distance' ? sortDir : undefined}>
                    <button
                      type="button"
                      onClick={() => handleSortClick('distance', '4 Statistik Keputusan')}
                    >
                      <span>4 Statistik Keputusan</span>
                      {renderSortIcon('distance')}
                    </button>
                  </th>
                  <th scope="col" className="py-3.5 px-4 font-bold">
                    4 Indikator Kesiapan Medan
                  </th>
                  <th scope="col" aria-sort={sortCol === 'price' ? sortDir : undefined}>
                    <button
                      type="button"
                      onClick={() => handleSortClick('price', 'Standar Tarif Resmi Perda')}
                    >
                      <span>Standar Tarif Perda</span>
                      {renderSortIcon('price')}
                    </button>
                  </th>
                  <th scope="col" className="py-3.5 px-4 font-bold">
                    Tips Menjaga Tempat
                  </th>
                  <th scope="col" className="py-3.5 px-5 font-bold text-right">
                    Tindakan Pengelolaan
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E4E9DA]">
                {filteredAndSortedDestinations.map((dest) => {
                  const medan = dest.medan_indicator;
                  const primaryTariff = dest.tariffs?.[0];
                  const primaryTip = dest.tips?.[0] || dest.aturan_destinasi?.[0];

                  return (
                    <tr key={dest.id} className="hover:bg-[#FAF8F3] transition-colors align-top">
                      <th
                        scope="row"
                        className="py-5 px-5 font-bold text-[#1B1F1A] min-w-[260px] border-r border-[#234B24]/10/60"
                      >
                        <div className="flex items-start gap-3.5">
                          <img
                            src={dest.cover_image}
                            alt=""
                            loading="lazy"
                            className="w-16 h-16 rounded-2xl object-cover shrink-0 bg-[#E4E9DA] shadow-sm"
                          />
                          <div className="min-w-0 space-y-1">
                            <div className="flex flex-wrap items-center gap-1.5">
                              <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded bg-[#E4E9DA] text-[#234B24]">
                                {dest.id.toUpperCase()}
                              </span>
                              {dest.is_hidden_gem && (
                                <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-purple-100 text-purple-800">
                                  Hidden Gem
                                </span>
                              )}
                            </div>
                            <div className="text-sm font-extrabold text-[#1B1F1A] leading-snug">
                              {dest.name}
                            </div>
                            <div className="flex flex-wrap items-center gap-1.5">
                              {renderWeatherBadge(dest)}
                            </div>
                          </div>
                        </div>
                      </th>

                      <td className="py-5 px-4 min-w-[185px]">
                        <div className="inline-flex items-center gap-1.5 text-xs font-extrabold text-[#234B24]">
                          <MapPin className="w-3.5 h-3.5 shrink-0 text-[#F26B4B]" aria-hidden="true" />
                          <span>{dest.city_regency}</span>
                        </div>
                        <div className="mt-1.5 flex items-center gap-1.5">
                          <img
                            src={getCategorySvgPath(dest.category)}
                            alt=""
                            className="w-5 h-5 shrink-0"
                          />
                          <span className="inline-block text-xs font-semibold px-2.5 py-0.5 rounded-full bg-[#F6F3EC] border border-[#CFD8BE] text-[#1B1F1A]">
                            {dest.category}
                          </span>
                        </div>
                      </td>

                      <td className="py-5 px-4 min-w-[205px]" data-value={dest.distance_km ?? 0}>
                        <div className="mb-2">{renderCrowdBadge(dest.crowd_level)}</div>
                        <div className="space-y-1 text-xs text-[#4A5248]">
                          <div className="flex items-center gap-1.5">
                            <Navigation className="w-3.5 h-3.5 text-[#234B24]" aria-hidden="true" />
                            <span>
                              Jarak: <strong className="text-[#1B1F1A]">{dest.distance_km} km</strong>
                            </span>
                          </div>
                          <div className="flex items-center gap-1.5">
                            <Clock className="w-3.5 h-3.5 text-[#E85D1A]" aria-hidden="true" />
                            <span>
                              Tempuh:{' '}
                              <strong className="text-[#1B1F1A]">
                                {formatDuration(dest.travel_time_min)}
                              </strong>
                            </span>
                          </div>
                          <div className="text-[11px] font-bold text-[#234B24]">
                            Estimasi: {dest.ticket_price_summary || formatRupiah(dest.estimated_cost)}
                          </div>
                        </div>
                      </td>

                      <td className="py-5 px-4 min-w-[250px]">
                        {medan ? (
                          <div className="flex flex-wrap gap-1.5 text-[11px]">
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#F6F3EC] border border-[#CFD8BE] font-semibold text-[#1B1F1A]">
                              <Car className="w-3 h-3 text-[#234B24]" aria-hidden="true" />
                              {medan.vehicle_access}
                            </span>
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#F6F3EC] border border-[#CFD8BE] font-semibold text-[#1B1F1A]">
                              <Mountain className="w-3 h-3 text-[#E85D1A]" aria-hidden="true" />
                              {medan.trekking_level}
                            </span>
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#F6F3EC] text-[#4A5248] font-medium">
                              <Building2 className="w-3 h-3 text-[#234B24]" aria-hidden="true" />
                              {medan.facilities}
                            </span>
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#E4E9DA] text-[#234B24] font-bold">
                              <UserCheck className="w-3 h-3" aria-hidden="true" />
                              {medan.guide_need}
                            </span>
                          </div>
                        ) : (
                          <span className="text-xs text-[#4A5248]">Belum ditetapkan</span>
                        )}
                      </td>

                      <td
                        className="py-5 px-4 min-w-[215px]"
                        data-value={primaryTariff?.price ?? dest.estimated_cost ?? 0}
                      >
                        {primaryTariff ? (
                          <div>
                            <div className="flex items-center gap-1 text-xs font-extrabold text-[#234B24]">
                              <Receipt className="w-3.5 h-3.5 text-[#E85D1A]" aria-hidden="true" />
                              <span>{formatRupiah(primaryTariff.price)}</span>
                              <span className="font-normal text-[#4A5248]">
                                / {primaryTariff.unit.replace('per ', '')}
                              </span>
                            </div>
                            <div className="text-xs font-semibold text-[#1B1F1A] mt-0.5">
                              {primaryTariff.item_name}
                            </div>
                            <div className="text-[11px] text-[#4A5248] mt-0.5">
                              {primaryTariff.regulation_ref}
                            </div>
                            {(dest.tariffs?.length || 0) > 1 && (
                              <span className="inline-block mt-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                                +{(dest.tariffs?.length || 1) - 1} komponen tarif lainnya
                              </span>
                            )}
                          </div>
                        ) : (
                          <div className="text-xs font-bold text-[#234B24]">
                            {dest.ticket_price_summary || formatRupiah(dest.estimated_cost)}
                          </div>
                        )}
                      </td>

                      <td className="py-5 px-4 min-w-[230px]">
                        {primaryTip ? (
                          <div className="p-3 rounded-2xl bg-[#E4E9DA]/60 border border-[#CFD8BE] text-xs text-[#1B1F1A]">
                            <div className="flex items-center gap-1 font-bold text-[#234B24] mb-1">
                              <Sparkles className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
                              <span>{primaryTip.title || 'Tips Menjaga Tempat Ini'}</span>
                            </div>
                            <p className="text-[11px] leading-relaxed line-clamp-3">
                              {primaryTip.content}
                            </p>
                          </div>
                        ) : (
                          <span className="text-xs text-[#4A5248]">-</span>
                        )}
                      </td>

                      <td className="py-4 px-4 text-right whitespace-nowrap">
                        <div className="inline-flex items-center gap-1.5 justify-end">
                          <button
                            type="button"
                            onClick={() => setViewingDest(dest)}
                            className="min-h-[36px] px-3 py-1.5 rounded-xl bg-stone-50 hover:bg-[#234B24]/8 text-[#234B24] border border-[#234B24]/12 font-bold text-xs inline-flex items-center gap-1.5 transition"
                          >
                            <Eye className="w-3.5 h-3.5" aria-hidden="true" />
                            <span>Detail</span>
                          </button>

                          <button
                            type="button"
                            onClick={() => handleOpenEditModal(dest)}
                            className="min-h-[36px] px-3.5 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold text-xs inline-flex items-center gap-1.5 transition shadow-xs"
                          >
                            <Edit3 className="w-3.5 h-3.5 text-[#F26B4B]" aria-hidden="true" />
                            <span>Edit</span>
                          </button>

                          <button
                            type="button"
                            onClick={() => onOpenTariffManager(dest.id)}
                            title="Kelola Standar Tarif & Smart QR"
                            className="min-h-[36px] px-3 py-1.5 rounded-xl bg-[#234B24]/5 hover:bg-[#234B24]/10 text-[#234B24] border border-[#234B24]/10 font-bold text-xs inline-flex items-center gap-1.5 transition"
                          >
                            <Receipt className="w-3.5 h-3.5 text-[#E85D1A]" aria-hidden="true" />
                            <span>Tarif &amp; QR</span>
                          </button>

                          <button
                            type="button"
                            onClick={() => onOpenSmartQRModal(dest)}
                            title="Pratinjau & Cetak Plang Smart QR"
                            className="min-h-[36px] p-2 rounded-xl bg-white hover:bg-[#1E9E5A]/10 text-[#1E9E5A] border border-[#1E9E5A]/25 transition"
                          >
                            <QrCode className="w-3.5 h-3.5" aria-hidden="true" />
                          </button>

                          <button
                            type="button"
                            aria-label={`Hapus destinasi ${dest.name}`}
                            onClick={() => setDeletingDest(dest)}
                            title="Hapus Destinasi"
                            className="min-h-[36px] p-2 rounded-xl bg-[#F26B4B]/10 hover:bg-[#F26B4B] hover:text-white text-[#D95637] border border-[#F26B4B]/20 transition"
                          >
                            <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </>
      )}

      {activeSubTab === 'minang_dictionary' && (
        <MinangDictionarySubTab showToast={showToast} />
      )}

      {activeSubTab === 'culture_calendar' && (
        <CultureCalendarSubTab showToast={showToast} />
      )}

      {activeSubTab === 'gaode_ranking' && (
        <GaodeRankingSubTab showToast={showToast} />
      )}

      {activeSubTab === 'ugc_submissions' && (
        <UgcSubmissionsSubTab
          onRefreshDestinations={onRefresh}
          showToast={showToast}
        />
      )}

      {activeSubTab === 'reviews_moderation' && (
        <TouristReviewsSubTab destinations={destinations} showToast={showToast} />
      )}

      {/* =====================================================================
          MODAL EDITOR DESTINASI 3 BAGIAN (Bagian B = 4 Indikator Medan)
         ===================================================================== */}
      <dialog
        ref={editorDialogRef}
        aria-labelledby="editor-modal-title"
        onClose={() => setEditingDest(null)}
        className="w-full max-w-4xl rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {editingDest && (
          <form
            onSubmit={handleSaveEditorForm}
            className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border border-[#CFD8BE] shadow-2xl overflow-hidden max-h-[90vh] flex flex-col"
          >
            <div className="shrink-0 bg-[#234B24] text-[#F6F3EC] px-6 py-5 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#A7F3D0]">
                  Formulir Manajemen Destinasi &amp; 4 Indikator Medan ({editingDest.id.toUpperCase()})
                </span>
                <h2
                  id="editor-modal-title"
                  className="text-xl lg:text-2xl font-extrabold text-[#F6F3EC] mt-0.5"
                >
                  {isNewDest
                    ? 'Tambah Destinasi Wisata Baru'
                    : `Perbarui Destinasi: ${editingDest.name}`}
                </h2>
              </div>
              <button
                type="button"
                aria-label="Tutup editor destinasi"
                onClick={() => setEditingDest(null)}
                className="w-11 h-11 rounded-full bg-white/10 hover:bg-[#F26B4B] text-white flex items-center justify-center transition"
              >
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <div
              role="tablist"
              aria-label="Tahapan Pengisian Data Destinasi"
              className="shrink-0 bg-[#F6F3EC] border-b border-[#234B24]/15 px-6 py-3"
            >
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                {(
                  [
                    { key: 'A', step: '1', title: 'Profil & 4 Statistik' },
                    { key: 'B', step: '2', title: '4 Indikator Medan' },
                    { key: 'C', step: '3', title: 'Edukasi Adat & Media' },
                  ] as const
                ).map((tab) => {
                  const selected = editorTab === tab.key;
                  return (
                    <button
                      key={tab.key}
                      id={`editor-tab-${tab.key}`}
                      type="button"
                      role="tab"
                      aria-selected={selected}
                      onClick={() => setEditorTab(tab.key)}
                      className={`min-h-[44px] px-3 py-2 rounded-xl text-xs font-semibold transition flex items-center justify-center gap-2 ${selected
                          ? 'bg-[#234B24] !text-white font-semibold shadow-sm'
                          : 'bg-white !text-[#234B24] hover:bg-[#234B24]/5 border border-[#234B24]/15'
                        }`}
                    >
                      <span
                        className={`w-5 h-5 rounded-full text-[11px] font-extrabold flex items-center justify-center shrink-0 ${selected
                            ? 'bg-white !text-[#234B24]'
                            : 'bg-[#234B24]/10 !text-[#234B24]'
                          }`}
                      >
                        {tab.step}
                      </span>
                      <span className="truncate">
                        Bagian {tab.key}: {tab.title}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="flex-1 min-h-0 overflow-y-auto p-6 space-y-5">
              {/* PANEL A */}
              <div role="tabpanel" aria-labelledby="editor-tab-A" hidden={editorTab !== 'A'}>
                <div className="space-y-5">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label htmlFor="dest-name" className="text-xs font-bold text-[#1B1F1A]">
                        Nama Destinasi Wisata *
                      </label>
                      <input
                        id="dest-name"
                        type="text"
                        required
                        placeholder="Contoh: Lembah Harau & Sarasah Bunta"
                        value={editingDest.name}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            name: e.target.value,
                            slug: toDestinationSlug(e.target.value),
                          })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-bold"
                      />
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label htmlFor="dest-regency" className="text-xs font-bold text-[#1B1F1A]">
                        Wilayah Kabupaten / Kota (19 Kab/Kota) *
                      </label>
                      <select
                        id="dest-regency"
                        value={editingDest.city_regency}
                        onChange={(e) =>
                          setEditingDest({ ...editingDest, city_regency: e.target.value })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                      >
                        {SUMBAR_REGENCIES.filter((r) => r !== 'Semua Kab/Kota').map((reg) => (
                          <option key={reg} value={reg}>
                            {reg}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label htmlFor="dest-category" className="text-xs font-bold text-[#1B1F1A]">
                        5 Master Kategori *
                      </label>
                      <select
                        id="dest-category"
                        value={normalizeDestinationCategory(editingDest.category)}
                        onChange={(e) => {
                          const cat = e.target.value as MasterDestinationCategory;
                          setEditingDest({
                            ...editingDest,
                            category: cat,
                            category_id: categoryNameToId(cat),
                            is_hidden_gem: cat === 'Hidden Gem' ? true : editingDest.is_hidden_gem,
                          });
                        }}
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                      >
                        {MASTER_DESTINATION_CATEGORIES.map((cat) => (
                          <option key={cat} value={cat}>
                            {cat}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label htmlFor="dest-lat" className="text-xs font-bold text-[#1B1F1A]">
                        Latitude GPS *
                      </label>
                      <input
                        id="dest-lat"
                        type="number"
                        step="0.0001"
                        required
                        value={editingDest.latitude}
                        onChange={(e) =>
                          setEditingDest({ ...editingDest, latitude: Number(e.target.value) })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-mono"
                      />
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label htmlFor="dest-lng" className="text-xs font-bold text-[#1B1F1A]">
                        Longitude GPS *
                      </label>
                      <input
                        id="dest-lng"
                        type="number"
                        step="0.0001"
                        required
                        value={editingDest.longitude}
                        onChange={(e) =>
                          setEditingDest({ ...editingDest, longitude: Number(e.target.value) })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-mono"
                      />
                    </div>
                  </div>

                  <fieldset className="p-5 rounded-3xl bg-white border border-[#CFD8BE]">
                    <legend className="text-xs font-extrabold uppercase tracking-wider text-[#234B24] px-2">
                      4 Statistik Keputusan Wisatawan (Sinkron Aplikasi Mobile)
                    </legend>
                    <div className="mt-2 grid grid-cols-1 sm:grid-cols-4 gap-4">
                      <div className="flex flex-col gap-1">
                        <label htmlFor="stat-distance" className="text-xs font-bold text-[#1B1F1A]">
                          1. Estimasi Jarak (km)
                        </label>
                        <input
                          id="stat-distance"
                          type="number"
                          min={0}
                          value={editingDest.distance_km}
                          onChange={(e) =>
                            setEditingDest({ ...editingDest, distance_km: Number(e.target.value) })
                          }
                          className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                        />
                      </div>

                      <div className="flex flex-col gap-1">
                        <label htmlFor="stat-duration" className="text-xs font-bold text-[#1B1F1A]">
                          2. Waktu Tempuh (menit)
                        </label>
                        <input
                          id="stat-duration"
                          type="number"
                          min={5}
                          value={editingDest.travel_time_min}
                          onChange={(e) =>
                            setEditingDest({
                              ...editingDest,
                              travel_time_min: Number(e.target.value),
                            })
                          }
                          className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                        />
                      </div>

                      <div className="flex flex-col gap-1">
                        <label htmlFor="stat-crowd" className="text-xs font-bold text-[#1B1F1A]">
                          3. Status Keramaian
                        </label>
                        <select
                          id="stat-crowd"
                          value={editingDest.crowd_level}
                          onChange={(e) =>
                            setEditingDest({
                              ...editingDest,
                              crowd_level: e.target.value as CrowdLevel,
                            })
                          }
                          className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                        >
                          <option value="Sepi">Sepi (Hijau)</option>
                          <option value="Sedang">Sedang (Sage)</option>
                          <option value="Ramai">Ramai (Koral)</option>
                        </select>
                      </div>

                      <div className="flex flex-col gap-1">
                        <label htmlFor="stat-cost" className="text-xs font-bold text-[#1B1F1A]">
                          4. Estimasi Biaya (IDR)
                        </label>
                        <input
                          id="stat-cost"
                          type="number"
                          min={0}
                          step={500}
                          value={editingDest.estimated_cost}
                          onChange={(e) => {
                            const val = Number(e.target.value);
                            setEditingDest({
                              ...editingDest,
                              estimated_cost: val,
                              ticket_price_summary:
                                val === 0
                                  ? 'Gratis'
                                  : `Rp ${val.toLocaleString('id-ID')} / orang`,
                            });
                          }}
                          className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold text-[#234B24]"
                        />
                      </div>
                    </div>
                  </fieldset>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label htmlFor="dest-weather-status" className="text-xs font-bold text-[#1B1F1A]">
                        Status Cuaca Destinasi (Sinkron Open-Meteo / Override)
                      </label>
                      <select
                        id="dest-weather-status"
                        value={editingDest.weather_status || 'Aman'}
                        onChange={(e) =>
                          setEditingDest({ ...editingDest, weather_status: e.target.value })
                        }
                        className="min-h-[46px] px-3.5 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                      >
                        <option value="Aman">Aman (Cerah / Berawan Normal)</option>
                        <option value="Waspada Hujan">Waspada Hujan / Jalur Licin</option>
                        <option value="Siaga Cuaca Ekstrem">Siaga Cuaca Ekstrem</option>
                      </select>
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label htmlFor="dest-hours" className="text-xs font-bold text-[#1B1F1A]">
                        Jam Operasional Kawasan
                      </label>
                      <input
                        id="dest-hours"
                        type="text"
                        value={editingDest.opening_hours || '08:00 - 17:00 WIB'}
                        onChange={(e) =>
                          setEditingDest({ ...editingDest, opening_hours: e.target.value })
                        }
                        className="min-h-[46px] px-3.5 py-2 rounded-xl bg-white border border-[#767676] text-sm font-medium"
                      />
                    </div>
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label htmlFor="dest-desc" className="text-xs font-bold text-[#1B1F1A]">
                      Deskripsi Ringkas Kawasan Wisata
                    </label>
                    <textarea
                      id="dest-desc"
                      rows={3}
                      value={editingDest.description}
                      onChange={(e) =>
                        setEditingDest({ ...editingDest, description: e.target.value })
                      }
                      placeholder="Tuliskan daya tarik utama, sejarah nagari, dan keunikan alam..."
                      className="p-3.5 rounded-2xl bg-white border border-[#767676] text-sm"
                    />
                  </div>
                </div>
              </div>

              {/* PANEL B: 4 INDIKATOR KESIAPAN MEDAN */}
              <div role="tabpanel" aria-labelledby="editor-tab-B" hidden={editorTab !== 'B'}>
                <div className="space-y-5">
                  <div className="p-4 rounded-2xl bg-[#E4E9DA] border border-[#CFD8BE] text-xs text-[#1B1F1A]">
                    <strong>4 Indikator Kesiapan Medan (Standar Aplikasi WISGO):</strong> Meliputi Akses Kendaraan, Tingkat Trekking, Ketersediaan Fasilitas Resmi, dan Kebutuhan Pemandu Lokal. Kondisi cuaca ditarik langsung dari integrasi Open-Meteo Live.
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="bg-white p-5 rounded-2xl border border-[#CFD8BE] space-y-2">
                      <label
                        htmlFor="medan-vehicle"
                        className="text-xs font-extrabold uppercase text-[#234B24] flex items-center gap-1.5"
                      >
                        <Car className="w-4 h-4 text-[#234B24]" />
                        1. Akses Kendaraan
                      </label>
                      <select
                        id="medan-vehicle"
                        value={editingDest.medan_indicator?.vehicle_access || 'Mobil OK'}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              vehicle_access: e.target.value,
                            },
                          })
                        }
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Mobil OK">Mobil OK (Roda Empat &amp; Bus Pariwisata)</option>
                        <option value="Hanya Motor">Hanya Motor (Jalur Sempit / Tanjakan)</option>
                        <option value="Jalan Kaki">Jalan Kaki (Trek Khusus)</option>
                      </select>
                    </div>

                    <div className="bg-white p-5 rounded-2xl border border-[#CFD8BE] space-y-2">
                      <label
                        htmlFor="medan-trekking"
                        className="text-xs font-extrabold uppercase text-[#234B24] flex items-center gap-1.5"
                      >
                        <Mountain className="w-4 h-4 text-[#234B24]" />
                        2. Tingkat Kesulitan Trekking
                      </label>
                      <select
                        id="medan-trekking"
                        value={editingDest.medan_indicator?.trekking_level || 'Mudah (Datar)'}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              trekking_level: e.target.value,
                            },
                          })
                        }
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Mudah (Datar)">Mudah (Datar — Ramah Keluarga &amp; Lansia)</option>
                        <option value="Sedang">Sedang (Jalur Tanah / Tanjakan Berundak)</option>
                        <option value="Ekstrem (Curam)">Ekstrem (Curam — Wajib Fisik Prima)</option>
                      </select>
                    </div>

                    <div className="bg-white p-5 rounded-2xl border border-[#CFD8BE] space-y-2">
                      <label
                        htmlFor="medan-facilities"
                        className="text-xs font-extrabold uppercase text-[#234B24] flex items-center gap-1.5"
                      >
                        <MapPin className="w-4 h-4 text-[#234B24]" />
                        3. Ketersediaan Fasilitas Resmi
                      </label>
                      <select
                        id="medan-facilities"
                        value={
                          editingDest.medan_indicator?.facilities ||
                          'Toilet, Musala & Parkir Lengkap'
                        }
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              facilities: e.target.value,
                            },
                          })
                        }
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Toilet, Musala & Parkir Lengkap">
                          Toilet, Musala &amp; Parkir Lengkap
                        </option>
                        <option value="Terbatas">Terbatas (Toilet Dasar / Warung Warga)</option>
                        <option value="Belum Ada">Belum Ada (Kawasan Alam Murni)</option>
                      </select>
                    </div>

                    <div className="bg-white p-5 rounded-2xl border border-[#CFD8BE] space-y-2">
                      <label
                        htmlFor="medan-guide"
                        className="text-xs font-extrabold uppercase text-[#234B24] flex items-center gap-1.5"
                      >
                        <Compass className="w-4 h-4 text-[#234B24]" />
                        4. Kebutuhan Pemandu Lokal / Pokdarwis
                      </label>
                      <select
                        id="medan-guide"
                        value={editingDest.medan_indicator?.guide_need || 'Mandiri'}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              guide_need: e.target.value,
                            },
                          })
                        }
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Mandiri">Mandiri (Jalur Terbuka &amp; Rambu Jelas)</option>
                        <option value="Disarankan">Disarankan Pemandu Lokal</option>
                        <option value="Wajib Pemandu Lokal">
                          Wajib Pemandu Lokal (Kawasan Hutan / Sensitif)
                        </option>
                      </select>
                    </div>
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <label htmlFor="medan-notes" className="text-xs font-bold text-[#1B1F1A]">
                      Catatan Medan &amp; Kesiapan Fisik Lapangan (terrain_note)
                    </label>
                    <textarea
                      id="medan-notes"
                      rows={2}
                      placeholder="Contoh: Gunakan sepatu trekking anti-selip saat musim hujan..."
                      value={
                        editingDest.medan_indicator?.terrain_note ||
                        editingDest.medan_indicator?.readiness_notes ||
                        ''
                      }
                      onChange={(e) =>
                        setEditingDest({
                          ...editingDest,
                          medan_indicator: {
                            ...editingDest.medan_indicator!,
                            terrain_note: e.target.value,
                            readiness_notes: e.target.value,
                          },
                        })
                      }
                      className="p-3.5 rounded-2xl bg-white border border-[#767676] text-sm"
                    />
                  </div>
                </div>
              </div>

              {/* PANEL C */}
              <div role="tabpanel" aria-labelledby="editor-tab-C" hidden={editorTab !== 'C'}>
                <div className="space-y-6">
                  <div className="p-4 rounded-2xl bg-white border border-[#234B24]/10 space-y-4">
                    <div className="flex flex-wrap items-center justify-between gap-3">
                      <div>
                        <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                          Daftar &ldquo;Tips Menjaga Tempat Ini&rdquo; (Etika Adat &amp; Kelestarian)
                        </h3>
                        <p className="text-xs text-[#4A5248]">
                          Tersinkronisasi dua arah dengan kartu aturan &amp; etika wisatawan.
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={handleAddTipRow}
                        className="min-h-[40px] px-4 py-2 rounded-pill bg-[#234B24] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 hover:bg-[#1B3A1C] transition"
                      >
                        <Plus className="w-3.5 h-3.5" aria-hidden="true" />
                        <span>Tambah Butir Panduan</span>
                      </button>
                    </div>

                    <div className="space-y-3">
                      {(editingDest.tips || []).map((tip, idx) => (
                        <div
                          key={tip.id}
                          className="bg-[#F6F3EC] p-4 rounded-2xl border border-[#CFD8BE] space-y-3"
                        >
                          <div className="flex items-center justify-between gap-2">
                            <span className="text-xs font-extrabold text-[#234B24]">
                              Panduan #{idx + 1}
                            </span>
                            <div className="flex items-center gap-3">
                              <label
                                htmlFor={`tip-important-${tip.id}`}
                                className="inline-flex items-center gap-1.5 text-xs font-bold text-[#D95637] cursor-pointer"
                              >
                                <input
                                  id={`tip-important-${tip.id}`}
                                  type="checkbox"
                                  checked={Boolean(tip.is_important)}
                                  onChange={(e) =>
                                    handleUpdateTipRow(tip.id, { is_important: e.target.checked })
                                  }
                                  className="w-4 h-4 accent-[#F26B4B]"
                                />
                                <AlertTriangle className="w-3.5 h-3.5" aria-hidden="true" />
                                <span>Peringatan Penting</span>
                              </label>

                              {(editingDest.tips?.length || 0) > 1 && (
                                <button
                                  type="button"
                                  onClick={() => handleRemoveTipRow(tip.id)}
                                  className="text-xs font-bold text-[#D95637] hover:underline"
                                >
                                  Hapus
                                </button>
                              )}
                            </div>
                          </div>

                          <textarea
                            rows={2}
                            required
                            aria-label={`Isi panduan ke-${idx + 1}`}
                            placeholder="Tuliskan pesan etika adat Minangkabau, keselamatan, atau pelestarian alam..."
                            value={tip.content}
                            onChange={(e) =>
                              handleUpdateTipRow(tip.id, { content: e.target.value })
                            }
                            className="w-full p-3 rounded-xl bg-white border border-[#767676] text-sm"
                          />
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="p-4 rounded-2xl bg-white border border-[#234B24]/10 space-y-4">
                    <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                      Foto Sampul &amp; Pratinjau Tampilan Wisatawan
                    </h3>
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
                      <div className="space-y-3">
                        <ImageDropzone
                          label="Foto Sampul Utama Destinasi"
                          value={editingDest.cover_image}
                          onChange={(dataUrl) =>
                            setEditingDest({ ...editingDest, cover_image: dataUrl })
                          }
                          onClear={() => setEditingDest({ ...editingDest, cover_image: '' })}
                          helperText="Unggah foto lanskap (JPG, PNG, WebP)."
                        />
                        <div className="p-3.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#4A5248]">
                          Slug Smart QR:{' '}
                          <strong className="text-[#234B24] font-mono">
                            /qr/{editingDest.slug || toDestinationSlug(editingDest.name || 'destinasi')}
                          </strong>
                        </div>
                      </div>

                      <div className="bg-[#F6F3EC] rounded-3xl border border-[#CFD8BE] overflow-hidden shadow-xs">
                        <div className="relative h-40 bg-[#234B24]/10">
                          {editingDest.cover_image ? (
                            <img
                              src={editingDest.cover_image}
                              alt={editingDest.name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-xs text-[#4A5248]">
                              Belum ada foto
                            </div>
                          )}
                          <div className="absolute top-3 left-3 flex gap-1.5">
                            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#1E9E5A] text-white">
                              {editingDest.city_regency}
                            </span>
                            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#234B24] text-white">
                              {editingDest.category}
                            </span>
                          </div>
                        </div>
                        <div className="p-4 space-y-2">
                          <h4 className="font-extrabold text-[#1B1F1A] text-base">
                            {editingDest.name || 'Nama Destinasi Wisata'}
                          </h4>
                          <p className="text-xs text-[#4A5248] line-clamp-2">
                            {editingDest.description || 'Deskripsi singkat kawasan wisata.'}
                          </p>
                          <div className="pt-2 border-t border-[#CFD8BE]/50 flex items-center justify-between text-xs">
                            <span className="font-bold text-[#234B24]">
                              {editingDest.ticket_price_summary || formatRupiah(editingDest.estimated_cost)}
                            </span>
                            <span className="text-[#4A5248]">
                              {editingDest.distance_km} km • ± {formatDuration(editingDest.travel_time_min)}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Check Point Lokasi untuk Gamifikasi */}
                  <details className="group bg-white p-4 rounded-2xl border border-[#234B24]/10">
                    <summary className="flex items-center justify-between cursor-pointer list-none select-none">
                      <span className="text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
                        Pengaturan Lanjutan: Check Point GPS Tantangan (Opsional)
                      </span>
                      <span className="text-xs text-[#4A5248] group-open:rotate-180 transition-transform">
                        ▼
                      </span>
                    </summary>

                    <div className="mt-4 pt-4 border-t border-[#CFD8BE]/60 space-y-3">
                      <div className="flex items-center justify-between">
                        <p className="text-[11px] text-[#4A5248]">
                          Spot check-in GPS radius &lt;500m untuk pengumpulan XP &amp; Paspor Digital.
                        </p>
                        <button
                          type="button"
                          onClick={() => {
                            const currentCps = editingDest.checkpoints || [];
                            setEditingDest({
                              ...editingDest,
                              checkpoints: [
                                ...currentCps,
                                {
                                  id: `cp-${Date.now()}`,
                                  destination_id: editingDest.id,
                                  name: `Check Point #${currentCps.length + 1}`,
                                  latitude: editingDest.latitude,
                                  longitude: editingDest.longitude,
                                  is_mandatory_challenge: true,
                                },
                              ],
                            });
                          }}
                          className="px-3 py-1.5 rounded-xl bg-[#234B24] text-white text-xs font-bold flex items-center gap-1"
                        >
                          <Plus className="w-3 h-3" />
                          Tambah Check Point
                        </button>
                      </div>

                      {(editingDest.checkpoints || []).map((cp, idx) => (
                        <div
                          key={cp.id || idx}
                          className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col sm:flex-row sm:items-center gap-2"
                        >
                          <input
                            type="text"
                            value={cp.name}
                            onChange={(e) => {
                              const next = [...(editingDest.checkpoints || [])];
                              next[idx] = { ...cp, name: e.target.value };
                              setEditingDest({ ...editingDest, checkpoints: next });
                            }}
                            className="flex-1 px-2.5 py-1.5 rounded-lg bg-white border border-[#CFD8BE] text-xs font-bold"
                          />
                          <button
                            type="button"
                            onClick={() => {
                              const next = (editingDest.checkpoints || []).filter((_, i) => i !== idx);
                              setEditingDest({ ...editingDest, checkpoints: next });
                            }}
                            className="text-red-600 p-1.5 rounded-lg hover:bg-red-50"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      ))}
                    </div>
                  </details>
                </div>
              </div>
            </div>

            <div className="shrink-0 border-t border-[#234B24]/15 bg-white px-6 py-4 flex flex-wrap items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  disabled={editorTab === 'A'}
                  onClick={() => {
                    const tabs: EditorTabKey[] = ['A', 'B', 'C'];
                    const currIdx = tabs.indexOf(editorTab);
                    if (currIdx > 0) setEditorTab(tabs[currIdx - 1]);
                  }}
                  className="min-h-[44px] px-4 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] disabled:opacity-40"
                >
                  ← Sebelumnya
                </button>
                <button
                  type="button"
                  disabled={editorTab === 'C'}
                  onClick={() => {
                    const tabs: EditorTabKey[] = ['A', 'B', 'C'];
                    const currIdx = tabs.indexOf(editorTab);
                    if (currIdx < tabs.length - 1) setEditorTab(tabs[currIdx + 1]);
                  }}
                  className="min-h-[44px] px-4 rounded-xl bg-[#234B24]/10 border border-[#234B24]/20 text-xs font-bold text-[#234B24] disabled:opacity-40"
                >
                  Selanjutnya →
                </button>
              </div>

              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setEditingDest(null)}
                  className="min-h-[44px] px-5 rounded-pill bg-[#F6F3EC] border border-[#767676] text-xs font-bold text-[#1B1F1A]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[46px] px-7 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-sm font-bold shadow-md transition"
                >
                  {isNewDest ? 'Simpan Destinasi Baru' : 'Simpan Seluruh Perubahan'}
                </button>
              </div>
            </div>
          </form>
        )}
      </dialog>

      {/* =====================================================================
          MODAL DETAIL DESTINASI (4 Indikator Medan + Cuaca Live Open-Meteo)
         ===================================================================== */}
      <dialog
        ref={detailDialogRef}
        aria-labelledby="detail-modal-title"
        onClose={() => setViewingDest(null)}
        className="w-full max-w-3xl rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {viewingDest && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border border-[#CFD8BE] shadow-2xl overflow-hidden max-h-[90vh] overflow-y-auto">
            <div className="relative h-52 bg-[#234B24]">
              <img
                src={viewingDest.cover_image}
                alt=""
                className="w-full h-full object-cover opacity-80"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent p-6 flex flex-col justify-end text-white">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="px-2.5 py-0.5 rounded-full bg-[#1E9E5A] text-[11px] font-bold">
                    {viewingDest.city_regency}
                  </span>
                  <span className="px-2.5 py-0.5 rounded-full bg-white/20 text-[11px] font-bold">
                    {viewingDest.category}
                  </span>
                </div>
                <h2 id="detail-modal-title" className="text-2xl font-extrabold mt-1">
                  {viewingDest.name}
                </h2>
              </div>
              <button
                type="button"
                aria-label="Tutup rincian destinasi"
                onClick={() => setViewingDest(null)}
                className="absolute top-4 right-4 w-10 h-10 rounded-full bg-black/50 hover:bg-[#F26B4B] text-white flex items-center justify-center transition"
              >
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <div className="p-6 lg:p-8 space-y-5">
              <p className="text-sm text-[#1B1F1A] leading-relaxed">{viewingDest.description}</p>

              {/* Cuaca Open-Meteo Live */}
              {viewingDest.weather && (
                <div className="p-4 rounded-2xl bg-sky-50 border border-sky-200 flex flex-wrap items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <CloudSun className="w-7 h-7 text-sky-700" />
                    <div>
                      <div className="text-xs font-extrabold text-sky-900">
                        Cuaca Terkini ({viewingDest.weather.source}) · {viewingDest.weather.temperature_c}°C
                      </div>
                      <div className="text-[11px] text-sky-800">
                        {viewingDest.weather.condition} · Kelembapan {viewingDest.weather.humidity_percent}% · Angin {viewingDest.weather.wind_speed_kmh} km/jam · Peluang Hujan {viewingDest.weather.rain_probability}%
                      </div>
                    </div>
                  </div>
                  <span className="px-2.5 py-1 rounded-full text-[11px] font-bold bg-white border border-sky-200 text-sky-900">
                    Status: {viewingDest.weather_status || viewingDest.weather.weather_status}
                  </span>
                </div>
              )}

              {/* 4 Statistik Keputusan */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">Estimasi Jarak</div>
                  <div className="text-base font-extrabold text-[#1B1F1A] mt-0.5">
                    {viewingDest.distance_km} km
                  </div>
                </div>
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">Waktu Tempuh</div>
                  <div className="text-base font-extrabold text-[#1B1F1A] mt-0.5">
                    {formatDuration(viewingDest.travel_time_min)}
                  </div>
                </div>
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">Keramaian</div>
                  <div className="mt-1">{renderCrowdBadge(viewingDest.crowd_level)}</div>
                </div>
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">Tiket Utama</div>
                  <div className="text-sm font-extrabold text-[#234B24] mt-0.5">
                    {viewingDest.tariffs?.[0]
                      ? formatRupiah(viewingDest.tariffs[0].price)
                      : formatRupiah(viewingDest.estimated_cost)}
                  </div>
                </div>
              </div>

              {/* 4 Indikator Medan */}
              {viewingDest.medan_indicator && (
                <div className="bg-white p-5 rounded-3xl border border-[#CFD8BE] space-y-3">
                  <h3 className="text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
                    4 Indikator Kesiapan Medan Lapangan
                  </h3>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Akses Kendaraan:</span>
                      <strong className="text-[#1B1F1A]">
                        {viewingDest.medan_indicator.vehicle_access}
                      </strong>
                    </div>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Tingkat Trekking:</span>
                      <strong className="text-[#1B1F1A]">
                        {viewingDest.medan_indicator.trekking_level}
                      </strong>
                    </div>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Fasilitas Resmi:</span>
                      <strong className="text-[#1B1F1A]">
                        {viewingDest.medan_indicator.facilities}
                      </strong>
                    </div>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Kebutuhan Pemandu:</span>
                      <strong className="text-[#234B24]">
                        {viewingDest.medan_indicator.guide_need}
                      </strong>
                    </div>
                  </div>
                  {(viewingDest.medan_indicator.terrain_note ||
                    viewingDest.medan_indicator.readiness_notes) && (
                      <p className="text-xs text-[#4A5248] pt-1">
                        <strong>Catatan Lapangan:</strong>{' '}
                        {viewingDest.medan_indicator.terrain_note ||
                          viewingDest.medan_indicator.readiness_notes}
                      </p>
                    )}
                </div>
              )}

              <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => {
                    const target = viewingDest;
                    setViewingDest(null);
                    onOpenSmartQRModal(target);
                  }}
                  className="min-h-[46px] px-5 rounded-pill bg-white border border-[#234B24] text-[#234B24] font-bold text-xs inline-flex items-center gap-2"
                >
                  <QrCode className="w-4 h-4" aria-hidden="true" />
                  <span>Pratinjau &amp; Cetak Plang Smart QR</span>
                </button>
                <button
                  type="button"
                  onClick={() => {
                    const target = viewingDest;
                    setViewingDest(null);
                    handleOpenEditModal(target);
                  }}
                  className="h-[48px] px-6 rounded-pill bg-[#234B24] text-[#F6F3EC] font-bold text-xs inline-flex items-center gap-2"
                >
                  <Edit3 className="w-4 h-4" aria-hidden="true" />
                  <span>Edit Data Destinasi</span>
                </button>
              </div>
            </div>
          </div>
        )}
      </dialog>

      {/* DIALOG HAPUS */}
      <dialog
        ref={deleteDialogRef}
        aria-labelledby="delete-dest-title"
        onClose={() => setDeletingDest(null)}
        className="w-full max-w-md rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {deletingDest && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] p-6 lg:p-7 rounded-[28px] border border-[#CFD8BE] shadow-2xl">
            <h3 id="delete-dest-title" className="text-lg font-extrabold text-[#1B1F1A]">
              Hapus Destinasi dari Direktori?
            </h3>
            <p className="mt-2 text-xs text-[#4A5248] leading-relaxed">
              Apakah Anda yakin ingin menghapus destinasi{' '}
              <strong className="text-[#1B1F1A]">{deletingDest.name}</strong> (
              {deletingDest.city_regency}) beserta seluruh indikator medan, denah 2D, dan tarif resminya?
            </p>
            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                type="button"
                autoFocus
                onClick={() => setDeletingDest(null)}
                className="min-h-[44px] px-5 rounded-pill bg-white border border-[#767676] text-xs font-bold text-[#1B1F1A]"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={async () => {
                  const target = deletingDest;
                  setDeletingDest(null);
                  await onDeleteDestination(
                    target,
                    `Destinasi "${target.name}" berhasil dihapus dari direktori.`
                  );
                }}
                className="min-h-[44px] px-5 rounded-pill bg-[#F26B4B] hover:bg-[#D95637] text-white text-xs font-bold shadow-sm transition"
              >
                Ya, Hapus Destinasi
              </button>
            </div>
          </div>
        )}
      </dialog>
    </div>
  );
};
