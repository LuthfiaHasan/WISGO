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
    color: AppColors.info,
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
    color: AppColors.goldMinang,
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
    color: AppColors.brush,
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
    color: AppColors.warningDark,
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
    color: AppColors.warningDark,
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
    color: AppColors.danger,
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
    color: AppColors.info,
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
    color: AppColors.success,
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
    color: AppColors.forest,
    icon: Icons.terrain_rounded,
  ),
  SumbarMapDestination(
    id: 'masjid-raya-sumbar',
    name: 'Masjid Raya Syekh Ahmad Khatib',
    region: 'Padang Utara, Kota Padang',
    category: 'Sejarah & Budaya',
    distanceLabel: '3.2 km',
    durationLabel: '10 mnt',
    position: LatLng(-0.9242, 100.3624),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9242, 100.3624),
    ],
    color: AppColors.goldMinang,
    icon: Icons.mosque_rounded,
  ),
  SumbarMapDestination(
    id: 'pantai-air-manis',
    name: 'Pantai Air Manis & Malin Kundang',
    region: 'Padang Selatan, Kota Padang',
    category: 'Pantai & Budaya',
    distanceLabel: '10 km',
    durationLabel: '22 mnt',
    position: LatLng(-0.9906, 100.3596),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9906, 100.3596),
    ],
    color: AppColors.info,
    icon: Icons.beach_access_rounded,
  ),
  SumbarMapDestination(
    id: 'taplau-pantai-padang',
    name: 'Taplau Pantai Padang',
    region: 'Padang Barat, Kota Padang',
    category: 'Pantai & Bahari',
    distanceLabel: '2.5 km',
    durationLabel: '8 mnt',
    position: LatLng(-0.9378, 100.3504),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9378, 100.3504),
    ],
    color: AppColors.info,
    icon: Icons.waves_rounded,
  ),
  SumbarMapDestination(
    id: 'kota-tua-padang',
    name: 'Kota Tua & Jembatan Siti Nurbaya',
    region: 'Padang Selatan, Kota Padang',
    category: 'Sejarah & Budaya',
    distanceLabel: '3.5 km',
    durationLabel: '11 mnt',
    position: LatLng(-0.9636, 100.3609),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9636, 100.3609),
    ],
    color: AppColors.warningDark,
    icon: Icons.account_balance_rounded,
  ),
  SumbarMapDestination(
    id: 'pulau-pasumpahan',
    name: 'Pulau Pasumpahan',
    region: 'Bungus, Kota Padang',
    category: 'Pantai & Bahari',
    distanceLabel: '24 km',
    durationLabel: '55 mnt',
    position: LatLng(-1.1194, 100.3672),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-1.1194, 100.3672),
    ],
    color: AppColors.goldMinang,
    icon: Icons.sailing_rounded,
  ),
  SumbarMapDestination(
    id: 'museum-adityawarman',
    name: 'Museum Adityawarman',
    region: 'Padang Barat, Kota Padang',
    category: 'Sejarah & Budaya',
    distanceLabel: '1.8 km',
    durationLabel: '6 mnt',
    position: LatLng(-0.9539, 100.3556),
    routeFromPadang: [
      LatLng(-0.9471, 100.3543),
      LatLng(-0.9539, 100.3556),
    ],
    color: AppColors.warningDark,
    icon: Icons.museum_rounded,
  ),
];

/// Kategori filter cepat untuk Tab Peta Wisata Sumbar
enum SumbarMapCategory {
  semua('Semua', 'All', Icons.explore_rounded),
  pantai('Pantai & Bahari', 'Beach & Sea', Icons.sailing_rounded),
  gunung('Gunung & Alam', 'Mountain & Nature', Icons.terrain_rounded),
  airTerjun('Air Terjun', 'Waterfalls', Icons.water_drop_rounded),
  budaya('Budaya', 'Culture', Icons.account_balance_rounded);

  const SumbarMapCategory(this.labelId, this.labelEn, this.icon);
  final String labelId;
  final String labelEn;
  final IconData icon;

  String get label => AppLocale.isEn ? labelEn : labelId;

  bool matches(SumbarMapDestination dest) {
    if (this == SumbarMapCategory.semua) return true;
    final cat = dest.category.toLowerCase();
    switch (this) {
      case SumbarMapCategory.semua:
        return true;
      case SumbarMapCategory.pantai:
        return cat.contains('pantai') || cat.contains('bahari') || cat.contains('danau');
      case SumbarMapCategory.gunung:
        return cat.contains('gunung') ||
            cat.contains('puncak') ||
            cat.contains('hutan') ||
            cat.contains('lembah');
      case SumbarMapCategory.airTerjun:
        return cat.contains('air terjun');
      case SumbarMapCategory.budaya:
        return cat.contains('budaya') ||
            cat.contains('adat') ||
            cat.contains('sejarah') ||
            cat.contains('ikon');
    }
  }
}

