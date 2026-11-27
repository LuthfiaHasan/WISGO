import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_destination_image.dart';
import '../../../fair_price/data/models/fair_price_tariff_model.dart';

/// Smooth, isolated Hero Landmark Slider untuk Beranda WISGO.
///
/// Dirancang khusus untuk bebas patah-patah (60/120fps) pada Android & Web:
/// - Terisolasi di StatefulWidget sendiri (tidak pernah memanggil setState()
///   pada layar induk SavedPlacesScreen yang berat).
/// - Shadow & ClipRRect berada statis di luar PageView sehingga GPU tidak
///   merasterisasi ulang bayangan di setiap frame geseran.
/// - Infinite forward looping mulus tanpa loncatan balik 4 slide.
/// - Pre-cache & resize gambar (`cacheWidth: 900`, `gaplessPlayback: true`).
/// - Timer auto-slide otomatis jeda saat jari/mouse menyentuh slider.
/// - Indikator titik pill berubah ukuran secara real-time mengikuti posisi geser.
class WisgoHeroSlider extends StatefulWidget {
  final List<SavedDestinationModel> slides;
  final ValueChanged<SavedDestinationModel> onOpenDetail;
  final ValueChanged<SavedDestinationModel> onOpen360;
  final bool isEnglish;
  final Duration autoSlideInterval;

  const WisgoHeroSlider({
    super.key,
    required this.slides,
    required this.onOpenDetail,
    required this.onOpen360,
    required this.isEnglish,
    this.autoSlideInterval = const Duration(seconds: 5),
  });

  @override
  State<WisgoHeroSlider> createState() => _WisgoHeroSliderState();
}

class _WisgoHeroSliderState extends State<WisgoHeroSlider> {
  static const int _kVirtualCount = 10000;

  late final int _initialPage;
  late final PageController _pageController;
  late final ValueNotifier<int> _activeIndexNotifier;
  Timer? _autoSlideTimer;
  bool _isPointerDown = false;
  bool _isUserDragging = false;
  bool _hasPrecached = false;

  @override
  void initState() {
    super.initState();
    final count = widget.slides.length;
    _initialPage = count > 1
        ? (_kVirtualCount ~/ 2) - ((_kVirtualCount ~/ 2) % count)
        : 0;
    _pageController = PageController(initialPage: _initialPage);
    _activeIndexNotifier = ValueNotifier<int>(0);
    _startAutoSlideTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecached && widget.slides.isNotEmpty) {
      _hasPrecached = true;
      for (final slide in widget.slides) {
        final provider = WisgoDestinationImage.resolveProvider(
          id: slide.id,
          title: slide.title,
          source: slide.imageUrl,
          cacheWidth: 900,
        );
        if (provider != null) {
          precacheImage(provider, context, onError: (_, __) {});
        }
      }
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _activeIndexNotifier.dispose();
    super.dispose();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    if (widget.slides.length <= 1) return;
    _autoSlideTimer = Timer.periodic(widget.autoSlideInterval, (_) {
      _advanceAutoSlide();
    });
  }

