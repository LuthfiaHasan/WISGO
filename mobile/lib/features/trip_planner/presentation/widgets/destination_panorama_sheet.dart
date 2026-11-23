import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../../../core/theme/app_colors.dart';

/// Modal Viewer Foto Panorama 360° Realistis Destinasi (Item Pengalaman & Kondisi Nyata)
/// Menggunakan PanoramaViewer untuk navigasi sudut pandang destinasi secara 360 derajat.
class DestinationPanoramaSheet extends StatefulWidget {
  final String destinationName;
  final String panoramaImageUrl;
  final String subtitle;

  const DestinationPanoramaSheet({
    super.key,
    required this.destinationName,
    this.panoramaImageUrl =
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=2000&q=80',
    this.subtitle = 'Panorama 360° Sudut Pandang Tebing & Lembah Harau',
  });

  @override
  State<DestinationPanoramaSheet> createState() =>
      _DestinationPanoramaSheetState();
}

class _DestinationPanoramaSheetState extends State<DestinationPanoramaSheet> {
  bool _isSensorEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.threesixty_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.destinationName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 360 Panorama View Area
          SizedBox(
            height: 420,
            width: double.infinity,
            child: Stack(
              children: [
                // Panorama Viewer Widget
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: PanoramaViewer(
                    sensorControl: _isSensorEnabled
                        ? SensorControl.orientation
                        : SensorControl.none,
                    child: Image.network(
                      widget.panoramaImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        // Fallback jika offline/tidak ada koneksi gambar
                        return Container(
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.panorama_photosphere_rounded,
                                  size: 64,
                                  color: Colors.white38,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Mode Panorama 360° Aktif',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Geser layar atau gerakkan HP untuk melihat lanskap',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Floating Overlay Instructions & Controls
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFF68D391),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Geser untuk putar 360° • Cubit untuk zoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Gyroscope Sensor Toggle Button
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: InkWell(
                    onTap: () {
                      setState(() => _isSensorEnabled = !_isSensorEnabled);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.ink,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                          content: Text(
                            _isSensorEnabled
                                ? 'Sensor Gyroskop HP Aktif'
                                : 'Sensor Gyroskop Dimatikan (Navigasi Sentuh)',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isSensorEnabled
                            ? AppColors.forest
                            : Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSensorEnabled
                                ? Icons.screen_rotation_rounded
                                : Icons.screen_lock_rotation_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isSensorEnabled ? 'Gyro Aktif' : 'Gyro Mati',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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

          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
