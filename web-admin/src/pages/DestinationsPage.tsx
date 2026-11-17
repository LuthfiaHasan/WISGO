import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Search,
  MapPin,
  WifiOff,
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
  CheckCircle2,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Clock,
  Navigation,
  AlertTriangle,
  X,
} from 'lucide-react';
import {
  Destination,
  CrowdLevel,
  DestinationTip,
} from '../types/contract';
import {
  DESTINATION_CATEGORIES,
  SUMBAR_REGENCIES,
  toDestinationSlug,
} from '../data/mockDestinations';
import { ImageDropzone } from '../components/ImageDropzone';

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
}

type SortColumn = 'name' | 'city_regency' | 'distance' | 'price';
type SortDirection = 'ascending' | 'descending';
type EditorTabKey = 'A' | 'B' | 'C' | 'D';

const collator = new Intl.Collator('id', {
  numeric: true,
  sensitivity: 'base',
});

export const DestinationsPage: React.FC<DestinationsPageProps> = ({
  destinations,
  backendOnline,
  loading,
  onRefresh,
  onSaveDestination,
  onDeleteDestination,
  onOpenTariffManager,
  onOpenSmartQRModal,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRegency, setSelectedRegency] =
    useState<string>('Semua Kab/Kota');
  const [selectedCrowd, setSelectedCrowd] = useState<string>('Semua');
  const [onlyBlankSpot, setOnlyBlankSpot] = useState<boolean>(false);

  // State Pengurutan (Sort)
  const [sortCol, setSortCol] = useState<SortColumn>('name');
  const [sortDir, setSortDir] = useState<SortDirection>('ascending');
  const [sortAnnouncement, setSortAnnouncement] = useState<string>('');

  // State Modal Editor (Bagian A, B, C), Detail, & Konfirmasi Hapus
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
    if (editingDest && !dialog.open) {
      dialog.showModal();
    } else if (!editingDest && dialog.open) {
      dialog.close();
    }
  }, [editingDest]);

  useEffect(() => {
    const dialog = detailDialogRef.current;
    if (!dialog) return;
    if (viewingDest && !dialog.open) {
      dialog.showModal();
    } else if (!viewingDest && dialog.open) {
      dialog.close();
    }
  }, [viewingDest]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (deletingDest && !dialog.open) {
      dialog.showModal();
    } else if (!deletingDest && dialog.open) {
      dialog.close();
    }
  }, [deletingDest]);

  const handleSortClick = (col: SortColumn, label: string) => {
    let nextDir: SortDirection = 'ascending';
    if (sortCol === col) {
      nextDir = sortDir === 'ascending' ? 'descending' : 'ascending';
    }
    setSortCol(col);
    setSortDir(nextDir);
    setSortAnnouncement(
      `Tabel diurutkan berdasarkan ${label} secara ${
        nextDir === 'ascending' ? 'menaik' : 'menurun'
      }.`
    );
  };

  const filteredAndSortedDestinations = useMemo(() => {
    const filtered = destinations.filter((item) => {
      const q = searchQuery.trim().toLowerCase();
      const matchesSearch =
        !q ||
        item.name.toLowerCase().includes(q) ||
        item.category.toLowerCase().includes(q) ||
        item.city_regency.toLowerCase().includes(q) ||
        item.description.toLowerCase().includes(q) ||
        item.tariffs?.some(
          (t) =>
            t.item_name.toLowerCase().includes(q) ||
            t.regulation_ref.toLowerCase().includes(q)
        );

      const matchesRegency =
        selectedRegency === 'Semua Kab/Kota' ||
        item.city_regency === selectedRegency;

      const matchesCrowd =
        selectedCrowd === 'Semua' || item.crowd_level === selectedCrowd;

      const isBlank =
        Boolean(item.is_blank_spot) ||
        Boolean(
          item.medan_indicator?.cellular_signal.toLowerCase().includes('blank')
        ) ||
        Boolean(
          item.medan_indicator?.cellular_signal.toLowerCase().includes('zero')
        );

      const matchesBlankSpot = !onlyBlankSpot || isBlank;

      return (
        matchesSearch && matchesRegency && matchesCrowd && matchesBlankSpot
      );
    });

    const factor = sortDir === 'ascending' ? 1 : -1;
    return [...filtered].sort((a, b) => {
      if (sortCol === 'name') {
        return factor * collator.compare(a.name, b.name);
      }
      if (sortCol === 'city_regency') {
        return factor * collator.compare(a.city_regency, b.city_regency);
      }
      if (sortCol === 'distance') {
        const distA = a.estimated_distance_km ?? 0;
        const distB = b.estimated_distance_km ?? 0;
        return factor * (distA - distB);
      }
      if (sortCol === 'price') {
        const priceA = a.tariffs?.[0]?.price ?? 0;
        const priceB = b.tariffs?.[0]?.price ?? 0;
        return factor * (priceA - priceB);
      }
      return 0;
    });
  }, [
    destinations,
    searchQuery,
    selectedRegency,
    selectedCrowd,
    onlyBlankSpot,
    sortCol,
    sortDir,
  ]);

  const stats = useMemo(() => {
    const total = destinations.length;
    const blankSpots = destinations.filter(
      (d) =>
        d.is_blank_spot ||
        d.medan_indicator?.cellular_signal.toLowerCase().includes('blank') ||
        d.medan_indicator?.cellular_signal.toLowerCase().includes('zero')
    ).length;
    const uniqueRegencies = new Set(destinations.map((d) => d.city_regency))
      .size;
    const totalTariffItems = destinations.reduce(
      (acc, d) => acc + (d.tariffs?.length || 0),
      0
    );
    return { total, blankSpots, uniqueRegencies, totalTariffItems };
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
    if (!minutes) return '± 1 jam 30 mnt';
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

  const renderSortIcon = (col: SortColumn) => {
    if (sortCol !== col) {
      return (
        <ArrowUpDown
          className="w-3.5 h-3.5 opacity-60 shrink-0"
          aria-hidden="true"
        />
      );
    }
    return sortDir === 'ascending' ? (
      <ArrowUp
        className="w-3.5 h-3.5 text-[#F26B4B] shrink-0"
        aria-hidden="true"
      />
    ) : (
      <ArrowDown
        className="w-3.5 h-3.5 text-[#F26B4B] shrink-0"
        aria-hidden="true"
      />
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
      category: 'Alam & Tebing',
      city_regency: 'Kota Bukittinggi',
      description: '',
      latitude: -0.3056,
      longitude: 100.3692,
      cover_image:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80',
      crowd_level: 'Sepi',
      estimated_distance_km: 85,
      estimated_duration_min: 120,
      ticket_price_summary: 'Rp 15.000 / orang',
      is_blank_spot: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      medan_indicator: {
        id: `med-${newId}`,
        destination_id: newId,
        vehicle_access: 'Mobil OK',
        trekking_level: 'Landai / Mudah',
        cellular_signal: '4G Lancar',
        facilities: 'Toilet, Musala & Parkir Lengkap',
        guide_need: 'Mandiri',
        vehicle_score: 5,
        trekking_score: 5,
        signal_score: 5,
        facilities_score: 5,
        guide_score: 5,
        readiness_notes:
          'Akses jalan beraspal baik, dapat dilalui kendaraan roda empat dan bus.',
      },
      tariffs: [
        {
          id: `trf-${newId}-1`,
          destination_id: newId,
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
          content:
            'Patuhi etika adat basandi syarak, syarak basandi Kitabullah dan jaga kebersihan lingkungan wisata.',
          is_important: true,
        },
      ],
    });
  };

  const handleOpenEditModal = (dest: Destination) => {
    setIsNewDest(false);
    setEditorTab('A');
    setEditingDest({
      ...dest,
      slug: dest.slug || toDestinationSlug(dest.name),
      estimated_distance_km: dest.estimated_distance_km ?? 90,
      estimated_duration_min: dest.estimated_duration_min ?? 135,
      ticket_price_summary:
        dest.ticket_price_summary ||
        (dest.tariffs?.[0]
          ? `${formatRupiah(dest.tariffs[0].price)} / ${dest.tariffs[0].unit.replace(
              'per ',
              ''
            )}`
          : 'Rp 15.000 / orang'),
      is_blank_spot:
        dest.is_blank_spot ??
        Boolean(
          dest.medan_indicator?.cellular_signal
            .toLowerCase()
            .includes('blank') ||
            dest.medan_indicator?.cellular_signal.toLowerCase().includes('zero')
        ),
      medan_indicator: {
        id: dest.medan_indicator?.id || `med-${dest.id}`,
        destination_id: dest.id,
        vehicle_access: dest.medan_indicator?.vehicle_access || 'Mobil OK',
        trekking_level:
          dest.medan_indicator?.trekking_level || 'Landai / Mudah',
        cellular_signal: dest.medan_indicator?.cellular_signal || '4G Lancar',
        facilities:
          dest.medan_indicator?.facilities || 'Toilet, Musala & Parkir Lengkap',
        guide_need: dest.medan_indicator?.guide_need || 'Mandiri',
        vehicle_score: dest.medan_indicator?.vehicle_score ?? 5,
        trekking_score: dest.medan_indicator?.trekking_score ?? 4,
        signal_score: dest.medan_indicator?.signal_score ?? 4,
        facilities_score: dest.medan_indicator?.facilities_score ?? 4,
        guide_score: dest.medan_indicator?.guide_score ?? 5,
        readiness_notes:
          dest.medan_indicator?.readiness_notes ||
          'Kondisi jalur terpantau aman dan siap dikunjungi wisatawan.',
      },
      tips:
        dest.tips && dest.tips.length > 0
          ? dest.tips
          : [
              {
                id: `tip-${dest.id}-1`,
                destination_id: dest.id,
                content: 'Jaga kebersihan dan patuhi kearifan lokal Nagari.',
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

    const finalDest: Destination = {
      ...editingDest,
      slug: editingDest.slug || toDestinationSlug(editingDest.name),
      updated_at: new Date().toISOString(),
    };

    await onSaveDestination(
      finalDest,
      isNewDest
        ? `Destinasi baru "${finalDest.name}" (${finalDest.city_regency}) berhasil ditambahkan dan disimpan.`
        : `Perubahan data destinasi "${finalDest.name}" beserta indikator medan dan tips adat berhasil disimpan.`
    );
    setEditingDest(null);
  };

  const handleAddTipRow = () => {
    if (!editingDest) return;
    const currentTips = editingDest.tips || [];
    const newTip: DestinationTip = {
      id: `tip-${editingDest.id}-${Date.now()}`,
      destination_id: editingDest.id,
      content: '',
      is_important: false,
    };
    setEditingDest({
      ...editingDest,
      tips: [...currentTips, newTip],
    });
  };

  const handleUpdateTipRow = (
    tipId: string,
    patch: Partial<DestinationTip>
  ) => {
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
      {/* Header Utama Halaman */}
      <header className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-[#E4E9DA] text-[#234B24] text-xs font-bold">
            <CheckCircle2
              className="w-3.5 h-3.5 text-[#1E9E5A]"
              aria-hidden="true"
            />
            <span>
              {backendOnline
                ? 'Status Sistem: Terhubung (Database Utama)'
                : 'Status Sistem: Mode Lokal Aktif (Sinkronisasi Otomatis)'}
            </span>
          </div>
          <h1 className="mt-2 text-2xl lg:text-3xl font-extrabold text-[#1B1F1A] tracking-tight">
            Manajemen Destinasi Wisata &amp; Kesiapan Medan
          </h1>
          <p className="text-sm text-[#4A5248] mt-0.5">
            Direktori resmi destinasi unggulan, 4 statistik keputusan wisatawan,
            5 indikator kesiapan medan lapangan, dan standar tarif Perda.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <button
            type="button"
            onClick={onRefresh}
            disabled={loading}
            className="min-h-[48px] px-4 py-2.5 rounded-pill bg-white border border-[#CFD8BE] hover:bg-[#E4E9DA]/50 text-[#1B1F1A] font-bold text-xs flex items-center gap-2 transition shadow-sm"
          >
            <RefreshCw
              className={`w-4 h-4 text-[#234B24] ${
                loading ? 'animate-spin' : ''
              }`}
              aria-hidden="true"
            />
            <span>Sinkronisasi Data</span>
          </button>

          <button
            type="button"
            onClick={handleOpenNewModal}
            className="h-[52px] px-6 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-sm flex items-center gap-2 shadow-sm transition"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
            <span>+ Tambah Destinasi Baru</span>
          </button>
        </div>
      </header>

      {/* 4 Kartu Ringkasan Eksekutif */}
      <section
        aria-label="Ringkasan Statistik Destinasi Sumatera Barat"
        className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4"
      >
        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Destinasi Terdaftar
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.total}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
              Terverifikasi Dispar
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Mencakup {stats.uniqueRegencies} Kabupaten/Kota Sumatera Barat
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Kawasan Blank Spot (Zero-Signal)
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#F26B4B]">
              {stats.blankSpots}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
              Paket Offline Aktif
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Mengaktifkan unduhan peta &amp; panduan suara luring
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Komponen Tarif Resmi Perda
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#1B1F1A]">
              {stats.totalTariffItems}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#E85D1A]/15 text-[#E85D1A]">
              Fair-Price Barometer
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Tercetak pada Plang Smart QR di tiap gerbang kawasan
          </p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
            Pemetaan Kesiapan Medan
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              5 Indikator
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#234B24] text-[#F6F3EC]">
              Standar Lapangan
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">
            Kendaraan, Trekking, Sinyal, Fasilitas &amp; Pemandu
          </p>
        </div>
      </section>

      {/* Bilah Pencarian dan Filter (<search> dari modern-web-guidance: forms) */}
      <search
        aria-label="Pencarian dan Penyaringan Direktori Destinasi"
        className="bg-white p-5 lg:p-6 rounded-3xl border border-[#E4E9DA] shadow-sm"
      >
        <form
          method="get"
          action="/destinations"
          onSubmit={(e) => e.preventDefault()}
          className="grid grid-cols-1 lg:grid-cols-12 gap-4 items-end"
        >
          {/* Pencarian Kata Kunci */}
          <div className="lg:col-span-4 flex flex-col items-start gap-1.5">
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
                autoCorrect="off"
                autoCapitalize="none"
                spellCheck={false}
                className="w-full min-h-[48px] pl-10 pr-4 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#767676] text-sm text-[#1B1F1A] font-medium"
              />
            </div>
          </div>

          {/* Filter Kabupaten / Kota */}
          <div className="lg:col-span-3 flex flex-col items-start gap-1.5">
            <label
              htmlFor="filter-regency"
              className="text-xs font-bold text-[#1B1F1A]"
            >
              Wilayah Kabupaten / Kota
            </label>
            <select
              id="filter-regency"
              name="city_regency"
              value={selectedRegency}
              onChange={(e) => setSelectedRegency(e.target.value)}
              className="w-full min-h-[48px] px-4 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#767676] text-sm text-[#1B1F1A] font-semibold"
            >
              {SUMBAR_REGENCIES.map((reg) => (
                <option key={reg} value={reg}>
                  {reg}
                </option>
              ))}
            </select>
          </div>

          {/* Filter Tingkat Keramaian */}
          <div className="lg:col-span-3 flex flex-col items-start gap-1.5">
            <span className="text-xs font-bold text-[#1B1F1A]">
              Tingkat Keramaian Kunjungan
            </span>
            <div className="w-full flex items-center gap-1 bg-[#F6F3EC] p-1 rounded-2xl border border-[#CFD8BE] min-h-[48px]">
              {(['Semua', 'Sepi', 'Sedang', 'Ramai'] as const).map((lvl) => (
                <button
                  key={lvl}
                  type="button"
                  onClick={() => setSelectedCrowd(lvl)}
                  className={`flex-1 py-2 px-2 rounded-xl text-xs font-bold transition min-h-[40px] ${
                    selectedCrowd === lvl
                      ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
                      : 'text-[#1B1F1A] hover:bg-[#E4E9DA]/60'
                  }`}
                >
                  {lvl}
                </button>
              ))}
            </div>
          </div>

          {/* Filter Khusus Blank Spot */}
          <div className="lg:col-span-2 flex items-center">
            <label
              htmlFor="filter-blankspot"
              className={`w-full min-h-[48px] px-3.5 py-2 rounded-2xl border text-xs font-bold flex items-center gap-2 cursor-pointer transition ${
                onlyBlankSpot
                  ? 'bg-[#F26B4B]/15 border-[#F26B4B] text-[#D95637]'
                  : 'bg-[#F6F3EC] border-[#CFD8BE] text-[#1B1F1A]'
              }`}
            >
              <input
                id="filter-blankspot"
                type="checkbox"
                checked={onlyBlankSpot}
                onChange={(e) => setOnlyBlankSpot(e.target.checked)}
                className="w-4 h-4 accent-[#F26B4B]"
              />
              <span>Zona Blank Spot</span>
            </label>
          </div>
        </form>

        {/* Status Hasil Penyaringan */}
        <div
          role="status"
          aria-live="polite"
          className="mt-3.5 pt-3.5 border-t border-[#E4E9DA] flex flex-wrap items-center justify-between gap-2 text-xs text-[#4A5248]"
        >
          <span>
            Menampilkan{' '}
            <strong className="text-[#1B1F1A]">
              {filteredAndSortedDestinations.length}
            </strong>{' '}
            dari <strong>{destinations.length}</strong> destinasi terdaftar
            {selectedRegency !== 'Semua Kab/Kota' && (
              <>
                {' '}
                di wilayah{' '}
                <strong className="text-[#234B24]">{selectedRegency}</strong>
              </>
            )}
          </span>

          {(searchQuery ||
            selectedRegency !== 'Semua Kab/Kota' ||
            selectedCrowd !== 'Semua' ||
            onlyBlankSpot) && (
            <button
              type="button"
              onClick={() => {
                setSearchQuery('');
                setSelectedRegency('Semua Kab/Kota');
                setSelectedCrowd('Semua');
                setOnlyBlankSpot(false);
              }}
              className="text-xs font-bold text-[#F26B4B] hover:underline"
            >
              Atur Ulang Semua Filter
            </button>
          )}
        </div>
      </search>

      {/* Pengumuman Status Urutan Tabel untuk Pembaca Layar (sortable-table guide) */}
      <div role="status" aria-live="polite" className="visually-hidden">
        {sortAnnouncement}
      </div>

      {/* Tabel Responsif & Dapat Diurutkan (responsive-table & sortable-table guides) */}
      <div
        tabIndex={0}
        role="region"
        aria-labelledby="destinations-table-caption"
        className="table-wrapper bg-white rounded-3xl border border-[#E4E9DA] shadow-sm"
      >
        <table className="wisgo-table rancak-table text-left text-sm">
          <caption
            id="destinations-table-caption"
            className="p-4 lg:px-6 text-left font-bold text-xs uppercase tracking-wider text-[#234B24] bg-[#E4E9DA]/50 border-b border-[#E4E9DA]"
          >
            Direktori Resmi Destinasi Wisata Sumatera Barat — Klik judul kolom
            untuk mengurutkan data
          </caption>
          <thead className="bg-[#234B24] text-[#F6F3EC] text-xs uppercase tracking-wider">
            <tr>
              <th
                scope="col"
                aria-sort={sortCol === 'name' ? sortDir : undefined}
              >
                <button
                  type="button"
                  onClick={() => handleSortClick('name', 'Nama Destinasi')}
                >
                  <span>Destinasi Wisata</span>
                  {renderSortIcon('name')}
                </button>
              </th>
              <th
                scope="col"
                aria-sort={sortCol === 'city_regency' ? sortDir : undefined}
              >
                <button
                  type="button"
                  onClick={() =>
                    handleSortClick('city_regency', 'Wilayah Kabupaten/Kota')
                  }
                >
                  <span>Wilayah &amp; Kategori</span>
                  {renderSortIcon('city_regency')}
                </button>
              </th>
              <th
                scope="col"
                aria-sort={sortCol === 'distance' ? sortDir : undefined}
              >
                <button
                  type="button"
                  onClick={() =>
                    handleSortClick('distance', 'Jarak & 4 Statistik Keputusan')
                  }
                >
                  <span>4 Statistik Keputusan</span>
                  {renderSortIcon('distance')}
                </button>
              </th>
              <th scope="col" className="py-3.5 px-4 font-bold">
                5 Indikator Kesiapan Medan
              </th>
              <th
                scope="col"
                aria-sort={sortCol === 'price' ? sortDir : undefined}
              >
                <button
                  type="button"
                  onClick={() =>
                    handleSortClick('price', 'Standar Tarif Resmi Perda')
                  }
                >
                  <span>Standar Tarif Perda</span>
                  {renderSortIcon('price')}
                </button>
              </th>
              <th scope="col" className="py-3.5 px-4 font-bold">
                Edukasi &amp; Adat
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
              const primaryTip = dest.tips?.[0];
              const isBlank =
                dest.is_blank_spot ||
                medan?.cellular_signal.toLowerCase().includes('blank') ||
                medan?.cellular_signal.toLowerCase().includes('zero');

              return (
                <tr
                  key={dest.id}
                  className="hover:bg-[#FAF8F3] transition-colors align-top"
                >
                  {/* Kolom 1: Sticky Row Header Nama Destinasi */}
                  <th
                    scope="row"
                    className="py-5 px-5 font-bold text-[#1B1F1A] min-w-[250px] border-r border-[#E4E9DA]/60"
                  >
                    <div className="flex items-start gap-3.5">
                      <img
                        src={dest.cover_image}
                        alt=""
                        loading="lazy"
                        className="w-16 h-16 rounded-2xl object-cover shrink-0 bg-[#E4E9DA] shadow-sm"
                      />
                      <div className="min-w-0">
                        <div className="flex flex-wrap items-center gap-1.5">
                          <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded bg-[#E4E9DA] text-[#234B24]">
                            {dest.id.toUpperCase()}
                          </span>
                          {isBlank && (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded bg-[#F26B4B]/15 text-[#D95637]">
                              <WifiOff
                                className="w-2.5 h-2.5"
                                aria-hidden="true"
                              />
                              Offline Pocket
                            </span>
                          )}
                        </div>
                        <div className="text-sm font-extrabold text-[#1B1F1A] mt-1 leading-snug">
                          {dest.name}
                        </div>
                        <div className="text-[11px] font-normal text-[#4A5248] mt-0.5">
                          GPS: {dest.latitude.toFixed(4)},{' '}
                          {dest.longitude.toFixed(4)}
                        </div>
                      </div>
                    </div>
                  </th>

                  {/* Kolom 2: Wilayah Kab/Kota & Kategori */}
                  <td className="py-5 px-4 min-w-[185px]">
                    <div className="inline-flex items-center gap-1.5 text-xs font-extrabold text-[#234B24]">
                      <MapPin
                        className="w-3.5 h-3.5 shrink-0 text-[#F26B4B]"
                        aria-hidden="true"
                      />
                      <span>{dest.city_regency}</span>
                    </div>
                    <div className="mt-1.5">
                      <span className="inline-block text-xs font-semibold px-2.5 py-0.5 rounded-full bg-[#F6F3EC] border border-[#CFD8BE] text-[#1B1F1A]">
                        {dest.category}
                      </span>
                    </div>
                  </td>

                  {/* Kolom 3: 4 Statistik Keputusan */}
                  <td
                    className="py-5 px-4 min-w-[205px]"
                    data-value={dest.estimated_distance_km ?? 0}
                  >
                    <div className="mb-2">
                      {renderCrowdBadge(dest.crowd_level)}
                    </div>
                    <div className="space-y-1 text-xs text-[#4A5248]">
                      <div className="flex items-center gap-1.5">
                        <Navigation
                          className="w-3.5 h-3.5 text-[#234B24]"
                          aria-hidden="true"
                        />
                        <span>
                          Jarak:{' '}
                          <strong className="text-[#1B1F1A]">
                            {dest.estimated_distance_km ?? 85} km
                          </strong>
                        </span>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <Clock
                          className="w-3.5 h-3.5 text-[#E85D1A]"
                          aria-hidden="true"
                        />
                        <span>
                          Tempuh:{' '}
                          <strong className="text-[#1B1F1A]">
                            {formatDuration(dest.estimated_duration_min)}
                          </strong>
                        </span>
                      </div>
                    </div>
                  </td>

                  {/* Kolom 4: 5 Indikator Medan */}
                  <td className="py-5 px-4 min-w-[260px]">
                    {medan ? (
                      <div className="flex flex-wrap gap-1.5 text-[11px]">
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#F6F3EC] border border-[#CFD8BE] font-semibold text-[#1B1F1A]">
                          <Car
                            className="w-3 h-3 text-[#234B24]"
                            aria-hidden="true"
                          />
                          {medan.vehicle_access}
                        </span>
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#F6F3EC] border border-[#CFD8BE] font-semibold text-[#1B1F1A]">
                          <Mountain
                            className="w-3 h-3 text-[#E85D1A]"
                            aria-hidden="true"
                          />
                          {medan.trekking_level}
                        </span>
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg font-bold ${
                            isBlank
                              ? 'bg-[#F26B4B]/15 text-[#D95637] border border-[#F26B4B]'
                              : 'bg-[#1E9E5A]/15 text-[#234B24]'
                          }`}
                        >
                          <WifiOff className="w-3 h-3" aria-hidden="true" />
                          {medan.cellular_signal}
                        </span>
                        <span className="inline-block px-2.5 py-1 rounded-lg bg-[#F6F3EC] text-[#4A5248] font-medium">
                          {medan.facilities}
                        </span>
                        <span className="inline-block px-2.5 py-1 rounded-lg bg-[#E4E9DA] text-[#234B24] font-bold">
                          Pemandu: {medan.guide_need}
                        </span>
                      </div>
                    ) : (
                      <span className="text-xs text-[#4A5248]">
                        Belum ditetapkan
                      </span>
                    )}
                  </td>

                  {/* Kolom 5: Standar Tarif Perda */}
                  <td
                    className="py-5 px-4 min-w-[215px]"
                    data-value={primaryTariff?.price ?? 0}
                  >
                    {primaryTariff ? (
                      <div>
                        <div className="flex items-center gap-1 text-xs font-extrabold text-[#234B24]">
                          <Receipt
                            className="w-3.5 h-3.5 text-[#E85D1A]"
                            aria-hidden="true"
                          />
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
                            +{(dest.tariffs?.length || 1) - 1} komponen tarif
                            lainnya
                          </span>
                        )}
                      </div>
                    ) : (
                      <span className="text-xs text-[#4A5248]">
                        Belum ada tarif
                      </span>
                    )}
                  </td>

                  {/* Kolom 6: Tips Menjaga Tempat */}
                  <td className="py-5 px-4 min-w-[235px]">
                    {primaryTip ? (
                      <div className="p-3 rounded-2xl bg-[#E4E9DA]/60 border border-[#CFD8BE] text-xs text-[#1B1F1A]">
                        <div className="flex items-center gap-1 font-bold text-[#234B24] mb-1">
                          <Sparkles
                            className="w-3.5 h-3.5 shrink-0"
                            aria-hidden="true"
                          />
                          <span>
                            {primaryTip.is_important
                              ? 'Peringatan Adat & Alam'
                              : 'Panduan Etika Kunjungan'}
                          </span>
                        </div>
                        <p className="text-[11px] leading-relaxed line-clamp-3">
                          {primaryTip.content}
                        </p>
                      </div>
                    ) : (
                      <span className="text-xs text-[#4A5248]">-</span>
                    )}
                  </td>

                  {/* Kolom 7: Tindakan Pengelolaan Lengkap */}
                  <td className="py-5 px-5 text-right whitespace-nowrap">
                    <div className="flex flex-col items-end gap-2">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={() => setViewingDest(dest)}
                          className="min-h-[38px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#1B1F1A] border border-[#CFD8BE] font-bold text-xs inline-flex items-center gap-1.5 transition"
                        >
                          <Eye
                            className="w-3.5 h-3.5 text-[#234B24]"
                            aria-hidden="true"
                          />
                          <span>Detail</span>
                        </button>

                        <button
                          type="button"
                          onClick={() => handleOpenEditModal(dest)}
                          className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs inline-flex items-center gap-1.5 transition shadow-sm"
                        >
                          <Edit3 className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Edit</span>
                        </button>
                      </div>

                      <div className="inline-flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={() => onOpenTariffManager(dest.id)}
                          className="min-h-[38px] px-3 py-1.5 rounded-xl bg-[#E4E9DA]/80 hover:bg-[#234B24] hover:text-white text-[#234B24] font-bold text-xs inline-flex items-center gap-1.5 transition"
                        >
                          <Receipt className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Kelola Tarif &amp; QR</span>
                        </button>

                        <button
                          type="button"
                          onClick={() => onOpenSmartQRModal(dest)}
                          title="Pratinjau & Cetak Plang Smart QR"
                          className="min-h-[38px] px-2.5 py-1.5 rounded-xl bg-white hover:bg-[#1E9E5A] hover:text-white text-[#1E9E5A] border border-[#1E9E5A]/40 font-bold text-xs inline-flex items-center gap-1 transition"
                        >
                          <QrCode className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Plang QR</span>
                        </button>

                        <button
                          type="button"
                          aria-label={`Hapus destinasi ${dest.name}`}
                          onClick={() => setDeletingDest(dest)}
                          className="min-h-[38px] px-2.5 py-1.5 rounded-xl bg-[#F26B4B]/10 hover:bg-[#F26B4B] hover:text-white text-[#D95637] border border-[#F26B4B]/30 font-bold text-xs inline-flex items-center justify-center transition"
                        >
                          <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                        </button>
                      </div>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* =====================================================================
          MODAL EDITOR DESTINASI 3 BAGIAN (FS1-M1-03)
          Bagian A: Profil & 4 Statistik Keputusan
          Bagian B: Editor Visual 5 Indikator Medan
          Bagian C: Edukasi & Adat (Tips Menjaga Tempat Ini)
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
            {/* Bagian a) Header Modal Editor (shrink-0) */}
            <div className="shrink-0 bg-[#234B24] text-[#F6F3EC] px-6 py-5 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#A7F3D0]">
                  Formulir Manajemen Destinasi &amp; Kesiapan Medan ({editingDest.id.toUpperCase()})
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

            {/* Bagian b) Baris Tab Navigasi (shrink-0 bg-[#F6F3EC] border-b border-[#234B24]/15 px-6 py-3) */}
            <div
              role="tablist"
              aria-label="Tahapan Pengisian Data Destinasi"
              className="shrink-0 bg-[#F6F3EC] border-b border-[#234B24]/15 px-6 py-3"
            >
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {(
                  [
                    {
                      key: 'A',
                      title: 'Bagian A: Profil & 4 Statistik',
                    },
                    {
                      key: 'B',
                      title: 'Bagian B: 5 Indikator Medan',
                    },
                    {
                      key: 'C',
                      title: 'Bagian C: Edukasi & Adat',
                    },
                    {
                      key: 'D',
                      title: 'Bagian D: Foto & Media Lokal',
                    },
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
                      className={`min-h-[44px] px-3 py-2 rounded-xl text-xs font-bold transition flex items-center justify-center text-center ${
                        selected
                          ? 'bg-[#234B24] text-white shadow-xs'
                          : 'bg-white text-[#234B24] border border-[#CFD8BE] hover:bg-[#E4E9DA]'
                      }`}
                    >
                      {tab.title}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Bagian c) Kontainer Isi Form (flex-1 min-h-0 overflow-y-auto p-6 space-y-5) */}
            <div className="flex-1 min-h-0 overflow-y-auto p-6 space-y-5">
              {/* PANEL BAGIAN A: PROFIL & 4 STATISTIK KEPUTUSAN */}
              <div
                role="tabpanel"
                aria-labelledby="editor-tab-A"
                hidden={editorTab !== 'A'}
              >
                <div className="space-y-5">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label
                        htmlFor="dest-name"
                        className="text-xs font-bold text-[#1B1F1A]"
                      >
                        Nama Destinasi Wisata *
                      </label>
                      <input
                        id="dest-name"
                        type="text"
                        required
                        placeholder="Contoh: Lembah Harau / Istano Basa Pagaruyung"
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
                      <label
                        htmlFor="dest-regency"
                        className="text-xs font-bold text-[#1B1F1A]"
                      >
                        Wilayah Kabupaten / Kota (19 Kab/Kota) *
                      </label>
                      <select
                        id="dest-regency"
                        value={editingDest.city_regency}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            city_regency: e.target.value,
                          })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                      >
                        {SUMBAR_REGENCIES.filter(
                          (r) => r !== 'Semua Kab/Kota'
                        ).map((reg) => (
                          <option key={reg} value={reg}>
                            {reg}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div className="flex flex-col gap-1.5">
                      <label
                        htmlFor="dest-category"
                        className="text-xs font-bold text-[#1B1F1A]"
                      >
                        Kategori Wisata *
                      </label>
                      <select
                        id="dest-category"
                        value={editingDest.category}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            category: e.target.value,
                          })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                      >
                        {DESTINATION_CATEGORIES.map((cat) => (
                          <option key={cat} value={cat}>
                            {cat}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label
                        htmlFor="dest-lat"
                        className="text-xs font-bold text-[#1B1F1A]"
                      >
                        Garis Lintang (Latitude GPS) *
                      </label>
                      <input
                        id="dest-lat"
                        type="number"
                        step="0.0001"
                        required
                        value={editingDest.latitude}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            latitude: Number(e.target.value),
                          })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-mono"
                      />
                    </div>

                    <div className="flex flex-col gap-1.5">
                      <label
                        htmlFor="dest-lng"
                        className="text-xs font-bold text-[#1B1F1A]"
                      >
                        Garis Bujur (Longitude GPS) *
                      </label>
                      <input
                        id="dest-lng"
                        type="number"
                        step="0.0001"
                        required
                        value={editingDest.longitude}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            longitude: Number(e.target.value),
                          })
                        }
                        className="min-h-[48px] px-4 py-2.5 rounded-2xl bg-white border border-[#767676] text-sm font-mono"
                      />
                    </div>
                  </div>

                  {/* Fieldset 4 Statistik Keputusan */}
                  <fieldset className="p-5 rounded-3xl bg-white border border-[#CFD8BE]">
                    <legend className="text-xs font-extrabold uppercase tracking-wider text-[#234B24] px-2">
                      4 Statistik Keputusan Wisatawan (Paruh Atas Layar)
                    </legend>
                    <div className="mt-2 grid grid-cols-1 sm:grid-cols-4 gap-4">
                      <div className="flex flex-col gap-1">
                        <label
                          htmlFor="stat-distance"
                          className="text-xs font-bold text-[#1B1F1A]"
                        >
                          1. Estimasi Jarak (km)
                        </label>
                        <input
                          id="stat-distance"
                          type="number"
                          min={1}
                          value={editingDest.estimated_distance_km ?? 85}
                          onChange={(e) =>
                            setEditingDest({
                              ...editingDest,
                              estimated_distance_km: Number(e.target.value),
                            })
                          }
                          className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                        />
                      </div>

                      <div className="flex flex-col gap-1">
                        <label
                          htmlFor="stat-duration"
                          className="text-xs font-bold text-[#1B1F1A]"
                        >
                          2. Waktu Tempuh (menit)
                        </label>
                        <input
                          id="stat-duration"
                          type="number"
                          min={5}
                          value={editingDest.estimated_duration_min ?? 120}
                          onChange={(e) =>
                            setEditingDest({
                              ...editingDest,
                              estimated_duration_min: Number(e.target.value),
                            })
                          }
                          className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                        />
                      </div>

                      <div className="flex flex-col gap-1">
                        <label
                          htmlFor="stat-crowd"
                          className="text-xs font-bold text-[#1B1F1A]"
                        >
                          3. Status Keramaian
                        </label>
                        <select
                          id="stat-crowd"
                          value={editingDest.crowd_level}
                          onChange={(e) =>
                            setEditingDest({
                              ...editingDest,
                              crowd_level: e.target.value,
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
                        <label
                          htmlFor="stat-ticket"
                          className="text-xs font-bold text-[#1B1F1A]"
                        >
                          4. Ringkasan Biaya Tiket
                        </label>
                        <input
                          id="stat-ticket"
                          type="text"
                          placeholder="Rp 15.000 / orang"
                          value={editingDest.ticket_price_summary ?? ''}
                          onChange={(e) =>
                            setEditingDest({
                              ...editingDest,
                              ticket_price_summary: e.target.value,
                            })
                          }
                          className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold text-[#234B24]"
                        />
                      </div>
                    </div>
                  </fieldset>

                  {/* Sakelar Kawasan Blank Spot (Wajib Unduh Offline Pocket) */}
                  <div className="p-4 rounded-2xl bg-[#F26B4B]/10 border border-[#F26B4B]/40 flex items-center justify-between gap-4">
                    <div className="flex items-start gap-3">
                      <WifiOff
                        className="w-5 h-5 text-[#F26B4B] shrink-0 mt-0.5"
                        aria-hidden="true"
                      />
                      <div>
                        <label
                          htmlFor="dest-blankspot-toggle"
                          className="text-xs font-extrabold text-[#1B1F1A] cursor-pointer"
                        >
                          Kawasan Blank Spot (Wajib Unduh Offline Pocket)
                        </label>
                        <p className="text-xs text-[#4A5248] mt-0.5">
                          Aktifkan jika lokasi wisata berada di lembah/hutan
                          tanpa sinyal seluler agar aplikasi wisatawan otomatis
                          menyimpan peta mikro &amp; tiket QR di memori lokal.
                        </p>
                      </div>
                    </div>
                    <input
                      id="dest-blankspot-toggle"
                      type="checkbox"
                      checked={Boolean(editingDest.is_blank_spot)}
                      onChange={(e) => {
                        const checked = e.target.checked;
                        setEditingDest({
                          ...editingDest,
                          is_blank_spot: checked,
                          medan_indicator: {
                            ...editingDest.medan_indicator!,
                            cellular_signal: checked
                              ? 'Zero-Signal (Blank Spot)'
                              : '4G Lancar',
                            signal_score: checked ? 1 : 5,
                          },
                        });
                      }}
                      className="w-6 h-6 accent-[#F26B4B] shrink-0 cursor-pointer"
                    />
                  </div>

                  {/* Deskripsi Kawasan Wisata */}
                  <div className="flex flex-col gap-1.5">
                    <label
                      htmlFor="dest-desc"
                      className="text-xs font-bold text-[#1B1F1A]"
                    >
                      Deskripsi Ringkas Kawasan Wisata
                    </label>
                    <textarea
                      id="dest-desc"
                      rows={3}
                      value={editingDest.description}
                      onChange={(e) =>
                        setEditingDest({
                          ...editingDest,
                          description: e.target.value,
                        })
                      }
                      placeholder="Tuliskan gambaran daya tarik wisata, sejarah, atau keunikan alam..."
                      className="p-3.5 rounded-2xl bg-white border border-[#767676] text-sm"
                    />
                  </div>
                </div>
              </div>

              {/* PANEL BAGIAN B: EDITOR VISUAL 5 INDIKATOR MEDAN */}
              <div
                role="tabpanel"
                aria-labelledby="editor-tab-B"
                hidden={editorTab !== 'B'}
              >
                <div className="space-y-5">
                  <div className="p-4 rounded-2xl bg-[#E4E9DA] border border-[#CFD8BE] text-xs text-[#1B1F1A]">
                    <strong>Panduan Penilaian Medan:</strong> Atur kategori dan
                    skor kesiapan (1–5) untuk setiap indikator agar wisatawan
                    keluarga, lansia, maupun penjelajah mengetahui kondisi riil
                    sebelum berangkat.
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Indikator 1: Akses Kendaraan */}
                    <div className="bg-white p-5 rounded-3xl border border-[#CFD8BE] space-y-3">
                      <div className="flex items-center justify-between">
                        <label
                          htmlFor="medan-vehicle"
                          className="text-xs font-extrabold uppercase text-[#234B24]"
                        >
                          1. Akses Kendaraan
                        </label>
                        <span className="text-xs font-extrabold px-2.5 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                          Skor Kesiapan:{' '}
                          {editingDest.medan_indicator?.vehicle_score ?? 5} / 5
                        </span>
                      </div>
                      <select
                        id="medan-vehicle"
                        value={
                          editingDest.medan_indicator?.vehicle_access ||
                          'Mobil OK'
                        }
                        onChange={(e) => {
                          const val = e.target.value;
                          const autoScore =
                            val === 'Mobil OK'
                              ? 5
                              : val === 'Hanya Motor'
                              ? 3
                              : 2;
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              vehicle_access: val,
                              vehicle_score: autoScore,
                            },
                          });
                        }}
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Mobil OK">
                          Mobil OK (Roda Empat &amp; Bus)
                        </option>
                        <option value="Hanya Motor">
                          Hanya Motor (Jalur Sempit)
                        </option>
                        <option value="Jalan Kaki">
                          Jalan Kaki Saja (Trek Khusus)
                        </option>
                      </select>
                      <input
                        type="range"
                        min={1}
                        max={5}
                        aria-label="Skor Akses Kendaraan 1 sampai 5"
                        value={editingDest.medan_indicator?.vehicle_score ?? 5}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              vehicle_score: Number(e.target.value),
                            },
                          })
                        }
                        className="w-full accent-[#234B24]"
                      />
                    </div>

                    {/* Indikator 2: Tingkat Kesulitan Trekking */}
                    <div className="bg-white p-5 rounded-3xl border border-[#CFD8BE] space-y-3">
                      <div className="flex items-center justify-between">
                        <label
                          htmlFor="medan-trekking"
                          className="text-xs font-extrabold uppercase text-[#234B24]"
                        >
                          2. Tingkat Kesulitan Trekking
                        </label>
                        <span className="text-xs font-extrabold px-2.5 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                          Skor Kemudahan:{' '}
                          {editingDest.medan_indicator?.trekking_score ?? 5} / 5
                        </span>
                      </div>
                      <select
                        id="medan-trekking"
                        value={
                          editingDest.medan_indicator?.trekking_level ||
                          'Landai / Mudah'
                        }
                        onChange={(e) => {
                          const val = e.target.value;
                          const autoScore = val.includes('Landai')
                            ? 5
                            : val === 'Sedang'
                            ? 3
                            : 2;
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              trekking_level: val,
                              trekking_score: autoScore,
                            },
                          });
                        }}
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Landai / Mudah">
                          Landai / Mudah (Ramah Lansia &amp; Anak)
                        </option>
                        <option value="Sedang">
                          Sedang (Berundak / Tanjakan Ringan)
                        </option>
                        <option value="Curam / Ekstrem">
                          Curam / Ekstrem (Butuh Fisik Prima)
                        </option>
                      </select>
                      <input
                        type="range"
                        min={1}
                        max={5}
                        aria-label="Skor Kemudahan Trekking 1 sampai 5"
                        value={editingDest.medan_indicator?.trekking_score ?? 5}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              trekking_score: Number(e.target.value),
                            },
                          })
                        }
                        className="w-full accent-[#234B24]"
                      />
                    </div>

                    {/* Indikator 3: Kualitas Sinyal Seluler */}
                    <div className="bg-white p-5 rounded-3xl border border-[#CFD8BE] space-y-3">
                      <div className="flex items-center justify-between">
                        <label
                          htmlFor="medan-signal"
                          className="text-xs font-extrabold uppercase text-[#234B24]"
                        >
                          3. Kualitas Sinyal Seluler
                        </label>
                        <span className="text-xs font-extrabold px-2.5 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                          Skor Sinyal:{' '}
                          {editingDest.medan_indicator?.signal_score ?? 5} / 5
                        </span>
                      </div>
                      <select
                        id="medan-signal"
                        value={
                          editingDest.medan_indicator?.cellular_signal ||
                          '4G Lancar'
                        }
                        onChange={(e) => {
                          const val = e.target.value;
                          const isBlank =
                            val.toLowerCase().includes('blank') ||
                            val.toLowerCase().includes('zero');
                          const autoScore = isBlank
                            ? 1
                            : val === 'Sinyal Lemah'
                            ? 3
                            : 5;
                          setEditingDest({
                            ...editingDest,
                            is_blank_spot: isBlank,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              cellular_signal: val,
                              signal_score: autoScore,
                            },
                          });
                        }}
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="4G Lancar">
                          4G Lancar (Semua Operator)
                        </option>
                        <option value="Sinyal Lemah">
                          Sinyal Lemah (Titik Tertentu)
                        </option>
                        <option value="Zero-Signal (Blank Spot)">
                          Zero-Signal (Blank Spot — Wajib Offline)
                        </option>
                      </select>
                      <input
                        type="range"
                        min={1}
                        max={5}
                        aria-label="Skor Kualitas Sinyal 1 sampai 5"
                        value={editingDest.medan_indicator?.signal_score ?? 5}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              signal_score: Number(e.target.value),
                            },
                          })
                        }
                        className="w-full accent-[#234B24]"
                      />
                    </div>

                    {/* Indikator 4: Ketersediaan Fasilitas Resmi */}
                    <div className="bg-white p-5 rounded-3xl border border-[#CFD8BE] space-y-3">
                      <div className="flex items-center justify-between">
                        <label
                          htmlFor="medan-facilities"
                          className="text-xs font-extrabold uppercase text-[#234B24]"
                        >
                          4. Ketersediaan Fasilitas Resmi
                        </label>
                        <span className="text-xs font-extrabold px-2.5 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                          Skor Fasilitas:{' '}
                          {editingDest.medan_indicator?.facilities_score ?? 5} /
                          5
                        </span>
                      </div>
                      <select
                        id="medan-facilities"
                        value={
                          editingDest.medan_indicator?.facilities ||
                          'Toilet, Musala & Parkir Lengkap'
                        }
                        onChange={(e) => {
                          const val = e.target.value;
                          const autoScore = val.includes('Lengkap')
                            ? 5
                            : val === 'Terbatas'
                            ? 3
                            : 1;
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              facilities: val,
                              facilities_score: autoScore,
                            },
                          });
                        }}
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Toilet, Musala & Parkir Lengkap">
                          Toilet, Musala &amp; Parkir Lengkap
                        </option>
                        <option value="Terbatas">
                          Terbatas (Fasilitas Dasar)
                        </option>
                        <option value="Belum Ada">
                          Belum Ada (Kawasan Alami Murni)
                        </option>
                      </select>
                      <input
                        type="range"
                        min={1}
                        max={5}
                        aria-label="Skor Ketersediaan Fasilitas 1 sampai 5"
                        value={
                          editingDest.medan_indicator?.facilities_score ?? 5
                        }
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              facilities_score: Number(e.target.value),
                            },
                          })
                        }
                        className="w-full accent-[#234B24]"
                      />
                    </div>

                    {/* Indikator 5: Kebutuhan Pemandu Lokal / Pokdarwis */}
                    <div className="md:col-span-2 bg-white p-5 rounded-3xl border border-[#CFD8BE] space-y-3">
                      <div className="flex items-center justify-between">
                        <label
                          htmlFor="medan-guide"
                          className="text-xs font-extrabold uppercase text-[#234B24]"
                        >
                          5. Kebutuhan Pemandu Lokal / Pokdarwis
                        </label>
                        <span className="text-xs font-extrabold px-2.5 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                          Skor Kemandirian:{' '}
                          {editingDest.medan_indicator?.guide_score ?? 5} / 5
                        </span>
                      </div>
                      <select
                        id="medan-guide"
                        value={
                          editingDest.medan_indicator?.guide_need || 'Mandiri'
                        }
                        onChange={(e) => {
                          const val = e.target.value;
                          const autoScore =
                            val === 'Mandiri'
                              ? 5
                              : val === 'Disarankan'
                              ? 3
                              : 1;
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              guide_need: val,
                              guide_score: autoScore,
                            },
                          });
                        }}
                        className="w-full min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm font-bold"
                      >
                        <option value="Mandiri">
                          Bisa Mandiri (Jalur Jelas &amp; Berambu)
                        </option>
                        <option value="Disarankan">
                          Disarankan Pemandu Lokal / Sejarah
                        </option>
                        <option value="Wajib Pemandu">
                          Wajib Pemandu Resmi Pokdarwis
                        </option>
                      </select>
                      <input
                        type="range"
                        min={1}
                        max={5}
                        aria-label="Skor Kemandirian Kunjungan 1 sampai 5"
                        value={editingDest.medan_indicator?.guide_score ?? 5}
                        onChange={(e) =>
                          setEditingDest({
                            ...editingDest,
                            medan_indicator: {
                              ...editingDest.medan_indicator!,
                              guide_score: Number(e.target.value),
                            },
                          })
                        }
                        className="w-full accent-[#234B24]"
                      />
                    </div>
                  </div>

                  {/* Catatan Kesiapan Fisik & Kendaraan */}
                  <div className="flex flex-col gap-1.5">
                    <label
                      htmlFor="medan-notes"
                      className="text-xs font-bold text-[#1B1F1A]"
                    >
                      Deskripsi Kesiapan Fisik &amp; Kendaraan di Lapangan
                    </label>
                    <textarea
                      id="medan-notes"
                      rows={2}
                      placeholder="Contoh: Gunakan gigi rendah saat menuruni Kelok 44, atau wajib sepatu anti-selip..."
                      value={
                        editingDest.medan_indicator?.readiness_notes || ''
                      }
                      onChange={(e) =>
                        setEditingDest({
                          ...editingDest,
                          medan_indicator: {
                            ...editingDest.medan_indicator!,
                            readiness_notes: e.target.value,
                          },
                        })
                      }
                      className="p-3.5 rounded-2xl bg-white border border-[#767676] text-sm"
                    />
                  </div>
                </div>
              </div>

              {/* PANEL BAGIAN C: EDUKASI & ADAT (TIPS MENJAGA TEMPAT INI) */}
              <div
                role="tabpanel"
                aria-labelledby="editor-tab-C"
                hidden={editorTab !== 'C'}
              >
                <div className="space-y-4">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div>
                      <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                        Daftar &ldquo;Tips Menjaga Tempat Ini&rdquo; (Etika Adat
                        &amp; Kelestarian Alam)
                      </h3>
                      <p className="text-xs text-[#4A5248]">
                        Ditampilkan pada kartu edukasi hijau sage di layar
                        detail destinasi wisatawan.
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={handleAddTipRow}
                      className="min-h-[42px] px-4 py-2 rounded-pill bg-[#234B24] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 shadow-xs"
                    >
                      <Plus className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>Tambah Butir Panduan</span>
                    </button>
                  </div>

                  <div className="space-y-3">
                    {(editingDest.tips || []).map((tip, idx) => (
                      <div
                        key={tip.id}
                        className="bg-white p-4 rounded-2xl border border-[#CFD8BE] space-y-3"
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
                                checked={tip.is_important}
                                onChange={(e) =>
                                  handleUpdateTipRow(tip.id, {
                                    is_important: e.target.checked,
                                  })
                                }
                                className="w-4 h-4 accent-[#F26B4B]"
                              />
                              <AlertTriangle
                                className="w-3.5 h-3.5"
                                aria-hidden="true"
                              />
                              <span>Tandai sebagai Peringatan Penting</span>
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
                          placeholder="Tuliskan pesan etika adat Minangkabau, keselamatan, atau pelestarian lingkungan..."
                          value={tip.content}
                          onChange={(e) =>
                            handleUpdateTipRow(tip.id, {
                              content: e.target.value,
                            })
                          }
                          className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#767676] text-sm"
                        />
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* PANEL BAGIAN D: FOTO & MEDIA LOKAL */}
              <div
                role="tabpanel"
                aria-labelledby="editor-tab-D"
                hidden={editorTab !== 'D'}
              >
                <div className="space-y-5">
                  <div className="p-4 rounded-2xl bg-[#E4E9DA] border border-[#CFD8BE] text-xs text-[#1B1F1A]">
                    <strong>Standarisasi Media Resmi:</strong> Unggah foto lanskap berkualitas tinggi langsung dari perangkat komputer/laptop Anda. Sistem secara otomatis mengoptimalkan dan mengompresi gambar ke format WebP ringan agar pemuatan di perangkat wisatawan sangat cepat.
                  </div>

                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
                    {/* Komponen Pengunggah File Lokal */}
                    <div className="space-y-3">
                      <ImageDropzone
                        label="Foto Sampul Utama Destinasi"
                        value={editingDest.cover_image}
                        onChange={(dataUrl) =>
                          setEditingDest({
                            ...editingDest,
                            cover_image: dataUrl,
                          })
                        }
                        onClear={() =>
                          setEditingDest({
                            ...editingDest,
                            cover_image: '',
                          })
                        }
                        helperText="Pilih foto dari device (JPG, PNG, WebP). Kompresi kanvas otomatis menjaga penyimpanan tetap optimal."
                      />

                      <div className="p-4 rounded-2xl bg-white border border-[#CFD8BE] space-y-2">
                        <span className="text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
                          Integrasi URL Pintar
                        </span>
                        <div className="flex items-center gap-2 text-xs text-[#4A5248]">
                          <span>Slug Smart QR Otomatis:</span>
                          <strong className="text-[#234B24] font-mono">
                            /qr/{editingDest.slug || toDestinationSlug(editingDest.name || 'destinasi')}
                          </strong>
                        </div>
                        <p className="text-[11px] text-[#4A5248]">
                          Tautan ini otomatis dihubungkan dengan plang fisik QR Perda, stiker retribusi resmi, dan aplikasi panduan luring.
                        </p>
                      </div>
                    </div>

                    {/* Pratinjau Tampilan Kartu Wisatawan */}
                    <div className="space-y-2">
                      <span className="text-xs font-bold text-[#1B1F1A]">
                        Pratinjau Kartu di Aplikasi Wisatawan
                      </span>
                      <div className="bg-white rounded-3xl border border-[#CFD8BE] overflow-hidden shadow-sm">
                        <div className="relative h-44 bg-[#234B24]/10">
                          {editingDest.cover_image ? (
                            <img
                              src={editingDest.cover_image}
                              alt={editingDest.name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex flex-col items-center justify-center text-[#4A5248] text-xs">
                              <Eye className="w-6 h-6 text-[#234B24]/40 mb-1" />
                              <span>Belum ada foto yang dipilih</span>
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
                            {editingDest.description || 'Deskripsi destinasi akan tampil di sini untuk memandu wisatawan.'}
                          </p>
                          <div className="pt-2 border-t border-[#CFD8BE]/50 flex items-center justify-between text-xs">
                            <span className="font-bold text-[#234B24]">
                              {editingDest.ticket_price_summary || 'Tarif Resmi Perda'}
                            </span>
                            <span className="text-[#4A5248]">
                              {editingDest.estimated_distance_km || 0} km • ± {editingDest.estimated_duration_min || 0} mnt
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Bagian d) Sticky Action Footer (shrink-0 border-t border-[#234B24]/15 bg-white px-6 py-4 flex flex-wrap items-center justify-between gap-3) */}
            <div className="shrink-0 border-t border-[#234B24]/15 bg-white px-6 py-4 flex flex-wrap items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  disabled={editorTab === 'A'}
                  onClick={() => {
                    const tabs: EditorTabKey[] = ['A', 'B', 'C', 'D'];
                    const currIdx = tabs.indexOf(editorTab);
                    if (currIdx > 0) setEditorTab(tabs[currIdx - 1]);
                  }}
                  className="min-h-[44px] px-4 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#E4E9DA] transition"
                >
                  ← Sebelumnya
                </button>
                <button
                  type="button"
                  disabled={editorTab === 'D'}
                  onClick={() => {
                    const tabs: EditorTabKey[] = ['A', 'B', 'C', 'D'];
                    const currIdx = tabs.indexOf(editorTab);
                    if (currIdx < tabs.length - 1) setEditorTab(tabs[currIdx + 1]);
                  }}
                  className="min-h-[44px] px-4 rounded-xl bg-[#234B24]/10 border border-[#234B24]/20 text-xs font-bold text-[#234B24] disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#234B24]/20 transition"
                >
                  Selanjutnya →
                </button>
                <span className="text-xs text-[#4A5248] hidden sm:inline ml-2">
                  Tab aktif: <strong>Bagian {editorTab}</strong>
                </span>
              </div>

              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setEditingDest(null)}
                  className="min-h-[44px] px-5 rounded-pill bg-[#F6F3EC] border border-[#767676] text-xs font-bold text-[#1B1F1A] hover:bg-[#E4E9DA] transition"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[46px] px-7 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-sm font-bold shadow-md transition"
                >
                  {isNewDest
                    ? 'Simpan Destinasi Baru'
                    : 'Simpan Seluruh Perubahan'}
                </button>
              </div>
            </div>
          </form>
        )}
      </dialog>

      {/* =====================================================================
          MODAL DETAIL DESTINASI LENGKAP
         ===================================================================== */}
      <dialog
        ref={detailDialogRef}
        aria-labelledby="detail-modal-title"
        onClose={() => setViewingDest(null)}
        className="w-full max-w-3xl rounded-[28px] p-0 bg-transparent"
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
                <div className="flex items-center gap-2">
                  <span className="px-2.5 py-0.5 rounded-full bg-[#1E9E5A] text-[11px] font-bold">
                    {viewingDest.city_regency}
                  </span>
                  <span className="px-2.5 py-0.5 rounded-full bg-white/20 text-[11px] font-bold">
                    {viewingDest.category}
                  </span>
                </div>
                <h2
                  id="detail-modal-title"
                  className="text-2xl font-extrabold mt-1"
                >
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

            <div className="p-6 lg:p-8 space-y-6">
              <p className="text-sm text-[#1B1F1A] leading-relaxed">
                {viewingDest.description}
              </p>

              {/* Grid 4 Statistik Keputusan */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">
                    Estimasi Jarak
                  </div>
                  <div className="text-base font-extrabold text-[#1B1F1A] mt-0.5">
                    {viewingDest.estimated_distance_km ?? 85} km
                  </div>
                </div>
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">
                    Waktu Tempuh
                  </div>
                  <div className="text-base font-extrabold text-[#1B1F1A] mt-0.5">
                    {formatDuration(viewingDest.estimated_duration_min)}
                  </div>
                </div>
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">
                    Status Keramaian
                  </div>
                  <div className="mt-1">
                    {renderCrowdBadge(viewingDest.crowd_level)}
                  </div>
                </div>
                <div className="bg-white p-3.5 rounded-2xl border border-[#CFD8BE]">
                  <div className="text-[11px] font-bold text-[#4A5248]">
                    Tiket Utama
                  </div>
                  <div className="text-sm font-extrabold text-[#234B24] mt-0.5">
                    {viewingDest.tariffs?.[0]
                      ? formatRupiah(viewingDest.tariffs[0].price)
                      : viewingDest.ticket_price_summary || 'Gratis'}
                  </div>
                </div>
              </div>

              {/* 5 Indikator Medan */}
              {viewingDest.medan_indicator && (
                <div className="bg-white p-5 rounded-3xl border border-[#CFD8BE] space-y-3">
                  <h3 className="text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
                    5 Indikator Kesiapan Medan Lapangan
                  </h3>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Akses Kendaraan:</span>
                      <strong className="text-[#1B1F1A]">
                        {viewingDest.medan_indicator.vehicle_access} (Skor{' '}
                        {viewingDest.medan_indicator.vehicle_score ?? 5}/5)
                      </strong>
                    </div>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Tingkat Trekking:</span>
                      <strong className="text-[#1B1F1A]">
                        {viewingDest.medan_indicator.trekking_level} (Skor{' '}
                        {viewingDest.medan_indicator.trekking_score ?? 4}/5)
                      </strong>
                    </div>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Sinyal Seluler:</span>
                      <strong className="text-[#1B1F1A]">
                        {viewingDest.medan_indicator.cellular_signal} (Skor{' '}
                        {viewingDest.medan_indicator.signal_score ?? 4}/5)
                      </strong>
                    </div>
                    <div className="p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Fasilitas Resmi:</span>
                      <strong className="text-[#1B1F1A]">
                        {viewingDest.medan_indicator.facilities}
                      </strong>
                    </div>
                    <div className="sm:col-span-2 p-3 rounded-xl bg-[#F6F3EC] flex justify-between">
                      <span className="text-[#4A5248]">Kebutuhan Pemandu:</span>
                      <strong className="text-[#234B24]">
                        {viewingDest.medan_indicator.guide_need}
                      </strong>
                    </div>
                  </div>
                  {viewingDest.medan_indicator.readiness_notes && (
                    <p className="text-xs text-[#4A5248] pt-1">
                      <strong>Catatan Lapangan:</strong>{' '}
                      {viewingDest.medan_indicator.readiness_notes}
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

      {/* =====================================================================
          DIALOG KONFIRMASI HAPUS DESTINASI (dialog guide: autofocus Batal)
         ===================================================================== */}
      <dialog
        ref={deleteDialogRef}
        aria-labelledby="delete-dest-title"
        onClose={() => setDeletingDest(null)}
        className="w-full max-w-md rounded-[28px] p-0 bg-transparent"
      >
        {deletingDest && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] p-6 lg:p-7 rounded-[28px] border border-[#CFD8BE] shadow-2xl">
            <h3
              id="delete-dest-title"
              className="text-lg font-extrabold text-[#1B1F1A]"
            >
              Hapus Destinasi dari Direktori?
            </h3>
            <p className="mt-2 text-xs text-[#4A5248] leading-relaxed">
              Apakah Anda yakin ingin menghapus destinasi{' '}
              <strong className="text-[#1B1F1A]">{deletingDest.name}</strong> (
              {deletingDest.city_regency}) beserta seluruh indikator medan dan
              daftar tarif resminya?
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
