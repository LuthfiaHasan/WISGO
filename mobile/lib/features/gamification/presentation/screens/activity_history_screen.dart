import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/gamification_model.dart';
import '../../services/gamification_service.dart';
import '../modals/activity_detail_modal.dart';
import '../widgets/activity_timeline_card.dart';

/// Halaman Riwayat Perjalanan & Aktivitas Lengkap
/// Menampilkan seluruh rekam jejak check-in, mitigasi jalur rawan, penaklukan tantangan,
/// serta perolehan XP & Geode Points secara kronologis dan interaktif.
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String _selectedFilter = 'all'; // 'all' | 'checkin' | 'hazard' | 'badge'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
    }
  }

  List<CheckInActivity> _filterActivities(List<CheckInActivity> list) {
    return list.where((act) {
      // Filter tab
      if (_selectedFilter == 'checkin') {
        if (!act.note.toLowerCase().contains('check-in')) {
          return false;
        }
      } else if (_selectedFilter == 'hazard') {
        if (!act.note.toLowerCase().contains('jalur rawan') &&
            !act.note.toLowerCase().contains('rute')) {
          return false;
        }
      } else if (_selectedFilter == 'badge') {
        if (!act.note.toLowerCase().contains('lencana') &&
            !act.note.toLowerCase().contains('penakluk')) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = act.destinationTitle.toLowerCase().contains(query);
        final matchRegion = act.region.toLowerCase().contains(query);
        final matchNote = act.note.toLowerCase().contains(query);
        if (!matchTitle && !matchRegion && !matchNote) return false;
      }

      return true;
    }).toList();
  }

  void _showActivityDetailModal(BuildContext context, CheckInActivity act) {
    showActivityDetailModal(
      context: context,
      activity: act,
      formattedTimestamp: _formatTimestamp(act.timestamp),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sageBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.forest,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocale.tr('Riwayat Aktivitas & Perjalanan', 'Activity & Journey History'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              AppLocale.tr('Semua rekam jejak check-in & perolehan XP', 'All check-in logs & XP earned'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ink.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: GamificationService.instance,
        builder: (context, _) {
          final service = GamificationService.instance;
          final allActivities = service.activityHistory;
          final filtered = _filterActivities(allActivities);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // 1. Ringkasan Statistik Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.forest, AppColors.brush],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: AppColors.warningBg,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.currentGrade.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Pangkat Petualang Aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${service.currentXp} XP Total',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatColumn('Total Check-in', '${allActivities.length}', Icons.pin_drop_rounded),
                        _buildStatColumn('Check Point Misi', '${service.primaryChallenge.currentCheckpoints}/10', Icons.flag_rounded),
                        _buildStatColumn('Poin Geode', '${service.currentPoints} GP', Icons.stars_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warmBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Cari destinasi, nagari, atau catatan…',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Semua (${allActivities.length})', Icons.dashboard_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('checkin', 'Check-in GPS', Icons.pin_drop_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('hazard', 'Jalur & Rute', Icons.hiking_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('badge', 'Lencana Resmi', Icons.military_tech_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Daftar Linimasa Kronologis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocale.tr('Linimasa Aktivitas Terverifikasi', 'Verified Activity Timeline'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${filtered.length} Aktivitas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.warmBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 26,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada riwayat aktivitas yang cocok',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba ganti filter kategori atau kata kunci pencarian Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final act = filtered[index];
                    return _buildTimelineCard(context, act);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = key;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.warmBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.forest,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, CheckInActivity act) {
    return ActivityTimelineCard(
      activity: act,
      formattedTimestamp: _formatTimestamp(act.timestamp),
      onTap: () => _showActivityDetailModal(context, act),
    );
  }
}
