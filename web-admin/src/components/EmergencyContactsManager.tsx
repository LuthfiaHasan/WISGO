import React, { useId, useState } from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  Clock,
  Edit3,
  Flame,
  LifeBuoy,
  MapPin,
  Phone,
  Plus,
  Search,
  ShieldCheck,
  Trash2,
  X,
} from 'lucide-react';
import { EmergencyAgencyType, EmergencyContact } from '../types/contract';
import { EMERGENCY_AGENCY_TYPES, SUMBAR_REGENCIES } from '../data/mockDestinations';
import { EmergencyContactsRepo } from '../services/dbRepository';

interface EmergencyContactsManagerProps {
  showToast?: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const EmergencyContactsManager: React.FC<EmergencyContactsManagerProps> = ({
  showToast,
}) => {
  const [contacts, setContacts] = useState<EmergencyContact[]>(() =>
    EmergencyContactsRepo.getAll()
  );
  const [searchQuery, setSearchQuery] = useState('');
  const [agencyFilter, setAgencyFilter] = useState<string>('all');
  const [regencyFilter, setRegencyFilter] = useState<string>('all');

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<EmergencyContact | null>(null);
  const [formAgencyName, setFormAgencyName] = useState('');
  const [formAgencyType, setFormAgencyType] = useState<EmergencyAgencyType>('BPBD');
  const [formPhone, setFormPhone] = useState('');
  const [formWhatsapp, setFormWhatsapp] = useState('');
  const [formRegency, setFormRegency] = useState('Provinsi Sumatera Barat');
  const [formAddress, setFormAddress] = useState('');
  const [formDescription, setFormDescription] = useState('');
  const [formIs24Hours, setFormIs24Hours] = useState(true);
  const [formIsActive, setFormIsActive] = useState(true);

  const searchInputId = useId();

  const filteredContacts = contacts.filter((c) => {
    const q = searchQuery.trim().toLowerCase();
    const matchesSearch =
      !q ||
      c.agency_name.toLowerCase().includes(q) ||
      c.phone_number.toLowerCase().includes(q) ||
      c.city_regency.toLowerCase().includes(q) ||
      (c.description || '').toLowerCase().includes(q);
    const matchesType = agencyFilter === 'all' || c.agency_type === agencyFilter;
    const matchesReg =
      regencyFilter === 'all' || c.city_regency.toLowerCase().includes(regencyFilter.toLowerCase());
    return matchesSearch && matchesType && matchesReg;
  });

  const handleOpenCreate = () => {
    setEditingContact(null);
    setFormAgencyName('');
    setFormAgencyType('BPBD');
    setFormPhone('');
    setFormWhatsapp('');
    setFormRegency('Provinsi Sumatera Barat');
    setFormAddress('');
    setFormDescription('');
    setFormIs24Hours(true);
    setFormIsActive(true);
    setIsModalOpen(true);
  };

  const handleOpenEdit = (contact: EmergencyContact) => {
    setEditingContact(contact);
    setFormAgencyName(contact.agency_name);
    setFormAgencyType(contact.agency_type);
    setFormPhone(contact.phone_number);
    setFormWhatsapp(contact.whatsapp_number || '');
    setFormRegency(contact.city_regency);
    setFormAddress(contact.address || '');
    setFormDescription(contact.description || '');
    setFormIs24Hours(contact.is_24_hours);
    setFormIsActive(contact.is_active);
    setIsModalOpen(true);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formAgencyName.trim() || !formPhone.trim()) {
      showToast?.('Nama instansi dan nomor darurat wajib diisi.', 'warning');
      return;
    }

    const updated = EmergencyContactsRepo.save({
      id: editingContact ? editingContact.id : `emg-${Date.now().toString(36)}`,
      agency_name: formAgencyName.trim(),
      agency_type: formAgencyType,
      phone_number: formPhone.trim(),
      whatsapp_number: formWhatsapp.trim() || null,
      city_regency: formRegency,
      address: formAddress.trim() || undefined,
      description: formDescription.trim() || undefined,
      is_24_hours: formIs24Hours,
      is_active: formIsActive,
      latitude: editingContact?.latitude ?? -0.9471,
      longitude: editingContact?.longitude ?? 100.3543,
      created_by_admin_id: 'usr-admin-01',
    });
    setContacts(updated);
    setIsModalOpen(false);
    showToast?.(
      editingContact ? 'Kontak darurat diperbarui.' : 'Kontak darurat baru ditambahkan.',
      'success'
    );
  };

