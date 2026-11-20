import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../saved/presentation/screens/saved_places_screen.dart';
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

  void _skipToBeranda() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const SavedPlacesScreen(),
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
          // 1. Photographic Architectural Background (Rumah Gadang Gonjong Megah)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.58,
            child: Image.asset(
              'assets/images/onboarding_location_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. Gradiasi Warna Ivory Otentik WISGO (Menghubungkan Pemandangan & Konten)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.cream.withValues(alpha: 0.28), // Langit biru & atap gonjong terlihat jelas
                    AppColors.cream.withValues(alpha: 0.62), // Kabut ivory lembut
                    AppColors.cream.withValues(alpha: 0.92), // Transisi halus di belakang 3D model
                    AppColors.cream,                         // Solid ivory untuk teks & tombol aksi
                    AppColors.cream,
                  ],
                  stops: const [0.0, 0.24, 0.46, 0.72, 1.0],
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Langkah
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.sageBorder.withValues(alpha: 0.8),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Langkah 1 dari 2',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.sageBorder.withValues(alpha: 0.8),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: _skipToBeranda,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Lewati',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 2. Panggung 3D Rumah Gadang Interaktif (Tetap Asli dengan Efek Kedalaman)
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft ambient glow behind 3D circular badge
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
                              // Model 3D Asli
                              Animated3DRouteScene(spinBoost: _spinBoost),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 3. Penjelasan & 3 Kolom Manfaat Bersih
                        Column(
                          children: [
                            const Text(
                              'Izinkan Akses Lokasi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Aktifkan lokasi perangkat Anda untuk navigasi rute Sumatera Barat yang akurat dan informasi destinasi terdekat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildFeatureCard(
                                    title: 'Rute Akurat',
                                    subtitle: 'Bebas salah jalan',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFeatureCard(
                                    title: 'Wisata Sekitar',
                                    subtitle: 'Alam & kuliner',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFeatureCard(
                                    title: 'Privasi Terjaga',
                                    subtitle: 'Hanya saat aktif',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 4. Tombol Aksi Bawah (Hijau Resmi WisGo)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _activateLocationAndContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forest,
                                  foregroundColor: AppColors.cream,
                                  elevation: 2,
                                  shadowColor: AppColors.forest.withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
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
                                                fontSize: 13.5,
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
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.cream,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _skipToBeranda,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Lewati untuk Sekarang',
                                style: TextStyle(
                                  fontSize: 12.5,
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
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.sageBorder.withValues(alpha: 0.9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
