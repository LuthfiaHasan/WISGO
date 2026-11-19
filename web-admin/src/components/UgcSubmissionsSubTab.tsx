import React, { useState, useEffect } from 'react';
import {
  Inbox,
  CheckCircle2,
  XCircle,
  Clock,
  Eye,
  Search,
  Plus,
  Filter,
  MapPin,
  Phone,
  User,
  Sparkles,
  AlertCircle,
  X,
  Check,
  Calendar,
  Image as ImageIcon,
} from 'lucide-react';
import {
  TouristDestinationSubmission,
  UGCSubmissionStatus,
  Destination,
  MedanIndicator,
} from '../types/contract';
import { SUMBAR_REGENCIES, DESTINATION_CATEGORIES } from '../data/mockDestinations';
import { ImageDropzone } from './ImageDropzone';

interface UgcSubmissionsSubTabProps {
  destinations: Destination[];
  onSaveDestination: (dest: Destination, toastMessage: string) => Promise<void> | void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const STORAGE_KEY_UGC = 'wisgo_tourist_ugc_submissions';

// Seed Initial UGC Submissions
const INITIAL_UGC_SUBMISSIONS: TouristDestinationSubmission[] = [
  {
    id: 'ugc-01',
    title: 'Air Terjun Sarasah Barasok',
    submitter_name: 'Ilham Fathoni',
    submitter_phone: '081266554433',
    city_regency: 'Kabupaten Lima Puluh Kota',
    category: 'Alam & Ekowisata',
    description:
      'Air terjun tersembunyi dengan semburan uap air menyerupai asap putih alami di balik tebing Harau. Sangat indah untuk trekking pagi hari, airnya jernih dan segar.',
    photo_url: 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&w=1200&q=80',
    estimated_price: 'Rp 10.000 / orang',
    status: 'MENUNGGU',
    submitted_at: '2026-11-16T15:30:00Z',
    admin_notes: 'Menunggu verifikasi lapangan oleh Pokdarwis setempat.',
  },
  {
    id: 'ugc-02',
    title: 'Bukit Nobita Teluk Bayur',
    submitter_name: 'Dinda Maharani',
    submitter_phone: '085277112233',
    city_regency: 'Kota Padang',
    category: 'Bukit & Pemandangan',
    description:
      'Spot sunset menghadap ke Pelabuhan Teluk Bayur dan Samudra Hindia. Terdapat monumen baling-baling bambu dan jalur trekking ringan 15 menit dari parkiran.',
    photo_url: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    estimated_price: 'Rp 5.000 (Parkir Motor)',
    status: 'MENUNGGU',
    submitted_at: '2026-11-15T09:40:00Z',
  },
  {
    id: 'ugc-03',
    title: 'Danau Bontak & Geotermal Sangir',
    submitter_name: 'Hendri Kurniawan',
    submitter_phone: '082188990011',
    city_regency: 'Kabupaten Solok Selatan',
    category: 'Danau & Agrowisata',
    description:
      'Danau kawah vulkanik alami di kaki Gunung Kerinci dengan pemandangan sumber air panas geotermal dan hamparan kebun teh Liki.',
    photo_url: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=1200&q=80',
    estimated_price: 'Rp 15.000 / orang',
    status: 'DISETUJUI',
    submitted_at: '2026-11-10T11:20:00Z',
    admin_notes: 'Telah disetujui & dimasukkan ke inventaris resmi Dispar Sumbar.',
  },
  {
    id: 'ugc-04',
    title: 'Pantai Pasir Putih Karang Tirta',
    submitter_name: 'Rudi Pratama',
    submitter_phone: '081399887766',
    city_regency: 'Kabupaten Pesisir Selatan',
    category: 'Bahari & Kepulauan',
    description:
      'Garis pantai pasir putih alami dengan gugusan terumbu karang dangkal yang cocok untuk snorkeling mandiri dan perahu kano.',
    photo_url: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
    estimated_price: 'Rp 10.000 / orang',
    status: 'MENUNGGU',
    submitted_at: '2026-11-14T14:10:00Z',
  },
];

export const UgcSubmissionsSubTab: React.FC<UgcSubmissionsSubTabProps> = ({
  destinations,
  onSaveDestination,
  showToast,
}) => {
  const [submissions, setSubmissions] = useState<TouristDestinationSubmission[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY_UGC);
      return saved ? JSON.parse(saved) : INITIAL_UGC_SUBMISSIONS;
    } catch {
      return INITIAL_UGC_SUBMISSIONS;
    }
  });

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY_UGC, JSON.stringify(submissions));
    } catch (e) {
      console.warn('Gagal menyimpan usulan UGC ke localStorage:', e);
    }
  }, [submissions]);

  // Search & Filter
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | UGCSubmissionStatus>('ALL');
  const [regencyFilter, setRegencyFilter] = useState('Semua Kab/Kota');

  // Modal Detail / Verifikasi
  const [selectedSubmission, setSelectedSubmission] = useState<TouristDestinationSubmission | null>(null);

  // Modal Form Simulasi Usulan Wisatawan Baru
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [formTitle, setFormTitle] = useState('');
  const [formSubmitterName, setFormSubmitterName] = useState('');
  const [formSubmitterPhone, setFormSubmitterPhone] = useState('');
  const [formRegency, setFormRegency] = useState('Kabupaten Lima Puluh Kota');
  const [formCategory, setFormCategory] = useState('Alam & Ekowisata');
  const [formDescription, setFormDescription] = useState('');
  const [formPhotoUrl, setFormPhotoUrl] = useState('');
  const [formPrice, setFormPrice] = useState('Rp 10.000 / orang');

  // Setujui Usulan (Approve) -> Tambah ke Direktori Utama Destinasi
  const handleApproveSubmission = async (sub: TouristDestinationSubmission) => {
    const subTitle = sub.title || sub.name || 'Destinasi Wisata';
    const slugName = subTitle
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)+/g, '');

    const defaultMedan: MedanIndicator = {
      id: `medan-${Date.now().toString(36)}`,
      destination_id: `dest-ugc-${Date.now().toString(36)}`,
      vehicle_access: 'Mobil OK',
      trekking_level: 'Mudah',
      cellular_signal: '4G Lancar',
      facilities: 'Ada Toilet & Musala',
      guide_need: 'Bisa Mandiri',
      vehicle_score: 5,
      trekking_score: 4,
      signal_score: 4,
      facilities_score: 3,
      guide_score: 4,
      readiness_notes: `Usulan dari wisatawan (${sub.submitter_name || 'Wisatawan'}). Diverifikasi oleh Admin Dispar Sumbar.`,
    };

    const newDest: Destination = {
      id: defaultMedan.destination_id,
      slug: slugName,
      name: subTitle.trim(),
      city_regency: sub.city_regency,
      category: sub.category,
      description: sub.description || '',
      cover_image: sub.photo_url || 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&w=1200&q=80',
      crowd_level: 'Sedang',
      latitude: -0.22,
      longitude: 100.63,
      estimated_distance_km: 75,
      estimated_duration_min: 90,
      ticket_price_summary: (sub as any).estimated_price || 'Rp 10.000',
      is_blank_spot: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      medan_indicator: defaultMedan,
      tips: [
        {
          id: `tip-1-${Date.now().toString(36)}`,
          destination_id: defaultMedan.destination_id,
          content: 'Jaga kebersihan lingkungan dengan membawa pulang kembali sampah plastik Anda.',
          is_important: true,
        },
        {
          id: `tip-2-${Date.now().toString(36)}`,
          destination_id: defaultMedan.destination_id,
          content: 'Hormati norma adat nagari setempat dan berpakaianlah secara sopan santun.',
          is_important: false,
        },
      ],
      tariffs: [
        {
          id: `trf-${Date.now().toString(36)}`,
          destination_id: defaultMedan.destination_id,
          category: 'Tiket Masuk',
          item_name: 'Retribusi Masuk Kawasan Wisata',
          price: 10000,
          unit: 'per orang',
          regulation_ref: 'Perda Retribusi Wisata Sumbar',
        },
      ],
    };

    // 1. Simpan ke direktori utama
    await onSaveDestination(
      newDest,
      `Destinasi "${sub.title}" berhasil disetujui & otomatis masuk ke Direktori Utama WISGO!`
    );

    // 2. Perbarui status UGC
    const updated = submissions.map((s) =>
      s.id === sub.id
        ? {
            ...s,
            status: 'DISETUJUI' as UGCSubmissionStatus,
            admin_notes: 'Disetujui oleh Admin Dispar dan masuk ke direktori resmi.',
          }
        : s
    );
    setSubmissions(updated);
    setSelectedSubmission(null);
    showToast(
      `Usulan destinasi "${sub.title}" telah disetujui dan ditambahkan ke daftar 20 destinasi.`,
      'success'
    );
  };

  // Tolak Usulan (Reject)
  const handleRejectSubmission = (sub: TouristDestinationSubmission) => {
    const updated = submissions.map((s) =>
      s.id === sub.id
        ? {
            ...s,
            status: 'DITOLAK' as UGCSubmissionStatus,
            admin_notes: 'Belum memenuhi kriteria kelayakan destinasi wisata aman & tertib.',
          }
        : s
    );
    setSubmissions(updated);
    setSelectedSubmission(null);
    showToast(`Usulan destinasi "${sub.title}" ditolak.`, 'info');
  };

  // Hapus Usulan
  const handleDeleteSubmission = (id: string) => {
    if (!window.confirm('Hapus usulan destinasi ini dari daftar?')) return;
    setSubmissions(submissions.filter((s) => s.id !== id));
    showToast('Usulan destinasi berhasil dihapus.', 'info');
  };

  // Simpan Form Usulan Baru (Simulasi Wisatawan)
  const handleSaveNewUGC = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim() || !formSubmitterName.trim()) {
      showToast('Nama destinasi dan nama pengusul wajib diisi.', 'warning');
      return;
    }

    const newSub: TouristDestinationSubmission = {
      id: `ugc-${Date.now().toString(36)}`,
      title: formTitle.trim(),
      submitter_name: formSubmitterName.trim(),
      submitter_phone: formSubmitterPhone.trim() || '081234567890',
      city_regency: formRegency,
      category: formCategory,
      description: formDescription.trim(),
      photo_url:
        formPhotoUrl ||
        'https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&w=1200&q=80',
      estimated_price: formPrice.trim() || 'Gratis',
      status: 'MENUNGGU',
      submitted_at: new Date().toISOString(),
      admin_notes: 'Menunggu kurasi admin.',
    };

    setSubmissions([newSub, ...submissions]);
    setIsAddModalOpen(false);
    showToast(
      `Usulan destinasi "${newSub.title}" dari wisatawan berhasil didaftarkan ke sistem!`,
      'success'
    );
  };

  // Filtered Submissions
  const filtered = submissions.filter((sub) => {
    const sTitle = sub.title || sub.name || '';
    const sName = sub.submitter_name || '';
    const sDesc = sub.description || '';
    const matchesSearch =
      sTitle.toLowerCase().includes(searchTerm.toLowerCase()) ||
      sName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      sDesc.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus =
      statusFilter === 'ALL' || sub.status === statusFilter;

    const matchesRegency =
      regencyFilter === 'Semua Kab/Kota' || sub.city_regency === regencyFilter;

    return matchesSearch && matchesStatus && matchesRegency;
  });

  const waitingCount = submissions.filter((s) => s.status === 'MENUNGGU').length;
  const approvedCount = submissions.filter((s) => s.status === 'DISETUJUI').length;
  const rejectedCount = submissions.filter((s) => s.status === 'DITOLAK').length;

  return (
    <div className="space-y-6">
      {/* 3 Kartu Status Usulan */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-4 rounded-2xl bg-[#FFEDD5]/60 border border-[#FDBA74] flex items-center justify-between">
          <div>
            <span className="text-[11px] font-extrabold text-[#C2410C] uppercase tracking-wider">
              Menunggu Kurasi Admin
            </span>
            <div className="text-2xl font-black text-[#C2410C] mt-1">
              {waitingCount} Usulan
            </div>
            <p className="text-[11px] text-[#9A3412] mt-0.5">
              Perlu verifikasi foto &amp; indikator medan
            </p>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shadow-xs">
            <Clock className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-[#CCFBF1]/60 border border-[#99F6E4] flex items-center justify-between">
          <div>
            <span className="text-[11px] font-extrabold text-[#0D9488] uppercase tracking-wider">
              Disetujui &amp; Terbit
            </span>
            <div className="text-2xl font-black text-[#0D9488] mt-1">
              {approvedCount} Destinasi
            </div>
            <p className="text-[11px] text-[#0F766E] mt-0.5">
              Telah masuk ke direktori utama WISGO
            </p>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#0D9488] text-white flex items-center justify-center shadow-xs">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white border border-[#E4E9DA] flex items-center justify-between">
          <div>
            <span className="text-[11px] font-extrabold text-[#767676] uppercase tracking-wider">
              Ditolak / Belum Layak
            </span>
            <div className="text-2xl font-black text-[#1B1F1A] mt-1">
              {rejectedCount} Usulan
            </div>
            <p className="text-[11px] text-[#4A5248] mt-0.5">
              Belum memenuhi SOP keselamatan &amp; perda
            </p>
          </div>
          <div className="w-10 h-10 rounded-xl bg-gray-200 text-[#4A5248] flex items-center justify-center">
            <XCircle className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Filter & Action Bar */}
      <div className="bg-white rounded-2xl p-4 border border-[#E4E9DA] flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex items-center gap-2 flex-wrap flex-1">
          <div className="relative min-w-[240px] flex-1 max-w-sm">
            <Search className="w-3.5 h-3.5 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Cari tempat atau nama pengusul..."
              className="w-full min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as any)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="ALL">Semua Status</option>
            <option value="MENUNGGU">Menunggu Kurasi ({waitingCount})</option>
            <option value="DISETUJUI">Disetujui ({approvedCount})</option>
            <option value="DITOLAK">Ditolak ({rejectedCount})</option>
          </select>

          <select
            value={regencyFilter}
            onChange={(e) => setRegencyFilter(e.target.value)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="Semua Kab/Kota">Semua Kab/Kota</option>
            {SUMBAR_REGENCIES.map((reg) => (
              <option key={reg} value={reg}>
                {reg}
              </option>
            ))}
          </select>
        </div>

        <button
          type="button"
          onClick={() => {
            setFormTitle('');
            setFormSubmitterName('');
            setFormSubmitterPhone('');
            setFormRegency('Kabupaten Lima Puluh Kota');
            setFormCategory('Alam & Ekowisata');
            setFormDescription('');
            setFormPhotoUrl('');
            setFormPrice('Rp 10.000 / orang');
            setIsAddModalOpen(true);
          }}
          className="min-h-[40px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
        >
          <Plus className="w-3.5 h-3.5" />
          <span>Simulasi Usulan Wisatawan</span>
        </button>
      </div>

      {/* Tabel Usulan Destinasi (UGC) */}
      <div className="bg-white rounded-2xl border border-[#E4E9DA] overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F6F3EC] text-[#234B24] font-extrabold uppercase text-[10px] tracking-wider border-b border-[#CFD8BE]">
              <tr>
                <th className="py-3.5 px-4">Foto &amp; Nama Destinasi</th>
                <th className="py-3.5 px-4">Wilayah &amp; Kategori</th>
                <th className="py-3.5 px-4">Pengusul (Wisatawan)</th>
                <th className="py-3.5 px-4">Estimasi Tarif</th>
                <th className="py-3.5 px-4">Status Kurasi</th>
                <th className="py-3.5 px-4 text-right">Tindakan Admin</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA]">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-10 text-center text-[#767676]">
                    Tidak ada usulan destinasi wisatawan yang sesuai filter.
                  </td>
                </tr>
              ) : (
                filtered.map((sub) => (
                  <tr key={sub.id} className="hover:bg-[#F6F3EC]/40 transition">
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-14 h-11 rounded-lg overflow-hidden bg-gray-100 shrink-0 border border-black/5">
                          {sub.photo_url ? (
                            <img
                              src={sub.photo_url}
                              alt={sub.title}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-gray-400">
                              <ImageIcon className="w-4 h-4" />
                            </div>
                          )}
                        </div>
                        <div>
                          <div className="font-extrabold text-[#1B1F1A] text-xs">
                            {sub.title}
                          </div>
                          <div className="text-[11px] text-[#4A5248] line-clamp-1 max-w-xs mt-0.5">
                            {sub.description}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-[#1B1F1A]">{sub.city_regency}</div>
                      <div className="text-[10px] text-[#234B24] font-bold mt-0.5">
                        {sub.category}
                      </div>
                    </td>

                    <td className="py-3.5 px-4">
                      <div className="font-bold text-[#1B1F1A]">{sub.submitter_name}</div>
                      <div className="text-[10px] font-mono text-[#767676]">
                        {sub.submitter_phone}
                      </div>
                    </td>

                    <td className="py-3.5 px-4 font-mono font-bold text-[#234B24]">
                      {sub.estimated_price}
                    </td>

                    <td className="py-3.5 px-4">
                      {sub.status === 'MENUNGGU' && (
                        <span className="px-2.5 py-1 rounded-full text-[10px] font-extrabold bg-[#FFEDD5] text-[#C2410C] inline-flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          Menunggu Kurasi
                        </span>
                      )}
                      {sub.status === 'DISETUJUI' && (
                        <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-[#CCFBF1] text-[#0D9488] inline-flex items-center gap-1">
                          <CheckCircle2 className="w-3 h-3" />
                          Disetujui
                        </span>
                      )}
                      {sub.status === 'DITOLAK' && (
                        <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-red-100 text-red-600 inline-flex items-center gap-1">
                          <XCircle className="w-3 h-3" />
                          Ditolak
                        </span>
                      )}
                    </td>

                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        {sub.status === 'MENUNGGU' ? (
                          <>
                            <button
                              type="button"
                              onClick={() => handleApproveSubmission(sub)}
                              title="Setujui dan masukkan ke direktori resmi"
                              className="px-3 py-1.5 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold text-[11px] inline-flex items-center gap-1 shadow-xs transition"
                            >
                              <Check className="w-3.5 h-3.5" />
                              <span>Setujui</span>
                            </button>
                            <button
                              type="button"
                              onClick={() => handleRejectSubmission(sub)}
                              title="Tolak usulan ini"
                              className="px-2.5 py-1.5 rounded-lg bg-red-100 hover:bg-red-200 text-red-700 font-bold text-[11px] inline-flex items-center gap-1 transition"
                            >
                              <X className="w-3.5 h-3.5" />
                              <span>Tolak</span>
                            </button>
                          </>
                        ) : sub.status === 'DISETUJUI' ? (
                          <span className="text-[11px] text-[#0D9488] font-bold flex items-center justify-end gap-1">
                            <CheckCircle2 className="w-3.5 h-3.5" />
                            <span>Sudah di Direktori</span>
                          </span>
                        ) : (
                          <button
                            type="button"
                            onClick={() => handleApproveSubmission(sub)}
                            className="px-2.5 py-1 rounded-lg text-[10px] font-bold text-[#234B24] hover:bg-[#234B24]/10 border border-[#234B24]/20"
                          >
                            Tinjau Ulang &amp; Setujui
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() => handleDeleteSubmission(sub.id)}
                          className="p-1.5 rounded-lg text-[#767676] hover:text-red-600 hover:bg-red-50"
                          title="Hapus Usulan"
                        >
                          <X className="w-3.5 h-3.5" />
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

      {/* Modal Simulasi Usulan Wisatawan Baru */}
      {isAddModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[92vh] flex flex-col overflow-hidden">
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA] shrink-0">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-xs">
                  <Inbox className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    Simulasi Usulan Destinasi Wisatawan
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    UGC (User Generated Content) WISGO
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsAddModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveNewUGC} className="mt-4 space-y-4 overflow-y-auto pr-1">
              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Nama Tempat Wisata yang Diusulkan <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  type="text"
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  placeholder="Contoh: Air Terjun Sarasah Barasok"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Nama Wisatawan Pengusul <span className="text-[#F26B4B]">*</span>
                  </label>
                  <input
                    type="text"
                    value={formSubmitterName}
                    onChange={(e) => setFormSubmitterName(e.target.value)}
                    placeholder="Contoh: Ilham Fathoni"
                    required
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Nomor WhatsApp
                  </label>
                  <input
                    type="tel"
                    value={formSubmitterPhone}
                    onChange={(e) => setFormSubmitterPhone(e.target.value)}
                    placeholder="08123456789"
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-medium text-[#1B1F1A]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Kabupaten / Kota
                  </label>
                  <select
                    value={formRegency}
                    onChange={(e) => setFormRegency(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    {SUMBAR_REGENCIES.map((reg) => (
                      <option key={reg} value={reg}>
                        {reg}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Kategori Medan
                  </label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    {DESTINATION_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Deskripsi Keindahan &amp; Kondisi Lapangan
                </label>
                <textarea
                  rows={2}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  placeholder="Ceritakan pesona tempat, akses jalan, dan keunikan alamnya..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div>
                <ImageDropzone
                  label="Foto Objek Wisata (Upload dari Device)"
                  value={formPhotoUrl}
                  onChange={(dataUrl) => setFormPhotoUrl(dataUrl)}
                  onClear={() => setFormPhotoUrl('')}
                  helperText="Pilih foto dokumentasi dari komputer untuk bukti visual tempat wisata."
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Estimasi Biaya Masuk / Parkir
                </label>
                <input
                  type="text"
                  value={formPrice}
                  onChange={(e) => setFormPrice(e.target.value)}
                  placeholder="Contoh: Rp 10.000 / orang"
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div className="pt-3 flex items-center justify-end gap-2.5 border-t border-[#E4E9DA] shrink-0">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm"
                >
                  <Plus className="w-4 h-4" />
                  <span>Kirim Usulan Wisata</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
