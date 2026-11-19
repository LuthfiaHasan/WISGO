import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  double _voiceOverProgress = 0.0;
  Timer? _voiceOverTimer;
  bool _isNarrationExpanded = false;

  @override
  void dispose() {
    _voiceOverTimer?.cancel();
    super.dispose();
  }

  void _toggleAudioNarration([Hotspot360Model? hotspot]) {
    setState(() {
      _isSpatialAudioPlaying = !_isSpatialAudioPlaying;
      if (_isSpatialAudioPlaying) {
        if (hotspot != null) {
          _yawAngle = hotspot.yaw.toDouble();
          _pitchAngle = hotspot.pitch.toDouble();
        }
        _voiceOverTimer?.cancel();
        _voiceOverTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
          if (!mounted) return;
          setState(() {
            _voiceOverProgress += 0.015;
            if (_voiceOverProgress >= 1.0) {
              _voiceOverProgress = 0.0;
              _isSpatialAudioPlaying = false;
              t.cancel();
            }
          });
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.pinAudioEmas,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.graphic_eq, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Memutar Suara AI: Sejarah ${_dest.name}...',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        _voiceOverTimer?.cancel();
      }
    });
  }

  String _getHistoricalNarration() {
    final title = _dest.name.toLowerCase();
    if (title.contains('lubuk hitam') || title.contains('cindakir')) {
      return 'Air Terjun Lubuk Hitam (Cindakir) memiliki formasi langka tiga tingkatan air terjun alami di kawasan hutan lindung Bungus Teluk Kabung. Berdasarkan penuturan tetua adat nagari, kolam alami pada tingkatan ketiga konon merupakan tempat pemandian dan meditasi para pemuka adat sebelum menempuh jalur maritim pesisir barat Sumatera pada abad ke-16.';
    } else if (title.contains('harau')) {
      return 'Lembah Harau merupakan lembah cadas subur di Kabupaten Lima Puluh Kota yang dikelilingi tebing granit raksasa setinggi 100 hingga 500 meter. Penelitian geologis membuktikan lembah ini jutaan tahun lalu merupakan dasar samudera purba yang terangkat. Dalam sejarah lisan Minangkabau, lembah ini menjadi benteng alam pertahanan nagari yang kokoh dan pusat permukiman suku-suku Luhak Limopuluah.';
    } else if (title.contains('sianok')) {
      return 'Ngarai Sianok adalah lembah patahan curam sepanjang 15 kilometer dengan dinding vertikal hingga 120 meter yang terbentuk dari sesar geser aktif Semangko. Dalam sejarah perjuangan masyarakat Bukittinggi, ngarai ini menjadi jalur persembunyian rahasia dan penghubung peradaban nagari Koto Gadang yang melegenda.';
    } else if (title.contains('singkarak')) {
      return 'Danau Singkarak terbentang luas di antara Solok dan Tanah Datar, menjadi habitat alami ikan bilih endemik dunia. Danau tektonik ini menyimpan sejarah jalur perdagangan tradisional garam dan rempah-rempah dari pedalaman Minangkabau menuju pesisir Selat Malaka sejak masa kerajaan Melayu Dharmasraya.';
    } else {
      return '${_dest.name} di wilayah ${_dest.cityRegency}: ${_dest.description} Tempat ini menyimpan cerita turun-temurun masyarakat lokal mengenai kearifan menjaga hutan adat, kelestarian mata air pegunungan, serta filosofi adat Minangkabau "Alam Takambang Jadi Guru".';
    }
  }

  Image _buildPanoramaImage() {
    final scenes = _dest.scenes360;
    if (scenes.isNotEmpty) {
      final targetType = _isAerialMode ? 'aerial' : 'ground';
      final matched = scenes.where((s) => s.type == targetType).toList();
      if (matched.isNotEmpty &&
          matched.first.panoramaUrl.isNotEmpty &&
          matched.first.panoramaUrl.startsWith('http')) {
        return Image.network(
          matched.first.panoramaUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/panorama_sumbar_default.jpg',
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return Image.asset(
      'assets/images/panorama_sumbar_default.jpg',
      fit: BoxFit.cover,
    );
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
              if (hotspot.type == 'audio') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCF5E5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.pinAudioEmas.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over_rounded, color: AppColors.pinAudioEmas, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isSpatialAudioPlaying ? 'Sedang Memutar Narasi AI' : 'Narasi AI Budaya Minang',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pinAudioEmas,
                            ),
                          ),
                          if (_isSpatialAudioPlaying) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.graphic_eq, color: AppColors.pinAudioEmas, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getHistoricalNarration(),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink900, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PillButton(
                  text: _isSpatialAudioPlaying
                      ? 'Hentikan Audio Suara AI'
                      : 'Putar Suara AI Sejarah Tempat',
                  icon: Icon(
                    _isSpatialAudioPlaying ? Icons.pause_circle_filled_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  backgroundColor: AppColors.pinAudioEmas,
                  onPressed: () {
                    _toggleAudioNarration(hotspot);
                    Navigator.pop(ctx);
                  },
                ),
              ]
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
          child: _buildPanoramaImage(),
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

  Widget _buildDesktopPanoramaFallback() {
    final double alignX = (_yawAngle % 360 - 180) / 180.0;
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _yawAngle += details.delta.dx * 0.45;
          _pitchAngle = (_pitchAngle - details.delta.dy * 0.25).clamp(-45.0, 45.0);
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/panorama_sumbar_default.jpg',
              fit: BoxFit.cover,
              alignment: Alignment(alignX, (_pitchAngle / 45.0).clamp(-1.0, 1.0)),
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.ink900,
                child: const Center(
                  child: Icon(Icons.panorama_photosphere, color: Colors.white24, size: 80),
                ),
              ),
            ),
          ),
          ..._currentHotspots.map((hotspot) {
            double diff = (hotspot.yaw - _yawAngle) % 360;
            if (diff > 180) diff -= 360;
            if (diff < -180) diff += 360;
            if (diff.abs() > 65) return const SizedBox.shrink();

            final w = MediaQuery.of(context).size.width;
            final h = MediaQuery.of(context).size.height;
            final double posX = (w / 2) + (diff / 65.0) * (w / 2 * 0.85);
            final double posY = (h * 0.38) + (_pitchAngle * 2.0);
            final color = _pinColor(hotspot.type);

            return Positioned(
              left: posX - 22,
              top: posY - 22,
              child: GestureDetector(
                onTap: () {
                  if (hotspot.type == 'audio') {
                    _toggleAudioNarration(hotspot);
                  } else {
                    _showHotspotSheet(hotspot);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(_pinIcon(hotspot.type), color: Colors.white, size: 20),
                ),
              ),
            );
          }),
        ],
      ),
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
                // 1. VIEWER PANORAMA 360° SUNGGUHAN (EQUIRECTANGULAR + GYROSCOPE + DESKTOP RESILIENT)
                if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
                  _buildDesktopPanoramaFallback()
                else
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
                  child: _buildPanoramaImage(),
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

          // 2.5 FLOATING AI VOICE OVER HISTORICAL STORYTELLING BAR
          if (_isSpatialAudioPlaying)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.ink900.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.pinAudioEmas, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                          onTap: () => _toggleAudioNarration(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.pinAudioEmas,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.pause_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'MEMUTAR SUARA AI SEJARAH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: AppColors.pinAudioEmas,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.pinAudioEmas),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sejarah ${_dest.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _isNarrationExpanded ? 'Tutup' : 'Teks',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _voiceOverProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pinAudioEmas),
                        minHeight: 3.5,
                      ),
                    ),
                    if (_isNarrationExpanded) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _getHistoricalNarration(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
                    final isAudio = hotspot.type == 'audio';
                    final isAudioPlaying = isAudio && _isSpatialAudioPlaying;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (isAudio) {
                            _toggleAudioNarration(hotspot);
                          } else {
                            _showHotspotSheet(hotspot);
                          }
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isAudioPlaying ? const Color(0xFFFCF5E5) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAudioPlaying ? AppColors.pinAudioEmas : color.withValues(alpha: 0.35),
                              width: isAudioPlaying ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: color,
                                child: Icon(
                                  isAudioPlaying ? Icons.graphic_eq : _pinIcon(hotspot.type),
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
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isAudioPlaying ? AppColors.pinAudioEmas : AppColors.ink900,
                                      ),
                                    ),
                                    Text(
                                      isAudioPlaying
                                          ? 'Sedang Memutar: Suara AI Sejarah Tempat (Ketuk Jeda)'
                                          : (isAudio
                                              ? 'Pin Audio Budaya (Emas) · Suara AI Sejarah Tempat'
                                              : '${_pinBadgeLabel(hotspot.type)} · Pitch ${hotspot.pitch}°, Yaw ${hotspot.yaw}°'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isAudioPlaying ? FontWeight.w600 : FontWeight.normal,
                                        color: isAudioPlaying ? AppColors.pinAudioEmas : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAudio)
                                Icon(
                                  isAudioPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                  color: AppColors.pinAudioEmas,
                                  size: 24,
                                )
                              else
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
