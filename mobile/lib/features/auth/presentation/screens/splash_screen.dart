import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_logo.dart';
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

/// Screen 1: Splash Screen & Onboarding Visual Showcase
/// - Menggunakan 3 foto lanskap otentik Sumatera Barat HD 1080x1920
/// - Menampilkan Logo Asli WISGO (100% transparan, floating bebas tanpa background ivory/kotak)
/// - Menggunakan warna hijau resmi WISGO (AppColors.forest #193D22) serasi dengan tombol Izinkan Akses Lokasi
/// - Animasi lengkap: Ken Burns slow zoom, logo entrance & breathing float, transisi teks halus, dan micro-interaction
/// - Alur navigasi tetap terjaga ke LocationOnboardingScreen
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

  // 2. Logo entrance animation (fade + slide down)
  late final AnimationController _logoEntranceController;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<Offset> _logoSlideAnimation;

  // 3. Logo subtle floating/hovering animation
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

    // Inisialisasi animasi masuk Logo
    _logoEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFadeAnimation = CurvedAnimation(
      parent: _logoEntranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
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

    _logoEntranceController.forward();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (!mounted || _userInteracted) return;
      if (_currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 450),
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
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToOnboarding();
    }
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
    _logoEntranceController.dispose();
    _logoFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) => _onUserInteraction(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-bleed Scenic Photography Backgrounds with Ken Burns Animated Zoom
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Animated Ken Burns slow zoom
                    AnimatedBuilder(
                      animation: _bgScaleAnimation,
                      builder: (context, child) {
                        final isCurrent = _currentPage == index;
                        return Transform.scale(
                          scale: isCurrent ? _bgScaleAnimation.value : 1.0,
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        slide.imageAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    // Subtle top vignette to protect status bar while keeping bright natural sky
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 140,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.32),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bottom dark gradient overlay for text readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 480,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.36),
                              Colors.black.withValues(alpha: 0.78),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.28, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 2. Fixed Top Bar: Authentic WISGO Logo (NO Ivory Background) & Lewati Button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Invisible spacer to mathematically balance the Lewati button
                      const SizedBox(width: 72),

                      // Logo Resmi WISGO floating bebas (Tanpa background kotak / ivory)
                      SlideTransition(
                        position: _logoSlideAnimation,
                        child: FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: AnimatedBuilder(
                            animation: _logoFloatAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _logoFloatAnimation.value),
                                child: child,
                              );
                            },
                            child: Hero(
                              tag: 'wisgo_app_logo',
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Soft contour drop shadow directly behind logo strokes
                                  ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Image.asset(
                                      'assets/images/logo_primary.png',
                                      width: 135,
                                      color: Colors.black.withValues(alpha: 0.35),
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                  // Logo Asli dengan warna hijau asli
                                  const WisgoLogo(
                                    width: 135,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Tombol Lewati (Pill Glassmorphic Transparan)
                      GestureDetector(
                        onTap: _goToOnboarding,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.36),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Bottom Content: Indicator, Title, Subtitle, CTA Button (HIJAU RESMI WISGO)
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
                      // Dots Indicator (Animasi Lebar & Warna Lembut)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (idx) {
                          final isActive = _currentPage == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 26 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.36),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.40),
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

                      // Animated Title (Slide-up + Fade)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        transitionBuilder: (child, animation) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.25),
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _slides[_currentPage].title,
                          key: ValueKey<int>(_currentPage),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.20,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Animated Subtitle (Slide-up + Fade)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        transitionBuilder: (child, animation) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.20),
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _slides[_currentPage].subtitle,
                          key: ValueKey<String>('sub_$_currentPage'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Primary Action Button (HIJAU RESMI WISGO: AppColors.forest #193D22, SESUAI TOMBOL LOKASI)
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
                                backgroundColor: AppColors.forest, // HIJAU RESMI WISGO #193D22
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: Colors.black.withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28), // Bentuk Pill serasi
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18),
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
