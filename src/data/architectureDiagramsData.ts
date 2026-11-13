// ============================================================================
// STUDIO DIAGRAM ARSITEKTUR, ERD & UML (MINGGU 1 S/D MINGGU 4)
// Nama Tabel & Kolom (Field): Menggunakan Bahasa Indonesia agar Mudah Dimengerti
// ============================================================================

export type DiagramKind = 'erd' | 'class' | 'sequence' | 'usecase' | 'architecture';

export interface ErdColumnSpec {
  name: string;
  dataType: string;
  keyType: 'PK' | 'FK' | 'SPATIAL' | 'INDEX' | 'NORMAL';
  nullable: boolean;
  references?: string;
  description: string;
}

export interface ErdEntityNode {
  id: string;
  tableName: string;
  tableNumberLabel: string;
  owner: 'BE-1' | 'BE-2';
  sprint: 'Minggu 1' | 'Minggu 2' | 'Minggu 3' | 'Minggu 4' | 'Boundary BE-2';
  moduleGroup: string;
  spatialGeometry: string;
  indexes: string[];
  description: string;
  columns: ErdColumnSpec[];
}

export interface ErdRelationshipSpec {
  id: string;
  fromTable: string;
  fromColumn: string;
  toTable: string;
  toColumn: string;
  cardinality: '1:1' | '1:N' | '0..1:N' | 'JWT-Claim';
  relationLabel: string;
  sprint: string;
  isCrossBoundary: boolean;
}

export interface GoClassField {
  visibility: '+' | '-';
  name: string;
  type: string;
  tagOrNote?: string;
}

export interface GoClassMethod {
  visibility: '+' | '-';
  name: string;
  params: string;
  returnType: string;
  sprintOrigin: 'S1' | 'S2' | 'S3' | 'S4';
  description: string;
}

export interface GoClassNode {
  id: string;
  className: string;
  stereotype: '<<Middleware & Security>>' | '<<HTTP Delivery & Cache>>' | '<<PostGIS Repository>>' | '<<Domain Struct / DTO>>';
  layer: 'middleware' | 'handler' | 'repository' | 'domain';
  sourceFile: string;
  sprintRange: string;
  description: string;
  fields: GoClassField[];
  methods: GoClassMethod[];
}

export interface GoClassRelation {
  id: string;
  fromClass: string;
  toClass: string;
  relationType: 'Composition (*--)' | 'Aggregation (o--)' | 'Dependency (..>)' | 'Association (-->)';
  label: string;
}

export interface SequenceStep {
  stepNo: number;
  fromActor: string;
  toActor: string;
  message: string;
  protocolOrSql: string;
  returnPayload: string;
  latencyNote: string;
  isHighlight?: boolean;
}

export interface SequenceScenario {
  id: string;
  title: string;
  sprintBadge: string;
  actors: Array<{ id: string; name: string; roleBadge: string }>;
  summary: string;
  steps: SequenceStep[];
  mermaidCode: string;
}

export interface UseCaseItem {
  id: string;
  code: string;
  title: string;
  endpoint: string;
  sprint: 'Minggu 1' | 'Minggu 2' | 'Minggu 3' | 'Minggu 4';
  actors: Array<'wisatawan_fe1' | 'wisatawan_fe2' | 'admin_dispar' | 'satgas_pungli' | 'petugas_bpbd'>;
  authRequirement: string;
  slaTarget: string;
}

