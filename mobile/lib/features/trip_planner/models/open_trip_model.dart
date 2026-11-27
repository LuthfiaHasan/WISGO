import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Peran pengguna aktif pada fitur Trip Go (Wisatawan/Peserta vs Penyelenggara/Host)
enum TripGoRole {
  participant,
  organizer,
}

/// Status verifikasi admin untuk pengajuan Open Trip baru oleh penyelenggara
enum TripVerificationStatus {
  pendingAdmin,
  approved,
  rejected,
}

/// Bridge notifikasi status verifikasi Admin (Disetujui / Ditolak) ke Pusat Notifikasi
class OrganizerNotificationBridge {
  OrganizerNotificationBridge._();
  static final ValueNotifier<Map<String, dynamic>?> latestNotif =
      ValueNotifier<Map<String, dynamic>?>(null);

  static void emit({
    required String tripId,
    required String tripTitle,
    required bool approved,
    String reason = '',
  }) {
    latestNotif.value = {
      'id': 'notif_admin_${tripId}_${DateTime.now().millisecondsSinceEpoch}',
      'title': approved
          ? 'Open Trip Disetujui Admin ✓'
          : 'Pengajuan Open Trip Ditolak',
      'message': approved
          ? 'Selamat! "$tripTitle" telah diverifikasi Admin WISGO. Menu Manajemen Penyelenggara kini aktif.'
          : 'Pengajuan "$tripTitle" ditolak Admin: ${reason.isEmpty ? 'Dokumen KTP/Lisensi perlu diperbaiki.' : reason}',
      'time': 'Baru saja',
      'isRead': false,
      'type': approved ? 'opentrip' : 'admin_rejected',
      'tripId': tripId,
    };
  }
}

/// Model Penyelenggara Terverifikasi (Item 2 Spesifikasi Trip Go)
class VerifiedOrganizer {
  final String id;
  final String name;
  final bool isVerified;
  final String verificationBadge;
  final String ktpStatus;
  final String ktpUploadStatus;
  final String faceVerificationStatus;
  final String licenseNumber;
  final String specialCompetency;
  final double rating;
  final int completedTrips;
  final String phone;
  final String socialMedia;
  final String experienceYears;
  final String organizationName;
  final String escrowProtectionNote;

  const VerifiedOrganizer({
    required this.id,
    required this.name,
    this.isVerified = true,
    this.verificationBadge = 'Penyelenggara Terverifikasi WISGO',
    this.ktpStatus = 'Terverifikasi e-KTP Dukcapil RI',
    this.ktpUploadStatus = 'Dokumen e-KTP Terunggah & Valid',
    this.faceVerificationStatus = 'Verifikasi Wajah (Liveness Biometrik) Lolos',
    required this.licenseNumber,
    this.specialCompetency = 'Sertifikasi P3K & Wilderness First Aid BNSP',
    this.rating = 4.95,
    this.completedTrips = 38,
    required this.phone,
    this.socialMedia = '@rahmathidayat_guide (Instagram)',
    this.experienceYears = '4+ Tahun Pengalaman Pemandu Wisata Alam',
    required this.organizationName,
    this.escrowProtectionNote =
        'Dana peserta ditahan di Rekening Penampung (Escrow) WISGO dan baru diteruskan ke penyelenggara setelah trip selesai dan terkonfirmasi.',
  });
}

/// Model Kebutuhan Perjalanan (Item 1 Trip Planner)
class TripReadinessItem {
  final String id;
  final String title;
  final String description;
  bool isDone;
  final String category; // 'Transportasi', 'Perizinan', 'Akomodasi', 'Logistik', 'Keamanan'

  TripReadinessItem({
    required this.id,
    required this.title,
    required this.description,
    this.isDone = false,
    required this.category,
  });
}

/// Model Pembagian Jobdesk Tim (Item 2 Trip Planner)
class TripJobdeskItem {
  final String id;
  final String roleTitle;
  final String picName;
  final String picRole; // 'Penyelenggara' atau 'Peserta'
  final List<String> tasks;
  String status; // 'Siap', 'Sedang Berjalan', 'Selesai'
  final IconData icon;

  TripJobdeskItem({
    required this.id,
    required this.roleTitle,
    required this.picName,
    this.picRole = 'Peserta',
    required this.tasks,
    this.status = 'Siap',
    required this.icon,
  });
}

/// Model Checklist Barang Bawaan Peserta (Item 3 Trip Planner)
class TripPackingItem {
  final String id;
  final String category; // 'Pakaian & Alas Kaki', 'Kesehatan & P3K', 'Elektronik & Gadget', 'Dokumen & Ibadah'
  final String itemName;
  final String notes;
  bool isPacked;

  TripPackingItem({
    required this.id,
    required this.category,
    required this.itemName,
    this.notes = '',
    this.isPacked = false,
  });
}

/// Model Itinerary Jam-per-Jam (Item 4 Trip Planner)
class TripItineraryStep {
  final String time;
  final String activity;
  final String location;
  final String notes;
  String status; // 'Selesai', 'Sedang Berlangsung', 'Akan Datang'
  final IconData icon;

  TripItineraryStep({
    required this.time,
    required this.activity,
    required this.location,
    required this.notes,
    this.status = 'Akan Datang',
    required this.icon,
  });
}

/// Model Komunikasi & Obrolan Tim (Item 5 Trip Planner)
class TripChatMessage {
  final String id;
  final String senderName;
  final String senderRole; // 'Host' atau 'Peserta'
  final String message;
  final String timestamp;
  final bool isPinnedNotice;

  TripChatMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isPinnedNotice = false,
  });
}

/// Model Ketentuan & SOP Aktivitas Luar Aplikasi (Item 7 Open Trip)
class OfflineTripRule {
  final String title;
  final String ruleDescription;
  final String iconCode;

  const OfflineTripRule({
    required this.title,
    required this.ruleDescription,
    required this.iconCode,
  });
}

/// Model Struktur Pengelompokan Kategori Perjalanan Resmi WISGO
class TravelCategoryGroup {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color badgeBgColor;
  final List<String> popularKeywords;

  const TravelCategoryGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.badgeBgColor,
    required this.popularKeywords,
  });
}

