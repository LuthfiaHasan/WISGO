import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Model Permintaan Bergabung Open Trip
class OpenTripJoinRequest {
  final String id;
  final String travelerName;
  final String whatsappNumber;
  final String requestedAt;
  String status; // 'pending', 'accepted', 'rejected'

  OpenTripJoinRequest({
    required this.id,
    required this.travelerName,
    required this.whatsappNumber,
    required this.requestedAt,
    this.status = 'pending',
  });
}

/// Model Data Open Trip Lengkap
class OpenTripData {
  String name;
  String coverUrl;
  List<String> registeredSpots;
  String category; // 'hiking', 'camping', 'beach', 'adventure', 'nature'
  String inclusionsDescription;
  String departureDate;
  String returnDate;
  String departureTime;
  String meetingPointNote;
  String whatsappGroupLink;
  String destinationPoint;
  int minQuota;
  int maxQuota;
  int currentParticipants;
  String registrationDeadline;
  String itineraryText;
  String preparationNotes;
  String difficulty; // 'easy', 'medium', 'hard'
  String hostName;
  String hostWhatsApp;
  bool isPublic;
  String allowedJoinGroup; // 'Semua Wisatawan', 'Komunitas Terverifikasi'
  bool requiresApproval;
  bool isPublished;
  List<OpenTripJoinRequest> joinRequests;

  OpenTripData({
    required this.name,
    required this.coverUrl,
    required this.registeredSpots,
    required this.category,
    required this.inclusionsDescription,
    required this.departureDate,
    required this.returnDate,
    required this.departureTime,
    required this.meetingPointNote,
    required this.whatsappGroupLink,
    required this.destinationPoint,
    required this.minQuota,
    required this.maxQuota,
    this.currentParticipants = 4,
    required this.registrationDeadline,
    required this.itineraryText,
    required this.preparationNotes,
    required this.difficulty,
    required this.hostName,
    required this.hostWhatsApp,
    this.isPublic = true,
    this.allowedJoinGroup = 'Semua Wisatawan',
    this.requiresApproval = true,
    this.isPublished = true,
    List<OpenTripJoinRequest>? joinRequests,
  }) : joinRequests = joinRequests ?? [];
}

/// Sheet Manajemen & Pembuatan Open Trip Sesuai Alur Spesifikasi
class TripPlannerSheet extends StatefulWidget {
  const TripPlannerSheet({super.key});

  @override
  State<TripPlannerSheet> createState() => _TripPlannerSheetState();
}

class SystemTouristSpot {
  final String name;
  final String region;
  final String category;
  final String imageUrl;
  final String feeInfo;

  const SystemTouristSpot({
    required this.name,
    required this.region,
    required this.category,
    required this.imageUrl,
    required this.feeInfo,
  });
}

