import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';
import 'destination_weather_sheet.dart';
import 'google_maps_meeting_point_sheet.dart';
import 'open_trip_offline_rules_sheet.dart';
import 'trip_group_chat_sheet.dart';
import 'verified_organizer_sheet.dart';

/// Sheet Fitur Trip Planner Lengkap (4 Fitur Perencanaan Inti)
/// 1. Informasi itinerary dan rencana perjalanan yang tersusun dengan jelas.
/// 2. Checklist perjalanan untuk memastikan seluruh kebutuhan perjalanan telah dipersiapkan.
/// 3. Pembagian jobdesk oleh penyelenggara kepada anggota/peserta.
/// 4. Checklist persiapan barang bawaan peserta.
/// (Komunikasi grup dipisahkan ke ruang khusus TripGroupChatSheet â€” 100% In-App tanpa WhatsApp)
class TripPlannerDetailSheet extends StatefulWidget {
  final OpenTripItem trip;
  final bool isOrganizerMode;
  final bool isJoinedParticipant;
  final VoidCallback? onReadinessFinalized;

  const TripPlannerDetailSheet({
    super.key,
    required this.trip,
    this.isOrganizerMode = false,
    this.isJoinedParticipant = true,
    this.onReadinessFinalized,
  });

  @override
  State<TripPlannerDetailSheet> createState() => _TripPlannerDetailSheetState();
}

