import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  AlertTriangle,
  Building2,
  Calendar,
  CalendarDays,
  Clock,
  Edit3,
  ListChecks,
  MapPin,
  Plus,
  Search,
  Send,
  Sparkles,
  Trash2,
  X,
} from 'lucide-react';
import {
  CulturalEvent,
  CultureEventCategory,
  CultureEventStatus,
} from '../types/contract';
import { SUMBAR_REGENCIES } from '../data/mockDestinations';
import { CulturalEventsRepo } from '../services/dbRepository';
import { broadcastSystemNotification } from '../services/api';
import { ImageDropzone } from './ImageDropzone';

interface CultureCalendarSubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const EVENT_CATEGORIES: CultureEventCategory[] = [
  'Festival Seni & Musik',
  'Atraksi Adat',
  'Upacara Tradisi',
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
  const [events, setEvents] = useState<CulturalEvent[]>(() => CulturalEventsRepo.getAll());
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRegency, setSelectedRegency] = useState('Semua Kab/Kota');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');

  const [editingEvent, setEditingEvent] = useState<CulturalEvent | null>(null);
  const [rundownText, setRundownText] = useState('');
  const [isNewEvent, setIsNewEvent] = useState(false);
  const [deletingEvent, setDeletingEvent] = useState<CulturalEvent | null>(null);

  const editorDialogRef = useRef<HTMLDialogElement>(null);
  const deleteDialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = editorDialogRef.current;
    if (!dialog) return;
    if (editingEvent && !dialog.open) dialog.showModal();
    else if (!editingEvent && dialog.open) dialog.close();
  }, [editingEvent]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (deletingEvent && !dialog.open) dialog.showModal();
    else if (!deletingEvent && dialog.open) dialog.close();
  }, [deletingEvent]);

  const handleOpenAdd = () => {
    setIsNewEvent(true);
    setRundownText('09:00 WIB: Pembukaan Adat Nagari\n13:00 WIB: Pentas Utama & Makan Bajamba');
    setEditingEvent({
      id: `ev-${Date.now()}`,
      user_id: 'usr-admin-01',
      title: '',
      event_type: 'Atraksi Adat',
      nagari_location: '',
      city_regency: 'Kab. Tanah Datar',
      schedule_rule: 'Tahunan',
      next_event_date: new Date().toISOString().slice(0, 10),
      end_date: new Date().toISOString().slice(0, 10),
      latitude: -0.4712,
      longitude: 100.6213,
      highlight_item: '',
      cultural_etiquette: 'Berpakaian sopan tertutup dan ikuti arahan panitia nagari.',
      rundown: [],
      poster_url: '',
      organizer: 'Dinas Pariwisata & Lembaga Adat Nagari',
      status: 'Akan Datang',
    });
  };

  const handleOpenEdit = (evt: CulturalEvent) => {
    setIsNewEvent(false);
    setRundownText((evt.rundown || []).join('\n'));
    setEditingEvent({ ...evt });
  };

  const handleSaveSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingEvent) return;
    if (!editingEvent.title.trim() || !editingEvent.nagari_location.trim()) {
      showToast('Nama festival dan lokasi nagari wajib diisi.', 'warning');
      return;
    }

    const rundownList = rundownText
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);

    const updated = CulturalEventsRepo.save({
      ...editingEvent,
      rundown: rundownList,
    });
    setEvents(updated);
    setEditingEvent(null);
    showToast(
      isNewEvent
        ? `Festival "${editingEvent.title}" berhasil dijadwalkan.`
        : `Perubahan agenda "${editingEvent.title}" berhasil disimpan.`,
      'success'
    );
  };

  const handleConfirmDelete = () => {
    if (!deletingEvent) return;
    const updated = CulturalEventsRepo.delete(deletingEvent.id);
    setEvents(updated);
    showToast(`Festival "${deletingEvent.title}" berhasil dihapus.`, 'info');
    setDeletingEvent(null);
  };

  const filteredEvents = useMemo(() => {
    return events.filter((e) => {
      const q = searchQuery.trim().toLowerCase();
      const matchQuery =
        !q ||
        e.title.toLowerCase().includes(q) ||
        e.nagari_location.toLowerCase().includes(q) ||
        e.city_regency.toLowerCase().includes(q) ||
        e.highlight_item.toLowerCase().includes(q);
      const matchReg =
        selectedRegency === 'Semua Kab/Kota' || e.city_regency === selectedRegency;
      const matchCat = selectedCategory === 'all' || e.event_type === selectedCategory;
      const matchStatus = selectedStatus === 'all' || e.status === selectedStatus;
      return matchQuery && matchReg && matchCat && matchStatus;
    });
  }, [events, searchQuery, selectedRegency, selectedCategory, selectedStatus]);

  const stats = useMemo(() => {
    const total = events.length;
    const upcoming = events.filter((e) => e.status === 'Akan Datang').length;
    const ongoing = events.filter((e) => e.status === 'Sedang Berlangsung').length;
    const uniqueRegencies = new Set(events.map((e) => e.city_regency)).size;
    return { total, upcoming, ongoing, uniqueRegencies };
  }, [events]);

  const getStatusBadge = (status: CultureEventStatus) => {
    if (status === 'Sedang Berlangsung') return { bg: 'bg-[#1E9E5A]', text: 'text-white', pulse: true };
    if (status === 'Akan Datang') return { bg: 'bg-[#F26B4B]', text: 'text-white', pulse: false };
    return { bg: 'bg-neutral-500', text: 'text-white', pulse: false };
  };

  return (
    <div className="space-y-6">
      <section className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Festival Terjadwal
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">{stats.total}</span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
              Kalender Resmi
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Menjangkau {stats.uniqueRegencies} Kabupaten/Kota di Sumbar
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Sedang Berlangsung
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#1E9E5A]">{stats.ongoing}</span>
            <span className="w-2.5 h-2.5 rounded-full bg-[#1E9E5A] animate-ping" />
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">Aktif dipantau di aplikasi wisatawan</p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Agenda Akan Datang
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#F26B4B]">{stats.upcoming}</span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
              Siap Dikunjungi
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">Pasa Harau, Pacu Jawi &amp; Batagak Panghulu</p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
            Sinkron FE-1 Budaya
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-2xl font-extrabold text-[#234B24]">Rundown &amp; Adat</span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">Dilengkapi etika kunjungan &amp; koordinat GPS</p>
        </div>
      </section>

      <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari nama festival, nagari, atau sorotan tradisi..."
            className="w-full min-h-[46px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <select
            value={selectedRegency}
            onChange={(e) => setSelectedRegency(e.target.value)}
            className="min-h-[46px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
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
            className="min-h-[46px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
          >
            <option value="all">Semua Jenis Acara</option>
            {EVENT_CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>

          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="min-h-[46px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
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
            className="min-h-[46px] px-5 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Jadwalkan Festival</span>
          </button>
        </div>
      </div>

      {filteredEvents.length === 0 ? (
        <div className="bg-white rounded-3xl border border-[#234B24]/10 p-12 text-center text-[#4A5248] space-y-2">
          <Calendar className="w-10 h-10 text-[#234B24]/40 mx-auto" />
          <p className="text-sm font-bold text-[#1B1F1A]">Tidak ada agenda budaya sesuai filter.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
          {filteredEvents.map((evt) => {
            const statusMeta = getStatusBadge(evt.status);
            return (
              <div
                key={evt.id}
                className="bg-white rounded-3xl border border-[#234B24]/10 shadow-sm overflow-hidden flex flex-col justify-between"
              >
                <div>
                  <div className="relative h-44 bg-[#234B24]/10 overflow-hidden">
                    {evt.poster_url ? (
                      <img src={evt.poster_url} alt={evt.title} className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full flex flex-col items-center justify-center text-[#4A5248] text-xs">
                        <CalendarDays className="w-8 h-8 text-[#234B24]/40 mb-1" />
                        <span>Poster Belum Diunggah</span>
                      </div>
                    )}
                    <div className="absolute top-3 left-3 flex gap-1.5 flex-wrap">
                      <span
                        className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase flex items-center gap-1 ${statusMeta.bg} ${statusMeta.text}`}
                      >
                        {statusMeta.pulse && <span className="w-1.5 h-1.5 rounded-full bg-white animate-ping" />}
                        {evt.status}
                      </span>
                      <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#234B24] text-white">
                        {evt.event_type}
                      </span>
                    </div>
                  </div>

                  <div className="p-5 space-y-2.5">
                    <h4 className="font-extrabold text-[#1B1F1A] text-base leading-snug">{evt.title}</h4>

                    <div className="space-y-1 text-xs text-[#4A5248]">
                      <div className="flex items-center gap-1.5 font-bold text-[#234B24]">
                        <MapPin className="w-3.5 h-3.5 shrink-0" />
                        <span className="truncate">
                          {evt.nagari_location} ({evt.city_regency})
                        </span>
                      </div>
                      <div className="flex items-center gap-1.5 font-semibold">
                        <Clock className="w-3.5 h-3.5 shrink-0 text-[#767676]" />
                        <span>
                          {evt.next_event_date}
                          {evt.end_date && evt.end_date !== evt.next_event_date ? ` s.d. ${evt.end_date}` : ''} · {evt.schedule_rule}
                        </span>
                      </div>
                      {evt.organizer && (
                        <div className="flex items-center gap-1.5 text-[11px] text-[#767676]">
                          <Building2 className="w-3.5 h-3.5 shrink-0" />
                          <span className="truncate">{evt.organizer}</span>
                        </div>
                      )}
                    </div>

                    <p className="text-xs text-[#1B1F1A] bg-[#F6F3EC] p-3 rounded-2xl border border-[#CFD8BE]/50">
                      {evt.highlight_item}
                    </p>

                    {evt.rundown && evt.rundown.length > 0 && (
                      <div className="text-[11px] space-y-1 bg-white p-2.5 rounded-xl border border-[#E4E9DA]">
                        <div className="font-bold text-[#234B24] flex items-center gap-1">
                          <ListChecks className="w-3.5 h-3.5" /> Rangkaian Acara:
                        </div>
                        <ul className="list-disc pl-4 space-y-0.5 text-[#4A5248]">
                          {evt.rundown.slice(0, 3).map((item, i) => (
                            <li key={i}>{item}</li>
                          ))}
                        </ul>
                      </div>
                    )}

                    <div className="text-[11px] text-[#234B24] bg-[#E4E9DA]/60 p-2.5 rounded-xl flex items-start gap-1.5">
                      <Sparkles className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                      <span>
                        <strong>Etika Adat:</strong> {evt.cultural_etiquette}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-[#F6F3EC] border-t border-[#234B24]/10 flex items-center justify-between">
                  <span className="text-[10px] font-mono text-[#4A5248]">
                    GPS: {evt.latitude.toFixed(3)}, {evt.longitude.toFixed(3)}
                  </span>
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => {
                        broadcastSystemNotification({
                          title: `Festival Budaya: ${evt.title}`,
                          message: `Saksikan ${evt.title} di ${evt.nagari_location} (${evt.city_regency}) pada ${evt.next_event_date}.`,
                          notification_type: 'system',
                          reference_id: evt.id,
                        });
                        showToast(`Notifikasi siaran festival "${evt.title}" terkirim!`, 'success');
                      }}
                      className="min-h-[36px] px-3 py-1.5 rounded-xl bg-[#234B24] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1"
                    >
                      <Send className="w-3 h-3 text-[#F26B4B]" /> Siarkan
                    </button>
                    <button
                      type="button"
                      onClick={() => handleOpenEdit(evt)}
                      className="min-h-[36px] px-3 py-1.5 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold inline-flex items-center gap-1"
                    >
                      <Edit3 className="w-3 h-3 text-[#234B24]" /> Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => setDeletingEvent(evt)}
                      className="min-h-[36px] px-2.5 py-1.5 rounded-xl bg-white border border-[#F26B4B]/30 text-xs font-bold text-[#D95637]"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

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
            <div className="shrink-0 bg-[#234B24] text-[#F6F3EC] px-6 py-5 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#A7F3D0]">
                  Kalender Budaya Sumatera Barat ({editingEvent.id})
                </span>
                <h2 id="event-modal-title" className="text-xl font-extrabold mt-0.5">
                  {isNewEvent ? 'Jadwalkan Festival Budaya Baru' : `Edit: ${editingEvent.title}`}
                </h2>
              </div>
              <button
                type="button"
                onClick={() => setEditingEvent(null)}
                className="w-10 h-10 rounded-full bg-white/10 hover:bg-[#F26B4B] text-white flex items-center justify-center"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex-1 min-h-0 overflow-y-auto p-6 space-y-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold">Nama Festival / Acara Budaya *</label>
                <input
                  type="text"
                  required
                  value={editingEvent.title}
                  onChange={(e) => setEditingEvent({ ...editingEvent, title: e.target.value })}
                  className="min-h-[44px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Wilayah Kab/Kota *</label>
                  <select
                    value={editingEvent.city_regency}
                    onChange={(e) =>
                      setEditingEvent({ ...editingEvent, city_regency: e.target.value })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-xs font-bold"
                  >
                    {SUMBAR_REGENCIES.filter((r) => r !== 'Semua Kab/Kota').map((r) => (
                      <option key={r} value={r}>
                        {r}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Jenis Acara *</label>
                  <select
                    value={editingEvent.event_type}
                    onChange={(e) =>
                      setEditingEvent({ ...editingEvent, event_type: e.target.value })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-xs font-bold"
                  >
                    {EVENT_CATEGORIES.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Lokasi Nagari *</label>
                  <input
                    type="text"
                    required
                    value={editingEvent.nagari_location}
                    onChange={(e) =>
                      setEditingEvent({ ...editingEvent, nagari_location: e.target.value })
                    }
                    className="min-h-[44px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Aturan Jadwal (Schedule Rule)</label>
                  <input
                    type="text"
                    value={editingEvent.schedule_rule}
                    onChange={(e) =>
                      setEditingEvent({ ...editingEvent, schedule_rule: e.target.value })
                    }
                    placeholder="Contoh: Tahunan (Desember)"
                    className="min-h-[44px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Tanggal Mulai *</label>
                  <input
                    type="date"
                    required
                    value={editingEvent.next_event_date}
                    onChange={(e) =>
                      setEditingEvent({ ...editingEvent, next_event_date: e.target.value })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Tanggal Selesai</label>
                  <input
                    type="date"
                    value={editingEvent.end_date || editingEvent.next_event_date}
                    onChange={(e) =>
                      setEditingEvent({ ...editingEvent, end_date: e.target.value })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Status *</label>
                  <select
                    value={editingEvent.status}
                    onChange={(e) =>
                      setEditingEvent({ ...editingEvent, status: e.target.value })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-xs font-bold"
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
                <label className="text-xs font-bold">Sorotan Utama &amp; Filosofi Tradisi</label>
                <textarea
                  rows={2}
                  value={editingEvent.highlight_item}
                  onChange={(e) =>
                    setEditingEvent({ ...editingEvent, highlight_item: e.target.value })
                  }
                  className="p-3 rounded-xl bg-white border border-[#767676] text-xs"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold">Etika Adat Wisatawan</label>
                <input
                  type="text"
                  value={editingEvent.cultural_etiquette}
                  onChange={(e) =>
                    setEditingEvent({ ...editingEvent, cultural_etiquette: e.target.value })
                  }
                  className="min-h-[42px] px-3.5 py-2 rounded-xl bg-white border border-[#767676] text-xs"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold">Rundown Acara (1 baris per sesi)</label>
                <textarea
                  rows={3}
                  value={rundownText}
                  onChange={(e) => setRundownText(e.target.value)}
                  className="p-3 rounded-xl bg-white border border-[#767676] text-xs"
                />
              </div>

              <ImageDropzone
                label="Poster Resmi Festival"
                value={editingEvent.poster_url || ''}
                onChange={(url) => setEditingEvent({ ...editingEvent, poster_url: url })}
                onClear={() => setEditingEvent({ ...editingEvent, poster_url: '' })}
              />
            </div>

            <div className="shrink-0 border-t border-[#234B24]/15 bg-white px-6 py-4 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setEditingEvent(null)}
                className="min-h-[42px] px-5 rounded-pill bg-[#F6F3EC] border border-[#767676] text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="submit"
                className="min-h-[42px] px-6 rounded-pill bg-[#234B24] text-[#F6F3EC] text-xs font-bold"
              >
                {isNewEvent ? 'Jadwalkan Acara' : 'Simpan Perubahan'}
              </button>
            </div>
          </form>
        )}
      </dialog>

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
              <h3 id="delete-event-title" className="text-lg font-extrabold">
                Hapus Jadwal Festival?
              </h3>
              <p className="text-xs text-[#4A5248] mt-1">
                Agenda &ldquo;{deletingEvent.title}&rdquo; akan dihapus dari Kalender Budaya WISGO.
              </p>
            </div>
            <div className="flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setDeletingEvent(null)}
                className="min-h-[40px] px-4 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmDelete}
                className="min-h-[40px] px-5 rounded-xl bg-[#D95637] text-white text-xs font-bold"
              >
                Ya, Hapus
              </button>
            </div>
          </div>
        )}
      </dialog>
    </div>
  );
};