/// 5 Kluster Struktur Kategori Perjalanan Resmi (Poin 6: Master Categories)
const List<TravelCategoryGroup> kStandardTravelCategories = [
  TravelCategoryGroup(
    id: 'cat-alam-geopark',
    name: 'Alam & Geopark',
    description: 'Eksplorasi puncak gunung api, tebing granit purba, air terjun alami, ngarai, dan geopark Sumatera Barat.',
    icon: Icons.terrain_rounded,
    primaryColor: AppColors.forest,
    badgeBgColor: AppColors.sage,
    popularKeywords: [
      'harau', 'sarasah', 'tebing', 'gunung', 'marapi', 'singgalang',
      'talang', 'tandikat', 'ngarai', 'sianok', 'anai', 'lawang', 'maninjau',
      'mandeh', 'pasumpahan', 'pagang', 'gandoriah', 'danau', 'geopark'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-budaya-nagari',
    name: 'Budaya & Nagari',
    description: 'Warisan sejarah Minangkabau, istano basa, rumah gadang, desa adat tertua, dan seni tradisi.',
    icon: Icons.account_balance_rounded,
    primaryColor: AppColors.terracotta,
    badgeBgColor: AppColors.dangerBg,
    popularKeywords: [
      'pagaruyung', 'istano', 'rumah gadang', 'jam gadang', 'pariangan',
      'pandai sikek', 'desa adat', 'nagari', 'tenun', 'ukiran', 'cagar budaya'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-hidden-gem',
    name: 'Hidden Gem',
    description: 'Destinasi alami tersembunyi yang asri, minim keramaian, dan membutuhkan edukasi kelestarian tinggi.',
    icon: Icons.diamond_outlined,
    primaryColor: AppColors.success,
    badgeBgColor: AppColors.successBg,
    popularKeywords: [
      'nyarai', 'lubuk gamaran', 'batu kapal', 'jembatan akar', 'bayang',
      'silokek', 'ngalau basurek', 'madobag', 'mentawai', 'hidden gem'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-religi',
    name: 'Religi',
    description: 'Wisata masjid bersejarah berarsitektur Minang, surau tarekat, dan jejak peradaban Islam Minangkabau.',
    icon: Icons.mosque_rounded,
    primaryColor: AppColors.success,
    badgeBgColor: AppColors.successBg,
    popularKeywords: [
      'masjid raya', 'masjid', 'surau', 'religi', 'islam', 'tarusan'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-kuliner',
    name: 'Kuliner',
    description: 'Sentra kuliner Minangkabau otentik, los lambuang pasar tradisional, rumah makan legendaris, dan sentra rendang.',
    icon: Icons.restaurant_rounded,
    primaryColor: AppColors.terracotta,
    badgeBgColor: AppColors.coralTint,
    popularKeywords: [
      'kapau', 'rendang', 'payakumbuh', 'los lambuang', 'sate', 'ikan bilih',
      'singkarak', 'kopi kawa', 'kuliner', 'pasar ateh'
    ],
  ),
];

/// Fungsi Penentuan Kategori Otomatis Berdasarkan Destinasi Tunggal (Item 2 Open Trip & Kategori Perjalanan)
String determineCategoryForDestination(String destinationName) {
  final lower = destinationName.toLowerCase();

  for (final cat in kStandardTravelCategories) {
    for (final kw in cat.popularKeywords) {
      if (lower.contains(kw)) {
        return cat.name;
      }
    }
  }

  // Fallback default kategori resmi
  return 'Alam & Geopark';
}

/// Model Peserta Terdaftar beserta Kelengkapan Data & Persiapan untuk Penyelenggara
class OpenTripParticipant {
  final String userId;
  final String bookingCode;
  final String fullName;
  final String phoneNumber;
  final String emergencyContact;
  final int seatCount;
  final String paymentMethod;
  final int totalPaid;
  final String specialNotes;
  final String joinedAt;
  bool isScheduleReady;
  int readinessDone;
  int readinessTotal;
  int packingDone;
  int packingTotal;
  bool isFinalized;
  bool isCheckedInAtMeetingPoint;

  OpenTripParticipant({
    required this.userId,
    this.bookingCode = 'TRIP-RESMI',
    required this.fullName,
    required this.phoneNumber,
    this.emergencyContact = '-',
    this.seatCount = 1,
    this.paymentMethod = 'WISGO_PAY',
    this.totalPaid = 135000,
    this.specialNotes = '',
    required this.joinedAt,
    this.isScheduleReady = false,
    this.readinessDone = 0,
    this.readinessTotal = 6,
    this.packingDone = 0,
    this.packingTotal = 10,
    this.isFinalized = false,
    this.isCheckedInAtMeetingPoint = false,
  });

  factory OpenTripParticipant.fromJson(Map<String, dynamic> json) {
    return OpenTripParticipant(
      userId: json['user_id']?.toString() ?? '',
      bookingCode: json['booking_code']?.toString() ?? 'TRIP-RESMI',
      fullName: json['full_name']?.toString() ?? 'Peserta',
      phoneNumber: json['phone_number']?.toString() ?? '',
      emergencyContact: json['emergency_contact']?.toString() ?? '-',
      seatCount: (json['seat_count'] as num?)?.toInt() ?? 1,
      paymentMethod: json['payment_method']?.toString() ?? 'WISGO_PAY',
      totalPaid: (json['total_paid'] as num?)?.toInt() ?? 135000,
      specialNotes: json['special_notes']?.toString() ?? '',
      joinedAt: json['joined_at']?.toString() ?? '',
    );
  }
}

/// Model Ulasan & Rating untuk Penyelenggara setelah Open Trip selesai
class OrganizerReview {
  final String id;
  final String organizerId;
  final String organizerName;
  final String tripTitle;
  final String reviewerName;
  final int rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  const OrganizerReview({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.tripTitle,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
  });
}

/// Store terpusat untuk Rating, Ulasan & Pencapaian Akun Penyelenggara
class OrganizerRatingStore extends ChangeNotifier {
  OrganizerRatingStore._();
  static final OrganizerRatingStore instance = OrganizerRatingStore._();

  final List<OrganizerReview> _reviews = [
    OrganizerReview(
      id: 'rev-init-1',
      organizerId: 'ORG-01',
      organizerName: 'Rahmat Hidayat (Guide Nagari)',
      tripTitle: 'Jelajah Lembah Harau & Air Terjun Sarasah Bunta',
      reviewerName: 'Nadia Putri',
      rating: 5,
      comment:
          'Pemandunya sangat ramah, tepat waktu di titik kumpul, dan penjelasan sejarah Lembah Harau sangat menarik!',
      tags: const ['Tepat Waktu', 'Pemandu Ramah', 'Rute Aman'],
      createdAt: DateTime(2026, 11, 20),
    ),
  ];

  int _completedTripsAsOrganizer = 1;

  List<OrganizerReview> get allReviews => List.unmodifiable(_reviews);
  int get completedTripsAsOrganizer => _completedTripsAsOrganizer;

  List<OrganizerReview> reviewsForOrganizer(String organizerId) =>
      _reviews.where((r) => r.organizerId == organizerId).toList();

  double averageRatingForOrganizer(String organizerId, double fallback) {
    final list = reviewsForOrganizer(organizerId);
    if (list.isEmpty) return fallback;
    final sum = list.fold<int>(0, (acc, r) => acc + r.rating);
    return double.parse((sum / list.length).toStringAsFixed(2));
  }

  double get overallAccountRating {
    if (_reviews.isEmpty) return 4.95;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return double.parse((sum / _reviews.length).toStringAsFixed(2));
  }

  void markOrganizerTripCompleted() {
    _completedTripsAsOrganizer++;
    notifyListeners();
  }

  void addReview(OrganizerReview review) {
    _reviews.insert(0, review);
    notifyListeners();
  }
}

/// Model Data Trip Go Lengkap (Item 1-10 Spesifikasi Trip Go)
class OpenTripItem {
  final String id;
  final String userId; // ID Host pembuat trip
  final String destinationId; // ID referensi katalog destinasi BE-1
  final String contactWa; // Nomor Kontak Penyelenggara
  final String title;

  /// ATURAN UTAMA 1: Trip Go HANYA memiliki 1 tujuan/destinasi dalam satu perjalanan
  final String singleDestination;

  /// Deskripsi Destinasi Informatif & Kondisi Sebenarnya (Item 5 Trip Go)
  final String destinationDescription;

  /// ATURAN UTAMA 2: Kategori perjalanan ditentukan secara OTOMATIS berdasarkan destinasi
  final String category;

  final String coverUrl;
  final String departureDate;
  final String returnDate;
  final String departureTime;
  final String duration;

  /// ATURAN UTAMA 5: Titik kumpul terintegrasi dengan Google Maps
  final String meetingPointName;
  final String meetingPointAddress;
  final double meetingPointLat;
  final double meetingPointLng;
  final String googleMapsUrl;

  /// ATURAN UTAMA 3: Transaksi dilakukan langsung melalui sistem WISGO
  final int pricePerPerson;

  /// Rincian Fasilitas & Layanan Include & Exclude (Item 1 Trip Go)
  final List<String> includes;
  final List<String> excludes;

  final String paymentGatewayInfo;
  final bool isDirectWisgoEscrow;

  int quotaMax;
  int quotaFilled;

  /// ATURAN UTAMA 6: Verifikasi penyelenggara terjamin (7 Poin)
  final VerifiedOrganizer organizer;

  /// ATURAN UTAMA 7: Ketentuan aktivitas di luar aplikasi jelas bagi peserta
  final List<OfflineTripRule> offlineRules;

  // FITUR SMART TRIP PLANNER & KOMUNIKASI IN-APP (Item 6 Trip Go)
  final List<TripItineraryStep> itinerary;
  final List<TripReadinessItem> readinessChecklist;
  final List<TripJobdeskItem> jobdeskList;
  final List<TripPackingItem> packingList;
  final List<TripChatMessage> messages;
  final String communicationChannel;
  final String whatsappGroupLink;

  // ROLE & VERIFICATION LIFECYCLE STATE
  TripVerificationStatus verificationStatus;
  String difficultyLevel; // 'Easy' | 'Medium' | 'Hard'
  String? adminRejectionReason;
  final bool isCreatedByCurrentUser;
  bool isCurrentUserJoined;
  bool isScheduleReviewed;
  bool isReadinessFinalized;
  bool isTripCompleted;
  bool hasReviewedOrganizer;
  final List<OpenTripParticipant> participants;

  OpenTripItem({
    required this.id,
    this.userId = 'usr-host-01',
    this.destinationId = 'dest-001',
    this.contactWa = '0812-7578-953',
    required this.title,
    required this.singleDestination,
    String? destinationDescription,
    String? category,
    required this.coverUrl,
    required this.departureDate,
    required this.returnDate,
    required this.departureTime,
    required this.duration,
    required this.meetingPointName,
    required this.meetingPointAddress,
    required this.meetingPointLat,
    required this.meetingPointLng,
    required this.googleMapsUrl,
    required this.pricePerPerson,
    List<String>? includes,
    List<String>? excludes,
    this.paymentGatewayInfo =
        'Sistem Pembayaran Resmi WISGO (Payment Gateway / Rekening Penampung Escrow)',
    this.isDirectWisgoEscrow = true,
    required this.quotaMax,
    required this.quotaFilled,
    required this.organizer,
    required this.offlineRules,
    required this.itinerary,
    required this.readinessChecklist,
    required this.jobdeskList,
    required this.packingList,
    required this.messages,
    this.communicationChannel =
        'Forum Diskusi & Chat Komunikasi Smart Trip Planner (In-App)',
    this.whatsappGroupLink = '',
    this.verificationStatus = TripVerificationStatus.approved,
    this.difficultyLevel = 'Medium',
    this.adminRejectionReason,
    this.isCreatedByCurrentUser = false,
    this.isCurrentUserJoined = false,
    this.isScheduleReviewed = false,
    this.isReadinessFinalized = false,
    this.isTripCompleted = false,
    this.hasReviewedOrganizer = false,
    List<OpenTripParticipant>? participants,
  })  : participants = participants ??
            [
              OpenTripParticipant(
                userId: 'usr-p1',
                bookingCode: 'TRIP-84210',
                fullName: 'Siti Rahma',
                phoneNumber: '0813-6542-1120',
                emergencyContact: '0812-6611-8890 (Ibu Rahma)',
                seatCount: 1,
                paymentMethod: 'QRIS',
                totalPaid: pricePerPerson,
                specialNotes: 'Tidak ada alergi makanan',
                joinedAt: '25 Nov 2026',
                isScheduleReady: true,
                readinessDone: 6,
                readinessTotal: 6,
                packingDone: 10,
                packingTotal: 10,
                isFinalized: true,
              ),
              OpenTripParticipant(
                userId: 'usr-p2',
                bookingCode: 'TRIP-84219',
                fullName: 'Doni Pratama',
                phoneNumber: '0852-7410-3398',
                emergencyContact: '0811-6620-4411 (Ayah Doni)',
                seatCount: 2,
                paymentMethod: 'WISGO_PAY',
                totalPaid: pricePerPerson * 2,
                specialNotes: 'Bawa kamera & tripod, butuh jaket ukuran L',
                joinedAt: '26 Nov 2026',
                isScheduleReady: true,
                readinessDone: 4,
                readinessTotal: 6,
                packingDone: 7,
                packingTotal: 10,
                isFinalized: false,
              ),
            ],
        destinationDescription = destinationDescription ??
            'Kawasan cagar alam Lembah Harau dengan formasi tebing batuan vertikal 100-300 meter, akses jalan aspal datar yang mudah dijangkau, serta kolam alami air terjun Sarasah Bunta yang sejuk.',
        includes = includes ??
            const [
              'Tiket Masuk Resmi Kawasan (Perda Terpantau)',
              'Pemandu Lokal Berlisensi HPI / Pokdarwis',
              'Air Mineral & Buah Segar Lokal',
              'Asuransi Keselamatan Rekreasi Nagari',
              'Retribusi Parkir Resmi & Kebersihan Terkelola',
            ],
        excludes = excludes ??
            const [
              'Pengeluaran Pribadi & Cinderamata',
              'Makan di Luar Jadwal Rundown',
              'Sewa Perlengkapan Pribadi / Ojek Tambahan',
              'Transportasi Mandiri Menuju Titik Kumpul',
            ],
        category = category ?? determineCategoryForDestination(singleDestination);

  int get availableSeats => quotaMax - quotaFilled;

  OpenTripItem copyWith({
    String? id,
    String? userId,
    String? destinationId,
    String? contactWa,
    String? title,
    String? singleDestination,
    String? destinationDescription,
    String? category,
    String? coverUrl,
    String? departureDate,
    String? returnDate,
    String? departureTime,
    String? duration,
    String? meetingPointName,
    String? meetingPointAddress,
    double? meetingPointLat,
    double? meetingPointLng,
    String? googleMapsUrl,
    int? pricePerPerson,
    List<String>? includes,
    List<String>? excludes,
    String? paymentGatewayInfo,
    bool? isDirectWisgoEscrow,
    int? quotaMax,
    int? quotaFilled,
    VerifiedOrganizer? organizer,
    List<OfflineTripRule>? offlineRules,
    List<TripItineraryStep>? itinerary,
    List<TripReadinessItem>? readinessChecklist,
    List<TripJobdeskItem>? jobdeskList,
    List<TripPackingItem>? packingList,
    List<TripChatMessage>? messages,
    String? communicationChannel,
    String? whatsappGroupLink,
  }) {
    return OpenTripItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      destinationId: destinationId ?? this.destinationId,
      contactWa: contactWa ?? this.contactWa,
      title: title ?? this.title,
      singleDestination: singleDestination ?? this.singleDestination,
      destinationDescription:
          destinationDescription ?? this.destinationDescription,
      category: category ?? this.category,
      coverUrl: coverUrl ?? this.coverUrl,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      departureTime: departureTime ?? this.departureTime,
      duration: duration ?? this.duration,
      meetingPointName: meetingPointName ?? this.meetingPointName,
      meetingPointAddress: meetingPointAddress ?? this.meetingPointAddress,
      meetingPointLat: meetingPointLat ?? this.meetingPointLat,
      meetingPointLng: meetingPointLng ?? this.meetingPointLng,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      paymentGatewayInfo: paymentGatewayInfo ?? this.paymentGatewayInfo,
      isDirectWisgoEscrow: isDirectWisgoEscrow ?? this.isDirectWisgoEscrow,
      quotaMax: quotaMax ?? this.quotaMax,
      quotaFilled: quotaFilled ?? this.quotaFilled,
      organizer: organizer ?? this.organizer,
      offlineRules: offlineRules ?? this.offlineRules,
      itinerary: itinerary ?? this.itinerary,
      readinessChecklist: readinessChecklist ?? this.readinessChecklist,
      jobdeskList: jobdeskList ?? this.jobdeskList,
      packingList: packingList ?? this.packingList,
      messages: messages ?? this.messages,
      communicationChannel: communicationChannel ?? this.communicationChannel,
      whatsappGroupLink: whatsappGroupLink ?? this.whatsappGroupLink,
    );
  }
}

/// Data Contoh Resmi Trip Go (Masing-masing 1 Destinasi Tunggal)
final List<OpenTripItem> kMockOpenTrips = [
  // TRIP 1: Lembah Harau (Alam & Geopark)
  OpenTripItem(
    id: 'TRIP-HARAU-01',
    title: 'Jelajah Lembah Harau & Air Terjun Sarasah Bunta',
    singleDestination: 'Lembah Harau & Sarasah Bunta',
    category: 'Alam & Geopark',
    destinationDescription:
        'Kawasan cagar alam Lembah Harau dengan tebing batuan vertikal setinggi 100-300 meter, akses jalan aspal datar yang mudah dijangkau kendaraan roda dua maupun empat, serta aliran air terjun Sarasah Bunta dengan kolam alami yang sejuk dan terawat.',
    coverUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
    departureDate: 'Sabtu, 28 Nov 2026',
    returnDate: 'Minggu, 29 Nov 2026',
    departureTime: '06.00 WIB',
    duration: '2 Hari 1 Malam',
    meetingPointName: 'Rest Area Simpang Harau (Depan Kantor Nagari)',
    meetingPointAddress: 'Jl. Raya Payakumbuh-Harau KM 8, Kab. Lima Puluh Kota',
    meetingPointLat: -0.1132,
    meetingPointLng: 100.6721,
    googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-0.1132,100.6721',
    pricePerPerson: 135000,
    quotaMax: 8,
    quotaFilled: 5,
    organizer: const VerifiedOrganizer(
      id: 'ORG-01',
      name: 'Rahmat Hidayat (Guide Berlisensi Nagari)',
      licenseNumber: 'HPI-SB-2024-0412 (Pemandu Wisata Muda)',
      specialCompetency: 'Sertifikasi P3K & Wilderness First Aid BNSP',
      ktpStatus: 'Terverifikasi e-KTP Dukcapil RI',
      ktpUploadStatus: 'Dokumen KTP Terunggah & Tervalidasi',
      faceVerificationStatus: 'Verifikasi Wajah / Liveness Biometrik Lolos (99.2%)',
      rating: 4.95,
      completedTrips: 38,
      phone: '0812-7578-953',
      socialMedia: '@rahmathidayat_guide (Instagram)',
      experienceYears: '4+ Tahun Pengalaman Pemandu Wisata Alam',
      organizationName: 'Komunitas Pemandu Harau Geopark',
    ),
    offlineRules: const [
      OfflineTripRule(
        title: 'Toleransi Waktu Titik Kumpul 15 Menit',
        ruleDescription: 'Peserta wajib hadir 15 menit sebelum jam keberangkatan. Toleransi keterlambatan maksimal 15 menit sebelum kendaraan bergerak.',
        iconCode: 'schedule',
      ),
      OfflineTripRule(
        title: 'Asuransi Keselamatan Rekreasi Resmi',
        ruleDescription: 'Seluruh peserta terdaftar otomatis pada asuransi keselamatan wisata BKSDA & Jasa Raharja selama kegiatan luar ruang.',
        iconCode: 'security',
      ),
      OfflineTripRule(
        title: 'Protokol Cuaca Ekstrem BMKG',
        ruleDescription: 'Apabila BMKG merilis peringatan dini curah hujan tinggi atau debit air terjun meningkat, rute dialihkan ke spot tebing aman atau reschedule resmi.',
        iconCode: 'thunderstorm',
      ),
      OfflineTripRule(
        title: 'Kearifan Lokal Minangkabau & Zero Waste',
        ruleDescription: 'Menjaga sopan santun sesuai filosofi Adat Basandi Syarak, dilarang membuang sampah sembarangan (wajib bawa tumbler & kantong sampah sendiri).',
        iconCode: 'nature_people',
      ),
      OfflineTripRule(
        title: 'Kontak Darurat Satgas Wisata Sumbar',
        ruleDescription: 'Nomor darurat Satgas Pariwisata Limapuluh Kota: 0811-660-8899 / Call Center WISGO 24/7.',
        iconCode: 'phone_in_talk',
      ),
    ],
    readinessChecklist: [
      TripReadinessItem(
        id: 'readiness_1',
        title: 'Konfirmasi Transportasi Hiace Wisata',
        description: 'Unit armada ber-AC disewa dari vendor transportasi resmi nagari.',
        isDone: true,
        category: 'Transportasi',
      ),
      TripReadinessItem(
        id: 'readiness_2',
        title: 'Tiket Masuk Resmi Perda Telah Dibayar',
        description: 'Retribusi tiket masuk gerbang Lembah Harau via sistem WISGO.',
        isDone: true,
        category: 'Perizinan',
      ),
      TripReadinessItem(
        id: 'readiness_3',
        title: 'Pengecekan Prakiraan Cuaca BMKG',
        description: 'Pantauan radar cuaca Stasiun Meteorologi Minangkabau cerah berawan.',
        isDone: true,
        category: 'Keamanan',
      ),
      TripReadinessItem(
        id: 'readiness_4',
        title: 'Tenda Dome & Matras Camping Harau',
        description: '4 tenda kapasitas 2 orang telah disiapkan di basecamp sarasah.',
        isDone: true,
        category: 'Akomodasi',
      ),
      TripReadinessItem(
        id: 'readiness_5',
        title: 'Kotak P3K & Obat Khusus Luar Ruang',
        description: 'Antiseptik, perban, minyak angin, oksigen portabel, dan obat lambung.',
        isDone: false,
        category: 'Logistik',
      ),
      TripReadinessItem(
        id: 'readiness_6',
        title: 'Briefing Keberangkatan H-1 via Chat Tim',
        description: 'Penyampaian aturan pertemuan di rest area pukul 06.00 WIB tepat.',
        isDone: false,
        category: 'Keamanan',
      ),
    ],
    jobdeskList: [
      TripJobdeskItem(
        id: 'job_1',
        roleTitle: 'Tour Leader & Pemandu Utama',
        picName: 'Rahmat Hidayat (Penyelenggara)',
        picRole: 'Penyelenggara',
        tasks: [
          'Memimpin rombongan selama trekking tebing Harau',
          'Koordinasi jam keberangkatan & kepulangan',
          'Briefing keselamatan di tepi air terjun Sarasah',
        ],
        status: 'Sedang Berjalan',
        icon: Icons.person_pin_circle_rounded,
      ),
      TripJobdeskItem(
        id: 'job_2',
        roleTitle: 'Divisi Logistik & Konsumsi Minang',
        picName: 'Siti Rahma (Peserta 1)',
        picRole: 'Peserta',
        tasks: [
          'Memastikan katering sarapan & makan malam khas nagari siap',
          'Mengelola galon air isi ulang & snack lokal',
          'Memeriksa alat masak portable untuk teh talua malam hari',
        ],
        status: 'Siap',
        icon: Icons.restaurant_menu_rounded,
      ),
      TripJobdeskItem(
        id: 'job_3',
        roleTitle: 'Divisi Dokumentasi & Media',
        picName: 'Doni Pratama (Peserta 2)',
        picRole: 'Peserta',
        tasks: [
          'Pengambilan foto kelompok di bawah tebing vertikal Harau',
          'Menerbangkan drone untuk video lanskap panorama',
          'Mengunggah hasil jepretan ke Google Drive rombongan',
        ],
        status: 'Siap',
        icon: Icons.camera_alt_rounded,
      ),
      TripJobdeskItem(
        id: 'job_4',
        roleTitle: 'Divisi Medis & Kesehatan Peserta',
        picName: 'Fauzan Akbar (Peserta 3)',
        picRole: 'Peserta',
        tasks: [
          'Membawa tas P3K standar outdoor',
          'Memonitor fisik peserta saat mendaki jalur tebing',
          'Siap sedia balsem hangat & obat kram otot',
        ],
        status: 'Siap',
        icon: Icons.medical_services_rounded,
      ),
      TripJobdeskItem(
        id: 'job_5',
        roleTitle: 'Navigator & Parkir Armada',
        picName: 'Pak Anton (Driver Nagari)',
        picRole: 'Penyelenggara',
        tasks: [
          'Memastikan armada Hiace terparkir di zona resmi Perda',
          'Cek tekanan ban & bahan bakar armada sebelum jalan',
        ],
        status: 'Siap',
        icon: Icons.directions_bus_rounded,
      ),
    ],
    packingList: [
      TripPackingItem(
        id: 'pack_1',
        category: 'Pakaian & Alas Kaki',
        itemName: 'Jaket Windbreaker / Jaket Tebal',
        notes: 'Suhu malam hari di lembah tebing sekitar 18-20°C',
        isPacked: true,
      ),
      TripPackingItem(
        id: 'pack_2',
        category: 'Pakaian & Alas Kaki',
        itemName: 'Sepatu Trekking / Sandal Gunung Antiselip',
        notes: 'Jalur batu Sarasah lembab dan licin',
        isPacked: true,
      ),
      TripPackingItem(
        id: 'pack_3',
        category: 'Pakaian & Alas Kaki',
        itemName: 'Pakaian Ganti (2 Pasang)',
        notes: 'Untuk berenang di air terjun dan tidur malam',
        isPacked: false,
      ),
      TripPackingItem(
        id: 'pack_4',
        category: 'Kesehatan & P3K',
        itemName: 'Obat Pribadi & Minyak Kayu Putih',
        notes: 'Wajib bagi yang memiliki riwayat alergi dingin/asma',
        isPacked: true,
      ),
      TripPackingItem(
        id: 'pack_5',
        category: 'Kesehatan & P3K',
        itemName: 'Sunscreen SPF 50 & Lotion Anti-Nyamuk',
        notes: 'Melindungi kulit dari terik matahari dan serangga',
        isPacked: false,
      ),
      TripPackingItem(
        id: 'pack_6',
        category: 'Elektronik & Gadget',
        itemName: 'Powerbank 10.000 mAh & Kabel Charger',
        notes: 'Area camping minim stopkontak umum',
        isPacked: true,
      ),
      TripPackingItem(
        id: 'pack_7',
        category: 'Elektronik & Gadget',
        itemName: 'Headlamp / Senter Kecil',
        notes: 'Sangat berguna saat berjalan malam hari ke toilet',
        isPacked: false,
      ),
      TripPackingItem(
        id: 'pack_8',
        category: 'Dokumen & Ibadah',
        itemName: 'e-KTP Asli / Identitas Diri',
        notes: 'Diperlukan untuk registrasi tiket Perda & asuransi',
        isPacked: true,
      ),
      TripPackingItem(
        id: 'pack_9',
        category: 'Dokumen & Ibadah',
        itemName: 'Sajadah Travel Ringan',
        notes: 'Untuk sholat berjamaah di gazebo basecamp',
        isPacked: true,
      ),
      TripPackingItem(
        id: 'pack_10',
        category: 'Dokumen & Ibadah',
        itemName: 'Tumbler Air Minum & Trashbag Pribadi',
        notes: 'Mendukung gerakan Zero Waste bebas sampah plastik',
        isPacked: true,
      ),
    ],
    itinerary: [
      TripItineraryStep(
        time: '06.00 - 06.30 WIB',
        activity: 'Kumpul & Presensi di Titik Kumpul',
        location: 'Rest Area Simpang Harau',
        notes: 'Cek kehadiran peserta, pembagian name-tag & snack pagi.',
        status: 'Akan Datang',
        icon: Icons.place_rounded,
      ),
      TripItineraryStep(
        time: '06.30 - 07.45 WIB',
        activity: 'Perjalanan Menuju Gerbang Lembah Harau',
        location: 'Jl. Raya Harau',
        notes: 'Pemandu menyampaikan sejarah geologi tebing granit.',
        status: 'Akan Datang',
        icon: Icons.directions_bus_rounded,
      ),
      TripItineraryStep(
        time: '07.45 - 11.30 WIB',
        activity: 'Eksplorasi Tebing & Sarasah Bunta',
        location: 'Kawasan Lembah Harau & Sarasah Bunta',
        notes: 'Trekking santai, foto tebing vertikal, dan berenang air terjun.',
        status: 'Akan Datang',
        icon: Icons.landscape_rounded,
      ),
      TripItineraryStep(
        time: '11.30 - 13.30 WIB',
        activity: 'Makan Siang Bersama & Sholat Dzuhur',
        location: 'Gazebo Tradisional Lembah Harau',
        notes: 'Makan siang nasi kapau khas Luak Limopuluah.',
        status: 'Akan Datang',
        icon: Icons.restaurant_rounded,
      ),
      TripItineraryStep(
        time: '13.30 - 17.00 WIB',
        activity: 'Mendirikan Tenda Camp & Sesi Bebas',
        location: 'Camping Ground Sarasah Murai',
        notes: 'Didampingi pemandu nagari, istirahat dan foto panorama tebing.',
        status: 'Akan Datang',
        icon: Icons.nature_people_rounded,
      ),
      TripItineraryStep(
        time: '19.00 - 21.00 WIB',
        activity: 'Makan Malam & Api Unggun Teh Talua',
        location: 'Campfire Area Harau',
        notes: 'Diskusi budaya Minang dan keakraban antar peserta.',
        status: 'Akan Datang',
        icon: Icons.fireplace_rounded,
      ),
    ],
    messages: [
      TripChatMessage(
        id: 'msg_pin',
        senderName: 'Rahmat Hidayat (Host)',
        senderRole: 'Host',
        message:
            ' PENGUMUMAN PENTING: Mohon seluruh peserta tiba di Rest Area Simpang Harau maksimal pukul 06.15 WIB. Pastikan baterai ponsel terisi penuh untuk scan tiket masuk!',
        timestamp: 'Kemarin, 20.30 WIB',
        isPinnedNotice: true,
      ),
      TripChatMessage(
        id: 'msg_1',
        senderName: 'Rahmat Hidayat (Host)',
        senderRole: 'Host',
        message: 'Selamat datang teman-teman di grup trip Harau! Cuaca diprakirakan cerah berawan.',
        timestamp: '08.15 WIB',
      ),
      TripChatMessage(
        id: 'msg_2',
        senderName: 'Siti Rahma',
        senderRole: 'Peserta',
        message: 'Halo Pak Rahmat dan semuanya! Katering nasi kapau untuk siang besok sudah aman dikonfirmasi.',
        timestamp: '08.30 WIB',
      ),
      TripChatMessage(
        id: 'msg_3',
        senderName: 'Doni Pratama',
        senderRole: 'Peserta',
        message: 'Kamera dan drone sudah selesai dites, memori 128GB siap mengabadikan tebing Harau!',
        timestamp: '08.45 WIB',
      ),
    ],
    whatsappGroupLink: 'https://chat.whatsapp.com/WisgoHarauTrip2026',
  ),

  // TRIP 2: Kawasan Mandeh (Alam & Geopark)
  OpenTripItem(
    id: 'TRIP-MANDEH-02',
    title: 'Island Hopping & Snorkeling Eksotis Kawasan Mandeh',
    singleDestination: 'Kawasan Mandeh (Raja Ampat Minang)',
    category: 'Alam & Geopark',
    coverUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
    departureDate: 'Minggu, 29 Nov 2026',
    returnDate: 'Minggu, 29 Nov 2026',
    departureTime: '07.00 WIB',
    duration: '1 Hari (Full Day Trip)',
    meetingPointName: 'Dermaga TPI Tarusan / Carocok Anau',
    meetingPointAddress: 'Kec. Koto XI Tarusan, Kab. Pesisir Selatan',
    meetingPointLat: -1.2144,
    meetingPointLng: 100.4182,
    googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-1.2144,100.4182',
    pricePerPerson: 185000,
    quotaMax: 10,
    quotaFilled: 7,
    organizer: const VerifiedOrganizer(
      id: 'ORG-02',
      name: 'Kapten Hendra Saputra',
      licenseNumber: 'SK-DISHUB-SB-0988 (Nahkoda Wisata Laut)',
      ktpStatus: 'Terverifikasi e-KTP & Koperasi Bahari Tarusan',
      rating: 4.92,
      completedTrips: 52,
      phone: '0813-6622-4411',
      organizationName: 'Paguyuban Speedboat Bahari Mandeh',
    ),
    offlineRules: const [
      OfflineTripRule(
        title: 'Wajib Menggunakan Life Jacket (Pelampung)',
        ruleDescription: 'Seluruh peserta wajib memakai pelampung keselamatan selama berada di atas boat laut.',
        iconCode: 'life_jacket',
      ),
      OfflineTripRule(
        title: 'Larangan Menginjak Terumbu Karang',
        ruleDescription: 'Saat snorkeling di Pulau Sironjong, dilarang menyentuh atau menginjak terumbu karang hidup demi kelestarian ekosistem bahari.',
        iconCode: 'water',
      ),
      OfflineTripRule(
        title: 'Toleransi Waktu Pasang Surut Laut',
        ruleDescription: 'Keberangkatan boat mengikuti jadwal pasang laut Tarusan. Keterlambatan maksimal 15 menit.',
        iconCode: 'schedule',
      ),
      OfflineTripRule(
        title: 'Asuransi Penyeberangan Resmi Jasa Raharja',
        ruleDescription: 'Setiap penumpang terdaftar manifest asuransi laut resmi pelabuhan Tarusan.',
        iconCode: 'security',
      ),
      OfflineTripRule(
        title: 'Kontak Darurat Polairud & Satgas Mandeh',
        ruleDescription: 'Hotline Pos SAR Bahari Pesisir Selatan: 0812-7000-5544.',
        iconCode: 'phone_in_talk',
      ),
    ],
    readinessChecklist: [
      TripReadinessItem(
        id: 'mandeh_ready_1',
        title: 'Sewa Speedboat 2 Mesin Yamaha 200HP',
        description: 'Armada boat resmi dengan sertifikat kelaikan laut.',
        isDone: true,
        category: 'Transportasi',
      ),
      TripReadinessItem(
        id: 'mandeh_ready_2',
        title: 'Tiket Retribusi Perda & Donasi Terumbu Karang',
        description: 'Telah dilunasi via sistem pembayaran terintegrasi WISGO.',
        isDone: true,
        category: 'Perizinan',
      ),
      TripReadinessItem(
        id: 'mandeh_ready_3',
        title: 'Pelampung SNI & Alat Snorkeling (10 Set)',
        description: 'Masker, snorkel, dan fin kaki katak ukuran lengkap.',
        isDone: true,
        category: 'Logistik',
      ),
    ],
    jobdeskList: [
      TripJobdeskItem(
        id: 'm_job_1',
        roleTitle: 'Nahkoda & Pemandu Bahari',
        picName: 'Kapten Hendra Saputra',
        picRole: 'Penyelenggara',
        tasks: ['Mengemudikan speedboat', 'Cek keamanan arus laut'],
        status: 'Siap',
        icon: Icons.directions_boat_rounded,
      ),
    ],
    packingList: [
      TripPackingItem(
        id: 'm_pack_1',
        category: 'Pakaian & Alas Kaki',
        itemName: 'Baju Renang & Pakaian Kering Ganti',
        isPacked: true,
      ),
      TripPackingItem(
        id: 'm_pack_2',
        category: 'Elektronik & Gadget',
        itemName: 'Waterproof Pouch / Pelindung HP Anti Air',
        isPacked: true,
      ),
    ],
    itinerary: [
      TripItineraryStep(
        time: '07.00 - 07.30 WIB',
        activity: 'Kumpul di Dermaga Tarusan & Fitting Pelampung',
        location: 'Dermaga TPI Tarusan',
        notes: 'Briefing keselamatan laut dan pembagian alat snorkeling.',
        status: 'Akan Datang',
        icon: Icons.place_rounded,
      ),
      TripItineraryStep(
        time: '08.00 - 10.30 WIB',
        activity: 'Island Hopping Pulau Sironjong Gadang & Ketek',
        location: 'Kawasan Mandeh',
        notes: 'Snorkeling karang laut dan cliff jumping bagi yang berani.',
        status: 'Akan Datang',
        icon: Icons.scuba_diving_rounded,
      ),
    ],
    messages: [
      TripChatMessage(
        id: 'm_msg_1',
        senderName: 'Kapten Hendra (Host)',
        senderRole: 'Host',
        message: 'Kondisi ombak Mandeh hari ini sangat tenang (0.5 meter), sangat ideal untuk snorkeling!',
        timestamp: '06.00 WIB',
        isPinnedNotice: true,
      ),
    ],
    whatsappGroupLink: 'https://chat.whatsapp.com/WisgoMandehTrip2026',
  ),

  // TRIP 3: Puncak Lawang (Alam & Geopark)
  OpenTripItem(
    id: 'TRIP-LAWANG-03',
    title: 'Pesona Negeri di Atas Awan Puncak Lawang & Danau Maninjau',
    singleDestination: 'Puncak Lawang & Kebun Tebu Tradisional',
    category: 'Alam & Geopark',
    coverUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
    departureDate: 'Sabtu, 5 Des 2026',
    returnDate: 'Sabtu, 5 Des 2026',
    departureTime: '06.30 WIB',
    duration: '1 Hari (Day Trip)',
    meetingPointName: 'Jam Gadang Bukittinggi (Sisi Barat Plaza)',
    meetingPointAddress: 'Pusat Kota Bukittinggi, Sumatera Barat',
    meetingPointLat: -0.3051,
    meetingPointLng: 100.3694,
    googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-0.3051,100.3694',
    pricePerPerson: 110000,
    quotaMax: 7,
    quotaFilled: 4,
    organizer: const VerifiedOrganizer(
      id: 'ORG-03',
      name: 'Fandi Kurniawan (FASI Agam)',
      licenseNumber: 'FASI-PL-2023-019 (Pilot Tandem Paralayang)',
      ktpStatus: 'Terverifikasi e-KTP & Disparpora Agam',
      rating: 4.88,
      completedTrips: 29,
      phone: '0852-9988-1122',
      organizationName: 'Lawang Adventure & Culture Guide',
    ),
    offlineRules: const [
      OfflineTripRule(
        title: 'Aturan Pakaian Hangat Dataran Tinggi',
        ruleDescription: 'Puncak Lawang berada pada ketinggian 1.210 mdpl, bawa jaket penahan angin.',
        iconCode: 'cloud',
      ),
      OfflineTripRule(
        title: 'Ketentuan Terbang Tandem Paralayang',
        ruleDescription: 'Peserta yang ingin tandem wajib mengikuti instruksi pilot FASI dan memiliki berat badan 40-85 kg.',
        iconCode: 'flight',
      ),
    ],
    readinessChecklist: [
      TripReadinessItem(
        id: 'l_ready_1',
        title: 'Armada Minibus Wisata Bukittinggi - Lawang',
        description: 'Transportasi pulang pergi titik kumpul Jam Gadang.',
        isDone: true,
        category: 'Transportasi',
      ),
    ],
    jobdeskList: [
      TripJobdeskItem(
        id: 'l_job_1',
        roleTitle: 'Pemandu Rute & Sejarah Maninjau',
        picName: 'Fandi Kurniawan',
        picRole: 'Penyelenggara',
        tasks: ['Menceritakan sejarah Kelok 44 dan Buya Hamka'],
        status: 'Siap',
        icon: Icons.history_edu_rounded,
      ),
    ],
    packingList: [
      TripPackingItem(
        id: 'l_pack_1',
        category: 'Pakaian & Alas Kaki',
        itemName: 'Jaket Windbreaker & Topi Kupluk',
        isPacked: true,
      ),
    ],
    itinerary: [
      TripItineraryStep(
        time: '06.30 - 07.00 WIB',
        activity: 'Kumpul di Jam Gadang & Berangkat Bersama',
        location: 'Jam Gadang Bukittinggi',
        notes: 'Perjalanan sekitar 45 menit menuju Puncak Lawang.',
        status: 'Akan Datang',
        icon: Icons.place_rounded,
      ),
    ],
    messages: [
      TripChatMessage(
        id: 'l_msg_1',
        senderName: 'Fandi (Host)',
        senderRole: 'Host',
        message: 'Jangan lupa siapkan kamera, pemandangan awan dan Danau Maninjau pagi sangat memukau!',
        timestamp: '07.00 WIB',
      ),
    ],
    whatsappGroupLink: 'https://chat.whatsapp.com/WisgoLawangTrip2026',
  ),

  // TRIP 4: Istano Basa Pagaruyung (Budaya & Nagari)
  OpenTripItem(
    id: 'TRIP-PAGARUYUNG-04',
    title: 'Napak Tilas Kejayaan Kerajaan Minangkabau di Istano Basa Pagaruyung',
    singleDestination: 'Istano Basa Pagaruyung',
    category: 'Budaya & Nagari',
    coverUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=800',
    departureDate: 'Minggu, 6 Des 2026',
    returnDate: 'Minggu, 6 Des 2026',
    departureTime: '08.00 WIB',
    duration: '1 Hari (Full Day Culture Trip)',
    meetingPointName: 'Stasiun Kereta Api Padang Panjang',
    meetingPointAddress: 'Jl. Sutan Syahrir No. 1, Kota Padang Panjang',
    meetingPointLat: -0.4632,
    meetingPointLng: 100.3986,
    googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-0.4632,100.3986',
    pricePerPerson: 95000,
    quotaMax: 12,
    quotaFilled: 8,
    organizer: const VerifiedOrganizer(
      id: 'ORG-04',
      name: 'Mak Katik Sutan Marajo (Budayawan Nagari)',
      licenseNumber: 'SK-BUDAYA-TD-2022-005 (Pamong Budaya Luhak Nan Tuo)',
      ktpStatus: 'Terverifikasi e-KTP & Lembaga Kerapatan Adat',
      rating: 4.98,
      completedTrips: 64,
      phone: '0812-3344-7788',
      organizationName: 'Lembaga Pelestari Warisan Adat Pagaruyung',
    ),
    offlineRules: const [
      OfflineTripRule(
        title: 'Etika Berbusana Sopan di Kawasan Rumah Gadang',
        ruleDescription: 'Peserta wajib mengenakan pakaian yang menutup aurat dan sopan saat memasuki Rumah Gadang kembar Pagaruyung.',
        iconCode: 'checkroom',
      ),
      OfflineTripRule(
        title: 'Penjelasan Filosofi Ukiran Rumah Adat',
        ruleDescription: 'Dilarang mencoret-coret atau merusak ukiran kayu kayu surian khas Minangkabau.',
        iconCode: 'museum',
      ),
    ],
    readinessChecklist: [
      TripReadinessItem(
        id: 'p_ready_1',
        title: 'Tiket Masuk Resmi Perda Tanah Datar',
        description: 'Telah divalidasi langsung di loket resmi Istano Basa.',
        isDone: true,
        category: 'Perizinan',
      ),
    ],
    jobdeskList: [
      TripJobdeskItem(
        id: 'p_job_1',
        roleTitle: 'Pencerita Sejarah Adat & Silsilah Kerajaan',
        picName: 'Mak Katik Sutan Marajo',
        picRole: 'Penyelenggara',
        tasks: ['Menjelaskan fungsi gonjong, anjuang, dan tiang tuo Rumah Gadang'],
        status: 'Siap',
        icon: Icons.auto_stories_rounded,
      ),
    ],
    packingList: [
      TripPackingItem(
        id: 'p_pack_1',
        category: 'Dokumen & Ibadah',
        itemName: 'Buku Catatan Kecil & Pulpen',
        isPacked: true,
      ),
    ],
    itinerary: [
      TripItineraryStep(
        time: '08.00 - 08.30 WIB',
        activity: 'Kumpul di Stasiun Padang Panjang & Registrasi',
        location: 'Stasiun Padang Panjang',
        notes: 'Briefing rute budaya Tanah Datar.',
        status: 'Akan Datang',
        icon: Icons.place_rounded,
      ),
    ],
    messages: [
      TripChatMessage(
        id: 'p_msg_1',
        senderName: 'Mak Katik (Host)',
        senderRole: 'Host',
        message: 'Bagi peserta yang ingin mencoba pakaian adat kebesaran Minangkabau, sudah kami koordinasikan di lantai 1!',
        timestamp: '07.30 WIB',
      ),
    ],
    whatsappGroupLink: 'https://chat.whatsapp.com/WisgoPagaruyungTrip2026',
  ),

  // TRIP 5: Air Terjun Nyarai (Hidden Gem)
  OpenTripItem(
    id: 'TRIP-NYARAI-05',
    title: 'Jelajah Kolam Hijau Toska & Hutan Asri Air Terjun Nyarai',
    singleDestination: 'Air Terjun Lubuk Nyarai',
    category: 'Hidden Gem',
    coverUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800',
    departureDate: 'Sabtu, 12 Des 2026',
    returnDate: 'Sabtu, 12 Des 2026',
    departureTime: '07.30 WIB',
    duration: '1 Hari (Day Trip)',
    meetingPointName: 'Pos Registrasi Pokdarwis Nyarai Lubuk Alung',
    meetingPointAddress: 'Nagari Salibutan, Kec. Lubuk Alung, Kab. Padang Pariaman',
    meetingPointLat: -0.6812,
    meetingPointLng: 100.3915,
    googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-0.6812,100.3915',
    pricePerPerson: 85000,
    quotaMax: 10,
    quotaFilled: 6,
    organizer: const VerifiedOrganizer(
      id: 'ORG-05',
      name: 'Ritno Kurniawan (Inisiator Ekowisata Nyarai)',
      licenseNumber: 'HPI-SB-2021-0088 (Pemandu Ekowisata Utama)',
      ktpStatus: 'Terverifikasi e-KTP & Pokdarwis Nyarai',
      rating: 4.96,
      completedTrips: 76,
      phone: '0812-6677-8899',
      organizationName: 'Lembaga Pengelola Hutan Nagari Gamaran',
    ),
    offlineRules: const [
      OfflineTripRule(
        title: 'Wajib Dipandu Pemandu Resmi Nagari',
        ruleDescription: 'Jalur hutan Gamaran sepanjang 3.5 km wajib didampingi pemandu berlisensi.',
        iconCode: 'hiking',
      ),
      OfflineTripRule(
        title: 'Larangan Meninggalkan Sampah Apapun',
        ruleDescription: 'Zero waste zone: kantong kresek sampah wajib dibawa kembali ke pos registrasi.',
        iconCode: 'nature_people',
      ),
    ],
    readinessChecklist: [
      TripReadinessItem(
        id: 'nyarai_ready_1',
        title: 'Izin Masuk Hutan Lindung Gamaran',
        description: 'Telah terdaftar resmi pada Balai Pengelola Ekowisata Nyarai.',
        isDone: true,
        category: 'Perizinan',
      ),
    ],
    jobdeskList: [
      TripJobdeskItem(
        id: 'ny_job_1',
        roleTitle: 'Pemandu Trekking Hutan',
        picName: 'Ritno Kurniawan',
        picRole: 'Penyelenggara',
        tasks: ['Memimpin rute jalan setapak', 'Edukasi flora fauna hutan'],
        status: 'Siap',
        icon: Icons.hiking_rounded,
      ),
    ],
    packingList: [
      TripPackingItem(
        id: 'ny_pack_1',
        category: 'Pakaian & Alas Kaki',
        itemName: 'Sepatu Trekking Antiselip / Sandal Gunung',
        isPacked: true,
      ),
    ],
    itinerary: [
      TripItineraryStep(
        time: '07.30 - 08.00 WIB',
        activity: 'Briefing Jalur di Posko Nyarai',
        location: 'Pos Ekowisata Lubuk Alung',
        notes: 'Pemberian instruksi keselamatan dan pengecekan perlengkapan.',
        status: 'Akan Datang',
        icon: Icons.place_rounded,
      ),
    ],
    messages: [
      TripChatMessage(
        id: 'ny_msg_1',
        senderName: 'Ritno (Host)',
        senderRole: 'Host',
        message: 'Jalur trekking terpantau kering dan jernih, sangat aman untuk berenang!',
        timestamp: '07.00 WIB',
      ),
    ],
    whatsappGroupLink: 'https://chat.whatsapp.com/WisgoNyaraiTrip2026',
  ),

  // TRIP 6: Masjid Raya Sumbar (Religi)
  OpenTripItem(
    id: 'TRIP-MASJID-06',
    title: 'Wisata Religi & Kemegahan Mahakarya Arsitektur Minangkabau',
    singleDestination: 'Masjid Raya Sumatera Barat',
    category: 'Religi',
    coverUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=800',
    departureDate: 'Jumat, 18 Des 2026',
    returnDate: 'Jumat, 18 Des 2026',
    departureTime: '10.30 WIB',
    duration: 'Setengah Hari',
    meetingPointName: 'Pelataran Gerbang Utama Masjid Raya Sumbar',
    meetingPointAddress: 'Jl. Khatib Sulaiman, Padang Utara, Kota Padang',
    meetingPointLat: -0.9242,
    meetingPointLng: 100.3626,
    googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-0.9242,100.3626',
    pricePerPerson: 50000,
    quotaMax: 15,
    quotaFilled: 9,
    organizer: const VerifiedOrganizer(
      id: 'ORG-06',
      name: 'Ustadz Ilham Siddiq, M.Ag',
      licenseNumber: 'SK-MUI-SB-2023-0144 (Pemandu Wisata Religi Minang)',
      ktpStatus: 'Terverifikasi e-KTP & Pengurus Masjid Raya',
      rating: 4.97,
      completedTrips: 45,
      phone: '0813-7788-9900',
      organizationName: 'Dewan Kemakmuran Masjid Raya Sumatera Barat',
    ),
    offlineRules: const [
      OfflineTripRule(
        title: 'Etika Berbusana Muslim Menutup Aurat',
        ruleDescription: 'Peserta wajib mengenakan pakaian muslim/muslimah rapi dan sopan di area suci masjid.',
        iconCode: 'checkroom',
      ),
    ],
    readinessChecklist: [
      TripReadinessItem(
        id: 'mr_ready_1',
        title: 'Konfirmasi Tur Sejarah & Filosofi Arsitektur',
        description: 'Izin resmi pengurus DKM untuk tur ruang shalat & galeri kubah gonjong.',
        isDone: true,
        category: 'Perizinan',
      ),
    ],
    jobdeskList: [
      TripJobdeskItem(
        id: 'mr_job_1',
        roleTitle: 'Pemandu Sejarah & Muazin',
        picName: 'Ustadz Ilham Siddiq',
        picRole: 'Penyelenggara',
        tasks: ['Kajian arsitektur gonjong bentang kain hajar aswad'],
        status: 'Siap',
        icon: Icons.mosque_rounded,
      ),
    ],
    packingList: [
      TripPackingItem(
        id: 'mr_pack_1',
        category: 'Dokumen & Ibadah',
        itemName: 'Perlengkapan Shalat Pribadi (Mukena / Sarung)',
        isPacked: true,
      ),
    ],
    itinerary: [
      TripItineraryStep(
        time: '10.30 - 11.45 WIB',
        activity: 'Eksplorasi Makna Ukiran & Bentang Kain Ka\'bah',
        location: 'Lantai Utama Masjid Raya',
        notes: 'Pemaparan filosofi Adat Basandi Syarak, Syarak Basandi Kitabullah.',
        status: 'Akan Datang',
        icon: Icons.mosque_rounded,
      ),
    ],
    messages: [
      TripChatMessage(
        id: 'mr_msg_1',
        senderName: 'Ustadz Ilham (Host)',
        senderRole: 'Host',
        message: 'Selamat datang jamaah sekalian, kita kumpul di pelataran barat pukul 10.30 WIB.',
        timestamp: '09.00 WIB',
      ),
    ],
    whatsappGroupLink: 'https://chat.whatsapp.com/WisgoMasjidRaya2026',
  ),

  // TRIP 7: Los Lambuang Bukittinggi (Kuliner)
  OpenTripItem(
    id: 'TRIP-KAPAU-07',
    title: 'Jelajah Kuliner Otentik Los Lambuang & Sentra Rendang Ranah Minang',
    singleDestination: 'Los Lambuang Pasar Ateh Bukittinggi',
    category: 'Kuliner',
    coverUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
    departureDate: 'Sabtu, 19 Des 2026',
    returnDate: 'Sabtu, 19 Des 2026',
    departureTime: '11.00 WIB',
    duration: '1 Hari (Gourmet Trip)',
    meetingPointName: 'Depan Janjang 40 (Tangga Pasar Bawah - Pasar Ateh)',
    meetingPointAddress: 'Kawasan Pasar Ateh, Benteng Pasar Ateh, Kota Bukittinggi',
    meetingPointLat: -0.3042,
    meetingPointLng: 100.3698,
    googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=-0.3042,100.3698',
    pricePerPerson: 125000,
    quotaMax: 12,
    quotaFilled: 7,
    organizer: const VerifiedOrganizer(
      id: 'ORG-07',
      name: 'Uni Desi Nasi Kapau (Pakar Kuliner Nagari)',
      licenseNumber: 'SK-DISPERINDAG-KTB-2022-019 (Kurator Kuliner Tradisi)',
      ktpStatus: 'Terverifikasi e-KTP & Koperasi Pedagang Pasar Ateh',
      rating: 4.99,
      completedTrips: 88,
      phone: '0812-5544-3322',
      organizationName: 'Paguyuban Kuliner Los Lambuang Bukittinggi',
    ),
    offlineRules: const [
      OfflineTripRule(
        title: 'Paket Menu Otentik Telah Termasuk',
        ruleDescription: 'Harga paket sudah meliputi 1 porsi Nasi Kapau lengkap (Tambusu/Dendeng), Talua Barendo, dan Kawa Daun.',
        iconCode: 'restaurant',
      ),
    ],
    readinessChecklist: [
      TripReadinessItem(
        id: 'kapau_ready_1',
        title: 'Reservasi Meja Panjang Los Lambuang',
        description: 'Area duduk khusus rombongan telah diamankan di lapak Uni Desi.',
        isDone: true,
        category: 'Akomodasi',
      ),
    ],
    jobdeskList: [
      TripJobdeskItem(
        id: 'kp_job_1',
        roleTitle: 'Pemandu Rasa & Master Chef Kapau',
        picName: 'Uni Desi',
        picRole: 'Penyelenggara',
        tasks: ['Mendemonstrasikan cara sendok kuah centong panjang'],
        status: 'Siap',
        icon: Icons.restaurant_menu_rounded,
      ),
    ],
    packingList: [
      TripPackingItem(
        id: 'kp_pack_1',
        category: 'Dokumen & Ibadah',
        itemName: 'Wadah Makanan / Tas Belanja Ramah Lingkungan',
        isPacked: true,
      ),
    ],
    itinerary: [
      TripItineraryStep(
        time: '11.00 - 13.00 WIB',
        activity: 'Makan Bersama di Los Lambuang & Demo Gulai Tambusu',
        location: 'Los Lambuang Pasar Ateh',
        notes: 'Mencicipi aneka lauk khas dan belajar racikan rempah Minang.',
        status: 'Akan Datang',
        icon: Icons.restaurant_rounded,
      ),
    ],
    messages: [
      TripChatMessage(
        id: 'kp_msg_1',
        senderName: 'Uni Desi (Host)',
        senderRole: 'Host',
        message: 'Gulai tambusu dan dendeng batokok hangat sudah siap menunggu kedatangan teman-teman!',
        timestamp: '10.00 WIB',
      ),
    ],
    whatsappGroupLink: 'https://chat.whatsapp.com/WisgoKulinerTrip2026',
  ),
];
