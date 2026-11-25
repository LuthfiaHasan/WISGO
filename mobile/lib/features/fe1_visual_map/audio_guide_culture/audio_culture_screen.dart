import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../data/destination_repository.dart';
import '../models/destination_model.dart';
import 'data/festival_budaya_data.dart';
import '../map_explore_shunlu/map_explore_screen.dart';

part 'modals/audio_culture_gps_kalender_modals.dart';
part 'modals/audio_culture_festival_detail_modal.dart';
part 'tabs/audio_culture_kalender_tab.dart';

/// Modul FE-1: Kamus Saku Audio Minang & Kalender Budaya (Pilar 1)
class AudioCultureScreen extends StatefulWidget {
  final bool embedded;
  final Set<String>? remindedFestivalIds;
  final void Function(Map<String, dynamic> festival)? onToggleReminder;
  final void Function(Map<String, dynamic> festival)? onNavigateToGps;
  final List<Map<String, dynamic>>? festivals;

  const AudioCultureScreen({
    super.key,
    this.embedded = false,
    this.remindedFestivalIds,
    this.onToggleReminder,
    this.onNavigateToGps,
    this.festivals,
  });

  @override
  State<AudioCultureScreen> createState() => _AudioCultureScreenState();
}
class _AudioCultureScreenState extends State<AudioCultureScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _internalRemindedFestivalIds = {'ev_harau'};
  Set<String> get _remindedIds => widget.remindedFestivalIds ?? _internalRemindedFestivalIds;
  List<Map<String, dynamic>> get _festivalList => widget.festivals ?? kDefaultMinangFestivals;

  void _handleToggleReminder(Map<String, dynamic> ev, [StateSetter? setModalState]) {
    final id = ev['id'] as String;
    final currentlyActive = _remindedIds.contains(id);

    if (widget.onToggleReminder != null) {
      widget.onToggleReminder!(ev);
    } else {
      setState(() {
        if (currentlyActive) {
          _internalRemindedFestivalIds.remove(id);
        } else {
          _internalRemindedFestivalIds.add(id);
        }
      });
      final activeNow = _internalRemindedFestivalIds.contains(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activeNow
                ? 'Pengingat aktif! Notifikasi pengingat untuk ${ev["title"]} telah dijadwalkan.'
                : 'Pengingat untuk ${ev["title"]} telah dinonaktifkan.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          backgroundColor: activeNow ? AppColors.forest : AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (setModalState != null) {
      setModalState(() {});
    }
    setState(() {});
  }

  final DestinationRepository _repository = DestinationRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  late TabController _tabController;

  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;
  Duration _currentDuration = Duration.zero;

  static const Set<String> _bundledAudioIds = {
    'phr-1',
    'phr-2',
    'phr-3',
    'phr-4',
    'phr-5',
    'phr-6',
    'phr-7',
    'phr-8',
  };

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
    _initAudioPlayer();
    _initTts();
    _loadCultureData();
  }

  void _initAudioPlayer() {
    try {
      _durationSub = _audioPlayer.onDurationChanged.listen((d) {
        if (!mounted) return;
        _currentDuration = d;
      });
      _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
        if (!mounted || !_isAudioPlaying) return;
        final totalMs = _currentDuration.inMilliseconds;
        if (totalMs > 0) {
          setState(() {
            _playbackProgress = (pos.inMilliseconds / totalMs).clamp(0.05, 1.0);
          });
        }
      });
      _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _isAudioPlaying = false;
          _currentlyPlayingId = null;
          _playbackProgress = 0.0;
        });
      });
    } on MissingPluginException {
      // Aman saat widget test
    } catch (_) {}
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
    } on MissingPluginException {
      // Aman saat dijalankan di environment widget test tanpa channel native
    } catch (_) {}
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    try {
      _audioPlayer.dispose();
    } catch (_) {}
    try {
      _flutterTts.stop();
    } catch (_) {}
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

  String _prepareSpeechText(MinangPhraseModel phrase) {
    return phrase.minangText
        .replaceAll('/', ' atau ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _playPhrase(MinangPhraseModel phrase) async {
    final isStoppingSame = _currentlyPlayingId == phrase.id && _isAudioPlaying;

    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}

    if (isStoppingSame) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
        _currentlyPlayingId = null;
        _playbackProgress = 0.0;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _currentlyPlayingId = phrase.id;
      _isAudioPlaying = true;
      _playbackProgress = 0.12;
      _currentDuration = Duration.zero;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.pinAudioEmas),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memutar Suara: "${phrase.minangText}"',
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

    // 1. Utamakan memutar file audio MP3 asli via rootBundle + BytesSource
    // (100% kompatibel lintas platform: Web Chrome/Edge, Windows, Android & iOS)
    if (_bundledAudioIds.contains(phrase.id)) {
      try {
        final byteData = await rootBundle.load('assets/audio/${phrase.id}.mp3');
        final bytes = byteData.buffer.asUint8List();
        await _audioPlayer.setVolume(1.0);
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.play(
          BytesSource(bytes, mimeType: 'audio/mpeg'),
        );
        return;
      } on MissingPluginException catch (e) {
        debugPrint('[KamusAudio] Plugin audioplayers belum terdaftar (perlu restart penuh flutter run): $e');
      } catch (e) {
        debugPrint('[KamusAudio] Gagal memutar MP3 lokal ${phrase.id}: $e');
      }
    }

    // 2. Fallback: TTS sistem perangkat untuk frasa dinamis tambahan
    final speechText = _prepareSpeechText(phrase);
    var spokeNatively = false;
    try {
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.speak(speechText);
      spokeNatively = true;
    } on MissingPluginException {
      spokeNatively = false;
    } catch (_) {
      spokeNatively = false;
    }

    if (!spokeNatively) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && _currentlyPlayingId == phrase.id) {
          setState(() {
            _isAudioPlaying = false;
            _currentlyPlayingId = null;
            _playbackProgress = 0.0;
          });
        }
      });
    } else if (mounted && _currentlyPlayingId == phrase.id) {
      setState(() {
        _isAudioPlaying = false;
        _currentlyPlayingId = null;
        _playbackProgress = 0.0;
      });
    }
  }

  String _categoryLabel(String cat) {
    if (!AppLocale.isEn) return cat;
    switch (cat) {
      case 'Semua':
        return 'All';
      case 'Kuliner':
        return 'Culinary';
      case 'Pasar & Belanja':
        return 'Market & Shopping';
      case 'Sapaan Nagari':
        return 'Greetings';
      case 'Arah & Navigasi':
        return 'Directions';
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.notifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            automaticallyImplyLeading: !widget.embedded,
            title: Text(
              widget.embedded
                  ? AppLocale.tr(
                      'Kamus Minang & Budaya',
                      'Minang Dictionary & Culture',
                    )
                  : AppLocale.tr(
                      'Kamus Saku Audio & Budaya Minang',
                      'Minang Pocket Audio & Culture',
                    ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: LanguageTogglePill(compact: true)),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.forest,
              indicatorWeight: 3,
              labelColor: AppColors.forest,
              unselectedLabelColor: AppColors.muted,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  text: AppLocale.tr(
                    'Kamus Audio Minang',
                    'Minang Audio Dictionary',
                  ),
                ),
                Tab(
                  text: AppLocale.tr('Kalender Budaya', 'Culture Calendar'),
                ),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.forest),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildKamusAudioTab(),
                    _buildKalenderBudayaTab(),
                  ],
                ),
        );
      },
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
          p.englishText.toLowerCase().contains(q) ||
          p.usageContextTip.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, widget.embedded ? 124 : 32),
      children: [
        // BANNER INTRODUKSI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.goldMinang.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: AppColors.goldMinang,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.tr(
                        'Pemandu Bahasa Minang Asli',
                        'Authentic Minang Phrase Guide',
                      ),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocale.tr(
                        'Lafal frasa otentik dengan prinsip Kato Nan Ampek (Adat Basandi Syarak).',
                        'Authentic local phrases with audio, ID & EN meanings for speaking with locals.',
                      ),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: AppLocale.tr(
                'Cari kata Minang, Indonesia, atau English...',
                'Search Minang, Indonesian, or English phrases...',
              ),
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
              prefixIcon: const Icon(Icons.search, color: AppColors.forest),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  label: Text(_categoryLabel(cat)),
                  selected: isSelected,
                  selectedColor: AppColors.forest,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
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
            Expanded(
              child: Text(
                AppLocale.tr(
                  'Daftar Frasa Budaya & Pasar',
                  'Cultural & Market Phrases',
                ),
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocale.tr(
                '${filteredPhrases.length} frasa',
                '${filteredPhrases.length} phrases',
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
                color: isPlaying ? AppColors.forest : AppColors.ink.withValues(alpha: 0.06),
                width: isPlaying ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPlaying
                      ? AppColors.forest.withValues(alpha: 0.08)
                      : AppColors.ink.withValues(alpha: 0.02),
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
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phrase.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldMinang.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        phrase.politenessLevel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldMinang,
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
                              color: AppColors.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${AppLocale.tr('Lafal:', 'Pronunciation:')} [ ${phrase.phoneticGuide} ]',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Putar Interaktif
                    Material(
                      color: isPlaying ? AppColors.forest : AppColors.sage,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => _playPhrase(phrase),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: isPlaying ? Colors.white : AppColors.forest,
                            size: 24,
                          ),
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
                      backgroundColor: AppColors.sage,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forest),
                      minHeight: 4,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Arti Bahasa Indonesia & Bahasa Inggris (Bilingual ID & EN)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'ID',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '"${phrase.indonesianText}"',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (phrase.englishText.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'EN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '"${phrase.englishText}"',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phrase.usageContextTip,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
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
}
