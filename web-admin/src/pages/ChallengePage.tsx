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
  Shield,
  CheckCheck,
  Sliders,
  ExternalLink,
  Smartphone,
  Navigation,
  Compass,
  Flame,
  Mountain,
} from 'lucide-react';
import {
  ChecklistChallenge,
  ChecklistClaimStatus,
  TouristChecklistClaim,
  Destination,
  AdventurerLevelConfig,
  UserProfileExperience,
  PostingShareTemplate,
} from '../types/contract';
import {
  AdventurerLevelsRepo,
  UserProfilesRepo,
  PostingTemplatesRepo,
} from '../services/dbRepository';
import { SEED_POSTING_TEMPLATES } from '../data/mockDatabaseV2';

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
    checkin_tagline: 'Check-In di Lokasi, Kumpulkan Lencana Ranah Minang!',
    target_count: 10,
    reward_type: 'Uang Tunai',
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
    target_checkpoints: ['Sarasah Bunta Point', 'Tebing Granit Harau', 'Skywalk Kelok 9'],
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
    checkin_tagline: 'Jelajahi Nagari Pusaka, Kumpulkan Paspor Adat!',
    target_count: 5,
    reward_type: 'Voucher',
    reward_description: 'Paket Voucher Belanja UMKM Songket Rp 750.000 + Piagam Adat',
    duration_days: 21,
    target_destinations: [
      'Istano Basa Pagaruyung',
      'Nagari Pariangan (Desa Terindah)',
      'Desa Wisata Kubu Gadang',
      'Kawasan Saribu Rumah Gadang',
      'Benteng Fort de Kock',
    ],
    target_checkpoints: ['Singgasana Balairung Sari', 'Rumah Gadang Tuo', 'Batu Tagak Pariangan'],
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
    checkin_tagline: 'Buktikan Jelajah Bahari Mandeh, Raih Reward Eksklusif!',
    target_count: 7,
    reward_type: 'Voucher',
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
    target_checkpoints: ['Dermaga Tarusan Mandeh', 'Pulau Sironjong Cliff', 'Batu Malin Kundang'],
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
    checkin_tagline: 'Dingin Ranah Solok, Ceklis 3 Ikon Utama!',
    target_count: 3,
    reward_type: 'Badge Khusus',
    reward_description: 'Merchandise Eksklusif Kopi Solok Radjo + Goodie Bag Dispar',
    duration_days: 14,
    target_destinations: [
      'Danau Diatas & Danau Dibawah',
      'Kebun Teh Alahan Panjang',
      'Danau Singkarak',
    ],
    target_checkpoints: ['Dermaga Danau Diatas', 'Bukit Cambai Viewpoint'],
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
];

