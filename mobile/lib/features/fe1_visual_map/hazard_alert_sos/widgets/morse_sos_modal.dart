import 'dart:async';
import 'package:flutter/material.dart';

/// Modal Darurat 100% Offline: Senter Visual Pola Morse SOS (· · · — — — · · ·)
/// - Berfungsi penuh tanpa jaringan internet / sinyal seluler
/// - Layar kontras tinggi dengan kedipan Morse standar internasional untuk memudahkan SAR/evakuasi
class MorseSosModal extends StatefulWidget {
  const MorseSosModal({super.key});

  @override
  State<MorseSosModal> createState() => _MorseSosModalState();
}

class _MorseSosModalState extends State<MorseSosModal> {
  bool _isLightOn = false;
  String _currentMorseStep = 'S (· · ·)';
  Timer? _morseTimer;
  int _stepIndex = 0;

  // Pola Morse SOS: 3 dot, 3 dash, 3 dot (on/off dalam satuan waktu ms)
  // dot = 180ms on, 140ms off
  // dash = 540ms on, 140ms off
  // letter gap = 380ms off
  // word/cycle gap = 1200ms off
  final List<_MorseTiming> _timings = [
    // S: dot dot dot
    _MorseTiming(true, 200, 'S (· · ·)'),
    _MorseTiming(false, 140, 'S (· · ·)'),
    _MorseTiming(true, 200, 'S (· · ·)'),
    _MorseTiming(false, 140, 'S (· · ·)'),
    _MorseTiming(true, 200, 'S (· · ·)'),
    _MorseTiming(false, 380, 'Jeda Huruf'),

    // O: dash dash dash
    _MorseTiming(true, 560, 'O (— — —)'),
    _MorseTiming(false, 140, 'O (— — —)'),
    _MorseTiming(true, 560, 'O (— — —)'),
    _MorseTiming(false, 140, 'O (— — —)'),
    _MorseTiming(true, 560, 'O (— — —)'),
    _MorseTiming(false, 380, 'Jeda Huruf'),

    // S: dot dot dot
    _MorseTiming(true, 200, 'S (· · ·)'),
    _MorseTiming(false, 140, 'S (· · ·)'),
    _MorseTiming(true, 200, 'S (· · ·)'),
    _MorseTiming(false, 140, 'S (· · ·)'),
    _MorseTiming(true, 200, 'S (· · ·)'),
    _MorseTiming(false, 1200, 'Siklus Selesai (Jeda)'),
  ];

  @override
  void initState() {
    super.initState();
    _runMorseLoop();
  }

  void _runMorseLoop() {
    if (!mounted) return;
    final current = _timings[_stepIndex];
    setState(() {
      _isLightOn = current.isOn;
      _currentMorseStep = current.label;
    });

    _morseTimer = Timer(Duration(milliseconds: current.durationMs), () {
      if (!mounted) return;
      _stepIndex = (_stepIndex + 1) % _timings.length;
      _runMorseLoop();
    });
  }

  @override
  void dispose() {
    _morseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isLightOn ? Colors.white : const Color(0xFF0D0D0D);
    final textColor = _isLightOn ? Colors.black : Colors.white;
    final accentColor = _isLightOn ? const Color(0xFFD32F2F) : Colors.redAccent;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 16, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'SENTER MORSE SOS (100% OFFLINE)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textColor, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Visual Indikator Morse Utama
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLightOn ? Colors.yellow.shade400 : Colors.grey.shade900,
                      boxShadow: _isLightOn
                          ? [
                              BoxShadow(
                                color: Colors.yellow.withValues(alpha: 0.6),
                                blurRadius: 40,
                                spreadRadius: 16,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.flare_rounded,
                        size: 72,
                        color: _isLightOn ? Colors.red.shade900 : Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'S  O  S',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '· · ·    — — —    · · ·',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isLightOn ? Colors.grey.shade200 : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pola Aktif: $_currentMorseStep',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arahkan layar ponsel ke atas lereng atau langit terbuka.\nSinyal kedipan Morse membantu regu penolong melihat posisi Anda di kegelapan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // Tombol Tutup / Nonaktifkan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.power_settings_new_rounded),
                  label: const Text(
                    'MATIKAN SENTER DARURAT',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MorseTiming {
  final bool isOn;
  final int durationMs;
  final String label;

  _MorseTiming(this.isOn, this.durationMs, this.label);
}
