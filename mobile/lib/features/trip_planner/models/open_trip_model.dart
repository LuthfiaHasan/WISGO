import 'package:flutter/material.dart';

/// Model Penyelenggara Terverifikasi (Item 6 Open Trip)
class VerifiedOrganizer {
  final String id;
  final String name;
  final bool isVerified;
  final String verificationBadge;
  final String ktpStatus;
  final String licenseNumber;
  final double rating;
  final int completedTrips;
  final String phone;
  final String organizationName;
  final String escrowProtectionNote;

  const VerifiedOrganizer({
    required this.id,
    required this.name,
    this.isVerified = true,
    this.verificationBadge = 'Penyelenggara Terverifikasi WISGO',
    this.ktpStatus = 'Terverifikasi e-KTP & KYC WISGO',
    required this.licenseNumber,
    this.rating = 4.9,
    this.completedTrips = 24,
    required this.phone,
    required this.organizationName,
    this.escrowProtectionNote =
        'Dana peserta ditahan di Rekening Penampung (Escrow) WISGO dan baru dilepas setelah trip selesai.',
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

/// 5 Kluster Struktur Kategori Perjalanan Resmi (Terstruktur & Mudah Dipahami)
const List<TravelCategoryGroup> kStandardTravelCategories = [
  TravelCategoryGroup(
    id: 'cat-alam-gunung',
    name: 'Wisata Alam & Pegunungan',
    description: 'Eksplorasi puncak gunung api, tebing granit megah, air terjun tersembunyi, dan ngarai hijau.',
    icon: Icons.terrain_rounded,
    primaryColor: Color(0xFF193D22),
    badgeBgColor: Color(0xFFE8F2EC),
    popularKeywords: [
      'harau', 'sarasah', 'tebing', 'gunung', 'marapi', 'singgalang',
      'talang', 'tandikat', 'ngarai', 'sianok', 'anai', 'lubuk', 'bukit',
      'air terjun', 'puncak', 'rimba', 'lawang', 'paralayang'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-bahari-pesisir',
    name: 'Wisata Bahari & Pesisir',
    description: 'Jelajah gugusan pulau eksotis, teluk tenang Mandeh, terumbu karang, dan pesona pantai Samudera Hindia.',
    icon: Icons.sailing_rounded,
    primaryColor: Color(0xFF0369A1),
    badgeBgColor: Color(0xFFE0F2FE),
    popularKeywords: [
      'mandeh', 'pasumpahan', 'pagang', 'sirandah', 'pamutusan',
      'mentawai', 'suwarnadwipa', 'pantai', 'air manis', 'carocok',
      'gandoriah', 'pulau', 'bahari', 'snorkeling', 'diving', 'surfing'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-sejarah-warisan',
    name: 'Sejarah & Warisan Minangkabau',
    description: 'Napak tilas kejayaan kerajaan Pagaruyung, arsitektur gonjong megah, dan cagar budaya bersejarah.',
    icon: Icons.account_balance_rounded,
    primaryColor: Color(0xFF7C2D12),
    badgeBgColor: Color(0xFFFEE2E2),
    popularKeywords: [
      'pagaruyung', 'istano', 'rumah gadang', 'jam gadang', 'lubang jepang',
      'benteng', 'fort de kock', 'cagar budaya', 'heritage', 'kota tua'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-nagari-budaya',
    name: 'Nagari Adat & Edukasi Budaya',
    description: 'Pengalaman autentik berinteraksi dengan ninik mamak, desa terindah, tradisi tenun, dan seni randai.',
    icon: Icons.diversity_3_rounded,
    primaryColor: Color(0xFF92400E),
    badgeBgColor: Color(0xFFFEF3C7),
    popularKeywords: [
      'pariangan', 'silokek', 'pandai sikek', 'desa adat', 'nagari',
      'tenun', 'ukiran', 'pacu jawi', 'randai', 'silek', 'budaya', 'pokdarwis'
    ],
  ),
  TravelCategoryGroup(
    id: 'cat-kuliner-agro',
    name: 'Kuliner Otentik & Agrowisata',
    description: 'Eksplorasi cita rasa rempah rendang asli, pasar kuliner kapau, kebun teh sejuk, dan danau kembar.',
    icon: Icons.restaurant_rounded,
    primaryColor: Color(0xFF15803D),
    badgeBgColor: Color(0xFFDCFCE7),
    popularKeywords: [
      'kapau', 'rendang', 'payakumbuh', 'danguang', 'sate', 'kebun teh',
      'alahan panjang', 'danau', 'singkarak', 'maninjau', 'diatas', 'dibawah',
      'kopi', 'agrowisata', 'durian'
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
  return 'Wisata Alam & Pegunungan';
}

/// Model Data Open Trip Lengkap (Item 1-7 Open Trip & Item 1-5 Trip Planner)
class OpenTripItem {
  final String id;
  final String title;

  /// ATURAN UTAMA 1: Open Trip HANYA memiliki 1 tujuan/destinasi dalam satu perjalanan
  final String singleDestination;

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
  final String paymentGatewayInfo;
  final bool isDirectWisgoEscrow;

  int quotaMax;
  int quotaFilled;

  /// ATURAN UTAMA 6: Verifikasi penyelenggara terjamin
  final VerifiedOrganizer organizer;

  /// ATURAN UTAMA 7: Ketentuan aktivitas di luar aplikasi jelas bagi peserta
  final List<OfflineTripRule> offlineRules;

  // FITUR TRIP PLANNER (Item 1-5 Trip Planner)
  final List<TripItineraryStep> itinerary;
  final List<TripReadinessItem> readinessChecklist;
  final List<TripJobdeskItem> jobdeskList;
  final List<TripPackingItem> packingList;
  final List<TripChatMessage> messages;
  final String whatsappGroupLink;

  OpenTripItem({
    required this.id,
    required this.title,
    required this.singleDestination,
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
    this.paymentGatewayInfo = 'Sistem Pembayaran Resmi WISGO (QRIS / Escrow Terlindungi)',
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
    required this.whatsappGroupLink,
  }) : category = category ?? determineCategoryForDestination(singleDestination);
}

/// Data Contoh Resmi Open Trip (Masing-masing 1 Destinasi Tunggal)
final List<OpenTripItem> kMockOpenTrips = [
  // TRIP 1: Lembah Harau (Wisata Alam & Tebing)
  OpenTripItem(
    id: 'TRIP-HARAU-01',
    title: 'Eksplor Kemegahan Tebing Granit Lembah Harau',
    singleDestination: 'Lembah Harau & Sarasah Bunta',
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
      ktpStatus: 'Terverifikasi e-KTP & SK Pokdarwis Harau',
      rating: 4.95,
      completedTrips: 38,
      phone: '0812-7578-953',
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
        activity: 'Kumpul & Presensi di Titik Kumpul (Google Maps)',
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
        location: 'Lembah Harau (Sarasah Bunta)',
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

  // TRIP 2: Kawasan Mandeh (Wisata Bahari & Snorkeling)
  OpenTripItem(
    id: 'TRIP-MANDEH-02',
    title: 'Island Hopping & Snorkeling Eksotis Kawasan Mandeh',
    singleDestination: 'Kawasan Mandeh (Raja Ampat Minang)',
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

  // TRIP 3: Puncak Lawang (Paralayang & Panorama)
  OpenTripItem(
    id: 'TRIP-LAWANG-03',
    title: 'Pesona Negeri di Atas Awan Puncak Lawang & Danau Maninjau',
    singleDestination: 'Puncak Lawang & Kebun Tebu Tradisional',
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

  // TRIP 4: Istano Basa Pagaruyung (Cagar Budaya & Adat Minang)
  OpenTripItem(
    id: 'TRIP-PAGARUYUNG-04',
    title: 'Napak Tilas Kejayaan Kerajaan Minangkabau di Istano Basa Pagaruyung',
    singleDestination: 'Istano Basa Pagaruyung',
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
];
