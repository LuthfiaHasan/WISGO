import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/gamification_model.dart';

/// Service Gamifikasi WISGO terpusat (ChangeNotifier Singleton):
/// Mengelola akumulasi XP, 5 Tingkatan Grade Petualang, Sinkronisasi Check-In,
/// Progres Challenge Misi, Koleksi Lencana (Unlocked & Grayscale), dan Histori Aktivitas.
class GamificationService extends ChangeNotifier {
  static final GamificationService _instance = GamificationService._internal();
  static GamificationService get instance => _instance;

  GamificationService._internal() {
    _initializeData();
  }

  // --- STATE ---
  late int _currentXp;
  late int _currentPoints;
  late int _totalTrips;
  late int _totalCheckpoints;
  late List<ChallengeMission> _challenges;
  late List<GamificationBadge> _badges;
  late List<CheckInActivity> _activityHistory;

  // --- GETTERS ---
  int get currentXp => _currentXp;
  int get currentPoints => _currentPoints;
  int get totalTrips => _totalTrips;
  int get totalCheckpoints => _totalCheckpoints;
  List<ChallengeMission> get challenges => List.unmodifiable(_challenges);
  List<GamificationBadge> get badges => List.unmodifiable(_badges);
  List<CheckInActivity> get activityHistory => List.unmodifiable(_activityHistory);

  // Misi Utama Tantangan 10 Destinasi Nagari
  ChallengeMission get primaryChallenge => _challenges.first;

  // Grade Petualang Saat Ini
  AdventurerGrade get currentGrade => AdventurerGrade.fromXp(_currentXp);

  // Grade Berikutnya (null jika sudah level 5)
  AdventurerGrade? get nextGrade {
    final curLevel = currentGrade.level;
    if (curLevel >= 5) return null;
    return AdventurerGrade.allGrades[curLevel]; // index 0=lvl1, 1=lvl2, etc.
  }

  // Hitungan XP pada level berjalan
  int get xpIntoCurrentLevel {
    final grade = currentGrade;
    return _currentXp - grade.minXp;
  }

  // Rentang XP yang dibutuhkan untuk level berjalan ini
  int get xpSpanForCurrentLevel {
    final grade = currentGrade;
    final next = nextGrade;
    if (next == null) {
      return 1000; // Wanderer cap target
    }
    return next.minXp - grade.minXp;
  }

  // Target XP untuk mencapai level selanjutnya
  int get targetXpForNextLevel {
    final next = nextGrade;
    if (next == null) return 3000;
    return next.minXp;
  }

  // Rasio progres XP pada level ini (0.0 sampai 1.0)
  double get levelProgressRatio {
    final span = xpSpanForCurrentLevel;
    if (span <= 0) return 1.0;
    return (xpIntoCurrentLevel / span).clamp(0.0, 1.0);
  }

  int get levelProgressPercent => (levelProgressRatio * 100).toInt();

  // Hitungan lencana
  int get unlockedBadgeCount => _badges.where((b) => b.isUnlocked).length;
  int get lockedBadgeCount => _badges.where((b) => !b.isUnlocked).length;

