import React, { useEffect, useId, useMemo, useState } from 'react';
import {
  Store,
  CheckCircle2,
  Search,
  Plus,
  Edit3,
  Trash2,
  Eye,
  Phone,
  Flame,
  Award,
  ExternalLink,
  X,
  Save,
  MapPin,
  Users,
  MessageCircle,
  Map,
  ShieldCheck,
  CreditCard,
} from 'lucide-react';
import {
  CanonicalPartnerCategory,
  Destination,
  Partner,
} from '../types/contract';
import {
  PARTNER_CATEGORIES,
  SUMBAR_REGENCIES,
  normalizePartnerCategory,
} from '../data/mockDestinations';
import { DenahPointsRepo, OpenTripsRepo } from '../services/dbRepository';
import { trackPartnerWaLead } from '../services/api';
import { ImageDropzone } from '../components/ImageDropzone';
import { OpenTripsSubTab } from '../components/OpenTripsSubTab';

export type PartnersSubTab = 'partners_directory' | 'trip_go';

interface PartnersPageProps {
  partners: Partner[];
  destinations: Destination[];
  onSavePartner: (partner: Partner) => Promise<void> | void;
  onDeletePartner: (partnerId: string) => Promise<void> | void;
  onTripsChanged?: () => void;
  onNavigateToStudio360?: (destId: string, tab?: 'panorama') => void;
  initialSelectedPartnerId?: string;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const DIRECT_PAYMENT_OPTIONS = [
  'QRIS Bank Nagari',
  'Transfer Bank',
  'Tunai di Tempat',
] as const;

function normalizeWaDigits(raw: string): string {
  const digits = raw.replace(/\D/g, '');
  if (!digits) return '';
  if (digits.startsWith('62')) return digits;
  if (digits.startsWith('0')) return `62${digits.slice(1)}`;
  return `62${digits}`;
}

function formatWaDisplay(raw: string): string {
  const digits = normalizeWaDigits(raw);
  return digits ? `+${digits}` : '-';
}

export const PartnersPage: React.FC<PartnersPageProps> = ({
  partners,
  destinations,
  onSavePartner,
  onDeletePartner,
  onTripsChanged,
  onNavigateToStudio360,
  initialSelectedPartnerId,
  showToast,
}) => {
  const searchInputId = useId();
  const catFilterId = useId();
  const regencyFilterId = useId();

  const [activeSubTab, setActiveSubTab] = useState<PartnersSubTab>('partners_directory');
  const [tripGoCount, setTripGoCount] = useState<number>(() => OpenTripsRepo.getAll().length);
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [regencyFilter, setRegencyFilter] = useState<string>('all');

  const [selectedPartner, setSelectedPartner] = useState<Partner | null>(() => {
    if (initialSelectedPartnerId) {
      return partners.find((p) => p.id === initialSelectedPartnerId) || null;
    }
    return null;
  });

  useEffect(() => {
    if (initialSelectedPartnerId) {
      const match = partners.find((p) => p.id === initialSelectedPartnerId);
      if (match) {
        setActiveSubTab('partners_directory');
        setSelectedPartner(match);
      }
    }
  }, [initialSelectedPartnerId, partners]);

  const [activeDetailTab, setActiveDetailTab] = useState<'profile' | 'wa_p2p' | 'denah'>(
    'profile'
  );

  // Edit / Create Modal State
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingPartner, setEditingPartner] = useState<Partner | null>(null);

  const [formName, setFormName] = useState('');
  const [formCategory, setFormCategory] = useState<CanonicalPartnerCategory>('Kuliner');
  const [formWhatsapp, setFormWhatsapp] = useState('628');
  const [formStandardFee, setFormStandardFee] = useState<number>(50000);
  const [formNagari, setFormNagari] = useState('');
  const [formCityRegency, setFormCityRegency] = useState('Kab. Lima Puluh Kota');
  const [formOwnerName, setFormOwnerName] = useState('');
  const [formSkNumber, setFormSkNumber] = useState('');
  const [formPhoto, setFormPhoto] = useState('');
  const [formSpicyLevel, setFormSpicyLevel] = useState<number>(3);
  const [formHalal, setFormHalal] = useState(true);
  const [formDestId, setFormDestId] = useState('');
  const [formDenahPointId, setFormDenahPointId] = useState('');
  const [formPaymentMethods, setFormPaymentMethods] = useState<string[]>([
    'QRIS Bank Nagari',
    'Tunai di Tempat',
  ]);

