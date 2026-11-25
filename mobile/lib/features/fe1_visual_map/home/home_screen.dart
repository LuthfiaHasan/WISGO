import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/crowd_badge.dart';
import '../../../core/widgets/pill_button.dart';
import '../data/destination_repository.dart';
import '../destination_detail/destination_detail_screen.dart';
import '../models/destination_model.dart';
import '../virtual_tour_360/virtual_tour_360_screen.dart';

/// Layar 01 · Beranda Destinasi Wisata Sumatera Barat (FE-1)
/// Pilar 1: Eksplorasi Visual 360° & Budaya Minang
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DestinationRepository _repository = DestinationRepository();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;
  List<DestinationModel> _destinations = [];

  static const List<String> _categories = [
    'Semua',
    'Alam & Geopark',
    'Budaya & Nagari',
    'Hidden Gem',
    'Religi',
    'Kuliner',
  ];

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    setState(() => _isLoading = true);
    final data = await _repository.getDestinations(
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );
    if (!mounted) return;
    setState(() {
      _destinations = data;
      _isLoading = false;
    });
  }

  void _openDetail(DestinationModel dest) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailScreen(destination: dest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Rancak.in · Sumatera Barat'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data Destinasi',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.forest),
            onPressed: _loadDestinations,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.forest,
        backgroundColor: Colors.white,
        onRefresh: _loadDestinations,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // 1. BANNER STATUS JALUR RAWAN (PILAR 7)
            _buildHazardAlertBanner(),
            const SizedBox(height: 18),

            // 2. SEARCH BAR DESTINASI & NAGARI
            _buildSearchBar(),
            const SizedBox(height: 16),

            // 3. FILTER CHIP KATEGORI (Alam, Budaya, Kuliner, Sejarah)
            _buildCategoryChips(),
            const SizedBox(height: 20),

            // 4. HEADER DAFTAR DESTINASI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == 'Semua'
                      ? 'Destinasi Unggulan Sumbar'
                      : 'Kategori: $_selectedCategory',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${_destinations.length} Lokasi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. LIST KARTU DESTINASI (DENGAN COVER IMAGE & 4 MINI STAT)
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: AppColors.forest),
                ),
              )
            else if (_destinations.isEmpty)
              _buildEmptyState()
            else
              ..._destinations.map((dest) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildDestinationCard(dest),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldMinang.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.forest, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pantauan Jalur Sumbar: Sitinjau Lauik & Kelok 9 Normal',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cek 5 Indikator Medan & sinyal Blank Spot di detail destinasi sebelum bepergian.',
                  style: TextStyle(color: AppColors.ink, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        _searchQuery = value;
        _loadDestinations();
      },
      decoration: InputDecoration(
        hintText: 'Cari Lembah Harau, Bukittinggi, Lubuk Nyarai...',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
        prefixIcon: const Icon(Icons.search, color: AppColors.forest),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  _loadDestinations();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.forest,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
              onSelected: (_) {
                setState(() => _selectedCategory = cat);
                _loadDestinations();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDestinationCard(DestinationModel dest) {
    final signal = dest.medanIndicator?.cellularSignal ?? '4G Kuat';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(dest),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COVER IMAGE DENGAN FLOATING BADGES
            if (dest.coverImage.isNotEmpty)
              Stack(
                children: [
                  SizedBox(
                    height: 165,
                    width: double.infinity,
                    child: Image.network(
                      dest.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 165,
                        color: AppColors.sage,
                        child: const Center(
                          child: Icon(Icons.landscape, size: 48, color: AppColors.forest),
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 165,
                          color: AppColors.sage,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.forest,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.ink.withValues(alpha: 0.4),
                            Colors.transparent,
                            AppColors.ink.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: dest.category.toLowerCase().contains('budaya')
                                ? AppColors.goldMinang
                                : (dest.category.toLowerCase().contains('gem')
                                    ? AppColors.brush
                                    : (dest.category.toLowerCase().contains('religi')
                                        ? AppColors.success
                                        : (dest.category.toLowerCase().contains('kuliner')
                                            ? AppColors.terracotta
                                            : AppColors.forest))),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.25),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            dest.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        CrowdBadge(level: dest.crowdLevelEnum),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.threesixty, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '360° Ready',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        dest.cityRegency,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dest.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                  const Divider(height: 24),

                  // Ringkasan 4 Statistik
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Jarak', dest.distanceKm),
                      _buildMiniStat('Waktu', dest.travelTime),
                      _buildMiniStat('Sinyal', signal.contains('Blank') ? 'Blank Spot' : signal),
                      _buildMiniStat('Tiket', dest.entryFee),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tombol PillButton 52px
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          text: 'Lihat Detail & Medan',
                          icon: const Icon(
                            Icons.compass_calibration_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _openDetail(dest),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppColors.forest),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => VirtualTour360Screen(destination: dest),
                              ),
                            );
                          },
                          child: const Icon(Icons.view_in_ar_rounded, color: AppColors.forest),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.travel_explore, size: 54, color: AppColors.warmBorder),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada destinasi yang cocok',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba ubah kata kunci pencarian atau ganti filter kategori.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'Semua';
                _searchController.clear();
                _searchQuery = '';
              });
              _loadDestinations();
            },
            child: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }
}