class _TripPlannerDetailSheetState extends State<TripPlannerDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Dialog controllers for adding items
  final TextEditingController _newChecklistController = TextEditingController();
  final TextEditingController _newPackingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _currentTabIndex != _tabController.index &&
          mounted) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newChecklistController.dispose();
    _newPackingController.dispose();
    super.dispose();
  }

  Future<void> _showReadinessConfirmDialog(
    int readinessDone,
    int readinessTotal,
    int packingDone,
    int packingTotal,
  ) async {
    bool isChecked = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.fact_check_rounded, color: AppColors.forest, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konfirmasi Kesiapan Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '• Jadwal perjalanan sudah dipahami',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Persiapan & barang bawaan sudah lengkap',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setDialogState(() => isChecked = !isChecked),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isChecked ? AppColors.sage : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isChecked ? AppColors.forest : AppColors.sageBorder,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isChecked,
                              activeColor: AppColors.forest,
                              onChanged: (v) =>
                                  setDialogState(() => isChecked = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Saya menyetujui & menyatakan bahwa seluruh persiapan serta barang bawaan wajib sudah saya lengkapi untuk keberangkatan trip ini.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  onPressed: isChecked ? () => Navigator.pop(dialogCtx, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: AppColors.cream,
                    disabledBackgroundColor: AppColors.disabledBg,
                    disabledForegroundColor: AppColors.disabledText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Setuju & Simpan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        widget.trip.isScheduleReviewed = true;
        widget.trip.isReadinessFinalized = true;
      });
      widget.onReadinessFinalized?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.forest,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Finalisasi berhasil! Jadwal, persiapan & barang bawaan Anda telah tervalidasi.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
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

  void _showAddOrEditItineraryRundownDialog({int? editIndex, TripItineraryStep? editingStep}) {
    final isEditing = editIndex != null && editingStep != null;

    final activityCtrl = TextEditingController(text: editingStep?.activity ?? '');
    final locationCtrl = TextEditingController(
      text: editingStep != null ? editingStep.location : widget.trip.singleDestination,
    );
    final notesCtrl = TextEditingController(text: editingStep?.notes ?? '');

    // Waktu yang disediakan sistem (slot jam)
    String selectedTimeRange = editingStep?.time ?? '08.00 - 09.30 WIB';
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 30);

    // Preset jam rundown yang disediakan sistem
    final systemPresetHours = [
      '06.00 - 07.00 WIB',
      '06.30 - 07.30 WIB',
      '07.00 - 08.30 WIB',
      '07.30 - 09.30 WIB',
      '08.00 - 09.30 WIB',
      '08.30 - 10.30 WIB',
      '09.30 - 11.30 WIB',
      '11.30 - 13.00 WIB',
      '13.00 - 14.30 WIB',
      '13.00 - 16.30 WIB',
      '14.30 - 16.00 WIB',
      '16.00 - 17.30 WIB',
      '17.30 - 19.00 WIB',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule_rounded, color: AppColors.forest, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing ? 'Ubah Item Rundown' : 'Tambah Rundown Baru',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.forest),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.infoBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 15),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sistem menyediakan pilihan jam. Silakan pilih jam lalu isi kegiatan manual di bawah.',
                              style: TextStyle(fontSize: 11, color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. JAM / WAKTU
                    const Text(
                      'PILIHAN JAM / WAKTU',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.sageBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: systemPresetHours.contains(selectedTimeRange)
                              ? selectedTimeRange
                              : null,
                          hint: Text(selectedTimeRange, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest)),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.forest),
                          items: systemPresetHours.map((h) {
                            return DropdownMenuItem<String>(
                              value: h,
                              child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedTimeRange = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Opsi Custom Jam Manual
                    Row(
                      children: [
                        const Text('Atau pilih jam custom: ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        TextButton(
                          onPressed: () async {
                            final pickStart = await showTimePicker(context: dialogCtx, initialTime: startTime);
                            if (pickStart != null && dialogCtx.mounted) {
                              final pickEnd = await showTimePicker(context: dialogCtx, initialTime: endTime);
                              if (pickEnd != null) {
                                final sStr = '${pickStart.hour.toString().padLeft(2, '0')}.${pickStart.minute.toString().padLeft(2, '0')}';
                                final eStr = '${pickEnd.hour.toString().padLeft(2, '0')}.${pickEnd.minute.toString().padLeft(2, '0')}';
                                setDialogState(() {
                                  selectedTimeRange = '$sStr - $eStr WIB';
                                });
                              }
                            }
                          },
                          child: const Text('Pilih Jam Mulai & Selesai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 2. NAMA KEGIATAN
                    const Text(
                      'NAMA KEGIATAN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: activityCtrl,
                      decoration: InputDecoration(
                        hintText: 'Kumpul & Briefing / Trekking Air Terjun',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. LOKASI KEGIATAN
                    const Text(
                      'LOKASI',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: locationCtrl,
                      decoration: InputDecoration(
                        hintText: 'Titik Kumpul Rest Area / Tebing Echo',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. CATATAN
                    const Text(
                      'CATATAN KHUSUS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Wajib memakai alas kaki antiselip & jaket',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final activityText = activityCtrl.text.trim();
                    if (activityText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama kegiatan wajib diisi')),
                      );
                      return;
                    }

                    final newStep = TripItineraryStep(
                      time: selectedTimeRange,
                      activity: activityText,
                      location: locationCtrl.text.trim().isEmpty ? widget.trip.singleDestination : locationCtrl.text.trim(),
                      notes: notesCtrl.text.trim().isEmpty ? 'Mengikuti instruksi penyelenggara' : notesCtrl.text.trim(),
                      status: editingStep?.status ?? 'Akan Datang',
                      icon: activityText.toLowerCase().contains('kumpul') || activityText.toLowerCase().contains('meeting')
                          ? Icons.flag_rounded
                          : (activityText.toLowerCase().contains('makan') || activityText.toLowerCase().contains('sholat')
                              ? Icons.restaurant_rounded
                              : (activityText.toLowerCase().contains('foto') || activityText.toLowerCase().contains('dokumentasi')
                                  ? Icons.camera_alt_rounded
                                  : Icons.landscape_rounded)),
                    );

                    setState(() {
                      if (isEditing) {
                        widget.trip.itinerary[editIndex] = newStep;
                      } else {
                        widget.trip.itinerary.add(newStep);
                      }
                    });

                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Rundown'),
                ),
              ],
            );
          },
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
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.sageBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.forest),
                            SizedBox(width: 3),
                            Text('Kembali', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alt_route_rounded, size: 14, color: AppColors.forest),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'RENCANA & PERSIAPAN',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: AppColors.forest),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick Action Menu (Cuaca, Kondisi Lapangan, Maps & SOP)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.wb_cloudy_rounded, size: 18, color: AppColors.info),
                          tooltip: 'Informasi Cuaca Destinasi',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => DestinationWeatherSheet(destinationName: widget.trip.singleDestination),
                            );
                          },
                        ),
                        const SizedBox(width: 3),
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.danger),
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
                        const SizedBox(width: 3),
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.verified_user_rounded, size: 18, color: AppColors.forest),
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
                        const SizedBox(width: 3),
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.forum_rounded, size: 18, color: AppColors.forest),
                          tooltip: 'Buka Chat Trip',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => TripGroupChatSheet(trip: widget.trip),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Trip Title & Destination Badge
                Text(
                  widget.trip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.trip.singleDestination,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.trip.category,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.isOrganizerMode
                            ? AppColors.forest
                            : (widget.isJoinedParticipant
                                ? AppColors.successBg
                                : AppColors.warningBg),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.isOrganizerMode
                              ? AppColors.forest
                              : (widget.isJoinedParticipant
                                  ? AppColors.successBorder
                                  : AppColors.warning),
                        ),
                      ),
                      child: Text(
                        widget.isOrganizerMode
                            ? 'Penyelenggara'
                            : (widget.isJoinedParticipant
                                ? 'Peserta Terdaftar'
                                : 'Belum Terdaftar'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.isOrganizerMode
                              ? AppColors.cream
                              : (widget.isJoinedParticipant
                                  ? AppColors.success
                                  : AppColors.warningDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // TabBar Bersih Tanpa Angka Pecahan
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.forest,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.forest,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(
                      text: widget.isJoinedParticipant && widget.trip.isScheduleReviewed
                          ? 'Jadwal ✓'
                          : 'Jadwal',
                    ),
                    Tab(
                      text: widget.isJoinedParticipant &&
                              readinessTotal > 0 &&
                              readinessDone >= readinessTotal
                          ? 'Persiapan ✓'
                          : 'Persiapan',
                    ),
                    Tab(
                      text: widget.isJoinedParticipant &&
                              packingTotal > 0 &&
                              packingDone >= packingTotal
                          ? 'Barang Bawaan ✓'
                          : 'Barang Bawaan',
                    ),
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
                _buildPackingListTab(packingDone, packingTotal),
              ],
            ),
          ),

          // Bar Aksi Bawah Sesuai Role (Penyelenggara vs Peserta Terdaftar vs Pratinjau)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              border: Border(top: BorderSide(color: AppColors.warmBorder)),
            ),
            child: SafeArea(
              top: false,
              child: widget.isOrganizerMode
                  ? Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Pengaturan Penyelenggara',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                              Text(
                                'Jadwal, persiapan & barang bawaan otomatis tampil ke peserta.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.forest,
                                content: Text(
                                  'Rencana & Persiapan berhasil disimpan dan diterbitkan ke seluruh peserta!',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            foregroundColor: AppColors.cream,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Simpan & Terbitkan',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    )
                  : (!widget.isJoinedParticipant
                      ? const Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: AppColors.warningDark,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Daftar trip terlebih dahulu untuk mengisi checklist persiapan.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildParticipantSequentialFooter(
                          readinessDone: readinessDone,
                          readinessTotal: readinessTotal,
                          packingDone: packingDone,
                          packingTotal: packingTotal,
                        )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSequentialFooter({
    required int readinessDone,
    required int readinessTotal,
    required int packingDone,
    required int packingTotal,
  }) {
    final trip = widget.trip;
    final allReadinessDone = readinessTotal == 0 || readinessDone >= readinessTotal;
    final allPackingDone = packingTotal == 0 || packingDone >= packingTotal;

    if (trip.isReadinessFinalized) {
      return Row(
        children: [
          const Icon(Icons.verified_rounded, size: 20, color: AppColors.success),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Finalisasi Kesiapan Tervalidasi ✓',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Jadwal, persiapan & barang bawaan siap berangkat.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              setState(() => trip.isReadinessFinalized = false);
              widget.onReadinessFinalized?.call();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.forest,
              side: const BorderSide(color: AppColors.sageBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Ubah',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }

    // Step 1: Jadwal -> "Lanjut Persiapan"
    if (_currentTabIndex == 0) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.isScheduleReviewed
                      ? 'Jadwal Siap ✓'
                      : 'Jadwal Perjalanan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: trip.isScheduleReviewed ? AppColors.success : AppColors.ink,
                  ),
                ),
                const Text(
                  'Pastikan jam & titik kumpul sesuai rencana Anda.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              setState(() => trip.isScheduleReviewed = true);
              _tabController.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Lanjut Persiapan →',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    }

    // Step 2: Persiapan -> "Lanjut Barang Bawaan"
    if (_currentTabIndex == 1) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  allReadinessDone
                      ? 'Persiapan Lengkap ✓'
                      : 'Checklist Persiapan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: allReadinessDone ? AppColors.success : AppColors.ink,
                  ),
                ),
                const Text(
                  'Centang daftar persiapan sebelum lanjut ke barang bawaan.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: allReadinessDone ? () => _tabController.animateTo(2) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
              disabledBackgroundColor: AppColors.disabledBg,
              disabledForegroundColor: AppColors.disabledText,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Lanjut Barang →',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    }

    // Step 3: Barang Bawaan -> Finalisasi Semua
    final bool canFinalize =
        trip.isScheduleReviewed && allReadinessDone && allPackingDone;
    String actionLabel = 'Konfirmasi Kesiapan';
    VoidCallback? onPressed;

    if (!trip.isScheduleReviewed) {
      actionLabel = 'Cek Jadwal';
      onPressed = () => _tabController.animateTo(0);
    } else if (!allReadinessDone) {
      actionLabel = 'Cek Persiapan';
      onPressed = () => _tabController.animateTo(1);
    } else if (!allPackingDone) {
      actionLabel = 'Konfirmasi Kesiapan';
      onPressed = null;
    } else {
      onPressed = () => _showReadinessConfirmDialog(
            readinessDone,
            readinessTotal,
            packingDone,
            packingTotal,
          );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                canFinalize
                    ? 'Siap Berangkat ✓'
                    : 'Checklist Barang Bawaan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: canFinalize ? AppColors.success : AppColors.ink,
                ),
              ),
              const Text(
                'Centang barang bawaan Anda sebelum konfirmasi kesiapan.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forest,
            foregroundColor: AppColors.cream,
            disabledBackgroundColor: AppColors.disabledBg,
            disabledForegroundColor: AppColors.disabledText,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RUNDOWN PERJALANAN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.forest),
                  ),
                  Text(
                    '${widget.trip.departureDate} • ${widget.trip.duration}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ],
              ),
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
        const SizedBox(height: 10),

        // Tombol Tambah Rundown Manual (Khusus Penyelenggara)
        if (widget.isOrganizerMode)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddOrEditItineraryRundownDialog(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Tambah Jam & Kegiatan Rundown',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        // Info Banner sesuai Role
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.infoBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isOrganizerMode
                      ? 'Sebagai Penyelenggara, Anda dapat menambah, mengubah, atau menghapus jadwal kegiatan peserta.'
                      : 'Jadwal perjalanan resmi ini disusun dan dikelola oleh penyelenggara trip.',
                  style: const TextStyle(fontSize: 11, color: AppColors.info, height: 1.3),
                ),
              ),
            ],
          ),
        ),

        if (widget.trip.itinerary.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sageBorder),
            ),
            child: const Center(
              child: Text(
                'Belum ada rundown. Klik tombol di atas untuk menambah jam & kegiatan rundown perjalanan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ),
          )
        else
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
                            color: step.status == 'Selesai'
                                ? AppColors.success
                                : (step.status == 'Sedang Berlangsung' ? AppColors.warning : AppColors.forest),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              step.icon,
                              size: 16,
                              color: Colors.white,
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
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: step.status == 'Selesai'
                                        ? AppColors.successBorder
                                        : (step.status == 'Sedang Berlangsung'
                                            ? AppColors.warningBg
                                            : AppColors.creamSubtle),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    step.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: step.status == 'Selesai'
                                          ? AppColors.success
                                          : (step.status == 'Sedang Berlangsung'
                                              ? AppColors.warningDark
                                              : AppColors.muted),
                                    ),
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
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                                  ),
                                ),
                              ],
                            ),
                            if (step.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                step.notes,
                                style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.35),
                              ),
                            ],
                            if (widget.isOrganizerMode) ...[
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: AppColors.creamSubtle),
                              const SizedBox(height: 6),

                              // Aksi Item Rundown (Khusus Penyelenggara): Toggle Status, Ubah & Hapus
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (step.status == 'Akan Datang') {
                                          step.status = 'Sedang Berlangsung';
                                        } else if (step.status == 'Sedang Berlangsung') {
                                          step.status = 'Selesai';
                                        } else {
                                          step.status = 'Akan Datang';
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.creamSubtle,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.divider),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.sync_rounded, size: 11, color: AppColors.forest),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ubah: ${step.status}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.forest),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Ubah Kegiatan',
                                        onPressed: () => _showAddOrEditItineraryRundownDialog(
                                          editIndex: index,
                                          editingStep: step,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Hapus Rundown',
                                        onPressed: () {
                                          setState(() {
                                            widget.trip.itinerary.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
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
  // TAB 2: CHECKLIST PERSIAPAN
  // ===========================================================================
  Widget _buildReadinessChecklistTab(int doneCount, int totalCount, double percent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Action: Tambah Checklist (Khusus Penyelenggara)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DAFTAR PERSIAPAN PESERTA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.forest),
            ),
            if (widget.isOrganizerMode)
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
          final canToggle = !widget.isOrganizerMode && widget.isJoinedParticipant;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.isDone ? AppColors.success.withValues(alpha: 0.4) : AppColors.sageBorder,
              ),
            ),
            child: CheckboxListTile(
              value: item.isDone,
              activeColor: AppColors.forest,
              onChanged: canToggle
                  ? (val) {
                      setState(() => item.isDone = val ?? false);
                    }
                  : null,
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
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPackingListTab(int packedCount, int totalCount) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DAFTAR BARANG BAWAAN',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.forest),
            ),
            if (widget.isOrganizerMode)
              TextButton.icon(
                onPressed: _showAddPackingDialog,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Tambah Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                style: TextButton.styleFrom(foregroundColor: AppColors.forest),
              ),
          ],
        ),
        const SizedBox(height: 6),

        ...widget.trip.packingList.map((pack) {
          final canToggle = !widget.isOrganizerMode && widget.isJoinedParticipant;
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pack.isPacked ? AppColors.success.withValues(alpha: 0.4) : AppColors.sageBorder,
              ),
            ),
            child: CheckboxListTile(
              value: pack.isPacked,
              activeColor: AppColors.forest,
              onChanged: canToggle
                  ? (val) {
                      setState(() => pack.isPacked = val ?? false);
                    }
                  : null,
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
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          );
        }),
      ],
    );
  }

}
