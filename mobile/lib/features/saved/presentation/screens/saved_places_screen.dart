import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_guard_dialog.dart';
import '../../../../core/widgets/wisgo_destination_image.dart';
import '../../../../core/widgets/wisgo_facility_icon.dart';
import '../../../auth/presentation/screens/edit_profile_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/splash_screen.dart';
import '../../../auth/services/auth_session.dart';
import '../../../fair_price/data/models/fair_price_tariff_model.dart';
import '../../../proposal/presentation/widgets/usul_destinasi_sheet.dart';
import '../../../qr_scanner/presentation/widgets/qr_scanner_sheet.dart';
import '../../../trip_planner/models/open_trip_model.dart';
import '../../../trip_planner/presentation/widgets/open_trip_card.dart';
import '../../../trip_planner/presentation/widgets/open_trip_organizer_hub_sheet.dart';
import '../../../trip_planner/presentation/widgets/trip_go_agreement_dialog.dart';
import '../../../trip_planner/presentation/widgets/trip_eticket_sheet.dart';
import '../../../trip_planner/presentation/widgets/trip_planner_detail_sheet.dart';
import '../../../trip_planner/services/trip_eticket_store.dart';
import '../../../reports/presentation/widgets/lapor_pungli_sheet.dart';
import '../../../fe1_visual_map/audio_guide_culture/audio_culture_screen.dart';
import '../../../fe1_visual_map/destination_detail/destination_detail_screen.dart';
import '../../../fe1_visual_map/hazard_alert_sos/hazard_sos_screen.dart';
import '../../../fe1_visual_map/map_explore_shunlu/map_explore_screen.dart';
import '../../../fe1_visual_map/map_explore_shunlu/widgets/sumbar_real_map_widget.dart';
import '../../../fe1_visual_map/models/destination_model.dart';
import '../../../fe1_visual_map/offline_pocket/offline_pocket_screen.dart';
import '../../../fe1_visual_map/virtual_tour_360/virtual_tour_360_gallery_screen.dart';
import '../../../fe1_visual_map/virtual_tour_360/virtual_tour_360_screen.dart';
import '../../../booking/presentation/widgets/quick_booking_panel.dart';
import '../../../group_room/presentation/widgets/live_group_tracking_sheet.dart';
import '../../../passport/presentation/widgets/digital_passport_sheet.dart';
import '../../../gamification/presentation/screens/activity_history_screen.dart';
import '../../../gamification/services/gamification_service.dart';
import '../../../trip_planner/models/travel_experience_model.dart';
import '../../../trip_planner/presentation/widgets/travel_experience_sheet.dart';
import '../../../trip_planner/presentation/widgets/travel_share_card_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/saved_empty_state.dart';
import '../widgets/wisgo_hero_slider.dart';

/// Extension untuk menjembatani model FE-2 dengan layar detail FE-1
extension SavedDestinationModelFe1Bridge on SavedDestinationModel {
  DestinationModel toFe1Destination() {
    return DestinationModel(
      id: id,
      name: title,
      category: natureType == 'ALL' ? 'Alam' : natureType,
      cityRegency: subRegion,
      description:
          'Destinasi wisata $title berlokasi di $subRegion, Sumatera Barat. Dikelola resmi dengan transparansi tiket dan fasilitas sesuai regulasi $perdaRef.',
      latitude: -0.95,
      longitude: 100.35,
      coverImage: imageUrl,
      crowdLevel: 'Sedang',
      distanceKm:
          '${distanceKm.toStringAsFixed(distanceKm.truncateToDouble() == distanceKm ? 0 : 1)} km',
      travelTime: duration,
      entryFee: 'Rp ${calcRates.tiket}',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-$id',
        destinationId: id,
        vehicleAccess: 'Mobil OK',
        trekkingLevel: terrainNote.toLowerCase().contains('jalan kaki') ||
                terrainNote.toLowerCase().contains('trekking')
            ? 'Sedang (Jalan Kaki)'
            : 'Mudah (Datar)',
        cellularSignal: 'Sinyal Lemah / Siap Luring',
        facilities: facilities.length > 2
            ? '${facilities.take(2).join(', ')}, +${facilities.length - 2} lainnya'
            : (facilities.isNotEmpty ? facilities.join(', ') : 'Ada Toilet & Musala'),
        guideNeed: 'Bisa Mandiri',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-$id-1',
          destinationId: id,
          content:
              'Simpan tiket QR digital di perangkat Anda sebelum tiba di lokasi agar tidak terkendala sinyal lemah.',
          isImportant: true,
        ),
        LocalTipModel(
          id: 'tip-$id-2',
          destinationId: id,
          content:
              'Patuhi tata tertib lokal dan gunakan tarif resmi sesuai $perdaRef.',
          isImportant: false,
        ),
      ],
      tariffs: tariffs
          .map((t) => OfficialTariffModel(
                id: '$id-${t.name}',
                destinationId: id,
                itemName: t.name,
                price: (int.tryParse(t.official.replaceAll(RegExp(r'\D'), '')) ??
                        10000)
                    .toDouble(),
                unit: t.note.isNotEmpty ? t.note : 'per orang/kendaraan',
                regulationRef: perdaRef,
              ))
          .toList(),
    );
  }
}

/// Layar Utama WISGO (1:1 dari `wisgo_interactive_3d_prototype (1).html`):
/// - Minimal Editorial Status Bar (`09:41 | WISGO SUMBAR | Daring / Tanpa Sinyal`)
/// - Global Static Offline Notification Banner (`Mode Tanpa Koneksi Internet`)
/// - View 0: Jelajah Daerah Sumbar (`Semua Daerah`, `Padang`, `Payakumbuh & 50 Kota`, `Bukittinggi & Agam`, `Daerah Terpencil` + Sub-kategori Alam)
/// - View 1: Layar 04 Destinasi Tersimpan (`Daftar`, `Efek Memuat`, `Kosong`, `Luring` + Filter Wilayah + Kartu Bergambar & Biaya Vertikal)
/// - View 2: Pilar 3 Rincian Biaya Resmi & Kalkulator Simulasi Vertikal
/// - Clean 4-Button Bottom Navigation Bar (`Daerah`, `Tersimpan`, `Tarif Resmi`, `Alur Awal`)
class SavedPlacesScreen extends StatefulWidget {
  final bool initialOfflineMode;
  final bool initialLoading;
  final int initialTabIndex;
  final bool isGuest;

  const SavedPlacesScreen({
    super.key,
    this.initialOfflineMode = false,
    this.initialLoading = false,
    this.initialTabIndex = 0,
    this.isGuest = false,
  });

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  // 0 = Daerah (Explore), 1 = Tersimpan (Saved), 2 = Tarif Resmi (Barometer)
  late int _activeTabIndex;
  late bool _isOfflineMode;

  // View 0: Explore Region, Nature Type, Search & Sort
  String _currentExploreRegion = 'ALL';
  String _currentExploreType = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'default'; // 'default' | 'distance' | 'rating'

  // View 1: Saved Places State
  late List<String> _savedIds;
  String _savedViewState = 'loaded'; // 'loaded' | 'shimmer' | 'empty'

  // View 2: Real Interactive Sumbar Map State & Google Maps Hub
  String? _selectedPetaDestinationId;
  SumbarMapCategory _selectedPetaCategory = SumbarMapCategory.semua;
  final ScrollController _petaScrollController = ScrollController();
  bool _petaMapInteracting = false;

