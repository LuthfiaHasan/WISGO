import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/widgets/pill_button.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';

/// Layar 07 · Kanvas Tur Virtual 360° (Aerial-to-Ground & 4 Pin Interaktif)
/// Desain Imersif Full-Screen + Frosted Glass Minimalis & Elegan
class VirtualTour360Screen extends StatefulWidget {
  final DestinationModel? destination;
  final VoidCallback? onOpenDenah;

  const VirtualTour360Screen({
    super.key,
    this.destination,
    this.onOpenDenah,
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
    coverImage:
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1400&q=80',
    crowdLevel: 'Sedang',
  );

  DestinationModel get _dest => widget.destination ?? _defaultDest;

  bool _isAerialMode = true;
  bool _isGyroEnabled = true;
  bool _isSpatialAudioPlaying = false;
  bool _isMinangMusicPlaying = false;
  bool _isVrMode = false;
  double _yawAngle = 20.0;
  double _pitchAngle = -5.0;
  double _voiceOverProgress = 0.0;
  Timer? _voiceOverTimer;
  double _minangMusicProgress = 0.0;
  Timer? _minangMusicTimer;
  bool _isNarrationExpanded = false;

  // Nullable agar aman saat Hot Reload
  bool? _isPinListExpanded = false;
  Hotspot360Model? _activeHotspotPreview;
  List<Scene360Model>? _liveScenes360;
  bool? _isBeSceneLoaded = false;

  bool get _pinListExpanded => _isPinListExpanded ?? false;
  List<Scene360Model> get _activeScenes {
    if (_liveScenes360 != null && _liveScenes360!.isNotEmpty) {
      return _liveScenes360!;
    }
    return _dest.scenes360;
  }

  @override
  void initState() {
    super.initState();
    _syncScenesFromBackend();
  }

  Future<void> _syncScenesFromBackend() async {
    final beId = DestinationRepository.resolveScenes360BackendId(_dest);
    final res = await DestinationRepository().fetchLiveScenes360(beId);
    if (!mounted || res.scenes.isEmpty) return;

    final hasAerial = res.scenes.any((s) => s.type == 'aerial');
    setState(() {
      _liveScenes360 = res.scenes;
      _isBeSceneLoaded = res.fromBackend;
      if (!hasAerial) {
        _isAerialMode = false;
      }
    });
  }

  @override
  void dispose() {
    _voiceOverTimer?.cancel();
    _minangMusicTimer?.cancel();
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
      } else {
        _voiceOverTimer?.cancel();
      }
    });
  }

  void _toggleMinangMusic([Hotspot360Model? hotspot]) {
    setState(() {
      _isMinangMusicPlaying = !_isMinangMusicPlaying;
      if (_isMinangMusicPlaying) {
        if (hotspot != null) {
          _yawAngle = hotspot.yaw.toDouble();
          _pitchAngle = hotspot.pitch.toDouble();
        }
        _minangMusicTimer?.cancel();
        _minangMusicTimer =
            Timer.periodic(const Duration(milliseconds: 250), (t) {
          if (!mounted) return;
          setState(() {
            _minangMusicProgress += 0.012;
            if (_minangMusicProgress >= 1.0) {
              _minangMusicProgress = 0.0; // Loop seamlessly
            }
          });
        });
      } else {
        _minangMusicTimer?.cancel();
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF102218).withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(
              _isMinangMusicPlaying
                  ? Icons.music_note_rounded
                  : Icons.music_off_rounded,
              color: const Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isMinangMusicPlaying
                    ? AppLocale.tr(
                        'Memutar alunan musik tradisional Minang (Saluang & Talempong)',
                        'Playing traditional Minang music (Saluang & Talempong)',
                      )
                    : AppLocale.tr(
                        'Musik tradisional Minang dijeda',
                        'Traditional Minang music paused',
                      ),
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  String _getHistoricalNarration() {
    final title = _dest.name.toLowerCase();
    if (title.contains('lubuk hitam') || title.contains('cindakir')) {
      return 'Air Terjun Lubuk Hitam (Cindakir) memiliki formasi langka tiga tingkatan air terjun alami di kawasan hutan lindung Bungus Teluk Kabung. Kolam alami pada tingkatan ketiga konon menjadi tempat persinggahan para pemuka adat sebelum menempuh jalur maritim pesisir barat Sumatera.';
    } else if (title.contains('harau')) {
      return 'Lembah Harau dikelilingi tebing granit raksasa setinggi 100 hingga 500 meter yang jutaan tahun lalu merupakan dasar samudera purba. Dalam sejarah lisan Minangkabau, lembah ini menjadi benteng alam pertahanan nagari dan pusat permukiman Luhak Limopuluah.';
    } else if (title.contains('sianok') || title.contains('jam gadang')) {
      return 'Ngarai Sianok adalah lembah patahan curam sepanjang 15 kilometer yang terbentuk dari sesar aktif Semangko, berdampingan dengan ikon Jam Gadang Bukittinggi dan jalur bersejarah menuju Nagari Koto Gadang.';
    } else if (title.contains('maninjau') || title.contains('singkarak')) {
      return 'Danau vulkanik dan tektonik Minangkabau dikelilingi perbukitan hijau serta kelok jalan legendaris, menjadi sumber kehidupan nelayan lokal sekaligus saksi sejarah perdagangan rempah pedalaman Sumatera Barat.';
    } else if (title.contains('mandeh')) {
      return 'Kawasan Bahari Mandeh dikenal sebagai surga teluk tenang berair zamrud di Pesisir Selatan, diapit pulau-pulau kecil berhutan bakau yang menjadi jalur pelayaran tradisional nelayan Minang.';
    } else if (title.contains('pagaruyung')) {
      return 'Istano Basa Pagaruyung adalah replika megah istana Kerajaan Pagaruyung bergonjong sebelas, merepresentasikan arsitektur Rumah Gadang dan falsafah Adat Basandi Syarak, Syarak Basandi Kitabullah.';
    } else {
      return '${_dest.name} di wilayah ${_dest.cityRegency}: ${_dest.description} Tempat ini menyimpan kearifan lokal masyarakat Minangkabau dalam menjaga alam dengan falsafah "Alam Takambang Jadi Guru".';
    }
  }

  String? _resolvedNetworkPanoramaUrl() {
    final scenes = _activeScenes;
    if (scenes.isNotEmpty) {
      final targetType = _isAerialMode ? 'aerial' : 'ground';
      final matched = scenes.where((s) => s.type == targetType).toList();
      final candidate = matched.isNotEmpty
          ? matched.first.panoramaUrl
          : scenes.first.panoramaUrl;
      // Abaikan URL CDN dummy / repo lama yang 404 agar langsung memuat foto asli destinasi
      if (candidate.isNotEmpty &&
          candidate.startsWith('http') &&
          !candidate.contains('cdn.rancak.in') &&
          !candidate.contains('yushijinhun')) {
        return candidate;
      }
    }
    if (_dest.coverImage.isNotEmpty && _dest.coverImage.startsWith('http')) {
      return _dest.coverImage;
    }
    return null;
  }

  Widget _buildPanoramaPhotoTile({bool flipX = false}) {
    final url = _resolvedNetworkPanoramaUrl();
    final fallbackCover =
        (_dest.coverImage.isNotEmpty && _dest.coverImage.startsWith('http'))
            ? _dest.coverImage
            : null;

    Widget buildAssetFallback() => Image.asset(
          'assets/images/panorama_sumbar_default.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );

    final Widget imageWidget = url != null
        ? Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFF102218),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF6EE7B7),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) {
              if (fallbackCover != null && fallbackCover != url) {
                return Image.network(
                  fallbackCover,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => buildAssetFallback(),
                );
              }
              return buildAssetFallback();
            },
          )
        : buildAssetFallback();

    if (flipX) {
      return Transform.flip(flipX: true, child: imageWidget);
    }
    return imageWidget;
  }

  List<Hotspot360Model> get _currentHotspots {
    final scenes = _activeScenes;
    if ((_isBeSceneLoaded ?? false) && scenes.isNotEmpty) {
      final targetType = _isAerialMode ? 'aerial' : 'ground';
      final matched = scenes.where((s) => s.type == targetType).toList();
      List<Hotspot360Model> raw = [];
      if (matched.isNotEmpty && matched.first.hotspots.isNotEmpty) {
        raw = matched.first.hotspots;
      } else if (scenes.first.hotspots.isNotEmpty) {
        raw = scenes.first.hotspots;
      }
      final filtered = raw
          .where((h) =>
              h.type != 'fasilitas' &&
              h.type != 'mitra' &&
              h.type != 'kuliner')
          .toList();
      if (filtered.isNotEmpty) {
        return filtered;
      }
    }
    return [
      Hotspot360Model(
        id: 'default-nav',
        sceneId: 'default',
        type: 'navigasi',
        pitch: -12,
        yaw: 10,
        title: _isAerialMode
            ? AppLocale.tr('Turun ke Titik Darat', 'Switch to Ground Spot')
            : AppLocale.tr('Naik ke Drone Udara (150m)', 'Switch to Aerial Drone'),
        description: AppLocale.tr(
          'Transisi sudut pandang antara Drone Udara (150m) dan jalur pejalan kaki 360°.',
          'Smooth transition between 150m Aerial Drone view and walking-level 360° spot.',
        ),
      ),
      Hotspot360Model(
        id: 'default-narasi',
        sceneId: 'default',
        type: 'narasi',
        pitch: 6,
        yaw: -32,
        title: AppLocale.tr(
          'Narasi Sejarah Minangkabau',
          'Minangkabau History Narration',
        ),
        description: AppLocale.tr(
          'Dengarkan kisah sejarah nagari, asal-usul legenda, dan kearifan lokal Minangkabau secara spasial.',
          'Listen to local Minang heritage storytelling, folk legends, and spatial wisdom.',
        ),
      ),
      Hotspot360Model(
        id: 'default-musik',
        sceneId: 'default',
        type: 'musik',
        pitch: -6,
        yaw: 45,
        title: AppLocale.tr(
          'Musik Tradisional Minang',
          'Traditional Minang Music',
        ),
        description: AppLocale.tr(
          'Alunan instrumen Saluang dan Talempong tradisional khas Minangkabau yang menenangkan.',
          'Soothing traditional Minangkabau instruments (Saluang flute & Talempong).',
        ),
      ),
    ];
  }

  Color _pinColor(String type) {
    switch (type) {
      case 'navigasi':
        return const Color(0xFF4F9DFF);
      case 'narasi':
      case 'audio':
        return const Color(0xFFF5B041);
      case 'musik':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF4F9DFF);
    }
  }

  IconData _pinIcon(String type) {
    switch (type) {
      case 'navigasi':
        return _isAerialMode
            ? Icons.flight_land_rounded
            : Icons.flight_takeoff_rounded;
      case 'narasi':
      case 'audio':
        return Icons.record_voice_over_rounded;
      case 'musik':
        return Icons.music_note_rounded;
      default:
        return Icons.explore_rounded;
    }
  }

  String _pinShortLabel(String type) {
    switch (type) {
      case 'navigasi':
        return _isAerialMode
            ? AppLocale.tr('Darat', 'Ground')
            : AppLocale.tr('Drone', 'Aerial');
      case 'narasi':
      case 'audio':
        return AppLocale.tr('Narasi Sejarah', 'History Narration');
      case 'musik':
        return AppLocale.tr('Musik Minang', 'Minang Music');
      default:
        return AppLocale.tr('360°', '360°');
    }
  }

  String _pinBadgeLabel(String type) {
    switch (type) {
      case 'navigasi':
        return AppLocale.tr('Navigasi Sudut 360°', '360° Viewpoint Switch');
      case 'narasi':
      case 'audio':
        return AppLocale.tr('Narasi Cerita Sejarah', 'Historical Storytelling');
      case 'musik':
        return AppLocale.tr('Musik Tradisional Minang', 'Traditional Minang Music');
      default:
        return AppLocale.tr('Titik 360°', '360° Point');
    }
  }

  void _handleHotspotTap(Hotspot360Model hotspot) {
    if (hotspot.type == 'navigasi') {
      setState(() {
        _isAerialMode = !_isAerialMode;
        _activeHotspotPreview = null;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink900.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            _isAerialMode
                ? AppLocale.tr(
                    'Berpindah ke Mode Drone Udara (150m)',
                    'Switched to Aerial Drone Mode (150m)',
                  )
                : AppLocale.tr(
                    'Berpindah ke Mode Titik Darat',
                    'Switched to Ground Spot Mode',
                  ),
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
          duration: const Duration(milliseconds: 1600),
        ),
      );
      return;
    }

    if (hotspot.type == 'narasi' || hotspot.type == 'audio') {
      setState(() {
        _activeHotspotPreview = null;
        _isPinListExpanded = false;
      });
      _toggleAudioNarration(hotspot);
      return;
    }

    if (hotspot.type == 'musik') {
      setState(() {
        _activeHotspotPreview = null;
        _isPinListExpanded = false;
      });
      _toggleMinangMusic(hotspot);
      return;
    }

    setState(() {
      _yawAngle = hotspot.yaw.toDouble();
      _pitchAngle = hotspot.pitch.toDouble();
      _isPinListExpanded = false;
      _activeHotspotPreview =
          _activeHotspotPreview?.id == hotspot.id ? null : hotspot;
    });
  }

  void _showHotspotSheet(Hotspot360Model hotspot) {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
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
              if (hotspot.type == 'narasi' || hotspot.type == 'audio')
                PillButton(
                  text: _isSpatialAudioPlaying
                      ? AppLocale.tr(
                          'Jeda Narasi Sejarah',
                          'Pause History Narration',
                        )
                      : AppLocale.tr(
                          'Dengarkan Narasi Sejarah',
                          'Play History Narration',
                        ),
                  icon: Icon(
                    _isSpatialAudioPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: const Color(0xFFF5B041),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleAudioNarration(hotspot);
                  },
                )
              else if (hotspot.type == 'musik')
                PillButton(
                  text: _isMinangMusicPlaying
                      ? AppLocale.tr(
                          'Jeda Musik Minang',
                          'Pause Minang Music',
                        )
                      : AppLocale.tr(
                          'Putar Musik Tradisional Minang',
                          'Play Traditional Minang Music',
                        ),
                  icon: Icon(
                    _isMinangMusicPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleMinangMusic(hotspot);
                  },
                )
              else
                PillButton(
                  text: _isAerialMode
                      ? AppLocale.tr(
                          'Turun ke Titik Darat',
                          'Switch to Ground Spot',
                        )
                      : AppLocale.tr(
                          'Naik ke Drone Udara (150m)',
                          'Switch to Aerial Drone',
                        ),
                  icon: Icon(
                    _isAerialMode
                        ? Icons.flight_land_rounded
                        : Icons.flight_takeoff_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: const Color(0xFF4F9DFF),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleHotspotTap(hotspot);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Tag kaca minimalis melayang di sela-sela pemandangan 360°
  Widget _buildFloating360HotspotTag(Hotspot360Model hotspot) {
    final color = _pinColor(hotspot.type);
    final isAudio = hotspot.type == 'audio' || hotspot.type == 'narasi';
    final isMusik = hotspot.type == 'musik';
    final isAudioPlaying = isAudio && _isSpatialAudioPlaying;
    final isMusikPlaying = isMusik && _isMinangMusicPlaying;
    final isFocused =
        _activeHotspotPreview?.id == hotspot.id || isAudioPlaying || isMusikPlaying;

    return GestureDetector(
      onTap: () => _handleHotspotTap(hotspot),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(5, 5, 11, 5),
            decoration: BoxDecoration(
              color: isFocused
                  ? Colors.black.withValues(alpha: 0.62)
                  : Colors.black.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isFocused
                    ? color.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.32),
                width: isFocused ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _pinIcon(hotspot.type),
                    color: Colors.white,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _pinShortLabel(hotspot.type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVrEyeView({required bool isLeft}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildSeamless360PanoramicCanvas(
          stereoOffset: isLeft ? -4.0 : 4.0,
          compactHotspots: true,
        ),
        Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70, width: 1.8),
            ),
            child: const Center(
              child: Icon(Icons.add, size: 10, color: Colors.white70),
            ),
          ),
        ),
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
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kanvas Panorama 360° Seamless (Web, Desktop, Android & iOS — bebas blank CORS WebGL)
  Widget _buildSeamless360PanoramicCanvas({
    double stereoOffset = 0.0,
    bool compactHotspots = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        final double tileW = (w * 1.95).clamp(420.0, 2400.0);
        final double cycleW = tileW * 2.0;
        final double canvasH = h * 1.32;

        // Normalisasi sudut yaw ke [0, 360) agar geser 360° berputar tanpa batas & mulus
        double normalizedYaw = (_yawAngle + stereoOffset) % 360.0;
        if (normalizedYaw < 0) normalizedYaw += 360.0;
        final double shiftX = (normalizedYaw / 360.0) * cycleW;

        // Translasi vertikal pitch (-28°..+28°)
        final double maxShiftY = (canvasH - h) / 2.0;
        final double pitchFrac = (_pitchAngle / 28.0).clamp(-1.0, 1.0);
        final double topOffset = -maxShiftY + (pitchFrac * maxShiftY);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            setState(() {
              _yawAngle = (_yawAngle - details.delta.dx * 0.35) % 360.0;
              _pitchAngle =
                  (_pitchAngle + details.delta.dy * 0.22).clamp(-28.0, 28.0);
            });
          },
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 3-tile mirrored panoramic strip [Normal | Flipped | Normal] untuk loop 360° mulus tanpa garis potong
                AnimatedScale(
                  scale: _isAerialMode ? 1.0 : 1.24,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -shiftX,
                        top: topOffset,
                        width: tileW * 3,
                        height: canvasH,
                        child: Row(
                          children: [
                            SizedBox(
                              width: tileW,
                              height: canvasH,
                              child: _buildPanoramaPhotoTile(flipX: false),
                            ),
                            SizedBox(
                              width: tileW,
                              height: canvasH,
                              child: _buildPanoramaPhotoTile(flipX: true),
                            ),
                            SizedBox(
                              width: tileW,
                              height: canvasH,
                              child: _buildPanoramaPhotoTile(flipX: false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Frosted-Glass Hotspot Tags di sela-sela pemandangan 360°
                ..._currentHotspots.map((hotspot) {
                  double diff = (hotspot.yaw - (_yawAngle + stereoOffset)) % 360;
                  if (diff > 180) diff -= 360;
                  if (diff < -180) diff += 360;
                  if (diff.abs() > 75) return const SizedBox.shrink();

                  final double edgeFade =
                      (1.0 - ((diff.abs() - 50.0) / 25.0).clamp(0.0, 1.0));
                  final double posX = (w / 2) + (diff / 75.0) * (w * 0.44);
                  final double posY =
                      (h * 0.45) - ((hotspot.pitch - _pitchAngle) * 3.4);

                  if (compactHotspots) {
                    final color = _pinColor(hotspot.type);
                    return Positioned(
                      left: (posX - 16).clamp(8.0, w - 40.0),
                      top: posY.clamp(90.0, h - 100.0),
                      child: Opacity(
                        opacity: edgeFade,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.8),
                          ),
                          child: Icon(
                            _pinIcon(hotspot.type),
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return Positioned(
                    left: (posX - 54).clamp(12.0, (w - 132.0).clamp(12.0, w)),
                    top: posY.clamp(138.0, (h - 150.0).clamp(138.0, h)),
                    child: Opacity(
                      opacity: edgeFade,
                      child: _buildFloating360HotspotTag(hotspot),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color iconColor = Colors.white,
    bool highlighted = false,
  }) {
    final btn = GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted
                  ? AppColors.green800.withValues(alpha: 0.82)
                  : Colors.black.withValues(alpha: 0.34),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.26),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 19),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  Widget _buildFloatingHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildGlassCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: AppLocale.tr('Kembali', 'Back'),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _dest.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Icon(
                                  _isAerialMode
                                      ? Icons.flight_takeoff_rounded
                                      : Icons.directions_walk_rounded,
                                  size: 11,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _isVrMode
                                        ? AppLocale.tr(
                                            'Mode VR Stereoscopic',
                                            'Stereoscopic VR Mode',
                                          )
                                        : '${_isAerialMode ? AppLocale.tr('Drone 150m', 'Aerial 150m') : AppLocale.tr('Titik Darat', 'Ground Spot')} · ${_yawAngle.toStringAsFixed(0)}° / ${_pitchAngle.toStringAsFixed(0)}°${(_isBeSceneLoaded ?? false) ? ' · BE-1' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildGlassCircleButton(
                  icon: Icons.vrpano_rounded,
                  tooltip: _isVrMode
                      ? AppLocale.tr('Keluar Mode VR', 'Exit VR Mode')
                      : AppLocale.tr('Mode VR', 'VR Mode'),
                  iconColor: _isVrMode ? const Color(0xFFF5B041) : Colors.white,
                  highlighted: _isVrMode,
                  onTap: () => setState(() => _isVrMode = !_isVrMode),
                ),
                const SizedBox(width: 6),
                _buildGlassCircleButton(
                  icon: _isGyroEnabled
                      ? Icons.screen_rotation_rounded
                      : Icons.screen_lock_rotation_rounded,
                  tooltip: AppLocale.tr('Sensor Gyroscope', 'Gyroscope Sensor'),
                  iconColor:
                      _isGyroEnabled ? const Color(0xFF6EE7B7) : Colors.white60,
                  onTap: () =>
                      setState(() => _isGyroEnabled = !_isGyroEnabled),
                ),
              ],
            ),
            if (!_isVrMode) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeChip(
                              label: AppLocale.tr('Drone Udara', 'Aerial'),
                              icon: Icons.flight_takeoff_rounded,
                              selected: _isAerialMode,
                              onTap: () =>
                                  setState(() => _isAerialMode = true),
                            ),
                            _buildModeChip(
                              label: AppLocale.tr('Titik Darat', 'Ground'),
                              icon: Icons.directions_walk_rounded,
                              selected: !_isAerialMode,
                              onTap: () =>
                                  setState(() => _isAerialMode = false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isSpatialAudioPlaying)
                    Builder(
                      builder: (_) {
                        final pan = (_yawAngle % 360) / 180.0 - 1.0;
                        final leftPct =
                            ((1.0 - pan) * 50).clamp(10, 90).toInt();
                        final rightPct = 100 - leftPct;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pinAudioEmas
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.graphic_eq_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'L:$leftPct% R:$rightPct%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMiniGlassBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF5B041).withValues(alpha: 0.7),
              width: 1.2,
            ),
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
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5B041),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.pause_rounded,
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
                        Text(
                          AppLocale.tr(
                            'NARASI SUARA AI SEJARAH',
                            'AI HISTORICAL NARRATION',
                          ),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFFF5B041),
                          ),
                        ),
                        Text(
                          _dest.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(
                      () => _isNarrationExpanded = !_isNarrationExpanded,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isNarrationExpanded
                            ? AppLocale.tr('Tutup', 'Hide')
                            : AppLocale.tr('Teks', 'Script'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
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
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFF5B041)),
                  minHeight: 3,
                ),
              ),
              if (_isNarrationExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _getHistoricalNarration(),
                      style: const TextStyle(
                        fontSize: 11.5,
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
    );
  }

  /// Floating Glass Bar untuk Musik Tradisional Minangkabau (Saluang & Talempong)
  Widget _buildMinangMusicGlassBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleMinangMusic(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.pause_rounded,
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
                        Text(
                          AppLocale.tr(
                            'MUSIK TRADISIONAL MINANGKABAU',
                            'MINANG TRADITIONAL MUSIC',
                          ),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Saluang, Talempong & Bansi · Nada Singgalang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.equalizer_rounded,
                          color: Color(0xFF10B981),
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Live Ambience',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _minangMusicProgress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF10B981),
                  ),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu pratinjau kaca tipis ketika 1 pin dipilih (tidak menutupi pemandangan)
  Widget _buildFocusedHotspotGlassCard(Hotspot360Model hotspot) {
    final color = _pinColor(hotspot.type);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.8)),
                ),
                alignment: Alignment.center,
                child: Icon(_pinIcon(hotspot.type), color: color, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hotspot.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hotspot.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showHotspotSheet(hotspot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    AppLocale.tr('Detail', 'Info'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _activeHotspotPreview = null),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white60,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Panel bawah minimalis kaca (Frosted Glass Dock) yang bisa dibuka/tutup
  Widget _buildMinimalistBottomDock() {
    final hotspots = _currentHotspots;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pratinjau singkat jika ada pin yang dipilih
            if (_activeHotspotPreview != null && !_pinListExpanded) ...[
              _buildFocusedHotspotGlassCard(_activeHotspotPreview!),
              const SizedBox(height: 8),
            ],

            // Daftar 4 Pin versi kaca tipis (hanya muncul kalau pengguna tekan tombol expand)
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: _pinListExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocale.tr(
                                        'Titik Interaktif Scene Ini',
                                        'Interactive Scene Pins',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _isPinListExpanded = false,
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...hotspots.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final hotspot = entry.value;
                                  final color = _pinColor(hotspot.type);
                                  final isAudio = hotspot.type == 'audio' ||
                                      hotspot.type == 'narasi';
                                  final isMusik = hotspot.type == 'musik';
                                  final isAudioPlaying =
                                      isAudio && _isSpatialAudioPlaying;
                                  final isMusikPlaying =
                                      isMusik && _isMinangMusicPlaying;

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (idx > 0)
                                        Divider(
                                          height: 1,
                                          color: Colors.white
                                              .withValues(alpha: 0.12),
                                        ),
                                      InkWell(
                                        onTap: () =>
                                            _handleHotspotTap(hotspot),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 9,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                    alpha: 0.22,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: color.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  _pinIcon(hotspot.type),
                                                  color: color,
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      hotspot.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: isAudioPlaying
                                                            ? const Color(
                                                                0xFFF5B041,
                                                              )
                                                            : (isMusikPlaying
                                                                ? const Color(
                                                                    0xFF10B981,
                                                                  )
                                                                : Colors.white),
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    Text(
                                                      _pinBadgeLabel(
                                                        hotspot.type,
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 10.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                isAudio
                                                    ? (isAudioPlaying
                                                        ? Icons
                                                            .pause_circle_filled_rounded
                                                        : Icons
                                                            .play_circle_fill_rounded)
                                                    : (isMusik
                                                        ? (isMusikPlaying
                                                            ? Icons
                                                                .pause_circle_filled_rounded
                                                            : Icons
                                                                .play_circle_fill_rounded)
                                                        : Icons
                                                            .chevron_right_rounded),
                                                color: isAudio
                                                    ? const Color(0xFFF5B041)
                                                    : (isMusik
                                                        ? const Color(0xFF10B981)
                                                        : Colors.white60),
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Ultra-Slim Floating Glass Dock (1 baris ramping ~52px)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ...hotspots.map((hotspot) {
                        final color = _pinColor(hotspot.type);
                        final isAudio = hotspot.type == 'audio' ||
                            hotspot.type == 'narasi';
                        final isMusik = hotspot.type == 'musik';
                        final isAudioPlaying =
                            isAudio && _isSpatialAudioPlaying;
                        final isMusikPlaying =
                            isMusik && _isMinangMusicPlaying;
                        final isActive = isAudioPlaying ||
                            isMusikPlaying ||
                            _activeHotspotPreview?.id == hotspot.id;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _handleHotspotTap(hotspot),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? color.withValues(alpha: 0.24)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: color.withValues(
                                        alpha: isActive ? 0.95 : 0.25,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      _pinIcon(hotspot.type),
                                      color: isActive ? Colors.white : color,
                                      size: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _pinShortLabel(hotspot.type),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.88),
                                        fontSize: 11,
                                        fontWeight: isActive
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                          () => _isPinListExpanded = !_pinListExpanded,
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _pinListExpanded
                                ? Colors.white.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _pinListExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: Colors.white,
                            size: 19,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.notifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.ink900,
          body: _isVrMode
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildVrEyeView(isLeft: true)),
                        Container(
                          width: 4,
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                        Expanded(child: _buildVrEyeView(isLeft: false)),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildFloatingHeader(),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. FULL-SCREEN SEAMLESS 360° PANORAMA VIEWER
                    _buildSeamless360PanoramicCanvas(),

                    // 2. GRADIENT VIGNETTE TIPIS ATAS & BAWAH (AGAR TEKS KACA TETAP KONTRAST)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 140,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.52),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. FLOATING GLASS HEADER & AERIAL/GROUND TOGGLE
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildFloatingHeader(),
                    ),

                    // 4. FLOATING AI AUDIO & MUSIK MINANG MINI-BAR
                    if (_isSpatialAudioPlaying || _isMinangMusicPlaying)
                      Positioned(
                        top: 124,
                        left: 14,
                        right: 14,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSpatialAudioPlaying)
                              _buildAudioMiniGlassBar(),
                            if (_isSpatialAudioPlaying && _isMinangMusicPlaying)
                              const SizedBox(height: 8),
                            if (_isMinangMusicPlaying)
                              _buildMinangMusicGlassBar(),
                          ],
                        ),
                      ),

                    // 5. ULTRA-MINIMALIST FROSTED GLASS BOTTOM DOCK (3 PIN ELEGAN: 360, NARASI SEJARAH, MUSIK MINANG)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildMinimalistBottomDock(),
                    ),
                  ],
                ),
        );
      },
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green800.withValues(alpha: 0.92)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
