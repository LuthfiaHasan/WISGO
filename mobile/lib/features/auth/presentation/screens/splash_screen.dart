import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_logo.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';
import '../../services/auth_session.dart';
import 'location_onboarding_screen.dart';

class OnboardingSlideData {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String buttonText;

  const OnboardingSlideData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });
}

/// Physics custom bergaya *Lenis smooth inertia* (damped spring lembut) khusus untuk Splash PageView.
class _LenisSmoothPagePhysics extends PageScrollPhysics {
  const _LenisSmoothPagePhysics({super.parent});

  @override
  _LenisSmoothPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _LenisSmoothPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1.0,
        stiffness: 85.0,
        damping: 18.0,
      );
}

/// Screen 1: Splash Screen & Onboarding Visual Showcase
/// - Menggunakan 3 foto lanskap otentik Sumatera Barat HD 1080x1920
/// - Gradiasi bawah menggunakan warna IVORY (AppColors.cream #FAF3E6), bukan hitam
/// - Logo WISGO ikut bergerak bersama slide saat berpindah (tidak diam/statis)
/// - Tipografi serasi dengan teks hijau hutan resmi (AppColors.forest) di atas ivory
/// - Tombol Lewati presisi dan seragam dengan halaman Izinkan Akses Lokasi
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _userInteracted = false;
  bool _isButtonPressed = false;

  // 1. Ken Burns background breathing zoom
  late final AnimationController _bgAnimationController;
  late final Animation<double> _bgScaleAnimation;

  // 2. Logo subtle floating/hovering animation
  late final AnimationController _logoFloatController;
  late final Animation<double> _logoFloatAnimation;

  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      imageAsset: 'assets/images/splash_bg_1.jpg',
      title: 'Jelajahi\nSumatera Barat',
      subtitle: 'Temukan keindahan tersembunyi negeri Minang yang menakjubkan',
      buttonText: 'Mulai Jelajah',
    ),
    OnboardingSlideData(
      imageAsset: 'assets/images/splash_bg_2.jpg',
      title: 'Wisata Autentik\nMinang',
      subtitle: 'Nikmati budaya, kuliner, dan alam Sumatera Barat dalam genggamanmu',
      buttonText: 'Eksplorasi Sekarang',
    ),
    OnboardingSlideData(
      imageAsset: 'assets/images/splash_bg_3.jpg',
      title: 'Perjalanan Tak\nTerlupakan',
      subtitle: 'Tarif resmi, rute akurat, dan pengalaman wisata terbaik bersamamu',
      buttonText: 'Ayo Mulai',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Inisialisasi Ken Burns Zoom halus
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _bgScaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _bgAnimationController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Inisialisasi floating logo halus
    _logoFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _logoFloatAnimation = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(
        parent: _logoFloatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _startAutoSlide();
  }

  bool _didPrecache = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrecache) {
      _didPrecache = true;
      for (final slide in _slides) {
        precacheImage(AssetImage(slide.imageAsset), context);
      }
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (!mounted || _userInteracted) return;
      if (_currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 620),
          curve: Curves.easeInOutCubic,
        );
        _startAutoSlide();
      } else {
        _goToOnboarding();
      }
    });
  }

  void _onUserInteraction() {
    if (!_userInteracted) {
      _userInteracted = true;
      _autoSlideTimer?.cancel();
    }
  }

  void _handleButtonPress() {
    _onUserInteraction();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 680),
        curve: Curves.easeOutExpo,
      );
    } else {
      _goToOnboarding();
    }
  }

  /// Lewati langsung masuk ke beranda sebagai Tamu (Guest Mode) tanpa login
  void _skipAsGuest() {
    _autoSlideTimer?.cancel();
    AuthSession.instance.setGuestMode();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const SavedPlacesScreen(isGuest: true),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
      (route) => false,
    );
  }

  void _goToOnboarding() {
    _autoSlideTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const LocationOnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _bgAnimationController.dispose();
    _logoFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Listener(
        onPointerDown: (_) => _onUserInteraction(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Seamless Real-Time Cross-Fade Background Stack (0 kebocoran & 0 garis belah saat di-slide manual)
            AnimatedBuilder(
              animation: Listenable.merge([
                _pageController,
                _bgScaleAnimation,
              ]),
              builder: (context, _) {
                final double page = (_pageController.hasClients &&
                        _pageController.position.haveDimensions)
                    ? (_pageController.page ?? _currentPage.toDouble())
                    : _currentPage.toDouble();

                return Stack(
                  fit: StackFit.expand,
                  children: List.generate(_slides.length, (index) {
                    final distance = (page - index).abs();
                    final opacity = (1.0 - distance).clamp(0.0, 1.0);
                    if (opacity <= 0.001) {
                      return const SizedBox.shrink();
                    }
                    final isCurrent = _currentPage == index;
                    final scale =
                        (isCurrent ? _bgScaleAnimation.value : 1.03) +
                            (distance * 0.03);
                    return RepaintBoundary(
                      child: Opacity(
                        opacity: opacity,
                        child: ClipRect(
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.center,
                            child: Image.asset(
                              _slides[index].imageAsset,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.medium,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            // 2. Gradiasi Ivory Atas & Bawah Tetap Utuh (Tidak pernah terbelah saat swipe)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 170,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cream.withValues(alpha: 0.34),
                        AppColors.cream.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 460,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.cream.withValues(alpha: 0.48),
                        AppColors.cream.withValues(alpha: 0.90),
                        AppColors.cream,
                      ],
                      stops: const [0.0, 0.30, 0.66, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Invisible Fullscreen PageView untuk Gestur Geser Manual Halus ala Lenis
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              physics: const _LenisSmoothPagePhysics(
                parent: BouncingScrollPhysics(),
              ),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) => const SizedBox.expand(),
            ),

            // 4. Logo Resmi WISGO Terpusat Utuh (Melayang halus tanpa terpotong ganda saat swipe)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _logoFloatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _logoFloatAnimation.value),
                            child: child,
                          );
                        },
                        child: const WisgoLogo(
                          width: 135,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 5. Fixed Top Bar: Tombol Lewati di Kanan Atas -> Langsung Masuk sebagai Tamu Tanpa Login
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _skipAsGuest,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.sageBorder.withValues(alpha: 0.9),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Lewati',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 6. Bottom Content: Real-time scrubbed Indicator, Title, Subtitle & CTA Button mengikuti geseran slider
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Real-Time Scrubbed Dots Indicator + Horizontal Glide Title & Subtitle
                      AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, _) {
                          final double page = (_pageController.hasClients &&
                                  _pageController.position.haveDimensions)
                              ? (_pageController.page ?? _currentPage.toDouble())
                              : _currentPage.toDouble();

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Dots Indicator mengikuti progres geseran jari secara real-time
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_slides.length, (idx) {
                                  final proximity =
                                      (1.0 - (page - idx).abs()).clamp(0.0, 1.0);
                                  final dotWidth =
                                      ui.lerpDouble(7.0, 26.0, proximity)!;
                                  final dotColor = Color.lerp(
                                    AppColors.sageBorder,
                                    AppColors.forest,
                                    proximity,
                                  )!;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: dotWidth,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: proximity > 0.5
                                          ? [
                                              BoxShadow(
                                                color: AppColors.forest
                                                    .withValues(
                                                  alpha: 0.25 * proximity,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 22),

                              // Title & Subtitle meluncur horizontal + cross-fade sinkron dengan slider (tanpa pop-up & adaptif segala skala font)
                              IgnorePointer(
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none,
                                  children:
                                      List.generate(_slides.length, (idx) {
                                    final delta = idx - page;
                                    final dist = delta.abs();
                                    if (dist >= 1.0) {
                                      return const SizedBox.shrink();
                                    }
                                    final opacity =
                                        (1.0 - (dist * 1.45)).clamp(0.0, 1.0);
                                    return Opacity(
                                      opacity: opacity,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Transform.translate(
                                            offset: Offset(delta * 52.0, 0),
                                            child: Text(
                                              _slides[idx].title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.forest,
                                                height: 1.20,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Transform.translate(
                                            offset: Offset(delta * 74.0, 0),
                                            child: Text(
                                              _slides[idx].subtitle,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: AppColors.muted,
                                                height: 1.45,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Primary Action Button (HIJAU RESMI WISGO: AppColors.forest #193D22)
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_) => setState(() => _isButtonPressed = false),
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        child: AnimatedScale(
                          scale: _isButtonPressed ? 0.96 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeInOut,
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _handleButtonPress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forest,
                                foregroundColor: AppColors.cream,
                                elevation: 3,
                                shadowColor: AppColors.ink.withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _slides[_currentPage].buttonText,
                                  key: ValueKey<String>(_slides[_currentPage].buttonText),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: Colors.white,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
