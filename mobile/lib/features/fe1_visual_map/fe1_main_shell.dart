import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../saved/presentation/screens/saved_places_screen.dart';
import 'audio_guide_culture/audio_culture_screen.dart';
import 'hazard_alert_sos/hazard_sos_screen.dart';
import 'home/home_screen.dart';
import 'map_explore_shunlu/map_explore_screen.dart';

/// Shell Navigasi Terpadu WISGO (Gabungan FE-1 Visual 360/Peta Shunlu + FE-2 Saved/Barometer)
class Fe1MainShell extends StatefulWidget {
  final int initialIndex;
  const Fe1MainShell({super.key, this.initialIndex = 0});

  @override
  State<Fe1MainShell> createState() => _Fe1MainShellState();
}

class _Fe1MainShellState extends State<Fe1MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const List<Widget> _pages = [
    Fe1HomeScreen(),
    MapExploreShunluScreen(),
    SavedPlacesScreen(initialTabIndex: 1),
    AudioCultureScreen(),
    HazardSosScreen(),
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
        indicatorColor: AppColors.green800.withOpacity(0.14),
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
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: AppColors.green800),
            label: 'Tersimpan',
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
        ],
      ),
    );
  }
}
