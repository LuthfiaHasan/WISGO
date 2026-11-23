import 'package:flutter/material.dart';

/// Model Prediksi Cuaca Jam-per-Jam
class HourlyWeatherForecast {
  final String hourTime;
  final int tempCelsius;
  final String condition;
  final IconData icon;
  final int rainChancePercent;

  const HourlyWeatherForecast({
    required this.hourTime,
    required this.tempCelsius,
    required this.condition,
    required this.icon,
    required this.rainChancePercent,
  });
}

/// Model Peringatan & Perubahan Cuaca Relevan untuk Wisatawan
class WeatherTripAlert {
  final String severity; // 'Aman' | 'Waspada' | 'Peringatan Dini'
  final String title;
  final String description;
  final String validUntil;
  final List<String> practicalAdvice;
  final IconData icon;

  const WeatherTripAlert({
    required this.severity,
    required this.title,
    required this.description,
    required this.validUntil,
    required this.practicalAdvice,
    this.icon = Icons.warning_amber_rounded,
  });
}

/// Model Informasi Cuaca Tingkat Kota/Lokasi Destinasi
class DestinationWeather {
  final String cityName;
  final String destinationName;
  final int currentTemp;
  final int feelsLikeTemp;
  final String currentCondition;
  final IconData conditionIcon;
  final int humidity;
  final int windSpeedKmh;
  final String uvIndex;
  final int rainProbability;
  final String lastUpdatedTime;
  final List<HourlyWeatherForecast> hourlyForecast;
  final WeatherTripAlert tripAlert;

  const DestinationWeather({
    required this.cityName,
    required this.destinationName,
    required this.currentTemp,
    required this.feelsLikeTemp,
    required this.currentCondition,
    required this.conditionIcon,
    required this.humidity,
    required this.windSpeedKmh,
    required this.uvIndex,
    required this.rainProbability,
    required this.lastUpdatedTime,
    required this.hourlyForecast,
    required this.tripAlert,
  });

