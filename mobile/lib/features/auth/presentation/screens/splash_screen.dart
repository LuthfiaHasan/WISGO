import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/wisgo_logo.dart';
import 'location_onboarding_screen.dart';

/// Screen 1: Splash Screen (1:1 dari `wisgo_interactive_3d_prototype.html`)
/// - LOGO ONLY — Zero Clutter, Pure & Iconic di atas latar `#FAF3E6`
/// - Animasi goresan kuas kaligrafi (`strokeDraw` 1.4s) + gerakan mengapung halus (`logoFloat` 4s)
/// - Progress bar minimalis di bawah (`w-24 h-1 bg-[#DFECE2]` dengan fill `#193D22` selama 2.2s)
/// - Teks petunjuk: "Ketuk layar untuk mulai menjelajah"
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _strokeController;
  late final AnimationController _floatController;
  late final AnimationController _progressController;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // Animasi goresan kuas 1.4 detik
    _strokeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Animasi mengapung halus 4 detik
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Animasi progress bar bawah 2.2 detik
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Auto-transisi ke Layar 2 setelah 2.4 detik (persis wisgo_interactive_3d_prototype.html)
    _navTimer = Timer(const Duration(milliseconds: 2400), _goToOnboarding);
  }

  void _goToOnboarding() {
    _navTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => const LocationOnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _strokeController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goToOnboarding,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Top Empty Spacer untuk keseimbangan vertikal murni
                const SizedBox(height: 24),

                // 2. Centerpiece: ONLY the WISGO Calligraphic Brush Logo & Wordmark
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _strokeController,
                      _floatController,
                    ]),
                    builder: (context, _) {
                      final strokeCurve = CurvedAnimation(
                        parent: _strokeController,
                        curve: Curves.easeOutExpo,
                      ).value;
                      final floatWave =
                          math.sin(_floatController.value * 2 * math.pi);
                      final dy = floatWave * -5.0;
                      final scale = 1.0 + (floatWave.abs() * 0.015);

                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.scale(
                          scale: scale,
                          child: WisgoLogo(
                            width: 220,
                            strokeProgress: strokeCurve,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3. Minimal Loading Progress Bar & Tap Hint di bagian paling bawah
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          final progress = CurvedAnimation(
                            parent: _progressController,
                            curve: Curves.easeOut,
                          ).value;
                          return FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ketuk layar untuk mulai menjelajah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
