import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';

/// Modul FE-1: Kamus Saku Audio Minang & Kalender Budaya (Pilar 1)
class AudioCultureScreen extends StatefulWidget {
  const AudioCultureScreen({super.key});

  @override
  State<AudioCultureScreen> createState() => _AudioCultureScreenState();
}

class _AudioCultureScreenState extends State<AudioCultureScreen>
    with SingleTickerProviderStateMixin {
  final DestinationRepository _repository = DestinationRepository();
  late TabController _tabController;

  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String? _currentlyPlayingId;
  bool _isAudioPlaying = false;
  double _playbackProgress = 0.0;

  List<MinangPhraseModel> _phrases = [];
  List<CulturalEventModel> _culturalEvents = [];
  bool _isLoading = true;

  static const List<String> _phraseCategories = [
    'Semua',
    'Kuliner',
    'Pasar & Belanja',
    'Sapaan Nagari',
    'Arah & Navigasi',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCultureData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCultureData() async {
    setState(() => _isLoading = true);
    final phrases = await _repository.getCulturePhrases();
    final events = await _repository.getCulturalEvents();

    if (!mounted) return;
    setState(() {
      _phrases = phrases;
      _culturalEvents = events;
      _isLoading = false;
    });
  }

  void _playPhrase(MinangPhraseModel phrase) {
    setState(() {
      if (_currentlyPlayingId == phrase.id && _isAudioPlaying) {
        _isAudioPlaying = false;
        _currentlyPlayingId = null;
        _playbackProgress = 0.0;
      } else {
        _currentlyPlayingId = phrase.id;
        _isAudioPlaying = true;
        _playbackProgress = 0.2;
      }
    });

    if (_isAudioPlaying) {
      // Simulasi progress audio
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _currentlyPlayingId == phrase.id) {
          setState(() => _playbackProgress = 0.6);
        }
      });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _currentlyPlayingId == phrase.id) {
          setState(() => _playbackProgress = 1.0);
        }
      });
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && _currentlyPlayingId == phrase.id) {
          setState(() {
            _isAudioPlaying = false;
            _currentlyPlayingId = null;
            _playbackProgress = 0.0;
          });
        }
      });

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
                      'Memutar Audio: "${phrase.minangText}"',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Lafal: ${phrase.phoneticGuide} (${phrase.dialectNote})',
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
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Text('Kamus Saku Audio & Budaya Minang'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.green800,
          indicatorWeight: 3,
          labelColor: AppColors.green800,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Kamus Audio Minang'),
            Tab(text: 'Kalender Budaya'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green800))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildKamusAudioTab(),
                _buildKalenderBudayaTab(),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1: KAMUS SAKU AUDIO MINANG
  // ===========================================================================
  Widget _buildKamusAudioTab() {
    final filteredPhrases = _phrases.where((p) {
      final matchCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          p.minangText.toLowerCase().contains(q) ||
          p.indonesianText.toLowerCase().contains(q) ||
          p.usageContextTip.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                      'Pemandu Bahasa Minang Asli',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lafal frasa otentik dengan prinsip Kato Nan Ampek (Adat Basandi Syarak).',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              hintText: 'Cari kata Minang atau arti bahasa Indonesia...',
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
            children: _phraseCategories.map((cat) {
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
            const Expanded(
              child: Text(
                'Daftar Frasa Budaya & Pasar',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${filteredPhrases.length} frasa',
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // DAFTAR KARTU AUDIO
        ...filteredPhrases.map((phrase) {
          final isPlaying = _currentlyPlayingId == phrase.id && _isAudioPlaying;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isPlaying ? AppColors.green800 : Colors.black.withValues(alpha: 0.06),
                width: isPlaying ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPlaying
                      ? AppColors.green800.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: isPlaying ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Kategori & Badges Kato Nan Ampek
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.sage100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phrase.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phrase.politenessLevel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Teks Minang & Tombol Putar Audio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phrase.minangText,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Lafal: [ ${phrase.phoneticGuide} ]',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Putar Interaktif
                    GestureDetector(
                      onTap: () => _playPhrase(phrase),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isPlaying ? AppColors.green800 : AppColors.sage100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isPlaying ? Colors.white : AppColors.green800,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                // Visual Soundwave Bar jika sedang diputar
                if (isPlaying) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _playbackProgress,
                      backgroundColor: AppColors.sage100,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green800),
                      minHeight: 4,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Arti Bahasa Indonesia & Konteks Penggunaan
                Text(
                  'Arti: "${phrase.indonesianText}"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 12, color: AppColors.orange500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phrase.usageContextTip,
                        style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: KALENDER BUDAYA & HARI PAKAN NAGARI
  // ===========================================================================
  Widget _buildKalenderBudayaTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4E8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE89F3C).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: AppColors.orange500, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalender Adat & Hari Pakan',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hari Pakan adalah hari pasar tradisional bergilir nagari tempat warga menjual kuliner otentik.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        ..._culturalEvents.map((evt) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green800.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          evt.badge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green800,
                          ),
                        ),
                      ),
                      Text(
                        evt.cityRegency,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evt.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 13, color: AppColors.coral500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evt.scheduleRule,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.coral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evt.nagariLocation,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evt.description,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
