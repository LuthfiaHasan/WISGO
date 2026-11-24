import 'package:flutter/material.dart';

/// Model Ringkasan Jejak WISGO Akun Wisatawan (BE-2 Summary)
class JejakWisgoSummary {
  final int visitedCount;
  final int totalDestinations;
  final int level;
  final String levelTitle;
  final int totalXp;

  const JejakWisgoSummary({
    this.visitedCount = 0,
    this.totalDestinations = 20,
    this.level = 1,
    this.levelTitle = 'Wisatawan Pemula',
    this.totalXp = 0,
  });

  factory JejakWisgoSummary.fromJson(Map<String, dynamic> json) {
    return JejakWisgoSummary(
      visitedCount: (json['visited_count'] as num?)?.toInt() ?? 0,
      totalDestinations: (json['total_destinations'] as num?)?.toInt() ?? 20,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelTitle: json['level_title']?.toString() ?? 'Wisatawan Pemula',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'visited_count': visitedCount,
        'total_destinations': totalDestinations,
        'level': level,
        'level_title': levelTitle,
        'total_xp': totalXp,
      };
}

/// Model Titik Singgah / Checkpoint Kunjungan Wisata
class TravelCheckpoint {
  final String id;
  final String name;
  final String time;
  final bool isCompleted;
  final String notes;
  final IconData icon;

  const TravelCheckpoint({
    required this.id,
    required this.name,
    required this.time,
    this.isCompleted = true,
    required this.notes,
    this.icon = Icons.check_circle_rounded,
  });

  factory TravelCheckpoint.fromJson(Map<String, dynamic> json) {
    return TravelCheckpoint(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      isCompleted: json['is_completed'] == true,
      notes: json['notes']?.toString() ?? '',
    );
  }
}

/// Model Lencana Pencapaian Kunjungan Wisata Jejak WISGO
class TripAchievementBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color ribbonColor;

  const TripAchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.ribbonColor = const Color(0xFFD97706),
  });
}

/// Model Data Jejak WISGO / Riwayat Kunjungan Wisata (Item 1-3 Jejak WISGO)
/// Diadaptasi dari konsep overlay Strava menjadi kampanye sosial promosi wisata Minangkabau.
/// TIDAK memuat metrik olahraga (tanpa pace, kalori, atau elevasi).
class TravelExperience {
  final String id;
  final String destinationId;
  final String destinationName;
  final String cityRegency;
  final String category;
  final String tripDate;
  final String coverPhotoUrl;
  final String? customPhotoUrl;
  final String source; // 'GPS_CHECKIN', 'TRIP_GO', 'TICKET_SCAN'
  final String openTripId;
  final String storyNotes;
  final String badgeTitle;
  final String levelTitle;
  final int stampNumber;
  final int visitedCount;
  final int totalDestinations;
  final List<TravelCheckpoint> checkpoints;
  final List<TripAchievementBadge> achievements;
  final int likesCount;
  final String promoQrUrl;

  const TravelExperience({
    required this.id,
    this.destinationId = '',
    required this.destinationName,
    this.cityRegency = 'Sumatera Barat',
    required this.category,
    required this.tripDate,
    required this.coverPhotoUrl,
    this.customPhotoUrl,
    this.source = 'GPS_CHECKIN',
    this.openTripId = '',
    required this.storyNotes,
    this.badgeTitle = 'Penjelajah Nagari',
    this.levelTitle = 'Panjelajah Nagari',
    this.stampNumber = 1,
    this.visitedCount = 1,
    this.totalDestinations = 20,
    this.checkpoints = const [],
    this.achievements = const [],
    this.likesCount = 24,
    this.promoQrUrl = 'https://wisgo.sumbarprov.go.id/download',
  });

  /// Judul tampilan utama
  String get title => 'Jejak di $destinationName';

  /// Foto aktif yang ditampilkan (foto jepretan sendiri jika ada, fallback ke foto katalog resmi)
  String get activePhotoUrl =>
      (customPhotoUrl != null && customPhotoUrl!.isNotEmpty)
          ? customPhotoUrl!
          : coverPhotoUrl;

