import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';
import '../models/destination_model.dart';

/// Layar 07 · Kanvas Tur Virtual 360° (Aerial-to-Ground & 4 Pin Interaktif)
/// Pilar 1: Eksplorasi Visual 360° & Budaya Minang
class VirtualTour360Screen extends StatefulWidget {
  final DestinationModel? destination;

  const VirtualTour360Screen({
    super.key,
    this.destination,
  });

  @override
  State<VirtualTour360Screen> createState() => _VirtualTour360ScreenState();
}

class _VirtualTour360ScreenState extends State<VirtualTour360Screen> {
  static const DestinationModel _defaultDest = DestinationModel(
    id: 'dest-harau',
    name: 'Lembah Harau (Nagari Harau)',
    category: 'Alam',
    cityRegency: 'Kab. Lima Puluh Kota',
    description:
        'Lembah tebing granit eksotis dengan air terjun dan panorama 360 derajat.',
    latitude: -0.1023,
    longitude: 100.6728,
    crowdLevel: 'Sedang',
  );

  DestinationModel get _dest => widget.destination ?? _defaultDest;

  bool _isAerialMode = true;
  bool _isGyroEnabled = true;
  bool _isSpatialAudioPlaying = false;
  bool _isVrMode = false;
  double _yawAngle = 20.0;
  double _pitchAngle = -5.0;

  String get _currentPanoramaUrl {
    final scenes = _dest.scenes360;
    if (scenes.isNotEmpty) {
      final targetType = _isAerialMode ? 'aerial' : 'ground';
      final matched = scenes.where((s) => s.type == targetType).toList();
      if (matched.isNotEmpty && matched.first.panoramaUrl.isNotEmpty) {
        return matched.first.panoramaUrl;
      }
    }
    return _isAerialMode
        ? 'https://raw.githubusercontent.com/yushijinhun/panorama_viewer/master/example/assets/panorama.jpg'
        : 'https://raw.githubusercontent.com/yushijinhun/panorama_viewer/master/example/assets/panorama2.jpg';
  }

  List<Hotspot360Model> get _currentHotspots {
    final scenes = _dest.scenes360;
    if (scenes.isNotEmpty) {
      final targetType = _isAerialMode ? 'aerial' : 'ground';
      final matched = scenes.where((s) => s.type == targetType).toList();
      if (matched.isNotEmpty && matched.first.hotspots.isNotEmpty) {
        return matched.first.hotspots;
      }
    }
    return [
      const Hotspot360Model(
        id: 'default-nav',
        sceneId: 'default',
        type: 'navigasi',
        pitch: -15,
        yaw: 10,
        title: 'Pindah ke Spot Utama (Ground)',
        description: 'Transisi mulus dari Drone Udara (150m) ke titik jalan kaki.',
      ),
      const Hotspot360Model(
        id: 'default-audio',
        sceneId: 'default',
        type: 'audio',
        pitch: 5,
        yaw: -35,
        title: 'Narasi Sejarah Nagari & Musik Saluang',
        description: 'Putar cerita lokal & instrumen Bansi/Saluang secara spasial.',
      ),
      const Hotspot360Model(
        id: 'default-fasilitas',
        sceneId: 'default',
        type: 'fasilitas',
        pitch: -8,
        yaw: 55,
        title: 'Musala, Toilet & Loket Karcis Resmi',
        description: 'Fasilitas terverifikasi berjarak 50m dari titik ini.',
      ),
      const Hotspot360Model(
        id: 'default-mitra',
        sceneId: 'default',
        type: 'mitra',
        pitch: -4,
        yaw: -65,
        title: 'Homestay Rumah Gadang & Kuliner Nagari',
        description: 'Mitra resmi terverifikasi. Ketuk untuk lihat tarif & booking.',
      ),
    ];
  }

  Color _pinColor(String type) {
    switch (type) {
      case 'navigasi':
        return AppColors.pinNavigasiBiru;
      case 'audio':
        return AppColors.pinAudioEmas;
      case 'fasilitas':
        return AppColors.pinFasilitasHijau;
      case 'mitra':
      default:
        return AppColors.pinMitraOranye;
    }
  }