export const ChallengePage: React.FC<ChallengePageProps> = ({
  destinations,
  showToast,
}) => {
  // Main Tab Navigation: 4 Modul Gamifikasi
  const [activeTab, setActiveTab] = useState<
    'checkin' | 'levels' | 'profiles' | 'templates'
  >('checkin');

  // Sub-view Tab 1: Master Tantangan vs Klaim Hadiah
  const [checkinSubView, setCheckinSubView] = useState<'challenges' | 'claims'>('challenges');

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

  // Tab 2: Adventurer Levels State
  const [adventurerLevels, setAdventurerLevels] = useState<AdventurerLevelConfig[]>(() =>
    AdventurerLevelsRepo.getAll()
  );
  const [editingLevel, setEditingLevel] = useState<AdventurerLevelConfig | null>(null);
  const [levelFormTrips, setLevelFormTrips] = useState(0);
  const [levelFormCheckpoints, setLevelFormCheckpoints] = useState(0);
  const [levelFormXp, setLevelFormXp] = useState(0);
  const [levelFormPerks, setLevelFormPerks] = useState('');
  const [levelFormTitle, setLevelFormTitle] = useState('');
  const [levelFormBadgeIcon, setLevelFormBadgeIcon] = useState('Compass');

  // Tab 3: User Profiles State
  const [userProfiles, setUserProfiles] = useState<UserProfileExperience[]>(() =>
    UserProfilesRepo.getAll()
  );
  const [profileSearchTerm, setProfileSearchTerm] = useState('');
  const [selectedUserForDetail, setSelectedUserForDetail] = useState<UserProfileExperience | null>(null);

  // Tab 4: Posting Templates State
  const [postingTemplates, setPostingTemplates] = useState<PostingShareTemplate[]>(() =>
    PostingTemplatesRepo.getAll()
  );
  const [selectedTemplate, setSelectedTemplate] = useState<PostingShareTemplate>(() =>
    postingTemplates[0] || SEED_POSTING_TEMPLATES[0]
  );
  const [templateWatermark, setTemplateWatermark] = useState(selectedTemplate.watermark_text);
  const [templateQrUrl, setTemplateQrUrl] = useState(selectedTemplate.qr_download_url);

  // Persist Challenges & Claims to LocalStorage
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
  const [formTagline, setFormTagline] = useState('Check-In di Lokasi, Kumpulkan Lencana Ranah Minang!');
  const [formDescription, setFormDescription] = useState('');
  const [formCategory, setFormCategory] = useState('Eksplorasi Alam & Geopark');
  const [formRewardType, setFormRewardType] = useState<string>('Uang Tunai');
  const [formReward, setFormReward] = useState('');
  const [formTargetCount, setFormTargetCount] = useState<number>(5);
  const [formDuration, setFormDuration] = useState<number>(30);
  const [formSelectedDests, setFormSelectedDests] = useState<string[]>([]);
  const [formSelectedCheckpoints, setFormSelectedCheckpoints] = useState<string[]>([]);

  // Search & Filter State (Tab 1)
  const [searchTerm, setSearchTerm] = useState('');
  const [claimStatusFilter, setClaimStatusFilter] = useState<'ALL' | ChecklistClaimStatus>('ALL');

  // Modal Detail Claim / Kirim Hadiah
  const [selectedClaimForReward, setSelectedClaimForReward] = useState<TouristChecklistClaim | null>(null);
  const [rewardNotesInput, setRewardNotesInput] = useState('');

  // Extract all available checkpoints across destinations
  const allAvailableCheckpoints = destinations.flatMap((d) =>
    (d.checkpoints || []).map((cp) => ({
      name: cp.name,
      destName: d.name,
      city: d.city_regency,
    }))
  );

  // Open Create Challenge Modal
  const handleOpenCreateModal = () => {
    setEditingChallenge(null);
    setFormTitle('');
    setFormTagline('Check-In di Lokasi, Kumpulkan Lencana Ranah Minang!');
    setFormDescription('');
    setFormCategory('Eksplorasi Alam & Geopark');
    setFormRewardType('Uang Tunai');
    setFormReward('');
    setFormTargetCount(5);
    setFormDuration(30);
    setFormSelectedDests([]);
    setFormSelectedCheckpoints([]);
    setIsModalOpen(true);
  };

  // Open Edit Challenge Modal
  const handleOpenEditModal = (ch: ChecklistChallenge) => {
    setEditingChallenge(ch);
    setFormTitle(ch.title);
    setFormTagline(ch.checkin_tagline || 'Check-In di Lokasi, Kumpulkan Lencana Ranah Minang!');
    setFormDescription(ch.description);
    setFormCategory(ch.category || 'Eksplorasi Alam & Geopark');
    setFormRewardType(ch.reward_type || 'Uang Tunai');
    setFormReward(ch.reward_description || ch.reward_title || '');
    setFormTargetCount(ch.target_count ?? ch.target_destination_count ?? 3);
    setFormDuration(ch.duration_days ?? 30);
    setFormSelectedDests(ch.target_destinations || []);
    setFormSelectedCheckpoints(ch.target_checkpoints || []);
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
              checkin_tagline: formTagline.trim(),
              description: formDescription.trim(),
              category: formCategory,
              reward_type: formRewardType,
              target_count: Number(formTargetCount),
              reward_description: formReward.trim(),
              duration_days: Number(formDuration),
              target_destinations: formSelectedDests,
              target_checkpoints: formSelectedCheckpoints,
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
        checkin_tagline: formTagline.trim(),
        description: formDescription.trim(),
        category: formCategory,
        reward_type: formRewardType,
        target_count: Number(formTargetCount),
        reward_description: formReward.trim(),
        duration_days: Number(formDuration),
        target_destinations: formSelectedDests,
        target_checkpoints: formSelectedCheckpoints,
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

  // Level Modal Edit Handlers
  const handleOpenEditLevel = (lvl: AdventurerLevelConfig) => {
    setEditingLevel(lvl);
    setLevelFormTitle(lvl.title);
    setLevelFormTrips(lvl.min_trips);
    setLevelFormCheckpoints(lvl.min_checkpoints);
    setLevelFormXp(lvl.min_xp);
    setLevelFormPerks(lvl.perk_description);
    setLevelFormBadgeIcon(lvl.badge_icon);
  };

  const handleSaveLevel = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingLevel) return;

    const updatedConfig: AdventurerLevelConfig = {
      ...editingLevel,
      title: levelFormTitle.trim() || editingLevel.title,
      min_trips: Number(levelFormTrips),
      min_checkpoints: Number(levelFormCheckpoints),
      min_xp: Number(levelFormXp),
      perk_description: levelFormPerks.trim() || editingLevel.perk_description,
      badge_icon: levelFormBadgeIcon,
    };

    const updatedList = AdventurerLevelsRepo.updateLevel(updatedConfig);
    setAdventurerLevels(updatedList);
    setEditingLevel(null);
    showToast(`Kriteria Level ${updatedConfig.level} (${updatedConfig.name}) berhasil diperbarui!`, 'success');
  };

  // Verify Experience Item for User Profile
  const handleVerifyExperience = (userId: string, expIdx: number) => {
    const user = userProfiles.find((u) => u.id === userId || u.user_id === userId);
    if (!user) return;

    const updatedHistory = [...user.experience_history];
    const targetItem = updatedHistory[expIdx];
    if (!targetItem) return;

    targetItem.status = 'verified';
    const updatedUser: UserProfileExperience = {
      ...user,
      total_xp: user.total_xp + (targetItem.xp_earned || 50),
      experience_history: updatedHistory,
    };

    const updatedList = UserProfilesRepo.save(updatedUser);
    setUserProfiles(updatedList);
    if (selectedUserForDetail?.id === user.id) {
      setSelectedUserForDetail(updatedUser);
    }
    showToast(`Pengalaman check-in "${targetItem.checkpoint_name || targetItem.destination_name}" terverifikasi!`, 'success');
  };

  // Save Posting Template
  const handleSavePostingTemplate = (e: React.FormEvent) => {
    e.preventDefault();
    const updatedTemplate: PostingShareTemplate = {
      ...selectedTemplate,
      watermark_text: templateWatermark.trim(),
      qr_download_url: templateQrUrl.trim(),
      qr_image_url: `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(
        templateQrUrl.trim()
      )}`,
    };

    const updatedList = PostingTemplatesRepo.save(updatedTemplate);
    setPostingTemplates(updatedList);
    setSelectedTemplate(updatedTemplate);
    showToast('Template posting media sosial & QR unduh berhasil disimpan!', 'success');
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

  // Filtered Profiles
  const filteredProfiles = userProfiles.filter((u) => {
    const q = profileSearchTerm.toLowerCase();
    return (
      u.full_name.toLowerCase().includes(q) ||
      u.email.toLowerCase().includes(q) ||
      u.level_name.toLowerCase().includes(q)
    );
  });

  const getLevelBadgeSvg = (level: number) => {
    switch (level) {
      case 1:
        return '/assets/synced/badge_level_1_beginner.svg';
      case 2:
        return '/assets/synced/badge_level_2_explorer.svg';
      case 3:
        return '/assets/synced/badge_level_3_adventurer.svg';
      case 4:
        return '/assets/synced/badge_level_4_trailblazer.svg';
      case 5:
      default:
        return '/assets/synced/badge_level_5_wanderer.svg';
    }
  };

  const renderBadgeIcon = (iconName: string) => {
    switch (iconName) {
      case 'Flame':
        return <Flame className="w-5 h-5 text-[#8B5CF6]" />;
      case 'Mountain':
        return <Mountain className="w-5 h-5 text-[#F26B4B]" />;
      case 'Award':
        return <Award className="w-5 h-5 text-[#F59E0B]" />;
      case 'MapPin':
        return <MapPin className="w-5 h-5 text-[#1E9E5A]" />;
      case 'Compass':
      default:
        return <Compass className="w-5 h-5 text-[#3B82F6]" />;
    }
  };

  return (
    <div className="space-y-6 overflow-x-hidden">
      {/* Header Halaman */}
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            Gamifikasi &amp; Check-In Challenge
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Tantangan wisata, 5 level petualang, profil experience ala Strava, dan template posting.
          </p>
        </div>

        {activeTab === 'checkin' && (
          <button
            type="button"
            onClick={handleOpenCreateModal}
            className="min-h-[40px] px-4 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center gap-2 shadow-xs transition duration-200 shrink-0"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Buat Tantangan</span>
          </button>
        )}
      </header>

      {/* 4 Kartu Metrik Makro */}
      <section
        aria-label="Metrik Gamifikasi"
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
      >
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Tantangan Aktif</span>
            <Trophy className="w-4 h-4 text-[#234B24]/70" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#234B24]">
            {totalActiveChallenges}
          </div>
          <p className="text-xs text-slate-500">
            Dari {challenges.length} program terdaftar
          </p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Wisatawan Ikut Serta</span>
            <Users className="w-4 h-4 text-[#1E9E5A]" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#234B24]">
            {totalParticipants.toLocaleString('id-ID')}
          </div>
          <p className="text-xs text-slate-500">
            Aplikasi mobile WISGO
          </p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Siap Klaim Hadiah</span>
            <Sparkles className="w-4 h-4 text-[#F26B4B]" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#F26B4B]">
            {totalReadyToClaim} Wisatawan
          </div>
          <p className="text-xs text-slate-500">
            Menunggu verifikasi Dispar
          </p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)] flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Profil Petualang</span>
            <Award className="w-4 h-4 text-[#234B24]/70" />
          </div>
          <div className="my-2 text-2xl font-bold tracking-tight text-[#234B24]">
            {userProfiles.length}
          </div>
          <p className="text-xs text-slate-500">
            5 Tingkatan level aktif
          </p>
        </div>
      </section>

      {/* 4 SUB-TAB NAVIGATION BAR */}
      <nav
        aria-label="Tab Gamifikasi"
        className="flex overflow-x-auto no-scrollbar whitespace-nowrap shrink-0 gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-2xs"
      >
        <button
          type="button"
          onClick={() => setActiveTab('checkin')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'checkin'
              ? 'bg-[#234B24] text-white shadow-xs'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
          }`}
        >
          <Trophy className="w-3.5 h-3.5" />
          <span>Check-In &amp; Tantangan</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('levels')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'levels'
              ? 'bg-[#234B24] text-white shadow-xs'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
          }`}
        >
          <Award className="w-3.5 h-3.5 text-[#F59E0B]" />
          <span>5 Level &amp; Lencana</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('profiles')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'profiles'
              ? 'bg-[#234B24] text-white shadow-xs'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
          }`}
        >
          <Users className="w-3.5 h-3.5 text-[#3B82F6]" />
          <span>Profil Experience</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('templates')}
          className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${
            activeTab === 'templates'
              ? 'bg-[#234B24] text-white shadow-xs'
              : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
          }`}
        >
          <Share2 className="w-3.5 h-3.5 text-[#F26B4B]" />
          <span>Template Share &amp; QR</span>
        </button>
      </nav>

      {/* ==================================================================== */}
      {/* TAB 1: CHECK-IN & TANTANGAN WISATA                                   */}
      {/* ==================================================================== */}
      {activeTab === 'checkin' && (
        <section className="bg-white rounded-2xl p-6 lg:p-7 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] space-y-6">
          {/* Sub-Switch: Master Tantangan vs Klaim Hadiah */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#234B24]/10">
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setCheckinSubView('challenges')}
                className={`px-4 py-1.5 rounded-lg text-xs font-extrabold transition ${
                  checkinSubView === 'challenges'
                    ? 'bg-[#234B24] text-white'
                    : 'bg-[#F6F3EC] text-[#4A5248] hover:text-[#1B1F1A]'
                }`}
              >
                Daftar Program Tantangan ({challenges.length})
              </button>
              <button
                type="button"
                onClick={() => setCheckinSubView('claims')}
                className={`px-4 py-1.5 rounded-lg text-xs font-extrabold transition flex items-center gap-1.5 ${
                  checkinSubView === 'claims'
                    ? 'bg-[#234B24] text-white'
                    : 'bg-[#F6F3EC] text-[#4A5248] hover:text-[#1B1F1A]'
                }`}
              >
                <span>Verifikasi Klaim Hadiah</span>
                {totalReadyToClaim > 0 && (
                  <span className="w-4 h-4 rounded-full bg-[#F26B4B] text-white text-[9px] flex items-center justify-center font-black">
                    {totalReadyToClaim}
                  </span>
                )}
              </button>
            </div>
            <p className="text-xs text-[#767676]">
              Setiap tantangan memiliki tagline check-in, target check point, dan pilihan reward fleksibel.
            </p>
          </div>

          {/* Sub-View: Master Program Tantangan */}
          {checkinSubView === 'challenges' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {challenges.map((ch) => (
                <div
                  key={ch.id}
                  className="p-5 rounded-2xl bg-[#F6F3EC]/70 border border-[#CFD8BE] hover:border-[#234B24] transition flex flex-col justify-between space-y-4"
                >
                  <div className="space-y-2.5">
                    <div className="flex items-start justify-between gap-2">
                      <span className="px-2.5 py-1 rounded-md bg-[#234B24]/10 text-[#234B24] font-extrabold text-[10px] uppercase">
                        {ch.category || 'Eksplorasi Alam'}
                      </span>
                      <span className="px-2 py-0.5 rounded-md bg-[#3B82F6]/10 text-[#2563EB] font-bold text-[10px]">
                        Reward: {ch.reward_type || 'Bebas'}
                      </span>
                    </div>

                    {/* Tagline Khusus Check-In */}
                    <div className="p-2.5 rounded-xl bg-white border border-[#CFD8BE]/80 text-[11px] font-bold text-[#234B24] flex items-center gap-2">
                      <Sparkles className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" />
                      <span>{ch.checkin_tagline || 'Check-In di Lokasi, Kumpulkan Lencana Ranah Minang!'}</span>
                    </div>

                    <h3 className="text-base font-extrabold text-[#1B1F1A]">
                      {ch.title}
                    </h3>

                    <p className="text-xs text-[#4A5248] line-clamp-2">
                      {ch.description}
                    </p>

                    {/* Target Checkpoints Chips */}
                    {ch.target_checkpoints && ch.target_checkpoints.length > 0 && (
                      <div className="space-y-1">
                        <span className="text-[10px] font-bold text-[#767676] uppercase">
                          Target Check Point Lokasi ({ch.target_checkpoints.length}):
                        </span>
                        <div className="flex flex-wrap gap-1">
                          {ch.target_checkpoints.map((cp, idx) => (
                            <span
                              key={idx}
                              className="px-2 py-0.5 rounded-md bg-[#E4E9DA] text-[#234B24] font-bold text-[10px]"
                            >
                              📍 {cp}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    <div className="p-3 rounded-xl bg-[#FFEDD5]/60 border border-[#FDBA74] text-xs">
                      <span className="font-extrabold text-[#9A3412] block">
                        🎁 Hadiah: {ch.reward_description || ch.reward_title}
                      </span>
                      <span className="text-[11px] text-[#C2410C] mt-0.5 block">
                        Target: {ch.target_count ?? ch.target_destination_count} Tempat • Durasi: {ch.duration_days ?? 30} Hari
                      </span>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-[#CFD8BE] flex items-center justify-between">
                    <button
                      type="button"
                      onClick={() => handleToggleActive(ch.id)}
                      className={`px-3 py-1 rounded-full text-xs font-bold transition ${
                        ch.is_active
                          ? 'bg-[#1E9E5A]/15 text-[#166534]'
                          : 'bg-gray-200 text-[#767676]'
                      }`}
                    >
                      {ch.is_active ? 'Tantangan Aktif' : 'Non-Aktif'}
                    </button>

                    <div className="flex items-center gap-1.5">
                      <button
                        type="button"
                        onClick={() => handleOpenEditModal(ch)}
                        className="p-2 rounded-xl text-[#234B24] hover:bg-[#234B24]/10 transition"
                        title="Edit Tantangan"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDeleteChallenge(ch.id)}
                        className="p-2 rounded-xl text-red-600 hover:bg-red-50 transition"
                        title="Hapus Tantangan"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Sub-View: Verifikasi Klaim Hadiah */}
          {checkinSubView === 'claims' && (
            <div className="space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="relative flex-1 max-w-sm">
                  <Search className="w-4 h-4 absolute left-3.5 top-3 text-[#767676]" />
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    placeholder="Cari nama atau telepon wisatawan..."
                    className="w-full pl-9 pr-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium"
                  />
                </div>
                <div className="flex items-center gap-2">
                  <select
                    value={claimStatusFilter}
                    onChange={(e) => setClaimStatusFilter(e.target.value as any)}
                    className="px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    <option value="ALL">Semua Status Klaim</option>
                    <option value="SIAP_KLAIM">Siap Klaim (Menunggu)</option>
                    <option value="HADIAH_TERKIRIM">Hadiah Terkirim</option>
                    <option value="DALAM_PROGRES">Dalam Progres</option>
                  </select>
                </div>
              </div>

              <div className="overflow-x-auto rounded-2xl border border-[#CFD8BE]">
                <table className="w-full text-left text-xs">
                  <thead className="bg-[#234B24] text-[#F6F3EC] font-bold">
                    <tr>
                      <th className="py-3 px-4">Wisatawan</th>
                      <th className="py-3 px-4">Tantangan</th>
                      <th className="py-3 px-4">Progress Check-In</th>
                      <th className="py-3 px-4">Reward</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4 text-right">Tindakan</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E4E9DA]">
                    {filteredClaims.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="py-6 text-center text-[#767676]">
                          Tidak ada data klaim hadiah sesuai filter.
                        </td>
                      </tr>
                    ) : (
                      filteredClaims.map((clm) => (
                        <tr key={clm.id} className="hover:bg-[#F6F3EC]/50">
                          <td className="py-3 px-4">
                            <span className="font-extrabold text-[#1B1F1A] block">
                              {clm.tourist_name}
                            </span>
                            <span className="text-[10px] text-[#767676] font-mono">
                              {clm.tourist_phone}
                            </span>
                          </td>
                          <td className="py-3 px-4 font-medium text-[#1B1F1A]">
                            {clm.challenge_title}
                          </td>
                          <td className="py-3 px-4">
                            <span className="font-bold text-[#234B24]">
                              {clm.completed_count} / {clm.target_count} Titik
                            </span>
                          </td>
                          <td className="py-3 px-4 text-[#C2410C] font-extrabold">
                            {clm.reward_description}
                          </td>
                          <td className="py-3 px-4">
                            <span
                              className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                                clm.status === 'SIAP_KLAIM'
                                  ? 'bg-[#FFEDD5] text-[#C2410C] animate-pulse'
                                  : clm.status === 'HADIAH_TERKIRIM'
                                  ? 'bg-[#CCFBF1] text-[#0D9488]'
                                  : 'bg-gray-100 text-[#4A5248]'
                              }`}
                            >
                              {clm.status}
                            </span>
                          </td>
                          <td className="py-3 px-4 text-right">
                            {clm.status === 'SIAP_KLAIM' && (
                              <button
                                type="button"
                                onClick={() => {
                                  setSelectedClaimForReward(clm);
                                  setRewardNotesInput('');
                                }}
                                className="px-3 py-1.5 rounded-xl bg-[#F26B4B] hover:bg-[#D95637] text-white font-extrabold text-[11px] shadow-xs"
                              >
                                Serahkan Hadiah
                              </button>
                            )}
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </section>
      )}

      {/* ==================================================================== */}
      {/* TAB 2: 5 LEVEL & LENCANA PETUALANG                                   */}
      {/* ==================================================================== */}
      {activeTab === 'levels' && (
        <section className="bg-white rounded-2xl p-6 lg:p-7 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#234B24]/10">
            <div>
              <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Award className="w-5 h-5 text-[#F59E0B]" />
                <span>Konfigurasi 5 Tingkatan Level &amp; Lencana Petualang WISGO</span>
              </h2>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Standar resmi gamifikasi: Beginner, Explorer, Adventurer, Trailblazer, dan Wanderer. Kriteria dapat disesuaikan oleh admin.
              </p>
            </div>
            <span className="text-xs font-bold px-3 py-1 rounded-xl bg-[#234B24]/10 text-[#234B24]">
              5 Level Terstandar
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {adventurerLevels.map((lvl) => (
              <div
                key={lvl.level}
                className="p-5 rounded-3xl border-2 border-[#CFD8BE] hover:border-[#234B24] transition bg-[#F6F3EC]/50 flex flex-col justify-between space-y-4"
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span
                      className="px-3 py-1 rounded-full text-xs font-black text-white shadow-xs"
                      style={{ backgroundColor: lvl.badge_color || '#234B24' }}
                    >
                      LEVEL {lvl.level}
                    </span>
                    <div className="w-14 h-16 flex items-center justify-center">
                      <img
                        src={getLevelBadgeSvg(lvl.level)}
                        alt={lvl.name}
                        className="w-full h-full object-contain drop-shadow-sm hover:scale-105 transition"
                      />
                    </div>
                  </div>

                  <div>
                    <h3 className="text-lg font-black text-[#1B1F1A]">
                      {lvl.name}
                    </h3>
                    <div className="text-xs font-extrabold text-[#234B24] mt-0.5">
                      Lencana: "{lvl.title}"
                    </div>
                  </div>

                  {/* Kriteria Ambang Batas */}
                  <div className="p-3.5 rounded-2xl bg-white border border-[#234B24]/10 space-y-2 text-xs">
                    <div className="flex justify-between items-center">
                      <span className="text-[#767676]">Min. Trip Selesai:</span>
                      <strong className="text-[#1B1F1A] font-mono">{lvl.min_trips} Trip</strong>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-[#767676]">Min. Check Point:</span>
                      <strong className="text-[#1B1F1A] font-mono">{lvl.min_checkpoints} Titik</strong>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-[#767676]">Min. XP Dibutuhkan:</span>
                      <strong className="text-[#234B24] font-mono">{lvl.min_xp} XP</strong>
                    </div>
                  </div>

                  {/* Keistimewaan / Perks */}
                  <div className="p-3 rounded-xl bg-[#E4E9DA]/50 text-xs text-[#234B24]">
                    <strong>Hak Istimewa:</strong> {lvl.perk_description}
                  </div>
                </div>

                <div className="pt-3 border-t border-[#CFD8BE]">
                  <button
                    type="button"
                    onClick={() => handleOpenEditLevel(lvl)}
                    className="w-full min-h-[40px] px-3 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold flex items-center justify-center gap-1.5 transition"
                  >
                    <Sliders className="w-3.5 h-3.5" />
                    <span>Ubah Kriteria Level {lvl.level}</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ==================================================================== */}
      {/* TAB 3: PROFIL & EXPERIENCE PENGGUNA (STRAVA-STYLE)                   */}
      {/* ==================================================================== */}
      {activeTab === 'profiles' && (
        <section className="bg-white rounded-2xl p-6 lg:p-7 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#234B24]/10">
            <div>
              <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Users className="w-5 h-5 text-[#3B82F6]" />
                <span>Direktori Profil Petualang &amp; Experience Pengguna (Strava-Style)</span>
              </h2>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Pantau statistik perjalanan, verifikasi akun Google wisatawan, dan validasi klaim experience check-in.
              </p>
            </div>
            <div className="relative max-w-xs w-full">
              <Search className="w-4 h-4 absolute left-3 top-2.5 text-[#767676]" />
              <input
                type="text"
                value={profileSearchTerm}
                onChange={(e) => setProfileSearchTerm(e.target.value)}
                placeholder="Cari nama atau email..."
                className="w-full pl-9 pr-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {filteredProfiles.map((user) => (
              <div
                key={user.id}
                className="p-5 rounded-3xl border border-[#CFD8BE] bg-[#F6F3EC]/50 hover:border-[#234B24] transition flex flex-col justify-between space-y-4 shadow-xs"
              >
                <div className="space-y-3.5">
                  {/* Avatar & Identitas */}
                  <div className="flex items-start gap-3">
                    <img
                      src={user.google_avatar || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80'}
                      alt={user.full_name}
                      className="w-12 h-12 rounded-2xl object-cover border-2 border-[#234B24]"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <h3 className="text-sm font-black text-[#1B1F1A] truncate">
                          {user.full_name}
                        </h3>
                        {user.is_google_auth && (
                          <span className="px-1.5 py-0.5 rounded text-[9px] font-black bg-blue-100 text-blue-700 flex items-center gap-0.5">
                            <Shield className="w-2.5 h-2.5" />
                            <span>Google Verified</span>
                          </span>
                        )}
                      </div>
                      <span className="text-[11px] text-[#767676] block truncate">
                        {user.email}
                      </span>
                      <div className="flex items-center gap-2 mt-1.5">
                        <img
                          src={getLevelBadgeSvg(user.current_level)}
                          alt=""
                          className="w-5 h-6 object-contain shrink-0"
                        />
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-[#234B24]/10 text-[#234B24]">
                          Level {user.current_level}: {user.level_name}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Statistik ala Strava (4 Kolom Mini) */}
                  <div className="grid grid-cols-2 gap-2 text-center">
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Total Trip</span>
                      <strong className="text-sm font-black text-[#1B1F1A]">
                        {user.total_trips}
                      </strong>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Check Point</span>
                      <strong className="text-sm font-black text-[#1B1F1A]">
                        {user.total_checkpoints}
                      </strong>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Jarak Tempuh</span>
                      <strong className="text-sm font-black text-[#F26B4B]">
                        {user.total_distance_km} km
                      </strong>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Total XP</span>
                      <strong className="text-sm font-black text-[#234B24]">
                        {user.total_xp} XP
                      </strong>
                    </div>
                  </div>

                  {/* Cuplikan Riwayat Terakhir */}
                  <div className="space-y-1.5">
                    <span className="text-[10px] font-black uppercase text-[#4A5248] block">
                      Riwayat Experience Terakhir:
                    </span>
                    {user.experience_history.slice(0, 2).map((exp, idx) => (
                      <div
                        key={idx}
                        className="p-2.5 rounded-xl bg-white border border-[#234B24]/10 text-xs flex items-center justify-between gap-2"
                      >
                        <div className="min-w-0">
                          <strong className="text-[#1B1F1A] block truncate">
                            {exp.destination_name}
                          </strong>
                          <span className="text-[10px] text-[#767676]">
                            {exp.checkpoint_name || 'Check-in'} • {exp.date}
                          </span>
                        </div>
                        <span className="font-extrabold text-[11px] text-[#234B24] shrink-0">
                          +{exp.xp_earned} XP
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="pt-3 border-t border-[#CFD8BE]">
                  <button
                    type="button"
                    onClick={() => setSelectedUserForDetail(user)}
                    className="w-full min-h-[40px] px-3 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold flex items-center justify-center gap-1.5 transition"
                  >
                    <FileCheck className="w-3.5 h-3.5" />
                    <span>Lihat &amp; Validasi Experience ({user.experience_history.length})</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ==================================================================== */}
      {/* TAB 4: TEMPLATE POSTING & QR UNDUH                                   */}
      {/* ==================================================================== */}
      {activeTab === 'templates' && (
        <section className="bg-white rounded-2xl p-6 lg:p-7 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#234B24]/10">
            <div>
              <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Share2 className="w-5 h-5 text-[#F26B4B]" />
                <span>Template Posting Media Sosial &amp; QR Unduh Aplikasi</span>
              </h2>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Konfigurasi watermark branding resmi WISGO dan tautan QR code unduh aplikasi saat wisatawan membagikan pencapaian ke media sosial.
              </p>
            </div>
            <span className="text-xs font-bold px-3 py-1 rounded-xl bg-[#F26B4B]/10 text-[#F26B4B]">
              Viralitas Organik
            </span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {/* Form Editor Pengaturan Template */}
            <div className="lg:col-span-6 space-y-4">
              <form onSubmit={handleSavePostingTemplate} className="space-y-4 p-5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
                <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                  Pengaturan Materi Promosi &amp; Unduh
                </h3>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Pilih Template Posting
                  </label>
                  <select
                    value={selectedTemplate.id}
                    onChange={(e) => {
                      const found = postingTemplates.find((t) => t.id === e.target.value);
                      if (found) {
                        setSelectedTemplate(found);
                        setTemplateWatermark(found.watermark_text);
                        setTemplateQrUrl(found.qr_download_url);
                      }
                    }}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
                  >
                    {postingTemplates.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.template_name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Teks Watermark Resmi
                  </label>
                  <input
                    type="text"
                    value={templateWatermark}
                    onChange={(e) => setTemplateWatermark(e.target.value)}
                    placeholder="Contoh: WISGO • Ekosistem Wisata Pintar Sumatera Barat"
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
                  />
                  <span className="text-[10px] text-[#767676] mt-1 block">
                    Watermark tercetak otomatis di bagian bawah materi foto postingan wisatawan.
                  </span>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    URL Target QR Code Unduh Aplikasi
                  </label>
                  <input
                    type="url"
                    value={templateQrUrl}
                    onChange={(e) => setTemplateQrUrl(e.target.value)}
                    placeholder="https://wisgo.sumbarprov.go.id/download-app"
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-mono"
                  />
                  <span className="text-[10px] text-[#767676] mt-1 block">
                    Pindai QR akan mengarahkan pengguna baru langsung ke Play Store / App Store.
                  </span>
                </div>

                <div className="pt-2">
                  <button
                    type="submit"
                    className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold flex items-center gap-2 shadow-sm transition"
                  >
                    <CheckCheck className="w-4 h-4" />
                    <span>Simpan Pengaturan Template</span>
                  </button>
                </div>
              </form>
            </div>

            {/* Live Interactive Preview Card */}
            <div className="lg:col-span-6 flex justify-center">
              <div className="w-full max-w-sm rounded-[32px] overflow-hidden border-4 border-[#234B24] shadow-2xl bg-[#1B3A1C] text-white p-6 space-y-5">
                {/* Header Mock Card */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-xl bg-[#F26B4B] flex items-center justify-center font-black text-sm">
                      W
                    </div>
                    <div>
                      <h4 className="text-xs font-black tracking-wide">WISGO SUMBAR</h4>
                      <span className="text-[9px] text-[#CFD8BE]">Pencapaian Petualang</span>
                    </div>
                  </div>
                  <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-white/20">
                    STATUS RESMI
                  </span>
                </div>

                {/* Body Banner Card */}
                <div className="relative rounded-2xl overflow-hidden aspect-4/3 bg-black/40 border border-white/10 flex flex-col justify-end p-4">
                  <img
                    src={selectedTemplate.background_banner_url || 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=1000&q=80'}
                    alt="Preview Background"
                    className="absolute inset-0 w-full h-full object-cover opacity-60"
                  />
                  <div className="relative z-10 space-y-1">
                    <span className="px-2 py-0.5 rounded text-[9px] font-black bg-[#F59E0B] text-black inline-block">
                      LEVEL 3 ADVENTURER
                    </span>
                    <h3 className="text-base font-black leading-tight text-white drop-shadow-md">
                      Rian Pratama Baru Saja Menaklukkan Lembah Harau!
                    </h3>
                    <p className="text-[10px] text-white/90">
                      8 Trip Selesai • 22 Check Point Terkunjungi • 1.150 XP
                    </p>
                  </div>
                </div>

                {/* QR Code & Watermark Box */}
                <div className="p-3.5 rounded-2xl bg-white/10 border border-white/15 flex items-center justify-between gap-3">
                  <div className="space-y-0.5">
                    <span className="text-[10px] font-extrabold text-[#F26B4B] block uppercase tracking-wider">
                      Unduh WISGO Sekarang
                    </span>
                    <p className="text-[9px] text-[#CFD8BE] leading-snug">
                      Pindai QR ini untuk ikut menjelajah &amp; kumpulkan lencana Minangkabau!
                    </p>
                  </div>
                  <img
                    src={selectedTemplate.qr_image_url || 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://wisgo.sumbarprov.go.id/app'}
                    alt="QR Code Unduh"
                    className="w-16 h-16 rounded-xl bg-white p-1 shrink-0"
                  />
                </div>

                {/* Footer Watermark */}
                <div className="text-center pt-2 border-t border-white/10">
                  <span className="text-[10px] font-mono tracking-wider text-white/80">
                    {templateWatermark}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </section>
      )}

      {/* ==================================================================== */}
      {/* MODAL BUAT / EDIT TANTANGAN (TAB 1)                                   */}
      {/* ==================================================================== */}
      {isModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-xl p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 max-h-[92vh] flex flex-col overflow-hidden">
            <div className="flex items-center justify-between pb-4 border-b border-[#234B24]/10 shrink-0">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#234B24] text-white flex items-center justify-center shadow-xs">
                  <Trophy className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {editingChallenge ? 'Edit Program Tantangan' : 'Buat Tantangan Wisata Baru'}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Konsep Check-In Lokasi &amp; Pilihan Reward Fleksibel
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

              {/* Tagline Khusus Check-In */}
              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Tagline Khusus Check-In (Aplikasi Mobile)
                </label>
                <input
                  type="text"
                  value={formTagline}
                  onChange={(e) => setFormTagline(e.target.value)}
                  placeholder="Contoh: Check-In di Lokasi, Kumpulkan Lencana Ranah Minang!"
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-semibold text-[#234B24]"
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
                    <option value="Eksplorasi Alam & Geopark">Eksplorasi Alam &amp; Geopark</option>
                    <option value="Pusaka & Warisan Adat">Pusaka &amp; Warisan Adat</option>
                    <option value="Bahari & Kepulauan">Bahari &amp; Kepulauan</option>
                    <option value="Danau & Agrowisata">Danau &amp; Agrowisata</option>
                    <option value="Kuliner Tradisional Minang">Kuliner Tradisional Minang</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Jenis Reward Fleksibel
                  </label>
                  <select
                    value={formRewardType}
                    onChange={(e) => setFormRewardType(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  >
                    <option value="XP">XP (Experience Points)</option>
                    <option value="Poin">Poin</option>
                    <option value="Badge Khusus">Badge Khusus</option>
                    <option value="Sertifikat">Sertifikat Resmi</option>
                    <option value="Voucher">Voucher Belanja UMKM</option>
                    <option value="Uang Tunai">Uang Tunai</option>
                  </select>
                </div>
              </div>

              <div className="p-4 rounded-xl bg-[#FFEDD5]/50 border border-[#FDBA74] space-y-2">
                <label className="block text-xs font-bold text-[#C2410C]">
                  Detail / Deskripsi Hadiah <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  type="text"
                  value={formReward}
                  onChange={(e) => setFormReward(e.target.value)}
                  placeholder="Contoh: Uang Tunai Rp 1.500.000 + Sertifikat Penjelajah Geopark"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#FDBA74] text-xs font-bold text-[#1B1F1A]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
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

              {/* Target Check Points Selection */}
              {allAvailableCheckpoints.length > 0 && (
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1.5">
                    Pilih Target Check Point Lokasi Spesifik:
                  </label>
                  <div className="max-h-36 overflow-y-auto p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-1.5">
                    {allAvailableCheckpoints.map((cp, idx) => {
                      const isChecked = formSelectedCheckpoints.includes(cp.name);
                      return (
                        <label
                          key={idx}
                          className="flex items-center gap-2 text-xs font-medium text-[#1B1F1A] cursor-pointer hover:bg-white/60 p-1.5 rounded-lg"
                        >
                          <input
                            type="checkbox"
                            checked={isChecked}
                            onChange={(e) => {
                              if (e.target.checked) {
                                setFormSelectedCheckpoints([...formSelectedCheckpoints, cp.name]);
                              } else {
                                setFormSelectedCheckpoints(
                                  formSelectedCheckpoints.filter((name) => name !== cp.name)
                                );
                              }
                            }}
                            className="rounded text-[#234B24] focus:ring-[#234B24]"
                          />
                          <span>📍 {cp.name}</span>
                          <span className="text-[10px] text-[#767676]">({cp.destName})</span>
                        </label>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Pemilihan Destinasi Sasaran */}
              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1.5">
                  Pilih Destinasi Sasaran (Checklist):
                </label>
                <div className="max-h-36 overflow-y-auto p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-1.5">
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

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10 shrink-0">
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
      {/* MODAL EDIT KRITERIA LEVEL PETUALANG (TAB 2)                          */}
      {/* ==================================================================== */}
      {editingLevel && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#234B24]/10">
              <div className="flex items-center gap-2.5">
                <div className="w-10 h-10 rounded-2xl bg-[#234B24] text-white flex items-center justify-center">
                  <Award className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    Edit Kriteria Level {editingLevel.level}: {editingLevel.name}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Atur ambang batas kenaikan tingkat wisatawan
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setEditingLevel(null)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveLevel} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Nama Gelar / Lencana
                </label>
                <input
                  type="text"
                  value={levelFormTitle}
                  onChange={(e) => setLevelFormTitle(e.target.value)}
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                  required
                />
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Min. Trip
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={levelFormTrips}
                    onChange={(e) => setLevelFormTrips(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Min. Checkpoint
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={levelFormCheckpoints}
                    onChange={(e) => setLevelFormCheckpoints(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                    Min. XP
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={levelFormXp}
                    onChange={(e) => setLevelFormXp(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#1B1F1A] mb-1">
                  Hak Istimewa / Perks Level
                </label>
                <textarea
                  rows={3}
                  value={levelFormPerks}
                  onChange={(e) => setLevelFormPerks(e.target.value)}
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium"
                />
              </div>

              <div className="pt-3 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10">
                <button
                  type="button"
                  onClick={() => setEditingLevel(null)}
                  className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold"
                >
                  Simpan Kriteria Level
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL DETAIL & VALIDASI RIWAYAT EXPERIENCE (TAB 3)                   */}
      {/* ==================================================================== */}
      {selectedUserForDetail && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-2xl p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 max-h-[90vh] flex flex-col overflow-hidden">
            <div className="flex items-center justify-between pb-4 border-b border-[#234B24]/10 shrink-0">
              <div className="flex items-center gap-3">
                <img
                  src={selectedUserForDetail.google_avatar || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80'}
                  alt={selectedUserForDetail.full_name}
                  className="w-10 h-10 rounded-xl object-cover border"
                />
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {selectedUserForDetail.full_name}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Level {selectedUserForDetail.current_level} ({selectedUserForDetail.level_name}) • Total XP: {selectedUserForDetail.total_xp}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setSelectedUserForDetail(null)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="mt-4 space-y-3 overflow-y-auto pr-1">
              <span className="text-xs font-extrabold text-[#234B24] block">
                Daftar Riwayat Check-In &amp; Status Validasi:
              </span>

              {selectedUserForDetail.experience_history.map((exp, idx) => (
                <div
                  key={idx}
                  className="p-3.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between gap-3 text-xs"
                >
                  <div className="space-y-0.5">
                    <strong className="text-sm font-extrabold text-[#1B1F1A] block">
                      {exp.destination_name}
                    </strong>
                    <div className="text-[11px] text-[#4A5248]">
                      Titik: 📍 {exp.checkpoint_name || 'Lokasi Destinasi'} • Tanggal: {exp.date}
                    </div>
                    {exp.notes && (
                      <div className="text-[11px] text-[#767676] italic">
                        "{exp.notes}"
                      </div>
                    )}
                  </div>

                  <div className="flex items-center gap-2.5 shrink-0">
                    <span className="font-mono font-black text-[#234B24]">
                      +{exp.xp_earned} XP
                    </span>
                    {exp.status === 'verified' ? (
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 flex items-center gap-1">
                        <CheckCheck className="w-3 h-3 text-emerald-600" />
                        <span>Valid</span>
                      </span>
                    ) : (
                      <button
                        type="button"
                        onClick={() => handleVerifyExperience(selectedUserForDetail.id, idx)}
                        className="px-3 py-1 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-[11px] font-bold shadow-xs transition"
                      >
                        Verifikasi Klaim
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-3 border-t border-[#234B24]/10 flex justify-end shrink-0">
              <button
                type="button"
                onClick={() => setSelectedUserForDetail(null)}
                className="px-4 py-2 rounded-xl bg-gray-100 hover:bg-gray-200 text-xs font-bold text-[#1B1F1A]"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL SERAH TERIMA HADIAH (TAB 1)                                    */}
      {/* ==================================================================== */}
      {selectedClaimForReward && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#234B24]/10">
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

            <div className="pt-3 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10">
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
