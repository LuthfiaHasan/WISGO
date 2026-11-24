import React, { useEffect, useMemo, useState } from 'react';
import {
  Users,
  Search,
  CheckCircle2,
  AlertTriangle,
  Clock,
  MapPin,
  Phone,
  ShieldCheck,
  Building2,
  DollarSign,
  Calendar,
  Compass,
  ArrowRight,
  Eye,
  X,
  FileText,
  Check,
  Ban,
  ExternalLink,
  Plus,
  Trash2,
  ListChecks,
  Briefcase,
  Luggage,
  Sparkles,
  Layers,
  CreditCard,
  Receipt,
  UserCheck,
} from 'lucide-react';
import {
  OpenTrip,
  OpenTripItem,
  OpenTripStatus,
  OpenTripOrganizer,
  OpenTripTransaction,
  PackingTemplate,
} from '../types/contract';
import {
  OpenTripsRepo,
  OpenTripOrganizersRepo,
  OpenTripTransactionsRepo,
  PackingTemplatesRepo,
} from '../services/dbRepository';
import { DESTINATION_CATEGORIES } from '../data/mockDestinations';

interface OpenTripsSubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

type OpenTripModuleSubTab =
  | 'monitoring_cards'
  | 'organizers_verification'
  | 'transactions_recap'
  | 'packing_templates';

export const getCategoryIconSvg = (cat: string) => {
  if (cat.includes('Alam') || cat.includes('Pegunungan')) return '/assets/synced/cat_alam_gunung.svg';
  if (cat.includes('Bahari') || cat.includes('Pesisir')) return '/assets/synced/cat_bahari_pesisir.svg';
  if (cat.includes('Sejarah') || cat.includes('Warisan')) return '/assets/synced/cat_sejarah_warisan.svg';
  if (cat.includes('Nagari') || cat.includes('Budaya')) return '/assets/synced/cat_nagari_budaya.svg';
  if (cat.includes('Kuliner') || cat.includes('Agrowisata')) return '/assets/synced/cat_kuliner_agro.svg';
  return '/assets/synced/cat_alam_gunung.svg';
};