  const allDenahPoints = useMemo(() => DenahPointsRepo.getAll(), [destinations, partners]);

  const findLinkedDenahPoint = (partner: Partner) => {
    return allDenahPoints.find(
      (pt) =>
        (partner.denah_point_id && pt.id === partner.denah_point_id) ||
        pt.partner_id === partner.id
    );
  };

  // KPI Calculations
  const totalVerified = partners.filter((p) => p.is_verified).length;
  const totalWaClicks = useMemo(
    () => partners.reduce((acc, p) => acc + Number(p.wa_click_count || 0), 0),
    [partners]
  );
  const totalLinkedDenah = useMemo(
    () => partners.filter((p) => Boolean(findLinkedDenahPoint(p))).length,
    [partners, allDenahPoints]
  );

  // Filtered Partners
  const filteredPartners = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return partners.filter((p) => {
      const matchQuery =
        !q ||
        p.name.toLowerCase().includes(q) ||
        p.nagari_name.toLowerCase().includes(q) ||
        (p.owner_name && p.owner_name.toLowerCase().includes(q)) ||
        (p.city_regency && p.city_regency.toLowerCase().includes(q)) ||
        (p.pokdarwis_sk_number && p.pokdarwis_sk_number.toLowerCase().includes(q));

      const matchCat = categoryFilter === 'all' ? true : p.category === categoryFilter;

      const matchReg =
        regencyFilter === 'all'
          ? true
          : p.city_regency?.includes(regencyFilter) || p.nagari_name.includes(regencyFilter);

      return matchQuery && matchCat && matchReg;
    });
  }, [partners, searchQuery, categoryFilter, regencyFilter]);

  const availableDenahPointsForFormDest = useMemo(() => {
    if (!formDestId) return [];
    return allDenahPoints.filter(
      (pt) => pt.destination_id === formDestId && pt.category === 'UMKM'
    );
  }, [allDenahPoints, formDestId]);

  const handleOpenCreate = () => {
    const defaultDestId = destinations[0]?.id || 'dest-001';
    setEditingPartner(null);
    setFormName('');
    setFormCategory('Kuliner');
    setFormWhatsapp('628');
    setFormStandardFee(50000);
    setFormNagari('');
    setFormCityRegency(destinations[0]?.city_regency || 'Kab. Lima Puluh Kota');
    setFormOwnerName('');
    setFormSkNumber('SK-POKDARWIS/2026/001');
    setFormPhoto('');
    setFormSpicyLevel(3);
    setFormHalal(true);
    setFormDestId(defaultDestId);
    setFormDenahPointId('');
    setFormPaymentMethods(['QRIS Bank Nagari', 'Tunai di Tempat']);
    setIsEditModalOpen(true);
  };

  const handleOpenEdit = (partner: Partner) => {
    setEditingPartner(partner);
    setFormName(partner.name);
    setFormCategory(normalizePartnerCategory(partner.category));
    setFormWhatsapp(normalizeWaDigits(partner.whatsapp));
    setFormStandardFee(partner.standard_fee);
    setFormNagari(partner.nagari_name);
    setFormCityRegency(partner.city_regency || 'Kab. Lima Puluh Kota');
    setFormOwnerName(partner.owner_name || '');
    setFormSkNumber(partner.pokdarwis_sk_number || 'SK-POKDARWIS/2026/001');
    setFormPhoto(partner.photo_url || '');
    setFormSpicyLevel(partner.spicy_level || 3);
    setFormHalal(partner.halal_certified !== false);
    setFormDestId(partner.destination_id || destinations[0]?.id || 'dest-001');
    setFormDenahPointId(partner.denah_point_id || findLinkedDenahPoint(partner)?.id || '');
    setFormPaymentMethods(
      partner.direct_payment_methods && partner.direct_payment_methods.length > 0
        ? partner.direct_payment_methods
        : ['QRIS Bank Nagari', 'Tunai di Tempat']
    );
    setIsEditModalOpen(true);
  };

  const togglePaymentMethod = (method: string) => {
    setFormPaymentMethods((prev) =>
      prev.includes(method) ? prev.filter((m) => m !== method) : [...prev, method]
    );
  };

  const handleSavePartnerSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanDigits = normalizeWaDigits(formWhatsapp);
    if (!formName.trim() || cleanDigits.length < 9) {
      showToast('Nama mitra dan nomor WhatsApp aktif (minimal 9 digit) wajib diisi.', 'warning');
      return;
    }

    const linkedDest = destinations.find((d) => d.id === formDestId);

    const partnerData: Partner = {
      id: editingPartner ? editingPartner.id : `ptr-${Date.now().toString(36)}`,
      name: formName.trim(),
      category: normalizePartnerCategory(formCategory),
      whatsapp: cleanDigits,
      standard_fee: Number(formStandardFee) || 0,
      fee_myr_estimate: Number(((Number(formStandardFee) || 0) / 3300).toFixed(1)),
      nagari_name: formNagari.trim() || 'Nagari Terdaftar',
      city_regency: formCityRegency,
      owner_name: formOwnerName.trim() || 'Pengelola UMKM Nagari',
      pokdarwis_sk_number: formSkNumber.trim() || 'SK-POKDARWIS/2026/001',
      photo_url: formPhoto.trim() || undefined,
      is_verified: true,
      spicy_level: formCategory === 'Kuliner' ? formSpicyLevel : undefined,
      halal_certified: formHalal,
      destination_id: formDestId || undefined,
      destination_name: linkedDest?.name,
      denah_point_id: formDenahPointId || undefined,
      wa_click_count: editingPartner?.wa_click_count ?? 0,
      direct_payment_methods:
        formPaymentMethods.length > 0 ? formPaymentMethods : ['QRIS Bank Nagari', 'Tunai di Tempat'],
      created_at: editingPartner?.created_at || new Date().toISOString(),
    };

    await onSavePartner(partnerData);
    setIsEditModalOpen(false);
    if (selectedPartner?.id === partnerData.id) {
      setSelectedPartner(partnerData);
    }
    showToast(
      editingPartner
        ? `Data mitra "${partnerData.name}" berhasil diperbarui.`
        : `Mitra UMKM "${partnerData.name}" berhasil didaftarkan.`,
      'success'
    );
  };

  const handleDelete = async (partner: Partner) => {
    if (!window.confirm(`Apakah Anda yakin ingin menghapus data mitra "${partner.name}"?`)) {
      return;
    }

    await onDeletePartner(partner.id);
    if (selectedPartner?.id === partner.id) setSelectedPartner(null);
    showToast(`Mitra "${partner.name}" berhasil dihapus.`, 'info');
  };

  const handleTestWaP2P = async (partner: Partner) => {
    const digits = normalizeWaDigits(partner.whatsapp);
    if (!digits) {
      showToast('Nomor WhatsApp mitra belum valid.', 'warning');
      return;
    }

    const message = `Halo ${partner.name}, saya wisatawan dari aplikasi WISGO Sumbar. Saya ingin menanyakan info & ketersediaan layanan ${partner.category} di ${partner.nagari_name} (Tarif standar Rp ${partner.standard_fee.toLocaleString('id-ID')}). Terima kasih!`;
    const waUrl = `https://wa.me/${digits}?text=${encodeURIComponent(message)}`;

    window.open(waUrl, '_blank', 'noopener,noreferrer');

    const incremented = await trackPartnerWaLead(partner.id);
    if (incremented) {
      await onSavePartner(incremented);
      if (selectedPartner?.id === incremented.id) {
        setSelectedPartner(incremented);
      }
    }
    showToast(
      `Membuka uji WA P2P (+${digits}) & mencatat +1 klik leads untuk ${partner.name}.`,
      'success'
    );
  };

  const handleTripsChanged = () => {
    setTripGoCount(OpenTripsRepo.getAll().length);
    onTripsChanged?.();
  };

  return (
    <div className="space-y-6">
      {/* Header Halaman */}
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            UMKM &amp; Trip Go
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            5 kategori mitra UMKM Direct P2P WhatsApp (0% komisi) dan manajemen Trip Go Escrow.
          </p>
        </div>

        {activeSubTab === 'partners_directory' && (
          <button
            type="button"
            onClick={handleOpenCreate}
            className="min-h-[40px] px-4 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm transition duration-200 shrink-0"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
            <span>Tambah Mitra UMKM</span>
          </button>
        )}
      </header>

      {/* 2 Sub-Tabs Navigasi (Direktori Mitra UMKM & Trip Go) */}
      <nav
        aria-label="Sub-tab UMKM dan Trip Go"
        className="flex overflow-x-auto no-scrollbar whitespace-nowrap shrink-0 gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-sm"
      >
        <button
          type="button"
          onClick={() => setActiveSubTab('partners_directory')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeSubTab === 'partners_directory'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
            }`}
        >
          <Store className="w-3.5 h-3.5" aria-hidden="true" />
          <span>Direktori Mitra UMKM</span>
          <span
            className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold ${activeSubTab === 'partners_directory'
                ? 'bg-white/20 text-white'
                : 'bg-[#234B24]/10 text-[#234B24]'
              }`}
          >
            {partners.length}
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveSubTab('trip_go')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeSubTab === 'trip_go'
              ? 'bg-[#234B24] text-white shadow-sm'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
            }`}
        >
          <Users className="w-3.5 h-3.5" aria-hidden="true" />
          <span>Trip Go &amp; Escrow</span>
          <span
            className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold ${activeSubTab === 'trip_go'
                ? 'bg-white/20 text-white'
                : 'bg-[#234B24]/10 text-[#234B24]'
              }`}
          >
            {tripGoCount}
          </span>
        </button>
      </nav>

      {activeSubTab === 'partners_directory' && (
        <>
          {/* Banner Aturan Tegas Transaksi Direct P2P 0% Komisi */}
          <div className="p-4 rounded-2xl bg-[#234B24]/10 border border-[#234B24]/20 flex items-start gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0 mt-0.5">
              <MessageCircle className="w-5 h-5 text-[#F26B4B]" />
            </div>
            <div className="text-xs">
              <h4 className="font-extrabold text-[#234B24]">
                Model Transaksi Mitra UMKM Nagari: 100% Direct P2P WhatsApp (0% Potongan)
              </h4>
              <p className="text-[#4A5248] mt-0.5 leading-relaxed">
                Seluruh 5 kategori mitra UMKM (<strong>Penginapan, Transportasi, Atraksi, Pakaian Adat, Kuliner</strong>) terhubung langsung ke WhatsApp pengelola nagari dan QRIS Bank Nagari tanpa potongan komisi platform. Sistem Escrow dalam aplikasi <strong>hanya berlaku untuk Trip Go</strong>.
              </p>
            </div>
          </div>

          {/* 3 Kartu KPI */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
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
              <span className="text-xs font-bold text-[#234B24]">Total Klik Leads WA P2P</span>
              <div className="mt-2 text-2xl lg:text-3xl font-extrabold text-[#234B24]">
                {totalWaClicks.toLocaleString('id-ID')}
              </div>
              <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
                Konversi Langsung ke wa.me Mitra
              </p>
            </div>

            <div className="bg-white rounded-2xl p-4 sm:p-5 border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
              <span className="text-xs font-bold text-[#F26B4B]">Kategori Layanan Kanonik</span>
              <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#1B1F1A]">
                5 Kategori
              </div>
              <p className="text-[11px] text-[#4A5248] mt-1">
                Penginapan, Transportasi, Atraksi, Pakaian Adat, Kuliner
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
                <option value="all">Semua 5 Kategori UMKM</option>
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
                      Mitra &amp; Kontak WA
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Kategori UMKM
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Nagari &amp; Kab/Kota
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Tarif Resmi
                    </th>
                    <th scope="col" className="py-3.5 px-4">
                      Leads WA P2P
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
                    filteredPartners.map((partner) => {
                      const linkedDenah = findLinkedDenahPoint(partner);
                      return (
                        <tr key={partner.id} className="hover:bg-[#F6F3EC]/40 transition">
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
                                <div className="font-extrabold text-[#1B1F1A]">{partner.name}</div>
                                <div className="text-[11px] text-[#4A5248]">
                                  Pengelola: {partner.owner_name || 'Masyarakat Nagari'}
                                </div>
                                <div className="text-[10px] text-[#767676] font-mono">
                                  WA: {formatWaDisplay(partner.whatsapp)}
                                </div>
                              </div>
                            </div>
                          </td>

                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <span className="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                              {partner.category}
                            </span>
                            {partner.category === 'Kuliner' && partner.spicy_level && (
                              <div className="text-[10px] text-[#D95637] font-bold mt-1 flex items-center gap-0.5">
                                <Flame className="w-3 h-3" />
                                <span>Level {partner.spicy_level} Pedas</span>
                              </div>
                            )}
                          </td>

                          <td className="py-3.5 px-4 min-w-[160px]">
                            <div className="font-bold text-[#1B1F1A]">{partner.nagari_name}</div>
                            <div className="text-[11px] text-[#4A5248] flex items-center gap-1 mt-0.5">
                              <MapPin className="w-3 h-3 text-[#234B24]" />
                              <span>{partner.city_regency || 'Sumatera Barat'}</span>
                            </div>
                          </td>

                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <div className="font-extrabold text-[#234B24]">
                              Rp {partner.standard_fee.toLocaleString('id-ID')}
                            </div>
                            <div className="text-[10px] text-[#767676]">
                              ± RM {(partner.fee_myr_estimate || partner.standard_fee / 3300).toFixed(1)} MYR
                            </div>
                          </td>

                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <div className="font-extrabold text-[#1E9E5A] font-mono">
                              {(partner.wa_click_count || 0).toLocaleString('id-ID')} Klik
                            </div>
                            <div className="text-[9px] text-[#767676] font-mono mt-0.5 truncate max-w-[130px]">
                              {partner.pokdarwis_sk_number || 'SK Resmi'}
                            </div>
                          </td>

                          <td className="py-3.5 px-4 text-right whitespace-nowrap">
                            <div className="inline-flex items-center gap-1.5">
                              <button
                                type="button"
                                onClick={() => handleTestWaP2P(partner)}
                                className="min-h-[36px] px-2.5 py-1 rounded-xl bg-[#1E9E5A] hover:bg-[#166534] text-white text-[11px] font-bold inline-flex items-center gap-1 shadow-sm transition"
                                title="Uji Pesan WhatsApp Langsung (wa.me)"
                              >
                                <MessageCircle className="w-3.5 h-3.5" />
                                <span>Uji WA P2P</span>
                              </button>
                              <button
                                type="button"
                                onClick={() => {
                                  setSelectedPartner(partner);
                                  setActiveDetailTab('profile');
                                }}
                                className="min-h-[36px] px-3 py-1 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1 shadow-sm transition"
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
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {activeSubTab === 'trip_go' && (
        <OpenTripsSubTab
          destinations={destinations}
          onTripsChanged={handleTripsChanged}
          showToast={showToast}
        />
      )}

      {/* ==================================================================== */}
      {/* MODAL DETAIL MITRA UMKM (PROFIL, UJI WA P2P & DENAH KAWASAN 2D)      */}
      {/* ==================================================================== */}
      {selectedPartner && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
        >
          <div className="bg-white rounded-[28px] w-full max-w-2xl p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 max-h-[92vh] overflow-y-auto flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between pb-4 border-b border-[#234B24]/10">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shadow-sm">
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
                  className={`py-2 rounded-lg transition ${activeDetailTab === 'profile'
                      ? 'bg-white text-[#234B24] shadow-sm'
                      : 'text-[#4A5248] hover:text-[#1B1F1A]'
                    }`}
                >
                  Profil &amp; SK Nagari
                </button>
                <button
                  type="button"
                  onClick={() => setActiveDetailTab('wa_p2p')}
                  className={`py-2 rounded-lg transition ${activeDetailTab === 'wa_p2p'
                      ? 'bg-white text-[#234B24] shadow-sm'
                      : 'text-[#4A5248] hover:text-[#1B1F1A]'
                    }`}
                >
                  Uji WA P2P &amp; Pembayaran
                </button>
              </div>

              {/* TAB A: PROFIL & VERIFIKASI */}
              {activeDetailTab === 'profile' && (
                <div className="mt-5 space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
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
                          WhatsApp Direct P2P Resmi:
                        </span>
                        <div className="font-mono font-bold text-[#234B24] mt-0.5 flex items-center gap-1.5">
                          <Phone className="w-3.5 h-3.5" />
                          <span>{formatWaDisplay(selectedPartner.whatsapp)}</span>
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
                      <span className="font-bold text-[#4A5248]">Tarif Standar Resmi:</span>
                      <div className="text-base font-extrabold text-[#234B24]">
                        Rp {selectedPartner.standard_fee.toLocaleString('id-ID')}
                        <span className="text-xs text-[#767676] font-normal ml-1">
                          (± RM{' '}
                          {(selectedPartner.fee_myr_estimate || selectedPartner.standard_fee / 3300).toFixed(1)}{' '}
                          MYR)
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 flex-wrap">
                      {selectedPartner.halal_certified && (
                        <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#DCFCE7] text-[#166534] border border-[#86EFAC] flex items-center gap-1">
                          <Award className="w-3.5 h-3.5" />
                          <span>Halal Terverifikasi</span>
                        </span>
                      )}
                      {selectedPartner.category === 'Kuliner' && selectedPartner.spicy_level && (
                        <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#FFEDD5] text-[#C2410C] border border-[#FDBA74] flex items-center gap-1">
                          <Flame className="w-3.5 h-3.5" />
                          <span>Level Pedas {selectedPartner.spicy_level}/5</span>
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* TAB B: UJI WA P2P & METODE PEMBAYARAN LANGSUNG */}
              {activeDetailTab === 'wa_p2p' && (
                <div className="mt-5 space-y-4">
                  <div className="p-4 rounded-2xl bg-[#E4E9DA]/60 border border-[#CFD8BE] space-y-3">
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                      <div>
                        <span className="text-[#4A5248] text-xs font-bold block">
                          Kanal WhatsApp Resmi (Direct P2P 0% Komisi):
                        </span>
                        <div className="font-mono text-base font-extrabold text-[#234B24] flex items-center gap-2 mt-0.5">
                          <Phone className="w-4 h-4 text-[#1E9E5A]" />
                          <span>{formatWaDisplay(selectedPartner.whatsapp)}</span>
                        </div>
                        <p className="text-[11px] text-[#4A5248] mt-1">
                          Total Leads Tercatat:{' '}
                          <strong className="text-[#1E9E5A] font-mono">
                            {(selectedPartner.wa_click_count || 0).toLocaleString('id-ID')} Klik WA
                          </strong>
                        </p>
                      </div>

                      <button
                        type="button"
                        onClick={() => handleTestWaP2P(selectedPartner)}
                        className="min-h-[42px] px-4 py-2 rounded-xl bg-[#1E9E5A] hover:bg-[#166534] text-white text-xs font-extrabold inline-flex items-center justify-center gap-2 shadow-sm transition shrink-0"
                      >
                        <MessageCircle className="w-4 h-4" />
                        <span>Uji Pesan WA P2P (wa.me)</span>
                        <ExternalLink className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>

                  <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2.5 text-xs">
                    <h4 className="font-extrabold text-[#1B1F1A] flex items-center gap-1.5">
                      <CreditCard className="w-4 h-4 text-[#234B24]" />
                      <span>Metode Pembayaran Langsung Mitra (Tanpa Escrow)</span>
                    </h4>
                    <div className="flex flex-wrap gap-2">
                      {(selectedPartner.direct_payment_methods || ['QRIS Bank Nagari', 'Tunai di Tempat']).map(
                        (method) => (
                          <span
                            key={method}
                            className="px-3 py-1 rounded-full bg-white border border-[#CFD8BE] text-[#234B24] font-bold text-[11px] inline-flex items-center gap-1"
                          >
                            <CheckCircle2 className="w-3 h-3 text-[#1E9E5A]" />
                            <span>{method}</span>
                          </span>
                        )
                      )}
                    </div>
                    <p className="text-[11px] text-[#4A5248] leading-relaxed">
                      Wisatawan membayar langsung di lokasi atau via QRIS Bank Nagari milik pengelola UMKM. Aplikasi WISGO tidak memotong komisi sepeser pun.
                    </p>
                  </div>
                </div>
              )}

            </div>

            <div className="mt-6 pt-4 border-t border-[#234B24]/10 flex items-center justify-between gap-2">
              <button
                type="button"
                onClick={() => {
                  const target = selectedPartner;
                  setSelectedPartner(null);
                  handleOpenEdit(target);
                }}
                className="min-h-[40px] px-4 py-2 rounded-xl bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24] text-xs font-bold inline-flex items-center gap-1.5"
              >
                <Edit3 className="w-3.5 h-3.5" />
                <span>Edit Data Mitra</span>
              </button>
              <button
                type="button"
                onClick={() => setSelectedPartner(null)}
                className="min-h-[40px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL TAMBAH / EDIT MITRA UMKM                                       */}
      {/* ==================================================================== */}
      {isEditModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
        >
          <div className="bg-white rounded-[28px] w-full max-w-2xl shadow-2xl border border-[#234B24]/10 max-h-[92vh] flex flex-col overflow-hidden">
            <div className="p-5 bg-[#234B24] text-[#F6F3EC] flex items-center justify-between">
              <div>
                <span className="text-[10px] font-bold uppercase tracking-wider text-[#A7F3D0]">
                  Direktori Mitra UMKM Nagari (0% Komisi)
                </span>
                <h2 className="text-base font-extrabold">
                  {editingPartner ? `Edit Mitra: ${editingPartner.name}` : 'Tambah Mitra UMKM Baru'}
                </h2>
              </div>
              <button
                type="button"
                onClick={() => setIsEditModalOpen(false)}
                className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSavePartnerSubmit} className="p-6 overflow-y-auto space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Nama Usaha / Mitra *</label>
                  <input
                    type="text"
                    required
                    value={formName}
                    onChange={(e) => setFormName(e.target.value)}
                    placeholder="Contoh: Homestay Rumah Gadang Harau"
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-medium"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Kategori Kanonik (5 Kategori) *</label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value as CanonicalPartnerCategory)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-bold text-[#234B24]"
                  >
                    {PARTNER_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Nomor WhatsApp Direct P2P *</label>
                  <input
                    type="tel"
                    required
                    value={formWhatsapp}
                    onChange={(e) => setFormWhatsapp(e.target.value)}
                    placeholder="62812xxxxxxxx"
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Tarif Standar Resmi (IDR)</label>
                  <input
                    type="number"
                    min={0}
                    step={5000}
                    value={formStandardFee}
                    onChange={(e) => setFormStandardFee(Number(e.target.value))}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono font-bold"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Nama Pemilik / Pengelola</label>
                  <input
                    type="text"
                    value={formOwnerName}
                    onChange={(e) => setFormOwnerName(e.target.value)}
                    placeholder="Contoh: Bundo Kartini"
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">No. SK Pokdarwis / Nagari</label>
                  <input
                    type="text"
                    value={formSkNumber}
                    onChange={(e) => setFormSkNumber(e.target.value)}
                    placeholder="SK-POKDARWIS/2026/..."
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Nama Nagari / Kawasan</label>
                  <input
                    type="text"
                    value={formNagari}
                    onChange={(e) => setFormNagari(e.target.value)}
                    placeholder="Contoh: Nagari Tarantang"
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Kabupaten / Kota</label>
                  <select
                    value={formCityRegency}
                    onChange={(e) => setFormCityRegency(e.target.value)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-semibold"
                  >
                    {SUMBAR_REGENCIES.filter((r) => r !== 'Semua Kab/Kota').map((reg) => (
                      <option key={reg} value={reg}>
                        {reg}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Destinasi Terkait</label>
                  <select
                    value={formDestId}
                    onChange={(e) => {
                      setFormDestId(e.target.value);
                      setFormDenahPointId('');
                    }}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-semibold"
                  >
                    {destinations.map((d) => (
                      <option key={d.id} value={d.id}>
                        {d.name} ({d.city_regency})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Tautan Titik UMKM di Denah 2D (Opsional)
                  </label>
                  <select
                    value={formDenahPointId}
                    onChange={(e) => setFormDenahPointId(e.target.value)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  >
                    <option value="">Belum ditautkan (Atur di Editor Denah 2D)</option>
                    {availableDenahPointsForFormDest.map((pt) => (
                      <option key={pt.id} value={pt.id}>
                        {pt.title} ({Math.round(pt.x)}%, {Math.round(pt.y)}%)
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Metode Pembayaran Langsung */}
              <div className="p-3.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2">
                <span className="font-bold text-[#234B24] block">
                  Metode Pembayaran Langsung P2P:
                </span>
                <div className="flex flex-wrap gap-3">
                  {DIRECT_PAYMENT_OPTIONS.map((method) => (
                    <label
                      key={method}
                      className="inline-flex items-center gap-1.5 font-semibold text-[#1B1F1A] cursor-pointer"
                    >
                      <input
                        type="checkbox"
                        checked={formPaymentMethods.includes(method)}
                        onChange={() => togglePaymentMethod(method)}
                        className="rounded accent-[#234B24]"
                      />
                      <span>{method}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Opsi Halal & Level Pedas (Khusus Kuliner) */}
              <div className="flex flex-wrap items-center gap-4">
                <label className="inline-flex items-center gap-2 font-bold text-[#234B24] cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formHalal}
                    onChange={(e) => setFormHalal(e.target.checked)}
                    className="rounded accent-[#234B24]"
                  />
                  <ShieldCheck className="w-4 h-4 text-[#1E9E5A]" />
                  <span>Tersertifikasi Halal / Ramah Muslim</span>
                </label>

                {formCategory === 'Kuliner' && (
                  <div className="flex items-center gap-2">
                    <label className="font-bold text-[#D95637]">Level Pedas (1–5):</label>
                    <input
                      type="number"
                      min={1}
                      max={5}
                      value={formSpicyLevel}
                      onChange={(e) => setFormSpicyLevel(Number(e.target.value))}
                      className="w-16 px-2 py-1 rounded-lg bg-[#F6F3EC] border border-[#CFD8BE] font-mono font-bold text-center"
                    />
                  </div>
                )}
              </div>

              {/* Foto Usaha */}
              <ImageDropzone
                label="Foto Usaha / Produk UMKM"
                value={formPhoto}
                onChange={(url) => setFormPhoto(url)}
                onClear={() => setFormPhoto('')}
                helperText="Unggah foto usaha atau tempel URL gambar."
              />

              <div className="pt-3 border-t border-[#234B24]/10 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="min-h-[42px] px-4 py-2 rounded-xl bg-[#F6F3EC] text-[#4A5248] font-bold hover:bg-[#E4E9DA]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[42px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold inline-flex items-center gap-2 shadow-sm"
                >
                  <Save className="w-4 h-4 text-[#F26B4B]" />
                  <span>{editingPartner ? 'Simpan Perubahan' : 'Daftarkan Mitra'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
