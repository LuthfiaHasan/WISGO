import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/splash_screen.dart';
import '../../../fair_price/data/models/fair_price_tariff_model.dart';
import '../../../proposal/presentation/widgets/usul_destinasi_sheet.dart';
import '../../../qr_scanner/presentation/widgets/qr_scanner_sheet.dart';
import '../../../trip_planner/presentation/widgets/trip_planner_sheet.dart';
import '../../../reports/presentation/widgets/lapor_pungli_sheet.dart';
import '../../../fe1_visual_map/audio_guide_culture/audio_culture_screen.dart';
import '../../../fe1_visual_map/destination_detail/destination_detail_screen.dart';
import '../../../fe1_visual_map/hazard_alert_sos/hazard_sos_screen.dart';
import '../../../fe1_visual_map/map_explore_shunlu/map_explore_screen.dart';
import '../../../fe1_visual_map/map_explore_shunlu/widgets/sumbar_real_map_widget.dart';
import '../../../fe1_visual_map/models/destination_model.dart';
import '../../../fe1_visual_map/virtual_tour_360/virtual_tour_360_gallery_screen.dart';
import '../../../fe1_visual_map/virtual_tour_360/virtual_tour_360_screen.dart';
import '../../../booking/presentation/widgets/quick_booking_panel.dart';
import '../../../group_room/presentation/widgets/live_group_tracking_sheet.dart';
import '../../../passport/presentation/widgets/digital_passport_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/saved_empty_state.dart';

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

  const SavedPlacesScreen({
    super.key,
    this.initialOfflineMode = false,
    this.initialLoading = false,
    this.initialTabIndex = 0,
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

  // View 2: Real Interactive Sumbar Map State
  String? _selectedPetaDestinationId;

  // Navigation Items (5 Tabs: Beranda, Open Trip, Peta, Kamus Minang, Profil)
  static const List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Beranda',
      'labelEn': 'Home',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
    },
    {
      'label': 'Open Trip',
      'labelEn': 'Open Trip',
      'icon': Icons.groups_outlined,
      'activeIcon': Icons.groups_rounded,
    },
    {
      'label': 'Peta',
      'labelEn': 'Map',
      'icon': Icons.map_outlined,
      'activeIcon': Icons.map_rounded,
    },
    {
      'label': 'Kamus Minang',
      'labelEn': 'Dictionary',
      'icon': Icons.translate_rounded,
      'activeIcon': Icons.translate_rounded,
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
    {'key': 'Air Terjun', 'label': 'Air Terjun'},
    {'key': 'Gunung & Lembah', 'label': 'Gunung & Lembah'},
    {'key': 'Pantai & Bahari', 'label': 'Pantai & Bahari'},
    {'key': 'Nagari & Hutan Terpencil', 'label': 'Nagari & Hutan Terpencil'},
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
      'title': 'Permintaan Open Trip Disetujui!',
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



  // Profile Editable State (nullable agar aman saat Hot Reload)
  String? _profileName = 'Ahmad Fauzi';
  String? _profilePhone = '+62 812-7578-953';
  String? _profileRole = 'Wisatawan Nusantara';
  String? _profileOrigin = 'Padang, Sumatera Barat';

  String get _safeProfileName =>
      (_profileName?.trim().isNotEmpty ?? false) ? _profileName!.trim() : 'Ahmad Fauzi';
  String get _safeProfilePhone =>
      (_profilePhone?.trim().isNotEmpty ?? false) ? _profilePhone!.trim() : '+62 812-7578-953';
  String get _safeProfileRole =>
      (_profileRole?.trim().isNotEmpty ?? false) ? _profileRole!.trim() : 'Wisatawan Nusantara';
  String get _safeProfileOrigin =>
      (_profileOrigin?.trim().isNotEmpty ?? false) ? _profileOrigin!.trim() : 'Padang, Sumatera Barat';

  String get _safeProfileInitials {
    final parts = _safeProfileName.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'AF';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // Hero Landmark Slider & Explore Scroll State (nullable & lazy-init agar aman saat Hot Reload)
  PageController? _heroPageController;
  ScrollController? _exploreScrollController;
  GlobalKey? _wisataSectionKey;
  int? _heroSliderIndex = 0;
  Timer? _heroSliderTimer;

  PageController get _safeHeroPageController =>
      _heroPageController ??= PageController();

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
    return picked.isNotEmpty ? picked : kAllSumbarDestinations.take(5).toList();
  }

  @override
  void dispose() {
    _heroSliderTimer?.cancel();
    _heroPageController?.dispose();
    _exploreScrollController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    _isOfflineMode = widget.initialOfflineMode;
    _savedIds = List<String>.from(kDefaultSavedIds);
    if (widget.initialLoading) {
      _savedViewState = 'shimmer';
    }
    _heroSliderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final ctrl = _heroPageController;
      if (!mounted || ctrl == null || !ctrl.hasClients) return;
      final total = _heroLandmarks.length;
      if (total <= 1) return;
      final next = ((_heroSliderIndex ?? 0) + 1) % total;
      ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    });
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
                fontSize: 10,
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
      _activeTabIndex = 2; // Buka Peta Interaktif
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

                // Active Main View (5 Tabs: Beranda, Open Trip, Peta, Kamus Minang, Profil)
                Expanded(
                  child: IndexedStack(
                    index: _activeTabIndex.clamp(0, _navItems.length - 1),
                    children: [
                      _buildExploreView(),
                      _buildOpenTripView(),
                      _buildPetaView(),
                      const AudioCultureScreen(embedded: true),
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
      case 'Air Terjun':
        return Icons.water_drop_rounded;
      case 'Gunung & Lembah':
        return Icons.terrain_rounded;
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        fontSize: 10.5,
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
    final slides = _heroLandmarks;
    final activeIdx = (_heroSliderIndex ?? 0).clamp(0, slides.length - 1);
    final controller = _safeHeroPageController;
    return Column(
      children: [
        SizedBox(
          height: 222,
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: (idx) => setState(() => _heroSliderIndex = idx),
            itemBuilder: (context, idx) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _buildHeroLandmarkSlideItem(slides[idx], idx),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Minimalist High-Contrast Pill Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (idx) {
            final active = idx == activeIdx;
            return GestureDetector(
              onTap: () {
                if (controller.hasClients) {
                  controller.animateToPage(
                    idx,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.forest
                      : AppColors.ink.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroLandmarkSlideItem(SavedDestinationModel hero, int idx) {
    final badgeLabels = AppLocale.isEn
        ? [
            'MAIN LANDMARK',
            'GRANITE CLIFFS',
            'BUKITTINGGI ICON',
            'MARINE PARADISE',
            'MINANG HERITAGE',
          ]
        : [
            'LANDMARK UTAMA',
            'TEBING GRANIT',
            'IKON BUKITTINGGI',
            'SURGA BAHARI',
            'WARISAN MINANG',
          ];
    final temps = ['28°C', '24°C', '22°C', '29°C', '25°C'];
    final badgeText = badgeLabels[idx % badgeLabels.length];
    final tempText = temps[idx % temps.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.forest),
          Image.network(
            hero.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.forest),
          ),
          // Smooth Editorial Bottom Scrim
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF0A140D).withValues(alpha: 0.84),
                  const Color(0xFF0A140D).withValues(alpha: 0.24),
                  Colors.black.withValues(alpha: 0.06),
                ],
                stops: const [0.0, 0.56, 1.0],
              ),
            ),
          ),
          // Top Subtle Glass Pills: Location & Temperature
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${hero.region}, Sumbar',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            size: 12,
                            color: Color(0xFFFCD34D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tempText,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Hero Text + Clean Pure Frosted Glass Buttons
          Positioned(
            bottom: 14,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC85B2D),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${hero.distanceKm.toStringAsFixed(hero.distanceKm.truncateToDouble() == hero.distanceKm ? 0 : 1)} ${AppLocale.tr('km dari sini', 'km away')}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  hero.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.18,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Pure Frosted Glass Primary Button (Sleek, Clear Blur)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openDestinationDetailModal(hero),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.24),
                                      Colors.white.withValues(alpha: 0.13),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.34),
                                    width: 0.9,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocale.tr(
                                        'Lihat Destinasi',
                                        'View Destination',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Matching Pure Frosted Glass 360° Button
                    Tooltip(
                      message: 'Tur Virtual 360° & Denah',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _open360AndDenahModal(hero),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.24),
                                      Colors.white.withValues(alpha: 0.13),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.34),
                                    width: 0.9,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.threesixty_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
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
    );
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
        'onTap': _scrollToWisataSection,
      },
      {
        'label': AppLocale.tr('Peta', 'Map'),
        'fullTitle': AppLocale.tr('Peta Interaktif Sumbar', 'Interactive Map'),
        'subtitle': AppLocale.tr(
          'Peta GPS asli, rute Shunlu & pantauan kondisi jalur',
          'Real GPS map, Shunlu routes & road monitor',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.map_rounded,
        'onTap': () => setState(() => _activeTabIndex = 2),
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
        'label': AppLocale.tr('Simpan', 'Saved'),
        'fullTitle': AppLocale.tr('Destinasi Tersimpan', 'Saved Places'),
        'subtitle': AppLocale.tr(
          'Akses cepat daftar tempat wisata favorit Anda',
          'Quick access to your bookmarked destinations',
        ),
        'section': 'Eksplorasi & Navigasi',
        'icon': Icons.bookmark_rounded,
        'onTap': _openSavedPlacesModal,
      },
      {
        'label': AppLocale.tr('Darurat', 'Emergency'),
        'fullTitle': AppLocale.tr('Darurat & Radar SOS', 'Emergency & SOS'),
        'subtitle': AppLocale.tr(
          'Lapor bahaya jalur, kontak darurat & posko terdekat',
          'Hazard alerts, emergency contacts & nearest posts',
        ),
        'section': 'Budaya, Keamanan & Paspor',
        'icon': Icons.local_hospital_rounded,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HazardSosScreen()),
            ),
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
        'onTap': () => setState(() => _activeTabIndex = 3),
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
        'onTap': _openDigitalPassportModal,
      },
    ];
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
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _buildAllCategorySection(
                pageCtx: pageCtx,
                title: AppLocale.tr(
                  'Eksplorasi & Navigasi',
                  'Explore & Navigation',
                ),
                items: exploreItems,
              ),
              const SizedBox(height: 20),
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
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, idx) {
            final item = items[idx];
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  Navigator.pop(pageCtx);
                  (item['onTap'] as VoidCallback)();
                },
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warmBorder.withValues(alpha: 0.85),
                        ),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: 25,
                        color: const Color(0xFF3E4740),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
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
    // Tampilkan 4 kategori utama + 1 tombol "Lainnya" (total 5 item rata penuh tanpa geser)
    final primaryFour = [
      allItems[0], // Wisata
      allItems[3], // Simpan (Destinasi Tersimpan)
      allItems[2], // Tur 360°
      allItems[4], // Darurat
    ];
    final rowItems = <Map<String, dynamic>>[
      ...primaryFour,
      {
        'label': AppLocale.tr('Lainnya', 'More'),
        'icon': Icons.grid_view_rounded,
        'onTap': _openAllCategoriesPage,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 12),
        // 5 item rata penuh (4 kategori utama + Lainnya) — bersih tanpa geser
        Row(
          children: rowItems.map((item) {
            return Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: item['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 23,
                          color: const Color(0xFF475049),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475049),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Divider(
          height: 1,
          thickness: 1,
          color: AppColors.warmBorder.withValues(alpha: 0.65),
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
                  backgroundColor: Color(0xFF16A34A),
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
                child: GestureDetector(
                  onTap: () => _openDestinationDetailModal(place),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.warmBorder.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 112,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(color: AppColors.forest),
                              Image.network(
                                place.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppColors.forest),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.58),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${place.rating}',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _toggleBookmark(place.id),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isBookmarked
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      size: 14,
                                      color: isBookmarked
                                          ? const Color(0xFFD97706)
                                          : AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 7,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i == 0
                                        ? const Color(0xFFC85B2D)
                                        : AppColors.forest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    place.natureType,
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${place.distanceKm.toStringAsFixed(place.distanceKm.truncateToDouble() == place.distanceKm ? 0 : 1)} km • ${place.region}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.sage,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      AppLocale.tr(
                                        'Ikonik Sumbar',
                                        'Iconic Sumbar',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: AppColors.forest,
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
          }),
        ),
      ],
    );
  }

  Widget _buildWeatherConditionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142E1B), Color(0xFF1D4327)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142E1B).withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                      children: [
                        const Icon(
                          Icons.wb_cloudy_rounded,
                          size: 12,
                          color: Color(0xFFFCD34D),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            AppLocale.tr(
                              'CUACA & KONDISI UDARA',
                              'WEATHER & AIR CONDITIONS',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: Color(0xFFA7D3B4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocale.tr(
                        'Kota Padang, Sumbar',
                        'Padang City, West Sumatra',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '28°C',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFCD34D),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocale.tr('Cerah Berawan', 'Partly Cloudy'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD1E7D7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWeatherMiniStat(
                  icon: Icons.water_drop_outlined,
                  label: AppLocale.tr('Kelembaban', 'Humidity'),
                  value: '82%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWeatherMiniStat(
                  icon: Icons.air_rounded,
                  label: AppLocale.tr('Kec. Angin', 'Wind Speed'),
                  value: AppLocale.tr('11 km/j', '11 km/h'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWeatherMiniStat(
                  icon: Icons.visibility_outlined,
                  label: AppLocale.tr('Pandangan', 'Visibility'),
                  value: '10 km',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFCD34D)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB5D4BE),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
          item.natureType == _currentExploreType;
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
                                      : const Color(0xFF16A34A),
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
                                    fontSize: 10,
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

                  // 1. SCAN CHECK-IN TIBA DI LOKASI
                  Tooltip(
                    message: 'Scan Check-in Tiba di Lokasi',
                    child: Material(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _openQrScannerModal,
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6.5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 14,
                                color: AppColors.cream,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Check-in',
                                style: TextStyle(
                                  fontSize: 10.5,
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
                  const SizedBox(width: 6),

                  // 2. Siaga SOS
                  Tooltip(
                    message: 'Darurat SOS & Jalur Rawan',
                    child: Material(
                      color: const Color(0xFFFEE2E2),
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
                              color: const Color(0xFFB91C1C)
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.sos_rounded,
                            size: 15,
                            color: Color(0xFFB91C1C),
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
                                      color: const Color(0xFFDC2626),
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
                                        fontSize: 8.5,
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

                    // 7. Filter Wilayah (Clean Rounded Pills)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _exploreRegions.map((reg) {
                          final isSelected =
                              _currentExploreRegion == reg['key'];
                          final regLabel = reg['key'] == 'ALL'
                              ? AppLocale.tr('Semua Daerah', 'All Regions')
                              : reg['key'] == 'Daerah Terpencil'
                                  ? AppLocale.tr(
                                      'Daerah Terpencil',
                                      'Remote Areas',
                                    )
                                  : reg['title']!;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _currentExploreRegion = reg['key']!,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.forest
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.forest
                                        : AppColors.warmBorder,
                                  ),
                                ),
                                child: Text(
                                  regLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.cream
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 7),

                    // 8. Filter Kategori Alam Berikon
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _exploreTypes.map((type) {
                          final isSelected = _currentExploreType == type['key'];
                          String typeLabel = type['label']!;
                          if (AppLocale.isEn) {
                            switch (type['key']) {
                              case 'ALL':
                                typeLabel = 'All Categories';
                                break;
                              case 'Air Terjun':
                                typeLabel = 'Waterfalls';
                                break;
                              case 'Gunung & Lembah':
                                typeLabel = 'Mountains & Valleys';
                                break;
                              case 'Pantai & Bahari':
                                typeLabel = 'Beaches & Marine';
                                break;
                              case 'Nagari & Hutan Terpencil':
                                typeLabel = 'Remote Villages';
                                break;
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _currentExploreType = type['key']!,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.sage
                                      : AppColors.creamSubtle,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.forest
                                            .withValues(alpha: 0.35)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryChipIcon(type['key']!),
                                      size: 12,
                                      color: isSelected
                                          ? AppColors.forest
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.forest
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDestinationCard(
                          filtered[index],
                          isSavedContext: false,
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),

            // 9. Kartu Budaya "Tahukah Kamu?" + Ruang Scroll Aman di atas FAB & Tab Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 168),
                child: _buildTahukahKamuCard(),
              ),
            ),
          ],
        ),

        // Floating Action Button bergaya Frosted Glass Blur di atas floating bottom bar transparan
        Positioned(
          bottom: MediaQuery.paddingOf(context).bottom + 102,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.24),
                  blurRadius: 16,
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
                              fontSize: 11.5,
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
  Widget _buildOpenTripView() {
    return Column(
      children: [
        // Top Sticky Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                        'KOLABORASI & CARI BARENGAN',
                        'COLLABORATION & TRAVEL BUDDIES',
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: Color(0xFF1E5B82),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr(
                        'Open Trip Sumbar',
                        'West Sumatra Open Trips',
                      ),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E5B82).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF1E5B82)),
                    const SizedBox(width: 4),
                    Text(
                      AppLocale.tr('3 Trip Aktif', '3 Active Trips'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E5B82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 116),
            children: [
              // 1. PUBLIC OPEN TRIP BOARD
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.sageBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.06),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1F8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF1E5B82).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.group_add_rounded, size: 13, color: Color(0xFF1E5B82)),
                              const SizedBox(width: 4),
                              Text(
                                AppLocale.tr('OPEN TRIP TERBUKA', 'OPEN GROUP TRIPS'),
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF1E5B82)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            AppLocale.tr('Kuota Tersedia', 'Spots Available'),
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocale.tr(
                        'Daftar Open Trip Terbuka (Cari Barengan)',
                        'Available Open Group Trips',
                      ),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocale.tr(
                        'Gabung open trip untuk patungan sewa mobil, tour guide nagari, dan nikmati serunya jelajah Sumbar bersama wisatawan lain.',
                        'Join open group trips to share car rental, local village guides, and explore West Sumatra with fellow travelers.',
                      ),
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF5A6B5D)),
                    ),
                    const SizedBox(height: 12),
                    // Trip 1
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Eksplor Harau & Batang Tabik',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                                ),
                                Text(
                                  'Sabtu, 21 Nov 2026 • Kuota: 4/6 org • Rp 120rb/org',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _openTripPlannerModal,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(AppLocale.tr('Gabung', 'Join'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Trip 2
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E5B82),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.sailing_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Island Hopping Mandeh & Snorkeling',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                                ),
                                Text(
                                  'Minggu, 22 Nov 2026 • Kuota: 6/10 org • Rp 175rb/org',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _openTripPlannerModal,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1E5B82),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(AppLocale.tr('Gabung', 'Join'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Trip 3
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC89242),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nagari Pariangan & Istano Pagaruyung',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                                ),
                                Text(
                                  'Sabtu, 28 Nov 2026 • Kuota: 3/5 org • Rp 95rb/org',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _openTripPlannerModal,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFC89242),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(AppLocale.tr('Gabung', 'Join'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openTripPlannerModal,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          AppLocale.tr(
                            '+ Buat Jadwal Open Trip Baru',
                            '+ Create New Open Trip',
                          ),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.forest, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Feature Card: Smart Trip Planner
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF193D22), Color(0xFF2F663E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF193D22).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.cream),
                              SizedBox(width: 4),
                              Text(
                                'Smart Trip Planner',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cream,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.alt_route_rounded, color: AppColors.sage, size: 22),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocale.tr(
                        'Rencana Perjalanan Otomatis 1–7 Hari',
                        'Automated 1–7 Day Travel Itinerary',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocale.tr(
                        'Susun jadwal liburan otomatis berdasarkan durasi hari, estimasi anggaran per orang, dan minat wisata rombongan (Alam, Kuliner, Adat).',
                        'Automatically plan your trip based on duration, estimated budget per person, and interests (Nature, Culinary, Heritage).',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _openTripPlannerModal,
                      icon: const Icon(Icons.calendar_today_rounded, size: 15),
                      label: Text(
                        AppLocale.tr(
                          'Buka Trip Planner & Estimasi Anggaran',
                          'Open Trip Planner & Budget Estimator',
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.forest,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Feature Card: Kalender Event & Budaya Sumbar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_available_rounded, size: 13, color: Color(0xFF5A3E85)),
                              SizedBox(width: 4),
                              Text(
                                'Agenda & Event',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5A3E85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF5A3E85)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocale.tr(
                        'Kalender Event & Festival Budaya',
                        'Cultural Events & Festivals Calendar',
                      ),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocale.tr(
                        'Lihat jadwal festival budaya, pertunjukan kesenian randai, pacu jawi, dan agenda wisata tahunan resmi di Sumatera Barat.',
                        'Discover cultural festivals, Randai performances, Pacu Jawi, and official annual tourism events in West Sumatra.',
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openKalenderBudayaModal,
                        icon: const Icon(Icons.event_note_rounded, size: 16),
                        label: Text(
                          AppLocale.tr(
                            'Buka Kalender Event',
                            'Open Events Calendar',
                          ),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3E85),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                                fontSize: 9.5,
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
  static final List<Map<String, dynamic>> _budayaFestivals = [
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                                fontSize: 9.5,
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
                                              fontSize: 9.5,
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
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.notifications_active_rounded, size: 10, color: Color(0xFF15803D)),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Pengingat Aktif',
                                                      style: TextStyle(
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFF15803D),
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
                                                fontSize: 10.5,
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
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.forest,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Text(
                                            'Lihat Detail & Rute',
                                            style: TextStyle(
                                              fontSize: 10,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                                  fontSize: 10,
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
                              color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
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
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        ev['tips'] as String,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF78350F),
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
                                    color: isReminded ? const Color(0xFF15803D) : AppColors.ink,
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
                                            color: isReminded ? const Color(0xFF15803D) : AppColors.ink,
                                          ),
                                        ),
                                        Text(
                                          isReminded
                                              ? 'Anda akan menerima notifikasi otomatis di hari acara.'
                                              : 'Dapatkan pemberitahuan otomatis saat mendekati jadwal festival.',
                                          style: const TextStyle(
                                            fontSize: 10,
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
                                    setState(() {
                                      if (isReminded) {
                                        _remindedFestivalIds.remove(ev['id']);
                                      } else {
                                        _remindedFestivalIds.add(ev['id'] as String);
                                        // Tambahkan notifikasi pengingat ke daftar notifikasi aplikasi
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
                                    setDetailState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isReminded
                                              ? 'Pengingat untuk ${ev['title']} telah dinonaktifkan.'
                                              : 'Pengingat aktif! Notifikasi pengingat untuk ${ev['title']} telah dijadwalkan.',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                        backgroundColor: isReminded ? AppColors.ink : AppColors.forest,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    isReminded ? Icons.check_circle_rounded : Icons.add_alert_rounded,
                                    size: 16,
                                    color: isReminded ? const Color(0xFF15803D) : AppColors.forest,
                                  ),
                                  label: Text(
                                    isReminded ? 'Pengingat Aktif (Ketuk untuk Batalkan)' : 'Aktifkan Pengingat Acara',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isReminded ? const Color(0xFF15803D) : AppColors.forest,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isReminded ? const Color(0xFF15803D) : AppColors.forest,
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_unreadNotificationCount Baru',
                                  style: const TextStyle(
                                    fontSize: 9.5,
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
                                  iconBg = const Color(0xFFDCFCE7);
                                  break;
                                case 'passport':
                                  notifIcon = Icons.verified_rounded;
                                  iconColor = const Color(0xFF1E5B82);
                                  iconBg = const Color(0xFFE8F1F8);
                                  break;
                                case 'weather':
                                  notifIcon = Icons.wb_sunny_rounded;
                                  iconColor = const Color(0xFFD97706);
                                  iconBg = const Color(0xFFFEF3C7);
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
                                                          color: Color(0xFFDC2626),
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
                                                        fontSize: 9.5,
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
                                                              fontSize: 10,
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
        // Top Sticky Header Peta
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                        'SISTEM INFORMASI GEOGRAFIS & SPASIAL',
                        'GEOGRAPHIC & SPATIAL INFORMATION',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AppColors.brush,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr(
                        'Peta Wisata Interaktif Sumbar',
                        'Interactive West Sumatra Map',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 13, color: AppColors.forest),
                    const SizedBox(width: 4),
                    Text(
                      AppLocale.tr('GPS Aktif', 'GPS Active'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable Peta Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 116),
            children: [
              // 1. REAL INTERACTIVE SUMBAR MAP (flutter_map + Carto Voyager / Esri Satellite / Esri Topo)
              SumbarRealMapWidget(
                height: 315,
                selectedDestinationId: _selectedPetaDestinationId,
                onDestinationSelected: (dest) {
                  setState(() => _selectedPetaDestinationId = dest.id);
                },
                onOpenFullShunlu: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MapExploreShunluScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Hero Launcher Strip: Peta Rute & Titik Singgah (Shunlu)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapExploreShunluScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.forest, Color(0xFF153017)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.alt_route_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocale.tr(
                                  'Peta Rute & Titik Singgah',
                                  'Route & Pit-Stop Map',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocale.tr(
                                  'Cari RM Padang, SPBU, Masjid & ATM searah rute',
                                  'Find Padang restaurants, fuel, mosques & ATMs en route',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFD8E6D9),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocale.tr('Buka', 'Open'),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.forest,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Two-Column Quick Spatial Actions (Radar Rombongan & Lapor Pungli)
              Row(
                children: [
                  Expanded(
                    child: _buildPetaQuickToolCard(
                      icon: Icons.radar_rounded,
                      iconBg: const Color(0xFFE6F0FA),
                      iconColor: const Color(0xFF1E5B82),
                      title: AppLocale.tr('Radar Grup', 'Group Radar'),
                      subtitle: AppLocale.tr(
                        'Pantau GPS rombongan',
                        'Track group live GPS',
                      ),
                      onTap: _openLiveGroupTrackingModal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPetaQuickToolCard(
                      icon: Icons.shield_outlined,
                      iconBg: const Color(0xFFFEF3D6),
                      iconColor: const Color(0xFFB45309),
                      title: AppLocale.tr('Aduan Jalur', 'Route Report'),
                      subtitle: AppLocale.tr(
                        'Pungli & jalan rusak',
                        'Illegal fees & road hazards',
                      ),
                      onTap: () => _openLaporPungliModal(tab: 'pungli'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 4. Horizontal Carousel: Destinasi Terdekat dari Lokasi Anda
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocale.tr(
                      'Terdekat dari Lokasimu',
                      'Nearest to Your Location',
                    ),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final dest = kSumbarMapDestinations[index];
                    final isSelected = _selectedPetaDestinationId == dest.id;
                    return GestureDetector(
                      onTap: () => setState(
                        () => _selectedPetaDestinationId = dest.id,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 208,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF1F7F2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.forest
                                : AppColors.warmBorder,
                            width: isSelected ? 1.8 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(
                                alpha: isSelected ? 0.08 : 0.04,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: dest.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${dest.distanceLabel} • ${dest.durationLabel}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: dest.color,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: dest.color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    dest.icon,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              dest.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dest.region,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.route_rounded,
                                  size: 13,
                                  color: AppColors.forest,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSelected
                                      ? AppLocale.tr(
                                          'Ditampilkan di peta',
                                          'Shown on map',
                                        )
                                      : AppLocale.tr(
                                          'Lihat rute di peta',
                                          'View route on map',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              // 5. Compact 2x2 Grid: Pantauan Jalur Utama Sumbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocale.tr(
                      'Pantauan Jalur Utama',
                      'Main Route Monitor',
                    ),
                    style: const TextStyle(
                      fontSize: 15.5,
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
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sos_rounded,
                            size: 12,
                            color: Color(0xFFB91C1C),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Radar SOS →',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      dotColor: const Color(0xFF16A34A),
                      badgeBg: const Color(0xFFDCFCE7),
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
                      dotColor: const Color(0xFF16A34A),
                      badgeBg: const Color(0xFFDCFCE7),
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
                      dotColor: const Color(0xFFD97706),
                      badgeBg: const Color(0xFFFEF3C7),
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
                      dotColor: const Color(0xFF16A34A),
                      badgeBg: const Color(0xFFDCFCE7),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                        fontSize: 10,
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
                            fontSize: 9.5,
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
                      fontSize: 10.5,
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
                  fontSize: 10,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
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
                  Image.network(
                    place.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.forest),
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
                                fontSize: 10,
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
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.creamSubtle,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.warmBorder
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _getFacilityIcon(fac),
                                        size: 14,
                                        color: AppColors.forest,
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
                          fontSize: 10.5,
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
                                AppLocale.tr('360° & Denah', '360° & Map'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DestinationDetailSheet(
          place: place,
          isBookmarked: _savedIds.contains(place.id),
          onToggleBookmark: () {
            _toggleBookmark(place.id);
          },
          onOpen360: () {
            Navigator.pop(ctx);
            _open360AndDenahModal(place);
          },
          onOpenBarometer: () {
            Navigator.pop(ctx);
            _openPlaceBarometer(place.baroIndex);
          },
          onCheckout: (total, breakdown) {
            Navigator.pop(ctx);
            _openWhatsAppVendorDialog(place);
          },
        );
      },
    );
  }

  // Catatan: Transaksi resmi in-app ditiadakan sesuai regulasi sistem, dialihkan langsung ke WhatsApp Vendor resmi.

  // ===========================================================================
  // MODAL 4: PEMINDAIAN PLANG SMART QR WISATA (ITEM 8)
  // ===========================================================================
  void _openQrScannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QrScannerSheet(),
    );
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
  // MODAL 6: LAYAR 06 TRIP PLANNER & KAPASITAS ORANG (ITEM 10 & 12)
  // ===========================================================================
  void _openTripPlannerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TripPlannerSheet(),
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
                color: const Color(0xFFFEF3D6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Usulan Terdaftar ke Dispar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
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
                color: const Color(0xFFFEF3D6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD97706)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 6),
                  Text(
                    'Status: Menunggu Verifikasi Admin',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Destinasi: "$name"',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF142618)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Usulan destinasi hidden gem Anda berhasil diajukan ke Dinas Pariwisata Sumbar.',
              style: TextStyle(fontSize: 11, color: Color(0xFF5A6B5D), height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3D6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📢 Catatan Validasi: Destinasi baru ini hanya akan resmi tampil di aplikasi wisata setelah diverifikasi dan divalidasi oleh Admin Dispar Sumbar.',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF78350F), height: 1.35),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF193D22),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Mengerti & Pantau Status'),
          ),
        ],
      ),
    );
  }

  void _openWhatsAppVendorDialog(SavedDestinationModel place) {
    final message = 'Halo Pengelola ${place.title}, saya ingin memesan tiket dan parkir resmi sesuai tarif Perda Sumbar. Mohon info ketersediaan slot reservasi.';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pesan via WhatsApp Vendor',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                      ),
                      Text(
                        'Pengelola / Pokdarwis: +62 812-7578-953',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brush),
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
                color: const Color(0xFFF5FAF6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destinasi: ${place.title}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF193D22)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perda Acuan: ${place.perdaRef}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF5A6B5D)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Format Pesan Siap Kirim:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF142618)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAppToast('Membuka WhatsApp Pengelola ${place.title} (+62 812-7578-953)...');
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Kirim Pesan WhatsApp Vendor (+62 812-7578-953)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message));
                  _showAppToast('Format pesan berhasil disalin ke clipboard!');
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Salin Format Pesan WhatsApp'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forest,
                  side: const BorderSide(color: AppColors.forest, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getFacilityIcon(facName), size: 20, color: AppColors.cream),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMASI FASILITAS LINGKUNGAN',
                            style: TextStyle(
                              fontSize: 9.5,
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
                        const Text('Kawasan Wisata:', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Terverifikasi Perda', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.forest)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const Divider(height: 16, color: AppColors.warmBorder),
                    const Text('Keterangan & Standar Layanan:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest)),
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
                        style: TextStyle(fontSize: 9.5, color: AppColors.forest, fontWeight: FontWeight.w600),
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

  // MODAL: EDIT PROFIL WISATAWAN
  void _openEditProfileModal() {
    final nameCtrl = TextEditingController(text: _safeProfileName);
    final phoneCtrl = TextEditingController(text: _safeProfilePhone);
    final originCtrl = TextEditingController(text: _safeProfileOrigin);
    String selectedRole = _safeProfileRole;

    const roles = [
      'Wisatawan Nusantara',
      'Wisatawan Lokal Sumbar',
      'International Traveler',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final previewName = nameCtrl.text.trim().isEmpty
                ? 'AF'
                : nameCtrl.text.trim();
            final parts = previewName
                .split(RegExp(r'\s+'))
                .where((e) => e.isNotEmpty)
                .toList();
            final previewInitials = parts.length > 1
                ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
                : parts.first
                    .substring(0, parts.first.length >= 2 ? 2 : 1)
                    .toUpperCase();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(modalCtx).bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocale.tr('Edit Profil', 'Edit Profile'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.forest, Color(0xFF153017)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            previewInitials,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocale.tr('Nama Lengkap', 'Full Name'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: AppLocale.tr(
                            'Masukkan nama lengkap',
                            'Enter full name',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocale.tr('Nomor WhatsApp', 'WhatsApp Number'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: '+62 812-xxxx-xxxx',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocale.tr('Kota Asal', 'Home City'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: originCtrl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: AppLocale.tr(
                            'Contoh: Padang, Sumatera Barat',
                            'e.g. Padang, West Sumatra',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocale.tr('Kategori Wisatawan', 'Traveler Type'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: roles.map((role) {
                          final active = selectedRole == role;
                          return ChoiceChip(
                            label: Text(
                              role,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: active ? AppColors.cream : AppColors.ink,
                              ),
                            ),
                            selected: active,
                            selectedColor: AppColors.forest,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: active
                                  ? AppColors.forest
                                  : AppColors.warmBorder,
                            ),
                            onSelected: (_) {
                              setModalState(() => selectedRole = role);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _profileName = nameCtrl.text.trim().isEmpty
                                  ? _safeProfileName
                                  : nameCtrl.text.trim();
                              _profilePhone = phoneCtrl.text.trim().isEmpty
                                  ? _safeProfilePhone
                                  : phoneCtrl.text.trim();
                              _profileOrigin = originCtrl.text.trim().isEmpty
                                  ? _safeProfileOrigin
                                  : originCtrl.text.trim();
                              _profileRole = selectedRole;
                            });
                            Navigator.pop(ctx);
                            _showAppToast(
                              AppLocale.tr(
                                'Profil berhasil diperbarui',
                                'Profile updated successfully',
                              ),
                            );
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
                            AppLocale.tr('Simpan Perubahan', 'Save Changes'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // VIEW 3: PROFIL WISATAWAN & PENGATURAN AKUN
  // ===========================================================================
  Widget _buildProfileView() {
    return Column(
      children: [
        // Sticky Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                  children: [
                    Text(
                      AppLocale.tr('AKUN WISATAWAN', 'TRAVELER ACCOUNT'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AppColors.brush,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr('Profil Saya', 'My Profile'),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocale.tr('Terverifikasi', 'Verified'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
            children: [
              // 1. Hero Identity Card (Clean & Modern + Tombol Edit Profil)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.warmBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.forest, Color(0xFF153017)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.forest.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _safeProfileInitials,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cream,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -3,
                              bottom: -3,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _safeProfileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Material(
                                    color: AppColors.creamSubtle,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      onTap: _openEditProfileModal,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.warmBorder,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 13,
                                              color: AppColors.forest,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Edit',
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
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_safeProfilePhone • $_safeProfileOrigin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.sage,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _safeProfileRole,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3D6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'OTP WhatsApp',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFB45309),
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
                    const SizedBox(height: 16),
                    // 3 Interactive Mini Metric Tiles
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfileMetricTile(
                            icon: Icons.bookmark_rounded,
                            iconColor: AppColors.forest,
                            value: '${_savedIds.length}',
                            label: AppLocale.tr('Tersimpan', 'Saved'),
                            onTap: () => setState(() => _activeTabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProfileMetricTile(
                            icon: Icons.military_tech_rounded,
                            iconColor: const Color(0xFFB45309),
                            value: '4 / 10',
                            label: AppLocale.tr('Stempel', 'Stamps'),
                            onTap: _openDigitalPassportModal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProfileMetricTile(
                            icon: Icons.gps_fixed_rounded,
                            iconColor: const Color(0xFF1E5B82),
                            value: AppLocale.tr('Aktif', 'Active'),
                            label: 'GPS Sumbar',
                            onTap: () => setState(() => _activeTabIndex = 2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. PASPOR DIGITAL MINANG (Refined Luxury Card + Fixed 40% Progress)
              Container(
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
                            color: const Color(0xFFC89242).withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE5C07B).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            AppLocale.tr(
                              'PASPOR DIGITAL MINANG',
                              'MINANG DIGITAL PASSPORT',
                            ),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Color(0xFFE5C07B),
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
                            color: Color(0xFFE5C07B),
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
                    // Progress bar (4/10 = 40% akurat!)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocale.tr(
                            '4 dari 10 Destinasi Nagari',
                            '4 of 10 Village Destinations',
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE5C07B),
                          ),
                        ),
                        const Text(
                          '40%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(99)),
                      child: LinearProgressIndicator(
                        value: 0.40,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE5C07B),
                        ),
                        minHeight: 6,
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
                                color: const Color(0xFFE5C07B)
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
              ),

              const SizedBox(height: 22),

              // 3. Pengaturan & Pintasan Fitur (Apple Settings Clean Style)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  AppLocale.tr('Pengaturan & Perangkat', 'Settings & Device'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warmBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pilihan Bahasa Sistem (ID / EN)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1F8),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.language_rounded,
                              size: 20,
                              color: Color(0xFF1E5B82),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocale.tr(
                                    'Bahasa Aplikasi',
                                    'App Language',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  AppLocale.tr(
                                    'Bahasa Indonesia / English',
                                    'Indonesian / English',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const LanguageTogglePill(),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: AppColors.warmBorder,
                    ),
                    // Mode Luring Toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _isOfflineMode
                                  ? const Color(0xFFFEF3D6)
                                  : AppColors.sage,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              _isOfflineMode
                                  ? Icons.cloud_off_rounded
                                  : Icons.offline_pin_rounded,
                              size: 20,
                              color: _isOfflineMode
                                  ? const Color(0xFFB45309)
                                  : AppColors.forest,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocale.tr(
                                    'Mode Tanpa Sinyal (Luring)',
                                    'Offline Mode',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  _isOfflineMode
                                      ? AppLocale.tr(
                                          'Aktif • Menggunakan cache perangkat',
                                          'Active • Using local device cache',
                                        )
                                      : AppLocale.tr(
                                          'Siap siaga untuk area blank spot',
                                          'Ready for no-signal mountain routes',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
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
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: AppColors.warmBorder,
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.record_voice_over_rounded,
                      iconBg: const Color(0xFFFEF3D6),
                      iconColor: const Color(0xFFB45309),
                      title: AppLocale.tr(
                        'Kamus Minang & Kalender Budaya',
                        'Minang Dictionary & Culture Calendar',
                      ),
                      subtitle: AppLocale.tr(
                        'Audio frasa lokal & jadwal tradisi nagari',
                        'Local audio phrases & village festivals',
                      ),
                      onTap: () => setState(() => _activeTabIndex = 3),
                    ),
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: AppColors.warmBorder,
                    ),
                    _buildProfileMenuTile(
                      icon: Icons.sos_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFB91C1C),
                      title: AppLocale.tr(
                        'Radar Jalur Rawan & Darurat SOS',
                        'Hazard Radar & Emergency SOS',
                      ),
                      subtitle: AppLocale.tr(
                        'Hotline 115/112 & kirim titik koordinat GPS',
                        '115/112 hotline & share GPS coordinates',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HazardSosScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4. Clean Consumer Logout Button
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
                                    color: const Color(0xFF8B2B38).withValues(alpha: 0.16),
                                    width: 1.2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Color(0xFF8B2B38),
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
                                              const Color(0xFF8B2B38),
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
                    AppLocale.tr('Keluar dari Akun', 'Sign Out'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFAF2F3),
                    foregroundColor: const Color(0xFF8B2B38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: const Color(0xFF8B2B38).withValues(alpha: 0.18),
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
                    fontSize: 10.5,
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
  }

  Widget _buildProfileMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
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
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClean4ButtonBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: SizedBox(
          height: 78,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const double horizontalInset = 12.0;
              final usableWidth =
                  (totalWidth - (horizontalInset * 2)).clamp(1.0, totalWidth);
              final safeIndex = _activeTabIndex.clamp(0, _navItems.length - 1);
              final itemWidth = usableWidth / _navItems.length;
              final targetCenterX =
                  horizontalInset + (itemWidth * safeIndex) + (itemWidth / 2);

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: targetCenterX),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, animatedCenterX, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Curved Bar Surface with Smooth Concave Notch
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CurvedNotchBarPainter(
                            notchCenterX: animatedCenterX,
                          ),
                        ),
                      ),

                      // 2. Floating Active Circle Icon inside the Notch
                      Positioned(
                        top: -6,
                        left: animatedCenterX - 24,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.forest,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forest.withValues(alpha: 0.22),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _navItems[safeIndex]['activeIcon']
                                  as IconData,
                              size: 20,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ),

                      // 3. 5 Navigation Columns
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            horizontalInset,
                            14,
                            horizontalInset,
                            13,
                          ),
                          child: Row(
                            children: List.generate(_navItems.length, (idx) {
                              final isSelected = idx == safeIndex;
                              final item = _navItems[idx];

                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() => _activeTabIndex = idx);
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        opacity: isSelected ? 0.0 : 1.0,
                                        child: Icon(
                                          item['icon'] as IconData,
                                          size: 20,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            AppLocale.isEn
                                                ? (item['labelEn'] as String)
                                                : (item['label'] as String),
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.forest
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                            width: 112,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.forest.withValues(alpha: 0.35),
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
/// di posisi tab yang sedang aktif (1:1 sesuai Gambar 2).
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
    const double cornerRadius = 18.0;
    const double minTopCorner = 8.0;
    const double maxNotchHalfWidth = 35.0;
    const double notchDepth = 47.0;

    // Pastikan pusat lekukan selalu tepat di tengah lingkaran aktif (termasuk Tab 0 & Tab 4)
    final double cx = notchCenterX.clamp(
      minTopCorner + 24.0,
      w - minTopCorner - 24.0,
    );
    final double maxLeftHalf =
        (cx - minTopCorner).clamp(24.0, maxNotchHalfWidth);
    final double maxRightHalf =
        ((w - minTopCorner) - cx).clamp(24.0, maxNotchHalfWidth);
    final double notchHalfWidth =
        maxLeftHalf < maxRightHalf ? maxLeftHalf : maxRightHalf;

    final double nStart = cx - notchHalfWidth;
    final double nEnd = cx + notchHalfWidth;
    final double leftTopRadius = nStart < cornerRadius ? nStart : cornerRadius;
    final double rightTopRadius =
        (w - nEnd) < cornerRadius ? (w - nEnd) : cornerRadius;
    final double ctrlOuter = notchHalfWidth * 0.70;
    final double ctrlInner = notchHalfWidth * 0.68;

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

    // Soft Drop Shadow
    canvas.drawShadow(
      path,
      AppColors.forest.withValues(alpha: 0.18),
      12.0,
      false,
    );

    // White Fill
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Subtle Border
    final borderPaint = Paint()
      ..color = AppColors.sageBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
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

class _Facility360Data {
  final String category;
  final String title;
  final String label;
  final String imageUrl;
  final String badge;
  final String description;
  final String subDetail;
  final double yaw;
  final IconData icon;

  const _Facility360Data({
    required this.category,
    required this.title,
    required this.label,
    required this.imageUrl,
    required this.badge,
    required this.description,
    required this.subDetail,
    required this.yaw,
    required this.icon,
  });
}

const List<_Facility360Data> _k360Facilities = [
  _Facility360Data(
    category: 'PARKIR',
    title: 'Tempat Parkir Resmi Kendaraan',
    label: 'Tempat Parkir',
    imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=800&q=80',
    badge: 'Parkir Resmi Pokdarwis',
    description: 'Area parkir beratap pepohonan rindang dengan penjagaan pemuda nagari. Karcis resmi sesuai Perda tanpa pungli liar.',
    subDetail: 'Kapasitas 40 Mobil & 120 Motor • Karcis Resmi Rp 5.000 / Rp 10.000',
    yaw: -70.0,
    icon: Icons.local_parking_rounded,
  ),
  _Facility360Data(
    category: 'UMKM',
    title: 'Warung Kuliner UMKM Tradisional Minang',
    label: 'UMKM Kuliner Minang',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
    badge: 'Kuliner Nagari • Standar Tarif',
    description: 'Menyajikan hidangan lokal nagari: Nasi Kapau, sate lokan, kelapa muda murni segar, dan gorengan hangat dengan daftar menu berharga pasti.',
    subDetail: 'Menu Transparan • Kelapa Muda Rp 12.000 • Kopi Nagari Rp 8.000',
    yaw: 15.0,
    icon: Icons.restaurant_rounded,
  ),
  _Facility360Data(
    category: 'TOILET',
    title: 'Toilet Bersih & Kamar Bilas Pos 1',
    label: 'Toilet & Bilas',
    imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
    badge: 'Sanitasi & Bilas Segar',
    description: 'Fasilitas kamar mandi dan bilas menggunakan air sumber pegunungan alami yang dingin dan jernih, dirawat rutin oleh pengelola.',
    subDetail: 'Air Alami Sumber Pegunungan • Kebersihan Terawat Rutin',
    yaw: 65.0,
    icon: Icons.wc_rounded,
  ),
  _Facility360Data(
    category: 'MUSHOLLA',
    title: 'Musholla Al-Ikhlas Pos 1 Wisata',
    label: 'Musholla',
    imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
    badge: 'Tempat Ibadah • Terverifikasi',
    description: 'Musholla bernuansa kayu asri khas nagari. Tersedia tempat wudhu dengan air alami yang mengalir segar dan perlengkapan sholat bersih.',
    subDetail: 'Air Wudhu Alami Mengalir • Mukena & Sajadah Bersih • Buka 24 Jam',
    yaw: 115.0,
    icon: Icons.mosque_rounded,
  ),
];

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
  _Facility360Data? _selectedFacility360;
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
                          fontSize: 9.5,
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
                      hotspots: _k360Facilities.map((facility) {
                        final isSelected = _selectedFacility360?.category == facility.category;
                        return Hotspot(
                          latitude: -10.0,
                          longitude: facility.yaw,
                          width: isSelected ? 44 : 36,
                          height: isSelected ? 44 : 36,
                          widget: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFacility360 = facility;
                                _yaw = facility.yaw;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.terracotta : AppColors.forest,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.40),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(facility.icon, size: isSelected ? 20 : 16, color: Colors.white),
                            ),
                          ),
                        );
                      }).toList(),
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
                          fontSize: 10.5,
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
                            fontSize: 10.5,
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

          // 3. Filter Chips Fasilitas (top: 48)
          Positioned(
            top: 48,
            left: 14,
            right: 14,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _k360Facilities.map((facility) {
                  final isSelected = _selectedFacility360?.category == facility.category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFacility360 = facility;
                          _yaw = facility.yaw;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.terracotta
                              : AppColors.ink.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white30,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              facility.icon,
                              size: 12,
                              color: isSelected ? Colors.white : AppColors.sage,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              facility.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppColors.cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 3.5. Floating AI Voice Over Historical Storytelling Bar (Sejalan dengan 360°)
          Positioned(
            top: 86,
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
                                  _isPlayingVoiceOver ? 'MEMUTAR SUARA AI SEJARAH' : 'AUDIO NARASI AI SEJARAH',
                                  style: TextStyle(
                                    fontSize: 9.5,
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
                                  fontSize: 9.5,
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
                          fontSize: 10.5,
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

          // 4. Floating Photo Preview Card when a facility is tapped
          if (_selectedFacility360 != null)
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _selectedFacility360!.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: AppColors.sage,
                              child: Icon(_selectedFacility360!.icon, color: AppColors.forest, size: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.sage,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _selectedFacility360!.badge,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedFacility360 = null),
                                    child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedFacility360!.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedFacility360!.description,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showMapNavigationSheet(
                                context,
                                widget.place,
                                _selectedFacility360!.category,
                                widget.onOpenDetail,
                              );
                            },
                            icon: const Icon(Icons.directions_rounded, size: 16),
                            label: const Text(
                              'Buka Rute di Peta (Google Maps)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: AppColors.cream,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
              ),
            ),

          // 5. Floating Quick Booking Button (Requirement 14)
          if (!_isQuickBookingOpen && _selectedFacility360 == null)
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
                          'Pesan Layanan Cepat 360° (Setengah Layar)',
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

          // 6. Bottom gesture prompt when no facility is selected and panel closed
          if (!_isQuickBookingOpen && _selectedFacility360 == null)
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
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
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

              // Interactive 360 Hotspot Pins pinned onto the view
              ..._k360Facilities.map((facility) {
                double diff = (facility.yaw - _yaw) % 360;
                if (diff > 180) diff -= 360;
                if (diff < -180) diff += 360;

                if (diff.abs() > 65) return const SizedBox.shrink();

                final double posX = (w / 2) + (diff / 65.0) * (w / 2 * 0.85);
                final double posY = (h * 0.52) + (_pitch * 1.5);
                final isSelected = _selectedFacility360?.category == facility.category;

                return Positioned(
                  left: posX - (isSelected ? 26 : 20),
                  top: posY - (isSelected ? 26 : 20),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFacility360 = facility;
                        _yaw = facility.yaw;
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isSelected ? 9 : 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.terracotta : AppColors.forest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.50),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(facility.icon, size: isSelected ? 22 : 16, color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white30, width: 0.5),
                          ),
                          child: Text(
                            facility.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.amber : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const Text(
                      'Terverifikasi Petugas',
                      style: TextStyle(
                        fontSize: 10,
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
                  fontSize: 10,
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
                          fontSize: 10,
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
                                  fontSize: 10.5,
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
                              fontSize: 10.5,
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
// MODAL 2: DETAIL DESTINASI + ULASAN + RINCIAN BIAYA & PEMESANAN (REQUEST 1 & 4)
// =============================================================================

class _DestinationDetailSheet extends StatefulWidget {
  final SavedDestinationModel place;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpen360;
  final VoidCallback onOpenBarometer;
  final void Function(int total, String breakdown) onCheckout;

  const _DestinationDetailSheet({
    required this.place,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onOpen360,
    required this.onOpenBarometer,
    required this.onCheckout,
  });

  @override
  State<_DestinationDetailSheet> createState() => _DestinationDetailSheetState();
}

class _DestinationDetailSheetState extends State<_DestinationDetailSheet> {
  late bool _bookmarked;
  late List<UserReview> _reviews;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isBookmarked;
    _reviews = List<UserReview>.from(widget.place.reviews);
  }

  String _formatRupiah(int num) {
    return 'Rp ${num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseTicketPrice = widget.place.calcRates.tiket;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Navigation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(bottom: BorderSide(color: AppColors.warmBorder)),
            ),
            child: Row(
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
                        Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Center(
                    child: Text(
                      'DETAIL & TIKET',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() => _bookmarked = !_bookmarked);
                    widget.onToggleBookmark();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _bookmarked ? AppColors.sage : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _bookmarked ? AppColors.forest : AppColors.sageBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 13,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _bookmarked ? 'Tersimpan' : '+ Simpan',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              children: [
                // Visual Hero Header
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: AppColors.forest),
                        Image.network(
                          widget.place.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.forest),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.ink.withValues(alpha: 0.90),
                                AppColors.ink.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.place.categoryTag,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.forest.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${widget.place.distanceKm.toStringAsFixed(widget.place.distanceKm.truncateToDouble() == widget.place.distanceKm ? 0 : 1)} km',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.place.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cream,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.place.subRegion,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.sage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Rating & Quick 360 CTA
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '★ ${widget.place.rating}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '(${widget.place.reviewsCount} Ulasan)',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Tarif Resmi Transparan',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brush,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onOpen360,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.sage,
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.sageBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.threed_rotation_rounded, size: 16),
                        label: const Text(
                          '360° & Denah',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Geode Ranking Banner in Detail
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC89242)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC89242),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Geode Ranking & Papan Peringkat Spasial',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8C5C1E)),
                            ),
                            Text(
                              'Pantau posisi penjelajah & skor geospasial Minang',
                              style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => _GeodeRankingModal(dest: widget.place),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF193D22),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Buka', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Lingkup Fasilitas Kawasan Wisata (REQUEST 1)
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
                      const Text(
                        'LINGKUP FASILITAS KAWASAN WISATA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.place.facilities.map((fac) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warmBorder),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getFacilityIcon(fac),
                                    size: 13,
                                    color: AppColors.forest,
                                  ),
                                  const SizedBox(width: 4.5),
                                  Flexible(
                                    child: Text(
                                      fac,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warmBorder),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: AppColors.muted,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Info Medan & Rute: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              TextSpan(text: widget.place.terrainNote),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DestinationDetailScreen(
                                destination: widget.place.toFe1Destination(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.terrain_rounded, color: AppColors.cream, size: 15),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Panduan Medan (Layar 02 FE-1)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cream,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Ulasan Wisatawan Terverifikasi (Dengan Bukti Foto & Lokasi Real GPS)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ULASAN WISATAWAN TERVERIFIKASI',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: AppColors.forest,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Bukti Foto Asli & Koordinat GPS',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openAddReviewSheet,
                            icon: const Icon(Icons.add_a_photo_rounded, size: 13),
                            label: const Text(
                              '+ Tulis Ulasan',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: AppColors.cream,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_reviews.length, (idx) {
                        final rev = _reviews[idx];
                        return Container(
                          padding: EdgeInsets.only(top: idx > 0 ? 12 : 0),
                          margin: EdgeInsets.only(top: idx > 0 ? 12 : 0),
                          decoration: idx > 0
                              ? const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.warmBorder),
                                  ),
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: AppColors.forest,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            rev.author.isNotEmpty ? rev.author.substring(0, 1) : 'U',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.cream,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                rev.author,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              Text(
                                                'Wisatawan Terverifikasi • ${rev.date}',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.brush,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3D6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '★ ${rev.rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (rev.realLocation != null && rev.realLocation!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDFECE2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.sageBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 11, color: AppColors.forest),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          rev.realLocation!,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.forest,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '"${rev.comment}"',
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: AppColors.muted,
                                ),
                              ),
                              if (rev.photoUrl != null && rev.photoUrl!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _openImagePreview(
                                    rev.photoUrl!,
                                    rev.author,
                                    rev.realLocation ?? 'Lokasi Terverifikasi',
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      alignment: Alignment.bottomLeft,
                                      children: [
                                        Image.network(
                                          rev.photoUrl!,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 80,
                                            width: double.infinity,
                                            color: AppColors.creamSubtle,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.image_not_supported_rounded, color: AppColors.muted),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.75),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          width: double.infinity,
                                          child: const Row(
                                            children: [
                                              Icon(Icons.photo_camera_rounded, size: 11, color: Color(0xFFE5C07B)),
                                              SizedBox(width: 4),
                                              Text(
                                                'Bukti Foto Asli di Lokasi • Ketuk Perbesar',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 3. Rincian Biaya Resmi Sesuai Perda (REQUEST 1 & 4)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'RINCIAN BIAYA RESMI',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: widget.onOpenBarometer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.warmBorder),
                                  ),
                                  child: const Text(
                                    'Barometer →',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Resmi',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.place.perdaRef,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(widget.place.verticalFees.length, (idx) {
                        final fee = widget.place.verticalFees[idx];
                        return Container(
                          padding: EdgeInsets.only(top: idx > 0 ? 8 : 0),
                          margin: EdgeInsets.only(top: idx > 0 ? 8 : 0),
                          decoration: idx > 0
                              ? const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.warmBorder),
                                  ),
                                )
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fee.label,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      fee.sub,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                fee.price,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                              ],
            ),
          ),

          // Sticky Bottom Action Bar with Official Ticket Price & Pesan Tiket Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.warmBorder)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tiket Masuk Resmi',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      _formatRupiah(baseTicketPrice),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onCheckout(baseTicketPrice, '1 Tiket Masuk Resmi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.cream,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Pesan via WhatsApp Vendor',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
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

  void _openImagePreview(String url, String author, String location) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 260,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, color: Colors.white, size: 48),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFE5C07B)),
                        const SizedBox(width: 6),
                        Text(
                          'Bukti Foto Asli • $author',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.cream),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(fontSize: 10.5, color: AppColors.sage.withValues(alpha: 0.9)),
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

  void _openAddReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => _AddReviewModal(
        destination: widget.place,
        onReviewSubmitted: (newReview) {
          setState(() {
            _reviews.insert(0, newReview);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.forest,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFFE5C07B), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ulasan dengan bukti foto & koordinat GPS berhasil diterbitkan!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.cream),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddReviewModal extends StatefulWidget {
  final SavedDestinationModel destination;
  final ValueChanged<UserReview> onReviewSubmitted;

  const _AddReviewModal({
    required this.destination,
    required this.onReviewSubmitted,
  });

  @override
  State<_AddReviewModal> createState() => _AddReviewModalState();
}

class _AddReviewModalState extends State<_AddReviewModal> {
  int _rating = 5;
  late String _photoUrl;
  final _commentController = TextEditingController();

  late final List<Map<String, String>> _samplePhotos;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.destination.imageUrl;
    _samplePhotos = [
      {
        'label': 'Spot Utama',
        'url': widget.destination.imageUrl,
      },
      {
        'label': 'Pemandangan Alam',
        'url': 'https://images.unsplash.com/photo-1546776310-eef45dd6d63c?auto=format&fit=crop&w=600&q=80',
      },
      {
        'label': 'Pos & Loket Resmi',
        'url': 'https://images.unsplash.com/photo-1518457607834-6e8d80c183c5?auto=format&fit=crop&w=600&q=80',
      },
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getRatingText(int stars) {
    switch (stars) {
      case 5:
        return '⭐⭐⭐⭐⭐ Sangat Memuaskan (5.0)';
      case 4:
        return '⭐⭐⭐⭐ Bagus & Tertib (4.0)';
      case 3:
        return '⭐⭐⭐ Cukup Baik (3.0)';
      case 2:
        return '⭐⭐ Kurang Memuaskan (2.0)';
      default:
        return '⭐ Perlu Perbaikan (1.0)';
    }
  }

  void _submitReview() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tulis ulasan atau pengalaman Anda terlebih dahulu.'),
          backgroundColor: AppColors.terracotta,
        ),
      );
      return;
    }

    final newReview = UserReview(
      author: 'Ahmad Fauzi',
      rating: _rating.toDouble(),
      date: 'Baru saja',
      comment: comment,
      photoUrl: _photoUrl,
      realLocation: 'GPS Terverifikasi (${widget.destination.subRegion}) • Real-time',
      isGpsVerified: true,
    );

    Navigator.pop(context);
    widget.onReviewSubmitted(newReview);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.warmBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TULIS ULASAN WISATAWAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.brush,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ulasan Nyata & Bukti Foto',
                        style: TextStyle(
                          fontSize: 18,
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
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.creamSubtle,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. Lokasi Real GPS Geofence Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDFECE2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sageBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.gps_fixed_rounded, color: AppColors.cream, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lokasi Real GPS Terdeteksi',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                        Text(
                          '${widget.destination.title} (${widget.destination.subRegion}) • Radius < 150m',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Terverifikasi',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Rating Bintang
            const Text(
              'PENILAIAN RATING:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 32,
                            color: starIndex <= _rating ? Colors.amber : AppColors.warmBorder,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingText(_rating),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Bukti Foto Asli di Lokasi
            const Text(
              'BUKTI FOTO KUNJUNGAN DI LOKASI:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        Image.network(
                          _photoUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 100,
                            color: AppColors.creamSubtle,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image, color: AppColors.muted),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                            ),
                          ),
                          width: double.infinity,
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFFE5C07B)),
                              SizedBox(width: 4),
                              Text(
                                'Bukti Foto Terlampir & Siap Diverifikasi',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pilih contoh bukti foto nyata di lokasi:',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _samplePhotos.map((sample) {
                      final isSelected = _photoUrl == sample['url'];
                      return ChoiceChip(
                        label: Text(sample['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _photoUrl = sample['url']!);
                        },
                        selectedColor: AppColors.forest,
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.cream : AppColors.ink,
                        ),
                        backgroundColor: AppColors.creamSubtle,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSelected ? AppColors.forest : AppColors.warmBorder),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Input Ulasan & Catatan Pengalaman
            const Text(
              'PENGALAMAN & KONDISI NYATA DI LOKASI:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Tulis pengalaman Anda (kebersihan fasilitas, kesesuaian tiket perda, keindahan spot)...',
                hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.warmBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.warmBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'Tarif resmi sesuai Perda',
                'Fasilitas bersih & rapi',
                'Pemandangan sangat indah',
                'Parkir aman & tertib',
              ].map((chipText) {
                return GestureDetector(
                  onTap: () {
                    final cur = _commentController.text;
                    _commentController.text = cur.isEmpty ? chipText : '$cur. $chipText';
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: Text(
                      '+ $chipText',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.forest),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // 5. Tombol Kirim Ulasan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitReview,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text(
                  'Kirim Ulasan Terverifikasi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: AppColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
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
        backgroundColor: Color(0xFF193D22),
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
            backgroundColor: Color(0xFF193D22),
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
                    colors: [Color(0xFFC89242), Color(0xFF8C5C1E)],
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF142618)),
                    ),
                    Text(
                      'Papan Peringkat Spasial • Direkalkulasi oleh Admin Dispar',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF5A6B5D)),
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
                colors: [Color(0xFF193D22), Color(0xFF142618)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF193D22).withValues(alpha: 0.25),
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
                        Text('POSISI RANKING ANDA', style: TextStyle(fontSize: 9.5, color: AppColors.sage, fontWeight: FontWeight.w800)),
                        Text('Peringkat #3 Se-Sumbar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC89242),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Tier Geode Platinum', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('$_userGeodeScore GP', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE2B755))),
                        const Text('Skor Geode', style: TextStyle(fontSize: 9.5, color: AppColors.sage)),
                      ],
                    ),
                    Container(width: 1, height: 24, color: Colors.white24),
                    Column(
                      children: [
                        Text('${_userGeodeDistanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        const Text('Jarak Geodesik', style: TextStyle(fontSize: 9.5, color: AppColors.sage)),
                      ],
                    ),
                    Container(width: 1, height: 24, color: Colors.white24),
                    Column(
                      children: [
                        Text(_isGpsCheckedIn ? '10/10' : '9/10', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                        const Text('Tertaklukkan', style: TextStyle(fontSize: 9.5, color: AppColors.sage)),
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
                  : const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF193D22)),
              label: Text(
                _isRecalculating ? 'Merekalkulasi Peringkat Geospasial...' : 'Rekalkulasi Geode Ranking Saya',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF193D22)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF193D22)),
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
                color: _isGpsCheckedIn ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3D6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isGpsCheckedIn ? const Color(0xFF22C55E) : const Color(0xFFD97706),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGpsCheckedIn ? Icons.check_circle_rounded : Icons.my_location_rounded,
                    color: _isGpsCheckedIn ? const Color(0xFF15803D) : const Color(0xFFB45309),
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
                            color: _isGpsCheckedIn ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                        Text(
                          _isGpsCheckedIn
                              ? 'Stempel check-in di $destName (+250 GP)'
                              : 'Berada di $destName (< 500m geofence)',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF5A6B5D)),
                        ),
                      ],
                    ),
                  ),
                  if (!_isGpsCheckedIn)
                    ElevatedButton(
                      onPressed: _verifyGpsCheckin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF193D22),
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
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1),
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
        color: isMe ? const Color(0xFFFBF4E4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? const Color(0xFFC89242) : AppColors.sageBorder,
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
                  ? const Color(0xFFE2B755)
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
                fontSize: 10.5,
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
                          color: isMe ? const Color(0xFF8C5C1E) : AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC89242),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Saya', style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text('$dest • $dist', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF193D22))),
              Text('Tier $tier', style: const TextStyle(fontSize: 8.5, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
