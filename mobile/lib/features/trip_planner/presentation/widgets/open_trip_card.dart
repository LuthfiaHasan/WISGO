import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../saved/services/destination_review_store.dart';
import '../../models/open_trip_model.dart';
import 'destination_panorama_sheet.dart';
import 'destination_weather_sheet.dart';
import 'google_maps_meeting_point_sheet.dart';
import 'open_trip_detail_sheet.dart';
import 'open_trip_payment_sheet.dart';
import 'organizer_rating_dialog.dart';
import 'trip_go_agreement_dialog.dart';
import 'trip_group_chat_sheet.dart';
import 'trip_planner_detail_sheet.dart';
import 'verified_organizer_sheet.dart';

/// Kartu Trip Go Modern & User-Friendly (Sesuai desain.md & 12 Poin Revisi Trip Go)
class OpenTripCard extends StatefulWidget {
  final OpenTripItem trip;
  final VoidCallback? onTripUpdated;
  final ValueChanged<String>? onTripDeleted;
  final VoidCallback? onOpenDestination360;
  final VoidCallback? onOpenDestinationReviews;
  final bool isOrganizerView;
  final VoidCallback? onSimulateAdminApprove;

  const OpenTripCard({
    super.key,
    required this.trip,
    this.onTripUpdated,
    this.onTripDeleted,
    this.onOpenDestination360,
    this.onOpenDestinationReviews,
    this.isOrganizerView = false,
    this.onSimulateAdminApprove,
  });

  @override
  State<OpenTripCard> createState() => _OpenTripCardState();
}

