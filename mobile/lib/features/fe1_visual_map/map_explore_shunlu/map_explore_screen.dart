import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/colors.dart';
import '../data/destination_repository.dart';

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

  // Geofence GPS Simulation (Pilar 2 — Radius <= 15m)
  bool _isGeofenceActive = false;
  bool _isGeofenceAudioPlaying = false;
  double _userDistanceToSpotMeters = 12.0;

  // Kompas Gunung Bearing Simulation
  double _compassHeadingDeg = 45.0; // Default menghadap Gunung Marapi

  // 1. POI SEARAH RUTE (SHUNLU)
  static const List<Map<String, dynamic>> _shunluPois = [
    {
      'id': 'poi-rm-1',
      'category': 'RM Padang',
      'name': 'RM Simpang Raya Bukittinggi',
      'detour': 'Detour: +4 menit (350 m)',
      'route': 'Searah koridor Padang → Lembah Harau',
      'lat': -0.3055,
      'lng': 100.3695,
      'address': 'Jl. Sudirman No. 8, Bukittinggi',
    },
    {
      'id': 'poi-rm-2',
      'category': 'RM Padang',
      'name': 'Rumah Makan Pak Dt. Padang Panjang',
      'detour': 'Detour: +1 menit (80 m)',
      'route': 'Jalur Lintas Padang - Bukittinggi',
      'lat': -0.4635,
      'lng': 100.3988,
      'address': 'Jl. Sutan Syahrir No. 45, Padang Panjang',
    },
    {
      'id': 'poi-spbu-1',
      'category': 'SPBU',
      'name': 'SPBU Pertamina 14.271.536 Padang Panjang',
      'detour': 'Detour: +2 menit (120 m)',
      'route': 'Tepat di sisi kiri jalur utama Lintas Tengah',
      'lat': -0.4580,
      'lng': 100.4020,
      'address': 'Jl. Raya Padang - Bukittinggi Km 6',
    },
    {
      'id': 'poi-spbu-2',
      'category': 'SPBU',
      'name': 'SPBU Koto Baru Lembah Harau',
      'detour': 'Detour: +3 menit (200 m)',
      'route': 'Pintu masuk kawasan lembah',
      'lat': -0.1180,
      'lng': 100.6550,
      'address': 'Jl. Raya Harau Km 2',
    },
    {
      'id': 'poi-masjid-1',
      'category': 'Masjid',
      'name': 'Masjid Raya Syekh Ahmad Khatib Al-Minangkabawi',
      'detour': 'Detour: +5 menit (600 m)',
      'route': 'Parkir luas & fasilitas wudu ramah rombongan',
      'lat': -0.9250,
      'lng': 100.3620,
      'address': 'Kec. Padang Utara, Kota Padang',
    },
    {
      'id': 'poi-masjid-2',
      'category': 'Masjid',
      'name': 'Masjid Asasi Sigando Padang Panjang (Tertua)',
      'detour': 'Detour: +2 menit (150 m)',
      'route': 'Bangunan bersejarah kayu surau Minang',
      'lat': -0.4700,
      'lng': 100.4100,
      'address': 'Nagari Gunuang, Padang Panjang',
    },
    {
      'id': 'poi-atm-1',
      'category': 'ATM & Bengkel',
      'name': 'ATM Center Bank Nagari & Bengkel Siaga Kelok 9',
      'detour': 'Detour: +3 menit (250 m)',
      'route': 'Sebelum tanjakan jembatan layang Kelok 9',
      'lat': -0.0750,
      'lng': 100.7020,
      'address': 'Jalur Lintas Riau - Sumbar Km 32',
    },
    {
      'id': 'poi-atm-2',
      'category': 'ATM & Bengkel',
      'name': 'Posko Siaga Mobil & Motor Koto Baru',
      'detour': 'Detour: +2 menit (110 m)',
      'route': 'Rest area pasar Koto Baru',
      'lat': -0.3800,
      'lng': 100.3850,
      'address': 'Jl. Raya Bukittinggi - Padang',
    },
  ];

  static const List<LatLng> _corridorPoints = [
    LatLng(-0.9500, 100.3540),
    LatLng(-0.6800, 100.3400),
    LatLng(-0.4635, 100.3988),
    LatLng(-0.3800, 100.3850),
    LatLng(-0.3051, 100.3692),
    LatLng(-0.2100, 100.6300),
    LatLng(-0.1023, 100.6728),
  ];

  // 2. DATA PETA MIKRO KAWASAN PEJALAN KAKI (LEMBAH HARAU)
  static const List<LatLng> _microMapPoints = [
    LatLng(-0.1030, 100.6710),
    LatLng(-0.1025, 100.6725),
    LatLng(-0.1018, 100.6738),
    LatLng(-0.1012, 100.6746),
    LatLng(-0.1008, 100.6755),
  ];

  static const List<Map<String, dynamic>> _microMapPois = [
    {
      'id': 'micro-1',
      'category': 'Gerbang & Loket',
      'name': 'Pintu Gerbang & Loket Karcis Resmi',
      'detour': 'Akses Pejalan Kaki & E-Tiket',
      'route': 'Sesuai Perda No. 4/2023 · Rp 10.000/org',
      'lat': -0.1030,
      'lng': 100.6710,
      'address': 'Kawasan Nagari Harau, Kab. 50 Kota',
      'hasAudio': false,
    },
    {
      'id': 'micro-2',
      'category': 'Budaya & Audio',
      'name': 'Pondok Saluang & Suvenir Nagari Harau',
      'detour': 'Zona Narasi Suara Spasial (≤ 15m)',
      'route': 'Kisah legenda Sarasah & irama Saluang Minang',
      'lat': -0.1025,
      'lng': 100.6725,
      'address': 'Jalur Setapak Bambu Km 0.4',
      'hasAudio': true,
    },
    {
      'id': 'micro-3',
      'category': 'Air Terjun',
      'name': 'Sarasah Bunta (Air Terjun Utama)',
      'detour': 'Kolam Alami & Swafoto',
      'route': 'Tebing granit 200m & kolam air alami pegunungan',
      'lat': -0.1018,
      'lng': 100.6738,
      'address': 'Titik Tengah Lembah Harau',
      'hasAudio': true,
    },
    {
      'id': 'micro-4',
      'category': 'Eco-Trek',
      'name': 'Spot Tebing Granit & Posko Pemandu Nagari',
      'detour': 'Jalur Trekking Berpemandu Pokdarwis',
      'route': 'Wajib registrasi posko pemandu untuk keselamatan',
      'lat': -0.1008,
      'lng': 100.6755,
      'address': 'Kaki Tebing Granit Harau',
      'hasAudio': false,
    },
  ];

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
        return AppColors.coral500;
      case 'SPBU':
        return AppColors.orange500;
      case 'Masjid':
        return AppColors.green800;
      case 'ATM & Bengkel':
        return AppColors.indigo500;
      case 'Gerbang & Loket':
        return AppColors.green800;
      case 'Budaya & Audio':
        return AppColors.pinAudioEmas;
      case 'Air Terjun':
        return AppColors.pinNavigasiBiru;
      case 'Eco-Trek':
        return AppColors.green500;
      default:
        return AppColors.green800;
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
    final mountains = _repository.getMountainLandmarks();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtrl) => ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Kompas Gunung
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.green800.withValues(alpha: 0.12),
                      child: const Icon(Icons.explore, color: AppColors.green800, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kompas Visual Landmark Gunung',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink900,
                            ),
                          ),
                          Text(
                            'Pilar 2: Navigasi visual ke puncak gunung ikonik Sumbar',
                            style: TextStyle(fontSize: 11.5, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Azimuth Compass Dial Widget
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dial Outer Ring
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.green800, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green800.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Kardinal N E S W
                            const Positioned(
                              top: 8,
                              child: Text('N (0°)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)),
                            ),
                            const Positioned(
                              right: 8,
                              child: Text('E (90°)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 10)),
                            ),
                            const Positioned(
                              bottom: 8,
                              child: Text('S (180°)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 10)),
                            ),
                            const Positioned(
                              left: 8,
                              child: Text('W (270°)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 10)),
                            ),
                            // Lingkaran dalam derajat
                            Text(
                              '${_compassHeadingDeg.toStringAsFixed(0)}°',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rotating Compass Needle
                      Transform.rotate(
                        angle: (_compassHeadingDeg * 3.1415926535 / 180),
                        child: Container(
                          width: 180,
                          height: 180,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Heading Slider (Simulasi putar HP / Gyroscope)
                Row(
                  children: [
                    const Text('Arah HP: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _compassHeadingDeg,
                        min: 0,
                        max: 360,
                        activeColor: AppColors.green800,
                        onChanged: (val) {
                          setSheetState(() => _compassHeadingDeg = val);
                          setState(() => _compassHeadingDeg = val);
                        },
                      ),
                    ),
                    Text('${_compassHeadingDeg.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Landmark Gunung Terdeteksi:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink900),
                ),
                const SizedBox(height: 10),

                ...mountains.map((mtn) {
                  final diff = (_compassHeadingDeg - mtn.defaultBearingDeg).abs();
                  final isAligned = diff < 20 || diff > 340;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAligned ? AppColors.sage100 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAligned ? AppColors.green800 : Colors.black.withValues(alpha: 0.06),
                        width: isAligned ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isAligned
                              ? AppColors.green800
                              : AppColors.orange500.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.landscape_rounded,
                            color: isAligned ? Colors.white : AppColors.orange500,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      mtn.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: AppColors.ink900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${mtn.elevationMdpl} mdpl',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mtn.regency,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mtn.description,
                                style: const TextStyle(fontSize: 11, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bearing: ${mtn.defaultBearingDeg.toStringAsFixed(0)}°',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAligned ? AppColors.green800 : Colors.black54,
                              ),
                            ),
                            if (isAligned)
                              const Text(
                                '🎯 SEJAJAR',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.green800),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
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
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: Text(
          _isMicroMapMode ? 'Peta Mikro Pejalan Kaki' : 'Jelajah Peta & Rute Shunlu',
        ),
        actions: [
          IconButton(
            tooltip: 'Kompas Visual Landmark Gunung',
            icon: const Icon(Icons.explore_outlined, color: AppColors.green800),
            onPressed: _openMountainCompassSheet,
          ),
          IconButton(
            tooltip: 'Fokus Ulang Peta',
            icon: const Icon(Icons.my_location, color: AppColors.green800),
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
                color: AppColors.cream100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchMode(false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isMicroMapMode ? AppColors.green800 : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🛣️ Koridor Shunlu',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: !_isMicroMapMode ? Colors.white : AppColors.ink900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchMode(true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isMicroMapMode ? AppColors.green800 : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🚶 Peta Mikro Kawasan',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _isMicroMapMode ? Colors.white : AppColors.ink900,
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
              color: _isGeofenceActive ? const Color(0xFFFBF4E8) : Colors.white,
              child: Row(
                children: [
                  Icon(
                    _isGeofenceActive ? Icons.spatial_audio_rounded : Icons.radar_rounded,
                    color: _isGeofenceActive ? AppColors.orange500 : AppColors.green800,
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
                        color: _isGeofenceActive ? AppColors.orange500 : AppColors.ink900,
                      ),
                    ),
                  ),
                  if (_isGeofenceActive)
                    IconButton(
                      icon: Icon(
                        _isGeofenceAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: AppColors.orange500,
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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wisgo.rancakin',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (!_isMicroMapMode)
                          Polyline(
                            points: _corridorPoints,
                            color: AppColors.green800.withValues(alpha: 0.85),
                            strokeWidth: 5.0,
                          )
                        else
                          Polyline(
                            points: _microMapPoints,
                            color: AppColors.green500,
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
                          child: GestureDetector(
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
                                    color: Colors.black.withValues(alpha: 0.3),
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
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.green800.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
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
                            color: Colors.black.withValues(alpha: 0.2),
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
                                    color: AppColors.ink900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _selectedPoi!['detour'] as String,
                                  style: const TextStyle(
                                    color: AppColors.green500,
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
                    color: AppColors.ink900,
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
                                selectedColor: AppColors.green800,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.ink900,
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
                                selectedColor: AppColors.green800,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.ink900,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedPoi?['id'] == poi['id']
                          ? color
                          : Colors.black.withValues(alpha: 0.05),
                      width: _selectedPoi?['id'] == poi['id'] ? 2.0 : 1.0,
                    ),
                  ),
                  child: InkWell(
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
                                  color: AppColors.ink900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                poi['route'] as String,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black54,
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
                                      color: AppColors.green500.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      poi['detour'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.green500,
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
                                        color: AppColors.pinAudioEmas.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '🎧 Audio GPS',
                                        style: TextStyle(
                                          fontSize: 10.5,
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
                        const Icon(Icons.chevron_right, color: Colors.black26),
                      ],
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
