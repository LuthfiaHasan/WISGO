import 'package:flutter/material.dart';

/// Model Titik Singgah / Checkpoint Riwayat Perjalanan (Strava-like)
class TravelCheckpoint {
  final String id;
  final String name;
  final String time;
  final bool isCompleted;
  final int elevationMeters;
  final String notes;
  final IconData icon;

  const TravelCheckpoint({
    required this.id,
    required this.name,
    required this.time,
    this.isCompleted = true,
    required this.elevationMeters,
    required this.notes,
    this.icon = Icons.check_circle_rounded,
  });
}

/// Model Lencana Pencapaian dalam Perjalanan
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

/// Model Riwayat Perjalanan & Experience Wisatawan (Konsep Strava)
class TravelExperience {
  final String id;
  final String title;
  final String destinationName;
  final String category;
  final String tripDate;
  final double distanceKm;
  final String durationFormatted;
  final int elevationGainMeters;
  final String avgPace;
  final int caloriesBurned;
  final List<TravelCheckpoint> checkpoints;
  final List<TripAchievementBadge> achievements;
  final String coverPhotoUrl;
  final String organizerName;
  final String storyNotes;
  final int likesCount;
  final String openTripId;
  final String promoQrUrl;

  const TravelExperience({
    required this.id,
    required this.title,
    required this.destinationName,
    required this.category,
    required this.tripDate,
    required this.distanceKm,
    required this.durationFormatted,
    required this.elevationGainMeters,
    required this.avgPace,
    required this.caloriesBurned,
    required this.checkpoints,
    required this.achievements,
    required this.coverPhotoUrl,
    required this.organizerName,
    required this.storyNotes,
    this.likesCount = 38,
    required this.openTripId,
    this.promoQrUrl = 'https://wisgo.sumbarprov.go.id/download',
  });

  int get completedCheckpointsCount =>
      checkpoints.where((cp) => cp.isCompleted).length;
}

