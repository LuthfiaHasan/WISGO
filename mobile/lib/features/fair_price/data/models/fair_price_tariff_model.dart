// Model Data Lengkap Sumatera Barat (1:1 dengan `wisgo_interactive_3d_prototype (1).html`)
// Mencakup:
// - 4 Wilayah: Padang, Payakumbuh & 50 Kota, Bukittinggi & Agam, Daerah Terpencil
// - 4 Kategori Alam: Air Terjun, Gunung & Lembah, Pantai & Bahari, Nagari & Hutan Terpencil
// - Rincian Biaya Resmi Vertikal (`VerticalFeeItem`)
// - Tarif Kalkulator Simulasi (`CalcRates`)
// - Rincian Barometer Perda Vertikal (`TariffItem`)

class VerticalFeeItem {
  final String label;
  final String sub;
  final String price;

  const VerticalFeeItem({
    required this.label,
    required this.sub,
    required this.price,
  });
}

class CalcRates {
  final int tiket;
  final int motor;
  final int mobil;

  const CalcRates({
    required this.tiket,
    required this.motor,
    required this.mobil,
  });
}

class TariffItem {
  final String cat; // 'TIKET' | 'PARKIR' | 'FASILITAS'
  final String name;
  final String note;
  final String official;
  final String fairMax;
  final String type;

  const TariffItem({
    required this.cat,
    required this.name,
    required this.note,
    required this.official,
    required this.fairMax,
    required this.type,
  });
}

class UserReview {
  final String author;
  final double rating;
  final String date;
  final String comment;

  const UserReview({
    required this.author,
    required this.rating,
    required this.date,
    required this.comment,
  });
}

class DenahPoint {
  final String category; // 'PARKIR' | 'UMKM' | 'TOILET' | 'MUSHOLLA' | 'LOKET'
  final String title;
  final String description;
  final double x; // Percent 0-100
  final double y; // Percent 0-100

  const DenahPoint({
    required this.category,
    required this.title,
    required this.description,
    required this.x,
    required this.y,
  });
}

class SavedDestinationModel {
  final String id;
  final int baroIndex;
  final String region;
  final String subRegion;
  final String natureType;
  final String categoryTag;
  final String title;
  final String distance;
  final double distanceKm;
  final String duration;
  final String terrainNote;
  final String imageUrl;
  final String perdaRef;
  final double rating;
  final int reviewsCount;
  final List<String> facilities;
  final List<UserReview> reviews;
  final List<DenahPoint> denahPoints;
  final List<VerticalFeeItem> verticalFees;
  final CalcRates calcRates;
  final List<TariffItem> tariffs;

  const SavedDestinationModel({
    required this.id,
    required this.baroIndex,
    required this.region,
    required this.subRegion,
    required this.natureType,
    required this.categoryTag,
    required this.title,
    required this.distance,
    required this.distanceKm,
    required this.duration,
    required this.terrainNote,
    required this.imageUrl,
    required this.perdaRef,
    required this.rating,
    required this.reviewsCount,
    required this.facilities,
    required this.reviews,
    required this.denahPoints,
    required this.verticalFees,
    required this.calcRates,
    required this.tariffs,
  });

  String get shortLabel =>
      '${region.split(' ').first} • ${title.split('&').first.trim()}';
}

/// 4 ID Destinasi Default yang Tersimpan di Memori Perangkat
const List<String> kDefaultSavedIds = [
  'lubuk-hitam-padang',
  'lembah-harau',
  'jam-gadang-ngarai',
  'nyarai-terpencil',
];