class _TripPlannerSheetState extends State<TripPlannerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Daftar Tempat Wisata Terdaftar di Sistem dengan Kartu Lengkap
  final List<SystemTouristSpot> _systemPlaces = const [
    SystemTouristSpot(
      name: 'Lembah Harau & Sarasah Bunta',
      region: 'Kab. Lima Puluh Kota',
      category: 'Tebing & Air Terjun',
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300',
      feeInfo: 'Tiket Perda Rp 5.000',
    ),
    SystemTouristSpot(
      name: 'Danau Maninjau & Kelok 44',
      region: 'Kab. Agam',
      category: 'Danau & Kaldera',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300',
      feeInfo: 'Tiket Perda Rp 5.000',
    ),
    SystemTouristSpot(
      name: 'Gunung Marapi (Koto Baru)',
      region: 'Kab. Tanah Datar & Agam',
      category: 'Hiking & Gunung Api',
      imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300',
      feeInfo: 'Simaksi BKSDA Rp 15.000',
    ),
    SystemTouristSpot(
      name: 'Puncak Lawang & Kebun Tebu',
      region: 'Kab. Agam',
      category: 'Paralayang & Panorama',
      imageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=300',
      feeInfo: 'Tiket Perda Rp 10.000',
    ),
    SystemTouristSpot(
      name: 'Pantai Gandoriah & Angso Duo',
      region: 'Kota Pariaman',
      category: 'Pantai & Bahari',
      imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300',
      feeInfo: 'Tiket Perda Rp 5.000',
    ),
    SystemTouristSpot(
      name: 'Kawasan Mandeh (Raja Ampat Minang)',
      region: 'Kab. Pesisir Selatan',
      category: 'Island Hopping & Bahari',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=300',
      feeInfo: 'Tiket Perda Rp 10.000',
    ),
    SystemTouristSpot(
      name: 'Air Terjun Lubuk Hitam (Cindakir)',
      region: 'Kota Padang (Teluk Kabung)',
      category: 'Air Terjun 3 Tingkat',
      imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=300',
      feeInfo: 'Tiket Perda Rp 5.000',
    ),
    SystemTouristSpot(
      name: 'Kapalo Banda Taram',
      region: 'Kab. Lima Puluh Kota',
      category: 'Rakit Bambu & Danau',
      imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=300',
      feeInfo: 'Tiket Perda Rp 5.000',
    ),
    SystemTouristSpot(
      name: 'Istano Basa Pagaruyung',
      region: 'Kab. Tanah Datar',
      category: 'Cagar Budaya & Museum',
      imageUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=300',
      feeInfo: 'Tiket Perda Rp 15.000',
    ),
  ];

  final TextEditingController _spotSearchController = TextEditingController();
  String _spotSearchQuery = '';

  // Kategori
  final List<String> _categories = ['hiking', 'camping', 'beach', 'adventure', 'nature'];

  // Kesulitan
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _inclusionsController;
  late TextEditingController _departureDateController;
  late TextEditingController _returnDateController;
  late TextEditingController _timeController;
  late TextEditingController _meetingNoteController;
  late TextEditingController _whatsappGroupController;
  late TextEditingController _destinationController;
  late TextEditingController _minQuotaController;
  late TextEditingController _maxQuotaController;
  late TextEditingController _deadlineController;
  late TextEditingController _itineraryController;
  late TextEditingController _prepController;
  late TextEditingController _hostNameController;
  late TextEditingController _hostPhoneController;

  // Date & Time Picker Values (Sistem Kalender Interaktif)
  DateTime _departureDate = DateTime(2026, 11, 21);
  DateTime _returnDate = DateTime(2026, 11, 22);
  TimeOfDay _departureTime = const TimeOfDay(hour: 6, minute: 0);
  DateTime _deadlineDate = DateTime(2026, 11, 20);
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 20, minute: 0);

  String _formatIndoDate(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final weekday = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} $month ${dt.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h.$m WIB';
  }

  String get _tripDurationBadge {
    final diff = _returnDate.difference(_departureDate).inDays;
    final days = diff < 0 ? 1 : diff + 1;
    final nights = (days - 1).clamp(0, 30);
    return '$days Hari $nights Malam';
  }

  Future<void> _pickDepartureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forest,
              onPrimary: Colors.white,
              surface: AppColors.cream,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _departureDate = picked;
        if (_returnDate.isBefore(_departureDate)) {
          _returnDate = _departureDate.add(const Duration(days: 1));
        }
        _departureDateController.text = _formatIndoDate(_departureDate);
        _returnDateController.text = _formatIndoDate(_returnDate);
      });
    }
  }

  Future<void> _pickReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate.isBefore(_departureDate) ? _departureDate : _returnDate,
      firstDate: _departureDate,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forest,
              onPrimary: Colors.white,
              surface: AppColors.cream,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _returnDate = picked;
        _returnDateController.text = _formatIndoDate(_returnDate);
      });
    }
  }

  Future<void> _pickDepartureTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forest,
              onPrimary: Colors.white,
              surface: AppColors.cream,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _departureTime = picked;
        _timeController.text = _formatTime(_departureTime);
      });
    }
  }

  Future<void> _pickDeadlineDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate,
      firstDate: DateTime(2025),
      lastDate: _departureDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forest,
              onPrimary: Colors.white,
              surface: AppColors.cream,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _deadlineDate = picked;
        _deadlineController.text = '${_formatIndoDate(_deadlineDate)}, ${_formatTime(_deadlineTime)}';
      });
    }
  }

  Future<void> _pickDeadlineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forest,
              onPrimary: Colors.white,
              surface: AppColors.cream,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _deadlineTime = picked;
        _deadlineController.text = '${_formatIndoDate(_deadlineDate)}, ${_formatTime(_deadlineTime)}';
      });
    }
  }

  // Form State Values
  String _selectedCategory = 'camping';
  String _selectedDifficulty = 'medium';
  final List<String> _selectedSpots = ['Lembah Harau', 'Kapalo Banda Taram'];
  bool _isPublic = true;
  final String _allowedJoinGroup = 'Semua Wisatawan';
  bool _requiresApproval = true;
  String _selectedCoverUrl = 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800';

  // Joiner Dialog State
  final TextEditingController _joinerNameController = TextEditingController(text: 'Rian Pratama');
  final TextEditingController _joinerPhoneController = TextEditingController(text: '081267889900');
  String _myJoinStatus = 'none'; // 'none', 'pending', 'accepted'

  // Model Data Aktif
  late OpenTripData _currentTrip;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _nameController = TextEditingController(text: 'Eksplor Harau Camp & Air Terjun');
    _inclusionsController = TextEditingController(
      text: '- Transportasi PP Padang/Payakumbuh\n'
          '- Tiket Masuk Resmi Perda & Spot Wisata\n'
          '- Makan 3x Sehari (Masakan Khas Minang)\n'
          '- Tour Guide Berlisensi Nagari\n'
          '- Dokumentasi Foto & Drone\n'
          '- Tenda Dome & Matras Camping',
    );
    _departureDateController = TextEditingController(text: '2026-11-21');
    _returnDateController = TextEditingController(text: '2026-11-22');
    _timeController = TextEditingController(text: '06.00 WIB');
    _meetingNoteController = TextEditingController(text: 'Rest Area Simpang Harau / Gerbang Masuk Nagari');
    _whatsappGroupController = TextEditingController(text: 'https://chat.whatsapp.com/WisgoHarauCamp2026');
    _destinationController = TextEditingController(text: 'Sarasah Bunta & Kapalo Banda Taram');
    _minQuotaController = TextEditingController(text: '4');
    _maxQuotaController = TextEditingController(text: '10');
    _deadlineController = TextEditingController(text: '20 Nov 2026, 20:00 WIB');
    _itineraryController = TextEditingController(
      text: 'Day 1\n'
          '- 06.00 — Meeting point (Rest Area)\n'
          '- 07.00 — Berangkat bersama menuju Harau\n'
          '- 10.00 — Tiba di basecamp Sarasah\n'
          '- 11.00 — Trekking & renang air terjun\n'
          '- 17.00 — Sunset & dirikan camping\n'
          '- 19.30 — Barbeque & makan malam\n\n'
          'Day 2\n'
          '- 06.00 — Sunrise panorama tebing Harau\n'
          '- 08.00 — Sarapan pagi\n'
          '- 09.00 — Turun & eksplor Kapalo Banda (Rakit bambu)\n'
          '- 14.00 — Pulang kembali ke titik kumpul',
    );
    _prepController = TextEditingController(
      text: '- Jaket tebal / windbreaker anti angin\n'
          '- Sepatu trekking / sandal outdoor\n'
          '- Pakaian ganti & perlengkapan ibadah\n'
          '- Obat-obatan pribadi & botol minum\n'
          '- Jas hujan / ponco & senter/headlamp',
    );
    _hostNameController = TextEditingController(text: 'Rahmat Hidayat (Guide Nagari)');
    _hostPhoneController = TextEditingController(text: '081267891234');

    _currentTrip = OpenTripData(
      name: _nameController.text,
      coverUrl: _selectedCoverUrl,
      registeredSpots: List.from(_selectedSpots),
      category: _selectedCategory,
      inclusionsDescription: _inclusionsController.text,
      departureDate: _departureDateController.text,
      returnDate: _returnDateController.text,
      departureTime: _timeController.text,
      meetingPointNote: _meetingNoteController.text,
      whatsappGroupLink: _whatsappGroupController.text,
      destinationPoint: _destinationController.text,
      minQuota: int.tryParse(_minQuotaController.text) ?? 4,
      maxQuota: int.tryParse(_maxQuotaController.text) ?? 10,
      currentParticipants: 4,
      registrationDeadline: _deadlineController.text,
      itineraryText: _itineraryController.text,
      preparationNotes: _prepController.text,
      difficulty: _selectedDifficulty,
      hostName: _hostNameController.text,
      hostWhatsApp: _hostPhoneController.text,
      isPublic: _isPublic,
      allowedJoinGroup: _allowedJoinGroup,
      requiresApproval: _requiresApproval,
      isPublished: true,
      joinRequests: [
        OpenTripJoinRequest(
          id: 'req_1',
          travelerName: 'Siti Rahma',
          whatsappNumber: '08219876543',
          requestedAt: '10 menit lalu',
          status: 'pending',
        ),
        OpenTripJoinRequest(
          id: 'req_2',
          travelerName: 'Doni Pratama',
          whatsappNumber: '08137788990',
          requestedAt: '35 menit lalu',
          status: 'accepted',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _spotSearchController.dispose();
    _nameController.dispose();
    _inclusionsController.dispose();
    _departureDateController.dispose();
    _returnDateController.dispose();
    _timeController.dispose();
    _meetingNoteController.dispose();
    _whatsappGroupController.dispose();
    _destinationController.dispose();
    _minQuotaController.dispose();
    _maxQuotaController.dispose();
    _deadlineController.dispose();
    _itineraryController.dispose();
    _prepController.dispose();
    _hostNameController.dispose();
    _hostPhoneController.dispose();
    _joinerNameController.dispose();
    _joinerPhoneController.dispose();
    super.dispose();
  }

  void _syncTripFromForm() {
    _currentTrip.name = _nameController.text;
    _currentTrip.coverUrl = _selectedCoverUrl;
    _currentTrip.registeredSpots = List.from(_selectedSpots);
    _currentTrip.category = _selectedCategory;
    _currentTrip.inclusionsDescription = _inclusionsController.text;
    _currentTrip.departureDate = _departureDateController.text;
    _currentTrip.returnDate = _returnDateController.text;
    _currentTrip.departureTime = _timeController.text;
    _currentTrip.meetingPointNote = _meetingNoteController.text;
    _currentTrip.whatsappGroupLink = _whatsappGroupController.text;
    _currentTrip.destinationPoint = _destinationController.text;
    _currentTrip.minQuota = int.tryParse(_minQuotaController.text) ?? 4;
    _currentTrip.maxQuota = int.tryParse(_maxQuotaController.text) ?? 10;
    _currentTrip.registrationDeadline = _deadlineController.text;
    _currentTrip.itineraryText = _itineraryController.text;
    _currentTrip.preparationNotes = _prepController.text;
    _currentTrip.difficulty = _selectedDifficulty;
    _currentTrip.hostName = _hostNameController.text;
    _currentTrip.hostWhatsApp = _hostPhoneController.text;
    _currentTrip.isPublic = _isPublic;
    _currentTrip.allowedJoinGroup = _allowedJoinGroup;
    _currentTrip.requiresApproval = _requiresApproval;
  }

  void _onPreviewTrip() {
    setState(() {
      _syncTripFromForm();
      _tabController.animateTo(1);
    });
  }

  void _onPublishTrip() {
    setState(() {
      _syncTripFromForm();
      _currentTrip.isPublished = true;
      _tabController.animateTo(1);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Berhasil Mempublikasikan Open Trip! Kini wisatawan lain dapat melihat dan mengajukan bergabung.'),
        backgroundColor: AppColors.forest,
      ),
    );
  }

  void _handleJoinRequestSubmit() {
    if (_joinerNameController.text.trim().isEmpty || _joinerPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan nama dan nomor WhatsApp Anda.')),
      );
      return;
    }

    setState(() {
      if (_currentTrip.requiresApproval) {
        _myJoinStatus = 'pending';
        _currentTrip.joinRequests.add(
          OpenTripJoinRequest(
            id: 'req_${DateTime.now().millisecondsSinceEpoch}',
            travelerName: _joinerNameController.text.trim(),
            whatsappNumber: _joinerPhoneController.text.trim(),
            requestedAt: 'Baru saja',
            status: 'pending',
          ),
        );
      } else {
        _myJoinStatus = 'accepted';
        _currentTrip.currentParticipants++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _currentTrip.requiresApproval
              ? ' Permintaan bergabung terkirim! Menunggu persetujuan host.'
              : ' Berhasil langsung bergabung ke Open Trip!',
        ),
        backgroundColor: AppColors.forest,
      ),
    );
  }

  void _acceptJoinRequest(OpenTripJoinRequest req) {
    setState(() {
      req.status = 'accepted';
      _currentTrip.currentParticipants = (_currentTrip.currentParticipants + 1).clamp(0, _currentTrip.maxQuota);
      if (req.travelerName == _joinerNameController.text.trim()) {
        _myJoinStatus = 'accepted';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(' Permintaan ${req.travelerName} DISETUJUI! Link WhatsApp Group telah dirilis untuknya.'),
        backgroundColor: AppColors.forest,
      ),
    );
  }

  void _rejectJoinRequest(OpenTripJoinRequest req) {
    setState(() {
      req.status = 'rejected';
      if (req.travelerName == _joinerNameController.text.trim()) {
        _myJoinStatus = 'none';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Permintaan ${req.travelerName} ditolak.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.94,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(bottom: BorderSide(color: AppColors.warmBorder)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.ink),
                            SizedBox(width: 4),
                            Text('Tutup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ],
                        ),
                      ),
                    ),
                    const Flexible(
                      child: Text(
                        'BUAT & KELOLA JADWAL OPEN TRIP',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.forest),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.forest,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.forest,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  tabs: [
                    const Tab(text: 'Buat Trip'),
                    const Tab(text: 'Detail & Pratinjau'),
                    Tab(
                      text: 'Permintaan Host (${_currentTrip.joinRequests.where((r) => r.status == 'pending').length})',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormTab(),
                _buildPreviewDetailTab(),
                _buildJoinRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: FORM BUAT OPEN TRIP
  // ===========================================================================
  Widget _buildFormTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // 1. Nama & Foto/Cover
        _buildSectionHeader('NAMA OPEN TRIP & COVER'),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration('Contoh: Eksplor Harau Camp & Air Terjun'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sageBorder),
            image: DecorationImage(
              image: NetworkImage(_selectedCoverUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCoverUrl = _selectedCoverUrl.contains('photo-1506744038136')
                          ? 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800'
                          : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800';
                    });
                  },
                  icon: const Icon(Icons.photo_camera_rounded, size: 14),
                  label: const Text('Ganti / Unggah Cover Foto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.forest,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Opsi Tempat Wisata Terdaftar di Sistem (Search + Card Tempat)
        _buildSectionHeader('DESTINASI WISATA TERDAFTAR'),
        TextField(
          controller: _spotSearchController,
          onChanged: (val) => setState(() => _spotSearchQuery = val.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Cari tempat wisata (Harau, Maninjau, Marapi)...',
            hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.forest),
            suffixIcon: _spotSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.muted),
                    onPressed: () {
                      _spotSearchController.clear();
                      setState(() => _spotSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.sageBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
            ),
          ),
          style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 230),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Builder(builder: (context) {
            final filteredSpots = _systemPlaces.where((s) {
              if (_spotSearchQuery.isEmpty) return true;
              return s.name.toLowerCase().contains(_spotSearchQuery) ||
                  s.region.toLowerCase().contains(_spotSearchQuery) ||
                  s.category.toLowerCase().contains(_spotSearchQuery);
            }).toList();

            if (filteredSpots.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Tidak menemukan tempat wisata dengan kata kunci "$_spotSearchQuery"',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: filteredSpots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final spot = filteredSpots[index];
                final isSelected = _selectedSpots.contains(spot.name);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedSpots.length > 1) {
                          _selectedSpots.remove(spot.name);
                        }
                      } else {
                        _selectedSpots.add(spot.name);
                      }
                      // Otomatis masukkan nama tempat ke field titik akhir & nama open trip
                      _destinationController.text = _selectedSpots.join(' & ');
                      if (_nameController.text.isEmpty || _nameController.text.contains('Eksplor Harau')) {
                        _nameController.text = 'Eksplor ${_selectedSpots.first}';
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.sage : const Color(0xFFFAF3E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.forest : AppColors.sageBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            spot.imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => Container(
                              width: 44,
                              height: 44,
                              color: AppColors.forest,
                              child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot.name,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? AppColors.forest : AppColors.ink,
                                ),
                              ),
                              Text(
                                '📍 ${spot.region} • ${spot.category}',
                                style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                              ),
                              Text(
                                spot.feeInfo,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.forest : Colors.white,
                            border: Border.all(color: isSelected ? AppColors.forest : AppColors.sageBorder),
                          ),
                          child: Icon(
                            isSelected ? Icons.check_rounded : Icons.add_rounded,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TEMPAT WISATA OTOMATIS TERHUBUNG:',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    Text(
                      _selectedSpots.isNotEmpty ? _selectedSpots.join(', ') : 'Belum ada tempat dipilih',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Kategori
        _buildSectionHeader('KATEGORI PERJALANAN'),
        Wrap(
          spacing: 6,
          children: _categories.map((cat) {
            final isSel = _selectedCategory == cat;
            return ChoiceChip(
              selected: isSel,
              label: Text(
                cat.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSel ? Colors.white : AppColors.forest),
              ),
              selectedColor: AppColors.forest,
              backgroundColor: AppColors.sage,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (_) => setState(() => _selectedCategory = cat),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 4. Deskripsi Trip Termasuk Apa Saja (Manual)
        _buildSectionHeader('FASILITAS TERMASUK (INCLUSIONS)'),
        TextFormField(
          controller: _inclusionsController,
          maxLines: 5,
          decoration: _inputDecoration('Contoh:\n- Transportasi\n- Tiket Masuk\n- Makan\n- Guide\n- Dokumentasi\n- Tenda, dll.'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
        ),

        const SizedBox(height: 16),

        // Jadwal & Waktu Keberangkatan (Modern Date & Time System)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.date_range_rounded, size: 16, color: AppColors.forest),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'JADWAL & WAKTU KEBERANGKATAN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E5B82).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _tripDurationBadge,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF1E5B82)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Card Tanggal Berangkat
                  Expanded(
                    child: InkWell(
                      onTap: _pickDepartureDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF3E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warmBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flight_takeoff_rounded, size: 13, color: AppColors.forest),
                                SizedBox(width: 4),
                                Text('TANGGAL BERANGKAT', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatIndoDate(_departureDate),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                            const Text('Ketuk untuk ubah tanggal', style: TextStyle(fontSize: 8.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Card Tanggal Pulang
                  Expanded(
                    child: InkWell(
                      onTap: _pickReturnDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF3E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warmBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flight_land_rounded, size: 13, color: AppColors.forest),
                                SizedBox(width: 4),
                                Text('TANGGAL PULANG', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatIndoDate(_returnDate),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                            const Text('Ketuk untuk ubah tanggal', style: TextStyle(fontSize: 8.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Card Jam Kumpul
              InkWell(
                onTap: _pickDepartureTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF3E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 16, color: AppColors.forest),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WAKTU KUMPUL (MEETING)', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                              Text('Pilih jam kumpul di meeting point', style: TextStyle(fontSize: 10, color: AppColors.ink)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: Text(
                          _formatTime(_departureTime),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.forest),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 7. Meeting via Group WhatsApp
        _buildSectionHeader('MEETING POINT & KOORDINASI WHATSAPP'),
        TextField(
          controller: _whatsappGroupController,
          decoration: _inputDecoration('Tautan Grup WhatsApp (e.g. https://chat.whatsapp.com/...)'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.forest, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _meetingNoteController,
          decoration: _inputDecoration('Catatan Titik Kumpul Fisik (e.g. Simpang Harau / Rest Area Lembah Anai)'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
        ),

        const SizedBox(height: 16),

        // 8. Titik Akhir / Destinasi
        _buildSectionHeader('TITIK AKHIR DESTINASI'),
        TextField(
          controller: _destinationController,
          decoration: _inputDecoration('Nama titik akhir / destinasi tujuan trip'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
        ),

        const SizedBox(height: 16),

        // Kuota & Batas Pendaftaran Modern
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('KAPASITAS KUOTA & BATAS PENDAFTARAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MIN PESERTA', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          TextField(
                            controller: _minQuotaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MAKSIMAL KUOTA', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          TextField(
                            controller: _maxQuotaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Batas Pendaftaran (Interactive Date & Time Picker)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BATAS AKHIR PENDAFTARAN', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDeadlineDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.sageBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 14, color: AppColors.forest),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(_formatIndoDate(_deadlineDate), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _pickDeadlineTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.sageBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.terracotta),
                                const SizedBox(width: 4),
                                Text(_formatTime(_deadlineTime), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.terracotta)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 11. Itinerary Harian
        _buildSectionHeader('ITINERARY PERJALANAN'),
        TextFormField(
          controller: _itineraryController,
          maxLines: 7,
          decoration: _inputDecoration('Day 1\n- 06.00 — Meeting point\n- 07.00 — Berangkat\nDay 2\n- 06.00 — Sunrise'),
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.ink),
        ),

        const SizedBox(height: 16),

        // 12. Pemberitahuan Persiapan
        _buildSectionHeader('PERSIAPAN & BARANG BAWAAN'),
        TextFormField(
          controller: _prepController,
          maxLines: 4,
          decoration: _inputDecoration('- Barang yang wajib dibawa\n- Pakaian ganti\n- Jas hujan'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.ink),
        ),

        const SizedBox(height: 16),

        // 13. Tingkat Kesulitan
        _buildSectionHeader('TINGKAT KESULITAN'),
        Row(
          children: _difficulties.map((diff) {
            final isSel = _selectedDifficulty == diff;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSel,
                label: Text(
                  diff.toUpperCase(),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: isSel ? Colors.white : AppColors.ink),
                ),
                selectedColor: diff == 'easy'
                    ? const Color(0xFF15803D)
                    : diff == 'medium'
                        ? const Color(0xFFC89242)
                        : AppColors.terracotta,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) => setState(() => _selectedDifficulty = diff),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 14. Kontak Pembuat
        _buildSectionHeader('KONTAK PEMBUAT (HOST)'),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Pembuat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  TextField(controller: _hostNameController, decoration: _inputDecoration('Rahmat Hidayat')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nomor WhatsApp', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  TextField(controller: _hostPhoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('081267891234')),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Pengaturan Open Trip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PENGATURAN OPEN TRIP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest)),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visibilitas Publik', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  _isPublic ? 'Tampil terbuka di board pencarian Open Trip' : 'Privat (Hanya lewat tautan undangan)',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                value: _isPublic,
                activeColor: AppColors.forest,
                onChanged: (val) => setState(() => _isPublic = val),
              ),
              const Divider(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Perlu Persetujuan Host', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                subtitle: Text(
                  _requiresApproval
                      ? 'Calon peserta harus di-accept host sebelum mendapatkan link WhatsApp'
                      : 'Langsung join otomatis',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                value: _requiresApproval,
                activeColor: AppColors.forest,
                onChanged: (val) => setState(() => _requiresApproval = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons: [ Preview ] -> [ Publish Open Trip ]
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _onPreviewTrip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forest,
                  side: const BorderSide(color: AppColors.forest, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Preview Open Trip', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _onPublishTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Publish Open Trip', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: PREVIEW & DETAIL TRIP + JOIN OPEN TRIP
  // ===========================================================================
  Widget _buildPreviewDetailTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        // Hero Card
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Image.network(
                _currentTrip.coverUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => Container(height: 170, color: AppColors.forest),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentTrip.category.toUpperCase(),
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentTrip.difficulty == 'easy'
                        ? const Color(0xFF15803D)
                        : _currentTrip.difficulty == 'medium'
                            ? const Color(0xFFC89242)
                            : AppColors.terracotta,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'KESULITAN: ${_currentTrip.difficulty.toUpperCase()}',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    _currentTrip.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Ringkasan Kuota & Jadwal
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group_rounded, size: 16, color: AppColors.forest),
                      const SizedBox(width: 6),
                      Text(
                        'Kuota: ${_currentTrip.currentParticipants} / ${_currentTrip.maxQuota} Peserta (Min. ${_currentTrip.minQuota})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ],
                  ),
                  Text(
                    'Deadline: ${_currentTrip.registrationDeadline}',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconText(Icons.calendar_today_rounded, '${_currentTrip.departureDate} s/d ${_currentTrip.returnDate}'),
                  _buildIconText(Icons.access_time_rounded, _currentTrip.departureTime),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Spot Terdaftar di Sistem
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TEMPAT WISATA DALAM SISTEM:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _currentTrip.registeredSpots.map((spot) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                    ),
                    child: Text(spot, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text('Titik Akhir: ${_currentTrip.destinationPoint}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text('Meeting Point: ${_currentTrip.meetingPointNote}', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Fasilitas Termasuk
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FASILITAS YANG TERMASUK:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.forest)),
              const SizedBox(height: 6),
              Text(_currentTrip.inclusionsDescription, style: const TextStyle(fontSize: 11, color: AppColors.ink, height: 1.4)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Itinerary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ITINERARY LENGKAP:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.forest)),
              const SizedBox(height: 6),
              Text(_currentTrip.itineraryText, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.ink, height: 1.4)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Persiapan & Kontak Host
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PERSIAPAN & BARANG WAJIB DIBAWA:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.terracotta)),
              const SizedBox(height: 6),
              Text(_currentTrip.preparationNotes, style: const TextStyle(fontSize: 11, color: AppColors.ink)),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Host / Pembuat Open Trip:', style: TextStyle(fontSize: 9.5, color: AppColors.muted)),
                      Text(_currentTrip.hostName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.forest)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: Text('WA: ${_currentTrip.hostWhatsApp}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // =====================================================================
        // BAGIAN GABUNG OPEN TRIP & RELEASE LINK WHATSAPP
        // =====================================================================
        _buildJoinStatusCard(),
      ],
    );
  }

  Widget _buildJoinStatusCard() {
    if (_myJoinStatus == 'accepted') {
      // Kondisi SUDAH DI-ACCEPT HOST: LINK WHATSAPP GROUP DIBERIKAN!
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
                SizedBox(width: 8),
                Text(
                  'PERMINTAAN GABUNG DISETUJUI HOST!',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Anda telah resmi terdaftar dalam rombongan Open Trip ini. Silakan masuk ke WhatsApp Group koordinasi berikut untuk briefing keberangkatan:',
              style: TextStyle(fontSize: 11, color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Membuka Grup WhatsApp: ${_currentTrip.whatsappGroupLink}'),
                      backgroundColor: const Color(0xFF15803D),
                    ),
                  );
                },
                icon: const Icon(Icons.forum_rounded, size: 18),
                label: const Text('Masuk ke Grup WhatsApp Open Trip', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_myJoinStatus == 'pending') {
      // Kondisi MENUNGGU PERSETUJUAN HOST
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 18),
                SizedBox(width: 8),
                Text(
                  'Menunggu Persetujuan Host...',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Permintaan bergabung Anda atas nama ${_joinerNameController.text} sedang ditinjau oleh Host (${_currentTrip.hostName}). Link WhatsApp Group akan diberikan setelah host menekan tombol Terima / Accept.',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF78350F)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('Lihat Status di Tab Permintaan Host ->', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest)),
            ),
          ],
        ),
      );
    }

    // Kondisi BELUM GABUNG: Form Input Traveler & Tombol Join
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GABUNG OPEN TRIP INI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
          const SizedBox(height: 4),
          const Text(
            'Isi data Anda untuk mengajukan bergabung. Host akan memverifikasi sebelum Anda dimasukkan ke WhatsApp Group koordinasi.',
            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _joinerNameController,
            decoration: _inputDecoration('Nama Lengkap Anda'),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _joinerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Nomor WhatsApp Anda'),
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleJoinRequestSubmit,
              icon: const Icon(Icons.group_add_rounded, size: 16),
              label: Text(
                _currentTrip.requiresApproval ? 'Ajukan Permintaan Bergabung' : 'Langsung Join Open Trip',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: DAFTAR PERMINTAAN BERGABUNG (PANEL HOST)
  // ===========================================================================
  Widget _buildJoinRequestsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.sage,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PANEL HOST: ${_currentTrip.hostName}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
              ),
              const SizedBox(height: 4),
              const Text(
                'Saat Anda menekan tombol "Terima (Accept)", peserta dinyatakan resmi bergabung dan tautan link WhatsApp Group otomatis dirilis ke layar mereka.',
                style: TextStyle(fontSize: 10.5, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_currentTrip.joinRequests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text('Belum ada permintaan bergabung dari wisatawan.', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
          )
        else
          ..._currentTrip.joinRequests.map((req) {
            final isPending = req.status == 'pending';
            final isAccepted = req.status == 'accepted';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isAccepted ? const Color(0xFF22C55E) : AppColors.sageBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isAccepted ? const Color(0xFFF0FDF4) : AppColors.sage,
                    child: Icon(
                      isAccepted ? Icons.check_circle_rounded : Icons.person_rounded,
                      color: isAccepted ? const Color(0xFF15803D) : AppColors.forest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.travelerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        Text('WA: ${req.whatsappNumber} • ${req.requestedAt}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAccepted
                                ? const Color(0xFFF0FDF4)
                                : isPending
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAccepted
                                ? ' Diterima (WA Group Terbuka)'
                                : isPending
                                    ? '⏳ Menunggu Persetujuan'
                                    : '✕ Ditolak',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isAccepted
                                  ? const Color(0xFF15803D)
                                  : isPending
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPending)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 28),
                          tooltip: 'Terima Permintaan',
                          onPressed: () => _acceptJoinRequest(req),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: AppColors.terracotta, size: 28),
                          tooltip: 'Tolak',
                          onPressed: () => _rejectJoinRequest(req),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.lock_open_rounded, color: Color(0xFF15803D), size: 20),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.forest),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.sageBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ],
    );
  }
}
