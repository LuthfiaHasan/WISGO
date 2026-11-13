export interface MedanIndicator {
  id: string;
  destination_id: string;
  road_access_status: string;
  car_accessible: boolean;
  motorcycle_accessible: boolean;
  max_slope_deg: number;
  trekking_difficulty: 'mudah' | 'sedang' | 'ekstrem';
  trekking_distance_m: number;
  cellular_signal: '4g_stabil' | 'sinyal_lemah' | 'blank_spot';
  recommended_provider: string;
  facilities_completeness: string;
  has_clean_toilet: boolean;
  has_musala: boolean;
  local_guide_status: 'mandiri' | 'tersedia_opsional' | 'wajib_pokdarwis';
  pokdarwis_name: string;
}

export interface DestinationTip {
  id: string;
  destination_id: string;
  tip_type: 'kelestarian_alam' | 'etika_adat' | 'keselamatan_medan' | 'waktu_terbaik';
  title: string;
  content: string;
  is_mandatory_read: boolean;
}

export interface OfficialTariff {
  id: string;
  destination_id: string;
  item_name: string;
  category: 'tiket' | 'parkir' | 'transport_lokal' | 'pemandu' | 'fasilitas';
  price_idr: number;
  unit: string;
  perda_reference: string;
  is_mandatory: boolean;
}

export interface DestinationRecord {
  id: string;
  slug: string;
  name: string;
  kabupaten_kota: string;
  category: 'alam' | 'budaya' | 'bahari' | 'nagari' | 'geopark';
  latitude: number;
  longitude: number;
  elevation_m: number;
  crowd_level: 'sepi' | 'sedang' | 'ramai';
  base_ticket_idr: number;
  distance_from_padang_km: number;
  travel_time_from_padang_min: number;
  is_hidden_gem: boolean;
  qr_placard_code: string;
  summary: string;
  description: string;
  opening_hours: string;
  updated_at: string;
  medan_indicator: MedanIndicator;
  tips: DestinationTip[];
  official_tariffs: OfficialTariff[];
}

