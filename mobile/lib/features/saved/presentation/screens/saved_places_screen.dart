import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/splash_screen.dart';
import '../../../fair_price/data/models/fair_price_tariff_model.dart';
import '../../../group_room/presentation/widgets/group_room_sheet.dart';
import '../../../proposal/presentation/widgets/usul_destinasi_sheet.dart';
import '../../../qr_scanner/presentation/widgets/qr_scanner_sheet.dart';
import '../../../trip_planner/presentation/widgets/trip_planner_sheet.dart';
import '../../../reports/presentation/widgets/lapor_pungli_sheet.dart';
import '../../../fe1_visual_map/audio_guide_culture/audio_culture_screen.dart';
import '../../../fe1_visual_map/destination_detail/destination_detail_screen.dart';
import '../../../fe1_visual_map/hazard_alert_sos/hazard_sos_screen.dart';
import '../../../fe1_visual_map/map_explore_shunlu/map_explore_screen.dart';
import '../../../fe1_visual_map/models/destination_model.dart';
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

  // Navigation Items
  static const List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Beranda',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
    },
    {
      'label': 'Open Trip',
      'icon': Icons.groups_outlined,
      'activeIcon': Icons.groups_rounded,
    },
    {
      'label': 'Peta',
      'icon': Icons.map_outlined,
      'activeIcon': Icons.map_rounded,
    },
    {
      'label': 'Profil',
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



  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Global Static Offline Notification Banner (Item 6)
            if (_isOfflineMode)
              OfflineBanner(
                onRetry: () => setState(() => _isOfflineMode = false),
              ),

            // Active Main View (4 Tabs: Beranda, Peta Rute, Tarif Resmi, Profil)
            Expanded(
              child: IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildExploreView(),
                  _buildOpenTripView(),
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
  }

  // ===========================================================================
  // VIEW 0: JELAJAH DAERAH & ALAM SUMATERA BARAT
  // ===========================================================================
  Widget _buildSortChip({
    required String key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.sageBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.cream : AppColors.muted,
          ),
        ),
      ),
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
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (_sortMode == 'rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Stack(
      children: [
        CustomScrollView(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Jelajah 10 Destinasi Wisata Sumbar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        GestureDetector(
                          onTap: () => setState(() => _isOfflineMode = !_isOfflineMode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isOfflineMode ? const Color(0xFFFDEEE9) : const Color(0xFFE8F3EB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isOfflineMode ? AppColors.terracotta.withValues(alpha: 0.5) : AppColors.forest.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _isOfflineMode ? AppColors.terracotta : AppColors.brush,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isOfflineMode ? 'Luring' : 'Online',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _isOfflineMode ? AppColors.terracotta : AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. SCAN QR (DIPERBESAR BIAR NAMPAK!)
                  GestureDetector(
                    onTap: _openQrScannerModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forest.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 17, color: AppColors.cream),
                          SizedBox(width: 4),
                          Text(
                            'Scan QR',
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
                  const SizedBox(width: 6),

                  // 2. Siaga SOS
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HazardSosScreen()),
                    ),
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEEE9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.45)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.sos_rounded, size: 18, color: AppColors.terracotta),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // 3. Disimpan (Icon Simpan)
                  GestureDetector(
                    onTap: _openSavedPlacesModal,
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: AppColors.creamSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.bookmark_rounded, size: 18, color: AppColors.forest),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // 4. Kalender Budaya (Icon Kalender)
                  GestureDetector(
                    onTap: _openKalenderBudayaModal,
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EDFA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF5A3E85).withValues(alpha: 0.35)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF5A3E85)),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // 5. Akses Kamus Minang
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AudioCultureScreen()),
                    ),
                    child: Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E5B82).withValues(alpha: 0.35)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.menu_book_rounded, size: 17, color: Color(0xFF1E5B82)),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Header Content (Clean & Streamlined)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.sageBorder.withValues(alpha: 0.8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Cari destinasi, daerah, fasilitas...',
                          hintStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted.withValues(alpha: 0.7),
                          ),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.muted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.close, size: 16, color: AppColors.muted),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Sort Mode Chips (Semua | Jarak Terdekat | Rating Tertinggi)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortChip(
                            key: 'default',
                            label: 'Semua',
                            isSelected: _sortMode == 'default',
                            onTap: () => setState(() => _sortMode = 'default'),
                          ),
                          const SizedBox(width: 6),
                          _buildSortChip(
                            key: 'distance',
                            label: 'Jarak Terdekat (GPS)',
                            isSelected: _sortMode == 'distance',
                            onTap: () => setState(() => _sortMode = 'distance'),
                          ),
                          const SizedBox(width: 6),
                          _buildSortChip(
                            key: 'rating',
                            label: 'Rating Tertinggi',
                            isSelected: _sortMode == 'rating',
                            onTap: () => setState(() => _sortMode = 'rating'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Primary Region Navigator (Clean Rounded Pills)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _exploreRegions.map((reg) {
                          final isSelected = _currentExploreRegion == reg['key'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _currentExploreRegion = reg['key']!,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
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
                                        : AppColors.sageBorder,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.forest.withValues(alpha: 0.18),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  reg['title']!,
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
                    const SizedBox(height: 8),

                    // 5. Nature Sub-Category Navigator (Compact Chips)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _exploreTypes.map((type) {
                          final isSelected = _currentExploreType == type['key'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _currentExploreType = type['key']!,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.sage
                                      : AppColors.creamSubtle,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  type['label']!,
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
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
          ],
        ),

        // Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _openUsulDestinasiModal,
            backgroundColor: AppColors.forest,
            foregroundColor: AppColors.cream,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Usul Wisata',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KOLABORASI & CARI BARENGAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: Color(0xFF1E5B82),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Open Trip Sumbar',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E5B82).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_rounded, size: 14, color: Color(0xFF1E5B82)),
                    SizedBox(width: 4),
                    Text(
                      '3 Trip Aktif',
                      style: TextStyle(
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.group_add_rounded, size: 13, color: Color(0xFF1E5B82)),
                              SizedBox(width: 4),
                              Text(
                                'OPEN TRIP TERBUKA',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF1E5B82)),
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
                          child: const Text(
                            'Kuota Tersedia',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Daftar Open Trip Terbuka (Cari Barengan)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Gabung open trip untuk patungan sewa mobil, tour guide nagari, dan nikmati serunya jelajah Sumbar bersama wisatawan lain.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF5A6B5D)),
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
                            onPressed: () => _showAppToast('Menghubungi Koordinator Open Trip Harau...'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('Gabung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
                            onPressed: () => _showAppToast('Menghubungi Koordinator Open Trip Mandeh...'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1E5B82),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('Gabung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
                            onPressed: () => _showAppToast('Menghubungi Koordinator Open Trip Budaya...'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFC89242),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: const Text('Gabung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
                        label: const Text(
                          '+ Buat Jadwal Open Trip Baru',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
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
                    const Text(
                      'Rencana Perjalanan Otomatis 1–7 Hari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Susun jadwal liburan otomatis berdasarkan durasi hari, estimasi anggaran per orang, dan minat wisata rombongan (Alam, Kuliner, Adat).',
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
                      label: const Text(
                        'Buka Trip Planner & Estimasi Anggaran',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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

              // 3. Feature Card: Ruang Rombongan & Kolaborasi Voting
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
                            color: const Color(0xFFFEF3D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.how_to_vote_rounded, size: 13, color: Color(0xFFB45309)),
                              SizedBox(width: 4),
                              Text(
                                'Kolaborasi Rombongan',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.share_rounded, size: 18, color: AppColors.forest),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ruang Rombongan & Voting Destinasi',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Buat ruang bersama teman rombongan, lakukan voting destinasi favorit secara demokratis, dan bagikan link undangan.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openGroupRoomModal,
                            icon: const Icon(Icons.group_rounded, size: 16),
                            label: const Text(
                              'Buka Ruang Room',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openKalenderBudayaModal,
                            icon: const Icon(Icons.event_note_rounded, size: 16),
                            label: const Text(
                              'Kalender Event',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5A3E85),
                              side: const BorderSide(color: Color(0xFF5A3E85)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Modal: Kalender Acara & Festival Budaya Minang (Dibuka lewat icon kalender di header Beranda)
  void _openKalenderBudayaModal() {
    final events = [
      {
        'title': 'Festival Pasa Harau 2026',
        'date': '18 – 20 Desember 2026',
        'location': 'Lembah Harau, Kab. Lima Puluh Kota',
        'desc': 'Pagelaran akbar seni adat, randai tradisional, musik saluang, & kuliner nagari di bawah tebing granit.',
        'badge': 'Festival Adat Resmi',
      },
      {
        'title': 'Pacu Jawi Tradisional Luhak Nan Tuo',
        'date': 'Setiap Sabtu (Pukul 09:00 WIB)',
        'location': 'Kec. Pariangan, Kab. Tanah Datar',
        'desc': 'Balapan sepasang sapi di sawah basah berlumpur khas Minangkabau sebagai perayaan syukur panen padi nagari.',
        'badge': 'Warisan Budaya',
      },
      {
        'title': 'Festival Pesona Danau Maninjau',
        'date': '24 – 26 Desember 2026',
        'location': 'Kelok 44 & Tepian Danau, Agam',
        'desc': 'Kejuaraan paralayang internasional dari puncak Lawang, pameran kriya perak, & santap rinuak segar.',
        'badge': 'Agenda Tahunan',
      },
      {
        'title': 'Pesta Budaya Tabuik Pariaman',
        'date': '10 Muharram (Puncak Hoyak Tabuik)',
        'location': 'Pantai Gandoriah, Kota Pariaman',
        'desc': 'Prosesi kultural pengusungan Tabuik raksasa nan megah hingga pembuangan ke laut diiringi tambua tasa membahana.',
        'badge': 'Karnaval Akbar',
      },
      {
        'title': 'Batagak Panghulu & Alek Nagari',
        'date': 'Jadwal Adat Nagari',
        'location': 'Balai Adat Koto Gadang',
        'desc': 'Upacara sakral pengangkatan Datuak Datuak pemangku adat suku Minangkabau dengan jamuan bajamba adat.',
        'badge': 'Hukum Adat',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                  itemCount: events.length,
                  itemBuilder: (context, idx) {
                    final ev = events[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sageBorder),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3EDFA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ev['badge'] as String,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5A3E85),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
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
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.brush),
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
                        ],
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SISTEM INFORMASI GEOGRAFIS & SPASIAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AppColors.brush,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Peta Wisata Interaktif Sumbar',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed_rounded, size: 13, color: AppColors.forest),
                    SizedBox(width: 4),
                    Text(
                      'GPS Aktif',
                      style: TextStyle(
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            children: [
              // 1. Simulated Live GPS Map Canvas (Visual Route & Spatial Markers)
              Container(
                height: 230,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2ED),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.forest, width: 2),
                ),
                child: Stack(
                  children: [
                    // Road Path & Spatial Terrain
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RouteMapPainter(),
                      ),
                    ),

                    // Status GPS Pill
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location_rounded, size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              '10 Destinasi Terpetakan • Padang, Sumbar',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Turn guidance strip at bottom
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.explore_rounded, color: AppColors.forest, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jalur arteri Trans-Sumatera & akses aspal nagari terpantau aman.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
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

              // 2. Button Launcher: Peta Rute & Titik Singgah Shunlu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NAVIGASI INTERAKTIF & TEMPAT MAMPIR SEARAH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.forest,
                          ),
                        ),
                        Icon(Icons.map_rounded, size: 18, color: AppColors.forest),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Peta Rute & Titik Singgah (Shunlu)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Peta visual interaktif jalur penghubung antar-destinasi di Padang, Bukittinggi, Payakumbuh, Pesisir Selatan, Agam, dan Tanah Datar.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapExploreShunluScreen()),
                      ),
                      icon: const Icon(Icons.near_me_rounded, size: 16),
                      label: const Text(
                        'Buka Peta Rute & Titik Singgah (Shunlu)',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: AppColors.cream,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Card: Hitung Jarak Spasial Terdekat (GPS)
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF15803D)),
                              SizedBox(width: 4),
                              Text(
                                'JARAK SPASIAL TERDEKAT',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Kalkulasi Otomatis',
                          style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Destinasi Paling Dekat dari Lokasi Anda',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                    ),
                    const SizedBox(height: 10),
                    // Destinasi Terdekat 1: Gunung Padang
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.forest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Taman Siti Nurbaya & Gunung Padang', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF142618))),
                                Text('Padang • 4.5 km (12 mnt)', style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D))),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brush),
                        ],
                      ),
                    ),
                    // Destinasi Terdekat 2: Lubuk Hitam
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E5B82),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Air Terjun Lubuk Hitam 3 Tingkat', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF142618))),
                                Text('Padang Selatan • 18 km (35 mnt)', style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D))),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brush),
                        ],
                      ),
                    ),
                    // Destinasi Terdekat 3: Kawasan Mandeh
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC89242),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kawasan Wisata Bahari Mandeh', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF142618))),
                                Text('Pesisir Selatan • 56 km (1 jam 15 mnt)', style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D))),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.brush),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Card: Pantau Jalur Ekstrem & Arteri Wisata Sumbar
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFB45309)),
                              SizedBox(width: 4),
                              Text(
                                'STATUS JALUR UTAMA SUMBAR',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Update Terkini',
                          style: TextStyle(fontSize: 10, color: Color(0xFF5A6B5D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kondisi Jalur Ekstrem & Lalu Lintas Wisata',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                    ),
                    const SizedBox(height: 10),
                    _buildJalurStatusRow('Sitinjau Lauik (Padang - Solok)', 'Lancar • Waspada Tanjakan & Tikungan Licin', Colors.green),
                    const SizedBox(height: 6),
                    _buildJalurStatusRow('Kelok 9 (Payakumbuh - Riau)', 'Lancar • Pemandangan Ramai Wisatawan', Colors.green),
                    const SizedBox(height: 6),
                    _buildJalurStatusRow('Kelok 44 Maninjau (Agam)', 'Beraspal Mulus • Hati-hati 44 Tikungan Curam', Colors.amber.shade800),
                    const SizedBox(height: 6),
                    _buildJalurStatusRow('Lembah Anai (Padang - Padang Panjang)', 'Lancar • Debit Air Terjun Normal', Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4.5. Tombol Lapor Saber Pungli / Jalur Rusak
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3D6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Satgas Saber Pungli & Aduan Jalur',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                          ),
                          Text(
                            'Laporkan tarif liar di luar Perda atau rambu jalur rusak',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF5A6B5D)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _openLaporPungliModal(tab: 'pungli'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB45309),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Lapor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),

              // 5. Radar Live Tracking Rombongan Button
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E5B82).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E5B82),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Radar Lokasi Rombongan Live',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                          ),
                          Text(
                            'Pantau koordinat GPS teman satu rombongan',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF5A6B5D)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _openLiveGroupTrackingModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E5B82),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Buka Radar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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

  Widget _buildJalurStatusRow(String name, String status, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF142618))),
                Text(status, style: const TextStyle(fontSize: 9.5, color: Color(0xFF5A6B5D))),
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
                // 1. Rating & Official Entry Fee Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          '${place.rating}',
                          style: const TextStyle(
                            fontSize: 12,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.creamSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.sageBorder),
                      ),
                      child: Text(
                        'Tiket: Rp ${place.calcRates.tiket}',
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

                // 2. Fasilitas Lingkungan: Ikon informatif di kartu, hover & detail lengkap
                Row(
                  children: [
                    const Text(
                      'FASILITAS LINGKUNGAN:',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: place.facilities.map((fac) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Tooltip(
                                message: '$fac (Ketuk untuk rincian standar fasilitas)',
                                preferBelow: false,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: InkWell(
                                    onTap: () => _openFacilityDetailSheet(fac, place),
                                    borderRadius: BorderRadius.circular(8),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.creamSubtle,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.warmBorder.withValues(alpha: 0.9),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getFacilityIcon(fac),
                                            size: 13,
                                            color: AppColors.forest,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            fac,
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Text(
                                            'ⓘ',
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              color: AppColors.brush,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
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
                const SizedBox(height: 8),

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
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.threed_rotation_rounded, size: 15),
                              SizedBox(width: 4),
                              Text(
                                '360° & Denah',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Detail',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
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
  // MODAL 1: 360° PANORAMA & DENAH LOKASI INTERAKTIF (REQUEST 3)
  // ===========================================================================
  void _open360AndDenahModal(SavedDestinationModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _Explore360AndDenahSheet(
          place: place,
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
      builder: (ctx) => TripPlannerSheet(
        onOpenGroupRoom: _openGroupRoomModal,
      ),
    );
  }

  // ===========================================================================
  // MODAL 7: RUANG ROMBONGAN PRIBADI & UNDANGAN WHATSAPP (ITEM 11)
  // ===========================================================================
  void _openGroupRoomModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GroupRoomSheet(
        onInviteWhatsApp: () {
          _showAppToast('Tautan Undangan WhatsApp Rombongan Siap Dikirim!');
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

  void _openGachaRankinModal([SavedDestinationModel? dest]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GachaRankinModal(dest: dest),
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
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AKUN WISATAWAN • TERVERIFIKASI WHATSAPP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AppColors.brush,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Profil Saya',
                      style: TextStyle(
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
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sage,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Profile Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              // 1. Kartu Identitas Wisatawan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sageBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'AF',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ahmad Fauzi',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                '+62 812-7578-953 • Wisatawan Nusantara',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.sage,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'OTP WhatsApp Terverifikasi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
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
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Column(
                        children: [
                          _buildProfileStatRow(
                            label: 'Destinasi Tersimpan di Perangkat',
                            value: '${_savedIds.length} Lokasi',
                            onTap: () => setState(() => _activeTabIndex = 1),
                          ),
                          const Divider(
                            height: 16,
                            color: AppColors.warmBorder,
                          ),
                          _buildProfileStatRow(
                            label: 'Status Akses Lokasi GPS (3D)',
                            value: 'Aktif • Sumatera Barat',
                          ),
                          const Divider(
                            height: 16,
                            color: AppColors.warmBorder,
                          ),
                          _buildProfileStatRow(
                            label: 'Mode Memori Tanpa Sinyal (Luring)',
                            value: _isOfflineMode ? 'Sedang Aktif' : 'Siap Siaga',
                            valueColor: _isOfflineMode
                                ? AppColors.terracotta
                                : AppColors.forest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 1.5. PASPOR DIGITAL MINANG (Verifikasi Jarak GPS & Stempel Nagari)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E1C0C), Color(0xFF5C3818)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E1C0C).withValues(alpha: 0.25),
                      blurRadius: 10,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC89242).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC89242), width: 1),
                          ),
                          child: const Text(
                            'PILAR 6 • PASPOR DIGITAL MINANG',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFFE5C07B),
                            ),
                          ),
                        ),
                        const Icon(Icons.military_tech_rounded, color: Color(0xFFE5C07B), size: 22),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Paspor Digital & Lencana Kunjungan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kumpulkan stempel resmi nagari setelah koordinat GPS perangkat Anda terverifikasi di kawasan wisata (< 500m geofence).',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD4C5B9),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progres Penjelajah: 4 / 10 Destinasi Nagari',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFE5C07B)),
                        ),
                        Text(
                          '50%',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        value: 0.50,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC89242)),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openGachaRankinModal(),
                            icon: const Icon(Icons.stars_rounded, size: 16),
                            label: const Text(
                              'Gacha Rankin',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openDigitalPassportModal,
                            icon: const Icon(Icons.verified_rounded, size: 16),
                            label: const Text(
                              'Paspor Digital',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC89242),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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



              const SizedBox(height: 14),

              // 3. Pengaturan Akun & Tombol Keluar (Ke Alur Awal Jobdesk 1-4)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SESI AKUN & ALUR ONBOARDING (JOBDESK 1–4)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingin menguji ulang alur awal mulai dari Splash Screen WISGO, Izin Lokasi 3D Rumah Gadang, Login Nomor WhatsApp (+62), hingga Verifikasi OTP 4 Digit?',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const SplashScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.coralTint,
                          foregroundColor: AppColors.terracotta,
                          side: BorderSide(
                            color: AppColors.terracotta.withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Keluar dari Akun & Ulangi Alur Masuk (Splash / OTP)',
                          style: TextStyle(
                            fontSize: 12,
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
        ),
      ],
    );
  }

  Widget _buildProfileStatRow({
    required String label,
    required String value,
    Color valueColor = AppColors.forest,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
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
              final itemWidth = totalWidth / 4;
              final targetCenterX =
                  (itemWidth * _activeTabIndex) + (itemWidth / 2);

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
                              _navItems[_activeTabIndex]['activeIcon']
                                  as IconData,
                              size: 20,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ),

                      // 3. 4 Navigation Columns
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 13),
                          child: Row(
                            children: List.generate(_navItems.length, (idx) {
                              final isSelected = idx == _activeTabIndex;
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
                                          size: 21,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item['label'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
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
    const double notchHalfWidth = 38.0;
    const double notchDepth = 46.0;

    final double cx = notchCenterX.clamp(
      cornerRadius + notchHalfWidth,
      w - cornerRadius - notchHalfWidth,
    );
    final double nStart = cx - notchHalfWidth;
    final double nEnd = cx + notchHalfWidth;

    final path = Path()
      ..moveTo(0, topY + cornerRadius)
      ..quadraticBezierTo(0, topY, cornerRadius, topY)
      ..lineTo(nStart, topY)
      ..cubicTo(
        cx - 24.0,
        topY,
        cx - 23.0,
        notchDepth,
        cx,
        notchDepth,
      )
      ..cubicTo(
        cx + 23.0,
        notchDepth,
        cx + 24.0,
        topY,
        nEnd,
        topY,
      )
      ..lineTo(w - cornerRadius, topY)
      ..quadraticBezierTo(w, topY, w, topY + cornerRadius)
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

  const _Explore360AndDenahSheet({
    required this.place,
    required this.onOpenDetail,
  });

  @override
  State<_Explore360AndDenahSheet> createState() => _Explore360AndDenahSheetState();
}

class _Explore360AndDenahSheetState extends State<_Explore360AndDenahSheet> {
  String _subTab = '360'; // '360' | 'denah'
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

                // Simulated Live GPS Map Container
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF2ED),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.forest, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Road Path CustomPaint
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RouteMapPainter(),
                        ),
                      ),

                      // Status GPS pill
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.sageBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gps_fixed_rounded, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'GPS Aktif • Akurasi 5m',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Turn guidance strip at bottom
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.sageBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.turn_right_rounded, color: AppColors.forest, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Akses via ${place.subRegion} menuju area parkir & fasilitas resmi.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
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

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background terrain curves
    final greenPaint = Paint()
      ..color = const Color(0xFFCCE0D1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 60, greenPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 80, greenPaint);

    // Road path
    final roadPaint = Paint()
      ..color = const Color(0xFFD5DFD7)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..cubicTo(
        size.width * 0.35, size.height * 0.70,
        size.width * 0.55, size.height * 0.40,
        size.width * 0.82, size.height * 0.25,
      );
    canvas.drawPath(path, roadPaint);

    // Active GPS Line (Orange)
    final gpsPaint = Paint()
      ..color = const Color(0xFFE65F2B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, gpsPaint);

    // Start point (Padang GPS)
    final startPaint = Paint()..color = AppColors.forest;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 7, startPaint);
    final startInner = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 3, startInner);

    // End point (Target pin)
    final endPaint = Paint()..color = const Color(0xFFE65F2B);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.25), 9, endPaint);
    final endInner = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.25), 4, endInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

                // Gacha Rankin Banner in Detail
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3D6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD97706)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gacha Rankin & Check-in GPS',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                            ),
                            Text(
                              'Klaim voucher kuliner & diskon tiket resmi',
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
                            builder: (ctx) => _GachaRankinModal(dest: widget.place),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB45309),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Buka', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
