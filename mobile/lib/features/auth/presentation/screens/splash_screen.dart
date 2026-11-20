import 'dart:async';
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
/// - Menggunakan 3 foto lanskap otentik Sumatera Barat kiriman pengguna
/// - Menampilkan Logo Asli WISGO (100% transparan, tajam, dan elegan)
/// - Menjaga palet warna identitas resmi WISGO (AppColors.forest & AppColors.cream)
/// - Mempertahankan alur navigasi aplikasi ke LocationOnboardingScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _userInteracted = false;

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
            // 1. Full-bleed Scenic Photography Backgrounds with PageView
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
                    Image.asset(
                      slide.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    // Top gradient overlay for logo readability
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 240,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.72),
                              Colors.black.withValues(alpha: 0.35),
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
                              Colors.black.withValues(alpha: 0.40),
                              Colors.black.withValues(alpha: 0.78),
                              Colors.black.withValues(alpha: 0.94),
                            ],
                            stops: const [0.0, 0.32, 0.68, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 2. Fixed Top Bar: Real WISGO Logo & Lewati Button
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
                      // Invisible spacer to balance the Lewati button
                      const SizedBox(width: 60),

                      // Real WISGO Logo in pure crisp white
                      const Hero(
                        tag: 'wisgo_app_logo',
                        child: WisgoLogo(
                          width: 140,
                          color: Colors.white,
                        ),
                      ),

                      // Tombol Lewati (Pill Glassmorphic)
                      GestureDetector(
                        onTap: _goToOnboarding,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.32),
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
                              fontSize: 12,
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

            // 3. Bottom Content: Indicator, Title, Subtitle, CTA Button
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
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (idx) {
                          final isActive = _currentPage == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.symmetric(horizontal: 3.5),
                            width: isActive ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.36),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 22),

                      // Title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _slides[_currentPage].title,
                          key: ValueKey<int>(_currentPage),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.22,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _slides[_currentPage].subtitle,
                          key: ValueKey<String>('sub_$_currentPage'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Primary Action Button (Warna Khas WisGo: Forest Green dengan aksen lembut)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _handleButtonPress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
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
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
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
