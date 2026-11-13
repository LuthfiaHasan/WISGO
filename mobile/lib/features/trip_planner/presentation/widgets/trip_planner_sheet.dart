import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Item 10 & 12: Layar 06: Perencana Perjalanan Otomatis
/// Perjalanan otomatis berdasarkan durasi hari, anggaran, minat wisata,
/// serta pengaturan berapa jumlah orang rombongan yang melakukan trip (Item 12).
class TripPlannerSheet extends StatefulWidget {
  final VoidCallback? onOpenGroupRoom;

  const TripPlannerSheet({super.key, this.onOpenGroupRoom});

  @override
  State<TripPlannerSheet> createState() => _TripPlannerSheetState();
}

class _TripPlannerSheetState extends State<TripPlannerSheet> {
  int _selectedDays = 3;
  int _peopleCount = 5; // Item 12: Di aplikasi ada berapa orang untuk trip
  String _selectedBudget = 'sedang';

  String get _peopleDescription {
    if (_peopleCount == 1) return 'Solo Traveler (Backpacker)';
    if (_peopleCount == 2) return 'Pasangan / 2 Orang';
    if (_peopleCount <= 6) return 'Keluarga / Grup Kecil (Mobil Pribadi)';
    return 'Rombongan Besar / Bus Wisata';
  }

  int get _calculatedTotal {
    int basePerPerson = 95000;
    if (_selectedBudget == 'hemat') basePerPerson = 50000;
    if (_selectedBudget == 'sultan') basePerPerson = 180000;
    return basePerPerson * _peopleCount * _selectedDays;
  }

  String _formatRupiah(int val) {
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(bottom: BorderSide(color: AppColors.warmBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.ink),
                        SizedBox(width: 4),
                        Text('Tutup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
                const Flexible(
                  child: Text(
                    'LAYAR 06 • SMART TRIP PLANNER',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.forest),
                  ),
                ),
                if (widget.onOpenGroupRoom != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenGroupRoom!();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.forest.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Ruang Grup', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.forest)),
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Form Parameter Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Durasi Hari
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '1. DURASI PERJALANAN (HARI):',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                          ),
                          Text(
                            '$_selectedDays Hari ${_selectedDays > 1 ? "${_selectedDays - 1} Malam" : ""}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brush),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [1, 2, 3, 5, 7].map((days) {
                          final isSelected = days == _selectedDays;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedDays = days),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.forest : AppColors.cream,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.forest : AppColors.warmBorder,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$days H',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? AppColors.cream : AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 2. JUMLAH PESERTA TRIP (ITEM 12: Di aplikasi ada berapa orang untuk trip)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.warmBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '2. JUMLAH ORANG TRIP:',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _peopleDescription,
                                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_peopleCount > 1) setState(() => _peopleCount--);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.sageBorder),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_peopleCount',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.forest),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    if (_peopleCount < 25) setState(() => _peopleCount++);
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.forest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Estimasi Anggaran per Orang
                      const Text(
                        '3. ESTIMASI ANGGARAN PER ORANG:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedBudget = 'hemat'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedBudget == 'hemat' ? AppColors.sage : AppColors.cream,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedBudget == 'hemat' ? AppColors.forest : AppColors.warmBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text('Hemat\nRp 50rb/org', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedBudget = 'sedang'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedBudget == 'sedang' ? AppColors.sage : AppColors.cream,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedBudget == 'sedang' ? AppColors.forest : AppColors.warmBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text('Standar\nRp 95rb/org', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedBudget = 'sultan'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedBudget == 'sultan' ? AppColors.sage : AppColors.cream,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedBudget == 'sultan' ? AppColors.forest : AppColors.warmBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text('Eksklusif\nRp 180rb/org', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Total Rombongan Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Estimasi Rombongan', style: TextStyle(fontSize: 10, color: AppColors.cream)),
                          Text('$_peopleCount Orang • $_selectedDays Hari', style: const TextStyle(fontSize: 9.5, color: AppColors.sage)),
                        ],
                      ),
                      Text(
                        _formatRupiah(_calculatedTotal),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.cream),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Hasil Jadwal Rute Otomatis
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'JADWAL RUTE SEARAH TEROPTIMASI',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                          ),
                          Text('Hemat Bensin', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.brush)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDayItem(
                        dayTitle: 'Hari 1 • Padang Menuju Bukittinggi',
                        stops: [
                          '08:30 • Air Terjun Lembah Anai (Foto & Rest Area)',
                          '12:30 • Makan Siang Kuliner Minang di Padang Panjang',
                          '15:45 • Jam Gadang & Ngarai Sianok Panorama',
                        ],
                      ),
                      const Divider(color: AppColors.warmBorder, height: 20),
                      _buildDayItem(
                        dayTitle: 'Hari 2 • Harau & Kapalo Banda Taram',
                        stops: [
                          '09:00 • Lembah Harau & Sarasah Bunta (Tiket Perda)',
                          '14:00 • Kapalo Banda Taram (Wisata Rakit Bambu)',
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem({required String dayTitle, required List<String> stops}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayTitle,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        ...stops.map((stop) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 5, color: AppColors.terracotta),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