  /// Jumlah pos atau titik singgah yang telah diselesaikan
  int get completedCheckpointsCount =>
      checkpoints.where((cp) => cp.isCompleted).length;

  /// Buat copy dengan opsi ganti foto pribadi
  TravelExperience copyWith({
    String? customPhotoUrl,
    String? storyNotes,
    int? likesCount,
  }) {
    return TravelExperience(
      id: id,
      destinationId: destinationId,
      destinationName: destinationName,
      cityRegency: cityRegency,
      category: category,
      tripDate: tripDate,
      coverPhotoUrl: coverPhotoUrl,
      customPhotoUrl: customPhotoUrl ?? this.customPhotoUrl,
      source: source,
      openTripId: openTripId,
      storyNotes: storyNotes ?? this.storyNotes,
      badgeTitle: badgeTitle,
      levelTitle: levelTitle,
      stampNumber: stampNumber,
      visitedCount: visitedCount,
      totalDestinations: totalDestinations,
      checkpoints: checkpoints,
      achievements: achievements,
      likesCount: likesCount ?? this.likesCount,
      promoQrUrl: promoQrUrl,
    );
  }

  /// Deserialisasi dari response API BE-2 (`GET /api/v1/gamification/trips`)
  factory TravelExperience.fromJson(
    Map<String, dynamic> json, {
    JejakWisgoSummary? summary,
    int stampIndex = 1,
  }) {
    final visitedAtRaw = json['visited_at']?.toString() ?? '';
    String formattedDate = 'Hari ini';
    if (visitedAtRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(visitedAtRaw).toLocal();
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        formattedDate = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        formattedDate = visitedAtRaw;
      }
    }

    return TravelExperience(
      id: json['id']?.toString() ?? '',
      destinationId: json['destination_id']?.toString() ?? '',
      destinationName: json['destination_name']?.toString() ?? 'Destinasi Wisata',
      cityRegency: json['city_regency']?.toString() ?? 'Sumatera Barat',
      category: json['category']?.toString() ?? 'Wisata Alam',
      tripDate: formattedDate,
      coverPhotoUrl: json['cover_image']?.toString() ??
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
      source: json['source']?.toString() ?? 'GPS_CHECKIN',
      openTripId: json['open_trip_id']?.toString() ?? '',
      storyNotes: json['story_notes']?.toString() ??
          'Pengalaman tak terlupakan menjelajahi keindahan Ranah Minang bersama WISGO.',
      badgeTitle: json['badge_title']?.toString() ?? 'Penjelajah Nagari',
      levelTitle: summary?.levelTitle ?? 'Panjelajah Nagari',
      stampNumber: stampIndex,
      visitedCount: summary?.visitedCount ?? stampIndex,
      totalDestinations: summary?.totalDestinations ?? 20,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination_id': destinationId,
        'destination_name': destinationName,
        'city_regency': cityRegency,
        'category': category,
        'trip_date': tripDate,
        'cover_image': coverPhotoUrl,
        'source': source,
        'open_trip_id': openTripId,
        'story_notes': storyNotes,
        'badge_title': badgeTitle,
      };
}

