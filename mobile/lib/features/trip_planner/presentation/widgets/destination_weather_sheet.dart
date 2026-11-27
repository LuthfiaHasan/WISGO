import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../models/weather_model.dart';

/// Modal Lembar Informasi Cuaca Destinasi Real-Time & Peringatan Perjalanan
/// Selaras dengan Widget Cuaca Hijau Rimba & Warm Cream Beranda WISGO (desain.md).
class DestinationWeatherSheet extends StatefulWidget {
  final String destinationName;

  const DestinationWeatherSheet({
    super.key,
    required this.destinationName,
  });

  @override
  State<DestinationWeatherSheet> createState() =>
      _DestinationWeatherSheetState();
}

class _DestinationWeatherSheetState extends State<DestinationWeatherSheet> {
  late DestinationWeather _weather;
  bool _isRefreshing = false;
  DateTime _lastUpdatedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _weather = DestinationWeather.getForDestination(widget.destinationName);
    _loadLiveWeather();
  }

  void _loadLiveWeather() async {
    final live = await DestinationWeather.fetchLiveFromWeatherApi(
      destinationName: widget.destinationName,
    );
    if (!mounted) return;
    setState(() {
      _weather = live;
      _lastUpdatedTime = DateTime.now();
    });
  }

  void _handleRefreshWeather() async {
    setState(() => _isRefreshing = true);
    final live = await DestinationWeather.fetchLiveFromWeatherApi(
      destinationName: widget.destinationName,
    );
    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
      _lastUpdatedTime = DateTime.now();
      _weather = live;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.satellite_alt_rounded, color: AppColors.cream, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data cuaca ${_weather.destinationName} berhasil diperbarui via WeatherAPI!',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.cream,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alert = _weather.tripAlert;
    final isAlertWarning = alert.severity != 'Aman';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle baku 40x4 px
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.warmBorder,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),

            // Header selaras palet WISGO (Sage + Forest + Cream)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.sageBorder),
                    ),
                    child: Icon(
                      _weather.conditionIcon,
                      color: AppColors.forest,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Cuaca Destinasi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          _weather.cityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CARD 1: SUHU & KONDISI CUACA SAAT INI (SELARAS HIJAU RIMBA + CREAM BERANDA WISGO)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.forest,
                              AppColors.brush,
                              AppColors.ink,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.forest.withValues(alpha: 0.24),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Latar Atmosfer Hangat (Cahaya Emas Lembut + Siluet Awan seperti di Beranda)
                            Positioned(
                              top: -32,
                              right: -20,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.goldSoft.withValues(alpha: 0.38),
                                      AppColors.goldMinang.withValues(alpha: 0.14),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.48, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 26,
                              right: -12,
                              child: Icon(
                                Icons.cloud_rounded,
                                size: 84,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            Positioned(
                              top: 46,
                              right: 52,
                              child: Icon(
                                Icons.cloud_rounded,
                                size: 54,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            Positioned(
                              bottom: -18,
                              left: -12,
                              child: Icon(
                                Icons.cloud_rounded,
                                size: 70,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),

                            // Konten Utama Cuaca
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  // Real-time update badge & refresh button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.13),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.pill),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.successBorder,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'Live WeatherAPI • ${_lastUpdatedTime.hour.toString().padLeft(2, '0')}:${_lastUpdatedTime.minute.toString().padLeft(2, '0')} WIB',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: AppColors.cream,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        mouseCursor: SystemMouseCursors.click,
                                        onTap: _isRefreshing
                                            ? null
                                            : _handleRefreshWeather,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.pill),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.cream
                                                .withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.pill),
                                            border: Border.all(
                                              color: AppColors.cream
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _isRefreshing
                                                  ? const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                AppColors.cream),
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.refresh_rounded,
                                                      size: 13,
                                                      color: AppColors.cream,
                                                    ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Perbarui',
                                                style: TextStyle(
                                                  color: AppColors.cream,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Main temperature & condition
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _weather.destinationName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.cream
                                                    .withValues(alpha: 0.85),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${_weather.currentTemp}',
                                                  style: AppTypography
                                                      .withTabularFigures(
                                                    const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 46,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                ),
                                                const Text(
                                                  '°C',
                                                  style: TextStyle(
                                                    color: AppColors.cream,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _weather.currentCondition,
                                              style: const TextStyle(
                                                color: AppColors.goldSoft,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Terasa seperti ${_weather.feelsLikeTemp}°C',
                                              style: TextStyle(
                                                color: AppColors.cream
                                                    .withValues(alpha: 0.72),
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.goldSoft
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Icon(
                                          _weather.conditionIcon,
                                          color: AppColors.goldSoft,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Sub-metrics strip ala Widget Cuaca Beranda
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildMiniMetric(
                                            Icons.water_drop_outlined,
                                            '${_weather.humidity}%',
                                            'Kelembaban',
                                          ),
                                        ),
                                        _buildMiniDivider(),
                                        Expanded(
                                          child: _buildMiniMetric(
                                            Icons.air_rounded,
                                            '${_weather.windSpeedKmh} km/j',
                                            'Angin',
                                          ),
                                        ),
                                        _buildMiniDivider(),
                                        Expanded(
                                          child: _buildMiniMetric(
                                            Icons.wb_sunny_outlined,
                                            _weather.uvIndex.split(' ').first,
                                            'Indeks UV',
                                          ),
                                        ),
                                        _buildMiniDivider(),
                                        Expanded(
                                          child: _buildMiniMetric(
                                            Icons.umbrella_outlined,
                                            '${_weather.rainProbability}%',
                                            'Hujan',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // CARD 2: PREDIKSI CUACA BEBERAPA WAKTU KE DEPAN (HOURLY — CREAM & FOREST)
                    const Text(
                      'Prediksi Cuaca Beberapa Waktu ke Depan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _weather.hourlyForecast.map((hour) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.warmBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.ink.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  hour.hourTime,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.sage,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    hour.icon,
                                    size: 18,
                                    color: AppColors.forest,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${hour.tempCelsius}°',
                                  style: AppTypography.withTabularFigures(
                                    const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${hour.rainChancePercent}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brush,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    // CARD 3: PERINGATAN & SARAN PERJALANAN (WARM CORAL / SAGE HARMONIS)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isAlertWarning
                            ? AppColors.coralTint
                            : AppColors.sage,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isAlertWarning
                              ? AppColors.terracotta.withValues(alpha: 0.30)
                              : AppColors.sageBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                alert.icon,
                                color: isAlertWarning
                                    ? AppColors.terracotta
                                    : AppColors.forest,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.title,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isAlertWarning
                                        ? AppColors.ink
                                        : AppColors.forest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isAlertWarning
                                      ? AppColors.terracotta
                                      : AppColors.forest,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  alert.severity,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Saran Relevan Perjalanan:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...alert.practicalAdvice.map((advice) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: isAlertWarning
                                          ? AppColors.terracotta
                                          : AppColors.forest,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      advice,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.muted,
                                        height: 1.35,
                                      ),
                                    ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.goldSoft, size: 15),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.withTabularFigures(
            const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.cream.withValues(alpha: 0.72),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniDivider() {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}
