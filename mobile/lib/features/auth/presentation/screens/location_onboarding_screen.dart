import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';
import '../../services/auth_session.dart';
import '../widgets/animated_3d_route_scene.dart';
import 'login_screen.dart';

class LocationOnboardingScreen extends StatefulWidget {
  const LocationOnboardingScreen({super.key});

  @override
  State<LocationOnboardingScreen> createState() =>
      _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState extends State<LocationOnboardingScreen> {
  bool _isLockingGps = false;
  double _spinBoost = 0.0;
  bool _isButtonPressed = false;

  void _skipToBeranda() {
    AuthSession.instance.setGuestMode();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const SavedPlacesScreen(isGuest: true),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }

  void _skipToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _activateLocationAndContinue() {
    if (_isLockingGps) return;
    setState(() {
      _isLockingGps = true;
      _spinBoost = 0.08;
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _isLockingGps = false;
        _spinBoost = 0.0;
      });
      _skipToLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Photographic Architectural Background (Rumah Gadang Gonjong Megah HD)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.56,
            child: Image.asset(
              'assets/images/onboarding_location_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Gradiasi Warna Ivory Otentik WISGO
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.cream.withValues(alpha: 0.28), // Langit biru & gonjong terlihat jelas
                    AppColors.cream.withValues(alpha: 0.60), // Kabut ivory lembut
                    AppColors.cream.withValues(alpha: 0.90), // Transisi mulus di sekitar 3D model
                    AppColors.cream,                         // Solid ivory penuh untuk teks & kontrol aksi
                    AppColors.cream,
                  ],
                  stops: const [0.0, 0.22, 0.44, 0.68, 1.0],
                ),
              ),
            ),
          ),

          // 3. Konten Utama Layar
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Spacer atas untuk memberi ruang bagi tombol Lewati
                        const SizedBox(height: 36),

                        // Panggung 3D Rumah Gadang Interaktif (Tetap Asli dengan Ambient Glow)
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.forest.withValues(alpha: 0.08),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.70),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Animated3DRouteScene(spinBoost: _spinBoost),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tipografi Judul & Subjudul (FONT SAMA PERSIS DENGAN 3 SPLASHSCREEN)
                        Column(
                          children: const [
                            Text(
                              'Izinkan Akses Lokasi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.forest,
                                height: 1.20,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Aktifkan lokasi perangkat Anda untuk navigasi rute Sumatera Barat yang akurat dan informasi destinasi terdekat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.muted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Tombol Aksi Bawah (HIJAU RESMI WISGO DENGAN BENTUK PILL SAMA DENGAN SPLASHSCREEN)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTapDown: (_) => setState(() => _isButtonPressed = true),
                              onTapUp: (_) => setState(() => _isButtonPressed = false),
                              onTapCancel: () => setState(() => _isButtonPressed = false),
                              child: AnimatedScale(
                                scale: _isButtonPressed ? 0.96 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _activateLocationAndContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.forest,
                                      foregroundColor: AppColors.cream,
                                      elevation: 3,
                                      shadowColor: Colors.black.withValues(alpha: 0.35),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                        side: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.20),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                    child: _isLockingGps
                                        ? const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: AppColors.cream,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  'Menyesuaikan Titik Lokasi Sumatera Barat...',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.cream,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            'Izinkan Akses Lokasi',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _skipToBeranda,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Lewati untuk Sekarang',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Fixed Top Bar: Tombol Lewati di Kanan Atas (FLOATING DI LAPISAN TERATAS AGAR BISA DI-KLIK)
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
                    onTap: _skipToBeranda,
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
                            color: Colors.black.withValues(alpha: 0.08),
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
        ],
      ),
    );
  }
}
