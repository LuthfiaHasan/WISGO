/// Model Laporan Pengalaman & Kondisi Nyata di Lokasi (Crowdsourced Wisatawan)
/// Aturan: Bebas tanpa template kaku, tetapi WAJIB minimal karakter agar informatif.
class GroundConditionReport {
  final String id;
  final String destinationName;
  final String authorName;
  final String authorBadge;
  final String timeAgo;
  final String freeformContent; // Teks pengalaman nyata tanpa template khusus
  final List<String> tags; // Contoh: 'Jalur Licin', 'Debit Air Deras', 'Parkir Longgar', 'Tiket Sesuai Perda'
  final int helpfulCount;
  final bool isVerifiedTourist;
  final String? panoramaAvailable;

  const GroundConditionReport({
    required this.id,
    required this.destinationName,
    required this.authorName,
    this.authorBadge = 'Wisatawan Terverifikasi',
    required this.timeAgo,
    required this.freeformContent,
    required this.tags,
    this.helpfulCount = 12,
    this.isVerifiedTourist = true,
    this.panoramaAvailable,
  });
}

/// Batas Minimal Karakter untuk Laporan Kondisi Nyata
const int kMinGroundReportChars = 30;

/// Data Simulasi Laporan Lapangan Terkini dari Wisatawan
final List<GroundConditionReport> kSampleGroundReports = [
  const GroundConditionReport(
    id: 'rep-01',
    destinationName: 'Lembah Harau & Sarasah Bunta',
    authorName: 'Fajri Ramadhan',
    authorBadge: 'Wisatawan Lokal Luhak 50',
    timeAgo: '20 menit lalu',
    freeformContent:
        'Kondisi air terjun Sarasah Bunta hari ini airnya sangat jernih dan debitnya sedang, pas untuk mandi. Jalur setapak dari parkiran ke Sarasah agak licin kena embun pagi, jadi hati-hati kalau bawa anak kecil. Tiket resmi loket Perda Rp10.000 pas tanpa pungli.',
    tags: ['Debit Air Pas', 'Jalur Agak Licin', 'Bebas Pungli', 'Parkir Aman'],
    helpfulCount: 28,
    isVerifiedTourist: true,
  ),
  const GroundConditionReport(
    id: 'rep-02',
    destinationName: 'Lembah Harau & Sarasah Bunta',
    authorName: 'dr. Sarah Nabila',
    authorBadge: 'Trekker Aktif WISGO',
    timeAgo: '1 jam lalu',
    freeformContent:
        'Parkiran mobil di depan gazebo utama mulai ramai sejak jam 09.30 WIB. Buat yang mau trekking ke Sarasah Murai disarankan sewa pemandu lokal Pokdarwis seharga Rp85.000 karena jalurnya banyak cabang baru di dekat hutan pinus.',
    tags: ['Parkiran Padat', 'Saran Pemandu Pokdarwis', 'Trekking Sejuk'],
    helpfulCount: 19,
    isVerifiedTourist: true,
  ),
  const GroundConditionReport(
    id: 'rep-03',
    destinationName: 'Kawasan Wisata Mandeh',
    authorName: 'Ilham Kurnia',
    authorBadge: 'Wisatawan Bahari',
    timeAgo: '45 menit lalu',
    freeformContent:
        'Cuaca di Teluk Mandeh sangat cerah tanpa ombak besar, perahu motor nelayan beroperasi normal sesuai standar SOP rompi pelampung. Jarak pandang bawah air untuk snorkeling di Pulau Sironjong tembus sampai 8 meter.',
    tags: ['Ombak Tenang', 'Air Jernih 8m', 'SOP Rompi Patuh'],
    helpfulCount: 34,
    isVerifiedTourist: true,
  ),
];