  /// Factory untuk mendapatkan cuaca berdasarkan destinasi / kota
  static DestinationWeather getForDestination(String destinationOrCity) {
    final lower = destinationOrCity.toLowerCase();
    if (lower.contains('mandeh') || lower.contains('pesisir') || lower.contains('pantai') || lower.contains('padang')) {
      return const DestinationWeather(
        cityName: 'Kab. Pesisir Selatan / Kota Padang',
        destinationName: 'Kawasan Pesisir & Bahari Mandeh',
        currentTemp: 29,
        feelsLikeTemp: 32,
        currentCondition: 'Cerah Berawan',
        conditionIcon: Icons.wb_sunny_rounded,
        humidity: 74,
        windSpeedKmh: 14,
        uvIndex: 'Tinggi (UV 7)',
        rainProbability: 25,
        lastUpdatedTime: '10:45 WIB (Real-time BMKG)',
        hourlyForecast: [
          HourlyWeatherForecast(
            hourTime: '10:00',
            tempCelsius: 29,
            condition: 'Cerah',
            icon: Icons.wb_sunny_rounded,
            rainChancePercent: 10,
          ),
          HourlyWeatherForecast(
            hourTime: '13:00',
            tempCelsius: 31,
            condition: 'Cerah Berawan',
            icon: Icons.wb_cloudy_rounded,
            rainChancePercent: 20,
          ),
          HourlyWeatherForecast(
            hourTime: '16:00',
            tempCelsius: 28,
            condition: 'Hujan Ringan',
            icon: Icons.grain_rounded,
            rainChancePercent: 55,
          ),
          HourlyWeatherForecast(
            hourTime: '19:00',
            tempCelsius: 26,
            condition: 'Berawan Lembut',
            icon: Icons.nightlight_round,
            rainChancePercent: 25,
          ),
        ],
        tripAlert: WeatherTripAlert(
          severity: 'Aman',
          title: 'Kondisi Perairan Tenang & Aman Berlayar',
          description:
              'Gelombang laut teluk berkisar 0.4 - 0.8 meter. Sangat kondusif untuk aktivitas snorkeling, perahu motor wisata, dan island hopping hingga sore hari.',
          validUntil: 'Berlaku s.d 17:30 WIB',
          practicalAdvice: [
            'Gunakan tabir surya SPF 50+ untuk perlindungan dari sengatan terik',
            'Pakai kacamata hitam dan topi pelindung saat di atas perahu terbuka',
            'Selesaikan penyeberangan antarpulau sebelum angin pasang pukul 16:30 WIB',
          ],
        ),
      );
    } else if (lower.contains('bukittinggi') || lower.contains('gadang') || lower.contains('sianok') || lower.contains('agam')) {
      return const DestinationWeather(
        cityName: 'Kota Bukittinggi / Kab. Agam',
        destinationName: 'Ngarai Sianok & Jam Gadang',
        currentTemp: 21,
        feelsLikeTemp: 21,
        currentCondition: 'Sejuk Berkabut Tipis',
        conditionIcon: Icons.cloud_rounded,
        humidity: 86,
        windSpeedKmh: 8,
        uvIndex: 'Sedang (UV 4)',
        rainProbability: 40,
        lastUpdatedTime: '10:45 WIB (Real-time BMKG)',
        hourlyForecast: [
          HourlyWeatherForecast(
            hourTime: '10:00',
            tempCelsius: 21,
            condition: 'Berkabut',
            icon: Icons.cloud_rounded,
            rainChancePercent: 20,
          ),
          HourlyWeatherForecast(
            hourTime: '13:00',
            tempCelsius: 24,
            condition: 'Cerah Berawan',
            icon: Icons.wb_cloudy_rounded,
            rainChancePercent: 35,
          ),
          HourlyWeatherForecast(
            hourTime: '16:00',
            tempCelsius: 20,
            condition: 'Hujan Sedang',
            icon: Icons.grain_rounded,
            rainChancePercent: 70,
          ),
          HourlyWeatherForecast(
            hourTime: '19:00',
            tempCelsius: 18,
            condition: 'Dingin Berembun',
            icon: Icons.air_rounded,
            rainChancePercent: 40,
          ),
        ],
        tripAlert: WeatherTripAlert(
          severity: 'Waspada',
          title: 'Penurunan Jarak Pandang di Lembah Ngarai Sore Hari',
          description:
              'Kabut lembah dan rintik hujan diperkirakan turun mulai pukul 15.30 WIB. Jalan setapak Janjang Koto Gadang berpotensi licin.',
          validUntil: 'Berlaku s.d 18:00 WIB',
          practicalAdvice: [
            'Siapkan jaket tahan angin (windbreaker) dan payung/jas hujan lipat',
            'Gunakan alas kaki dengan sol karet bergrip kuat',
            'Hindari bersandar pada pagar tepi tebing ngarai saat kabut tebal turun',
          ],
        ),
      );
    }

    // Default: Kab. Lima Puluh Kota / Lembah Harau
    return const DestinationWeather(
      cityName: 'Kab. Lima Puluh Kota',
      destinationName: 'Kawasan Lembah Harau & Sarasah',
      currentTemp: 23,
      feelsLikeTemp: 23,
      currentCondition: 'Cerah Berawan di Lembah',
      conditionIcon: Icons.wb_cloudy_rounded,
      humidity: 80,
      windSpeedKmh: 11,
      uvIndex: 'Sedang (UV 5)',
      rainProbability: 35,
      lastUpdatedTime: '10:45 WIB (Real-time BMKG)',
      hourlyForecast: [
        HourlyWeatherForecast(
          hourTime: '10:00',
          tempCelsius: 23,
          condition: 'Cerah Berawan',
          icon: Icons.wb_cloudy_rounded,
          rainChancePercent: 15,
        ),
        HourlyWeatherForecast(
          hourTime: '13:00',
          tempCelsius: 26,
          condition: 'Cerah Hangat',
          icon: Icons.wb_sunny_rounded,
          rainChancePercent: 25,
        ),
        HourlyWeatherForecast(
          hourTime: '16:00',
          tempCelsius: 22,
          condition: 'Potensi Hujan Rintik',
          icon: Icons.grain_rounded,
          rainChancePercent: 65,
        ),
        HourlyWeatherForecast(
          hourTime: '19:00',
          tempCelsius: 19,
          condition: 'Sejuk Alami',
          icon: Icons.nightlight_round,
          rainChancePercent: 30,
        ),
      ],
      tripAlert: WeatherTripAlert(
        severity: 'Waspada',
        title: 'Perubahan Cuaca: Potensi Hujan Petir di Kawasan Tebing',
        description:
            'Awan cumulonimbus terpantau bergerak dari arah barat daya. Potensi kenaikan debit air terjun Sarasah pada rentang waktu 15:00 - 17:30 WIB.',
        validUntil: 'Berlaku s.d 17:30 WIB',
        practicalAdvice: [
          'Selesaikan aktivitas berenang di kolam bawah air terjun sebelum pukul 14:30 WIB',
          'Segera jauhi aliran sungai utama apabila warna air berubah menjadi keruh kecokelatan',
          'Amankan perangkat elektronik di dry bag kedap air',
        ],
      ),
    );
  }
}
