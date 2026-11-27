import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';

/// Sheet Data & Kelengkapan Peserta Trip Go (Khusus Penyelenggara Terverifikasi)
class OpenTripParticipantsSheet extends StatefulWidget {
  final OpenTripItem trip;
  final VoidCallback? onUpdated;

  const OpenTripParticipantsSheet({
    super.key,
    required this.trip,
    this.onUpdated,
  });

  @override
  State<OpenTripParticipantsSheet> createState() =>
      _OpenTripParticipantsSheetState();
}

class _OpenTripParticipantsSheetState extends State<OpenTripParticipantsSheet> {
  String _filter = 'Semua'; // 'Semua' | 'Siap' | 'Belum'

  @override
  Widget build(BuildContext context) {
    final all = widget.trip.participants;
    final readyCount = all.where((p) => p.isFinalized).length;
    final checkedInCount = all.where((p) => p.isCheckedInAtMeetingPoint).length;

    final filtered = all.where((p) {
      if (_filter == 'Siap') return p.isFinalized;
      if (_filter == 'Belum') return !p.isFinalized;
      return true;
    }).toList();

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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATA & KELENGKAPAN PESERTA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.brush,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.trip.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  ),
                ],
              ),
            ),

            // Ringkasan Stat Peserta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statBox(
                    label: 'Terdaftar',
                    value: '${all.length} Org',
                    color: AppColors.forest,
                    bg: AppColors.sage,
                  ),
                  const SizedBox(width: 8),
                  _statBox(
                    label: 'Siap Final',
                    value: '$readyCount/${all.length}',
                    color: AppColors.success,
                    bg: AppColors.successBg,
                  ),
                  const SizedBox(width: 8),
                  _statBox(
                    label: 'Presensi Kumpul',
                    value: '$checkedInCount/${all.length}',
                    color: AppColors.info,
                    bg: AppColors.infoBg,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filter Cepat
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Semua', 'Siap', 'Belum'].map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selected,
                      label: Text(
                        f == 'Siap'
                            ? 'Siap Berangkat'
                            : (f == 'Belum' ? 'Belum Finalisasi' : 'Semua'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.forest,
                        ),
                      ),
                      selectedColor: AppColors.forest,
                      backgroundColor: AppColors.bgCard,
                      showCheckmark: false,
                      side: BorderSide(
                        color: selected ? AppColors.forest : AppColors.sageBorder,
                      ),
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Daftar Anggota Trip
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada peserta pada filter ini.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: p.isFinalized
                                  ? AppColors.successBorder
                                  : AppColors.warmBorder,
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
                                      p.fullName,
                                      style: const TextStyle(
                                        fontSize: 14,
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
                                      color: p.isFinalized
                                          ? AppColors.successBg
                                          : AppColors.warningBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      p.isFinalized
                                          ? 'Siap Berangkat ✓'
                                          : 'Belum Finalisasi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: p.isFinalized
                                            ? AppColors.success
                                            : AppColors.warningDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${p.bookingCode} • ${p.seatCount} Kursi • ${p.paymentMethod} (LUNAS)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                              const Divider(height: 16, color: AppColors.divider),
                              _infoLine(Icons.phone_rounded, 'HP / WA', p.phoneNumber),
                              const SizedBox(height: 4),
                              _infoLine(
                                Icons.emergency_rounded,
                                'Kontak Darurat',
                                p.emergencyContact,
                              ),
                              if (p.specialNotes.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                _infoLine(
                                  Icons.notes_rounded,
                                  'Catatan / Alergi',
                                  p.specialNotes,
                                ),
                              ],
                              const SizedBox(height: 10),

                              // Checklist Kelengkapan Peserta
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.creamSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _miniCheck(
                                      'Jadwal',
                                      p.isScheduleReady ? 'Siap ✓' : 'Belum',
                                      p.isScheduleReady,
                                    ),
                                    _miniCheck(
                                      'Persiapan',
                                      '${p.readinessDone}/${p.readinessTotal}',
                                      p.readinessDone >= p.readinessTotal,
                                    ),
                                    _miniCheck(
                                      'Barang',
                                      '${p.packingDone}/${p.packingTotal}',
                                      p.packingDone >= p.packingTotal,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Tombol Presensi Titik Kumpul
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      p.isCheckedInAtMeetingPoint =
                                          !p.isCheckedInAtMeetingPoint;
                                    });
                                    widget.onUpdated?.call();
                                  },
                                  icon: Icon(
                                    p.isCheckedInAtMeetingPoint
                                        ? Icons.check_circle_rounded
                                        : Icons.how_to_reg_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    p.isCheckedInAtMeetingPoint
                                        ? 'Hadir di Titik Kumpul ✓'
                                        : 'Tandai Hadir di Titik Kumpul',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: p.isCheckedInAtMeetingPoint
                                        ? AppColors.success
                                        : AppColors.forest,
                                    backgroundColor: p.isCheckedInAtMeetingPoint
                                        ? AppColors.successBg
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color: p.isCheckedInAtMeetingPoint
                                          ? AppColors.success
                                          : AppColors.sageBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniCheck(String label, String value, bool ok) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: ok ? AppColors.success : AppColors.warningDark,
          ),
        ),
      ],
    );
  }
}
