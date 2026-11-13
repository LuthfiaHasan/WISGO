import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Modul FE-1: Kamus Saku Audio Minang & Kalender Budaya (Pilar 1)
class AudioCultureScreen extends StatelessWidget {
  const AudioCultureScreen({super.key});

  static const List<Map<String, String>> _phrases = [
    {
      'minang': 'Bara haragonyo ko, Uni / Uda?',
      'indo': 'Berapa harganya ini, Kakak?',
      'context': 'Berbelanja di Pasar Atas / Los Lambuang',
    },
    {
      'minang': 'Tambuah ciek, Uni!',
      'indo': 'Tambah satu porsi lagi, Kak!',
      'context': 'Kuliner Rumah Makan Padang / Kapau',
    },
    {
      'minang': 'Tarimo kasih banyak, sanak.',
      'indo': 'Terima kasih banyak, saudara.',
      'context': 'Sapaan sopan kepada warga Nagari',
    },
    {
      'minang': 'kama jalan ka Sarasah Bunta?',
      'indo': 'Ke mana arah jalan menuju Sarasah Bunta?',
      'context': 'Menanyakan arah di kawasan wisata',
    },
  ];

  static const List<Map<String, String>> _events = [
    {
      'title': 'Pacu Jawi (Balap Sapi Sawah Berlumpur)',
      'location': 'Kec. Pariangan & Rambatan, Kab. Tanah Datar',
      'schedule': 'Sabtu Akhir Pekan (Bergilir antar Nagari)',
    },
    {
      'title': 'Festival Hoyak Tabuik Piaman',
      'location': 'Pantai Gandoriah, Kota Pariaman',
      'schedule': '1–10 Muharram (Tahunan)',
    },
    {
      'title': 'Hari Pakan (Pasar Tradisional Nagari)',
      'location': 'Pakan Kamis Tilatang Kamang & Pakan Sinayan',
      'schedule': 'Setiap Senin & Kamis Pagi',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Kamus Audio Minang & Budaya'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Kamus Saku Audio Frasa Minang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          ..._phrases.map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.pinAudioEmas.withOpacity(0.15),
                    child: IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.pinAudioEmas,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.green800,
                            content: Text('Memutar lafal: "${p['minang']}"'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['minang']!,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p['indo']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.green800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          p['context']!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Kalender Budaya & Hari Pakan Nagari',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          ..._events.map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.indigo500.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e['schedule']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indigo500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e['title']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e['location']!,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

