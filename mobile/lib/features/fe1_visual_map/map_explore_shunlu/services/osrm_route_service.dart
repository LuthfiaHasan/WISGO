import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../core/localization/app_locale.dart';

/// Satu langkah panduan arah belokan (Turn-by-Turn) dari jaringan jalan nyata OSRM.
class RoadRouteStep {
  const RoadRouteStep({
    required this.instructionId,
    required this.instructionEn,
    required this.roadName,
    required this.distanceMeters,
    required this.icon,
  });

  final String instructionId;
  final String instructionEn;
  final String roadName;
  final double distanceMeters;
  final IconData icon;

  String get instruction => AppLocale.isEn ? instructionEn : instructionId;

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }
}

/// Satu pilihan rute jalan nyata (Jalur Utama / Jalur Alternatif) hasil OSRM.
class RoadRouteOption {
  const RoadRouteOption({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.steps,
  });

  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final List<RoadRouteStep> steps;

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  String get formattedDuration {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      if (AppLocale.isEn) {
        return m > 0 ? '${h}h ${m}m' : '${h}h';
      }
      return m > 0 ? '$h jam $m mnt' : '$h jam';
    }
    return AppLocale.isEn ? '$durationMinutes min' : '$durationMinutes mnt';
  }
}

/// Layanan routing jalan raya nyata berbasis OSRM (OpenStreetMap — 100% gratis, tanpa API Key, CORS friendly).
class OsrmRouteService {
  OsrmRouteService._();

  static final Map<String, List<RoadRouteOption>> _cache = {};

  static String _cacheKey(LatLng start, LatLng end) =>
      '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}->'
      '${end.latitude.toStringAsFixed(4)},${end.longitude.toStringAsFixed(4)}';

  static List<RoadRouteOption>? getCached(LatLng start, LatLng end) =>
      _cache[_cacheKey(start, end)];

