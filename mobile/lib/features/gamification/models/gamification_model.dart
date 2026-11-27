import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 5 Tingkatan (Grade) Petualang WISGO:
/// Level 1 – Beginner: 0–299 XP (awal / 1 perjalanan atau check-in pertama)
/// Level 2 – Explorer: 300–699 XP
/// Level 3 – Adventurer: 700–1.199 XP
/// Level 4 – Trailblazer: 1.200–1.999 XP
/// Level 5 – Wanderer: 2.000+ XP (Puncak Penjelajah Ranah Minang)
class AdventurerGrade {
  final int level;
  final String name;
  final String title;
  final int minXp;
  final int maxXp; // Nilai batas atas level ini, atau 2000 untuk Wanderer
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;
  final String description;
  final String perks;

  const AdventurerGrade({
    required this.level,
    required this.name,
    required this.title,
    required this.minXp,
    required this.maxXp,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    required this.description,
    required this.perks,
  });

  static const AdventurerGrade level1Beginner = AdventurerGrade(
    level: 1,
    name: 'Beginner',
    title: 'Level 1 – Beginner',
    minXp: 0,
    maxXp: 300,
    icon: Icons.hiking_rounded,
    primaryColor: AppColors.muted,
    accentColor: AppColors.muted,
    description: 'Langkah awal penjelajahan di Ranah Minang.',
    perks: 'Akses Peta Wisata & Check-in GPS Pertama',
  );

  static const AdventurerGrade level2Explorer = AdventurerGrade(
    level: 2,
    name: 'Explorer',
    title: 'Level 2 – Explorer',
    minXp: 300,
    maxXp: 700,
    icon: Icons.explore_rounded,
    primaryColor: AppColors.pinNavigasiBiru,
    accentColor: AppColors.infoBorder,
    description: 'Menjelajah berbagai destinasi nagari dan rute budaya.',
    perks: 'Stempel Paspor Digital & Diskon Tiket Nagari 5%',
  );

  static const AdventurerGrade level3Adventurer = AdventurerGrade(
    level: 3,
    name: 'Adventurer',
    title: 'Level 3 – Adventurer',
    minXp: 700,
    maxXp: 1200,
    icon: Icons.terrain_rounded,
    primaryColor: AppColors.success,
    accentColor: AppColors.success,
    description: 'Menaklukkan jalur alam, air terjun, dan lembah ikonik.',
    perks: 'Audio Guide Budaya Offline & Lencana Khusus Geotourist',
  );

  static const AdventurerGrade level4Trailblazer = AdventurerGrade(
    level: 4,
    name: 'Trailblazer',
    title: 'Level 4 – Trailblazer',
    minXp: 1200,
    maxXp: 2000,
    icon: Icons.stars_rounded,
    primaryColor: AppColors.warning,
    accentColor: AppColors.warning,
    description: 'Perintis rute terpencil & penjelajah aktif Sumatera Barat.',
    perks: 'Tier Platinum Geode Ranking & Rekomendasi Khusus Dispar',
  );

  static const AdventurerGrade level5Wanderer = AdventurerGrade(
    level: 5,
    name: 'Wanderer',
    title: 'Level 5 – Wanderer',
    minXp: 2000,
    maxXp: 3000,
    icon: Icons.workspace_premium_rounded,
    primaryColor: AppColors.goldMinang,
    accentColor: AppColors.goldSoft,
    description: 'Puncak Penjelajah Agung Ranah Minang sejati.',
    perks: 'Apresiasi Pemprov Sumbar, Paspor Emas & Peringkat Elit',
  );

  static const List<AdventurerGrade> allGrades = [
    level1Beginner,
    level2Explorer,
    level3Adventurer,
    level4Trailblazer,
    level5Wanderer,
  ];

  static AdventurerGrade fromXp(int xp) {
    if (xp >= 2000) return level5Wanderer;
    if (xp >= 1200) return level4Trailblazer;
    if (xp >= 700) return level3Adventurer;
    if (xp >= 300) return level2Explorer;
    return level1Beginner;
  }
}

/// Model Lencana (Badge) Gamifikasi
class GamificationBadge {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final String category; // 'grade' | 'destination' | 'challenge' | 'culture'
  final String requirementDescription;

