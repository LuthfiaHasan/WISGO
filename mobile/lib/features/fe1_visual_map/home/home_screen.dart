import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/crowd_badge.dart';
import '../../../core/widgets/pill_button.dart';
import '../data/destination_repository.dart';
import '../destination_detail/destination_detail_screen.dart';
import '../models/destination_model.dart';
import '../virtual_tour_360/virtual_tour_360_screen.dart';
import '../../qr_scanner/presentation/widgets/qr_scanner_sheet.dart';
import '../../reports/presentation/widgets/lapor_pungli_sheet.dart';

/// Layar 01 · Beranda Utama (Minggu 1 Wajib FE-1)
/// Menampilkan:
/// - Banner Peringatan Jalur Rawan (Pilar 7)
/// - Pencarian Destinasi & Kabupaten/Kota
/// - Filter Kategori (Semua, Alam, Budaya, Kuliner, Sejarah)
/// - Daftar Kartu Destinasi Sumatera Barat (4 Statistik Ringkas + CrowdBadge + Navigasi ke Layar 02 Detail)
class Fe1HomeScreen extends StatefulWidget {
  const Fe1HomeScreen({super.key});

  @override
  State<Fe1HomeScreen> createState() => _Fe1HomeScreenState();
}

class _Fe1HomeScreenState extends State<Fe1HomeScreen> {
  final DestinationRepository _repository = DestinationRepository();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'Semua',
    'Alam',
    'Budaya',
    'Kuliner',
    'Sejarah',
  ];

  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  List<DestinationModel> _destinations = [];
  bool _isLoading = true;

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
    final results = await _repository.getDestinations(
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );
    if (!mounted) return;
    setState(() {
      _destinations = results;
      _isLoading = false;
    });
  }

  void _openDetail(DestinationModel destination) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DestinationDetailScreen(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream100,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rancak.in · Sumatera Barat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink900,
              ),
            ),
            Text(
              'Eksplorasi 360°, Kesiapan Medan & Navigasi Nagari',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Scan Plang QR Gerbang',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.green800),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const QrScannerSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'Lapor Pungli / Fasilitas',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.report_problem_outlined, color: AppColors.coral500),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const LaporPungliSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'Mode Offline Pocket',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(
              Icons.offline_pin_outlined,
              color: AppColors.green800,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.green800,
                  content: Text(
                    'Mode Zero-Signal siap menyimpan data destinasi untuk jalur Blank Spot.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.green800,
        onRefresh: _loadDestinations,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            // 1. BANNER PERINGATAN DINI JALUR RAWAN (Pilar 7)
            _buildHazardBanner(),
            const SizedBox(height: 16),

            // 2. SEARCH BAR DESTINASI / KABUPATEN
            _buildSearchBar(),
            const SizedBox(height: 16),

            // 3. FILTER CHIP KATEGORI
            _buildCategoryFilter(),
            const SizedBox(height: 20),

            // 4. HEADER DAFTAR DESTINASI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Destinasi Pilihan (${_destinations.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const Text(
                  'Ketuk kartu untuk Detail',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. LIST KARTU DESTINASI
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.green800),
                ),
              )
            else if (_destinations.isEmpty)
              _buildEmptyState()
            else
              ..._destinations.map(
                (dest) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildDestinationCard(dest),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazardBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sage100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green800.withOpacity(0.15)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.green800, size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pantauan Jalur Sumbar: Sitinjau Lauik & Kelok 9 Normal',
                  style: TextStyle(
                    color: AppColors.ink900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cek 5 Indikator Medan & sinyal Blank Spot di setiap detail destinasi sebelum berangkat.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11.5,
                  ),
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
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
        prefixIcon: const Icon(Icons.search, color: AppColors.green800),
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
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: AppColors.green800, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44, // Touch target minimum 44px sesuai desain.md
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          final bool isCulture = cat == 'Budaya';

          final Color activeColor =
              isCulture ? AppColors.indigo500 : AppColors.green800;

          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: activeColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.ink900,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: isSelected
                    ? activeColor
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            onSelected: (_) {
              setState(() => _selectedCategory = cat);
              _loadDestinations();
            },
          );
        },
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
        side: BorderSide(color: Colors.black.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(dest),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COVER IMAGE DESTINASI DENGAN FLOATING BADGES
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
                        color: AppColors.sage100,
                        child: const Center(
                          child: Icon(
                            Icons.landscape,
                            size: 48,
                            color: AppColors.green800,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 165,
                          color: AppColors.sage100,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.green800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay untuk kontras teks & badge
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badges di atas gambar
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: dest.category == 'Budaya'
                                ? AppColors.indigo500
                                : AppColors.green800,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
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
                  // Tag 360° di sudut kanan bawah foto
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
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
                              fontSize: 10.5,
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
                  // Fallback baris kategori jika tidak ada coverImage
                  if (dest.coverImage.isEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: dest.category == 'Budaya'
                                ? AppColors.indigo500.withOpacity(0.12)
                                : AppColors.sage100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            dest.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: dest.category == 'Budaya'
                                  ? AppColors.indigo500
                                  : AppColors.green800,
                            ),
                          ),
                        ),
                        CrowdBadge(level: dest.crowdLevelEnum),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Nama Destinasi & Kabupaten/Kota
                  Text(
                    dest.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dest.cityRegency,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                      color: Colors.black87,
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
                      _buildMiniStat(
                        'Sinyal',
                        signal.contains('Blank') ? 'Blank Spot' : signal,
                      ),
                      _buildMiniStat('Tiket', dest.entryFee),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tombol PillButton 52px
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: 'Lihat Detail & Medan',
                          icon: Icons.compass_calibration_outlined,
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
                            side: const BorderSide(color: AppColors.green800),
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    VirtualTour360Screen(destination: dest),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.view_in_ar_rounded,
                            color: AppColors.green800,
                          ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.ink900,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Colors.black38),
          const SizedBox(height: 12),
          const Text(
            'Destinasi tidak ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba ubah filter kategori atau kata kunci pencarian.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          PillButton(
            label: 'Tampilkan Semua Destinasi',
            isFullWidth: false,
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedCategory = 'Semua';
                _searchQuery = '';
              });
              _loadDestinations();
            },
          ),
        ],
      ),
    );
  }
}
