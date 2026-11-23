import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';
import 'google_maps_meeting_point_sheet.dart';
import 'open_trip_offline_rules_sheet.dart';
import 'verified_organizer_sheet.dart';

/// Sheet Fitur Trip Planner Lengkap (5 Fitur Utama Trip Planner)
/// 1. Checklist perjalanan untuk memastikan seluruh kebutuhan perjalanan telah dipersiapkan.
/// 2. Pembagian jobdesk oleh penyelenggara kepada anggota/peserta.
/// 3. Checklist persiapan barang bawaan, sehingga peserta mengetahui barang apa saja yang perlu dibawa.
/// 4. Informasi itinerary dan rencana perjalanan yang tersusun dengan jelas.
/// 5. Komunikasi antara penyelenggara dan peserta dalam satu perjalanan.
class TripPlannerDetailSheet extends StatefulWidget {
  final OpenTripItem trip;

  const TripPlannerDetailSheet({
    super.key,
    required this.trip,
  });

  @override
  State<TripPlannerDetailSheet> createState() => _TripPlannerDetailSheetState();
}

class _TripPlannerDetailSheetState extends State<TripPlannerDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Dialog controllers for adding items
  final TextEditingController _newChecklistController = TextEditingController();
  final TextEditingController _newPackingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _newChecklistController.dispose();
    _newPackingController.dispose();
    super.dispose();
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.trip.messages.add(
        TripChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderName: 'Saya (Peserta)',
          senderRole: 'Peserta',
          message: text,
          timestamp: 'Baru saja',
        ),
      );
      _chatController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAddChecklistDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Kebutuhan Perjalanan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forest)),
          content: TextField(
            controller: _newChecklistController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Contoh: Konfirmasi Sewa Alat Snorkeling',
              hintStyle: TextStyle(fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_newChecklistController.text.trim().isNotEmpty) {
                  setState(() {
                    widget.trip.readinessChecklist.add(
                      TripReadinessItem(
                        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                        title: _newChecklistController.text.trim(),
                        description: 'Ditambahkan oleh peserta',
                        isDone: false,
                        category: 'Logistik',
                      ),
                    );
                    _newChecklistController.clear();
                  });
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddPackingDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Barang Bawaan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forest)),
          content: TextField(
            controller: _newPackingController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Contoh: Sandal Jepit Cadangan',
              hintStyle: TextStyle(fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_newPackingController.text.trim().isNotEmpty) {
                  setState(() {
                    widget.trip.packingList.add(
                      TripPackingItem(
                        id: 'pack_${DateTime.now().millisecondsSinceEpoch}',
                        category: 'Pakaian & Perlengkapan',
                        itemName: _newPackingController.text.trim(),
                        notes: 'Barang pribadi tambahan',
                        isPacked: false,
                      ),
                    );
                    _newPackingController.clear();
                  });
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final readinessDone = widget.trip.readinessChecklist.where((i) => i.isDone).length;
    final readinessTotal = widget.trip.readinessChecklist.length;
    final readinessPercent = readinessTotal > 0 ? (readinessDone / readinessTotal) : 0.0;

    final packingDone = widget.trip.packingList.where((p) => p.isPacked).length;
    final packingTotal = widget.trip.packingList.length;

    return Container(
      height: screenHeight * 0.94,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              border: Border(bottom: BorderSide(color: AppColors.warmBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.forest),
                            SizedBox(width: 4),
                            Text('Kembali', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest)),
                          ],
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.alt_route_rounded, size: 16, color: AppColors.forest),
                        SizedBox(width: 6),
                        Text(
                          'SMART TRIP PLANNER',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: AppColors.forest),
                        ),
                      ],
                    ),
                    // Quick Action Menu (SOP & Maps)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFEA4335)),
                          tooltip: 'Titik Kumpul Google Maps',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => GoogleMapsMeetingPointSheet(trip: widget.trip),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.verified_user_rounded, size: 20, color: AppColors.forest),
                          tooltip: 'Verifikasi Penyelenggara',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => VerifiedOrganizerSheet(organizer: widget.trip.organizer),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Trip Title & Single Destination Badge
                Text(
                  widget.trip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Destinasi Tunggal: ${widget.trip.singleDestination}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.trip.category,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E5B82)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // TabBar (5 Fitur Spesifikasi)
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.forest,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.forest,
                  indicatorWeight: 3,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  tabs: [
                    const Tab(text: 'Itinerary'),
                    Tab(text: 'Checklist Trip ($readinessDone/$readinessTotal)'),
                    Tab(text: 'Jobdesk Tim (${widget.trip.jobdeskList.length})'),
                    Tab(text: 'Barang Bawaan ($packingDone/$packingTotal)'),
                    Tab(text: 'Komunikasi (${widget.trip.messages.length})'),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItineraryTab(),
                _buildReadinessChecklistTab(readinessDone, readinessTotal, readinessPercent),
                _buildJobdeskTab(),
                _buildPackingListTab(packingDone, packingTotal),
                _buildCommunicationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ITINERARY RENCANA PERJALANAN (Item 4 Trip Planner)
  // ===========================================================================
  Widget _buildItineraryTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RENCANA PERJALANAN TERSTRUKTUR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.forest),
                ),
                Text(
                  '${widget.trip.departureDate} (${widget.trip.duration})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => OpenTripOfflineRulesSheet(trip: widget.trip),
                );
              },
              icon: const Icon(Icons.rule_folder_rounded, size: 14),
              label: const Text('Ketentuan SOP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forest,
                elevation: 0,
                side: const BorderSide(color: AppColors.sageBorder),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Timeline Items
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.trip.itinerary.length,
          itemBuilder: (ctx, index) {
            final step = widget.trip.itinerary[index];
            final isLast = index == widget.trip.itinerary.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Indicator
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index == 0 ? AppColors.forest : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.forest, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            step.icon,
                            size: 16,
                            color: index == 0 ? Colors.white : AppColors.forest,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.sageBorder,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Card Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sageBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cream,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.warmBorder),
                                ),
                                child: Text(
                                  step.time,
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                                ),
                              ),
                              Text(
                                step.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: step.status == 'Selesai' ? const Color(0xFF10B981) : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.activity,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded, size: 12, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  step.location,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E5B82)),
                                ),
                              ),
                            ],
                          ),
                          if (step.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              step.notes,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF5A6B5D), height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: CHECKLIST PERJALANAN (Item 1 Trip Planner)
  // ===========================================================================
  Widget _buildReadinessChecklistTab(int doneCount, int totalCount, double percent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Progress Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kesiapan Kebutuhan Perjalanan',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                  ),
                  Text(
                    '${(percent * 100).toInt()}% Siap',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.forest),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: AppColors.cream,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forest),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$doneCount dari $totalCount kebutuhan telah dipersiapkan dan terverifikasi.',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Action: Tambah Checklist
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DAFTAR KEBUTUHAN PERJALANAN',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.forest),
            ),
            TextButton.icon(
              onPressed: _showAddChecklistDialog,
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Tambah Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              style: TextButton.styleFrom(foregroundColor: AppColors.forest),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // List Checklist
        ...widget.trip.readinessChecklist.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.isDone ? const Color(0xFF22C55E).withValues(alpha: 0.4) : AppColors.sageBorder,
              ),
            ),
            child: CheckboxListTile(
              value: item.isDone,
              activeColor: AppColors.forest,
              onChanged: (val) {
                setState(() => item.isDone = val ?? false);
              },
              title: Text(
                item.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                  color: item.isDone ? AppColors.muted : AppColors.ink,
                ),
              ),
              subtitle: Text(
                '${item.category} • ${item.description}',
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: PEMBAGIAN JOBDESK TIM (Item 2 Trip Planner)
  // ===========================================================================
  Widget _buildJobdeskTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.assignment_ind_rounded, color: Color(0xFF1D4ED8), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Penyelenggara membagi tanggung jawab agar perjalanan tertib, aman, dan partisipatif.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'PEMBAGIAN PERAN & TUGAS (JOBDESK)',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.forest),
        ),
        const SizedBox(height: 8),

        ...widget.trip.jobdeskList.map((job) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.forest.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(job.icon, size: 18, color: AppColors.forest),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.roleTitle,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forest),
                            ),
                            Text(
                              'PIC: ${job.picName} (${job.picRole})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E5B82)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: job.status == 'Selesai'
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: job.status == 'Selesai'
                              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        job.status,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: job.status == 'Selesai'
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 8),

                const Text(
                  'Rincian Tugas:',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                ...job.tasks.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest)),
                          Expanded(
                            child: Text(
                              t,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: CHECKLIST PERSIAPAN BARANG BAWAAN (Item 3 Trip Planner)
  // ===========================================================================
  Widget _buildPackingListTab(int packedCount, int totalCount) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sageBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.luggage_rounded, color: AppColors.forest, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Perlengkapan Bawaan',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                      Text(
                        '$packedCount dari $totalCount barang siap di tas',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _showAddPackingDialog,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forest,
                  side: const BorderSide(color: AppColors.forest),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'CHECKLIST BARANG BAWAAN PESERTA',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.forest),
        ),
        const SizedBox(height: 8),

        ...widget.trip.packingList.map((pack) {
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pack.isPacked ? const Color(0xFF22C55E).withValues(alpha: 0.4) : AppColors.sageBorder,
              ),
            ),
            child: CheckboxListTile(
              value: pack.isPacked,
              activeColor: AppColors.forest,
              onChanged: (val) {
                setState(() => pack.isPacked = val ?? false);
              },
              title: Text(
                pack.itemName,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  decoration: pack.isPacked ? TextDecoration.lineThrough : null,
                  color: pack.isPacked ? AppColors.muted : AppColors.ink,
                ),
              ),
              subtitle: Text(
                '${pack.category}${pack.notes.isNotEmpty ? ' • ${pack.notes}' : ''}',
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 5: KOMUNIKASI PENYELENGGARA & PESERTA (Item 5 Trip Planner)
  // ===========================================================================
  Widget _buildCommunicationTab() {
    return Column(
      children: [
        // WhatsApp Official Group Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF25D366),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'WhatsApp Group Resmi Rombongan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Membuka grup WhatsApp: ${widget.trip.whatsappGroupLink}'),
                      backgroundColor: const Color(0xFF15803D),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Buka WA',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chat Message List
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            itemCount: widget.trip.messages.length,
            itemBuilder: (ctx, index) {
              final msg = widget.trip.messages[index];

              // Pinned notice style
              if (msg.isPinnedNotice) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.push_pin_rounded, size: 15, color: Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Text(
                                msg.senderName,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                          Text(msg.timestamp, style: const TextStyle(fontSize: 10, color: Color(0xFF92400E))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        msg.message,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              final isMe = msg.senderRole == 'Peserta' && msg.senderName.contains('Saya');
              final isHost = msg.senderRole == 'Host';

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.forest
                        : isHost
                            ? const Color(0xFFE8F1F8)
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                    ),
                    border: isHost ? Border.all(color: const Color(0xFF1E5B82).withValues(alpha: 0.2)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.senderName,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isMe
                                  ? AppColors.cream
                                  : isHost
                                      ? const Color(0xFF1E5B82)
                                      : AppColors.ink,
                            ),
                          ),
                          if (isHost) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E5B82),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HOST',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        msg.message,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isMe ? Colors.white : AppColors.ink,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg.timestamp,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isMe ? AppColors.cream.withValues(alpha: 0.7) : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.warmBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan koordinasi tim...',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.muted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendChatMessage,
                icon: const Icon(Icons.send_rounded, color: AppColors.forest),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
