import React, { useState, useEffect, useId } from 'react';
import {
  Award,
  Sparkles,
  Plus,
  Send,
  CheckCircle2,
  MapPin,
  Clock,
  ShieldCheck,
  Search,
  Edit3,
  Trash2,
  X,
  Save,
  Gift,
  QrCode,
  Users,
  Compass,
  FileCheck,
  Star,
  ExternalLink,
  BellRing,
} from 'lucide-react';
import {
  ChallengeCategoryType,
  ChallengeRewardType,
  Destination,
  TouristChallenge,
} from '../types/contract';
import {
  fetchTouristChallenges,
  saveTouristChallenge,
  deleteTouristChallenge,
  broadcastSystemNotification,
} from '../services/api';

interface ChallengesRewardsSubTabProps {
  destinations: Destination[];
  showToast?: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const ChallengesRewardsSubTab: React.FC<ChallengesRewardsSubTabProps> = ({
  destinations,
  showToast,
}) => {
  const [challenges, setChallenges] = useState<TouristChallenge[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // Filters
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const searchInputId = useId();

  // Modal State for Challenge
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingChallenge, setEditingChallenge] = useState<TouristChallenge | null>(null);

  // Form States - Challenge Info
  const [formTitle, setFormTitle] = useState<string>('');
  const [formCategory, setFormCategory] = useState<ChallengeCategoryType>('Penakluk Medan Ekstrem');
  const [formDescription, setFormDescription] = useState<string>('');
  const [formTargetDestIds, setFormTargetDestIds] = useState<string[]>([]);
  const [formRadiusMeters, setFormRadiusMeters] = useState<number>(200);
  const [formDurationDays, setFormDurationDays] = useState<number>(30);
  const [formStatus, setFormStatus] = useState<'Aktif Disiarkan' | 'Segera Hadir' | 'Selesai'>('Aktif Disiarkan');

  // Form States - Reward Info (<<include>> Tentukan reward)
  const [formRewardType, setFormRewardType] = useState<ChallengeRewardType>('Sertifikat Digital Gubernur');
  const [formRewardTitle, setFormRewardTitle] = useState<string>('');
  const [formRewardDesc, setFormRewardDesc] = useState<string>('');
  const [formRewardPoints, setFormRewardPoints] = useState<number>(1000);
  const [formVoucherPartner, setFormVoucherPartner] = useState<string>('');

  // Modal Broadcast Notification State
  const [isNotifModalOpen, setIsNotifModalOpen] = useState<boolean>(false);
  const [selectedChallengeForNotif, setSelectedChallengeForNotif] = useState<TouristChallenge | null>(null);
  const [notifMessage, setNotifMessage] = useState<string>('');
  const [isBroadcasting, setIsBroadcasting] = useState<boolean>(false);

  const loadChallenges = async () => {
    setLoading(true);
    try {
      const data = await fetchTouristChallenges();
      setChallenges(data);
    } catch {
      showToast?.('Gagal memuat daftar tantangan & reward.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadChallenges();
  }, []);

  // Filtered Challenges
  const filteredChallenges = challenges.filter((c) => {
    const matchesSearch =
      c.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.reward.title.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesCat = categoryFilter === 'all' || c.category === categoryFilter;
    return matchesSearch && matchesCat;
  });

  // KPI Computations
  const totalActiveChallenges = challenges.filter((c) => c.status === 'Aktif Disiarkan').length;
  const totalParticipants = challenges.reduce((acc, c) => acc + c.participant_count, 0);
  const totalCompletions = challenges.reduce((acc, c) => acc + c.completion_count, 0);

  // Open Create Challenge Modal
  const handleOpenCreate = () => {
    setEditingChallenge(null);
    setFormTitle('');
    setFormCategory('Penakluk Medan Ekstrem');
    setFormDescription('');
    setFormTargetDestIds([destinations[0]?.id || 'dest-01', destinations[1]?.id || 'dest-02']);
    setFormRadiusMeters(200);
    setFormDurationDays(30);
    setFormStatus('Aktif Disiarkan');

    // Default reward
    setFormRewardType('Sertifikat Digital Gubernur');
    setFormRewardTitle('Sertifikat Digital Resmi Gubernur Sumbar + 1.000 Poin Gaode');
    setFormRewardDesc('Sertifikat kelulusan bertanda tangan digital Gubernur Prov. Sumbar dan Lencana Emas Paspor Digital.');
    setFormRewardPoints(1000);
    setFormVoucherPartner('');
    setIsModalOpen(true);
  };

  // Open Edit Challenge Modal
  const handleOpenEdit = (ch: TouristChallenge) => {
    setEditingChallenge(ch);
    setFormTitle(ch.title);
    setFormCategory(ch.category);
    setFormDescription(ch.description);
    setFormTargetDestIds(ch.target_destination_ids);
    setFormRadiusMeters(ch.min_gps_checkin_radius_meters);
    setFormDurationDays(ch.duration_days);
    setFormStatus(ch.status);

    setFormRewardType(ch.reward.reward_type);
    setFormRewardTitle(ch.reward.title);
    setFormRewardDesc(ch.reward.description);
    setFormRewardPoints(ch.reward.points_reward);
    setFormVoucherPartner(ch.reward.voucher_partner || '');
    setIsModalOpen(true);
  };

  // Toggle Destination in Multi-select
  const handleToggleDest = (destId: string) => {
    setFormTargetDestIds((prev) =>
      prev.includes(destId) ? prev.filter((id) => id !== destId) : [...prev, destId]
    );
  };

  // Save Challenge & Reward
  const handleSaveChallenge = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim() || !formRewardTitle.trim()) {
      showToast?.('Judul tantangan dan judul reward wajib diisi.', 'warning');
      return;
    }

    if (formTargetDestIds.length === 0) {
      showToast?.('Pilih minimal 1 destinasi wajib untuk tantangan.', 'warning');
      return;
    }

    const challengeData: TouristChallenge = {
      id: editingChallenge ? editingChallenge.id : `chl-${Date.now().toString(36)}`,
      title: formTitle.trim(),
      slug: formTitle.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
      category: formCategory,
      description: formDescription.trim(),
      target_destination_ids: formTargetDestIds,
      target_destinations_count: formTargetDestIds.length,
      min_gps_checkin_radius_meters: formRadiusMeters,
      duration_days: formDurationDays,
      reward: {
        id: editingChallenge?.reward?.id || `rwd-${Date.now().toString(36)}`,
        reward_type: formRewardType,
        title: formRewardTitle.trim(),
        description: formRewardDesc.trim(),
        points_reward: formRewardPoints,
        voucher_partner: formVoucherPartner || undefined,
        certificate_template:
          formRewardType === 'Sertifikat Digital Gubernur'
            ? 'CERT-GUB-SUMBAR-RESMI'
            : undefined,
      },
      participant_count: editingChallenge?.participant_count || 0,
      completion_count: editingChallenge?.completion_count || 0,
      status: formStatus,
      created_at: editingChallenge?.created_at || new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    try {
      const updated = await saveTouristChallenge(challengeData);
      setChallenges(updated);
      setIsModalOpen(false);
      showToast?.(
        editingChallenge
          ? 'Tantangan dan reward berhasil diperbarui.'
          : 'Tantangan baru dan reward berhasil diterbitkan!',
        'success'
      );
    } catch {
      showToast?.('Gagal menyimpan tantangan.', 'error');
    }
  };

  // Delete Challenge
  const handleDeleteChallenge = async (ch: TouristChallenge) => {
    if (!window.confirm(`Hapus tantangan "${ch.title}"?`)) return;
    try {
      const updated = await deleteTouristChallenge(ch.id);
      setChallenges(updated);
      showToast?.(`Tantangan "${ch.title}" telah dihapus.`, 'info');
    } catch {
      showToast?.('Gagal menghapus tantangan.', 'error');
    }
  };

  // Open Broadcast Modal
  const handleOpenBroadcastModal = (ch: TouristChallenge) => {
    setSelectedChallengeForNotif(ch);
    setNotifMessage(
      `🏆 Gubernur Sumatera Barat membuka tantangan baru: "${ch.title}"! Kunjungi ${ch.target_destinations_count} destinasi, check-in via GPS & QR fisik untuk raih: ${ch.reward.title}.`
    );
    setIsNotifModalOpen(true);
  };

  // Broadcast Notification Action
  const handleBroadcastNotification = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedChallengeForNotif || !notifMessage.trim()) return;

