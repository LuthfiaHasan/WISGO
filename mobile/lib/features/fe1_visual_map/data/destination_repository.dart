import 'dart:convert';
import 'package:http/http.dart' as http;
import '../map_explore_shunlu/widgets/sumbar_real_map_widget.dart';
import '../models/destination_model.dart';

/// Repository Destinasi Wisata Sumatera Barat (FE-1)
/// Mendukung Mock Data (untuk pengembangan mandiri) & integrasi REST API BE-1 (`/api/v1/destinations`)
class DestinationRepository {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  /// Mengambil semua destinasi (terhubung ke BE-1 dengan fallback otomatis ke Mock)
  Future<List<DestinationModel>> getDestinations({
    String category = 'Semua',
    String searchQuery = '',
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != 'Semua') queryParams['category'] = category;
      if (searchQuery.trim().isNotEmpty) queryParams['search'] = searchQuery.trim();

      final uri = Uri.parse('$baseUrl/destinations').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List)
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : <dynamic>[]);

        if (list.isNotEmpty) {
          final parsed = list
              .map((item) => DestinationModel.fromJson(item as Map<String, dynamic>))
              .toList();
          SumbarMapRegistry.instance.syncFromDestinationModels(parsed);
          return parsed;
        }
      }
    } catch (_) {
      // Fallback mulus ke Mock Data jika backend belum online
    }

    // Filter dari Mock Data lokal
    return _mockDestinations.where((dest) {
      final matchCategory = category == 'Semua' ||
          dest.category.toLowerCase().contains(category.toLowerCase()) ||
          dest.categoryId.toLowerCase().contains(category.toLowerCase());
      final query = searchQuery.trim().toLowerCase();
      final matchSearch = query.isEmpty ||
          dest.name.toLowerCase().contains(query) ||
          dest.cityRegency.toLowerCase().contains(query) ||
          dest.description.toLowerCase().contains(query);
      return matchCategory && matchSearch;
    }).toList();
  }

  /// Mengambil detail satu destinasi berdasarkan ID (`GET /api/v1/destinations/:id`)
  Future<DestinationModel?> getDestinationById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/destinations/$id'))
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data = (decoded is Map<String, dynamic> &&
                decoded.containsKey('data') &&
                decoded['data'] is Map<String, dynamic>)
            ? decoded['data'] as Map<String, dynamic>
            : (decoded is Map<String, dynamic> ? decoded : <String, dynamic>{});

        if (data.isNotEmpty) {
          return DestinationModel.fromJson(data);
        }
      }
    } catch (_) {
      // Fallback ke Mock Data
    }

    try {
      return _mockDestinations.firstWhere((d) => d.id == id);
    } catch (_) {
      return _mockDestinations.isNotEmpty ? _mockDestinations.first : null;
    }
  }

  /// Mencocokkan ID destinasi lokal (Beranda) dengan ID seeder BE-1 (`/scenes-360`)
  static String resolveScenes360BackendId(DestinationModel dest) {
    final id = dest.id.toLowerCase();
    final name = dest.name.toLowerCase();
    if (id == 'dest-001' || id.contains('harau') || name.contains('harau')) {
      return 'dest-001';
    }
    if (id == 'dest-002' ||
        id.contains('jam-gadang') ||
        name.contains('jam gadang') ||
        name.contains('ngarai sianok')) {
      return 'dest-002';
    }
    if (id == 'dest-005' ||
        id.contains('pagaruyung') ||
        name.contains('pagaruyung')) {
      return 'dest-005';
    }
    return dest.id;
  }

  /// Mengambil daftar destinasi langsung dari BE-1 beserta status koneksi
  Future<({List<DestinationModel> items, bool fromBackend})>
      fetchLiveDestinations() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/destinations'))
          .timeout(const Duration(milliseconds: 2200));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List)
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : <dynamic>[]);

        if (list.isNotEmpty) {
          final parsed = list
              .map(
                (item) =>
                    DestinationModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          return (items: parsed, fromBackend: true);
        }
      }
    } catch (_) {
      // Fallback mulus jika BE-1 tidak sedang berjalan
    }
    return (items: List<DestinationModel>.from(_mockDestinations), fromBackend: false);
  }

  /// Mengambil scene 360° langsung dari BE-1 (`GET /api/v1/destinations/:id/scenes-360`)
  Future<({List<Scene360Model> scenes, bool fromBackend})> fetchLiveScenes360(
    String destinationId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/destinations/$destinationId/scenes-360'))
          .timeout(const Duration(milliseconds: 2200));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> list = const [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['scenes_360'] is List) {
            list = decoded['scenes_360'] as List<dynamic>;
          } else if (decoded['data'] is List) {
            list = decoded['data'] as List<dynamic>;
          } else if (decoded['data'] is Map<String, dynamic> &&
              (decoded['data'] as Map<String, dynamic>)['scenes_360'] is List) {
            list = (decoded['data'] as Map<String, dynamic>)['scenes_360']
                as List<dynamic>;
          }
        }
        if (list.isNotEmpty) {
          return (
            scenes: list
                .map(
                  (item) =>
                      Scene360Model.fromJson(item as Map<String, dynamic>),
                )
                .toList(),
            fromBackend: true,
          );
        }
      }
    } catch (_) {}

    return (scenes: const <Scene360Model>[], fromBackend: false);
  }

  /// Mengambil scene 360° untuk destinasi (`GET /api/v1/destinations/:id/scenes-360`)
  Future<List<Scene360Model>> getScenes360(String destinationId) async {
    final res = await fetchLiveScenes360(destinationId);
    return res.scenes;
  }

  /// Mengambil 4 pin hotspot pada kanvas 360° (`GET /api/v1/scenes-360/:id/hotspots`)
  Future<List<Hotspot360Model>> getHotspots(String sceneId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/scenes-360/$sceneId/hotspots'))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> list = const [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['hotspots'] is List) {
            list = decoded['hotspots'] as List<dynamic>;
          } else if (decoded['data'] is List) {
            list = decoded['data'] as List<dynamic>;
          }
        }
        if (list.isNotEmpty) {
          return list
              .map((item) => Hotspot360Model.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    // Fallback hotspots
    for (final dest in _mockDestinations) {
      for (final scn in dest.scenes360) {
        if (scn.id == sceneId && scn.hotspots.isNotEmpty) {
          return scn.hotspots;
        }
      }
    }
    return const [];
  }

  /// Mengambil data GeoJSON Peta Mikro pejalan kaki (`GET /api/v1/destinations/:id/micro-map`)
  Future<Map<String, dynamic>> getMicroMap(String destinationId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/destinations/$destinationId/micro-map'))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded;
        }
      }
    } catch (_) {}

    // Fallback GeoJSON mikro pejalan kaki Lembah Harau
    return {
      'destination_id': destinationId,
      'name': 'Peta Mikro Pejalan Kaki Lembah Harau',
      'trail_difficulty': 'Mudah (Datar)',
      'total_length_km': 1.8,
      'zones': [
        {'name': 'Pintu Gerbang & Loket Resmi', 'lat': -0.1030, 'lng': 100.6710, 'type': 'gate'},
        {'name': 'Sarasah Bunta (Air Terjun Utama)', 'lat': -0.1015, 'lng': 100.6740, 'type': 'waterfall'},
        {'name': 'Spot Tebing Granit Eco-Trek', 'lat': -0.1008, 'lng': 100.6755, 'type': 'viewpoint'},
        {'name': 'Pondok Saluang & Suvenir Nagari', 'lat': -0.1025, 'lng': 100.6725, 'type': 'culture'},
      ],
      'path_coordinates': [
        [-0.1030, 100.6710],
        [-0.1025, 100.6725],
        [-0.1015, 100.6740],
        [-0.1008, 100.6755],
      ],
    };
  }

  /// Mengambil bundel offline untuk Mode Zero-Signal (`GET /api/v1/destinations/:id/offline-bundle`)
  Future<Map<String, dynamic>> getOfflineBundle(String destinationId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/destinations/$destinationId/offline-bundle'))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}

    final dest = await getDestinationById(destinationId);
    final micro = await getMicroMap(destinationId);
    return {
      'destination': dest?.name ?? 'Destinasi Offline',
      'synced_at': DateTime.now().toIso8601String(),
      'destination_data': dest != null ? {
        'id': dest.id,
        'name': dest.name,
        'category': dest.category,
        'city_regency': dest.cityRegency,
        'description': dest.description,
        'distance_km': dest.distanceKm,
        'travel_time': dest.travelTime,
        'entry_fee': dest.entryFee,
      } : null,
      'micro_map': micro,
    };
  }

  /// Mengambil alert peringatan dini jalur rawan (`GET /api/v1/spatial/hazards` atau `/api/v1/hazards/active`)
  Future<List<HazardAlertModel>> getHazardAlerts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/spatial/hazards'))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List)
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : <dynamic>[]);
        if (list.isNotEmpty) {
          return list.map((item) => HazardAlertModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}

    return _mockHazardAlerts;
  }

  /// Mengambil master kontak darurat resmi langsung dari Backend BE-1 (`GET /api/v1/spatial/emergency-contacts`)
  Future<List<EmergencyContactModel>> getEmergencyContacts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/spatial/emergency-contacts'))
          .timeout(const Duration(milliseconds: 3000));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['contacts'] is List) {
          final list = decoded['contacts'] as List<dynamic>;
          if (list.isNotEmpty) {
            return list
                .map((item) => EmergencyContactModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }
    } catch (_) {}

    return _mockEmergencyContacts;
  }

  /// Mengirim sinyal darurat SOS GPS ke Posko SAR & Satgas Nagari (`POST /api/v1/hazards/sos`)
  Future<String?> sendSosSignal(SOSSignalModel signal) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/hazards/sos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(signal.toJson()),
          )
          .timeout(const Duration(milliseconds: 3000));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          return decoded['message'] as String;
        }
        return 'Sinyal darurat berhasil diterima oleh server backend!';
      }
    } catch (_) {}
    return null;
  }

  /// Mengambil 5 Master Categories resmi dari database/backend (`GET /api/v1/categories`)
  Future<List<Map<String, dynamic>>> getMasterCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/categories'))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List)
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : <dynamic>[]);
        if (list.isNotEmpty) {
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
    } catch (_) {}

    return const [
      {'id': 'cat-alam-geopark', 'name': 'Alam & Geopark', 'slug': 'alam-geopark'},
      {'id': 'cat-budaya-nagari', 'name': 'Budaya & Nagari', 'slug': 'budaya-nagari'},
      {'id': 'cat-hidden-gem', 'name': 'Hidden Gem', 'slug': 'hidden-gem'},
      {'id': 'cat-religi', 'name': 'Religi', 'slug': 'religi'},
      {'id': 'cat-kuliner', 'name': 'Kuliner', 'slug': 'kuliner'},
    ];
  }

  /// Mengambil frasa Kamus Saku Audio Minang (`GET /api/v1/culture/audio-phrases`)
  Future<List<MinangPhraseModel>> getCulturePhrases({String category = 'Semua'}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/culture/audio-phrases'))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List)
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : <dynamic>[]);
        if (list.isNotEmpty) {
          final phrases = list.map((item) => MinangPhraseModel.fromJson(item as Map<String, dynamic>)).toList();
          if (category == 'Semua') return phrases;
          return phrases.where((p) => p.category.toLowerCase().contains(category.toLowerCase())).toList();
        }
      }
    } catch (_) {}

    if (category == 'Semua') return _mockMinangPhrases;
    return _mockMinangPhrases.where((p) => p.category.toLowerCase().contains(category.toLowerCase())).toList();
  }

  /// Mengambil agenda Kalender Budaya & Hari Pakan Nagari
  Future<List<CulturalEventModel>> getCulturalEvents() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/culture/events'))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> list = (decoded is List)
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List<dynamic>
                : <dynamic>[]);
        if (list.isNotEmpty) {
          return list.map((item) => CulturalEventModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}

    return _mockCulturalEvents;
  }

  /// Landmark Gunung untuk Fitur Kompas Visual (Pilar 2 — Minggu 4)
  List<MountainLandmarkModel> getMountainLandmarks() {
    return const [
      MountainLandmarkModel(
        name: 'Gunung Marapi',
        elevationMdpl: 2891,
        latitude: -0.3808,
        longitude: 100.4728,
        regency: 'Kab. Tanah Datar & Agam',
        defaultBearingDeg: 45.0,
        description: 'Gunung berapi paling aktif di Sumatera Barat, pusat asal-usul kultural Nagari Pariangan.',
      ),
      MountainLandmarkModel(
        name: 'Gunung Singgalang',
        elevationMdpl: 2877,
        latitude: -0.3922,
        longitude: 100.3325,
        regency: 'Kab. Tanah Datar & Agam',
        defaultBearingDeg: 335.0,
        description: 'Memiliki Telaga Dewi di puncaknya dan jalur hutan lumut eksotis.',
      ),
      MountainLandmarkModel(
        name: 'Gunung Tandikat',
        elevationMdpl: 2438,
        latitude: -0.4328,
        longitude: 100.3167,
        regency: 'Kab. Padang Pariaman',
        defaultBearingDeg: 290.0,
        description: 'Puncak kembar Singgalang dengan kawah megah dan panorama ke arah pesisir barat.',
      ),
      MountainLandmarkModel(
        name: 'Gunung Sago',
        elevationMdpl: 2271,
        latitude: -0.3278,
        longitude: 100.6694,
        regency: 'Kab. Lima Puluh Kota',
        defaultBearingDeg: 80.0,
        description: 'Membentengi kawasan Payakumbuh dan lembah perkebunan nagari.',
      ),
      MountainLandmarkModel(
        name: 'Gunung Talang',
        elevationMdpl: 2597,
        latitude: -0.9778,
        longitude: 100.6789,
        regency: 'Kab. Solok',
        defaultBearingDeg: 165.0,
        description: 'Dikelilingi hamparan kebun teh Danau Kembar (Danau Diatas & Danau Dibawah).',
      ),
    ];
  }

  /// Katalog Pakaian Adat Minangkabau (Pilar 1 — Minggu 4)
  List<TraditionalAttireModel> getTraditionalAttires() {
    return const [
      TraditionalAttireModel(
        id: 'attire-bundo',
        name: 'Baju Kurung Basiba & Tengkuluk Tanduk',
        userType: 'Bundo Kanduang (Wanita Adat)',
        regency: 'Darek (Tanah Datar, Agam, 50 Kota)',
        philosophy: 'Bentuk tanduk kerbau melambangkan ketegasan pemimpin rumah gadang dan keanggunan perempuan Minang dalam musyawarah adat.',
        imageUrl: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?auto=format&fit=crop&w=700&q=80',
        elements: ['Tengkuluk Tanduk Balenggek', 'Baju Kurung Basiba Beludru Emas', 'Salempang Songket Silungkang', 'Kodek Sarung Songket Tabur'],
      ),
      TraditionalAttireModel(
        id: 'attire-marapulai',
        name: 'Pakaian Marapulai & Saluak Deta',
        userType: 'Marapulai (Pengantin Pria)',
        regency: 'Seluruh Luhak Nan Tigo',
        philosophy: 'Saluak deta berkerut-kerut melambangkan lilitan akal budi dan musyawarah mufakat seorang pemimpin keluarga baru.',
        imageUrl: 'https://images.unsplash.com/photo-1583391733975-4752662c64df?auto=format&fit=crop&w=700&q=80',
        elements: ['Destar / Saluak Bertatah Emas', 'Baju Roki / Jas Beludru Sikoci', 'Kain Samping Songket Pandai Sikek', 'Keris Sandang & Tali Ameh'],
      ),
      TraditionalAttireModel(
        id: 'attire-penghulu',
        name: 'Baju Gadang Kebesaran Datuak Penghulu',
        userType: 'Penghulu / Ninik Mamak',
        regency: 'Nagari Adat Luhak Nan Tigo',
        philosophy: 'Baju hitam longgar mencerminkan dada lapang tempat menyimpan segala rahasia nagari serta sikap adil tak berpihak.',
        imageUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=700&q=80',
        elements: ['Deta Saluak Hitam', 'Baju Hitam Longgar Tak Berkantong', 'Celana Sarawa Gadang', 'Sesamping Songket & Cawek', 'Tungkek / Tongkat Adat'],
      ),
      TraditionalAttireModel(
        id: 'attire-suntiang',
        name: 'Suntiang Anak Daro Minangkabau',
        userType: 'Anak Daro (Pengantin Wanita)',
        regency: 'Pesisir & Darek',
        philosophy: 'Mahkota bertingkat 7–11 lapis seberat 3–5 kg sebagai lambang kesiapan memikul tanggung jawab besar sebagai ibu dan ratu rumah tangga.',
        imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=700&q=80',
        elements: ['Suntiang Gadang Jurai 11', 'Baju Beludru Tabur Emas', 'Kalung Maniak & Gelang Garobak', 'Kain Songket Tenun Tangan Asli'],
      ),
    ];
  }

  static const List<HazardAlertModel> _mockHazardAlerts = [
    HazardAlertModel(
      id: 'hz-001',
      corridorCode: 'SITINJAU-LAUIK',
      location: 'Sitinjau Lauik (Padang - Solok)',
      roadSegment: 'Km 14 - Km 18 Tikungan Panorama 1 & 2',
      cityRegency: 'Kota Padang & Kab. Solok',
      latitude: -0.9468,
      longitude: 100.5182,
      severity: 'Waspada',
      hazardType: 'Tanjakan Curam 24° & Kabut Tebal',
      weatherStatus: 'Hujan Gerimis Berkabut',
      slopeGradientDeg: 24,
      message: 'Antrean truk bermuatan di tanjakan panorama 1. Aspal licin akibat hujan rintik. Jaga jarak minimal 20 meter.',
      detourRoute: 'Alternatif: Jalur Padang Panjang - Singkarak (Detour: +35 mnt).',
      nearestRescuePost: 'Posko Gabungan Damkar & SAR Padang',
      emergencyContact: '08116606113 (Damkar Padang)',
    ),
    HazardAlertModel(
      id: 'hz-002',
      corridorCode: 'LEMBAH-ANAI',
      location: 'Lembah Anai (Padang Panjang)',
      roadSegment: 'Jl. Raya Padang - Bukittinggi Km 64',
      cityRegency: 'Kab. Padang Pariaman & Tanah Datar',
      latitude: -0.4855,
      longitude: 100.3472,
      severity: 'Siaga',
      hazardType: 'Debit Air Terjun Meningkat & Rawan Longsor Tebing',
      weatherStatus: 'Hujan Hulu Deras',
      slopeGradientDeg: 18,
      message: 'Aliran sungai Batang Anai mendekati bibir aspal. Sistem buka-tutup bergantian di pos air terjun.',
      detourRoute: 'Alternatif: Sicincin - Malalak - Bukittinggi (Detour: +40 mnt).',
      nearestRescuePost: 'Posko Siaga BPBD Padang Pariaman',
      emergencyContact: '08116662114 (BPBD Padang Pariaman)',
    ),
    HazardAlertModel(
      id: 'hz-003',
      corridorCode: 'KELOK-9',
      location: 'Kelok 9 (Payakumbuh - Riau)',
      roadSegment: 'Flyover Kelok 9 Km 28 - 32',
      cityRegency: 'Kab. Lima Puluh Kota',
      latitude: -0.0750,
      longitude: 100.7020,
      severity: 'Normal',
      hazardType: 'Lalu Lintas Wisatawan Ramai Lancar',
      weatherStatus: 'Cerah Berawan',
      slopeGradientDeg: 12,
      message: 'Jalur jembatan layang lancar dua arah. Dilarang parkir di atas flyover untuk berfoto.',
      detourRoute: 'Tidak ada pengalihan arus.',
      nearestRescuePost: 'Posko Siaga Bencana BPBD Sumbar',
      emergencyContact: '(0751) 890721 (BPBD Sumbar)',
    ),
    HazardAlertModel(
      id: 'hz-004',
      corridorCode: 'KELOK-44',
      location: 'Kelok 44 (Danau Maninjau)',
      roadSegment: 'Nagari Maninjau - Matur Km 1 s/d 44',
      cityRegency: 'Kab. Agam & Bukittinggi',
      latitude: -0.3012,
      longitude: 100.2245,
      severity: 'Waspada',
      hazardType: '44 Tikungan Sempit 180° & Kawanan Kera Liar',
      weatherStatus: 'Kabut Sore Tipis',
      slopeGradientDeg: 20,
      message: 'Gunakan gigi rendah saat menurun. Bunyikan klakson di tikungan tanpa cermin cembung.',
      detourRoute: 'Alternatif: Jalur Pariaman - Lubuk Basung.',
      nearestRescuePost: 'Posko Siaga Damkar & Penyelamatan',
      emergencyContact: '085355157883 (Damkar Bukittinggi)',
    ),
  ];

  static const List<EmergencyContactModel> _mockEmergencyContacts = [
    EmergencyContactModel(
      id: 'emg-001',
      corridorCode: 'PROV-SUMBAR',
      agencyType: 'BPBD',
      agencyName: 'BPBD Sumatera Barat',
      phoneNumber: '(0751) 890721',
      city: 'Provinsi Sumatera Barat',
      latitude: -0.9471,
      longitude: 100.3543,
    ),
    EmergencyContactModel(
      id: 'emg-002',
      corridorCode: 'PROV-SUMBAR',
      agencyType: 'PMI',
      agencyName: 'PMI Sumatera Barat',
      phoneNumber: '(0751) 27882',
      city: 'Kota Padang',
      latitude: -0.9324,
      longitude: 100.3621,
    ),
    EmergencyContactModel(
      id: 'emg-003',
      corridorCode: 'SITINJAU-LAUIK',
      agencyType: 'Damkar',
      agencyName: 'Damkar Kota Padang',
      phoneNumber: '08116606113',
      city: 'Kota Padang',
      latitude: -0.9512,
      longitude: 100.3705,
    ),
    EmergencyContactModel(
      id: 'emg-004',
      corridorCode: 'LEMBAH-ANAI',
      agencyType: 'BPBD',
      agencyName: 'BPBD Padang Pariaman',
      phoneNumber: '08116662114',
      city: 'Kab. Padang Pariaman',
      latitude: -0.6272,
      longitude: 100.2811,
    ),
    EmergencyContactModel(
      id: 'emg-005',
      corridorCode: 'MANDEH-PESSEL',
      agencyType: 'BPBD',
      agencyName: 'BPBD Pesisir Selatan',
      phoneNumber: '085269380950',
      city: 'Kab. Pesisir Selatan',
      latitude: -1.3502,
      longitude: 100.5694,
    ),
    EmergencyContactModel(
      id: 'emg-006',
      corridorCode: 'MALALAK-AGAM',
      agencyType: 'Damkar',
      agencyName: 'Damkar Bukittinggi',
      phoneNumber: '085355157883',
      city: 'Kota Bukittinggi',
      latitude: -0.3055,
      longitude: 100.3692,
    ),
  ];

  static const List<MinangPhraseModel> _mockMinangPhrases = [
    MinangPhraseModel(
      id: 'phr-1',
      category: 'Pasar & Belanja',
      minangText: 'Bara haragonyo ko, Uni / Uda?',
      indonesianText: 'Berapa harganya ini, Kakak?',
      englishText: 'How much does this cost, Sister / Brother?',
      phoneticGuide: 'ba-ra ha-ra-go-nyo ko, u-ni / u-da?',
      usageContextTip: 'Berbelanja di Pasar Atas / Los Lambuang Bukittinggi',
      dialectNote: 'Darek (Bukittinggi & Payakumbuh)',
      politenessLevel: 'Kato Mandata (Sesama Sebaya)',
    ),
    MinangPhraseModel(
      id: 'phr-2',
      category: 'Kuliner',
      minangText: 'Tambuah ciek, Uni!',
      indonesianText: 'Tambah satu porsi nasi/lauk lagi, Kak!',
      englishText: 'One more serving of rice/dish please, Sister!',
      phoneticGuide: 'tam-bu-ah cie-k, u-ni!',
      usageContextTip: 'Saat bersantap di Rumah Makan Padang / Los Lambuang Kapau',
      dialectNote: 'Umum Minangkabau',
      politenessLevel: 'Kato Mandata (Akrab Santun)',
    ),
    MinangPhraseModel(
      id: 'phr-3',
      category: 'Sapaan Nagari',
      minangText: 'Tarimo kasih banyak, sanak.',
      indonesianText: 'Terima kasih banyak, saudara/sahabat.',
      englishText: 'Thank you very much, my friend.',
      phoneticGuide: 'ta-ri-mo ka-sih ba-nyak, sa-nak',
      usageContextTip: 'Ucapan terima kasih santun kepada warga nagari & pemandu',
      dialectNote: 'Luhak Nan Tigo',
      politenessLevel: 'Kato Malereang (Sangat Menghormati)',
    ),
    MinangPhraseModel(
      id: 'phr-4',
      category: 'Arah & Navigasi',
      minangText: 'Kama jalan ka Sarasah Bunta, Uda?',
      indonesianText: 'Ke mana arah jalan menuju Air Terjun Sarasah Bunta, Kak?',
      englishText: 'Which way to Sarasah Bunta Waterfall, Brother?',
      phoneticGuide: 'ka-ma ja-lan ka sa-ra-sah bun-ta, u-da?',
      usageContextTip: 'Menanyakan rute setapak pejalan kaki di Lembah Harau',
      dialectNote: 'Luhak 50 Kota',
      politenessLevel: 'Kato Mandaki (Kepada yang Dituakan)',
    ),
    MinangPhraseModel(
      id: 'phr-5',
      category: 'Kuliner',
      minangText: 'Jan padeh bana yo, Da.',
      indonesianText: 'Jangan terlalu pedas ya, Kak.',
      englishText: 'Please do not make it too spicy, Brother.',
      phoneticGuide: 'jan pa-deh ba-na yo, da',
      usageContextTip: 'Memesan dendeng lambok atau gulai dengan kepedasan sedang',
      dialectNote: 'Padang Pesisir',
      politenessLevel: 'Kato Mandata',
    ),
    MinangPhraseModel(
      id: 'phr-6',
      category: 'Pasar & Belanja',
      minangText: 'Buliah kurang saketek, Mak?',
      indonesianText: 'Boleh tawar sedikit harganya, Ibu?',
      englishText: 'Could I get a small discount, Ma\'am?',
      phoneticGuide: 'bu-liah ku-rang sa-ke-tek, mak?',
      usageContextTip: 'Tawar-menawar santun untuk suvenir songket atau kerupuk sanjai',
      dialectNote: 'Darek & Pesisir',
      politenessLevel: 'Kato Mandaki (Kepada Ibu/Pedagang Senior)',
    ),
    MinangPhraseModel(
      id: 'phr-7',
      category: 'Sapaan Nagari',
      minangText: 'Salamaik tibo di Ranah Minang, sanak!',
      indonesianText: 'Selamat datang di Tanah Minangkabau, sahabat!',
      englishText: 'Welcome to Minangkabau Land, friend!',
      phoneticGuide: 'sa-la-maik ti-bo di ra-nah mi-nang, sa-nak!',
      usageContextTip: 'Ucapan salam pembuka saat tiba di desa wisata / homestay',
      dialectNote: 'Resmi Ranah Minang',
      politenessLevel: 'Kato Malereang',
    ),
    MinangPhraseModel(
      id: 'phr-8',
      category: 'Arah & Navigasi',
      minangText: 'Lai jauah lai ka posko pemandu nagari?',
      indonesianText: 'Apakah masih jauh menuju posko pemandu nagari?',
      englishText: 'Is it still far to the village guide post?',
      phoneticGuide: 'lai jau-ah lai ka pos-ko pe-man-du na-ga-ri?',
      usageContextTip: 'Mengecek jarak trekking di kawasan hutan Lubuk Nyarai / Harau',
      dialectNote: 'Padang Pariaman',
      politenessLevel: 'Kato Mandata',
    ),
  ];

  static const List<CulturalEventModel> _mockCulturalEvents = [
    CulturalEventModel(
      id: 'evt-1',
      title: 'Alek Nagari Pacu Jawi (Balap Sapi Sawah Lumpur)',
      eventType: 'Tradisi Adat Panen',
      nagariLocation: 'Nagari Pariangan & Nagari Sungai Tarab',
      cityRegency: 'Kab. Tanah Datar',
      scheduleRule: 'Setiap Sabtu Sore Bergilir antar Nagari',
      badge: 'Warisan Budaya Takbenda',
      description: 'Atraksi joki memacu sepasang sapi di sawah berlumpur tanpa pecut, simbol keselarasan manusia dengan alam pasca panen.',
    ),
    CulturalEventModel(
      id: 'evt-2',
      title: 'Festival Budaya Hoyak Tabuik Piaman',
      eventType: 'Festival Akbar Pesisir',
      nagariLocation: 'Pantai Gandoriah & Muaro',
      cityRegency: 'Kota Pariaman',
      scheduleRule: '1–10 Muharram (Puncak: 10 Muharram)',
      badge: 'Karisma Event Nusantara',
      description: 'Upacara budaya melarung sepasang menara Tabuik megah setinggi 12 meter ke Samudra Hindia saat terbenam matahari.',
    ),
    CulturalEventModel(
      id: 'evt-3',
      title: 'Hari Pakan (Pasar Tradisional Nagari Minang)',
      eventType: 'Pasar Rakyat & Sentra Kuliner',
      nagariLocation: 'Pakan Sinayan & Pakan Koto Baru',
      cityRegency: 'Kab. Agam & Tanah Datar',
      scheduleRule: 'Setiap Senin & Kamis Pagi (06:00 - 12:00)',
      badge: 'Kuliner & UMKM Nagari',
      description: 'Pusat bertemunya petani nagari menjual bika talam, lamang tapai, beras organik pulut, dan hasil bumi segar asli gunung.',
    ),
    CulturalEventModel(
      id: 'evt-4',
      title: 'Pawai Alek Batagak Gala & Randai Malam',
      eventType: 'Upacara Pengangkatan Gelar Datuak',
      nagariLocation: 'Balai Adat Nagari Tuo Pariangan',
      cityRegency: 'Kab. Tanah Datar',
      scheduleRule: 'Musiman (Saat Pelantikan Penghulu Nagari)',
      badge: 'Hukum Adat & Seni',
      description: 'Pementasan teater rakyat Randai melingkar dengan dendang Saluang dan arak-arakan Bundo Kanduang menjunjung jamba.',
    ),
  ];

  static const List<DestinationModel> _mockDestinations = [
    DestinationModel(
      id: 'dest-001',
      name: 'Lembah Harau',
      category: 'Alam & Geopark',
      categoryId: 'cat-alam-geopark',
      cityRegency: 'Kab. Lima Puluh Kota',
      description:
          'Lembah subur yang dikelilingi tebing granit terjal setinggi 100–500 meter dengan deretan air terjun alami (Sarasah Bunta, Akar Berayun) dan hamparan sawah Nagari Harau.',
      latitude: -0.1023,
      longitude: 100.6728,
      coverImage:
          'https://images.unsplash.com/photo-1596401057633-54a8fe8ef647?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Sedang',
      distanceKm: '124 km',
      travelTime: '2j 45m',
      entryFee: 'Rp 10.000',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-001',
        destinationId: 'dest-001',
        vehicleAccess: 'Mobil OK',
        trekkingLevel: 'Mudah (Datar)',
        cellularSignal: 'Blank Spot (Zero-Signal)',
        facilities: 'Ada Toilet & Musala',
        guideNeed: 'Bisa Mandiri',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-001',
          destinationId: 'dest-001',
          content:
              'Unduh Paket Offline sebelum masuk kawasan tebing dalam karena sinyal seluler melemah di titik air terjun Sarasah.',
          isImportant: true,
        ),
        LocalTipModel(
          id: 'tip-002',
          destinationId: 'dest-001',
          content:
              'Jaga ketenangan di area pesawahan warga Nagari dan bawa kembali botol plastik Anda.',
          isImportant: false,
        ),
      ],
      tariffs: [
        OfficialTariffModel(
          id: 'trf-001',
          destinationId: 'dest-001',
          itemName: 'Tiket Masuk Dewasa',
          price: 10000,
          unit: 'per orang',
          regulationRef: 'Perda Kab. 50 Kota No. 4/2023',
        ),
        OfficialTariffModel(
          id: 'trf-002',
          destinationId: 'dest-001',
          itemName: 'Parkir Roda Dua (Motor)',
          price: 5000,
          unit: 'per kendaraan',
          regulationRef: 'Perda Kab. 50 Kota No. 4/2023',
        ),
        OfficialTariffModel(
          id: 'trf-003',
          destinationId: 'dest-001',
          itemName: 'Parkir Roda Empat (Mobil)',
          price: 10000,
          unit: 'per kendaraan',
          regulationRef: 'Perda Kab. 50 Kota No. 4/2023',
        ),
      ],
      scenes360: [
        Scene360Model(
          id: 'scn-harau-aerial',
          destinationId: 'dest-001',
          title: 'Panorama Drone Udara Lembah Harau (150m)',
          type: 'aerial',
          panoramaUrl:
              'https://raw.githubusercontent.com/yushijinhun/panorama_viewer/master/example/assets/panorama.jpg',
          initialPitch: -12.0,
          initialYaw: 25.0,
          hotspots: [
            Hotspot360Model(
              id: 'hs-1',
              sceneId: 'scn-harau-aerial',
              type: 'navigasi',
              pitch: -20.0,
              yaw: 15.0,
              title: 'Turun ke Sarasah Bunta (Ground)',
              targetRef: 'scn-harau-ground',
              description: 'Pindah ke tampilan darat di kaki air terjun.',
            ),
            Hotspot360Model(
              id: 'hs-2',
              sceneId: 'scn-harau-aerial',
              type: 'audio',
              pitch: -5.0,
              yaw: -40.0,
              title: 'Legenda Tebing Granit Harau & Saluang',
              description:
                  'Narasi geologi purba cekungan Harau diiringi alunan Saluang.',
            ),
          ],
        ),
        Scene360Model(
          id: 'scn-harau-ground',
          destinationId: 'dest-001',
          title: 'Tepi Air Terjun Sarasah Bunta (Ground)',
          type: 'ground',
          panoramaUrl:
              'https://raw.githubusercontent.com/yushijinhun/panorama_viewer/master/example/assets/panorama2.jpg',
          initialPitch: 0.0,
          initialYaw: 0.0,
          hotspots: [
            Hotspot360Model(
              id: 'hs-3',
              sceneId: 'scn-harau-ground',
              type: 'navigasi',
              pitch: 25.0,
              yaw: -10.0,
              title: 'Naik ke Drone Udara (150m)',
              targetRef: 'scn-harau-aerial',
              description: 'Lihat lanskap penuh lembah dari atas.',
            ),
            Hotspot360Model(
              id: 'hs-4',
              sceneId: 'scn-harau-ground',
              type: 'narasi',
              pitch: -4.0,
              yaw: 65.0,
              title: 'Narasi Sejarah Lembah Harau & Sarasah Bunta',
              description:
                  'Dengarkan kisah geologi cekungan purba dan sejarah Luhak Limopuluah.',
            ),
            Hotspot360Model(
              id: 'hs-5',
              sceneId: 'scn-harau-ground',
              type: 'musik',
              pitch: -2.0,
              yaw: -75.0,
              title: 'Musik Tradisional Saluang & Talempong',
              description:
                  'Petikan dan alunan instrumen khas Minangkabau yang menenangkan jiwa.',
            ),
          ],
        ),
      ],
    ),
    DestinationModel(
      id: 'dest-002',
      name: 'Air Terjun Lubuk Nyarai',
      category: 'Hidden Gem',
      categoryId: 'cat-hidden-gem',
      cityRegency: 'Kab. Padang Pariaman',
      description:
          'Kolam alami berwarna hijau toska di tengah Hutan Lindung Gamaran Nagari Lubuk Alung yang terbentuk dari kikisan batuan cadas alami.',
      latitude: -0.6812,
      longitude: 100.3915,
      coverImage:
          'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Sepi',
      distanceKm: '48 km',
      travelTime: '1j 20m',
      entryFee: 'Rp 20.000',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-002',
        destinationId: 'dest-002',
        vehicleAccess: 'Hanya Motor',
        trekkingLevel: 'Sedang',
        cellularSignal: 'Blank Spot (Zero-Signal)',
        facilities: 'Terbatas',
        guideNeed: 'Wajib Pemandu Lokal',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-003',
          destinationId: 'dest-002',
          content:
              'Wajib registrasi di Pos Pokdarwis Riterek dan tidak diperbolehkan naik saat debit sungai hulu meningkat (mendung tebal).',
          isImportant: true,
        ),
        LocalTipModel(
          id: 'tip-004',
          destinationId: 'dest-002',
          content:
              'Gunakan alas kaki anti-slip untuk trekking 1,5 jam menyusuri hutan Gamaran.',
          isImportant: false,
        ),
      ],
      tariffs: [
        OfficialTariffModel(
          id: 'trf-004',
          destinationId: 'dest-002',
          itemName: 'Paket Registrasi & Pemandu Pokdarwis',
          price: 35000,
          unit: 'per orang',
          regulationRef: 'Peraturan Nagari Lubuk Alung No. 2/2024',
        ),
      ],
      scenes360: [
        Scene360Model(
          id: 'scn-nyarai-ground',
          destinationId: 'dest-002',
          title: 'Kolam Utama Lubuk Nyarai (Ground)',
          type: 'ground',
          panoramaUrl:
              'https://raw.githubusercontent.com/yushijinhun/panorama_viewer/master/example/assets/panorama.jpg',
          hotspots: [
            Hotspot360Model(
              id: 'hs-ny-1',
              sceneId: 'scn-nyarai-ground',
              type: 'audio',
              pitch: 0,
              yaw: 10,
              title: 'Kisah Konservasi Hutan Gamaran oleh Pemuda Nagari',
              description: 'Audio dokumenter pelestarian ikan larangan.',
            ),
            Hotspot360Model(
              id: 'hs-ny-2',
              sceneId: 'scn-nyarai-ground',
              type: 'musik',
              pitch: -5,
              yaw: -50,
              title: 'Musik Tradisional Minang Alam Gamaran',
              description:
                  'Petikan Saluang dan Talempong Minang berpadu dengan gemericik air alami.',
            ),
          ],
        ),
      ],
    ),
    DestinationModel(
      id: 'dest-003',
      name: 'Geopark Nasional Silokek',
      category: 'Alam & Geopark',
      categoryId: 'cat-alam-geopark',
      cityRegency: 'Kab. Sijunjung',
      description:
          'Ngarai batuan karst dan granit berusia 359 juta tahun yang membelah aliran Batang Kuantan dengan pasir putih sungai dan goa purba.',
      latitude: -0.6420,
      longitude: 100.9942,
      coverImage:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Sepi',
      distanceKm: '118 km',
      travelTime: '2j 50m',
      entryFee: 'Gratis',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-003',
        destinationId: 'dest-003',
        vehicleAccess: 'Mobil OK',
        trekkingLevel: 'Sedang',
        cellularSignal: 'Sinyal Lemah',
        facilities: 'Ada Toilet & Musala',
        guideNeed: 'Disarankan',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-005',
          destinationId: 'dest-003',
          content:
              'Dilarang mencoret atau mengambil stalaktit/batuan geologi di dalam Ngalau Basurek.',
          isImportant: true,
        ),
      ],
      tariffs: [
        OfficialTariffModel(
          id: 'trf-005',
          destinationId: 'dest-003',
          itemName: 'Retribusi Masuk Kawasan Geopark',
          price: 0,
          unit: 'per orang (Gratis)',
          regulationRef: 'Perda Kab. Sijunjung Geopark Nasional',
        ),
      ],
      scenes360: [],
    ),
    DestinationModel(
      id: 'dest-004',
      name: 'Jam Gadang & Panorama Ngarai Sianok',
      category: 'Budaya & Nagari',
      categoryId: 'cat-budaya-nagari',
      cityRegency: 'Kota Bukittinggi',
      description:
          'Ikon bersejarah jantung Kota Bukittinggi dengan mesin jam langka dunia serta terowongan sejarah Lubang Jepang di tepi Ngarai Sianok.',
      latitude: -0.3051,
      longitude: 100.3692,
      coverImage:
          'https://images.unsplash.com/photo-1570789210967-2cac24afeb00?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Ramai',
      distanceKm: '90 km',
      travelTime: '2j 05m',
      entryFee: 'Rp 15.000',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-004',
        destinationId: 'dest-004',
        vehicleAccess: 'Mobil OK',
        trekkingLevel: 'Mudah (Datar)',
        cellularSignal: '4G Kuat',
        facilities: 'Ada Toilet & Musala',
        guideNeed: 'Bisa Mandiri',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-006',
          destinationId: 'dest-004',
          content:
              'Gunakan panduan Tarif Resmi Bendi di bawah ini sebelum naik bendi wisata agar terhindar dari tarik harga tidak wajar.',
          isImportant: true,
        ),
      ],
      tariffs: [
        OfficialTariffModel(
          id: 'trf-006',
          destinationId: 'dest-004',
          itemName: 'Tiket Taman Panorama & Lubang Jepang',
          price: 15000,
          unit: 'per orang',
          regulationRef: 'Perda Kota Bukittinggi No. 3/2023',
        ),
        OfficialTariffModel(
          id: 'trf-007',
          destinationId: 'dest-004',
          itemName: 'Bendi Wisata Rute Pendek Keliling Pasar Atas',
          price: 50000,
          unit: 'per putaran (maks 4 orang)',
          regulationRef: 'Kesepakatan Dinas Pariwisata Bukittinggi',
        ),
      ],
      scenes360: [],
    ),
    DestinationModel(
      id: 'dest-005',
      name: 'Kampung Adat Sarugo (Saribu Gonjong)',
      category: 'Budaya & Nagari',
      categoryId: 'cat-budaya-nagari',
      cityRegency: 'Kab. Lima Puluh Kota',
      description:
          'Perkampungan adat Minangkabau di Nagari Koto Tinggi dengan puluhan Rumah Gadang bergonjong yang masih asli dan dikelilingi kebun jeruk Siam Gunuang Omeh.',
      latitude: 0.0321,
      longitude: 100.4619,
      coverImage:
          'https://images.unsplash.com/photo-1518780664697-55e3ad937233?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Sepi',
      distanceKm: '148 km',
      travelTime: '3j 20m',
      entryFee: 'Rp 10.000',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-005',
        destinationId: 'dest-005',
        vehicleAccess: 'Mobil OK',
        trekkingLevel: 'Mudah (Datar)',
        cellularSignal: 'Sinyal Lemah',
        facilities: 'Ada Toilet & Musala',
        guideNeed: 'Disarankan',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-007',
          destinationId: 'dest-005',
          content:
              'Kenakan pakaian sopan dan ucapkan salam saat melewati halaman Rumah Gadang yang masih dihuni keluarga suku adat.',
          isImportant: true,
        ),
      ],
      tariffs: [
        OfficialTariffModel(
          id: 'trf-008',
          destinationId: 'dest-005',
          itemName: 'Kontribusi Kebersihan Nagari',
          price: 10000,
          unit: 'per orang',
          regulationRef: 'Peraturan Nagari Koto Tinggi',
        ),
      ],
      scenes360: [],
    ),
    DestinationModel(
      id: 'dest-006',
      name: 'Kawasan Bahari Mandeh (Puncak Paku)',
      category: 'Alam & Geopark',
      categoryId: 'cat-alam-geopark',
      cityRegency: 'Kab. Pesisir Selatan',
      description:
          'Gugusan teluk tenang berair biru jernih dengan pulau-pulau eksotis (Sironjong Ketek, Cubadak, Desa Kapo-Kapo) dan hutan mangrove.',
      latitude: -1.2015,
      longitude: 100.4220,
      coverImage:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Sedang',
      distanceKm: '56 km',
      travelTime: '1j 30m',
      entryFee: 'Rp 10.000',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-006',
        destinationId: 'dest-006',
        vehicleAccess: 'Mobil OK',
        trekkingLevel: 'Mudah (Datar)',
        cellularSignal: '4G Kuat',
        facilities: 'Ada Toilet & Musala',
        guideNeed: 'Disarankan',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-008',
          destinationId: 'dest-006',
          content:
              'Pesan perahu wisata resmi melalui Koperasi Dermaga TPI Carocok Tarusan agar mendapat jaket pelampung standar.',
          isImportant: true,
        ),
      ],
      tariffs: [
        OfficialTariffModel(
          id: 'trf-009',
          destinationId: 'dest-006',
          itemName: 'Sewa Boat Jelajah 4 Pulau Resmi (PP)',
          price: 650000,
          unit: 'per kapal (maks 10 penumpang)',
          regulationRef: 'Tarif Resmi Dermaga TPI Carocok Tarusan',
        ),
      ],
      scenes360: [],
    ),
    DestinationModel(
      id: 'dest-007',
      name: 'Sentra Kuliner Nasi Kapau Pasar Atas Los Lambuang',
      category: 'Kuliner',
      categoryId: 'cat-kuliner',
      cityRegency: 'Kota Bukittinggi',
      description:
          'Pusat kuliner otentik Nasi Kapau dengan gulai tambusu, gulai tunjang, dendeng batokok, dan talua barendo langsung dari Uni Kapau.',
      latitude: -0.3042,
      longitude: 100.3698,
      coverImage:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Ramai',
      distanceKm: '90 km',
      travelTime: '2j 05m',
      entryFee: 'Gratis',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-007',
        destinationId: 'dest-007',
        vehicleAccess: 'Mobil OK',
        trekkingLevel: 'Mudah (Datar)',
        cellularSignal: '4G Kuat',
        facilities: 'Ada Toilet & Musala',
        guideNeed: 'Bisa Mandiri',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-009',
          destinationId: 'dest-007',
          content:
              'Setiap kedai di Los Lambuang wajib memasang daftar harga resmi per porsi. Cek level kepedasan di katalog Mitra Nagari.',
          isImportant: true,
        ),
      ],
      tariffs: [
        OfficialTariffModel(
          id: 'trf-010',
          destinationId: 'dest-007',
          itemName: 'Seporsi Nasi Kapau + 1 Lauk Utama (Tambusu/Rendang)',
          price: 30000,
          unit: 'per porsi',
          regulationRef: 'Standar Paguyuban Los Lambuang Bukittinggi',
        ),
      ],
      scenes360: [],
    ),
    DestinationModel(
      id: 'dest-021',
      name: 'Masjid Raya Sumatera Barat',
      category: 'Religi',
      categoryId: 'cat-religi',
      cityRegency: 'Kota Padang',
      description:
          'Mahakarya arsitektur Islam Minangkabau dengan atap gonjong bentang kain Ka\'bah berukir khas Minang tanpa kubah konvensional.',
      latitude: -0.9242,
      longitude: 100.3626,
      coverImage:
          'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?auto=format&fit=crop&w=800&q=80',
      crowdLevel: 'Ramai',
      distanceKm: '0 km',
      travelTime: 'Pusat Kota',
      entryFee: 'Gratis',
      medanIndicator: MedanIndicatorModel(
        id: 'medan-021',
        destinationId: 'dest-021',
        vehicleAccess: 'Mobil OK',
        trekkingLevel: 'Sangat Mudah',
        cellularSignal: '4G Kuat',
        facilities: 'Lengkap (Lift, AC, Parkir Luas)',
        guideNeed: 'Bisa Mandiri',
      ),
      tips: [
        LocalTipModel(
          id: 'tip-021',
          destinationId: 'dest-021',
          content: 'Patuhi etika berbusana muslim/muslimah rapi dan sopan saat berkunjung.',
          isImportant: true,
        ),
      ],
      tariffs: [],
      scenes360: [],
    ),
  ];
}

