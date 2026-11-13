import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pill_button.dart';

/// Layar Mitigasi Jalur Rawan & Tombol Darurat SOS GPS (FE-1)
/// Pilar 7: Mitigasi Jalur Rawan & Mode Zero-Signal
class HazardSosScreen extends StatefulWidget {
  const HazardSosScreen({super.key});

  @override
  State<HazardSosScreen> createState() => _HazardSosScreenState();
}

class _HazardSosScreenState extends State<HazardSosScreen> {
  bool _isSendingSos = false;

  static const List<Map<String, dynamic>> _hazardCorridors = [
    {
      'name': 'Koridor Sitinjau Lauik (Padang - Solok)',
      'status': 'WASPADA',
      'statusColor': Color(0xFFE89F3C),
      'desc':
          'Tanjakan curam 45° & potensi longsor saat hujan lebat. Truk bermuatan sering mogok di tikungan 1.',
      'altRoute':
          'Rute Alternatif: Jalur Malalak atau via Danau Singkarak jika terjadi penutupan total.',
      'lastUpdate': '10 menit yang lalu (BPBD Sumbar)',
    },
    {
      'name': 'Koridor Lembah Anai (Padang Panjang)',
      'status': 'NORMAL',
      'statusColor': Color(0xFF1E9E5A),
      'desc':
          'Debit air terjun normal, jalan dua arah lancar terkendali. Alat berat siaga di Pos Km 64.',
      'altRoute': 'Rute Alternatif: Malalak - Bukittinggi.',
      'lastUpdate': '25 menit yang lalu (Satlantas Padang Panjang)',
    },
    {
      'name': 'Koridor Kelok 9 (Payakumbuh - Riau)',
      'status': 'NORMAL',
      'statusColor': Color(0xFF1E9E5A),
      'desc':
          'Jembatan layang & kelokan lancar. Hindari berhenti di bahu jalan layang untuk swafoto.',
      'altRoute': 'Tidak ada pengalihan arus.',
      'lastUpdate': '1 jam yang lalu (Polres 50 Kota)',
    },
  ];

  void _triggerSosDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.coral500, size: 28),
            SizedBox(width: 10),
            Text(
              'Kirim Sinyal Darurat SOS?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Lokasi koordinat GPS Anda (-0.1023, 100.6728) beserta status baterai akan segera dikirimkan ke SAR Sumbar, BPBD & Pokdarwis Nagari terdekat.',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isSendingSos = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (!mounted) return;
                setState(() => _isSendingSos = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.green800,
                    content: Text(
                      'Sinyal SOS & GPS darurat berhasil dipancarkan ke Posko SAR & Satgas Nagari.',
                    ),
                  ),
                );
              });
            },
            child: const Text('Ya, Kirim Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Pantauan Jalur Rawan & SOS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner Tombol Darurat SOS GPS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sos_rounded, color: Colors.white, size: 36),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tombol Bantuan Darurat SOS GPS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan hanya dalam keadaan darurat (bencana alam, kecelakaan, tersesat di jalur tanpa sinyal). Sistem akan memancarkan koordinat terakhir ke Basarnas & Pokdarwis.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 18),
                PillButton(
                  text: _isSendingSos ? 'Memancarkan Sinyal...' : 'PANCARKAN SOS SEKARANG',
                  icon: const Icon(Icons.emergency_share, color: Colors.white, size: 18),
                  backgroundColor: const Color(0xFF8B0000),
                  onPressed: _isSendingSos ? null : _triggerSosDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Status 3 Koridor Utama Rawan Bencana',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),

          ..._hazardCorridors.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c['name'] as String,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (c['statusColor'] as Color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c['status'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: c['statusColor'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c['desc'] as String,
                      style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.sage100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route, size: 16, color: AppColors.green800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c['altRoute'] as String,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.ink900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pembaruan: ${c['lastUpdate']}',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
