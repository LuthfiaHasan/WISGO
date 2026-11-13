import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/splash_screen.dart';
import '../../../fair_price/data/models/fair_price_tariff_model.dart';
import '../../../fair_price/presentation/widgets/fair_price_barometer_table.dart';
import '../../../group_room/presentation/widgets/group_room_sheet.dart';
import '../../../proposal/presentation/widgets/usul_destinasi_sheet.dart';
import '../../../qr_scanner/presentation/widgets/qr_scanner_sheet.dart';
import '../../../reports/presentation/widgets/lapor_pungli_sheet.dart';
import '../../../trip_planner/presentation/widgets/trip_planner_sheet.dart';
import '../widgets/offline_banner.dart';
import '../widgets/saved_empty_state.dart';
import '../widgets/saved_skeleton_shimmer.dart';

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
  String _selectedSavedRegionFilter = 'ALL';

  // View 2: Barometer State
  int _activeBarometerDestIdx = 2; // Default Lembah Harau
  String _activeBarometerCategory = 'ALL'; // 'ALL' | 'TIKET' | 'PARKIR' | 'FASILITAS'

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

  static const List<Map<String, String>> _savedRegionChips = [
    {'key': 'ALL', 'label': 'Semua Daerah'},
    {'key': 'Padang', 'label': 'Padang'},
    {'key': 'Payakumbuh & 50 Kota', 'label': 'Payakumbuh & 50 Kota'},
    {'key': 'Bukittinggi & Agam', 'label': 'Bukittinggi'},
    {'key': 'Daerah Terpencil', 'label': 'Daerah Terpencil'},
  ];

  static const List<Map<String, String>> _barometerCategories = [
    {'key': 'ALL', 'label': 'Semua Biaya'},
    {'key': 'TIKET', 'label': 'Tiket Masuk'},
    {'key': 'PARKIR', 'label': 'Parkir Resmi'},
    {'key': 'FASILITAS', 'label': 'Sewa & Lokal'},
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

  List<SavedDestinationModel> get _savedDestinationsList {
    return kAllSumbarDestinations
        .where((d) => _savedIds.contains(d.id))
        .toList();
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
      _selectedSavedRegionFilter = 'ALL';
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
      _activeBarometerDestIdx = baroIndex;
      _activeTabIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Minimal Editorial Status Bar
            _buildEditorialStatusBar(),

            // 2. Global Static Offline Notification Banner (Item 6)
            if (_isOfflineMode)
              OfflineBanner(
                onRetry: () => setState(() => _isOfflineMode = false),
              ),

            // 3. Active Main View (4 Tabs: Daerah, Tersimpan, Tarif Resmi, Profil)
            Expanded(
              child: IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildExploreView(),
                  _buildSavedView(),
                  _buildBarometerView(),
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

  /// Minimal Editorial Status Bar (`09:41 | WISGO SUMBAR | Daring / Tanpa Sinyal`)
  Widget _buildEditorialStatusBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(
          bottom: BorderSide(
            color: AppColors.warmBorder.withValues(alpha: 0.70),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '09:41',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const Text(
            'WISGO SUMBAR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: AppColors.forest,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isOfflineMode = !_isOfflineMode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.creamSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warmBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isOfflineMode
                          ? AppColors.terracotta
                          : AppColors.brush,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isOfflineMode ? 'Tanpa Sinyal' : 'Daring',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _isOfflineMode
                          ? AppColors.terracotta
                          : AppColors.brush,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    return GestureDetector(
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

    return Column(
      children: [
        // Sticky Region & Nature Sub-Category Navigator Header
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
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DIREKTORI WILAYAH & BIAYA RESMI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            color: AppColors.brush,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Jelajah Daerah Sumbar',
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _openQrScannerModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, size: 13, color: AppColors.cream),
                              SizedBox(width: 4),
                              Text(
                                'Scan QR',
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filtered.length} Destinasi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick Trip Planner & Group Room Banner (ITEM 10, 11, 12)
              GestureDetector(
                onTap: _openTripPlannerModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.forest, AppColors.brush],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forest.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.route_rounded, color: AppColors.cream, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perencana Trip Rombongan',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Durasi hari, estimasi anggaran & tautan grup',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.sage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.sage,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Search Bar (REQUEST 2)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sageBorder),
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
                    hintText: 'Cari wisata, daerah, fasilitas (toilet, umkm)...',
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

              // Sort Mode Chips (REQUEST 2: Jarak Terdekat)
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

              const Text(
                'PILIH DAERAH / KABUPATEN-KOTA:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),

              // Primary Region Navigator Buttons
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
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.forest
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.forest
                                  : AppColors.sageBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reg['title']!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? AppColors.cream
                                      : AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reg['sub']!,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.cream.withValues(alpha: 0.80)
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

              const SizedBox(height: 8),

              // Secondary Nature / Terrain Sub-Category Navigator
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
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.sage
                                : AppColors.creamSubtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
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

        // Scrollable Destination Feed
        Expanded(
          child: Stack(
            children: [
              filtered.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
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
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildDestinationCard(
                            filtered[index],
                            isSavedContext: false,
                          ),
                        );
                      },
                    ),
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
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 1: LAYAR 04 — DESTINASI TERSIMPAN + SKELETON SHIMMER + EMPTY STATE
  // ===========================================================================
  Widget _buildSavedView() {
    final savedPlaces = _savedDestinationsList;
    final filteredSaved = _selectedSavedRegionFilter == 'ALL'
        ? savedPlaces
        : savedPlaces
            .where((p) => p.region == _selectedSavedRegionFilter)
            .toList();

    return Column(
      children: [
        // Screen Header + Clean State Controls
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
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAYAR 04 • MEMORI PERANGKAT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            color: AppColors.brush,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Destinasi Tersimpan',
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
                    child: Text(
                      '${_savedIds.length} Lokasi',
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

              // Clean In-Screen State Switcher (Segmented Control)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.creamSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStateSwitchButton(
                        label: 'Daftar (${_savedIds.length})',
                        isActive: _savedViewState == 'loaded',
                        onTap: () {
                          if (_savedIds.isEmpty) {
                            _savedIds = List<String>.from(kDefaultSavedIds);
                          }
                          setState(() => _savedViewState = 'loaded');
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildStateSwitchButton(
                        label: 'Efek Memuat',
                        isActive: _savedViewState == 'shimmer',
                        onTap: () =>
                            setState(() => _savedViewState = 'shimmer'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildStateSwitchButton(
                        label: 'Kosong',
                        isActive: _savedViewState == 'empty',
                        onTap: () => setState(() => _savedViewState = 'empty'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildStateSwitchButton(
                        label: _isOfflineMode ? 'Luring: Aktif' : 'Luring: Mati',
                        isActive: _isOfflineMode,
                        activeColor: AppColors.terracotta,
                        onTap: () =>
                            setState(() => _isOfflineMode = !_isOfflineMode),
                      ),
                    ),
                  ],
                ),
              ),

              // Region Navigator Bar inside Saved Places (only when loaded)
              if (_savedViewState == 'loaded') ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _savedRegionChips.map((chip) {
                      final isSelected =
                          _selectedSavedRegionFilter == chip['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _selectedSavedRegionFilter = chip['key']!,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.forest
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.forest
                                    : AppColors.sageBorder,
                              ),
                            ),
                            child: Text(
                              chip['label']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.cream
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
            ],
          ),
        ),

        // Scrollable Body of Layar 04
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              if (_savedViewState == 'shimmer')
                const SavedSkeletonShimmer(itemCount: 2)
              else if (_savedViewState == 'empty' || savedPlaces.isEmpty)
                SavedEmptyState(
                  onRestoreDefaultPressed: _restoreDefaultBookmarks,
                  onOpenExplorePressed: () =>
                      setState(() => _activeTabIndex = 0),
                )
              else if (filteredSaved.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Belum ada destinasi tersimpan untuk wilayah $_selectedSavedRegionFilter',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => setState(
                          () => _selectedSavedRegionFilter = 'ALL',
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.sage,
                          foregroundColor: AppColors.forest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Tampilkan Semua Daerah Tersimpan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredSaved.map(
                  (place) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildDestinationCard(
                      place,
                      isSavedContext: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStateSwitchButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color activeColor = AppColors.forest,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? AppColors.cream : AppColors.muted,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // VIEW 2: ITEM 7 — KOMPONEN TABEL FAIR-PRICE BAROMETER (VERTIKAL)
  // ===========================================================================
  Widget _buildBarometerView() {
    final activeDest = kAllSumbarDestinations[_activeBarometerDestIdx];

    return Column(
      children: [
        // Top Header & Destination Switcher
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PILAR 3 • ACUAN RESMI PERDA & DISHUB',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                            color: AppColors.brush,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rincian Biaya Resmi',
                          style: TextStyle(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: const Text(
                      'Anti-Pungli',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Destination Selector Pills (All 8 Destinations)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(kAllSumbarDestinations.length, (idx) {
                    final d = kAllSumbarDestinations[idx];
                    final isSelected = idx == _activeBarometerDestIdx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _activeBarometerDestIdx = idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.forest
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.forest
                                  : AppColors.sageBorder,
                            ),
                          ),
                          child: Text(
                            d.shortLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.cream
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),

              // Category Filter Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.creamSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                child: Row(
                  children: _barometerCategories.map((cat) {
                    final isSelected = _activeBarometerCategory == cat['key'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _activeBarometerCategory = cat['key']!,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.forest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cat['label']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.cream
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

        // Scrollable Barometer Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              FairPriceBarometerTable(
                destinationData: activeDest,
                selectedCategory: _activeBarometerCategory,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _openLaporPungliModal(tab: 'pungli'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.coralTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.terracotta),
                          SizedBox(width: 8),
                          Text(
                            'Temukan Pungli atau Fasilitas Rusak?',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                          ),
                        ],
                      ),
                      Text(
                        'Lapor GPS →',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.terracotta, decoration: TextDecoration.underline),
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

  // ===========================================================================
  // SHARED DESTINATION CARD (NO FEE TABLE ON INITIAL CARD - REQUEST 1 & 4)
  // ===========================================================================
  Widget _buildDestinationCard(
    SavedDestinationModel place, {
    required bool isSavedContext,
  }) {
    final isBookmarked = _savedIds.contains(place.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Image Header (h-40 = 160px)
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.forest),
                Image.network(
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.forest),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.ink.withValues(alpha: 0.88),
                        AppColors.ink.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Top Region & Nature Category Badges
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            place.categoryTag,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          place.natureType,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Image Overlay Title & Distance
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              place.subRegion,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.sage,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.brush.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${place.distanceKm.toStringAsFixed(place.distanceKm.truncateToDouble() == place.distanceKm ? 0 : 1)} km',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cream,
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

          // Card Content Body (Clean & User Friendly - NO FEE TABLE ON CARD)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating & Distance Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                          '(${place.reviewsCount} ulasan)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Jarak ${place.distanceKm.toStringAsFixed(place.distanceKm.truncateToDouble() == place.distanceKm ? 0 : 1)} km',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Fasilitas Lingkungan Chips (REQUEST 1)
                const Text(
                  'FASILITAS LINGKUNGAN:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: place.facilities.map((fac) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getFacilityIcon(fac), size: 12, color: AppColors.brush),
                          const SizedBox(width: 4),
                          Text(
                            fac,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Terrain & Route Access Info
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Info Medan: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      TextSpan(text: place.terrainNote),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: 360 & Denah + Detail & Pesan Tiket + Bookmark
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => _open360AndDenahModal(place),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.sage,
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.sageBorder),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.threed_rotation_rounded, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '360° & Denah',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
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
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Detail & Pesan',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _toggleBookmark(place.id),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isBookmarked ? AppColors.sage : Colors.white,
                        foregroundColor: isBookmarked ? AppColors.forest : AppColors.muted,
                        side: BorderSide(
                          color: isBookmarked ? AppColors.forest : AppColors.sageBorder,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 18,
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
            _openBookingCheckoutModal(place, total, breakdown);
          },
        );
      },
    );
  }

  // ===========================================================================
  // MODAL 3: CHECKOUT PEMESANAN RESMI (WISGO ESCROW & TIKET QR)
  // ===========================================================================
  void _openBookingCheckoutModal(
    SavedDestinationModel place,
    int total,
    String breakdown,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _BookingCheckoutSheet(
          place: place,
          total: total,
          breakdown: breakdown,
          onConfirmSuccess: () {
            Navigator.pop(ctx);
            _showAppToast('Tiket Resmi Berhasil Diterbitkan via Escrow!');
          },
        );
      },
    );
  }

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
          _showAppToast('Usulan destinasi "$name" berhasil diajukan ke Dispar Sumbar!');
        },
      ),
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

              // 2. Menu Fitur & Aktivitas Wisatawan (Vertikal)
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
                    const Text(
                      'AKTIVITAS & FITUR WISATAWAN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildProfileMenuTile(
                      title: 'Daftar Wisata Tersimpan (Layar 04)',
                      subtitle:
                          'Lihat ${_savedIds.length} bookmark wisata, efek shimmer, & mode luring',
                      badge: 'Buka',
                      onTap: () => setState(() => _activeTabIndex = 1),
                    ),
                    const Divider(height: 18, color: AppColors.warmBorder),
                    _buildProfileMenuTile(
                      title: 'Tabel Fair-Price Barometer (Pilar 3)',
                      subtitle:
                          'Cek tarif resmi tiket, parkir motor/mobil, & kalkulator biaya',
                      badge: 'Perda',
                      onTap: () => setState(() => _activeTabIndex = 2),
                    ),
                    const Divider(height: 18, color: AppColors.warmBorder),
                    _buildProfileMenuTile(
                      title: 'Simulasi Mode Tanpa Sinyal (Offline Banner)',
                      subtitle: _isOfflineMode
                          ? 'Banner notifikasi statis luring sedang ditampilkan di atas'
                          : 'Ketuk untuk menyalakan banner notifikasi tanpa internet',
                      badge: _isOfflineMode ? 'Aktif' : 'Uji',
                      isWarning: _isOfflineMode,
                      onTap: () {
                        setState(() => _isOfflineMode = !_isOfflineMode);
                        _showAppToast(
                          _isOfflineMode
                              ? 'Mode Tanpa Sinyal diaktifkan'
                              : 'Kembali ke mode Daring',
                        );
                      },
                    ),
                    const Divider(height: 18, color: AppColors.warmBorder),
                    _buildProfileMenuTile(
                      title: 'Paspor Digital Minang & Lencana Nagari',
                      subtitle:
                          '3 dari 10 stempel kunjungan nagari telah terkumpul',
                      badge: '3/10',
                      onTap: () => _showAppToast(
                        'Paspor Digital Minang: 3 Lencana Nagari aktif',
                      ),
                    ),
                    const Divider(height: 18, color: AppColors.warmBorder),
                    _buildProfileMenuTile(
                      title: 'Riwayat Laporan Ketidaksesuaian Tarif / Pungli',
                      subtitle:
                          'Pantau status laporan ke Dinas Pariwisata & Dishub',
                      badge: 'Aman',
                      onTap: () {
                        setState(() => _activeTabIndex = 2);
                        _showAppToast(
                          'Buka bagian bawah Tabel Tarif untuk melapor pungli',
                        );
                      },
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

  Widget _buildProfileMenuTile({
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
    bool isWarning = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isWarning ? AppColors.coralTint : AppColors.sage,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isWarning ? AppColors.terracotta : AppColors.forest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CURVED FLOATING-CIRCLE MOBILE NAVIGATION BAR (Sesuai Gambar 2)
  // ===========================================================================
  static const List<Map<String, dynamic>> _navItems = [
    {
      'label': 'Daerah',
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
    },
    {
      'label': 'Tersimpan',
      'icon': Icons.credit_card_outlined,
      'activeIcon': Icons.credit_card_rounded,
    },
    {
      'label': 'Tarif Resmi',
      'icon': Icons.account_balance_wallet_outlined,
      'activeIcon': Icons.account_balance_wallet_rounded,
    },
    {
      'label': 'Profil',
      'icon': Icons.account_circle_outlined,
      'activeIcon': Icons.account_circle_rounded,
    },
  ];

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
  double _yaw = 0.0;
  double _pitch = 0.0;

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
    return Stack(
      children: [
        // Pan gesture detector over panorama
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              setState(() {
                _yaw += details.delta.dx * 0.45;
                _pitch = (_pitch - details.delta.dy * 0.45).clamp(-35.0, 35.0);
              });
            },
            child: CustomPaint(
              painter: _Panorama360Painter(
                yaw: _yaw,
                pitch: _pitch,
                placeTitle: widget.place.title,
              ),
            ),
          ),
        ),

        // Floating Badges in 360 scene
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildScenePill('Tempat Parkir', Icons.local_parking_rounded),
              _buildScenePill('UMKM Kuliner Minang', Icons.restaurant_rounded),
              _buildScenePill('Toilet & Bilas', Icons.wc_rounded),
              _buildScenePill('Musholla', Icons.mosque_rounded),
            ],
          ),
        ),

        // Bottom gesture prompt
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
      ],
    );
  }

  Widget _buildScenePill(String label, IconData iconData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: AppColors.sage),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.cream,
            ),
          ),
        ],
      ),
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
  int _visitors = 2;
  int _motor = 0;
  int _mobil = 1;
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isBookmarked;
  }

  String _formatRupiah(int num) {
    return 'Rp ${num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final total = (_visitors * widget.place.calcRates.tiket) +
        (_motor * widget.place.calcRates.motor) +
        (_mobil * widget.place.calcRates.mobil);

    final parts = <String>[];
    if (_visitors > 0) parts.add('$_visitors Tiket');
    if (_motor > 0) parts.add('$_motor Motor');
    if (_mobil > 0) parts.add('$_mobil Mobil');
    final breakdown = parts.isNotEmpty ? parts.join(' + ') : '1 Tiket Masuk';

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
                          errorBuilder: (_, _, _) => Container(color: AppColors.forest),
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
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warmBorder),
                            ),
                            child: Text(
                              fac,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
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
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Ulasan Wisatawan Terverifikasi (REQUEST 1)
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
                        children: const [
                          Flexible(
                            child: Text(
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
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pengalaman Nyata',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(widget.place.reviews.length, (idx) {
                        final rev = widget.place.reviews[idx];
                        return Container(
                          padding: EdgeInsets.only(top: idx > 0 ? 10 : 0),
                          margin: EdgeInsets.only(top: idx > 0 ? 10 : 0),
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
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: AppColors.forest,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            rev.author.isNotEmpty ? rev.author.substring(0, 1) : 'U',
                                            style: const TextStyle(
                                              fontSize: 10,
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
                                                  fontSize: 11.5,
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
                                  Text(
                                    '★ ${rev.rating.toInt()}.0',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Text(
                                  '"${rev.comment}"',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
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
                const SizedBox(height: 14),

                // 4. Simulasi Hitung Tiket & Parkir
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
                        'SIMULASI HITUNG TIKET & PARKIR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tiket Pengunjung
                      _buildCalcStepperRow(
                        label: 'Tiket Pengunjung',
                        rateText: '${_formatRupiah(widget.place.calcRates.tiket)} / orang',
                        value: _visitors,
                        onDecrement: () => setState(() => _visitors = (_visitors - 1).clamp(0, 99)),
                        onIncrement: () => setState(() => _visitors++),
                      ),
                      const Divider(color: AppColors.warmBorder, height: 16),

                      // Parkir Motor
                      _buildCalcStepperRow(
                        label: 'Parkir Motor (Roda 2)',
                        rateText: '${_formatRupiah(widget.place.calcRates.motor)} / unit',
                        value: _motor,
                        onDecrement: () => setState(() => _motor = (_motor - 1).clamp(0, 99)),
                        onIncrement: () => setState(() => _motor++),
                      ),
                      const Divider(color: AppColors.warmBorder, height: 16),

                      // Parkir Mobil
                      _buildCalcStepperRow(
                        label: 'Parkir Mobil (Roda 4)',
                        rateText: '${_formatRupiah(widget.place.calcRates.mobil)} / unit',
                        value: _mobil,
                        onDecrement: () => setState(() => _mobil = (_mobil - 1).clamp(0, 99)),
                        onIncrement: () => setState(() => _mobil++),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Action Bar with Total & Pesan Tiket Button (REQUEST 4)
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
                      'Total Biaya Resmi',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      _formatRupiah(total),
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
                    onPressed: () => widget.onCheckout(total, breakdown),
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
                      'Pesan Tiket & Parkir Resmi',
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

  Widget _buildCalcStepperRow({
    required String label,
    required String rateText,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              rateText,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warmBorder),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// MODAL 3: CHECKOUT PEMESANAN RESMI (WISGO ESCROW & TIKET QR)
// =============================================================================

class _BookingCheckoutSheet extends StatefulWidget {
  final SavedDestinationModel place;
  final int total;
  final String breakdown;
  final VoidCallback onConfirmSuccess;

  const _BookingCheckoutSheet({
    required this.place,
    required this.total,
    required this.breakdown,
    required this.onConfirmSuccess,
  });

  @override
  State<_BookingCheckoutSheet> createState() => _BookingCheckoutSheetState();
}

class _BookingCheckoutSheetState extends State<_BookingCheckoutSheet> {
  int _paymentMethod = 0; // 0 = QRIS, 1 = Loket

  String _formatRupiah(int num) {
    return 'Rp ${num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PEMESANAN RESMI & ANTI-PUNGLI',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.brush,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Konfirmasi Pemesanan Tiket',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
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
          const SizedBox(height: 14),

          // Order summary
          Container(
            padding: const EdgeInsets.all(14),
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
                    const Text('Destinasi:', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    Text(
                      widget.place.title,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ],
                ),
                const Divider(color: AppColors.warmBorder, height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tanggal Kunjungan:', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    Text(
                      'Hari Ini • 13 Nov 2026',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ],
                ),
                const Divider(color: AppColors.warmBorder, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rincian Item:', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    Text(
                      widget.breakdown,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // WISGO Escrow protection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sage,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛡️', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proteksi WISGO Escrow Aktif',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dana Anda ditahan aman. Karcis resmi Perda dijamin terbit tanpa biaya tambahan liar di lapangan.',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.35,
                          color: AppColors.brush,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Payment Methods
          const Text(
            'PILIH METODE PEMBAYARAN RESMI:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 0 ? AppColors.creamSubtle : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 0 ? AppColors.forest : AppColors.sageBorder,
                        width: _paymentMethod == 0 ? 2 : 1,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QRIS Instan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        SizedBox(height: 2),
                        Text('BCA/Mandiri/GoPay', style: TextStyle(fontSize: 9.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMethod = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 1 ? AppColors.creamSubtle : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paymentMethod == 1 ? AppColors.forest : AppColors.sageBorder,
                        width: _paymentMethod == 1 ? 2 : 1,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bayar di Loket', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        SizedBox(height: 2),
                        Text('Kode Booking QR', style: TextStyle(fontSize: 9.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Tagihan Resmi', style: TextStyle(fontSize: 10.5, color: AppColors.sage)),
                    Text('Termasuk Asuransi Daerah', style: TextStyle(fontSize: 9.5, color: AppColors.cream)),
                  ],
                ),
                Text(
                  _formatRupiah(widget.total > 0 ? widget.total : 5000),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onConfirmSuccess,
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
                'Konfirmasi & Dapatkan Tiket Elektronik QR',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS: PANORAMA 360 & SITE PLAN DENAH
// =============================================================================

class _Panorama360Painter extends CustomPainter {
  final double yaw;
  final double pitch;
  final String placeTitle;

  _Panorama360Painter({
    required this.yaw,
    required this.pitch,
    required this.placeTitle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky & Horizon Gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF142618),
          Color(0xFF2F663E),
          Color(0xFF8EB897),
          Color(0xFFDFECE2),
          Color(0xFF193D22),
        ],
        stops: const [0.0, 0.35, 0.6, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, pitch * 2, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Stylized rolling mountains shifted by yaw
    final mountainPaint = Paint()
      ..color = const Color(0xFF193D22).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, h);
    final baseY = h * 0.65 + pitch * 1.5;
    for (double x = 0; x <= w; x += 15) {
      final rad = (x + yaw * 2.5) * 0.02;
      final y = baseY + (30 * (rad).remainder(1.0) * ((rad).toInt() % 2 == 0 ? 1 : -1));
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, mountainPaint);
  }

  @override
  bool shouldRepaint(covariant _Panorama360Painter oldDelegate) {
    return oldDelegate.yaw != yaw || oldDelegate.pitch != pitch;
  }
}

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
  if (lower.contains('toilet') || lower.contains('bilas')) return Icons.wc_rounded;
  if (lower.contains('kuliner') || lower.contains('warung') || lower.contains('makan')) return Icons.restaurant_rounded;
  if (lower.contains('musholla') || lower.contains('masjid')) return Icons.mosque_rounded;
  if (lower.contains('trekking') || lower.contains('jalan')) return Icons.hiking_rounded;
  if (lower.contains('rakit') || lower.contains('perahu') || lower.contains('danau')) return Icons.directions_boat_rounded;
  if (lower.contains('foto') || lower.contains('spot')) return Icons.camera_alt_rounded;
  if (lower.contains('camping') || lower.contains('kemah')) return Icons.cabin_rounded;
  if (lower.contains('sejarah') || lower.contains('istano')) return Icons.account_balance_rounded;
  if (lower.contains('pemandu') || lower.contains('guide')) return Icons.support_agent_rounded;
  return Icons.check_circle_outline_rounded;
}