  const handleDelete = (contact: EmergencyContact) => {
    if (!window.confirm(`Hapus kontak darurat "${contact.agency_name}"?`)) return;
    setContacts(EmergencyContactsRepo.delete(contact.id));
    showToast?.(`Kontak "${contact.agency_name}" dihapus.`, 'info');
  };

  const handleToggleActive = (contact: EmergencyContact) => {
    const updated = EmergencyContactsRepo.save({ ...contact, is_active: !contact.is_active });
    setContacts(updated);
    showToast?.(
      `Siaran ${contact.agency_name} ${!contact.is_active ? 'diaktifkan' : 'dinonaktifkan'}.`,
      'info'
    );
  };

  const getAgencyMeta = (type: EmergencyAgencyType) => {
    switch (type) {
      case 'BPBD':
        return { bg: 'bg-amber-100 text-amber-900 border-amber-300', icon: AlertTriangle };
      case 'PMI':
      case 'Medis':
        return { bg: 'bg-emerald-100 text-emerald-900 border-emerald-300', icon: CheckCircle2 };
      case 'Damkar':
        return { bg: 'bg-red-100 text-red-900 border-red-300', icon: Flame };
      case 'Kepolisian':
        return { bg: 'bg-blue-100 text-blue-900 border-blue-300', icon: ShieldCheck };
      case 'Basarnas':
      default:
        return { bg: 'bg-[#F26B4B]/15 text-[#D95637] border-[#F26B4B]/40', icon: LifeBuoy };
    }
  };

