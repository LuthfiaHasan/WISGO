import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';

/// Layar 07 · Panorama View 360° Destinasi
/// Fokus pada foto panorama 360° bersih tanpa ikon hotspot agar gambaran kondisi destinasi lebih nyata.
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
  bool _isVrMode = false;
  double _yawAngle = 20.0;
  double _pitchAngle = -5.0;

  List<Scene360Model>? _liveScenes360;
  bool? _isBeSceneLoaded = false;

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

  String? _resolvedNetworkPanoramaUrl() {
    final scenes = _activeScenes;
    if (scenes.isNotEmpty) {
      final targetType = _isAerialMode ? 'aerial' : 'ground';
      final matched = scenes.where((s) => s.type == targetType).toList();
      final candidate = matched.isNotEmpty
          ? matched.first.panoramaUrl
          : scenes.first.panoramaUrl;
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
                color: AppColors.ink,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.successBorder,
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

  Widget _buildVrEyeView({required bool isLeft}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildSeamless360PanoramicCanvas(
          stereoOffset: isLeft ? -4.0 : 4.0,
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
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isLeft ? 'LEFT EYE' : 'RIGHT EYE',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kanvas Panorama 360° Bersih (Pure Panorama View tanpa ikon/pin mengambang)
  Widget _buildSeamless360PanoramicCanvas({
    double stereoOffset = 0.0,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        final double tileW = (w * 1.95).clamp(420.0, 2400.0);
        final double cycleW = tileW * 2.0;
        final double canvasH = h * 1.32;

        double normalizedYaw = (_yawAngle + stereoOffset) % 360.0;
        if (normalizedYaw < 0) normalizedYaw += 360.0;
        final double shiftX = (normalizedYaw / 360.0) * cycleW;

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
            child: AnimatedScale(
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
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlighted
                    ? AppColors.forest.withValues(alpha: 0.82)
                    : AppColors.ink.withValues(alpha: 0.34),
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
                          color: AppColors.ink.withValues(alpha: 0.34),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                const Icon(
                                  Icons.threesixty_rounded,
                                  size: 12,
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
                                        : '${AppLocale.tr('Panorama 360°', '360° Panorama')} · ${_yawAngle.toStringAsFixed(0)}° / ${_pitchAngle.toStringAsFixed(0)}°${(_isBeSceneLoaded ?? false) ? ' · BE-1' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
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
                  iconColor: _isVrMode ? AppColors.goldSoft : Colors.white,
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
                      _isGyroEnabled ? AppColors.successBorder : Colors.white60,
                  onTap: () =>
                      setState(() => _isGyroEnabled = !_isGyroEnabled),
                ),
              ],
            ),
            if (!_isVrMode) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeChip(
                            label: AppLocale.tr('Panorama Luas', 'Wide'),
                            icon: Icons.panorama_horizontal_rounded,
                            selected: _isAerialMode,
                            onTap: () => setState(() => _isAerialMode = true),
                          ),
                          _buildModeChip(
                            label: AppLocale.tr('Dekat', 'Close'),
                            icon: Icons.zoom_in_rounded,
                            selected: !_isAerialMode,
                            onTap: () => setState(() => _isAerialMode = false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Petunjuk geser panorama minimalis di bagian bawah (tanpa ikon hotspot)
  Widget _buildPanoramaBottomHint() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.successBorder,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            AppLocale.tr(
                              'Geser layar untuk melihat panorama 360° destinasi',
                              'Drag screen to view 360° destination panorama',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
          backgroundColor: AppColors.ink,
          body: _isVrMode
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildVrEyeView(isLeft: true)),
                        Container(
                          width: 4,
                          color: AppColors.ink,
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
                    // 1. FULL-SCREEN SEAMLESS 360° PANORAMA VIEW (BERSIH TANPA IKON HOTSPOT)
                    _buildSeamless360PanoramicCanvas(),

                    // 2. GRADIENT VIGNETTE TIPIS ATAS & BAWAH
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 130,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.ink.withValues(alpha: 0.52),
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
                      height: 100,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.ink.withValues(alpha: 0.48),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. FLOATING GLASS HEADER
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildFloatingHeader(),
                    ),

                    // 4. MINIMALIST BOTTOM PANORAMA HINT
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildPanoramaBottomHint(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.forest.withValues(alpha: 0.92)
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
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
