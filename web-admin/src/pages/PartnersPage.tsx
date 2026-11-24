import React, { useId, useMemo, useState } from 'react';
import {
  Store,
  CheckCircle2,
  ShieldCheck,
  Search,
  Plus,
  Edit3,
  Trash2,
  Eye,
  Camera,
  DollarSign,
  Phone,
  Flame,
  Award,
  Layers,
  ArrowRight,
  ExternalLink,
  Receipt,
  Clock,
  Check,
  X,
  Save,
  Compass,
  Building2,
  MapPin,
  TrendingUp,
  Users,
  MessageSquare,
} from 'lucide-react';
import {
  Destination,
  Partner,
  PartnerCategoryType,
} from '../types/contract';
import { SUMBAR_REGENCIES } from '../data/mockDestinations';
import { ImageDropzone } from '../components/ImageDropzone';
import { OpenTripsSubTab } from '../components/OpenTripsSubTab';
import { CommunityCurationSubTab } from '../components/CommunityCurationSubTab';

export type PartnersSubTab =
  | 'partners_directory'
  | 'open_trips'
  | 'community_curation';

interface PartnersPageProps {
  partners: Partner[];
  destinations: Destination[];
  onSavePartner: (partner: Partner) => Promise<void> | void;
  onDeletePartner: (partnerId: string) => Promise<void> | void;
  onNavigateToStudio360?: (destId: string, sceneId: string, pinId: string) => void;
  initialSelectedPartnerId?: string;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const PARTNER_CATEGORIES: PartnerCategoryType[] = [
  'Homestay Rumah Gadang',
  'Kapal & Transportasi',
  'Pemandu Pokdarwis',
  'Kuliner Halal',
  'Sewa Baju Adat',
];

export const PartnersPage: React.FC<PartnersPageProps> = ({
  partners,
  destinations,
  onSavePartner,
  onDeletePartner,
  onNavigateToStudio360,
  initialSelectedPartnerId,
  showToast,
}) => {
  const searchInputId = useId();
  const catFilterId = useId();
  const regencyFilterId = useId();

  // Search & Filter
  const [activeSubTab, setActiveSubTab] = useState<PartnersSubTab>('partners_directory');
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [regencyFilter, setRegencyFilter] = useState<string>('all');

  // Selected Partner for Detail Drawer/Modal
  const [selectedPartner, setSelectedPartner] = useState<Partner | null>(() => {
    if (initialSelectedPartnerId) {
      return partners.find((p) => p.id === initialSelectedPartnerId) || null;
    }
    return null;
  });

  const [activeDetailTab, setActiveDetailTab] = useState<'profile' | 'contact_catalog' | '360'>(
    'profile'
  );

  // Edit / Create Modal State
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingPartner, setEditingPartner] = useState<Partner | null>(null);

  // Form States for Partner Edit/Create
  const [formName, setFormName] = useState('');
  const [formCategory, setFormCategory] =
    useState<PartnerCategoryType>('Kuliner Halal');
  const [formWhatsapp, setFormWhatsapp] = useState('');
  const [formStandardFee, setFormStandardFee] = useState<number>(50000);
  const [formNagari, setFormNagari] = useState('');
  const [formCityRegency, setFormCityRegency] = useState('Kab. Lima Puluh Kota');
  const [formOwnerName, setFormOwnerName] = useState('');
  const [formSkNumber, setFormSkNumber] = useState('');
  const [formPhoto, setFormPhoto] = useState('');
  const [formSpicyLevel, setFormSpicyLevel] = useState<number>(3);
  const [formHalal, setFormHalal] = useState(true);
  const [formDestId, setFormDestId] = useState('');
  const [formSceneId, setFormSceneId] = useState('');
  const [formPitch, setFormPitch] = useState<number>(-15);
  const [formYaw, setFormYaw] = useState<number>(45);

  // KPI Calculations
  const totalVerified = partners.filter((p) => p.is_verified).length;

  const totalWaClicks = useMemo(() => {
    return partners.reduce((acc, p) => acc + (p.wa_click_count || 120), 0);
  }, [partners]);

  const totalWith360 = partners.filter((p) => p.has_360_pin).length;

