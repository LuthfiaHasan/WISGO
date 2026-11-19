import React, { useState, useEffect, useId } from 'react';
import {
  Phone,
  ShieldCheck,
  Plus,
  Edit3,
  Trash2,
  Search,
  CheckCircle2,
  Clock,
  Building2,
  MapPin,
  LifeBuoy,
  Flame,
  Radio,
  ExternalLink,
  Save,
  X,
  AlertTriangle,
  Send,
  Eye,
} from 'lucide-react';
import { EmergencyCategoryType, EmergencyContactNumber } from '../types/contract';
import {
  fetchEmergencyContacts,
  saveEmergencyContact,
  deleteEmergencyContact,
} from '../services/api';
import { SUMBAR_REGENCIES } from '../data/mockDestinations';

interface EmergencyContactsManagerProps {
  showToast?: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const EmergencyContactsManager: React.FC<EmergencyContactsManagerProps> = ({
  showToast,
}) => {
  const [contacts, setContacts] = useState<EmergencyContactNumber[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [regencyFilter, setRegencyFilter] = useState<string>('all');

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingContact, setEditingContact] = useState<EmergencyContactNumber | null>(null);

  // Form States
  const [formAgencyName, setFormAgencyName] = useState<string>('');
  const [formCallNumber, setFormCallNumber] = useState<string>('');
  const [formCategory, setFormCategory] = useState<EmergencyCategoryType>('SAR & Basarnas');
  const [formRegency, setFormRegency] = useState<string>('Provinsi Sumatera Barat');
  const [formAddress, setFormAddress] = useState<string>('');
  const [formIs24Hours, setFormIs24Hours] = useState<boolean>(true);
  const [formIsActive, setFormIsActive] = useState<boolean>(true);
  const [formDescription, setFormDescription] = useState<string>('');

  const searchInputId = useId();

  const loadContacts = async () => {
    setLoading(true);
    try {
      const data = await fetchEmergencyContacts();
      setContacts(data);
    } catch {
      showToast?.('Gagal memuat direktori nomor darurat.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadContacts();
  }, []);

  // Filtered Contacts
  const filteredContacts = contacts.filter((c) => {
    const phone = c.call_number || c.phone_number || '';
    const cat = c.category || c.agency_type || '';
    const matchesSearch =
      c.agency_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      phone.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.city_regency.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (c.description && c.description.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchesCategory = categoryFilter === 'all' || cat === categoryFilter;
    const matchesRegency =
      regencyFilter === 'all' ||
      c.city_regency.toLowerCase().includes(regencyFilter.toLowerCase());

    return matchesSearch && matchesCategory && matchesRegency;
  });

  // Open Create Modal
  const handleOpenCreate = () => {
    setEditingContact(null);
    setFormAgencyName('');
    setFormCallNumber('');
    setFormCategory('SAR & Basarnas');
    setFormRegency('Provinsi Sumatera Barat');
    setFormAddress('');
    setFormIs24Hours(true);
    setFormIsActive(true);
    setFormDescription('');
    setIsModalOpen(true);
  };

  // Open Edit Modal
  const handleOpenEdit = (contact: EmergencyContactNumber) => {
    setEditingContact(contact);
    setFormAgencyName(contact.agency_name);
    setFormCallNumber(contact.call_number || contact.phone_number || '');
    setFormCategory(contact.category || contact.agency_type || 'SAR & Basarnas');
    setFormRegency(contact.city_regency);
    setFormAddress(contact.address || '');
    setFormIs24Hours(contact.is_24_hours ?? true);
    setFormIsActive(contact.is_active ?? true);
    setFormDescription(contact.description || '');
    setIsModalOpen(true);
  };

  // Submit Save
  const handleSaveContact = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formAgencyName.trim() || !formCallNumber.trim()) {
      showToast?.('Nama instansi dan nomor panggilan darurat wajib diisi.', 'warning');
      return;
    }

    const contactData: EmergencyContactNumber = {
      id: editingContact ? editingContact.id : `emg-${Date.now().toString(36)}`,
      agency_name: formAgencyName.trim(),
      agency_type: formCategory,
      phone_number: formCallNumber.trim(),
      whatsapp_number: editingContact?.whatsapp_number || null,
      call_number: formCallNumber.trim(),
      category: formCategory,
      city_regency: formRegency,
      address: formAddress.trim() || undefined,
      is_24_hours: formIs24Hours,
      is_active: formIsActive,
      geog: editingContact?.geog || 'SRID=4326;POINT(100.354270 -0.949240)',
      created_by_admin_id: editingContact?.created_by_admin_id || 'usr-admin-01',
      description: formDescription.trim() || undefined,
      updated_at: new Date().toISOString(),
    };

    try {
      const updated = await saveEmergencyContact(contactData);
      setContacts(updated);
      setIsModalOpen(false);
      showToast?.(
        editingContact
          ? 'Nomor darurat berhasil diperbarui.'
          : 'Nomor darurat baru berhasil didaftarkan.',
        'success'
      );
    } catch {
      showToast?.('Gagal menyimpan nomor darurat.', 'error');
    }
  };

  // Delete Contact
  const handleDeleteContact = async (contact: EmergencyContactNumber) => {
    if (!window.confirm(`Hapus nomor darurat "${contact.agency_name}"?`)) return;
    try {
      const updated = await deleteEmergencyContact(contact.id);
      setContacts(updated);
      showToast?.(`Nomor darurat "${contact.agency_name}" telah dihapus.`, 'info');
    } catch {
      showToast?.('Gagal menghapus nomor darurat.', 'error');
    }
  };

  // Toggle Active
  const handleToggleActive = async (contact: EmergencyContactNumber) => {
    const updatedContact = { ...contact, is_active: !contact.is_active };
    try {
      const updated = await saveEmergencyContact(updatedContact);
      setContacts(updated);
      showToast?.(
        `Siaran ${contact.agency_name} sekarang ${
          updatedContact.is_active ? 'AKTIF disiarkan' : 'DINONAKTIFKAN'
        }.`,
        'info'
      );
    } catch {
      showToast?.('Gagal mengubah status siaran.', 'error');
    }
  };

  // Badge Category Helper
  const getCategoryMeta = (cat: EmergencyCategoryType) => {
    switch (cat) {
      case 'SAR & Basarnas':
        return { bg: 'bg-[#F26B4B]/15 text-[#D95637] border-[#F26B4B]/30', icon: LifeBuoy };
      case 'BPBD & Kebencanaan':
        return { bg: 'bg-[#FEF08A] text-[#854D0E] border-[#FDE047]', icon: AlertTriangle };
      case 'Kepolisian':
        return { bg: 'bg-[#DBEAFE] text-[#1D4ED8] border-[#93C5FD]', icon: ShieldCheck };
      case 'Medis & Ambulans':
        return { bg: 'bg-[#DCFCE7] text-[#166534] border-[#86EFAC]', icon: CheckCircle2 };
      case 'Pemadam Kebakaran':
        return { bg: 'bg-[#FEE2E2] text-[#991B1B] border-[#FCA5A5]', icon: Flame };
      case 'Posko Jalur Rawan':
        return { bg: 'bg-[#234B24]/10 text-[#234B24] border-[#234B24]/20', icon: Radio };
      default:
        return { bg: 'bg-gray-100 text-gray-800 border-gray-200', icon: Phone };
    }
  };

  return (
    <div className="space-y-6">
      {/* 4 Kartu KPI Statistik Nomor Darurat */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#4A5248]">Total Nomor Siaga Resmi</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#234B24]">
            {contacts.length} Hotline
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            Terverifikasi Siaga Wisata Sumbar
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#166534]">Layanan Siaga 24 Jam</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#16A34A]">
            {contacts.filter((c) => c.is_24_hours && c.is_active).length} Unit
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            Respon Cepat Tanggap Darurat
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#D95637]">SAR &amp; Medis Kritis</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#F26B4B]">
            {
              contacts.filter(
                (c) => c.category === 'SAR & Basarnas' || c.category === 'Medis & Ambulans'
              ).length
            }{' '}
            Kontak
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Basarnas Padang &amp; RSUP M. Djamil
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#1D4ED8]">Status Siaran ke Aplikasi</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#1D4ED8]">
            {contacts.filter((c) => c.is_active).length} Aktif
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Tampil di Plang QR &amp; HP Wisatawan
          </p>
        </div>
      </div>

      {/* Header Kontrol & Tombol Input Nomor Baru */}
      <div className="bg-white rounded-[24px] p-5 shadow-sm border border-[#E4E9DA] space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <Phone className="w-5 h-5 text-[#234B24]" aria-hidden="true" />
              <span>Direktori Nomor Darurat &amp; Hotline Bencana (Use Case: Input)</span>
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Kelola nomor panggilan darurat instansi berwenang (SAR, BPBD, Kepolisian, Medis, Pemadam, Posko Jalur Rawan) yang disiarkan langsung ke aplikasi dan plang Smart QR wisatawan.
            </p>
          </div>

          <button
            type="button"
            onClick={handleOpenCreate}
            className="min-h-[44px] px-5 py-2.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center justify-center gap-2 shadow-sm transition shrink-0"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
            <span>Input Nomor Darurat Baru</span>
          </button>
        </div>

        {/* Filter Bar */}
        <div className="pt-3 border-t border-[#234B24]/10 flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="relative flex-1">
            <label htmlFor={searchInputId} className="sr-only">
              Cari kontak darurat
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
              placeholder="Cari instansi, nomor telepon, wilayah kab/kota..."
              className="w-full min-h-[40px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
            />
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="min-h-[40px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
            >
              <option value="all">Semua Kategori Instansi</option>
              <option value="SAR & Basarnas">SAR &amp; Basarnas</option>
              <option value="BPBD & Kebencanaan">BPBD &amp; Kebencanaan</option>
              <option value="Kepolisian">Kepolisian</option>
              <option value="Medis & Ambulans">Medis &amp; Ambulans</option>
              <option value="Pemadam Kebakaran">Pemadam Kebakaran</option>
              <option value="Posko Jalur Rawan">Posko Jalur Rawan</option>
            </select>

            <select
              value={regencyFilter}
              onChange={(e) => setRegencyFilter(e.target.value)}
              className="min-h-[40px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
            >
              <option value="all">Semua Wilayah</option>
              {SUMBAR_REGENCIES.slice(1).map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Grid Kartu Nomor Darurat */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filteredContacts.length === 0 ? (
          <div className="col-span-full bg-white rounded-2xl p-8 text-center text-xs text-[#767676] border border-[#E4E9DA]">
            Tidak ada nomor darurat yang sesuai dengan kriteria pencarian.
          </div>
        ) : (
          filteredContacts.map((contact) => {
            const cat = contact.category || contact.agency_type || 'SAR & Basarnas';
            const meta = getCategoryMeta(cat);
            const IconComponent = meta.icon;
            const phone = contact.call_number || contact.phone_number || '';

            return (
              <div
                key={contact.id}
                className={`p-5 rounded-2xl bg-white border-2 transition shadow-sm flex flex-col justify-between space-y-4 ${
                  contact.is_active ? 'border-[#CFD8BE] hover:border-[#234B24]' : 'border-gray-200 opacity-60'
                }`}
              >
                <div>
                  {/* Baris Atas: Badge Kategori & Status Siaran */}
                  <div className="flex items-start justify-between gap-2">
                    <span
                      className={`px-2.5 py-1 rounded-full text-[11px] font-extrabold border flex items-center gap-1.5 ${meta.bg}`}
                    >
                      <IconComponent className="w-3.5 h-3.5" />
                      <span>{cat}</span>
                    </span>

                    <div className="flex items-center gap-1.5">
                      {contact.is_24_hours && (
                        <span className="px-2 py-0.5 rounded-md bg-[#DCFCE7] text-[#166534] text-[10px] font-bold border border-[#86EFAC] flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          <span>24 Jam</span>
                        </span>
                      )}

                      <button
                        type="button"
                        onClick={() => handleToggleActive(contact)}
                        className={`px-2 py-0.5 rounded-md text-[10px] font-bold transition ${
                          contact.is_active
                            ? 'bg-[#1E9E5A]/15 text-[#166534]'
                            : 'bg-gray-100 text-gray-500'
                        }`}
                        title="Klik untuk ubah status siaran"
                      >
                        {contact.is_active ? 'Disiarkan' : 'Nonaktif'}
                      </button>
                    </div>
                  </div>

                  {/* Judul & Nomor Telepon Panggilan */}
                  <div className="mt-3">
                    <h4 className="text-sm font-extrabold text-[#1B1F1A] leading-snug">
                      {contact.agency_name}
                    </h4>

                    <div className="mt-2 flex items-center justify-between p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                      <div className="flex items-center gap-2">
                        <Phone className="w-4 h-4 text-[#F26B4B]" />
                        <span className="font-mono text-base font-extrabold text-[#234B24]">
                          {phone}
                        </span>
                      </div>

                      <a
                        href={phone ? `tel:${phone.replace(/\D/g, '')}` : '#'}
                        className="px-3 py-1 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-white text-[11px] font-bold inline-flex items-center gap-1 shadow-xs transition"
                        title="Uji Panggilan Cepat"
                      >
                        <Phone className="w-3 h-3" />
                        <span>Panggil</span>
                      </a>
                    </div>
                  </div>

                  {/* Alamat & Wilayah */}
                  <div className="mt-2.5 space-y-1 text-xs text-[#4A5248]">
                    <div className="flex items-center gap-1.5 font-bold text-[#1B1F1A]">
                      <MapPin className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" />
                      <span>{contact.city_regency}</span>
                    </div>
                    {contact.address && (
                      <p className="text-[11px] text-[#767676] pl-5 leading-relaxed">
                        {contact.address}
                      </p>
                    )}
                    {contact.description && (
                      <p className="text-[11px] text-[#4A5248] italic pt-1 pl-5">
                        "{contact.description}"
                      </p>
                    )}
                  </div>
                </div>

                {/* Footer Action Buttons */}
                <div className="pt-3 border-t border-[#E4E9DA] flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => handleOpenEdit(contact)}
                    className="px-3 py-1.5 rounded-xl bg-white hover:bg-gray-100 text-[#234B24] border border-[#CFD8BE] text-xs font-bold inline-flex items-center gap-1 transition"
                  >
                    <Edit3 className="w-3.5 h-3.5" />
                    <span>Ubah</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => handleDeleteContact(contact)}
                    className="px-3 py-1.5 rounded-xl bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637] text-xs font-bold inline-flex items-center gap-1 transition"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Hapus</span>
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Modal Input / Edit Nomor Darurat */}
      {isModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 shadow-2xl border border-[#E4E9DA] max-h-[92vh] overflow-y-auto space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center">
                  <Phone className="w-5 h-5 text-[#F26B4B]" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {editingContact ? 'Ubah Nomor Darurat' : 'Input Nomor Darurat Baru'}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Standar Dispar &amp; Satgas Siaga SAR Sumbar
                  </p>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveContact} className="space-y-3.5 text-xs">
              <div>
                <label className="block font-bold text-[#1B1F1A] mb-1">
                  Nama Instansi / Posko Layanan *
                </label>
                <input
                  type="text"
                  required
                  value={formAgencyName}
                  onChange={(e) => setFormAgencyName(e.target.value)}
                  placeholder="misal: Kantor SAR Kelas A Padang (Basarnas)"
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-semibold text-[#1B1F1A]"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Nomor Panggilan / Hotline *
                  </label>
                  <input
                    type="text"
                    required
                    value={formCallNumber}
                    onChange={(e) => setFormCallNumber(e.target.value)}
                    placeholder="misal: 115 atau (0751) 484555"
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono font-bold text-xs text-[#234B24]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Kategori Instansi *
                  </label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value as EmergencyCategoryType)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    <option value="SAR & Basarnas">SAR &amp; Basarnas</option>
                    <option value="BPBD & Kebencanaan">BPBD &amp; Kebencanaan</option>
                    <option value="Kepolisian">Kepolisian</option>
                    <option value="Medis & Ambulans">Medis &amp; Ambulans</option>
                    <option value="Pemadam Kebakaran">Pemadam Kebakaran</option>
                    <option value="Posko Jalur Rawan">Posko Jalur Rawan</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block font-bold text-[#1B1F1A] mb-1">
                  Cakupan Wilayah Kab/Kota *
                </label>
                <select
                  value={formRegency}
                  onChange={(e) => setFormRegency(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="Provinsi Sumatera Barat">Provinsi Sumatera Barat (Seluruh Wilayah)</option>
                  {SUMBAR_REGENCIES.slice(1).map((r) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-[#1B1F1A] mb-1">
                  Alamat Kantor / Pos Pantau Fisik
                </label>
                <input
                  type="text"
                  value={formAddress}
                  onChange={(e) => setFormAddress(e.target.value)}
                  placeholder="misal: Jl. By Pass KM 25, Koto Tangah, Kota Padang"
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A]"
                />
              </div>

              <div>
                <label className="block font-bold text-[#1B1F1A] mb-1">
                  Catatan Operasional &amp; Petunjuk
                </label>
                <textarea
                  rows={2}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  placeholder="misal: Siaga derek darurat dan penanganan rem blong jalur Sitinjau Lauik."
                  className="w-full px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A]"
                />
              </div>

              <div className="flex items-center gap-6 pt-1">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formIs24Hours}
                    onChange={(e) => setFormIs24Hours(e.target.checked)}
                    className="rounded text-[#234B24] focus:ring-[#234B24] w-4 h-4"
                  />
                  <span className="font-bold text-[#1B1F1A]">Siaga 24 Jam Nonstop</span>
                </label>

                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formIsActive}
                    onChange={(e) => setFormIsActive(e.target.checked)}
                    className="rounded text-[#234B24] focus:ring-[#234B24] w-4 h-4"
                  />
                  <span className="font-bold text-[#1B1F1A]">Aktifkan Siaran ke Wisatawan</span>
                </label>
              </div>

              <div className="pt-3 border-t border-[#E4E9DA] flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5 shadow-sm"
                >
                  <Save className="w-4 h-4" />
                  <span>Simpan Nomor Darurat</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