  /// Mengambil rute jalan raya nyata beserta rute alternatif & panduan belokan turn-by-turn.
  static Future<List<RoadRouteOption>?> fetchRoutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final key = _cacheKey(origin, destination);
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=true&alternatives=true',
    );

    try {
      final response = await http
          .get(url, headers: const {'User-Agent': 'WISGO-Sumbar-App/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawRoutes = decoded['routes'] as List<dynamic>?;
      if (rawRoutes == null || rawRoutes.isEmpty) return null;

      final parsed = <RoadRouteOption>[];
      for (final raw in rawRoutes.take(2)) {
        final routeMap = raw as Map<String, dynamic>;
        final geometry = routeMap['geometry'] as Map<String, dynamic>?;
        final coords = geometry?['coordinates'] as List<dynamic>?;
        if (coords == null || coords.length < 2) continue;

        final points = coords.map((c) {
          final pair = c as List<dynamic>;
          return LatLng(
            (pair[1] as num).toDouble(),
            (pair[0] as num).toDouble(),
          );
        }).toList();

        final distKm = ((routeMap['distance'] as num?)?.toDouble() ?? 0) / 1000;
        final durMin =
            (((routeMap['duration'] as num?)?.toDouble() ?? 0) / 60).round().clamp(1, 999);

        final steps = <RoadRouteStep>[];
        final legs = routeMap['legs'] as List<dynamic>? ?? const [];
        for (final leg in legs) {
          final legSteps =
              (leg as Map<String, dynamic>)['steps'] as List<dynamic>? ?? const [];
          for (final rawStep in legSteps) {
            final stepMap = rawStep as Map<String, dynamic>;
            final maneuver =
                stepMap['maneuver'] as Map<String, dynamic>? ?? const {};
            final type = maneuver['type'] as String? ?? 'continue';
            final modifier = maneuver['modifier'] as String? ?? '';
            final rawName = (stepMap['name'] as String? ?? '').trim();
            final cleanName = rawName.split(',').first.trim();
            final distM = (stepMap['distance'] as num?)?.toDouble() ?? 0;

            steps.add(
              _buildStep(
                type: type,
                modifier: modifier,
                roadName: cleanName,
                distanceMeters: distM,
              ),
            );
          }
        }

        parsed.add(
          RoadRouteOption(
            points: points,
            distanceKm: distKm,
            durationMinutes: durMin,
            steps: steps,
          ),
        );
      }

      if (parsed.isEmpty) return null;
      // Urutkan rute tercepat / terpendek di indeks 0
      parsed.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      _cache[key] = parsed;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static RoadRouteStep _buildStep({
    required String type,
    required String modifier,
    required String roadName,
    required double distanceMeters,
  }) {
    final hasRoad = roadName.isNotEmpty;
    final roadSuffixId = hasRoad ? ' ke $roadName' : '';
    final roadSuffixEn = hasRoad ? ' onto $roadName' : '';

    if (type == 'depart') {
      return RoadRouteStep(
        instructionId: hasRoad
            ? 'Mulai perjalanan melalui $roadName'
            : 'Mulai perjalanan dari lokasi Anda',
        instructionEn: hasRoad
            ? 'Start driving via $roadName'
            : 'Start driving from your location',
        roadName: roadName,
        distanceMeters: distanceMeters,
        icon: Icons.my_location_rounded,
      );
    }

    if (type == 'arrive') {
      return RoadRouteStep(
        instructionId: 'Tiba di destinasi wisata tujuan',
        instructionEn: 'Arrive at your destination',
        roadName: roadName,
        distanceMeters: distanceMeters,
        icon: Icons.flag_rounded,
      );
    }

    if (type == 'roundabout' || type == 'rotary') {
      return RoadRouteStep(
        instructionId: 'Masuk bundaran lalu keluar$roadSuffixId',
        instructionEn: 'Enter roundabout and exit$roadSuffixEn',
        roadName: roadName,
        distanceMeters: distanceMeters,
        icon: Icons.roundabout_right_rounded,
      );
    }

    switch (modifier) {
      case 'right':
      case 'sharp right':
        return RoadRouteStep(
          instructionId: 'Belok kanan$roadSuffixId',
          instructionEn: 'Turn right$roadSuffixEn',
          roadName: roadName,
          distanceMeters: distanceMeters,
          icon: Icons.turn_right_rounded,
        );
      case 'slight right':
        return RoadRouteStep(
          instructionId: 'Ambil arah kanan$roadSuffixId',
          instructionEn: 'Keep right$roadSuffixEn',
          roadName: roadName,
          distanceMeters: distanceMeters,
          icon: Icons.turn_slight_right_rounded,
        );
      case 'left':
      case 'sharp left':
        return RoadRouteStep(
          instructionId: 'Belok kiri$roadSuffixId',
          instructionEn: 'Turn left$roadSuffixEn',
          roadName: roadName,
          distanceMeters: distanceMeters,
          icon: Icons.turn_left_rounded,
        );
      case 'slight left':
        return RoadRouteStep(
          instructionId: 'Ambil arah kiri$roadSuffixId',
          instructionEn: 'Keep left$roadSuffixEn',
          roadName: roadName,
          distanceMeters: distanceMeters,
          icon: Icons.turn_slight_left_rounded,
        );
      case 'uturn':
        return RoadRouteStep(
          instructionId: 'Putar balik$roadSuffixId',
          instructionEn: 'Make a U-turn$roadSuffixEn',
          roadName: roadName,
          distanceMeters: distanceMeters,
          icon: Icons.u_turn_left_rounded,
        );
      default:
        return RoadRouteStep(
          instructionId: hasRoad
              ? 'Lurus mengikuti $roadName'
              : 'Lanjutkan lurus mengikuti jalan',
          instructionEn: hasRoad
              ? 'Continue straight on $roadName'
              : 'Continue straight along the road',
          roadName: roadName,
          distanceMeters: distanceMeters,
          icon: Icons.straight_rounded,
        );
    }
  }
}
