import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GroupMemberLocation {
  final String id;
  final String name;
  final String role; // 'Ketua' | 'Anggota'
  final int distanceMeters;
  final int batteryPct;
  final double xPct;
  final double yPct;
  final String status;

  const GroupMemberLocation({
    required this.id,
    required this.name,
    required this.role,
    required this.distanceMeters,
    required this.batteryPct,
    required this.xPct,
    required this.yPct,
    required this.status,
  });
}

class LiveGroupTrackingSheet extends StatefulWidget {
  final String groupName;
  final String destinationTitle;

  const LiveGroupTrackingSheet({
    super.key,
    this.groupName = 'Rombongan Wisata Alumni Sumbar',
    this.destinationTitle = 'Kawasan Wisata Sumatera Barat',
  });

  @override
  State<LiveGroupTrackingSheet> createState() => _LiveGroupTrackingSheetState();
}

class _LiveGroupTrackingSheetState extends State<LiveGroupTrackingSheet> {
  final List<GroupMemberLocation> _members = [
    const GroupMemberLocation(
      id: 'm1',
      name: 'Anda (Ketua Rombongan)',
      role: 'Ketua',
      distanceMeters: 0,
      batteryPct: 88,
      xPct: 0.50,
      yPct: 0.55,
      status: 'Titik Posisi Utama',
    ),
    const GroupMemberLocation(
      id: 'm2',
      name: 'Siti Rahma',
      role: 'Anggota',
      distanceMeters: 25,
      batteryPct: 76,
      xPct: 0.42,
      yPct: 0.45,
      status: 'Di Dekat Loket Registrasi',
    ),
    const GroupMemberLocation(
      id: 'm3',
      name: 'Bayu Pratama',
      role: 'Anggota',
      distanceMeters: 80,
      batteryPct: 54,
      xPct: 0.65,
      yPct: 0.40,
      status: 'Di Warung Kuliner UMKM',
    ),
    const GroupMemberLocation(
      id: 'm4',
      name: 'Eko Wahyudi',
      role: 'Anggota',
      distanceMeters: 210,
      batteryPct: 22,
      xPct: 0.78,
      yPct: 0.28,
      status: 'Dekat Jalur Trekking Atas',
    ),
  ];

  String _meetingPoint = 'Pos Musholla & Parkir Utama';
  bool _isAlarmActive = false;

  void _triggerAlarm() {
    setState(() => _isAlarmActive = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sinyal Alarm Kumpul Terkirim ke Seluruh Perangkat Rombongan!'),
        backgroundColor: AppColors.terracotta,
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isAlarmActive = false);
    });
  }

  void _changeMeetingPoint(String newPoint) {
    setState(() => _meetingPoint = newPoint);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Titik Temu Diperbarui: $_meetingPoint'),
        backgroundColor: AppColors.forest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PANTAU LOKASI ROMBONGAN (LIVE GPS)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.brush,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.warmBorder),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Meeting point badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sageBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_rounded, size: 16, color: AppColors.forest),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Titik Kumpul Resmi (Meeting Point)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.muted),
                            ),
                            Text(
                              _meetingPoint,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _changeMeetingPoint(
                            _meetingPoint.contains('Musholla')
                                ? 'Pusat Warung UMKM Minang'
                                : 'Pos Musholla & Parkir Utama',
                          );
                        },
                        child: const Text('Ganti', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.forest)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Radar GPS Map Visualizer
                Container(
                  height: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF2ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.forest, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Radar Concentric Circles
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RadarBackgroundPainter(),
                        ),
                      ),

                      // Status pill
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.sageBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.radar_rounded, size: 13, color: AppColors.forest),
                              SizedBox(width: 4),
                              Text(
                                'Radius Pemantauan: 500m',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forest),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Members Pins on Radar
                      ..._members.map((m) {
                        final isLeader = m.role == 'Ketua';
                        return Positioned(
                          left: 320 * m.xPct - 14,
                          top: 230 * m.yPct - 14,
                          child: Tooltip(
                            message: '${m.name} (${m.distanceMeters}m)',
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: isLeader ? AppColors.forest : AppColors.terracotta,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isLeader ? Icons.star_rounded : Icons.person_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    m.name.split(' ').first,
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Emergency Gathering Alarm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _triggerAlarm,
                    icon: Icon(_isAlarmActive ? Icons.notifications_active_rounded : Icons.campaign_rounded, size: 18),
                    label: Text(
                      _isAlarmActive ? 'Mengirim Sinyal Panggilan Kumpul...' : 'Bunyikan Alarm Panggil Kumpul Rombongan',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAlarmActive ? Colors.redAccent : AppColors.terracotta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Member detail cards list
                const Text(
                  'STATUS ANGGOTA ROMBONGAN (4 ORANG)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.muted),
                ),
                const SizedBox(height: 8),

                ..._members.map((m) {
                  final isWarning = m.distanceMeters > 150 || m.batteryPct < 25;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isWarning ? AppColors.terracotta.withValues(alpha: 0.5) : AppColors.sageBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: m.role == 'Ketua' ? AppColors.sage : const Color(0xFFF0EAE1),
                          child: Text(
                            m.name[0],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: m.role == 'Ketua' ? AppColors.forest : AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                                  ),
                                  if (m.role == 'Ketua') ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.forest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Ketua', style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.status,
                                style: const TextStyle(fontSize: 10, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m.distanceMeters == 0 ? 'Titik Anda' : '${m.distanceMeters}m',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: m.distanceMeters > 150 ? AppColors.terracotta : AppColors.forest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  m.batteryPct < 25 ? Icons.battery_alert_rounded : Icons.battery_5_bar_rounded,
                                  size: 12,
                                  color: m.batteryPct < 25 ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${m.batteryPct}%',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final circlePaint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 40, circlePaint);
    canvas.drawCircle(center, 80, circlePaint);
    canvas.drawCircle(center, 120, circlePaint);

    final linePaint = Paint()
      ..color = AppColors.forest.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
