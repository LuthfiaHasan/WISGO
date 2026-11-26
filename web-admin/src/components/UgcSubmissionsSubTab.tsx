import React, { useMemo, useState } from 'react';
import {
  Camera,
  Check,
  CheckCircle2,
  Clock,
  EyeOff,
  GitMerge,
  Image as ImageIcon,
  Inbox,
  MapPin,
  Plus,
  Search,
  Sparkles,
  Users,
  X,
  XCircle,
} from 'lucide-react';
import { MasterDestinationCategory, NewTour, NewTourStatus } from '../types/contract';
import {
  MASTER_DESTINATION_CATEGORIES,
  SUMBAR_REGENCIES,
  categoryNameToId,
} from '../data/mockDestinations';
import { NewTourRepo } from '../services/dbRepository';
import { ImageDropzone } from './ImageDropzone';

interface UgcSubmissionsSubTabProps {
  onRefreshDestinations: () => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const FACILITY_CHIPS = [
  'Area Parkir',
  'Toilet / Kamar Mandi',
  'Musholla',
  'Warung Kuliner',
  'Gazebo / Pondok',
  'Spot Foto Alami',
  'Jalur Trekking',
  'Pemandu Lokal',
] as const;

export const UgcSubmissionsSubTab: React.FC<UgcSubmissionsSubTabProps> = ({
  onRefreshDestinations,
  showToast,
}) => {
  const [submissions, setSubmissions] = useState<NewTour[]>(() => NewTourRepo.getAll());
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | NewTourStatus>('ALL');
  const [regencyFilter, setRegencyFilter] = useState('Semua Kab/Kota');

  // Create New Submission Modal
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [formName, setFormName] = useState('');
  const [formSubmitterName, setFormSubmitterName] = useState('');
  const [formSubmitterPhone, setFormSubmitterPhone] = useState('');
  const [formRegency, setFormRegency] = useState('Kab. Lima Puluh Kota');
  const [formCategory, setFormCategory] = useState<MasterDestinationCategory>('Hidden Gem');
  const [formLat, setFormLat] = useState(-0.1023);
  const [formLng, setFormLng] = useState(100.6728);
  const [formDescription, setFormDescription] = useState('');
  const [formTips, setFormTips] = useState('');
  const [formFacilities, setFormFacilities] = useState<string[]>(['Jalur Trekking', 'Spot Foto Alami']);
  const [formPhotoUrl, setFormPhotoUrl] = useState('');
  const [formPrice, setFormPrice] = useState('Rp 10.000 / orang');
  const [formSensitive, setFormSensitive] = useState(false);

  // Merge Duplicate Submissions Modal
  const [mergeGroup, setMergeGroup] = useState<NewTour[] | null>(null);
  const [primaryDataId, setPrimaryDataId] = useState<string>('');
  const [coverPhotoId, setCoverPhotoId] = useState<string>('');
  const [mergeName, setMergeName] = useState<string>('');
  const [mergeDescription, setMergeDescription] = useState<string>('');
  const [mergeTips, setMergeTips] = useState<string>('');

  const duplicateGroups = useMemo(
    () => NewTourRepo.findDuplicateGroups(submissions),
    [submissions]
  );

  const duplicateGroupById = useMemo(() => {
    const map = new Map<string, NewTour[]>();
    duplicateGroups.forEach((group) => {
      group.forEach((item) => map.set(item.id, group));
    });
    return map;
  }, [duplicateGroups]);

  const openMergeModal = (group: NewTour[]) => {
    const first = group[0];
    const second = group[1] || first;
    setMergeGroup(group);
    setPrimaryDataId(first.id);
    setCoverPhotoId(second.photo_url ? second.id : first.id);
    setMergeName(first.name);
    setMergeDescription(first.description);
    const combinedTips = Array.from(
      new Set(group.map((g) => g.tips_menjaga.trim()).filter(Boolean))
    ).join(' ');
    setMergeTips(combinedTips);
  };

  const handleSelectPrimaryData = (sub: NewTour) => {
    setPrimaryDataId(sub.id);
    setMergeName(sub.name);
    setMergeDescription(sub.description);
  };

  const handleConfirmMerge = (e: React.FormEvent) => {
    e.preventDefault();
    if (!mergeGroup || mergeGroup.length < 2) return;

    const mergedDest = NewTourRepo.mergeAndApproveToDestination({
      submissions: mergeGroup,
      primaryDataSubmissionId: primaryDataId,
      coverPhotoSubmissionId: coverPhotoId,
      customName: mergeName,
      customDescription: mergeDescription,
      customTips: mergeTips,
    });

    setSubmissions(NewTourRepo.getAll());
    setMergeGroup(null);
    onRefreshDestinations();
    const creditNames = (mergedDest.contributors || [])
      .map((c) => `${c.name} (${c.role})`)
      .join(' & ');
    showToast(
      `Destinasi "${mergedDest.name}" terbit hasil penggabungan ${mergeGroup.length} usulan! Kredit: ${creditNames}.`,
      'success'
    );
  };

  const toggleFacility = (label: string) => {
    setFormFacilities((prev) =>
      prev.includes(label) ? prev.filter((item) => item !== label) : [...prev, label]
    );
  };

  const handleApproveSubmission = (sub: NewTour) => {
    const created = NewTourRepo.approveToDestinations(sub);
    setSubmissions(NewTourRepo.getAll());
    onRefreshDestinations();
    showToast(
      `Usulan "${created.name}" oleh ${sub.submitter_name} disetujui & masuk ke Direktori Destinasi.`,
      'success'
    );
  };

  const handleRejectSubmission = (sub: NewTour) => {
    const reason = window.prompt(
      `Masukkan alasan penolakan untuk usulan "${sub.name}":`,
      'Belum memenuhi kriteria akses aman & kelengkapan foto lokasi.'
    );
    if (reason === null) return;
    const updated = NewTourRepo.rejectWithNotice(
      sub.id,
      reason.trim() || 'Belum memenuhi kriteria kurasi Dispar Sumbar.'
    );
    setSubmissions(updated);
    showToast(`Usulan "${sub.name}" ditolak dan notifikasi dikirim ke pengusul.`, 'info');
  };

  const handleSaveNewTour = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formName.trim() || !formSubmitterName.trim() || !formTips.trim()) {
      showToast('Nama destinasi, nama pengusul, dan Tips Menjaga Tempat wajib diisi.', 'warning');
      return;
    }

