part of '../audio_culture_screen.dart';

extension _AudioCultureKalenderTab on _AudioCultureScreenState {
  Widget _buildKalenderBudayaTab() {
    final festivals = _festivalList;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, widget.embedded ? 124 : 32),
      children: [
        // =====================================================================
        // KARTU 1: BANNER FITUR KALENDER EVENT & FESTIVAL BUDAYA (PERSIS DARI OPEN TRIP)
        // =====================================================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldMinang.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldMinang.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.creamSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 13, color: AppColors.goldMinang),
                        SizedBox(width: 4),
                        Text(
                          'Agenda & Event',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldMinang,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.calendar_month_outlined, color: AppColors.goldMinang, size: 22),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Kalender Event & Festival Budaya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lihat jadwal festival budaya, pertunjukan kesenian randai, pacu jawi, dan agenda wisata tahunan resmi di Sumatera Barat.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _openKalenderBudayaModal(context),
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text(
                    'Buka Kalender Event',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldMinang,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // =====================================================================
        // SECTION 2: AGENDA FESTIVAL TAHUNAN RESMI (LIST INTERAKTIF LENGKAP)
        // =====================================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'AGENDA FESTIVAL TAHUNAN RESMI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.goldMinang,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.creamSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${festivals.length} Festival',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldMinang,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List Festival Cards
        ...festivals.map((ev) {
          final isReminded = _remindedIds.contains(ev['id']);
          final badgeColor = Color(ev['badgeColor'] as int? ?? 0xFF5A3E85);
          final badgeBg = Color(ev['badgeBg'] as int? ?? 0xFFF3EDFA);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isReminded ? AppColors.forest.withValues(alpha: 0.6) : AppColors.sageBorder,
                width: isReminded ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openFestivalDetailModal(ev),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ev['badge'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isReminded) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBorder,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.notifications_active_rounded, size: 10, color: AppColors.success),
                                      SizedBox(width: 3),
                                      Text(
                                        'Pengingat Aktif',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.muted),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      ev['date'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ev['title'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.brush),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ev['location'] as String,
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
                      Text(
                        ev['desc'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.creamSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warmBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 12, color: AppColors.forest),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'GPS: ${ev["gpsCoordinate"]}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                            const Text(
                              'Lihat Detail & Rute',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.ink),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // =====================================================================
        // SECTION 3: PASAR TRADISIONAL & HARI PAKAN NAGARI
        // =====================================================================
        const Text(
          'PASAR TRADISIONAL & HARI PAKAN NAGARI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.info,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldMinang.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.warning, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.tr(
                        'Kalender Adat & Hari Pakan',
                        'Cultural & Market Day Calendar',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hari Pakan adalah hari pasar tradisional bergilir nagari tempat warga menjual kuliner otentik.',
                      style: TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ..._culturalEvents.map((evt) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          evt.badge,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      Text(
                        evt.cityRegency,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evt.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 13, color: AppColors.terracotta),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evt.scheduleRule,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evt.nagariLocation,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evt.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