/// Data Sampel Resmi Jejak WISGO (Digunakan saat Pengguna Mengaktifkan Demo / Mode Terverifikasi)
final List<TravelExperience> kSampleTravelExperiences = [
  const TravelExperience(
    id: 'jwk-001',
    destinationId: 'dest-001',
    destinationName: 'Lembah Harau',
    cityRegency: 'Kab. Lima Puluh Kota',
    category: 'Alam & Geopark',
    tripDate: '24 Nov 2026',
    stampNumber: 4,
    visitedCount: 4,
    totalDestinations: 20,
    levelTitle: 'Panjelajah Nagari',
    badgeTitle: 'Penakluk Tebing Harau',
    coverPhotoUrl:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
    storyNotes:
        'Melintasi 4 pos nagari, menikmati kemegahan tebing batuan granit Sarasah Bunta dan segarnya air terjun Sarasah Murai. Kabut pagi di Lembah Harau luar biasa!',
    likesCount: 54,
    source: 'GPS_CHECKIN',
    openTripId: 'TRIP-HARAU-01',
    checkpoints: [
      TravelCheckpoint(
        id: 'cp-1',
        name: 'Gerbang Nagari & Pos Registrasi Pokdarwis Harau',
        time: '08:30 WIB',
        notes: 'Verifikasi tiket resmi Perda & pembagian briefing rute',
        icon: Icons.flag_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-2',
        name: 'Sarasah Bunta & Tebing Gema Suara (Echo Point)',
        time: '10:15 WIB',
        notes: 'Gema suara alami memantul di dinding granit vertikal 100m',
        icon: Icons.water_drop_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-3',
        name: 'Sarasah Murai & Jalur Konservasi Burung Murai',
        time: '12:45 WIB',
        notes: 'Istirahat makan siang pangek masin & santai di gazebo adat',
        icon: Icons.forest_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-4',
        name: 'Puncak Tebing Harau Horizon (Spot Panorama)',
        time: '15:20 WIB',
        notes: 'Menikmati lanskap lembah sawah hijau 360° dari bibir tebing',
        icon: Icons.emoji_events_rounded,
      ),
    ],
    achievements: [
      TripAchievementBadge(
        id: 'ach-1',
        title: 'Penakluk Tebing Harau',
        description: 'Tuntas menjelajahi dinding batuan granit Harau Geopark',
        icon: Icons.landscape_rounded,
        ribbonColor: Color(0xFFD97706),
      ),
      TripAchievementBadge(
        id: 'ach-2',
        title: 'Sahabat Alam Nagari',
        description: 'Zero waste & patuh etika kearifan lokal Minangkabau',
        icon: Icons.eco_rounded,
        ribbonColor: Color(0xFF0369A1),
      ),
    ],
  ),
  const TravelExperience(
    id: 'jwk-002',
    destinationId: 'dest-005',
    destinationName: 'Kawasan Wisata Mandeh',
    cityRegency: 'Kab. Pesisir Selatan',
    category: 'Alam & Geopark',
    tripDate: '15 Nov 2026',
    stampNumber: 3,
    visitedCount: 4,
    totalDestinations: 20,
    levelTitle: 'Panjelajah Nagari',
    badgeTitle: 'Penjelajah Bahari Mandeh',
    coverPhotoUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    storyNotes:
        'Menjelajahi perairan tenang Raja Ampat-nya Ranah Minang. Snorkeling terumbu karang pulau Sironjong Gadang dan cliff jumping di Sironjong Ketek.',
    likesCount: 42,
    source: 'TRIP_GO',
    openTripId: 'TRIP-MANDEH-02',
    checkpoints: [
      TravelCheckpoint(
        id: 'cp-m1',
        name: 'Dermaga Tarusan & Safety Briefing Kapal',
        time: '08:00 WIB',
        notes: 'Pemasangan jaket pelampung dan cek sertifikasi nakhoda',
        icon: Icons.sailing_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-m2',
        name: 'Pulau Setan (Pantai Pasir Putih)',
        time: '09:40 WIB',
        notes: 'Eksplorasi garis pantai dan kelapa muda nagari',
        icon: Icons.beach_access_rounded,
      ),
    ],
    achievements: [
      TripAchievementBadge(
        id: 'ach-m1',
        title: 'Penjelajah Bahari Mandeh',
        description: 'Mengunjungi gugusan teluk pulau pesisir selatan',
        icon: Icons.scuba_diving_rounded,
        ribbonColor: Color(0xFF0284C7),
      ),
    ],
  ),
  const TravelExperience(
    id: 'jwk-003',
    destinationId: 'dest-002',
    destinationName: 'Istano Basa Pagaruyung',
    cityRegency: 'Kab. Tanah Datar',
    category: 'Budaya & Nagari',
    tripDate: '08 Nov 2026',
    stampNumber: 2,
    visitedCount: 4,
    totalDestinations: 20,
    levelTitle: 'Panjelajah Nagari',
    badgeTitle: 'Ksatria Adat Minangkabau',
    coverPhotoUrl:
        'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1200&q=80',
    storyNotes:
        'Mempelajari 11 tiang penyangga gonjong kayu surian tanpa paku besi dan makna filosofis ukiran Saik Galamai serta lumbung padi Rangkiang.',
    likesCount: 31,
    source: 'GPS_CHECKIN',
    checkpoints: [
      TravelCheckpoint(
        id: 'cp-p1',
        name: 'Gerbang Utama Balairung Sari Istano Basa',
        time: '09:00 WIB',
        notes: 'Mengenakan busana adat Deta & Sasampiang Minangkabau',
        icon: Icons.account_balance_rounded,
      ),
    ],
    achievements: [
      TripAchievementBadge(
        id: 'ach-p1',
        title: 'Ksatria Adat Minangkabau',
        description: 'Menuntaskan pemahaman falsafah Adat Basandi Syarak',
        icon: Icons.military_tech_rounded,
        ribbonColor: Color(0xFF7C2D12),
      ),
    ],
  ),
];

