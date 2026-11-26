import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../data/destination_repository.dart';
import 'data/map_explore_pois_data.dart';
import 'modals/mountain_compass_modal.dart';
import 'widgets/sumbar_real_map_widget.dart';

/// Layar 03 · Jelajah Peta Interaktif, Cari Searah Rute (Shunlu), Peta Mikro & Kompas Gunung
/// Pilar 2: Navigasi Cerdas & Algoritma Amap
class MapExploreShunluScreen extends StatefulWidget {
  const MapExploreShunluScreen({super.key});

  @override
  State<MapExploreShunluScreen> createState() => _MapExploreShunluScreenState();
}

class _MapExploreShunluScreenState extends State<MapExploreShunluScreen> {
  final DestinationRepository _repository = DestinationRepository();
  bool _isMicroMapMode = false;
  String _selectedShunluFilter = 'RM Padang';
  String _selectedMicroFilter = 'Semua';
  final MapController _mapController = MapController();
  Map<String, dynamic>? _selectedPoi;
  SumbarMapLayer _activeMapLayer = SumbarMapLayer.jalan;

  // Geofence GPS Simulation (Pilar 2 — Radius <= 15m)
  bool _isGeofenceActive = false;
  bool _isGeofenceAudioPlaying = false;
  double _userDistanceToSpotMeters = 12.0;

  // Kompas Gunung Bearing Simulation
  double _compassHeadingDeg = 45.0; // Default menghadap Gunung Marapi

