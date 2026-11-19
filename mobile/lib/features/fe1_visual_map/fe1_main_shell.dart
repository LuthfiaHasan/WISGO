import 'package:flutter/material.dart';
import '../saved/presentation/screens/saved_places_screen.dart';

/// Shell Navigasi Utama Modul FE-1
/// Terintegrasi langsung dengan SavedPlacesScreen sebagai Beranda utama WISGO
class Fe1MainShell extends StatelessWidget {
  const Fe1MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const SavedPlacesScreen();
  }
}