    const newItem: NewTour = {
      id: `nt-${Date.now().toString(36)}`,
      user_id: 'usr-tourist-01',
      name: formName.trim(),
      category_id: categoryNameToId(formCategory),
      category: formCategory,
      city_regency: formRegency,
      description: formDescription.trim(),
      latitude: Number(formLat),
      longitude: Number(formLng),
      tips_menjaga: formTips.trim(),
      facilities: formFacilities,
      estimated_price: formPrice.trim() || 'Gratis',
      photo_url:
        formPhotoUrl ||
        'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=900&q=80',
      is_sensitive: formSensitive,
      status: 'pending',
      submitter_name: formSubmitterName.trim(),
      submitter_phone: formSubmitterPhone.trim() || '6281234567890',
      created_at: new Date().toISOString(),
    };

    const updated = NewTourRepo.save(newItem);
    setSubmissions(updated);
    setIsAddModalOpen(false);
    showToast(`Usulan destinasi "${newItem.name}" berhasil masuk antrean kurasi.`, 'success');
  };

  const filtered = submissions.filter((sub) => {
    const q = searchTerm.trim().toLowerCase();
    const matchesSearch =
      !q ||
      sub.name.toLowerCase().includes(q) ||
      sub.submitter_name.toLowerCase().includes(q) ||
      sub.description.toLowerCase().includes(q) ||
      sub.tips_menjaga.toLowerCase().includes(q);
    const matchesStatus = statusFilter === 'ALL' || sub.status === statusFilter;
    const matchesRegency =
      regencyFilter === 'Semua Kab/Kota' || sub.city_regency === regencyFilter;
    return matchesSearch && matchesStatus && matchesRegency;
  });

  const pendingCount = submissions.filter((s) => s.status === 'pending').length;
  const approvedCount = submissions.filter((s) => s.status === 'approved').length;
  const rejectedCount = submissions.filter((s) => s.status === 'rejected').length;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-4 rounded-2xl bg-[#FFEDD5]/60 border border-[#FDBA74] flex items-center justify-between">
          <div>
            <span className="text-[11px] font-extrabold text-[#C2410C] uppercase tracking-wider">
              Menunggu Kurasi (Pending)
            </span>
            <div className="text-2xl font-black text-[#C2410C] mt-1">{pendingCount} Usulan</div>
            <p className="text-[11px] text-[#9A3412] mt-0.5">
              Satu pintu kurasi dari form Usul Destinasi Mobile
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
            <div className="text-2xl font-black text-[#0D9488] mt-1">{approvedCount} Usulan</div>
            <p className="text-[11px] text-[#0F766E] mt-0.5">
              Otomatis masuk Direktori Utama + Kredit Kontributor
            </p>
          </div>
          <div className="w-10 h-10 rounded-xl bg-[#0D9488] text-white flex items-center justify-center shadow-xs">
            <CheckCircle2 className="w-5 h-5" />
          </div>
        </div>

        <div className="p-4 rounded-2xl bg-white border border-[#234B24]/10 flex items-center justify-between">
          <div>
            <span className="text-[11px] font-extrabold text-[#767676] uppercase tracking-wider">
              Ditolak / Belum Layak
            </span>
            <div className="text-2xl font-black text-[#1B1F1A] mt-1">{rejectedCount} Usulan</div>
            <p className="text-[11px] text-[#4A5248] mt-0.5">
              Notifikasi alasan penolakan dikirim ke pengguna
            </p>
          </div>
          <div className="w-10 h-10 rounded-xl bg-gray-200 text-[#4A5248] flex items-center justify-center">
            <XCircle className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* BANNER DETEKSI OTOMATIS USULAN DUPLIKAT */}
      {duplicateGroups.length > 0 && (
        <div className="p-4 rounded-2xl bg-amber-50 border border-amber-300 space-y-3">
          <div className="flex items-start gap-3">
            <div className="w-9 h-9 rounded-xl bg-amber-500 text-white flex items-center justify-center shrink-0 mt-0.5">
              <GitMerge className="w-5 h-5" />
            </div>
            <div className="flex-1 text-xs">
              <h3 className="font-extrabold text-amber-950">
                Terdeteksi {duplicateGroups.length} Kelompok Usulan Tempat yang Sama (Duplikat)
              </h3>
              <p className="text-amber-900/90 mt-0.5 leading-relaxed">
                Anda dapat menggabungkan usulan serupa: pilih <strong>deskripsi/data terbaik</strong> dari satu pengusul dan <strong>foto terbaik</strong> dari pengusul lain. Semua nama pengusul otomatis dicantumkan sebagai <strong>Kontributor</strong> tanpa ada yang ditolak.
              </p>
            </div>
          </div>

          <div className="space-y-2">
            {duplicateGroups.map((group, idx) => (
              <div
                key={idx}
                className="p-3 rounded-xl bg-white border border-amber-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
              >
                <div>
                  <div className="font-extrabold text-[#1B1F1A]">
                    {group.map((g) => `"${g.name}"`).join(' + ')}
                  </div>
                  <div className="text-[11px] text-[#4A5248] mt-0.5">
                    {group.length} Pengusul:{' '}
                    <strong className="text-[#234B24]">
                      {group.map((g) => g.submitter_name).join(', ')}
                    </strong>{' '}
                    · {group[0].city_regency}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => openMergeModal(group)}
                  className="min-h-[38px] px-4 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 shadow-xs shrink-0 transition"
                >
                  <GitMerge className="w-3.5 h-3.5 text-[#F26B4B]" />
                  <span>Gabungkan &amp; Pilih Terbaik</span>
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="bg-white rounded-2xl p-4 border border-[#234B24]/10 flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex items-center gap-2 flex-wrap flex-1">
          <div className="relative min-w-[220px] flex-1 max-w-sm">
            <Search className="w-3.5 h-3.5 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Cari usulan, pengusul, atau tips menjaga..."
              className="w-full min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as 'ALL' | NewTourStatus)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="ALL">Semua Status ({submissions.length})</option>
            <option value="pending">Pending ({pendingCount})</option>
            <option value="approved">Approved ({approvedCount})</option>
            <option value="rejected">Rejected ({rejectedCount})</option>
          </select>

          <select
            value={regencyFilter}
            onChange={(e) => setRegencyFilter(e.target.value)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
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
            setFormName('');
            setFormSubmitterName('');
            setFormSubmitterPhone('');
            setFormRegency('Kab. Lima Puluh Kota');
            setFormCategory('Hidden Gem');
            setFormLat(-0.1023);
            setFormLng(100.6728);
            setFormDescription('');
            setFormTips('');
            setFormFacilities(['Jalur Trekking', 'Spot Foto Alami']);
            setFormPhotoUrl('');
            setFormPrice('Rp 10.000 / orang');
            setFormSensitive(false);
            setIsAddModalOpen(true);
          }}
          className="min-h-[40px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
        >
          <Plus className="w-3.5 h-3.5" />
          <span>Input Usulan Destinasi</span>
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-[#234B24]/10 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F6F3EC] text-[#234B24] font-extrabold uppercase text-[10px] tracking-wider border-b border-[#CFD8BE]">
              <tr>
                <th className="py-3.5 px-4">Foto &amp; Destinasi Usulan</th>
                <th className="py-3.5 px-4">Wilayah, Kategori &amp; GPS</th>
                <th className="py-3.5 px-4">Tips Menjaga &amp; Fasilitas</th>
                <th className="py-3.5 px-4">Pengusul</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Kurasi Admin</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA]">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-10 text-center text-[#767676]">
                    Tidak ada usulan destinasi yang sesuai filter.
                  </td>
                </tr>
              ) : (
                filtered.map((sub) => {
                  const dupGroup = duplicateGroupById.get(sub.id);
                  return (
                    <tr key={sub.id} className="hover:bg-[#F6F3EC]/40 transition align-top">
                      <td className="py-3.5 px-4 max-w-xs">
                        <div className="flex items-start gap-3">
                          <div className="w-14 h-12 rounded-lg overflow-hidden bg-gray-100 shrink-0 border border-black/5">
                            {sub.photo_url ? (
                              <img
                                src={sub.photo_url}
                                alt={sub.name}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center text-gray-400">
                                <ImageIcon className="w-4 h-4" />
                              </div>
                            )}
                          </div>
                          <div>
                            <div className="flex items-center gap-1.5 flex-wrap">
                              <span className="font-extrabold text-[#1B1F1A]">{sub.name}</span>
                              {dupGroup && sub.status === 'pending' && (
                                <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-amber-100 text-amber-800 border border-amber-300 inline-flex items-center gap-1">
                                  <GitMerge className="w-2.5 h-2.5" />
                                  Duplikat ({dupGroup.length})
                                </span>
                              )}
                            </div>
                            <div className="text-[11px] text-[#4A5248] line-clamp-2 mt-0.5">
                              {sub.description}
                            </div>
                            {sub.estimated_price && (
                              <div className="text-[10px] font-mono font-bold text-[#234B24] mt-1">
                                Estimasi: {sub.estimated_price}
                              </div>
                            )}
                          </div>
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-semibold text-[#1B1F1A]">{sub.city_regency}</div>
                        <div className="text-[10px] text-[#234B24] font-bold mt-0.5">
                          {sub.category}
                        </div>
                        <div className="mt-1 inline-flex items-center gap-1 text-[10px] font-mono text-[#4A5248]">
                          {sub.is_sensitive ? (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-purple-100 text-purple-800 font-bold">
                              <EyeOff className="w-3 h-3" />
                              GPS Terlindungi (Sensitif)
                            </span>
                          ) : (
                            <>
                              <MapPin className="w-3 h-3 text-[#F26B4B]" />
                              {sub.latitude.toFixed(4)}, {sub.longitude.toFixed(4)}
                            </>
                          )}
                        </div>
                      </td>

                      <td className="py-3.5 px-4 max-w-xs">
                        <div className="p-2 rounded-xl bg-[#E4E9DA]/60 border border-[#CFD8BE] text-[11px] text-[#1B1F1A]">
                          <div className="font-bold text-[#234B24] flex items-center gap-1 mb-0.5">
                            <Sparkles className="w-3 h-3" /> Tips Menjaga Tempat:
                          </div>
                          <p className="line-clamp-2">{sub.tips_menjaga}</p>
                        </div>
                        {sub.facilities && sub.facilities.length > 0 && (
                          <div className="flex flex-wrap gap-1 mt-1.5">
                            {sub.facilities.map((fac) => (
                              <span
                                key={fac}
                                className="px-1.5 py-0.5 rounded bg-[#F6F3EC] border border-[#CFD8BE] text-[10px] font-semibold text-[#4A5248]"
                              >
                                {fac}
                              </span>
                            ))}
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4">
                        <div className="font-bold text-[#1B1F1A]">{sub.submitter_name}</div>
                        <div className="text-[10px] font-mono text-[#767676]">
                          {sub.submitter_phone}
                        </div>
                      </td>

                      <td className="py-3.5 px-4">
                        {sub.status === 'pending' && (
                          <span className="px-2.5 py-1 rounded-full text-[10px] font-extrabold bg-[#FFEDD5] text-[#C2410C] inline-flex items-center gap-1">
                            <Clock className="w-3 h-3" /> Pending
                          </span>
                        )}
                        {sub.status === 'approved' && (
                          <div className="space-y-1">
                            <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-[#CCFBF1] text-[#0D9488] inline-flex items-center gap-1">
                              <CheckCircle2 className="w-3 h-3" /> Approved
                            </span>
                            {sub.merged_role && (
                              <div className="text-[10px] font-bold text-[#234B24]">
                                {sub.merged_role}
                              </div>
                            )}
                          </div>
                        )}
                        {sub.status === 'rejected' && (
                          <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-red-100 text-red-700 inline-flex items-center gap-1">
                            <XCircle className="w-3 h-3" /> Rejected
                          </span>
                        )}
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5 flex-wrap">
                          {sub.status === 'pending' ? (
                            <>
                              {dupGroup && (
                                <button
                                  type="button"
                                  onClick={() => openMergeModal(dupGroup)}
                                  className="px-2.5 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-600 text-white font-bold text-[11px] inline-flex items-center gap-1"
                                  title="Gabungkan dengan usulan serupa"
                                >
                                  <GitMerge className="w-3.5 h-3.5" /> Gabungkan
                                </button>
                              )}
                              <button
                                type="button"
                                onClick={() => handleApproveSubmission(sub)}
                                className="px-3 py-1.5 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold text-[11px] inline-flex items-center gap-1"
                              >
                                <Check className="w-3.5 h-3.5" /> Setujui
                              </button>
                              <button
                                type="button"
                                onClick={() => handleRejectSubmission(sub)}
                                className="px-2.5 py-1.5 rounded-lg bg-red-100 hover:bg-red-200 text-red-700 font-bold text-[11px] inline-flex items-center gap-1"
                              >
                                <X className="w-3.5 h-3.5" /> Tolak
                              </button>
                            </>
                          ) : sub.status === 'approved' ? (
                            <span className="text-[11px] text-[#0D9488] font-bold inline-flex items-center gap-1">
                              <CheckCircle2 className="w-3.5 h-3.5" /> Terbit di Direktori
                            </span>
                          ) : (
                            <button
                              type="button"
                              onClick={() => handleApproveSubmission(sub)}
                              className="px-2.5 py-1 rounded-lg text-[10px] font-bold text-[#234B24] border border-[#234B24]/20 hover:bg-[#234B24]/10"
                            >
                              Tinjau Ulang &amp; Setujui
                            </button>
                          )}
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

      {/* ==================================================================== */}
      {/* MODAL GABUNGKAN USULAN DUPLIKAT (PICK BEST DATA + BEST PHOTO)        */}
      {/* ==================================================================== */}
      {mergeGroup && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-3xl shadow-2xl border border-[#234B24]/10 max-h-[92vh] flex flex-col overflow-hidden">
            <div className="p-5 bg-[#234B24] text-[#F6F3EC] flex items-center justify-between shrink-0">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-white/10 flex items-center justify-center">
                  <GitMerge className="w-5 h-5 text-[#F26B4B]" />
                </div>
                <div>
                  <span className="text-[10px] font-bold uppercase tracking-wider text-[#A7F3D0]">
                    Kurasi Kolaboratif · {mergeGroup.length} Usulan Serupa
                  </span>
                  <h3 className="text-base font-extrabold">
                    Gabungkan Usulan &amp; Cantumkan Kredit Kontributor
                  </h3>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setMergeGroup(null)}
                className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleConfirmMerge} className="p-6 overflow-y-auto space-y-5 text-xs">
              {/* LANGKAH 1: PILIH DATA & DESKRIPSI TERBAIK */}
              <div className="space-y-2.5">
                <h4 className="font-extrabold text-[#234B24] uppercase tracking-wider text-[11px]">
                  1. Pilih Sumber Data, Deskripsi &amp; Koordinat Terbaik
                </h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {mergeGroup.map((sub) => {
                    const selected = primaryDataId === sub.id;
                    return (
                      <button
                        key={sub.id}
                        type="button"
                        onClick={() => handleSelectPrimaryData(sub)}
                        className={`text-left p-3.5 rounded-2xl border-2 transition ${
                          selected
                            ? 'border-[#234B24] bg-[#E4E9DA]/50'
                            : 'border-[#CFD8BE] bg-[#F6F3EC]/60 hover:border-[#234B24]/40'
                        }`}
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="font-extrabold text-[#1B1F1A]">{sub.name}</span>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
                              selected
                                ? 'bg-[#234B24] text-white'
                                : 'bg-white text-[#4A5248] border border-[#CFD8BE]'
                            }`}
                          >
                            {selected ? 'Dipilih (Data)' : 'Pilih Data'}
                          </span>
                        </div>
                        <p className="text-[11px] text-[#4A5248] mt-1 line-clamp-2">
                          {sub.description}
                        </p>
                        <div className="mt-2 text-[10px] font-bold text-[#234B24]">
                          Pengusul: {sub.submitter_name} · GPS {sub.latitude.toFixed(4)},{' '}
                          {sub.longitude.toFixed(4)}
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* LANGKAH 2: PILIH FOTO COVER TERBAIK */}
              <div className="space-y-2.5">
                <h4 className="font-extrabold text-[#234B24] uppercase tracking-wider text-[11px] flex items-center gap-1.5">
                  <Camera className="w-3.5 h-3.5 text-[#F26B4B]" />
                  <span>
                    2. Pilih Foto Utama (Cover) Terbaik — Foto lain otomatis tersimpan ke galeri
                  </span>
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {mergeGroup.map((sub) => {
                    const selected = coverPhotoId === sub.id;
                    return (
                      <button
                        key={sub.id}
                        type="button"
                        onClick={() => setCoverPhotoId(sub.id)}
                        className={`text-left rounded-2xl overflow-hidden border-2 transition ${
                          selected
                            ? 'border-[#F26B4B] ring-2 ring-[#F26B4B]/20'
                            : 'border-[#CFD8BE] opacity-85 hover:opacity-100'
                        }`}
                      >
                        <div className="aspect-[16/9] bg-black/10 relative">
                          {sub.photo_url ? (
                            <img
                              src={sub.photo_url}
                              alt={sub.name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-gray-400">
                              <ImageIcon className="w-6 h-6" />
                            </div>
                          )}
                          {selected && (
                            <span className="absolute top-2 right-2 px-2.5 py-1 rounded-full bg-[#F26B4B] text-white text-[10px] font-black shadow-sm">
                              ✓ Foto Cover Terpilih
                            </span>
                          )}
                        </div>
                        <div className="p-2.5 bg-[#F6F3EC] flex items-center justify-between text-[11px]">
                          <span className="font-bold text-[#1B1F1A]">
                            Foto oleh {sub.submitter_name}
                          </span>
                          <span className="text-[10px] text-[#4A5248]">
                            {selected ? 'Utama' : 'Masuk Galeri'}
                          </span>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* LANGKAH 3: SUNTHING HASIL GABUNGAN */}
              <div className="space-y-3 p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
                <h4 className="font-extrabold text-[#234B24] uppercase tracking-wider text-[11px]">
                  3. Hasil Final Destinasi &amp; Gabungan Tips
                </h4>
                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Nama Final Destinasi *</label>
                  <input
                    type="text"
                    required
                    value={mergeName}
                    onChange={(e) => setMergeName(e.target.value)}
                    className="w-full min-h-[40px] px-3 py-2 rounded-xl bg-white border border-[#CFD8BE] font-bold"
                  />
                </div>
                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">Deskripsi Final</label>
                  <textarea
                    rows={2}
                    value={mergeDescription}
                    onChange={(e) => setMergeDescription(e.target.value)}
                    className="w-full p-3 rounded-xl bg-white border border-[#CFD8BE]"
                  />
                </div>
                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Tips Menjaga Tempat Ini (Otomatis Digabung dari Semua Pengusul)
                  </label>
                  <textarea
                    rows={2}
                    value={mergeTips}
                    onChange={(e) => setMergeTips(e.target.value)}
                    className="w-full p-3 rounded-xl bg-white border border-[#CFD8BE]"
                  />
                </div>
              </div>

              {/* PRATINJAU KREDIT KONTRIBUTOR ("DIUSULKAN OLEH") */}
              <div className="p-4 rounded-2xl bg-[#E4E9DA]/70 border border-[#234B24]/20 space-y-2">
                <div className="font-extrabold text-[#234B24] flex items-center gap-1.5">
                  <Users className="w-4 h-4" />
                  <span>Pratinjau Kredit Kontributor (Tampil di Detail Destinasi)</span>
                </div>
                <div className="flex flex-wrap gap-2">
                  {mergeGroup.map((sub) => {
                    const isPrimary = sub.id === primaryDataId;
                    const isPhoto = sub.id === coverPhotoId;
                    const role =
                      isPrimary && isPhoto
                        ? 'Pengusul Utama'
                        : isPrimary
                        ? 'Kontributor Data & Tips'
                        : isPhoto
                        ? 'Kontributor Foto'
                        : 'Pengusul Bersama';
                    return (
                      <span
                        key={sub.id}
                        className="px-3 py-1 rounded-full bg-white border border-[#234B24]/20 text-[11px] font-bold text-[#1B1F1A]"
                      >
                        {sub.submitter_name}{' '}
                        <span className="text-[#234B24] font-extrabold">({role})</span>
                      </span>
                    );
                  })}
                </div>
                <p className="text-[10.5px] text-[#4A5248]">
                  Semua pengusul di atas akan berstatus <strong>Approved (Digabungkan)</strong> dan menerima notifikasi apresiasi.
                </p>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10">
                <button
                  type="button"
                  onClick={() => setMergeGroup(null)}
                  className="min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[42px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm"
                >
                  <GitMerge className="w-4 h-4 text-[#F26B4B]" />
                  <span>Gabungkan &amp; Terbitkan 1 Destinasi</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL INPUT USULAN DESTINASI BARU */}
      {isAddModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-2xl p-6 shadow-2xl border border-[#234B24]/10 max-h-[92vh] flex flex-col overflow-hidden">
            <div className="flex items-center justify-between pb-3 border-b border-[#234B24]/10 shrink-0">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center">
                  <Inbox className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    Formulir Usulan Destinasi (Sinkron usul_destinasi_sheet)
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    5 Master Kategori · 8 Fasilitas · Tips Menjaga Wajib
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

            <form onSubmit={handleSaveNewTour} className="mt-4 space-y-4 overflow-y-auto pr-1">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Nama Destinasi *
                  </label>
                  <input
                    type="text"
                    required
                    value={formName}
                    onChange={(e) => setFormName(e.target.value)}
                    placeholder="Contoh: Air Terjun Sarasah Barasok"
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    5 Master Kategori *
                  </label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value as MasterDestinationCategory)}
                    className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                  >
                    {MASTER_DESTINATION_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">Kab/Kota *</label>
                  <select
                    value={formRegency}
                    onChange={(e) => setFormRegency(e.target.value)}
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                  >
                    {SUMBAR_REGENCIES.filter((r) => r !== 'Semua Kab/Kota').map((reg) => (
                      <option key={reg} value={reg}>
                        {reg}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">Latitude GPS</label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formLat}
                    onChange={(e) => setFormLat(Number(e.target.value))}
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Longitude GPS
                  </label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formLng}
                    onChange={(e) => setFormLng(Number(e.target.value))}
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Nama Pengusul *
                  </label>
                  <input
                    type="text"
                    required
                    value={formSubmitterName}
                    onChange={(e) => setFormSubmitterName(e.target.value)}
                    placeholder="Contoh: Ilham Fathoni"
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">WhatsApp</label>
                  <input
                    type="tel"
                    value={formSubmitterPhone}
                    onChange={(e) => setFormSubmitterPhone(e.target.value)}
                    placeholder="6281234567890"
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Estimasi Tarif
                  </label>
                  <input
                    type="text"
                    value={formPrice}
                    onChange={(e) => setFormPrice(e.target.value)}
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1.5">
                  Fasilitas Terpantau di Lokasi (8 Opsi Mobile)
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {FACILITY_CHIPS.map((chip) => {
                    const active = formFacilities.includes(chip);
                    return (
                      <button
                        key={chip}
                        type="button"
                        onClick={() => toggleFacility(chip)}
                        className={`px-3 py-1.5 rounded-full text-[11px] font-bold border transition ${
                          active
                            ? 'bg-[#234B24] text-white border-[#234B24]'
                            : 'bg-[#F6F3EC] text-[#4A5248] border-[#CFD8BE]'
                        }`}
                      >
                        {chip}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Tips Menjaga Tempat Ini (Wajib) *
                </label>
                <textarea
                  rows={2}
                  required
                  value={formTips}
                  onChange={(e) => setFormTips(e.target.value)}
                  placeholder="Contoh: Bawa pulang sampah plastik dan lapor Pokdarwis sebelum masuk hutan..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Deskripsi Keindahan &amp; Akses
                </label>
                <textarea
                  rows={2}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                />
              </div>

              <label className="flex items-center gap-2 text-xs font-bold text-purple-900 bg-purple-50 p-3 rounded-xl border border-purple-200 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formSensitive}
                  onChange={(e) => setFormSensitive(e.target.checked)}
                  className="w-4 h-4 accent-purple-700"
                />
                <span>
                  Lindungi Koordinat GPS (Kawasan Alam Sensitif / Hidden Gem sebelum kurasi)
                </span>
              </label>

              <ImageDropzone
                label="Foto Dokumentasi Destinasi"
                value={formPhotoUrl}
                onChange={setFormPhotoUrl}
                onClear={() => setFormPhotoUrl('')}
              />

              <div className="pt-3 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="min-h-[42px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[42px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2"
                >
                  <Plus className="w-4 h-4" />
                  <span>Kirim Usulan</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