  // Data POI & koridor diekstrak ke MapExplorePoisData (modularitas desain.md)
  static const List<Map<String, dynamic>> _shunluPois = MapExplorePoisData.shunluPois;
  static const List<LatLng> _corridorPoints = MapExplorePoisData.corridorPoints;
  static const List<LatLng> _microMapPoints = MapExplorePoisData.microMapPoints;
  static const List<Map<String, dynamic>> _microMapPois = MapExplorePoisData.microMapPois;

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'RM Padang':
        return Icons.restaurant;
      case 'SPBU':
        return Icons.local_gas_station;
      case 'Masjid':
        return Icons.mosque;
      case 'ATM & Bengkel':
        return Icons.build_circle;
      case 'Gerbang & Loket':
        return Icons.door_sliding;
      case 'Budaya & Audio':
        return Icons.volume_up;
      case 'Air Terjun':
        return Icons.water_drop;
      case 'Eco-Trek':
        return Icons.hiking;
      default:
        return Icons.place;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'RM Padang':
        return AppColors.terracotta;
      case 'SPBU':
        return AppColors.warning;
      case 'Masjid':
        return AppColors.forest;
      case 'ATM & Bengkel':
        return AppColors.goldMinang;
      case 'Gerbang & Loket':
        return AppColors.forest;
      case 'Budaya & Audio':
        return AppColors.pinAudioEmas;
      case 'Air Terjun':
        return AppColors.pinNavigasiBiru;
      case 'Eco-Trek':
        return AppColors.success;
      default:
        return AppColors.forest;
    }
  }

  void _switchMode(bool microMode) {
    setState(() {
      _isMicroMapMode = microMode;
      _selectedPoi = null;
    });

    if (microMode) {
      _mapController.move(const LatLng(-0.1020, 100.6735), 15.8);
    } else {
      _mapController.move(const LatLng(-0.3800, 100.4100), 10.2);
    }
  }

  void _openMountainCompassSheet() {
    showMountainCompassModal(
      context: context,
      mountains: _repository.getMountainLandmarks(),
      initialHeadingDeg: _compassHeadingDeg,
      onHeadingChanged: (val) => setState(() => _compassHeadingDeg = val),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredShunlu = _shunluPois
        .where((p) => p['category'] == _selectedShunluFilter)
        .toList();

    final filteredMicro = _microMapPois.where((p) {
      if (_selectedMicroFilter == 'Semua') return true;
      return p['category'] == _selectedMicroFilter;
    }).toList();

    final activePois = _isMicroMapMode ? filteredMicro : filteredShunlu;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          _isMicroMapMode ? 'Peta Mikro Pejalan Kaki' : 'Jelajah Peta & Rute Shunlu',
        ),
        actions: [
          IconButton(
            tooltip: 'Kompas Visual Landmark Gunung',
            icon: const Icon(Icons.explore_outlined, color: AppColors.forest),
            onPressed: _openMountainCompassSheet,
          ),
          IconButton(
            tooltip: 'Fokus Ulang Peta',
            icon: const Icon(Icons.my_location, color: AppColors.forest),
            onPressed: () {
              if (_isMicroMapMode) {
                _mapController.move(const LatLng(-0.1020, 100.6735), 15.8);
              } else {
                _mapController.move(const LatLng(-0.3800, 100.4100), 10.5);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // MODE SWITCHER: Koridor Shunlu vs Peta Mikro Kawasan
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _switchMode(false),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isMicroMapMode ? AppColors.forest : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🛣️ Koridor Shunlu',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: !_isMicroMapMode ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _switchMode(true),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isMicroMapMode ? AppColors.forest : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🚶 Peta Mikro Kawasan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _isMicroMapMode ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RADAR GEOFENCE GPS AUDIO (RADIUS <= 15M)
          if (_isMicroMapMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: _isGeofenceActive ? AppColors.cream : Colors.white,
              child: Row(
                children: [
                  Icon(
                    _isGeofenceActive ? Icons.spatial_audio_rounded : Icons.radar_rounded,
                    color: _isGeofenceActive ? AppColors.warning : AppColors.forest,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isGeofenceActive
                          ? '📍 Radius ${_userDistanceToSpotMeters.toStringAsFixed(0)}m: Narasi Audio ${_isGeofenceAudioPlaying ? 'Diputar 🔊' : 'Dijeda ⏸️'}'
                          : 'Radar Geofence GPS (≤15m): Deteksi narasi audio otomatis',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isGeofenceActive ? AppColors.warning : AppColors.ink,
                      ),
                    ),
                  ),
                  if (_isGeofenceActive)
                    IconButton(
                      icon: Icon(
                        _isGeofenceAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: AppColors.warning,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _isGeofenceAudioPlaying = !_isGeofenceAudioPlaying);
                      },
                    ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isGeofenceActive = !_isGeofenceActive;
                        if (_isGeofenceActive) {
                          _isGeofenceAudioPlaying = true;
                          _userDistanceToSpotMeters = 12.0;
                          _selectedPoi = _microMapPois[1]; // Pondok Saluang
                          _mapController.move(const LatLng(-0.1025, 100.6725), 17.0);
                        } else {
                          _isGeofenceAudioPlaying = false;
                        }
                      });
                    },
                    child: Text(
                      _isGeofenceActive ? 'Matikan' : 'Simulasi GPS ≤15m',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // KANVAS PETA INTERAKTIF OPENSTREETMAP (FLUTTER_MAP V8)
          SizedBox(
            height: 290,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _isMicroMapMode
                        ? const LatLng(-0.1020, 100.6735)
                        : const LatLng(-0.3800, 100.4100),
                    initialZoom: _isMicroMapMode ? 15.8 : 10.2,
                    minZoom: 8.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _activeMapLayer.tileUrl,
                      userAgentPackageName: 'com.wisgo.rancakin',
                      maxZoom: 18,
                    ),
                    if (_activeMapLayer.labelOverlayUrl != null)
                      TileLayer(
                        urlTemplate: _activeMapLayer.labelOverlayUrl!,
                        userAgentPackageName: 'com.wisgo.rancakin',
                        maxZoom: 18,
                      ),
                    PolylineLayer(
                      polylines: [
                        if (!_isMicroMapMode)
                          Polyline(
                            points: _corridorPoints,
                            color: AppColors.forest.withValues(alpha: 0.85),
                            strokeWidth: 5.0,
                          )
                        else
                          Polyline(
                            points: _microMapPoints,
                            color: AppColors.success,
                            strokeWidth: 6.0,
                            pattern: StrokePattern.dashed(segments: const [12, 6]),
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: activePois.map((poi) {
                        final lat = poi['lat'] as double;
                        final lng = poi['lng'] as double;
                        final isSelected = _selectedPoi?['id'] == poi['id'];
                        final color = _categoryColor(poi['category'] as String);

                        return Marker(
                          point: LatLng(lat, lng),
                          width: 44,
                          height: 44,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                setState(() => _selectedPoi = poi);
                                _mapController.move(
                                  LatLng(lat, lng),
                                  _isMicroMapMode ? 16.5 : 12.5,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? color : Colors.white,
                                    width: isSelected ? 3.0 : 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.ink.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _categoryIcon(poi['category'] as String),
                                  color: isSelected ? color : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Map Layer Switcher (Jalan / Satelit / Medan)
                Positioned(
                  top: 56,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.16),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: SumbarMapLayer.values.map((layer) {
                        final active = _activeMapLayer == layer;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _activeMapLayer = layer),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
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
                                    size: 12,
                                    color: active ? Colors.white : AppColors.forest,
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  layer.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: active ? Colors.white : AppColors.ink,
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
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isMicroMapMode ? Icons.hiking : Icons.alt_route,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isMicroMapMode
                                ? 'Peta Mikro Pejalan Kaki: Jalur Sarasah Lembah Harau (1.8 km)'
                                : 'Koridor: Padang → Padang Panjang → Bukittinggi → Harau',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedPoi != null)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _categoryColor(
                              _selectedPoi!['category'] as String,
                            ),
                            child: Icon(
                              _categoryIcon(_selectedPoi!['category'] as String),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedPoi!['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _selectedPoi!['detour'] as String,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedPoi!['hasAudio'] == true)
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: AppColors.pinAudioEmas),
                              tooltip: 'Putar Pemandu Audio GPS (≤ 15m)',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.pinAudioEmas,
                                    content: Text(
                                      'Audio GPS aktif di radius ≤ 15m: ${_selectedPoi!['name']}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _selectedPoi = null),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // FILTER KATEGORI SESUAI MODE
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isMicroMapMode
                      ? 'Titik & Fasilitas Kawasan Harau'
                      : 'Pencarian Searah Rute (Shunlu Algorithm)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _isMicroMapMode
                        ? [
                            'Semua',
                            'Gerbang & Loket',
                            'Budaya & Audio',
                            'Air Terjun',
                            'Eco-Trek',
                          ].map((cat) {
                            final isSelected = _selectedMicroFilter == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppColors.forest,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.ink,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedMicroFilter = cat;
                                      _selectedPoi = null;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList()
                        : ['RM Padang', 'SPBU', 'Masjid', 'ATM & Bengkel'].map((cat) {
                            final isSelected = _selectedShunluFilter == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppColors.forest,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.ink,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedShunluFilter = cat;
                                      _selectedPoi = null;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // DAFTAR REKOMENDASI (LIST VIEW)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: activePois.length,
              itemBuilder: (ctx, i) {
                final poi = activePois[i];
                final color = _categoryColor(poi['category'] as String);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _selectedPoi?['id'] == poi['id']
                          ? color
                          : AppColors.warmBorder,
                      width: _selectedPoi?['id'] == poi['id'] ? 1.8 : 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _selectedPoi = poi);
                        final lat = poi['lat'] as double;
                        final lng = poi['lng'] as double;
                        _mapController.move(
                          LatLng(lat, lng),
                          _isMicroMapMode ? 16.5 : 12.5,
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(
                              _categoryIcon(poi['category'] as String),
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  poi['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  poi['route'] as String,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        poi['detour'] as String,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (poi['hasAudio'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.pinAudioEmas
                                              .withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          '🎧 Audio GPS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.pinAudioEmas,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => launchWisgoGoogleMapsRoute(
                              lat: poi['lat'] as double,
                              lng: poi['lng'] as double,
                              destinationName: poi['name'] as String,
                            ),
                            icon: const Icon(
                              Icons.near_me_rounded,
                              size: 18,
                              color: AppColors.forest,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            tooltip: 'Buka Rute di Google Maps',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