    setIsBroadcasting(true);
    try {
      await broadcastSystemNotification({
        title: `Tantangan Baru: ${selectedChallengeForNotif.title}`,
        message: notifMessage.trim(),
        type: 'TANTANGAN_BARU',
        target: 'Semua Wisatawan',
        ref_id: selectedChallengeForNotif.id,
      });

      setIsNotifModalOpen(false);
      showToast?.(
        `Notifikasi tantangan "${selectedChallengeForNotif.title}" berhasil disiarkan ke seluruh aplikasi wisatawan!`,
        'success'
      );
    } catch {
      showToast?.('Gagal menyiarkan notifikasi tantangan.', 'error');
    } finally {
      setIsBroadcasting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* 4 Kartu KPI Statistik Gamifikasi Tantangan & Reward */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#4A5248]">Tantangan Aktif Disiarkan</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#234B24]">
            {totalActiveChallenges} Quest
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            Siap Dijalankan Wisatawan
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#1D4ED8]">Wisatawan Bergabung</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#1D4ED8]">
            {totalParticipants.toLocaleString('id-ID')} Orang
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Terdaftar di Paspor Digital
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#166534]">Sertifikat Gubernur Terbit</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#16A34A]">
            {totalCompletions.toLocaleString('id-ID')} Piagam
          </div>
          <p className="text-[11px] text-[#1E9E5A] mt-1 font-bold">
            Validasi GPS &le; 200m Terverifikasi
          </p>
        </div>

        <div className="bg-white rounded-2xl p-4 sm:p-5 shadow-sm border border-[#E4E9DA] flex flex-col justify-between">
          <span className="text-xs font-bold text-[#F26B4B]">Reward &amp; Poin Gaode</span>
          <div className="mt-2 text-2xl sm:text-3xl font-extrabold text-[#F26B4B]">
            +2.850 Poin
          </div>
          <p className="text-[11px] text-[#4A5248] mt-1">
            Voucher Homestay &amp; Ranking Poin
          </p>
        </div>
      </div>

      {/* Action Header Card */}
      <div className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <Award className="w-5 h-5 text-[#234B24]" aria-hidden="true" />
              <span>Kelola Tantangan &amp; Tentukan Reward (Use Case: Buat Tantangan)</span>
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Rancang misi petualangan menaklukkan destinasi wisata Sumbar, tentukan hadiah resmi (*Sertifikat Digital Gubernur, Lencana Paspor, Voucher Pokdarwis*), dan siarkan notifikasi langsung ke aplikasi wisatawan.
            </p>
          </div>

          <button
            type="button"
            onClick={handleOpenCreate}
            className="min-h-[44px] px-5 py-2.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center justify-center gap-2 shadow-sm transition shrink-0"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
            <span>Buat Tantangan Baru</span>
          </button>
        </div>

        {/* Filter Bar */}
        <div className="pt-3 border-t border-[#234B24]/10 flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="relative flex-1">
            <label htmlFor={searchInputId} className="sr-only">
              Cari tantangan
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
              placeholder="Cari judul misi, hadiah, atau deskripsi tantangan..."
              className="w-full min-h-[40px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
            />
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="min-h-[40px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
            >
              <option value="all">Semua Kategori Misi</option>
              <option value="Penakluk Medan Ekstrem">Penakluk Medan Ekstrem</option>
              <option value="Jejak Adat & Budaya">Jejak Adat &amp; Budaya</option>
              <option value="Pecinta Kuliner Nagari">Pecinta Kuliner Nagari</option>
              <option value="Eksplorasi Danau & Geopark">Eksplorasi Danau &amp; Geopark</option>
            </select>
          </div>
        </div>
      </div>

      {/* Grid Kartu Tantangan */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {filteredChallenges.length === 0 ? (
          <div className="col-span-full bg-white rounded-2xl p-8 text-center text-xs text-[#767676] border border-[#E4E9DA]">
            Tidak ada tantangan yang cocok dengan kata kunci pencarian.
          </div>
        ) : (
          filteredChallenges.map((ch) => {
            const completionPct =
              ch.participant_count > 0
                ? Math.round((ch.completion_count / ch.participant_count) * 100)
                : 0;

            const targetDests = destinations.filter((d) =>
              ch.target_destination_ids.includes(d.id)
            );

            return (
              <div
                key={ch.id}
                className="bg-white rounded-[24px] border-2 border-[#CFD8BE] hover:border-[#234B24] transition shadow-sm p-6 flex flex-col justify-between space-y-4"
              >
                <div>
                  {/* Baris Atas: Badge Kategori & Status */}
                  <div className="flex items-start justify-between gap-2">
                    <span className="px-3 py-1 rounded-full text-[11px] font-extrabold bg-[#234B24]/10 text-[#234B24] border border-[#234B24]/20 flex items-center gap-1.5">
                      <Compass className="w-3.5 h-3.5 text-[#F26B4B]" />
                      <span>{ch.category}</span>
                    </span>

                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                        ch.status === 'Aktif Disiarkan'
                          ? 'bg-[#DCFCE7] text-[#166534] border border-[#86EFAC]'
                          : ch.status === 'Segera Hadir'
                          ? 'bg-[#FEF08A] text-[#854D0E] border border-[#FDE047]'
                          : 'bg-gray-100 text-gray-700'
                      }`}
                    >
                      {ch.status}
                    </span>
                  </div>

                  {/* Judul & Deskripsi */}
                  <h4 className="text-base font-extrabold text-[#1B1F1A] mt-3 leading-snug">
                    {ch.title}
                  </h4>
                  <p className="text-xs text-[#4A5248] mt-1.5 leading-relaxed">
                    {ch.description}
                  </p>

                  {/* Destinasi Target yang Wajib Dikunjungi */}
                  <div className="mt-3.5 p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                    <div className="flex items-center justify-between text-xs mb-1.5">
                      <span className="font-bold text-[#1B1F1A] flex items-center gap-1">
                        <MapPin className="w-3.5 h-3.5 text-[#F26B4B]" />
                        <span>Destinasi Wajib Check-In ({ch.target_destinations_count}):</span>
                      </span>
                      <span className="text-[10px] text-[#4A5248]">
                        Validasi GPS &le; {ch.min_gps_checkin_radius_meters}m
                      </span>
                    </div>

                    <div className="flex flex-wrap gap-1.5">
                      {targetDests.map((d) => (
                        <span
                          key={d.id}
                          className="px-2.5 py-1 rounded-lg bg-white border border-[#234B24]/20 text-[11px] font-bold text-[#234B24] shadow-2xs"
                        >
                          📍 {d.name}
                        </span>
                      ))}
                    </div>
                  </div>

                  {/* Kotak Tentukan Reward (<<include>> Tentukan reward) */}
                  <div className="mt-3.5 p-4 rounded-xl bg-[#E4E9DA]/60 border border-[#CFD8BE] space-y-1.5">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-extrabold text-[#234B24] flex items-center gap-1.5">
                        <Gift className="w-4 h-4 text-[#F26B4B]" />
                        <span>Hadiah &amp; Reward Resmi:</span>
                      </span>
                      <span className="px-2 py-0.5 rounded-full bg-[#234B24] text-[#F6F3EC] text-[10px] font-extrabold">
                        +{ch.reward.points_reward} Poin Gaode
                      </span>
                    </div>

                    <div className="font-extrabold text-xs text-[#1B1F1A]">
                      {ch.reward.title}
                    </div>
                    <p className="text-[11px] text-[#4A5248] leading-relaxed">
                      {ch.reward.description}
                    </p>
                  </div>

                  {/* Progress Partisipasi & Kelulusan */}
                  <div className="mt-4 space-y-1.5 text-xs">
                    <div className="flex justify-between items-center text-[#4A5248]">
                      <span>
                        Partisipan: <strong>{ch.participant_count}</strong> wisatawan
                      </span>
                      <span className="text-[#1E9E5A] font-bold">
                        {ch.completion_count} Lulus ({completionPct}%)
                      </span>
                    </div>
                    <div className="w-full bg-[#F6F3EC] h-2.5 rounded-full overflow-hidden border border-[#CFD8BE]">
                      <div
                        style={{ width: `${Math.min(100, completionPct)}%` }}
                        className="bg-[#234B24] h-full rounded-full transition-all duration-500"
                      />
                    </div>
                  </div>
                </div>

                {/* Footer Action Buttons */}
                <div className="pt-3 border-t border-[#E4E9DA] flex flex-wrap items-center justify-between gap-2">
                  <button
                    type="button"
                    onClick={() => handleOpenBroadcastModal(ch)}
                    className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 shadow-xs transition"
                  >
                    <Send className="w-3.5 h-3.5 text-[#F26B4B]" />
                    <span>Siarkan Notifikasi (Push)</span>
                  </button>

                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => handleOpenEdit(ch)}
                      className="min-h-[38px] px-3 py-1.5 rounded-xl bg-white hover:bg-gray-100 text-[#234B24] border border-[#CFD8BE] text-xs font-bold inline-flex items-center gap-1 transition"
                    >
                      <Edit3 className="w-3.5 h-3.5" />
                      <span>Ubah</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => handleDeleteChallenge(ch)}
                      className="min-h-[38px] px-3 py-1.5 rounded-xl bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637] text-xs font-bold inline-flex items-center gap-1 transition"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>Hapus</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Modal: Buat / Ubah Tantangan & Tentukan Reward */}
      {isModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-2xl p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[92vh] overflow-y-auto space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center">
                  <Award className="w-5 h-5 text-[#F26B4B]" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {editingChallenge ? 'Ubah Misi Tantangan & Reward' : 'Buat Tantangan Baru & Tentukan Reward'}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Ekosistem Paspor Digital &amp; Gamifikasi Pariwisata Sumbar
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

            <form onSubmit={handleSaveChallenge} className="space-y-4 text-xs">
              {/* BAGIAN 1: INFORMASI MISI TANTANGAN */}
              <div className="space-y-3">
                <h4 className="font-extrabold text-xs text-[#234B24] uppercase tracking-wider flex items-center gap-1.5">
                  <Compass className="w-4 h-4 text-[#F26B4B]" />
                  <span>1. Detail Misi Menaklukkan Destinasi</span>
                </h4>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Judul Tantangan Wisatawan *
                  </label>
                  <input
                    type="text"
                    required
                    value={formTitle}
                    onChange={(e) => setFormTitle(e.target.value)}
                    placeholder="misal: Ekspedisi 5 Medan Ekstrem Minangkabau"
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-[#1B1F1A] mb-1">
                      Kategori Misi *
                    </label>
                    <select
                      value={formCategory}
                      onChange={(e) => setFormCategory(e.target.value as ChallengeCategoryType)}
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                    >
                      <option value="Penakluk Medan Ekstrem">Penakluk Medan Ekstrem</option>
                      <option value="Jejak Adat & Budaya">Jejak Adat &amp; Budaya</option>
                      <option value="Pecinta Kuliner Nagari">Pecinta Kuliner Nagari</option>
                      <option value="Eksplorasi Danau & Geopark">Eksplorasi Danau &amp; Geopark</option>
                    </select>
                  </div>

                  <div>
                    <label className="block font-bold text-[#1B1F1A] mb-1">
                      Status Penyiaran *
                    </label>
                    <select
                      value={formStatus}
                      onChange={(e) =>
                        setFormStatus(e.target.value as 'Aktif Disiarkan' | 'Segera Hadir' | 'Selesai')
                      }
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                    >
                      <option value="Aktif Disiarkan">Aktif Disiarkan</option>
                      <option value="Segera Hadir">Segera Hadir</option>
                      <option value="Selesai">Selesai</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Deskripsi &amp; Narasi Petualangan
                  </label>
                  <textarea
                    rows={2}
                    value={formDescription}
                    onChange={(e) => setFormDescription(e.target.value)}
                    placeholder="Jelaskan misi yang harus diselesaikan wisatawan..."
                    className="w-full px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A]"
                  />
                </div>

                {/* Pilih Destinasi Wajib Multi-Select */}
                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1.5">
                    Pilih Destinasi Wajib Check-In ({formTargetDestIds.length} Terpilih) *
                  </label>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-[160px] overflow-y-auto p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                    {destinations.map((d) => {
                      const isSelected = formTargetDestIds.includes(d.id);
                      return (
                        <label
                          key={d.id}
                          className={`p-2 rounded-lg border text-xs flex items-center gap-2 cursor-pointer transition ${
                            isSelected
                              ? 'bg-[#234B24] text-white border-[#234B24]'
                              : 'bg-white text-[#1B1F1A] border-[#CFD8BE] hover:bg-gray-50'
                          }`}
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => handleToggleDest(d.id)}
                            className="rounded text-[#234B24] focus:ring-[#234B24] w-4 h-4 shrink-0"
                          />
                          <span className="font-semibold truncate">{d.name}</span>
                        </label>
                      );
                    })}
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-[#1B1F1A] mb-1">
                      Radius Validasi GPS (Meter) *
                    </label>
                    <input
                      type="number"
                      min={50}
                      max={1000}
                      step={50}
                      value={formRadiusMeters}
                      onChange={(e) => setFormRadiusMeters(Number(e.target.value))}
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono text-xs font-bold text-[#234B24]"
                    />
                    <span className="text-[10px] text-[#767676]">Default: 200m dari plang Smart QR fisik</span>
                  </div>

                  <div>
                    <label className="block font-bold text-[#1B1F1A] mb-1">
                      Batas Durasi Pengerjaan (Hari) *
                    </label>
                    <input
                      type="number"
                      min={1}
                      max={90}
                      value={formDurationDays}
                      onChange={(e) => setFormDurationDays(Number(e.target.value))}
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono text-xs font-bold text-[#1B1F1A]"
                    />
                  </div>
                </div>
              </div>

              {/* BAGIAN 2: TENTUKAN REWARD (<<include>> Tentukan reward) */}
              <div className="space-y-3 pt-3 border-t border-[#234B24]/15">
                <h4 className="font-extrabold text-xs text-[#234B24] uppercase tracking-wider flex items-center gap-1.5">
                  <Gift className="w-4 h-4 text-[#F26B4B]" />
                  <span>2. Tentukan Reward Resmi (&lt;&lt;include&gt;&gt; Tentukan reward)</span>
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-[#1B1F1A] mb-1">
                      Jenis Hadiah / Reward *
                    </label>
                    <select
                      value={formRewardType}
                      onChange={(e) => setFormRewardType(e.target.value as ChallengeRewardType)}
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#234B24]"
                    >
                      <option value="Sertifikat Digital Gubernur">Sertifikat Digital Gubernur</option>
                      <option value="Lencana Emas Paspor">Lencana Emas Paspor</option>
                      <option value="Voucher Homestay Nagari">Voucher Homestay Nagari</option>
                      <option value="Poin Gaode Ranking">Poin Gaode Ranking</option>
                    </select>
                  </div>

                  <div>
                    <label className="block font-bold text-[#1B1F1A] mb-1">
                      Bonus Poin Gaode Ranking *
                    </label>
                    <input
                      type="number"
                      min={100}
                      max={5000}
                      step={100}
                      value={formRewardPoints}
                      onChange={(e) => setFormRewardPoints(Number(e.target.value))}
                      className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] font-mono text-xs font-bold text-[#1E9E5A]"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Judul Reward Resmi *
                  </label>
                  <input
                    type="text"
                    required
                    value={formRewardTitle}
                    onChange={(e) => setFormRewardTitle(e.target.value)}
                    placeholder="misal: Sertifikat Digital Resmi Gubernur Sumbar + Voucher 20%"
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  />
                </div>

                <div>
                  <label className="block font-bold text-[#1B1F1A] mb-1">
                    Rincian &amp; Manfaat Reward Bagi Wisatawan
                  </label>
                  <textarea
                    rows={2}
                    value={formRewardDesc}
                    onChange={(e) => setFormRewardDesc(e.target.value)}
                    placeholder="Jelaskan fasilitas reward atau voucher yang didapatkan..."
                    className="w-full px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A]"
                  />
                </div>
              </div>

              {/* Tombol Aksi */}
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
                  <span>Simpan Tantangan &amp; Reward</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Siarkan Notifikasi Broadcast Wisatawan (Use Case: Notifikasi) */}
      {isNotifModalOpen && selectedChallengeForNotif && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 shadow-2xl border border-[#E4E9DA] space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center">
                  <BellRing className="w-5 h-5 text-[#F26B4B]" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    Siarkan Notifikasi Tantangan (Use Case: Notifikasi)
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Broadcast Push Notification ke Aplikasi Mobile Wisatawan
                  </p>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setIsNotifModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleBroadcastNotification} className="space-y-3.5 text-xs">
              <div className="p-3.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]">
                <span className="text-[#4A5248] text-[10px] font-bold block">Tantangan Terpilih:</span>
                <div className="font-extrabold text-sm text-[#234B24] mt-0.5">
                  {selectedChallengeForNotif.title}
                </div>
                <div className="text-[11px] text-[#4A5248] mt-1">
                  Hadiah: {selectedChallengeForNotif.reward.title} (+{selectedChallengeForNotif.reward.points_reward} Poin)
                </div>
              </div>

              <div>
                <label className="block font-bold text-[#1B1F1A] mb-1">
                  Pesan Notifikasi Siaran (Push Notification) *
                </label>
                <textarea
                  rows={4}
                  required
                  value={notifMessage}
                  onChange={(e) => setNotifMessage(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div className="p-3 rounded-xl bg-[#DCFCE7] border border-[#86EFAC] text-xs text-[#166534] flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 shrink-0 text-[#16A34A]" />
                <span>
                  Notifikasi akan dikirimkan ke 3.870+ pengguna aktif aplikasi WISGO secara seketika.
                </span>
              </div>

              <div className="pt-3 border-t border-[#E4E9DA] flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsNotifModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isBroadcasting}
                  className="px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-1.5 shadow-sm transition disabled:opacity-50"
                >
                  <Send className="w-4 h-4 text-[#F26B4B]" />
                  <span>{isBroadcasting ? 'Menyiarkan...' : 'Kirim Siaran Sekarang'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
