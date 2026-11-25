import React, { useMemo, useState } from 'react';
import {
  Award,
  CheckCheck,
  CheckCircle2,
  Edit3,
  FileCheck,
  MapPin,
  Plus,
  Search,
  Share2,
  Shield,
  Sliders,
  Sparkles,
  Stamp,
  Trash2,
  Trophy,
  Users,
  X,
} from 'lucide-react';
import {
  AdventurerLevelConfig,
  Challenge,
  Destination,
  JejakWisgoSource,
  PostingShareTemplate,
  UserChallengeReward,
  UserProfileExperience,
} from '../types/contract';
import {
  AdventurerLevelsRepo,
  ChallengesRepo,
  PassportSpotsRepo,
  PostingTemplatesRepo,
  StempVisitsRepo,
  UserChallengeRewardsRepo,
  UserProfilesRepo,
} from '../services/dbRepository';
import {
  MASTER_DESTINATION_CATEGORIES,
  calculateAdventurerLevel,
} from '../data/mockDestinations';

interface ChallengePageProps {
  destinations: Destination[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const SOURCE_LABELS: Record<JejakWisgoSource, { label: string; color: string }> = {
  GPS_CHECKIN: { label: 'Check-in GPS', color: 'bg-emerald-100 text-emerald-800' },
  TRIP_GO: { label: 'Trip Go', color: 'bg-blue-100 text-blue-800' },
  TICKET_SCAN: { label: 'Scan Tiket QR', color: 'bg-amber-100 text-amber-800' },
};

export const ChallengePage: React.FC<ChallengePageProps> = ({
  destinations,
  showToast,
}) => {
  const [activeTab, setActiveTab] = useState<'checkin' | 'levels' | 'profiles' | 'templates'>(
    'checkin'
  );
  const [checkinSubView, setCheckinSubView] = useState<'challenges' | 'claims'>('challenges');

  // Tab 1: Challenges & Claims (Unified V3 Repos)
  const [challenges, setChallenges] = useState<Challenge[]>(() => ChallengesRepo.getAll());
  const [claims, setClaims] = useState<UserChallengeReward[]>(() =>
    UserChallengeRewardsRepo.getAll()
  );

  // Tab 2: 5 Levels & 10-Spot Digital Passport
  const [adventurerLevels, setAdventurerLevels] = useState<AdventurerLevelConfig[]>(() =>
    AdventurerLevelsRepo.getAll()
  );
  const passportSpots = useMemo(() => PassportSpotsRepo.getAll(), []);
  const stempVisits = useMemo(() => StempVisitsRepo.getAll(), []);
  const [editingLevel, setEditingLevel] = useState<AdventurerLevelConfig | null>(null);
  const [levelFormTitle, setLevelFormTitle] = useState('');
  const [levelFormTrips, setLevelFormTrips] = useState(0);
  const [levelFormCheckpoints, setLevelFormCheckpoints] = useState(0);
  const [levelFormXp, setLevelFormXp] = useState(0);
  const [levelFormMaxXp, setLevelFormMaxXp] = useState(300);
  const [levelFormPerks, setLevelFormPerks] = useState('');

  // Tab 3: Jejak WISGO Profiles
  const [userProfiles, setUserProfiles] = useState<UserProfileExperience[]>(() =>
    UserProfilesRepo.getAll()
  );
  const [selectedPassportUserId, setSelectedPassportUserId] = useState<string>(
    () => UserProfilesRepo.getAll()[0]?.user_id || 'usr-tourist-01'
  );
  const [profileSearchTerm, setProfileSearchTerm] = useState('');
  const [sourceFilter, setSourceFilter] = useState<'ALL' | JejakWisgoSource>('ALL');
  const [selectedUserForDetail, setSelectedUserForDetail] =
    useState<UserProfileExperience | null>(null);

  // Tab 4: Jejak WISGO Share Templates
  const [postingTemplates, setPostingTemplates] = useState<PostingShareTemplate[]>(() =>
    PostingTemplatesRepo.getAll()
  );
  const [selectedTemplate, setSelectedTemplate] = useState<PostingShareTemplate>(
    () => PostingTemplatesRepo.getAll()[0]
  );
  const [templateWatermark, setTemplateWatermark] = useState(
    () => PostingTemplatesRepo.getAll()[0]?.watermark_text || ''
  );
  const [templateQrUrl, setTemplateQrUrl] = useState(
    () => PostingTemplatesRepo.getAll()[0]?.qr_download_url || ''
  );
  const [previewUserId, setPreviewUserId] = useState<string>(
    () => UserProfilesRepo.getAll()[0]?.id || 'uprof-001'
  );

  // Challenge Modal Form
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingChallenge, setEditingChallenge] = useState<Challenge | null>(null);
  const [formTitle, setFormTitle] = useState('');
  const [formTagline, setFormTagline] = useState('Kumpulkan Stempel Paspor Digital Minang!');
  const [formDescription, setFormDescription] = useState('');
  const [formCategory, setFormCategory] = useState<string>('Alam & Geopark');
  const [formRewardType, setFormRewardType] = useState<string>('Sertifikat & XP');
  const [formReward, setFormReward] = useState('');
  const [formRewardPoints, setFormRewardPoints] = useState<number>(300);
  const [formTargetCount, setFormTargetCount] = useState<number>(5);
  const [formDuration, setFormDuration] = useState<number>(60);
  const [formSelectedDests, setFormSelectedDests] = useState<string[]>([]);

  // Claim Filters & Reward Modal
  const [searchTerm, setSearchTerm] = useState('');
  const [claimStatusFilter, setClaimStatusFilter] = useState<
    'ALL' | 'DALAM_PROGRES' | 'SIAP_KLAIM' | 'HADIAH_TERKIRIM'
  >('ALL');
  const [selectedClaimForReward, setSelectedClaimForReward] =
    useState<UserChallengeReward | null>(null);
  const [rewardNotesInput, setRewardNotesInput] = useState('');

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

  const handleOpenCreateModal = () => {
    setEditingChallenge(null);
    setFormTitle('');
    setFormTagline('Kumpulkan Stempel Paspor Digital Minang!');
    setFormDescription('');
    setFormCategory('Alam & Geopark');
    setFormRewardType('Sertifikat & XP');
    setFormReward('');
    setFormRewardPoints(350);
    setFormTargetCount(5);
    setFormDuration(60);
    setFormSelectedDests([]);
    setIsModalOpen(true);
  };

  const handleOpenEditModal = (ch: Challenge) => {
    setEditingChallenge(ch);
    setFormTitle(ch.title);
    setFormTagline(ch.checkin_tagline || '');
    setFormDescription(ch.description);
    setFormCategory(ch.category || 'Alam & Geopark');
    setFormRewardType(ch.reward_type || 'Sertifikat & XP');
    setFormReward(ch.reward_title);
    setFormRewardPoints(ch.reward_points || 300);
    setFormTargetCount(ch.target_destination_count);
    setFormDuration(ch.duration_days || 60);
    setFormSelectedDests(ch.target_destinations || []);
    setIsModalOpen(true);
  };

  const handleSaveChallenge = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim() || !formReward.trim()) {
      showToast('Judul tantangan dan deskripsi reward wajib diisi.', 'warning');
      return;
    }

