import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../saved/presentation/screens/saved_places_screen.dart';
import 'audio_guide_culture/audio_culture_screen.dart';
import 'hazard_alert_sos/hazard_sos_screen.dart';
import 'home/home_screen.dart';
import 'map_explore_shunlu/map_explore_screen.dart';
import 'offline_pocket/offline_pocket_screen.dart';

/// Shell Navigasi Utama Modul FE-1 (Visual 360°, Peta Shunlu, Budaya, Jalur Rawan & Offline)
class Fe1MainShell extends StatefulWidget {
  const Fe1MainShell({super.key});

  @override
  State<Fe1MainShell> createState() => _Fe1MainShellState();
}

class _Fe1MainShellState extends State<Fe1MainShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    MapExploreShunluScreen(),
    AudioCultureScreen(),
    HazardSosScreen(),
    OfflinePocketScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.green800.withValues(alpha: 0.14),
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppColors.green800),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route, color: AppColors.green800),
            label: 'Peta Shunlu',
          ),
          NavigationDestination(
            icon: Icon(Icons.record_voice_over_outlined),
            selectedIcon:
                Icon(Icons.record_voice_over, color: AppColors.green800),
            label: 'Budaya',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_rounded),
            selectedIcon: Icon(Icons.warning_rounded, color: AppColors.coral500),
            label: 'Jalur & SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.offline_pin_outlined),
            selectedIcon: Icon(Icons.offline_pin, color: AppColors.green800),
            label: 'Offline',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'fe2_bridge_btn',
              backgroundColor: AppColors.green800,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              label: const Text(
                'Buka Fitur FE-2 (Tersimpan & QR)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPlacesScreen()),
                );
              },
            )
          : null,
    );
  }
}