  // Inisialisasi Data Awal (Baseline Pengguna: Level 4 Trailblazer, 1.450 XP)
  void _initializeData() {
    _currentXp = 1450;
    _currentPoints = 1250;
    _totalTrips = 12;
    _totalCheckpoints = 28;

    _challenges = [
      ChallengeMission(
        id: 'chl-10-destinasi',
        title: 'Tantangan 10 Destinasi Nagari',
        tagline: 'Tandai Check Point, Kumpulkan XP & Taklukkan Challenge',
        description: 'Check-in GPS pada 10 Kawasan Destinasi Resmi Terverifikasi Admin Dispar Sumbar.',
        region: 'Sumatera Barat',
        targetCheckpoints: 10,
        currentCheckpoints: 4,
        xpReward: 500,
        pointsReward: 500,
        isCompleted: false,
        badgeRewardId: 'badge_wanderer_master',
        checkpointLocations: [
          'Jam Gadang & Ngarai Sianok',
          'Lembah Harau & Sarasah Bunta',
          'Istano Basa Pagaruyung',
          'Danau Singkarak & Dermaga Ombilin',
          'Danau Maninjau & Puncak Lawang',
          'Pantai Air Manis & Batu Malin',
          'Kawasan Mandeh & Pulau Setan',
          'Air Terjun Lembah Anai',
          'Nagari Tuo Pariangan',
          'Air Terjun Lubuk Hitam (Cindakir)',
        ],
      ),
      ChallengeMission(
        id: 'chl-rute-geotourist',
        title: 'Rute Geotourist Lembah & Danau',
        tagline: 'Tandai Check Point, Kumpulkan XP & Taklukkan Challenge',
        description: 'Jelajahi danau tektonik & tebing geologis Sumatera Barat.',
        region: 'Solok & Lima Puluh Kota',
        targetCheckpoints: 5,
        currentCheckpoints: 3,
        xpReward: 350,
        pointsReward: 300,
        isCompleted: false,
        badgeRewardId: 'badge_geotourist',
        checkpointLocations: [
          'Danau Singkarak',
          'Danau Maninjau',
          'Danau Diatas',
          'Danau Dibawah',
          'Lembah Harau',
        ],
      ),
      ChallengeMission(
        id: 'chl-luhak-nan-tuo',
        title: 'Jejak Adat Luhak Nan Tuo',
        tagline: 'Tandai Check Point, Kumpulkan XP & Taklukkan Challenge',
        description: 'Menelusuri warisan adat dan sejarah terverifikasi di Tanah Datar.',
        region: 'Kab. Tanah Datar',
        targetCheckpoints: 3,
        currentCheckpoints: 2,
        xpReward: 300,
        pointsReward: 250,
        isCompleted: false,
        badgeRewardId: 'badge_pariangan',
        checkpointLocations: [
          'Istano Basa Pagaruyung',
          'Nagari Tuo Pariangan',
          'Batu Basurek',
        ],
      ),
    ];

    _badges = [
      // 5 Lencana Grade Petualang
      GamificationBadge(
        id: 'badge_grade_1',
        title: 'Lencana Beginner',
        subtitle: 'Level 1 – Awal Penjelajahan',
        icon: Icons.hiking_rounded,
        color: AppColors.muted,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 45)),
        xpReward: 100,
        category: 'grade',
        requirementDescription: 'Mulai perjalanan dan check-in GPS pertama di Sumbar',
      ),
      GamificationBadge(
        id: 'badge_grade_2',
        title: 'Lencana Explorer',
        subtitle: 'Level 2 – Penjelajah Aktif',
        icon: Icons.explore_rounded,
        color: AppColors.pinNavigasiBiru,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 30)),
        xpReward: 200,
        category: 'grade',
        requirementDescription: 'Capai 300 XP & kunjungi 3 destinasi nagari',
      ),
      GamificationBadge(
        id: 'badge_grade_3',
        title: 'Lencana Adventurer',
        subtitle: 'Level 3 – Penakluk Medan',
        icon: Icons.terrain_rounded,
        color: AppColors.success,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 14)),
        xpReward: 300,
        category: 'grade',
        requirementDescription: 'Capai 700 XP & tuntaskan rute alam Minang',
      ),
      GamificationBadge(
        id: 'badge_grade_4',
        title: 'Lencana Trailblazer',
        subtitle: 'Level 4 – Perintis Rute',
        icon: Icons.stars_rounded,
        color: AppColors.warning,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
        xpReward: 400,
        category: 'grade',
        requirementDescription: 'Capai 1.200 XP & tuntaskan tantangan wilayah terpencil',
      ),
      GamificationBadge(
        id: 'badge_grade_5',
        title: 'Lencana Wanderer',
        subtitle: 'Level 5 – Mahaguru Penjelajah',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.goldMinang,
        isUnlocked: false,
        xpReward: 500,
        category: 'grade',
        requirementDescription: 'Capai 2.000 XP & taklukkan seluruh 10 destinasi tantangan',
      ),

      // Lencana Prestasi Destinasi & Budaya
      GamificationBadge(
        id: 'badge_singgalang',
        title: 'Puncak Singgalang',
        subtitle: 'Telaga Dewi & Hutan Lumut',
        icon: Icons.emoji_events_rounded,
        color: AppColors.goldSoft,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 7)),
        xpReward: 250,
        category: 'destination',
        requirementDescription: 'Tuntaskan jalur pendakian Gunung Singgalang',
      ),
      GamificationBadge(
        id: 'badge_kelok9',
        title: 'Penakluk Kelok 9',
        subtitle: 'Mahakarya Jembatan Lembah',
        icon: Icons.military_tech_rounded,
        color: AppColors.info,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 4)),
        xpReward: 200,
        category: 'destination',
        requirementDescription: 'Check-in di kawasan ikonik Flyover Kelok 9',
      ),
      GamificationBadge(
        id: 'badge_pariangan',
        title: 'Nagari Pariangan',
        subtitle: 'Nagari Tertua Minangkabau',
        icon: Icons.account_balance_rounded,
        color: AppColors.success,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
        xpReward: 150,
        category: 'culture',
        requirementDescription: 'Check-in & telusuri rumah gadang Nagari Tuo Pariangan',
      ),
      GamificationBadge(
        id: 'badge_randang',
        title: 'Randang Otentik',
        subtitle: 'Kuliner Legenda Dunia',
        icon: Icons.restaurant_rounded,
        color: AppColors.danger,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
        xpReward: 100,
        category: 'culture',
        requirementDescription: 'Nikmati kuliner randang otentik bersertifikat',
      ),
      GamificationBadge(
        id: 'badge_harau',
        title: 'Rimba Harau',
        subtitle: 'Tebing Granit 500m',
        icon: Icons.lock_outline_rounded,
        color: AppColors.muted,
        isUnlocked: false,
        xpReward: 200,
        category: 'destination',
        requirementDescription: 'Check-in di Lembah Harau & Sarasah Bunta',
      ),
      GamificationBadge(
        id: 'badge_marapi',
        title: 'Master Marapi',
        subtitle: 'Kawah & Cadas Bersejarah',
        icon: Icons.lock_outline_rounded,
        color: AppColors.muted,
        isUnlocked: false,
        xpReward: 300,
        category: 'destination',
        requirementDescription: 'Kunjungi 3 pos pantau geologi Marapi',
      ),
    ];

    _activityHistory = [
      CheckInActivity(
        id: 'act-1',
        destinationTitle: 'Istano Basa Pagaruyung',
        region: 'Kab. Tanah Datar',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
        xpEarned: 50,
        pointsEarned: 100,
        note: 'Check-in GPS Terverifikasi (<500m) • Progres Tantangan 4/10',
        icon: Icons.pin_drop_rounded,
        iconColor: AppColors.success,
        imageAsset: 'assets/images/activity_pagaruyung.jpg',
      ),
      CheckInActivity(
        id: 'act-2',
        destinationTitle: 'Rute Geotourist Lembah Anai',
        region: 'Kab. Tanah Datar',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        xpEarned: 120,
        pointsEarned: 150,
        note: 'Jalur Rawan Berhasil Dilewati dengan Aman • Audio Guide Aktif',
        icon: Icons.hiking_rounded,
        iconColor: AppColors.pinNavigasiBiru,
        imageAsset: 'assets/images/activity_lembah_anai.jpg',
      ),
      CheckInActivity(
        id: 'act-3',
        destinationTitle: 'Penakluk Kelok 9',
        region: 'Kab. Lima Puluh Kota',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
        xpEarned: 200,
        pointsEarned: 200,
        note: 'Membuka Lencana Resmi Penakluk Kelok 9',
        icon: Icons.military_tech_rounded,
        iconColor: AppColors.warning,
        imageAsset: 'assets/images/activity_kelok9.jpg',
      ),
      CheckInActivity(
        id: 'act-4',
        destinationTitle: 'Nagari Tuo Pariangan',
        region: 'Kab. Tanah Datar',
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        xpEarned: 50,
        pointsEarned: 100,
        note: 'Check-in di Desa Wisata Tertua • Pemandu Adat Terhubung',
        icon: Icons.storefront_rounded,
        iconColor: AppColors.goldMinang,
        imageAsset: 'assets/images/activity_pariangan.jpg',
      ),
    ];
  }

  /// Eksekusi Check-In GPS Lokasi:
  /// - Memberikan XP (+50 s.d +150 XP) & Poin Geode (+100 s.d +250 GP)
  /// - Memperbarui indikator progres Challenge (contoh: 4/10 -> 5/10)
  /// - Otomatis mendeteksi kenaikan Level (Level Up)
  /// - Membuka lencana baru jika syarat terpenuhi
  /// - Menyinkronkan histori aktivitas
  CheckInResult performCheckIn({
    required String destinationTitle,
    required String region,
    int xpBonus = 50,
    int pointBonus = 100,
  }) {
    final oldGrade = currentGrade;
    _currentXp += xpBonus;
    _currentPoints += pointBonus;
    _totalCheckpoints++;

    // 1. Perbarui Challenge 10 Destinasi Nagari
    ChallengeMission? updatedPrimaryChallenge;
    GamificationBadge? newlyUnlockedBadge;

    if (_challenges.isNotEmpty) {
      final primary = _challenges.first;
      final newCount = (primary.currentCheckpoints + 1).clamp(0, primary.targetCheckpoints);
      final isNowCompleted = newCount >= primary.targetCheckpoints;

      _challenges[0] = primary.copyWith(
        currentCheckpoints: newCount,
        isCompleted: isNowCompleted,
      );
      updatedPrimaryChallenge = _challenges[0];

      // Jika tantangan 10 destinasi komplit, berikan reward ekstra
      if (isNowCompleted && !primary.isCompleted) {
        _currentXp += primary.xpReward;
        _currentPoints += primary.pointsReward;
      }
    }

    // 2. Evaluasi Level Up
    final newGrade = currentGrade;
    final bool leveledUp = newGrade.level > oldGrade.level;

    // Jika naik ke level berikutnya, buka lencana grade tersebut
    if (leveledUp) {
      final gradeBadgeId = 'badge_grade_${newGrade.level}';
      final badgeIdx = _badges.indexWhere((b) => b.id == gradeBadgeId);
      if (badgeIdx != -1 && !_badges[badgeIdx].isUnlocked) {
        _badges[badgeIdx] = _badges[badgeIdx].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        newlyUnlockedBadge = _badges[badgeIdx];
      }
    }

    // 3. Tambahkan ke Log Riwayat Aktivitas
    final newActivity = CheckInActivity(
      id: 'act-${DateTime.now().millisecondsSinceEpoch}',
      destinationTitle: destinationTitle,
      region: region,
      timestamp: DateTime.now(),
      xpEarned: xpBonus,
      pointsEarned: pointBonus,
      note: 'Check-in GPS Terverifikasi (<500m) • Progres Tantangan ${_challenges.first.currentCheckpoints}/${_challenges.first.targetCheckpoints}',
      icon: Icons.pin_drop_rounded,
      iconColor: AppColors.success,
    );
    _activityHistory.insert(0, newActivity);

    // 4. Beri tahu seluruh listener (Profile Screen, QrScanner, dll.)
    notifyListeners();

    return CheckInResult(
      success: true,
      destinationTitle: destinationTitle,
      region: region,
      xpEarned: xpBonus,
      pointsEarned: pointBonus,
      leveledUp: leveledUp,
      oldGrade: oldGrade,
      newGrade: newGrade,
      updatedChallenge: updatedPrimaryChallenge,
      unlockedBadge: newlyUnlockedBadge,
      message: 'Check-in berhasil! +$xpBonus XP dan +$pointBonus Poin Geode ditambahkan ke profil Anda.',
    );
  }

  /// Tambah XP Kustom (misal untuk demonstrasi kenaikan level instan)
  CheckInResult grantBonusXp(int xp, {String reason = 'Bonus Misi Petualang'}) {
    final oldGrade = currentGrade;
    _currentXp += xp;

    final newGrade = currentGrade;
    final bool leveledUp = newGrade.level > oldGrade.level;

    if (leveledUp) {
      final gradeBadgeId = 'badge_grade_${newGrade.level}';
      final badgeIdx = _badges.indexWhere((b) => b.id == gradeBadgeId);
      if (badgeIdx != -1 && !_badges[badgeIdx].isUnlocked) {
        _badges[badgeIdx] = _badges[badgeIdx].copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
      }
    }

    _activityHistory.insert(
      0,
      CheckInActivity(
        id: 'act-${DateTime.now().millisecondsSinceEpoch}',
        destinationTitle: reason,
        region: 'Sumatera Barat',
        timestamp: DateTime.now(),
        xpEarned: xp,
        pointsEarned: xp ~/ 2,
        note: reason,
        icon: Icons.stars_rounded,
        iconColor: AppColors.warning,
      ),
    );

    notifyListeners();

    return CheckInResult(
      success: true,
      destinationTitle: reason,
      region: 'Sumatera Barat',
      xpEarned: xp,
      pointsEarned: xp ~/ 2,
      leveledUp: leveledUp,
      oldGrade: oldGrade,
      newGrade: newGrade,
      message: 'Bonus +$xp XP berhasil ditambahkan!',
    );
  }

  /// Reset data ke kondisi awal
  void resetToBaseline() {
    _initializeData();
    notifyListeners();
  }
}
