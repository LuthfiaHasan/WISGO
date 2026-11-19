import React, { useState, useEffect } from 'react';
import {
  Trophy,
  Award,
  CheckCircle2,
  Clock,
  Gift,
  Search,
  Plus,
  Trash2,
  Edit3,
  Filter,
  Sparkles,
  MapPin,
  Users,
  Send,
  Check,
  Calendar,
  X,
  Share2,
  QrCode,
  FileCheck,
} from 'lucide-react';
import {
  ChecklistChallenge,
  ChecklistClaimStatus,
  TouristChecklistClaim,
  Destination,
} from '../types/contract';

interface ChallengePageProps {
  destinations: Destination[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const STORAGE_KEY_CHALLENGES = 'wisgo_checklist_challenges';
const STORAGE_KEY_CLAIMS = 'wisgo_checklist_claims';

// Seed Initial Challenges
const INITIAL_CHALLENGES: ChecklistChallenge[] = [
  {
    id: 'ch-01',
    title: 'Jelajah 10 Ikon Geopark & Lembah Harau',
    description:
      'Kunjungi 10 titik destinasi geologi dan panorama tebing granit di kawasan Limapuluh Kota & Agam. Cukup scan QR GPS di setiap lokasi.',
    category: 'Eksplorasi Alam & Geopark',
    target_count: 10,
    reward_description: 'Uang Tunai Rp 1.500.000 + Sertifikat Penjelajah Geopark Sumbar',
    duration_days: 30,
    target_destinations: [
      'Lembah Harau',
      'Kelok 9 Skywalk',
      'Ngalau Indah',
      'Danau Maninjau',
      'Puncak Lawang',
      'Ngarai Sianok',
      'Jam Gadang Bukittinggi',
      'Taruko Cafe & Valley',
      'Lembah Anai',
      'Batang Tabik Waterpark',
    ],
    participant_count: 428,
    completed_count: 36,
    is_active: true,
    created_at: '2026-10-01T08:00:00Z',
    updated_at: '2026-11-15T10:00:00Z',
  },
  {
    id: 'ch-02',
    title: 'Ekspedisi 5 Nagari Pusaka & Warisan Adat',
    description:
      'Lengkapi kunjungan ke 5 perkampungan adat dan istana peninggalan Minangkabau untuk menguji kecintaan budaya lokal.',
    category: 'Pusaka & Warisan Adat',
    target_count: 5,
    reward_description: 'Paket Voucher Belanja UMKM Songket Rp 750.000 + Piagam Adat',
    duration_days: 21,
    target_destinations: [
      'Istano Basa Pagaruyung',
      'Nagari Pariangan (Desa Terindah)',
      'Desa Wisata Kubu Gadang',
      'Kawasan Saribu Rumah Gadang',
      'Benteng Fort de Kock',
    ],
    participant_count: 312,
    completed_count: 58,
    is_active: true,
    created_at: '2026-10-10T09:00:00Z',
    updated_at: '2026-11-12T14:30:00Z',
  },
  {
    id: 'ch-03',
    title: 'Pesona 7 Surga Bahari Mandeh & Pesisir',
    description:
      'Jelajahi 7 pulau dan pesisir eksotis di Kawasan Mandeh dan Kota Padang dengan check-in terverifikasi.',
    category: 'Bahari & Kepulauan',
    target_count: 7,
    reward_description: 'Voucher Menginap 2M1N Eco-Resort Mandeh + Free Island Hopping Boat',
    duration_days: 45,
    target_destinations: [
      'Kawasan Wisata Bahari Mandeh',
      'Pulau Cubadak',
      'Pulau Pamutusan',
      'Pulau Pasumpahan',
      'Pantai Air Manis Padang',
      'Pantai Gandoriah Pariaman',
      'Pantai Padang Taplau',
    ],
    participant_count: 245,
    completed_count: 19,
    is_active: true,
    created_at: '2026-10-15T11:00:00Z',
    updated_at: '2026-11-10T16:00:00Z',
  },
  {
    id: 'ch-04',
    title: 'Tantangan 3 Puncak & Danau Kembar Solok',
    description:
      'Jelajahi keindahan Danau Diatas, Danau Dibawah, dan Kebun Teh Alahan Panjang dalam 1 rute dingin nan sejuk.',
    category: 'Danau & Agrowisata',
    target_count: 3,
    reward_description: 'Merchandise Eksklusif Kopi Solok Radjo + Goodie Bag Dispar',
    duration_days: 14,
    target_destinations: [
      'Danau Diatas & Danau Dibawah',
      'Kebun Teh Alahan Panjang',
      'Danau Singkarak',
    ],
    participant_count: 189,
    completed_count: 74,
    is_active: true,
    created_at: '2026-10-20T10:00:00Z',
    updated_at: '2026-11-05T09:00:00Z',
  },
];

// Seed Initial Claims
const INITIAL_CLAIMS: TouristChecklistClaim[] = [
  {
    id: 'clm-001',
    challenge_id: 'ch-01',
    challenge_title: 'Jelajah 10 Ikon Geopark & Lembah Harau',
    tourist_name: 'Fauzan Pratama',
    tourist_phone: '081267891011',
    target_count: 10,
    completed_count: 10,
    completed_destinations: [
      'Lembah Harau',
      'Kelok 9 Skywalk',
      'Ngalau Indah',
      'Danau Maninjau',
      'Puncak Lawang',
      'Ngarai Sianok',
      'Jam Gadang Bukittinggi',
      'Taruko Cafe & Valley',
      'Lembah Anai',
      'Batang Tabik Waterpark',
    ],
    reward_description: 'Uang Tunai Rp 1.500.000 + Sertifikat Penjelajah Geopark Sumbar',
    status: 'SIAP_KLAIM',
    completed_at: '2026-11-16T14:20:00Z',
  },
  {
    id: 'clm-002',
    challenge_id: 'ch-02',
    challenge_title: 'Ekspedisi 5 Nagari Pusaka & Warisan Adat',
    tourist_name: 'Siti Rahmawati',
    tourist_phone: '081398765432',
    target_count: 5,
    completed_count: 5,
    completed_destinations: [
      'Istano Basa Pagaruyung',
      'Nagari Pariangan (Desa Terindah)',
      'Desa Wisata Kubu Gadang',
      'Kawasan Saribu Rumah Gadang',
      'Benteng Fort de Kock',
    ],
    reward_description: 'Paket Voucher Belanja UMKM Songket Rp 750.000 + Piagam Adat',
    status: 'HADIAH_TERKIRIM',
    completed_at: '2026-11-14T11:15:00Z',
    reward_sent_at: '2026-11-15T09:30:00Z',
    reward_notes: 'Voucher digital terkirim via WhatsApp dan Piagam Fisik dikirim via Pos Kilat.',
  },
  {
    id: 'clm-003',
    challenge_id: 'ch-01',
    challenge_title: 'Jelajah 10 Ikon Geopark & Lembah Harau',
    tourist_name: 'Budi Santoso',
    tourist_phone: '082155443322',
    target_count: 10,
    completed_count: 8,
    completed_destinations: [
      'Lembah Harau',
      'Kelok 9 Skywalk',
      'Ngalau Indah',
      'Danau Maninjau',
      'Puncak Lawang',
      'Ngarai Sianok',
      'Jam Gadang Bukittinggi',
      'Taruko Cafe & Valley',
    ],
    reward_description: 'Uang Tunai Rp 1.500.000 + Sertifikat Penjelajah Geopark Sumbar',
    status: 'DALAM_PROGRES',
  },
  {
    id: 'clm-004',
    challenge_id: 'ch-03',
    challenge_title: 'Pesona 7 Surga Bahari Mandeh & Pesisir',
    tourist_name: 'Anisa Nurul Fitri',
    tourist_phone: '085277889900',
    target_count: 7,
    completed_count: 7,
    completed_destinations: [
      'Kawasan Wisata Bahari Mandeh',
      'Pulau Cubadak',
      'Pulau Pamutusan',
      'Pulau Pasumpahan',
      'Pantai Air Manis Padang',
      'Pantai Gandoriah Pariaman',
      'Pantai Padang Taplau',
    ],
    reward_description: 'Voucher Menginap 2M1N Eco-Resort Mandeh + Free Island Hopping Boat',
    status: 'SIAP_KLAIM',
    completed_at: '2026-11-17T09:45:00Z',
  },
  {
    id: 'clm-005',
    challenge_id: 'ch-04',
    challenge_title: 'Tantangan 3 Puncak & Danau Kembar Solok',
    tourist_name: 'Rahmat Hidayat',
    tourist_phone: '081912345678',
    target_count: 3,
    completed_count: 2,
    completed_destinations: [
      'Danau Diatas & Danau Dibawah',
      'Kebun Teh Alahan Panjang',
    ],
    reward_description: 'Merchandise Eksklusif Kopi Solok Radjo + Goodie Bag Dispar',
    status: 'DALAM_PROGRES',
  },
];

export const ChallengePage: React.FC<ChallengePageProps> = ({
  destinations,
  showToast,
}) => {
  // Sub-Tab Navigation
  const [activeTab, setActiveTab] = useState<'master' | 'claims'>('master');

  // Challenges State
  const [challenges, setChallenges] = useState<ChecklistChallenge[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY_CHALLENGES);
      return saved ? JSON.parse(saved) : INITIAL_CHALLENGES;
    } catch {
      return INITIAL_CHALLENGES;
    }
  });

  // Claims State
  const [claims, setClaims] = useState<TouristChecklistClaim[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY_CLAIMS);
      return saved ? JSON.parse(saved) : INITIAL_CLAIMS;
    } catch {
      return INITIAL_CLAIMS;
    }
  });

  // Persist to LocalStorage
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY_CHALLENGES, JSON.stringify(challenges));
    } catch (e) {
      console.warn('Gagal menyimpan challenges ke localStorage:', e);
    }
  }, [challenges]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY_CLAIMS, JSON.stringify(claims));
    } catch (e) {
      console.warn('Gagal menyimpan claims ke localStorage:', e);
    }
  }, [claims]);

  // Modal Challenge Form State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingChallenge, setEditingChallenge] = useState<ChecklistChallenge | null>(null);
  const [formTitle, setFormTitle] = useState('');
  const [formDescription, setFormDescription] = useState('');
  const [formCategory, setFormCategory] = useState('Eksplorasi Alam & Geopark');
  const [formTargetCount, setFormTargetCount] = useState<number>(5);
  const [formReward, setFormReward] = useState('');
  const [formDuration, setFormDuration] = useState<number>(30);
  const [formSelectedDests, setFormSelectedDests] = useState<string[]>([]);

  // Search & Filter State
  const [searchTerm, setSearchTerm] = useState('');
  const [claimStatusFilter, setClaimStatusFilter] = useState<'ALL' | ChecklistClaimStatus>('ALL');

  // Modal Detail Claim / Kirim Hadiah
  const [selectedClaimForReward, setSelectedClaimForReward] = useState<TouristChecklistClaim | null>(null);
  const [rewardNotesInput, setRewardNotesInput] = useState('');

  // Open Create Challenge Modal
  const handleOpenCreateModal = () => {
    setEditingChallenge(null);
    setFormTitle('');
    setFormDescription('');
    setFormCategory('Eksplorasi Alam & Geopark');
    setFormTargetCount(5);
    setFormReward('');
    setFormDuration(30);
    setFormSelectedDests([]);
    setIsModalOpen(true);
  };

  // Open Edit Challenge Modal
  const handleOpenEditModal = (ch: ChecklistChallenge) => {
    setEditingChallenge(ch);
    setFormTitle(ch.title);
    setFormDescription(ch.description);
    setFormCategory(ch.category || 'Penakluk Medan Ekstrem');
    setFormTargetCount(ch.target_count ?? ch.target_destination_count ?? 3);
    setFormReward(ch.reward_description || ch.reward_title || '');
    setFormDuration(ch.duration_days ?? 30);
    setFormSelectedDests(ch.target_destinations || []);
    setIsModalOpen(true);
  };

  // Save Challenge (Create / Update)
  const handleSaveChallenge = (e: React.FormEvent) => {
    e.preventDefault();

    if (!formTitle.trim() || !formReward.trim()) {
      showToast('Judul tantangan dan deskripsi reward wajib diisi.', 'warning');
      return;
    }

    if (formTargetCount <= 0) {
      showToast('Target jumlah tempat harus lebih dari 0.', 'warning');
      return;
    }

    if (editingChallenge) {
      const updated: ChecklistChallenge[] = challenges.map((ch) =>
        ch.id === editingChallenge.id
          ? {
              ...ch,
              title: formTitle.trim(),
              description: formDescription.trim(),
              category: formCategory,
              target_count: Number(formTargetCount),
              reward_description: formReward.trim(),
              duration_days: Number(formDuration),
              target_destinations: formSelectedDests,
              updated_at: new Date().toISOString(),
            }
          : ch
      );
      setChallenges(updated);
      showToast('Tantangan berhasil diperbarui!', 'success');
    } else {
      const newCh: ChecklistChallenge = {
        id: `ch-${Date.now().toString(36)}`,
        title: formTitle.trim(),
        description: formDescription.trim(),
        category: formCategory,
        target_count: Number(formTargetCount),
        reward_description: formReward.trim(),
        duration_days: Number(formDuration),
        target_destinations: formSelectedDests,
        participant_count: 0,
        completed_count: 0,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
      setChallenges([newCh, ...challenges]);
      showToast('Tantangan baru berhasil dibuat!', 'success');
    }

    setIsModalOpen(false);
  };

  // Toggle Challenge Active Status
  const handleToggleActive = (id: string) => {
    const updated = challenges.map((ch) =>
      ch.id === id ? { ...ch, is_active: !ch.is_active } : ch
    );
    setChallenges(updated);
    showToast('Status keaktifan tantangan diperbarui.', 'info');
  };

  // Delete Challenge
  const handleDeleteChallenge = (id: string) => {
    if (!window.confirm('Hapus tantangan ini? Riwayat klaim terkait akan tetap tersimpan.')) {
      return;
    }
    setChallenges(challenges.filter((ch) => ch.id !== id));
    showToast('Tantangan berhasil dihapus.', 'info');
  };

  // Process Reward Sending
  const handleConfirmSendReward = () => {
    if (!selectedClaimForReward) return;

    const updated = claims.map((clm) =>
      clm.id === selectedClaimForReward.id
        ? {
            ...clm,
            status: 'HADIAH_TERKIRIM' as ChecklistClaimStatus,
            reward_sent_at: new Date().toISOString(),
            reward_notes:
              rewardNotesInput.trim() ||
              'Hadiah resmi telah diverifikasi & diserahkan oleh Pengelola Dispar Sumbar.',
          }
        : clm
    );

    setClaims(updated);
    showToast(
      `Hadiah berhasil dikirimkan ke wisatawan: ${selectedClaimForReward.tourist_name}! Notifikasi WhatsApp diterbitkan.`,
      'success'
    );
    setSelectedClaimForReward(null);
    setRewardNotesInput('');
  };

  // Macro Metrics
  const totalActiveChallenges = challenges.filter((c) => c.is_active).length;
  const totalParticipants = challenges.reduce((sum, c) => sum + (c.participant_count || 0), 0);
  const totalReadyToClaim = claims.filter((c) => c.status === 'SIAP_KLAIM').length;
  const totalRewardSent = claims.filter((c) => c.status === 'HADIAH_TERKIRIM').length;

  // Filtered Claims
  const filteredClaims = claims.filter((clm) => {
    const tName = clm.tourist_name || '';
    const tPhone = clm.tourist_phone || '';
    const cTitle = clm.challenge_title || clm.reward || '';
    const matchesSearch =
      tName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tPhone.includes(searchTerm) ||
      cTitle.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus =
      claimStatusFilter === 'ALL' || clm.status === claimStatusFilter;

    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6 overflow-x-hidden">
      {/* Header Halaman */}
      <header className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA]">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2.5 mb-1.5">
              <span className="px-3 py-1 rounded-pill bg-[#234B24]/10 text-[#234B24] font-extrabold text-[11px] uppercase tracking-wider">
                Gamifikasi &amp; Partisipasi Wisatawan
              </span>
              <span className="px-2.5 py-0.5 rounded-md bg-[#F26B4B]/10 text-[#F26B4B] font-bold text-[10px]">
                Checklist Murni (Non-Poin)
              </span>
            </div>
            <h1 className="text-2xl font-black text-[#1B1F1A] tracking-tight">
              Tantangan Menaklukkan Destinasi
            </h1>
            <p className="text-xs text-[#4A5248] mt-1">
              Kelola tantangan checklist tempat wisata berhadiah bebas (uang tunai, voucher, sertifikat) dan verifikasi progres check-in GPS wisatawan.
            </p>
          </div>

          <div className="flex items-center gap-2.5 flex-wrap">
            <button
              type="button"
              onClick={handleOpenCreateModal}
              className="min-h-[46px] px-5 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center gap-2 shadow-sm transition"
            >
              <Plus className="w-4 h-4" />
              <span>Buat Tantangan Baru</span>
            </button>
          </div>
        </div>

        {/* 4 Kartu Metrik Makro */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mt-6 pt-6 border-t border-[#E4E9DA]">
          <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
            <div className="flex items-center justify-between text-[#234B24]">
              <span className="text-[11px] font-extrabold uppercase">Tantangan Aktif</span>
              <Trophy className="w-4 h-4" />
            </div>
            <div className="text-2xl font-black text-[#1B1F1A] mt-1.5">
              {totalActiveChallenges}
            </div>
            <p className="text-[11px] text-[#4A5248] mt-0.5">
              Dari total {challenges.length} master tantangan
            </p>
          </div>

          <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
            <div className="flex items-center justify-between text-[#234B24]">
              <span className="text-[11px] font-extrabold uppercase">Wisatawan Ikut Serta</span>
              <Users className="w-4 h-4" />
            </div>
            <div className="text-2xl font-black text-[#1B1F1A] mt-1.5">
              {totalParticipants.toLocaleString('id-ID')}
            </div>
            <p className="text-[11px] text-[#4A5248] mt-0.5">
              Melalui aplikasi mobile WISGO
            </p>
          </div>

          <div className="p-4 rounded-2xl bg-[#FFEDD5]/60 border border-[#FDBA74]">
            <div className="flex items-center justify-between text-[#C2410C]">
              <span className="text-[11px] font-extrabold uppercase">Siap Klaim (100% Ceklis)</span>
              <Sparkles className="w-4 h-4" />
            </div>
            <div className="text-2xl font-black text-[#C2410C] mt-1.5">
              {totalReadyToClaim} Wisatawan
            </div>
            <p className="text-[11px] text-[#9A3412] mt-0.5">
              Menunggu verifikasi &amp; serah terima hadiah
            </p>
          </div>

          <div className="p-4 rounded-2xl bg-[#CCFBF1]/60 border border-[#99F6E4]">
            <div className="flex items-center justify-between text-[#0D9488]">
              <span className="text-[11px] font-extrabold uppercase">Hadiah Berhasil Disalurkan</span>
              <CheckCircle2 className="w-4 h-4" />
            </div>
            <div className="text-2xl font-black text-[#0D9488] mt-1.5">
              {totalRewardSent} Hadiah
            </div>
            <p className="text-[11px] text-[#0F766E] mt-0.5">
              Sertifikat &amp; reward fisik/digital terkirim
            </p>
          </div>
        </div>

        {/* Sub-Tab Navigation Bar */}
        <div className="flex items-center gap-2 mt-6 pt-4 border-t border-[#E4E9DA]">
          <button
            type="button"
            onClick={() => setActiveTab('master')}
            className={`min-h-[44px] px-5 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
              activeTab === 'master'
                ? 'bg-[#234B24] !text-white shadow-sm'
                : 'bg-white !text-[#234B24] hover:bg-[#234B24]/5 border border-[#234B24]/15'
            }`}
          >
            <Trophy className="w-4 h-4" />
            <span>Tab 1: Master Challenge ({challenges.length})</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('claims')}
            className={`min-h-[44px] px-5 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
              activeTab === 'claims'
                ? 'bg-[#234B24] !text-white shadow-sm'
                : 'bg-white !text-[#234B24] hover:bg-[#234B24]/5 border border-[#234B24]/15'
            }`}
          >
            <Gift className="w-4 h-4" />
            <span>Tab 2: Verifikasi &amp; Klaim Hadiah</span>
            {totalReadyToClaim > 0 && (
              <span className="w-5 h-5 rounded-full bg-[#F26B4B] text-white text-[10px] font-black flex items-center justify-center">
                {totalReadyToClaim}
              </span>
            )}
          </button>
        </div>
      </header>

      {/* ==================================================================== */}
      {/* TAB 1: MASTER CHALLENGE                                              */}
      {/* ==================================================================== */}
      {activeTab === 'master' && (
        <section className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <h2 className="text-base font-extrabold text-[#1B1F1A]">
                Daftar Program Tantangan Wisata
              </h2>
              <p className="text-xs text-[#4A5248]">
                Tentukan target jumlah destinasi yang wajib dikunjungi wisatawan dan reward yang dijanjikan.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {challenges.map((ch) => (
              <div
                key={ch.id}
                className="p-5 rounded-2xl bg-[#F6F3EC]/70 border border-[#CFD8BE] hover:border-[#234B24] transition flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-start justify-between gap-2">
                    <span className="px-2.5 py-1 rounded-md bg-[#234B24]/10 text-[#234B24] font-extrabold text-[10px] uppercase">
                      {ch.category}
                    </span>
                    <button
                      type="button"
                      onClick={() => handleToggleActive(ch.id)}
                      className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                        ch.is_active
                          ? 'bg-[#CCFBF1] text-[#0D9488]'
                          : 'bg-[#FEE2E2] text-[#DC2626]'
                      }`}
                    >
                      {ch.is_active ? '● Aktif' : '○ Nonaktif'}
                    </button>
                  </div>

                  <h3 className="text-sm font-black text-[#1B1F1A] mt-2.5 line-clamp-2">
                    {ch.title}
                  </h3>
                  <p className="text-xs text-[#4A5248] mt-1 line-clamp-2">
                    {ch.description}
                  </p>

                  {/* Info Target & Reward */}
                  <div className="mt-4 p-3 rounded-xl bg-white border border-[#E4E9DA] space-y-2">
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-[#767676] font-medium">Target Tempat:</span>
                      <span className="font-extrabold text-[#234B24]">
                        {ch.target_count} Lokasi Destinasi
                      </span>
                    </div>
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-[#767676] font-medium">Batas Waktu:</span>
                      <span className="font-bold text-[#1B1F1A]">
                        {ch.duration_days} Hari
                      </span>
                    </div>
                    <div className="pt-2 border-t border-[#E4E9DA]">
                      <div className="text-[11px] font-bold text-[#C2410C] flex items-center gap-1.5">
                        <Gift className="w-3.5 h-3.5 shrink-0" />
                        <span>Reward: {ch.reward_description}</span>
                      </div>
                    </div>
                  </div>

                  {/* Target Destinations Chips */}
                  {ch.target_destinations && ch.target_destinations.length > 0 && (
                    <div className="mt-3">
                      <span className="text-[10px] font-bold text-[#767676] uppercase">
                        Destinasi Sasaran ({ch.target_destinations.length}):
                      </span>
                      <div className="flex flex-wrap gap-1 mt-1">
                        {ch.target_destinations.slice(0, 4).map((d, idx) => (
                          <span
                            key={idx}
                            className="px-2 py-0.5 rounded-md bg-[#234B24]/5 text-[#234B24] text-[10px] font-semibold"
                          >
                            {d}
                          </span>
                        ))}
                        {ch.target_destinations.length > 4 && (
                          <span className="px-1.5 py-0.5 text-[10px] text-[#767676] font-bold">
                            +{ch.target_destinations.length - 4} lainnya
                          </span>
                        )}
                      </div>
                    </div>
                  )}
                </div>

                {/* Footer Card */}
                <div className="mt-5 pt-3 border-t border-[#CFD8BE]/50 flex items-center justify-between">
                  <div className="flex items-center gap-3 text-[11px] text-[#4A5248]">
                    <span className="flex items-center gap-1">
                      <Users className="w-3.5 h-3.5 text-[#234B24]" />
                      <b>{ch.participant_count}</b> peserta
                    </span>
                    <span className="flex items-center gap-1">
                      <CheckCircle2 className="w-3.5 h-3.5 text-[#0D9488]" />
                      <b>{ch.completed_count}</b> tuntas
                    </span>
                  </div>

                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => handleOpenEditModal(ch)}
                      className="px-3 py-1.5 rounded-lg text-xs font-bold text-[#234B24] hover:bg-[#234B24]/10 transition"
                    >
                      <Edit3 className="w-3.5 h-3.5 inline mr-1" />
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteChallenge(ch.id)}
                      className="px-2.5 py-1.5 rounded-lg text-xs font-bold text-[#D95637] hover:bg-[#F26B4B]/10 transition"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ==================================================================== */}
      {/* TAB 2: VERIFIKASI & KLAIM HADIAH                                     */}
      {/* ==================================================================== */}
      {activeTab === 'claims' && (
        <section className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA] space-y-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h2 className="text-base font-extrabold text-[#1B1F1A]">
                Tabel Progres Ceklis &amp; Verifikasi Klaim Hadiah
              </h2>
              <p className="text-xs text-[#4A5248]">
                Pantau progres penaklukan destinasi oleh wisatawan berbasis check-in GPS. Wisatawan dengan checklist 100% siap menerima reward resmi.
              </p>
            </div>

            {/* Filter Status */}
            <div className="flex items-center gap-2 flex-wrap">
              <div className="relative">
                <Search className="w-3.5 h-3.5 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Cari nama, WhatsApp, atau tantangan..."
                  className="min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A] w-64"
                />
              </div>

              <select
                value={claimStatusFilter}
                onChange={(e) => setClaimStatusFilter(e.target.value as any)}
                className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                <option value="ALL">Semua Status Klaim</option>
                <option value="SIAP_KLAIM">Siap Klaim (100% Ceklis)</option>
                <option value="DALAM_PROGRES">Dalam Progres</option>
                <option value="HADIAH_TERKIRIM">Hadiah Terkirim</option>
              </select>
            </div>
          </div>

          {/* Tabel Progres Klaim */}
          <div className="overflow-x-auto rounded-2xl border border-[#E4E9DA]">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#F6F3EC] text-[#234B24] font-extrabold uppercase text-[10px] tracking-wider border-b border-[#CFD8BE]">
                <tr>
                  <th className="py-3.5 px-4">Wisatawan</th>
                  <th className="py-3.5 px-4">Program Tantangan</th>
                  <th className="py-3.5 px-4">Progres Ceklis</th>
                  <th className="py-3.5 px-4">Reward yang Dijanjikan</th>
                  <th className="py-3.5 px-4">Status</th>
                  <th className="py-3.5 px-4 text-right">Tindakan Admin</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E4E9DA]">
                {filteredClaims.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-10 text-center text-[#767676]">
                      Tidak ada data klaim wisatawan yang sesuai filter.
                    </td>
                  </tr>
                ) : (
                  filteredClaims.map((clm) => {
                    const completed = clm.completed_count ?? clm.progress_count ?? 0;
                    const target = clm.target_count ?? clm.target_destination_count ?? 1;
                    const progressPercent = Math.round((completed / target) * 100);
                    const is100Percent = completed >= target;

                    return (
                      <tr key={clm.id} className="hover:bg-[#F6F3EC]/40 transition">
                        <td className="py-3.5 px-4 font-bold text-[#1B1F1A]">
                          <div>{clm.tourist_name || 'Wisatawan'}</div>
                          <div className="text-[11px] font-mono text-[#767676]">
                            {clm.tourist_phone || '-'}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <div className="font-semibold text-[#1B1F1A] line-clamp-1 max-w-xs">
                            {clm.challenge_title || clm.reward}
                          </div>
                          <div className="text-[10px] text-[#767676] mt-0.5">
                            Target {target} Lokasi
                          </div>
                        </td>
                        <td className="py-3.5 px-4 min-w-[180px]">
                          <div className="flex items-center justify-between text-[11px] mb-1">
                            <span className="font-extrabold text-[#234B24]">
                              {completed}/{target} Tempat
                            </span>
                            <span className="font-bold text-[#4A5248]">
                              {progressPercent}%
                            </span>
                          </div>
                          <div className="w-full h-2 rounded-full bg-gray-200 overflow-hidden">
                            <div
                              style={{ width: `${Math.min(100, progressPercent)}%` }}
                              className={`h-full transition-all duration-300 ${
                                is100Percent ? 'bg-[#0D9488]' : 'bg-[#234B24]'
                              }`}
                            />
                          </div>
                          {/* Mini Tooltip Tempat Ceklis */}
                          <div className="text-[10px] text-[#767676] mt-1 line-clamp-1">
                            {(clm.completed_destinations || []).join(', ')}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <div className="text-[11px] font-bold text-[#C2410C] max-w-xs line-clamp-2">
                            {clm.reward_description}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          {clm.status === 'SIAP_KLAIM' && (
                            <span className="px-2.5 py-1 rounded-full text-[10px] font-extrabold bg-[#FFEDD5] text-[#C2410C] animate-pulse inline-flex items-center gap-1">
                              <Sparkles className="w-3 h-3" />
                              Siap Klaim Hadiah
                            </span>
                          )}
                          {clm.status === 'DALAM_PROGRES' && (
                            <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-gray-100 text-[#4A5248] inline-flex items-center gap-1">
                              <Clock className="w-3 h-3" />
                              Dalam Progres
                            </span>
                          )}
                          {clm.status === 'HADIAH_TERKIRIM' && (
                            <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-[#CCFBF1] text-[#0D9488] inline-flex items-center gap-1">
                              <Check className="w-3 h-3" />
                              Hadiah Terkirim
                            </span>
                          )}
                        </td>
                        <td className="py-3.5 px-4 text-right">
                          {clm.status === 'SIAP_KLAIM' ? (
                            <button
                              type="button"
                              onClick={() => {
                                setSelectedClaimForReward(clm);
                                setRewardNotesInput('');
                              }}
                              className="min-h-[36px] px-3.5 py-1.5 rounded-xl bg-[#F26B4B] hover:bg-[#D95637] text-white font-extrabold text-[11px] inline-flex items-center gap-1.5 shadow-xs transition"
                            >
                              <Gift className="w-3.5 h-3.5" />
                              <span>Kirim Hadiah</span>
                            </button>
                          ) : clm.status === 'HADIAH_TERKIRIM' ? (
                            <button
                              type="button"
                              onClick={() => {
                                alert(
                                  `Hadiah telah diserahkan pada: ${
                                    clm.reward_sent_at
                                      ? new Date(clm.reward_sent_at).toLocaleString('id-ID')
                                      : '-'
                                  }\nCatatan: ${clm.reward_notes || '-'}`
                                );
                              }}
                              className="px-3 py-1.5 rounded-lg text-[11px] font-bold text-[#0D9488] hover:bg-[#CCFBF1]/50 border border-[#99F6E4]"
                            >
                              Lihat Bukti
                            </button>
                          ) : (
                            <span className="text-[11px] text-[#767676] italic">
                              Menunggu {Math.max(0, (clm.target_count ?? clm.target_destination_count ?? 3) - (clm.completed_count ?? clm.progress_count ?? 0))} tempat lagi
                            </span>
                          )}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* ==================================================================== */}
      {/* MODAL BUAT / EDIT TANTANGAN                                          */}
      {/* ==================================================================== */}
      {isModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-xl p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[92vh] flex flex-col overflow-hidden">
            {/* Modal Header (shrink-0) */}
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA] shrink-0">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#234B24] text-white flex items-center justify-center shadow-xs">
                  <Trophy className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {editingChallenge ? 'Edit Program Tantangan' : 'Buat Tantangan Wisata Baru'}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Konsep Checklist Destinasi Berhadiah Bebas
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

            {/* Modal Body (overflow-y-auto) */}
            <form onSubmit={handleSaveChallenge} className="mt-4 space-y-4 overflow-y-auto pr-1">
              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Nama / Judul Tantangan <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  type="text"
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  placeholder="Contoh: Jelajah 10 Ikon Geopark & Lembah Harau"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Kategori Tema
                  </label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    <option value="Eksplorasi Alam & Geopark">Eksplorasi Alam & Geopark</option>
                    <option value="Pusaka & Warisan Adat">Pusaka & Warisan Adat</option>
                    <option value="Bahari & Kepulauan">Bahari & Kepulauan</option>
                    <option value="Danau & Agrowisata">Danau & Agrowisata</option>
                    <option value="Kuliner Tradisional Minang">Kuliner Tradisional Minang</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Target Tempat (Jumlah Ceklis) <span className="text-[#F26B4B]">*</span>
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={50}
                    value={formTargetCount}
                    onChange={(e) => setFormTargetCount(Number(e.target.value))}
                    required
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold text-[#1B1F1A]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Deskripsi Tantangan
                </label>
                <textarea
                  rows={2}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  placeholder="Jelaskan aturan main penaklukan rute destinasi..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div className="p-4 rounded-xl bg-[#FFEDD5]/50 border border-[#FDBA74] space-y-2">
                <label className="block text-xs font-bold text-[#C2410C]">
                  Reward / Hadiah yang Dijanjikan (Bebas) <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  type="text"
                  value={formReward}
                  onChange={(e) => setFormReward(e.target.value)}
                  placeholder="Contoh: Uang Tunai Rp 1 Juta / Voucher Wisata / Sertifikat Resmi"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#FDBA74] text-xs font-bold text-[#1B1F1A]"
                />
                <p className="text-[11px] text-[#9A3412]">
                  Checklist murni: Tidak menggunakan sistem perolehan poin. Wisatawan yang menuntaskan target checklist berhak atas reward di atas.
                </p>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Durasi Masa Berlaku (Hari)
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={365}
                    value={formDuration}
                    onChange={(e) => setFormDuration(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold text-[#1B1F1A]"
                  />
                </div>
              </div>

              {/* Pemilihan Destinasi Sasaran */}
              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1.5">
                  Pilih Destinasi Sasaran (Checklist Opsional):
                </label>
                <div className="max-h-40 overflow-y-auto p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-1.5">
                  {destinations.map((d) => {
                    const isChecked = formSelectedDests.includes(d.name);
                    return (
                      <label
                        key={d.id}
                        className="flex items-center gap-2 text-xs font-medium text-[#1B1F1A] cursor-pointer hover:bg-white/60 p-1.5 rounded-lg"
                      >
                        <input
                          type="checkbox"
                          checked={isChecked}
                          onChange={(e) => {
                            if (e.target.checked) {
                              setFormSelectedDests([...formSelectedDests, d.name]);
                            } else {
                              setFormSelectedDests(
                                formSelectedDests.filter((name) => name !== d.name)
                              );
                            }
                          }}
                          className="rounded text-[#234B24] focus:ring-[#234B24]"
                        />
                        <span>{d.name}</span>
                        <span className="text-[10px] text-[#767676]">({d.city_regency})</span>
                      </label>
                    );
                  })}
                </div>
              </div>

              {/* Modal Footer (shrink-0) */}
              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#E4E9DA] shrink-0">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm"
                >
                  <Trophy className="w-4 h-4" />
                  <span>Simpan Program Tantangan</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL SERAH TERIMA / KIRIM HADIAH                                     */}
      {/* ==================================================================== */}
      {selectedClaimForReward && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-2xl bg-[#CCFBF1] text-[#0D9488] flex items-center justify-center">
                  <Gift className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    Verifikasi &amp; Serah Hadiah Wisatawan
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Konfirmasi penyaluran reward resmi
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedClaimForReward(null)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2">
              <div className="flex justify-between text-xs">
                <span className="text-[#767676]">Nama Wisatawan:</span>
                <span className="font-extrabold text-[#1B1F1A]">
                  {selectedClaimForReward.tourist_name}
                </span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-[#767676]">WhatsApp:</span>
                <span className="font-mono font-bold text-[#234B24]">
                  {selectedClaimForReward.tourist_phone}
                </span>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-[#767676]">Tantangan:</span>
                <span className="font-semibold text-[#1B1F1A]">
                  {selectedClaimForReward.challenge_title}
                </span>
              </div>
              <div className="pt-2 border-t border-[#CFD8BE] flex justify-between text-xs">
                <span className="text-[#C2410C] font-bold">Reward Resmi:</span>
                <span className="font-extrabold text-[#C2410C]">
                  {selectedClaimForReward.reward_description}
                </span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                Catatan Penyerahan / Nomor Resi / Tanda Terima
              </label>
              <textarea
                rows={2}
                value={rewardNotesInput}
                onChange={(e) => setRewardNotesInput(e.target.value)}
                placeholder="Contoh: Voucher digital terkirim via WhatsApp dan Sertifikat cetak diserahkan di Kantor Dispar..."
                className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
              />
            </div>

            <div className="pt-3 flex items-center justify-end gap-2.5 border-t border-[#E4E9DA]">
              <button
                type="button"
                onClick={() => setSelectedClaimForReward(null)}
                className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmSendReward}
                className="min-h-[44px] px-5 py-2 rounded-xl bg-[#0D9488] hover:bg-[#0F766E] text-white text-xs font-extrabold flex items-center gap-2 shadow-sm"
              >
                <Send className="w-4 h-4" />
                <span>Kirimkan Notifikasi &amp; Tuntaskan Hadiah</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