export const OpenTripsSubTab: React.FC<OpenTripsSubTabProps> = ({
  showToast,
}) => {
  const [activeModuleTab, setActiveModuleTab] =
    useState<OpenTripModuleSubTab>('monitoring_cards');

  // Data states from Repository
  const [trips, setTrips] = useState<OpenTrip[]>(() => OpenTripsRepo.getAll());
  const [organizers, setOrganizers] = useState<OpenTripOrganizer[]>(() =>
    OpenTripOrganizersRepo.getAll()
  );
  const [transactions, setTransactions] = useState<OpenTripTransaction[]>(() =>
    OpenTripTransactionsRepo.getAll()
  );
  const [packingTemplates, setPackingTemplates] = useState<PackingTemplate[]>(() =>
    PackingTemplatesRepo.getAll()
  );

  // Filters for Monitoring Cards
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');

  // Selected Trip for Trip Planner Modal
  const [selectedPlannerTrip, setSelectedPlannerTrip] = useState<OpenTrip | null>(null);

  // Selected Organizer for 7-Points Verification Sheet
  const [selectedOrganizerFor7Points, setSelectedOrganizerFor7Points] =
    useState<OpenTripOrganizer | null>(null);

  // New Packing Item Form
  const [newTemplateCat, setNewTemplateCat] = useState<string>('Wisata Alam & Pegunungan');
  const [newTemplateItem, setNewTemplateItem] = useState('');
  const [newTemplateMandatory, setNewTemplateMandatory] = useState(true);
  const [newTemplateNotes, setNewTemplateNotes] = useState('');

  // Update Organizer Verification Status
  const handleUpdateOrganizerStatus = (
    id: string,
    status: 'Menunggu' | 'Terverifikasi' | 'Ditolak'
  ) => {
    const updated = OpenTripOrganizersRepo.updateStatus(id, status);
    setOrganizers(updated);
    showToast(
      status === 'Terverifikasi'
        ? 'Penyelenggara Open Trip berhasil diverifikasi dan disetujui.'
        : 'Status pengajuan penyelenggara telah diperbarui.',
      status === 'Terverifikasi' ? 'success' : 'info'
    );
  };

  // Update Escrow Status
  const handleUpdateTripEscrow = (tripId: string, newStatus: string) => {
    const updated = OpenTripsRepo.updateEscrowStatus(tripId, newStatus);
    setTrips(updated);
    showToast(
      newStatus === 'DICAIRKAN_KE_PENYELENGGARA'
        ? 'Dana rekening penampung (Escrow) berhasil dicairkan ke penyelenggara.'
        : newStatus === 'DILAPORKAN_INSIDEN'
        ? 'Dana escrow dibekukan sementara karena investigasi laporan insiden.'
        : 'Status dana escrow dipulihkan ke rekening penampung aman.',
      newStatus === 'DILAPORKAN_INSIDEN' ? 'warning' : 'success'
    );
  };

  // Add Packing Item
  const handleAddPackingItem = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTemplateItem.trim()) {
      showToast('Nama barang bawaan wajib diisi.', 'warning');
      return;
    }
    const item: PackingTemplate = {
      id: `pkt-${Date.now()}`,
      category_name: newTemplateCat,
      item_name: newTemplateItem.trim(),
      is_mandatory: newTemplateMandatory,
      notes: newTemplateNotes.trim() || undefined,
    };
    const updated = PackingTemplatesRepo.save(item);
    setPackingTemplates(updated);
    setNewTemplateItem('');
    setNewTemplateNotes('');
    showToast(`Barang bawaan berhasil ditambahkan ke kategori ${newTemplateCat}.`, 'success');
  };

  // Delete Packing Item
  const handleDeletePackingItem = (id: string) => {
    const updated = PackingTemplatesRepo.delete(id);
    setPackingTemplates(updated);
    showToast('Item barang bawaan berhasil dihapus.', 'info');
  };

  // Filtered Open Trips
  const filteredTrips = useMemo(() => {
    return trips.filter((t) => {
      const q = searchQuery.trim().toLowerCase();
      const tripId = t.id || '';
      const leaderName = t.trip_leader_name || t.leader_name || '';
      const destName = t.destination_name || t.destination_route || '';
      const cat = t.travel_category || '';

      const matchQuery =
        !q ||
        tripId.toLowerCase().includes(q) ||
        t.title.toLowerCase().includes(q) ||
        leaderName.toLowerCase().includes(q) ||
        destName.toLowerCase().includes(q);

      const matchStatus =
        statusFilter === 'all' || t.status === statusFilter;

      const matchCat =
        categoryFilter === 'all' || cat === categoryFilter;

      return matchQuery && matchStatus && matchCat;
    });
  }, [trips, searchQuery, statusFilter, categoryFilter]);

  // Statistics
  const totalRevenue = useMemo(() => {
    return transactions
      .filter((t) => t.status === 'BERHASIL')
      .reduce((sum, t) => sum + t.amount_idr, 0);
  }, [transactions]);

  const verifiedOrganizersCount = organizers.filter((o) => o.status === 'Terverifikasi').length;
  const pendingOrganizersCount = organizers.filter((o) => o.status === 'Menunggu').length;

  return (
    <div className="space-y-6">
      {/* BANNER ATURAN TEGAS TRANSAKSI WISGO */}
      <div className="p-4 rounded-2xl bg-[#234B24] text-[#F6F3EC] shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center shrink-0 mt-0.5">
            <Receipt className="w-5 h-5 text-[#F26B4B]" />
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-sm font-extrabold tracking-wide uppercase">
                Aturan Tegas Transaksi Sistem WISGO
              </h2>
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black bg-[#F26B4B] text-white">
                Khusus Open Trip
              </span>
            </div>
            <p className="text-xs text-[#E4E9DA] mt-0.5 leading-relaxed">
              Sistem pembayaran escrow / transaksi di dalam aplikasi <strong>HANYA berlaku untuk Open Trip</strong> demi keamanan split-bill peserta.
              Untuk <strong>Mitra UMKM Nagari biasa</strong> (Kuliner, Homestay, Sewa Baju Adat), transaksi 100% langsung (Direct WhatsApp P2P) tanpa potongan sistem dan diukur lewat metrik <strong>Klik Leads WA</strong>.
            </p>
          </div>
        </div>

        <div className="shrink-0 flex items-center gap-2 bg-white/10 px-3.5 py-2 rounded-xl text-xs font-semibold">
          <span>Total Transaksi Open Trip:</span>
          <strong className="text-[#F26B4B] font-mono text-sm">
            Rp {totalRevenue.toLocaleString('id-ID')}
          </strong>
        </div>
      </div>

      {/* SUB-TAB NAVIGASI MODUL OPEN TRIP */}
      <div className="bg-white p-2 rounded-2xl border border-[#234B24]/8 shadow-[0_2px_12px_rgba(35,75,36,0.03)] flex flex-wrap items-center gap-2">
        <button
          type="button"
          onClick={() => setActiveModuleTab('monitoring_cards')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeModuleTab === 'monitoring_cards'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <Compass className="w-4 h-4" />
          <span>Monitoring Open Trip (Tampilan Card)</span>
          <span className="px-2 py-0.5 rounded-full text-[10px] bg-white/20">
            {trips.length}
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveModuleTab('organizers_verification')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeModuleTab === 'organizers_verification'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <UserCheck className="w-4 h-4" />
          <span>Verifikasi Penyelenggara Open Trip</span>
          {pendingOrganizersCount > 0 && (
            <span className="px-2 py-0.5 rounded-full text-[10px] bg-amber-500 text-white font-black animate-pulse">
              {pendingOrganizersCount} Menunggu
            </span>
          )}
        </button>

        <button
          type="button"
          onClick={() => setActiveModuleTab('transactions_recap')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeModuleTab === 'transactions_recap'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <CreditCard className="w-4 h-4" />
          <span>Transaksi Open Trip (Sistem)</span>
          <span className="px-2 py-0.5 rounded-full text-[10px] bg-white/20">
            {transactions.length} Trx
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveModuleTab('packing_templates')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
            activeModuleTab === 'packing_templates'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
          }`}
        >
          <Luggage className="w-4 h-4" />
          <span>Template Barang Bawaan (Trip Planner)</span>
        </button>
      </div>

      {/* 1. SUB-TAB: MONITORING OPEN TRIP (TAMPILAN CARD) */}
      {activeModuleTab === 'monitoring_cards' && (
        <div className="space-y-6">
          {/* Baris Filter & Pencarian */}
          <div className="bg-white p-4 rounded-2xl border border-[#234B24]/10 flex flex-col md:flex-row md:items-center justify-between gap-3">
            <div className="flex items-center gap-2 flex-wrap flex-1">
              <div className="relative min-w-[240px] flex-1 max-w-sm">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#767676]" />
                <input
                  type="search"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Cari open trip, ketua rombongan, atau meeting point..."
                  className="w-full min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A]"
                />
              </div>

              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                <option value="all">Semua Kategori Perjalanan</option>
                {DESTINATION_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>

              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                <option value="all">Semua Status</option>
                <option value="Terverifikasi">Terverifikasi</option>
                <option value="Menunggu">Menunggu</option>
                <option value="Ditangguhkan">Ditangguhkan</option>
              </select>
            </div>

            <div className="text-xs font-semibold text-[#4A5248]">
              Menampilkan <strong className="text-[#234B24]">{filteredTrips.length}</strong> open trip aktif
            </div>
          </div>

          {/* GRID CARD TAMPILAN BERSIH */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {filteredTrips.map((trip) => {
              const destName = trip.destination_name || trip.destination_route || 'Destinasi Terdaftar';
              const catName = trip.travel_category || 'Wisata Alam & Pegunungan';
              const gmapsUrl = trip.meeting_point_gmaps_url || (trip.meeting_point_coords ? `https://maps.google.com/?q=${trip.meeting_point_coords}` : '#');

              return (
                <div
                  key={trip.id}
                  className="bg-white rounded-2xl p-5 sm:p-6 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] hover:shadow-[0_8px_32px_rgba(35,75,36,0.08)] hover:border-[#234B24]/20 transition-all duration-300 flex flex-col justify-between"
                >
                  <div className="space-y-4">
                    {/* Top Header Card: Kategori Otomatis & Status */}
                    <div className="flex items-start justify-between gap-2">
                      <span className="px-3 py-1 rounded-full text-[11px] font-black bg-[#234B24]/8 text-[#234B24] border border-[#234B24]/12 flex items-center gap-1.5">
                        <img
                          src={getCategoryIconSvg(catName)}
                          alt=""
                          className="w-3.5 h-3.5 object-contain"
                        />
                        <span>{catName}</span>
                      </span>
                      <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-[#1E9E5A]/12 text-[#166534]">
                        {trip.status || 'Terverifikasi'}
                      </span>
                    </div>

                    {/* Judul & 1 Target Destinasi */}
                    <div>
                      <h4 className="text-base font-extrabold text-[#1B1F1A] line-clamp-2 leading-snug">
                        {trip.title}
                      </h4>
                      <div className="flex items-center gap-1.5 mt-1.5 text-xs font-bold text-[#234B24]">
                        <MapPin className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" />
                        <span>Destinasi: {destName}</span>
                      </div>
                    </div>

                    {/* Meeting Point & Koordinat Google Maps */}
                    <div className="p-3.5 rounded-xl bg-[#F6F3EC]/70 border border-[#234B24]/8 space-y-1.5">
                      <div className="text-[10.5px] font-bold text-[#4A5248] uppercase tracking-wider flex items-center justify-between">
                        <span className="flex items-center gap-1.5">
                          <img
                            src="/assets/synced/pin_meeting_point.svg"
                            alt=""
                            className="w-3.5 h-4 object-contain inline-block"
                          />
                          <span>Meeting Point</span>
                        </span>
                        {gmapsUrl !== '#' && (
                          <a
                            href={gmapsUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-[#0D9488] hover:underline flex items-center gap-0.5 text-[10px] font-extrabold"
                          >
                            <span>Google Maps</span>
                            <ExternalLink className="w-3 h-3" />
                          </a>
                        )}
                      </div>
                      <p className="text-xs font-semibold text-[#1B1F1A]">
                        {trip.meeting_point_name || 'Ditetapkan panitia di Bukittinggi'}
                      </p>
                      {trip.meeting_point_coords && (
                        <p className="text-[10px] font-mono text-[#767676]">
                          Koordinat: {trip.meeting_point_coords}
                        </p>
                      )}
                    </div>

                    {/* Info Rombongan & Biaya Split-Bill */}
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div className="p-2.5 rounded-xl bg-white border border-[#234B24]/8 shadow-2xs">
                        <span className="text-[10px] font-bold text-[#767676] block">Ketua Rombongan</span>
                        <strong className="text-[#1B1F1A] truncate block mt-0.5">
                          {trip.trip_leader_name || trip.leader_name || 'Pemandu Pokdarwis'}
                        </strong>
                      </div>
                      <div className="p-2.5 rounded-xl bg-white border border-[#234B24]/8 shadow-2xs">
                        <span className="text-[10px] font-bold text-[#767676] block">Sisa Kuota</span>
                        <strong className="text-[#1E9E5A] block mt-0.5">
                          {trip.available_seats} Kursi Tersedia
                        </strong>
                      </div>
                    </div>

                    <div className="flex items-center justify-between pt-1">
                      <span className="text-xs font-bold text-[#767676]">Biaya / Orang:</span>
                      <strong className="text-sm font-extrabold text-[#234B24] font-mono">
                        Rp {trip.cost_per_person.toLocaleString('id-ID')}
                      </strong>
                    </div>

                    {/* Rincian Biaya Termasuk vs Tidak Termasuk */}
                    {trip.includes && trip.includes.length > 0 && (
                      <div className="space-y-1 pt-1 text-[11px]">
                        <span className="text-[#4A5248] font-bold block">Fasilitas Termasuk:</span>
                        <div className="flex flex-wrap gap-1">
                          {trip.includes.slice(0, 2).map((inc, i) => (
                            <span key={i} className="px-2 py-0.5 rounded-md bg-[#16A34A]/10 text-[#166534] font-medium text-[10px]">
                              ✓ {inc}
                            </span>
                          ))}
                          {trip.includes.length > 2 && (
                            <span className="text-[10px] text-[#767676] font-bold self-center">
                              +{trip.includes.length - 2} lainnya
                            </span>
                          )}
                        </div>
                      </div>
                    )}

                    {/* Status Rekening Penampung (Escrow) WISGO */}
                    <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 space-y-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-extrabold text-[#234B24] flex items-center gap-1.5 text-[11px]">
                          <ShieldCheck className="w-3.5 h-3.5 text-[#16A34A]" />
                          <span>Escrow WISGO</span>
                        </span>
                        <span
                          className={`px-2 py-0.5 rounded-md text-[10px] font-black ${
                            trip.escrow_status === 'DICAIRKAN_KE_PENYELENGGARA'
                              ? 'bg-emerald-100 text-emerald-800'
                              : trip.escrow_status === 'DILAPORKAN_INSIDEN'
                              ? 'bg-red-100 text-red-700 animate-pulse'
                              : 'bg-amber-100 text-amber-800'
                          }`}
                        >
                          {trip.escrow_status === 'DICAIRKAN_KE_PENYELENGGARA'
                            ? 'Dicairkan ke Host'
                            : trip.escrow_status === 'DILAPORKAN_INSIDEN'
                            ? 'Dibekukan (Insiden)'
                            : 'Ditahan Aman di Escrow'}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-[11px] font-mono text-[#4A5248]">
                        <span>Dana Tertahan:</span>
                        <strong className="text-[#234B24]">
                          Rp {(trip.escrow_amount_idr || trip.cost_per_person * 8).toLocaleString('id-ID')}
                        </strong>
                      </div>
                      <div className="flex items-center gap-1.5 pt-0.5">
                        {trip.escrow_status !== 'DICAIRKAN_KE_PENYELENGGARA' && (
                          <button
                            type="button"
                            onClick={() => handleUpdateTripEscrow(trip.id, 'DICAIRKAN_KE_PENYELENGGARA')}
                            className="flex-1 py-1 px-2 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-white text-[10px] font-bold transition text-center shadow-2xs"
                          >
                            Cairkan Escrow
                          </button>
                        )}
                        {trip.escrow_status !== 'DILAPORKAN_INSIDEN' && (
                          <button
                            type="button"
                            onClick={() => handleUpdateTripEscrow(trip.id, 'DILAPORKAN_INSIDEN')}
                            className="flex-1 py-1 px-2 rounded-lg bg-red-100 hover:bg-red-200 text-red-700 text-[10px] font-bold transition text-center"
                          >
                            Bekukan (Sengketa)
                          </button>
                        )}
                        {trip.escrow_status === 'DILAPORKAN_INSIDEN' && (
                          <button
                            type="button"
                            onClick={() => handleUpdateTripEscrow(trip.id, 'DITAHAN_DI_ESCROW')}
                            className="flex-1 py-1 px-2 rounded-lg bg-amber-100 hover:bg-amber-200 text-amber-800 text-[10px] font-bold transition text-center"
                          >
                            Buka Pembekuan
                          </button>
                        )}
                      </div>
                    </div>

                    {/* Ketentuan Aktivitas di Luar Aplikasi */}
                    {trip.external_activity_terms && (
                      <div className="p-2.5 rounded-xl bg-amber-50/70 border border-amber-200/60 text-[11px] text-amber-900 leading-relaxed">
                        <strong>Ketentuan Khusus:</strong> {trip.external_activity_terms}
                      </div>
                    )}
                  </div>

                  {/* Tombol Aksi: Lihat Detail Trip Planner */}
                  <div className="mt-4 pt-3.5 border-t border-[#234B24]/8">
                    <button
                      type="button"
                      onClick={() => setSelectedPlannerTrip(trip)}
                      className="w-full min-h-[42px] px-4 rounded-xl bg-[#234B24] text-white text-xs font-bold hover:bg-[#1B3B1C] transition duration-200 flex items-center justify-center gap-2 shadow-xs"
                    >
                      <ListChecks className="w-4 h-4 text-[#F26B4B]" />
                      <span>Lihat Detail Trip Planner</span>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* 2. SUB-TAB: VERIFIKASI PENYELENGGARA OPEN TRIP */}
      {activeModuleTab === 'organizers_verification' && (
        <div className="space-y-5">
          <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-extrabold text-[#234B24] flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-[#1E9E5A]" />
                Verifikasi &amp; Legalitas Penyelenggara Open Trip
              </h3>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Pemeriksaan berkas KTP, SK Pokdarwis/Nagari, dan Sertifikat Pemandu BNSP untuk menjamin keamanan wisatawan rombongan.
              </p>
            </div>
            <div className="flex items-center gap-2 text-xs font-bold text-[#4A5248]">
              <span className="px-3 py-1.5 rounded-xl bg-[#1E9E5A]/15 text-[#166534]">
                {verifiedOrganizersCount} Penyelenggara Resmi
              </span>
            </div>
          </div>

          <div className="bg-white rounded-3xl border border-[#234B24]/10 shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="bg-[#F6F3EC] border-b border-[#CFD8BE] text-[#4A5248] font-extrabold uppercase tracking-wider">
                    <th className="py-3.5 px-4">Nama Penyelenggara</th>
                    <th className="py-3.5 px-4">Komunitas / Asosiasi Pokdarwis</th>
                    <th className="py-3.5 px-4">Nomor WhatsApp</th>
                    <th className="py-3.5 px-4 text-center">Dokumen Legalitas</th>
                    <th className="py-3.5 px-4 text-center">Status Verifikasi</th>
                    <th className="py-3.5 px-4 text-center min-w-[160px]">Tindakan Admin</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {organizers.map((org) => (
                    <tr key={org.id} className="hover:bg-[#F6F3EC]/50 transition">
                      <td className="py-3.5 px-4 font-bold text-[#1B1F1A]">
                        {org.name}
                      </td>
                      <td className="py-3.5 px-4 text-[#4A5248]">
                        {org.agency_name}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-[#234B24]">
                        +{org.phone_number}
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <div className="flex items-center justify-center gap-1.5 flex-wrap">
                          {org.doc_ktp_url ? (
                            <a
                              href={org.doc_ktp_url}
                              target="_blank"
                              rel="noreferrer"
                              className="px-2 py-1 rounded bg-[#E4E9DA] text-[#234B24] font-bold text-[10px] hover:underline"
                            >
                              KTP
                            </a>
                          ) : (
                            <span className="text-[10px] text-gray-400">-</span>
                          )}
                          {org.doc_sk_pokdarwis_url && (
                            <a
                              href={org.doc_sk_pokdarwis_url}
                              target="_blank"
                              rel="noreferrer"
                              className="px-2 py-1 rounded bg-[#E4E9DA] text-[#234B24] font-bold text-[10px] hover:underline"
                            >
                              SK Pokdarwis
                            </a>
                          )}
                          {org.doc_guide_cert_url && (
                            <a
                              href={org.doc_guide_cert_url}
                              target="_blank"
                              rel="noreferrer"
                              className="px-2 py-1 rounded bg-[#E4E9DA] text-[#234B24] font-bold text-[10px] hover:underline"
                            >
                              Sertifikat Pemandu
                            </a>
                          )}
                        </div>
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <span
                          className={`inline-block px-2.5 py-1 rounded-full text-[10px] font-black ${
                            org.status === 'Terverifikasi'
                              ? 'bg-[#1E9E5A]/15 text-[#166534]'
                              : org.status === 'Menunggu'
                              ? 'bg-amber-100 text-amber-800'
                              : 'bg-red-100 text-red-700'
                          }`}
                        >
                          {org.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <div className="flex items-center justify-center gap-1.5 flex-wrap">
                          <button
                            type="button"
                            onClick={() => setSelectedOrganizerFor7Points(org)}
                            className="px-2.5 py-1 rounded-lg bg-[#234B24]/10 hover:bg-[#234B24]/20 text-[#234B24] font-black text-[10px] transition border border-[#234B24]/15"
                            title="Buka Lembar 7 Poin Verifikasi"
                          >
                            7 Poin
                          </button>
                          {org.status !== 'Terverifikasi' && (
                            <button
                              type="button"
                              onClick={() => handleUpdateOrganizerStatus(org.id, 'Terverifikasi')}
                              className="px-3 py-1 rounded-lg bg-[#1E9E5A] hover:bg-[#166534] text-white font-bold text-xs transition shadow-2xs"
                            >
                              Setujui
                            </button>
                          )}
                          {org.status !== 'Ditolak' && (
                            <button
                              type="button"
                              onClick={() => handleUpdateOrganizerStatus(org.id, 'Ditolak')}
                              className="px-3 py-1 rounded-lg bg-red-100 hover:bg-red-200 text-red-700 font-bold text-xs transition"
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
          </div>
        </div>
      )}

      {/* 3. SUB-TAB: TRANSAKSI OPEN TRIP */}
      {activeModuleTab === 'transactions_recap' && (
        <div className="space-y-5">
          <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-extrabold text-[#234B24] flex items-center gap-2">
                <Receipt className="w-5 h-5 text-[#F26B4B]" />
                Rekap Transaksi Pembayaran Khusus Open Trip
              </h3>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Daftar pembayaran tiket/kuota open trip yang disetor peserta langsung melalui gateway resmi WISGO.
              </p>
            </div>
            <div className="p-3 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] text-right">
              <span className="text-[10px] font-bold uppercase tracking-wider text-[#767676] block">
                Total Penerimaan Escrow
              </span>
              <strong className="text-lg font-black text-[#234B24] font-mono">
                Rp {totalRevenue.toLocaleString('id-ID')}
              </strong>
            </div>
          </div>

          <div className="bg-white rounded-3xl border border-[#234B24]/10 shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="bg-[#F6F3EC] border-b border-[#CFD8BE] text-[#4A5248] font-extrabold uppercase tracking-wider">
                    <th className="py-3.5 px-4">Kode Transaksi</th>
                    <th className="py-3.5 px-4 min-w-[200px]">Agenda Open Trip</th>
                    <th className="py-3.5 px-4">Nama Peserta</th>
                    <th className="py-3.5 px-4 text-center">Kursi</th>
                    <th className="py-3.5 px-4 text-right">Nominal (IDR)</th>
                    <th className="py-3.5 px-4">Kanal Pembayaran</th>
                    <th className="py-3.5 px-4 text-center">Status</th>
                    <th className="py-3.5 px-4 text-center">Waktu Bayar</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {transactions.map((tx) => (
                    <tr key={tx.id} className="hover:bg-[#F6F3EC]/50 transition">
                      <td className="py-3.5 px-4 font-mono font-bold text-[#234B24]">
                        {tx.transaction_code}
                      </td>
                      <td className="py-3.5 px-4 font-semibold text-[#1B1F1A]">
                        {tx.trip_title}
                      </td>
                      <td className="py-3.5 px-4 text-[#4A5248]">
                        <div className="font-bold text-[#1B1F1A]">{tx.participant_name}</div>
                        <div className="text-[10px] font-mono text-[#767676]">+{tx.participant_phone}</div>
                      </td>
                      <td className="py-3.5 px-4 text-center font-bold">
                        {tx.seats_booked} Pax
                      </td>
                      <td className="py-3.5 px-4 text-right font-mono font-bold text-[#234B24]">
                        Rp {tx.amount_idr.toLocaleString('id-ID')}
                      </td>
                      <td className="py-3.5 px-4 font-medium text-[#4A5248]">
                        {tx.payment_channel}
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <span
                          className={`inline-block px-2.5 py-1 rounded-full text-[10px] font-black ${
                            tx.status === 'BERHASIL'
                              ? 'bg-[#1E9E5A]/15 text-[#166534]'
                              : tx.status === 'MENUNGGU'
                              ? 'bg-amber-100 text-amber-800'
                              : 'bg-red-100 text-red-700'
                          }`}
                        >
                          {tx.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-center font-mono text-[11px] text-[#767676]">
                        {new Date(tx.paid_at).toLocaleDateString('id-ID', {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                        })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* 4. SUB-TAB: TEMPLATE BARANG BAWAAN (TRIP PLANNER) */}
      {activeModuleTab === 'packing_templates' && (
        <div className="space-y-6">
          <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-extrabold text-[#234B24] flex items-center gap-2">
                <Luggage className="w-5 h-5 text-[#F26B4B]" />
                Template Rekomendasi Checklist Barang Bawaan
              </h3>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Kelola barang bawaan default per kategori perjalanan untuk menyuplai fitur Trip Planner di aplikasi mobile wisatawan.
              </p>
            </div>
          </div>

          {/* Form Tambah Item Checklist */}
          <form
            onSubmit={handleAddPackingItem}
            className="p-5 rounded-3xl bg-[#F6F3EC] border border-[#CFD8BE] grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 items-end"
          >
            <div>
              <label className="text-[11px] font-bold text-[#4A5248] uppercase block mb-1">
                Kategori Perjalanan *
              </label>
              <select
                value={newTemplateCat}
                onChange={(e) => setNewTemplateCat(e.target.value)}
                className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold text-[#234B24]"
              >
                {DESTINATION_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-[11px] font-bold text-[#4A5248] uppercase block mb-1">
                Nama Barang / Perlengkapan *
              </label>
              <input
                type="text"
                value={newTemplateItem}
                onChange={(e) => setNewTemplateItem(e.target.value)}
                placeholder="Contoh: Sepatu trekking anti-selip"
                className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-semibold text-[#1B1F1A]"
              />
            </div>

            <div>
              <label className="text-[11px] font-bold text-[#4A5248] uppercase block mb-1">
                Catatan Penggunaan
              </label>
              <input
                type="text"
                value={newTemplateNotes}
                onChange={(e) => setNewTemplateNotes(e.target.value)}
                placeholder="Contoh: Wajib untuk keselamatan jalur"
                className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs text-[#1B1F1A]"
              />
            </div>

            <div className="flex items-center gap-3">
              <label className="flex items-center gap-2 text-xs font-bold text-[#234B24] cursor-pointer pb-2">
                <input
                  type="checkbox"
                  checked={newTemplateMandatory}
                  onChange={(e) => setNewTemplateMandatory(e.target.checked)}
                  className="rounded border-[#CFD8BE] text-[#234B24] focus:ring-[#234B24]"
                />
                <span>Wajib Dibawa</span>
              </label>
              <button
                type="submit"
                className="flex-1 min-h-[42px] px-4 rounded-xl bg-[#234B24] text-white text-xs font-bold hover:bg-[#1B3A1C] transition flex items-center justify-center gap-1.5 shadow-xs"
              >
                <Plus className="w-4 h-4" />
                Tambah Item
              </button>
            </div>
          </form>

          {/* Tabel Template Per Kategori */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {DESTINATION_CATEGORIES.map((cat) => {
              const items = packingTemplates.filter((p) => p.category_name === cat);
              return (
                <div
                  key={cat}
                  className="bg-white rounded-3xl p-5 border border-[#234B24]/10 flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between pb-3 border-b border-[#234B24]/10">
                      <h4 className="text-sm font-extrabold text-[#234B24]">{cat}</h4>
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-[#234B24]/10 text-[#234B24]">
                        {items.length} Item
                      </span>
                    </div>

                    <div className="mt-3.5 space-y-2">
                      {items.length === 0 ? (
                        <p className="text-xs text-[#767676] italic py-2">
                          Belum ada rekomendasi barang bawaan untuk kategori ini.
                        </p>
                      ) : (
                        items.map((item) => (
                          <div
                            key={item.id}
                            className="p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]/70 flex items-start justify-between gap-2"
                          >
                            <div className="text-xs">
                              <div className="flex items-center gap-1.5 font-bold text-[#1B1F1A]">
                                {item.is_mandatory && (
                                  <span className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0" />
                                )}
                                <span>{item.item_name}</span>
                              </div>
                              {item.notes && (
                                <p className="text-[10px] text-[#767676] mt-0.5">
                                  {item.notes}
                                </p>
                              )}
                            </div>
                            <button
                              type="button"
                              onClick={() => handleDeletePackingItem(item.id)}
                              className="text-red-600 hover:text-red-800 p-1"
                              title="Hapus"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* MODAL LIHAT DETAIL TRIP PLANNER */}
      {selectedPlannerTrip && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="bg-white rounded-3xl border border-[#CFD8BE] shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden">
            {/* Modal Header */}
            <div className="p-5 border-b border-[#234B24]/10 bg-[#F6F3EC] flex items-center justify-between">
              <div>
                <span className="text-[10px] font-black uppercase tracking-wider text-[#234B24] px-2 py-0.5 rounded bg-white border border-[#234B24]/15">
                  Trip Planner Detail
                </span>
                <h3 className="text-base font-extrabold text-[#1B1F1A] mt-1">
                  {selectedPlannerTrip.title}
                </h3>
                <p className="text-xs text-[#4A5248]">
                  Destinasi: <strong>{selectedPlannerTrip.destination_name || selectedPlannerTrip.destination_route}</strong> • {selectedPlannerTrip.travel_category}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setSelectedPlannerTrip(null)}
                className="w-8 h-8 rounded-full bg-white text-[#767676] hover:text-[#1B1F1A] hover:bg-gray-100 flex items-center justify-center"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="p-6 overflow-y-auto space-y-6 flex-1 text-xs">
              {/* Meeting Point & Integrasi Google Maps */}
              <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#234B24]/10 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-extrabold text-[#234B24] flex items-center gap-1.5 text-xs">
                    <MapPin className="w-4 h-4 text-[#F26B4B]" />
                    <span>Titik Kumpul (Meeting Point) Terintegrasi</span>
                  </span>
                  <a
                    href={
                      selectedPlannerTrip.meeting_point_gmaps_url ||
                      (selectedPlannerTrip.meeting_point_coords
                        ? `https://maps.google.com/?q=${selectedPlannerTrip.meeting_point_coords}`
                        : '#')
                    }
                    target="_blank"
                    rel="noopener noreferrer"
                    className="min-h-[28px] px-2.5 py-1 rounded-lg bg-[#0D9488] hover:bg-[#0F766E] text-white font-extrabold text-[10px] flex items-center gap-1 transition"
                  >
                    <span>Buka Google Maps</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
                <p className="font-bold text-[#1B1F1A]">
                  {selectedPlannerTrip.meeting_point_name || 'Titik Kumpul Terjadwal'}
                </p>
                {selectedPlannerTrip.meeting_point_address && (
                  <p className="text-[11px] text-[#4A5248]">
                    {selectedPlannerTrip.meeting_point_address}
                  </p>
                )}
                {selectedPlannerTrip.meeting_point_coords && (
                  <p className="text-[10px] font-mono text-[#767676]">
                    Koordinat GPS: {selectedPlannerTrip.meeting_point_coords}
                  </p>
                )}
              </div>

              {/* Rincian Biaya Transparan (Includes vs Excludes) */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="p-3.5 rounded-2xl bg-emerald-50/70 border border-emerald-200/80 space-y-2">
                  <span className="font-extrabold text-emerald-900 block text-xs">
                    Fasilitas Termasuk (Include):
                  </span>
                  <ul className="space-y-1.5 text-[11px] text-emerald-800">
                    {(selectedPlannerTrip.includes || [
                      'Transportasi Pulang-Pergi Titik Kumpul - Lokasi',
                      'Tiket Masuk Resmi Retribusi Perda & Asuransi',
                      'Pemandu Berlisensi & First Aid',
                      'Makan Siang & Air Mineral',
                    ]).map((inc, i) => (
                      <li key={i} className="flex items-start gap-1.5">
                        <span className="font-black text-emerald-700">✓</span>
                        <span>{inc}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <div className="p-3.5 rounded-2xl bg-rose-50/70 border border-rose-200/80 space-y-2">
                  <span className="font-extrabold text-rose-900 block text-xs">
                    Tidak Termasuk (Exclude):
                  </span>
                  <ul className="space-y-1.5 text-[11px] text-rose-800">
                    {(selectedPlannerTrip.excludes || [
                      'Pengeluaran Belanja Pribadi & Oleh-oleh',
                      'Wahana Tambahan di Luar Paket',
                      'Tips Sukarela Kru Lapangan',
                    ]).map((exc, i) => (
                      <li key={i} className="flex items-start gap-1.5">
                        <span className="font-black text-rose-600">✕</span>
                        <span>{exc}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>

              {/* 1. Checklist Perjalanan */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <ListChecks className="w-4 h-4 text-[#F26B4B]" />
                  Checklist Tahapan Perjalanan
                </h4>
                <div className="space-y-1.5">
                  {(selectedPlannerTrip.trip_planner?.checklist || [
                    'Konfirmasi kehadiran H-1 via grup WhatsApp',
                    'Briefing keselamatan di titik kumpul',
                    'Pemeriksaan perlengkapan bawaan peserta',
                  ]).map((chk, i) => (
                    <div key={i} className="flex items-center gap-2 p-2.5 rounded-xl bg-[#F6F3EC]">
                      <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0" />
                      <span className="font-semibold text-[#1B1F1A]">{chk}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* 2. Pembagian Jobdesk Peserta / Panitia */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <Briefcase className="w-4 h-4 text-[#3B82F6]" />
                  Pembagian Tugas &amp; Jobdesk Tim
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {(selectedPlannerTrip.trip_planner?.jobdesk_assignments || [
                    { role: 'Pemandu Lapangan', person_name: selectedPlannerTrip.trip_leader_name || 'Ketua Trip' },
                    { role: 'First Aid P3K', person_name: 'Dodi Irawan' },
                  ]).map((job, i) => (
                    <div key={i} className="p-3 rounded-xl bg-blue-50/60 border border-blue-200">
                      <span className="text-[10px] font-bold text-blue-800 uppercase block">{job.role}</span>
                      <strong className="text-xs text-[#1B1F1A] block mt-0.5">{job.person_name}</strong>
                    </div>
                  ))}
                </div>
              </div>

              {/* 3. Checklist Barang Bawaan */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <Luggage className="w-4 h-4 text-amber-600" />
                  Checklist Barang Bawaan Peserta
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5">
                  {(selectedPlannerTrip.trip_planner?.packing_checklist || [
                    'Sepatu trekking anti-selip',
                    'Jas hujan ponco parasut',
                    'Obat-obatan pribadi',
                    'Pakaian ganti kering',
                  ]).map((item, i) => (
                    <div key={i} className="p-2 rounded-lg bg-amber-50/70 border border-amber-200 flex items-center gap-2">
                      <span className="w-1.5 h-1.5 rounded-full bg-amber-600 shrink-0" />
                      <span className="font-medium text-[#1B1F1A]">{item}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* 4. Itinerary Perjalanan */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-[#1E9E5A]" />
                  Rundown &amp; Itinerary
                </h4>
                <div className="space-y-2">
                  {(selectedPlannerTrip.trip_planner?.itinerary || [
                    { day: 1, time: '07.00 - 08.00', activity: 'Kumpul & briefing keselamatan di Meeting Point' },
                    { day: 1, time: '08.00 - 12.00', activity: 'Perjalanan & aktivitas di destinasi' },
                    { day: 1, time: '12.00 - 14.00', activity: 'Makan siang kuliner nagari & istirahat' },
                  ]).map((iti, i) => (
                    <div key={i} className="p-3 rounded-xl bg-gray-50 border border-gray-200 flex items-start gap-3">
                      <span className="px-2 py-0.5 rounded bg-gray-200 font-mono text-[10px] font-bold text-[#234B24] shrink-0">
                        {iti.time}
                      </span>
                      <p className="text-xs font-semibold text-[#1B1F1A]">{iti.activity}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* 5. SOP & Ketentuan Aktivitas di Luar Aplikasi */}
              {selectedPlannerTrip.offline_rules && selectedPlannerTrip.offline_rules.length > 0 && (
                <div className="p-3.5 rounded-2xl bg-amber-50/70 border border-amber-200/80 space-y-2">
                  <span className="font-extrabold text-amber-900 block text-xs">
                    Ketentuan Aktivitas di Luar Aplikasi (SOP Keamanan &amp; Adat):
                  </span>
                  <div className="space-y-1.5">
                    {selectedPlannerTrip.offline_rules.map((rule, i) => (
                      <div key={i} className="text-[11px] text-amber-950">
                        <strong>• {rule.title}:</strong> {rule.ruleDescription}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="p-4 border-t border-[#234B24]/10 bg-[#F6F3EC] flex items-center justify-end">
              <button
                type="button"
                onClick={() => setSelectedPlannerTrip(null)}
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold hover:bg-[#1B3A1C]"
              >
                Tutup Pratinjau
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL 7 POIN VERIFIKASI PENYELENGGARA */}
      {selectedOrganizerFor7Points && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="bg-white rounded-3xl border border-[#CFD8BE] shadow-2xl w-full max-w-xl max-h-[90vh] flex flex-col overflow-hidden">
            {/* Header */}
            <div className="p-5 border-b border-[#234B24]/10 bg-[#F6F3EC] flex items-center justify-between">
              <div>
                <span className="text-[10px] font-black uppercase tracking-wider text-[#166534] px-2 py-0.5 rounded bg-emerald-100 border border-emerald-300">
                  7 Poin Legalitas Penyelenggara
                </span>
                <h3 className="text-base font-extrabold text-[#1B1F1A] mt-1">
                  {selectedOrganizerFor7Points.name}
                </h3>
                <p className="text-xs text-[#4A5248]">
                  {selectedOrganizerFor7Points.agency_name} • WhatsApp: +{selectedOrganizerFor7Points.phone_number}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setSelectedOrganizerFor7Points(null)}
                className="w-8 h-8 rounded-full bg-white text-[#767676] hover:text-[#1B1F1A] hover:bg-gray-100 flex items-center justify-center"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Body 7 Poin */}
            <div className="p-6 overflow-y-auto space-y-3.5 flex-1 text-xs">
              {/* Poin 1 */}
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">1. Status e-KTP Dukcapil</strong>
                  <span className="text-emerald-700 font-semibold text-[11px]">
                    {selectedOrganizerFor7Points.ktp_status || 'Terverifikasi e-KTP Dukcapil RI'}
                  </span>
                </div>
              </div>

              {/* Poin 2 */}
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">2. Dokumen Fisik e-KTP Asli</strong>
                  <span className="text-[#4A5248] text-[11px]">
                    {selectedOrganizerFor7Points.ktp_upload_status || 'Dokumen e-KTP Terunggah & Valid'}
                  </span>
                </div>
              </div>

              {/* Poin 3 */}
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">3. Verifikasi Biometrik Wajah (Liveness Test)</strong>
                  <span className="text-emerald-700 font-semibold text-[11px]">
                    {selectedOrganizerFor7Points.face_verification_status || 'Verifikasi Wajah Liveness Lolos (99.2%)'}
                  </span>
                </div>
              </div>

              {/* Poin 4 */}
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <ShieldCheck className="w-4 h-4 text-[#234B24] shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">4. Lisensi Kepemanduan HPI / Pokdarwis</strong>
                  <span className="text-[#234B24] font-mono text-[11px]">
                    {selectedOrganizerFor7Points.license_number || 'SK Lisensi Pramuwisata HPI Aktif'}
                  </span>
                </div>
              </div>

              {/* Poin 5 */}
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <ShieldCheck className="w-4 h-4 text-[#234B24] shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">5. Sertifikasi Kompetensi &amp; P3K BNSP</strong>
                  <span className="text-[#4A5248] text-[11px]">
                    {selectedOrganizerFor7Points.special_competency || 'Sertifikasi P3K & Wilderness First Aid BNSP'}
                  </span>
                </div>
              </div>

              {/* Poin 6 */}
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <Users className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">6. Rating &amp; Rekam Jejak Trip Selesai</strong>
                  <span className="text-amber-800 font-bold text-[11px]">
                    Rating {selectedOrganizerFor7Points.rating || 4.95} ★ • {selectedOrganizerFor7Points.completed_trips || 38} Perjalanan Selesai
                  </span>
                </div>
              </div>

              {/* Poin 7 */}
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <Compass className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">7. Media Sosial &amp; Jam Terbang Lapangan</strong>
                  <span className="text-blue-700 font-semibold text-[11px] block">
                    {selectedOrganizerFor7Points.social_media || '@wisatapemandu_sumbar'}
                  </span>
                  <span className="text-[#767676] text-[10px]">
                    {selectedOrganizerFor7Points.experience_years || '4+ Tahun Pengalaman Pemandu Wisata Alam'}
                  </span>
                </div>
              </div>

              {/* Rekening Penampung Escrow */}
              <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-950 text-[11px] leading-relaxed">
                <strong>🛡️ Garansi Escrow WISGO:</strong>{' '}
                {selectedOrganizerFor7Points.escrow_protection_note ||
                  'Dana peserta ditahan di Rekening Penampung (Escrow) WISGO dan baru diteruskan ke penyelenggara setelah trip selesai dan terkonfirmasi tanpa insiden pungli.'}
              </div>
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-[#234B24]/10 bg-[#F6F3EC] flex items-center justify-between">
              <span className="text-[11px] text-[#4A5248]">
                Status: <strong>{selectedOrganizerFor7Points.status}</strong>
              </span>
              <button
                type="button"
                onClick={() => setSelectedOrganizerFor7Points(null)}
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold hover:bg-[#1B3A1C]"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
