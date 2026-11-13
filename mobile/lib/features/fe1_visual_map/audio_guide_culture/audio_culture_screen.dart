import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Modul FE-1: Kamus Saku Audio Minang & Kalender Budaya Nagari (Pilar 1)
class AudioCultureScreen extends StatefulWidget {
  const AudioCultureScreen({super.key});

  @override
  State<AudioCultureScreen> createState() => _AudioCultureScreenState();
}

class _AudioCultureScreenState extends State<AudioCultureScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String? _currentlyPlayingId;
  bool _isAudioPlaying = false;

  static const List<String> _categories = [
    'Semua',
    'Kuliner',
    'Pasar & Belanja',
    'Sapaan Nagari',
    'Arah & Navigasi',
  ];

  static const List<Map<String, String>> _phrases = [
    {
      'id': 'phr-1',
      'category': 'Pasar & Belanja',
      'minang': 'Bara haragonyo ko, Uni / Uda?',
      'indo': 'Berapa harganya ini, Kakak?',
      'context': 'Berbelanja di Pasar Atas / Los Lambuang Bukittinggi',
      'phonetic': 'ba-ra ha-ra-go-nyo ko, u-ni / u-da?',
    },
    {
      'id': 'phr-2',
      'category': 'Kuliner',
      'minang': 'Tambuah ciek, Uni!',
      'indo': 'Tambah satu porsi nasi/lauk lagi, Kak!',
      'context': 'Saat bersantap di Rumah Makan Padang / Kapau',
      'phonetic': 'tam-bu-ah cie-k, u-ni!',
    },
    {
      'id': 'phr-3',
      'category': 'Sapaan Nagari',
      'minang': 'Tarimo kasih banyak, sanak.',
      'indo': 'Terima kasih banyak, saudara/sahabat.',
      'context': 'Ucapan terima kasih santun kepada warga nagari',
      'phonetic': 'ta-ri-mo ka-sih ba-nyak, sa-nak',
    },
    {
      'id': 'phr-4',
      'category': 'Arah & Navigasi',
      'minang': 'Kama jalan ka Sarasah Bunta, Uda?',
      'indo': 'Ke mana arah jalan menuju Air Terjun Sarasah Bunta, Kak?',
      'context': 'Menanyakan rute pejalan kaki di Lembah Harau',
      'phonetic': 'ka-ma ja-lan ka sa-ra-sah bun-ta, u-da?',
    },
    {
      'id': 'phr-5',
      'category': 'Kuliner',
      'minang': 'Jan padeh bana yo, Da.',
      'indo': 'Jangan terlalu pedas ya, Kak.',
      'context': 'Memesan makanan dengan tingkat kepedasan sedang',
      'phonetic': 'jan pa-deh ba-na yo, da',
    },
    {
      'id': 'phr-6',
      'category': 'Pasar & Belanja',
      'minang': 'Buliah kurang saketek, Mak?',
      'indo': 'Boleh tawar sedikit harganya, Ibu?',
      'context': 'Tawar-menawar santun di pasar tradisional',
      'phonetic': 'bu-liah ku-rang sa-ke-tek, mak?',
    },
  ];

  static const List<Map<String, dynamic>> _culturalEvents = [
    {
      'id': 'evt-1',
      'title': 'Alek Nagari Pacu Jawi (Balap Sapi Sawah Lumpur)',
      'location': 'Nagari Pariangan & Rambatan, Kab. Tanah Datar',
      'schedule': 'Sabtu Akhir Pekan (Bergilir antar Nagari)',
      'badge': 'Tradisi Leluhur',
      'desc':
          'Atraksi joki memacu dua ekor sapi di sawah berlumpur sehabis panen, simbol rasa syukur hasil tani nagari.',
    },
    {
      'id': 'evt-2',
      'title': 'Festival Budaya Hoyak Tabuik Piaman',
      'location': 'Pantai Gandoriah & Muaro, Kota Pariaman',
      'schedule': '1–10 Muharram (Agenda Tahunan)',
      'badge': 'Event Provinsi',
      'desc':
          'Upacara kultural melarung replika Tabuik setinggi 12 meter ke laut lepas menjelang matahari terbenam.',
    },
    {
      'id': 'evt-3',
      'title': 'Hari Pakan (Pasar Tradisional Nagari Minang)',
      'location': 'Pakan Kamis Tilatang Kamang & Pakan Sinayan',
      'schedule': 'Setiap Senin & Kamis Pagi (06:00 - 12:00)',
      'badge': 'Kuliner & UMKM',
      'desc':
          'Pertemuan pedagang hasil bumi nagari dengan aneka jajanan tradisional otentik, lamang tapai, dan rendang.',
    },
  ];

  void _playPhrase(Map<String, String> phrase) {
    final id = phrase['id']!;
    setState(() {
      if (_currentlyPlayingId == id && _isAudioPlaying) {
        _isAudioPlaying = false;
        _currentlyPlayingId = null;
      } else {
        _currentlyPlayingId = id;
        _isAudioPlaying = true;
      }
    });

    if (_isAudioPlaying) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green800,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.volume_up, color: AppColors.pinAudioEmas),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memutar Audio: "${phrase['minang']}"',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Lafal: ${phrase['phonetic']}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPhrases = _phrases.where((p) {
      final matchCat =
          _selectedCategory == 'Semua' || p['category'] == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          p['minang']!.toLowerCase().contains(q) ||
          p['indo']!.toLowerCase().contains(q) ||
          p['context']!.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Kamus Saku Audio & Budaya'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // BANNER INTRODUKSI
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.indigo500.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.record_voice_over_rounded,
                    color: AppColors.indigo500,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemandu Bahasa & Adat Minang',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Lafal frasa asli dengan logat nagari serta kalender event kebudayaan untuk wisatawan.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // PENCARIAN FRASA
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Cari frasa Minang atau arti bahasa Indonesia...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                prefixIcon: Icon(Icons.search, color: AppColors.green800),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // FILTER KATEGORI CHIP
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.green800,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink900,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // HEADER SECTION KAMUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kamus Audio Frasa Minang',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
              Text(
                '${filteredPhrases.length} frasa',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // DAFTAR KARTU AUDIO
          ...filteredPhrases.map((p) {
            final isPlaying = _currentlyPlayingId == p['id'] && _isAudioPlaying;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPlaying
                      ? AppColors.pinAudioEmas
                      : Colors.black.withValues(alpha: 0.05),
                  width: isPlaying ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPlaying
                        ? AppColors.pinAudioEmas.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isPlaying
                        ? AppColors.pinAudioEmas
                        : AppColors.pinAudioEmas.withValues(alpha: 0.15),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                        color: isPlaying ? Colors.white : AppColors.pinAudioEmas,
                        size: 22,
                      ),
                      onPressed: () => _playPhrase(p),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p['category']!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green800,
                                ),
                              ),
                            ),
                            if (isPlaying) ...[
                              const SizedBox(width: 8),
                              const Text(
                                '• Sedang Memutar',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.pinAudioEmas,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p['minang']!,
                          style: const TextStyle(
                            fontSize: 15,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Konteks: ${p['context']}',
                          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // KALENDER BUDAYA & EVENT NAGARI
          const Text(
            'Kalender Event Budaya & Hari Pakan',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),
          ..._culturalEvents.map((evt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.indigo500.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          evt['badge'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                      Text(
                        evt['schedule'] as String,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.coral500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evt['title'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evt['location'] as String,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evt['desc'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
