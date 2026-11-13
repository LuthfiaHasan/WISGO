import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/fe1_visual_map/fe1_main_shell.dart';

void main() {
  runApp(const RancakinApp());
}

class RancakinApp extends StatelessWidget {
  const RancakinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rancak.in - Wisata Pintar Sumbar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Fe1MainShell(),
    );
  }
}