/// Mengembalikan daftar destinasi peta yang sesuai dengan filter kategori aktif
List<SumbarMapDestination> filterSumbarMapDestinations(
  SumbarMapCategory category,
) {
  return kSumbarMapDestinations.where(category.matches).toList();
}

/// Helper terpusat untuk membuka rute destinasi di Google Maps secara ringan & stabil
/// (Android/iOS/Web). Menggunakan Universal Google Maps Directions URL agar langsung
/// membuka aplikasi Google Maps pada layar pratinjau rute (tidak freeze/lag menunggu
/// GPS lock seperti mode `google.navigation:` di emulator), dengan fallback `geo:`.
bool _isLaunchingExternalMaps = false;

Future<bool> launchWisgoGoogleMapsRoute({
  required double lat,
  required double lng,
  String? destinationName,
}) async {
  if (_isLaunchingExternalMaps) return false;
  _isLaunchingExternalMaps = true;
  try {
    final directionsUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      'travelmode': 'driving',
    });
    if (await launchUrl(directionsUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    final encodedLabel = Uri.encodeComponent(destinationName ?? '$lat,$lng');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedLabel)');
    if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    return await launchUrl(directionsUri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  } finally {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      _isLaunchingExternalMaps = false;
    });
  }
}

/// Helper terpusat untuk membuka pencarian lokasi sekitar di Google Maps (RM Padang, SPBU, Masjid, ATM)
Future<bool> launchWisgoGoogleMapsSearch(String query) async {
  if (_isLaunchingExternalMaps) return false;
  _isLaunchingExternalMaps = true;
  try {
    final searchUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    if (await launchUrl(searchUri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    final geoSearchUri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
    if (await launchUrl(geoSearchUri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return await launchUrl(searchUri, mode: LaunchMode.platformDefault);
  } catch (_) {
    return false;
  } finally {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      _isLaunchingExternalMaps = false;
    });
  }
}

/// Peta Interaktif Real Sumatera Barat menggunakan flutter_map + Esri Street / Satellite / Topo
class SumbarRealMapWidget extends StatefulWidget {
  const SumbarRealMapWidget({
    super.key,
    this.height = 310,
    this.destinations,
    this.selectedDestinationId,
    this.onDestinationSelected,
    this.onOpenDestinationDetail,
    this.onOpenFullShunlu,
    this.compactNavigationTitle,
    this.onLaunchGoogleMapsRoute,
    this.onOpenGoogleMapsHub,
    this.onInteractionChanged,
  });

  final double height;
  final List<SumbarMapDestination>? destinations;
  final String? selectedDestinationId;
  final ValueChanged<SumbarMapDestination>? onDestinationSelected;
  final ValueChanged<SumbarMapDestination>? onOpenDestinationDetail;
  final VoidCallback? onOpenFullShunlu;
  final String? compactNavigationTitle;
  final ValueChanged<SumbarMapDestination>? onLaunchGoogleMapsRoute;
  final VoidCallback? onOpenGoogleMapsHub;
  final ValueChanged<bool>? onInteractionChanged;

  @override
  State<SumbarRealMapWidget> createState() => _SumbarRealMapWidgetState();
}

class _SumbarRealMapWidgetState extends State<SumbarRealMapWidget> {
  final MapController _mapController = MapController();
  SumbarMapLayer _activeLayer = SumbarMapLayer.jalan;
  String? _selectedId;
  double _currentZoom = 8.4;
  int _activePointers = 0;

  void _handlePointerDelta(int delta) {
    final prevActive = _activePointers > 0;
    _activePointers = (_activePointers + delta).clamp(0, 10);
    final nextActive = _activePointers > 0;
    if (prevActive != nextActive) {
      widget.onInteractionChanged?.call(nextActive);
    }
  }

  static const LatLng _sumbarCenter = LatLng(-0.62, 100.43);

  Future<void> _launchGmapsRoute(SumbarMapDestination dest) async {
    if (widget.onLaunchGoogleMapsRoute != null) {
      widget.onLaunchGoogleMapsRoute!(dest);
      return;
    }
    await launchWisgoGoogleMapsRoute(
      lat: dest.position.latitude,
      lng: dest.position.longitude,
      destinationName: dest.name,
    );
  }

  List<SumbarMapDestination> get _visibleDestinations =>
      widget.destinations ?? kSumbarMapDestinations;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedDestinationId;
  }

  @override
  void didUpdateWidget(covariant SumbarRealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDestinationId != oldWidget.selectedDestinationId) {
      setState(() {
        _selectedId = widget.selectedDestinationId;
      });
      final target = _findById(widget.selectedDestinationId);
      if (target != null) {
        _focusDestination(target);
      }
    }
    if (_selectedId != null &&
        !_visibleDestinations.any((d) => d.id == _selectedId)) {
      setState(() {
        _selectedId = null;
      });
    }
  }

  SumbarMapDestination? _findById(String? id) {
    if (id == null) return null;
    for (final d in _visibleDestinations) {
      if (d.id == id) return d;
    }
    return null;
  }

  String _shortPinLabel(String name) {
    if (name.contains('&')) {
      return name.split('&').first.trim();
    }
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length <= 3) return name;
    return words.take(3).join(' ');
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
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warmBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.8),
        child: Stack(
          children: [
            // 1. REAL INTERACTIVE FLUTTER MAP (Support pinch-to-zoom 2 jari, drag, double-tap, scroll wheel)
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _handlePointerDelta(1),
              onPointerUp: (_) => _handlePointerDelta(-1),
              onPointerCancel: (_) => _handlePointerDelta(-1),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: selectedDest?.position ?? _sumbarCenter,
                  initialZoom: selectedDest != null ? 11.5 : 8.4,
                  minZoom: 6.5,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.scrollWheelZoom,
                  ),
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
                          color: AppColors.pinNavigasiBiru.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.pinNavigasiBiru,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.pinNavigasiBiru.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Marker Destinasi Asli Sumbar (tersaring sesuai kategori aktif)
                    ..._visibleDestinations.map((dest) {
                      final isSelected = dest.id == _selectedId;
                      return Marker(
                        point: dest.position,
                        width: isSelected ? 148 : 44,
                        height: isSelected ? 74 : 44,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              setState(() {
                                _selectedId = dest.id;
                              });
                              _focusDestination(dest);
                              widget.onDestinationSelected?.call(dest);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: isSelected ? 44 : 34,
                                  height: isSelected ? 44 : 34,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.terracotta
                                        : dest.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.ink.withValues(
                                          alpha: isSelected ? 0.32 : 0.22,
                                        ),
                                        blurRadius: isSelected ? 8 : 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    dest.icon,
                                    color: Colors.white,
                                    size: isSelected ? 20 : 15,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.96),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.terracotta.withValues(alpha: 0.35),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.ink.withValues(alpha: 0.14),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _shortPinLabel(dest.name),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            ),

            // 2. TOP RIGHT: Minimalist Map Layer Switcher (Jalan / Satelit / Medan)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: SumbarMapLayer.values.map((layer) {
                    final active = _activeLayer == layer;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _activeLayer = layer),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: active ? AppColors.forest : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            layer.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                              color: active ? Colors.white : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 3. RIGHT SIDE: Compact Zoom Pill & Recenter
            Positioned(
              right: 12,
              bottom: selectedDest != null ? 78 : 62,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _zoomBy(1.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: const SizedBox(
                            width: 34,
                            height: 32,
                            child: Icon(Icons.add_rounded, size: 17, color: AppColors.ink),
                          ),
                        ),
                        Container(width: 20, height: 1, color: AppColors.warmBorder),
                        InkWell(
                          onTap: () => _zoomBy(-1.2),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          child: const SizedBox(
                            width: 34,
                            height: 32,
                            child: Icon(Icons.remove_rounded, size: 17, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MapControlBtn(
                    icon: Icons.my_location_rounded,
                    tooltip: AppLocale.tr('Lihat Semua Sumbar', 'Reset Overview'),
                    onTap: _resetOverview,
                  ),
                ],
              ),
            ),

            // 4. BOTTOM FLOATING CARD (Clean & Minimalist)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: selectedDest != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: selectedDest.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              selectedDest.icon,
                              color: selectedDest.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${selectedDest.distanceLabel} • ${selectedDest.durationLabel}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (widget.onOpenDestinationDetail != null) ...[
                            Material(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => widget.onOpenDestinationDetail!(selectedDest),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    AppLocale.tr('Detail', 'Detail'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Material(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _launchGmapsRoute(selectedDest),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.near_me_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocale.tr('Rute', 'Route'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            onPressed: _resetOverview,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            padding: EdgeInsets.zero,
                            tooltip: AppLocale.tr('Tutup', 'Close'),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.touch_app_rounded,
                              color: AppColors.forest,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AppLocale.tr(
                                  'Ketuk pin untuk rute Google Maps',
                                  'Tap a pin for Google Maps route',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
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
