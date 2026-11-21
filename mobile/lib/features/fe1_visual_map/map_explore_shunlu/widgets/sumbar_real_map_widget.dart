import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../services/osrm_route_service.dart';

/// Gaya peta real (tanpa perlu API Key berbayar)
enum SumbarMapLayer {
  jalan('Jalan', 'Street', Icons.map_rounded),
  satelit('Satelit', 'Satellite', Icons.satellite_alt_rounded),
  medan('Medan', 'Terrain', Icons.terrain_rounded);

  const SumbarMapLayer(this.labelId, this.labelEn, this.icon);
  final String labelId;
  final String labelEn;
  final IconData icon;

  String get label => AppLocale.isEn ? labelEn : labelId;

  String get tileUrl {
    switch (this) {
      case SumbarMapLayer.jalan:
        // Esri World Street Map: peta jalan nyata modern, tajam, bebas API Key & watermark
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
      case SumbarMapLayer.satelit:
        // Esri World Imagery: citra satelit bumi resolusi tinggi sungguhan
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case SumbarMapLayer.medan:
        // Esri World Topo Map: kontur pegunungan, lembah, sungai & elevasi Sumbar
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  /// Overlay nama kota & tempat transparan khusus untuk mode Satelit (Hybrid)
  String? get labelOverlayUrl {
    if (this == SumbarMapLayer.satelit) {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';
    }
    return null;
  }
}

class SumbarMapDestination {
  const SumbarMapDestination({
    required this.id,
    required this.name,
    required this.region,
    required this.category,
    required this.distanceLabel,
    required this.durationLabel,
    required this.position,
    required this.routeFromPadang,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String region;
  final String category;
  final String distanceLabel;
  final String durationLabel;
  final LatLng position;
  final List<LatLng> routeFromPadang;
  final Color color;
  final IconData icon;
}

/// Lokasi GPS pengguna saat ini (Pusat Kota Padang)
const LatLng kPadangUserPosition = LatLng(-0.9471, 100.3543);

/// Koordinat GPS asli 10 destinasi wisata unggulan Sumatera Barat + rute arteri realistis
const List<SumbarMapDestination> kSumbarMapDestinations = [
  SumbarMapDestination(
    id: 'gunung-padang',
    name: 'Taman Siti Nurbaya & Gunung Padang',
    region: 'Padang Selatan',
    category: 'Gunung & Puncak',
    distanceLabel: '4.5 km',
    durationLabel: '12 mnt',
    position: LatLng(-0.9628, 100.3547),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9548, 100.3562),
      LatLng(-0.9602, 100.3578),
      LatLng(-0.9628, 100.3547),
    ],
    color: AppColors.forest,
    icon: Icons.landscape_rounded,
  ),
  SumbarMapDestination(
    id: 'lubuk-hitam-padang',
    name: 'Air Terjun Lubuk Hitam 3 Tingkat',
    region: 'Bungus, Padang',
    category: 'Air Terjun',
    distanceLabel: '18 km',
    durationLabel: '35 mnt',
    position: LatLng(-1.0086, 100.4284),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9675, 100.3820),
      LatLng(-0.9890, 100.4025),
      LatLng(-1.0086, 100.4284),
    ],
    color: Color(0xFF1E5B82),
    icon: Icons.water_drop_rounded,
  ),
  SumbarMapDestination(
    id: 'kawasan-mandeh',
    name: 'Kawasan Wisata Bahari Mandeh',
    region: 'Pesisir Selatan',
    category: 'Pantai & Bahari',
    distanceLabel: '56 km',
    durationLabel: '1 jam 15 mnt',
    position: LatLng(-1.2016, 100.4158),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9890, 100.4025),
      LatLng(-1.0640, 100.4190),
      LatLng(-1.1320, 100.4420),
      LatLng(-1.2016, 100.4158),
    ],
    color: Color(0xFFC89242),
    icon: Icons.sailing_rounded,
  ),
  SumbarMapDestination(
    id: 'nyarai-terpencil',
    name: 'Air Terjun Nyarai Gamaran',
    region: 'Padang Pariaman',
    category: 'Hutan & Air Terjun',
    distanceLabel: '42 km',
    durationLabel: '1 jam 10 mnt',
    position: LatLng(-0.6736, 100.3208),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.8310, 100.3390),
      LatLng(-0.6870, 100.2890),
      LatLng(-0.6736, 100.3208),
    ],
    color: Color(0xFF0F766E),
    icon: Icons.forest_rounded,
  ),
  SumbarMapDestination(
    id: 'pariangan-terpencil',
    name: 'Nagari Tuo Pariangan',
    region: 'Tanah Datar',
    category: 'Nagari Adat',
    distanceLabel: '82 km',
    durationLabel: '2 jam',
    position: LatLng(-0.4539, 100.4932),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.6870, 100.2890),
      LatLng(-0.4640, 100.3988),
      LatLng(-0.4539, 100.4932),
    ],
    color: Color(0xFFB45309),
    icon: Icons.temple_buddhist_rounded,
  ),
  SumbarMapDestination(
    id: 'istano-basa-pagaruyung',
    name: 'Istano Basa Pagaruyung',
    region: 'Batusangkar, Tanah Datar',
    category: 'Sejarah & Budaya',
    distanceLabel: '98 km',
    durationLabel: '2 jam 25 mnt',
    position: LatLng(-0.4713, 100.6214),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.6870, 100.2890),
      LatLng(-0.4640, 100.3988),
      LatLng(-0.4539, 100.4932),
      LatLng(-0.4713, 100.6214),
    ],
    color: Color(0xFF9A3412),
    icon: Icons.account_balance_rounded,
  ),
  SumbarMapDestination(
    id: 'jam-gadang-ngarai',
    name: 'Jam Gadang & Ngarai Sianok',
    region: 'Bukittinggi',
    category: 'Ikon & Panorama',
    distanceLabel: '93 km',
    durationLabel: '2 jam 15 mnt',
    position: LatLng(-0.3051, 100.3692),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.6870, 100.2890),
      LatLng(-0.4640, 100.3988),
      LatLng(-0.3800, 100.3850),
      LatLng(-0.3051, 100.3692),
    ],
    color: Color(0xFFDC2626),
    icon: Icons.location_city_rounded,
  ),
  SumbarMapDestination(
    id: 'danau-maninjau',
    name: 'Danau Maninjau & Kelok 44',
    region: 'Kabupaten Agam',
    category: 'Danau & Panorama',
    distanceLabel: '112 km',
    durationLabel: '2 jam 50 mnt',
    position: LatLng(-0.3125, 100.1869),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.6870, 100.2890),
      LatLng(-0.4640, 100.3988),
      LatLng(-0.3051, 100.3692),
      LatLng(-0.2780, 100.2610),
      LatLng(-0.3125, 100.1869),
    ],
    color: Color(0xFF0284C7),
    icon: Icons.water_rounded,
  ),
  SumbarMapDestination(
    id: 'kapalo-banda-taram',
    name: 'Kapalo Banda Taram',
    region: 'Lima Puluh Kota',
    category: 'Hutan Pinus & Air',
    distanceLabel: '132 km',
    durationLabel: '3 jam 15 mnt',
    position: LatLng(-0.2007, 100.7131),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.6870, 100.2890),
      LatLng(-0.4640, 100.3988),
      LatLng(-0.3051, 100.3692),
      LatLng(-0.2230, 100.6320),
      LatLng(-0.2007, 100.7131),
    ],
    color: Color(0xFF15803D),
    icon: Icons.park_rounded,
  ),
  SumbarMapDestination(
    id: 'lembah-harau',
    name: 'Lembah Harau & Sarasah Bunta',
    region: 'Lima Puluh Kota',
    category: 'Lembah & Air Terjun',
    distanceLabel: '138 km',
    durationLabel: '3 jam 25 mnt',
    position: LatLng(-0.1023, 100.6728),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.6870, 100.2890),
      LatLng(-0.4640, 100.3988),
      LatLng(-0.3051, 100.3692),
      LatLng(-0.2230, 100.6320),
      LatLng(-0.1023, 100.6728),
    ],
    color: Color(0xFF166534),
    icon: Icons.terrain_rounded,
  ),
];