  // Filtered Partners
  const filteredPartners = useMemo(() => {
    return partners.filter((p) => {
      const matchQuery =
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.nagari_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (p.owner_name && p.owner_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (p.city_regency && p.city_regency.toLowerCase().includes(searchQuery.toLowerCase()));

      const matchCat =
        categoryFilter === 'all' ? true : p.category === categoryFilter;

      const matchReg =
        regencyFilter === 'all'
          ? true
          : p.city_regency?.includes(regencyFilter) ||
            p.nagari_name.includes(regencyFilter);

      return matchQuery && matchCat && matchReg;
    });
  }, [partners, searchQuery, categoryFilter, regencyFilter]);

  // Open Create Modal
  const handleOpenCreate = () => {
    setEditingPartner(null);
    setFormName('');
    setFormCategory('Kuliner Halal');
    setFormWhatsapp('628');
    setFormStandardFee(50000);
    setFormNagari('');
    setFormCityRegency('Kab. Lima Puluh Kota');
    setFormOwnerName('');
    setFormSkNumber('SK-POKDARWIS/2026/001');
    setFormPhoto('');
    setFormSpicyLevel(3);
    setFormHalal(true);
    setFormDestId(destinations[0]?.id || 'dest-001');
    setFormSceneId(destinations[0]?.scenes_360?.[0]?.id || '');
    setFormPitch(-15);
    setFormYaw(45);
    setIsEditModalOpen(true);
  };

  // Open Edit Modal
  const handleOpenEdit = (partner: Partner) => {
    setEditingPartner(partner);
    setFormName(partner.name);
    setFormCategory(partner.category as PartnerCategoryType);
    setFormWhatsapp(partner.whatsapp);
    setFormStandardFee(partner.standard_fee);
    setFormNagari(partner.nagari_name);
    setFormCityRegency(partner.city_regency || 'Kab. Lima Puluh Kota');
    setFormOwnerName(partner.owner_name || '');
    setFormSkNumber(partner.pokdarwis_sk_number || 'SK-POKDARWIS/2026/001');
    setFormPhoto(partner.photo_url || '');
    setFormSpicyLevel(partner.spicy_level || 3);
    setFormHalal(partner.halal_certified !== false);
    setFormDestId(partner.destination_id || destinations[0]?.id || 'dest-001');
    setFormSceneId(partner.scene_id || '');
    setFormPitch(partner.pitch || -15);
    setFormYaw(partner.yaw || 45);
    setIsEditModalOpen(true);
  };

  // Save Partner
  const handleSavePartnerSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formName.trim() || !formWhatsapp.trim()) {
      showToast('Nama mitra dan nomor WhatsApp wajib diisi.', 'warning');
      return;
    }

    const linkedDest = destinations.find((d) => d.id === formDestId);

    const partnerData: Partner = {
      id: editingPartner ? editingPartner.id : `ptr-${Date.now().toString(36)}`,
      name: formName.trim(),
      category: formCategory,
      whatsapp: formWhatsapp.trim().replace(/\D/g, ''),
      standard_fee: formStandardFee,
      fee_myr_estimate: Math.round((formStandardFee / 3300) * 10) / 10,
      nagari_name: formNagari.trim() || 'Nagari Terdaftar',
      city_regency: formCityRegency,
      owner_name: formOwnerName.trim() || 'Pengelola UMKM Nagari',
      pokdarwis_sk_number: formSkNumber.trim() || 'SK-POKDARWIS/2026/001',
      photo_url: formPhoto.trim() || undefined,
      is_verified: true,
      spicy_level: formCategory === 'Kuliner Halal' ? formSpicyLevel : undefined,
      halal_certified: formHalal,
      destination_id: formDestId || undefined,
      destination_name: linkedDest?.name,
      scene_id: formSceneId || undefined,
      pitch: formPitch,
      yaw: formYaw,
      has_360_pin: Boolean(formDestId && formSceneId),
      wa_click_count: editingPartner?.wa_click_count || 120,
      direct_payment_methods: editingPartner?.direct_payment_methods || [
        'QRIS Bank Nagari',
        'Transfer Bank',
        'Tunai Langsung',
      ],
      created_at: editingPartner?.created_at || new Date().toISOString(),
    };

