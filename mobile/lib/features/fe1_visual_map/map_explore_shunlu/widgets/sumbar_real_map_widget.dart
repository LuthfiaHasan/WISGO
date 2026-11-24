import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';

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
    this.onLaunchGoogleMapsRoute,
    this.onOpenGoogleMapsHub,
  });

  final double height;
  final String? selectedDestinationId;
  final ValueChanged<SumbarMapDestination>? onDestinationSelected;
  final VoidCallback? onOpenFullShunlu;
  final String? compactNavigationTitle;
  final ValueChanged<SumbarMapDestination>? onLaunchGoogleMapsRoute;
  final VoidCallback? onOpenGoogleMapsHub;

  @override
  State<SumbarRealMapWidget> createState() => _SumbarRealMapWidgetState();
}

class _SumbarRealMapWidgetState extends State<SumbarRealMapWidget> {
  final MapController _mapController = MapController();
  SumbarMapLayer _activeLayer = SumbarMapLayer.jalan;
  String? _selectedId;
  double _currentZoom = 8.4;

  static const LatLng _sumbarCenter = LatLng(-0.62, 100.43);

  Future<void> _launchGmapsRoute(SumbarMapDestination dest) async {
    if (widget.onLaunchGoogleMapsRoute != null) {
      widget.onLaunchGoogleMapsRoute!(dest);
      return;
    }
    final lat = dest.position.latitude;
    final lng = dest.position.longitude;
    final nativeUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _launchGmapsHub() async {
    if (widget.onOpenGoogleMapsHub != null) {
      widget.onOpenGoogleMapsHub!();
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=Wisata+Sumatera+Barat');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedDestinationId;
  }

  @override
  void didUpdateWidget(covariant SumbarRealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDestinationId != oldWidget.selectedDestinationId &&
        widget.selectedDestinationId != null) {
      setState(() {
        _selectedId = widget.selectedDestinationId;
      });
      final target = _findById(widget.selectedDestinationId);
      if (target != null) {
        _focusDestination(target);
      }
    }
  }

  SumbarMapDestination? _findById(String? id) {
    if (id == null) return null;
    for (final d in kSumbarMapDestinations) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _focusDestination(SumbarMapDestination dest) {
    _currentZoom = 11.5;
    try {
      _mapController.move(dest.position, _currentZoom);
    } catch (_) {}
  }

  void _resetOverview() {
    setState(() {
      _selectedId = null;
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

  @override
  Widget build(BuildContext context) {
    final selectedDest = _findById(_selectedId);

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
            // 1. REAL INTERACTIVE FLUTTER MAP (Ringan: tanpa garis rute / OSRM tracking)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: selectedDest?.position ?? _sumbarCenter,
                initialZoom: selectedDest != null ? 11.5 : 8.4,
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
                            });
                            _focusDestination(dest);
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
                      widget.compactNavigationTitle ??
                          '${AppLocale.tr('10 Destinasi', '10 Destinations')} • ${_activeLayer.label}',
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
              bottom: 68,
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
                  const SizedBox(height: 5),
                  _MapControlBtn(
                    icon: Icons.map_rounded,
                    tooltip: AppLocale.tr('Buka Peta Wisata di Google Maps', 'Open Tourist Map in Google Maps'),
                    onTap: _launchGmapsHub,
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
                                      '${selectedDest.region} • ${selectedDest.distanceLabel} (${selectedDest.durationLabel})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _launchGmapsRoute(selectedDest),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A73E8),
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.navigation_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocale.tr('Rute GMaps', 'GMaps Route'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: AppColors.forest,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocale.tr(
                                'Ketuk pin destinasi untuk rute langsung ke Google Maps.',
                                'Tap any destination pin for direct Google Maps route.',
                              ),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _launchGmapsHub,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A73E8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.map_rounded, size: 11, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocale.tr('Buka GMaps', 'Open GMaps'),
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
