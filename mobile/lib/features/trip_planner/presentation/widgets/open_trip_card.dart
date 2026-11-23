import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';
import 'destination_weather_sheet.dart';
import 'ground_condition_sheet.dart';
import 'destination_panorama_sheet.dart';
import 'google_maps_meeting_point_sheet.dart';
import 'open_trip_offline_rules_sheet.dart';
import 'open_trip_payment_sheet.dart';
import 'trip_planner_detail_sheet.dart';
import 'verified_organizer_sheet.dart';

/// Card Tampilan Open Trip Modern (Item 4 Open Trip)
/// Mengimplementasikan seluruh kriteria Open Trip:
/// 1. Satu destinasi tunggal per perjalanan
/// 2. Kategori otomatis berdasarkan destinasi
/// 3. Transaksi langsung melalui sistem WISGO
/// 4. Tampilan card elegan & mudah dipahami
/// 5. Titik kumpul Google Maps terintegrasi
/// 6. Mekanisme verifikasi penyelenggara
/// 7. Ketentuan aktivitas luar aplikasi
class OpenTripCard extends StatelessWidget {
  final OpenTripItem trip;
  final VoidCallback? onTripUpdated;

  const OpenTripCard({
    super.key,
    required this.trip,
    this.onTripUpdated,
  });

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final availableQuota = trip.quotaMax - trip.quotaFilled;
    final isQuotaFull = availableQuota <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sageBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cover Image with Auto-Category & Quota Badges
          Stack(
            children: [
              Image.network(
                trip.coverUrl,
                height: 155,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 155,
                  color: AppColors.sage,
                  child: const Center(
                    child: Icon(Icons.landscape_rounded, size: 48, color: AppColors.forest),
                  ),
                ),
              ),
              // Subtle gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Badges on Top
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kategori Otomatis
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.cream),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                trip.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.cream,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Status Kuota
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isQuotaFull
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF10B981).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        isQuotaFull
                            ? 'Penuh'
                            : '${trip.quotaFilled}/${trip.quotaMax} (Sisa $availableQuota)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Single Destination Tag on Bottom of Image
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 13, color: AppColors.forest),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Tujuan: ${trip.singleDestination}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Card Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  trip.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Departure Date & Duration
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${trip.departureDate} • ${trip.departureTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trip.duration,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E5B82)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Meeting Point (Google Maps Integrated)
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => GoogleMapsMeetingPointSheet(trip: trip),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Kumpul: ${trip.meetingPointName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Peta Maps ↗',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Penyelenggara Terverifikasi Badge (Item 6 Open Trip)
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => VerifiedOrganizerSheet(organizer: trip.organizer),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.organizer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              Text(
                                '${trip.organizer.verificationBadge} • ★ ${trip.organizer.rating}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Bilah Pintasan Cepat: Cuaca Real-time, Kondisi Nyata & Panorama 360°
                Row(
                  children: [
                    // Tombol Cuaca Real-time
                    Expanded(
                      child: InkWell(
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
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wb_cloudy_rounded, size: 13, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Info Cuaca',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Tombol Kondisi Nyata Lapangan
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => GroundConditionSheet(
                              destinationName: trip.singleDestination,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_rounded, size: 13, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Kondisi Riil',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Tombol 360 Panorama View
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DestinationPanoramaSheet(
                              destinationName: trip.singleDestination,
                              panoramaImageUrl: trip.coverUrl,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.threesixty_rounded, size: 13, color: Color(0xFFD97706)),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Foto 360°',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),

                // Harga & Status Transaksi Sistem WISGO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaksi Khusus Open Trip (Escrow):',
                            style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Text(
                                'Rp ${_formatRupiah(trip.pricePerPerson)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forest,
                                ),
                              ),
                              const Text(
                                ' / org',
                                style: TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.forest.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 11, color: AppColors.forest),
                          SizedBox(width: 4),
                          Text(
                            'Escrow',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.forest),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons Bar
                Row(
                  children: [
                    // Tombol SOP Luar Aplikasi
                    IconButton(
                      tooltip: 'Ketentuan & SOP Luar Aplikasi',
                      icon: const Icon(Icons.rule_folder_outlined, size: 22, color: AppColors.forest),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => OpenTripOfflineRulesSheet(trip: trip),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    // Tombol Trip Planner (5 Fitur: Itinerary, Checklist, Jobdesk, Packing, Chat)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TripPlannerDetailSheet(trip: trip),
                          );
                        },
                        icon: const Icon(Icons.alt_route_rounded, size: 15),
                        label: const Text(
                          'Trip Planner',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.forest, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Transaksi Langsung Sistem WISGO
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isQuotaFull
                            ? null
                            : () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => OpenTripPaymentSheet(trip: trip),
                                ).then((_) => onTripUpdated?.call());
                              },
                        icon: const Icon(Icons.payment_rounded, size: 15),
                        label: Text(
                          isQuotaFull ? 'Penuh' : 'Daftar & Bayar',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }
}