export const INITIAL_20_DESTINATIONS: DestinationRecord[] = [
  {
    id: 'dest-001',
    slug: 'jam-gadang-bukittinggi',
    name: 'Jam Gadang & Taman Panorama Bukittinggi',
    kabupaten_kota: 'Kota Bukittinggi',
    category: 'budaya',
    latitude: -0.30519,
    longitude: 100.36947,
    elevation_m: 930,
    crowd_level: 'ramai',
    base_ticket_idr: 0,
    distance_from_padang_km: 91.5,
    travel_time_from_padang_min: 145,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-BKT-001',
    summary: 'Menara jam ikonik jantung Kota Bukittinggi dengan mesin kembaran Big Ben London dan latar Gunung Singgalang.',
    description: 'Didirikan pada tahun 1926 sebagai hadiah Ratu Wilhelmina kepada Sekretaris Kota Fort de Kock, Rook Maker. Kawasan pedestrian pelataran Jam Gadang terhubung langsung dengan Pasar Ateh dan jalur pejalan kaki menuju Taman Panorama Ngarai Sianok.',
    opening_hours: '24 Jam (Pedestrian Taman)',
    updated_at: '2026-11-10T08:00:00Z',
    medan_indicator: {
      id: 'medan-001',
      destination_id: 'dest-001',
      road_access_status: 'Mobil & Bus Pariwisata (Aspal kota mulus, kantong parkir gedung Pasar Ateh)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 6,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 150,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Semua Operator (Telkomsel, Indosat, XL 5G/4G+)',
      facilities_completeness: 'Toilet ramah difabel, Musala Agung Pasar Ateh, ATM Center, Pos Satgas Wisata',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'HPI & Pokdarwis Kota Wisata Bukittinggi'
    },
    tips: [
      {
        id: 'tip-001a',
        destination_id: 'dest-001',
        tip_type: 'etika_adat',
        title: 'Gunakan Bendi Resmi Berstiker Nomor Lambung',
        content: 'Pastikan menyewa Bendi wisata yang memiliki pelat nomor resmi Dinas Perhubungan dan sepakati rute keliling sesuai tabel tarif Perda sebelum naik.',
        is_mandatory_read: true
      },
      {
        id: 'tip-001b',
        destination_id: 'dest-001',
        tip_type: 'waktu_terbaik',
        title: 'Waktu Terbaik Menikmati Siluet Singgalang',
        content: 'Kunjungi pukul 06.00–08.00 WIB saat udara sejuk dan puncak Gunung Marapi serta Singgalang terlihat bersih tanpa kabut.',
        is_mandatory_read: false
      }
    ],
    official_tariffs: [
      { id: 'trf-001a', destination_id: 'dest-001', item_name: 'Tiket Masuk Pelataran Taman Jam Gadang', category: 'tiket', price_idr: 0, unit: 'per_orang', perda_reference: 'Perda Kota Bukittinggi No. 4/2023 (Gratis Ruang Publik)', is_mandatory: true },
      { id: 'trf-001b', destination_id: 'dest-001', item_name: 'Parkir Resmi Sepeda Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Bukittinggi No. 4/2023 Psl. 18', is_mandatory: true },
      { id: 'trf-001c', destination_id: 'dest-001', item_name: 'Parkir Resmi Mobil Penumpang / Minibus', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Bukittinggi No. 4/2023 Psl. 18', is_mandatory: true },
      { id: 'trf-001d', destination_id: 'dest-001', item_name: 'Tur Bendi Wisata Rute Pendek (Jam Gadang - Panorama PP)', category: 'transport_lokal', price_idr: 50000, unit: 'per_bendi_4_orang', perda_reference: 'SK Dishub & Dispar Bukittinggi No. 12/2024', is_mandatory: false }
    ]
  },
  {
    id: 'dest-002',
    slug: 'lembah-harau-limapuluh-kota',
    name: 'Kawasan Geopark Lembah Harau (Aka Barayun & Sarasah Bunta)',
    kabupaten_kota: 'Kab. Lima Puluh Kota',
    category: 'geopark',
    latitude: -0.10461,
    longitude: 100.66534,
    elevation_m: 540,
    crowd_level: 'sedang',
    base_ticket_idr: 15000,
    distance_from_padang_km: 138.0,
    travel_time_from_padang_min: 205,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-LPK-002',
    summary: 'Lembah tebing granit purba setinggi 150–300 meter dengan 7 air terjun alami dan persawahan nagari yang asri.',
    description: 'Cagar alam dan geopark nasional seluas 669 hektare yang dikelilingi dinding batu pasir dan konglomerat curam. Memiliki spot gema suara legendaris di Sarasah Bunta serta deretan homestay di kaki tebing.',
    opening_hours: '07.30 – 18.00 WIB',
    updated_at: '2026-11-10T08:05:00Z',
    medan_indicator: {
      id: 'medan-002',
      destination_id: 'dest-002',
      road_access_status: 'Mobil & Bus Besar (Jalan datar aspal mulus hingga kaki tebing air terjun)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 5,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 300,
      cellular_signal: 'sinyal_lemah',
      recommended_provider: 'Telkomsel (4G di gerbang depan; Blank Spot di lembah bagian dalam Sarasah Murai)',
      facilities_completeness: 'Toilet bersih di tiap titik air terjun, Musala Nagari Tarantang, Gazebo istirahat',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Pokdarwis Nagari Tarantang & Harau Geopark'
    },
    tips: [
      {
        id: 'tip-002a',
        destination_id: 'dest-002',
        tip_type: 'keselamatan_medan',
        title: 'Unduh Paket Offline Sebelum Masuk Lembah Dalam',
        content: 'Tebing granit vertikal 300 meter menghalangi sinyal seluler di area Sarasah Murai dan jalur trekking bukit. Aktifkan Mode Offline Pocket di gerbang depan.',
        is_mandatory_read: true
      },
      {
        id: 'tip-002b',
        destination_id: 'dest-002',
        tip_type: 'kelestarian_alam',
        title: 'Jangan Memberi Makan Monyet Ekor Panjang',
        content: 'Simpan makanan di dalam tas tertutup agar kawanan kera liar di sekitar Sarasah Bunta tetap mencari pakan alami di hutan.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-002a', destination_id: 'dest-002', item_name: 'Tiket Masuk Kawasan Lembah Harau (Dewasa)', category: 'tiket', price_idr: 15000, unit: 'per_orang', perda_reference: 'Perda Kab. Lima Puluh Kota No. 7/2023', is_mandatory: true },
      { id: 'trf-002b', destination_id: 'dest-002', item_name: 'Tiket Masuk Kawasan Lembah Harau (Anak-Anak)', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Lima Puluh Kota No. 7/2023', is_mandatory: true },
      { id: 'trf-002c', destination_id: 'dest-002', item_name: 'Parkir Resmi Motor (1x Bayar Berlaku Seluruh Spot Air Terjun)', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Peraturan Nagari Tarantang No. 2/2024', is_mandatory: true },
      { id: 'trf-002d', destination_id: 'dest-002', item_name: 'Parkir Resmi Mobil (1x Bayar Berlaku Seluruh Spot Air Terjun)', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Peraturan Nagari Tarantang No. 2/2024', is_mandatory: true }
    ]
  },
  {
    id: 'dest-003',
    slug: 'istano-basa-pagaruyung',
    name: 'Istano Basa Pagaruyung Batusangkar',
    kabupaten_kota: 'Kab. Tanah Datar',
    category: 'budaya',
    latitude: -0.47126,
    longitude: 100.62142,
    elevation_m: 470,
    crowd_level: 'sedang',
    base_ticket_idr: 20000,
    distance_from_padang_km: 104.0,
    travel_time_from_padang_min: 165,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-TND-003',
    summary: 'Replika megah istana Kerajaan Pagaruyung dengan 11 gonjong dan 72 tonggak kayu berukir filosofi Adat Basandi Syarak.',
    description: 'Pusat edukasi sejarah dan falsafah matrilineal Minangkabau yang terdiri dari 3 tingkat lantai, lengkap dengan Rangkiang Patah Sembilan, Tabuah Larangan, serta layanan sewa pakaian adat Suntiang dan Saluak.',
    opening_hours: '08.00 – 17.30 WIB',
    updated_at: '2026-11-10T08:10:00Z',
    medan_indicator: {
      id: 'medan-003',
      destination_id: 'dest-003',
      road_access_status: 'Mobil & Bus Besar (Pelataran parkir sangat luas langsung di depan kompleks istana)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 4,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 120,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Semua Operator 4G Stabil',
      facilities_completeness: 'Toilet bersih berstandar nasional, Surau/Musala luas, Ruang laktasi, Kios kuliner & suvenir resmi',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Unit Pengelola Istano Basa Pagaruyung & Pokdarwis Nagari Pagaruyung'
    },
    tips: [
      {
        id: 'tip-003a',
        destination_id: 'dest-003',
        tip_type: 'etika_adat',
        title: 'Tata Krama Memasuki Ruang Dalam Istano',
        content: 'Wajib melepas alas kaki di tangga utama dan berpakaian sopan. Dilarang duduk di atas Singgasana Bundo Kanduang di lantai tengah.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-003a', destination_id: 'dest-003', item_name: 'Tiket Masuk Dewasa Domestik', category: 'tiket', price_idr: 20000, unit: 'per_orang', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-003b', destination_id: 'dest-003', item_name: 'Tiket Masuk Anak-Anak / Pelajar', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-003c', destination_id: 'dest-003', item_name: 'Tiket Masuk Wisatawan Mancanegara (Malaysia/Asing)', category: 'tiket', price_idr: 30000, unit: 'per_orang', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-003d', destination_id: 'dest-003', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-003e', destination_id: 'dest-003', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-003f', destination_id: 'dest-003', item_name: 'Sewa Baju Adat Minang Lengkap (Suntiang / Deta)', category: 'fasilitas', price_idr: 35000, unit: 'per_set_60_menit', perda_reference: 'Standar Koperasi Pengelola Istano 2024', is_mandatory: false }
    ]
  },
  {
    id: 'dest-004',
    slug: 'air-terjun-nyarai-lubuk-alung',
    name: 'Ekowisata Air Terjun Nyarai & Lubuk Gamaran',
    kabupaten_kota: 'Kab. Padang Pariaman',
    category: 'alam',
    latitude: -0.68342,
    longitude: 100.38812,
    elevation_m: 380,
    crowd_level: 'sepi',
    base_ticket_idr: 25000,
    distance_from_padang_km: 48.0,
    travel_time_from_padang_min: 80,
    is_hidden_gem: true,
    qr_placard_code: 'QR-SMBR-PDP-004',
    summary: 'Hidden gem air terjun di dalam Hutan Lindung Gamaran dengan kolam alami hijau zamrud hasil pusaran batu jutaan tahun.',
    description: 'Terletak di Nagari Salibutan, Kecamatan Lubuk Alung. Untuk mencapainya, wisatawan menyusuri hutan tropis Bukit Barisan dan sungai jernih berbatu besar bersama pemandu Pokdarwis setempat.',
    opening_hours: '08.00 – 15.00 WIB (Batas Masuk Hutan 13.00 WIB)',
    updated_at: '2026-11-10T08:15:00Z',
    medan_indicator: {
      id: 'medan-004',
      destination_id: 'dest-004',
      road_access_status: 'Mobil & Motor sampai Posko Registrasi Nagari Salibutan; lanjut jalan kaki 5.2 km',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 22,
      trekking_difficulty: 'sedang',
      trekking_distance_m: 5200,
      cellular_signal: 'blank_spot',
      recommended_provider: 'Blank Spot Total setelah melewati Pos 1 Hutan Gamaran (Wajib Simpan Offline)',
      facilities_completeness: 'Toilet & Musala di Posko Registrasi; Pos Istirahat sederhana di dalam hutan',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'wajib_pokdarwis',
      pokdarwis_name: 'Pokdarwis L.A. Adventure Nagari Salibutan'
    },
    tips: [
      {
        id: 'tip-004a',
        destination_id: 'dest-004',
        tip_type: 'kelestarian_alam',
        title: 'Tips Menjaga Tempat Ini: Cagar Ikan Larangan & Hutan Gamaran',
        content: 'Dilarang keras menangkap ikan larangan di sepanjang sungai menuju air terjun dan wajib membawa kembali 100% sampah kemasan plastik ke Posko Registrasi.',
        is_mandatory_read: true
      },
      {
        id: 'tip-004b',
        destination_id: 'dest-004',
        tip_type: 'keselamatan_medan',
        title: 'Wajib Didampingi Pemandu & Waspada Debit Air Hulu',
        content: 'Gunakan sepatu trekking anti-selip. Jika cuaca di hulu Bukit Barisan mendung gelap, ikuti instruksi pemandu Pokdarwis untuk segera kembali ke pos aman.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-004a', destination_id: 'dest-004', item_name: 'Paket Registrasi Ekowisata & Asuransi Dasar', category: 'tiket', price_idr: 25000, unit: 'per_orang', perda_reference: 'Peraturan Nagari Salibutan No. 3/2023', is_mandatory: true },
      { id: 'trf-004b', destination_id: 'dest-004', item_name: 'Jasa Pemandu Resmi Pokdarwis (Maks. 5 Wisatawan)', category: 'pemandu', price_idr: 150000, unit: 'per_tim_5_orang', perda_reference: 'SK Pokdarwis Nagari Salibutan 2024', is_mandatory: true },
      { id: 'trf-004c', destination_id: 'dest-004', item_name: 'Parkir Resmi Motor di Posko Salibutan', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Peraturan Nagari Salibutan No. 3/2023', is_mandatory: true },
      { id: 'trf-004d', destination_id: 'dest-004', item_name: 'Parkir Resmi Mobil di Posko Salibutan', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Peraturan Nagari Salibutan No. 3/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-005',
    slug: 'kawasan-bahari-mandeh',
    name: 'Kawasan Bahari Terpadu Mandeh (Puncak Paku & Pulau Setan)',
    kabupaten_kota: 'Kab. Pesisir Selatan',
    category: 'bahari',
    latitude: -1.19845,
    longitude: 100.41528,
    elevation_m: 120,
    crowd_level: 'sedang',
    base_ticket_idr: 10000,
    distance_from_padang_km: 56.0,
    travel_time_from_padang_min: 95,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-PSS-005',
    summary: 'Teluk tenang berjuluk Raja Ampat dari Barat dengan gugusan pulau bukit hijau, hutan bakau, dan spot cliff jumping.',
    description: 'Terbentang di Kecamatan Koto XI Tarusan. Wisatawan dapat menikmati panorama teluk dari ketinggian Puncak Paku lalu menyeberang dengan perahu wisata resmi dari Dermaga Carocok Tarusan menuju Pulau Sironjong Ketek dan Hutan Mangrove Sungai Gemuruh.',
    opening_hours: '07.00 – 18.00 WIB',
    updated_at: '2026-11-10T08:20:00Z',
    medan_indicator: {
      id: 'medan-005',
      destination_id: 'dest-005',
      road_access_status: 'Mobil & Motor via Jalan Lintas Sungai Pisang - Mandeh (Aspal mulus berliku & tanjakan bukit)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 16,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 100,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Telkomsel & Indosat 4G di Dermaga & Puncak Paku (Sinyal lemah di balik pulau luar)',
      facilities_completeness: 'Dermaga resmi berpelampung, Toilet bilas air tawar, Musala dermaga, Restoran seafood nagari',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Koperasi Kapal Wisata & Pokdarwis Carocok Tarusan'
    },
    tips: [
      {
        id: 'tip-005a',
        destination_id: 'dest-005',
        tip_type: 'keselamatan_medan',
        title: 'Gunakan Jaket Pelampung & Kapal Terdaftar di Loket Dermaga',
        content: 'Selalu pesan kapal melalui loket resmi Dermaga Tarusan atau via Quick Booking Escrow Rancak.in untuk memastikan ketersediaan life jacket bagi seluruh penumpang.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-005a', destination_id: 'dest-005', item_name: 'Retribusi Masuk Dermaga Wisata Carocok Tarusan', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Pesisir Selatan No. 5/2023', is_mandatory: true },
      { id: 'trf-005b', destination_id: 'dest-005', item_name: 'Parkir Resmi Motor di Dermaga Tarusan', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Pesisir Selatan No. 5/2023', is_mandatory: true },
      { id: 'trf-005c', destination_id: 'dest-005', item_name: 'Parkir Resmi Mobil di Dermaga Tarusan', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Pesisir Selatan No. 5/2023', is_mandatory: true },
      { id: 'trf-005d', destination_id: 'dest-005', item_name: 'Sewa Kapal Island Hopping 4 Destinasi (Kapasitas 10 Orang)', category: 'transport_lokal', price_idr: 750000, unit: 'per_kapal_10_orang', perda_reference: 'Tarif Standar Koperasi Kapal Wisata Mandeh 2024', is_mandatory: false }
    ]
  },
  {
    id: 'dest-006',
    slug: 'jembatan-layang-kelok-9',
    name: 'Jembatan Layang & Rest Area Panorama Kelok 9',
    kabupaten_kota: 'Kab. Lima Puluh Kota',
    category: 'alam',
    latitude: -0.07089,
    longitude: 100.69761,
    elevation_m: 720,
    crowd_level: 'ramai',
    base_ticket_idr: 0,
    distance_from_padang_km: 147.0,
    travel_time_from_padang_min: 220,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-LPK-006',
    summary: 'Mahakarya arsitektur jembatan layang melingkar di tengah Cagar Alam Air Putih Bukit Barisan.',
    description: 'Menghubungkan Provinsi Sumatera Barat dan Riau dengan enam jembatan layang yang meliuk harmonis di antara dua perbukitan cagar alam hijau. Dilengkapi titik anjungan pandang resmi dan deretan kuliner jagung bakar serta kopi kawa daun.',
    opening_hours: '24 Jam',
    updated_at: '2026-11-10T08:25:00Z',
    medan_indicator: {
      id: 'medan-006',
      destination_id: 'dest-006',
      road_access_status: 'Semua Kendaraan (Jalan Nasional Lintas Sumbar-Riau, tanjakan berkelok tajam)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 14,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 80,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Telkomsel & XL 4G Stabil di area jembatan utama',
      facilities_completeness: 'Anjungan foto resmi, Warung kopi & jagung bakar terdata, Musala dan toilet rest area atas',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'mandiri',
      pokdarwis_name: 'Satgas Ketertiban Kawasan Kelok 9'
    },
    tips: [
      {
        id: 'tip-006a',
        destination_id: 'dest-006',
        tip_type: 'keselamatan_medan',
        title: 'Dilarang Parkir di Bahu Tikungan Jembatan Layang',
        content: 'Gunakan kantong parkir resmi di bagian atas atau bawah jembatan untuk mencegah kemacetan dan risiko kecelakaan kendaraan berat lintas provinsi.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-006a', destination_id: 'dest-006', item_name: 'Akses Anjungan Pandang Kelok 9', category: 'tiket', price_idr: 0, unit: 'per_orang', perda_reference: 'Kawasan Jalan Nasional Bebas Tiket Masuk', is_mandatory: true },
      { id: 'trf-006b', destination_id: 'dest-006', item_name: 'Parkir Resmi Motor di Kantong Rest Area', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Lima Puluh Kota No. 7/2023', is_mandatory: true },
      { id: 'trf-006c', destination_id: 'dest-006', item_name: 'Parkir Resmi Mobil di Kantong Rest Area', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Lima Puluh Kota No. 7/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-007',
    slug: 'puncak-lawang-danau-maninjau',
    name: 'Puncak Lawang & Panorama Kelok 44 Danau Maninjau',
    kabupaten_kota: 'Kab. Agam',
    category: 'alam',
    latitude: -0.26491,
    longitude: 100.24075,
    elevation_m: 1210,
    crowd_level: 'sedang',
    base_ticket_idr: 20000,
    distance_from_padang_km: 112.0,
    travel_time_from_padang_min: 175,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-AGM-007',
    summary: 'Titik pandang tertinggi di atas kaldera vulkanik Danau Maninjau (1.210 mdpl) dan landasan paralayang internasional.',
    description: 'Menyajikan hamparan biru Danau Maninjau yang dikelilingi dinding perbukitan hijau serta keunikan tradisi pengolahan tebu tradisional kilangan kerbau di Nagari Lawang.',
    opening_hours: '07.30 – 18.00 WIB',
    updated_at: '2026-11-10T08:30:00Z',
    medan_indicator: {
      id: 'medan-007',
      destination_id: 'dest-007',
      road_access_status: 'Mobil & Motor via Matur (Hindari Kelok 44 untuk bus besar; akses dari Bukittinggi via Matur jauh lebih landai)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 18,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 200,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Telkomsel & Indosat 4G Stabil',
      facilities_completeness: 'Toilet bersih, Musala kayu khas dataran tinggi, Dek observasi, Area outbound & paralayang',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Pokdarwis Nagari Lawang & Komunitas Paralayang Agam'
    },
    tips: [
      {
        id: 'tip-007a',
        destination_id: 'dest-007',
        tip_type: 'waktu_terbaik',
        title: 'Datang Sebelum Pukul 11.00 WIB untuk Menghindari Kabut Kaldera',
        content: 'Selepas tengah hari, awan kabut sering naik dari permukaan Danau Maninjau. Pagi hari adalah waktu paling jernih untuk foto panorama 360 derajat.',
        is_mandatory_read: false
      }
    ],
    official_tariffs: [
      { id: 'trf-007a', destination_id: 'dest-007', item_name: 'Tiket Masuk Taman Panorama Puncak Lawang (Hari Kerja)', category: 'tiket', price_idr: 20000, unit: 'per_orang', perda_reference: 'SK Pengelola Nagari Lawang & Dispar Agam 2024', is_mandatory: true },
      { id: 'trf-007b', destination_id: 'dest-007', item_name: 'Tiket Masuk Taman Panorama Puncak Lawang (Akhir Pekan)', category: 'tiket', price_idr: 25000, unit: 'per_orang', perda_reference: 'SK Pengelola Nagari Lawang & Dispar Agam 2024', is_mandatory: true },
      { id: 'trf-007c', destination_id: 'dest-007', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Agam No. 3/2023', is_mandatory: true },
      { id: 'trf-007d', destination_id: 'dest-007', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Agam No. 3/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-008',
    slug: 'ngarai-sianok-lobang-jepang',
    name: 'Geopark Ngarai Sianok, Lobang Jepang & Great Wall Koto Gadang',
    kabupaten_kota: 'Kota Bukittinggi',
    category: 'geopark',
    latitude: -0.30982,
    longitude: 100.36518,
    elevation_m: 915,
    crowd_level: 'sedang',
    base_ticket_idr: 15000,
    distance_from_padang_km: 90.0,
    travel_time_from_padang_min: 140,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-BKT-008',
    summary: 'Lembah patahan Semangko sedalam 100 meter dengan bunker bawah tanah bersejarah dan jembatan gantung Janjang Koto Gadang.',
    description: 'Menyajikan perpaduan wisata geologi patahan aktif Sumatera, wisata sejarah bunker pertahanan masa Perang Dunia II sepanjang 1.470 meter, serta jalur trekking menyeberangi lembah menuju desa pengrajin perak Koto Gadang.',
    opening_hours: '08.00 – 17.30 WIB',
    updated_at: '2026-11-10T08:35:00Z',
    medan_indicator: {
      id: 'medan-008',
      destination_id: 'dest-008',
      road_access_status: 'Mobil & Bus (Akses mudah ke Taman Panorama maupun ke dasar lembah Ngarai)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 15,
      trekking_difficulty: 'sedang',
      trekking_distance_m: 1200,
      cellular_signal: '4g_stabil',
      recommended_provider: '4G Stabil di permukaan taman; Blank Spot khusus di dalam lorong bunker Lobang Jepang',
      facilities_completeness: 'Toilet bersih, Musala taman, Penerangan lorong bunker, Pos pemandu resmi bersertifikat',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Himpunan Pramuwisata Taman Panorama & Ngarai Sianok'
    },
    tips: [
      {
        id: 'tip-008a',
        destination_id: 'dest-008',
        tip_type: 'etika_adat',
        title: 'Gunakan Pemandu Berkartu Tanda Pengenal Resmi Dispar',
        content: 'Pemandu resmi Lobang Jepang mengenakan rompi dan ID Card Dinas Pariwisata Bukittinggi dengan tarif terstandar tanpa paksaan tip tambahan.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-008a', destination_id: 'dest-008', item_name: 'Tiket Masuk Taman Panorama & Lobang Jepang (Dewasa)', category: 'tiket', price_idr: 15000, unit: 'per_orang', perda_reference: 'Perda Kota Bukittinggi No. 4/2023', is_mandatory: true },
      { id: 'trf-008b', destination_id: 'dest-008', item_name: 'Tiket Masuk Taman Panorama & Lobang Jepang (Anak)', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kota Bukittinggi No. 4/2023', is_mandatory: true },
      { id: 'trf-008c', destination_id: 'dest-008', item_name: 'Jasa Pemandu Sejarah Lobang Jepang (Opsional Resmi)', category: 'pemandu', price_idr: 50000, unit: 'per_rombongan', perda_reference: 'Standar HPI Taman Panorama Bukittinggi 2024', is_mandatory: false },
      { id: 'trf-008d', destination_id: 'dest-008', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Bukittinggi No. 4/2023', is_mandatory: true },
      { id: 'trf-008e', destination_id: 'dest-008', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Bukittinggi No. 4/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-009',
    slug: 'pantai-air-manis-malin-kundang',
    name: 'Pantai Air Manis & Situs Batu Malin Kundang',
    kabupaten_kota: 'Kota Padang',
    category: 'bahari',
    latitude: -0.99642,
    longitude: 100.36015,
    elevation_m: 5,
    crowd_level: 'ramai',
    base_ticket_idr: 10000,
    distance_from_padang_km: 8.5,
    travel_time_from_padang_min: 22,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-PDG-009',
    summary: 'Pantai landai berombak tenang dengan situs relief legenda Malin Kundang dan akses jalan kaki saat surut ke Pulau Pisang Ketek.',
    description: 'Sejak revitalisasi pedestrian dan gerbang e-ticketing oleh Pemko Padang, Pantai Air Manis menawarkan area wisata keluarga yang tertib dengan tarif masuk dan parkir satu pintu.',
    opening_hours: '07.00 – 18.30 WIB',
    updated_at: '2026-11-10T08:40:00Z',
    medan_indicator: {
      id: 'medan-009',
      destination_id: 'dest-009',
      road_access_status: 'Mobil & Bus via Jalur Baru Gunung Padang atau Bukik Gado-Gado (Aspal beton mulus)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 12,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 200,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Semua Operator 4G/5G Stabil',
      facilities_completeness: 'Gerbang e-Ticketing, Kamar bilas bersih, Musala tepi pantai, Pusat kuliner ikan bakar berdaftar harga',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'mandiri',
      pokdarwis_name: 'Perumda Padang Sejahtera Mandiri & Satgas Pantai Air Manis'
    },
    tips: [
      {
        id: 'tip-009a',
        destination_id: 'dest-009',
        tip_type: 'etika_adat',
        title: 'Hanya Bayar di Gerbang Resmi e-Ticketing (Bebas Pungutan Jembatan Kecil)',
        content: 'Seluruh akses ke Batu Malin Kundang sudah termasuk dalam tiket gerbang utama. Jika ada oknum meminta uang parkir kedua atau uang seberang jembatan kayu, gunakan tombol Lapor Pungli.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-009a', destination_id: 'dest-009', item_name: 'Tiket Masuk Pantai Air Manis (Dewasa)', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kota Padang No. 1/2024', is_mandatory: true },
      { id: 'trf-009b', destination_id: 'dest-009', item_name: 'Tiket Masuk Pantai Air Manis (Anak-Anak)', category: 'tiket', price_idr: 5000, unit: 'per_orang', perda_reference: 'Perda Kota Padang No. 1/2024', is_mandatory: true },
      { id: 'trf-009c', destination_id: 'dest-009', item_name: 'Parkir Resmi Motor (1x Bayar di Gerbang Utama)', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Padang No. 1/2024', is_mandatory: true },
      { id: 'trf-009d', destination_id: 'dest-009', item_name: 'Parkir Resmi Mobil (1x Bayar di Gerbang Utama)', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Padang No. 1/2024', is_mandatory: true },
      { id: 'trf-009e', destination_id: 'dest-009', item_name: 'Sewa ATV Resmi Menyusuri Pantai (15 Menit)', category: 'fasilitas', price_idr: 50000, unit: 'per_unit_15_menit', perda_reference: 'Standar Koperasi Wisata Air Manis 2024', is_mandatory: false }
    ]
  },
  {
    id: 'dest-010',
    slug: 'geopark-nasional-silokek-sijunjung',
    name: 'UNESCO Global Geopark Aspiring Silokek & Ngalau Basurek',
    kabupaten_kota: 'Kab. Sijunjung',
    category: 'geopark',
    latitude: -0.68419,
    longitude: 100.99214,
    elevation_m: 210,
    crowd_level: 'sepi',
    base_ticket_idr: 10000,
    distance_from_padang_km: 126.0,
    travel_time_from_padang_min: 195,
    is_hidden_gem: true,
    qr_placard_code: 'QR-SMBR-SJJ-010',
    summary: 'Ngarai batuan karst dan granit berumur 359 juta tahun (Zaman Karbon) yang dibelah aliran Sungai Batang Kuantan.',
    description: 'Menyimpan keajaiban geologi langka tempat bertemunya batuan gamping terumbu purba dengan batuan intrusi granit, pantai pasir putih di tepi sungai, gua kelelawar Ngalau Basurek, dan jalur arung jeram kelas dunia.',
    opening_hours: '08.00 – 17.30 WIB',
    updated_at: '2026-11-10T08:45:00Z',
    medan_indicator: {
      id: 'medan-010',
      destination_id: 'dest-010',
      road_access_status: 'Mobil & Motor dari Muaro Sijunjung (Jalan tepi tebing sungai beraspal sempit, hati-hati saat berpapasan)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 14,
      trekking_difficulty: 'sedang',
      trekking_distance_m: 650,
      cellular_signal: 'blank_spot',
      recommended_provider: 'Blank Spot sepanjang lembah Ngarai Batang Kuantan; WiFi Publik tersedia di Pusat Informasi Geopark Nagari Silokek',
      facilities_completeness: 'Pusat Informasi Geopark, Toilet & Musala bersih di Rest Area Pasir Putih, Gazebo tepi sungai',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Badan Pengelola Geopark Ranah Minang Silokek'
    },
    tips: [
      {
        id: 'tip-010a',
        destination_id: 'dest-010',
        tip_type: 'kelestarian_alam',
        title: 'Tips Menjaga Tempat Ini: Larangan Mengambil Fosil & Stalaktit Gua',
        content: 'Batuan karst Silokek berusia 359 juta tahun dan dilindungi undang-undang cagar geologi. Dilarang mencoret dinding gua atau mematahkan ornamen stalaktit.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-010a', destination_id: 'dest-010', item_name: 'Retribusi Masuk Kawasan Pasir Putih & Ngalau Silokek', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Sijunjung No. 2/2023', is_mandatory: true },
      { id: 'trf-010b', destination_id: 'dest-010', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Sijunjung No. 2/2023', is_mandatory: true },
      { id: 'trf-010c', destination_id: 'dest-010', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Sijunjung No. 2/2023', is_mandatory: true },
      { id: 'trf-010d', destination_id: 'dest-010', item_name: 'Pemandu Susur Gua Ngalau Basurek & Helm Senter', category: 'pemandu', price_idr: 100000, unit: 'per_rombongan_5_orang', perda_reference: 'Standar Pokdarwis Geopark Silokek 2024', is_mandatory: false }
    ]
  },
  {
    id: 'dest-011',
    slug: 'danau-kembar-kebun-teh-alahan-panjang',
    name: 'Danau Kembar (Diateh & Dibawah) & Kebun Teh Alahan Panjang',
    kabupaten_kota: 'Kab. Solok',
    category: 'alam',
    latitude: -1.04512,
    longitude: 100.73108,
    elevation_m: 1530,
    crowd_level: 'sedang',
    base_ticket_idr: 10000,
    distance_from_padang_km: 65.0,
    travel_time_from_padang_min: 110,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-SLK-011',
    summary: 'Kawasan agrowisata bersuhu dingin (14–18°C) dengan hamparan kebun teh hijau membentang di antara dua danau kembar.',
    description: 'Melewati jalur legendaris Sitinjau Lauik dan Lubuk Selasih, wisatawan disambut lanskap pegunungan mirip Eropa dengan latar Gunung Talang dan perkebunan hortikultura dataran tinggi.',
    opening_hours: '07.00 – 18.00 WIB',
    updated_at: '2026-11-10T08:50:00Z',
    medan_indicator: {
      id: 'medan-011',
      destination_id: 'dest-011',
      road_access_status: 'Mobil & Bus (Melintasi tanjakan Sitinjau Lauik dari Padang; pastikan kondisi rem prima)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 20,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 250,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Telkomsel & XL 4G Stabil',
      facilities_completeness: 'Toilet bersih, Musala, Glamping & Villa tepi danau, Kios stroberi dan sayur segar petani lokal',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'mandiri',
      pokdarwis_name: 'Pokdarwis Alahan Panjang & Dinas Pariwisata Kab. Solok'
    },
    tips: [
      {
        id: 'tip-011a',
        destination_id: 'dest-011',
        tip_type: 'keselamatan_medan',
        title: 'Pantau Live Hazard Alert Sitinjau Lauik Sebelum Berangkat dari Padang',
        content: 'Jalur Padang – Solok melewati Panorama 1 dan 2 Sitinjau Lauik. Cek status cuaca dan buka-tutup jalur pada banner peringatan aplikasi sebelum berangkat.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-011a', destination_id: 'dest-011', item_name: 'Tiket Masuk Kawasan Dermaga Danau Diateh', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Solok No. 4/2023', is_mandatory: true },
      { id: 'trf-011b', destination_id: 'dest-011', item_name: 'Spot Walk Kebun Teh Alahan Panjang', category: 'tiket', price_idr: 5000, unit: 'per_orang', perda_reference: 'Kesepakatan Nagari Alahan Panjang 2024', is_mandatory: false },
      { id: 'trf-011c', destination_id: 'dest-011', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Solok No. 4/2023', is_mandatory: true },
      { id: 'trf-011d', destination_id: 'dest-011', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Solok No. 4/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-012',
    slug: 'kawasan-seribu-rumah-gadang-solok-selatan',
    name: 'Kawasan Saribu Rumah Gadang Nagari Koto Baru',
    kabupaten_kota: 'Kab. Solok Selatan',
    category: 'nagari',
    latitude: -1.48231,
    longitude: 101.05642,
    elevation_m: 430,
    crowd_level: 'sepi',
    base_ticket_idr: 10000,
    distance_from_padang_km: 136.0,
    travel_time_from_padang_min: 215,
    is_hidden_gem: true,
    qr_placard_code: 'QR-SMBR-SLS-012',
    summary: 'Perkampungan adat hidup dengan lebih dari 125 Rumah Gadang autentik dari berbagai suku Minangkabau yang masih dihuni.',
    description: 'Dinobatkan sebagai Kampung Adat Terpopuler di Indonesia. Wisatawan dapat menginap langsung bersama keluarga pemilik Rumah Gadang, menyaksikan tari tradisional di Menara Songket, dan mencicipi kuliner pangek pisang.',
    opening_hours: '07.00 – 21.00 WIB',
    updated_at: '2026-11-10T08:55:00Z',
    medan_indicator: {
      id: 'medan-012',
      destination_id: 'dest-012',
      road_access_status: 'Mobil & Bus (Jalan aspal mulus langsung membelah perkampungan adat Muara Labuh)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 6,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 400,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Telkomsel & Indosat 4G Stabil',
      facilities_completeness: 'Homestay Rumah Gadang terstandarisasi, Toilet bersih modern, Surau adat bersejarah, Pusat Informasi Budaya',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Pokdarwis Saribu Rumah Gadang Koto Baru'
    },
    tips: [
      {
        id: 'tip-012a',
        destination_id: 'dest-012',
        tip_type: 'etika_adat',
        title: 'Tips Menjaga Tempat Ini: Hormati Privasi Penghuni Rumah Gadang',
        content: 'Seluruh Rumah Gadang di kawasan ini adalah rumah tinggal aktif warga. Ucapkan salam dan minta izin sebelum memotret area beranda atau naik ke tangga rumah.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-012a', destination_id: 'dest-012', item_name: 'Kontribusi Pelestarian Kawasan Adat Saribu Rumah Gadang', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Solok Selatan No. 3/2023', is_mandatory: true },
      { id: 'trf-012b', destination_id: 'dest-012', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Solok Selatan No. 3/2023', is_mandatory: true },
      { id: 'trf-012c', destination_id: 'dest-012', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Solok Selatan No. 3/2023', is_mandatory: true },
      { id: 'trf-012d', destination_id: 'dest-012', item_name: 'Menginap Homestay Rumah Gadang (Termasuk Sarapan Adat)', category: 'fasilitas', price_idr: 250000, unit: 'per_kamar_malam', perda_reference: 'Standar Asosiasi Homestay Saribu Rumah Gadang 2024', is_mandatory: false }
    ]
  },
  {
    id: 'dest-013',
    slug: 'desa-terindah-pariangan-tanah-datar',
    name: 'Nagari Tuo Pariangan (Desa Terindah di Dunia)',
    kabupaten_kota: 'Kab. Tanah Datar',
    category: 'nagari',
    latitude: -0.45918,
    longitude: 100.50192,
    elevation_m: 680,
    crowd_level: 'sedang',
    base_ticket_idr: 5000,
    distance_from_padang_km: 95.0,
    travel_time_from_padang_min: 150,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-TND-013',
    summary: 'Nagari tertua asal-usul leluhur Minangkabau di lereng Gunung Marapi yang dinobatkan Budget Travel New York sebagai desa terindah di dunia.',
    description: 'Menampilkan arsitektur Rumah Gadang beratap ijuk tanpa paku, Masjid Ishlah abad ke-19 dengan pancuran air panas belerang alami dari Gunung Marapi, serta Sawah Gadang Satampang Baniah.',
    opening_hours: '07.00 – 18.00 WIB',
    updated_at: '2026-11-10T09:00:00Z',
    medan_indicator: {
      id: 'medan-013',
      destination_id: 'dest-013',
      road_access_status: 'Mobil & Bus Medium (Jalan lereng Gunung Marapi beraspal mulus, tanjakan sedang)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 15,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 350,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Telkomsel & Indosat 4G Stabil',
      facilities_completeness: 'Pemandian air panas umum terpisah pria/wanita, Masjid Ishlah bersejarah, Warung Kopi Kawa Daun Puncak Mortir',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Pokdarwis Nagari Tuo Pariangan'
    },
    tips: [
      {
        id: 'tip-013a',
        destination_id: 'dest-013',
        tip_type: 'etika_adat',
        title: 'Adab di Pancuran Air Panas Masjid Ishlah',
        content: 'Pancuran air panas digunakan warga untuk berwudu dan mandi bersih. Pisahkan jalur pria dan wanita sesuai penanda adat setempat.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-013a', destination_id: 'dest-013', item_name: 'Retribusi Kebersihan & Pelestarian Nagari Tuo Pariangan', category: 'tiket', price_idr: 5000, unit: 'per_orang', perda_reference: 'Peraturan Nagari Pariangan No. 1/2023', is_mandatory: true },
      { id: 'trf-013b', destination_id: 'dest-013', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Peraturan Nagari Pariangan No. 1/2023', is_mandatory: true },
      { id: 'trf-013c', destination_id: 'dest-013', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Peraturan Nagari Pariangan No. 1/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-014',
    slug: 'pulau-pagang-pasumpahan-padang',
    name: 'Gugusan Wisata Bahari Pulau Pagang & Pulau Pasumpahan',
    kabupaten_kota: 'Kota Padang',
    category: 'bahari',
    latitude: -1.17142,
    longitude: 100.34185,
    elevation_m: 15,
    crowd_level: 'sedang',
    base_ticket_idr: 35000,
    distance_from_padang_km: 26.0,
    travel_time_from_padang_min: 65,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-PDG-014',
    summary: 'Pulau tropis berpasir putih halus dengan gradasi air laut tiga warna, terumbu karang snorkeling, dan bukit pandang 360 derajat.',
    description: 'Dapat ditempuh 25 menit menggunakan perahu wisata dari Dermaga Sungai Pisang atau Bungus Teluk Kabung. Sangat populer untuk snorkeling, camping tepi pantai, dan menikmati matahari terbenam.',
    opening_hours: '07.00 – 17.30 WIB (Menginap tersedia)',
    updated_at: '2026-11-10T09:05:00Z',
    medan_indicator: {
      id: 'medan-014',
      destination_id: 'dest-014',
      road_access_status: 'Mobil & Motor ke Dermaga Sungai Pisang, lanjut Perahu Wisata 25 menit',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 25,
      trekking_difficulty: 'sedang',
      trekking_distance_m: 350,
      cellular_signal: 'sinyal_lemah',
      recommended_provider: 'Telkomsel 4G tersedia; operator lain sinyal lemah di balik bukit Pulau Pasumpahan',
      facilities_completeness: 'Cottage kayu, Kamar bilas air tawar, Musala pulau, Penyewaan alat snorkeling & pelampung',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'tersedia_opsional',
      pokdarwis_name: 'Operator Wisata Bahari Sungai Pisang & Bungus'
    },
    tips: [
      {
        id: 'tip-014a',
        destination_id: 'dest-014',
        tip_type: 'kelestarian_alam',
        title: 'Dilarang Menginjak Terumbu Karang Saat Snorkeling',
        content: 'Gunakan pelampung saat melakukan snorkeling dan berfoto bawah air agar sirip kaki tidak mematahkan koloni karang meja di perairan Pulau Pagang.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-014a', destination_id: 'dest-014', item_name: 'Retribusi Masuk & Kebersihan Pulau Pagang / Pasumpahan', category: 'tiket', price_idr: 35000, unit: 'per_orang', perda_reference: 'Standar Pengelola Pulau Wisata Bungus-Tarusan 2024', is_mandatory: true },
      { id: 'trf-014b', destination_id: 'dest-014', item_name: 'Parkir Resmi Motor di Dermaga Sungai Pisang', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Retribusi Dermaga Sungai Pisang 2024', is_mandatory: true },
      { id: 'trf-014c', destination_id: 'dest-014', item_name: 'Parkir Resmi Mobil di Dermaga Sungai Pisang', category: 'parkir', price_idr: 10000, unit: 'per_kendaraan', perda_reference: 'Retribusi Dermaga Sungai Pisang 2024', is_mandatory: true },
      { id: 'trf-014d', destination_id: 'dest-014', item_name: 'Paket Perahu PP + Alat Snorkeling + Dokumentasi Bawah Air', category: 'transport_lokal', price_idr: 185000, unit: 'per_orang_sharing', perda_reference: 'Tarif Koperasi Wisata Bahari Sungai Pisang 2024', is_mandatory: false }
    ]
  },
  {
    id: 'dest-015',
    slug: 'pantai-gandoriah-pulau-angso-duo-pariaman',
    name: 'Pantai Gandoriah & Wisata Bahari Pulau Angso Duo',
    kabupaten_kota: 'Kota Pariaman',
    category: 'bahari',
    latitude: -0.62678,
    longitude: 100.11792,
    elevation_m: 4,
    crowd_level: 'ramai',
    base_ticket_idr: 5000,
    distance_from_padang_km: 58.0,
    travel_time_from_padang_min: 85,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-PRM-015',
    summary: 'Pantai ikonik terintegrasi Stasiun Kereta Api Pariaman, pusat pesta budaya Tabuik, dan penyeberangan 15 menit ke Pulau Angso Duo.',
    description: 'Wisatawan dapat naik Kereta Api Sibinuang langsung dari Stasiun Padang dan turun tepat di bibir Pantai Gandoriah untuk menyantap Nasi Sek dan Sala Lauak hangat sebelum menyeberang ke Pulau Angso Duo.',
    opening_hours: '06.30 – 22.00 WIB (Pulau Angso Duo 08.00 – 17.00 WIB)',
    updated_at: '2026-11-10T09:10:00Z',
    medan_indicator: {
      id: 'medan-015',
      destination_id: 'dest-015',
      road_access_status: 'Mobil, Bus Besar & Kereta Api Sibinuang (50 meter dari Stasiun Pariaman)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 2,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 100,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Semua Operator 4G/5G Stabil (Termasuk di Pulau Angso Duo)',
      facilities_completeness: 'Stasiun KA terintegrasi, Toilet & Kamar bilas modern, Musala tepi pantai, Dermaga apung resmi',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'mandiri',
      pokdarwis_name: 'Dinas Pariwisata & Kebudayaan Kota Pariaman'
    },
    tips: [
      {
        id: 'tip-015a',
        destination_id: 'dest-015',
        tip_type: 'waktu_terbaik',
        title: 'Gunakan Kereta Api Sibinuang untuk Bebas Macet Akhir Pekan',
        content: 'Dengan tarif kereta lokal Rp5.000 dari Stasiun Padang, Anda bisa tiba langsung di gerbang Pantai Gandoriah tanpa pusing mencari parkir.',
        is_mandatory_read: false
      }
    ],
    official_tariffs: [
      { id: 'trf-015a', destination_id: 'dest-015', item_name: 'Tiket Masuk Kawasan Pantai Gandoriah', category: 'tiket', price_idr: 5000, unit: 'per_orang', perda_reference: 'Perda Kota Pariaman No. 2/2023', is_mandatory: true },
      { id: 'trf-015b', destination_id: 'dest-015', item_name: 'Tiket Kapal Resmi PP + Retribusi Pulau Angso Duo', category: 'transport_lokal', price_idr: 55000, unit: 'per_orang_pp', perda_reference: 'Perwako Pariaman Tarif Angkutan Wisata Pulau 2024', is_mandatory: false },
      { id: 'trf-015c', destination_id: 'dest-015', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Pariaman No. 2/2023', is_mandatory: true },
      { id: 'trf-015d', destination_id: 'dest-015', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Pariaman No. 2/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-016',
    slug: 'kota-tua-tambang-batubara-ombilin-sawahlunto',
    name: 'Warisan Dunia UNESCO Tambang Batubara Ombilin & Lubang Mbah Soero',
    kabupaten_kota: 'Kota Sawahlunto',
    category: 'budaya',
    latitude: -0.68145,
    longitude: 100.77792,
    elevation_m: 260,
    crowd_level: 'sepi',
    base_ticket_idr: 15000,
    distance_from_padang_km: 94.0,
    travel_time_from_padang_min: 155,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-SWL-016',
    summary: 'Situs Warisan Dunia UNESCO dengan terowongan tambang batu bara bawah tanah abad ke-19, Museum Goedang Ransoem, dan Lokomotif Mak Itam.',
    description: 'Kota kuali bersejarah yang mempertahankan arsitektur kolonial Belanda, dapur umum pekerja tambang raksasa berkapasitas 3.000 porsi di Goedang Ransoem, serta wisata edukasi masuk ke lorong tambang batu bara asli.',
    opening_hours: '08.00 – 16.30 WIB',
    updated_at: '2026-11-10T09:15:00Z',
    medan_indicator: {
      id: 'medan-016',
      destination_id: 'dest-016',
      road_access_status: 'Mobil & Bus (Akses perkotaan berbukit dengan rambu heritage yang jelas)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 10,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 200,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Semua Operator 4G Stabil di kawasan Kota Tua',
      facilities_completeness: 'Helm & Sepatu Boot standar keselamatan tambang, Museum ber-AC, Toilet ramah difabel, Musala',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'wajib_pokdarwis',
      pokdarwis_name: 'Unit Pelaksana Teknis Museum & Heritage Kota Sawahlunto'
    },
    tips: [
      {
        id: 'tip-016a',
        destination_id: 'dest-016',
        tip_type: 'keselamatan_medan',
        title: 'Gunakan Helm Pengaman & Sepatu Boot Saat Masuk Lubang Mbah Soero',
        content: 'Perlengkapan keselamatan sudah termasuk dalam tiket masuk resmi. Ikuti instruksi pemandu museum selama menyusuri terowongan bawah tanah.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-016a', destination_id: 'dest-016', item_name: 'Tiket Masuk Lubang Tambang Mbah Soero (Termasuk Helm & Boot)', category: 'tiket', price_idr: 15000, unit: 'per_orang', perda_reference: 'Perda Kota Sawahlunto No. 5/2023', is_mandatory: true },
      { id: 'trf-016b', destination_id: 'dest-016', item_name: 'Tiket Masuk Museum Goedang Ransoem / Museum Kereta Api', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kota Sawahlunto No. 5/2023', is_mandatory: false },
      { id: 'trf-016c', destination_id: 'dest-016', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Sawahlunto No. 5/2023', is_mandatory: true },
      { id: 'trf-016d', destination_id: 'dest-016', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kota Sawahlunto No. 5/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-017',
    slug: 'jembatan-akar-bayang-pesisir-selatan',
    name: 'Jembatan Akar Hidup Pulut-Pulut Bayang',
    kabupaten_kota: 'Kab. Pesisir Selatan',
    category: 'alam',
    latitude: -1.16892,
    longitude: 100.56218,
    elevation_m: 195,
    crowd_level: 'sepi',
    base_ticket_idr: 10000,
    distance_from_padang_km: 82.0,
    travel_time_from_padang_min: 130,
    is_hidden_gem: true,
    qr_placard_code: 'QR-SMBR-PSS-017',
    summary: 'Jembatan gantung alami berusia lebih dari 100 tahun yang dirajut dari jalinan akar dua pohon beringin hidup di atas Sungai Batang Bayang.',
    description: 'Dirintis oleh ulama lokal Pakiah Sokan sejak tahun 1890 dan membutuhkan waktu 26 tahun hingga akar kedua pohon beringin menyatu sempurna sepanjang 25 meter di atas aliran sungai jernih.',
    opening_hours: '07.30 – 17.30 WIB',
    updated_at: '2026-11-10T09:20:00Z',
    medan_indicator: {
      id: 'medan-017',
      destination_id: 'dest-017',
      road_access_status: 'Mobil & Motor (Aspal mulus masuk ke lembah Kecamatan Bayang Utara)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 12,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 120,
      cellular_signal: 'sinyal_lemah',
      recommended_provider: 'Telkomsel 4G terbatas; operator lain sering hilang sinyal di dasar lembah sungai',
      facilities_completeness: 'Toilet & Ruang ganti pakaian, Musala tepi sungai, Warung kopi dan gorengan lokal',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'mandiri',
      pokdarwis_name: 'Pokdarwis Nagari Pulut-Pulut Bayang'
    },
    tips: [
      {
        id: 'tip-017a',
        destination_id: 'dest-017',
        tip_type: 'kelestarian_alam',
        title: 'Tips Menjaga Tempat Ini: Kapasitas Maksimal 15 Orang di Atas Jembatan Akar',
        content: 'Demi menjaga kesehatan struktur akar beringin berusia seabad, menyeberanglah secara bergantian dan jangan melompat-lompat di bagian tengah jembatan.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-017a', destination_id: 'dest-017', item_name: 'Tiket Masuk Kawasan Jembatan Akar Bayang', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Pesisir Selatan No. 5/2023', is_mandatory: true },
      { id: 'trf-017b', destination_id: 'dest-017', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Pesisir Selatan No. 5/2023', is_mandatory: true },
      { id: 'trf-017c', destination_id: 'dest-017', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Pesisir Selatan No. 5/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-018',
    slug: 'danau-singkarak-tanjung-mutiara',
    name: 'Kawasan Wisata Danau Singkarak & Kuliner Ikan Bilih',
    kabupaten_kota: 'Kab. Tanah Datar',
    category: 'alam',
    latitude: -0.60125,
    longitude: 100.53184,
    elevation_m: 365,
    crowd_level: 'sedang',
    base_ticket_idr: 10000,
    distance_from_padang_km: 78.0,
    travel_time_from_padang_min: 125,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-TND-018',
    summary: 'Danau tektonik terluas di Sumatera Barat (107,8 km²) yang menjadi habitat satu-satunya spesies endemik Ikan Bilih di dunia.',
    description: 'Membentang di Kabupaten Tanah Datar dan Kabupaten Solok. Dermaga Tanjung Mutiara dan Pantai Ombak Tanang menawarkan pemandangan senja keemasan serta pusat kuliner Ikan Bilih goreng dan pangek sasau.',
    opening_hours: '07.00 – 19.00 WIB',
    updated_at: '2026-11-10T09:25:00Z',
    medan_indicator: {
      id: 'medan-018',
      destination_id: 'dest-018',
      road_access_status: 'Mobil & Bus Besar (Terletak persis di tepi Jalan Lintas Solok – Padang Panjang yang lebar dan rata)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 4,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 50,
      cellular_signal: '4g_stabil',
      recommended_provider: 'Semua Operator 4G Stabil',
      facilities_completeness: 'Gazebo tepi danau, Toilet & Musala bersih, Sentra oleh-oleh Ikan Bilih kering & basah',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'mandiri',
      pokdarwis_name: 'Pokdarwis Tanjung Mutiara Batipuh Selatan'
    },
    tips: [
      {
        id: 'tip-018a',
        destination_id: 'dest-018',
        tip_type: 'kelestarian_alam',
        title: 'Beli Ikan Bilih Ukuran Dewasa Hasil Tangkap Ramah Lingkungan',
        content: 'Dukung kelestarian Ikan Bilih endemik Danau Singkarak dengan membeli produk dari koperasi nelayan tradisional yang tidak menggunakan bagan jaring rapat.',
        is_mandatory_read: false
      }
    ],
    official_tariffs: [
      { id: 'trf-018a', destination_id: 'dest-018', item_name: 'Tiket Masuk Kawasan Pantai Tanjung Mutiara Singkarak', category: 'tiket', price_idr: 10000, unit: 'per_orang', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-018b', destination_id: 'dest-018', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-018c', destination_id: 'dest-018', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-019',
    slug: 'air-terjun-lembah-anai-tanah-datar',
    name: 'Cagar Alam & Air Terjun Lembah Anai',
    kabupaten_kota: 'Kab. Tanah Datar',
    category: 'alam',
    latitude: -0.48324,
    longitude: 100.33815,
    elevation_m: 410,
    crowd_level: 'sedang',
    base_ticket_idr: 5000,
    distance_from_padang_km: 64.0,
    travel_time_from_padang_min: 100,
    is_hidden_gem: false,
    qr_placard_code: 'QR-SMBR-TND-019',
    summary: 'Air terjun setinggi 35 meter dari mata air Gunung Singgalang yang mengalir tepat di tepi jalan lintas utama Padang – Bukittinggi.',
    description: 'Ikon penyambut dataran tinggi Minangkabau yang dikelilingi hutan hujan tropis Cagar Alam Lembah Anai dan jembatan kereta api bergigi peninggalan Hindia Belanda.',
    opening_hours: '07.30 – 18.00 WIB',
    updated_at: '2026-11-10T09:30:00Z',
    medan_indicator: {
      id: 'medan-019',
      destination_id: 'dest-019',
      road_access_status: 'Semua Kendaraan (Tepat di tepi Jalan Nasional Padang – Padang Panjang; pantau info perbaikan jalan)',
      car_accessible: true,
      motorcycle_accessible: true,
      max_slope_deg: 11,
      trekking_difficulty: 'mudah',
      trekking_distance_m: 30,
      cellular_signal: 'sinyal_lemah',
      recommended_provider: 'Telkomsel 4G stabil; operator lain kadang melemah di tikungan tebing lembah',
      facilities_completeness: 'Kantong parkir seberang air terjun, Toilet, Musala rest area Singgalang Kariang',
      has_clean_toilet: true,
      has_musala: true,
      local_guide_status: 'mandiri',
      pokdarwis_name: 'BKSDA Sumatera Barat & Dishub Tanah Datar'
    },
    tips: [
      {
        id: 'tip-019a',
        destination_id: 'dest-019',
        tip_type: 'keselamatan_medan',
        title: 'Cek Peringatan Dini Curah Hujan Hulu Singgalang',
        content: 'Saat hujan lebat di puncak Gunung Singgalang, hindari berhenti terlalu lama di bawah tebing Lembah Anai dan ikuti petunjuk petugas jalur.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-019a', destination_id: 'dest-019', item_name: 'Tiket Masuk Pelataran Kolam Air Terjun Lembah Anai', category: 'tiket', price_idr: 5000, unit: 'per_orang', perda_reference: 'PNBP Kawasan Konservasi / Retribusi Daerah 2024', is_mandatory: true },
      { id: 'trf-019b', destination_id: 'dest-019', item_name: 'Parkir Resmi Motor', category: 'parkir', price_idr: 3000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true },
      { id: 'trf-019c', destination_id: 'dest-019', item_name: 'Parkir Resmi Mobil', category: 'parkir', price_idr: 5000, unit: 'per_kendaraan', perda_reference: 'Perda Kab. Tanah Datar No. 6/2023', is_mandatory: true }
    ]
  },
  {
    id: 'dest-020',
    slug: 'desa-adat-madobag-siberut-mentawai',
    name: 'Desa Adat Uma Madobag & Kulukubuk Siberut Selatan',
    kabupaten_kota: 'Kab. Kepulauan Mentawai',
    category: 'budaya',
    latitude: -1.56412,
    longitude: 99.18245,
    elevation_m: 45,
    crowd_level: 'sepi',
    base_ticket_idr: 50000,
    distance_from_padang_km: 155.0,
    travel_time_from_padang_min: 240,
    is_hidden_gem: true,
    qr_placard_code: 'QR-SMBR-MTW-020',
    summary: 'Jantung kebudayaan Sikerei dan rumah panggung komunal Uma di pedalaman Pulau Siberut dengan tradisi tato tertua di dunia.',
    description: 'Menyuguhkan pengalaman hidup bersama masyarakat adat Mentawai di sepanjang aliran Sungai Rereiket, melihat proses pengolahan sagu, ramuan panah tradisional, dan harmoni kosmologi Arat Sabulungan.',
    opening_hours: '08.00 – 17.00 WIB (Akses via Pelabuhan Maileppet Siberut)',
    updated_at: '2026-11-10T09:35:00Z',
    medan_indicator: {
      id: 'medan-020',
      destination_id: 'dest-020',
      road_access_status: 'Kapal Cepat Mentawai Fast dari Padang (3.5 jam) ke Siberut, lanjut Pompong Sungai & Jalan Kaki',
      car_accessible: false,
      motorcycle_accessible: true,
      max_slope_deg: 16,
      trekking_difficulty: 'ekstrem',
      trekking_distance_m: 3800,
      cellular_signal: 'blank_spot',
      recommended_provider: '4G di Dermaga Maileppet; Blank Spot Total di sepanjang hulu sungai & Uma pedalaman',
      facilities_completeness: 'Posko Ekowisata Maileppet, Menginap di Uma Adat (kelambu & matras), Toilet ekologis desa',
      has_clean_toilet: true,
      has_musala: false,
      local_guide_status: 'wajib_pokdarwis',
      pokdarwis_name: 'HPI & Pokdarwis Siberut Selatan Kepulauan Mentawai'
    },
    tips: [
      {
        id: 'tip-020a',
        destination_id: 'dest-020',
        tip_type: 'etika_adat',
        title: 'Tips Menjaga Tempat Ini: Hormati Pantangan Adat Uma (Punenen)',
        content: 'Wajib melapor di Posko Pariwisata Maileppet dan didampingi pemandu lokal berbahasa Mentawai. Jangan menyentuh tengkorak hewan buruan di beranda Uma tanpa izin Sikerei.',
        is_mandatory_read: true
      }
    ],
    official_tariffs: [
      { id: 'trf-020a', destination_id: 'dest-020', item_name: 'Retribusi Kunjungan Kawasan Budaya Siberut (Domestik)', category: 'tiket', price_idr: 50000, unit: 'per_orang', perda_reference: 'Perda Kab. Kepulauan Mentawai No. 4/2023', is_mandatory: true },
      { id: 'trf-020b', destination_id: 'dest-020', item_name: 'Tiket Kapal Cepat Mentawai Fast (Padang – Siberut Sekali Jalan)', category: 'transport_lokal', price_idr: 295000, unit: 'per_orang', perda_reference: 'Tarif Resmi Operator Mentawai Fast 2024', is_mandatory: false },
      { id: 'trf-020c', destination_id: 'dest-020', item_name: 'Jasa Pemandu Resmi Budaya Siberut (Per Hari)', category: 'pemandu', price_idr: 350000, unit: 'per_hari_rombongan', perda_reference: 'Standar HPI Kepulauan Mentawai 2024', is_mandatory: true }
    ]
  }
];