    const nextChallenge: Challenge = {
      id: editingChallenge ? editingChallenge.id : `chl-${Date.now().toString(36)}`,
      created_by_admin_id: 'usr-admin-01',
      title: formTitle.trim(),
      checkin_tagline: formTagline.trim(),
      category: formCategory,
      description: formDescription.trim(),
      target_destination_count: Number(formTargetCount),
      reward_title: formReward.trim(),
      reward_type: formRewardType,
      reward_points: Number(formRewardPoints),
      duration_days: Number(formDuration),
      target_destinations: formSelectedDests,
      target_checkpoints: editingChallenge?.target_checkpoints || [],
      participant_count: editingChallenge?.participant_count ?? 0,
      completed_count: editingChallenge?.completed_count ?? 0,
      is_active: editingChallenge ? editingChallenge.is_active : true,
      created_at: editingChallenge?.created_at || new Date().toISOString(),
    };

    const updated = ChallengesRepo.save(nextChallenge);
    setChallenges(updated);
    setIsModalOpen(false);
    showToast(
      editingChallenge ? 'Tantangan berhasil diperbarui.' : 'Tantangan baru berhasil ditambahkan.',
      'success'
    );
  };

  const handleToggleActive = (ch: Challenge) => {
    const updated = ChallengesRepo.save({ ...ch, is_active: !ch.is_active });
    setChallenges(updated);
    showToast(`Status tantangan "${ch.title}" diperbarui.`, 'info');
  };

  const handleDeleteChallenge = (id: string) => {
    if (!window.confirm('Hapus tantangan ini?')) return;
    setChallenges(ChallengesRepo.delete(id));
    showToast('Tantangan berhasil dihapus.', 'info');
  };

  const handleConfirmSendReward = () => {
    if (!selectedClaimForReward) return;
    const updated = UserChallengeRewardsRepo.validateAndSendReward(
      selectedClaimForReward.id,
      rewardNotesInput.trim() ||
      'E-Sertifikat Gubernur & hadiah diterbitkan resmi oleh Dinas Pariwisata Sumbar.'
    );
    setClaims(updated);
    showToast(
      `E-Sertifikat & Hadiah untuk ${selectedClaimForReward.tourist_name} berhasil diterbitkan!`,
      'success'
    );
    setSelectedClaimForReward(null);
    setRewardNotesInput('');
  };

  const handleIssuePassportCertificate = (user: UserProfileExperience) => {
    const certCode = `WG-CERT-2026-${Date.now().toString().slice(-5)}`;
    const newReward: UserChallengeReward = {
      id: `ucr-${Date.now().toString(36)}`,
      challenge_id: 'chl-10-destinasi',
      challenge_title: 'Tantangan 10 Destinasi Nagari (Paspor Digital)',
      user_id: user.user_id,
      tourist_name: user.full_name,
      tourist_phone: user.phone_number,
      progress_count: stempVisits.filter((v) => v.user_id === user.user_id && v.is_gps_valid).length,
      target_destination_count: 10,
      status: 'HADIAH_TERKIRIM',
      jenis_reward: 'E-Sertifikat Gubernur',
      reward: 'E-Sertifikat Resmi Gubernur Sumatera Barat + 500 XP',
      certificate_code: certCode,
      certificate_url: `https://wisgo.sumbarprov.go.id/certs/${certCode}.pdf`,
      completed_at: new Date().toISOString(),
      reward_notes: 'Diterbitkan langsung melalui Panel Paspor Digital Minang.',
    };
    setClaims(UserChallengeRewardsRepo.save(newReward));
    showToast(`E-Sertifikat Gubernur (${certCode}) diterbitkan untuk ${user.full_name}!`, 'success');
  };

  const handleSaveLevel = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingLevel) return;
    const updated = AdventurerLevelsRepo.updateLevel({
      ...editingLevel,
      title: levelFormTitle.trim() || editingLevel.title,
      min_trips: Number(levelFormTrips),
      min_checkpoints: Number(levelFormCheckpoints),
      min_xp: Number(levelFormXp),
      max_xp: Number(levelFormMaxXp),
      perk_description: levelFormPerks.trim() || editingLevel.perk_description,
    });
    setAdventurerLevels(updated);
    setEditingLevel(null);
    showToast(`Kriteria Level ${editingLevel.level} (${editingLevel.name}) diperbarui.`, 'success');
  };

  const handleVerifyJejakItem = (profileId: string, itemIdx: number) => {
    const user = userProfiles.find((u) => u.id === profileId);
    if (!user) return;
    const history = user.experience_history.map((item, idx) =>
      idx === itemIdx ? { ...item, status: 'verified' as const } : item
    );
    const target = user.experience_history[itemIdx];
    const nextXp = user.total_xp + (target?.xp_earned || 100);
    const nextLevel = calculateAdventurerLevel(nextXp);
    const nextVisited = user.visited_count + 1;

    const updatedUser: UserProfileExperience = {
      ...user,
      total_xp: nextXp,
      visited_count: nextVisited,
      current_level: nextLevel.level,
      level_name: nextLevel.name,
      experience_history: history,
    };

    const all = UserProfilesRepo.save(updatedUser);
    setUserProfiles(all);
    setSelectedUserForDetail(all.find((u) => u.id === profileId) || updatedUser);
    showToast(
      `Jejak "${target?.destination_name}" terverifikasi (+${target?.xp_earned || 100} XP · Level ${nextLevel.level} ${nextLevel.name}).`,
      'success'
    );
  };

  const handleSavePostingTemplate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedTemplate) return;
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
    showToast('Template Share Jejak WISGO & QR unduh berhasil disimpan.', 'success');
  };

  const totalActiveChallenges = challenges.filter((c) => c.is_active).length;
  const totalParticipants = challenges.reduce((sum, c) => sum + (c.participant_count || 0), 0);
  const totalReadyToClaim = claims.filter((c) => c.status === 'SIAP_KLAIM').length;

  const filteredClaims = claims.filter((clm) => {
    const q = searchTerm.trim().toLowerCase();
    const matchesSearch =
      !q ||
      clm.tourist_name.toLowerCase().includes(q) ||
      clm.tourist_phone.includes(q) ||
      (clm.challenge_title || clm.reward).toLowerCase().includes(q);
    const matchesStatus = claimStatusFilter === 'ALL' || clm.status === claimStatusFilter;
    return matchesSearch && matchesStatus;
  });

  const filteredProfiles = userProfiles.filter((u) => {
    const q = profileSearchTerm.trim().toLowerCase();
    const matchesQuery =
      !q ||
      u.full_name.toLowerCase().includes(q) ||
      u.email.toLowerCase().includes(q) ||
      u.level_name.toLowerCase().includes(q);
    const matchesSource =
      sourceFilter === 'ALL' || u.experience_history.some((h) => h.source === sourceFilter);
    return matchesQuery && matchesSource;
  });

  const previewUser =
    userProfiles.find((u) => u.id === previewUserId) || userProfiles[0];

  const inspectedPassportUser =
    userProfiles.find((u) => u.user_id === selectedPassportUserId) || userProfiles[0];
  const inspectedUserStamps = useMemo(
    () =>
      new Set(
        stempVisits
          .filter((v) => v.user_id === selectedPassportUserId && v.is_gps_valid)
          .map((v) => v.passport_code || v.destination_id)
      ),
    [stempVisits, selectedPassportUserId]
  );

  return (
    <div className="space-y-6 overflow-x-hidden">
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            Gamifikasi, Paspor Digital &amp; Jejak WISGO
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Tantangan check-in GPS, 5 Level Petualang, Paspor Digital 10 Spot Minang, Jejak WISGO, dan stiker share resmi.
          </p>
        </div>

        {activeTab === 'checkin' && (
          <button
            type="button"
            onClick={handleOpenCreateModal}
            className="min-h-[40px] px-4 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center gap-2 shadow-xs shrink-0"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Buat Tantangan</span>
          </button>
        )}
      </header>

      {/* 4 KPI */}
      <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Tantangan Aktif</span>
            <Trophy className="w-4 h-4 text-[#234B24]/70" />
          </div>
          <div className="my-2 text-2xl font-bold text-[#234B24]">{totalActiveChallenges}</div>
          <p className="text-xs text-slate-500">Dari {challenges.length} misi gamifikasi</p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Wisatawan Ikut Serta</span>
            <Users className="w-4 h-4 text-[#1E9E5A]" />
          </div>
          <div className="my-2 text-2xl font-bold text-[#234B24]">
            {totalParticipants.toLocaleString('id-ID')}
          </div>
          <p className="text-xs text-slate-500">{stempVisits.length} stempel GPS terverifikasi</p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Siap Klaim E-Sertifikat</span>
            <Sparkles className="w-4 h-4 text-[#F26B4B]" />
          </div>
          <div className="my-2 text-2xl font-bold text-[#F26B4B]">
            {totalReadyToClaim} Wisatawan
          </div>
          <p className="text-xs text-slate-500">Menunggu penerbitan Dispar Sumbar</p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-500 font-semibold">Paspor Digital Minang</span>
            <Stamp className="w-4 h-4 text-[#234B24]/70" />
          </div>
          <div className="my-2 text-2xl font-bold text-[#234B24]">
            {passportSpots.length} Spot Resmi
          </div>
          <p className="text-xs text-slate-500">CHL-BKT-01 s.d. CHL-LBH-10</p>
        </div>
      </section>

      {/* 4 Sub-Tab Bar */}
      <nav
        aria-label="Tab Gamifikasi"
        className="flex overflow-x-auto no-scrollbar whitespace-nowrap shrink-0 gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-2xs"
      >
        {(
          [
            { key: 'checkin', label: 'Check-In & Tantangan', icon: <Trophy className="w-3.5 h-3.5" /> },
            { key: 'levels', label: '5 Level & Paspor Digital', icon: <Award className="w-3.5 h-3.5 text-[#F59E0B]" /> },
            { key: 'profiles', label: 'Jejak WISGO & Riwayat', icon: <Users className="w-3.5 h-3.5 text-[#3B82F6]" /> },
            { key: 'templates', label: 'Template Share Jejak WISGO', icon: <Share2 className="w-3.5 h-3.5 text-[#F26B4B]" /> },
          ] as const
        ).map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => setActiveTab(tab.key)}
            className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${activeTab === tab.key
                ? 'bg-[#234B24] text-white shadow-xs'
                : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
              }`}
          >
            {tab.icon}
            <span>{tab.label}</span>
          </button>
        ))}
      </nav>

      {/* ==================================================================== */}
      {/* TAB 1: CHECK-IN & TANTANGAN                                          */}
      {/* ==================================================================== */}
      {activeTab === 'checkin' && (
        <section className="bg-white rounded-2xl p-6 border border-[#234B24]/8 shadow-xs space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#234B24]/10">
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setCheckinSubView('challenges')}
                className={`px-4 py-1.5 rounded-lg text-xs font-extrabold ${checkinSubView === 'challenges'
                    ? 'bg-[#234B24] text-white'
                    : 'bg-[#F6F3EC] text-[#4A5248]'
                  }`}
              >
                Program Tantangan ({challenges.length})
              </button>
              <button
                type="button"
                onClick={() => setCheckinSubView('claims')}
                className={`px-4 py-1.5 rounded-lg text-xs font-extrabold flex items-center gap-1.5 ${checkinSubView === 'claims'
                    ? 'bg-[#234B24] text-white'
                    : 'bg-[#F6F3EC] text-[#4A5248]'
                  }`}
              >
                <span>Verifikasi Klaim &amp; E-Sertifikat</span>
                {totalReadyToClaim > 0 && (
                  <span className="w-4 h-4 rounded-full bg-[#F26B4B] text-white text-[9px] flex items-center justify-center font-black">
                    {totalReadyToClaim}
                  </span>
                )}
              </button>
            </div>
          </div>

          {checkinSubView === 'challenges' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {challenges.map((ch) => (
                <div
                  key={ch.id}
                  className="p-5 rounded-2xl bg-[#F6F3EC]/70 border border-[#CFD8BE] flex flex-col justify-between space-y-4"
                >
                  <div className="space-y-2.5">
                    <div className="flex items-start justify-between gap-2">
                      <span className="px-2.5 py-1 rounded-md bg-[#234B24]/10 text-[#234B24] font-extrabold text-[10px] uppercase">
                        {ch.category || 'Alam & Geopark'}
                      </span>
                      <span className="px-2 py-0.5 rounded-md bg-blue-50 text-blue-700 font-bold text-[10px]">
                        +{ch.reward_points} XP · {ch.reward_type}
                      </span>
                    </div>

                    {ch.checkin_tagline && (
                      <div className="p-2.5 rounded-xl bg-white border border-[#CFD8BE]/80 text-[11px] font-bold text-[#234B24] flex items-center gap-2">
                        <Sparkles className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" />
                        <span>{ch.checkin_tagline}</span>
                      </div>
                    )}

                    <h3 className="text-base font-extrabold text-[#1B1F1A]">{ch.title}</h3>
                    <p className="text-xs text-[#4A5248]">{ch.description}</p>

                    <div className="p-3 rounded-xl bg-[#FFEDD5]/60 border border-[#FDBA74] text-xs">
                      <span className="font-extrabold text-[#9A3412] block">
                        Hadiah: {ch.reward_title}
                      </span>
                      <span className="text-[11px] text-[#C2410C] mt-0.5 block">
                        Target: {ch.target_destination_count} Destinasi · Durasi: {ch.duration_days ?? 60} Hari
                      </span>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-[#CFD8BE] flex items-center justify-between">
                    <button
                      type="button"
                      onClick={() => handleToggleActive(ch)}
                      className={`px-3 py-1 rounded-full text-xs font-bold ${ch.is_active ? 'bg-[#1E9E5A]/15 text-[#166534]' : 'bg-gray-200 text-[#767676]'
                        }`}
                    >
                      {ch.is_active ? 'Tantangan Aktif' : 'Non-Aktif'}
                    </button>

                    <div className="flex items-center gap-1.5">
                      <button
                        type="button"
                        onClick={() => handleOpenEditModal(ch)}
                        className="p-2 rounded-xl text-[#234B24] hover:bg-[#234B24]/10"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDeleteChallenge(ch.id)}
                        className="p-2 rounded-xl text-red-600 hover:bg-red-50"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {checkinSubView === 'claims' && (
            <div className="space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="relative flex-1 max-w-sm">
                  <Search className="w-4 h-4 absolute left-3.5 top-3 text-[#767676]" />
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    placeholder="Cari nama atau nomor wisatawan..."
                    className="w-full pl-9 pr-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                  />
                </div>
                <select
                  value={claimStatusFilter}
                  onChange={(e) =>
                    setClaimStatusFilter(
                      e.target.value as 'ALL' | 'DALAM_PROGRES' | 'SIAP_KLAIM' | 'HADIAH_TERKIRIM'
                    )
                  }
                  className="px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                >
                  <option value="ALL">Semua Status Klaim</option>
                  <option value="SIAP_KLAIM">Siap Klaim</option>
                  <option value="HADIAH_TERKIRIM">Hadiah Terkirim</option>
                  <option value="DALAM_PROGRES">Dalam Progres</option>
                </select>
              </div>

              <div className="overflow-x-auto rounded-2xl border border-[#CFD8BE]">
                <table className="w-full text-left text-xs">
                  <thead className="bg-[#234B24] text-[#F6F3EC] font-bold">
                    <tr>
                      <th className="py-3 px-4">Wisatawan</th>
                      <th className="py-3 px-4">Tantangan</th>
                      <th className="py-3 px-4">Progress</th>
                      <th className="py-3 px-4">Reward &amp; E-Sertifikat</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4 text-right">Tindakan</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#E4E9DA]">
                    {filteredClaims.map((clm) => (
                      <tr key={clm.id} className="hover:bg-[#F6F3EC]/50">
                        <td className="py-3 px-4">
                          <span className="font-extrabold block">{clm.tourist_name}</span>
                          <span className="text-[10px] font-mono text-[#767676]">
                            {clm.tourist_phone}
                          </span>
                        </td>
                        <td className="py-3 px-4 font-semibold">{clm.challenge_title}</td>
                        <td className="py-3 px-4 font-bold text-[#234B24]">
                          {clm.progress_count} / {clm.target_destination_count} Destinasi
                        </td>
                        <td className="py-3 px-4">
                          <div className="font-bold text-[#C2410C]">{clm.reward}</div>
                          {clm.certificate_code && (
                            <span className="text-[10px] font-mono text-[#234B24] font-bold">
                              Sertifikat: {clm.certificate_code}
                            </span>
                          )}
                        </td>
                        <td className="py-3 px-4">
                          <span
                            className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${clm.status === 'SIAP_KLAIM'
                                ? 'bg-[#FFEDD5] text-[#C2410C]'
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
                              className="px-3 py-1.5 rounded-xl bg-[#F26B4B] hover:bg-[#D95637] text-white font-bold text-[11px]"
                            >
                              Terbitkan Hadiah
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </section>
      )}

      {/* ==================================================================== */}
      {/* TAB 2: 5 LEVEL PETUALANG & PASPOR DIGITAL MINANG (10 SPOT)           */}
      {/* ==================================================================== */}
      {activeTab === 'levels' && (
        <div className="space-y-6">
          <section className="bg-white rounded-2xl p-6 border border-[#234B24]/8 shadow-xs space-y-5">
            <div>
              <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Award className="w-5 h-5 text-[#F59E0B]" />
                <span>5 Tingkatan Level Petualang (Sinkron AdventurerGrade Mobile)</span>
              </h2>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Ambang XP resmi: Beginner (0–299), Explorer (300–699), Adventurer (700–1199), Trailblazer (1200–1999), Wanderer (2000+ XP).
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {adventurerLevels.map((lvl) => (
                <div
                  key={lvl.level}
                  className="p-5 rounded-3xl border-2 border-[#CFD8BE] bg-[#F6F3EC]/50 flex flex-col justify-between space-y-4"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span
                        className="px-3 py-1 rounded-full text-xs font-black text-white"
                        style={{ backgroundColor: lvl.badge_color }}
                      >
                        LEVEL {lvl.level}
                      </span>
                      <img
                        src={getLevelBadgeSvg(lvl.level)}
                        alt={lvl.name}
                        className="w-12 h-14 object-contain"
                      />
                    </div>
                    <div>
                      <h3 className="text-lg font-black text-[#1B1F1A]">{lvl.name}</h3>
                      <div className="text-xs font-bold text-[#234B24]">{lvl.title}</div>
                    </div>
                    <div className="p-3 rounded-2xl bg-white border border-[#234B24]/10 text-xs space-y-1.5">
                      <div className="flex justify-between">
                        <span className="text-[#767676]">Ambang XP:</span>
                        <strong className="font-mono text-[#234B24]">
                          {lvl.min_xp} – {lvl.level === 5 ? `${lvl.min_xp}+` : lvl.max_xp} XP
                        </strong>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-[#767676]">Min. Trip / Check-in:</span>
                        <strong className="font-mono">
                          {lvl.min_trips} Trip · {lvl.min_checkpoints} Titik
                        </strong>
                      </div>
                    </div>
                    <div className="p-3 rounded-xl bg-[#E4E9DA]/50 text-xs text-[#234B24]">
                      <strong>Hak Istimewa:</strong> {lvl.perk_description}
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      setEditingLevel(lvl);
                      setLevelFormTitle(lvl.title);
                      setLevelFormTrips(lvl.min_trips);
                      setLevelFormCheckpoints(lvl.min_checkpoints);
                      setLevelFormXp(lvl.min_xp);
                      setLevelFormMaxXp(lvl.max_xp);
                      setLevelFormPerks(lvl.perk_description);
                    }}
                    className="w-full min-h-[38px] px-3 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold flex items-center justify-center gap-1.5"
                  >
                    <Sliders className="w-3.5 h-3.5" /> Ubah Kriteria Level {lvl.level}
                  </button>
                </div>
              ))}
            </div>
          </section>

          {/* PANEL PASPOR DIGITAL MINANG (10 SPOT RESMI) */}
          <section className="bg-white rounded-2xl p-6 border border-[#234B24]/8 shadow-xs space-y-5">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-3 border-b border-[#234B24]/10">
              <div>
                <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Stamp className="w-5 h-5 text-[#234B24]" />
                  <span>Paspor Digital Minang (10 Spot Stempel Resmi Gubernur)</span>
                </h2>
                <p className="text-xs text-[#4A5248] mt-0.5">
                  Pantau capaian stempel GPS (&lt;500m) tiap wisatawan dan terbitkan E-Sertifikat Gubernur.
                </p>
              </div>

              <div className="flex flex-wrap items-center gap-2">
                <select
                  value={selectedPassportUserId}
                  onChange={(e) => setSelectedPassportUserId(e.target.value)}
                  className="min-h-[38px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                >
                  {userProfiles.map((u) => (
                    <option key={u.user_id} value={u.user_id}>
                      Inspeksi: {u.full_name} ({u.level_name})
                    </option>
                  ))}
                </select>
                {inspectedPassportUser && (
                  <button
                    type="button"
                    onClick={() => handleIssuePassportCertificate(inspectedPassportUser)}
                    className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold inline-flex items-center gap-1.5"
                  >
                    <Award className="w-3.5 h-3.5 text-[#F59E0B]" />
                    <span>Terbitkan E-Sertifikat Gubernur</span>
                  </button>
                )}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
              {passportSpots.map((spot) => {
                const totalSpotVisits = stempVisits.filter(
                  (v) =>
                    v.is_gps_valid &&
                    (v.passport_code === spot.code || v.destination_id === spot.destination_id)
                ).length;
                const hasStamp =
                  inspectedUserStamps.has(spot.code) ||
                  inspectedUserStamps.has(spot.destination_id);

                return (
                  <div
                    key={spot.code}
                    className={`p-4 rounded-2xl border-2 transition ${hasStamp
                        ? 'bg-[#DCFCE7]/50 border-[#1E9E5A]'
                        : 'bg-[#F6F3EC]/60 border-[#CFD8BE]'
                      }`}
                  >
                    <div className="flex items-center justify-between gap-1">
                      <span className="font-mono text-[10px] font-black px-2 py-0.5 rounded bg-[#234B24] text-white">
                        {spot.code}
                      </span>
                      {hasStamp ? (
                        <CheckCircle2 className="w-4 h-4 text-[#1E9E5A]" />
                      ) : (
                        <span className="text-[10px] text-[#767676] font-bold">Belum</span>
                      )}
                    </div>
                    <h4 className="text-xs font-extrabold text-[#1B1F1A] mt-2 leading-snug">
                      {spot.destination_title}
                    </h4>
                    <div className="text-[10px] text-[#4A5248] flex items-center gap-1 mt-1">
                      <MapPin className="w-3 h-3 text-[#F26B4B]" /> {spot.region}
                    </div>
                    <p className="text-[10px] italic text-[#4A5248] mt-1.5 line-clamp-2">
                      &ldquo;{spot.cultural_quote}&rdquo;
                    </p>
                    <div className="mt-2 pt-2 border-t border-black/5 text-[10px] font-bold text-[#234B24]">
                      Total Check-in Valid: {totalSpotVisits} wisatawan
                    </div>
                  </div>
                );
              })}
            </div>
          </section>
        </div>
      )}

      {/* ==================================================================== */}
      {/* TAB 3: JEJAK WISGO & RIWAYAT AKTIVITAS (NON-OLAHRAGA / ZERO KM)       */}
      {/* ==================================================================== */}
      {activeTab === 'profiles' && (
        <section className="bg-white rounded-2xl p-6 border border-[#234B24]/8 shadow-xs space-y-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-3 border-b border-[#234B24]/10">
            <div>
              <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Users className="w-5 h-5 text-[#3B82F6]" />
                <span>Direktori Jejak WISGO &amp; Riwayat Aktivitas Wisatawan</span>
              </h2>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Statistik eksplorasi destinasi murni (Check-in GPS, Trip Go, Scan Tiket QR) — tanpa metrik olahraga.
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <div className="relative">
                <Search className="w-4 h-4 absolute left-3 top-2.5 text-[#767676]" />
                <input
                  type="text"
                  value={profileSearchTerm}
                  onChange={(e) => setProfileSearchTerm(e.target.value)}
                  placeholder="Cari nama atau email..."
                  className="pl-9 pr-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                />
              </div>
              <select
                value={sourceFilter}
                onChange={(e) => setSourceFilter(e.target.value as 'ALL' | JejakWisgoSource)}
                className="px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
              >
                <option value="ALL">Semua Sumber Aktivitas</option>
                <option value="GPS_CHECKIN">Check-in GPS</option>
                <option value="TRIP_GO">Trip Go</option>
                <option value="TICKET_SCAN">Scan Tiket QR</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {filteredProfiles.map((user) => (
              <div
                key={user.id}
                className="p-5 rounded-3xl border border-[#CFD8BE] bg-[#F6F3EC]/50 flex flex-col justify-between space-y-4"
              >
                <div className="space-y-3.5">
                  <div className="flex items-start gap-3">
                    <img
                      src={user.google_avatar}
                      alt={user.full_name}
                      className="w-12 h-12 rounded-2xl object-cover border-2 border-[#234B24]"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <h3 className="text-sm font-black truncate">{user.full_name}</h3>
                        {user.is_google_auth && (
                          <span className="px-1.5 py-0.5 rounded text-[9px] font-black bg-blue-100 text-blue-700 inline-flex items-center gap-0.5">
                            <Shield className="w-2.5 h-2.5" /> Google Verified
                          </span>
                        )}
                      </div>
                      <span className="text-[11px] text-[#767676] block truncate">{user.email}</span>
                      <div className="flex items-center gap-2 mt-1">
                        <img src={getLevelBadgeSvg(user.current_level)} alt="" className="w-5 h-6" />
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-[#234B24]/10 text-[#234B24]">
                          Level {user.current_level}: {user.level_name}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* 4 Metrik Murni Wisata Jejak WISGO (Nol km) */}
                  <div className="grid grid-cols-2 gap-2 text-center">
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Destinasi Dikunjungi</span>
                      <strong className="text-sm font-black text-[#234B24]">
                        {user.visited_count} / {destinations.length}
                      </strong>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Total Trip</span>
                      <strong className="text-sm font-black text-[#1B1F1A]">{user.total_trips}</strong>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Check Point GPS</span>
                      <strong className="text-sm font-black text-[#1B1F1A]">
                        {user.total_checkpoints}
                      </strong>
                    </div>
                    <div className="p-2 rounded-xl bg-white border border-[#234B24]/10">
                      <span className="text-[10px] text-[#767676] block">Total XP</span>
                      <strong className="text-sm font-black text-[#F26B4B]">
                        {user.total_xp} XP
                      </strong>
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <span className="text-[10px] font-black uppercase text-[#4A5248] block">
                      Jejak Terakhir:
                    </span>
                    {user.experience_history.slice(0, 2).map((exp, idx) => (
                      <div
                        key={idx}
                        className="p-2.5 rounded-xl bg-white border border-[#234B24]/10 text-xs flex items-center justify-between gap-2"
                      >
                        <div className="min-w-0">
                          <strong className="block truncate">{exp.destination_name}</strong>
                          <div className="flex items-center gap-1.5 mt-0.5">
                            <span
                              className={`px-1.5 py-0.5 rounded text-[9px] font-bold ${SOURCE_LABELS[exp.source]?.color || 'bg-gray-100'
                                }`}
                            >
                              {SOURCE_LABELS[exp.source]?.label || exp.source}
                            </span>
                            <span className="text-[10px] text-[#767676]">
                              Stempel #{exp.stamp_number}
                            </span>
                          </div>
                        </div>
                        <span className="font-extrabold text-[11px] text-[#234B24] shrink-0">
                          +{exp.xp_earned} XP
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <button
                  type="button"
                  onClick={() => setSelectedUserForDetail(user)}
                  className="w-full min-h-[40px] px-3 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold flex items-center justify-center gap-1.5"
                >
                  <FileCheck className="w-3.5 h-3.5" />
                  <span>Lihat &amp; Validasi Jejak ({user.experience_history.length})</span>
                </button>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* ==================================================================== */}
      {/* TAB 4: TEMPLATE SHARE JEJAK WISGO (Stiker Transparan PNG & Kartu)    */}
      {/* ==================================================================== */}
      {activeTab === 'templates' && selectedTemplate && (
        <section className="bg-white rounded-2xl p-6 border border-[#234B24]/8 shadow-xs space-y-6">
          <div>
            <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <Share2 className="w-5 h-5 text-[#F26B4B]" />
              <span>Template Share Jejak WISGO (Stiker Transparan PNG &amp; Kartu Penuh)</span>
            </h2>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Selaras dengan 2 mode berbagi Jejak WISGO pada aplikasi mobile: Stiker Overlay 3-Blok Transparan &amp; Kartu Foto Penuh.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            <div className="lg:col-span-6 space-y-4">
              <form
                onSubmit={handleSavePostingTemplate}
                className="space-y-4 p-5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]"
              >
                <div>
                  <label className="block text-xs font-bold mb-1">Mode Template Share</label>
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
                  <label className="block text-xs font-bold mb-1">
                    Pilih Profil Wisatawan untuk Pratinjau Dinamis
                  </label>
                  <select
                    value={previewUserId}
                    onChange={(e) => setPreviewUserId(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
                  >
                    {userProfiles.map((u) => (
                      <option key={u.id} value={u.id}>
                        {u.full_name} — Level {u.current_level} {u.level_name} ({u.total_xp} XP)
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold mb-1">Teks Watermark Resmi</label>
                  <input
                    type="text"
                    value={templateWatermark}
                    onChange={(e) => setTemplateWatermark(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold mb-1">URL Target QR Unduh Aplikasi</label>
                  <input
                    type="url"
                    value={templateQrUrl}
                    onChange={(e) => setTemplateQrUrl(e.target.value)}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>

                <button
                  type="submit"
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold flex items-center gap-2"
                >
                  <CheckCheck className="w-4 h-4" />
                  <span>Simpan Pengaturan Template</span>
                </button>
              </form>
            </div>

            {/* Dynamic Live Preview: Transparent Sticker PNG vs Full Card */}
            <div className="lg:col-span-6 flex justify-center">
              {selectedTemplate.preview_mode === 'transparent_sticker' ? (
                <div
                  className="w-full max-w-sm rounded-[32px] p-6 border-2 border-dashed border-[#234B24]/40 shadow-xl space-y-5"
                  style={{
                    backgroundImage:
                      'linear-gradient(45deg, #e5e7eb 25%, transparent 25%), linear-gradient(-45deg, #e5e7eb 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #e5e7eb 75%), linear-gradient(-45deg, transparent 75%, #e5e7eb 75%)',
                    backgroundSize: '20px 20px',
                    backgroundPosition: '0 0, 0 10px, 10px -10px, -10px 0px',
                    backgroundColor: '#f8fafc',
                  }}
                >
                  <div className="bg-[#234B24]/95 text-white rounded-2xl p-5 space-y-3 shadow-lg">
                    <span className="text-[10px] font-black uppercase tracking-widest text-[#A7F3D0]">
                      STIKER TRANSPARAN PNG · JEJAK WISGO
                    </span>
                    <div className="grid grid-cols-3 gap-2 text-center border-y border-white/15 py-3">
                      <div>
                        <div className="text-lg font-black text-[#F26B4B]">
                          {previewUser?.visited_count ?? 6}/{destinations.length}
                        </div>
                        <div className="text-[9px] uppercase text-white/75">Destinasi</div>
                      </div>
                      <div>
                        <div className="text-lg font-black text-white">
                          Lv.{previewUser?.current_level ?? 3}
                        </div>
                        <div className="text-[9px] uppercase text-white/75">
                          {previewUser?.level_name ?? 'Adventurer'}
                        </div>
                      </div>
                      <div>
                        <div className="text-lg font-black text-[#A7F3D0]">
                          {previewUser?.total_xp ?? 1050}
                        </div>
                        <div className="text-[9px] uppercase text-white/75">Total XP</div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between gap-2">
                      <div className="text-xs font-extrabold">{previewUser?.full_name}</div>
                      <img
                        src={selectedTemplate.qr_image_url}
                        alt="QR Unduh"
                        className="w-12 h-12 rounded-lg bg-white p-0.5"
                      />
                    </div>
                    <div className="text-[9px] font-mono text-white/75 text-center">
                      {templateWatermark}
                    </div>
                  </div>
                </div>
              ) : (
                <div className="w-full max-w-sm rounded-[32px] overflow-hidden border-4 border-[#234B24] shadow-2xl bg-[#1B3A1C] text-white p-6 space-y-5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-xl bg-[#F26B4B] flex items-center justify-center font-black text-sm">
                        W
                      </div>
                      <div>
                        <h4 className="text-xs font-black tracking-wide">JEJAK WISGO SUMBAR</h4>
                        <span className="text-[9px] text-[#CFD8BE]">Kartu Penuh Komunitas</span>
                      </div>
                    </div>
                    <span className="px-2 py-0.5 rounded-full text-[9px] font-black bg-white/20">
                      TERVERIFIKASI
                    </span>
                  </div>

                  <div className="relative rounded-2xl overflow-hidden aspect-[4/3] bg-black/40 border border-white/10 flex flex-col justify-end p-4">
                    <img
                      src={selectedTemplate.background_banner_url}
                      alt="Preview"
                      className="absolute inset-0 w-full h-full object-cover opacity-65"
                    />
                    <div className="relative z-10 space-y-1">
                      <span className="px-2 py-0.5 rounded text-[9px] font-black bg-[#F59E0B] text-black inline-block">
                        LEVEL {previewUser?.current_level ?? 3} · {(previewUser?.level_name || 'Adventurer').toUpperCase()}
                      </span>
                      <h3 className="text-base font-black leading-tight text-white">
                        {previewUser?.full_name} menjelajahi{' '}
                        {previewUser?.experience_history[0]?.destination_name || 'Ranah Minang'}!
                      </h3>
                      <p className="text-[10px] text-white/90">
                        {previewUser?.visited_count ?? 6} Destinasi · {previewUser?.total_checkpoints ?? 16} Check Point · {previewUser?.total_xp ?? 1050} XP
                      </p>
                    </div>
                  </div>

                  <div className="p-3.5 rounded-2xl bg-white/10 border border-white/15 flex items-center justify-between gap-3">
                    <div>
                      <span className="text-[10px] font-extrabold text-[#F26B4B] block uppercase">
                        Unduh WISGO Sekarang
                      </span>
                      <p className="text-[9px] text-[#CFD8BE]">
                        Pindai QR untuk kumpulkan Paspor Digital Minang!
                      </p>
                    </div>
                    <img
                      src={selectedTemplate.qr_image_url}
                      alt="QR Code Unduh"
                      className="w-16 h-16 rounded-xl bg-white p-1 shrink-0"
                    />
                  </div>

                  <div className="text-center pt-2 border-t border-white/10 text-[10px] font-mono text-white/80">
                    {templateWatermark}
                  </div>
                </div>
              )}
            </div>
          </div>
        </section>
      )}

      {/* MODAL BUAT/EDIT TANTANGAN */}
      {isModalOpen && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <div className="bg-white rounded-[28px] w-full max-w-xl p-6 shadow-2xl max-h-[90vh] flex flex-col overflow-hidden">
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA]">
              <h3 className="text-base font-extrabold">
                {editingChallenge ? 'Edit Tantangan' : 'Buat Tantangan Wisata Baru'}
              </h3>
              <button type="button" onClick={() => setIsModalOpen(false)} className="p-1.5">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveChallenge} className="mt-4 space-y-4 overflow-y-auto pr-1">
              <div>
                <label className="block text-xs font-bold mb-1">Judul Tantangan *</label>
                <input
                  type="text"
                  required
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                />
              </div>
              <div>
                <label className="block text-xs font-bold mb-1">Tagline Check-In</label>
                <input
                  type="text"
                  value={formTagline}
                  onChange={(e) => setFormTagline(e.target.value)}
                  className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold mb-1">5 Master Kategori</label>
                  <select
                    value={formCategory}
                    onChange={(e) => setFormCategory(e.target.value)}
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                  >
                    {MASTER_DESTINATION_CATEGORIES.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">Jenis Reward</label>
                  <select
                    value={formRewardType}
                    onChange={(e) => setFormRewardType(e.target.value)}
                    className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                  >
                    <option value="Sertifikat & XP">E-Sertifikat Gubernur &amp; XP</option>
                    <option value="Badge Khusus">Lencana Khusus</option>
                    <option value="Voucher">Voucher UMKM Nagari</option>
                    <option value="XP">XP Murni</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-xs font-bold mb-1">Detail Hadiah *</label>
                <input
                  type="text"
                  required
                  value={formReward}
                  onChange={(e) => setFormReward(e.target.value)}
                  className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                />
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-xs font-bold mb-1">Target Destinasi</label>
                  <input
                    type="number"
                    min={1}
                    value={formTargetCount}
                    onChange={(e) => setFormTargetCount(Number(e.target.value))}
                    className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">Reward XP</label>
                  <input
                    type="number"
                    min={50}
                    step={50}
                    value={formRewardPoints}
                    onChange={(e) => setFormRewardPoints(Number(e.target.value))}
                    className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">Durasi (Hari)</label>
                  <input
                    type="number"
                    min={7}
                    value={formDuration}
                    onChange={(e) => setFormDuration(Number(e.target.value))}
                    className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-bold mb-1">Deskripsi Misi</label>
                <textarea
                  rows={2}
                  value={formDescription}
                  onChange={(e) => setFormDescription(e.target.value)}
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
                />
              </div>
              <div>
                <label className="block text-xs font-bold mb-1">Destinasi Sasaran</label>
                <div className="max-h-32 overflow-y-auto p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-1">
                  {destinations.map((d) => (
                    <label key={d.id} className="flex items-center gap-2 text-xs cursor-pointer">
                      <input
                        type="checkbox"
                        checked={formSelectedDests.includes(d.name)}
                        onChange={(e) =>
                          setFormSelectedDests((prev) =>
                            e.target.checked ? [...prev, d.name] : prev.filter((n) => n !== d.name)
                          )
                        }
                      />
                      <span>{d.name}</span>
                    </label>
                  ))}
                </div>
              </div>
              <div className="pt-3 border-t flex justify-end gap-2">
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
                  Simpan Tantangan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL TERBITKAN HADIAH */}
      {selectedClaimForReward && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <div className="bg-white rounded-[28px] w-full max-w-md p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-extrabold">Terbitkan Hadiah &amp; E-Sertifikat</h3>
            <p className="text-xs text-[#4A5248]">
              Penerima: <strong>{selectedClaimForReward.tourist_name}</strong> ·{' '}
              {selectedClaimForReward.reward}
            </p>
            <textarea
              rows={2}
              value={rewardNotesInput}
              onChange={(e) => setRewardNotesInput(e.target.value)}
              placeholder="Catatan penyerahan hadiah / nomor E-Sertifikat..."
              className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
            />
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setSelectedClaimForReward(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmSendReward}
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Konfirmasi &amp; Terbitkan
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL EDIT LEVEL */}
      {editingLevel && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <form onSubmit={handleSaveLevel} className="bg-white rounded-[28px] w-full max-w-md p-6 shadow-2xl space-y-4">
            <h3 className="text-base font-extrabold">
              Ubah Kriteria Level {editingLevel.level} ({editingLevel.name})
            </h3>
            <div className="space-y-3 text-xs">
              <div>
                <label className="block font-bold mb-1">Judul Level</label>
                <input
                  type="text"
                  value={levelFormTitle}
                  onChange={(e) => setLevelFormTitle(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold mb-1">Min XP</label>
                  <input
                    type="number"
                    value={levelFormXp}
                    onChange={(e) => setLevelFormXp(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>
                <div>
                  <label className="block font-bold mb-1">Max XP</label>
                  <input
                    type="number"
                    value={levelFormMaxXp}
                    onChange={(e) => setLevelFormMaxXp(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block font-bold mb-1">Min Trip</label>
                  <input
                    type="number"
                    value={levelFormTrips}
                    onChange={(e) => setLevelFormTrips(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>
                <div>
                  <label className="block font-bold mb-1">Min Check Point</label>
                  <input
                    type="number"
                    value={levelFormCheckpoints}
                    onChange={(e) => setLevelFormCheckpoints(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                  />
                </div>
              </div>
              <div>
                <label className="block font-bold mb-1">Hak Istimewa (Perks)</label>
                <textarea
                  rows={2}
                  value={levelFormPerks}
                  onChange={(e) => setLevelFormPerks(e.target.value)}
                  className="w-full p-2.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE]"
                />
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setEditingLevel(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan Level
              </button>
            </div>
          </form>
        </div>
      )}

      {/* MODAL VALIDASI JEJAK WISGO */}
      {selectedUserForDetail && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60">
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 shadow-2xl space-y-4 max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b">
              <div>
                <h3 className="text-base font-extrabold">{selectedUserForDetail.full_name}</h3>
                <p className="text-xs text-[#4A5248]">
                  Level {selectedUserForDetail.current_level} {selectedUserForDetail.level_name} ·{' '}
                  {selectedUserForDetail.visited_count}/{destinations.length} Destinasi ·{' '}
                  {selectedUserForDetail.total_xp} XP
                </p>
              </div>
              <button type="button" onClick={() => setSelectedUserForDetail(null)}>
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2.5">
              {selectedUserForDetail.experience_history.map((item, idx) => (
                <div
                  key={item.id || idx}
                  className="p-3.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-start justify-between gap-3"
                >
                  <div className="space-y-1 text-xs">
                    <div className="font-extrabold text-[#1B1F1A]">{item.destination_name}</div>
                    <div className="flex flex-wrap items-center gap-1.5">
                      <span
                        className={`px-2 py-0.5 rounded text-[10px] font-bold ${SOURCE_LABELS[item.source]?.color || 'bg-gray-100'
                          }`}
                      >
                        {SOURCE_LABELS[item.source]?.label || item.source}
                      </span>
                      <span className="text-[10px] font-mono font-bold text-[#234B24]">
                        Stempel #{item.stamp_number}
                      </span>
                      <span className="text-[10px] text-[#767676]">{item.date}</span>
                    </div>
                    {item.notes && <p className="text-[11px] text-[#4A5248]">{item.notes}</p>}
                  </div>
                  <div className="shrink-0 text-right">
                    <div className="text-xs font-black text-[#234B24]">+{item.xp_earned} XP</div>
                    {item.status === 'verified' ? (
                      <span className="inline-flex items-center gap-1 text-[10px] font-bold text-[#166534] mt-1">
                        <CheckCircle2 className="w-3.5 h-3.5" /> Terverifikasi
                      </span>
                    ) : (
                      <button
                        type="button"
                        onClick={() => handleVerifyJejakItem(selectedUserForDetail.id, idx)}
                        className="mt-1 px-2.5 py-1 rounded-lg bg-[#234B24] text-white text-[10px] font-bold"
                      >
                        Verifikasi &amp; Beri XP
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
