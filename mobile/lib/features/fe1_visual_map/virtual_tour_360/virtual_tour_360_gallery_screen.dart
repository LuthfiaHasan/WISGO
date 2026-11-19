import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/localization/app_locale.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';
import 'virtual_tour_360_screen.dart';

/// Galeri Pilihan Destinasi yang Mendukung Tur Virtual 360°
/// Tersinkronisasi dengan Backend BE-1 (`GET /api/v1/destinations` & `/scenes-360`)
/// dengan fallback mulus ke data Beranda lokal jika server BE sedang mati.
class VirtualTour360GalleryScreen extends StatefulWidget {
  final List<DestinationModel>? destinations;

  const VirtualTour360GalleryScreen({
    super.key,
    this.destinations,
  });

  @override
  State<VirtualTour360GalleryScreen> createState() =>
      _VirtualTour360GalleryScreenState();
}

class _VirtualTour360GalleryScreenState
    extends State<VirtualTour360GalleryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DestinationRepository _repository = DestinationRepository();

  List<DestinationModel> _allDestinations = const [];
  Set<String>? _beSyncedDestIds = <String>{};
  bool? _isBackendConnected = false;
  bool _isLoading = false;
  String _selectedFilter = 'ALL';
  String _query = '';

  Set<String> get _syncedIds => _beSyncedDestIds ?? const <String>{};
  bool get _backendConnected => _isBackendConnected ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.destinations != null && widget.destinations!.isNotEmpty) {
      _allDestinations = List<DestinationModel>.from(widget.destinations!);
    }
    _syncWithBackend();
  }

  Future<void> _syncWithBackend() async {
    if (_allDestinations.isEmpty) {
      setState(() => _isLoading = true);
    }

    // 1. Cek koneksi BE-1 (/api/v1/destinations)
    final liveDestRes = await _repository.fetchLiveDestinations();
    final List<DestinationModel> baseList = _allDestinations.isNotEmpty
        ? _allDestinations
        : liveDestRes.items;

    // 2. Cocokkan metadata BE-1 + tarik scenes-360 nyata dari BE-1 secara paralel
    final Set<String> syncedIds = <String>{};
    bool anySceneFromBackend = false;

    final enriched = await Future.wait(
      baseList.map((dest) async {
        final beId = DestinationRepository.resolveScenes360BackendId(dest);

        // Cocokkan data BE-1 jika tersedia (tanpa menghilangkan foto cover Beranda)
        DestinationModel merged = dest;
        if (liveDestRes.fromBackend) {
          final matchedBe = liveDestRes.items.where((b) {
            final bName = b.name.toLowerCase();
            final dName = dest.name.toLowerCase();
            return b.id == beId ||
                (dName.contains('harau') && bName.contains('harau')) ||
                (dName.contains('jam gadang') && bName.contains('jam gadang')) ||
                (dName.contains('pagaruyung') && bName.contains('pagaruyung')) ||
                (dName.contains('mandeh') && bName.contains('mandeh')) ||
                (dName.contains('maninjau') && bName.contains('maninjau')) ||
                (dName.contains('pariangan') && bName.contains('pariangan'));
          }).firstOrNull;

          if (matchedBe != null) {
            merged = DestinationModel(
              id: dest.id,
              name: dest.name,
              category: dest.category,
              cityRegency: matchedBe.cityRegency.isNotEmpty
                  ? matchedBe.cityRegency
                  : dest.cityRegency,
              description: matchedBe.description.isNotEmpty
                  ? matchedBe.description
                  : dest.description,
              latitude:
                  matchedBe.latitude != 0 ? matchedBe.latitude : dest.latitude,
              longitude: matchedBe.longitude != 0
                  ? matchedBe.longitude
                  : dest.longitude,
              coverImage: dest.coverImage.isNotEmpty
                  ? dest.coverImage
                  : matchedBe.coverImage,
              crowdLevel: matchedBe.crowdLevel,
              distanceKm: dest.distanceKm,
              travelTime: dest.travelTime,
              entryFee: matchedBe.entryFee.isNotEmpty
                  ? matchedBe.entryFee
                  : dest.entryFee,
              medanIndicator: matchedBe.medanIndicator ?? dest.medanIndicator,
              tips: matchedBe.tips.isNotEmpty ? matchedBe.tips : dest.tips,
              tariffs:
                  matchedBe.tariffs.isNotEmpty ? matchedBe.tariffs : dest.tariffs,
              scenes360: dest.scenes360,
            );
          }
        }

        // Tarik scenes-360 (aerial + ground + hotspots) dari BE-1
        final sceneRes = await _repository.fetchLiveScenes360(beId);
        if (sceneRes.scenes.isNotEmpty) {
          if (sceneRes.fromBackend) {
            anySceneFromBackend = true;
            syncedIds.add(merged.id);
          }
          return DestinationModel(
            id: merged.id,
            name: merged.name,
            category: merged.category,
            cityRegency: merged.cityRegency,
            description: merged.description,
            latitude: merged.latitude,
            longitude: merged.longitude,
            coverImage: merged.coverImage,
            crowdLevel: merged.crowdLevel,
            distanceKm: merged.distanceKm,
            travelTime: merged.travelTime,
            entryFee: merged.entryFee,
            medanIndicator: merged.medanIndicator,
            tips: merged.tips,
            tariffs: merged.tariffs,
            scenes360: sceneRes.scenes,
          );
        }

        return merged;
      }),
    );

    // Urutkan destinasi yang memiliki scene 360° asli dari BE-1 di bagian atas
    enriched.sort((a, b) {
      final aHas = a.scenes360.isNotEmpty ? 0 : 1;
      final bHas = b.scenes360.isNotEmpty ? 0 : 1;
      return aHas.compareTo(bHas);
    });

    if (!mounted) return;
    setState(() {
      _allDestinations = enriched;
      _beSyncedDestIds = syncedIds;
      _isBackendConnected = liveDestRes.fromBackend || anySceneFromBackend;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filters => [
        {'key': 'ALL', 'label': AppLocale.tr('Semua', 'All')},
        {'key': 'Air Terjun', 'label': AppLocale.tr('Air Terjun', 'Waterfalls')},
        {
          'key': 'Gunung',
          'label': AppLocale.tr('Lembah & Gunung', 'Valleys & Peaks'),
        },
        {'key': 'Pantai', 'label': AppLocale.tr('Bahari', 'Marine')},
        {'key': 'Nagari', 'label': AppLocale.tr('Budaya & Nagari', 'Culture')},
      ];

  List<DestinationModel> get _filteredDestinations {
    final q = _query.trim().toLowerCase();
    return _allDestinations.where((dest) {
      final catLower = '${dest.category} ${dest.name}'.toLowerCase();
      final matchesFilter = _selectedFilter == 'ALL' ||
          (_selectedFilter == 'Air Terjun' &&
              (catLower.contains('air terjun') ||
                  catLower.contains('lubuk') ||
                  catLower.contains('sarasah'))) ||
          (_selectedFilter == 'Gunung' &&
              (catLower.contains('gunung') ||
                  catLower.contains('lembah') ||
                  catLower.contains('ngarai') ||
                  catLower.contains('danau') ||
                  catLower.contains('harau') ||
                  catLower.contains('pinus'))) ||
          (_selectedFilter == 'Pantai' &&
              (catLower.contains('pantai') ||
                  catLower.contains('bahari') ||
                  catLower.contains('mandeh') ||
                  catLower.contains('pulau'))) ||
          (_selectedFilter == 'Nagari' &&
              (catLower.contains('nagari') ||
                  catLower.contains('budaya') ||
                  catLower.contains('istano') ||
                  catLower.contains('jam gadang') ||
                  catLower.contains('pariangan')));

      final matchesQuery = q.isEmpty ||
          dest.name.toLowerCase().contains(q) ||
          dest.cityRegency.toLowerCase().contains(q) ||
          dest.category.toLowerCase().contains(q);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  void _openVirtualTour(DestinationModel dest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VirtualTour360Screen(destination: dest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.notifier,
      builder: (context, _, __) {
        final items = _filteredDestinations;

        return Scaffold(
          backgroundColor: AppColors.cream100,
          appBar: AppBar(
            backgroundColor: AppColors.cream100,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.ink900,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.tr('Pilih Destinasi Tur 360°', 'Choose 360° Tour'),
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink900,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _backendConnected
                            ? const Color(0xFF1E9E5A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _backendConnected
                            ? AppLocale.tr(
                                '${_allDestinations.length} lokasi · Tersinkron BE-1',
                                '${_allDestinations.length} spots · Synced with BE-1',
                              )
                            : AppLocale.tr(
                                '${_allDestinations.length} lokasi Sumbar · Mode Lokal',
                                '${_allDestinations.length} West Sumatra spots · Local Mode',
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink900.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.ink900.withValues(alpha: 0.09),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.ink900,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocale.tr(
                        'Cari tempat wisata 360° (Harau, Mandeh, Sianok...)',
                        'Search 360° spots (Harau, Mandeh, Sianok...)',
                      ),
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.ink900.withValues(alpha: 0.42),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppColors.ink900.withValues(alpha: 0.48),
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final f = _filters[idx];
                    final active = _selectedFilter == f['key'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilter = f['key'] ?? 'ALL'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppColors.green800 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active
                                ? AppColors.green800
                                : AppColors.ink900.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          f['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.ink900,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Destination 360° Cards
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green800,
                        ),
                      )
                    : items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.threesixty_rounded,
                                    size: 46,
                                    color:
                                        AppColors.ink900.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    AppLocale.tr(
                                      'Destinasi 360° tidak ditemukan',
                                      'No matching 360° destination found',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, idx) =>
                                _buildPanoramaCard(items[idx]),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanoramaCard(DestinationModel dest) {
    final hasNetworkCover = dest.coverImage.startsWith('http');
    final isBeLive = _syncedIds.contains(dest.id);
    final sceneCount = dest.scenes360.isNotEmpty ? dest.scenes360.length : 2;
    final hotspotCount = dest.scenes360.fold<int>(
      0,
      (sum, s) => sum + s.hotspots.length,
    );

    return GestureDetector(
      onTap: () => _openVirtualTour(dest),
      child: Container(
        height: 205,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Panorama Photo
              if (hasNetworkCover)
                Image.network(
                  dest.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/panorama_sumbar_default.jpg',
                    fit: BoxFit.cover,
                  ),
                )
              else
                Image.asset(
                  'assets/images/panorama_sumbar_default.jpg',
                  fit: BoxFit.cover,
                ),

              // Editorial Gradient Overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.42, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.80),
                    ],
                  ),
                ),
              ),

              // Top Row: 360° Frosted Badge + BE-1 / Distance Pill
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassPill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.threesixty_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isBeLive
                                ? AppLocale.tr(
                                    '360° BE-1 · $sceneCount Scene · $hotspotCount Pin',
                                    '360° BE-1 · $sceneCount Scenes · $hotspotCount Pins',
                                  )
                                : AppLocale.tr(
                                    '360° · $sceneCount Mode',
                                    '360° · $sceneCount Views',
                                  ),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dest.distanceKm.isNotEmpty)
                      _buildGlassPill(
                        child: Text(
                          dest.distanceKm,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Row: Title + Location + Frosted Glass CTA
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dest.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  dest.cityRegency,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildGlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocale.tr('Lihat 360°', 'Explore 360°'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildGlassPill({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 6,
    ),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