  return (
    <div className="space-y-5">
      <div className="bg-white rounded-2xl p-5 border border-[#234B24]/10 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <Phone className="w-5 h-5 text-[#234B24]" />
              <span>Direktori Kontak Darurat Resmi Sumbar ({contacts.length} Instansi Real)</span>
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Sinkron migrasi database 000004 — tampil pada halaman SOS aplikasi mobile dan Plang Smart QR.
            </p>
          </div>

          <button
            type="button"
            onClick={handleOpenCreate}
            className="min-h-[42px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 shrink-0"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Tambah Kontak Darurat</span>
          </button>
        </div>

        <div className="pt-3 border-t border-[#234B24]/10 flex flex-col md:flex-row gap-3">
          <div className="relative flex-1">
            <label htmlFor={searchInputId} className="sr-only">
              Cari kontak darurat
            </label>
            <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
            <input
              id={searchInputId}
              type="search"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Cari BPBD, PMI, Damkar, nomor telepon, atau wilayah..."
              className="w-full min-h-[40px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
            />
          </div>
          <select
            value={agencyFilter}
            onChange={(e) => setAgencyFilter(e.target.value)}
            className="min-h-[40px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
          >
            <option value="all">Semua Instansi</option>
            {EMERGENCY_AGENCY_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
          <select
            value={regencyFilter}
            onChange={(e) => setRegencyFilter(e.target.value)}
            className="min-h-[40px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
          >
            <option value="all">Semua Wilayah</option>
            <option value="Provinsi Sumatera Barat">Provinsi Sumatera Barat</option>
            {SUMBAR_REGENCIES.slice(1).map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredContacts.map((contact) => {
          const meta = getAgencyMeta(contact.agency_type);
          const IconComp = meta.icon;
          const cleanTel = contact.phone_number.replace(/[^\d+]/g, '');

          return (
            <div
              key={contact.id}
              className={`p-5 rounded-2xl bg-white border-2 transition flex flex-col justify-between space-y-3 ${contact.is_active ? 'border-[#CFD8BE] hover:border-[#234B24]' : 'border-gray-200 opacity-60'
                }`}
            >
              <div>
                <div className="flex items-center justify-between gap-2">
                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold border inline-flex items-center gap-1 ${meta.bg}`}
                  >
                    <IconComp className="w-3 h-3" /> {contact.agency_type}
                  </span>
                  <div className="flex items-center gap-1.5">
                    {contact.is_24_hours && (
                      <span className="px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-800 text-[10px] font-bold inline-flex items-center gap-1">
                        <Clock className="w-3 h-3" /> 24 Jam
                      </span>
                    )}
                    <button
                      type="button"
                      onClick={() => handleToggleActive(contact)}
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${contact.is_active ? 'bg-[#1E9E5A]/15 text-[#166534]' : 'bg-gray-100 text-gray-500'
                        }`}
                    >
                      {contact.is_active ? 'Aktif' : 'Nonaktif'}
                    </button>
                  </div>
                </div>

                <h4 className="text-sm font-extrabold text-[#1B1F1A] mt-2.5">
                  {contact.agency_name}
                </h4>

                <div className="mt-2 flex items-center justify-between p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                  <span className="font-mono text-sm font-extrabold text-[#234B24]">
                    {contact.phone_number}
                  </span>
                  <a
                    href={`tel:${cleanTel}`}
                    className="px-2.5 py-1 rounded-lg bg-[#234B24] text-white text-[11px] font-bold inline-flex items-center gap-1"
                  >
                    <Phone className="w-3 h-3" /> Panggil
                  </a>
                </div>

                <div className="mt-2 text-xs text-[#4A5248] space-y-1">
                  <div className="flex items-center gap-1 font-bold text-[#1B1F1A]">
                    <MapPin className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" />
                    <span>{contact.city_regency}</span>
                  </div>
                  {contact.address && <p className="text-[11px] text-[#767676]">{contact.address}</p>}
                  {contact.description && (
                    <p className="text-[11px] italic text-[#4A5248]">{contact.description}</p>
                  )}
                </div>
              </div>

              <div className="pt-2.5 border-t border-[#E4E9DA] flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => handleOpenEdit(contact)}
                  className="px-3 py-1.5 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold text-[#234B24] inline-flex items-center gap-1"
                >
                  <Edit3 className="w-3.5 h-3.5" /> Ubah
                </button>
                <button
                  type="button"
                  onClick={() => handleDelete(contact)}
                  className="px-3 py-1.5 rounded-xl bg-[#F26B4B]/15 text-[#D95637] text-xs font-bold inline-flex items-center gap-1"
                >
                  <Trash2 className="w-3.5 h-3.5" /> Hapus
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {isModalOpen && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <form onSubmit={handleSave} className="bg-white rounded-[28px] w-full max-w-lg p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between pb-3 border-b">
              <h3 className="text-base font-extrabold">
                {editingContact ? 'Ubah Kontak Darurat' : 'Tambah Kontak Darurat Resmi'}
              </h3>
              <button type="button" onClick={() => setIsModalOpen(false)}>
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-bold mb-1">Nama Instansi / Posko *</label>
                <input
                  type="text"
                  required
                  value={formAgencyName}
                  onChange={(e) => setFormAgencyName(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-semibold"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold mb-1">Nomor Telepon *</label>
                  <input
                    type="text"
                    required
                    value={formPhone}
                    onChange={(e) => setFormPhone(e.target.value)}
                    placeholder="(0751) 890721"
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono font-bold"
                  />
                </div>
                <div>
                  <label className="block font-bold mb-1">Jenis Instansi *</label>
                  <select
                    value={formAgencyType}
                    onChange={(e) => setFormAgencyType(e.target.value as EmergencyAgencyType)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-bold"
                  >
                    {EMERGENCY_AGENCY_TYPES.map((t) => (
                      <option key={t} value={t}>
                        {t}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold mb-1">WhatsApp (Opsional)</label>
                  <input
                    type="text"
                    value={formWhatsapp}
                    onChange={(e) => setFormWhatsapp(e.target.value)}
                    placeholder="628116606113"
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono"
                  />
                </div>
                <div>
                  <label className="block font-bold mb-1">Wilayah *</label>
                  <select
                    value={formRegency}
                    onChange={(e) => setFormRegency(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-bold"
                  >
                    <option value="Provinsi Sumatera Barat">Provinsi Sumatera Barat</option>
                    {SUMBAR_REGENCIES.slice(1).map((r) => (
                      <option key={r} value={r}>
                        {r}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div>
                <label className="block font-bold mb-1">Alamat Posko</label>
                <input
                  type="text"
                  value={formAddress}
                  onChange={(e) => setFormAddress(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
              <div>
                <label className="block font-bold mb-1">Deskripsi Layanan</label>
                <textarea
                  rows={2}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
              <div className="flex items-center gap-5">
                <label className="flex items-center gap-2 font-bold cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formIs24Hours}
                    onChange={(e) => setFormIs24Hours(e.target.checked)}
                  />
                  <span>Siaga 24 Jam</span>
                </label>
                <label className="flex items-center gap-2 font-bold cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formIsActive}
                    onChange={(e) => setFormIsActive(e.target.checked)}
                  />
                  <span>Aktif Disiarkan</span>
                </label>
              </div>
            </div>
            <div className="flex justify-end gap-2 pt-3 border-t">
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan Kontak
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