  // Navigation Items (5 Tabs: Beranda, Trip Go, Check-In, Peta, Profil)
  static const List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Beranda',
      'labelEn': 'Home',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
    },
    {
      'label': 'Trip Go',
      'labelEn': 'Trip Go',
      'icon': Icons.groups_outlined,
      'activeIcon': Icons.groups_rounded,
    },
    {
      'label': 'Check-In',
      'labelEn': 'Check-In',
      'icon': Icons.qr_code_scanner_rounded,
      'activeIcon': Icons.qr_code_scanner_rounded,
    },
    {
      'label': 'Peta',
      'labelEn': 'Map',
      'icon': Icons.map_outlined,
      'activeIcon': Icons.map_rounded,
    },
    {
      'label': 'Profil',
      'labelEn': 'Profile',
      'icon': Icons.account_circle_outlined,
      'activeIcon': Icons.account_circle_rounded,
    },
  ];

  static const List<Map<String, String>> _exploreRegions = [
    {
      'key': 'ALL',
      'title': 'Semua Daerah',
      'sub': '8 Lokasi Lengkap',
    },
    {
      'key': 'Padang',
      'title': 'Padang',
      'sub': 'Air Terjun & Gunung',
    },
    {
      'key': 'Payakumbuh & 50 Kota',
      'title': 'Payakumbuh & 50 Kota',
      'sub': 'Lembah Harau & Kapalo Banda',
    },
    {
      'key': 'Bukittinggi & Agam',
      'title': 'Bukittinggi & Agam',
      'sub': 'Ngarai Sianok & Puncak Lawang',
    },
    {
      'key': 'Daerah Terpencil',
      'title': 'Daerah Terpencil',
      'sub': 'Nyarai, Pariangan, Mandeh',
    },
  ];

  static const List<Map<String, String>> _exploreTypes = [
    {'key': 'ALL', 'label': 'Semua Kategori'},
    {'key': 'Alam & Geopark', 'label': 'Alam & Geopark'},
    {'key': 'Budaya & Nagari', 'label': 'Budaya & Nagari'},
    {'key': 'Hidden Gem', 'label': 'Hidden Gem'},
    {'key': 'Religi', 'label': 'Religi'},
    {'key': 'Kuliner', 'label': 'Kuliner'},
  ];

  // Notifikasi & Pengingat Festival Budaya
  final Set<String> _remindedFestivalIds = {'ev_harau'};
  final List<Map<String, dynamic>> _appNotifications = [
    {
      'id': 'notif_1',
      'title': 'Pengingat Festival: Festival Pasa Harau 2026',
      'message': 'Acara kebudayaan akbar di Lembah Harau segera berlangsung pada 18 – 20 Desember 2026. Ketuk untuk panduan rute GPS.',
      'time': 'Hari ini, 08:00 WIB',
      'isRead': false,
      'type': 'festival',
      'eventId': 'ev_harau',
    },
    {
      'id': 'notif_2',
      'title': 'Permintaan Trip Go Disetujui!',
      'message': 'Host telah menerima permohonan Anda untuk bergabung di Eksplor Harau Camp. Tautan WhatsApp Group kini dapat diakses.',
      'time': '1 jam lalu',
      'isRead': false,
      'type': 'opentrip',
    },
    {
      'id': 'notif_3',
      'title': 'Lencana Paspor Digital Terbuka',
      'message': 'Selamat! Anda telah melakukan check-in GPS di Nagari Pariangan dan mendapatkan Lencana Resmi.',
      'time': 'Kemarin',
      'isRead': true,
      'type': 'passport',
    },
    {
      'id': 'notif_4',
      'title': 'Peringatan Jalur & Cuaca Nagari',
      'message': 'Kondisi jalur Lembah Anai terpantau cerah berawan dan lancar untuk dilalui rombongan wisata.',
      'time': '2 hari lalu',
      'isRead': true,
      'type': 'weather',
    },
  ];

  int get _unreadNotificationCount => _appNotifications.where((n) => n['isRead'] == false).length;

  // Open Trip & Trip Planner State
  String _openTripFilterCategory = 'Semua';
  String _tripGoSearchQuery = '';
  List<OpenTripItem>? _customOpenTrips;
  List<OpenTripItem> get _activeOpenTrips => _customOpenTrips ?? kMockOpenTrips;



  // Profile Editable State (nullable agar aman saat Hot Reload)
  String? _profileName = 'Ahmad Fauzi';
  String? _profilePhone = '+62 812-7578-953';
  String? _profileRole = 'Wisatawan Nusantara';
  String? _profileOrigin = 'Padang, Sumatera Barat';

  bool get _isCurrentGuest => AuthSession.instance.isGuest || widget.isGuest;

  String get _safeProfileName =>
      _isCurrentGuest
          ? AuthSession.instance.userName
          : ((_profileName?.trim().isNotEmpty ?? false) ? _profileName!.trim() : 'Ahmad Fauzi');
  String get _safeProfilePhone =>
      _isCurrentGuest
          ? '-'
          : ((_profilePhone?.trim().isNotEmpty ?? false) ? _profilePhone!.trim() : '+62 812-7578-953');
  String get _safeProfileRole =>
      _isCurrentGuest
          ? AuthSession.instance.userRole
          : ((_profileRole?.trim().isNotEmpty ?? false) ? _profileRole!.trim() : 'Wisatawan Nusantara');
  String get _safeProfileOrigin =>
      _isCurrentGuest
          ? AuthSession.instance.userOrigin
          : ((_profileOrigin?.trim().isNotEmpty ?? false) ? _profileOrigin!.trim() : 'Padang, Sumatera Barat');

  String get _safeProfileInitials {
    if (_isCurrentGuest) return 'TM';
    final parts = _safeProfileName.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'AF';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // Explore Scroll State (nullable & lazy-init agar aman saat Hot Reload)
  ScrollController? _exploreScrollController;
  GlobalKey? _wisataSectionKey;
  List<SavedDestinationModel>? _cachedHeroLandmarks;
  bool _showAllExploreDestinations = false;

  ScrollController get _safeExploreScrollController =>
      _exploreScrollController ??= ScrollController();

  GlobalKey get _safeWisataSectionKey => _wisataSectionKey ??= GlobalKey();

  void _scrollToWisataSection() {
    setState(() {
      _activeTabIndex = 0;
      _currentExploreRegion = 'ALL';
      _currentExploreType = 'ALL';
      _searchQuery = '';
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetCtx = _safeWisataSectionKey.currentContext;
      if (targetCtx != null) {
        Scrollable.ensureVisible(
          targetCtx,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        );
      } else if (_safeExploreScrollController.hasClients) {
        _safeExploreScrollController.animateTo(
          520,
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  List<SavedDestinationModel> get _heroLandmarks {
    if (_cachedHeroLandmarks != null) return _cachedHeroLandmarks!;
    const heroIds = [
      'gunung-padang',
      'lembah-harau',
      'jam-gadang-ngarai',
      'kawasan-mandeh',
      'istano-basa-pagaruyung',
    ];
    final picked = <SavedDestinationModel>[];
    for (final id in heroIds) {
      for (final item in kAllSumbarDestinations) {
        if (item.id == id) {
          picked.add(item);
          break;
        }
      }
    }
    _cachedHeroLandmarks =
        picked.isNotEmpty ? picked : kAllSumbarDestinations.take(5).toList();
    return _cachedHeroLandmarks!;
  }

  void _handleAuthSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_handleAuthSessionChanged);
    TripETicketStore.instance.removeListener(_handleNewETicket);
    _exploreScrollController?.dispose();
    _petaScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleNewETicket() {
    final ticket = TripETicketStore.instance.lastIssuedTicket;
    if (ticket == null || !mounted) return;
    final notifId = 'notif_eticket_${ticket.bookingCode}';
    final exists = _appNotifications.any((n) => n['id'] == notifId);
    if (exists) return;
    setState(() {
      _appNotifications.insert(0, {
        'id': notifId,
        'title': 'e-Tiket Trip Go Terbit: ${ticket.bookingCode}',
        'message':
            '${ticket.tripTitle} (${ticket.departureDate} • ${ticket.departureTime}) — Ketuk untuk melihat & unduh PDF.',
        'time': 'Baru saja',
        'isRead': false,
        'type': 'eticket',
        'ticketCode': ticket.bookingCode,
      });

      final reminderId = 'notif_readiness_${ticket.tripId}';
      final hasReminder = _appNotifications.any((n) => n['id'] == reminderId);
      if (!hasReminder) {
        _appNotifications.insert(0, {
          'id': reminderId,
          'title': 'Pengingat Wajib: Validasi Rencana & Persiapan',
          'message':
              'Jadwal ${ticket.tripTitle} (${ticket.departureDate} • ${ticket.departureTime}) sudah dekat, namun Rencana & Persiapan belum difinalisasi. Ketuk untuk melengkapi!',
          'time': 'Pengingat Jadwal',
          'isRead': false,
          'type': 'readiness_reminder',
          'tripId': ticket.tripId,
        });
      }
    });
  }

  void _syncReadinessReminderNotifications() {
    if (!mounted) return;
    setState(() {
      for (final trip in _activeOpenTrips) {
        if (trip.isCurrentUserJoined && trip.isReadinessFinalized) {
          final reminderId = 'notif_readiness_${trip.id}';
          for (final n in _appNotifications) {
            if (n['id'] == reminderId) {
              n['isRead'] = true;
              n['title'] = 'Validasi Rencana & Persiapan Selesai ✓';
              n['message'] =
                  '${trip.title} sudah terfinalisasi (Jadwal, Persiapan & Barang Bawaan siap).';
            }
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_handleAuthSessionChanged);
    TripETicketStore.instance.addListener(_handleNewETicket);
    _activeTabIndex = widget.initialTabIndex;
    _isOfflineMode = widget.initialOfflineMode;
    if (widget.isGuest) {
      AuthSession.instance.setGuestMode();
    }
    _savedIds = List<String>.from(kDefaultSavedIds);
    if (widget.initialLoading) {
      _savedViewState = 'shimmer';
    }
  }



  void _showAppToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cream,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'WISGO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.sage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_savedIds.contains(id)) {
        _savedIds.remove(id);
        if (_savedIds.isEmpty && _activeTabIndex == 1) {
          _savedViewState = 'empty';
        }
        _showAppToast('Dihapus dari daftar tersimpan');
      } else {
        _savedIds.add(id);
        if (_savedViewState == 'empty') {
          _savedViewState = 'loaded';
        }
        _showAppToast('Disimpan ke memori perangkat (Tersimpan)');
      }
    });
  }

  void _restoreDefaultBookmarks() {
    setState(() {
      _savedIds = List<String>.from(kDefaultSavedIds);
      _savedViewState = 'shimmer';
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _savedViewState = 'loaded');
      _showAppToast('4 destinasi unggulan Sumbar berhasil dimuat');
    });
  }

  void _openPlaceBarometer(int baroIndex) {
    setState(() {
      _activeTabIndex = 3; // Buka Peta Interaktif
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.notifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Global Static Offline Notification Banner (Item 6)
                if (_isOfflineMode)
                  OfflineBanner(
                    onRetry: () => setState(() => _isOfflineMode = false),
                  ),

                // Active Main View (5 Tabs: Beranda, Trip Go, Check-In, Peta, Profil)
                Expanded(
                  child: IndexedStack(
                    index: _activeTabIndex.clamp(0, _navItems.length - 1),
                    children: [
                      _buildExploreView(),
                      _buildOpenTripView(),
                      QrScannerSheet(
                        embedded: true,
                        onNavigateToProfile: () {
                          setState(() => _activeTabIndex = 4);
                        },
                      ),
                      _buildPetaView(),
                      _buildProfileView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildClean4ButtonBottomNavigationBar(),
        );
      },
    );
  }

  // ===========================================================================
  // VIEW 0: JELAJAH DAERAH & ALAM SUMATERA BARAT
  // ===========================================================================
  String get _activeSortLabel {
    switch (_sortMode) {
      case 'distance':
        return AppLocale.tr('Terdekat', 'Nearest');
      case 'rating':
        return 'Top ★';
      default:
        return AppLocale.tr('Urutkan', 'Sort');
    }
  }

  IconData _getCategoryChipIcon(String key) {
    switch (key) {
      case 'Alam & Geopark':
      case 'Gunung & Lembah':
        return Icons.terrain_rounded;
      case 'Budaya & Nagari':
        return Icons.account_balance_rounded;
      case 'Hidden Gem':
        return Icons.diamond_outlined;
      case 'Religi':
        return Icons.mosque_rounded;
      case 'Kuliner':
        return Icons.restaurant_rounded;
      case 'Air Terjun':
        return Icons.water_drop_rounded;
      case 'Pantai & Bahari':
        return Icons.waves_rounded;
      case 'Nagari & Hutan Terpencil':
        return Icons.forest_rounded;
      default:
        return Icons.explore_rounded;
    }
  }

  void _openSortBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocale.tr('Urutkan Destinasi', 'Sort Destinations'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildSortOptionTile(
                ctx: ctx,
                mode: 'default',
                icon: Icons.auto_awesome_rounded,
                title: AppLocale.tr('Rekomendasi Utama', 'Top Recommendations'),
                subtitle: AppLocale.tr(
                  'Urutan destinasi unggulan Sumatera Barat',
                  'Curated highlights of West Sumatra',
                ),
              ),
              const SizedBox(height: 8),
              _buildSortOptionTile(
                ctx: ctx,
                mode: 'distance',
                icon: Icons.near_me_rounded,
                title: AppLocale.tr('Jarak Terdekat (GPS)', 'Nearest Distance (GPS)'),
                subtitle: AppLocale.tr(
                  'Menampilkan lokasi paling dekat dari posisimu',
                  'Shows destinations closest to your location',
                ),
              ),
              const SizedBox(height: 8),
              _buildSortOptionTile(
                ctx: ctx,
                mode: 'rating',
                icon: Icons.star_rounded,
                title: AppLocale.tr('Rating Tertinggi', 'Highest Rated'),
                subtitle: AppLocale.tr(
                  'Berdasarkan ulasan wisatawan terverifikasi',
                  'Based on verified traveler reviews',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptionTile({
    required BuildContext ctx,
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _sortMode == mode;
    return Material(
      color: selected ? AppColors.sage : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          setState(() => _sortMode = mode);
          Navigator.pop(ctx);
          final scrollCtrl = _exploreScrollController;
          if (scrollCtrl != null && scrollCtrl.hasClients) {
            scrollCtrl.animateTo(
              0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.warmBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.forest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.forest,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLandmarkSlider() {
    return WisgoHeroSlider(
      slides: _heroLandmarks,
      isEnglish: AppLocale.isEn,
      onOpenDetail: _openDestinationDetailModal,
      onOpen360: _open360AndDenahModal,
    );
  }

  void _openKamusMinangScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioCultureScreen(
          embedded: false,
          remindedFestivalIds: _remindedFestivalIds,
          onToggleReminder: _toggleFestivalReminder,
          onNavigateToGps: _navigateToGpsLocation,
          festivals: _budayaFestivals,
        ),
      ),
    );
  }

  Future<void> _runWithAuthGuard({
    required String title,
    required String description,
    required VoidCallback onAllowed,
  }) async {
    if (!_isCurrentGuest) {
      onAllowed();
      return;
    }
    final wantsLogin = await AuthGuard.check(
      context: context,
      actionTitle: title,
      actionDescription: description,
      isAuthenticated: !_isCurrentGuest,
    );
    if (!mounted) return;
    if (wantsLogin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  List<Map<String, dynamic>> _allServiceCategoryItems() {
    return <Map<String, dynamic>>[
      {
        'label': AppLocale.tr('Wisata', 'Explore'),
        'fullTitle': AppLocale.tr('Wisata Sumatera Barat', 'West Sumatra Tours'),
        'subtitle': AppLocale.tr(
          'Jelajahi 10 destinasi alam & budaya pilihan Sumbar',
          'Explore 10 curated nature & cultural destinations',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.landscape_rounded,
        'iconAsset': 'assets/images/cat_wisata.png',
        'iconColor': AppColors.forest,
        'bgColor': AppColors.sage,
        'onTap': _scrollToWisataSection,
      },
      {
        'label': AppLocale.tr('Kamus', 'Dictionary'),
        'fullTitle': AppLocale.tr('Kamus & Audio Minang', 'Minang Dictionary'),
        'subtitle': AppLocale.tr(
          'Panduan ungkapan bahasa Minang lengkap dengan suara',
          'Local Minang phrases with authentic voice audio',
        ),
        'section': 'Budaya, Keamanan & Paspor',
        'icon': Icons.translate_rounded,
        'iconAsset': 'assets/images/cat_kamus.png',
        'iconColor': AppColors.warningDark,
        'bgColor': AppColors.warningBg,
        'onTap': _openKamusMinangScreen,
      },
      {
        'label': AppLocale.tr('Tur 360°', '360° Tour'),
        'fullTitle': AppLocale.tr('Tur Virtual 360°', '360° Virtual Tour'),
        'subtitle': AppLocale.tr(
          'Pratinjau panorama 360° destinasi sebelum berangkat',
          'Preview 360° panoramas before traveling',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.threesixty_rounded,
        'iconAsset': 'assets/images/cat_tur360.png',
        'iconColor': AppColors.terracotta,
        'bgColor': AppColors.coralTint,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VirtualTour360GalleryScreen(
                  destinations: kAllSumbarDestinations
                      .map((d) => d.toFe1Destination())
                      .toList(),
                ),
              ),
            ),
      },
      {
        'label': AppLocale.tr('Darurat', 'Emergency'),
        'fullTitle': AppLocale.tr('Darurat SOS & Info Bencana', 'Emergency & News'),
        'subtitle': AppLocale.tr(
          'Kontak darurat 115/112 & berita wisata bencana terkini',
          '115/112 emergency contacts & disaster travel news',
        ),
        'section': 'Budaya, Keamanan & Paspor',
        'icon': Icons.health_and_safety_rounded,
        'iconAsset': 'assets/images/cat_darurat.png',
        'iconColor': AppColors.danger,
        'bgColor': AppColors.dangerBg,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HazardSosScreen()),
            ),
      },
      {
        'label': AppLocale.tr('Simpan', 'Saved'),
        'fullTitle': AppLocale.tr('Destinasi Tersimpan', 'Saved Places'),
        'subtitle': AppLocale.tr(
          'Akses cepat daftar tempat wisata favorit Anda',
          'Quick access to your bookmarked destinations',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.bookmark_rounded,
        'iconAsset': 'assets/images/cat_simpan.png',
        'iconColor': AppColors.info,
        'bgColor': AppColors.infoBg,
        'onTap': _openSavedPlacesModal,
      },
      {
        'label': AppLocale.tr('Peta', 'Map'),
        'fullTitle': AppLocale.tr('Peta Interaktif Sumbar', 'Interactive Map'),
        'subtitle': AppLocale.tr(
          'Peta GPS asli, rute Shunlu & pantauan destinasi',
          'Real GPS map, Shunlu routes & nearby spots',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.map_rounded,
        'iconAsset': 'assets/images/cat_peta.png',
        'iconColor': AppColors.pinNavigasiBiru,
        'bgColor': AppColors.infoBg,
        'onTap': () => setState(() => _activeTabIndex = 3),
      },
      {
        'label': AppLocale.tr('Shunlu', 'Shunlu'),
        'fullTitle': AppLocale.tr('Jelajah Peta & Kompas Gunung', 'Shunlu & Compass'),
        'subtitle': AppLocale.tr(
          'Rute koridor wisata, peta mikro & kompas puncak Sumbar',
          'Corridor route finder, micro map & mountain compass',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.explore_rounded,
        'iconAsset': 'assets/images/cat_shunlu.png',
        'iconColor': AppColors.forest,
        'bgColor': AppColors.sage,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapExploreShunluScreen()),
            ),
      },
      {
        'label': AppLocale.tr('Offline', 'Offline'),
        'fullTitle': AppLocale.tr('Kantong Offline Zero-Signal', 'Offline Pocket'),
        'subtitle': AppLocale.tr(
          'Unduh peta & info darurat untuk area tanpa sinyal',
          'Download maps & emergency info for blank-spot areas',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.cloud_off_rounded,
        'iconAsset': 'assets/images/cat_offline.png',
        'iconColor': AppColors.muted,
        'bgColor': AppColors.creamSubtle,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfflinePocketScreen()),
            ),
      },
      {
        'label': AppLocale.tr('Event', 'Events'),
        'fullTitle': AppLocale.tr('Kalender Event & Budaya', 'Culture Calendar'),
        'subtitle': AppLocale.tr(
          'Jadwal festival nagari, tradisi & acara wisata Sumbar',
          'Local village festivals & cultural events',
        ),
        'section': 'Budaya, Keamanan & Paspor',
        'icon': Icons.calendar_month_rounded,
        'iconAsset': 'assets/images/cat_event.png',
        'iconColor': AppColors.terracotta,
        'bgColor': AppColors.coralTint,
        'onTap': _openKalenderBudayaModal,
      },
      {
        'label': AppLocale.tr('Paspor', 'Passport'),
        'fullTitle': AppLocale.tr('Paspor Digital Minang', 'Digital Passport'),
        'subtitle': AppLocale.tr(
          'Kumpulkan stempel kunjungan GPS & lencana penjelajah',
          'Collect GPS visit stamps & explorer badges',
        ),
        'section': 'Budaya, Keamanan & Paspor',
        'icon': Icons.badge_rounded,
        'iconAsset': 'assets/images/cat_paspor.png',
        'iconColor': AppColors.forest,
        'bgColor': AppColors.sage,
        'onTap': _openDigitalPassportModal,
      },
      {
        'label': AppLocale.tr('Check-In', 'Check-In'),
        'fullTitle': AppLocale.tr('Check-In GPS & Challenge', 'GPS Check-In'),
        'subtitle': AppLocale.tr(
          'Scan QR / lokasi wisata untuk kumpulkan XP & stempel',
          'Scan QR / destination GPS to earn XP & stamps',
        ),
        'section': 'Budaya, Keamanan & Paspor',
        'icon': Icons.qr_code_scanner_rounded,
        'iconAsset': 'assets/images/cat_checkin.png',
        'iconColor': AppColors.success,
        'bgColor': AppColors.successBg,
        'onTap': () => _runWithAuthGuard(
              title: 'Masuk untuk Check-In GPS',
              description:
                  'Simpan stempel kunjungan, XP petualang, dan progres Challenge 10 Destinasi ke akunmu.',
              onAllowed: _openQrScannerModal,
            ),
      },
      {
        'label': AppLocale.tr('Usul', 'Suggest'),
        'fullTitle': AppLocale.tr('Usul Destinasi Baru', 'Suggest Destination'),
        'subtitle': AppLocale.tr(
          'Laporkan hidden gem Sumatera Barat ke Dispar Sumbar',
          'Submit a hidden gem to West Sumatra Tourism Board',
        ),
        'section': 'Budaya, Keamanan & Paspor',
        'icon': Icons.add_location_alt_rounded,
        'iconAsset': 'assets/images/cat_usul.png',
        'iconColor': AppColors.warningDark,
        'bgColor': AppColors.warningBg,
        'onTap': () => _runWithAuthGuard(
              title: 'Masuk untuk Usul Wisata',
              description:
                  'Masuk dengan akun WISGO agar usulan hidden gem kamu dapat diverifikasi dan diberi poin XP.',
              onAllowed: _openUsulDestinasiModal,
            ),
      },
    ];
  }

  Widget _buildServiceCategoryIcon(
    Map<String, dynamic> item, {
    required double size,
  }) {
    final iconAsset = item['iconAsset'] as String?;
    final iconColor = (item['iconColor'] as Color?) ?? AppColors.forest;
    final bgColor = (item['bgColor'] as Color?) ?? AppColors.sage;

    Widget fallbackIcon() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            item['icon'] as IconData,
            size: size * 0.52,
            color: iconColor,
          ),
        );

    if (iconAsset == null || iconAsset.isEmpty) {
      return fallbackIcon();
    }

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        iconAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallbackIcon(),
      ),
    );
  }

  void _openAllCategoriesPage() {
    final allItems = _allServiceCategoryItems();
    final exploreItems = allItems
        .where((e) => e['section'] == 'Eksplorasi & Navigasi')
        .toList();
    final cultureItems = allItems
        .where((e) => e['section'] == 'Budaya, Keamanan & Paspor')
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageCtx) => Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.cream,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.ink,
              ),
              onPressed: () => Navigator.pop(pageCtx),
            ),
            title: Text(
              AppLocale.tr('Semua Kategori Layanan', 'All Service Categories'),
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.warmBorder.withValues(alpha: 0.7),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Pendar latar lembut agar efek kaca buram (frosted glass) terlihat hidup & hangat
              Positioned(
                top: -40,
                right: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.sage.withValues(alpha: 0.75),
                        AppColors.sage.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.goldSoft.withValues(alpha: 0.28),
                        AppColors.goldSoft.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _buildAllCategorySection(
                    pageCtx: pageCtx,
                    title: AppLocale.tr(
                      'Eksplorasi & Navigasi',
                      'Explore & Navigation',
                    ),
                    items: exploreItems,
                  ),
                  const SizedBox(height: 22),
                  _buildAllCategorySection(
                    pageCtx: pageCtx,
                    title: AppLocale.tr(
                      'Budaya, Keamanan & Paspor',
                      'Culture, Safety & Passport',
                    ),
                    items: cultureItems,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllCategorySection({
    required BuildContext pageCtx,
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} ${AppLocale.tr('Layanan', 'Services')}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 94,
          ),
          itemBuilder: (context, idx) {
            final item = items[idx];
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(pageCtx);
                      (item['onTap'] as VoidCallback)();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.56),
                            AppColors.creamSubtle.withValues(alpha: 0.34),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.74),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildServiceCategoryIcon(item, size: 40),
                          const SizedBox(height: 6),
                          Text(
                            item['label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCategoryGrid() {
    final allItems = _allServiceCategoryItems();
    // 4 layanan utama (termasuk Kamus Minang agar selalu menonjol) + Lainnya -> semua memakai custom 3D icon WISGO
    final primaryFour = [
      allItems[0], // Wisata
      allItems[1], // Kamus Minang
      allItems[2], // Tur 360°
      allItems[3], // Darurat
    ];
    final rowItems = <Map<String, dynamic>>[
      ...primaryFour,
      {
        'label': AppLocale.tr('Lainnya', 'More'),
        'icon': Icons.grid_view_rounded,
        'iconAsset': 'assets/images/cat_lainnya.png',
        'iconColor': AppColors.forest,
        'bgColor': AppColors.sage,
        'onTap': _openAllCategoriesPage,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocale.tr('Kategori Layanan', 'Quick Services'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${allItems.length} ${AppLocale.tr('Layanan', 'Services')}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(rowItems.length, (i) {
            final item = rowItems[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == rowItems.length - 1 ? 0 : 6),
                child: InkWell(
                  onTap: item['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.56),
                                    AppColors.creamSubtle.withValues(alpha: 0.38),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ink.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _buildServiceCategoryIcon(item, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNearestRecommendationPair() {
    final nearest = List<SavedDestinationModel>.from(kAllSumbarDestinations)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final topTwo = nearest.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppLocale.tr('Rekomendasi Terdekat', 'Nearby Picks'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocale.tr('GPS Aktif', 'GPS Active'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 5),
                const CircleAvatar(
                  radius: 3.5,
                  backgroundColor: AppColors.success,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(topTwo.length, (i) {
            final place = topTwo[i];
            final isBookmarked = _savedIds.contains(place.id);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 0 ? 10 : 0),
                child: Material(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openDestinationDetailModal(place),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.warmBorder.withValues(alpha: 0.9),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 118,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(color: AppColors.forest),
                                WisgoDestinationImage(
                                  source: place.imageUrl,
                                  destinationId: place.id,
                                  destinationTitle: place.title,
                                  fit: BoxFit.cover,
                                  cacheWidth: 480,
                                  fallback: Image.asset(
                                    'assets/images/splash_bg_1.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Gradasi bawah halus untuk keterbacaan kategori tanpa stiker blok mencolok
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.transparent,
                                          AppColors.ink.withValues(alpha: 0.58),
                                        ],
                                        stops: const [0.0, 0.52, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Pill rating minimalis kiri atas
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.ink.withValues(alpha: 0.54),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: Color(0xFFF3C669),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${place.rating}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Tombol bookmark bundar bersih kanan atas
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () => _toggleBookmark(place.id),
                                      customBorder: const CircleBorder(),
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Icon(
                                          isBookmarked
                                              ? Icons.bookmark_rounded
                                              : Icons.bookmark_border_rounded,
                                          size: 15,
                                          color: isBookmarked
                                              ? AppColors.terracotta
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Label kategori minimalis di tepi bawah foto
                                Positioned(
                                  bottom: 8,
                                  left: 10,
                                  right: 10,
                                  child: Text(
                                    place.natureType,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                    height: 1.25,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${place.distanceKm.toStringAsFixed(place.distanceKm.truncateToDouble() == place.distanceKm ? 0 : 1)} km • ${place.region}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.muted,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: AppColors.sage,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 13,
                                        color: AppColors.forest,
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
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWeatherConditionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF173B30),
              Color(0xFF1E4C3E),
              Color(0xFF132D22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // 1. Latar Atmosfer Cuaca Terkini (Cahaya Matahari Hangat + Awan Halus seperti Widget Cuaca HP)
            Positioned(
              top: -28,
              right: -18,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFDE68A).withValues(alpha: 0.42),
                      const Color(0xFFF59E0B).withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 22,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFDE68A).withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Siluet Awan Lembut Berlapis di Belakang
            Positioned(
              top: 16,
              right: -8,
              child: Icon(
                Icons.cloud_rounded,
                size: 74,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              top: 30,
              right: 46,
              child: Icon(
                Icons.cloud_rounded,
                size: 52,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -14,
              left: -10,
              child: Icon(
                Icons.cloud_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),

            // 2. Konten Utama Widget Cuaca
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF86EFAC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    AppLocale.tr(
                                      'CUACA TERKINI',
                                      'LIVE WEATHER',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: AppColors.cream.withValues(alpha: 0.80),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              AppLocale.tr(
                                'Kota Padang, Sumbar',
                                'Padang City, West Sumatra',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppLocale.tr(
                                'Cerah Berawan • Nyaman untuk wisata',
                                'Partly Cloudy • Great for travel',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          '28°C',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -0.8,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Strip Metrik Transparan ala Widget Cuaca HP
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildWeatherMiniStat(
                            icon: Icons.water_drop_outlined,
                            label: AppLocale.tr('Kelembaban', 'Humidity'),
                            value: '82%',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        Expanded(
                          child: _buildWeatherMiniStat(
                            icon: Icons.air_rounded,
                            label: AppLocale.tr('Angin', 'Wind'),
                            value: AppLocale.tr('11 km/j', '11 km/h'),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        Expanded(
                          child: _buildWeatherMiniStat(
                            icon: Icons.visibility_outlined,
                            label: AppLocale.tr('Pandangan', 'Visibility'),
                            value: '10 km',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFFFDE68A)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }

  Widget _buildTahukahKamuCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2EB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC85B2D).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFC85B2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.tr('Tahukah Kamu?', 'Did You Know?'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocale.tr(
                    'Atap melengkung runcing Rumah Gadang melambangkan tanduk kerbau (Gonjong) serta filosofi Adat Basandi Syarak, Syarak Basandi Kitabullah.',
                    'The curved horn-shaped roof (Gonjong) of Rumah Gadang symbolizes buffalo horns and the Minangkabau philosophy of Adat Basandi Syarak, Syarak Basandi Kitabullah.',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreView() {
    var filtered = kAllSumbarDestinations.where((item) {
      final regMatch = _currentExploreRegion == 'ALL' ||
          item.region == _currentExploreRegion;
      final typeMatch = _currentExploreType == 'ALL' ||
          item.natureType.toLowerCase().contains(_currentExploreType.toLowerCase()) ||
          item.categoryTag.toLowerCase().contains(_currentExploreType.toLowerCase()) ||
          (_currentExploreType == 'Alam & Geopark' &&
              (item.natureType == 'Air Terjun' ||
                  item.natureType == 'Gunung & Lembah' ||
                  item.natureType == 'Pantai & Bahari' ||
                  item.natureType.contains('Alam'))) ||
          (_currentExploreType == 'Budaya & Nagari' &&
              (item.natureType == 'Nagari & Hutan Terpencil' ||
                  item.categoryTag.toLowerCase().contains('nagari') ||
                  item.categoryTag.toLowerCase().contains('budaya'))) ||
          (_currentExploreType == 'Hidden Gem' &&
              (item.natureType == 'Air Terjun' ||
                  item.title.toLowerCase().contains('tersembunyi') ||
                  item.title.toLowerCase().contains('cindakir') ||
                  item.title.toLowerCase().contains('taram'))) ||
          (_currentExploreType == 'Religi' &&
              (item.facilities.any((f) => f.toLowerCase().contains('musholla') || f.toLowerCase().contains('masjid')))) ||
          (_currentExploreType == 'Kuliner' &&
              (item.facilities.any((f) => f.toLowerCase().contains('makanan') || f.toLowerCase().contains('kuliner'))));
      var searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final facs = item.facilities.join(' ').toLowerCase();
        final target =
            '${item.title} ${item.subRegion} ${item.region} ${item.categoryTag} ${item.natureType} $facs'
                .toLowerCase();
        searchMatch = target.contains(query);
      }
      return regMatch && typeMatch && searchMatch;
    }).toList();

    if (_sortMode == 'distance') {
      filtered.sort((a, b) {
        final cmp = a.distanceKm.compareTo(b.distanceKm);
        return cmp != 0 ? cmp : b.rating.compareTo(a.rating);
      });
    } else if (_sortMode == 'rating') {
      filtered.sort((a, b) {
        final cmp = b.rating.compareTo(a.rating);
        return cmp != 0 ? cmp : a.distanceKm.compareTo(b.distanceKm);
      });
    }

    final isExploreFiltering = _searchQuery.isNotEmpty ||
        _sortMode != 'default' ||
        _currentExploreRegion != 'ALL' ||
        _currentExploreType != 'ALL';

    String exploreListHeading =
        AppLocale.tr('Destinasi Wisata Pilihan', 'Featured Destinations');
    if (_searchQuery.isNotEmpty) {
      exploreListHeading = AppLocale.tr('Hasil Pencarian', 'Search Results');
    } else if (_sortMode == 'rating') {
      exploreListHeading =
          AppLocale.tr('Urutan Rating Tertinggi', 'Top Rated Destinations');
    } else if (_sortMode == 'distance') {
      exploreListHeading =
          AppLocale.tr('Urutan Jarak Terdekat', 'Nearest Destinations');
    }

    return Stack(
      children: [
        CustomScrollView(
          controller: _safeExploreScrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Pinned Frosted Glass App Bar Header
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              titleSpacing: 16,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.82),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.warmBorder.withValues(alpha: 0.70),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  // Logo Resmi WISGO (Transparan langsung menyatu di header)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      'assets/images/logo_primary.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.explore_rounded,
                        size: 22,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocale.tr('Jelajah Sumbar', 'Explore Sumbar'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 1),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isOfflineMode = !_isOfflineMode),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isOfflineMode
                                      ? AppColors.terracotta
                                      : AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _isOfflineMode
                                      ? AppLocale.tr(
                                          'Luring • 10 Destinasi',
                                          'Offline • 10 Destinations',
                                        )
                                      : AppLocale.tr(
                                          'Online • 10 Destinasi',
                                          'Online • 10 Destinations',
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isOfflineMode
                                        ? AppColors.terracotta
                                        : AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. Siaga SOS (Check-In kini berada di Tab Bar bawah agar header lebih lega)
                  Tooltip(
                    message: 'Darurat SOS & Berita Bencana',
                    child: Material(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HazardSosScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6.5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.danger
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.sos_rounded,
                            size: 15,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 3. Lonceng Pusat Notifikasi & Pengingat WISGO
                  Tooltip(
                    message: 'Pusat Notifikasi & Pengingat WISGO',
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _openNotificationCenterModal,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                size: 19,
                                color: AppColors.ink,
                              ),
                              if (_unreadNotificationCount > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.3,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 15,
                                      minHeight: 15,
                                    ),
                                    child: Text(
                                      '$_unreadNotificationCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Header Content (User-Friendly, Clean & Uncluttered)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Bar + Tombol Urutkan (1 Baris Rapi)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.warmBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val.trim()),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: AppLocale.tr(
                                  'Cari destinasi, daerah, fasilitas...',
                                  'Search destinations, regions, facilities...',
                                ),
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted.withValues(alpha: 0.7),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 19,
                                  color: AppColors.muted,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 17,
                                          color: AppColors.muted,
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tombol Urutkan (Buka Sheet Urutkan yang Ramah Pengguna)
                        Material(
                          color: _sortMode == 'default'
                              ? Colors.white
                              : AppColors.forest,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: _openSortBottomSheet,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 43,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _sortMode == 'default'
                                      ? AppColors.warmBorder
                                      : AppColors.forest,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ink.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 16,
                                    color: _sortMode == 'default'
                                        ? AppColors.forest
                                        : AppColors.cream,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _activeSortLabel,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: _sortMode == 'default'
                                          ? AppColors.ink
                                          : AppColors.cream,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bagian Showcase Beranda (otomatis beralih ke mode hasil cari/urut saat user memilih Urutkan, Cari, atau Filter)
                    if (!isExploreFiltering) ...[
                      // 2. Hero Landmark Utama (Multi-Slide Interactive Slider)
                      _buildHeroLandmarkSlider(),
                      const SizedBox(height: 18),

                      // 3. Kategori Layanan (5 item rata penuh + Lainnya)
                      _buildServiceCategoryGrid(),
                      const SizedBox(height: 18),

                      // 4. Rekomendasi Terdekat (2 Kartu Sejajar)
                      _buildNearestRecommendationPair(),
                      const SizedBox(height: 18),

                      // 5. Kartu Cuaca & Kondisi Udara Gelap
                      _buildWeatherConditionCard(),
                      const SizedBox(height: 20),
                    ],

                    // 6. Header Seksi Destinasi Wisata Pilihan / Hasil Urutan + Filter Wilayah & Kategori
                    Row(
                      key: _safeWisataSectionKey,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  exploreListHeading,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              if (isExploreFiltering) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(${filtered.length})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isExploreFiltering)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _sortMode = 'default';
                                _searchQuery = '';
                                _searchController.clear();
                                _currentExploreRegion = 'ALL';
                                _currentExploreType = 'ALL';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 13,
                                    color: AppColors.forest,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            '${filtered.length} ${AppLocale.tr('Lokasi', 'Places')}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 7. Bar Filter Ringkas (Menggantikan 2 Slider Daerah & Kategori Bertumpuk)
                    _buildExploreFilterBar(),
                  ],
                ),
              ),
            ),

            // Scrollable Destination Feed
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Belum ada kategori "$_currentExploreType" di wilayah $_currentExploreRegion',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Silakan pilih "Semua Kategori" atau pindah ke daerah lain.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => _currentExploreType = 'ALL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            foregroundColor: AppColors.cream,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Tampilkan Semua Kategori di $_currentExploreRegion',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 254,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDestinationGridCard(
                      filtered[index],
                    ),
                    childCount:
                        (!isExploreFiltering &&
                            !_showAllExploreDestinations &&
                            filtered.length > 6)
                        ? 6
                        : filtered.length,
                  ),
                ),
              ),
              if (!isExploreFiltering && filtered.length > 6)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _showAllExploreDestinations =
                              !_showAllExploreDestinations,
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFCF7),
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.sageBorder),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: Icon(
                          _showAllExploreDestinations
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.forest,
                        ),
                        label: Text(
                          _showAllExploreDestinations
                              ? AppLocale.tr(
                                  'Tampilkan Lebih Ringkas (6)',
                                  'Show Less (6)',
                                )
                              : AppLocale.tr(
                                  'Lihat Semua Destinasi (${filtered.length})',
                                  'View All Destinations (${filtered.length})',
                                ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // 9. Kartu Budaya "Tahukah Kamu?" + Ruang Scroll Aman di atas FAB & Tab Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 168),
                child: _buildTahukahKamuCard(),
              ),
            ),
          ],
        ),

        // Floating Action Button Usul Wisata (Glassmorphic Hijau Tembus Pandang seperti sebelumnya)
        Positioned(
          bottom: MediaQuery.paddingOf(context).bottom + 78,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Material(
                  color: AppColors.forest.withValues(alpha: 0.78),
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: _openUsulDestinasiModal,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppColors.cream,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocale.tr('Usul Wisata', 'Suggest Spot'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // NAVIGASI FITUR PINTAR INTEGRASI FE-1 & DETAIL MEDAN (LAYAR 01, 02, 03, 07)
  // ===========================================================================
  // ===========================================================================
  // VIEW 1: TAB PETA RUTE (NAVIGASI, RENCANA TRIP & PANTAU ROMBONGAN)
  // ===========================================================================
  /// Cocokkan nama destinasi Trip Go ke katalog destinasi sistem (untuk 360° & Ulasan terhubung)
  SavedDestinationModel _findDestinationForTrip(String destName) {
    final lower = destName.toLowerCase();
    for (final d in kAllSumbarDestinations) {
      final dLower = d.title.toLowerCase();
      if (dLower.contains(lower) || lower.contains(dLower)) {
        return d;
      }
      final keywords = lower.split(RegExp(r'[\s&,()]+')).where((w) => w.length >= 4);
      for (final kw in keywords) {
        if (dLower.contains(kw)) return d;
      }
    }
    return kAllSumbarDestinations.first;
  }

  /// Modal Panduan Trip Go Lengkap (1-8 Terpadu)
  void _openTripGoGuideModal() {
    showTripGoGuideSheet(context);
  }

  void _openOrganizerHubModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OpenTripOrganizerHubSheet(
        allTrips: _activeOpenTrips,
        onTripCreated: (newTrip) {
          setState(() {
            _customOpenTrips ??= List<OpenTripItem>.from(kMockOpenTrips);
            _customOpenTrips!.insert(0, newTrip);
          });
        },
        onTripsChanged: () => setState(() {}),
      ),
    );
  }

  Widget _buildOpenTripView() {
    final myOrganizerTrips =
        _activeOpenTrips.where((t) => t.isCreatedByCurrentUser).toList();
    final hasApprovedOrganizerTrip = myOrganizerTrips
        .any((t) => t.verificationStatus == TripVerificationStatus.approved);
    final hasPendingOrganizerTrip = myOrganizerTrips
        .any((t) => t.verificationStatus == TripVerificationStatus.pendingAdmin);

    final publicApprovedTrips = _activeOpenTrips
        .where((t) => t.verificationStatus == TripVerificationStatus.approved)
        .toList();

    final q = _tripGoSearchQuery.trim().toLowerCase();
    final filteredTrips = publicApprovedTrips.where((t) {
      final catMatch = _openTripFilterCategory == 'Semua' ||
          t.category == _openTripFilterCategory;
      if (!catMatch) return false;
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.singleDestination.toLowerCase().contains(q) ||
          t.organizer.name.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Top Sticky Header: Bersih, Judul "Trip Go" + Tagline + Panduan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            border: Border(
              bottom: BorderSide(color: AppColors.warmBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Trip Go',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Baca Panduan Trip Go (1–8)',
                        child: InkWell(
                          mouseCursor: SystemMouseCursors.click,
                          onTap: _openTripGoGuideModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.sageBorder),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 14,
                                  color: AppColors.forest,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Panduan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.groups_rounded, size: 14, color: AppColors.forest),
                            const SizedBox(width: 4),
                            Text(
                              '${publicApprovedTrips.length} Aktif',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Jelajahi destinasi impian bareng teman baru & pemandu lokal berlisensi — aman, terarah, dan seru!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        // Scrollable Body: Langsung Jadwal Trip Go Terbuka + Tombol Open Trip di bawah (seperti Usul Wisata di Beranda)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
            children: [
              // Pencarian Trip Go
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _tripGoSearchQuery = val),
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Cari Trip Go, destinasi, atau pemandu...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.forest),
                    suffixIcon: _tripGoSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                            onPressed: () => setState(() => _tripGoSearchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),

              // Filter Kategori Perjalanan Terstruktur (5 Kluster Utama)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    'Semua',
                    'Alam & Geopark',
                    'Budaya & Nagari',
                    'Hidden Gem',
                    'Religi',
                    'Kuliner',
                  ].map((category) {
                    final isSelected = _openTripFilterCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.forest,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.forest,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? AppColors.forest : AppColors.sageBorder,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        onSelected: (val) {
                          setState(() {
                            _openTripFilterCategory = category;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Daftar Kartu Open Trip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Jadwal Trip Go Terbuka (${filteredTrips.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '1 Destinasi Tunggal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (filteredTrips.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada Trip Go untuk pencarian atau kategori ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                    ),
                  ),
                )
              else
                ...filteredTrips.map((trip) {
                  return OpenTripCard(
                    trip: trip,
                    isOrganizerView: false,
                    onTripUpdated: _syncReadinessReminderNotifications,
                    onTripDeleted: (deletedId) {
                      setState(() {
                        _activeOpenTrips.removeWhere((t) => t.id == deletedId);
                      });
                    },
                    onOpenDestination360: () {
                      final matched = _findDestinationForTrip(trip.singleDestination);
                      _open360AndDenahModal(matched);
                    },
                    onOpenDestinationReviews: () {
                      final matched = _findDestinationForTrip(trip.singleDestination);
                      _openDestinationDetailModal(matched);
                    },
                  );
                }),

              const SizedBox(height: 10),

              // Tombol Bawah "Open Trip" (Penyelenggara) — seragam dengan Usul Wisata di Beranda
              InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: _openOrganizerHubModal,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.sageBorder, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.cream,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Open Trip (Penyelenggara)',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (hasApprovedOrganizerTrip || hasPendingOrganizerTrip) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasApprovedOrganizerTrip
                                          ? AppColors.successBg
                                          : AppColors.warningBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      hasApprovedOrganizerTrip
                                          ? 'Aktif (${myOrganizerTrips.length})'
                                          : 'Menunggu Admin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: hasApprovedOrganizerTrip
                                            ? AppColors.success
                                            : AppColors.warningDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Ajukan trip baru, cek verifikasi admin & kelola data peserta',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.forest,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Modal: Destinasi Tersimpan (Dibuka lewat icon simpan di header Beranda)
  void _openSavedPlacesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final savedPlaces = kAllSumbarDestinations
                .where((d) => _savedIds.contains(d.id))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MEMORI PERANGKAT (LURING)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: AppColors.brush,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Destinasi Tersimpan (${savedPlaces.length})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded, size: 22, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.warmBorder),
                  Expanded(
                    child: savedPlaces.isEmpty
                        ? SavedEmptyState(
                            onRestoreDefaultPressed: () {
                              _restoreDefaultBookmarks();
                              setModalState(() {});
                            },
                            onOpenExplorePressed: () => Navigator.pop(ctx),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: savedPlaces.length,
                            itemBuilder: (context, idx) {
                              final place = savedPlaces[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildDestinationCard(place, isSavedContext: true),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Data Master: Kalender Acara & Festival Budaya Minang
  static final List<Map<String, dynamic>> budayaFestivals = [
    {
      'id': 'ev_harau',
      'title': 'Festival Pasa Harau 2026',
      'date': '18 – 20 Desember 2026',
      'time': '08:00 – 22:00 WIB',
      'location': 'Lembah Harau, Kab. Lima Puluh Kota',
      'venue': 'Area Terbuka Tebing Granit Lembah Harau',
      'desc': 'Pagelaran akbar seni adat, randai tradisional, musik saluang, & kuliner nagari di bawah tebing granit.',
      'badge': 'Festival Adat Resmi',
      'badgeColor': 0xFF5A3E85,
      'badgeBg': 0xFFF3EDFA,
      'lat': -0.1008,
      'lng': 100.6728,
      'gpsCoordinate': '-0.1008, 100.6728',
      'imageUrl': 'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?w=800',
      'longDesc': 'Festival Pasa Harau adalah perayaan kebudayaan tahunan Minangkabau terbesar di Lembah Harau. Diapit tebing granit raksasa setinggi 100-300 meter, festival ini menampilkan teater tradisional Randai, pertunjukan musik Saluang & Gandang Tambua, pameran kuliner legendaris 50 Kota, serta pergelaran busana tenun songket khas Luak Limopuluah.',
      'rundown': [
        'Hari 1: Pawai Budaya Adat 100 Gandang & Pembukaan Resmi Nagari',
        'Hari 2: Randai Semalam Suntuk, Pasar Kuliner Tradisional, & Lomba Pacu Terbang Itik',
        'Hari 3: Pentas Musik Etnik Kontemporer & Ritual Syukur Nagari Harau',
      ],
      'tips': 'Gunakan pakaian sopan, kenakan alas kaki nyaman untuk area berumput, dan siapkan kantong sampah pribadi demi menjaga keasrian lembah.',
    },
    {
      'id': 'ev_pacu_jawi',
      'title': 'Pacu Jawi Tradisional Luhak Nan Tuo',
      'date': 'Setiap Sabtu (Pukul 09:00 WIB)',
      'time': '09:00 – 16:30 WIB',
      'location': 'Kec. Pariangan, Kab. Tanah Datar',
      'venue': 'Sawah Basah Nagari Pariangan (Desa Terindah)',
      'desc': 'Balapan sepasang sapi di sawah basah berlumpur khas Minangkabau sebagai perayaan syukur panen padi nagari.',
      'badge': 'Warisan Budaya',
      'badgeColor': 0xFF1E5B82,
      'badgeBg': 0xFFE8F1F8,
      'lat': -0.4469,
      'lng': 100.4939,
      'gpsCoordinate': '-0.4469, 100.4939',
      'imageUrl': 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800',
      'longDesc': 'Pacu Jawi adalah tradisi permainan anak nagari turun-temurun di Tanah Datar yang digelar seusai panen padi. Seorang joki berdiri di atas bajak bambu dan memegang ekor sepasang sapi sambil meluncur kencang di hamparan sawah basah berlumpur. Tradisi ini menilai ketangkasan, kekompakan lari sapi lurus, dan nilai jual sapi bibit unggul.',
      'rundown': [
        '09:00 - 10:00: Pawai Sapi Hias Khas Luhak Nan Tuo',
        '10:30 - 12:30: Babak Pertama Pacu Jawi Sawah Berlumpur',
        '12:30 - 13:30: Makan Bajamba di Dangau Sawah Bersama Warga',
        '13:30 - 16:30: Babak Utama & Penilaian Ketangkasan Joki',
      ],
      'tips': 'Bawa baju ganti dan pelindung kamera dari cipratan lumpur basah. Jangan berdiri terlalu dekat dengan jalur lintasan sapi demi keselamatan.',
    },
    {
      'id': 'ev_maninjau',
      'title': 'Festival Pesona Danau Maninjau',
      'date': '24 – 26 Desember 2026',
      'time': '08:30 – 18:00 WIB',
      'location': 'Kelok 44 & Tepian Danau, Agam',
      'venue': 'Puncak Lawang (Take-off) & Muko-Muko Maninjau',
      'desc': 'Kejuaraan paralayang internasional dari puncak Lawang, pameran kriya perak, & santap rinuak segar.',
      'badge': 'Agenda Tahunan',
      'badgeColor': 0xFF15803D,
      'badgeBg': 0xFFDCFCE7,
      'lat': -0.2933,
      'lng': 100.1989,
      'gpsCoordinate': '-0.2933, 100.1989',
      'imageUrl': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      'longDesc': 'Festival tahunan kebanggaan Ranah Agam yang memadukan keindahan lanskap kaldera purba Danau Maninjau dengan atraksi kedirgantaraan dunia. Puluhan atlet paralayang terbang dari tebing Puncak Lawang menyuguhkan pemandangan spektakuler di atas Kelok 44, berpadu dengan kuliner khas ikan rinuak dan pameran kerajinan perak Koto Gadang.',
      'rundown': [
        'Hari 1: Kejuaraan Internasional Paralayang Puncak Lawang - Danau Maninjau',
        'Hari 2: Lomba Dayung Sampan Tradisional & Pesta Kuliner Olahan Rinuak',
        'Hari 3: Parade Musik Akustik Danau & Pagelaran Seni Tari Piring',
      ],
      'tips': 'Udara di Puncak Lawang berkabut dan sejuk, kenakan jaket hangat. Patuhi rambu jalan menurun saat melewati Kelok 44.',
    },
    {
      'id': 'ev_tabuik',
      'title': 'Pesta Budaya Tabuik Pariaman',
      'date': '10 Muharram (Puncak Hoyak Tabuik)',
      'time': '06:00 – 18:30 WIB',
      'location': 'Pantai Gandoriah, Kota Pariaman',
      'venue': 'Lapangan Merdeka & Pesisir Pantai Gandoriah',
      'desc': 'Prosesi kultural pengusungan Tabuik raksasa nan megah hingga pembuangan ke laut diiringi tambua tasa membahana.',
      'badge': 'Karnaval Akbar',
      'badgeColor': 0xFFC2410C,
      'badgeBg': 0xFFFFEDD5,
      'lat': -0.6272,
      'lng': 100.1192,
      'gpsCoordinate': '-0.6272, 100.1192',
      'imageUrl': 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800',
      'longDesc': 'Pesta Budaya Tabuik adalah tradisi kolosal spektakuler masyarakat pesisir Pariaman. Dua menara Tabuik (Tabuik Pasa & Tabuik Subarang) setinggi 12 meter berornamen burung Buraq diarak ribuan warga diiringi dentuman ratusan Gandang Tambua Tasa, diakhiri ritual Hoyak Tabuik menuju laut lepas saat matahari terbenam.',
      'rundown': [
        '06:00 - 09:00: Ritual Maarak Jari-jari & Saroban',
        '10:00 - 14:00: Tabuik Naiak Pangkek di Lapangan Merdeka',
        '14:30 - 17:30: Hoyak Tabuik kolosal menuju pesisir Pantai Gandoriah',
        '18:00 - 18:30: Prosesi pelarungan Tabuik ke Samudera Hindia diiringi doa bersama',
      ],
      'tips': 'Suasana sangat padat dan meriah; simpan barang berharga di tas dada, gunakan topi dan tabir surya di area pantai.',
    },
    {
      'id': 'ev_batagak',
      'title': 'Batagak Panghulu & Alek Nagari',
      'date': 'Jadwal Adat Nagari',
      'time': '09:00 – 17:00 WIB',
      'location': 'Balai Adat Koto Gadang',
      'venue': 'Medan Nan Bapaneh & Rumah Gadang Suku',
      'desc': 'Upacara sakral pengangkatan Datuak Datuak pemangku adat suku Minangkabau dengan jamuan bajamba adat.',
      'badge': 'Hukum Adat',
      'badgeColor': 0xFF4338CA,
      'badgeBg': 0xFFEEF2FF,
      'lat': -0.3201,
      'lng': 100.3546,
      'gpsCoordinate': '-0.3201, 100.3546',
      'imageUrl': 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800',
      'longDesc': 'Batagak Panghulu adalah musyawarah dan prosesi sakral penobatan gelar kepemimpinan adat (Datuak) bagi pewaris suku menurut garis keturunan matrilineal. Acara ini diiringi pidato adat Pasambahan penuh pepatah petitih tingkat tinggi, penyembelihan kerbau, dan tradisi Makan Bajamba bersama ribuan anak nagari.',
      'rundown': [
        '09:00 - 11:00: Sidang Kerapatan Adat Nagari (KAN) & Pidato Pasambahan',
        '11:00 - 12:30: Pemasangan Saluak & Keris Pusaka Pemangku Adat',
        '12:30 - 14:30: Makan Bajamba Adat di Rumah Gadang',
        '14:30 - 17:00: Arak-arakan Penghulu Keliling Nagari Koto Gadang',
      ],
      'tips': 'Wajib mengenakan pakaian sopan dan tertutup. Hormati prosesi sakral dan ikuti arahan tetua adat saat jamuan berlangsung.',
    },
  ];

  static List<Map<String, dynamic>> get _budayaFestivals => budayaFestivals;

  void _toggleFestivalReminder(Map<String, dynamic> ev) {
    setState(() {
      final id = ev['id'] as String;
      if (_remindedFestivalIds.contains(id)) {
        _remindedFestivalIds.remove(id);
      } else {
        _remindedFestivalIds.add(id);
        _appNotifications.insert(0, {
          'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
          'title': 'Pengingat Aktif: ${ev['title']}',
          'message': 'Jadwal acara ${ev['date']} di ${ev['location']} telah dipasang. Ketuk untuk panduan rute GPS.',
          'time': 'Baru saja',
          'isRead': false,
          'type': 'festival',
          'eventId': ev['id'],
        });
      }
    });
    final isReminded = _remindedFestivalIds.contains(ev['id']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isReminded
              ? 'Pengingat aktif! Notifikasi pengingat untuk ${ev['title']} telah dijadwalkan.'
              : 'Pengingat untuk ${ev['title']} telah dinonaktifkan.',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        backgroundColor: isReminded ? AppColors.forest : AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Modal: Kalender Acara & Festival Budaya Minang (Dibuka lewat icon kalender di header Beranda)
  void _openKalenderBudayaModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WARISAN & PERAYAAN NAGARI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Color(0xFF5A3E85),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kalender Acara Budaya Minang',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded, size: 22, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.warmBorder),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _budayaFestivals.length,
                      itemBuilder: (context, idx) {
                        final ev = _budayaFestivals[idx];
                        final isReminded = _remindedFestivalIds.contains(ev['id']);
                        final badgeColor = Color(ev['badgeColor'] as int? ?? 0xFF5A3E85);
                        final badgeBg = Color(ev['badgeBg'] as int? ?? 0xFFF3EDFA);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isReminded ? AppColors.forest.withValues(alpha: 0.6) : AppColors.sageBorder,
                              width: isReminded ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                _openFestivalDetailModal(ev);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ev['badge'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (isReminded) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                margin: const EdgeInsets.only(right: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.successBorder,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.notifications_active_rounded, size: 10, color: AppColors.success),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Pengingat Aktif',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppColors.success,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.muted),
                                            const SizedBox(width: 4),
                                            Text(
                                              ev['date'] as String,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.forest,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ev['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 13, color: AppColors.brush),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            ev['location'] as String,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ev['desc'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.creamSubtle,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.warmBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.near_me_rounded, size: 12, color: AppColors.forest),
                                          const SizedBox(width: 5),
                                          Text(
                                            'GPS: ${ev['gpsCoordinate']}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.forest,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Text(
                                            'Lihat Detail & Rute',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.ink),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modal: Detail Festival Budaya (Deskripsi lengkap, navigasi GPS, dan toggle pengingat)
  void _openFestivalDetailModal(Map<String, dynamic> ev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDetailState) {
            final isReminded = _remindedFestivalIds.contains(ev['id']);
            final badgeColor = Color(ev['badgeColor'] as int? ?? 0xFF5A3E85);
            final badgeBg = Color(ev['badgeBg'] as int? ?? 0xFFF3EDFA);
            final rundown = ev['rundown'] as List<String>? ?? [];

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  // Modal Top Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ev['badge'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Detail Acara Budaya',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded, size: 22, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.warmBorder),

                  // Scrollable Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      children: [
                        // Judul Festival
                        Text(
                          ev['title'] as String,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Jadwal & Waktu Info Chips
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.creamSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.warmBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 13, color: AppColors.forest),
                                  const SizedBox(width: 5),
                                  Text(
                                    ev['date'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.creamSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.warmBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.muted),
                                  const SizedBox(width: 5),
                                  Text(
                                    ev['time'] as String? ?? '08:00 WIB',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // KARTU LOKASI & GPS INTERAKTIF
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBF8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.forest.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.forest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ev['location'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          ev['venue'] as String? ?? 'Sumatera Barat',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.sageBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.my_location_rounded, size: 13, color: AppColors.forest),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Titik GPS: ${ev['gpsCoordinate']}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          color: AppColors.forest,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Tombol Langsung Arahkan ke GPS
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _navigateToGpsLocation(ev);
                                  },
                                  icon: const Icon(Icons.near_me_rounded, size: 16),
                                  label: const Text(
                                    'Arahkan ke Lokasi GPS',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.forest,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // DESKRIPSI KEBUDAYAAN
                        const Text(
                          'Tentang Acara & Nilai Budaya',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ev['longDesc'] as String? ?? ev['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SUSUNAN ACARA / AGENDA
                        if (rundown.isNotEmpty) ...[
                          const Text(
                            'Rangkaian Acara Utama',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...rundown.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(top: 6, right: 8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.brush,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 14),
                        ],

                        // PANDUAN & TATA KRAMA NAGARI
                        if (ev['tips'] != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tata Krama & Tips Kunjungan Nagari',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.warningDark,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        ev['tips'] as String,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.warningDark,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // TOMBOL PENGINGAT / NOTIFIKASI ACARA
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.creamSubtle,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isReminded ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                    size: 18,
                                    color: isReminded ? AppColors.success : AppColors.ink,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isReminded ? 'Pengingat Festival Aktif' : 'Pasang Pengingat Acara',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: isReminded ? AppColors.success : AppColors.ink,
                                          ),
                                        ),
                                        Text(
                                          isReminded
                                              ? 'Anda akan menerima notifikasi otomatis di hari acara.'
                                              : 'Dapatkan pemberitahuan otomatis saat mendekati jadwal festival.',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _toggleFestivalReminder(ev);
                                    setDetailState(() {});
                                  },
                                  icon: Icon(
                                    isReminded ? Icons.check_circle_rounded : Icons.add_alert_rounded,
                                    size: 16,
                                    color: isReminded ? AppColors.success : AppColors.forest,
                                  ),
                                  label: Text(
                                    isReminded ? 'Pengingat Aktif (Ketuk untuk Batalkan)' : 'Aktifkan Pengingat Acara',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isReminded ? AppColors.success : AppColors.forest,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isReminded ? AppColors.success : AppColors.forest,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Navigasi GPS: Dialog Arahkan Langsung ke GPS / Peta WisGo
  void _navigateToGpsLocation(Map<String, dynamic> ev) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.near_me_rounded, size: 20, color: AppColors.forest),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navigasi Langsung ke GPS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          ev['location'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.creamSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Titik Koordinat GPS:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                        Text(
                          ev['gpsCoordinate'] as String,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Target Acara:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                        Expanded(
                          child: Text(
                            ev['title'] as String,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Pilihan 1: Buka Peta Interaktif WisGo
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapExploreShunluScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text(
                    'Buka Peta WisGo (Jelajah Interaktif)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Pilihan 2: Salin Koordinat GPS
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ev['gpsCoordinate'] as String));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Koordinat GPS ${ev['gpsCoordinate']} berhasil disalin ke clipboard!',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: AppColors.ink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.ink),
                  label: const Text(
                    'Salin Koordinat GPS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warmBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Modal: Pusat Notifikasi & Pengingat WisGo
  void _openNotificationCenterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setNotifState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Pusat Notifikasi',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            if (_unreadNotificationCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_unreadNotificationCount Baru',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            if (_unreadNotificationCount > 0)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    for (var n in _appNotifications) {
                                      n['isRead'] = true;
                                    }
                                  });
                                  setNotifState(() {});
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    'Tandai Dibaca',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: const Icon(Icons.close_rounded, size: 22, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.warmBorder),
                  Expanded(
                    child: _appNotifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.muted),
                                SizedBox(height: 12),
                                Text(
                                  'Belum ada notifikasi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _appNotifications.length,
                            itemBuilder: (context, idx) {
                              final notif = _appNotifications[idx];
                              final isRead = notif['isRead'] as bool? ?? false;
                              final type = notif['type'] as String? ?? 'general';

                              IconData notifIcon;
                              Color iconColor;
                              Color iconBg;

                              switch (type) {
                                case 'festival':
                                  notifIcon = Icons.calendar_month_rounded;
                                  iconColor = const Color(0xFF5A3E85);
                                  iconBg = const Color(0xFFF3EDFA);
                                  break;
                                case 'opentrip':
                                  notifIcon = Icons.groups_rounded;
                                  iconColor = AppColors.forest;
                                  iconBg = AppColors.successBorder;
                                  break;
                                case 'eticket':
                                  notifIcon = Icons.confirmation_number_rounded;
                                  iconColor = AppColors.forest;
                                  iconBg = AppColors.sage;
                                  break;
                                case 'readiness_reminder':
                                  notifIcon = Icons.assignment_late_rounded;
                                  iconColor = AppColors.warningDark;
                                  iconBg = AppColors.warningBg;
                                  break;
                                case 'passport':
                                  notifIcon = Icons.verified_rounded;
                                  iconColor = AppColors.info;
                                  iconBg = AppColors.infoBg;
                                  break;
                                case 'weather':
                                  notifIcon = Icons.wb_sunny_rounded;
                                  iconColor = AppColors.warning;
                                  iconBg = AppColors.warningBg;
                                  break;
                                default:
                                  notifIcon = Icons.notifications_rounded;
                                  iconColor = AppColors.ink;
                                  iconBg = AppColors.creamSubtle;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.white : const Color(0xFFFCFDFD),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isRead ? AppColors.warmBorder : AppColors.forest.withValues(alpha: 0.4),
                                    width: isRead ? 1.0 : 1.3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.ink.withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      setState(() {
                                        notif['isRead'] = true;
                                      });
                                      setNotifState(() {});

                                      // Jika notifikasi festival, langsung buka detail festival
                                      if (type == 'festival' && notif['eventId'] != null) {
                                        final matched = _budayaFestivals.firstWhere(
                                          (f) => f['id'] == notif['eventId'],
                                          orElse: () => _budayaFestivals.first,
                                        );
                                        _openFestivalDetailModal(matched);
                                      } else if (type == 'eticket' && notif['ticketCode'] != null) {
                                        final ticket = TripETicketStore.instance
                                            .findByCode(notif['ticketCode'] as String);
                                        if (ticket != null) {
                                          showTripETicketSheet(context, ticket);
                                        }
                                      } else if (type == 'readiness_reminder' && notif['tripId'] != null) {
                                        final tripId = notif['tripId'] as String;
                                        final matchedTrip = _activeOpenTrips.firstWhere(
                                          (t) => t.id == tripId,
                                          orElse: () => _activeOpenTrips.first,
                                        );
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => TripPlannerDetailSheet(
                                            trip: matchedTrip,
                                            isOrganizerMode: false,
                                            isJoinedParticipant: true,
                                            onReadinessFinalized: _syncReadinessReminderNotifications,
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: iconBg,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(notifIcon, size: 18, color: iconColor),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notif['title'] as String,
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                                          color: AppColors.ink,
                                                        ),
                                                      ),
                                                    ),
                                                    if (!isRead)
                                                      Container(
                                                        width: 7,
                                                        height: 7,
                                                        margin: const EdgeInsets.only(left: 6),
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.danger,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  notif['message'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.muted,
                                                    height: 1.35,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      notif['time'] as String,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.muted.withValues(alpha: 0.8),
                                                      ),
                                                    ),
                                                    if (type == 'festival')
                                                      const Row(
                                                        children: [
                                                          Text(
                                                            'Lihat Rute GPS',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w800,
                                                              color: AppColors.forest,
                                                            ),
                                                          ),
                                                          Icon(Icons.chevron_right_rounded, size: 13, color: AppColors.forest),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // VIEW 2: ITEM 7 — KOMPONEN TABEL FAIR-PRICE BAROMETER (VERTIKAL)
  // ===========================================================================
  Widget _buildPetaView() {
    return Column(
      children: [
        // Top Sticky Header Peta (Clean & Minimalist)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            border: Border(
              bottom: BorderSide(color: AppColors.warmBorder),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.tr(
                        'JELAJAH SUMATERA BARAT',
                        'EXPLORE WEST SUMATRA',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AppColors.brush,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr('Peta Wisata', 'Travel Map'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocale.tr('Padang', 'Padang'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable Peta Body (Clean Spacing & Breathing Room)
        Expanded(
          child: Builder(
            builder: (context) {
              final filteredMapDestinations =
                  filterSumbarMapDestinations(_selectedPetaCategory);
              return ListView(
                controller: _petaScrollController,
                physics: _petaMapInteracting
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
                children: [
                  // 0. FILTER & LEGENDA PIN 3D PETA (Grid 3x2 Statis, Tanpa Slider)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: SumbarMapCategory.values.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: 38,
                    ),
                    itemBuilder: (context, idx) {
                      final cat = SumbarMapCategory.values[idx];
                      final active = _selectedPetaCategory == cat;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                final nextList = filterSumbarMapDestinations(cat);
                                setState(() {
                                  _selectedPetaCategory = cat;
                                  if (_selectedPetaDestinationId != null &&
                                      !nextList.any(
                                        (d) => d.id == _selectedPetaDestinationId,
                                      )) {
                                    _selectedPetaDestinationId = null;
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.sage.withValues(alpha: 0.88)
                                      : Colors.white.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.brush.withValues(alpha: 0.45)
                                        : AppColors.warmBorder.withValues(alpha: 0.85),
                                    width: active ? 1.2 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      cat.pinAsset,
                                      width: 19,
                                      height: 19,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder: (_, __, ___) => Icon(
                                        cat.icon,
                                        size: 14,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        cat.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: active
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: active
                                              ? AppColors.forest
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  // 1. REAL INTERACTIVE SUMBAR MAP (Clean & Ringan)
                  SumbarRealMapWidget(
                    height: 330,
                    destinations: filteredMapDestinations,
                    selectedDestinationId: _selectedPetaDestinationId,
                    onDestinationSelected: (dest) {
                      setState(() => _selectedPetaDestinationId = dest.id);
                    },
                    onOpenDestinationDetail: _openMapDestinationDetail,
                    onLaunchGoogleMapsRoute: (dest) {
                      _launchGoogleMapsNavigation(
                        dest.position.latitude,
                        dest.position.longitude,
                        dest.name,
                      );
                    },
                    onOpenGoogleMapsHub: () =>
                        _launchGoogleMapsQuery('Wisata Sumatera Barat'),
                    onInteractionChanged: (interacting) {
                      if (_petaMapInteracting != interacting) {
                        setState(() => _petaMapInteracting = interacting);
                      }
                    },
                    onOpenFullShunlu: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapExploreShunluScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. SLIM ACTION STRIP: Buka Peta Wisata di Google Maps
                  _buildBukaPetaWisataGmapsStrip(),

                  const SizedBox(height: 22),

                  // 3. PINTASAN FASILITAS SEARAH RUTE (Clean 4 Icons)
                  _buildPintasanSearahRuteSection(),

                  const SizedBox(height: 24),

                  // 4. TERDEKAT DARI LOKASIMU (Tersinkron dengan filter kategori peta)
                  _buildTerdekatDariLokasimuSection(filteredMapDestinations),

                  const SizedBox(height: 24),

                  // 5. PANTAUAN JALUR UTAMA & KEAMANAN
                  _buildPantauanJalurSumbarSection(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Membuka modal detail destinasi dari pin peta terpilih
  void _openMapDestinationDetail(SumbarMapDestination mapDest) {
    final lowerName = mapDest.name.toLowerCase();
    final firstWord = lowerName.split(RegExp(r'[\s&]+')).firstWhere(
          (w) => w.length >= 4,
          orElse: () => lowerName,
        );
    SavedDestinationModel? matched;
    for (final item in kAllSumbarDestinations) {
      if (item.id == mapDest.id ||
          item.title.toLowerCase().contains(firstWord) ||
          lowerName.contains(item.title.toLowerCase().split(' ').first)) {
        matched = item;
        break;
      }
    }
    _openDestinationDetailModal(matched ?? kAllSumbarDestinations.first);
  }

  /// Launch Google Maps directions (ringan & stabil di Android/iOS/Emulator)
  Future<void> _launchGoogleMapsNavigation(
    double lat,
    double lng,
    String destinationName,
  ) async {
    final opened = await launchWisgoGoogleMapsRoute(
      lat: lat,
      lng: lng,
      destinationName: destinationName,
    );
    if (!opened && mounted) {
      _showAppToast('Tidak dapat membuka Google Maps untuk $destinationName');
    }
  }

  /// Launch Google Maps query search near user location (e.g., SPBU, RM Padang, Masjid, ATM)
  Future<void> _launchGoogleMapsQuery(String query) async {
    final opened = await launchWisgoGoogleMapsSearch(query);
    if (!opened && mounted) {
      _showAppToast('Tidak dapat membuka pencarian Google Maps');
    }
  }

  /// 2. Slim Action Strip: Buka Peta Wisata di Google Maps
  Widget _buildBukaPetaWisataGmapsStrip() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchGoogleMapsQuery('Wisata Sumatera Barat'),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.tr(
                        'Buka Peta Wisata di Google Maps',
                        'Open Travel Map in Google Maps',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      AppLocale.tr(
                        'Navigasi langsung & info lalu lintas real-time',
                        'Direct navigation & live traffic updates',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD0E2D2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocale.tr('Buka', 'Open'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.forest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Pintasan Fasilitas Searah Rute (Clean 4 Tiles)
  Widget _buildPintasanSearahRuteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.tr(
            'Cari Cepat di Sekitar',
            'Quick Nearby Search',
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPintasanQuickTile(
                icon: Icons.restaurant_rounded,
                iconAsset: 'assets/images/nearby_rm_padang.png',
                iconColor: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                title: AppLocale.tr('RM Padang', 'Dining'),
                onTap: () => _launchGoogleMapsQuery('Rumah Makan Padang terdekat'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPintasanQuickTile(
                icon: Icons.local_gas_station_rounded,
                iconAsset: 'assets/images/nearby_spbu.png',
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                title: AppLocale.tr('SPBU', 'Fuel'),
                onTap: () => _launchGoogleMapsQuery('SPBU terdekat'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPintasanQuickTile(
                icon: Icons.mosque_rounded,
                iconAsset: 'assets/images/nearby_masjid.png',
                iconColor: AppColors.success,
                bgColor: AppColors.successBg,
                title: AppLocale.tr('Masjid', 'Mosque'),
                onTap: () => _launchGoogleMapsQuery('Masjid terdekat'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPintasanQuickTile(
                icon: Icons.atm_rounded,
                iconAsset: 'assets/images/nearby_atm.png',
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                title: AppLocale.tr('ATM', 'ATM'),
                onTap: () => _launchGoogleMapsQuery('ATM terdekat'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPintasanQuickTile({
    required IconData icon,
    String? iconAsset,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    Widget fallbackIcon() => Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.56),
                        AppColors.creamSubtle.withValues(alpha: 0.38),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: (iconAsset != null && iconAsset.isNotEmpty)
                      ? Image.asset(
                          iconAsset,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => fallbackIcon(),
                        )
                      : fallbackIcon(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreFilterBar() {
    final activeCount = (_currentExploreRegion != 'ALL' ? 1 : 0) +
        (_currentExploreType != 'ALL' ? 1 : 0);
    final regionLabel = _currentExploreRegion == 'ALL'
        ? AppLocale.tr('Semua Daerah', 'All Regions')
        : _exploreRegions.firstWhere(
            (r) => r['key'] == _currentExploreRegion,
            orElse: () => {'title': _currentExploreRegion},
          )['title']!;
    final typeLabel = _currentExploreType == 'ALL'
        ? AppLocale.tr('Semua Kategori', 'All Categories')
        : _exploreTypes.firstWhere(
            (t) => t['key'] == _currentExploreType,
            orElse: () => {'label': _currentExploreType},
          )['label']!;

    return Row(
      children: [
        Material(
          color: activeCount > 0 ? AppColors.forest : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _openExploreFilterSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeCount > 0 ? AppColors.forest : AppColors.warmBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: activeCount > 0 ? AppColors.cream : AppColors.forest,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activeCount > 0
                        ? '${AppLocale.tr('Filter', 'Filter')} ($activeCount)'
                        : AppLocale.tr('Filter Daerah & Kategori', 'Filter Region & Category'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: activeCount > 0 ? AppColors.cream : AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: activeCount > 0 ? AppColors.cream : AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (activeCount > 0) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$regionLabel • $typeLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openExploreFilterSheet() {
    String tempRegion = _currentExploreRegion;
    String tempType = _currentExploreType;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.warmBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocale.tr('Filter Destinasi Wisata', 'Filter Destinations'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocale.tr('Wilayah Daerah', 'Region'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _exploreRegions.map((reg) {
                        final selected = tempRegion == reg['key'];
                        final label = reg['key'] == 'ALL'
                            ? AppLocale.tr('Semua Daerah', 'All Regions')
                            : reg['title']!;
                        return Material(
                          color: selected ? AppColors.forest : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setModalState(() => tempRegion = reg['key']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? AppColors.forest : AppColors.warmBorder,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? AppColors.cream : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppLocale.tr('Kategori Wisata', 'Category'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _exploreTypes.map((type) {
                        final selected = tempType == type['key'];
                        return Material(
                          color: selected ? AppColors.sage : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setModalState(() => tempType = type['key']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? AppColors.forest : AppColors.warmBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getCategoryChipIcon(type['key']!),
                                    size: 14,
                                    color: selected ? AppColors.forest : AppColors.muted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type['label']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? AppColors.forest : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentExploreRegion = 'ALL';
                                _currentExploreType = 'ALL';
                              });
                              Navigator.pop(ctx);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              side: const BorderSide(color: AppColors.sageBorder),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppLocale.tr('Reset', 'Reset'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentExploreRegion = tempRegion;
                                _currentExploreType = tempType;
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: AppColors.cream,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              AppLocale.tr('Terapkan Filter', 'Apply Filter'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _resolveMapDestinationImageUrl(SumbarMapDestination mapDest) {
    final lowerName = mapDest.name.toLowerCase();
    final firstWord = lowerName.split(RegExp(r'[\s&]+')).firstWhere(
          (w) => w.length >= 4,
          orElse: () => lowerName,
        );
    for (final item in kAllSumbarDestinations) {
      if (item.id == mapDest.id ||
          item.title.toLowerCase().contains(firstWord) ||
          lowerName.contains(item.title.toLowerCase().split(' ').first)) {
        if (item.imageUrl.isNotEmpty) return item.imageUrl;
      }
    }
    switch (mapDest.id) {
      case 'masjid-raya-sumbar':
        return 'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?w=800';
      case 'pantai-air-manis':
      case 'pantai-padang-taplau':
      case 'pulau-pasumpahan':
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800';
      case 'kota-tua-padang':
      case 'museum-adityawarman':
        return 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800';
      default:
        return kAllSumbarDestinations.first.imageUrl;
    }
  }

  /// 4. Terdekat dari Lokasimu (Tersinkron dengan Filter Kategori Peta + Foto Transisi Blur Elegan)
  Widget _buildTerdekatDariLokasimuSection(
    List<SumbarMapDestination> destinations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedPetaCategory == SumbarMapCategory.semua
                    ? AppLocale.tr(
                        'Terdekat dari Lokasimu',
                        'Nearest to Your Location',
                      )
                    : '${_selectedPetaCategory.label} (${destinations.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.near_me_rounded,
                    size: 11,
                    color: AppColors.forest,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'GPS Padang',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: destinations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final dest = destinations[index];
              final isSelected = _selectedPetaDestinationId == dest.id;
              final cardBg = isSelected ? AppColors.successBg : AppColors.bgCard;
              final photoUrl = _resolveMapDestinationImageUrl(dest);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() => _selectedPetaDestinationId = dest.id);
                    if (_petaScrollController.hasClients) {
                      _petaScrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 228,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppColors.forest : AppColors.warmBorder,
                        width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(
                            alpha: isSelected ? 0.09 : 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Stack(
                        children: [
                          // 1. Foto Destinasi + Progressive Blur di Bagian Atas (di-clip rapi, tidak bocor shadow)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 136,
                            child: ClipRect(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  WisgoDestinationImage(
                                    source: photoUrl,
                                    destinationId: dest.id,
                                    destinationTitle: dest.name,
                                    fit: BoxFit.cover,
                                    cacheWidth: 520,
                                    fallback: Image.asset(
                                      'assets/images/splash_bg_1.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  ShaderMask(
                                    shaderCallback: (rect) => const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.white,
                                        Colors.white,
                                      ],
                                      stops: [0.0, 0.48, 0.78, 1.0],
                                    ).createShader(rect),
                                    blendMode: BlendMode.dstIn,
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                        tileMode: TileMode.clamp,
                                      ),
                                      child: WisgoDestinationImage(
                                        source: photoUrl,
                                        destinationId: dest.id,
                                        destinationTitle: dest.name,
                                        fit: BoxFit.cover,
                                        cacheWidth: 320,
                                        filterQuality: FilterQuality.low,
                                        fallback: Image.asset(
                                          'assets/images/splash_bg_1.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 2. Gradasi Smooth Penuh Seluruh Tinggi Card (100% solid warna card sebelum tepi foto berakhir -> 0 garis/shadow)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    cardBg.withValues(alpha: 0.0),
                                    cardBg.withValues(alpha: 0.0),
                                    cardBg.withValues(alpha: 0.32),
                                    cardBg.withValues(alpha: 0.82),
                                    cardBg,
                                    cardBg,
                                  ],
                                  stops: const [
                                    0.0,
                                    0.32,
                                    0.44,
                                    0.53,
                                    0.59,
                                    1.0,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Konten Kartu (Badge Atas + Judul & Tombol di Bawah)
                          Padding(
                            padding: const EdgeInsets.all(11),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardBg.withValues(alpha: 0.90),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.warmBorder.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        child: Text(
                                          '${dest.distanceLabel} • ${dest.durationLabel}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: dest.color,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: dest.color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        dest.icon,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dest.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                        height: 1.25,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.place_rounded,
                                          size: 12,
                                          color: AppColors.muted,
                                        ),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            dest.region,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 9),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(
                                                () => _selectedPetaDestinationId = dest.id,
                                              );
                                              if (_petaScrollController.hasClients) {
                                                _petaScrollController.animateTo(
                                                  0,
                                                  duration: const Duration(milliseconds: 280),
                                                  curve: Curves.easeOutCubic,
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.forest,
                                              backgroundColor: cardBg.withValues(alpha: 0.75),
                                              side: const BorderSide(
                                                color: AppColors.sageBorder,
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              AppLocale.tr('Fokus Peta', 'Focus Map'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _launchGoogleMapsNavigation(
                                              dest.position.latitude,
                                              dest.position.longitude,
                                              dest.name,
                                            ),
                                            icon: const Icon(Icons.near_me_rounded, size: 12),
                                            label: Text(
                                              AppLocale.tr('Rute', 'Route'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.forest,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 4. Pantauan Jalur Utama & Keamanan
  Widget _buildPantauanJalurSumbarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocale.tr(
                'Pantauan Jalur Utama Sumbar',
                'Main Route Monitor',
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HazardSosScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sos_rounded,
                      size: 12,
                      color: AppColors.danger,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Radar SOS →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppLocale.tr(
            'Kondisi tanjakan, tikungan & jalur rawan terkini.',
            'Current steep slope, curve, and corridor safety status.',
          ),
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildJalurCompactCard(
                name: 'Sitinjau Lauik',
                route: 'Padang – Solok',
                statusLabel: 'Lancar',
                note: 'Tanjakan licin',
                slope: '24°',
                dotColor: AppColors.success,
                badgeBg: AppColors.successBorder,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildJalurCompactCard(
                name: 'Kelok 9',
                route: 'Payakumbuh – Riau',
                statusLabel: 'Lancar',
                note: 'Ramai wisatawan',
                slope: '12°',
                dotColor: AppColors.success,
                badgeBg: AppColors.successBorder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildJalurCompactCard(
                name: 'Kelok 44',
                route: 'Maninjau, Agam',
                statusLabel: 'Hati-hati',
                note: '44 tikungan curam',
                slope: '22°',
                dotColor: AppColors.warning,
                badgeBg: AppColors.warningBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildJalurCompactCard(
                name: 'Lembah Anai',
                route: 'Padang Panjang',
                statusLabel: 'Lancar',
                note: 'Debit air normal',
                slope: '18°',
                dotColor: AppColors.success,
                badgeBg: AppColors.successBorder,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Quick Actions: Radar Grup & Aduan Jalur
        Row(
          children: [
            Expanded(
              child: _buildPetaQuickToolCard(
                icon: Icons.radar_rounded,
                iconBg: const Color(0xFFE6F0FA),
                iconColor: AppColors.info,
                title: AppLocale.tr('Radar Grup', 'Group Radar'),
                subtitle: AppLocale.tr(
                  'Pantau rombongan',
                  'Track group GPS',
                ),
                onTap: _openLiveGroupTrackingModal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPetaQuickToolCard(
                icon: Icons.shield_outlined,
                iconBg: AppColors.warningBg,
                iconColor: AppColors.warningDark,
                title: AppLocale.tr('Aduan Jalur', 'Route Report'),
                subtitle: AppLocale.tr(
                  'Pungli & jalan rusak',
                  'Illegal fees & hazards',
                ),
                onTap: () => _openLaporPungliModal(tab: 'pungli'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPetaQuickToolCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warmBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJalurCompactCard({
    required String name,
    required String route,
    required String statusLabel,
    required String note,
    required String slope,
    required Color dotColor,
    required Color badgeBg,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HazardSosScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warmBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: dotColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    slope,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$route • $note',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationGridCard(SavedDestinationModel place) {
    final isBookmarked = _savedIds.contains(place.id);
    final distText =
        '${place.distanceKm.toStringAsFixed(place.distanceKm.truncateToDouble() == place.distanceKm ? 0 : 1)} km';
    const cardBg = Color(0xFFFFFCF7);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warmBorder.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Foto Atas Proporsional Ringkas + Progressive Blur (0 Garis Sambungan)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 144,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WisgoDestinationImage(
                  source: place.imageUrl,
                  destinationId: place.id,
                  destinationTitle: place.title,
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  filterQuality: FilterQuality.medium,
                  fallback: const ColoredBox(color: AppColors.sage),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 54,
                  child: ClipRect(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white],
                          stops: [0.0, 0.65],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: WisgoDestinationImage(
                          source: place.imageUrl,
                          destinationId: place.id,
                          destinationTitle: place.title,
                          fit: BoxFit.cover,
                          cacheWidth: 320,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.low,
                          fallback: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Gradasi Menyeluruh Full-Card (100% menutupi batas bawah foto sehingga mustahil muncul garis 1px)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.ink.withValues(alpha: 0.20),
                      Colors.transparent,
                      cardBg.withValues(alpha: 0.80),
                      cardBg,
                      cardBg,
                    ],
                    stops: const [0.0, 0.24, 0.43, 0.52, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Rating + Jarak (kiri atas) & Bookmark (kanan atas)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.56),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.goldSoft,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${place.rating} • $distText',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleBookmark(place.id),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.44),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 15,
                      color: isBookmarked ? AppColors.goldSoft : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten Bawah Kartu (Judul Lebih Besar + Lokasi + 5 Ikon 3D + 2 Tombol)
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ruang visual foto fleksibel (mendorong judul + ikon turun rapi ke bawah)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openDestinationDetailModal(place),
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        GestureDetector(
                          onTap: () => _openDestinationDetailModal(place),
                          child: Text(
                            place.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.18,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 11,
                              color: AppColors.brush,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                place.subRegion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        // Deretan Ikon Fasilitas 3D Clay Sejajar Penuh Kiri-Kanan
                        SizedBox(
                          height: 27,
                          child: Row(
                            children: List.generate(
                              place.facilities.take(5).length,
                              (fIdx) {
                                final fac = place.facilities[fIdx];
                                final totalFac = place.facilities.take(5).length;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: fIdx == totalFac - 1 ? 0 : 4,
                                    ),
                                    child: Tooltip(
                                      message: fac,
                                      preferBelow: false,
                                      child: InkWell(
                                        onTap: () =>
                                            _openFacilityDetailSheet(fac, place),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          height: 27,
                                          decoration: BoxDecoration(
                                            color: AppColors.creamSubtle
                                                .withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.warmBorder
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: WisgoFacilityIcon(
                                            facilityName: fac,
                                            size: 17,
                                            fallbackIcon: _getFacilityIcon(fac),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 2 Tombol Aksi Sejajar Rapi
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 30,
                                child: OutlinedButton(
                                  onPressed: () => _open360AndDenahModal(place),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.creamSubtle,
                                    foregroundColor: AppColors.forest,
                                    side: const BorderSide(
                                      color: AppColors.sageBorder,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      AppLocale.tr('Panorama 360°', '360°'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _openDestinationDetailModal(place),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.forest,
                                    foregroundColor: AppColors.cream,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      AppLocale.tr('Detail', 'Details'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
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
        ],
      ),
    );
  }

  Widget _buildDestinationCard(
    SavedDestinationModel place, {
    required bool isSavedContext,
  }) {
    final isBookmarked = _savedIds.contains(place.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warmBorder.withValues(alpha: 0.70)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Image Header (Cinematic & Clean) - Ketuk untuk Buka Detail
          GestureDetector(
            onTap: () => _openDestinationDetailModal(place),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 175,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.forest),
                  WisgoDestinationImage(
                    source: place.imageUrl,
                    destinationId: place.id,
                    destinationTitle: place.title,
                    fit: BoxFit.cover,
                    cacheWidth: 720,
                    fallback: const ColoredBox(color: AppColors.forest),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.ink.withValues(alpha: 0.88),
                          AppColors.ink.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),

                  // Top Category Tag & Floating Bookmark Button
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: AppColors.cream.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              place.categoryTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _toggleBookmark(place.id),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              size: 18,
                              color: isBookmarked ? Colors.amber : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Image Overlay: Title & Subregion with Distance
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.sage),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${place.subRegion} • ${place.distanceKm.toStringAsFixed(place.distanceKm.truncateToDouble() == place.distanceKm ? 0 : 1)} km',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.cream,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ),

          // Card Content Body (Clean & Elegant)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Rating (kiri) + Ikon Fasilitas Compact (kanan, menggantikan posisi harga tiket)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${place.rating}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${place.reviewsCount})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: place.facilities.take(5).map((fac) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Tooltip(
                                message: fac,
                                preferBelow: false,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: InkWell(
                                    onTap: () =>
                                        _openFacilityDetailSheet(fac, place),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.creamSubtle.withValues(alpha: 0.82),
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color: AppColors.warmBorder
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: WisgoFacilityIcon(
                                        facilityName: fac,
                                        size: 19,
                                        fallbackIcon: _getFacilityIcon(fac),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Terrain Note Hint
                Row(
                  children: [
                    const Icon(Icons.terrain_rounded, size: 12, color: AppColors.brush),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.terrainNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Two Balanced Primary Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => _open360AndDenahModal(place),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.creamSubtle,
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.sageBorder),
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.threesixty_rounded, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                AppLocale.tr('Panorama 360°', '360° Panorama'),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () => _openDestinationDetailModal(place),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: AppColors.cream,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocale.tr('Detail', 'Details'),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                          ),
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
    );
  }

  // ===========================================================================
  // MODAL 1: TUR VIRTUAL 360° TERPADU (KONSISTEN DI SEMUA TOMBOL 360°)
  // ===========================================================================
  void _open360AndDenahModal(SavedDestinationModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VirtualTour360Screen(
          destination: place.toFe1Destination(),
          onOpenDenah: () => _openDenahLokasiModal(place),
        ),
      ),
    );
  }

  void _openDenahLokasiModal(SavedDestinationModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _Explore360AndDenahSheet(
          place: place,
          initialSubTab: 'denah',
          onOpenDetail: () {
            Navigator.pop(ctx);
            _openDestinationDetailModal(place);
          },
        );
      },
    );
  }

  // ===========================================================================
  // MODAL 2: DETAIL DESTINASI + ULASAN + RINCIAN BIAYA & PEMESANAN (REQUEST 1 & 4)
  // ===========================================================================
  void _openDestinationDetailModal(SavedDestinationModel place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageCtx) => DestinationDetailScreen(
          destination: place.toFe1Destination(),
          fullData: place,
          initialBookmarked: _savedIds.contains(place.id),
          onToggleBookmark: () {
            _toggleBookmark(place.id);
          },
          onOpenBarometer: () {
            Navigator.pop(pageCtx);
            _openPlaceBarometer(place.baroIndex);
          },
          onOpenLeaderboard: () {
            _openGeodeRankingModal(place);
          },
        ),
      ),
    );
  }

  // Catatan: Transaksi resmi in-app ditiadakan sesuai regulasi sistem, dialihkan langsung ke WhatsApp Vendor resmi.

  // ===========================================================================
  // MODAL 4: PEMINDAIAN PLANG SMART QR WISATA (ITEM 8)
  // ===========================================================================
  void _openQrScannerModal() {
    setState(() {
      _activeTabIndex = 2;
    });
  }

  // ===========================================================================
  // MODAL 5: LAPORAN SATGAS SABER PUNGLI & FASILITAS RUSAK (ITEM 9)
  // ===========================================================================
  void _openLaporPungliModal({String tab = 'pungli'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LaporPungliSheet(
        initialTab: tab,
        onSubmitSuccess: (ticket) {
          _showAppToast('Laporan Resmi #$ticket berhasil diteruskan ke Satgas!');
        },
      ),
    );
  }

  // ===========================================================================
  // MODAL 8: FORMULIR USULAN DESTINASI WISATA BARU (ITEM 13)
  // ===========================================================================
  void _openUsulDestinasiModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UsulDestinasiSheet(
        onSubmitSuccess: (name) {
          _showUsulanStatusDialog(name);
        },
      ),
    );
  }

  void _showUsulanStatusDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warningDark, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Usulan Terdaftar ke Dispar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions_rounded, size: 16, color: AppColors.warningDark),
                  SizedBox(width: 6),
                  Text(
                    'Status: Menunggu Verifikasi Admin',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warningDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Destinasi: "$name"',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Usulan destinasi hidden gem Anda berhasil diajukan ke Dinas Pariwisata Sumbar.',
              style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📢 Catatan Validasi: Destinasi baru ini hanya akan resmi tampil di aplikasi wisata setelah diverifikasi dan divalidasi oleh Admin Dispar Sumbar.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warningDark, height: 1.35),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Mengerti & Pantau Status'),
          ),
        ],
      ),
    );
  }

  void _openGeodeRankingModal([SavedDestinationModel? dest]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GeodeRankingModal(dest: dest),
    );
  }

  // ===========================================================================
  // MODAL 9: PANTAU LOKASI ROMBONGAN (ITEM 17)
  // ===========================================================================
  void _openLiveGroupTrackingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LiveGroupTrackingSheet(),
    );
  }

  // ===========================================================================
  // MODAL 10: PASPOR DIGITAL & VERIFIKASI GPS (ITEM 18)
  // ===========================================================================
  void _openDigitalPassportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DigitalPassportSheet(),
    );
  }

  void _openTravelExperienceDetailModal(TravelExperience exp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TravelExperienceDetailSheet(experience: exp),
    );
  }

  void _openTravelShareCardModal(TravelExperience exp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TravelShareCardSheet(experience: exp),
    );
  }

  // ===========================================================================
  // MODAL 13: DETAIL FASILITAS LINGKUNGAN KAWASAN (DENGAN HOVER & DETAIL)
  // ===========================================================================
  void _openFacilityDetailSheet(String facName, SavedDestinationModel place) {
    String detailText;
    final lower = facName.toLowerCase();
    if (lower.contains('parkir')) {
      detailText = 'Kantong parkir resmi terkelola rapi oleh Pokdarwis nagari. Tarif resmi Perda No. 4/2024: Motor Rp 3.000 / Mobil Rp 5.000. Dilarang meminta pungutan tambahan di luar karcis resmi.';
    } else if (lower.contains('toilet') || lower.contains('bilas')) {
      detailText = 'Fasilitas sanitasi bersih berstandar CHSE dengan pasokan air alami pegunungan yang jernih dan mengalir lancar. Retribusi pemeliharaan Rp 2.000.';
    } else if (lower.contains('kuliner') || lower.contains('warung')) {
      detailText = 'Deretan kedai lokal warga nagari binaan yang menyajikan kopi kawa daun khas Luhak Nan Tuo, teh talua, dan aneka kuliner tradisional dengan daftar harga pasti.';
    } else if (lower.contains('musholla') || lower.contains('masjid')) {
      detailText = 'Musala bersih dengan karpet nyaman, perlengkapan salat (mukena & sarung), serta tempat wudu dengan air mata air pegunungan yang sejuk.';
    } else if (lower.contains('foto') || lower.contains('spot')) {
      detailText = 'Spot foto panorama alami berupa dek kayu dan jembatan bambu dengan latar lanskap alam yang memukau dan berpagar aman.';
    } else if (lower.contains('guide') || lower.contains('pemandu')) {
      detailText = 'Pemandu lokal terlatih dari pemuda nagari yang siap mendampingi trekking jalur alami serta menceritakan sejarah dan kearifan tambo adat Minang.';
    } else {
      detailText = 'Fasilitas resmi kawasan yang terawat dan dikelola bersama Pokdarwis nagari sesuai regulasi Perda Prov. Sumbar No. 4/2024.';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        alignment: Alignment.center,
                        child: WisgoFacilityIcon(
                          facilityName: facName,
                          size: 24,
                          fallbackIcon: _getFacilityIcon(facName),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMASI FASILITAS LINGKUNGAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            facName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kawasan Wisata:', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Terverifikasi Perda', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forest)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const Divider(height: 16, color: AppColors.warmBorder),
                    const Text('Keterangan & Standar Layanan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest)),
                    const SizedBox(height: 4),
                    Text(
                      detailText,
                      style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, size: 16, color: AppColors.forest),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seluruh fasilitas resmi diawasi Dispar & Satgas Nagari untuk menjamin kenyamanan bebas pungli.',
                        style: TextStyle(fontSize: 11, color: AppColors.forest, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Pahami & Tutup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // HALAMAN PENUH: GANTI PROFIL WISATAWAN (Navigasi halaman penuh, bukan pop-up)
  Future<void> _openEditProfileModal() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _safeProfileName,
          initialPhone: _safeProfilePhone,
          initialOrigin: _safeProfileOrigin,
          initialRole: _safeProfileRole,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    final session = AuthSession.instance;
    setState(() {
      _profileName = session.userName;
      _profilePhone = session.userPhone;
      _profileOrigin = session.userOrigin;
      _profileRole = session.userRole;
    });
    _showAppToast(
      AppLocale.tr(
        'Profil berhasil diperbarui',
        'Profile updated successfully',
      ),
    );
  }

  // VIEW 3: PROFIL WISATAWAN & PENGATURAN AKUN
  // ===========================================================================
  Widget _buildProfileView() {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: ApiConfig.authNotifier,
      builder: (context, authUser, _) {
        final isLoggedIn = (authUser != null && ApiConfig.isAuthenticated) && !_isCurrentGuest;
        final profileDisplayName = isLoggedIn ? authUser.fullName : _safeProfileName;
        final profileDisplayPhone = isLoggedIn ? authUser.phoneNumber : _safeProfilePhone;
        final profileInitials = isLoggedIn ? authUser.initials : _safeProfileInitials;

        return Column(
          children: [
            // Sticky Header (Ringkas 1 Baris, Hemat Ruang)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                border: Border(
                  bottom: BorderSide(color: AppColors.warmBorder),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLoggedIn ? 'AKUN WISGO' : 'MODE TAMU',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.brush,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isLoggedIn ? 'Profil Saya' : 'Akun Tamu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isLoggedIn ? AppColors.sage : AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLoggedIn ? AppColors.sageBorder : AppColors.warmBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLoggedIn ? Icons.verified_rounded : Icons.person_outline_rounded,
                          size: 13,
                          color: isLoggedIn ? AppColors.forest : AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLoggedIn ? AppLocale.tr('Terverifikasi', 'Verified') : 'Tamu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isLoggedIn ? AppColors.forest : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Profile Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
                children: [
                  // Banner Masuk Akun (Jika Belum Login)
                  if (!isLoggedIn)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.brush, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brush.withValues(alpha: 0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.coralTint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.lock_outline_rounded,
                                    color: AppColors.terracotta, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Masuk untuk Fitur Penuh',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Buka sinkronisasi cloud & Paspor Minang',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nikmati kemudahan simpan destinasi lintas perangkat, verifikasi Paspor Minang di geofence nagari, dan gabung ke room Open Trip.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.45,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.login_rounded, size: 16),
                              label: const Text(
                                'Masuk dengan Nomor WhatsApp',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forest,
                                foregroundColor: AppColors.cream,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              // 1. Hero Identity Card (Rapi, Minimalis & Bebas Badge Duplikat — hanya tampil jika SUDAH LOGIN)
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.warmBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedBuilder(
                                animation: AuthSession.instance,
                                builder: (_, __) => WisgoProfileAvatar(
                                  avatarMode: AuthSession.instance.avatarMode,
                                  initials: profileInitials,
                                  size: 56,
                                  borderRadius: 18,
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profileDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$profileDisplayPhone • $_safeProfileOrigin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: AppColors.creamSubtle,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _openEditProfileModal,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.warmBorder),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: AppColors.forest,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 2 Badge Rapi (Bebas Tumpukan Duplikat)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: AppColors.forest,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'OTP WhatsApp Terverifikasi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: GamificationService.instance,
                            builder: (context, _) {
                              final grade = GamificationService.instance.currentGrade;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: grade.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(grade.icon, size: 12, color: grade.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      grade.title,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: grade.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (!_isCurrentGuest) ...[
                        const SizedBox(height: 14),
                        // Strip XP & 4 Metrik Ringkas (1 Wadah Bersih tanpa Teks Panjang)
                        AnimatedBuilder(
                          animation: GamificationService.instance,
                          builder: (context, _) {
                            final gameService = GamificationService.instance;
                            final grade = gameService.currentGrade;
                            final challenge = gameService.primaryChallenge;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.warmBorder),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Grade ${grade.level}/5 • ${grade.name}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      Text(
                                        '${gameService.currentXp} / ${gameService.targetXpForNextLevel} XP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: grade.primaryColor,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: gameService.levelProgressRatio,
                                      backgroundColor: AppColors.warmBorder,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        grade.primaryColor,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCompactProfileStat(
                                          value: '${gameService.totalTrips}',
                                          label: AppLocale.tr('Trip', 'Trips'),
                                          onTap: () => setState(() => _activeTabIndex = 0),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color: AppColors.warmBorder,
                                      ),
                                      Expanded(
                                        child: _buildCompactProfileStat(
                                          value: '${gameService.totalCheckpoints}',
                                          label: 'Check-In',
                                          onTap: _openQrScannerModal,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color: AppColors.warmBorder,
                                      ),
                                      Expanded(
                                        child: _buildCompactProfileStat(
                                          value:
                                              '${challenge.currentCheckpoints}/${challenge.targetCheckpoints}',
                                          label: AppLocale.tr('Misi', 'Quests'),
                                          onTap: _openGeodeRankingModal,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 24,
                                        color: AppColors.warmBorder,
                                      ),
                                      Expanded(
                                        child: _buildCompactProfileStat(
                                          value: '${gameService.currentXp}',
                                          label: 'XP',
                                          onTap: _openDigitalPassportModal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

            if (_isCurrentGuest) ...[
              const SizedBox(height: 14),
              _buildGuestLoginCtaBanner(),
            ],

            if (!_isCurrentGuest) ...[
              const SizedBox(height: 16),

              // 2. PASPOR DIGITAL MINANG & KOLEKSI LENCANA
              AnimatedBuilder(
                animation: GamificationService.instance,
                builder: (context, _) {
                  final gameService = GamificationService.instance;
                  final challenge = gameService.primaryChallenge;
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF26180B), Color(0xFF4D3015)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF26180B).withValues(alpha: 0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldMinang.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.goldSoft.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                AppLocale.tr(
                                  'PASPOR DIGITAL MINANG',
                                  'MINANG DIGITAL PASSPORT',
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: AppColors.goldSoft,
                                ),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: AppColors.goldSoft,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocale.tr(
                            'Stempel & Lencana Penjelajah',
                            'Explorer Stamps & Badges',
                          ),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocale.tr(
                            'Check-in GPS di kawasan wisata (< 500m) untuk mengumpulkan stempel resmi nagari & naik peringkat.',
                            'Check in via GPS at attractions (< 500m) to collect official village stamps & level up.',
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFD9C9BC),
                            height: 1.38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Indikator Progres Tantangan Lokasi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${challenge.currentCheckpoints} dari ${challenge.targetCheckpoints} Destinasi Nagari',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldSoft,
                              ),
                            ),
                            Text(
                              '${challenge.progressPercent}%',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(99)),
                          child: LinearProgressIndicator(
                            value: challenge.progressRatio,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.goldSoft,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Koleksi Lencana (Unlocked & Locked)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocale.tr('Koleksi Lencana Wisata', 'Explorer Badge Showcase'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldSoft,
                              ),
                            ),
                            Text(
                              '${gameService.unlockedBadgeCount} Terbuka • ${gameService.lockedBadgeCount} Terkunci',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFD9C9BC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: gameService.badges.map((badge) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _buildBadgeChip(
                                  badge.title,
                                  isUnlocked: badge.isUnlocked,
                                  subtitle: badge.isUnlocked
                                      ? badge.subtitle
                                      : badge.requirementDescription,
                                  icon: badge.icon,
                                  color: badge.color,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openGeodeRankingModal,
                                icon: const Icon(
                                  Icons.leaderboard_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Geode Ranking',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF3DCAA),
                                  side: BorderSide(
                                    color: AppColors.goldSoft
                                        .withValues(alpha: 0.65),
                                  ),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openDigitalPassportModal,
                                icon: const Icon(Icons.verified_rounded, size: 16),
                                label: Text(
                                  AppLocale.tr(
                                    'Paspor Digital',
                                    'Digital Passport',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD49D4A),
                                  foregroundColor: const Color(0xFF1F1307),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // 2A. Pencapaian & Rating Penyelenggara Open Trip
              AnimatedBuilder(
                animation: OrganizerRatingStore.instance,
                builder: (context, _) {
                  final ratingStore = OrganizerRatingStore.instance;
                  final reviews = ratingStore.allReviews;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, size: 18, color: AppColors.goldMinang),
                                SizedBox(width: 6),
                                Text(
                                  'Pencapaian Penyelenggara',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${ratingStore.overallAccountRating} (${reviews.length} Ulasan)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warningDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${ratingStore.completedTripsAsOrganizer}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    const Text(
                                      'Trip Selesai',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.creamSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.warmBorder),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      ratingStore.overallAccountRating >= 4.8
                                          ? 'Pemandu Prima'
                                          : 'Terverifikasi',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const Text(
                                      'Lencana Akun',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (reviews.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warmBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ulasan Terbaru • ${reviews.first.reviewerName}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    Text(
                                      '★ ${reviews.first.rating}.0',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.warningDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  reviews.first.comment,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.ink,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              // 2B. Riwayat e-Tiket Trip Go Saya (Tersimpan & Siap Print PDF)
              AnimatedBuilder(
                animation: TripETicketStore.instance,
                builder: (context, _) {
                  final tickets = TripETicketStore.instance.tickets;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.confirmation_number_rounded, size: 18, color: AppColors.forest),
                                SizedBox(width: 6),
                                Text(
                                  'Riwayat e-Tiket Trip Go',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${tickets.length} Tiket',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (tickets.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.creamSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warmBorder),
                            ),
                            child: const Text(
                              'Belum ada e-Tiket Trip Go. Setelah Anda melakukan Daftar & Bayar di Trip Go, e-Tiket resmi akan otomatis tersimpan di sini & di Notifikasi untuk diunduh/print PDF.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4),
                            ),
                          )
                        else
                          ...tickets.map((t) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cream,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.sageBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          t.bookingCode,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successBg,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'LUNAS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t.tripTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${t.departureDate} • ${t.departureTime} • ${t.participantCount} Orang',
                                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => showTripETicketSheet(context, t),
                                            icon: const Icon(Icons.qr_code_2_rounded, size: 15),
                                            label: const Text(
                                              'Lihat Tiket',
                                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.forest,
                                              side: const BorderSide(color: AppColors.sageBorder),
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => printOrDownloadTripETicketPdf(context, t),
                                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                                            label: const Text(
                                              'Print PDF',
                                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.forest,
                                              foregroundColor: AppColors.cream,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  );
                },
              ),

              // 3. Riwayat Aktivitas (Grid Card 2 Kolom — tampil 2 terbaru, selebihnya di Lihat Semua)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 10, right: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 17, color: AppColors.forest),
                        const SizedBox(width: 6),
                        Text(
                          AppLocale.tr('Riwayat Aktivitas', 'Activity History'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ActivityHistoryScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                AppLocale.tr('Lihat Semua', 'View All'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: AppColors.forest,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: GamificationService.instance,
                builder: (context, _) {
                  final history = GamificationService.instance.activityHistory;
                  if (history.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: const Text(
                        'Belum ada aktivitas. Mulai check-in di destinasi pertamamu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    );
                  }
                  final preview = history.take(2).toList();
                  return Row(
                    children: List.generate(preview.length, (i) {
                      final item = preview[i];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 0 && preview.length > 1 ? 10 : 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.warmBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ActivityHistoryScreen(),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Foto Destinasi Asli + Badge XP
                                      SizedBox(
                                        height: 92,
                                        width: double.infinity,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.asset(
                                              item.resolvedImageAsset,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: item.iconColor.withValues(alpha: 0.14),
                                                child: Icon(
                                                  item.icon,
                                                  size: 28,
                                                  color: item.iconColor,
                                                ),
                                              ),
                                            ),
                                            const DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0x28000000),
                                                    Color(0x00000000),
                                                    Color(0x52000000),
                                                  ],
                                                  stops: [0.0, 0.45, 1.0],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 7,
                                              right: 7,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.forest.withValues(alpha: 0.88),
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.28),
                                                  ),
                                                ),
                                                child: Text(
                                                  '+${item.xpEarned} XP',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    fontFeatures: [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 7,
                                              bottom: 7,
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.92),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  item.icon,
                                                  size: 13,
                                                  color: item.iconColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Judul & Wilayah Ringkas
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 32,
                                              child: Text(
                                                item.destinationTitle,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink,
                                                  height: 1.25,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.place_outlined,
                                                  size: 12,
                                                  color: AppColors.muted,
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    item.region,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.muted,
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
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 2B. RIWAYAT PERJALANAN & EXPERIENCE (STRAVA-LIKE DENGAN CHECKPOINT & TEMPLATE POSTING PROMOSI)
              _buildTravelExperienceProfileSection(),
            ],

            const SizedBox(height: 22),

            // 3. Pintasan Cepat 2 Kolom (Visual Card - Mengurangi Daftar Teks Panjang)
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: _openKamusMinangScreen,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: AppColors.warningBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.translate_rounded,
                                  size: 18,
                                  color: AppColors.warningDark,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocale.tr('Kamus Minang', 'Minang Dictionary'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocale.tr('Audio & Budaya', 'Audio & Culture'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HazardSosScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: AppColors.dangerBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.health_and_safety_rounded,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocale.tr('Darurat SOS', 'Emergency SOS'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocale.tr('Hotline & Berita', 'Hotline & News'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

            // 4. Pengaturan Perangkat (Ringkas & Bersih)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  AppLocale.tr('Pengaturan Perangkat', 'Device Settings'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: AppColors.infoBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.language_rounded,
                              size: 18,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocale.tr('Bahasa Aplikasi', 'App Language'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const LanguageTogglePill(),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 60,
                      color: AppColors.warmBorder,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _isOfflineMode
                                  ? AppColors.warningBg
                                  : AppColors.sage,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isOfflineMode
                                  ? Icons.cloud_off_rounded
                                  : Icons.offline_pin_rounded,
                              size: 18,
                              color: _isOfflineMode
                                  ? AppColors.warningDark
                                  : AppColors.forest,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocale.tr('Mode Tanpa Sinyal', 'Offline Mode'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: _isOfflineMode,
                            activeTrackColor: AppColors.forest,
                            onChanged: (v) =>
                                setState(() => _isOfflineMode = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4. Action Button (Masuk untuk Tamu vs Logout untuk Pengguna Terdaftar)
              if (_isCurrentGuest)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(
                      AppLocale.tr('Masuk ke Akun Saya', 'Sign In to My Account'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => Dialog(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                          side: const BorderSide(
                            color: AppColors.warmBorder,
                            width: 1.0,
                          ),
                        ),
                        insetPadding:
                            const EdgeInsets.symmetric(horizontal: 28),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF4F4),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.16),
                                    width: 1.2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.danger,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocale.tr('Keluar dari Akun?', 'Sign Out?'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocale.tr(
                                  'Anda akan kembali ke halaman awal WISGO dan perlu verifikasi WhatsApp OTP untuk masuk kembali.',
                                  'You will return to the WISGO welcome screen and need WhatsApp OTP verification to sign back in.',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.ink,
                                          backgroundColor: AppColors.creamSubtle,
                                          side: const BorderSide(
                                            color: AppColors.warmBorder,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          AppLocale.tr('Batal', 'Cancel'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.of(context)
                                              .pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SplashScreen(),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.danger,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          AppLocale.tr('Keluar', 'Sign Out'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    isLoggedIn
                        ? 'Keluar dari Akun (Logout)'
                        : AppLocale.tr('Keluar dari Akun', 'Sign Out'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFAF2F3),
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'WISGO • Rancak.in Sumatera Barat v1.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
      },
    );
  }

  /// Banner ajakan masuk / registrasi untuk pengunjung Mode Tamu (Guest Mode)
  Widget _buildGuestLoginCtaBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F4EE), Color(0xFFEFE8DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD4C5B3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: AppColors.goldSoft,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.tr('Ayo Masuk ke Akun Anda!', 'Sign in to Your Account!'),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr(
                        'Simpan data & progres petualangan Anda',
                        'Save your progress & adventure badges',
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocale.tr(
              'Anda saat ini berada dalam Mode Tamu. Semua tab (Beranda, Open Trip, Peta, Kamus Minang) bebas dijelajahi! Masuk atau daftar akun untuk menyimpan riwayat perjalanan, mengoleksi stempel Paspor Minang, dan sinkronisasi lintas perangkat.',
              'You are exploring in Guest Mode. All tabs (Home, Open Trip, Map, Minang Dictionary) are fully accessible! Sign in to permanently save your journey logs, unlock passport stamps, and sync across devices.',
            ),
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF4A453E),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Preview Fitur Akun Terdaftar (Status Terkunci di Mode Tamu)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4C5B3).withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                _buildGuestFeatureRow(
                  Icons.military_tech_rounded,
                  AppColors.warning,
                  AppLocale.tr('5 Tingkat Grade & Lencana Petualang', '5 Adventurer Grades & Badges'),
                  AppLocale.tr('Kumpulkan XP dari check point & selesaikan challenge', 'Earn XP from check points & complete challenges'),
                ),
                const Divider(height: 16, color: AppColors.warmBorder),
                _buildGuestFeatureRow(
                  Icons.verified_rounded,
                  AppColors.forest,
                  AppLocale.tr('Paspor Digital Minang', 'Minang Digital Passport'),
                  AppLocale.tr('Stempel resmi nagari & bukti penjelajahan GPS', 'Official nagari stamps & GPS exploration proof'),
                ),
                const Divider(height: 16, color: AppColors.warmBorder),
                _buildGuestFeatureRow(
                  Icons.history_rounded,
                  AppColors.info,
                  AppLocale.tr('Riwayat Perjalanan & Aktivitas', 'Journey Logs & Timeline'),
                  AppLocale.tr('Simpan jejak rute wisata & sinkronisasi antar-perangkat', 'Save exploration routes & sync across devices'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: Text(
                AppLocale.tr('Masuk / Buat Akun Sekarang', 'Sign In / Register Now'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestFeatureRow(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 10, color: Colors.grey.shade600),
              const SizedBox(width: 2),
              Text(
                AppLocale.tr('Terkunci', 'Locked'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelExperienceProfileSection() {
    final jejakTrips = ApiConfig.isAuthenticated ? kSampleTravelExperiences : <TravelExperience>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Jejak WISGO (Item 1-2 Kampanye Sosial)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.travel_explore_rounded,
                          color: AppColors.forest,
                          size: 19,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Jejak WISGO',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pamerkan momen wisatamu ke IG Story, TikTok, atau WA Status',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ink.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: const Text(
                  'Viral Share',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Summary Stats Banner Jejak WISGO (Tanpa Pace, Kalori, Elevasi)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warmBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildAggregatedStatItem(
                jejakTrips.isNotEmpty ? '${jejakTrips.first.visitedCount}/${jejakTrips.first.totalDestinations}' : '0/20',
                '',
                'Destinasi',
                Icons.explore_rounded,
                AppColors.forest,
              ),
              _buildAggregatedDivider(),
              _buildAggregatedStatItem(
                jejakTrips.isNotEmpty ? '#${jejakTrips.first.stampNumber}' : '#0',
                '',
                'Stempel',
                Icons.verified_rounded,
                AppColors.success,
              ),
              _buildAggregatedDivider(),
              _buildAggregatedStatItem(
                jejakTrips.isNotEmpty ? jejakTrips.first.levelTitle : 'Pemula',
                '',
                'Gelar',
                Icons.military_tech_rounded,
                AppColors.warning,
              ),
              _buildAggregatedDivider(),
              _buildAggregatedStatItem(
                jejakTrips.isNotEmpty ? '450' : '0',
                'XP',
                'Poin Wisata',
                Icons.stars_rounded,
                AppColors.info,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Empty State Jujur atau Daftar Jejak WISGO
        if (jejakTrips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.forest.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 36,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Belum Ada Jejak WISGO',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kunjungi destinasi wisata di Sumatera Barat, lakukan check-in GPS atau ikuti Trip Go untuk menorehkan jejak pertamamu dan membagikannya ke media sosial!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _activeTabIndex = 0);
                    },
                    icon: const Icon(Icons.explore_rounded, size: 15),
                    label: const Text(
                      'Jelajahi Destinasi Sekarang',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...jejakTrips.map((exp) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.warmBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top tag & Date
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.forest.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exp.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        Text(
                          exp.tripDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title & Destination
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 12, color: AppColors.forest),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${exp.destinationName}, ${exp.cityRegency}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3 Blok Info Jejak WISGO
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniExpMetric('Stempel', '#${exp.stampNumber}'),
                        _buildMiniExpDivider(),
                        _buildMiniExpMetric('Progres', '${exp.visitedCount}/${exp.totalDestinations} Destinasi'),
                        _buildMiniExpDivider(),
                        _buildMiniExpMetric('Gelar', exp.levelTitle),
                      ],
                    ),
                  ),

                  // Lencana Pills
                  if (exp.achievements.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: exp.achievements.map((ach) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: ach.ribbonColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: ach.ribbonColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(ach.icon, size: 11, color: ach.ribbonColor),
                                const SizedBox(width: 3),
                                Text(
                                  ach.title,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: ach.ribbonColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // 2 Action Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: OutlinedButton.icon(
                              onPressed: () => _openTravelExperienceDetailModal(exp),
                              icon: const Icon(Icons.info_outline_rounded, size: 14),
                              label: const Text(
                                'Detail Jejak',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.forest,
                                side: const BorderSide(color: AppColors.forest),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ElevatedButton.icon(
                              onPressed: () => _openTravelShareCardModal(exp),
                              icon: const Icon(Icons.share_rounded, size: 14),
                              label: const Text(
                                'Stiker & Kartu',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forest,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAggregatedStatItem(String value, String unit, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 1),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatedDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.warmBorder,
    );
  }

  Widget _buildMiniExpMetric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniExpDivider() {
    return Container(
      width: 1,
      height: 18,
      color: AppColors.warmBorder,
    );
  }

  Widget _buildCompactProfileStat({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(
    String title, {
    required bool isUnlocked,
    required String subtitle,
    IconData? icon,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.goldSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF382310)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? activeColor.withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isUnlocked ? activeColor.withValues(alpha: 0.20) : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? icon : Icons.lock_outline_rounded,
                size: 13,
                color: isUnlocked ? activeColor : Colors.white38,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked ? AppColors.goldSoft : Colors.white54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? const Color(0xFFD9C9BC) : Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar Flat & Bersih (Tanpa Notch Menonjol / Tanpa Garis Home Palsu)
  Widget _buildClean4ButtonBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        child: SizedBox(
          height: 78,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const double horizontalInset = 10.0;
              final usableWidth =
                  (totalWidth - (horizontalInset * 2)).clamp(1.0, totalWidth);
              final safeIndex = _activeTabIndex.clamp(0, _navItems.length - 1);
              final itemWidth = usableWidth / _navItems.length;
              final targetCenterX =
                  horizontalInset + (itemWidth * safeIndex) + (itemWidth / 2);

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: targetCenterX),
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutQuart,
                builder: (context, animatedCenterX, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Curved Bar Surface with Smooth Concave Notch & Layered Shadow
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CurvedNotchBarPainter(
                            notchCenterX: animatedCenterX,
                          ),
                        ),
                      ),

                      // 2. Floating Active Circle Icon inside the Notch (Smooth AnimatedSwitcher)
                      Positioned(
                        top: -8,
                        left: animatedCenterX - 25,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.forest,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forest.withValues(alpha: 0.24),
                                blurRadius: 18,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.78),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                scale: CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutBack,
                                ),
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              ),
                              child: Icon(
                                _navItems[safeIndex]['activeIcon'] as IconData,
                                key: ValueKey<int>(safeIndex),
                                size: 20,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 3. 5 Navigation Columns (Beranda, Trip Go, Check-In, Peta, Profil)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            horizontalInset,
                            16,
                            horizontalInset,
                            14,
                          ),
                          child: Row(
                            children: List.generate(_navItems.length, (idx) {
                              final isSelected = idx == safeIndex;
                              final item = _navItems[idx];

                              return Expanded(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (idx == 2) {
                                        _runWithAuthGuard(
                                          title: 'Masuk untuk Check-In GPS',
                                          description:
                                              'Masuk ke akun WISGO untuk mencatat stempel kunjungan, XP petualang, dan Challenge 10 Destinasi.',
                                          onAllowed: _openQrScannerModal,
                                        );
                                        return;
                                      }
                                      setState(() => _activeTabIndex = idx);
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          opacity: isSelected ? 0.0 : 1.0,
                                          child: Icon(
                                            item['icon'] as IconData,
                                            size: 21,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? AppColors.forest
                                                    : AppColors.muted,
                                                letterSpacing:
                                                    isSelected ? -0.1 : 0.0,
                                              ),
                                              child: Text(
                                                AppLocale.isEn
                                                    ? (item['labelEn']
                                                        as String)
                                                    : (item['label'] as String),
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // 4. Bottom Home Indicator Pill
                      Positioned(
                        bottom: 5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 108,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.forest.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar Mobile Navigation Bar dengan lekukan cekung (Notch)
/// yang mengalir lembut (smooth cubic Bezier) beserta bayangan (shadow) berlapis.
class _CurvedNotchBarPainter extends CustomPainter {
  final double notchCenterX;

  const _CurvedNotchBarPainter({
    required this.notchCenterX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const double topY = 14.0;
    const double cornerRadius = 20.0;
    const double minTopCorner = 8.0;
    const double maxNotchHalfWidth = 40.0;
    const double notchDepth = 47.0;

    // Pastikan pusat lekukan selalu tepat di tengah lingkaran aktif (termasuk Tab 0 & Tab 4)
    final double cx = notchCenterX.clamp(
      minTopCorner + 26.0,
      w - minTopCorner - 26.0,
    );
    final double maxLeftHalf =
        (cx - minTopCorner).clamp(26.0, maxNotchHalfWidth);
    final double maxRightHalf =
        ((w - minTopCorner) - cx).clamp(26.0, maxNotchHalfWidth);
    final double notchHalfWidth =
        maxLeftHalf < maxRightHalf ? maxLeftHalf : maxRightHalf;

    final double nStart = cx - notchHalfWidth;
    final double nEnd = cx + notchHalfWidth;
    final double leftTopRadius = nStart < cornerRadius ? nStart : cornerRadius;
    final double rightTopRadius =
        (w - nEnd) < cornerRadius ? (w - nEnd) : cornerRadius;
    // Proporsi control point Bezier yang lebih landai & organik agar tidak ada sudut tajam
    final double ctrlOuter = notchHalfWidth * 0.62;
    final double ctrlInner = notchHalfWidth * 0.56;

    final path = Path()
      ..moveTo(0, topY + leftTopRadius)
      ..quadraticBezierTo(0, topY, leftTopRadius, topY)
      ..lineTo(nStart, topY)
      ..cubicTo(
        cx - ctrlOuter,
        topY,
        cx - ctrlInner,
        notchDepth,
        cx,
        notchDepth,
      )
      ..cubicTo(
        cx + ctrlInner,
        notchDepth,
        cx + ctrlOuter,
        topY,
        nEnd,
        topY,
      )
      ..lineTo(w - rightTopRadius, topY)
      ..quadraticBezierTo(w, topY, w, topY + rightTopRadius)
      ..lineTo(w, h - cornerRadius)
      ..quadraticBezierTo(w, h, w - cornerRadius, h)
      ..lineTo(cornerRadius, h)
      ..quadraticBezierTo(0, h, 0, h - cornerRadius)
      ..close();

    // 1. Ambient Soft Shadow (terlihat jelas & halus di Web maupun Mobile)
    final ambientShadowPaint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0);
    canvas.save();
    canvas.translate(0, 7);
    canvas.drawPath(path, ambientShadowPaint);
    canvas.restore();

    // 2. Focused Elevation Shadow
    final keyShadowPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, keyShadowPaint);
    canvas.restore();

    // 3. Material Elevation Drop Shadow
    canvas.drawShadow(
      path,
      AppColors.forest.withValues(alpha: 0.20),
      14.0,
      false,
    );

    // White Fill
    final fillPaint = Paint()
      ..color = AppColors.bgCard
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Subtle Border
    final borderPaint = Paint()
      ..color = AppColors.sageBorder.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNotchBarPainter oldDelegate) {
    return oldDelegate.notchCenterX != notchCenterX;
  }
}

// =============================================================================
// MODAL BOTTOM SHEETS: 360° & DENAH, DETAIL & ULASAN, CHECKOUT WISGO ESCROW
// =============================================================================

class _Explore360AndDenahSheet extends StatefulWidget {
  final SavedDestinationModel place;
  final VoidCallback onOpenDetail;
  final String initialSubTab;

  const _Explore360AndDenahSheet({
    required this.place,
    required this.onOpenDetail,
    this.initialSubTab = '360',
  });

  @override
  State<_Explore360AndDenahSheet> createState() => _Explore360AndDenahSheetState();
}

class _Explore360AndDenahSheetState extends State<_Explore360AndDenahSheet> {
  late String _subTab; // '360' | 'denah'
  String _selectedDenahType = 'UMKM';
  bool _isQuickBookingOpen = false;
  bool _isPlayingVoiceOver = false;
  bool _isNarrationExpanded = false;
  double _voiceOverProgress = 0.0;
  Timer? _voiceOverTimer;
  double _yaw = 0.0;
  double _pitch = 0.0;

  @override
  void initState() {
    super.initState();
    _subTab = widget.initialSubTab;
  }

  @override
  void dispose() {
    _voiceOverTimer?.cancel();
    super.dispose();
  }

  void _toggleVoiceOver() {
    setState(() {
      _isPlayingVoiceOver = !_isPlayingVoiceOver;
      if (_isPlayingVoiceOver) {
        _voiceOverTimer?.cancel();
        _voiceOverTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
          if (!mounted) return;
          setState(() {
            _voiceOverProgress += 0.015;
            if (_voiceOverProgress >= 1.0) {
              _voiceOverProgress = 0.0;
              _isPlayingVoiceOver = false;
              t.cancel();
            }
          });
        });
      } else {
        _voiceOverTimer?.cancel();
      }
    });
  }

  String _getHistoricalNarration(SavedDestinationModel place) {
    if (place.title.toLowerCase().contains('harau')) {
      return 'Lembah Harau merupakan lembah cadas subur di Kabupaten Lima Puluh Kota yang dikelilingi tebing batuan granit terjal setinggi 100 hingga 500 meter. Penelitian geologis membuktikan lembah ini jutaan tahun lalu merupakan dasar lautan purba yang terangkat ke permukaan bumi. Dalam sejarah lisan Minangkabau, lembah ini menjadi saksi bermukimnya suku-suku awal Luhak Limopuluah dan menjadi benteng alam pertahanan nagari yang tak tertembus.';
    } else if (place.title.toLowerCase().contains('lubuk hitam') || place.title.toLowerCase().contains('cindakir')) {
      return 'Air Terjun Lubuk Hitam (Cindakir) memiliki formasi langka tiga tingkatan air terjun alami di kawasan hutan lindung Bungus Teluk Kabung. Berdasarkan penuturan tetua adat nagari, kolam alami pada tingkatan ketiga konon merupakan tempat pemandian dan meditasi para pemuka adat sebelum menempuh jalur maritim pesisir barat Sumatera pada abad ke-16.';
    } else if (place.title.toLowerCase().contains('sianok')) {
      return 'Ngarai Sianok adalah lembah patahan curam sepanjang 15 kilometer dengan dinding vertikal hingga 120 meter yang terbentuk dari pergerakan lempeng tektonik sesar Semangko. Dalam sejarah perjuangan masyarakat Bukittinggi, ngarai ini menjadi jalur persembunyian rahasia dan penghubung peradaban nagari Koto Gadang yang melegenda dengan kerajinan perak dan tokoh-tokoh pergerakan nasional.';
    } else if (place.title.toLowerCase().contains('singkarak')) {
      return 'Danau Singkarak terbentang luas di antara Kabupaten Solok dan Tanah Datar, menjadi habitat alami ikan bilih yang merupakan spesies endemik satu-satunya di dunia. Danau tektonik ini menyimpan sejarah jalur perdagangan tradisional garam dan rempah-rempah dari pedalaman Minangkabau menuju pesisir Selat Malaka sejak masa kerajaan Melayu Dharmasraya.';
    } else {
      return '${place.title} di wilayah ${place.subRegion} merupakan salah satu warisan alam dan peradaban nagari bersejarah di Sumatera Barat. Tempat ini menyimpan cerita turun-temurun masyarakat lokal mengenai kearifan menjaga hutan adat, kelestarian sumber mata air pegunungan, serta falsafah Minangkabau "Alam Takambang Jadi Guru".';
    }
  }

  void _contactVendorWhatsApp(int totalAmount, List<Map<String, dynamic>> items) {
    final itemSummaries = items.map((it) => '${it['name']} (${it['qty']}x)').join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mengarahkan informasi layanan (${widget.place.title}) ke WhatsApp Vendor Resmi (+62 812-7578-953): $itemSummaries',
        ),
        backgroundColor: AppColors.forest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Header Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EKSPLORASI LINGKUNGAN & DENAH KAWASAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.brush,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.place.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.creamSubtle,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),

          // Subtabs: 360 vs Denah
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.creamSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _subTab = '360'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _subTab == '360' ? AppColors.forest : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '360° Virtual Kawasan',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _subTab == '360' ? AppColors.cream : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _subTab = 'denah'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _subTab == 'denah' ? AppColors.forest : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Denah Lokasi Interaktif',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _subTab == 'denah' ? AppColors.cream : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body Content
          Expanded(
            child: _subTab == '360'
                ? _build360PanoramaView()
                : _buildDenahLokasiView(),
          ),
        ],
      ),
    );
  }

  Widget _build360PanoramaView() {
    final bool useFallback360 = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Viewer Panorama 360° Interaktif (Native 3D Sphere on Mobile/Web + Touch Pan, Resilient Fallback on Desktop)
          Positioned.fill(
            child: useFallback360
                ? _buildDesktopPanoramaFallback()
                : ClipRect(
                    child: PanoramaViewer(
                      animSpeed: 0.1,
                      latitude: _pitch,
                      longitude: _yaw,
                      onViewChanged: (lon, lat, tilt) {
                        setState(() {
                          _yaw = lon;
                          _pitch = lat;
                        });
                      },
                      child: Image.asset(
                        'assets/images/panorama_sumbar_default.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),

          // 2. Baris Kontrol Atas: Status 360 & Tombol Sensor Gyro Fullscreen FE-1
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.threed_rotation_rounded, size: 14, color: AppColors.sage),
                      SizedBox(width: 5),
                      Text(
                        'Geser 360° Aktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VirtualTour360Screen(
                          destination: widget.place.toFe1Destination(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.screen_rotation_rounded,
                            size: 14, color: AppColors.cream),
                        SizedBox(width: 5),
                        Text(
                          'Sensor Gyro 360° Penuh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating AI Voice Over Historical Storytelling Bar (Sejalan dengan 360°)
          Positioned(
            top: 52,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPlayingVoiceOver ? Colors.amber : Colors.white24,
                  width: _isPlayingVoiceOver ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleVoiceOver,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _isPlayingVoiceOver ? AppColors.terracotta : AppColors.forest,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _isPlayingVoiceOver ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _isPlayingVoiceOver ? 'MEMUTAR NARASI BUDAYA' : 'AUDIO NARASI BUDAYA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: _isPlayingVoiceOver ? Colors.amber : AppColors.sage,
                                  ),
                                ),
                                if (_isPlayingVoiceOver) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.graphic_eq_rounded, size: 14, color: Colors.amber),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Sejarah ${widget.place.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isNarrationExpanded = !_isNarrationExpanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isNarrationExpanded ? 'Tutup' : 'Teks',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                _isNarrationExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isPlayingVoiceOver) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _voiceOverProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 3,
                      ),
                    ),
                  ],
                  if (_isNarrationExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getHistoricalNarration(widget.place),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.cream,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 4. Floating Quick Booking Button (Requirement 14)
          if (!_isQuickBookingOpen)
            Positioned(
              bottom: 58,
              left: 20,
              right: 20,
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isQuickBookingOpen = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 16, color: AppColors.cream),
                        SizedBox(width: 6),
                        Text(
                          'Pesan Layanan Cepat',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Bottom gesture prompt when panel closed
          if (!_isQuickBookingOpen)
            Positioned(
              bottom: 18,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Sentuh & geser layar untuk melihat sekeliling 360°',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                ),
              ),
            ),

          // 7. Quick Booking Sliding Half-Panel over 360 view (Requirement 14 & 15)
          if (_isQuickBookingOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: QuickBookingPanel(
                place: widget.place,
                onClose: () => setState(() => _isQuickBookingOpen = false),
                onProceedToPayment: (total, items) {
                  _contactVendorWhatsApp(total, items);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopPanoramaFallback() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double alignX = (_yaw % 360 - 180) / 180.0;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _yaw += details.delta.dx * 0.45;
              _pitch = (_pitch - details.delta.dy * 0.25).clamp(-45.0, 45.0);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Panorama 360 photo background that pans horizontally with drag
              Positioned.fill(
                child: Container(
                  color: AppColors.ink,
                  child: Image.asset(
                    'assets/images/panorama_sumbar_default.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment(alignX, (_pitch / 45.0).clamp(-1.0, 1.0)),
                    errorBuilder: (ctx, err, stack) => Image.network(
                      widget.place.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment(alignX, 0),
                    ),
                  ),
                ),
              ),

              // Ambient gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDenahLokasiView() {
    final points = widget.place.denahPoints;
    final selectedPoint = points.firstWhere(
      (p) => p.category == _selectedDenahType,
      orElse: () => points.isNotEmpty
          ? points.first
          : DenahPoint(
              category: 'UMKM',
              title: 'Warung Kuliner UMKM Minang',
              description: 'Kuliner lokal autentik.',
              x: 50,
              y: 50,
            ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.forest),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ketuk titik pin di denah untuk melihat fasilitas UMKM Makanan, Toilet, dan Parkir.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Map Box
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.sage.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.forest, width: 2),
            ),
            child: Stack(
              children: [
                // Painted river and trees
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SitePlanPainter(),
                  ),
                ),

                // Interactive Pin 1: Parkir
                _buildDenahPin(
                  category: 'PARKIR',
                  label: 'Parkir', iconData: Icons.local_parking_rounded,
                  topPct: 0.68,
                  leftPct: 0.16,
                ),
                // Interactive Pin 2: Loket
                _buildDenahPin(
                  category: 'LOKET',
                  label: 'Loket', iconData: Icons.confirmation_number_rounded,
                  topPct: 0.55,
                  leftPct: 0.36,
                ),
                // Interactive Pin 3: UMKM
                _buildDenahPin(
                  category: 'UMKM',
                  label: 'UMKM Makanan', iconData: Icons.restaurant_rounded,
                  topPct: 0.42,
                  leftPct: 0.56,
                ),
                // Interactive Pin 4: Toilet
                _buildDenahPin(
                  category: 'TOILET',
                  label: 'Toilet', iconData: Icons.wc_rounded,
                  topPct: 0.28,
                  leftPct: 0.42,
                ),
                // Interactive Pin 5: Musholla
                _buildDenahPin(
                  category: 'MUSHOLLA',
                  label: 'Musholla', iconData: Icons.mosque_rounded,
                  topPct: 0.22,
                  leftPct: 0.72,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Highlighted POI Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sageBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TITIK ${selectedPoint.category}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const Text(
                      'Terverifikasi Petugas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brush,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  selectedPoint.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedPoint.description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action: Buka Navigasi Peta Rute & Google Maps
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMapNavigationSheet(
                      context,
                      widget.place,
                      _selectedDenahType,
                      widget.onOpenDetail,
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text(
                    'Buka Peta & Rute Navigasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onOpenDetail,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forest,
                  side: const BorderSide(color: AppColors.warmBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDenahPin({
    required String category,
    required String label,
    required IconData iconData,
    required double topPct,
    required double leftPct,
  }) {
    final isSelected = _selectedDenahType == category;
    return Positioned(
      top: 220 * topPct - 14,
      left: 320 * leftPct - 30,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDenahType = category;
            // Geser yaw visual ke arah lokasi hotspot titik yang dipilih
            if (category == 'PARKIR') {
              _yaw = -60.0;
            } else if (category == 'LOKET') {
              _yaw = -25.0;
            } else if (category == 'UMKM') {
              _yaw = 20.0;
            } else if (category == 'TOILET') {
              _yaw = 65.0;
            } else if (category == 'MUSHOLLA') {
              _yaw = 110.0;
            }
          });
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(iconData, size: 16, color: AppColors.cream),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menuju lokasi:  (Koordinat Titik Terpilih)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.forest,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.forest : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.terracotta : AppColors.sageBorder,
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? AppColors.terracotta.withValues(alpha: 0.4) : Colors.black12,
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                size: 13,
                color: isSelected ? AppColors.cream : AppColors.forest,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.cream : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODAL PETA NAVIGASI & RUTE LOKASI (GOOGLE MAPS)
// =============================================================================

void _showMapNavigationSheet(
  BuildContext context,
  SavedDestinationModel place,
  String targetFacility,
  VoidCallback onOpenDetail,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MapNavigationSheet(
      place: place,
      targetFacility: targetFacility,
      onOpenDetail: onOpenDetail,
    ),
  );
}

class _MapNavigationSheet extends StatelessWidget {
  final SavedDestinationModel place;
  final String targetFacility;
  final VoidCallback onOpenDetail;

  const _MapNavigationSheet({
    required this.place,
    required this.targetFacility,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final facilityName = targetFacility == 'PARKIR'
        ? 'Tempat Parkir Resmi'
        : targetFacility == 'LOKET'
            ? 'Loket Tiket Pokdarwis'
            : targetFacility == 'UMKM'
                ? 'Warung UMKM Makanan'
                : targetFacility == 'TOILET'
                    ? 'Toilet & Sanitasi'
                    : targetFacility == 'MUSHOLLA'
                        ? 'Musholla & Tempat Ibadah'
                        : targetFacility;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PETA NAVIGASI & RUTE LOKASI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppColors.brush,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.warmBorder),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Menuju: $facilityName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              place.subRegion,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${place.distanceKm} km',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.forest,
                            ),
                          ),
                          Text(
                            '± ${place.distanceKm * 2} mnt',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Real Interactive GPS Map Container
                SumbarRealMapWidget(
                  height: 240,
                  selectedDestinationId: place.id,
                  compactNavigationTitle: 'GPS Aktif • Akurasi 5m',
                ),
                const SizedBox(height: 18),

                // Start Navigation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membuka rute GPS Google Maps menuju ${place.title}...'),
                          backgroundColor: AppColors.forest,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'Mulai Navigasi Langsung di Google Maps',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Check Detail Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onOpenDetail();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      side: const BorderSide(color: AppColors.warmBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Lihat Rincian Biaya & Tiket Masuk Resmi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MODAL 3: CHECKOUT PEMESANAN RESMI (WISGO ESCROW & TIKET QR)
// =============================================================================

class _SitePlanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // River
    final riverPaint = Paint()
      ..color = AppColors.sage.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(0, h * 0.75);
    riverPath.quadraticBezierTo(w * 0.35, h * 0.5, w * 0.65, h * 0.7);
    riverPath.quadraticBezierTo(w * 0.85, h * 0.85, w, h * 0.45);
    canvas.drawPath(riverPath, riverPaint);

    // Main Road
    final roadPaint = Paint()
      ..color = AppColors.warmBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final roadPath = Path();
    roadPath.moveTo(w * 0.05, h * 0.95);
    roadPath.lineTo(w * 0.25, h * 0.75);
    roadPath.lineTo(w * 0.55, h * 0.8);
    roadPath.lineTo(w * 0.95, h * 0.7);
    canvas.drawPath(roadPath, roadPaint);
  }

  @override
  bool shouldRepaint(covariant _SitePlanPainter oldDelegate) => false;
}

IconData _getFacilityIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('parkir')) return Icons.local_parking_rounded;
  if (lower.contains('toilet') || lower.contains('bilas') || lower.contains('kamar ganti')) return Icons.wc_rounded;
  if (lower.contains('kuliner') || lower.contains('warung') || lower.contains('makan') || lower.contains('kopi')) return Icons.restaurant_rounded;
  if (lower.contains('musholla') || lower.contains('masjid')) return Icons.mosque_rounded;
  if (lower.contains('trekking') || lower.contains('jalur') || lower.contains('hutan')) return Icons.hiking_rounded;
  if (lower.contains('rakit') || lower.contains('perahu') || lower.contains('boat') || lower.contains('kapal') || lower.contains('dermaga')) return Icons.directions_boat_rounded;
  if (lower.contains('pemandian') || lower.contains('air panas') || lower.contains('kolam')) return Icons.hot_tub_rounded;
  if (lower.contains('gardu') || lower.contains('pandang') || lower.contains('panorama')) return Icons.visibility_rounded;
  if (lower.contains('gazebo') || lower.contains('lesehan')) return Icons.deck_rounded;
  if (lower.contains('rumah gadang') || lower.contains('istano') || lower.contains('sejarah') || lower.contains('kuno')) return Icons.account_balance_rounded;
  if (lower.contains('pemandu') || lower.contains('guide')) return Icons.support_agent_rounded;
  if (lower.contains('foto') || lower.contains('spot')) return Icons.camera_alt_rounded;
  if (lower.contains('camping') || lower.contains('kemah')) return Icons.cabin_rounded;
  return Icons.check_circle_outline_rounded;
}


// =============================================================================
// MODAL GEODE RANKING & PAPAN PERINGKAT SPASIAL (ITEM USE CASE DIAGRAM)
// =============================================================================
class _GeodeRankingModal extends StatefulWidget {
  final SavedDestinationModel? dest;
  const _GeodeRankingModal({this.dest});

  @override
  State<_GeodeRankingModal> createState() => _GeodeRankingModalState();
}

class _GeodeRankingModalState extends State<_GeodeRankingModal> {
  bool _isGpsCheckedIn = false;
  bool _isRecalculating = false;
  int _userGeodeScore = 2500;
  double _userGeodeDistanceKm = 465.4;

  void _verifyGpsCheckin() {
    setState(() {
      _isGpsCheckedIn = true;
      _userGeodeScore += 250;
      _userGeodeDistanceKm += 18.5;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Koordinat Geospasial Terverifikasi (<500m)! Skor Geode bertambah +250 GP.'),
        backgroundColor: AppColors.forest,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _recalculateGeodeRanking() {
    setState(() => _isRecalculating = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isRecalculating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Rekalkulasi Geode Ranking Berhasil! Seluruh data titik spasial GPS telah disinkronkan oleh Admin Dispar.'),
            backgroundColor: AppColors.forest,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final destName = widget.dest?.title ?? 'Kawasan Wisata Sumatera Barat';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sageBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.goldMinang, AppColors.warningDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geode Ranking Penjelajah',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                    Text(
                      'Papan Peringkat Spasial • Direkalkulasi oleh Admin Dispar',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User Geode Status Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.forest, AppColors.ink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('POSISI RANKING ANDA', style: TextStyle(fontSize: 11, color: AppColors.sage, fontWeight: FontWeight.w800)),
                        Text('Peringkat #3 Se-Sumbar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldMinang,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Tier Geode Platinum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('$_userGeodeScore GP', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.goldSoft)),
                        const Text('Skor Geode', style: TextStyle(fontSize: 11, color: AppColors.sage)),
                      ],
                    ),
                    Container(width: 1, height: 24, color: Colors.white24),
                    Column(
                      children: [
                        Text('${_userGeodeDistanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        const Text('Jarak Geodesik', style: TextStyle(fontSize: 11, color: AppColors.sage)),
                      ],
                    ),
                    Container(width: 1, height: 24, color: Colors.white24),
                    Column(
                      children: [
                        Text(_isGpsCheckedIn ? '10/10' : '9/10', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        const Text('Tertaklukkan', style: TextStyle(fontSize: 11, color: AppColors.sage)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Rekalkulasi Geode Ranking
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isRecalculating ? null : _recalculateGeodeRanking,
              icon: _isRecalculating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync_rounded, size: 16, color: AppColors.forest),
              label: Text(
                _isRecalculating ? 'Merekalkulasi Peringkat Geospasial...' : 'Rekalkulasi Geode Ranking Saya',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.forest),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.forest),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // GPS Proximity Check-in Box (jika dibuka pada destinasi tertentu)
          if (widget.dest != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isGpsCheckedIn ? AppColors.successBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isGpsCheckedIn ? AppColors.success : AppColors.warning,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGpsCheckedIn ? Icons.check_circle_rounded : Icons.my_location_rounded,
                    color: _isGpsCheckedIn ? AppColors.success : AppColors.warningDark,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isGpsCheckedIn ? 'Koordinat Spasial Terverifikasi' : 'Check-in Geospasial di Kawasan',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _isGpsCheckedIn ? AppColors.success : AppColors.warningDark,
                          ),
                        ),
                        Text(
                          _isGpsCheckedIn
                              ? 'Stempel check-in di $destName (+250 GP)'
                              : 'Berada di $destName (< 500m geofence)',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (!_isGpsCheckedIn)
                    ElevatedButton(
                      onPressed: _verifyGpsCheckin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Check-in', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Text(
            'PAPAN PERINGKAT SPASIAL (TOP 5):',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1),
          ),
          const SizedBox(height: 8),

          // Leaderboard List
          Expanded(
            child: ListView(
              children: [
                _buildRankRow(1, 'Rangkayo Sutan', '10/10 Destinasi', '520.4 km', '2.950 GP', 'Diamond', false),
                _buildRankRow(2, 'Pendekar Marapulai', '10/10 Destinasi', '498.1 km', '2.750 GP', 'Diamond', false),
                _buildRankRow(3, 'Anda (Wisatawan Teladan)', _isGpsCheckedIn ? '10/10 Destinasi' : '9/10 Destinasi', '${_userGeodeDistanceKm.toStringAsFixed(1)} km', '$_userGeodeScore GP', 'Platinum', true),
                _buildRankRow(4, 'Bundo Penjelajah', '8/10 Destinasi', '412.0 km', '2.200 GP', 'Gold', false),
                _buildRankRow(5, 'Petualang Singkarak', '7/10 Destinasi', '385.5 km', '1.950 GP', 'Gold', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(int rank, String name, String dest, String dist, String score, String tier, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.creamSubtle : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? AppColors.goldMinang : AppColors.sageBorder,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank == 1
                  ? AppColors.goldSoft
                  : rank == 2
                      ? const Color(0xFFB0B7BD)
                      : rank == 3
                          ? const Color(0xFFCD7F32)
                          : AppColors.cream,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: rank <= 3 ? Colors.white : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                          color: isMe ? AppColors.warningDark : AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.goldMinang,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Saya', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text('$dest • $dist', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.forest)),
              Text('Tier $tier', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
