import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/weather_model.dart';

/// Modal Lembar Informasi Cuaca Destinasi Real-Time & Peringatan Perjalanan
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
  }

  void _handleRefreshWeather() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
      _lastUpdatedTime = DateTime.now();
      _weather = DestinationWeather.getForDestination(widget.destinationName);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Data cuaca ${_weather.destinationName} berhasil diperbarui!',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.warmBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0369A1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cloudy_snowing,
                        color: Color(0xFF0369A1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Cuaca Destinasi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          _weather.cityName,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ink.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD 1: SUHU & KONDISI CUACA SAAT INI (REAL-TIME)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0369A1).withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Real-time update badge & refresh button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ADE80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pembaruan: ${_lastUpdatedTime.hour.toString().padLeft(2, '0')}:${_lastUpdatedTime.minute.toString().padLeft(2, '0')} WIB',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: _isRefreshing ? null : _handleRefreshWeather,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _isRefreshing
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.refresh_rounded,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Perbarui',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _weather.destinationName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_weather.currentTemp}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      '°C',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _weather.currentCondition,
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Terasa seperti ${_weather.feelsLikeTemp}°C',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _weather.conditionIcon,
                              color: const Color(0xFFFDE047),
                              size: 72,
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Sub-metrics (Kelembaban, Angin, UV, Peluang Hujan)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniMetric(
                                Icons.water_drop_rounded,
                                '${_weather.humidity}%',
                                'Kelembaban',
                              ),
                              _buildMiniDivider(),
                              _buildMiniMetric(
                                Icons.air_rounded,
                                '${_weather.windSpeedKmh} km/j',
                                'Kecepatan Angin',
                              ),
                              _buildMiniDivider(),
                              _buildMiniMetric(
                                Icons.wb_sunny_rounded,
                                _weather.uvIndex.split(' ').first,
                                'Indeks UV',
                              ),
                              _buildMiniDivider(),
                              _buildMiniMetric(
                                Icons.beach_access_rounded,
                                '${_weather.rainProbability}%',
                                'Peluang Hujan',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // CARD 2: PREDIKSI CUACA BEBERAPA WAKTU KE DEPAN (HOURLY)
                  const Text(
                    'Prediksi Cuaca Beberapa Waktu ke Depan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.warmBorder),
                          ),
                          child: Column(
                            children: [
                              Text(
                                hour.hourTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                hour.icon,
                                size: 24,
                                color: const Color(0xFF0369A1),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${hour.tempCelsius}°',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${hour.rainChancePercent}%',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // CARD 3: PERINGATAN & PERUBAHAN CUACA RELEVAN BAGI PERJALANAN
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAlertWarning
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isAlertWarning
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFBBF7D0),
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
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alert.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isAlertWarning
                                      ? const Color(0xFF991B1B)
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isAlertWarning
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                alert.severity,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.description,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isAlertWarning
                                ? const Color(0xFF7F1D1D)
                                : const Color(0xFF14532D),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Saran Relevan Perjalanan:',
                          style: TextStyle(
                            fontSize: 11,
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
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    advice,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.ink.withValues(alpha: 0.8),
                                      height: 1.3,
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

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniDivider() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}