// MODAL GACHA RANKIN & CHECK-IN GPS (MINANG GAMIFIED REWARDS)
// =============================================================================
class _GachaRankinModal extends StatefulWidget {
  final SavedDestinationModel? dest;
  const _GachaRankinModal({this.dest});

  @override
  State<_GachaRankinModal> createState() => _GachaRankinModalState();
}

class _GachaRankinModalState extends State<_GachaRankinModal> {
  bool _isGpsCheckedIn = false;
  bool _isSpinning = false;
  String? _wonReward;
  String? _rewardCode;

  final List<Map<String, String>> _rewards = const [
    {
      'name': 'Voucher Rendang Asli Payakumbuh 20%',
      'code': 'MINANG-RENDANG-20',
      'icon': '🍲',
      'desc': 'Potongan 20% pembelian oleh-oleh rendang basah & rendang paru di gerai mitra Pokdarwis.',
    },
    {
      'name': 'Bebas Retribusi Parkir Pokdarwis 1x',
      'code': 'PARKIR-NAGARI-FREE',
      'icon': '🅿️',
      'desc': 'Gratis parkir motor/mobil 1 kali di seluruh destinasi binaan nagari Sumbar.',
    },
    {
      'name': 'Stempel Emas Paspor Digital Sumbar',
      'code': 'GOLD-BADGE-2026',
      'icon': '🌟',
      'desc': '+100 XP Paspor Digital dan lencana kebanggaan Penjelajah Ranah Minang.',
    },
    {
      'name': 'Kupon Gratis Minuman Kawa Daun Batang Tabik',
      'code': 'KAWA-DAUN-FREE',
      'icon': '☕',
      'desc': 'Gratis 1 cangkir batuang seduhan Kawa Daun hangat khas lereng Gunung Sago.',
    },
    {
      'name': 'Diskon Sewa Pakaian Adat Minang Rp 15.000',
      'code': 'ADAT-MINANG-15K',
      'icon': '👘',
      'desc': 'Diskon sewa pakaian Bundo Kanduang atau Marapulai di area wisata budaya.',
    },
  ];

