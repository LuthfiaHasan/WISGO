import React, { useMemo, useState } from 'react';
import {
  Users,
  Search,
  CheckCircle2,
  Clock,
  MapPin,
  ShieldCheck,
  Compass,
  X,
  ExternalLink,
  Plus,
  Trash2,
  ListChecks,
  Briefcase,
  Luggage,
  CreditCard,
  Receipt,
  UserCheck,
  Edit3,
  Save,
  Lock,
  MessageSquare,
  Send,
  Pin,
} from 'lucide-react';
import {
  Destination,
  EscrowStatus,
  MasterDestinationCategory,
  OpenTrip,
  OpenTripOrganizer,
  OpenTripStatus,
  OpenTripTransaction,
  PackingTemplate,
  TripChatMessageItem,
} from '../types/contract';
import {
  OpenTripsRepo,
  OpenTripOrganizersRepo,
  OpenTripTransactionsRepo,
  PackingTemplatesRepo,
} from '../services/dbRepository';
import {
  MASTER_DESTINATION_CATEGORIES,
  determineCategoryForDestination,
  getCategorySvgPath,
  normalizeDestinationCategory,
} from '../data/mockDestinations';

interface OpenTripsSubTabProps {
  destinations: Destination[];
  onTripsChanged?: () => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

type TripGoModuleSubTab =
  | 'monitoring_cards'
  | 'organizers_verification'
  | 'transactions_recap'
  | 'packing_templates';

export const OpenTripsSubTab: React.FC<OpenTripsSubTabProps> = ({
  destinations,
  onTripsChanged,
  showToast,
}) => {
  const [activeModuleTab, setActiveModuleTab] =
    useState<TripGoModuleSubTab>('monitoring_cards');

  const [trips, setTrips] = useState<OpenTrip[]>(() => OpenTripsRepo.getAll());
  const [organizers, setOrganizers] = useState<OpenTripOrganizer[]>(() =>
    OpenTripOrganizersRepo.getAll()
  );
  const [transactions] = useState<OpenTripTransaction[]>(() =>
    OpenTripTransactionsRepo.getAll()
  );
  const [packingTemplates, setPackingTemplates] = useState<PackingTemplate[]>(() =>
    PackingTemplatesRepo.getAll()
  );

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');

  // Detail Trip Planner & Forum Chat Modal
  const [selectedPlannerTrip, setSelectedPlannerTrip] = useState<OpenTrip | null>(null);
  const [newChatMessage, setNewChatMessage] = useState('');
  const [newChatPinned, setNewChatPinned] = useState(false);

  // 7-Points Organizer Modal
  const [selectedOrganizerFor7Points, setSelectedOrganizerFor7Points] =
    useState<OpenTripOrganizer | null>(null);

  // Create / Edit Trip Go Modal
  const [isTripModalOpen, setIsTripModalOpen] = useState(false);
  const [editingTrip, setEditingTrip] = useState<OpenTrip | null>(null);
  const [formTitle, setFormTitle] = useState('');
  const [formDestId, setFormDestId] = useState<string>(destinations[0]?.id || 'dest-001');
  const [formDepartureDate, setFormDepartureDate] = useState('2026-12-06');
  const [formAvailableSeats, setFormAvailableSeats] = useState<number>(10);
  const [formCostPerPerson, setFormCostPerPerson] = useState<number>(285000);
  const [formLeaderName, setFormLeaderName] = useState('');
  const [formContactWa, setFormContactWa] = useState('62812');
  const [formStatus, setFormStatus] = useState<OpenTripStatus>('Terverifikasi');
  const [formMeetingName, setFormMeetingName] = useState('');
  const [formMeetingAddress, setFormMeetingAddress] = useState('');
  const [formMeetingLat, setFormMeetingLat] = useState<number>(-0.9471);
  const [formMeetingLng, setFormMeetingLng] = useState<number>(100.3543);
  const [formIncludesText, setFormIncludesText] = useState('');
  const [formExcludesText, setFormExcludesText] = useState('');
  const [formExternalTerms, setFormExternalTerms] = useState('');

  // New Packing Template Item Form
  const [newTemplateCat, setNewTemplateCat] =
    useState<MasterDestinationCategory>('Alam & Geopark');
  const [newTemplateItem, setNewTemplateItem] = useState('');
  const [newTemplateMandatory, setNewTemplateMandatory] = useState(true);
  const [newTemplateNotes, setNewTemplateNotes] = useState('');

  // Auto-locked travel category from selected single destination
  const selectedFormDestination = useMemo(
    () => destinations.find((d) => d.id === formDestId) || destinations[0],
    [destinations, formDestId]
  );

  const lockedTravelCategory: MasterDestinationCategory = useMemo(() => {
    if (!selectedFormDestination) return 'Alam & Geopark';
    return normalizeDestinationCategory(
      selectedFormDestination.category ||
      determineCategoryForDestination(selectedFormDestination.name)
    );
  }, [selectedFormDestination]);

  const handleOpenCreateTrip = () => {
    const defaultDest = destinations[0];
    setEditingTrip(null);
    setFormTitle('');
    setFormDestId(defaultDest?.id || 'dest-001');
    setFormDepartureDate('2026-12-12');
    setFormAvailableSeats(10);
    setFormCostPerPerson(275000);
    setFormLeaderName('Uda Hendra (Pokdarwis)');
    setFormContactWa('6281266118899');
    setFormStatus('Terverifikasi');
    setFormMeetingName('Lapangan Imam Bonjol Padang');
    setFormMeetingAddress('Jl. Sudirman, Kec. Padang Barat, Kota Padang');
    setFormMeetingLat(defaultDest?.latitude ?? -0.9471);
    setFormMeetingLng(defaultDest?.longitude ?? 100.3543);
    setFormIncludesText(
      'Transportasi PP ber-AC dari titik kumpul\nTiket masuk resmi Perda & asuransi\nPemandu lokal berlisensi & P3K\nMakan siang kuliner nagari'
    );
    setFormExcludesText('Pengeluaran pribadi & oleh-oleh\nWahana tambahan di luar paket');
    setFormExternalTerms(
      'Peserta wajib mengikuti instruksi pemandu di lapangan dan menjaga kebersihan kawasan.'
    );
    setIsTripModalOpen(true);
  };

  const handleOpenEditTrip = (trip: OpenTrip) => {
    setEditingTrip(trip);
    setFormTitle(trip.title);
    setFormDestId(trip.destination_id || destinations[0]?.id || 'dest-001');
    setFormDepartureDate(trip.departure_date || '2026-12-12');
    setFormAvailableSeats(trip.available_seats);
    setFormCostPerPerson(trip.cost_per_person);
    setFormLeaderName(trip.trip_leader_name);
    setFormContactWa(trip.contact_wa);
    setFormStatus(trip.status);
    setFormMeetingName(trip.meeting_point_name);
    setFormMeetingAddress(trip.meeting_point_address || '');
    setFormMeetingLat(trip.meeting_point_lat ?? -0.9471);
    setFormMeetingLng(trip.meeting_point_lng ?? 100.3543);
    setFormIncludesText((trip.includes || []).join('\n'));
    setFormExcludesText((trip.excludes || []).join('\n'));
    setFormExternalTerms(trip.external_activity_terms || '');
    setIsTripModalOpen(true);
  };

  const handleSaveTripSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim() || !formLeaderName.trim() || !formMeetingName.trim()) {
      showToast('Judul Trip Go, nama ketua rombongan, dan titik kumpul wajib diisi.', 'warning');
      return;
    }