/// Sample Data Experience Riwayat Perjalanan Wisatawan
final List<TravelExperience> kSampleTravelExperiences = [
  TravelExperience(
    id: 'exp-harau-01',
    title: 'Eksplorasi Tebing Lembah Harau & 3 Air Terjun Sarasah',
    destinationName: 'Lembah Harau, Lima Puluh Kota',
    category: 'Wisata Alam & Pegunungan',
    tripDate: '22 November 2026',
    distanceKm: 14.8,
    durationFormatted: '4j 25m',
    elevationGainMeters: 520,
    avgPace: '17:54 /km',
    caloriesBurned: 780,
    coverPhotoUrl:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
    organizerName: 'Rangga Minang Adventure (Verified)',
    storyNotes:
        'Melintasi 4 pos nagari, mendaki tebing granit Sarasah Bunta dan mandi di kolam alami Sarasah Murai. Jalur basah tetapi pemandangan kabut pagi sangat spektakuler.',
    likesCount: 54,
    openTripId: 'trip-harau-001',
    checkpoints: const [
      TravelCheckpoint(
        id: 'cp-1',
        name: 'Gerbang Nagari & Pos Registrasi Pokdarwis Harau',
        time: '08:30 WIB',
        elevationMeters: 510,
        notes: 'Verifikasi tiket resmi Perda & pembagian briefing rute',
        icon: Icons.flag_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-2',
        name: 'Sarasah Bunta & Tebing Gema Suara (Echo Point)',
        time: '10:15 WIB',
        elevationMeters: 620,
        notes: 'Gema suara alami memantul di dinding granit vertikal 100m',
        icon: Icons.water_drop_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-3',
        name: 'Sarasah Murai & Jalur Konservasi Burung Murai',
        time: '12:45 WIB',
        elevationMeters: 740,
        notes: 'Istirahat makan siang pangek masin & istirahat di gazebo adat',
        icon: Icons.forest_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-4',
        name: 'Puncak Tebing Harau Horizon (Finish Checkpoint)',
        time: '15:20 WIB',
        elevationMeters: 1030,
        notes: 'Menikmati lanskap lembah sawah hijau 360° dari bibir tebing',
        icon: Icons.emoji_events_rounded,
      ),
    ],
    achievements: const [
      TripAchievementBadge(
        id: 'ach-1',
        title: 'Penakluk Tebing Harau',
        description: 'Menyelesaikan rute elevasi >500 mdpl di dinding granit Harau',
        icon: Icons.landscape_rounded,
        ribbonColor: Color(0xFFD97706),
      ),
      TripAchievementBadge(
        id: 'ach-2',
        title: 'Trekker Tangguh 10K',
        description: 'Menempuh jarak jalan kaki lebih dari 10 kilometer di alam terbuka',
        icon: Icons.directions_walk_rounded,
        ribbonColor: Color(0xFF15803D),
      ),
      TripAchievementBadge(
        id: 'ach-3',
        title: 'Sahabat Alam Nagari',
        description: 'Zero waste & patuh pada etika kearifan lokal Minangkabau',
        icon: Icons.eco_rounded,
        ribbonColor: Color(0xFF0369A1),
      ),
    ],
  ),
  TravelExperience(
    id: 'exp-mandeh-02',
    title: 'Island Hopping Teluk Mandeh & Snorkeling Sirandah',
    destinationName: 'Kawasan Wisata Mandeh, Pesisir Selatan',
    category: 'Wisata Bahari & Pesisir',
    tripDate: '15 November 2026',
    distanceKm: 21.3,
    durationFormatted: '5j 10m',
    elevationGainMeters: 85,
    avgPace: '14:30 /km',
    caloriesBurned: 610,
    coverPhotoUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    organizerName: 'Pesona Bahari Mandeh (Verified)',
    storyNotes:
        'Menjelajahi perairan tenang Raja Ampat-nya Sumatera Barat. Snorkeling terumbu karang pulau Sironjong Gadang dan cliff jumping di Sironjong Ketek.',
    likesCount: 42,
    openTripId: 'trip-mandeh-002',
    checkpoints: const [
      TravelCheckpoint(
        id: 'cp-m1',
        name: 'Dermaga Tarusan & Safety Briefing Kapal',
        time: '08:00 WIB',
        elevationMeters: 5,
        notes: 'Pemasangan jaket pelampung dan cek sertifikasi nakhoda',
        icon: Icons.sailing_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-m2',
        name: 'Pulau Setan (Pantai Pasir Putih)',
        time: '09:40 WIB',
        elevationMeters: 12,
        notes: 'Eksplorasi garis pantai dan kelapa muda nagari',
        icon: Icons.beach_access_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-m3',
        name: 'Sironjong Ketek (Cliff Jumping Point 15m)',
        time: '11:30 WIB',
        elevationMeters: 22,
        notes: 'Tantangan lompat tebing dengan pengawasan guide profesional',
        icon: Icons.pool_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-m4',
        name: 'Hutan Mangrove & Air Terjun Gemuruh',
        time: '14:15 WIB',
        elevationMeters: 30,
        notes: 'Menyusuri muara sungai air tawar di tengah rimbun bakau',
        icon: Icons.waves_rounded,
      ),
    ],
    achievements: const [
      TripAchievementBadge(
        id: 'ach-m1',
        title: 'Penjelajah Bahari Mandeh',
        description: 'Mengunjungi 4 gugusan pulau teluk pesisir selatan',
        icon: Icons.scuba_diving_rounded,
        ribbonColor: Color(0xFF0284C7),
      ),
      TripAchievementBadge(
        id: 'ach-m2',
        title: 'Pemberani Cliff Jump',
        description: 'Menaklukkan loncatan tebing karang alami Sironjong Ketek',
        icon: Icons.bolt_rounded,
        ribbonColor: Color(0xFFEA580C),
      ),
    ],
  ),
  TravelExperience(
    id: 'exp-pagaruyung-03',
    title: 'Napak Tilas Falsafah Luhak Nan Tuo & Arsitektur Rangkiang',
    destinationName: 'Istano Basa Pagaruyung, Batusangkar',
    category: 'Sejarah & Warisan Minangkabau',
    tripDate: '08 November 2026',
    distanceKm: 6.2,
    durationFormatted: '2j 40m',
    elevationGainMeters: 110,
    avgPace: '25:40 /km',
    caloriesBurned: 390,
    coverPhotoUrl:
        'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=1200&q=80',
    organizerName: 'Pemandu Pusaka Nagari (Verified)',
    storyNotes:
        'Mempelajari 11 tiang penyangga gonjong kayu surian tanpa paku besi dan makna filosofis ukiran Saik Galamai serta Itiak Pulang Patang.',
    likesCount: 31,
    openTripId: 'trip-pagaruyung-003',
    checkpoints: const [
      TravelCheckpoint(
        id: 'cp-p1',
        name: 'Gerbang Utama Balairung Sari Istano Basa',
        time: '09:00 WIB',
        elevationMeters: 450,
        notes: 'Mengenakan busana adat Deta & Sasampiang Minangkabau',
        icon: Icons.account_balance_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-p2',
        name: 'Rangkiang Si Bayau-bayau & Si Sitinjau Laut',
        time: '10:15 WIB',
        elevationMeters: 455,
        notes: 'Observasi lumbung padi adat penyangga ketahanan pangan nagari',
        icon: Icons.grain_rounded,
      ),
      TravelCheckpoint(
        id: 'cp-p3',
        name: 'Lantai 3 Mahkota Anjuang Perak',
        time: '11:20 WIB',
        elevationMeters: 480,
        notes: 'Menyaksikan koleksi naskah kuno kerajaan & pemandangan Bukit Patah',
        icon: Icons.auto_stories_rounded,
      ),
    ],
    achievements: const [
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

/// Model Postingan Feed Komunitas Aplikasi WISGO (Gaya Instagram)
class CommunityPost {
  final String id;
  final String authorName;
  final String username;
  final String avatarUrl;
  final String destinationName;
  final String photoUrl;
  String caption;
  final double distanceKm;
  final String durationFormatted;
  final int elevationGainMeters;
  final int caloriesBurned;
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
    required this.photoUrl,
    required this.caption,
    required this.distanceKm,
    required this.durationFormatted,
    required this.elevationGainMeters,
    required this.caloriesBurned,
    required this.likesCount,
    this.isLiked = false,
    required this.commentsCount,
    required this.postedTime,
    required this.tags,
    this.isSelfPost = false,
    List<String>? comments,
  }) : comments = comments ?? [
          'Keren banget jalurnya! Lembah Harau emang ga pernah gagal 😍',
          'Guide lokalnya ramah, minggu depan mau ikut open trip ke sini lagi!',
        ];
}

/// Daftar Postingan Komunitas Aplikasi WISGO yang Siap Ditampilkan
final List<CommunityPost> kSampleCommunityPosts = [
  CommunityPost(
    id: 'post-01',
    authorName: 'Fajri Pratama',
    username: 'fajri_travels',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    destinationName: 'Lembah Harau, Lima Puluh Kota',
    photoUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1200&q=80',
    caption: 'Menikmati kabut pagi di dinding granit Lembah Harau dan segarnya Sarasah Bunta! Rute 14.8 km dengan tanjakan memuaskan. Mari jaga kelestarian alam Ranah Minang 🏔️🌿',
    distanceKm: 14.8,
    durationFormatted: '4j 25m',
    elevationGainMeters: 520,
    caloriesBurned: 780,
    likesCount: 142,
    isLiked: false,
    commentsCount: 18,
    postedTime: '2 jam lalu',
    tags: const ['#WisataSumbar', '#WISGO', '#LembahHarau', '#StravaTravel'],
    isSelfPost: false,
  ),
  CommunityPost(
    id: 'post-02',
    authorName: 'Annisa Fitriani',
    username: 'annisa_minang',
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    destinationName: 'Kawasan Wisata Bahari Mandeh, Pesisir Selatan',
    photoUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    caption: 'Snorkeling di Teluk Mandeh dan cliff jump di Sironjong Ketek! Airnya sejernih kaca. Wajib banget pakai aplikasi WISGO untuk pesan perahu tarif resmi Perda tanpa calo 🌊🤿',
    distanceKm: 8.5,
    durationFormatted: '3j 10m',
    elevationGainMeters: 45,
    caloriesBurned: 420,
    likesCount: 96,
    isLiked: true,
    commentsCount: 12,
    postedTime: '5 jam lalu',
    tags: const ['#TelukMandeh', '#WISGO', '#PesisirSelatan', '#RajaAmpatSumbar'],
    isSelfPost: false,
  ),
];