/// Peta Interaktif Real Sumatera Barat menggunakan flutter_map + Carto Voyager / Esri Satellite / Esri Topo
class SumbarRealMapWidget extends StatefulWidget {
  const SumbarRealMapWidget({
    super.key,
    this.height = 310,
    this.selectedDestinationId,
    this.onDestinationSelected,
    this.onOpenFullShunlu,
    this.compactNavigationTitle,
  });

  final double height;
  final String? selectedDestinationId;
  final ValueChanged<SumbarMapDestination>? onDestinationSelected;
  final VoidCallback? onOpenFullShunlu;
  final String? compactNavigationTitle;

  @override
  State<SumbarRealMapWidget> createState() => _SumbarRealMapWidgetState();
}

class _SumbarRealMapWidgetState extends State<SumbarRealMapWidget> {
  final MapController _mapController = MapController();
  SumbarMapLayer _activeLayer = SumbarMapLayer.jalan;
  String? _selectedId;
  double _currentZoom = 8.4;

  // State rute jalan raya nyata (OSRM — mengikuti jalan sungguhan + alternatif)
  List<RoadRouteOption>? _roadRoutes;
  int _activeRouteIndex = 0;
  bool _isLoadingRoute = false;

  static const LatLng _sumbarCenter = LatLng(-0.62, 100.43);

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedDestinationId;
    final initial = _findById(_selectedId);
    if (initial != null) {
      _loadRoadRouteFor(initial);
    }
  }

  @override
  void didUpdateWidget(covariant SumbarRealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDestinationId != oldWidget.selectedDestinationId &&
        widget.selectedDestinationId != null) {
      setState(() {
        _selectedId = widget.selectedDestinationId;
        _activeRouteIndex = 0;
      });
      final target = _findById(widget.selectedDestinationId);
      if (target != null) {
        _focusDestination(target);
        _loadRoadRouteFor(target);
      }
    }
  }

  Future<void> _loadRoadRouteFor(SumbarMapDestination dest) async {
    final cached = OsrmRouteService.getCached(kPadangUserPosition, dest.position);
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _roadRoutes = cached;
        _activeRouteIndex = 0;
        _isLoadingRoute = false;
      });
      _fitRouteBounds(cached.first.points);
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _roadRoutes = null;
      _activeRouteIndex = 0;
    });

    final routes = await OsrmRouteService.fetchRoutes(
      origin: kPadangUserPosition,
      destination: dest.position,
    );

    if (!mounted || _selectedId != dest.id) return;
    setState(() {
      _roadRoutes = routes;
      _activeRouteIndex = 0;
      _isLoadingRoute = false;
    });
    if (routes != null && routes.isNotEmpty) {
      _fitRouteBounds(routes.first.points);
    }
  }

  void _fitRouteBounds(List<LatLng> points) {
    if (points.length < 2) return;
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(34, 52, 48, 108),
        ),
      );
    } catch (_) {}
  }

  SumbarMapDestination? _findById(String? id) {
    if (id == null) return null;
    for (final d in kSumbarMapDestinations) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _focusDestination(SumbarMapDestination dest) {
    final midLat = (kPadangUserPosition.latitude + dest.position.latitude) / 2;
    final midLng = (kPadangUserPosition.longitude + dest.position.longitude) / 2;
    final dist = const Distance().as(
      LengthUnit.Kilometer,
      kPadangUserPosition,
      dest.position,
    );
    final zoom = dist < 10
        ? 13.0
        : dist < 30
            ? 11.2
            : dist < 70
                ? 9.8
                : 8.8;
    _currentZoom = zoom;
    try {
      _mapController.move(LatLng(midLat, midLng), zoom);
    } catch (_) {}
  }

  void _resetOverview() {
    setState(() {
      _selectedId = null;
      _roadRoutes = null;
      _activeRouteIndex = 0;
      _isLoadingRoute = false;
    });
    _currentZoom = 8.4;
    try {
      _mapController.move(_sumbarCenter, _currentZoom);
    } catch (_) {}
  }

  void _zoomBy(double delta) {
    _currentZoom = (_currentZoom + delta).clamp(6.5, 17.5);
    try {
      _mapController.move(_mapController.camera.center, _currentZoom);
    } catch (_) {}
  }

  void _openTurnByTurnSheet(
    SumbarMapDestination dest,
    RoadRouteOption route,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.88,
          expand: false,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.warmBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dest.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${route.formattedDistance} • ${route.formattedDuration} • ${AppLocale.tr('Jalur Jalan Nyata', 'Real Road Route')}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.warmBorder),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: route.steps.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 48,
                        color: AppColors.warmBorder,
                      ),
                      itemBuilder: (_, idx) {
                        final step = route.steps[idx];
                        final isFirstOrLast =
                            idx == 0 || idx == route.steps.length - 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isFirstOrLast
                                      ? AppColors.sage
                                      : const Color(0xFFE8F0FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  step.icon,
                                  size: 18,
                                  color: isFirstOrLast
                                      ? AppColors.forest
                                      : const Color(0xFF1A73E8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.instruction,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    if (step.distanceMeters > 0)
                                      Text(
                                        step.formattedDistance,
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

  @override
  Widget build(BuildContext context) {
    final selectedDest = _findById(_selectedId);

    // Garis arteri utama Trans-Sumatera (tampil saat overview belum memilih satu tujuan)
    final mainArtery = kSumbarMapDestinations
        .firstWhere((d) => d.id == 'lembah-harau')
        .routeFromPadang;

    final routes = _roadRoutes;
    final hasRealRoutes =
        selectedDest != null && routes != null && routes.isNotEmpty;
    final safeRouteIdx =
        hasRealRoutes ? _activeRouteIndex.clamp(0, routes.length - 1) : 0;
    final activeRoadRoute = hasRealRoutes ? routes[safeRouteIdx] : null;

    final activePolylinePoints =
        activeRoadRoute?.points ?? selectedDest?.routeFromPadang ?? mainArtery;

    // Susun polyline: rute alternatif (abu-biru lembut) di bawah, rute aktif (biru Google Maps) di atas
    final polylines = <Polyline>[];
    if (hasRealRoutes && routes.length > 1) {
      for (var i = 0; i < routes.length; i++) {
        if (i == safeRouteIdx) continue;
        polylines.add(
          Polyline(
            points: routes[i].points,
            strokeWidth: 7.0,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );
        polylines.add(
          Polyline(
            points: routes[i].points,
            strokeWidth: 4.2,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.92),
          ),
        );
      }
    }

    // Rute utama terpilih (mengikuti jalan nyata seperti Google Maps!)
    polylines.addAll([
      Polyline(
        points: activePolylinePoints,
        strokeWidth: selectedDest != null ? 8.2 : 6.0,
        color: selectedDest != null
            ? const Color(0xFF0F4C81).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
      ),
      Polyline(
        points: activePolylinePoints,
        strokeWidth: selectedDest != null ? 5.2 : 3.5,
        color: selectedDest != null
            ? const Color(0xFF1A73E8)
            : AppColors.forest,
      ),
    ]);

    // Langkah belokan pertama yang bermakna untuk preview di kartu bawah
    RoadRouteStep? nextTurnStep;
    if (activeRoadRoute != null && activeRoadRoute.steps.length > 1) {
      nextTurnStep = activeRoadRoute.steps[1];
    } else if (activeRoadRoute != null && activeRoadRoute.steps.isNotEmpty) {
      nextTurnStep = activeRoadRoute.steps.first;
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5EDE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5),
        child: Stack(
          children: [
            // 1. REAL INTERACTIVE FLUTTER MAP (Esri Street / Satellite Hybrid / Topo)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selectedDest != null
                    ? LatLng(
                        (kPadangUserPosition.latitude +
                                selectedDest.position.latitude) /
                            2,
                        (kPadangUserPosition.longitude +
                                selectedDest.position.longitude) /
                            2,
                      )
                    : _sumbarCenter,
                initialZoom: selectedDest != null ? 10.8 : 8.4,
                minZoom: 6.5,
                maxZoom: 18.0,
                onPositionChanged: (pos, _) {
                  _currentZoom = pos.zoom;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _activeLayer.tileUrl,
                  userAgentPackageName: 'com.wisgo.rancakin',
                  maxZoom: 18,
                ),
                if (_activeLayer.labelOverlayUrl != null)
                  TileLayer(
                    urlTemplate: _activeLayer.labelOverlayUrl!,
                    userAgentPackageName: 'com.wisgo.rancakin',
                    maxZoom: 18,
                  ),

                // Polyline Rute Jalan Nyata (OSRM + Alternatif seperti Google Maps)
                PolylineLayer(polylines: polylines),

                // Markers: Lokasi Pengguna + 10 Destinasi Sumbar
                MarkerLayer(
                  markers: [
                    // Lokasi Pengguna (Blue GPS Dot)
                    Marker(
                      point: kPadangUserPosition,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 10 Marker Destinasi Asli Sumbar
                    ...kSumbarMapDestinations.map((dest) {
                      final isSelected = dest.id == _selectedId;
                      return Marker(
                        point: dest.position,
                        width: isSelected ? 46 : 34,
                        height: isSelected ? 46 : 34,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedId = dest.id;
                              _activeRouteIndex = 0;
                            });
                            _focusDestination(dest);
                            _loadRoadRouteFor(dest);
                            widget.onDestinationSelected?.call(dest);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE55934) : dest.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              dest.icon,
                              color: Colors.white,
                              size: isSelected ? 21 : 15,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            // 2. TOP LEFT: Live Status Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingRoute)
                      const SizedBox(
                        width: 9,
                        height: 9,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: Color(0xFF1A73E8),
                        ),
                      )
                    else
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 5),
                    Text(
                      _isLoadingRoute
                          ? AppLocale.tr(
                              'Mencari jalur jalan...',
                              'Finding road route...',
                            )
                          : (widget.compactNavigationTitle ??
                              '${AppLocale.tr('10 Destinasi', '10 Destinations')} • ${_activeLayer.label}'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. TOP RIGHT: Map Layer Switcher (Jalan / Satelit / Medan)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: SumbarMapLayer.values.map((layer) {
                    final active = _activeLayer == layer;
                    return GestureDetector(
                      onTap: () => setState(() => _activeLayer = layer),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppColors.forest : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              layer.icon,
                              size: 11,
                              color: active ? Colors.white : AppColors.forest,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              layer.label,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: active ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 4. RIGHT SIDE: Zoom (+ / -) & Recenter Buttons
            Positioned(
              right: 10,
              bottom: selectedDest != null && activeRoadRoute != null ? 112 : 68,
              child: Column(
                children: [
                  _MapControlBtn(
                    icon: Icons.add_rounded,
                    tooltip: AppLocale.tr('Perbesar Peta', 'Zoom In'),
                    onTap: () => _zoomBy(1.2),
                  ),
                  const SizedBox(height: 5),
                  _MapControlBtn(
                    icon: Icons.remove_rounded,
                    tooltip: AppLocale.tr('Perkecil Peta', 'Zoom Out'),
                    onTap: () => _zoomBy(-1.2),
                  ),
                  const SizedBox(height: 5),
                  _MapControlBtn(
                    icon: Icons.my_location_rounded,
                    tooltip: AppLocale.tr('Lihat Semua Sumbar', 'Reset Overview'),
                    onTap: _resetOverview,
                  ),
                ],
              ),
            ),

            // 5. BOTTOM FLOATING NAVIGATION STRIP (Gaya Google Maps: Jarak Real, Pilihan Jalur & Panduan Belokan)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sageBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: selectedDest != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: selectedDest.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  selectedDest.icon,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedDest.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      activeRoadRoute != null
                                          ? '${activeRoadRoute.formattedDistance} • ${activeRoadRoute.formattedDuration} (${safeRouteIdx == 0 ? AppLocale.tr('Jalur Tercepat', 'Fastest Route') : AppLocale.tr('Jalur Alternatif', 'Alt. Route')})'
                                          : '${selectedDest.region} • ${selectedDest.distanceLabel} (${selectedDest.durationLabel})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: activeRoadRoute != null
                                            ? const Color(0xFF1A73E8)
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (activeRoadRoute != null)
                                GestureDetector(
                                  onTap: () => _openTurnByTurnSheet(
                                    selectedDest,
                                    activeRoadRoute,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A73E8),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.directions_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          AppLocale.tr('Arahkan', 'Guide'),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (widget.onOpenFullShunlu != null)
                                GestureDetector(
                                  onTap: widget.onOpenFullShunlu,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.forest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      AppLocale.tr('Rute →', 'Route →'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Preview Belokan Berikutnya + Pilihan Jalur Alternatif (jika tersedia)
                          if (nextTurnStep != null ||
                              (hasRealRoutes && routes.length > 1)) ...[
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                if (nextTurnStep != null)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _openTurnByTurnSheet(
                                        selectedDest,
                                        activeRoadRoute!,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            nextTurnStep.icon,
                                            size: 13,
                                            color: const Color(0xFF1A73E8),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              nextTurnStep.instruction,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (hasRealRoutes && routes.length > 1) ...[
                                  const SizedBox(width: 6),
                                  ...List.generate(routes.length, (rIdx) {
                                    final isPick = rIdx == safeRouteIdx;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _activeRouteIndex = rIdx);
                                          _fitRouteBounds(routes[rIdx].points);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.5,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPick
                                                ? const Color(0xFF1A73E8)
                                                : AppColors.creamSubtle,
                                            borderRadius:
                                                BorderRadius.circular(7),
                                            border: Border.all(
                                              color: isPick
                                                  ? const Color(0xFF1A73E8)
                                                  : AppColors.warmBorder,
                                            ),
                                          ),
                                          child: Text(
                                            '${AppLocale.tr('Jalur', 'R')}${rIdx + 1}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: isPick
                                                  ? Colors.white
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: AppColors.forest,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocale.tr(
                                'Ketuk pin destinasi untuk melihat jalur jalan raya tercepat & panduan arah.',
                                'Tap any destination pin to get the fastest real road route & directions.',
                              ),
                              style: const TextStyle(
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
    );
  }
}

class _MapControlBtn extends StatelessWidget {
  const _MapControlBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 17, color: AppColors.forest),
          ),
        ),
      ),
    );
  }
}