  IconData _pinIcon(String type) {
    switch (type) {
      case 'navigasi':
        return Icons.flight_land_rounded;
      case 'audio':
        return Icons.graphic_eq;
      case 'fasilitas':
        return Icons.mosque_rounded;
      case 'mitra':
      default:
        return Icons.storefront_rounded;
    }
  }

  String _pinBadgeLabel(String type) {
    switch (type) {
      case 'navigasi':
        return 'Pin Navigasi (Biru)';
      case 'audio':
        return 'Pin Audio Budaya (Emas)';
      case 'fasilitas':
        return 'Pin Fasilitas Resmi (Hijau)';
      case 'mitra':
      default:
        return 'Pin Mitra Nagari (Oranye)';
    }
  }

  void _showHotspotSheet(Hotspot360Model hotspot) {
    if (hotspot.type == 'navigasi') {
      setState(() {
        _isAerialMode = !_isAerialMode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green800,
          content: Text(
            _isAerialMode
                ? 'Berpindah ke Mode Drone Udara (150m)...'
                : 'Berpindah ke Mode Darat (Ground Spot)...',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final color = _pinColor(hotspot.type);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pinBadgeLabel(hotspot.type),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hotspot.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hotspot.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.ink900,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              if (hotspot.type == 'audio')
                PillButton(
                  text: _isSpatialAudioPlaying
                      ? 'Hentikan Audio Budaya 360°'
                      : 'Putar Narasi & Saluang 360°',
                  icon: Icon(
                    _isSpatialAudioPlaying ? Icons.stop : Icons.volume_up,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: AppColors.pinAudioEmas,
                  onPressed: () {
                    setState(() {
                      _isSpatialAudioPlaying = !_isSpatialAudioPlaying;
                    });
                    Navigator.pop(ctx);
                  },
                )
              else if (hotspot.type == 'mitra')
                PillButton(
                  text: 'Buka Quick Booking Mitra (FE-2 Escrow)',
                  icon: const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: AppColors.pinMitraOranye,
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Titik integrasi dengan Quick Booking Drawer (FE-2).',
                        ),
                      ),
                    );
                  },
                )
              else
                PillButton(
                  text: 'Arahkan ke Fasilitas Ini di Peta Mikro',
                  icon: const Icon(Icons.directions_walk, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimulationCanvas() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isAerialMode
              ? [
                  const Color(0xFF102A43),
                  const Color(0xFF1C4532),
                  const Color(0xFF234B24),
                ]
              : [
                  const Color(0xFF1A3626),
                  const Color(0xFF234B24),
                  const Color(0xFF2D3748),
                ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isAerialMode ? Icons.flight : Icons.panorama_photosphere,
              size: 64,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            const SizedBox(height: 8),
            Text(
              'Yaw: ${_yawAngle.toStringAsFixed(0)}° · Pitch: ${_pitchAngle.toStringAsFixed(0)}°',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVrEyeView({required bool isLeft}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PanoramaViewer(
          sensorControl:
              _isGyroEnabled ? SensorControl.orientation : SensorControl.none,
          animSpeed: 0.2,
          latitude: _pitchAngle,
          longitude: _yawAngle,
          onViewChanged: (lon, lat, tilt) {
            setState(() {
              _yawAngle = lon;
              _pitchAngle = lat;
            });
          },
          hotspots: _currentHotspots.map((hotspot) {
            final color = _pinColor(hotspot.type);
            return Hotspot(
              latitude: hotspot.pitch,
              longitude: hotspot.yaw,
              width: 36,
              height: 36,
              widget: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(_pinIcon(hotspot.type), color: Colors.white, size: 16),
              ),
            );
          }).toList(),
          child: Image.network(
            _currentPanoramaUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/panorama_sumbar_default.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Reticle Crosshair di tengah layar VR
        Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.add, size: 10, color: Colors.white70),
            ),
          ),
        ),
        // Label Mata Kiri / Kanan
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isLeft ? 'LEFT EYE' : 'RIGHT EYE',
              style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink900,
      appBar: AppBar(
        backgroundColor: AppColors.ink900,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tur 360° · ${_dest.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isVrMode
                  ? 'Mode VR Stereoscopic (Dual Eye) · Siap Google Cardboard'
                  : (_isAerialMode
                      ? 'Mode Drone Udara (150m) · Geser untuk memutar 360°'
                      : 'Mode Darat (Ground) · Geser untuk memutar 360°'),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isVrMode ? 'Keluar Mode VR' : 'Mode VR (Cardboard / Split-Screen)',
            onPressed: () => setState(() => _isVrMode = !_isVrMode),
            icon: Icon(
              Icons.vrpano,
              color: _isVrMode ? AppColors.pinAudioEmas : Colors.white70,
            ),
          ),
          IconButton(
            tooltip: 'Sensor Gyroscope',
            onPressed: () => setState(() => _isGyroEnabled = !_isGyroEnabled),
            icon: Icon(
              _isGyroEnabled ? Icons.screen_rotation : Icons.screen_lock_rotation,
              color: _isGyroEnabled ? AppColors.green500 : Colors.white54,
            ),
          ),
        ],
      ),
      body: _isVrMode
          ? Row(
              children: [
                Expanded(child: _buildVrEyeView(isLeft: true)),
                Container(
                  width: 4,
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.circle, size: 6, color: Colors.white38),
                  ),
                ),
                Expanded(child: _buildVrEyeView(isLeft: false)),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // 1. VIEWER PANORAMA 360° SUNGGUHAN (EQUIRECTANGULAR + GYROSCOPE)
                PanoramaViewer(
                  sensorControl:
                      _isGyroEnabled ? SensorControl.orientation : SensorControl.none,
                  animSpeed: 0.2,
                  latitude: _pitchAngle,
                  longitude: _yawAngle,
                  onViewChanged: (lon, lat, tilt) {
                    setState(() {
                      _yawAngle = lon;
                      _pitchAngle = lat;
                    });
                  },
                  hotspots: _currentHotspots.map((hotspot) {
                    final color = _pinColor(hotspot.type);
                    return Hotspot(
                      latitude: hotspot.pitch,
                      longitude: hotspot.yaw,
                      width: 48,
                      height: 48,
                      widget: GestureDetector(
                        onTap: () => _showHotspotSheet(hotspot),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: Icon(
                            _pinIcon(hotspot.type),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  child: Image.network(
                    _currentPanoramaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/panorama_sumbar_default.jpg',
                      fit: BoxFit.cover,
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildSimulationCanvas(),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.green500,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Memuat Panorama 360°...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 2. SWITCHER AERIAL-TO-GROUND DI BAGIAN ATAS
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeChip(
                              label: 'Drone Udara',
                              icon: Icons.flight_takeoff,
                              selected: _isAerialMode,
                              onTap: () => setState(() => _isAerialMode = true),
                            ),
                            _buildModeChip(
                              label: 'Titik Darat',
                              icon: Icons.directions_walk,
                              selected: !_isAerialMode,
                              onTap: () => setState(() => _isAerialMode = false),
                            ),
                          ],
                        ),
                      ),
                      if (_isSpatialAudioPlaying)
                        Builder(
                          builder: (_) {
                            final pan = (_yawAngle % 360) / 180.0 - 1.0;
                            final leftPct = ((1.0 - pan) * 50).clamp(10, 90).toInt();
                            final rightPct = 100 - leftPct;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pinAudioEmas,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.graphic_eq, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Spatial [L:$leftPct% R:$rightPct%]',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

          // 3. PANEL DAFTAR 4 PIN INTERAKTIF
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cream100,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          '4 Pin Interaktif pada Scene Ini:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_yawAngle.toStringAsFixed(0)}° / ${_pitchAngle.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._currentHotspots.map((hotspot) {
                    final color = _pinColor(hotspot.type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showHotspotSheet(hotspot),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: color,
                                child: Icon(
                                  _pinIcon(hotspot.type),
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hotspot.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink900,
                                      ),
                                    ),
                                    Text(
                                      '${_pinBadgeLabel(hotspot.type)} · Pitch ${hotspot.pitch}°, Yaw ${hotspot.yaw}°',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: color),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green800 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