export const ERD_ENTITIES_BE1_AND_BOUNDARY: ErdEntityNode[] = [
  // ==========================================================================
  // MINGGU 1 (SPRINT 1: HARI 1-5) — 4 TABEL UTAMA WISATA
  // ==========================================================================
  {
    id: 'tbl-destinations',
    tableName: 'destinasi_wisata',
    tableNumberLabel: 'Tabel #01 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 1',
    moduleGroup: 'Data Utama Tempat Wisata',
    spatialGeometry: 'GEOMETRY(Point, 4326)',
    indexes: [
      'indeks_lokasi_gps_wisata (Pencarian titik GPS cepat)',
      'indeks_filter_kategori_keramaian (Filter kategori & keramaian)',
      'indeks_pencarian_nama_wisata (Pencarian kata kunci nama)',
    ],
    description:
      'Tabel utama yang menyimpan 20 tempat wisata di Sumatera Barat, lengkap dengan titik koordinat peta (GPS), kode QR plang lokasi, tingkat keramaian, dan perkiraan biaya.',
    columns: [
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik tempat wisata (contoh: dest-001)' },
      { name: 'kode_url_slug', dataType: 'VARCHAR(120)', keyType: 'INDEX', nullable: false, description: 'Nama pendek untuk alamat link web (contoh: jam-gadang-bukittinggi)' },
      { name: 'nama_wisata', dataType: 'VARCHAR(160)', keyType: 'NORMAL', nullable: false, description: 'Nama tempat wisata' },
      { name: 'kabupaten_kota', dataType: 'VARCHAR(80)', keyType: 'INDEX', nullable: false, description: 'Lokasi Kabupaten atau Kota di Sumatera Barat' },
      { name: 'kategori_wisata', dataType: 'VARCHAR(40)', keyType: 'INDEX', nullable: false, description: 'Jenis wisata: alam, budaya, kuliner, nagari, atau bahari' },
      { name: 'titik_koordinat_gps', dataType: 'GEOMETRY(Point, 4326)', keyType: 'SPATIAL', nullable: false, description: 'Titik lokasi di peta (Latitude & Longitude) untuk hitung jarak otomatis' },
      { name: 'ketinggian_mdpl', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Ketinggian tempat dari permukaan laut (meter)' },
      { name: 'apakah_hidden_gem', dataType: 'BOOLEAN', keyType: 'INDEX', nullable: false, description: 'Penanda apakah ini tempat wisata tersembunyi (Hidden Gem)' },
      { name: 'kode_plang_qr', dataType: 'VARCHAR(64)', keyType: 'INDEX', nullable: false, description: 'Kode QR yang ditempel di plang lokasi wisata untuk di-scan pengunjung' },
      { name: 'tingkat_keramaian', dataType: 'VARCHAR(16)', keyType: 'INDEX', nullable: false, description: 'Kondisi keramaian: sepi, sedang, atau ramai' },
      { name: 'estimasi_biaya_rupiah', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Perkiraan total biaya sekali datang per orang (Rupiah)' },
      { name: 'waktu_diperbarui', dataType: 'TIMESTAMPTZ', keyType: 'NORMAL', nullable: false, description: 'Waktu terakhir data diubah' },
    ],
  },
  {
    id: 'tbl-medan-indicators',
    tableName: 'indikator_medan',
    tableNumberLabel: 'Tabel #02 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 1',
    moduleGroup: 'Info Kondisi Jalan & Sinyal HP',
    spatialGeometry: '1 Tempat Wisata = 1 Info Medan (1:1)',
    indexes: ['indeks_sinyal_dan_akses_mobil (Filter sinyal & akses mobil)'],
    description:
      'Menyimpan kondisi lapangan yang penting diketahui sebelum berangkat: jalanan bisa masuk mobil atau tidak, tanjakan curam, sinyal HP, toilet/musala, dan pengelola lokal (Pokdarwis).',
    columns: [
      { name: 'id_indikator_medan', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik data kondisi medan' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke ID tempat wisata di tabel destinasi_wisata' },
      { name: 'kondisi_jalan_akses', dataType: 'VARCHAR(80)', keyType: 'NORMAL', nullable: false, description: 'Kondisi jalan menuju lokasi (aspal mulus, berbatu, atau sempit)' },
      { name: 'bisa_masuk_mobil', dataType: 'BOOLEAN', keyType: 'INDEX', nullable: false, description: 'Bisa dilewati mobil keluarga/bus atau tidak' },
      { name: 'bisa_masuk_motor', dataType: 'BOOLEAN', keyType: 'NORMAL', nullable: false, description: 'Bisa dilewati motor atau tidak' },
      { name: 'kemiringan_tanjakan_derajat', dataType: 'NUMERIC(4,1)', keyType: 'NORMAL', nullable: false, description: 'Seberapa curam tanjakan jalannya (dalam derajat)' },
      { name: 'tingkat_kesulitan_jalan_kaki', dataType: 'VARCHAR(32)', keyType: 'NORMAL', nullable: false, description: 'Capek tidaknya jalan kaki: mudah, sedang, menantang, ekstrem' },
      { name: 'kualitas_sinyal_hp', dataType: 'VARCHAR(24)', keyType: 'INDEX', nullable: false, description: 'Kekuatan sinyal HP: 4G_stabil, 4G_lemah, 3G_intermiten, atau susah_sinyal' },
      { name: 'operator_sinyal_terbaik', dataType: 'VARCHAR(64)', keyType: 'NORMAL', nullable: false, description: 'Kartu seluler yang sinyalnya paling bagus di sana' },
      { name: 'ada_toilet_bersih', dataType: 'BOOLEAN', keyType: 'NORMAL', nullable: false, description: 'Ada toilet bersih atau tidak' },
      { name: 'ada_musala', dataType: 'BOOLEAN', keyType: 'NORMAL', nullable: false, description: 'Ada tempat salat (musala) atau tidak' },
      { name: 'nama_pengelola_pokdarwis', dataType: 'VARCHAR(120)', keyType: 'NORMAL', nullable: false, description: 'Nama kelompok warga lokal (Pokdarwis) yang mengelola tempat itu' },
    ],
  },
  {
    id: 'tbl-local-tips',
    tableName: 'tips_lokal_adat',
    tableNumberLabel: 'Tabel #03 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 1',
    moduleGroup: 'Tips Warga & Sopan Santun Adat',
    spatialGeometry: '1 Tempat Wisata punya Banyak Tips (1:N)',
    indexes: ['indeks_tips_per_destinasi (Pencarian tips per lokasi)'],
    description:
      'Berisi pesan penting untuk pengunjung: aturan sopan santun adat Minang di nagari tersebut, tips keselamatan, dan waktu paling pas buat datang.',
    columns: [
      { name: 'id_tips', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik tips lokal' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke tempat wisata pemilik tips ini' },
      { name: 'judul_tips', dataType: 'VARCHAR(140)', keyType: 'NORMAL', nullable: false, description: 'Judul singkat tips atau aturan adat' },
      { name: 'isi_penjelasan_tips', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Isi penjelasan lengkap tips tersebut' },
      { name: 'jenis_tips', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Kategori tips: etika_adat, keselamatan, waktu_terbaik, atau hemat_biaya' },
      { name: 'wajib_dibaca', dataType: 'BOOLEAN', keyType: 'INDEX', nullable: false, description: 'Kalau TRUE, tips ini wajib dimunculkan paling atas supaya dibaca dulu' },
    ],
  },
  {
    id: 'tbl-official-tariffs',
    tableName: 'tarif_resmi_perda',
    tableNumberLabel: 'Tabel #04 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 1',
    moduleGroup: 'Daftar Harga Resmi Pemerintah (Anti-Pungli)',
    spatialGeometry: '1 Tempat Wisata punya Daftar Tarif (1:N)',
    indexes: ['indeks_tarif_per_destinasi (Pencarian tarif per kategori)'],
    description:
      'Menyimpan daftar harga resmi sesuai aturan Pemda/Nagari (harga tiket masuk, parkir motor/mobil resmi, dan sewa pemandu) supaya wisatawan tidak kena getok harga.',
    columns: [
      { name: 'id_tarif', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik item harga resmi' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke tempat wisata terkait' },
      { name: 'nama_komponen_biaya', dataType: 'VARCHAR(120)', keyType: 'NORMAL', nullable: false, description: 'Nama biaya (contoh: Parkir Mobil Resmi atau Tiket Masuk Dewasa)' },
      { name: 'kategori_biaya', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Jenis biaya: tiket_masuk, parkir_resmi, pemandu, fasilitas, kuliner_wajar' },
      { name: 'harga_resmi_rupiah', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Harga resmi dalam Rupiah' },
      { name: 'satuan_tarif', dataType: 'VARCHAR(40)', keyType: 'NORMAL', nullable: false, description: 'Hitungan tarifnya (per orang, per mobil, atau per jam)' },
      { name: 'nomor_aturan_perda', dataType: 'VARCHAR(140)', keyType: 'NORMAL', nullable: false, description: 'Nomor aturan Perda atau SK Nagari yang jadi dasar harga resmi' },
      { name: 'apakah_biaya_wajib', dataType: 'BOOLEAN', keyType: 'NORMAL', nullable: false, description: 'Apakah biaya ini wajib dibayar saat masuk atau cuma tambahan opsional' },
    ],
  },

  // ==========================================================================
  // MINGGU 2 (SPRINT 2: HARI 6-10) — 5 TABEL TUR 360°, MAMPIR SEARAH & LAPOR PUNGLI
  // ==========================================================================
  {
    id: 'tbl-panorama-scenes',
    tableName: 'adegan_panorama_360',
    tableNumberLabel: 'Tabel #05 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 2',
    moduleGroup: 'Foto Keliling 360° Tempat Wisata',
    spatialGeometry: 'Kamera Panorama 360 Derajat',
    indexes: ['indeks_foto_360_utama (Cari foto 360 utama)'],
    description:
      'Menyimpan foto pemandangan 360 derajat yang bisa diputar-putar oleh pengguna untuk melihat suasana asli lokasi sebelum berangkat, lengkap dengan suara latar.',
    columns: [
      { name: 'id_adegan_360', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik titik kamera 360°' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke tempat wisata pemilik foto 360° ini' },
      { name: 'judul_sudut_pandang', dataType: 'VARCHAR(140)', keyType: 'NORMAL', nullable: false, description: 'Nama titik sudut pandang (contoh: Pelataran Utama Jam Gadang)' },
      { name: 'url_gambar_360', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Link file gambar panorama 360°' },
      { name: 'url_suara_latar', dataType: 'TEXT', keyType: 'NORMAL', nullable: true, description: 'Link suara suasana sekitar (suara angin, air terjun, atau musik saluang)' },
      { name: 'sudut_vertikal_awal', dataType: 'NUMERIC(5,2)', keyType: 'NORMAL', nullable: false, description: 'Arah kamera atas-bawah saat gambar pertama kali dibuka' },
      { name: 'sudut_horizontal_awal', dataType: 'NUMERIC(6,2)', keyType: 'NORMAL', nullable: false, description: 'Arah hadap kamera kiri-kanan saat pertama kali dibuka' },
      { name: 'jarak_zoom_awal', dataType: 'NUMERIC(5,2)', keyType: 'NORMAL', nullable: false, description: 'Jarak pandang / zoom awal kamera' },
      { name: 'kondisi_cuaca_foto', dataType: 'VARCHAR(60)', keyType: 'NORMAL', nullable: false, description: 'Keterangan cuaca saat foto diambil' },
      { name: 'apakah_foto_utama', dataType: 'BOOLEAN', keyType: 'INDEX', nullable: false, description: 'Penanda bahwa foto ini yang muncul pertama kali saat tombol 360° diklik' },
    ],
  },
  {
    id: 'tbl-panorama-hotspots',
    tableName: 'titik_pin_360',
    tableNumberLabel: 'Tabel #06 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 2',
    moduleGroup: 'Titik Pin yang Bisa Diklik di Dalam Foto 360°',
    spatialGeometry: 'Titik Koordinat di Dalam Layar 360°',
    indexes: ['indeks_pin_per_adegan_360 (Cari pin per foto 360)'],
    description:
      'Menyimpan titik-titik pin di dalam foto 360° yang bisa diklik pengunjung. Ada 4 jenis pin: info umum, pindah ke titik kamera lain, cerita budaya, dan peringatan bahaya.',
    columns: [
      { name: 'id_pin_360', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik titik pin' },
      { name: 'id_adegan_360', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'adegan_panorama_360.id_adegan_360', description: 'Menunjuk ke foto 360° tempat pin ini menempel' },
      { name: 'jenis_pin', dataType: 'VARCHAR(24)', keyType: 'INDEX', nullable: false, description: '4 Jenis Pin: info | navigasi | budaya | peringatan' },
      { name: 'posisi_atas_bawah', dataType: 'NUMERIC(5,2)', keyType: 'NORMAL', nullable: false, description: 'Posisi atas-bawah pin di dalam foto 360°' },
      { name: 'posisi_kiri_kanan', dataType: 'NUMERIC(6,2)', keyType: 'NORMAL', nullable: false, description: 'Posisi kiri-kanan pin di dalam foto 360°' },
      { name: 'label_singkat_pin', dataType: 'VARCHAR(120)', keyType: 'NORMAL', nullable: false, description: 'Tulisan singkat di atas pin' },
      { name: 'isi_penjelasan_pin', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Penjelasan lengkap yang muncul saat pin diklik' },
      { name: 'id_adegan_tujuan_pindah', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: true, references: 'adegan_panorama_360.id_adegan_360', description: 'Kalau jenis pin-nya navigasi, ini berisi ID foto 360° tujuan berpindah' },
      { name: 'tingkat_bahaya_pin', dataType: 'VARCHAR(20)', keyType: 'NORMAL', nullable: true, description: 'Tingkat bahaya kalau pin ini adalah pin peringatan' },
    ],
  },
  {
    id: 'tbl-shunlu-pois',
    tableName: 'tempat_mampir_searah',
    tableNumberLabel: 'Tabel #07 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 2',
    moduleGroup: 'Tempat Mampir Searah di Perjalanan (Shunlu)',
    spatialGeometry: 'GEOMETRY(Point, 4326)',
    indexes: ['indeks_gps_tempat_mampir (GIST)', 'indeks_koridor_waktu_belok (Filter jalur & waktu belok)'],
    description:
      'Daftar tempat mampir yang searah dengan rute perjalanan wisatawan (seperti Masjid, SPBU, Rumah Makan Asli, Pusat Oleh-oleh, atau Bengkel) lengkap dengan info tambahan waktu beloknya (+X menit).',
    columns: [
      { name: 'id_tempat_mampir', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik tempat mampir' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Tempat wisata tujuan utama yang dilewati jalur ini' },
      { name: 'nama_koridor_jalan', dataType: 'VARCHAR(120)', keyType: 'INDEX', nullable: false, description: 'Nama jalur perjalanan (contoh: Jalur Padang - Bukittinggi)' },
      { name: 'nama_tempat_mampir', dataType: 'VARCHAR(140)', keyType: 'NORMAL', nullable: false, description: 'Nama tempat mampir (contoh: Sate Mak Syukur atau Masjid Raya)' },
      { name: 'kategori_tempat_mampir', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Jenis tempat: masjid_musala, kuliner_pakem, spbu_rest, oleh_oleh, bengkel_darurat' },
      { name: 'titik_koordinat_gps', dataType: 'GEOMETRY(Point, 4326)', keyType: 'SPATIAL', nullable: false, description: 'Titik lokasi GPS tempat mampir tersebut' },
      { name: 'tambahan_waktu_belok_menit', dataType: 'INTEGER', keyType: 'INDEX', nullable: false, description: 'Berapa menit tambahan waktu kalau belok mampir ke sini (+X menit)' },
      { name: 'jarak_belok_meter', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Jarak belok dari jalan raya utama (dalam meter)' },
      { name: 'menu_atau_fasilitas_unggulan', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Menu makanan andalan atau fasilitas yang tersedia di sana' },
      { name: 'sudah_diverifikasi_pokdarwis', dataType: 'BOOLEAN', keyType: 'NORMAL', nullable: false, description: 'Tanda sudah dicek resmi oleh Pokdarwis dan bebas getok harga' },
    ],
  },
  {
    id: 'tbl-scenic-micro-maps',
    tableName: 'peta_mikro_kawasan',
    tableNumberLabel: 'Tabel #08 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 2',
    moduleGroup: 'Peta Jalan Kaki di Dalam Kawasan Wisata',
    spatialGeometry: 'GEOMETRY(Polygon & LineString, 4326)',
    indexes: ['indeks_peta_mikro_destinasi (1 Peta Mikro per Destinasi)'],
    description:
      'Peta khusus saat wisatawan sudah sampai di dalam lokasi: menampilkan batas area wisata, jalur jalan kaki yang aman, letak toilet/loket, serta titik pemutar cerita suara otomatis.',
    columns: [
      { name: 'id_peta_mikro', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik peta dalam kawasan' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke tempat wisata pemilik peta ini' },
      { name: 'judul_peta_kawasan', dataType: 'VARCHAR(140)', keyType: 'NORMAL', nullable: false, description: 'Judul peta kawasan' },
      { name: 'estimasi_durasi_jalan_kaki_menit', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Perkiraan waktu keliling jalan kaki sampai puas (menit)' },
      { name: 'total_jarak_jalan_kaki_meter', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Total panjang rute jalan kaki di dalam lokasi (meter)' },
      { name: 'poligon_batas_kawasan', dataType: 'JSONB', keyType: 'SPATIAL', nullable: false, description: 'Garis batas area kawasan wisata di peta' },
      { name: 'garis_rute_jalan_kaki', dataType: 'JSONB', keyType: 'SPATIAL', nullable: false, description: 'Garis rute jalan kaki yang disarankan' },
      { name: 'daftar_titik_fasilitas_internal', dataType: 'JSONB', keyType: 'NORMAL', nullable: false, description: 'Daftar titik penting di dalam lokasi (loket, toilet, spot foto, pos medis)' },
      { name: 'daftar_titik_pemicu_audio', dataType: 'JSONB', keyType: 'NORMAL', nullable: false, description: 'Titik GPS yang otomatis memutar cerita sejarah saat pengunjung lewat di dekatnya' },
    ],
  },
  {
    id: 'tbl-pungli-reports',
    tableName: 'laporan_pungli',
    tableNumberLabel: 'Tabel #09 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 2',
    moduleGroup: 'Laporan Pungli & Tindak Lanjut Satgas',
    spatialGeometry: 'GEOMETRY(Point, 4326)',
    indexes: ['indeks_gps_kejadian_pungli (GIST)', 'indeks_kuorum_laporan_destinasi (Hitung jumlah laporan)'],
    description:
      'Menyimpan aduan masyarakat kalau menemukan parkir liar atau getok harga. Nama pelapor bisa dirahasiakan (anonim), dan kalau ada minimal 3 laporan di tempat yang sama, tanda peringatan bahaya pungli otomatis menyala.',
    columns: [
      { name: 'id_laporan_pungli', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik laporan pungli' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Tempat wisata lokasi terjadinya pungli' },
      { name: 'id_pengguna_pelapor', dataType: 'VARCHAR(64)', keyType: 'FK', nullable: false, references: 'pengguna.id_pengguna (JWT BE-2)', description: 'ID pengguna yang melapor (otomatis disamarkan jadi kode acak kalau pilih anonim)' },
      { name: 'apakah_anonim', dataType: 'BOOLEAN', keyType: 'INDEX', nullable: false, description: 'Kalau TRUE, nama pelapor disembunyikan demi keamanan' },
      { name: 'kategori_pelanggaran', dataType: 'VARCHAR(40)', keyType: 'INDEX', nullable: false, description: 'Jenis pelanggaran: parkir_liar, tiket_tanpa_karcis, getok_harga_kuliner, pemaksaan_pemandu' },
      { name: 'nominal_diminta_oknum_rupiah', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Jumlah uang yang diminta paksa oleh oknum (Rupiah)' },
      { name: 'nominal_resmi_seharusnya_rupiah', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Harga resmi yang seharusnya menurut aturan Perda (Rupiah)' },
      { name: 'titik_gps_kejadian', dataType: 'GEOMETRY(Point, 4326)', keyType: 'SPATIAL', nullable: false, description: 'Titik GPS persis tempat kejadian pungli' },
      { name: 'url_foto_bukti', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Foto bukti karcis palsu atau lokasi kejadian' },
      { name: 'status_tindak_lanjut', dataType: 'VARCHAR(24)', keyType: 'INDEX', nullable: false, description: 'Status laporan: baru_masuk, peringatan_aktif, atau selesai_ditindak_satgas' },
      { name: 'catatan_penindakan_satgas', dataType: 'TEXT', keyType: 'NORMAL', nullable: true, description: 'Catatan hasil penertiban lapangan oleh petugas Satgas Saber Pungli' },
    ],
  },

  // ==========================================================================
  // MINGGU 3 (SPRINT 3: HARI 11-15) — RANKING JUJUR GPS, JALUR EKSTREM & BUDAYA
  // ==========================================================================
  {
    id: 'tbl-gaode-rankings',
    tableName: 'peringkat_kunjungan_gps',
    tableNumberLabel: 'Tabel #10a BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 3',
    moduleGroup: 'Peringkat Wisata Jujur dari GPS (Gaode Ranking)',
    spatialGeometry: 'Hitungan Kedatangan & Lama Kunjungan GPS',
    indexes: ['indeks_skor_peringkat_tertinggi (Urutan skor tertinggi)', 'indeks_tabel_ringkasan_peringkat (Tabel Ringkasan Cepat)'],
    description:
      'Menyusun peringkat tempat wisata terbaik bukan dari rating bintang (yang rawan buzzer/palsu), melainkan dari data nyata: berapa banyak orang yang benar-benar datang pakai navigasi GPS dan berapa lama mereka betah di sana.',
    columns: [
      { name: 'id_peringkat', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik data peringkat' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke tempat wisata yang dinilai' },
      { name: 'kategori_peringkat', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Kategori peringkat: keluarga, solo_backpacker, kuliner_otentik, fotografi_alam, ramah_lansia' },
      { name: 'jumlah_kedatangan_navigasi_30h', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Jumlah pengguna yang benar-benar sampai ke lokasi lewat navigasi (bobot nilai 45%)' },
      { name: 'rata_rata_lama_betah_menit', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Rata-rata berapa menit pengunjung betah berada di lokasi (bobot nilai 35%)' },
      { name: 'jumlah_pengunjung_unik_30h', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Jumlah pengunjung berbeda dalam 30 hari terakhir (bobot nilai 20%)' },
      { name: 'persentase_kunjungan_ulang', dataType: 'NUMERIC(5,2)', keyType: 'NORMAL', nullable: false, description: 'Persentase pengunjung yang datang lagi ke tempat ini' },
      { name: 'skor_total_perilaku', dataType: 'NUMERIC(5,2)', keyType: 'INDEX', nullable: false, description: 'Nilai total otomatis (0 sampai 100) untuk menentukan urutan juara' },
      { name: 'terverifikasi_bebas_ulasan_palsu', dataType: 'BOOLEAN', keyType: 'NORMAL', nullable: false, description: 'Jaminan bahwa nilai ini murni dari jejak kunjungan GPS, bukan komentar palsu' },
    ],
  },
  {
    id: 'tbl-hazard-sos',
    tableName: 'peringatan_bahaya_dan_sos',
    tableNumberLabel: 'Tabel #10b BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 3',
    moduleGroup: 'Info Bahaya Jalur Ekstrem & Tombol Darurat SOS',
    spatialGeometry: 'GEOMETRY(Point, 4326) + Radius Bahaya',
    indexes: ['indeks_gps_pusat_bahaya (Cek jarak ke titik bahaya)', 'indeks_waktu_panggilan_sos (Urutan waktu panggilan SOS)'],
    description:
      'Menyimpan peringatan bahaya langsung di 4 jalur rawan Sumatera Barat (Sitinjau Lauik, Lembah Anai, Kelok 9, Kelok 44) beserta saran jalan memutar yang aman, sekaligus mencatat panggilan tombol darurat SOS dari wisatawan.',
    columns: [
      { name: 'id_bahaya_atau_sos', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik peringatan bahaya atau sinyal SOS' },
      { name: 'kode_koridor_ekstrem', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Nama jalur ekstrem: sitinjau_lauik | lembah_anai | kelok_9 | kelok_44' },
      { name: 'jenis_bahaya_atau_darurat', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Jenis bahaya: longsor, kabut_tebal, banjir_lahar_dingin, jalan_licin_tanjakan' },
      { name: 'tingkat_kewaspadaan', dataType: 'VARCHAR(16)', keyType: 'INDEX', nullable: false, description: 'Tingkat bahaya: waspada | siaga | awas_tutup (jalan ditutup)' },
      { name: 'titik_gps_pusat_kejadian', dataType: 'GEOMETRY(Point, 4326)', keyType: 'SPATIAL', nullable: false, description: 'Titik lokasi pusat bencana atau titik GPS wisatawan yang menekan tombol SOS' },
      { name: 'radius_dampak_meter', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Jarak radius area bahaya (dalam meter)' },
      { name: 'saran_jalur_alternatif', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Saran jalur alternatif yang aman dilewati (misal: lewat Jalur Malalak)' },
      { name: 'instansi_pelapor_resmi', dataType: 'VARCHAR(80)', keyType: 'NORMAL', nullable: false, description: 'Instansi resmi yang memberi peringatan (BPBD Sumbar / Dishub / BMKG)' },
      { name: 'apakah_masih_aktif', dataType: 'BOOLEAN', keyType: 'INDEX', nullable: false, description: 'Penanda apakah bahaya tersebut masih berlangsung saat ini' },
    ],
  },
  {
    id: 'tbl-minang-culture',
    tableName: 'kamus_minang_dan_agenda_budaya',
    tableNumberLabel: 'Tabel #11 BE-1',
    owner: 'BE-1',
    sprint: 'Minggu 3',
    moduleGroup: 'Kamus Suara Bahasa Minang & Jadwal Pasar Nagari',
    spatialGeometry: 'Audio Cara Baca & Lokasi Acara Budaya',
    indexes: ['indeks_kategori_bahasa_minang (Filter topik bahasa)', 'indeks_tanggal_acara_budaya (Filter tanggal acara)'],
    description:
      'Berisi kumpulan kalimat bahasa Minang sehari-hari lengkap dengan cara baca per suku kata dan suara pengucapannya, ditambah jadwal acara adat serta Hari Pakan (hari pasar ramai di nagari).',
    columns: [
      { name: 'id_kamus_atau_agenda', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode unik kosakata Minang atau acara budaya' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: true, references: 'destinasi_wisata.id_destinasi', description: 'Tempat wisata lokasi diadakannya acara budaya (jika ada)' },
      { name: 'kategori_topik', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Topik kalimat: sapaan, tawar_menawar, kuliner, atau darurat' },
      { name: 'kalimat_indonesia_atau_acara', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Kalimat dalam Bahasa Indonesia (atau nama acara budaya)' },
      { name: 'terjemahan_bahasa_minang', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Terjemahan dalam Bahasa Minang' },
      { name: 'panduan_baca_suku_kata', dataType: 'VARCHAR(180)', keyType: 'NORMAL', nullable: false, description: 'Cara baca per penggal suku kata supaya mudah ditiru wisatawan luar' },
      { name: 'url_rekaman_suara', dataType: 'TEXT', keyType: 'NORMAL', nullable: false, description: 'Link suara rekaman orang Minang asli mengucapkan kalimat tersebut' },
      { name: 'jadwal_hari_pakan_nagari', dataType: 'VARCHAR(120)', keyType: 'INDEX', nullable: true, description: 'Hari buka pasar tradisional di nagari tersebut (contoh: Setiap Rabu & Sabtu)' },
    ],
  },

  // ==========================================================================
  // TABEL MILIK BE-2 (DITAMPILKAN SEBAGAI BATAS KERJA SAMA TIM)
  // ==========================================================================
  {
    id: 'tbl-be2-users',
    tableName: 'pengguna (Milik BE-2)',
    tableNumberLabel: 'Batas BE-2 #01',
    owner: 'BE-2',
    sprint: 'Boundary BE-2',
    moduleGroup: 'Akun Pengguna & Login (Dikerjakan BE-2)',
    spatialGeometry: 'Bukan Tabel Peta (Milik BE-2)',
    indexes: ['indeks_email_pengguna_unik (Milik BE-2)'],
    description:
      'Tabel akun login yang dikerjakan oleh teman tim BE-2. Anda (BE-1) tidak perlu membuat tabel ini, cukup membaca kode ID dan jabatan pengguna dari tiket login (JWT) yang dikirim aplikasi.',
    columns: [
      { name: 'id_pengguna', dataType: 'VARCHAR(64)', keyType: 'PK', nullable: false, description: 'ID pengguna yang otomatis terbaca dari tiket login (JWT)' },
      { name: 'nama_lengkap', dataType: 'VARCHAR(120)', keyType: 'NORMAL', nullable: false, description: 'Nama lengkap pengguna atau petugas' },
      { name: 'peran_jabatan', dataType: 'VARCHAR(32)', keyType: 'INDEX', nullable: false, description: 'Peran akun: wisatawan, admin_dispar, satgas_pungli, atau petugas_bpbd' },
    ],
  },
  {
    id: 'tbl-be2-group-rooms',
    tableName: 'ruang_grup_dan_voting (Milik BE-2)',
    tableNumberLabel: 'Batas BE-2 #02',
    owner: 'BE-2',
    sprint: 'Boundary BE-2',
    moduleGroup: 'Ruang Diskusi & Voting Liburan Bareng (BE-2)',
    spatialGeometry: 'Memakai ID Tempat Wisata dari BE-1',
    indexes: ['indeks_voting_destinasi (Milik BE-2)'],
    description:
      'Fitur ruang kumpul teman untuk voting mau liburan ke mana (dikerjakan BE-2 di Minggu 2). Tabel ini hanya meminjam kode ID tempat wisata dari tabel destinasi_wisata milik Anda.',
    columns: [
      { name: 'id_ruang_grup', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode ruang grup liburan (milik BE-2)' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke ID tempat wisata yang ada di tabel destinasi_wisata milik BE-1' },
      { name: 'jumlah_suara_voting', dataType: 'INTEGER', keyType: 'NORMAL', nullable: false, description: 'Jumlah suara hasil voting teman-teman satu grup' },
    ],
  },
  {
    id: 'tbl-be2-booking-escrows',
    tableName: 'pesanan_pemandu_escrow (Milik BE-2)',
    tableNumberLabel: 'Batas BE-2 #03',
    owner: 'BE-2',
    sprint: 'Boundary BE-2',
    moduleGroup: 'Pesan Pemandu Lokal & Rekening Bersama (BE-2)',
    spatialGeometry: 'Memakai ID Tempat Wisata dari BE-1',
    indexes: ['indeks_pesanan_destinasi (Milik BE-2)'],
    description:
      'Fitur pesan pemandu wisata dan pembayaran aman (dikerjakan BE-2 di Minggu 3). Tabel ini memakai patokan harga resmi dari tabel tarif_resmi_perda milik Anda.',
    columns: [
      { name: 'id_pesanan_escrow', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode pesanan pemandu wisata (milik BE-2)' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Menunjuk ke tempat wisata di tabel destinasi_wisata milik BE-1' },
      { name: 'status_dana_escrow', dataType: 'VARCHAR(32)', keyType: 'NORMAL', nullable: false, description: 'Status uang pembayaran (ditahan sementara, cair ke pemandu, atau dikembalikan)' },
    ],
  },
  {
    id: 'tbl-be2-digital-passports',
    tableName: 'paspor_digital_nagari (Milik BE-2)',
    tableNumberLabel: 'Batas BE-2 #04',
    owner: 'BE-2',
    sprint: 'Boundary BE-2',
    moduleGroup: 'Stempel Paspor Digital Nagari (BE-2)',
    spatialGeometry: 'Memakai Koordinat & Kode QR dari BE-1',
    indexes: ['indeks_paspor_pengguna_destinasi (Milik BE-2)'],
    description:
      'Fitur koleksi stempel kunjungan wisata (dikerjakan BE-2 di Minggu 4). Saat pengguna klaim stempel, BE-2 mengecek kebenaran lokasi GPS dan kode QR lewat data milik BE-1.',
    columns: [
      { name: 'id_stempel_paspor', dataType: 'VARCHAR(36)', keyType: 'PK', nullable: false, description: 'Kode stempel paspor digital (milik BE-2)' },
      { name: 'id_pengguna', dataType: 'VARCHAR(64)', keyType: 'FK', nullable: false, references: 'pengguna.id_pengguna', description: 'Pengguna pemilik buku paspor digital' },
      { name: 'id_destinasi', dataType: 'VARCHAR(36)', keyType: 'FK', nullable: false, references: 'destinasi_wisata.id_destinasi', description: 'Tempat wisata milik BE-1 yang berhasil dikunjungi' },
    ],
  },
];

export const ERD_RELATIONSHIPS: ErdRelationshipSpec[] = [
  {
    id: 'rel-01',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'indikator_medan',
    toColumn: 'id_destinasi',
    cardinality: '1:1',
    relationLabel: '1 tempat wisata punya 1 paket info kondisi jalan & sinyal HP',
    sprint: 'Minggu 1',
    isCrossBoundary: false,
  },
  {
    id: 'rel-02',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'tips_lokal_adat',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: '1 tempat wisata bisa punya banyak tips adat & keselamatan',
    sprint: 'Minggu 1',
    isCrossBoundary: false,
  },
  {
    id: 'rel-03',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'tarif_resmi_perda',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: '1 tempat wisata punya daftar harga resmi tiket, parkir, & pemandu',
    sprint: 'Minggu 1',
    isCrossBoundary: false,
  },
  {
    id: 'rel-04',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'adegan_panorama_360',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: '1 tempat wisata bisa punya beberapa titik foto keliling 360°',
    sprint: 'Minggu 2',
    isCrossBoundary: false,
  },
  {
    id: 'rel-05',
    fromTable: 'adegan_panorama_360',
    fromColumn: 'id_adegan_360',
    toTable: 'titik_pin_360',
    toColumn: 'id_adegan_360',
    cardinality: '1:N',
    relationLabel: '1 foto 360° punya banyak titik pin yang bisa diklik (4 jenis pin)',
    sprint: 'Minggu 2',
    isCrossBoundary: false,
  },
  {
    id: 'rel-06',
    fromTable: 'adegan_panorama_360',
    fromColumn: 'id_adegan_360',
    toTable: 'titik_pin_360',
    toColumn: 'id_adegan_tujuan_pindah',
    cardinality: '0..1:N',
    relationLabel: 'pin navigasi dipakai untuk berpindah ke titik foto 360° sebelahnya',
    sprint: 'Minggu 2',
    isCrossBoundary: false,
  },
  {
    id: 'rel-07',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'tempat_mampir_searah',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: '1 rute wisata punya daftar tempat mampir searah (+X menit)',
    sprint: 'Minggu 2',
    isCrossBoundary: false,
  },
  {
    id: 'rel-08',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'peta_mikro_kawasan',
    toColumn: 'id_destinasi',
    cardinality: '1:1',
    relationLabel: '1 tempat wisata punya 1 peta jalan kaki di dalam kawasan',
    sprint: 'Minggu 2',
    isCrossBoundary: false,
  },
  {
    id: 'rel-09',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'laporan_pungli',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: 'tempat wisata menerima laporan pungli (jika >= 3 laporan, tanda bahaya menyala)',
    sprint: 'Minggu 2',
    isCrossBoundary: false,
  },
  {
    id: 'rel-10',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'peringkat_kunjungan_gps',
    toColumn: 'id_destinasi',
    cardinality: '1:1',
    relationLabel: '1 tempat wisata punya 1 nilai peringkat jujur dari data kunjungan GPS',
    sprint: 'Minggu 3',
    isCrossBoundary: false,
  },
  {
    id: 'rel-11',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'kamus_minang_dan_agenda_budaya',
    toColumn: 'id_destinasi',
    cardinality: '0..1:N',
    relationLabel: 'tempat wisata yang menjadi lokasi acara adat atau pasar nagari',
    sprint: 'Minggu 3',
    isCrossBoundary: false,
  },
  // RELASI KERJA SAMA ANTARA BE-1 DAN BE-2
  {
    id: 'rel-12',
    fromTable: 'pengguna (Milik BE-2)',
    fromColumn: 'id_pengguna (JWT)',
    toTable: 'laporan_pungli',
    toColumn: 'id_pengguna_pelapor',
    cardinality: 'JWT-Claim',
    relationLabel: 'BE-1 membaca ID pelapor langsung dari tiket login (JWT) buatan BE-2',
    sprint: 'Kerja Sama BE-1 ↔ BE-2',
    isCrossBoundary: true,
  },
  {
    id: 'rel-13',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'ruang_grup_dan_voting (Milik BE-2)',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: 'Fitur voting grup di BE-2 meminjam ID tempat wisata dari BE-1',
    sprint: 'Kerja Sama BE-1 ↔ BE-2',
    isCrossBoundary: true,
  },
  {
    id: 'rel-14',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi',
    toTable: 'pesanan_pemandu_escrow (Milik BE-2)',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: 'Fitur pesan pemandu di BE-2 mengacu pada ID lokasi & harga resmi di BE-1',
    sprint: 'Kerja Sama BE-1 ↔ BE-2',
    isCrossBoundary: true,
  },
  {
    id: 'rel-15',
    fromTable: 'destinasi_wisata',
    fromColumn: 'id_destinasi & kode_plang_qr',
    toTable: 'paspor_digital_nagari (Milik BE-2)',
    toColumn: 'id_destinasi',
    cardinality: '1:N',
    relationLabel: 'Fitur stempel paspor di BE-2 mengecek kecocokan kode QR & lokasi ke BE-1',
    sprint: 'Kerja Sama BE-1 ↔ BE-2',
    isCrossBoundary: true,
  },
];

// ============================================================================
// SUITE 2: CLASS DIAGRAM GO (PENJELASAN MUDAH DIPAHAMI PER BAGIAN KODE)
// ============================================================================
export const GO_CLASS_DIAGRAM_NODES: GoClassNode[] = [
  {
    id: 'cls-jwt-middleware',
    className: 'StatelessJWTMiddleware',
    stereotype: '<<Middleware & Security>>',
    layer: 'middleware',
    sourceFile: 'backend/internal/be1_core/middleware_jwt.go',
    sprintRange: 'Minggu 1 – Minggu 4',
    description:
      'Bagian penjaga pintu login: tugasnya memeriksa apakah tiket login (JWT) pengguna asli atau palsu, serta mengecek jabatannya (apakah wisatawan biasa, Admin Dispar, Satgas Pungli, atau Petugas BPBD).',
    fields: [
      { visibility: '-', name: 'jwtSecretKey', type: '[]byte', tagOrNote: 'Kunci rahasia bersama untuk cek keaslian tiket login' },
      { visibility: '+', name: 'AllowedRoles', type: '[]string', tagOrNote: 'Daftar jabatan yang diizinkan mengakses fitur tertentu' },
    ],
    methods: [
      {
        visibility: '+',
        name: 'RequireAuth',
        params: 'next http.HandlerFunc',
        returnType: 'http.HandlerFunc',
        sprintOrigin: 'S1',
        description: 'Wajibkan pengguna sudah login sebelum boleh lanjut',
      },
      {
        visibility: '+',
        name: 'RequireRole',
        params: 'roles []string, next http.HandlerFunc',
        returnType: 'http.HandlerFunc',
        sprintOrigin: 'S1',
        description: 'Cek apakah jabatan pengguna sesuai (misal khusus Admin atau khusus Satgas)',
      },
      {
        visibility: '+',
        name: 'ExtractOptionalClaims',
        params: 'r *http.Request',
        returnType: '*JWTClaims',
        sprintOrigin: 'S2',
        description: 'Boleh dipakai tanpa login (khusus untuk Lapor Pungli Anonim & tombol darurat SOS)',
      },
    ],
  },
  {
    id: 'cls-rate-limiter',
    className: 'TokenBucketRateLimiter',
    stereotype: '<<Middleware & Security>>',
    layer: 'middleware',
    sourceFile: 'backend/internal/be1_core/ratelimit_security_day18.go',
    sprintRange: 'Minggu 4 (Hari 18)',
    description:
      'Bagian penangkal spam & peretas: membatasi orang yang iseng menekan tombol Lapor Pungli atau SOS berkali-kali dalam 1 menit, sekaligus memastikan titik GPS yang dikirim benar-benar berada di Sumatera Barat.',
    fields: [
      { visibility: '-', name: 'mu', type: 'sync.Mutex', tagOrNote: 'Pengunci memori supaya aman saat diakses bersamaan' },
      { visibility: '-', name: 'visitors', type: 'map[string]*visitorBucket', tagOrNote: 'Catatan jatah klik per alamat IP pengguna' },
      { visibility: '-', name: 'blockedSpamCount', type: 'uint64', tagOrNote: 'Jumlah percobaan spam yang berhasil ditolak' },
    ],
    methods: [
      {
        visibility: '+',
        name: 'AllowRequest',
        params: 'clientKey string, scope string, maxBurst float64, refillRate float64',
        returnType: 'RateLimitDecision',
        sprintOrigin: 'S4',
        description: 'Cek apakah pengguna masih punya jatah kirim data atau harus tunggu sebentar (HTTP 429)',
      },
      {
        visibility: '+',
        name: 'SanitizeAndValidateInput',
        params: 'raw string, maxLength int',
        returnType: '(string, error)',
        sprintOrigin: 'S4',
        description: 'Bersihkan teks kiriman pengguna dari kode berbahaya (anti-hack SQL/XSS)',
      },
      {
        visibility: '+',
        name: 'ValidateSumbarCoordinateBounds',
        params: 'lat float64, lng float64',
        returnType: 'error',
        sprintOrigin: 'S4',
        description: 'Pastikan titik koordinat GPS tidak melenceng keluar dari wilayah Sumatera Barat',
      },
    ],
  },
  {
    id: 'cls-ttl-cache',
    className: 'InMemoryTTLCache',
    stereotype: '<<HTTP Delivery & Cache>>',
    layer: 'handler',
    sourceFile: 'backend/internal/be1_core/cache_etag_day17.go',
    sprintRange: 'Minggu 4 (Hari 17)',
    description:
      'Bagian penyimpan memori cepat (Cache): menyimpan data foto 360° dan rute yang sering dibuka di memori RAM. Kalau datanya belum berubah, aplikasi cukup pakai data yang sudah ada tanpa perlu download ulang.',
    fields: [
      { visibility: '-', name: 'mu', type: 'sync.RWMutex', tagOrNote: 'Pengatur baca-tulis memori berkecepatan tinggi' },
      { visibility: '-', name: 'entries', type: 'map[string]CacheEntry', tagOrNote: 'Tempat menyimpan data sementara beserta sidik jari ETag' },
      { visibility: '-', name: 'hits / misses / invalidations', type: 'uint64', tagOrNote: 'Penghitung berapa kali memori cepat berhasil menghemat waktu' },
    ],
    methods: [
      {
        visibility: '+',
        name: 'Get',
        params: 'key string',
        returnType: '(CacheEntry, bool)',
        sprintOrigin: 'S4',
        description: 'Ambil data dari memori cepat kalau masa berlakunya belum habis',
      },
      {
        visibility: '+',
        name: 'Set',
        params: 'key string, payload []byte, ttl time.Duration',
        returnType: 'CacheEntry',
        sprintOrigin: 'S4',
        description: 'Simpan data ke memori cepat dan buatkan kode tanda pengenal unik (ETag)',
      },
      {
        visibility: '+',
        name: 'InvalidateByPrefix',
        params: 'prefix string',
        returnType: 'int',
        sprintOrigin: 'S4',
        description: 'Hapus memori lama secara otomatis saat Admin atau Satgas memperbarui data',
      },
      {
        visibility: '+',
        name: 'ServeWithETag',
        params: 'w http.ResponseWriter, r *http.Request, key string, ttl Duration, loader func()',
        returnType: 'void',
        sprintOrigin: 'S4',
        description: 'Kalau kode ETag di HP pengguna masih sama dengan di server, langsung balas "Data Belum Berubah (304)" dalam < 1.5 milidetik',
      },
    ],
  },
  {
    id: 'cls-handler-be1',
    className: 'HandlerBE1',
    stereotype: '<<HTTP Delivery & Cache>>',
    layer: 'handler',
    sourceFile: 'backend/internal/be1_core/handlers.go',
    sprintRange: 'Minggu 1 – Minggu 4 (24 Endpoint)',
    description:
      'Bagian pelayan utama (Controller): menerima semua permintaan dari layar aplikasi FE-1, FE-2, dan FS-1 pada ke-24 alamat API, lalu mengirimkan hasilnya dalam bentuk JSON.',
    fields: [
      { visibility: '-', name: 'repo', type: '*RepositoryBE1', tagOrNote: 'Terhubung ke pengambil data database (Repository)' },
      { visibility: '-', name: 'cache', type: '*InMemoryTTLCache', tagOrNote: 'Terhubung ke penyimpan memori cepat (Cache)' },
      { visibility: '-', name: 'limiter', type: '*TokenBucketRateLimiter', tagOrNote: 'Terhubung ke penangkal spam (Rate Limiter)' },
    ],
    methods: [
      {
        visibility: '+',
        name: 'HandleListDestinations / HandleGetDestinationDetail',
        params: 'w http.ResponseWriter, r *http.Request',
        returnType: 'void',
        sprintOrigin: 'S1',
        description: 'Melayani pencarian tempat wisata terdekat, info kondisi jalan/sinyal, tips adat, dan harga resmi Perda',
      },
      {
        visibility: '+',
        name: 'HandleGetPanoramaTour / HandleGetShunluPOIs / HandleGetMicroMap',
        params: 'w http.ResponseWriter, r *http.Request',
        returnType: 'void',
        sprintOrigin: 'S2',
        description: 'Melayani tampilan foto keliling 360° 4-Pin, tempat mampir searah (+X menit), dan peta jalan kaki dalam lokasi',
      },
      {
        visibility: '+',
        name: 'HandleSubmitPungliReport / HandleSatgasVerifyReport',
        params: 'w http.ResponseWriter, r *http.Request',
        returnType: 'void',
        sprintOrigin: 'S2',
        description: 'Melayani pengiriman aduan pungli dari wisatawan dan pembaruan status penindakan oleh Satgas',
      },
      {
        visibility: '+',
        name: 'HandleGetGaodeRanking / HandleCheckRouteHazards / HandleTriggerSOS',
        params: 'w http.ResponseWriter, r *http.Request',
        returnType: 'void',
        sprintOrigin: 'S3',
        description: 'Melayani urutan wisata terfavorit dari GPS, cek bahaya jalur ekstrem (Sitinjau Lauik dll), dan tombol darurat SOS',
      },
      {
        visibility: '+',
        name: 'HandleGetOfflineSpatialBundle / HandleRunSystemBenchmark / HandleGetOpenAPIContract',
        params: 'w http.ResponseWriter, r *http.Request',
        returnType: 'void',
        sprintOrigin: 'S4',
        description: 'Melayani unduhan paket peta offline (untuk daerah susah sinyal), tes kecepatan server (<100ms), dan daftar 24 API',
      },
    ],
  },
  {
    id: 'cls-repository-be1',
    className: 'RepositoryBE1',
    stereotype: '<<PostGIS Repository>>',
    layer: 'repository',
    sourceFile: 'backend/internal/be1_core/repository_postgis.go (+6 file modul)',
    sprintRange: 'Minggu 1 – Minggu 4',
    description:
      'Bagian pengolah database & peta (PostGIS): tempat semua perintah ambil data, hitung jarak antar-titik GPS, hitung nilai peringkat kunjungan, dan cek radius bencana dijalankan.',
    fields: [
      { visibility: '-', name: 'db', type: '*sql.DB', tagOrNote: 'Koneksi langsung ke database PostgreSQL + PostGIS' },
      { visibility: '-', name: 'mu', type: 'sync.RWMutex', tagOrNote: 'Pengaman saat membaca/mengubah data secara bersamaan' },
      { visibility: '-', name: 'destinations / scenes360 / shunluPOIs / pungliReports', type: 'Slice Structs', tagOrNote: 'Data 20 tempat wisata Sumatera Barat siap pakai' },
    ],
    methods: [
      {
        visibility: '+',
        name: 'QueryDestinationsSpatial',
        params: 'filter SpatialFilterParams',
        returnType: '([]DestinationCardDTO, error)',
        sprintOrigin: 'S1',
        description: 'Cari tempat wisata sesuai jarak radius GPS, kategori, sinyal HP, dan tingkat keramaian',
      },
      {
        visibility: '+',
        name: 'GetPanoramaTourBySlug',
        params: 'slug string',
        returnType: '(*PanoramaTourResponse, error)',
        sprintOrigin: 'S2',
        description: 'Ambil paket foto 360° lengkap dengan titik-titik pin interaktif di dalamnya',
      },
      {
        visibility: '+',
        name: 'CreatePungliReportAndCheckQuorum',
        params: 'req CreatePungliReportRequest',
        returnType: '(*PungliReport, bool, error)',
        sprintOrigin: 'S2',
        description: 'Simpan laporan pungli baru & otomatis nyalakan tanda bahaya kalau jumlah laporan sudah mencapai 3 atau lebih',
      },
      {
        visibility: '+',
        name: 'RecordGaodeTelemetryAndRecalculate',
        params: 'destID string, dwellMinutes int, arrived bool',
        returnType: '(*GaodeBehaviorRanking, error)',
        sprintOrigin: 'S3',
        description: 'Catat kedatangan & lama kunjungan GPS wisatawan, lalu hitung ulang skor peringkat tempat wisata tersebut',
      },
      {
        visibility: '+',
        name: 'EvaluateRouteHazardsSpatial',
        params: 'lat float64, lng float64, corridor string',
        returnType: '(*HazardCheckResponse, error)',
        sprintOrigin: 'S3',
        description: 'Cek apakah posisi GPS pengendara sedang mendekati titik longsor/kabut tebal & berikan saran jalan memutar',
      },
    ],
  },
  {
    id: 'cls-domain-models',
    className: 'DomainEntitiesBE1 (11 Tabel Structs)',
    stereotype: '<<Domain Struct / DTO>>',
    layer: 'domain',
    sourceFile: 'backend/internal/be1_core/models.go',
    sprintRange: 'Minggu 1 – Minggu 4',
    description:
      'Bagian cetakan data (Struct): mendefinisikan bentuk data dari ke-11 tabel database agar rapi saat dikirimkan sebagai JSON ke layar aplikasi.',
    fields: [
      { visibility: '+', name: 'Destination / MedanIndicator / LocalTip / OfficialTariff', type: 'Struct Minggu 1', tagOrNote: 'Cetakan data Tabel #01 sampai #04' },
      { visibility: '+', name: 'PanoramaScene / PanoramaHotspot / ShunluPOI / ScenicMicroMap / PungliReport', type: 'Struct Minggu 2', tagOrNote: 'Cetakan data Tabel #05 sampai #09' },
      { visibility: '+', name: 'GaodeBehaviorRanking / HazardAlert / SOSSignal / MinangPhrase / CulturalEvent', type: 'Struct Minggu 3', tagOrNote: 'Cetakan data Tabel #10a, #10b & #11' },
      { visibility: '+', name: 'OfflineSpatialBundle / SystemBenchmarkReport / OpenAPIContractSpec', type: 'Struct Minggu 4', tagOrNote: 'Cetakan data Paket Offline & Tes Kecepatan' },
    ],
    methods: [
      {
        visibility: '+',
        name: 'ComputeFairPriceStatus',
        params: 'demandedIDR int, officialIDR int',
        returnType: 'string',
        sprintOrigin: 'S1',
        description: 'Bandingkan harga yang diminta di lapangan dengan harga resmi Perda (apakah Wajar atau Kemahalan/Pungli)',
      },
      {
        visibility: '+',
        name: 'MaskAnonymousReporter',
        params: 'report PungliReport',
        returnType: 'PungliReport',
        sprintOrigin: 'S2',
        description: 'Ubah ID pelapor pungli menjadi kode samaran (ANON-xxx) supaya identitasnya aman saat ditampilkan ke publik',
      },
    ],
  },
];

export const GO_CLASS_RELATIONSHIPS: GoClassRelation[] = [
  {
    id: 'crel-1',
    fromClass: 'HandlerBE1',
    toClass: 'StatelessJWTMiddleware',
    relationType: 'Dependency (..>)',
    label: 'meminta bantuan penjaga login untuk cek izin akses pengguna',
  },
  {
    id: 'crel-2',
    fromClass: 'HandlerBE1',
    toClass: 'TokenBucketRateLimiter',
    relationType: 'Composition (*--)',
    label: 'memakai penangkal spam saat menerima laporan pungli & panggilan SOS',
  },
  {
    id: 'crel-3',
    fromClass: 'HandlerBE1',
    toClass: 'InMemoryTTLCache',
    relationType: 'Composition (*--)',
    label: 'menyimpan foto 360° & rute di memori cepat supaya tidak perlu loading berulang',
  },
  {
    id: 'crel-4',
    fromClass: 'HandlerBE1',
    toClass: 'RepositoryBE1',
    relationType: 'Aggregation (o--)',
    label: 'memanggil fungsi pengambil data peta & database untuk 24 alamat API',
  },
  {
    id: 'crel-5',
    fromClass: 'RepositoryBE1',
    toClass: 'DomainEntitiesBE1 (11 Tabel Structs)',
    relationType: 'Association (-->)',
    label: 'mengisi hasil pencarian database ke dalam cetakan data JSON',
  },
];

// ============================================================================
// SUITE 3: SEQUENCE DIAGRAMS (CERITA LANGKAH DEMI LANGKAH YANG MUDAH DIIKUTI)
// ============================================================================
export const SEQUENCE_SCENARIOS: SequenceScenario[] = [
  {
    id: 'seq-360-etag',
    title: 'Alur 1: Membuka Foto Keliling 360° & Cara Kerja Memori Cepat (Cache ETag)',
    sprintBadge: 'Minggu 2 & Minggu 4',
    summary:
      'Menceritakan apa yang terjadi saat wisatawan mengklik tombol Tur 360°: saat pertama kali dibuka server mengambil data dari database, namun saat dibuka kedua kalinya server langsung menjawab dalam < 1.5 milidetik karena datanya sudah disimpan di memori cepat.',
    actors: [
      { id: 'FE1', name: 'Layar Wisatawan (FE-1)', roleBadge: 'Pembuka Tur 360°' },
      { id: 'HDL', name: 'HandlerBE1', roleBadge: 'Pelayan API Go' },
      { id: 'CAC', name: 'InMemoryTTLCache', roleBadge: 'Memori Cepat (Cache)' },
      { id: 'REP', name: 'RepositoryBE1', roleBadge: 'Pengambil Database' },
    ],
    steps: [
      {
        stepNo: 1,
        fromActor: 'Layar Wisatawan (FE-1)',
        toActor: 'HandlerBE1',
        message: 'Minta data foto 360° Jam Gadang (GET /destinations/jam-gadang-bukittinggi/panorama-360)',
        protocolOrSql: 'Baru pertama kali buka halaman Tur 360°',
        returnPayload: '-',
        latencyNote: '0.0 ms',
      },
      {
        stepNo: 2,
        fromActor: 'HandlerBE1',
        toActor: 'InMemoryTTLCache',
        message: 'Cek dulu: apakah foto 360° Jam Gadang sudah ada di memori cepat?',
        protocolOrSql: 'Get("panorama:jam-gadang-bukittinggi")',
        returnPayload: 'Belum ada di memori (Cache MISS) -> lanjut ambil dari database',
        latencyNote: '0.2 ms',
      },
      {
        stepNo: 3,
        fromActor: 'HandlerBE1',
        toActor: 'RepositoryBE1',
        message: 'Ambil data foto 360° beserta ke-4 jenis titik pin dari database',
        protocolOrSql: 'Gabungkan tabel adegan_panorama_360 dan titik_pin_360',
        returnPayload: 'Data foto 360° + Pin Info, Pin Pindah Kamera, Pin Budaya, & Pin Peringatan',
        latencyNote: '5.4 ms',
      },
      {
        stepNo: 4,
        fromActor: 'HandlerBE1',
        toActor: 'InMemoryTTLCache',
        message: 'Simpan hasilnya ke memori cepat selama 5 menit & beri kode tanda pengenal (ETag)',
        protocolOrSql: 'Set("panorama:jam-gadang-bukittinggi", TTL=5 menit)',
        returnPayload: 'Tersimpan dengan kode ETag: W/"rancak-360-8f92a1c4"',
        latencyNote: '5.8 ms',
      },
      {
        stepNo: 5,
        fromActor: 'HandlerBE1',
        toActor: 'Layar Wisatawan (FE-1)',
        message: 'Kirimkan gambar 360° & titik pin ke layar pengguna (HTTP 200 OK)',
        protocolOrSql: 'Sertakan kode ETag supaya HP pengguna mengingat versi data ini',
        returnPayload: 'Layar menampilkan pemandangan 360° yang bisa diputar-putar',
        latencyNote: 'Total: 6.1 ms',
      },
      {
        stepNo: 6,
        fromActor: 'Layar Wisatawan (FE-1)',
        toActor: 'HandlerBE1',
        message: 'Wisatawan membuka lagi Tur 360° sambil menunjukkan kode ETag tadi',
        protocolOrSql: 'GET /panorama-360 (Header If-None-Match: W/"rancak-360-8f92a1c4")',
        returnPayload: '-',
        latencyNote: '0.0 ms',
        isHighlight: true,
      },
      {
        stepNo: 7,
        fromActor: 'HandlerBE1',
        toActor: 'InMemoryTTLCache',
        message: 'Cocokkan kode ETag -> Ternyata sama persis & belum ada perubahan!',
        protocolOrSql: 'Tidak perlu cek database & tidak perlu kirim ulang file besar',
        returnPayload: 'Langsung balas HTTP 304 (Pakai data yang sudah ada di HP, hemat kuota 98%!)',
        latencyNote: 'Total: 0.8 ms (Super Cepat)',
        isHighlight: true,
      },
    ],
    mermaidCode: `sequenceDiagram
    autonumber
    actor FE1 as Layar Wisatawan (FE-1)
    participant HDL as HandlerBE1 (Pelayan API)
    participant CAC as InMemoryTTLCache (Memori Cepat)
    participant REP as RepositoryBE1 (Database)

    FE1->>HDL: 1. Buka Tur 360 Jam Gadang (GET /panorama-360)
    HDL->>CAC: 2. Cek apakah sudah ada di memori cepat?
    CAC-->>HDL: Belum ada (Cache MISS)
    HDL->>REP: 3. Ambil foto 360 & 4 titik pin dari tabel database
    REP-->>HDL: Kirim data adegan_panorama_360 & titik_pin_360
    HDL->>CAC: 4. Simpan di memori cepat (5 menit) & buat kode ETag
    HDL-->>FE1: 5. Tampilkan foto 360 ke layar (HTTP 200 OK + Kode ETag)

    Note over FE1,CAC: Saat Dibuka Kedua Kalinya (Hemat Kuota & Instan)
    FE1->>HDL: 6. Buka lagi sambil kirim kode ETag tadi
    HDL->>CAC: 7. Cek kecocokan kode ETag di memori
    CAC-->>HDL: Cocok! Data belum berubah (Cache HIT)
    HDL-->>FE1: 8. Balas HTTP 304 (< 1.5 ms, langsung tampil tanpa download ulang)`,
  },
  {
    id: 'seq-pungli-satgas',
    title: 'Alur 2: Kirim Laporan Pungli Anonim, Penangkal Spam & Penindakan Satgas',
    sprintBadge: 'Minggu 2 & Minggu 4',
    summary:
      'Menceritakan bagaimana wisatawan melaporkan pungutan liar dengan aman (tanpa ketahuan namanya), bagaimana sistem menolak orang iseng yang melakukan spam laporan, hingga petugas Satgas turun menindaklanjuti.',
    actors: [
      { id: 'FE2', name: 'Wisatawan (FE-2)', roleBadge: 'Pelapor Pungli' },
      { id: 'LIM', name: 'TokenBucketLimiter', roleBadge: 'Penjaga Anti-Spam' },
      { id: 'REP', name: 'RepositoryBE1', roleBadge: 'Database & Hitung Kuorum' },
      { id: 'FS1', name: 'Petugas Satgas (FS-1)', roleBadge: 'Penindak Lapangan' },
    ],
    steps: [
      {
        stepNo: 1,
        fromActor: 'Wisatawan (FE-2)',
        toActor: 'TokenBucketLimiter',
        message: 'Kirim aduan pungli parkir Rp25.000 + foto bukti + pilih mode Anonim (POST /pungli-reports)',
        protocolOrSql: 'Penjaga mengecek apakah pengirim ini melakukan spam bertubi-tubi',
        returnPayload: 'Aman (Kalau kirim lebih dari 5 kali sengaja berturut-turut, otomatis ditolak HTTP 429)',
        latencyNote: '0.3 ms',
        isHighlight: true,
      },
      {
        stepNo: 2,
        fromActor: 'TokenBucketLimiter',
        toActor: 'RepositoryBE1',
        message: 'Bersihkan teks laporan & pastikan titik GPS benar berada di Sumatera Barat',
        protocolOrSql: 'SanitizeAndValidateInput() & ValidateSumbarCoordinateBounds()',
        returnPayload: 'Data laporan dinyatakan bersih dan lokasi GPS valid',
        latencyNote: '0.6 ms',
      },
      {
        stepNo: 3,
        fromActor: 'RepositoryBE1',
        toActor: 'RepositoryBE1',
        message: 'Samarkan nama pelapor menjadi kode acak "ANON-7F3A9C" lalu simpan ke tabel laporan_pungli',
        protocolOrSql: 'INSERT INTO laporan_pungli (...) + Hitung jumlah aduan di tempat wisata itu',
        returnPayload: 'Laporan tersimpan aman di database',
        latencyNote: '4.2 ms',
      },
      {
        stepNo: 4,
        fromActor: 'RepositoryBE1',
        toActor: 'Wisatawan (FE-2)',
        message: 'Berikan tanda terima laporan (Kalau sudah ada >= 3 aduan, lencana Peringatan Pungli otomatis menyala)',
        protocolOrSql: 'HTTP 201 Created (quorum_warning_active: true)',
        returnPayload: 'Wisatawan lain langsung melihat tanda hati-hati di tempat wisata tersebut',
        latencyNote: 'Total: 5.1 ms',
      },
      {
        stepNo: 5,
        fromActor: 'Petugas Satgas (FS-1)',
        toActor: 'RepositoryBE1',
        message: 'Petugas Satgas menertibkan oknum di lokasi & mengubah status laporan menjadi Selesai Ditindak',
        protocolOrSql: 'PATCH /api/v1/admin/pungli-reports/{id}/status (Status -> selesai_ditindak_satgas)',
        returnPayload: 'Catatan tindakan Satgas tampil resmi di aplikasi',
        latencyNote: 'Total: 3.9 ms',
        isHighlight: true,
      },
    ],
    mermaidCode: `sequenceDiagram
    autonumber
    actor FE2 as Wisatawan Pelapor (FE-2)
    participant LIM as Penangkal Spam (Rate Limiter)
    participant REP as Database BE-1 (laporan_pungli)
    actor FS1 as Petugas Satgas Pungli (FS-1)

    FE2->>LIM: 1. Kirim laporan pungli + foto bukti (pilih Anonim)
    alt Jika kirim spam berkali-kali (> 5x per menit)
        LIM-->>FE2: Tolak sementara (HTTP 429: Tunggu 15 detik)
    else Jika pengiriman wajar & titik GPS di Sumbar
        LIM->>REP: 2. Teruskan data laporan yang sudah dicek
        Note right of REP: Samarkan nama pelapor jadi kode ANON<br/>& cek apakah sudah ada >= 3 laporan
        REP-->>FE2: 3. Laporan diterima! Tanda peringatan pungli menyala (HTTP 201)
    end

    FS1->>LIM: 4. Satgas update hasil penertiban lapangan (PATCH /status)
    LIM->>REP: 5. Ubah status_tindak_lanjut jadi selesai_ditindak_satgas
    REP-->>FS1: 6. Status berhasil diperbarui (HTTP 200 OK)`,
  },
  {
    id: 'seq-gaode-telemetry',
    title: 'Alur 3: Cara Kerja Peringkat Jujur dari Kunjungan GPS (Gaode Ranking)',
    sprintBadge: 'Minggu 3 & Minggu 4',
    summary:
      'Menceritakan kenapa peringkat wisata di Rancak.in tidak bisa dicurangi dengan komentar palsu: nilainya dihitung otomatis saat pengguna benar-benar sampai di lokasi dan betah berlama-lama di sana.',
    actors: [
      { id: 'FE1', name: 'HP Wisatawan (FE-1)', roleBadge: 'Navigasi GPS' },
      { id: 'HDL', name: 'HandlerBE1', roleBadge: 'Penerima Sinyal Kunjungan' },
      { id: 'REP', name: 'RepositoryBE1', roleBadge: 'Penghitung Skor Jujur' },
      { id: 'MV', name: 'ringkasan_peringkat_gps', roleBadge: 'Tabel Peringkat Cepat' },
    ],
    steps: [
      {
        stepNo: 1,
        fromActor: 'HP Wisatawan (FE-1)',
        toActor: 'HandlerBE1',
        message: 'Kirim catatan otomatis: pengguna sudah sampai di lokasi & berada di sana selama 95 menit',
        protocolOrSql: 'POST /api/v1/gaode-ranking/telemetry (dwell_time_minutes: 95, arrived: true)',
        returnPayload: '-',
        latencyNote: '0.0 ms',
      },
      {
        stepNo: 2,
        fromActor: 'HandlerBE1',
        toActor: 'RepositoryBE1',
        message: 'Tambahkan jumlah kunjungan nyata & perbarui rata-rata lama kunjungan di tabel peringkat_kunjungan_gps',
        protocolOrSql: 'RecordGaodeTelemetryAndRecalculate("dest-001", 95 menit)',
        returnPayload: 'Data kunjungan terbaru tercatat',
        latencyNote: '2.1 ms',
      },
      {
        stepNo: 3,
        fromActor: 'RepositoryBE1',
        toActor: 'RepositoryBE1',
        message: 'Hitung ulang nilai total: 45% dari jumlah orang sampai + 35% dari lama betah + 20% pengunjung unik',
        protocolOrSql: 'Tanpa melihat bintang ulasan sama sekali (bebas manipulasi buzzer)',
        returnPayload: 'Nilai skor_total_perilaku = 96.80 dari 100',
        latencyNote: '2.8 ms',
        isHighlight: true,
      },
      {
        stepNo: 4,
        fromActor: 'RepositoryBE1',
        toActor: 'ringkasan_peringkat_gps',
        message: 'Segarkan daftar urutan juara supaya pengunjung lain langsung melihat peringkat terbaru',
        protocolOrSql: 'Perbarui tabel ringkasan_peringkat_gps',
        returnPayload: 'Urutan peringkat selesai diperbarui',
        latencyNote: '4.5 ms',
      },
      {
        stepNo: 5,
        fromActor: 'HandlerBE1',
        toActor: 'HP Wisatawan (FE-1)',
        message: 'Kirim balasan sukses beserta peringkat terbaru tempat wisata tersebut (HTTP 200 OK)',
        protocolOrSql: 'JSON Response',
        returnPayload: 'Skor terbaru tampil di papan peringkat aplikasi',
        latencyNote: 'Total: 4.9 ms',
      },
    ],
    mermaidCode: `sequenceDiagram
    autonumber
    actor FE1 as Navigasi HP Wisatawan (FE-1)
    participant HDL as HandlerBE1
    participant REP as Penghitung Skor Gaode (BE-1)
    participant MV as Tabel Peringkat Cepat

    FE1->>HDL: 1. Kirim data: sudah tiba di lokasi & menetap 95 menit
    HDL->>REP: 2. Catat tambahan kunjungan nyata di tabel peringkat_kunjungan_gps
    Note right of REP: Rumus Jujur Anti-Buzzer:<br/>45% Orang Sampai + 35% Lama Betah<br/>+ 20% Jumlah Pengunjung Unik
    REP->>MV: 3. Hitung ulang skor (96.8) & perbarui urutan juara
    MV-->>REP: Daftar juara terbaru siap
    REP-->>HDL: Kirim data peringkat baru
    HDL-->>FE1: 4. Tampilkan peringkat terbaru di layar (HTTP 200 OK)`,
  },
  {
    id: 'seq-hazard-sos',
    title: 'Alur 4: Peringatan Bahaya Jalur Ekstrem (Sitinjau Lauik) & Tombol Darurat SOS',
    sprintBadge: 'Minggu 3',
    summary:
      'Menceritakan bagaimana petugas BPBD/Dishub menyalakan alarm bahaya longsor/kabut di jalur ekstrem, bagaimana HP wisatawan yang mendekati lokasi otomatis mendapat saran jalan memutar, serta cara kerja tombol darurat SOS.',
    actors: [
      { id: 'FS1', name: 'Petugas BPBD/Dishub (FS-1)', roleBadge: 'Pengirim Info Bencana' },
      { id: 'FE1', name: 'Wisatawan di Jalan (FE-1)', roleBadge: 'Pengendara' },
      { id: 'HDL', name: 'HandlerBE1', roleBadge: 'Pelayan API Bahaya & SOS' },
      { id: 'REP', name: 'RepositoryBE1 (PostGIS)', roleBadge: 'Pengecek Jarak Peta' },
    ],
    steps: [
      {
        stepNo: 1,
        fromActor: 'Petugas BPBD/Dishub (FS-1)',
        toActor: 'HandlerBE1',
        message: 'Petugas menyalakan peringatan: Jalur Sitinjau Lauik sedang bahaya longsor / kabut tebal',
        protocolOrSql: 'POST /api/v1/admin/hazards/trigger (corridor: "sitinjau_lauik", status: "awas_tutup")',
        returnPayload: '-',
        latencyNote: '0.5 ms',
      },
      {
        stepNo: 2,
        fromActor: 'HandlerBE1',
        toActor: 'RepositoryBE1 (PostGIS)',
        message: 'Simpan titik lokasi bahaya beserta radius amannya (3,5 km) & siapkan saran jalur memutar',
        protocolOrSql: 'Simpan ke tabel peringatan_bahaya_dan_sos',
        returnPayload: 'Alarm bahaya Sitinjau Lauik aktif!',
        latencyNote: '3.2 ms',
        isHighlight: true,
      },
      {
        stepNo: 3,
        fromActor: 'Wisatawan di Jalan (FE-1)',
        toActor: 'HandlerBE1',
        message: 'Aplikasi wisatawan otomatis mengecek keamanan jalan di depan berdasarkan titik GPS mobilnya',
        protocolOrSql: 'GET /api/v1/hazards/route-check?lat=-0.948&lng=100.502',
        returnPayload: '-',
        latencyNote: '0.0 ms',
      },
      {
        stepNo: 4,
        fromActor: 'HandlerBE1',
        toActor: 'RepositoryBE1 (PostGIS)',
        message: 'Ukur jarak mobil wisatawan ke titik longsor menggunakan fitur peta PostGIS',
        protocolOrSql: 'Deteksi mobil sudah masuk radius 1,1 km dari titik_gps_pusat_kejadian!',
        returnPayload: 'Terdeteksi bahaya di depan!',
        latencyNote: '4.1 ms',
        isHighlight: true,
      },
      {
        stepNo: 5,
        fromActor: 'HandlerBE1',
        toActor: 'Wisatawan di Jalan (FE-1)',
        message: 'Kirim peringatan bahaya ke layar & arahkan lewat jalur alternatif yang aman',
        protocolOrSql: 'HTTP 200 OK (is_route_safe: false + saran_jalur_alternatif)',
        returnPayload: 'Pengendara terhindar dari jebakan macet/longsor',
        latencyNote: 'Total: 4.6 ms',
      },
      {
        stepNo: 6,
        fromActor: 'Wisatawan di Jalan (FE-1)',
        toActor: 'HandlerBE1',
        message: 'Jika mobil mogok di tanjakan curam, wisatawan menekan tombol merah SOS (POST /api/v1/sos)',
        protocolOrSql: 'Catat koordinat GPS darurat ke tabel peringatan_bahaya_dan_sos & cari posko derek/SAR terdekat',
        returnPayload: 'Terhubung ke Posko SAR & Derek Sitinjau Lauik (jarak 1,2 km)',
        latencyNote: 'Total: 5.3 ms',
      },
    ],
    mermaidCode: `sequenceDiagram
    autonumber
    actor FS1 as Petugas BPBD/Dishub (FS-1)
    actor FE1 as Wisatawan di Jalan (FE-1)
    participant HDL as HandlerBE1
    participant REP as Database Peta PostGIS (BE-1)

    FS1->>HDL: 1. Nyalakan alarm bahaya di Sitinjau Lauik (POST /hazards/trigger)
    HDL->>REP: 2. Simpan ke tabel peringatan_bahaya_dan_sos (radius 3,5 km)
    REP-->>FS1: Peringatan bahaya aktif (HTTP 201)

    FE1->>HDL: 3. HP Wisatawan otomatis cek kondisi jalan di depan (GET /route-check)
    HDL->>REP: 4. Ukur jarak mobil ke titik_gps_pusat_kejadian
    REP-->>HDL: Masuk area bahaya! Ambil saran_jalur_alternatif
    HDL-->>FE1: 5. Munculkan peringatan & garis rute alternatif di layar

    opt Jika Kendaraan Mogok / Darurat di Jalur Ekstrem
        FE1->>HDL: 6. Tekan tombol darurat SOS (POST /api/v1/sos + Titik GPS)
        HDL->>REP: 7. Simpan sinyal SOS & cari Posko SAR/Derek terdekat
        REP-->>FE1: 8. Bantuan dikirim dari Posko Sitinjau Lauik (1,2 km)
    end`,
  },
];

// ============================================================================
// SUITE 4: USE CASE DIAGRAM (SIAPA BISA MENGAKSES FITUR APA SAJA)
// ============================================================================
export const USE_CASE_ACTORS = [
  {
    id: 'wisatawan_fe1',
    name: 'Wisatawan Pencari Rute & 360° (FE-1)',
    roleClaim: 'Pengunjung Umum / Wisatawan',
    color: '#234B24',
    description: 'Mencari tempat wisata, mengecek kondisi jalan & sinyal HP, memutar foto 360°, melihat tempat mampir searah, cek bahaya jalan, tekan tombol SOS, dan download peta offline.',
  },
  {
    id: 'wisatawan_fe2',
    name: 'Wisatawan Cek Harga & Budaya (FE-2)',
    roleClaim: 'Pengunjung Umum / Pelapor Anonim',
    color: '#1E9E5A',
    description: 'Mengecek harga resmi tiket/parkir supaya tidak kena pungli, scan QR plang lokasi, mengirim laporan pungli secara rahasia (anonim), dan mendengar kamus suara bahasa Minang.',
  },
  {
    id: 'admin_dispar',
    name: 'Admin Dinas Pariwisata (FS-1)',
    roleClaim: 'Khusus Login: admin_dispar',
    color: '#5B6AE8',
    description: 'Menambah tempat wisata baru, mengubah daftar harga resmi Perda, mengunggah foto keliling 360° beserta titik pin-nya, dan memantau kecepatan server.',
  },
  {
    id: 'satgas_pungli',
    name: 'Petugas Satgas Pungli & BPBD (FS-1)',
    roleClaim: 'Khusus Login: satgas_pungli / petugas_bpbd',
    color: '#E85D1A',
    description: 'Memeriksa dan menindak laporan pungli yang masuk dari masyarakat, serta menyalakan peringatan bahaya jalan ekstrem (longsor/kabut tebal).',
  },
] as const;

export const USE_CASE_ITEMS_24: UseCaseItem[] = [
  // MINGGU 1 (7 Endpoint)
  {
    id: 'uc-01',
    code: 'UC-01',
    title: 'Cek Apakah Server & Database Aktif',
    endpoint: 'GET /api/v1/health',
    sprint: 'Minggu 1',
    actors: ['wisatawan_fe1', 'admin_dispar'],
    authRequirement: 'Terbuka untuk Umum',
    slaTarget: '< 5 ms',
  },
  {
    id: 'uc-02',
    code: 'UC-02',
    title: 'Cari & Saring 20 Tempat Wisata Sumatera Barat',
    endpoint: 'GET /api/v1/destinations',
    sprint: 'Minggu 1',
    actors: ['wisatawan_fe1', 'wisatawan_fe2'],
    authRequirement: 'Terbuka (Memori Cepat)',
    slaTarget: '< 25 ms',
  },
  {
    id: 'uc-03',
    code: 'UC-03',
    title: 'Lihat Detail Wisata, Info Jalan, Sinyal HP & Tips Adat',
    endpoint: 'GET /api/v1/destinations/:slug',
    sprint: 'Minggu 1',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Terbuka (Memori Cepat)',
    slaTarget: '< 20 ms',
  },
  {
    id: 'uc-04',
    code: 'UC-04',
    title: 'Cek Daftar Harga Resmi Tiket/Parkir & Scan Plang QR',
    endpoint: 'GET /api/v1/tariffs/fair-price',
    sprint: 'Minggu 1',
    actors: ['wisatawan_fe2', 'wisatawan_fe1'],
    authRequirement: 'Terbuka untuk Umum',
    slaTarget: '< 20 ms',
  },
  {
    id: 'uc-05',
    code: 'UC-05',
    title: 'Cek Keaslian Tiket Login (JWT) Pengguna',
    endpoint: 'GET /api/v1/auth/verify-jwt',
    sprint: 'Minggu 1',
    actors: ['wisatawan_fe1', 'admin_dispar', 'satgas_pungli'],
    authRequirement: 'Wajib Tiket Login (JWT)',
    slaTarget: '< 5 ms',
  },
  {
    id: 'uc-06',
    code: 'UC-06',
    title: 'Tambah Tempat Wisata Baru dari Dashboard Admin',
    endpoint: 'POST /api/v1/admin/destinations',
    sprint: 'Minggu 1',
    actors: ['admin_dispar'],
    authRequirement: 'Khusus Admin Dispar',
    slaTarget: '< 45 ms',
  },
  {
    id: 'uc-07',
    code: 'UC-07',
    title: 'Ubah Harga Resmi Tiket / Parkir Sesuai Aturan Baru',
    endpoint: 'PUT /api/v1/admin/tariffs/:id',
    sprint: 'Minggu 1',
    actors: ['admin_dispar'],
    authRequirement: 'Khusus Admin Dispar',
    slaTarget: '< 35 ms',
  },

  // MINGGU 2 (7 Endpoint)
  {
    id: 'uc-08',
    code: 'UC-08',
    title: 'Buka Foto Keliling 360° & Klik 4 Jenis Pin Info',
    endpoint: 'GET /api/v1/destinations/:slug/panorama-360',
    sprint: 'Minggu 2',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Terbuka (Cache ETag 304)',
    slaTarget: '< 15 ms',
  },
  {
    id: 'uc-09',
    code: 'UC-09',
    title: 'Upload Foto 360° Baru & Pasang Titik Pin dari Admin',
    endpoint: 'POST /api/v1/admin/panorama-360',
    sprint: 'Minggu 2',
    actors: ['admin_dispar'],
    authRequirement: 'Khusus Admin Dispar',
    slaTarget: '< 50 ms',
  },
  {
    id: 'uc-10',
    code: 'UC-10',
    title: 'Cari Tempat Mampir Searah di Perjalanan (+X Menit)',
    endpoint: 'GET /api/v1/routes/shunlu-pois',
    sprint: 'Minggu 2',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Terbuka (Cache ETag 304)',
    slaTarget: '< 25 ms',
  },
  {
    id: 'uc-11',
    code: 'UC-11',
    title: 'Buka Peta Jalan Kaki Dalam Lokasi & Cerita Suara',
    endpoint: 'GET /api/v1/destinations/:slug/micro-map',
    sprint: 'Minggu 2',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Terbuka (Cache ETag 304)',
    slaTarget: '< 20 ms',
  },
  {
    id: 'uc-12',
    code: 'UC-12',
    title: 'Lihat Daftar Aduan Pungli & Tanda Peringatan Lokasi',
    endpoint: 'GET /api/v1/pungli-reports',
    sprint: 'Minggu 2',
    actors: ['wisatawan_fe2', 'satgas_pungli', 'admin_dispar'],
    authRequirement: 'Terbuka (Nama Pelapor Disamarkan)',
    slaTarget: '< 25 ms',
  },
  {
    id: 'uc-13',
    code: 'UC-13',
    title: 'Kirim Aduan Pungli (Bisa Anonim) + Foto Bukti',
    endpoint: 'POST /api/v1/pungli-reports',
    sprint: 'Minggu 2',
    actors: ['wisatawan_fe2'],
    authRequirement: 'Dilindungi Anti-Spam',
    slaTarget: '< 45 ms',
  },
  {
    id: 'uc-14',
    code: 'UC-14',
    title: 'Update Status Penertiban Pungli oleh Petugas Satgas',
    endpoint: 'PATCH /api/v1/admin/pungli-reports/:id/status',
    sprint: 'Minggu 2',
    actors: ['satgas_pungli', 'admin_dispar'],
    authRequirement: 'Khusus Satgas Pungli',
    slaTarget: '< 35 ms',
  },

  // MINGGU 3 (7 Endpoint)
  {
    id: 'uc-15',
    code: 'UC-15',
    title: 'Lihat Urutan Wisata Terfavorit dari Kunjungan GPS (Gaode)',
    endpoint: 'GET /api/v1/destinations/gaode-ranking',
    sprint: 'Minggu 3',
    actors: ['wisatawan_fe1', 'wisatawan_fe2'],
    authRequirement: 'Terbuka (Memori Cepat)',
    slaTarget: '< 15 ms',
  },
  {
    id: 'uc-16',
    code: 'UC-16',
    title: 'Catat Otomatis Kedatangan & Lama Kunjungan GPS',
    endpoint: 'POST /api/v1/gaode-ranking/telemetry',
    sprint: 'Minggu 3',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Dikirim Otomatis oleh Aplikasi',
    slaTarget: '< 30 ms',
  },
  {
    id: 'uc-17',
    code: 'UC-17',
    title: 'Cek Bahaya Jalur Ekstrem di Depan & Saran Jalan Memutar',
    endpoint: 'GET /api/v1/hazards/route-check',
    sprint: 'Minggu 3',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Terbuka untuk Umum',
    slaTarget: '< 25 ms',
  },
  {
    id: 'uc-18',
    code: 'UC-18',
    title: 'Nyalakan Peringatan Bencana / Penutupan Jalan Ekstrem',
    endpoint: 'POST /api/v1/admin/hazards/trigger',
    sprint: 'Minggu 3',
    actors: ['satgas_pungli', 'admin_dispar'],
    authRequirement: 'Khusus Petugas BPBD / Admin',
    slaTarget: '< 35 ms',
  },
  {
    id: 'uc-19',
    code: 'UC-19',
    title: 'Tekan Tombol Darurat SOS GPS & Cari Posko Bantuan Terdekat',
    endpoint: 'POST /api/v1/sos',
    sprint: 'Minggu 3',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Dilindungi Anti-Spam',
    slaTarget: '< 30 ms',
  },
  {
    id: 'uc-20',
    code: 'UC-20',
    title: 'Dengarkan Cara Bicara Bahasa Minang Sehari-hari',
    endpoint: 'GET /api/v1/culture/minang-phrases',
    sprint: 'Minggu 3',
    actors: ['wisatawan_fe2', 'wisatawan_fe1'],
    authRequirement: 'Terbuka (Memori Cepat)',
    slaTarget: '< 15 ms',
  },
  {
    id: 'uc-21',
    code: 'UC-21',
    title: 'Lihat Jadwal Acara Adat & Hari Pasar Tradisional (Hari Pakan)',
    endpoint: 'GET /api/v1/culture/events',
    sprint: 'Minggu 3',
    actors: ['wisatawan_fe1', 'wisatawan_fe2'],
    authRequirement: 'Terbuka (Memori Cepat)',
    slaTarget: '< 15 ms',
  },

  // MINGGU 4 (3 Endpoint Penutup -> Genap 24 Endpoint)
  {
    id: 'uc-22',
    code: 'UC-22',
    title: 'Download Paket Peta & Panduan Offline (Untuk Daerah Susah Sinyal)',
    endpoint: 'GET /api/v1/spatial/offline-bundle',
    sprint: 'Minggu 4',
    actors: ['wisatawan_fe1'],
    authRequirement: 'Terbuka (Cache ETag 304)',
    slaTarget: '< 20 ms',
  },
  {
    id: 'uc-23',
    code: 'UC-23',
    title: 'Tes Kecepatan Server (<100ms) & Statistik Penghematan Cache',
    endpoint: 'GET /api/v1/admin/system/benchmark',
    sprint: 'Minggu 4',
    actors: ['admin_dispar'],
    authRequirement: 'Khusus Admin Dispar',
    slaTarget: '< 35 ms',
  },
  {
    id: 'uc-24',
    code: 'UC-24',
    title: 'Buka Daftar Lengkap 24 Alamat API milik BE-1',
    endpoint: 'GET /api/v1/system/openapi-contract',
    sprint: 'Minggu 4',
    actors: ['admin_dispar', 'wisatawan_fe1'],
    authRequirement: 'Terbuka untuk Tim Developer',
    slaTarget: '< 15 ms',
  },
];

// ============================================================================
// KODE MERMAID.JS ERD DENGAN NAMA TABEL & KOLOM BAHASA INDONESIA
// ============================================================================
export const MERMAID_ERD_CODE = `erDiagram
    %% ========================================================================
    %% ERD BACKEND 1 (BE-1: CORE & SPASIAL) — NAMA TABEL & KOLOM BAHASA INDONESIA
    %% ========================================================================

    DESTINASI_WISATA {
        varchar id_destinasi PK "Kode unik wisata (dest-001..020)"
        varchar kode_url_slug UK "Alamat link web"
        varchar nama_wisata "Nama tempat wisata"
        varchar kabupaten_kota "Lokasi Kab/Kota di Sumbar"
        varchar kategori_wisata "alam | budaya | kuliner | nagari | bahari"
        geometry_point titik_koordinat_gps "Titik koordinat peta GPS"
        int ketinggian_mdpl "Ketinggian tempat (mdpl)"
        boolean apakah_hidden_gem "Penanda wisata tersembunyi"
        varchar kode_plang_qr UK "Kode plang QR di lokasi"
        varchar tingkat_keramaian "sepi | sedang | ramai"
        int estimasi_biaya_rupiah "Perkiraan biaya per orang"
        timestamptz waktu_diperbarui "Waktu terakhir data diubah"
    }

    INDIKATOR_MEDAN {
        varchar id_indikator_medan PK
        varchar id_destinasi FK "1:1 ke destinasi_wisata"
        varchar kondisi_jalan_akses "Kondisi aspal/jalan"
        boolean bisa_masuk_mobil "Bisa masuk mobil atau tidak"
        boolean bisa_masuk_motor "Bisa masuk motor atau tidak"
        numeric kemiringan_tanjakan_derajat "Kecuraman tanjakan"
        varchar tingkat_kesulitan_jalan_kaki "mudah | sedang | menantang"
        varchar kualitas_sinyal_hp "4G_stabil | 4G_lemah | susah_sinyal"
        varchar operator_sinyal_terbaik "Sinyal kartu paling bagus"
        boolean ada_toilet_bersih "Ada toilet bersih"
        boolean ada_musala "Ada musala"
        varchar nama_pengelola_pokdarwis "Nama pengelola lokal"
    }

    TIPS_LOKAL_ADAT {
        varchar id_tips PK
        varchar id_destinasi FK
        varchar judul_tips "Judul tips"
        text isi_penjelasan_tips "Isi aturan sopan santun adat / keselamatan"
        varchar jenis_tips "etika_adat | keselamatan | waktu_terbaik"
        boolean wajib_dibaca "Wajib baca sebelum berangkat"
    }

    TARIF_RESMI_PERDA {
        varchar id_tarif PK
        varchar id_destinasi FK
        varchar nama_komponen_biaya "Tiket / Parkir / Pemandu"
        varchar kategori_biaya "tiket_masuk | parkir_resmi | pemandu"
        int harga_resmi_rupiah "Harga resmi pemerintah (Rp)"
        varchar satuan_tarif "per orang | per mobil | per jam"
        varchar nomor_aturan_perda "Nomor aturan Perda / Nagari"
        boolean apakah_biaya_wajib "Wajib atau opsional"
    }

    ADEGAN_PANORAMA_360 {
        varchar id_adegan_360 PK
        varchar id_destinasi FK
        varchar judul_sudut_pandang "Nama sudut pandang 360"
        text url_gambar_360 "Link gambar 360 derajat"
        text url_suara_latar "Link suara suasana alam"
        numeric sudut_vertikal_awal "Arah kamera atas-bawah"
        numeric sudut_horizontal_awal "Arah kamera kiri-kanan"
        numeric jarak_zoom_awal "Zoom awal kamera"
        boolean apakah_foto_utama "Foto 360 utama"
    }

    TITIK_PIN_360 {
        varchar id_pin_360 PK
        varchar id_adegan_360 FK
        varchar jenis_pin "info | navigasi | budaya | peringatan"
        numeric posisi_atas_bawah
        numeric posisi_kiri_kanan
        varchar label_singkat_pin "Tulisan di atas pin"
        text isi_penjelasan_pin "Cerita saat pin diklik"
        varchar id_adegan_tujuan_pindah FK "Tujuan pindah foto 360"
    }

    TEMPAT_MAMPIR_SEARAH {
        varchar id_tempat_mampir PK
        varchar id_destinasi FK
        varchar nama_koridor_jalan "Nama jalur jalan raya"
        varchar nama_tempat_mampir "Nama tempat mampir"
        varchar kategori_tempat_mampir "masjid_musala | kuliner_pakem | spbu_rest"
        geometry_point titik_koordinat_gps "Titik GPS tempat mampir"
        int tambahan_waktu_belok_menit "Tambahan waktu belok (+X menit)"
        int jarak_belok_meter "Jarak belok dari jalan utama"
    }

    PETA_MIKRO_KAWASAN {
        varchar id_peta_mikro PK
        varchar id_destinasi FK
        varchar judul_peta_kawasan "Nama peta dalam lokasi"
        jsonb poligon_batas_kawasan "Garis batas kawasan wisata"
        jsonb garis_rute_jalan_kaki "Garis jalur jalan kaki"
        jsonb daftar_titik_fasilitas_internal "Titik loket, toilet, & spot foto"
        jsonb daftar_titik_pemicu_audio "Titik pemutar cerita suara otomatis"
    }

    LAPORAN_PUNGLI {
        varchar id_laporan_pungli PK
        varchar id_destinasi FK
        varchar id_pengguna_pelapor FK "ID pelapor (Disamarkan jika Anonim)"
        boolean apakah_anonim "Mode rahasia identitas"
        varchar kategori_pelanggaran "Jenis pungli / getok harga"
        int nominal_diminta_oknum_rupiah "Harga yang diminta oknum"
        int nominal_resmi_seharusnya_rupiah "Harga resmi seharusnya"
        geometry_point titik_gps_kejadian "Titik GPS kejadian pungli"
        text url_foto_bukti "Foto bukti"
        varchar status_tindak_lanjut "baru_masuk | peringatan_aktif | selesai_ditindak_satgas"
        text catatan_penindakan_satgas "Catatan penertiban Satgas"
    }

    PERINGKAT_KUNJUNGAN_GPS {
        varchar id_peringkat PK
        varchar id_destinasi FK
        varchar kategori_peringkat "Kategori peringkat"
        int jumlah_kedatangan_navigasi_30h "Jumlah orang sampai (45%)"
        int rata_rata_lama_betah_menit "Rata-rata lama betah (35%)"
        int jumlah_pengunjung_unik_30h "Jumlah pengunjung unik (20%)"
        numeric skor_total_perilaku "Nilai akhir otomatis (0-100)"
    }

    PERINGATAN_BAHAYA_DAN_SOS {
        varchar id_bahaya_atau_sos PK
        varchar kode_koridor_ekstrem "sitinjau_lauik | lembah_anai | kelok_9 | kelok_44"
        varchar jenis_bahaya_atau_darurat "longsor | kabut_tebal | banjir_lahar"
        varchar tingkat_kewaspadaan "waspada | siaga | awas_tutup"
        geometry_point titik_gps_pusat_kejadian "Titik pusat bahaya / SOS"
        int radius_dampak_meter "Jarak radius bahaya (meter)"
        text saran_jalur_alternatif "Saran jalan memutar yang aman"
        boolean apakah_masih_aktif "Masih berlangsung atau sudah aman"
    }

    KAMUS_MINANG_DAN_AGENDA_BUDAYA {
        varchar id_kamus_atau_agenda PK
        varchar id_destinasi FK "Lokasi acara budaya"
        varchar kategori_topik "Topik kalimat / acara"
        text kalimat_indonesia_atau_acara "Kalimat Bahasa Indonesia"
        text terjemahan_bahasa_minang "Kalimat Bahasa Minang"
        varchar panduan_baca_suku_kata "Cara baca per suku kata"
        text url_rekaman_suara "Suara contoh pengucapan"
        varchar jadwal_hari_pakan_nagari "Jadwal hari pasar nagari"
    }

    %% TABEL MILIK BE-2 (BATAS KERJA SAMA TIM)
    PENGGUNA_BE2 {
        varchar id_pengguna PK "Tabel akun milik BE-2"
        varchar peran_jabatan "wisatawan | admin_dispar | satgas_pungli | petugas_bpbd"
    }
    RUANG_GRUP_DAN_VOTING_BE2 {
        varchar id_ruang_grup PK "Fitur voting grup milik BE-2"
        varchar id_destinasi FK "Meminjam ID wisata dari BE-1"
    }
    PESANAN_PEMANDU_ESCROW_BE2 {
        varchar id_pesanan_escrow PK "Fitur pesan pemandu milik BE-2"
        varchar id_destinasi FK "Meminjam ID wisata dari BE-1"
    }
    PASPOR_DIGITAL_NAGARI_BE2 {
        varchar id_stempel_paspor PK "Fitur paspor stempel milik BE-2"
        varchar id_destinasi FK "Cek lokasi & kode QR ke BE-1"
    }

    DESTINASI_WISATA ||--|| INDIKATOR_MEDAN : "1:1 info kondisi jalan & sinyal"
    DESTINASI_WISATA ||--o{ TIPS_LOKAL_ADAT : "1:N punya banyak tips adat"
    DESTINASI_WISATA ||--o{ TARIF_RESMI_PERDA : "1:N punya daftar harga resmi"
    DESTINASI_WISATA ||--o{ ADEGAN_PANORAMA_360 : "1:N punya foto keliling 360"
    ADEGAN_PANORAMA_360 ||--o{ TITIK_PIN_360 : "1:N punya 4 jenis titik pin"
    DESTINASI_WISATA ||--o{ TEMPAT_MAMPIR_SEARAH : "1:N punya tempat mampir searah"
    DESTINASI_WISATA ||--|| PETA_MIKRO_KAWASAN : "1:1 punya peta jalan kaki"
    DESTINASI_WISATA ||--o{ LAPORAN_PUNGLI : "1:N menerima laporan pungli"
    DESTINASI_WISATA ||--|| PERINGKAT_KUNJUNGAN_GPS : "1:1 punya nilai peringkat GPS"
    DESTINASI_WISATA ||--o{ KAMUS_MINANG_DAN_AGENDA_BUDAYA : "0..1:N lokasi acara adat"

    PENGGUNA_BE2 ||--o{ LAPORAN_PUNGLI : "Baca ID dari tiket login JWT"
    DESTINASI_WISATA ||--o{ RUANG_GRUP_DAN_VOTING_BE2 : "Dipakai fitur grup BE-2"
    DESTINASI_WISATA ||--o{ PESANAN_PEMANDU_ESCROW_BE2 : "Dipakai fitur booking BE-2"
    DESTINASI_WISATA ||--o{ PASPOR_DIGITAL_NAGARI_BE2 : "Dipakai fitur paspor BE-2"`;

export const MERMAID_CLASS_DIAGRAM_CODE = `classDiagram
    %% ========================================================================
    %% CLASS DIAGRAM GO (BAGIAN-BAGIAN KODE BE-1) — MINGGU 1 S/D 4
    %% ========================================================================

    class StatelessJWTMiddleware {
        <<Penjaga Pintu Login>>
        -jwtSecretKey []byte
        +AllowedRoles []string
        +RequireAuth(next http.HandlerFunc) http.HandlerFunc
        +RequireRole(roles []string, next http.HandlerFunc) http.HandlerFunc
        +ExtractOptionalClaims(r *http.Request) *JWTClaims
    }

    class TokenBucketRateLimiter {
        <<Penangkal Spam & Peretas>>
        -mu sync.Mutex
        -visitors map~string~*visitorBucket
        -blockedSpamCount uint64
        +AllowRequest(clientKey, scope string, burst, rate float64) RateLimitDecision
        +SanitizeAndValidateInput(raw string, maxLen int) (string, error)
        +ValidateSumbarCoordinateBounds(lat, lng float64) error
    }

    class InMemoryTTLCache {
        <<Penyimpan Memori Cepat (Cache)>>
        -mu sync.RWMutex
        -entries map~string~CacheEntry
        -hits uint64
        -misses uint64
        +Get(key string) (CacheEntry, bool)
        +Set(key string, payload []byte, ttl Duration) CacheEntry
        +InvalidateByPrefix(prefix string) int
        +ServeWithETag(w ResponseWriter, r *Request, key string, ttl Duration, loader func())
    }

    class HandlerBE1 {
        <<Pelayan Utama 24 Alamat API>>
        -repo *RepositoryBE1
        -cache *InMemoryTTLCache
        -limiter *TokenBucketRateLimiter
        +RegisterRoutes(mux *http.ServeMux)
        +HandleListDestinations(w, r)
        +HandleGetDestinationDetail(w, r)
        +HandleGetPanoramaTour(w, r)
        +HandleGetShunluPOIs(w, r)
        +HandleGetMicroMap(w, r)
        +HandleSubmitPungliReport(w, r)
        +HandleSatgasVerifyReport(w, r)
        +HandleGetGaodeRanking(w, r)
        +HandleCheckRouteHazards(w, r)
        +HandleTriggerSOS(w, r)
        +HandleGetOfflineSpatialBundle(w, r)
        +HandleRunSystemBenchmark(w, r)
        +HandleGetOpenAPIContract(w, r)
    }

    class RepositoryBE1 {
        <<Pengolah Database & Peta PostGIS>>
        -db *sql.DB
        -mu sync.RWMutex
        +QueryDestinationsSpatial(filter SpatialFilterParams) ([]DestinationCardDTO, error)
        +GetDestinationDetailBySlug(slug string) (*DestinationDetailAggregate, error)
        +GetPanoramaTourBySlug(slug string) (*PanoramaTourResponse, error)
        +QueryShunluPOIsAlongCorridor(corridor, category string, maxDetour int) ([]ShunluPOI, error)
        +CreatePungliReportAndCheckQuorum(req CreatePungliReportRequest) (*PungliReport, bool, error)
        +RecordGaodeTelemetryAndRecalculate(destID string, dwell int, arrived bool) (*GaodeBehaviorRanking, error)
        +EvaluateRouteHazardsSpatial(lat, lng float64, corridor string) (*HazardCheckResponse, error)
        +CreateSOSSignalAndFindNearestPost(req CreateSOSRequest) (*SOSSignal, error)
    }

    class DomainEntitiesBE1 {
        <<Cetakan Data 11 Tabel>>
        +Destination
        +MedanIndicator
        +LocalTip
        +OfficialTariff
        +PanoramaScene
        +PanoramaHotspot
        +ShunluPOI
        +ScenicMicroMap
        +PungliReport
        +GaodeBehaviorRanking
        +HazardAlert
        +SOSSignal
        +MinangPhrase
        +CulturalEvent
        +ComputeFairPriceStatus(demanded, official int) string
        +MaskAnonymousReporter(report PungliReport) PungliReport
    }

    HandlerBE1 ..> StatelessJWTMiddleware : cek izin login & jabatan
    HandlerBE1 *-- TokenBucketRateLimiter : cegah spam laporan pungli & SOS
    HandlerBE1 *-- InMemoryTTLCache : simpan foto 360 di memori cepat
    HandlerBE1 o-- RepositoryBE1 : panggil 24 fungsi pengambil data
    RepositoryBE1 --> DomainEntitiesBE1 : masukkan hasil database ke cetakan JSON`;

export const MERMAID_USECASE_CODE = `flowchart LR
    %% ========================================================================
    %% USE CASE DIAGRAM (SIAPA BISA MEMAKAI FITUR APA SAJA DI BE-1)
    %% ========================================================================

    subgraph ACTORS["4 Pengguna Utama Aplikasi"]
        FE1["Wisatawan Pencari Rute<br/>(Layar FE-1: Peta & 360)"]
        FE2["Wisatawan Cek Harga<br/>(Layar FE-2: Anti-Pungli & Budaya)"]
        ADM["Admin Dinas Pariwisata<br/>(Layar FS-1: Pengelola Data)"]
        SAT["Petugas Satgas & BPBD<br/>(Layar FS-1: Penindak Lapangan)"]
    end

    subgraph S1["Minggu 1: Data Dasar 20 Tempat Wisata"]
        UC1("UC-01..03: Cari Wisata Terdekat,<br/>Kondisi Jalan, Sinyal HP & Tips Adat")
        UC2("UC-04: Cek Harga Resmi Tiket/Parkir<br/>& Scan Kode QR di Lokasi")
        UC3("UC-06..07: Tambah Wisata Baru<br/>& Ubah Harga Resmi Perda")
    end

    subgraph S2["Minggu 2: Tur 360°, Mampir Searah & Aduan Pungli"]
        UC4("UC-08,10,11: Putar Foto 360° 4-Pin,<br/>Tempat Mampir Searah & Peta Jalan Kaki")
        UC5("UC-12..13: Kirim Laporan Pungli Anonim<br/>& Lihat Tanda Peringatan Lokasi")
        UC6("UC-09,14: Upload Foto 360° Baru<br/>& Catat Hasil Penertiban Satgas")
    end

    subgraph S3["Minggu 3: Ranking Jujur GPS, Jalur Ekstrem & Bahasa Minang"]
        UC7("UC-15..16: Lihat Urutan Wisata Terfavorit<br/>dari Kunjungan GPS Nyata")
        UC8("UC-17,19: Cek Bahaya Sitinjau Lauik<br/>& Tekan Tombol Darurat SOS")
        UC9("UC-18: Nyalakan Alarm Bencana Jalan<br/>& Berikan Saran Jalur Alternatif")
        UC10("UC-20..21: Dengar Suara Bahasa Minang<br/>& Cek Jadwal Pasar Nagari")
    end

    subgraph S4["Minggu 4: Peta Offline & Tes Kecepatan"]
        UC11("UC-22: Download Paket Peta Offline<br/>untuk Daerah Susah Sinyal")
        UC12("UC-23..24: Tes Kecepatan Server (<100ms)<br/>& Lihat Daftar 24 API")
    end

    FE1 --> UC1
    FE1 --> UC4
    FE1 --> UC7
    FE1 --> UC8
    FE1 --> UC11

    FE2 --> UC2
    FE2 --> UC5
    FE2 --> UC10

    ADM --> UC3
    ADM --> UC6
    ADM --> UC12

    SAT --> UC6
    SAT --> UC9`;

export const MERMAID_ARCHITECTURE_CODE = `flowchart TB
    %% ========================================================================
    %% GAMBARAN BESAR CARA KERJA SISTEM RANCAK.IN (BE-1 CORE & SPASIAL)
    %% ========================================================================

    subgraph CLIENT["1. Layar Aplikasi yang Dipakai Pengguna"]
        FE1["Layar FE-1: Peta Wisata, Foto 360°,<br/>Tempat Mampir Searah & Tombol SOS"]
        FE2["Layar FE-2: Cek Harga Resmi,<br/>Lapor Pungli Anonim & Kamus Minang"]
        FS1["Layar FS-1: Dashboard Admin Dispar,<br/>Petugas Satgas Pungli & BPBD"]
    end

    subgraph GATEWAY["2. Pintu Keamanan & Penghemat Kuota (Middleware BE-1)"]
        JWT["Pengecek Tiket Login (JWT)<br/>Membedakan Wisatawan, Admin, Satgas, & BPBD"]
        RL["Penangkal Spam (Token Bucket)<br/>Mencegah Orang Iseng Spam Laporan / SOS"]
        CACHE["Penyimpan Memori Cepat (Cache ETag)<br/>Supaya Foto 360° Tidak Perlu Download Ulang"]
    end

    subgraph BACKEND["3. Pembagian Tugas Mesin Backend (Supaya Tidak Bentrok)"]
        subgraph BE1["Mesin Anda — BE-1: Peta, Wisata & Keamanan (24 API)"]
            M1["Minggu 1: Pencarian Peta, Info Jalan/Sinyal & Harga Resmi"]
            M2["Minggu 2: Foto Keliling 360°, Tempat Mampir & Aduan Pungli"]
            M3["Minggu 3: Peringkat Kunjungan GPS, Bahaya Jalan & Bahasa Minang"]
            M4["Minggu 4: Paket Peta Offline Susah Sinyal & Tes Kecepatan"]
        end

        subgraph BE2["Mesin Teman Setim — BE-2: Sosial & Pembayaran"]
            B2M["Login Akun, Ruang Voting Grup Liburan,<br/>Pesan Pemandu Lokal & Paspor Stempel"]
        end
    end

    subgraph DATA["4. Penyimpanan Database (PostgreSQL + PostGIS)"]
        DB1[("11 Tabel Milik BE-1<br/>Menyimpan 20 Wisata Sumbar, Titik Peta, Foto 360 & Laporan")]
        DB2[("11 Tabel Milik BE-2<br/>Menyimpan Akun User, Grup Liburan, Transaksi & Stempel")]
    end

    FE1 & FE2 & FS1 ==> JWT
    JWT ==> RL
    RL ==> CACHE
    CACHE ==> BE1
    BE1 ==> DB1
    B2M -.->|"Memberi Tiket Login (JWT)"| JWT
    B2M -.->|"Meminjam ID Tempat Wisata & Kode QR"| M1`;