    await onSavePartner(partnerData);
    setIsEditModalOpen(false);
    if (selectedPartner?.id === partnerData.id) {
      setSelectedPartner(partnerData);
    }
    showToast(
      editingPartner
        ? 'Data mitra UMKM berhasil diperbarui.'
        : 'Mitra UMKM Nagari baru berhasil didaftarkan.',
      'success'
    );
  };

  const handleDelete = async (partner: Partner) => {
    if (
      !window.confirm(
        `Apakah Anda yakin ingin menghapus data mitra "${partner.name}"?`
      )
    ) {
      return;
    }

    await onDeletePartner(partner.id);
    if (selectedPartner?.id === partner.id) setSelectedPartner(null);
    showToast(`Mitra "${partner.name}" berhasil dihapus.`, 'info');
  };

  return (
    <div className="space-y-6">
      {/* Header Halaman */}
      <header className="bg-white rounded-2xl p-6 lg:p-7 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)]">
        <div className="flex flex-col gap-5">
          {/* Baris 1: Judul Halaman & Penjelasan Eksekutif */}
          <div className="flex items-start gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm shrink-0 mt-0.5">
              <Store className="w-6 h-6" aria-hidden="true" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                  Direktori &amp; Verifikasi 5 Kategori Mitra UMKM Nagari
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#234B24]/8 text-[#234B24]">
                  Ekonomi Nagari &amp; Transaksi Langsung P2P
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1 max-w-3xl leading-relaxed">
                Kelola 5 kategori mitra UMKM nagari (Homestay, Kapal, Pemandu Pokdarwis, Kuliner Halal, Sewa Busana Adat), konektivitas kontak langsung WhatsApp (P2P), pemantauan Open Trip wisatawan, dan kurasi tempat wisata komunitas.
              </p>
            </div>
          </div>

          {/* Baris 2: Informasi Otoritas & Tombol Aksi */}
          <div className="pt-4 border-t border-[#234B24]/8 flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2 text-xs text-[#4A5248]">
              <span>Kemitraan Resmi:</span>
              <strong className="text-[#234B24]">Verifikasi Pokdarwis &amp; Pemprov Sumbar</strong>
            </div>

            {activeSubTab === 'partners_directory' && (
              <button
                type="button"
                onClick={handleOpenCreate}
                className="min-h-[44px] px-5 py-2.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center justify-center gap-2 shadow-sm transition duration-200 shrink-0"
              >
                <Plus className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
                <span>Tambah Mitra Nagari Baru</span>
              </button>
            )}
          </div>

          {/* Baris 3: 3 Sub-Tabs Navigasi Header Modern Clean */}
          <div className="pt-4 border-t border-[#234B24]/8 flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() => setActiveSubTab('partners_directory')}
              className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
                activeSubTab === 'partners_directory'
                  ? 'bg-[#234B24] text-white shadow-sm'
                  : 'bg-[#F6F3EC]/70 hover:bg-[#234B24]/8 text-[#4A5248] hover:text-[#234B24] border border-[#234B24]/8'
              }`}
            >
              <Store className="w-4 h-4" aria-hidden="true" />
              <span>Direktori 5 Mitra UMKM &amp; 360°</span>
              <span
                className={`ml-1 px-2 py-0.5 rounded-full text-[10.5px] font-extrabold ${
                  activeSubTab === 'partners_directory'
                    ? 'bg-white/20 text-white'
                    : 'bg-[#234B24]/8 text-[#234B24]'
                }`}
              >
                {partners.length}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setActiveSubTab('open_trips')}
              className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
                activeSubTab === 'open_trips'
                  ? 'bg-[#234B24] text-white shadow-sm'
                  : 'bg-[#F6F3EC]/70 hover:bg-[#234B24]/8 text-[#4A5248] hover:text-[#234B24] border border-[#234B24]/8'
              }`}
            >
              <Users className="w-4 h-4" aria-hidden="true" />
              <span>Pantau Open Trip Wisatawan</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveSubTab('community_curation')}
              className={`min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold transition duration-200 flex items-center gap-2 ${
                activeSubTab === 'community_curation'
                  ? 'bg-[#234B24] text-white shadow-sm'
                  : 'bg-[#F6F3EC]/70 hover:bg-[#234B24]/8 text-[#4A5248] hover:text-[#234B24] border border-[#234B24]/8'
              }`}
            >
              <Compass className="w-4 h-4" aria-hidden="true" />
              <span>Verifikasi Usulan Komunitas</span>
            </button>
          </div>
        </div>
      </header>

      {activeSubTab === 'partners_directory' && (
        <>
          {/* Banner Aturan Tegas Transaksi: UMKM P2P WA */}
          <div className="p-4 rounded-2xl bg-[#234B24]/10 border border-[#234B24]/20 flex items-start gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0 mt-0.5">
              <Phone className="w-5 h-5 text-[#F26B4B]" />
            </div>
            <div className="text-xs">
              <h4 className="font-extrabold text-[#234B24]">
                Model Transaksi Mitra UMKM Nagari: 100% Direct P2P WhatsApp
              </h4>
              <p className="text-[#4A5248] mt-0.5 leading-relaxed">
                Mitra UMKM biasa (Kuliner, Homestay, Sewa Baju Adat, Pemandu) <strong>tidak dikenakan potongan transaksi aplikasi</strong>. Wisatawan langsung terhubung melalui chat WhatsApp resmi mitra. Sistem transaksi pembayaran dalam aplikasi <strong>hanya berlaku khusus untuk Open Trip</strong> demi perlindungan kuota dan split-bill peserta.
              </p>
            </div>
          </div>
          {/* 4 Kartu KPI Statistik Mitra & Interaksi P2P */}
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#4A5248]">Mitra Terverifikasi</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#234B24]">
            {totalVerified}
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            100% Ber-SK Pokdarwis Nagari
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#234B24]">Total Klik / Interaksi WA</span>
          <div className="mt-2 text-2xl lg:text-3xl font-extrabold text-[#234B24]">
            {totalWaClicks.toLocaleString('id-ID')}
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            Leads Langsung ke WhatsApp Mitra
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#1D4ED8]">Terhubung Tur 360°</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#1D4ED8]">
            {totalWith360} Mitra
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Spot &amp; Pin Booking Virtual Aktif
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#F26B4B]">Kategori Layanan Aktif</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#1B1F1A]">
            5 Kategori
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Homestay, Kapal, Tour, Kuliner, Busana
          </p>
        </div>
      </div>

      {/* Filter Bar & Search */}
      <div className="bg-white rounded-2xl p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="relative flex-1">
          <label htmlFor={searchInputId} className="sr-only">
            Cari mitra UMKM
          </label>
          <Search
            className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]"
            aria-hidden="true"
          />
          <input
            id={searchInputId}
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari nama mitra, pengelola, nagari, atau no. SK..."
            className="w-full min-h-[44px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <label htmlFor={catFilterId} className="sr-only">
            Filter Kategori
          </label>
          <select
            id={catFilterId}
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="all">Semua 5 Kategori</option>
            {PARTNER_CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>

          <label htmlFor={regencyFilterId} className="sr-only">
            Filter Wilayah
          </label>
          <select
            id={regencyFilterId}
            value={regencyFilter}
            onChange={(e) => setRegencyFilter(e.target.value)}
            className="min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            {SUMBAR_REGENCIES.map((reg) => (
              <option key={reg} value={reg === 'Semua Kab/Kota' ? 'all' : reg}>
                {reg}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Tabel Data Mitra Nagari */}
      <div className="bg-white rounded-2xl border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#234B24]/10 bg-[#F6F3EC]/70 text-[11px] font-bold text-[#4A5248] uppercase tracking-wider">
                <th scope="col" className="py-3.5 px-4">
                  Mitra &amp; Foto Usaha
                </th>
                <th scope="col" className="py-3.5 px-4">
                  Kategori UMKM
                </th>
                <th scope="col" className="py-3.5 px-4">
                  Nagari &amp; Kab/Kota
                </th>
                <th scope="col" className="py-3.5 px-4">
                  Tarif Layanan Resmi
                </th>
                <th scope="col" className="py-3.5 px-4">
                  Integrasi 360°
                </th>
                <th scope="col" className="py-3.5 px-4">
                  Verifikasi Pokdarwis
                </th>
                <th scope="col" className="py-3.5 px-4 text-right">
                  Aksi
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA] text-xs text-[#1B1F1A]">
              {filteredPartners.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-xs text-[#767676]">
                    Tidak ada mitra UMKM nagari yang cocok dengan filter pencarian.
                  </td>
                </tr>
              ) : (
                filteredPartners.map((partner) => (
                  <tr
                    key={partner.id}
                    className="hover:bg-[#F6F3EC]/40 transition"
                  >
                    {/* Foto & Usaha */}
                    <td className="py-3.5 px-4 min-w-[220px]">
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-xl bg-black/10 overflow-hidden shrink-0 border border-[#CFD8BE]">
                          {partner.photo_url ? (
                            <img
                              src={partner.photo_url}
                              alt={partner.name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-[#767676]">
                              <Store className="w-5 h-5" />
                            </div>
                          )}
                        </div>
                        <div>
                          <div className="font-extrabold text-[#1B1F1A]">
                            {partner.name}
                          </div>
                          <div className="text-[11px] text-[#4A5248]">
                            Pengelola: {partner.owner_name || 'Masyarakat Nagari'}
                          </div>
                          <div className="text-[10px] text-[#767676] font-mono">
                            WA: +{partner.whatsapp}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* Kategori */}
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      <span className="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                        {partner.category}
                      </span>
                      {partner.spicy_level && (
                        <div className="text-[10px] text-[#D95637] font-bold mt-1 flex items-center gap-0.5">
                          <Flame className="w-3 h-3" />
                          <span>Level {partner.spicy_level} Pedas</span>
                        </div>
                      )}
                    </td>

                    {/* Wilayah */}
                    <td className="py-3.5 px-4 min-w-[160px]">
                      <div className="font-bold text-[#1B1F1A]">
                        {partner.nagari_name}
                      </div>
                      <div className="text-[11px] text-[#4A5248] flex items-center gap-1 mt-0.5">
                        <MapPin className="w-3 h-3 text-[#234B24]" />
                        <span>{partner.city_regency || 'Sumatera Barat'}</span>
                      </div>
                    </td>

                    {/* Tarif */}
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      <div className="font-extrabold text-[#234B24]">
                        Rp {partner.standard_fee.toLocaleString('id-ID')}
                      </div>
                      <div className="text-[10px] text-[#767676]">
                        ± RM {(partner.fee_myr_estimate || (partner.standard_fee / 3300)).toFixed(1)} MYR
                      </div>
                    </td>

                    {/* Integrasi 360 */}
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      {partner.has_360_pin ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-[#BFDBFE] text-[#1D4ED8]">
                          <Camera className="w-3 h-3" />
                          <span>Pin 360° Aktif</span>
                        </span>
                      ) : (
                        <span className="text-[10px] text-[#767676]">
                          Belum terhubung
                        </span>
                      )}
                    </td>

                    {/* Verifikasi */}
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      <div className="flex items-center gap-1 text-[11px] font-bold text-[#1E9E5A]">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        <span>Terverifikasi</span>
                      </div>
                      <div className="text-[9px] text-[#767676] font-mono mt-0.5 truncate max-w-[130px]">
                        {partner.pokdarwis_sk_number || 'SK Resmi'}
                      </div>
                    </td>

                    {/* Aksi */}
                    <td className="py-3.5 px-4 text-right whitespace-nowrap">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={() => {
                            setSelectedPartner(partner);
                            setActiveDetailTab('profile');
                          }}
                          className="min-h-[36px] px-3 py-1 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1 shadow-xs transition"
                        >
                          <Eye className="w-3.5 h-3.5" />
                          <span>Detail</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleOpenEdit(partner)}
                          className="min-h-[36px] p-2 rounded-xl bg-white hover:bg-gray-100 text-[#234B24] border border-[#CFD8BE]"
                          title="Edit Mitra"
                        >
                          <Edit3 className="w-3.5 h-3.5" />
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDelete(partner)}
                          className="min-h-[36px] p-2 rounded-xl bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637]"
                          title="Hapus Mitra"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
        </>
      )}

      {activeSubTab === 'open_trips' && (
        <OpenTripsSubTab showToast={showToast} />
      )}

      {activeSubTab === 'community_curation' && (
        <CommunityCurationSubTab showToast={showToast} />
      )}

      {/* ==================================================================== */}
      {/* DRAWER / MODAL: DETAIL LENGKAP MITRA, KONTAK WA P2P & INTEGRASI 360°  */}
      {/* ==================================================================== */}
      {selectedPartner && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-2xl p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 max-h-[92vh] overflow-y-auto flex flex-col justify-between">
            <div>
              {/* Header Modal */}
              <div className="flex items-center justify-between pb-4 border-b border-[#234B24]/10">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shadow-xs">
                    <Store className="w-5 h-5" />
                  </div>
                  <div>
                    <h2 className="text-base font-extrabold text-[#1B1F1A]">
                      {selectedPartner.name}
                    </h2>
                    <p className="text-[11px] text-[#4A5248]">
                      {selectedPartner.category} · {selectedPartner.nagari_name} ({selectedPartner.city_regency})
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedPartner(null)}
                  className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Tab Navigasi Detail */}
              <div className="grid grid-cols-3 bg-[#F6F3EC] rounded-xl p-1 mt-4 text-xs font-bold text-center">
                <button
                  type="button"
                  onClick={() => setActiveDetailTab('profile')}
                  className={`py-2 rounded-lg transition ${
                    activeDetailTab === 'profile'
                      ? 'bg-white text-[#234B24] shadow-xs'
                      : 'text-[#4A5248] hover:text-[#1B1F1A]'
                  }`}
                >
                  Profil &amp; SK Nagari
                </button>
                <button
                  type="button"
                  onClick={() => setActiveDetailTab('contact_catalog')}
                  className={`py-2 rounded-lg transition ${
                    activeDetailTab === 'contact_catalog'
                      ? 'bg-white text-[#234B24] shadow-xs'
                      : 'text-[#4A5248] hover:text-[#1B1F1A]'
                  }`}
                >
                  Katalog Layanan &amp; Kontak WA
                </button>
                <button
                  type="button"
                  onClick={() => setActiveDetailTab('360')}
                  className={`py-2 rounded-lg transition flex items-center justify-center gap-1.5 ${
                    activeDetailTab === '360'
                      ? 'bg-white text-[#1D4ED8] shadow-xs font-extrabold'
                      : 'text-[#4A5248] hover:text-[#1B1F1A]'
                  }`}
                >
                  <Camera className="w-3.5 h-3.5" />
                  <span>Integrasi 360°</span>
                </button>
              </div>

              {/* KONTEN TAB A: PROFIL & VERIFIKASI */}
              {activeDetailTab === 'profile' && (
                <div className="mt-5 space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {/* Foto */}
                    <div className="aspect-[4/3] rounded-2xl bg-black/10 overflow-hidden border border-[#CFD8BE]">
                      {selectedPartner.photo_url ? (
                        <img
                          src={selectedPartner.photo_url}
                          alt={selectedPartner.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-[#767676]">
                          <Store className="w-8 h-8" />
                        </div>
                      )}
                    </div>

                    <div className="space-y-2.5 text-xs">
                      <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                        <span className="text-[#4A5248] block text-[10px] font-bold">
                          Nama Pemilik / Pengelola:
                        </span>
                        <div className="font-extrabold text-[#1B1F1A] text-sm mt-0.5">
                          {selectedPartner.owner_name || 'Masyarakat Nagari'}
                        </div>
                      </div>

                      <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                        <span className="text-[#4A5248] block text-[10px] font-bold">
                          Nomor WhatsApp Bot Transaksi:
                        </span>
                        <div className="font-mono font-bold text-[#234B24] mt-0.5 flex items-center gap-1.5">
                          <Phone className="w-3.5 h-3.5" />
                          <span>+{selectedPartner.whatsapp}</span>
                        </div>
                      </div>

                      <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                        <span className="text-[#4A5248] block text-[10px] font-bold">
                          Nomor SK Verifikasi Pokdarwis / Nagari:
                        </span>
                        <div className="font-mono text-[#1B1F1A] font-bold mt-0.5">
                          {selectedPartner.pokdarwis_sk_number || 'SK-POKDARWIS/2026/001'}
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="p-4 rounded-2xl bg-[#E4E9DA]/70 border border-[#CFD8BE] flex flex-wrap items-center justify-between gap-3 text-xs">
                    <div>
                      <span className="font-bold text-[#4A5248]">
                        Tarif Standar Resmi:
                      </span>
                      <div className="text-base font-extrabold text-[#234B24]">
                        Rp {selectedPartner.standard_fee.toLocaleString('id-ID')}
                        <span className="text-xs text-[#767676] font-normal ml-1">
                          (± RM {(selectedPartner.fee_myr_estimate || (selectedPartner.standard_fee / 3300)).toFixed(1)} MYR)
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2">
                      {selectedPartner.halal_certified && (
                        <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#DCFCE7] text-[#166534] border border-[#86EFAC] flex items-center gap-1">
                          <Award className="w-3.5 h-3.5" />
                          <span>Halal Terverifikasi</span>
                        </span>
                      )}
                      {selectedPartner.spicy_level && (
                        <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#FFEDD5] text-[#C2410C] border border-[#FDBA74] flex items-center gap-1">
                          <Flame className="w-3.5 h-3.5" />
                          <span>Tingkat Kepedasan {selectedPartner.spicy_level}/5</span>
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* KONTEN TAB B: KATALOG LAYANAN & INFORMASI KONTAK */}
              {activeDetailTab === 'contact_catalog' && (
                <div className="mt-5 space-y-4">
                  <div className="p-4 rounded-2xl bg-[#E4E9DA]/60 border border-[#CFD8BE] space-y-3">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                      <div>
                        <span className="text-[#4A5248] text-xs font-bold block">
                          Kanal WhatsApp Resmi (P2P Langsung):
                        </span>
                        <div className="font-mono text-base font-extrabold text-[#234B24] flex items-center gap-2 mt-0.5">
                          <Phone className="w-4 h-4 text-[#1E9E5A]" />
                          <span>+{selectedPartner.whatsapp}</span>
                        </div>
                      </div>

                      <a
                        href={`https://wa.me/${selectedPartner.whatsapp.replace(/\D/g, '')}?text=Halo%20${encodeURIComponent(
                          selectedPartner.name
                        )},%20saya%20melihat%20informasi%20layanan%20Anda%20di%20WISGO.%20Apakah%20layanan%20ini%20tersedia?`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="min-h-[44px] px-5 py-2.5 rounded-xl bg-[#25D366] hover:bg-[#1EBE5D] text-white text-xs font-extrabold inline-flex items-center justify-center gap-2 shadow-sm transition"
                      >
                        <MessageSquare className="w-4 h-4" />
                        <span>Buka Chat WA Mitra (P2P)</span>
                        <ArrowRight className="w-3.5 h-3.5" />
                      </a>
                    </div>
                  </div>

                  {/* Informasi Tarif & Pembayaran Langsung */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 text-xs">
                    <div className="p-3.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                      <span className="text-[#4A5248] block text-[10px] font-bold">
                        Acuan Tarif Transaksi Langsung:
                      </span>
                      <div className="text-base font-extrabold text-[#234B24] mt-0.5">
                        Rp {selectedPartner.standard_fee.toLocaleString('id-ID')}
                        <span className="text-xs text-[#767676] font-normal ml-1">
                          (± RM {(selectedPartner.fee_myr_estimate || (selectedPartner.standard_fee / 3300)).toFixed(1)} MYR)
                        </span>
                      </div>
                      <span className="text-[10px] text-[#4A5248] block mt-1">
                        Dibayar langsung ke mitra via QRIS Nagari / Transfer / Tunai tanpa potongan platform.
                      </span>
                    </div>

                    <div className="p-3.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                      <span className="text-[#4A5248] block text-[10px] font-bold">
                        Total Interaksi Wisatawan (Leads WA):
                      </span>
                      <div className="text-base font-extrabold text-[#1B1F1A] mt-0.5">
                        {(selectedPartner.wa_click_count || 140).toLocaleString('id-ID')} Klik
                      </div>
                      <span className="text-[10px] text-[#1E9E5A] font-bold block mt-1">
                        Wisatawan terhubung langsung ke pengelola
                      </span>
                    </div>
                  </div>

                  {/* Metode Pembayaran Langsung Mitra */}
                  <div className="p-3.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs">
                    <span className="text-[#4A5248] block text-[10px] font-bold mb-2">
                      Metode Pembayaran Langsung (Direct P2P) Diterima Mitra:
                    </span>
                    <div className="flex flex-wrap gap-2">
                      {(selectedPartner.direct_payment_methods || [
                        'QRIS Bank Nagari',
                        'Transfer Bank',
                        'Tunai Langsung',
                      ]).map((method) => (
                        <span
                          key={method}
                          className="px-3 py-1 rounded-full bg-white border border-[#234B24]/20 text-[#234B24] font-bold text-[11px] shadow-2xs"
                        >
                          ✓ {method}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Catatan Otoritas Pariwisata */}
                  <div className="p-3 rounded-xl bg-[#FFEECD] border border-[#FDE047]/60 text-xs text-[#854D0E] flex items-start gap-2">
                    <ShieldCheck className="w-4 h-4 shrink-0 text-[#CA8A04] mt-0.5" />
                    <span>
                      Sistem WISGO menghubungkan wisatawan langsung dengan pengelola nagari. WISGO tidak memungut biaya perantara atau menahan dana. Seluruh transaksi disepakati mandiri (P2P).
                    </span>
                  </div>
                </div>
              )}

              {/* KONTEN TAB C: PRATINJAU & INTEGRASI STUDIO 360° */}
              {activeDetailTab === '360' && (
                <div className="mt-5 space-y-4">
                  <div className="p-4 rounded-2xl bg-[#BFDBFE]/30 border border-[#93C5FD] flex items-center justify-between gap-3 text-xs">
                    <div>
                      <span className="font-bold text-[#1D4ED8]">
                        Status Hubungan Titik Interaktif:
                      </span>
                      <div className="font-extrabold text-[#1B1F1A] mt-0.5">
                        {selectedPartner.has_360_pin ? (
                          <span>
                            Terhubung ke: {selectedPartner.destination_name || 'Destinasi Terdaftar'} (Pitch: {selectedPartner.pitch}°, Yaw: {selectedPartner.yaw}°)
                          </span>
                        ) : (
                          <span className="text-[#D95637]">
                            Belum terhubung ke Scene 360°. Silakan atur di form edit.
                          </span>
                        )}
                      </div>
                    </div>

                    {selectedPartner.destination_id && (
                      <button
                        type="button"
                        onClick={() => {
                          const targetDestId = selectedPartner.destination_id || 'dest-001';
                          const targetSceneId = selectedPartner.scene_id || 'scene-harau-aerial';
                          const targetPinId = selectedPartner.pin_id || 'pin-harau-04';
                          setSelectedPartner(null);
                          if (onNavigateToStudio360) {
                            onNavigateToStudio360(targetDestId, targetSceneId, targetPinId);
                          }
                        }}
                        className="min-h-[44px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5 shadow-sm shrink-0 transition"
                      >
                        <Camera className="w-4 h-4 text-[#A7F3D0]" />
                        <span>Buka &amp; Atur Pin di Studio 360°</span>
                        <ArrowRight className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>

                  {/* Pratinjau Spot 360 Mini */}
                  <div className="relative w-full aspect-[2/1] rounded-2xl overflow-hidden bg-black/90 border-2 border-[#234B24]/40 shadow-inner">
                    <img
                      src={
                        selectedPartner.photo_360_url ||
                        selectedPartner.photo_url ||
                        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80'
                      }
                      alt="Spot 360 Mitra"
                      className="w-full h-full object-cover"
                    />

                    {/* Pin Marker Marker Visual */}
                    <div
                      style={{
                        left: `${(( (selectedPartner.yaw || 0) + 180) / 360) * 100}%`,
                        top: `${((90 - (selectedPartner.pitch || 0)) / 180) * 100}%`,
                      }}
                      className="absolute -translate-x-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-[#F26B4B] text-white flex items-center justify-center shadow-lg border-2 border-white animate-bounce"
                    >
                      <Store className="w-4 h-4" />
                    </div>

                    <div className="absolute bottom-3 left-3 px-3 py-1.5 rounded-xl bg-black/70 backdrop-blur-xs text-white text-[11px] font-bold">
                      Pin Quick Booking: {selectedPartner.name}
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Tombol Footer Modal */}
            <div className="pt-4 border-t border-[#234B24]/10 flex items-center justify-end gap-2.5 mt-5">
              <button
                type="button"
                onClick={() => setSelectedPartner(null)}
                className="min-h-[44px] px-5 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
              >
                Tutup
              </button>
              <button
                type="button"
                onClick={() => {
                  const target = selectedPartner;
                  setSelectedPartner(null);
                  handleOpenEdit(target);
                }}
                className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5"
              >
                <Edit3 className="w-3.5 h-3.5" />
                <span>Ubah Data Mitra</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL TAMBAH / EDIT MITRA NAGARI DENGAN UPLOAD FOTO DEVICE           */}
      {/* ==================================================================== */}
      {isEditModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-xl p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#234B24]/10">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shadow-xs">
                  <Store className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {editingPartner ? 'Edit Data Mitra Nagari' : 'Tambah Mitra UMKM Nagari'}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Dinas Pariwisata Provinsi Sumatera Barat
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsEditModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSavePartnerSubmit} className="mt-5 space-y-4">
              {/* Upload Foto Produk / Tempat Mitra dari Device */}
              <div>
                <ImageDropzone
                  label="Foto Profil / Produk Mitra UMKM (Upload dari Device)"
                  value={formPhoto}
                  onChange={(dataUrl) => setFormPhoto(dataUrl)}
                  onClear={() => setFormPhoto('')}
                  helperText="Pilih foto tempat, makanan, armada kapal, atau busana dari komputer/HP. Otomatis dikompresi ringan."
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Nama Usaha / Mitra UMKM <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  type="text"
                  value={formName}
                  onChange={(e) => setFormName(e.target.value)}
                  placeholder="Contoh: Pondok Kawa Sarasah Harau"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    5 Kategori Mitra <span className="text-[#F26B4B]">*</span>
                  </label>
                  <select
                    value={formCategory}
                    onChange={(e) =>
                      setFormCategory(e.target.value as PartnerCategoryType)
                    }
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    {PARTNER_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Nomor WhatsApp Bot Transaksi <span className="text-[#F26B4B]">*</span>
                  </label>
                  <input
                    type="tel"
                    value={formWhatsapp}
                    onChange={(e) => setFormWhatsapp(e.target.value)}
                    placeholder="62812xxxxxxxx"
                    required
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-medium text-[#1B1F1A]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Nama Pemilik / Pengelola
                  </label>
                  <input
                    type="text"
                    value={formOwnerName}
                    onChange={(e) => setFormOwnerName(e.target.value)}
                    placeholder="Contoh: Uni Evi Susanti"
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Tarif Layanan Resmi (IDR)
                  </label>
                  <input
                    type="number"
                    min={0}
                    step={1000}
                    value={formStandardFee}
                    onChange={(e) => setFormStandardFee(Number(e.target.value))}
                    required
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#234B24]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Nama Nagari / Desa Adat
                  </label>
                  <input
                    type="text"
                    value={formNagari}
                    onChange={(e) => setFormNagari(e.target.value)}
                    placeholder="Contoh: Nagari Harau"
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Kabupaten / Kota
                  </label>
                  <select
                    value={formCityRegency}
                    onChange={(e) => setFormCityRegency(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    {SUMBAR_REGENCIES.filter((r) => r !== 'Semua Kab/Kota').map((reg) => (
                      <option key={reg} value={reg}>
                        {reg}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Nomor SK / Sertifikasi Pokdarwis
                </label>
                <input
                  type="text"
                  value={formSkNumber}
                  onChange={(e) => setFormSkNumber(e.target.value)}
                  placeholder="Contoh: SK-POKDARWIS/50KOTA/2024/018"
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-medium text-[#1B1F1A]"
                />
              </div>

              {/* Khusus Kuliner */}
              {formCategory === 'Kuliner Halal' && (
                <div className="p-3.5 rounded-xl bg-[#FFEDD5]/40 border border-[#FDBA74] space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-[#C2410C]">
                      Tingkat Kepedasan Masakan Minang (1 - 5 Cabai):
                    </span>
                    <span className="text-xs font-extrabold text-[#D95637]">
                      {formSpicyLevel} Cabai
                    </span>
                  </div>
                  <input
                    type="range"
                    min={1}
                    max={5}
                    value={formSpicyLevel}
                    onChange={(e) => setFormSpicyLevel(Number(e.target.value))}
                    className="w-full accent-[#D95637]"
                  />
                </div>
              )}

              {/* Keterkaitan dengan Studio 360 */}
              <div className="p-3.5 rounded-xl bg-[#BFDBFE]/25 border border-[#93C5FD] space-y-2.5">
                <span className="text-xs font-bold text-[#1D4ED8] block">
                  Koneksi Titik Pin di Studio Virtual 360° (Opsional)
                </span>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                  <div>
                    <label className="block text-[10px] text-[#4A5248] mb-1">
                      Destinasi Terkait:
                    </label>
                    <select
                      value={formDestId}
                      onChange={(e) => {
                        setFormDestId(e.target.value);
                        const match = destinations.find((d) => d.id === e.target.value);
                        setFormSceneId(match?.scenes_360?.[0]?.id || '');
                      }}
                      className="w-full min-h-[38px] px-2.5 py-1.5 rounded-lg bg-white border border-[#93C5FD] text-xs font-bold text-[#1B1F1A]"
                    >
                      <option value="">Pilih Destinasi...</option>
                      {destinations.map((d) => (
                        <option key={d.id} value={d.id}>
                          {d.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-[10px] text-[#4A5248] mb-1">
                      Scene 360° Terkait:
                    </label>
                    <select
                      value={formSceneId}
                      onChange={(e) => setFormSceneId(e.target.value)}
                      className="w-full min-h-[38px] px-2.5 py-1.5 rounded-lg bg-white border border-[#93C5FD] text-xs font-bold text-[#1B1F1A]"
                    >
                      <option value="">Pilih Scene...</option>
                      {destinations
                        .find((d) => d.id === formDestId)
                        ?.scenes_360?.map((s) => (
                          <option key={s.id} value={s.id}>
                            {s.title}
                          </option>
                        ))}
                    </select>
                  </div>
                </div>
              </div>

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="min-h-[44px] px-5 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[44px] px-6 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5 shadow-sm"
                >
                  <Save className="w-4 h-4" />
                  <span>Simpan Data Mitra</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