  void _advanceAutoSlide() {
    if (!mounted ||
        _isPointerDown ||
        _isUserDragging ||
        widget.slides.length <= 1 ||
        !_pageController.hasClients) {
      return;
    }

    final count = widget.slides.length;
    var current = _pageController.page?.round() ?? _initialPage;

    // Jaga agar indeks virtual tetap berada di rentang aman tengah
    if (current >= _kVirtualCount - 20) {
      final resetTarget = _initialPage + (current % count);
      _pageController.jumpToPage(resetTarget);
      current = resetTarget;
    }

    _pageController.animateToPage(
      current + 1,
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  void _animateToRealIndex(int targetRealIdx) {
    final count = widget.slides.length;
    if (count <= 1 || !_pageController.hasClients) return;

    final current = _pageController.page?.round() ?? _initialPage;
    final currentReal = current % count;
    if (targetRealIdx == currentReal) return;

    int delta = targetRealIdx - currentReal;
    final half = count ~/ 2;
    if (delta > half) delta -= count;
    if (delta < -half) delta += count;

    _startAutoSlideTimer();
    _pageController.animateToPage(
      current + delta,
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    if (slides.isEmpty) return const SizedBox.shrink();

    final isLooping = slides.length > 1;

    return Column(
      children: [
        // Frame statis di luar PageView: shadow & clip hanya dirasterisasi sekali oleh GPU
        RepaintBoundary(
          child: Container(
            height: 222,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: AppColors.forest,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ScrollConfiguration(
                behavior: const _HeroSliderScrollBehavior(),
                child: Listener(
                  onPointerDown: (_) {
                    _isPointerDown = true;
                    _autoSlideTimer?.cancel();
                  },
                  onPointerUp: (_) {
                    _isPointerDown = false;
                    if (!_isUserDragging) {
                      _startAutoSlideTimer();
                    }
                  },
                  onPointerCancel: (_) {
                    _isPointerDown = false;
                    if (!_isUserDragging) {
                      _startAutoSlideTimer();
                    }
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        _isUserDragging = true;
                        _autoSlideTimer?.cancel();
                      } else if (notification is ScrollEndNotification) {
                        if (_isUserDragging) {
                          _isUserDragging = false;
                          if (!_isPointerDown) {
                            _startAutoSlideTimer();
                          }
                        }
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      allowImplicitScrolling: true,
                      physics: const _SmoothHeroPagePhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: isLooping ? _kVirtualCount : slides.length,
                      onPageChanged: (virtualIdx) {
                        final realIdx = virtualIdx % slides.length;
                        if (_activeIndexNotifier.value != realIdx) {
                          _activeIndexNotifier.value = realIdx;
                        }
                      },
                      itemBuilder: (context, virtualIdx) {
                        final realIdx = virtualIdx % slides.length;
                        final hero = slides[realIdx];
                        return RepaintBoundary(
                          child: _HeroLandmarkSlideCard(
                            hero: hero,
                            slideIndex: realIdx,
                            isEnglish: widget.isEnglish,
                            onOpenDetail: () => widget.onOpenDetail(hero),
                            onOpen360: () => widget.onOpen360(hero),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Real-time Smooth Morphing Pill Dot Indicators (hanya merender ulang 5 titik kecil)
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pageController, _activeIndexNotifier]),
            builder: (context, _) {
              final count = slides.length;
              double currentPos = _activeIndexNotifier.value.toDouble();
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                final page = _pageController.page;
                if (page != null) {
                  currentPos = page % count;
                }
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(count, (idx) {
                  double dist = (currentPos - idx).abs();
                  if (dist > count / 2) {
                    dist = count - dist;
                  }
                  final t = (1.0 - dist).clamp(0.0, 1.0);
                  final width = 6.0 + (15.0 * t);
                  final color = Color.lerp(
                    AppColors.ink.withValues(alpha: 0.20),
                    AppColors.forest,
                    t,
                  )!;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _animateToRealIndex(idx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 4,
                      ),
                      child: Container(
                        width: width,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeroLandmarkSlideCard extends StatelessWidget {
  final SavedDestinationModel hero;
  final int slideIndex;
  final bool isEnglish;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpen360;

  const _HeroLandmarkSlideCard({
    required this.hero,
    required this.slideIndex,
    required this.isEnglish,
    required this.onOpenDetail,
    required this.onOpen360,
  });

  static const _badgeLabelsEn = [
    'MAIN LANDMARK',
    'GRANITE CLIFFS',
    'BUKITTINGGI ICON',
    'MARINE PARADISE',
    'MINANG HERITAGE',
  ];

  static const _badgeLabelsId = [
    'LANDMARK UTAMA',
    'TEBING GRANIT',
    'IKON BUKITTINGGI',
    'SURGA BAHARI',
    'WARISAN MINANG',
  ];

  static const _temps = ['28°C', '24°C', '22°C', '29°C', '25°C'];

  @override
  Widget build(BuildContext context) {
    final badgeLabels = isEnglish ? _badgeLabelsEn : _badgeLabelsId;
    final badgeText = badgeLabels[slideIndex % badgeLabels.length];
    final tempText = _temps[slideIndex % _temps.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.forest),
        WisgoDestinationImage(
          source: hero.imageUrl,
          destinationId: hero.id,
          destinationTitle: hero.title,
          fit: BoxFit.cover,
          cacheWidth: 900,
          filterQuality: FilterQuality.medium,
          fallback: const ColoredBox(color: AppColors.forest),
        ),
        // Smooth Editorial Bottom Scrim
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF0A140D).withValues(alpha: 0.84),
                const Color(0xFF0A140D).withValues(alpha: 0.24),
                AppColors.ink.withValues(alpha: 0.06),
              ],
              stops: const [0.0, 0.56, 1.0],
            ),
          ),
        ),
        // Top Subtle Translucent Glass Pills (Ringan 60/120fps tanpa BackdropFilter stall)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1D13).withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${hero.region}, Sumbar',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1D13).withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wb_sunny_rounded,
                      size: 12,
                      color: Color(0xFFFCD34D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tempText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom Hero Text + Clean Pure Frosted Glass Buttons
        Positioned(
          bottom: 14,
          left: 14,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC85B2D),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${hero.distanceKm.toStringAsFixed(hero.distanceKm.truncateToDouble() == hero.distanceKm ? 0 : 1)} ${AppLocale.tr('km dari sini', 'km away')}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                hero.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.18,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onOpenDetail,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.16),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.38),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocale.tr(
                                  'Lihat Destinasi',
                                  'View Destination',
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Panorama 360°',
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onOpen360,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.16),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.38),
                              width: 0.9,
                            ),
                          ),
                          child: const Icon(
                            Icons.threesixty_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fisika geser khusus dengan redaman halus (nearly critically damped)
/// agar slide mendarat lembut tanpa hentakan patah.
class _SmoothHeroPagePhysics extends PageScrollPhysics {
  const _SmoothHeroPagePhysics({super.parent});

  @override
  _SmoothHeroPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _SmoothHeroPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1.0,
        stiffness: 180.0,
        damping: 26.0,
      );
}

/// Mengaktifkan geser sentuh, mouse, dan trackpad agar mulus di HP maupun Web.
class _HeroSliderScrollBehavior extends MaterialScrollBehavior {
  const _HeroSliderScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
