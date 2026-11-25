import '../../fair_price/data/models/fair_price_tariff_model.dart';

/// Adapter konversi data respons REST API Supabase menjadi `SavedDestinationModel` (UI FE-2).
/// Menjaga konsistensi data antara Backend Supabase dan komponen UI FE-2 tanpa merge conflict.
class DestinationAdapter {
  /// Mengonversi satu item JSON destinasi dari Supabase menjadi `SavedDestinationModel`
  static SavedDestinationModel fromJson(Map<String, dynamic> json, {int index = 0}) {
    final id = json['id']?.toString() ?? 'dest-$index';
    final name = json['name']?.toString() ?? 'Destinasi Minangkabau';
    final cityRegency = json['city_regency']?.toString() ?? 'Sumatera Barat';
    final description = json['description']?.toString() ?? '';
    final coverImage = json['cover_image']?.toString() ??
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80';

    // Ekstrak biaya tiket masuk (default 10.000 jika kosong/0)
    final num? rawFee = json['entry_fee'] is num
        ? json['entry_fee'] as num
        : (json['entry_fee'] != null ? num.tryParse(json['entry_fee'].toString()) : null);
    final int entryFee = (rawFee != null && rawFee > 0) ? rawFee.toInt() : 10000;

    // Normalisasi Region (Padang, Payakumbuh & 50 Kota, Bukittinggi & Agam, Daerah Terpencil)
    String region = 'Daerah Terpencil';
    final cityLower = cityRegency.toLowerCase();
    if (cityLower.contains('padang')) {
      region = 'Padang';
    } else if (cityLower.contains('payakumbuh') || cityLower.contains('lima puluh kota') || cityLower.contains('50 kota')) {
      region = 'Payakumbuh & 50 Kota';
    } else if (cityLower.contains('bukittinggi') || cityLower.contains('agam')) {
      region = 'Bukittinggi & Agam';
    }

    // Normalisasi Kategori Alam (Air Terjun, Gunung & Lembah, Pantai & Bahari, Nagari & Hutan Terpencil)
    String natureType = 'Nagari & Hutan Terpencil';
    final nameLower = name.toLowerCase();
    final descLower = description.toLowerCase();

    if (nameLower.contains('gunung') || nameLower.contains('lembah') || nameLower.contains('ngarai') || nameLower.contains('puncak') || nameLower.contains('marapi') || nameLower.contains('singgalang')) {
      natureType = 'Gunung & Lembah';
    } else if (nameLower.contains('air terjun') || nameLower.contains('sarasah') || nameLower.contains('lubuk')) {
      natureType = 'Air Terjun';
    } else if (nameLower.contains('pantai') || nameLower.contains('pulau') || nameLower.contains('danau') || nameLower.contains('mandeh') || nameLower.contains('bahari')) {
      natureType = 'Pantai & Bahari';
    } else if (descLower.contains('air terjun') || descLower.contains('sarasah') || descLower.contains('lubuk')) {
      natureType = 'Air Terjun';
    } else if (descLower.contains('gunung') || descLower.contains('lembah') || descLower.contains('ngarai') || descLower.contains('puncak')) {
      natureType = 'Gunung & Lembah';
    } else if (descLower.contains('pantai') || descLower.contains('pulau') || descLower.contains('danau') || descLower.contains('mandeh')) {
      natureType = 'Pantai & Bahari';
    }

    // Indikator Medan & Fasilitas
    final medan = json['medan_indicator'] is Map<String, dynamic>
        ? json['medan_indicator'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawFacilities = medan['facilities']?.toString() ?? 'Toilet, Musala, Parkir, Gazebo';
    final List<String> facilities = rawFacilities
        .split(',')
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    if (facilities.isEmpty) {
      facilities.addAll(['Toilet Bersih', 'Musala', 'Area Parkir']);
    }

    final vehicleAccess = medan['vehicle_access']?.toString() ?? 'Mobil, Motor';
    final trekkingLevel = medan['trekking_level']?.toString() ?? 'Mudah (Akses Aspal)';
    final cellularSignal = medan['cellular_signal']?.toString() ?? '4G / Terpantau';
    final terrainNote = 'Akses: $vehicleAccess. Trekking: $trekkingLevel. Jaringan: $cellularSignal.';

    // Ekstrak & bangun Tariffs
    final List<TariffItem> tariffs = [];
    int parkirMotor = 5000;
    int parkirMobil = 10000;
    String perdaRef = 'Perda Kab/Kota Sumatera Barat';

    if (json['tariffs'] is List) {
      for (final t in json['tariffs'] as List) {
        if (t is Map<String, dynamic>) {
          final tName = t['item_name']?.toString() ?? 'Retribusi';
          final tUnit = t['unit']?.toString() ?? 'per orang/kendaraan';
          final num? tPriceNum = t['price'] is num ? t['price'] as num : num.tryParse(t['price']?.toString() ?? '0');
          final int tPrice = tPriceNum?.toInt() ?? 10000;
          final ref = t['regulation_ref']?.toString();
          if (ref != null && ref.trim().isNotEmpty) {
            perdaRef = ref.trim();
          }

          String cat = 'TIKET';
          final tLower = tName.toLowerCase();
          if (tLower.contains('parkir')) {
            cat = 'PARKIR';
            if (tLower.contains('motor') || tLower.contains('roda 2')) {
              parkirMotor = tPrice;
            } else if (tLower.contains('mobil') || tLower.contains('roda 4') || tLower.contains('bus')) {
              parkirMobil = tPrice;
            }
          } else if (tLower.contains('sewa') || tLower.contains('toilet') || tLower.contains('gazebo') || tLower.contains('alat')) {
            cat = 'FASILITAS';
          }

          tariffs.add(TariffItem(
            cat: cat,
            name: tName,
            note: tUnit,
            official: 'Rp ${_formatRupiah(tPrice)}',
            fairMax: 'Rp ${_formatRupiah((tPrice * 1.25).round())}',
            type: cat == 'TIKET' ? 'wajib' : 'opsional',
          ));
        }
      }
    }

    // Jika tariffs kosong dari backend, sediakan standar Perda
    if (tariffs.isEmpty) {
      tariffs.addAll([
        TariffItem(
          cat: 'TIKET',
          name: 'Tiket Masuk Wisatawan',
          note: 'per orang (SK Dispar)',
          official: 'Rp ${_formatRupiah(entryFee)}',
          fairMax: 'Rp ${_formatRupiah((entryFee * 1.2).round())}',
          type: 'wajib',
        ),
        TariffItem(
          cat: 'PARKIR',
          name: 'Parkir Resmi Roda Dua',
          note: 'per motor',
          official: 'Rp ${_formatRupiah(parkirMotor)}',
          fairMax: 'Rp ${_formatRupiah(parkirMotor + 2000)}',
          type: 'wajib',
        ),
        TariffItem(
          cat: 'PARKIR',
          name: 'Parkir Resmi Roda Empat',
          note: 'per mobil / bus',
          official: 'Rp ${_formatRupiah(parkirMobil)}',
          fairMax: 'Rp ${_formatRupiah(parkirMobil + 5000)}',
          type: 'wajib',
        ),
      ]);
    }

    final verticalFees = [
      VerticalFeeItem(
        label: 'Tiket Masuk Resmi',
        sub: 'Sesuai regulasi Perda',
        price: 'Rp ${_formatRupiah(entryFee)}',
      ),
      VerticalFeeItem(
        label: 'Parkir Kendaraan',
        sub: 'Motor / Mobil',
        price: 'Rp ${_formatRupiah(parkirMotor)} - ${_formatRupiah(parkirMobil)}',
      ),
      VerticalFeeItem(
        label: 'Akses Fasilitas Umum',
        sub: 'Toilet & Gazebo Pokdarwis',
        price: 'Rp 2.000 - 15.000',
      ),
    ];

    final calcRates = CalcRates(
      tiket: entryFee,
      motor: parkirMotor,
      mobil: parkirMobil,
    );

    // Titik denah standar
    final denahPoints = [
      const DenahPoint(
        category: 'LOKET',
        title: 'Loket Tiket Resmi & Verifikasi QRIS',
        description: 'Pintu gerbang utama dengan tarif resmi Perda.',
        x: 20,
        y: 85,
      ),
      const DenahPoint(
        category: 'PARKIR',
        title: 'Kantung Parkir Roda 2 & Roda 4',
        description: 'Area beraspal dengan pengawasan Pokdarwis nagari.',
        x: 35,
        y: 75,
      ),
      const DenahPoint(
        category: 'UMKM',
        title: 'Pujasera & Mitra Kuliner Minang',
        description: 'Aneka kuliner khas nagari dan suvenir terkurasi.',
        x: 65,
        y: 40,
      ),
      const DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musala & Toilet Bersih',
        description: 'Fasilitas umum terawat dengan air pegunungan alami.',
        x: 50,
        y: 50,
      ),
    ];

    // Reviews standar editorial
    final reviews = [
      UserReview(
        author: 'Rahmat Hidayat (Wisatawan Rombongan)',
        rating: 4.9,
        date: '2 hari lalu',
        comment: 'Harga tiket resmi sesuai aplikasi, tidak ada pungli liar saat masuk. Nagari sangat ramah!',
      ),
      UserReview(
        author: 'Siti Rahmawati',
        rating: 4.8,
        date: '1 minggu lalu',
        comment: 'Pemandangan luar biasa indah, udara sejuk. Rekomendasi datang pagi hari.',
      ),
    ];

    return SavedDestinationModel(
      id: id,
      baroIndex: index,
      region: region,
      subRegion: cityRegency,
      natureType: natureType,
      categoryTag: '$region • $natureType',
      title: name,
      distance: 'Terjangkau dari Pusat',
      distanceKm: 25.0 + (index * 4.5),
      duration: '45 - 90 menit perjalanan',
      terrainNote: terrainNote,
      imageUrl: coverImage,
      perdaRef: perdaRef,
      rating: 4.7 + ((index % 3) * 0.1),
      reviewsCount: 85 + (index * 14),
      facilities: facilities,
      reviews: reviews,
      denahPoints: denahPoints,
      verticalFees: verticalFees,
      calcRates: calcRates,
      tariffs: tariffs,
    );
  }

  /// Format angka integer menjadi representasi ribuan bertitik (15.000)
  static String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}
