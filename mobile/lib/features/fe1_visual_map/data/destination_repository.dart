import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';

/// Repository Destinasi Wisata Sumatera Barat (FE-1)
/// Mendukung Mock Data (untuk pengembangan mandiri Minggu 1) & integrasi REST API BE-1 (`/api/v1/destinations`)
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
          return list
              .map((item) => DestinationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Fallback mulus ke Mock Data jika backend belum online
    }

    // Filter dari Mock Data lokal
    return _mockDestinations.where((dest) {
      final matchCategory = category == 'Semua' ||
          dest.category.toLowerCase().contains(category.toLowerCase());
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

  static const List<DestinationModel> _mockDestinations = [
    DestinationModel(
      id: 'dest-001',
      name: 'Lembah Harau',
      category: 'Alam',
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
              type: 'fasilitas',
              pitch: -4.0,
              yaw: 65.0,
              title: 'Musala & Toilet Resmi Nagari',
              description: 'Jarak 60m ke arah timur dari kolam utama.',
            ),
            Hotspot360Model(
              id: 'hs-5',
              sceneId: 'scn-harau-ground',
              type: 'mitra',
              pitch: -2.0,
              yaw: -75.0,
              title: 'Homestay Rumah Gadang Bundo & Kopi Kawa Daun',
              targetRef: 'partner-harau-01',
              description:
                  'Mitra Resmi Terverifikasi Nagari · Tarif mulai Rp 250.000/malam.',
            ),
          ],
        ),
      ],
    ),
    DestinationModel(
      id: 'dest-002',
      name: 'Air Terjun Lubuk Nyarai',
      category: 'Alam',
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
              type: 'mitra',
              pitch: -5,
              yaw: -50,
              title: 'Pos Pemandu Resmi Pokdarwis Lubuk Nyarai',
              targetRef: 'partner-nyarai-01',
              description: 'Pesan pemandu lokal & pelampung resmi.',
            ),
          ],
        ),
      ],
    ),
    DestinationModel(
      id: 'dest-003',
      name: 'Geopark Nasional Silokek',
      category: 'Alam',
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
      category: 'Sejarah',
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
      category: 'Budaya',
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
      category: 'Alam',
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
  ];
}

