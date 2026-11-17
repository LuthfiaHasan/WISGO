import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Calendar,
  CalendarDays,
  MapPin,
  Clock,
  Plus,
  Search,
  Edit3,
  Trash2,
  Sparkles,
  Building2,
  CheckCircle2,
  AlertTriangle,
  X,
  Filter,
  Eye,
} from 'lucide-react';
import {
  CultureCalendarEvent,
  CultureEventCategory,
  CultureEventStatus,
} from '../types/contract';
import { SUMBAR_REGENCIES } from '../data/mockDestinations';
import {
  deleteCultureEvent,
  fetchCultureEvents,
  saveCultureEvent,
} from '../services/api';
import { ImageDropzone } from './ImageDropzone';

interface CultureCalendarSubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const EVENT_CATEGORIES: CultureEventCategory[] = [
  'Upacara Tradisi',
  'Festival Seni & Musik',
  'Atraksi Adat',
  'Wisata Alam & Olahraga',
];

const EVENT_STATUSES: CultureEventStatus[] = [
  'Akan Datang',
  'Sedang Berlangsung',
  'Selesai',
];

export const CultureCalendarSubTab: React.FC<CultureCalendarSubTabProps> = ({
  showToast,
}) => {
  const [events, setEvents] = useState<CultureCalendarEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRegency, setSelectedRegency] = useState('Semua Kab/Kota');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');

  // Modal Editor & Delete Dialog
  const [editingEvent, setEditingEvent] = useState<CultureCalendarEvent | null>(null);
  const [isNewEvent, setIsNewEvent] = useState(false);
  const [deletingEvent, setDeletingEvent] = useState<CultureCalendarEvent | null>(null);

  const editorDialogRef = useRef<HTMLDialogElement>(null);
  const deleteDialogRef = useRef<HTMLDialogElement>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await fetchCultureEvents();
      setEvents(data);
    } catch {
      showToast('Gagal memuat data kalender budaya.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  useEffect(() => {
    const dialog = editorDialogRef.current;
    if (!dialog) return;
    if (editingEvent && !dialog.open) {
      dialog.showModal();
    } else if (!editingEvent && dialog.open) {
      dialog.close();
    }
  }, [editingEvent]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (deletingEvent && !dialog.open) {
      dialog.showModal();
    } else if (!deletingEvent && dialog.open) {
      dialog.close();
    }
  }, [deletingEvent]);

  const handleOpenAdd = () => {
    setIsNewEvent(true);
    setEditingEvent({
      id: `evt-${Date.now()}`,
      title: '',
      city_regency: 'Kota Bukittinggi',
      location: '',
      start_date: new Date().toISOString().slice(0, 10),
      end_date: new Date().toISOString().slice(0, 10),
      category: 'Atraksi Adat',
      description: '',
      poster_url: '',
      organizer: 'Dinas Pariwisata & Lembaga Adat Nagari',
      status: 'Akan Datang',
      updated_at: new Date().toISOString(),
    });
  };

  const handleOpenEdit = (evt: CultureCalendarEvent) => {
    setIsNewEvent(false);
    setEditingEvent({ ...evt });
  };

  const handleSaveSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingEvent) return;
    if (!editingEvent.title.trim() || !editingEvent.location.trim()) {
      showToast('Nama festival dan lokasi spesifik wajib diisi.', 'warning');
      return;
    }

    try {
      const updated = await saveCultureEvent({
        ...editingEvent,
        updated_at: new Date().toISOString(),
      });
      setEvents(updated);
      setEditingEvent(null);
      showToast(
        isNewEvent
          ? `Festival "${editingEvent.title}" berhasil dijadwalkan.`
          : `Perubahan agenda "${editingEvent.title}" berhasil disimpan.`,
        'success'
      );
    } catch {
      showToast('Gagal menyimpan agenda festival.', 'error');
    }
  };

  const handleConfirmDelete = async () => {
    if (!deletingEvent) return;
    try {
      const updated = await deleteCultureEvent(deletingEvent.id);
      setEvents(updated);
      showToast(`Festival "${deletingEvent.title}" berhasil dihapus.`, 'info');
    } catch {
      showToast('Gagal menghapus festival.', 'error');
    } finally {
      setDeletingEvent(null);
    }
  };

  const filteredEvents = useMemo(() => {
    return events.filter((e) => {
      const q = searchQuery.trim().toLowerCase();
      const matchQuery =
        !q ||
        e.title.toLowerCase().includes(q) ||
        e.location.toLowerCase().includes(q) ||
        e.city_regency.toLowerCase().includes(q) ||
        e.description.toLowerCase().includes(q);

      const matchReg =
        selectedRegency === 'Semua Kab/Kota' || e.city_regency === selectedRegency;
      const matchCat =
        selectedCategory === 'all' || e.category === selectedCategory;
      const matchStatus =
        selectedStatus === 'all' || e.status === selectedStatus;

      return matchQuery && matchReg && matchCat && matchStatus;
    });
  }, [events, searchQuery, selectedRegency, selectedCategory, selectedStatus]);

  const stats = useMemo(() => {
    const total = events.length;
    const upcoming = events.filter((e) => e.status === 'Akan Datang').length;
    const ongoing = events.filter((e) => e.status === 'Sedang Berlangsung').length;
    const finished = events.filter((e) => e.status === 'Selesai').length;
    const uniqueRegencies = new Set(events.map((e) => e.city_regency)).size;
    return { total, upcoming, ongoing, finished, uniqueRegencies };
  }, [events]);

  const getStatusBadge = (status: CultureEventStatus) => {
    switch (status) {
      case 'Sedang Berlangsung':
        return {
          bg: 'bg-[#1E9E5A]',
          text: 'text-white',
          pulse: true,
        };
      case 'Akan Datang':
        return {
          bg: 'bg-[#F26B4B]',
          text: 'text-white',
          pulse: false,
        };
      case 'Selesai':
        return {
          bg: 'bg-neutral-500',
          text: 'text-white',
          pulse: false,
        };
    }
  };

  return (
    <div className="space-y-6">
      {/* 4 Kartu KPI Ringkasan Kalender Budaya */}
      <section
        aria-label="Ringkasan Statistik Kalender Budaya Sumbar"
        className="grid grid-cols-2 lg:grid-cols-4 gap-4"
      >
        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Festival Terjadwal
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.total}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
              Kalender Resmi
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Menjangkau {stats.uniqueRegencies} Kabupaten/Kota di Sumbar
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Sedang Berlangsung (Live)
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#1E9E5A]">
              {stats.ongoing}
            </span>
            <span className="w-2.5 h-2.5 rounded-full bg-[#1E9E5A] animate-ping" />
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Dapat dipantau wisatawan langsung di lokasi hari ini
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Agenda Akan Datang
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#F26B4B]">
              {stats.upcoming}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
              Siap Dikunjungi
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Termasuk Festival Pacu Jawi &amp; Tour de Singkarak
          </p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
            Kharisma Event Nusantara
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              Top Sumbar
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#234B24] text-[#F6F3EC]">
              Kemenpar RI
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">
            Standar kurasi adat &amp; kenyamanan wisatawan mancanegara
          </p>
        </div>
      </section>

      {/* Filter & Baris Pencarian Event */}
      <div className="bg-white p-5 lg:p-6 rounded-3xl border border-[#E4E9DA] shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari nama festival, lokasi, nagari, atau deskripsi acara..."
            className="w-full min-h-[46px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <select
            value={selectedRegency}
            onChange={(e) => setSelectedRegency(e.target.value)}
            className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            {SUMBAR_REGENCIES.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </select>

          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="all">Semua Kategori Acara</option>
            {EVENT_CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>

          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="all">Semua Status</option>
            {EVENT_STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>

          <button
            type="button"
            onClick={handleOpenAdd}
            className="min-h-[46px] px-5 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm transition"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Jadwalkan Festival</span>
          </button>
        </div>
      </div>

      {/* Grid Kartu Kalender Budaya */}
      {filteredEvents.length === 0 ? (
        <div className="bg-white rounded-3xl border border-[#E4E9DA] p-12 text-center text-[#4A5248] space-y-2">
          <Calendar className="w-10 h-10 text-[#234B24]/40 mx-auto" />
          <p className="text-sm font-bold text-[#1B1F1A]">
            Tidak ada agenda budaya yang sesuai filter.
          </p>
          <p className="text-xs">
            Ubah filter pencarian wilayah atau tambahkan jadwal festival budaya baru.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
          {filteredEvents.map((evt) => {
            const statusMeta = getStatusBadge(evt.status);

            return (
              <div
                key={evt.id}
                className="bg-white rounded-3xl border border-[#E4E9DA] shadow-sm overflow-hidden flex flex-col justify-between hover:shadow-md transition"
              >
                <div>
                  {/* Poster Thumbnail */}
                  <div className="relative h-48 bg-[#234B24]/10 overflow-hidden">
                    {evt.poster_url ? (
                      <img
                        src={evt.poster_url}
                        alt={evt.title}
                        className="w-full h-full object-cover transition-transform hover:scale-105 duration-300"
                      />
                    ) : (
                      <div className="w-full h-full flex flex-col items-center justify-center text-[#4A5248] text-xs">
                        <CalendarDays className="w-8 h-8 text-[#234B24]/40 mb-1" />
                        <span>Poster Belum Diunggah</span>
                      </div>
                    )}
                    <div className="absolute top-3 left-3 flex gap-1.5 flex-wrap">
                      <span
                        className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase shadow-sm flex items-center gap-1 ${statusMeta.bg} ${statusMeta.text}`}
                      >
                        {statusMeta.pulse && (
                          <span className="w-1.5 h-1.5 rounded-full bg-white animate-ping" />
                        )}
                        <span>{evt.status}</span>
                      </span>
                      <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#234B24] text-white">
                        {evt.category}
                      </span>
                    </div>
                  </div>

                  {/* Informasi Festival */}
                  <div className="p-5 space-y-2.5">
                    <h4 className="font-extrabold text-[#1B1F1A] text-base leading-snug">
                      {evt.title}
                    </h4>

                    <div className="space-y-1 text-xs text-[#4A5248]">
                      <div className="flex items-center gap-1.5 font-bold text-[#234B24]">
                        <MapPin className="w-3.5 h-3.5 shrink-0" />
                        <span className="truncate">{evt.location} ({evt.city_regency})</span>
                      </div>
                      <div className="flex items-center gap-1.5 font-semibold">
                        <Clock className="w-3.5 h-3.5 shrink-0 text-[#767676]" />
                        <span>
                          {evt.start_date} s.d. {evt.end_date}
                        </span>
                      </div>
                      <div className="flex items-center gap-1.5 text-[11px] text-[#767676]">
                        <Building2 className="w-3.5 h-3.5 shrink-0" />
                        <span className="truncate">Penyelenggara: {evt.organizer}</span>
                      </div>
                    </div>

                    <p className="text-xs text-[#4A5248] line-clamp-3 bg-[#F6F3EC]/70 p-3 rounded-2xl border border-[#CFD8BE]/50">
                      {evt.description}
                    </p>
                  </div>
                </div>

                {/* Footer Kartu & Tombol Aksi */}
                <div className="p-4 bg-[#F6F3EC] border-t border-[#E4E9DA] flex items-center justify-between">
                  <span className="text-[11px] text-[#4A5248]">
                    ID: <strong>{evt.id}</strong>
                  </span>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => handleOpenEdit(evt)}
                      className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-white border border-[#CFD8BE] hover:bg-[#E4E9DA] text-xs font-bold text-[#1B1F1A] inline-flex items-center gap-1 shadow-xs transition"
                    >
                      <Edit3 className="w-3 h-3 text-[#234B24]" />
                      <span>Edit</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setDeletingEvent(evt)}
                      className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-white border border-[#F26B4B]/30 hover:bg-[#F26B4B]/10 text-xs font-bold text-[#D95637] inline-flex items-center gap-1 shadow-xs transition"
                    >
                      <Trash2 className="w-3 h-3" />
                      <span>Hapus</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* =====================================================================
          MODAL TAMBAH & EDIT EVENT BUDAYA
         ===================================================================== */}
      <dialog
        ref={editorDialogRef}
        aria-labelledby="event-modal-title"
        onClose={() => setEditingEvent(null)}
        className="w-full max-w-2xl rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {editingEvent && (
          <form
            onSubmit={handleSaveSubmit}
            className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border border-[#CFD8BE] shadow-2xl overflow-hidden max-h-[90vh] flex flex-col"
          >
            {/* Header Modal */}
            <div className="shrink-0 bg-[#234B24] text-[#F6F3EC] px-6 py-5 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#A7F3D0]">
                  Formulir Kalender Budaya ({editingEvent.id})
                </span>
                <h2
                  id="event-modal-title"
                  className="text-xl font-extrabold text-[#F6F3EC] mt-0.5"
                >
                  {isNewEvent
                    ? 'Jadwalkan Festival Budaya Baru'
                    : `Perbarui Agenda: ${editingEvent.title}`}
                </h2>
              </div>
              <button
                type="button"
                aria-label="Tutup form event"
                onClick={() => setEditingEvent(null)}
                className="w-10 h-10 rounded-full bg-white/10 hover:bg-[#F26B4B] text-white flex items-center justify-center transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Isi Form */}
            <div className="flex-1 min-h-0 overflow-y-auto p-6 space-y-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold text-[#1B1F1A]">
                  Nama Festival / Acara Budaya *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Contoh: Festival Pesona Pacu Jawi 2024"
                  value={editingEvent.title}
                  onChange={(e) =>
                    setEditingEvent({ ...editingEvent, title: e.target.value })
                  }
                  className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Wilayah Kabupaten / Kota *
                  </label>
                  <select
                    value={editingEvent.city_regency}
                    onChange={(e) =>
                      setEditingEvent({
                        ...editingEvent,
                        city_regency: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                  >
                    {SUMBAR_REGENCIES.filter((r) => r !== 'Semua Kab/Kota').map(
                      (r) => (
                        <option key={r} value={r}>
                          {r}
                        </option>
                      )
                    )}
                  </select>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Kategori Acara *
                  </label>
                  <select
                    value={editingEvent.category}
                    onChange={(e) =>
                      setEditingEvent({
                        ...editingEvent,
                        category: e.target.value as CultureEventCategory,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                  >
                    {EVENT_CATEGORIES.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold text-[#1B1F1A]">
                  Lokasi Spesifik / Nagari Penyelenggaraan *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Contoh: Sawah Nagari Sungai Tarab & Pariangan"
                  value={editingEvent.location}
                  onChange={(e) =>
                    setEditingEvent({ ...editingEvent, location: e.target.value })
                  }
                  className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Tanggal Mulai *
                  </label>
                  <input
                    type="date"
                    required
                    value={editingEvent.start_date}
                    onChange={(e) =>
                      setEditingEvent({
                        ...editingEvent,
                        start_date: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-3.5 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Tanggal Selesai *
                  </label>
                  <input
                    type="date"
                    required
                    value={editingEvent.end_date}
                    onChange={(e) =>
                      setEditingEvent({
                        ...editingEvent,
                        end_date: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-3.5 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Status Acara *
                  </label>
                  <select
                    value={editingEvent.status}
                    onChange={(e) =>
                      setEditingEvent({
                        ...editingEvent,
                        status: e.target.value as CultureEventStatus,
                      })
                    }
                    className="min-h-[46px] px-3.5 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                  >
                    {EVENT_STATUSES.map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold text-[#1B1F1A]">
                  Penyelenggara Resmi (Dinas / Lembaga KAN) *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Contoh: Dinas Pariwisata Tanah Datar & Lembaga Adat KAN"
                  value={editingEvent.organizer}
                  onChange={(e) =>
                    setEditingEvent({
                      ...editingEvent,
                      organizer: e.target.value,
                    })
                  }
                  className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                />
              </div>

              {/* Upload Poster Acara */}
              <div className="p-4 rounded-2xl bg-white border border-[#CFD8BE]">
                <ImageDropzone
                  label="Upload Poster Resmi Festival dari Device"
                  value={editingEvent.poster_url}
                  onChange={(dataUrl) =>
                    setEditingEvent({
                      ...editingEvent,
                      poster_url: dataUrl,
                    })
                  }
                  onClear={() =>
                    setEditingEvent({
                      ...editingEvent,
                      poster_url: '',
                    })
                  }
                  helperText="Pilih gambar poster dari komputer (JPG, PNG, WebP). Kompresi otomatis WebP menjaga pemuatan sangat ringan."
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold text-[#1B1F1A]">
                  Deskripsi Acara &amp; Filosofi Tradisi Adat
                </label>
                <textarea
                  rows={3}
                  placeholder="Tuliskan latar belakang sejarah, prosesi ritual, dan daya tarik festival untuk wisatawan..."
                  value={editingEvent.description}
                  onChange={(e) =>
                    setEditingEvent({
                      ...editingEvent,
                      description: e.target.value,
                    })
                  }
                  className="p-3.5 rounded-xl bg-white border border-[#767676] text-xs"
                />
              </div>
            </div>

            {/* Footer Modal */}
            <div className="shrink-0 border-t border-[#234B24]/15 bg-white px-6 py-4 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setEditingEvent(null)}
                className="min-h-[44px] px-5 rounded-pill bg-[#F6F3EC] border border-[#767676] text-xs font-bold text-[#1B1F1A] hover:bg-[#E4E9DA] transition"
              >
                Batal
              </button>
              <button
                type="submit"
                className="min-h-[44px] px-6 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold shadow-md transition"
              >
                {isNewEvent ? 'Jadwalkan Acara' : 'Simpan Perubahan'}
              </button>
            </div>
          </form>
        )}
      </dialog>

      {/* Dialog Konfirmasi Hapus */}
      <dialog
        ref={deleteDialogRef}
        aria-labelledby="delete-event-title"
        onClose={() => setDeletingEvent(null)}
        className="w-full max-w-md rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {deletingEvent && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border border-[#CFD8BE] shadow-2xl p-6 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-[#F26B4B]/20 text-[#D95637] flex items-center justify-center">
              <AlertTriangle className="w-6 h-6" />
            </div>
            <div>
              <h3 id="delete-event-title" className="text-lg font-extrabold text-[#1B1F1A]">
                Hapus Jadwal Festival?
              </h3>
              <p className="text-xs text-[#4A5248] mt-1">
                Apakah Anda yakin ingin menghapus agenda &ldquo;{deletingEvent.title}&rdquo; dari kalender budaya resmi?
              </p>
            </div>
            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setDeletingEvent(null)}
                className="min-h-[42px] px-4 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmDelete}
                className="min-h-[42px] px-5 rounded-xl bg-[#D95637] text-white text-xs font-bold shadow-sm"
              >
                Ya, Hapus Agenda
              </button>
            </div>
          </div>
        )}
      </dialog>
    </div>
  );
};
