import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../saved/services/destination_review_store.dart';
import '../../models/open_trip_model.dart';
import 'open_trip_create_sheet.dart';
import 'open_trip_participants_sheet.dart';
import 'trip_group_chat_sheet.dart';
import 'trip_planner_detail_sheet.dart';

/// Hub Khusus Penyelenggara Open Trip (dibuka dari tombol bawah "Open Trip" di Trip Go)
class OpenTripOrganizerHubSheet extends StatefulWidget {
  final List<OpenTripItem> allTrips;
  final ValueChanged<OpenTripItem> onTripCreated;
  final VoidCallback onTripsChanged;

  const OpenTripOrganizerHubSheet({
    super.key,
    required this.allTrips,
    required this.onTripCreated,
    required this.onTripsChanged,
  });

  @override
  State<OpenTripOrganizerHubSheet> createState() =>
      _OpenTripOrganizerHubSheetState();
}

class _OpenTripOrganizerHubSheetState extends State<OpenTripOrganizerHubSheet> {
  void _openCreateForm() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OpenTripCreateSheet(
        onTripCreated: (newTrip) {
          widget.onTripCreated(newTrip);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.forest,
              content: Text(
                'Pengajuan Open Trip terkirim! Menunggu verifikasi Admin WISGO.',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepDot(String num, String label, bool isDone) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? AppColors.success : AppColors.creamSubtle,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? AppColors.success : AppColors.warmBorder,
              ),
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    num,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w600,
              color: isDone ? AppColors.ink : AppColors.muted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myTrips =
        widget.allTrips.where((t) => t.isCreatedByCurrentUser).toList();
    final hasApproved = myTrips
        .any((t) => t.verificationStatus == TripVerificationStatus.approved);
    final hasPending = myTrips
        .any((t) => t.verificationStatus == TripVerificationStatus.pendingAdmin);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.warmBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PANEL PENYELENGGARA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.brush,
                        ),
                      ),
                      Text(
                        'Open Trip Saya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.warmBorder),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  // Kartu Status Penyelenggara 5 Langkah
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'STATUS PENYELENGGARA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.brush,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: hasApproved
                                    ? AppColors.successBg
                                    : (hasPending
                                        ? AppColors.warningBg
                                        : AppColors.sage),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                hasApproved
                                    ? 'Penyelenggara Terverifikasi ✓'
                                    : (hasPending
                                        ? 'Menunggu Verifikasi Admin'
                                        : 'Belum Mengajukan'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: hasApproved
                                      ? AppColors.success
                                      : (hasPending
                                          ? AppColors.warningDark
                                          : AppColors.forest),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStepDot('1', 'Data Diri', myTrips.isNotEmpty),
                            _buildStepDot('2', 'Upload KTP', myTrips.isNotEmpty),
                            _buildStepDot('3', 'Lisensi /\nPengalaman', myTrips.isNotEmpty),
                            _buildStepDot('4', 'Verifikasi\nAdmin', hasApproved),
                            _buildStepDot('5', 'Atur &\nKelola', hasApproved),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openCreateForm,
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text(
                        'Buat Open Trip & Ajukan Verifikasi',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: AppColors.cream,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Daftar Open Trip yang Anda Kelola (${myTrips.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (myTrips.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: const Text(
                        'Semua wisatawan bisa menjadi penyelenggara! Klik tombol di atas untuk mengisi Data Diri, Upload KTP, serta Lisensi/Pengalaman. Setelah disetujui Admin, Anda dapat mengatur Rencana & Persiapan serta memantau Data & Kelengkapan Peserta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                    )
                  else
                    ...myTrips.map((trip) {
                      final isApproved = trip.verificationStatus ==
                          TripVerificationStatus.approved;
                      final isRejected = trip.verificationStatus ==
                          TripVerificationStatus.rejected;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRejected
                                ? AppColors.danger
                                : AppColors.sageBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    trip.title,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: trip.isTripCompleted
                                        ? AppColors.infoBg
                                        : (isRejected
                                            ? AppColors.dangerBg
                                            : (isApproved
                                                ? AppColors.successBg
                                                : AppColors.warningBg)),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    trip.isTripCompleted
                                        ? 'Selesai ✓'
                                        : (isRejected
                                            ? 'Ditolak Admin'
                                            : (isApproved
                                                ? 'Disetujui ✓'
                                                : 'Menunggu Admin')),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: trip.isTripCompleted
                                          ? AppColors.info
                                          : (isRejected
                                              ? AppColors.danger
                                              : (isApproved
                                                  ? AppColors.success
                                                  : AppColors.warningDark)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trip.singleDestination} • Level ${trip.difficultyLevel} • ${trip.departureDate}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (isRejected) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Ditolak Admin: ${trip.adminRejectionReason ?? 'Foto KTP / Lisensi belum jelas. Silakan ajukan ulang.'}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _openCreateForm,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text(
                                    'Perbaiki & Ajukan Ulang',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(color: AppColors.danger),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (!isApproved) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          trip.verificationStatus =
                                              TripVerificationStatus.approved;
                                        });
                                        OrganizerNotificationBridge.emit(
                                          tripId: trip.id,
                                          tripTitle: trip.title,
                                          approved: true,
                                        );
                                        widget.onTripsChanged();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppColors.success,
                                            content: Text(
                                              'Notifikasi terkirim: Disetujui Admin! Manajemen Penyelenggara kini aktif.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.verified_rounded, size: 15),
                                      label: const Text(
                                        'ACC Admin (Uji)',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.forest,
                                        foregroundColor: AppColors.cream,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          trip.verificationStatus =
                                              TripVerificationStatus.rejected;
                                          trip.adminRejectionReason =
                                              'Foto KTP kurang jelas atau nomor lisensi tidak valid.';
                                        });
                                        OrganizerNotificationBridge.emit(
                                          tripId: trip.id,
                                          tripTitle: trip.title,
                                          approved: false,
                                          reason: trip.adminRejectionReason!,
                                        );
                                        widget.onTripsChanged();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppColors.danger,
                                            content: Text(
                                              'Notifikasi terkirim: Pengajuan Ditolak Admin.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.close_rounded, size: 15),
                                      label: const Text(
                                        'Tolak (Uji)',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(color: AppColors.danger),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => TripPlannerDetailSheet(
                                            trip: trip,
                                            isOrganizerMode: true,
                                            isJoinedParticipant: true,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                                      label: const Text(
                                        'Atur Rencana',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.forest,
                                        foregroundColor: AppColors.cream,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => OpenTripParticipantsSheet(
                                            trip: trip,
                                            onUpdated: () {
                                              setState(() {});
                                              widget.onTripsChanged();
                                            },
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.people_alt_rounded, size: 15),
                                      label: Text(
                                        'Peserta (${trip.participants.length})',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.forest,
                                        side: const BorderSide(color: AppColors.sageBorder),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => TripGroupChatSheet(trip: trip),
                                        );
                                      },
                                      icon: const Icon(Icons.forum_outlined, size: 15),
                                      label: const Text(
                                        'Chat Peserta',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.forest,
                                        side: const BorderSide(color: AppColors.sageBorder),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!trip.isTripCompleted)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() => trip.isTripCompleted = true);
                                          OrganizerRatingStore.instance
                                              .markOrganizerTripCompleted();
                                          DestinationReviewStore.instance
                                              .unlockFromCompletedOpenTrip(
                                                  trip.singleDestination);
                                          widget.onTripsChanged();
                                        },
                                        icon: const Icon(Icons.flag_rounded, size: 15),
                                        label: const Text(
                                          'Tandai Selesai',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.info,
                                          side: const BorderSide(color: AppColors.infoBorder),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