  void _verifyGps() {
    setState(() {
      _isGpsCheckedIn = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Koordinat GPS Terverifikasi! Anda berada dalam geofence kawasan wisata Sumbar (Akurasi 8m).'),
        backgroundColor: Color(0xFF193D22),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _spinGacha() {
    if (!_isGpsCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lakukan Check-in GPS terlebih dahulu untuk membuka Rankin Hadiah!'),
          backgroundColor: Color(0xFFB45309),
        ),
      );
      return;
    }
    setState(() {
      _isSpinning = true;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      final selected = (_rewards..shuffle()).first;
      setState(() {
        _isSpinning = false;
        _wonReward = selected['name'];
        _rewardCode = selected['code'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final destName = widget.dest?.title ?? 'Kawasan Wisata Sumatera Barat';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gacha Rankin & Check-in GPS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF142618)),
                    ),
                    Text(
                      'Klaim hadiah & oleh-oleh khas Minang dari keranjang Rankin',
                      style: TextStyle(fontSize: 11, color: Color(0xFF5A6B5D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GPS Proximity Check-in Box
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
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isGpsCheckedIn ? 'Lokasi GPS Terverifikasi' : 'Check-in Lokasi Diperlukan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isGpsCheckedIn ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                      Text(
                        _isGpsCheckedIn
                            ? 'Koordinat aktif di $destName'
                            : 'Verifikasi keberadaan Anda di kawasan wisata',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF5A6B5D)),
                      ),
                    ],
                  ),
                ),
                if (!_isGpsCheckedIn)
                  ElevatedButton(
                    onPressed: _verifyGps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Check-in', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Prize Display or Rankin Box
          if (_wonReward != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCA8A04)),
              ),
              child: Column(
                children: [
                  const Text('🎉 SELAMAT! ANDA MENDAPATKAN:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF854D0E))),
                  const SizedBox(height: 6),
                  Text(
                    _wonReward!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF713F12)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCA8A04)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Kode: ${_rewardCode ?? ""}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF142618), letterSpacing: 1),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (_rewardCode != null) {
                              Clipboard.setData(ClipboardData(text: _rewardCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kode voucher disalin!')),
                              );
                            }
                          },
                          child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF854D0E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Gacha Spin Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSpinning ? null : _spinGacha,
              icon: _isSpinning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.casino_rounded, size: 20),
              label: Text(
                _isSpinning ? 'Mengocok Keranjang Rankin...' : 'Buka Keranjang Rankin Minang',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF193D22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