/// Katalog Lengkap 8 Destinasi Sumatera Barat (1:1 dari `wisgo_interactive_3d_prototype (1).html`)
const List<SavedDestinationModel> kAllSumbarDestinations = [
  SavedDestinationModel(
    id: 'lubuk-hitam-padang',
    baroIndex: 0,
    region: 'Padang',
    subRegion: 'Kec. Bungus Teluk Kabung, Kota Padang',
    natureType: 'Air Terjun',
    categoryTag: 'Padang • Air Terjun 3 Tingkat',
    title: 'Air Terjun Lubuk Hitam (Cindakir) 3 Tingkat',
    distance: '24 km dari Pusat Padang',
    distanceKm: 24.0,
    duration: '45 mnt berkendara + 40 mnt trekking',
    terrainNote:
        'Akses jalan raya Padang–Painan lanjut jalan kaki menyusuri kebun cengkeh & hutan.',
    imageUrl:
        'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'Retribusi Pokdarwis Bungus & Perda Kota Padang',
    rating: 4.8,
    reviewsCount: 142,
    facilities: [
      '🅿️ Tempat Parkir Warga',
      '🍜 Warung UMKM Makanan',
      '🚻 Toilet & Kamar Bilas',
      '🕌 Musholla Nagari',
      '🌿 Jalur Trekking Hutan',
    ],
    reviews: [
      UserReview(
        author: 'Rahmat Hidayat',
        rating: 5.0,
        date: '2 hari lalu',
        comment:
            'Air terjun 3 tingkat sangat asri dan sejuk. Parkir motor resmi 5 ribu aman dijaga warga pemuda setempat.',
      ),
      UserReview(
        author: 'Nurul Aisyah',
        rating: 4.8,
        date: '1 minggu lalu',
        comment:
            'Warung UMKM dekat pos 1 menyajikan goreng pisang dan kopi hangat dengan harga wajar tanpa getok.',
      ),
      UserReview(
        author: 'Fajar Pratama',
        rating: 4.7,
        date: '2 minggu lalu',
        comment:
            'Tersedia toilet dan bilas air bersih setelah bermain air. Sangat membantu melihat denah lokasi sebelum naik.',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Area Parkir Motor & Mobil',
        description: 'Halaman pos warga di awal jalur gerbang masuk Cindakir',
        x: 20,
        y: 80,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Pos Registrasi & Tiket',
        description: 'Loket resmi Pokdarwis Bungus, tiket Rp 10.000/orang',
        x: 35,
        y: 65,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Warung UMKM Makanan Minang',
        description: 'Kuliner lokal: gorengan, mie rebus, kelapa muda & kopi',
        x: 48,
        y: 60,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Toilet & Kamar Bilas',
        description: '2 bilik toilet bersih dengan sumber air pegunungan jernih',
        x: 42,
        y: 50,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musholla Pos Istirahat',
        description: 'Tempat ibadah nyaman lengkap sarung dan sajadah',
        x: 60,
        y: 45,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Tiket Masuk Kawasan & Pos Registrasi',
        sub: 'Per orang dewasa (akses 3 tingkatan)',
        price: 'Rp 10.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Area parkir warga di gerbang awal jalur',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Halaman parkir pos pemuda setempat',
        price: 'Rp 10.000',
      ),
      VerticalFeeItem(
        label: 'Jasa Pemandu Jalur Tingkat 3 (Opsional)',
        sub: '1 pemandu lokal untuk 1–5 pengunjung',
        price: 'Rp 50.000',
      ),
    ],
    calcRates: CalcRates(tiket: 10000, motor: 5000, mobil: 10000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Tiket Masuk & Pos Registrasi Pendaki Air Terjun',
        note: 'Berlaku untuk Tingkat 1, 2, dan 3',
        official: 'Rp 10.000 / org',
        fairMax: 'Rp 10.000',
        type: 'Resmi Pokdarwis',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Motor (Titik Awal Trekking)',
        note: 'Dijaga sampai sore hari',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'Karcis Pos',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Mobil Pribadi',
        note: 'Area parkir tepi jalan Cindakir',
        official: 'Rp 10.000 / unit',
        fairMax: 'Rp 10.000',
        type: 'Karcis Pos',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Sewa Pondok / Tempat Istirahat Pos 1',
        note: 'Dikelola warga sekitar',
        official: 'Rp 15.000',
        fairMax: 'Rp 20.000',
        type: 'Batas Wajar',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Pemandu Lokal Jalur Tebing Tingkat 3',
        note: 'Disarankan saat musim hujan',
        official: 'Rp 50.000 / grup',
        fairMax: 'Rp 75.000',
        type: 'Kesepakatan',
      ),
    ],
  ),
  SavedDestinationModel(
    id: 'gunung-padang',
    baroIndex: 1,
    region: 'Padang',
    subRegion: 'Kec. Padang Selatan, Kota Padang',
    natureType: 'Gunung & Lembah',
    categoryTag: 'Padang • Gunung & Puncak Laut',
    title: 'Taman Siti Nurbaya & Puncak Gunung Padang',
    distance: '4 km dari Pasar Raya Padang',
    distanceKm: 4.0,
    duration: '15 mnt berkendara + 20 mnt jalur tangga',
    terrainNote:
        'Melewati Jembatan Siti Nurbaya, tersedia jalur tangga beton rapi hingga ke puncak panorama Samudra Hindia.',
    imageUrl:
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'Perda Kota Padang • Dinas Pariwisata Kota Padang',
    rating: 4.9,
    reviewsCount: 286,
    facilities: [
      '🅿️ Tempat Parkir Dishub',
      '🍜 Pusat Kuliner UMKM Jembatan',
      '🚻 Toilet Bersih Pos Atas',
      '🕌 Musholla Kaki Bukit',
      '📸 Gardu Pandang Laut',
    ],
    reviews: [
      UserReview(
        author: 'Dian Permana',
        rating: 5.0,
        date: 'Kemarin',
        comment:
            'Sangat dekat dari pusat kota! Pemandangan matahari terbenam ke Samudra Hindia spektakuler. Parkir resmi Rp 2.000 ada karcis.',
      ),
      UserReview(
        author: 'Maya Sari',
        rating: 4.9,
        date: '4 hari lalu',
        comment:
            'Di puncak ada warung UMKM jual es kelapa muda dan pisang bakar keju. Tempat duduk gratis jika memesan minuman.',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Area Parkir Kaki Bukit (Dishub)',
        description: 'Karcis resmi Dishub Padang: Motor Rp 2.000, Mobil Rp 5.000',
        x: 18,
        y: 82,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Loket Tiket Gerbang Tangga',
        description: 'Tiket masuk resmi Dinas Pariwisata Rp 5.000/orang',
        x: 32,
        y: 70,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Sentra UMKM Kuliner Siti Nurbaya',
        description: 'Warung aneka minuman segar, sate lokan, dan camilan lokal',
        x: 52,
        y: 42,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Toilet Bersih Pengunjung',
        description: 'Fasilitas umum di pos pemberhentian tangga ke-2',
        x: 40,
        y: 52,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musholla Kaki Bukit',
        description: 'Musholla bersih sebelum mendaki tangga',
        x: 25,
        y: 78,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Tiket Masuk Kawasan Gunung Padang',
        sub: 'Karcis resmi Dinas Pariwisata per orang',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Area parkir kaki bukit / gerbang loket',
        price: 'Rp 2.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Tarif resmi Dishub Kota Padang',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Sewa Kursi & Meja Panorama Puncak',
        sub: 'Gratis jika memesan minuman standar warung',
        price: 'Rp 0 - Rp 10.000',
      ),
    ],
    calcRates: CalcRates(tiket: 5000, motor: 2000, mobil: 5000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Tiket Masuk Dewasa & Umum',
        note: 'Termasuk akses benteng Jepang & makam Siti Nurbaya',
        official: 'Rp 5.000 / org',
        fairMax: 'Rp 5.000',
        type: 'Perda Padang',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Motor Resmi',
        note: 'Sesuai Perda Dishub Kota Padang',
        official: 'Rp 2.000 / unit',
        fairMax: 'Rp 3.000',
        type: 'Perda Dishub',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Mobil Pribadi',
        note: 'Sesuai Perda Dishub Kota Padang',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'Perda Dishub',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Jasa Senter & Pemandu Celah Batu Makam',
        note: 'Opsional, tidak wajib diambil',
        official: 'Rp 10.000',
        fairMax: 'Rp 15.000',
        type: 'Sukarela',
      ),
    ],
  ),
  SavedDestinationModel(
    id: 'lembah-harau',
    baroIndex: 2,
    region: 'Payakumbuh & 50 Kota',
    subRegion: 'Kec. Harau, Dekat Payakumbuh',
    natureType: 'Air Terjun',
    categoryTag: 'Payakumbuh • Lembah & Air Terjun',
    title: 'Lembah Harau & Air Terjun Sarasah Bunta',
    distance: '14 km dari Pusat Kota Payakumbuh',
    distanceKm: 14.0,
    duration: '25 mnt dari Payakumbuh (3 jam dari Padang)',
    terrainNote:
        'Jalan aspal datar di antara tebing granit curam, sangat ramah keluarga, anak-anak, dan lansia.',
    imageUrl:
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'Perda Kab. Lima Puluh Kota • Retribusi Daerah',
    rating: 4.9,
    reviewsCount: 310,
    facilities: [
      '🅿️ Tempat Parkir Luas Tepi Tebing',
      '🍜 Sentra UMKM Makanan & Galamai',
      '🚻 Toilet & Kamar Ganti',
      '🕌 Musholla Harau Asri',
      '⛺ Gazebo Lesehan Tepi Aliran Air',
    ],
    reviews: [
      UserReview(
        author: 'Hendri Saputra',
        rating: 5.0,
        date: 'Kemarin',
        comment:
            'Tebing granitnya luar biasa megah. Denah lokasinya sangat akurat menunjukkan posisi warung UMKM dan toilet bersih di dekat kolam.',
      ),
      UserReview(
        author: 'Siti Aminah',
        rating: 4.9,
        date: '3 hari lalu',
        comment:
            'Harga makanan di warung warga sangat terjangkau, ada galamai asli Harau. Parkir mobil Rp 5.000 diberi karcis resmi.',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Area Parkir Resmi Sarasah Bunta',
        description: 'Parkir mobil & bus keluarga tepi tebing granit',
        x: 15,
        y: 75,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Loket Tiket Gerbang Harau',
        description: 'Karcis resmi Perda Lima Puluh Kota Rp 10.000/orang',
        x: 28,
        y: 68,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Deretan Warung UMKM Harau',
        description: 'Kuliner Minang: Nasi ramas, kelapa muda, dan oleh-oleh galamai',
        x: 45,
        y: 55,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Toilet & Kamar Bilas Wisata',
        description: 'Toilet bersih terawat dekat kolam pemandian air terjun',
        x: 58,
        y: 48,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musholla Harau Indah',
        description: 'Musholla sejuk dengan suara gemuruh air terjun alami',
        x: 70,
        y: 40,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Tiket Masuk Gerbang Utama Lembah Harau',
        sub: 'Akses seluruh titik air terjun Sarasah & Aka Barayun',
        price: 'Rp 10.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Area parkir resmi tepi kolam air terjun',
        price: 'Rp 3.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Wajib menerima karcis parkir resmi daerah',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Sewa Gazebo / Pondok Lesehan Keluarga',
        sub: 'Durasi sewa 3 jam di tepi aliran air terjun',
        price: 'Rp 25.000',
      ),
    ],
    calcRates: CalcRates(tiket: 10000, motor: 3000, mobil: 5000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Tiket Masuk Gerbang Utama Lembah Harau',
        note: 'Berlaku untuk seluruh air terjun utama',
        official: 'Rp 10.000 / org',
        fairMax: 'Rp 10.000',
        type: 'Tetap Perda',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Motor (Per Titik Air Terjun)',
        note: 'Area parkir Sarasah Bunta / Aka Barayun',
        official: 'Rp 3.000 / unit',
        fairMax: 'Rp 3.000',
        type: 'Perda',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Mobil Pribadi',
        note: 'Wajib meminta karcis retribusi',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'Perda',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Sewa Gazebo / Pondok Lesehan Tepi Air',
        note: 'Durasi sewa 3 jam untuk keluarga',
        official: 'Rp 25.000 / unit',
        fairMax: 'Rp 35.000',
        type: 'Batas Wajar',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Sewa Tikar Piknik Lipat',
        note: 'Sepuasnya selama di lokasi',
        official: 'Rp 10.000 / lembar',
        fairMax: 'Rp 15.000',
        type: 'Batas Wajar',
      ),
    ],
  ),
  SavedDestinationModel(
    id: 'kapalo-banda-taram',
    baroIndex: 3,
    region: 'Payakumbuh & 50 Kota',
    subRegion: 'Nagari Taram, Pinggiran Payakumbuh',
    natureType: 'Nagari & Hutan Terpencil',
    categoryTag: 'Payakumbuh • Hutan Pinus & Rakit Air',
    title: 'Kapalo Banda Taram & Hutan Pinus Wakaf',
    distance: '11 km dari Pusat Kota Payakumbuh',
    distanceKm: 11.0,
    duration: '20 mnt berkendara melewati persawahan nagari',
    terrainNote:
        'Akses jalan nagari beraspal menuju bendungan jernih di kaki bukit dan lorong pohon pinus rindang.',
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'BUMNag Taram & Dinas Pariwisata 50 Kota',
    rating: 4.8,
    reviewsCount: 198,
    facilities: [
      '🅿️ Tempat Parkir Pinus',
      '🍜 Warung UMKM Nagari Taram',
      '🚻 Toilet Bersih Bendungan',
      '🕌 Musholla Nagari',
      '🛶 Rakit Bambu Wisata',
    ],
    reviews: [
      UserReview(
        author: 'Arif Wibowo',
        rating: 5.0,
        date: '5 hari lalu',
        comment:
            'Airnya super jernih dan adem di bawah pohon pinus. Sewa rakit bambu 10 ribu puas banget!',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Area Parkir Hutan Pinus',
        description: 'Dikelola BUMNag Taram, teduh di bawah rindang pinus',
        x: 22,
        y: 78,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Loket Tiket BUMNag',
        description: 'Tiket masuk Rp 5.000/orang resmi BUMNag Nagari Taram',
        x: 35,
        y: 65,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Pusat UMKM Nagari Taram',
        description: 'Aneka makanan ringan khas nagari, kopi kawa daun, dan jagung bakar',
        x: 50,
        y: 50,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Toilet & Ruang Bilas Bendungan',
        description: 'Fasilitas bersih untuk pengunjung selesai berakit air',
        x: 42,
        y: 58,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musholla Pinus',
        description: 'Tempat ibadah di tepi danau jernih',
        x: 65,
        y: 38,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Tiket Masuk Kawasan Kapalo Banda',
        sub: 'Dikelola resmi oleh BUMNag Nagari Taram',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Parkir terpadu di bawah hutan pinus',
        price: 'Rp 3.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Area parkir luas dekat bendungan',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Sewa Rakit Bambu Foto Tengah Danau',
        sub: 'Per orang (durasi 20 menit lengkap pelampung)',
        price: 'Rp 10.000',
      ),
    ],
    calcRates: CalcRates(tiket: 5000, motor: 3000, mobil: 5000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Tiket Masuk Kawasan Wisata Nagari Taram',
        note: 'Karcis resmi BUMNag Taram',
        official: 'Rp 5.000 / org',
        fairMax: 'Rp 5.000',
        type: 'BUMNag Resmi',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Motor Terpadu',
        note: 'Sekali bayar bebas pindah titik',
        official: 'Rp 3.000 / unit',
        fairMax: 'Rp 3.000',
        type: 'BUMNag Resmi',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Mobil Pribadi',
        note: 'Sekali bayar',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'BUMNag Resmi',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Sewa Rakit Bambu / Kayak Air Jernih',
        note: 'Per orang sudah termasuk pelampung',
        official: 'Rp 10.000 / org',
        fairMax: 'Rp 15.000',
        type: 'Tarif Standar',
      ),
    ],
  ),
  SavedDestinationModel(
    id: 'jam-gadang-ngarai',
    baroIndex: 4,
    region: 'Bukittinggi & Agam',
    subRegion: 'Pusat Kota Bukittinggi',
    natureType: 'Gunung & Lembah',
    categoryTag: 'Bukittinggi • Ngarai & Sejarah',
    title: 'Jam Gadang & Taman Panorama Ngarai Sianok',
    distance: '92 km dari Kota Padang',
    distanceKm: 92.0,
    duration: '2 jam 15 mnt berkendara',
    terrainNote:
        'Terletak di jantung Kota Bukittinggi, akses pejalan kaki ramah kursi roda & dekat kantong parkir gedung.',
    imageUrl:
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'Perda Kota Bukittinggi No. 4/2023 • Dishub & Dispar',
    rating: 4.9,
    reviewsCount: 420,
    facilities: [
      '🅿️ Tempat Parkir Gedung Dishub',
      '🍜 Pasar Kuliner Los Lambuang',
      '🚻 Toilet Bersih Panorama',
      '🕌 Musholla Jam Gadang',
      '📸 Gardu Pandang Ngarai Sianok',
    ],
    reviews: [
      UserReview(
        author: 'Bambang Kusuma',
        rating: 5.0,
        date: 'Kemarin',
        comment:
            'Ikon Sumatera Barat yang wajib dikunjungi! Nasi Kapau di Los Lambuang sangat lezat, tarif parkir resmi terkontrol.',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Gedung Parkir Resmi Dishub Bukittinggi',
        description: 'Kapasitas ratusan mobil dan motor dengan tarif flat Perda',
        x: 20,
        y: 80,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Loket Tiket Taman Panorama & Lubang Jepang',
        description: 'Karcis resmi Dispar Bukittinggi Rp 15.000/orang dewasa',
        x: 35,
        y: 65,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Sentra UMKM Nasi Kapau & Cenderamata',
        description: 'Pusat kuliner legendaris dan kerajinan sulam Bukittinggi',
        x: 55,
        y: 50,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Toilet Bersih Kawasan Jam Gadang',
        description: 'Toilet standar pariwisata ramah disabilitas',
        x: 45,
        y: 55,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musholla Jam Gadang & Pasar Atas',
        description: 'Tempat sholat luas dan nyaman di pusat kota',
        x: 65,
        y: 40,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Tiket Masuk Taman Panorama & Lubang Jepang',
        sub: 'Dewasa Nusantara (Pelataran Jam Gadang gratis)',
        price: 'Rp 15.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Gedung parkir resmi / kantong parkir Dishub',
        price: 'Rp 2.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Tarif resmi sekali parkir sesuai Perda',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Jasa Pemandu Resmi Lubang Jepang (HPI)',
        sub: 'Rombongan 1–5 orang (opsional, berlisensi)',
        price: 'Rp 50.000',
      ),
    ],
    calcRates: CalcRates(tiket: 15000, motor: 2000, mobil: 5000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Tiket Masuk Kawasan Panorama (Dewasa)',
        note: 'Termasuk akses Lubang Jepang',
        official: 'Rp 15.000 / org',
        fairMax: 'Rp 15.000',
        type: 'Tetap Perda',
      ),
      TariffItem(
        cat: 'TIKET',
        name: 'Tiket Masuk Anak-Anak (6–12 Tahun)',
        note: 'Wajib karcis resmi bercap',
        official: 'Rp 10.000 / org',
        fairMax: 'Rp 10.000',
        type: 'Tetap Perda',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Motor (Roda 2)',
        note: 'Kantong parkir resmi gedung/tepi jalan',
        official: 'Rp 2.000 / unit',
        fairMax: 'Rp 3.000',
        type: 'Perda Dishub',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Retribusi Parkir Mobil (Roda 4)',
        note: 'Tarif sekali parkir (flat)',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'Perda Dishub',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Jasa Pemandu Lokal Lubang Jepang',
        note: 'Pemandu berlisensi HPI (1–5 orang)',
        official: 'Rp 50.000 / grup',
        fairMax: 'Rp 75.000',
        type: 'Batas Wajar',
      ),
    ],
  ),
  SavedDestinationModel(
    id: 'nyarai-terpencil',
    baroIndex: 5,
    region: 'Daerah Terpencil',
    subRegion: 'Hutan Gamaran, Lubuk Alung (Padang Pariaman)',
    natureType: 'Air Terjun',
    categoryTag: 'Terpencil • Air Terjun Hutan Lindung',
    title: 'Air Terjun Nyarai & Kolam Batu Alami Gamaran',
    distance: '48 km dari Kota Padang',
    distanceKm: 48.0,
    duration: '1 jam berkendara + 1 jam 30 mnt trekking hutan',
    terrainNote:
        'Lokasi terpencil di dalam Hutan Lindung Gamaran. Wajib registrasi di Pos Ekowisata & didampingi pemandu.',
    imageUrl:
        'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'Koperasi Ekowisata Hutan Gamaran Salibutan',
    rating: 4.8,
    reviewsCount: 165,
    facilities: [
      '🅿️ Tempat Parkir Posko Salibutan',
      '🍜 Warung UMKM Makanan Hutan',
      '🚻 Toilet & Kamar Bilas Alami',
      '🕌 Musholla Pos Ekowisata',
      '🧭 Pemandu Hutan Terlatih',
    ],
    reviews: [
      UserReview(
        author: 'Eko Wahyudi',
        rating: 5.0,
        date: '3 hari lalu',
        comment:
            'Trekking hutan yang seru, air terjun dan kolam batu alaminya sangat spektakuler! Pemandu lokalnya sangat profesional.',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Area Parkir Posko Ekowisata Salibutan',
        description: 'Parkir aman dijaga tim koperasi ekowisata seharian',
        x: 18,
        y: 82,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Posko Registrasi & Asuransi Nyarai',
        description: 'Pendaftaran wajib & briefing keselamatan trekking hutan',
        x: 32,
        y: 70,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Warung UMKM Warga Salibutan',
        description: 'Sedia perbekalan trekking, air mineral, dan nasi bungkus daun',
        x: 48,
        y: 58,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Toilet & Kamar Bilas Posko',
        description: 'Bilik bilas air bersih setelah berenang di Lubuk Nyarai',
        x: 40,
        y: 65,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musholla Posko Gamaran',
        description: 'Musholla kayu bersih di tepi sungai',
        x: 60,
        y: 45,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Tiket Registrasi & Asuransi Ekowisata Nyarai',
        sub: 'Resmi di Pos Salibutan (termasuk konservasi hutan)',
        price: 'Rp 20.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Parkir aman di halaman Posko Ekowisata',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Parkir seharian selama trekking hutan',
        price: 'Rp 10.000',
      ),
      VerticalFeeItem(
        label: 'Jasa Pemandu Hutan Resmi (Wajib per 5 Org)',
        sub: 'Menjaga keamanan jalur sungai & hutan lindung',
        price: 'Rp 100.000',
      ),
    ],
    calcRates: CalcRates(tiket: 20000, motor: 5000, mobil: 10000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Tiket Masuk & Konservasi Hutan Gamaran',
        note: 'Tercatat resmi di buku posko',
        official: 'Rp 20.000 / org',
        fairMax: 'Rp 20.000',
        type: 'Posko Resmi',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Motor Posko Salibutan',
        note: 'Dijaga petugas posko',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'Posko Resmi',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Mobil Posko Salibutan',
        note: 'Dijaga petugas posko',
        official: 'Rp 10.000 / unit',
        fairMax: 'Rp 10.000',
        type: 'Posko Resmi',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Pemandu Ekowisata Resmi (1 Guide / 5 Tamu)',
        note: 'Tarif patungan per rombongan',
        official: 'Rp 100.000 / grup',
        fairMax: 'Rp 100.000',
        type: 'Wajib Posko',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Sewa Pelampung Renang Lubuk Nyarai',
        note: 'Per unit seharian',
        official: 'Rp 15.000 / unit',
        fairMax: 'Rp 20.000',
        type: 'Standar Posko',
      ),
    ],
  ),
  SavedDestinationModel(
    id: 'pariangan-terpencil',
    baroIndex: 6,
    region: 'Daerah Terpencil',
    subRegion: 'Lereng Gunung Marapi, Kab. Tanah Datar',
    natureType: 'Nagari & Hutan Terpencil',
    categoryTag: 'Terpencil • Desa Kuno Lereng Gunung',
    title: 'Nagari Tuo Pariangan & Pemandian Air Panas Alami',
    distance: '95 km dari Kota Padang',
    distanceKm: 95.0,
    duration: '2 jam 25 mnt berkendara',
    terrainNote:
        'Desa adat tertua di lereng Gunung Marapi dengan jalan batu menanjak, rumah gadang asli, dan mata air panas.',
    imageUrl:
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'Pokdarwis Nagari Tuo Pariangan & Perda Tanah Datar',
    rating: 4.9,
    reviewsCount: 230,
    facilities: [
      '🅿️ Tempat Parkir Nagari Adat',
      '🍜 Kedai Kopi Kawa Daun UMKM',
      '♨️ Pemandian Air Panas Alami',
      '🕌 Masjid Ishlah Bersejarah',
      '🏛️ Rumah Gadang Asli Kuno',
    ],
    reviews: [
      UserReview(
        author: 'Rina Marlina',
        rating: 5.0,
        date: 'Kemarin',
        comment:
            'Desa terindah di dunia dengan suasana tenang lereng gunung. Minum kopi kawa daun di batok kelapa sangat berkesan!',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Area Parkir Masjid Ishlah Pariangan',
        description: 'Kantong parkir resmi nagari dekat balai adat',
        x: 20,
        y: 80,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Pos Informasi Nagari Adat',
        description: 'Pos donasi kebersihan dan pemandu nagari Rp 5.000',
        x: 35,
        y: 70,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Kedai UMKM Kopi Kawa Daun & Goreng Bada',
        description: 'Kuliner tradisional khas Pariangan langsung dari warga',
        x: 52,
        y: 52,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Pemandian Air Panas & Bilas Alami',
        description: 'Kamar mandi pancuran air belerang hangat alami gunung',
        x: 45,
        y: 60,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Masjid Ishlah Nagari Tuo',
        description: 'Masjid tertua beratapkan ijuk tradisional Minangkabau',
        x: 65,
        y: 42,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Kontribusi Masuk & Kebersihan Nagari Adat',
        sub: 'Per orang di pos informasi desa',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Area parkir Masjid Ishlah / Puncak Mortir',
        price: 'Rp 3.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Kantong parkir resmi Pokdarwis',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Kamar Pemandian Air Panas Belerang Alami',
        sub: 'Kontribusi kebersihan pemandian tradisional',
        price: 'Rp 5.000',
      ),
    ],
    calcRates: CalcRates(tiket: 5000, motor: 3000, mobil: 5000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Retribusi Masuk Kawasan Nagari Tuo Pariangan',
        note: 'Karcis resmi Pokdarwis Nagari',
        official: 'Rp 5.000 / org',
        fairMax: 'Rp 5.000',
        type: 'Resmi Nagari',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Motor Kawasan Adat',
        note: 'Sekali parkir',
        official: 'Rp 3.000 / unit',
        fairMax: 'Rp 3.000',
        type: 'Resmi Nagari',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Mobil Pribadi',
        note: 'Area parkir bawah & puncak',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'Resmi Nagari',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Berenang / Bilas Air Panas Alami Masjid Ishlah',
        note: 'Kontribusi perawatan kolam',
        official: 'Rp 5.000 / org',
        fairMax: 'Rp 5.000',
        type: 'Resmi Nagari',
      ),
    ],
  ),
  SavedDestinationModel(
    id: 'kawasan-mandeh',
    baroIndex: 7,
    region: 'Daerah Terpencil',
    subRegion: 'Teluk Carocok Tarusan, Pesisir Selatan',
    natureType: 'Pantai & Bahari',
    categoryTag: 'Terpencil • Kepulauan & Teluk Bahari',
    title: 'Kawasan Kepulauan Mandeh & Pulau Sironjong',
    distance: '56 km Selatan Kota Padang',
    distanceKm: 56.0,
    duration: '1 jam 30 mnt jalur pantai berliku',
    terrainNote:
        'Akses jalan aspal tebing pantai dengan pemandangan gugusan pulau, lanjut perahu dari Dermaga TPI Carocok.',
    imageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
    perdaRef: 'Perda Kab. Pesisir Selatan & Koperasi Boat Mandeh',
    rating: 4.9,
    reviewsCount: 340,
    facilities: [
      '🅿️ Tempat Parkir Dermaga TPI',
      '🍜 Pusat Kuliner Ikan Bakar UMKM',
      '🚻 Toilet & Kamar Bilas Dermaga',
      '🕌 Musholla Dermaga Tarusan',
      '⛵ Dermaga Kapal Wisata Resmi',
    ],
    reviews: [
      UserReview(
        author: 'Ferry Gunawan',
        rating: 5.0,
        date: '4 hari lalu',
        comment:
            'Raja Ampat-nya Sumatera! Sewa kapal resmi koperasi 650 ribu bisa keliling 4 pulau termasuk cliff jumping di Sironjong Ketek.',
      ),
    ],
    denahPoints: [
      DenahPoint(
        category: 'PARKIR',
        title: 'Area Parkir Resmi Dermaga TPI Tarusan',
        description: 'Parkir berpagar aman dijaga selama tur pulau',
        x: 18,
        y: 80,
      ),
      DenahPoint(
        category: 'LOKET',
        title: 'Loket Koperasi Kapal Wisata Mandeh',
        description: 'Loket tiket resmi Perda & sewa kapal berstandar pelampung',
        x: 32,
        y: 70,
      ),
      DenahPoint(
        category: 'UMKM',
        title: 'Sentra UMKM Ikan Bakar & Kuliner Pesisir',
        description: 'Ikan bakar segar langsung dari nelayan Carocok Tarusan',
        x: 52,
        y: 55,
      ),
      DenahPoint(
        category: 'TOILET',
        title: 'Toilet & Kamar Bilas Nelayan',
        description: 'Fasilitas bilas air tawar setelah snorkeling di laut',
        x: 42,
        y: 62,
      ),
      DenahPoint(
        category: 'MUSHOLLA',
        title: 'Musholla Dermaga Bahari',
        description: 'Tempat ibadah di tepi teluk Mandeh',
        x: 62,
        y: 45,
      ),
    ],
    verticalFees: [
      VerticalFeeItem(
        label: 'Retribusi Masuk Kawasan Puncak / Dermaga',
        sub: 'Per orang dewasa sesuai Perda Pesisir Selatan',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Motor (Roda 2)',
        sub: 'Parkir seharian di Dermaga TPI Tarusan',
        price: 'Rp 3.000',
      ),
      VerticalFeeItem(
        label: 'Retribusi Parkir Mobil (Roda 4)',
        sub: 'Kantong parkir resmi dermaga wisata',
        price: 'Rp 5.000',
      ),
      VerticalFeeItem(
        label: 'Sewa Kapal Resmi Keliling 4 Pulau (10 Orang)',
        sub: 'Sironjong Ketek, Cubadak, Hutan Bakau, Kapo-Kapo',
        price: 'Rp 650.000',
      ),
    ],
    calcRates: CalcRates(tiket: 5000, motor: 3000, mobil: 5000),
    tariffs: [
      TariffItem(
        cat: 'TIKET',
        name: 'Retribusi Masuk Kawasan Puncak / Dermaga',
        note: 'Per orang dewasa',
        official: 'Rp 5.000 / org',
        fairMax: 'Rp 5.000',
        type: 'Tetap Perda',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Motor Dermaga Carocok Tarusan',
        note: 'Parkir seharian selama tur pulau',
        official: 'Rp 3.000 / unit',
        fairMax: 'Rp 5.000',
        type: 'Perda',
      ),
      TariffItem(
        cat: 'PARKIR',
        name: 'Parkir Mobil Dermaga Carocok Tarusan',
        note: 'Area parkir resmi TPI',
        official: 'Rp 5.000 / unit',
        fairMax: 'Rp 10.000',
        type: 'Perda',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Sewa Kapal Wisata Keliling 4 Pulau (Maks 10 Org)',
        note: 'Tarif resmi loket koperasi dermaga',
        official: 'Rp 650.000 / kapal',
        fairMax: 'Rp 750.000',
        type: 'Tarif Koperasi',
      ),
      TariffItem(
        cat: 'FASILITAS',
        name: 'Sewa Alat Snorkeling & Pelampung',
        note: 'Per set lengkap seharian',
        official: 'Rp 25.000 / set',
        fairMax: 'Rp 35.000',
        type: 'Batas Wajar',
      ),
    ],
  ),
];

/// Alias untuk kompatibilitas mundur
const List<SavedDestinationModel> kSampleSavedDestinations =
    kAllSumbarDestinations;