class _OpenTripCardState extends State<OpenTripCard> {
  bool _isMeetingReminderActive = false;

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _openDetailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OpenTripDetailSheet(
        trip: widget.trip,
        onTripUpdated: (updated) => widget.onTripUpdated?.call(),
        onTripDeleted: widget.onTripDeleted,
      ),
    );
  }

  Future<void> _handleDaftarAndBayar() async {
    final agreed = await showTripGoJoinAgreementDialog(
      context,
      tripTitle: widget.trip.title,
    );
    if (!agreed || !mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OpenTripPaymentSheet(trip: widget.trip),
    );
    if (mounted) widget.onTripUpdated?.call();
  }

  void _toggleMeetingReminder() {
    setState(() => _isMeetingReminderActive = !_isMeetingReminderActive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            _isMeetingReminderActive ? AppColors.forest : AppColors.ink,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              _isMeetingReminderActive
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              size: 18,
              color: AppColors.cream,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isMeetingReminderActive
                    ? 'Pengingat aktif! Notifikasi titik kumpul "${widget.trip.meetingPointName}" akan muncul 1 jam sebelum ${widget.trip.departureTime}.'
                    : 'Pengingat titik kumpul dinonaktifkan.',
                style: const TextStyle(fontSize: 12, color: AppColors.cream),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final availableQuota = trip.quotaMax - trip.quotaFilled;
    final isQuotaFull = availableQuota <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warmBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: _openDetailSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cover Image Bersih
              SizedBox(
                height: 162,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      trip.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.sage,
                        child: const Center(
                          child: Icon(
                            Icons.landscape_rounded,
                            size: 44,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.ink.withValues(alpha: 0.20),
                            Colors.transparent,
                            AppColors.ink.withValues(alpha: 0.74),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream.withValues(alpha: 0.94),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                trip.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isOrganizerView
                                  ? (trip.verificationStatus ==
                                          TripVerificationStatus.pendingAdmin
                                      ? AppColors.warning
                                      : AppColors.success)
                                  : (trip.isCurrentUserJoined
                                      ? AppColors.success
                                      : (isQuotaFull
                                          ? AppColors.terracotta
                                          : AppColors.forest
                                              .withValues(alpha: 0.92))),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              widget.isOrganizerView
                                  ? (trip.verificationStatus ==
                                          TripVerificationStatus.pendingAdmin
                                      ? 'Menunggu Admin'
                                      : 'Terverifikasi ✓')
                                  : (trip.isCurrentUserJoined
                                      ? 'Terdaftar ✓'
                                      : (isQuotaFull
                                          ? 'Penuh'
                                          : 'Sisa $availableQuota Kursi')),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cream,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.md,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.sage,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trip.singleDestination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              trip.duration,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Konten Kartu
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Trip
                    Text(
                      trip.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Tanggal & Waktu Keberangkatan
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${trip.departureDate} • ${trip.departureTime}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Titik Kumpul + Pengingat Non-Intrusif + Peta Maps (Poin 11)
                    Row(
                      children: [
                        const Icon(
                          Icons.pin_drop_outlined,
                          size: 15,
                          color: AppColors.brush,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            mouseCursor: SystemMouseCursors.click,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    GoogleMapsMeetingPointSheet(trip: trip),
                              );
                            },
                            child: Text(
                              'Titik Kumpul: ${trip.meetingPointName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: _isMeetingReminderActive
                              ? 'Pengingat titik kumpul aktif'
                              : 'Aktifkan pengingat titik kumpul',
                          child: InkWell(
                            mouseCursor: SystemMouseCursors.click,
                            onTap: _toggleMeetingReminder,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 3,
                              ),
                              child: Icon(
                                _isMeetingReminderActive
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                size: 16,
                                color: _isMeetingReminderActive
                                    ? AppColors.terracotta
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        InkWell(
                          mouseCursor: SystemMouseCursors.click,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  GoogleMapsMeetingPointSheet(trip: trip),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            child: Text(
                              'Peta ↗',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Penyelenggara / Pemandu (1-Klik Lihat 5 Info Penyelenggara — Poin 12)
                    InkWell(
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              VerifiedOrganizerSheet(organizer: trip.organizer),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                trip.organizer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${trip.organizer.rating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Bilah Pintasan Fitur: Chat · Cuaca · Ulasan · 360° (Poin 5, 6, 7, 10)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.creamSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.warmBorder),
                      ),
                      child: Row(
                        children: [
                          _buildQuietShortcut(
                            icon: Icons.forum_outlined,
                            label: 'Chat',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => TripGroupChatSheet(trip: trip),
                              );
                            },
                          ),
                          _buildVerticalDot(),
                          _buildQuietShortcut(
                            icon: Icons.wb_cloudy_outlined,
                            label: 'Cuaca',
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => DestinationWeatherSheet(
                                  destinationName: trip.singleDestination,
                                ),
                              );
                            },
                          ),
                          _buildVerticalDot(),
                          _buildQuietShortcut(
                            icon: Icons.reviews_outlined,
                            label: 'Ulasan',
                            onTap: () {
                              if (widget.onOpenDestinationReviews != null) {
                                widget.onOpenDestinationReviews!();
                              } else {
                                _openDetailSheet();
                              }
                            },
                          ),
                          _buildVerticalDot(),
                          _buildQuietShortcut(
                            icon: Icons.threesixty_rounded,
                            label: '360°',
                            onTap: () {
                              if (widget.onOpenDestination360 != null) {
                                widget.onOpenDestination360!();
                              } else {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => DestinationPanoramaSheet(
                                    destinationName: trip.singleDestination,
                                    panoramaImageUrl: trip.coverUrl,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Baris Harga + Tombol Detail (Poin 8)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Rp ${_formatRupiah(trip.pricePerPerson)}',
                              style: AppTypography.withTabularFigures(
                                const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                            const Text(
                              ' / org',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _openDetailSheet,
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: AppColors.forest,
                          ),
                          label: const Text(
                            'Detail',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            backgroundColor: AppColors.sage,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xs),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 5. Tombol Aksi Utama sesuai Role (Penyelenggara vs Peserta Terdaftar vs Wisatawan)
                    if (widget.isOrganizerView) ...[
                      if (trip.verificationStatus ==
                          TripVerificationStatus.pendingAdmin) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.hourglass_top_rounded,
                                size: 16,
                                color: AppColors.warningDark,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Langkah 4: Pengajuan sedang ditinjau Admin WISGO (Data Diri, KTP, Lisensi/Pengalaman). Setelah disetujui, trip tayang ke publik & Anda bisa masuk Langkah 5 (Atur Rencana).',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.warningDark,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: widget.onSimulateAdminApprove,
                            icon: const Icon(Icons.verified_rounded, size: 16),
                            label: const Text(
                              'Simulasi ACC Admin (Uji Coba)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: AppColors.cream,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showModalBottomSheet(
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
                                  icon: const Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Atur Rencana & Persiapan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.forest,
                                    foregroundColor: AppColors.cream,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) =>
                                          TripGroupChatSheet(trip: trip),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.forum_outlined,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Chat Peserta',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.forest,
                                    side: const BorderSide(
                                      color: AppColors.sageBorder,
                                      width: 1.3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ] else if (trip.isCurrentUserJoined) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => TripPlannerDetailSheet(
                                      trip: trip,
                                      isOrganizerMode: false,
                                      isJoinedParticipant: true,
                                      onReadinessFinalized: widget.onTripUpdated,
                                    ),
                                  );
                                },
                                icon: Icon(
                                  trip.isReadinessFinalized
                                      ? Icons.verified_rounded
                                      : Icons.fact_check_rounded,
                                  size: 15,
                                ),
                                label: Text(
                                  trip.isReadinessFinalized
                                      ? 'Siap Berangkat ✓'
                                      : 'Lengkapi Persiapan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 42,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        TripGroupChatSheet(trip: trip),
                                  );
                                },
                                icon: const Icon(
                                  Icons.forum_outlined,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Buka Chat',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.forest,
                                  side: const BorderSide(
                                    color: AppColors.sageBorder,
                                    width: 1.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (trip.isTripCompleted) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: trip.hasReviewedOrganizer
                                ? null
                                : () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final ok = await showOrganizerRatingDialog(
                                      context,
                                      trip: trip,
                                    );
                                    if (ok && mounted) {
                                      setState(() {});
                                      widget.onTripUpdated?.call();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          backgroundColor: AppColors.success,
                                          content: Text(
                                            'Terima kasih! Rating & ulasan masuk ke Pencapaian Penyelenggara.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: Icon(
                              trip.hasReviewedOrganizer
                                  ? Icons.check_circle_rounded
                                  : Icons.star_rounded,
                              size: 16,
                            ),
                            label: Text(
                              trip.hasReviewedOrganizer
                                  ? 'Penyelenggara Sudah Diulas ✓'
                                  : 'Beri Rating & Ulasan Penyelenggara',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.sage,
                              disabledForegroundColor: AppColors.success,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                        ),
                      ] else if (trip.isReadinessFinalized) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() => trip.isTripCompleted = true);
                              OrganizerRatingStore.instance
                                  .markOrganizerTripCompleted();
                              DestinationReviewStore.instance
                                  .unlockFromCompletedOpenTrip(
                                      trip.singleDestination);
                              widget.onTripUpdated?.call();
                            },
                            icon: const Icon(Icons.flag_rounded, size: 14),
                            label: const Text(
                              'Simulasi Trip Selesai (Uji Rating)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.info,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => TripPlannerDetailSheet(
                                      trip: trip,
                                      isOrganizerMode: false,
                                      isJoinedParticipant: false,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.fact_check_outlined,
                                  size: 15,
                                ),
                                label: const Text(
                                  'Lihat Rencana',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.forest,
                                  side: const BorderSide(
                                    color: AppColors.sageBorder,
                                    width: 1.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed:
                                    isQuotaFull ? null : _handleDaftarAndBayar,
                                icon: const Icon(Icons.payment_rounded, size: 15),
                                label: Text(
                                  isQuotaFull ? 'Penuh' : 'Daftar & Bayar',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forest,
                                  foregroundColor: AppColors.cream,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuietShortcut({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.forest),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDot() {
    return Container(
      width: 1,
      height: 16,
      color: AppColors.warmBorder,
    );
  }
}