  const GamificationBadge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 100,
    this.category = 'destination',
    required this.requirementDescription,
  });

  GamificationBadge copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return GamificationBadge(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward,
      category: category,
      requirementDescription: requirementDescription,
    );
  }
}

/// Model Misi Tantangan (Challenge Mission)
class ChallengeMission {
  final String id;
  final String title;
  final String tagline;
  final String description;
  final String region;
  final int targetCheckpoints;
  final int currentCheckpoints;
  final int xpReward;
  final int pointsReward;
  final bool isCompleted;
  final String badgeRewardId;
  final List<String> checkpointLocations;

  const ChallengeMission({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.region,
    required this.targetCheckpoints,
    required this.currentCheckpoints,
    required this.xpReward,
    required this.pointsReward,
    this.isCompleted = false,
    required this.badgeRewardId,
    required this.checkpointLocations,
  });

  double get progressRatio => targetCheckpoints > 0
      ? (currentCheckpoints / targetCheckpoints).clamp(0.0, 1.0)
      : 0.0;

  int get progressPercent => (progressRatio * 100).toInt();

  ChallengeMission copyWith({
    int? currentCheckpoints,
    bool? isCompleted,
  }) {
    final newCount = currentCheckpoints ?? this.currentCheckpoints;
    final done = isCompleted ?? (newCount >= targetCheckpoints);
    return ChallengeMission(
      id: id,
      title: title,
      tagline: tagline,
      description: description,
      region: region,
      targetCheckpoints: targetCheckpoints,
      currentCheckpoints: newCount,
      xpReward: xpReward,
      pointsReward: pointsReward,
      isCompleted: done,
      badgeRewardId: badgeRewardId,
      checkpointLocations: checkpointLocations,
    );
  }
}

/// Riwayat Aktivitas & Check-In Log
class CheckInActivity {
  final String id;
  final String destinationTitle;
  final String region;
  final DateTime timestamp;
  final int xpEarned;
  final int pointsEarned;
  final String note;
  final IconData icon;
  final Color iconColor;
  final String? imageAsset;

  const CheckInActivity({
    required this.id,
    required this.destinationTitle,
    required this.region,
    required this.timestamp,
    required this.xpEarned,
    required this.pointsEarned,
    required this.note,
    this.icon = Icons.pin_drop_rounded,
    this.iconColor = AppColors.success,
    this.imageAsset,
  });

  /// Mengembalikan path aset gambar lokal yang paling sesuai dengan destinasi.
  String get resolvedImageAsset =>
      imageAsset ?? resolveAssetForDestination(destinationTitle);

  static String resolveAssetForDestination(String title) {
    final q = title.toLowerCase();
    if (q.contains('pagaruyung') || q.contains('istano')) {
      return 'assets/images/activity_pagaruyung.jpg';
    }
    if (q.contains('lembah anai') || q.contains('anai') || q.contains('air terjun')) {
      return 'assets/images/activity_lembah_anai.jpg';
    }
    if (q.contains('kelok 9') || q.contains('kelok sembilan')) {
      return 'assets/images/activity_kelok9.jpg';
    }
    if (q.contains('pariangan') || q.contains('nagari tuo')) {
      return 'assets/images/activity_pariangan.jpg';
    }
    if (q.contains('mandeh') || q.contains('pantai') || q.contains('pulau')) {
      return 'assets/images/splash_bg_3.jpg';
    }
    if (q.contains('harau') || q.contains('sarasah')) {
      return 'assets/images/splash_bg_2.jpg';
    }
    return 'assets/images/splash_bg_1.jpg';
  }
}

/// Hasil Eksekusi Check-In
class CheckInResult {
  final bool success;
  final String destinationTitle;
  final String region;
  final int xpEarned;
  final int pointsEarned;
  final bool leveledUp;
  final AdventurerGrade oldGrade;
  final AdventurerGrade newGrade;
  final ChallengeMission? updatedChallenge;
  final GamificationBadge? unlockedBadge;
  final String message;

  const CheckInResult({
    required this.success,
    required this.destinationTitle,
    required this.region,
    required this.xpEarned,
    required this.pointsEarned,
    required this.leveledUp,
    required this.oldGrade,
    required this.newGrade,
    this.updatedChallenge,
    this.unlockedBadge,
    required this.message,
  });
}