/// Model Postingan Feed Komunitas Kampanye Wisata Jejak WISGO
class CommunityPost {
  final String id;
  final String authorName;
  final String username;
  final String avatarUrl;
  final String destinationName;
  final String cityRegency;
  final String photoUrl;
  String caption;
  final String badgeTitle;
  int likesCount;
  bool isLiked;
  int commentsCount;
  final String postedTime;
  final List<String> tags;
  final bool isSelfPost;
  final List<String> comments;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.username,
    required this.avatarUrl,
    required this.destinationName,
    this.cityRegency = 'Sumatera Barat',
    required this.photoUrl,
    required this.caption,
    this.badgeTitle = 'Panjelajah Nagari',
    required this.likesCount,
    this.isLiked = false,
    required this.commentsCount,
    required this.postedTime,
    required this.tags,
    this.isSelfPost = false,
    List<String>? comments,
  }) : comments = comments ?? [
          'Keren banget fotonya! Lembah Harau emang ga pernah gagal 😍',
          'Ayo liburan bareng ke Sumbar pakai WISGO!',
        ];
}

/// Daftar Postingan Komunitas Kampanye Wisata Jejak WISGO
final List<CommunityPost> kSampleCommunityPosts = [
  CommunityPost(
    id: 'post-01',
    authorName: 'Fajri Pratama',
    username: 'fajri_travels',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    destinationName: 'Lembah Harau',
    cityRegency: 'Kab. Lima Puluh Kota',
    photoUrl:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
    caption:
        'Menikmati kabut pagi di dinding granit Lembah Harau dan segarnya Sarasah Bunta! Stempel #4 Jejak WISGO berhasil dibuka. Mari jelajah Sumbar bersama WISGO! 🏔️✨',
    badgeTitle: 'Penakluk Tebing Harau',
    likesCount: 142,
    isLiked: false,
    commentsCount: 18,
    postedTime: '2 jam lalu',
    tags: const ['#JejakWISGO', '#WisataSumbar', '#LembahHarau', '#Minangkabau'],
    isSelfPost: false,
  ),
  CommunityPost(
    id: 'post-02',
    authorName: 'Annisa Fitriani',
    username: 'annisa_minang',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    destinationName: 'Kawasan Wisata Mandeh',
    cityRegency: 'Kab. Pesisir Selatan',
    photoUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    caption:
        'Snorkeling di Teluk Mandeh dan cliff jump di Sironjong Ketek! Airnya sejernih kaca. Wajib share stiker Jejak WISGO ke IG Story biar temen-temen tau indahnya pesisir Sumbar 🌊🤿',
    badgeTitle: 'Penjelajah Bahari Mandeh',
    likesCount: 96,
    isLiked: true,
    commentsCount: 12,
    postedTime: '5 jam lalu',
    tags: const ['#JejakWISGO', '#TelukMandeh', '#PesisirSelatan', '#RajaAmpatSumbar'],
    isSelfPost: false,
  ),
];