    const dest = selectedFormDestination;
    const destName = dest?.name || 'Lembah Harau & Sarasah Bunta';
    const lat = Number(formMeetingLat) || dest?.latitude || -0.9471;
    const lng = Number(formMeetingLng) || dest?.longitude || 100.3543;
    const includes = formIncludesText
      .split('\n')
      .map((s) => s.trim())
      .filter(Boolean);
    const excludes = formExcludesText
      .split('\n')
      .map((s) => s.trim())
      .filter(Boolean);

    const categoryTemplates = packingTemplates
      .filter((t) => t.category_name === lockedTravelCategory)
      .map((t) => t.item_name);

    const payload: OpenTrip = {
      id: editingTrip ? editingTrip.id : `trip-${Date.now().toString(36)}`,
      user_id: editingTrip?.user_id || 'usr-admin-01',
      title: formTitle.trim(),
      singleDestination: destName,
      destination_id: dest?.id || formDestId,
      destination_name: destName,
      destination_route: destName,
      travel_category: lockedTravelCategory,
      departure_date: formDepartureDate,
      available_seats: Number(formAvailableSeats) || 1,
      quota_filled: editingTrip?.quota_filled ?? 2,
      cost_per_person: Number(formCostPerPerson) || 0,
      contact_wa: formContactWa.replace(/\D/g, '') || '6281266118899',
      trip_leader_name: formLeaderName.trim(),
      status: formStatus,
      meeting_point_name: formMeetingName.trim(),
      meeting_point_address: formMeetingAddress.trim() || dest?.city_regency || 'Sumatera Barat',
      meeting_point_lat: lat,
      meeting_point_lng: lng,
      meeting_point_gmaps_url: `https://maps.google.com/?q=${lat},${lng}`,
      meeting_point_coords: `${lat.toFixed(4)}, ${lng.toFixed(4)}`,
      external_activity_terms: formExternalTerms.trim(),
      includes: includes.length > 0 ? includes : ['Tiket masuk resmi Perda', 'Pemandu lokal berlisensi'],
      excludes: excludes.length > 0 ? excludes : ['Pengeluaran pribadi'],
      escrow_status: editingTrip?.escrow_status || 'DITAHAN_DI_ESCROW',
      escrow_amount_idr:
        editingTrip?.escrow_amount_idr ??
        (Number(formCostPerPerson) || 0) * Math.max(2, editingTrip?.quota_filled ?? 2),
      offline_rules: editingTrip?.offline_rules || [
        {
          title: 'Keselamatan & Adat Nagari',
          ruleDescription: 'Patuhi arahan pemandu lokal serta jaga etika dan kebersihan kawasan.',
        },
      ],
      organizer: editingTrip?.organizer || organizers[0],
      trip_planner: editingTrip?.trip_planner || {
        checklist: [
          'Konfirmasi kehadiran H-1 via Forum Chat Trip Go',
          'Briefing keselamatan di titik kumpul',
          'Pemeriksaan barang bawaan wajib sesuai kategori',
        ],
        jobdesk_assignments: [
          { role: 'Trip Leader', person_name: formLeaderName.trim() },
          { role: 'P3K & Dokumentasi', person_name: 'Kru Pokdarwis Nagari' },
        ],
        packing_checklist:
          categoryTemplates.length > 0
            ? categoryTemplates
            : ['Pakaian nyaman', 'Air minum isi ulang', 'Obat pribadi'],
        itinerary: [
          { day: 1, time: '07.00 - 08.00', activity: `Kumpul & briefing di ${formMeetingName.trim()}` },
          { day: 1, time: '08.30 - 12.30', activity: `Eksplorasi utama ${destName}` },
          { day: 1, time: '12.30 - 14.30', activity: 'Makan siang kuliner nagari & dokumentasi' },
        ],
        messages: [
          {
            id: `msg-${Date.now()}`,
            sender_name: formLeaderName.trim(),
            sender_role: 'Host',
            message: `Selamat datang di grup Trip Go "${formTitle.trim()}". Titik kumpul di ${formMeetingName.trim()}.`,
            timestamp: new Date().toISOString(),
            is_pinned_notice: true,
          },
        ],
      },
      created_at: editingTrip?.created_at || new Date().toISOString(),
    };

    const updated = OpenTripsRepo.save(payload);
    setTrips(updated);
    onTripsChanged?.();
    setIsTripModalOpen(false);
    showToast(
      editingTrip
        ? `Trip Go "${payload.title}" berhasil diperbarui.`
        : `Trip Go baru "${payload.title}" (${lockedTravelCategory}) berhasil dibuat.`,
      'success'
    );
  };

  const handleDeleteTrip = (trip: OpenTrip) => {
    if (!window.confirm(`Hapus agenda Trip Go "${trip.title}"?`)) return;
    const updated = OpenTripsRepo.delete(trip.id);
    setTrips(updated);
    onTripsChanged?.();
    if (selectedPlannerTrip?.id === trip.id) setSelectedPlannerTrip(null);
    showToast(`Agenda Trip Go "${trip.title}" berhasil dihapus.`, 'info');
  };

  const handleUpdateOrganizerStatus = (
    id: string,
    status: 'Menunggu' | 'Terverifikasi' | 'Ditolak'
  ) => {
    const updated = OpenTripOrganizersRepo.updateStatus(id, status);
    setOrganizers(updated);
    showToast(
      status === 'Terverifikasi'
        ? 'Penyelenggara Trip Go berhasil diverifikasi dan disetujui.'
        : 'Status pengajuan penyelenggara Trip Go telah diperbarui.',
      status === 'Terverifikasi' ? 'success' : 'info'
    );
  };

  const handleUpdateTripEscrow = (tripId: string, newStatus: EscrowStatus) => {
    const updated = OpenTripsRepo.updateEscrowStatus(tripId, newStatus);
    setTrips(updated);
    showToast(
      newStatus === 'DICAIRKAN_KE_PENYELENGGARA'
        ? 'Dana Escrow Trip Go berhasil dicairkan ke penyelenggara.'
        : newStatus === 'DILAPORKAN_INSIDEN'
          ? 'Dana Escrow dibekukan sementara karena investigasi laporan insiden.'
          : 'Status dana Escrow dipulihkan ke rekening penampung aman.',
      newStatus === 'DILAPORKAN_INSIDEN' ? 'warning' : 'success'
    );
  };

  const handleSendPlannerChat = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPlannerTrip || !newChatMessage.trim()) return;

    const newMsg: TripChatMessageItem = {
      id: `msg-${Date.now()}`,
      sender_name: 'Admin Komando / Host',
      sender_role: 'Host',
      message: newChatMessage.trim(),
      timestamp: new Date().toISOString(),
      is_pinned_notice: newChatPinned,
    };

    const updatedTrip: OpenTrip = {
      ...selectedPlannerTrip,
      trip_planner: {
        ...selectedPlannerTrip.trip_planner,
        messages: [...(selectedPlannerTrip.trip_planner?.messages || []), newMsg],
      },
    };

    const updatedList = OpenTripsRepo.save(updatedTrip);
    setTrips(updatedList);
    setSelectedPlannerTrip(updatedTrip);
    setNewChatMessage('');
    setNewChatPinned(false);
    showToast('Pesan berhasil dikirim ke Forum Chat In-App Trip Go.', 'success');
  };

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

  const handleDeletePackingItem = (id: string) => {
    const updated = PackingTemplatesRepo.delete(id);
    setPackingTemplates(updated);
    showToast('Item barang bawaan berhasil dihapus.', 'info');
  };

  const filteredTrips = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return trips.filter((t) => {
      const matchQuery =
        !q ||
        t.id.toLowerCase().includes(q) ||
        t.title.toLowerCase().includes(q) ||
        t.trip_leader_name.toLowerCase().includes(q) ||
        t.destination_name.toLowerCase().includes(q) ||
        t.meeting_point_name.toLowerCase().includes(q);
      const matchStatus = statusFilter === 'all' || t.status === statusFilter;
      const matchCat = categoryFilter === 'all' || t.travel_category === categoryFilter;
      return matchQuery && matchStatus && matchCat;
    });
  }, [trips, searchQuery, statusFilter, categoryFilter]);

  const totalRevenue = useMemo(
    () =>
      transactions
        .filter((t) => t.status === 'BERHASIL')
        .reduce((sum, t) => sum + t.amount_idr, 0),
    [transactions]
  );

  const verifiedOrganizersCount = organizers.filter((o) => o.status === 'Terverifikasi').length;
  const pendingOrganizersCount = organizers.filter((o) => o.status === 'Menunggu').length;

  return (
    <div className="space-y-6">
      {/* BANNER ATURAN TEGAS TRANSAKSI ESCROW TRIP GO */}
      <div className="p-4 rounded-2xl bg-[#234B24] text-[#F6F3EC] shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center shrink-0 mt-0.5">
            <Receipt className="w-5 h-5 text-[#F26B4B]" />
          </div>
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-sm font-extrabold tracking-wide uppercase">
                Aturan Tegas Rekening Penampung (Escrow) WISGO
              </h2>
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black bg-[#F26B4B] text-white">
                Khusus Trip Go
              </span>
            </div>
            <p className="text-xs text-[#E4E9DA] mt-0.5 leading-relaxed">
              Sistem pembayaran Escrow di dalam aplikasi <strong>HANYA berlaku untuk Trip Go</strong> (1 destinasi tunggal per perjalanan dengan kategori otomatis). Mitra UMKM biasa menggunakan <strong>Direct P2P WhatsApp (0% komisi)</strong>.
            </p>
          </div>
        </div>

        <div className="shrink-0 flex items-center gap-2 bg-white/10 px-3.5 py-2 rounded-xl text-xs font-semibold">
          <span>Total Escrow Trip Go:</span>
          <strong className="text-[#F26B4B] font-mono text-sm">
            Rp {totalRevenue.toLocaleString('id-ID')}
          </strong>
        </div>
      </div>

      {/* SUB-TAB NAVIGASI MODUL TRIP GO */}
      <div className="bg-white p-2 rounded-2xl border border-[#234B24]/8 shadow-[0_2px_12px_rgba(35,75,36,0.03)] flex flex-wrap items-center gap-2">
        <button
          type="button"
          onClick={() => setActiveModuleTab('monitoring_cards')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${activeModuleTab === 'monitoring_cards'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
            }`}
        >
          <Compass className="w-4 h-4" />
          <span>Monitoring Trip Go</span>
          <span className="px-2 py-0.5 rounded-full text-[10px] bg-white/20">{trips.length}</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveModuleTab('organizers_verification')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${activeModuleTab === 'organizers_verification'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
            }`}
        >
          <UserCheck className="w-4 h-4" />
          <span>Verifikasi Penyelenggara (7 Poin)</span>
          {pendingOrganizersCount > 0 && (
            <span className="px-2 py-0.5 rounded-full text-[10px] bg-amber-500 text-white font-black animate-pulse">
              {pendingOrganizersCount} Menunggu
            </span>
          )}
        </button>

        <button
          type="button"
          onClick={() => setActiveModuleTab('transactions_recap')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${activeModuleTab === 'transactions_recap'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
            }`}
        >
          <CreditCard className="w-4 h-4" />
          <span>Transaksi Escrow Trip Go</span>
          <span className="px-2 py-0.5 rounded-full text-[10px] bg-white/20">
            {transactions.length} Trx
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveModuleTab('packing_templates')}
          className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${activeModuleTab === 'packing_templates'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'bg-[#F6F3EC]/70 text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/8 border border-[#234B24]/8'
            }`}
        >
          <Luggage className="w-4 h-4" />
          <span>Template Barang Bawaan</span>
        </button>
      </div>

      {/* 1. SUB-TAB: MONITORING TRIP GO */}
      {activeModuleTab === 'monitoring_cards' && (
        <div className="space-y-6">
          <div className="bg-white p-4 rounded-2xl border border-[#234B24]/10 flex flex-col lg:flex-row lg:items-center justify-between gap-3">
            <div className="flex items-center gap-2 flex-wrap flex-1">
              <div className="relative min-w-[220px] flex-1 max-w-sm">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#767676]" />
                <input
                  type="search"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Cari Trip Go, ketua rombongan, atau meeting point..."
                  className="w-full min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A]"
                />
              </div>

              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                <option value="all">Semua 5 Kategori Master</option>
                {MASTER_DESTINATION_CATEGORIES.map((cat) => (
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

            <div className="flex items-center gap-3 shrink-0">
              <span className="text-xs font-semibold text-[#4A5248]">
                <strong className="text-[#234B24]">{filteredTrips.length}</strong> Trip Go aktif
              </span>
              <button
                type="button"
                onClick={handleOpenCreateTrip}
                className="min-h-[40px] px-4 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 shadow-xs transition"
              >
                <Plus className="w-4 h-4 text-[#F26B4B]" />
                <span>Buat Trip Go Baru</span>
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {filteredTrips.map((trip) => {
              const destName = trip.destination_name || trip.singleDestination || 'Destinasi Terdaftar';
              const catName = normalizeDestinationCategory(trip.travel_category);
              const gmapsUrl =
                trip.meeting_point_gmaps_url ||
                `https://maps.google.com/?q=${trip.meeting_point_lat},${trip.meeting_point_lng}`;
              const chatCount = trip.trip_planner?.messages?.length || 0;

              return (
                <div
                  key={trip.id}
                  className="bg-white rounded-2xl p-5 sm:p-6 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] hover:shadow-[0_8px_32px_rgba(35,75,36,0.08)] hover:border-[#234B24]/20 transition-all duration-300 flex flex-col justify-between"
                >
                  <div className="space-y-4">
                    {/* Top Header: Kategori Otomatis + Status + Aksi Edit/Hapus */}
                    <div className="flex items-start justify-between gap-2">
                      <span className="px-3 py-1 rounded-full text-[11px] font-black bg-[#234B24]/8 text-[#234B24] border border-[#234B24]/12 flex items-center gap-1.5">
                        <img
                          src={getCategorySvgPath(catName)}
                          alt=""
                          className="w-3.5 h-3.5 object-contain"
                        />
                        <span>{catName}</span>
                      </span>
                      <div className="flex items-center gap-1">
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-[#1E9E5A]/12 text-[#166534]">
                          {trip.status || 'Terverifikasi'}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleOpenEditTrip(trip)}
                          className="p-1.5 rounded-lg text-[#4A5248] hover:text-[#234B24] hover:bg-[#F6F3EC]"
                          title="Edit Trip Go"
                        >
                          <Edit3 className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDeleteTrip(trip)}
                          className="p-1.5 rounded-lg text-[#D95637] hover:bg-[#F26B4B]/15"
                          title="Hapus Trip Go"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>

                    {/* Judul & 1 Target Destinasi */}
                    <div>
                      <h4 className="text-base font-extrabold text-[#1B1F1A] line-clamp-2 leading-snug">
                        {trip.title}
                      </h4>
                      <div className="flex items-center gap-1.5 mt-1.5 text-xs font-bold text-[#234B24]">
                        <MapPin className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" />
                        <span>1 Destinasi: {destName}</span>
                      </div>
                      <p className="text-[11px] text-[#767676] mt-0.5">
                        Berangkat: <strong className="text-[#1B1F1A]">{trip.departure_date}</strong>
                      </p>
                    </div>

                    {/* Meeting Point & Google Maps */}
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
                        <a
                          href={gmapsUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-[#0D9488] hover:underline flex items-center gap-0.5 text-[10px] font-extrabold"
                        >
                          <span>Google Maps</span>
                          <ExternalLink className="w-3 h-3" />
                        </a>
                      </div>
                      <p className="text-xs font-semibold text-[#1B1F1A]">
                        {trip.meeting_point_name}
                      </p>
                      <p className="text-[10px] font-mono text-[#767676]">
                        GPS: {trip.meeting_point_lat}, {trip.meeting_point_lng}
                      </p>
                    </div>

                    {/* Ketua & Kuota */}
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div className="p-2.5 rounded-xl bg-white border border-[#234B24]/8 shadow-2xs">
                        <span className="text-[10px] font-bold text-[#767676] block">
                          Ketua Trip Go
                        </span>
                        <strong className="text-[#1B1F1A] truncate block mt-0.5">
                          {trip.trip_leader_name}
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

                    {trip.includes && trip.includes.length > 0 && (
                      <div className="space-y-1 pt-1 text-[11px]">
                        <span className="text-[#4A5248] font-bold block">Fasilitas Termasuk:</span>
                        <div className="flex flex-wrap gap-1">
                          {trip.includes.slice(0, 2).map((inc, i) => (
                            <span
                              key={i}
                              className="px-2 py-0.5 rounded-md bg-[#16A34A]/10 text-[#166534] font-medium text-[10px]"
                            >
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

                    {/* Status Rekening Penampung Escrow */}
                    <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 space-y-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-extrabold text-[#234B24] flex items-center gap-1.5 text-[11px]">
                          <ShieldCheck className="w-3.5 h-3.5 text-[#16A34A]" />
                          <span>Escrow Trip Go</span>
                        </span>
                        <span
                          className={`px-2 py-0.5 rounded-md text-[10px] font-black ${trip.escrow_status === 'DICAIRKAN_KE_PENYELENGGARA'
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
                              : 'Ditahan di Escrow'}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-[11px] font-mono text-[#4A5248]">
                        <span>Dana Escrow:</span>
                        <strong className="text-[#234B24]">
                          Rp {(trip.escrow_amount_idr || trip.cost_per_person * 4).toLocaleString('id-ID')}
                        </strong>
                      </div>
                      <div className="flex items-center gap-1.5 pt-0.5">
                        {trip.escrow_status !== 'DICAIRKAN_KE_PENYELENGGARA' && (
                          <button
                            type="button"
                            onClick={() =>
                              handleUpdateTripEscrow(trip.id, 'DICAIRKAN_KE_PENYELENGGARA')
                            }
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

                    {trip.external_activity_terms && (
                      <div className="p-2.5 rounded-xl bg-amber-50/70 border border-amber-200/60 text-[11px] text-amber-900 leading-relaxed">
                        <strong>Ketentuan Khusus:</strong> {trip.external_activity_terms}
                      </div>
                    )}
                  </div>

                  {/* Tombol Aksi: Detail Trip Planner & Forum Chat */}
                  <div className="mt-4 pt-3.5 border-t border-[#234B24]/8">
                    <button
                      type="button"
                      onClick={() => setSelectedPlannerTrip(trip)}
                      className="w-full min-h-[42px] px-4 rounded-xl bg-[#234B24] text-white text-xs font-bold hover:bg-[#1B3B1C] transition duration-200 flex items-center justify-center gap-2 shadow-xs"
                    >
                      <ListChecks className="w-4 h-4 text-[#F26B4B]" />
                      <span>Detail Trip Planner &amp; Chat ({chatCount})</span>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* 2. SUB-TAB: VERIFIKASI PENYELENGGARA TRIP GO */}
      {activeModuleTab === 'organizers_verification' && (
        <div className="space-y-5">
          <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-extrabold text-[#234B24] flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-[#1E9E5A]" />
                Verifikasi &amp; Legalitas Penyelenggara Trip Go
              </h3>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Pemeriksaan 7 poin legalitas: e-KTP Dukcapil, Liveness wajah, SK Pokdarwis/Nagari, dan Sertifikat Pemandu HPI/BNSP.
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
                      <td className="py-3.5 px-4 font-bold text-[#1B1F1A]">{org.name}</td>
                      <td className="py-3.5 px-4 text-[#4A5248]">{org.agency_name}</td>
                      <td className="py-3.5 px-4 font-mono text-[#234B24]">+{org.phone_number}</td>
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
                          className={`inline-block px-2.5 py-1 rounded-full text-[10px] font-black ${org.status === 'Terverifikasi'
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

      {/* 3. SUB-TAB: TRANSAKSI ESCROW TRIP GO */}
      {activeModuleTab === 'transactions_recap' && (
        <div className="space-y-5">
          <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-extrabold text-[#234B24] flex items-center gap-2">
                <Receipt className="w-5 h-5 text-[#F26B4B]" />
                Rekap Transaksi Escrow Khusus Trip Go
              </h3>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Pembayaran kuota Trip Go melalui kanal QRIS, WISGO Pay, dan Virtual Account yang terlindungi rekening Escrow.
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
                    <th className="py-3.5 px-4 min-w-[200px]">Agenda Trip Go</th>
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
                      <td className="py-3.5 px-4 font-semibold text-[#1B1F1A]">{tx.trip_title}</td>
                      <td className="py-3.5 px-4 text-[#4A5248]">
                        <div className="font-bold text-[#1B1F1A]">{tx.participant_name}</div>
                        <div className="text-[10px] font-mono text-[#767676]">
                          +{tx.participant_phone}
                        </div>
                      </td>
                      <td className="py-3.5 px-4 text-center font-bold">{tx.seats_booked} Pax</td>
                      <td className="py-3.5 px-4 text-right font-mono font-bold text-[#234B24]">
                        Rp {tx.amount_idr.toLocaleString('id-ID')}
                      </td>
                      <td className="py-3.5 px-4 font-mono font-semibold text-[#4A5248]">
                        {tx.payment_channel}
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <span
                          className={`inline-block px-2.5 py-1 rounded-full text-[10px] font-black ${tx.status === 'BERHASIL'
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

      {/* 4. SUB-TAB: TEMPLATE BARANG BAWAAN (5 KATEGORI MASTER) */}
      {activeModuleTab === 'packing_templates' && (
        <div className="space-y-6">
          <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
            <h3 className="text-base font-extrabold text-[#234B24] flex items-center gap-2">
              <Luggage className="w-5 h-5 text-[#F26B4B]" />
              Template Rekomendasi Checklist Barang Bawaan Trip Go
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Kelola barang bawaan default per 5 kategori master WISGO untuk menyuplai fitur Smart Trip Planner di aplikasi mobile.
            </p>
          </div>

          <form
            onSubmit={handleAddPackingItem}
            className="p-5 rounded-3xl bg-[#F6F3EC] border border-[#CFD8BE] grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 items-end"
          >
            <div>
              <label className="text-[11px] font-bold text-[#4A5248] uppercase block mb-1">
                5 Kategori Master *
              </label>
              <select
                value={newTemplateCat}
                onChange={(e) => setNewTemplateCat(e.target.value as MasterDestinationCategory)}
                className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold text-[#234B24]"
              >
                {MASTER_DESTINATION_CATEGORIES.map((cat) => (
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
                  className="rounded border-[#CFD8BE] accent-[#234B24]"
                />
                <span>Wajib</span>
              </label>
              <button
                type="submit"
                className="flex-1 min-h-[42px] px-4 rounded-xl bg-[#234B24] text-white text-xs font-bold hover:bg-[#1B3A1C] transition flex items-center justify-center gap-1.5 shadow-xs"
              >
                <Plus className="w-4 h-4" />
                <span>Tambah Item</span>
              </button>
            </div>
          </form>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {MASTER_DESTINATION_CATEGORIES.map((cat) => {
              const items = packingTemplates.filter((p) => p.category_name === cat);
              return (
                <div
                  key={cat}
                  className="bg-white rounded-3xl p-5 border border-[#234B24]/10 flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between pb-3 border-b border-[#234B24]/10">
                      <h4 className="text-sm font-extrabold text-[#234B24] flex items-center gap-2">
                        <img
                          src={getCategorySvgPath(cat)}
                          alt=""
                          className="w-4 h-4 object-contain"
                        />
                        <span>{cat}</span>
                      </h4>
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
                                <p className="text-[10px] text-[#767676] mt-0.5">{item.notes}</p>
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

      {/* ==================================================================== */}
      {/* MODAL BUAT / EDIT TRIP GO (1 DESTINASI TUNGGAL AUTO-LOCK KATEGORI)   */}
      {/* ==================================================================== */}
      {isTripModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-3xl border border-[#CFD8BE] shadow-2xl w-full max-w-2xl max-h-[92vh] flex flex-col overflow-hidden">
            <div className="p-5 bg-[#234B24] text-[#F6F3EC] flex items-center justify-between">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider text-[#A7F3D0]">
                  Trip Go • 1 Destinasi Tunggal &amp; Escrow Terlindungi
                </span>
                <h3 className="text-base font-extrabold">
                  {editingTrip ? `Edit Trip Go: ${editingTrip.title}` : 'Buat Agenda Trip Go Baru'}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setIsTripModalOpen(false)}
                className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSaveTripSubmit} className="p-6 overflow-y-auto space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="sm:col-span-2">
                  <label className="block font-bold text-[#1B1F1A] mb-1">Judul Trip Go *</label>
                  <input
                    type="text"
                    required
                    value={formTitle}
                    onChange={(e) => setFormTitle(e.target.value)}
                    placeholder="Contoh: Jelajah Geopark Lembah Harau & Sarasah Bunta"
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-semibold"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Destinasi Tunggal (1 Lokasi) *
                  </label>
                  <select
                    value={formDestId}
                    onChange={(e) => {
                      const nextId = e.target.value;
                      setFormDestId(nextId);
                      const matched = destinations.find((d) => d.id === nextId);
                      if (matched) {
                        setFormMeetingLat(matched.latitude);
                        setFormMeetingLng(matched.longitude);
                      }
                    }}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-bold text-[#234B24]"
                  >
                    {destinations.map((d) => (
                      <option key={d.id} value={d.id}>
                        {d.name} ({d.city_regency})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1 flex items-center gap-1">
                    <Lock className="w-3 h-3 text-[#234B24]" />
                    <span>Kategori Otomatis (Terkunci)</span>
                  </label>
                  <div className="min-h-[42px] px-3.5 py-2 rounded-xl bg-[#E4E9DA]/80 border border-[#CFD8BE] flex items-center gap-2 font-extrabold text-[#234B24]">
                    <img
                      src={getCategorySvgPath(lockedTravelCategory)}
                      alt=""
                      className="w-4 h-4 object-contain"
                    />
                    <span>{lockedTravelCategory}</span>
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Tanggal Berangkat *</label>
                  <input
                    type="date"
                    required
                    value={formDepartureDate}
                    onChange={(e) => setFormDepartureDate(e.target.value)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Status Publikasi</label>
                  <select
                    value={formStatus}
                    onChange={(e) => setFormStatus(e.target.value as OpenTripStatus)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-bold"
                  >
                    <option value="Terverifikasi">Terverifikasi</option>
                    <option value="Menunggu">Menunggu</option>
                    <option value="Ditangguhkan">Ditangguhkan</option>
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Kuota Kursi Tersedia *</label>
                  <input
                    type="number"
                    min={1}
                    max={60}
                    required
                    value={formAvailableSeats}
                    onChange={(e) => setFormAvailableSeats(Number(e.target.value))}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono font-bold"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Biaya / Orang (IDR) *</label>
                  <input
                    type="number"
                    min={0}
                    step={5000}
                    required
                    value={formCostPerPerson}
                    onChange={(e) => setFormCostPerPerson(Number(e.target.value))}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono font-bold"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Ketua Rombongan / Host *</label>
                  <input
                    type="text"
                    required
                    value={formLeaderName}
                    onChange={(e) => setFormLeaderName(e.target.value)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">WhatsApp Host *</label>
                  <input
                    type="tel"
                    required
                    value={formContactWa}
                    onChange={(e) => setFormContactWa(e.target.value)}
                    placeholder="62812xxxxxxxx"
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Titik Kumpul (Meeting Point) *</label>
                  <input
                    type="text"
                    required
                    value={formMeetingName}
                    onChange={(e) => setFormMeetingName(e.target.value)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Alamat Titik Kumpul</label>
                  <input
                    type="text"
                    value={formMeetingAddress}
                    onChange={(e) => setFormMeetingAddress(e.target.value)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Latitude Meeting Point</label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formMeetingLat}
                    onChange={(e) => setFormMeetingLat(Number(e.target.value))}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Longitude Meeting Point</label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formMeetingLng}
                    onChange={(e) => setFormMeetingLng(Number(e.target.value))}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Fasilitas Termasuk (1 per baris)
                  </label>
                  <textarea
                    rows={3}
                    value={formIncludesText}
                    onChange={(e) => setFormIncludesText(e.target.value)}
                    className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Tidak Termasuk (1 per baris)
                  </label>
                  <textarea
                    rows={3}
                    value={formExcludesText}
                    onChange={(e) => setFormExcludesText(e.target.value)}
                    className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>

                <div className="sm:col-span-2">
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Ketentuan Aktivitas di Luar Aplikasi
                  </label>
                  <textarea
                    rows={2}
                    value={formExternalTerms}
                    onChange={(e) => setFormExternalTerms(e.target.value)}
                    className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>
              </div>

              <div className="pt-3 border-t border-[#234B24]/10 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsTripModalOpen(false)}
                  className="min-h-[42px] px-4 py-2 rounded-xl bg-[#F6F3EC] text-[#4A5248] font-bold hover:bg-[#E4E9DA]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[42px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold inline-flex items-center gap-2 shadow-xs"
                >
                  <Save className="w-4 h-4 text-[#F26B4B]" />
                  <span>{editingTrip ? 'Simpan Perubahan' : 'Terbitkan Trip Go'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL DETAIL TRIP PLANNER & FORUM CHAT IN-APP (5 FITUR FE-2)         */}
      {/* ==================================================================== */}
      {selectedPlannerTrip && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="bg-white rounded-3xl border border-[#CFD8BE] shadow-2xl w-full max-w-2xl max-h-[92vh] flex flex-col overflow-hidden">
            <div className="p-5 border-b border-[#234B24]/10 bg-[#F6F3EC] flex items-center justify-between">
              <div>
                <span className="text-[10px] font-black uppercase tracking-wider text-[#234B24] px-2 py-0.5 rounded bg-white border border-[#234B24]/15">
                  Smart Trip Planner &amp; Forum Chat Trip Go
                </span>
                <h3 className="text-base font-extrabold text-[#1B1F1A] mt-1">
                  {selectedPlannerTrip.title}
                </h3>
                <p className="text-xs text-[#4A5248]">
                  Destinasi: <strong>{selectedPlannerTrip.destination_name}</strong> •{' '}
                  {selectedPlannerTrip.travel_category}
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

            <div className="p-6 overflow-y-auto space-y-6 flex-1 text-xs">
              {/* Meeting Point */}
              <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#234B24]/10 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-extrabold text-[#234B24] flex items-center gap-1.5 text-xs">
                    <MapPin className="w-4 h-4 text-[#F26B4B]" />
                    <span>Titik Kumpul (Meeting Point) Terintegrasi</span>
                  </span>
                  <a
                    href={
                      selectedPlannerTrip.meeting_point_gmaps_url ||
                      `https://maps.google.com/?q=${selectedPlannerTrip.meeting_point_lat},${selectedPlannerTrip.meeting_point_lng}`
                    }
                    target="_blank"
                    rel="noopener noreferrer"
                    className="min-h-[28px] px-2.5 py-1 rounded-lg bg-[#0D9488] hover:bg-[#0F766E] text-white font-extrabold text-[10px] flex items-center gap-1 transition"
                  >
                    <span>Buka Google Maps</span>
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
                <p className="font-bold text-[#1B1F1A]">{selectedPlannerTrip.meeting_point_name}</p>
                {selectedPlannerTrip.meeting_point_address && (
                  <p className="text-[11px] text-[#4A5248]">
                    {selectedPlannerTrip.meeting_point_address}
                  </p>
                )}
                <p className="text-[10px] font-mono text-[#767676]">
                  Koordinat GPS: {selectedPlannerTrip.meeting_point_lat},{' '}
                  {selectedPlannerTrip.meeting_point_lng}
                </p>
              </div>

              {/* Includes vs Excludes */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="p-3.5 rounded-2xl bg-emerald-50/70 border border-emerald-200/80 space-y-2">
                  <span className="font-extrabold text-emerald-900 block text-xs">
                    Fasilitas Termasuk (Include):
                  </span>
                  <ul className="space-y-1.5 text-[11px] text-emerald-800">
                    {(selectedPlannerTrip.includes || []).map((inc, i) => (
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
                    {(selectedPlannerTrip.excludes || []).map((exc, i) => (
                      <li key={i} className="flex items-start gap-1.5">
                        <span className="font-black text-rose-600">✕</span>
                        <span>{exc}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>

              {/* 1. Checklist */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <ListChecks className="w-4 h-4 text-[#F26B4B]" />
                  1. Checklist Tahapan Perjalanan
                </h4>
                <div className="space-y-1.5">
                  {(selectedPlannerTrip.trip_planner?.checklist || []).map((chk, i) => (
                    <div key={i} className="flex items-center gap-2 p-2.5 rounded-xl bg-[#F6F3EC]">
                      <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0" />
                      <span className="font-semibold text-[#1B1F1A]">{chk}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* 2. Jobdesk */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <Briefcase className="w-4 h-4 text-[#3B82F6]" />
                  2. Pembagian Tugas &amp; Jobdesk Tim
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {(selectedPlannerTrip.trip_planner?.jobdesk_assignments || []).map((job, i) => (
                    <div key={i} className="p-3 rounded-xl bg-blue-50/60 border border-blue-200">
                      <span className="text-[10px] font-bold text-blue-800 uppercase block">
                        {job.role}
                      </span>
                      <strong className="text-xs text-[#1B1F1A] block mt-0.5">
                        {job.person_name}
                      </strong>
                    </div>
                  ))}
                </div>
              </div>

              {/* 3. Packing List */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <Luggage className="w-4 h-4 text-amber-600" />
                  3. Checklist Barang Bawaan Peserta
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5">
                  {(selectedPlannerTrip.trip_planner?.packing_checklist || []).map((item, i) => (
                    <div
                      key={i}
                      className="p-2 rounded-lg bg-amber-50/70 border border-amber-200 flex items-center gap-2"
                    >
                      <span className="w-1.5 h-1.5 rounded-full bg-amber-600 shrink-0" />
                      <span className="font-medium text-[#1B1F1A]">{item}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* 4. Itinerary */}
              <div className="space-y-2.5">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-[#1E9E5A]" />
                  4. Rundown &amp; Itinerary
                </h4>
                <div className="space-y-2">
                  {(selectedPlannerTrip.trip_planner?.itinerary || []).map((iti, i) => (
                    <div
                      key={i}
                      className="p-3 rounded-xl bg-gray-50 border border-gray-200 flex items-start gap-3"
                    >
                      <span className="px-2 py-0.5 rounded bg-gray-200 font-mono text-[10px] font-bold text-[#234B24] shrink-0">
                        Hari {iti.day} · {iti.time}
                      </span>
                      <p className="text-xs font-semibold text-[#1B1F1A]">{iti.activity}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* 5. Forum Chat In-App (FE-2 Trip Go) */}
              <div className="space-y-3 p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
                <h4 className="text-xs font-black uppercase tracking-wider text-[#234B24] flex items-center gap-1.5">
                  <MessageSquare className="w-4 h-4 text-[#234B24]" />
                  5. Forum Chat In-App Rombongan (Moderasi Host/Admin)
                </h4>

                <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
                  {(selectedPlannerTrip.trip_planner?.messages || []).length === 0 ? (
                    <p className="text-[11px] text-[#767676] italic">
                      Belum ada percakapan di ruang grup Trip Go ini.
                    </p>
                  ) : (
                    (selectedPlannerTrip.trip_planner?.messages || []).map((msg) => (
                      <div
                        key={msg.id}
                        className={`p-3 rounded-xl border ${msg.is_pinned_notice
                            ? 'bg-amber-50 border-amber-300'
                            : msg.sender_role === 'Host'
                              ? 'bg-white border-[#234B24]/20'
                              : 'bg-white/80 border-[#CFD8BE]'
                          }`}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <div className="flex items-center gap-1.5">
                            <strong className="text-[#1B1F1A]">{msg.sender_name}</strong>
                            <span
                              className={`px-1.5 py-0.5 rounded text-[9px] font-black uppercase ${msg.sender_role === 'Host'
                                  ? 'bg-[#234B24] text-white'
                                  : 'bg-[#E4E9DA] text-[#234B24]'
                                }`}
                            >
                              {msg.sender_role}
                            </span>
                            {msg.is_pinned_notice && (
                              <span className="inline-flex items-center gap-0.5 text-[9px] font-black text-amber-800 bg-amber-200/80 px-1.5 py-0.5 rounded">
                                <Pin className="w-2.5 h-2.5" />
                                Pengumuman
                              </span>
                            )}
                          </div>
                          <span className="text-[10px] font-mono text-[#767676]">
                            {new Date(msg.timestamp).toLocaleTimeString('id-ID', {
                              hour: '2-digit',
                              minute: '2-digit',
                            })}
                          </span>
                        </div>
                        <p className="text-[11px] text-[#1B1F1A] mt-1 leading-relaxed">
                          {msg.message}
                        </p>
                      </div>
                    ))
                  )}
                </div>

                <form onSubmit={handleSendPlannerChat} className="space-y-2 pt-2 border-t border-[#CFD8BE]">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={newChatMessage}
                      onChange={(e) => setNewChatMessage(e.target.value)}
                      placeholder="Kirim pengumuman atau instruksi ke grup Trip Go..."
                      className="flex-1 min-h-[38px] px-3 py-1.5 rounded-xl bg-white border border-[#CFD8BE] text-xs"
                    />
                    <button
                      type="submit"
                      className="min-h-[38px] px-3.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold inline-flex items-center gap-1.5"
                    >
                      <Send className="w-3.5 h-3.5" />
                      <span>Kirim</span>
                    </button>
                  </div>
                  <label className="inline-flex items-center gap-1.5 text-[11px] font-bold text-[#4A5248] cursor-pointer">
                    <input
                      type="checkbox"
                      checked={newChatPinned}
                      onChange={(e) => setNewChatPinned(e.target.checked)}
                      className="rounded accent-[#234B24]"
                    />
                    <span>Sematkan sebagai Pengumuman Penting (Pinned Notice)</span>
                  </label>
                </form>
              </div>

              {/* 6. SOP & Ketentuan */}
              {selectedPlannerTrip.offline_rules && selectedPlannerTrip.offline_rules.length > 0 && (
                <div className="p-3.5 rounded-2xl bg-amber-50/70 border border-amber-200/80 space-y-2">
                  <span className="font-extrabold text-amber-900 block text-xs">
                    SOP Keamanan &amp; Adat Aktivitas Lapangan:
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
            <div className="p-5 border-b border-[#234B24]/10 bg-[#F6F3EC] flex items-center justify-between">
              <div>
                <span className="text-[10px] font-black uppercase tracking-wider text-[#166534] px-2 py-0.5 rounded bg-emerald-100 border border-emerald-300">
                  7 Poin Legalitas Penyelenggara Trip Go
                </span>
                <h3 className="text-base font-extrabold text-[#1B1F1A] mt-1">
                  {selectedOrganizerFor7Points.name}
                </h3>
                <p className="text-xs text-[#4A5248]">
                  {selectedOrganizerFor7Points.agency_name} • WhatsApp: +
                  {selectedOrganizerFor7Points.phone_number}
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

            <div className="p-6 overflow-y-auto space-y-3.5 flex-1 text-xs">
              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">1. Status e-KTP Dukcapil</strong>
                  <span className="text-emerald-700 font-semibold text-[11px]">
                    {selectedOrganizerFor7Points.ktp_status || 'Terverifikasi e-KTP Dukcapil RI'}
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">2. Dokumen Fisik e-KTP Asli</strong>
                  <span className="text-[#4A5248] text-[11px]">
                    {selectedOrganizerFor7Points.ktp_upload_status ||
                      'Dokumen e-KTP Terunggah & Valid'}
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">
                    3. Verifikasi Biometrik Wajah (Liveness Test)
                  </strong>
                  <span className="text-emerald-700 font-semibold text-[11px]">
                    {selectedOrganizerFor7Points.face_verification_status ||
                      'Verifikasi Wajah Liveness Lolos (99.2%)'}
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <ShieldCheck className="w-4 h-4 text-[#234B24] shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">
                    4. Lisensi Kepemanduan HPI / Pokdarwis
                  </strong>
                  <span className="text-[#234B24] font-mono text-[11px]">
                    {selectedOrganizerFor7Points.license_number || 'SK Lisensi Pramuwisata HPI Aktif'}
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <ShieldCheck className="w-4 h-4 text-[#234B24] shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">
                    5. Sertifikasi Kompetensi &amp; P3K BNSP
                  </strong>
                  <span className="text-[#4A5248] text-[11px]">
                    {selectedOrganizerFor7Points.special_competency ||
                      'Sertifikasi P3K & Wilderness First Aid BNSP'}
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <Users className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">
                    6. Rating &amp; Rekam Jejak Trip Go Selesai
                  </strong>
                  <span className="text-amber-800 font-bold text-[11px]">
                    Rating {selectedOrganizerFor7Points.rating || 4.95} ★ •{' '}
                    {selectedOrganizerFor7Points.completed_trips || 38} Perjalanan Selesai
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10 flex items-start gap-2.5">
                <Compass className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-[#1B1F1A] block">
                    7. Media Sosial &amp; Jam Terbang Lapangan
                  </strong>
                  <span className="text-blue-700 font-semibold text-[11px] block">
                    {selectedOrganizerFor7Points.social_media || '@wisatapemandu_sumbar'}
                  </span>
                  <span className="text-[#767676] text-[10px]">
                    {selectedOrganizerFor7Points.experience_years ||
                      '4+ Tahun Pengalaman Pemandu Wisata Alam'}
                  </span>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-950 text-[11px] leading-relaxed">
                <strong>Garansi Escrow Trip Go:</strong>{' '}
                {selectedOrganizerFor7Points.escrow_protection_note ||
                  'Dana peserta ditahan di Rekening Penampung (Escrow) WISGO dan baru diteruskan ke penyelenggara setelah Trip Go selesai tanpa insiden.'}
              </div>
            </div>

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
