import { jsPDF } from 'jspdf';
import {
  ERD_ENTITIES_BE1_AND_BOUNDARY,
  ERD_RELATIONSHIPS,
  GO_CLASS_DIAGRAM_NODES,
  GO_CLASS_RELATIONSHIPS,
  SEQUENCE_SCENARIOS,
  USE_CASE_ACTORS,
  USE_CASE_ITEMS_24,
} from '../data/architectureDiagramsData';
import { SPRINT_1_DAILY_STEPS, ROLE_BOUNDARY_MATRIX } from '../data/sprint1ArchitectureData';
import { SPRINT_2_DAILY_STEPS } from '../data/sprint2Data';
import { SPRINT_3_DAILY_STEPS } from '../data/sprint3Data';
import { SPRINT_4_DAILY_STEPS } from '../data/sprint4Data';

export function generateAndDownloadCompleteBe1Pdf(): void {
  const doc = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: 'a4',
  });

  const pageWidth = 210;
  const pageHeight = 297;
  const marginX = 14;
  const contentWidth = pageWidth - marginX * 2; // 182 mm
  let cursorY = 16;

  // Warna tema Rancak.in (Sumatera Barat)
  const COLOR_FOREST: [number, number, number] = [35, 75, 36]; // #234B24
  const COLOR_EMERALD: [number, number, number] = [30, 158, 90]; // #1E9E5A
  const COLOR_DARK: [number, number, number] = [27, 31, 26]; // #1B1F1A
  const COLOR_MUTED: [number, number, number] = [90, 98, 90]; // #5A625A
  const COLOR_CREAM: [number, number, number] = [246, 243, 236]; // #F6F3EC
  const COLOR_SAGE: [number, number, number] = [228, 233, 218]; // #E4E9DA
  const COLOR_ORANGE: [number, number, number] = [232, 93, 26]; // #E85D1A
  const COLOR_CORAL: [number, number, number] = [242, 107, 75]; // #F26B4B
  const COLOR_INDIGO: [number, number, number] = [91, 106, 232]; // #5B6AE8
  const COLOR_BORDER: [number, number, number] = [213, 208, 197]; // #D5D0C5

  const ensureSpace = (neededHeight: number) => {
    if (cursorY + neededHeight > pageHeight - 16) {
      doc.addPage();
      cursorY = 16;
      // Running top bar kecil di halaman baru
      doc.setFillColor(...COLOR_SAGE);
      doc.rect(marginX, 8, contentWidth, 5.5, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7.5);
      doc.setTextColor(...COLOR_FOREST);
      doc.text(
        'DOKUMEN LENGKAP BACKEND 1 (BE-1: PETA, WISATA & KEAMANAN) — RANCAK.IN (MINGGU 1 S/D MINGGU 4)',
        marginX + 2,
        11.8
      );
      cursorY = 18;
    }
  };

  const drawChapterHeader = (chapterNum: string, title: string, subtitle: string) => {
    ensureSpace(24);
    doc.setFillColor(...COLOR_FOREST);
    doc.roundedRect(marginX, cursorY, contentWidth, 17, 2, 2, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.5);
    doc.setTextColor(228, 233, 218);
    doc.text(chapterNum.toUpperCase(), marginX + 4, cursorY + 5.5);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    doc.setTextColor(255, 255, 255);
    doc.text(title, marginX + 4, cursorY + 11.2);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    doc.setTextColor(246, 243, 236);
    doc.text(subtitle, marginX + 4, cursorY + 15.2);
    cursorY += 21;
  };

  // ==========================================================================
  // HALAMAN 1: SAMPUL & BAB 1 (RINGKASAN PERAN BE-1 & PEMBAGIAN TIM)
  // ==========================================================================
  doc.setFillColor(...COLOR_FOREST);
  doc.roundedRect(marginX, cursorY, contentWidth, 38, 3, 3, 'F');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.setTextColor(228, 233, 218);
  doc.text('LAPORAN LENGKAP & DOKUMENTASI DIAGRAM ARSITEKTUR (MINGGU 1 – MINGGU 4)', marginX + 6, cursorY + 8);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(17);
  doc.setTextColor(255, 255, 255);
  doc.text('RANCAK.IN (WISGO) — SUMATERA BARAT', marginX + 6, cursorY + 17);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(11);
  doc.setTextColor(246, 243, 236);
  doc.text('Peran Fokus: Backend 1 (BE-1: Peta, Tempat Wisata, Foto 360°, Anti-Pungli & Keamanan Jalan)', marginX + 6, cursorY + 24.5);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8.5);
  doc.setTextColor(228, 233, 218);
  doc.text(
    'Lokasi Kode: backend/internal/be1_core/  |  11 Tabel Database (Bahasa Indonesia)  |  24 Alamat API  |  32 Tes Otomatis Lulus',
    marginX + 6,
    cursorY + 32
  );
  cursorY += 43;

  // 4 Kotak Ringkasan Capaian
  const summaryStats = [
    { label: 'Durasi Pengerjaan', val: '4 Minggu (20 Hari)', sub: 'Minggu 1 s/d Minggu 4 Tuntas' },
    { label: 'Tabel Database BE-1', val: '11 Tabel Utama', sub: '+ 4 Tabel Batas Kerja Sama BE-2' },
    { label: 'Total Alamat API BE-1', val: '24 Endpoint Aktif', sub: 'Melayani FE-1, FE-2, & FS-1' },
    { label: 'Target Kecepatan', val: '< 100 milidetik', sub: 'Dilengkapi Cache ETag & Anti-Spam' },
  ];
  const statBoxW = (contentWidth - 6) / 4;
  summaryStats.forEach((st, idx) => {
    const bx = marginX + idx * (statBoxW + 2);
    doc.setFillColor(...COLOR_CREAM);
    doc.setDrawColor(...COLOR_BORDER);
    doc.roundedRect(bx, cursorY, statBoxW, 18, 1.5, 1.5, 'FD');

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.5);
    doc.setTextColor(...COLOR_MUTED);
    doc.text(st.label, bx + 2.5, cursorY + 5);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10.5);
    doc.setTextColor(...COLOR_FOREST);
    doc.text(st.val, bx + 2.5, cursorY + 11);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.8);
    doc.setTextColor(...COLOR_DARK);
    doc.text(st.sub, bx + 2.5, cursorY + 15.5);
  });
  cursorY += 23;

  // BAB 1: PENJELASAN SINGKAT TUGAS BE-1 & PEMBAGIAN KERJA 5 ORANG
  drawChapterHeader(
    'Bab 1 — Pengenalan & Pembagian Tugas Tim',
    'Apa Tugas Anda sebagai BE-1 dan Bagaimana Cara Kerja Sama dengan 4 Teman Setim?',
    'Disusun dengan bahasa sehari-hari yang mudah dipahami supaya tidak bingung saat presentasi atau koordinasi tim.'
  );

  doc.setFillColor(...COLOR_CREAM);
  doc.setDrawColor(...COLOR_BORDER);
  doc.roundedRect(marginX, cursorY, contentWidth, 24, 2, 2, 'FD');
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.setTextColor(...COLOR_FOREST);
  doc.text('Inti Tugas Anda (Backend 1 / BE-1):', marginX + 3.5, cursorY + 5.5);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8.2);
  doc.setTextColor(...COLOR_DARK);
  const introLines = doc.splitTextToSize(
    'Di proyek Rancak.in (WISGO), tugas Backend dibagi menjadi dua orang (BE-1 dan BE-2) supaya adil dan tidak pernah bentrok saat menggabungkan kode di GitHub. Anda sebagai BE-1 bertanggung jawab penuh pada bagian Peta, Data 20 Tempat Wisata Sumatera Barat, Kondisi Jalan & Sinyal HP, Harga Resmi Pemerintah (Anti-Pungli), Foto Keliling 360°, Tempat Mampir Searah, Peringkat Kunjungan GPS, Info Bahaya Jalur Ekstrem (Sitinjau Lauik dll), Tombol Darurat SOS, serta Kamus Suara Bahasa Minang.',
    contentWidth - 7
  );
  doc.text(introLines, marginX + 3.5, cursorY + 10.5);
  cursorY += 28;

  // Tabel Pembagian 5 Peran Tim
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9.5);
  doc.setTextColor(...COLOR_DARK);
  doc.text('Tabel Pembagian Tugas 5 Anggota Tim (Supaya Tidak Bentrok Kode / Zero Merge Conflict):', marginX, cursorY);
  cursorY += 4;

  ROLE_BOUNDARY_MATRIX.forEach((rl) => {
    ensureSpace(22);
    const isBe1 = rl.roleCode === 'BE-1';
    doc.setFillColor(...(isBe1 ? COLOR_SAGE : [255, 255, 255] as [number, number, number]));
    doc.setDrawColor(...(isBe1 ? COLOR_FOREST : COLOR_BORDER));
    doc.roundedRect(marginX, cursorY, contentWidth, 19, 1.5, 1.5, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.5);
    doc.setTextColor(...(rl.roleCode === 'BE-2' ? COLOR_CORAL : COLOR_FOREST));
    doc.text(`${rl.roleCode} — ${rl.roleName} (${rl.stack})`, marginX + 3, cursorY + 5);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.5);
    doc.setTextColor(...COLOR_DARK);
    const focusWrapped = doc.splitTextToSize(`Tugas: ${rl.sprint1Focus}`, contentWidth - 6);
    doc.text(focusWrapped.slice(0, 2), marginX + 3, cursorY + 9.5);

    doc.setFont('helvetica', 'italic');
    doc.setFontSize(7.2);
    doc.setTextColor(...COLOR_MUTED);
    const ruleWrapped = doc.splitTextToSize(`Cara Kerja Sama dengan BE-1: ${rl.interactionRuleForBE1}`, contentWidth - 6);
    doc.text(ruleWrapped.slice(0, 1), marginX + 3, cursorY + 16.5);

    cursorY += 21;
  });

  // ==========================================================================
  // BAB 2: RANGKUMAN PEKERJAAN MINGGU 1 SAMPAI MINGGU 4 (HARI 1 - HARI 20)
  // ==========================================================================
  doc.addPage();
  cursorY = 16;
  drawChapterHeader(
    'Bab 2 — Rangkuman Pekerjaan Minggu 1 s/d Minggu 4 (Hari 1 – Hari 20)',
    'Apa Saja yang Sudah Dibuat dari Minggu Pertama sampai Minggu Terakhir?',
    'Daftar lengkap 20 hari kerja BE-1: mulai dari menyiapkan fondasi wisata, fitur 360°, jalur ekstrem, hingga penghemat kuota.'
  );

  const allSprints = [
    {
      sprintTitle: 'MINGGU 1 (HARI 1 – HARI 5): Fondasi Server Go, 4 Tabel Dasar Wisata & Data 20 Wisata Sumbar',
      sprintSummary:
        'Menyiapkan kerangka server Go, penjaga login JWT, 4 tabel dasar (destinasi_wisata, indikator_medan, tips_lokal_adat, tarif_resmi_perda), dan mengisi data 20 tempat wisata Sumatera Barat.',
      steps: SPRINT_1_DAILY_STEPS,
    },
    {
      sprintTitle: 'MINGGU 2 (HARI 6 – HARI 10): Foto Keliling 360° 4-Pin, Tempat Mampir Searah, Peta Mikro & Aduan Pungli',
      sprintSummary:
        'Menambahkan 5 tabel baru (adegan_panorama_360, titik_pin_360, tempat_mampir_searah, peta_mikro_kawasan, laporan_pungli) untuk fitur visual 360°, rute mampir +X menit, dan Satgas Pungli.',
      steps: SPRINT_2_DAILY_STEPS,
    },
    {
      sprintTitle: 'MINGGU 3 (HARI 11 – HARI 15): Peringkat Jujur Kunjungan GPS, Bahaya Jalur Ekstrem, Tombol SOS & Budaya Minang',
      sprintSummary:
        'Menuntaskan 11 tabel BE-1 (peringkat_kunjungan_gps, peringatan_bahaya_dan_sos, kamus_minang_dan_agenda_budaya) untuk urutan wisata anti-buzzer, mitigasi Sitinjau Lauik/Lembah Anai, dan audio bahasa Minang.',
      steps: SPRINT_3_DAILY_STEPS,
    },
    {
      sprintTitle: 'MINGGU 4 (HARI 16 – HARI 20): Peta Offline Susah Sinyal, Memori Cepat Cache ETag, Anti-Spam & 24 API',
      sprintSummary:
        'Menutup proyek 1 bulan penuh dengan mempercepat pencarian peta (<100ms), menyimpan foto 360° di memori cepat (hemat kuota 98%), menangkal spam laporan/SOS, dan menguji 32 skenario tes otomatis.',
      steps: SPRINT_4_DAILY_STEPS,
    },
  ];

  allSprints.forEach((sp) => {
    ensureSpace(32);
    doc.setFillColor(...COLOR_SAGE);
    doc.setDrawColor(...COLOR_FOREST);
    doc.roundedRect(marginX, cursorY, contentWidth, 13, 1.5, 1.5, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.8);
    doc.setTextColor(...COLOR_FOREST);
    doc.text(sp.sprintTitle, marginX + 3, cursorY + 5);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.4);
    doc.setTextColor(...COLOR_DARK);
    const spDesc = doc.splitTextToSize(sp.sprintSummary, contentWidth - 6);
    doc.text(spDesc, marginX + 3, cursorY + 9.2);
    cursorY += 15;

    sp.steps.forEach((st) => {
      ensureSpace(19);
      doc.setFillColor(255, 255, 255);
      doc.setDrawColor(...COLOR_BORDER);
      doc.roundedRect(marginX, cursorY, contentWidth, 16.5, 1, 1, 'FD');

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7.8);
      doc.setTextColor(...COLOR_EMERALD);
      doc.text(`[SELESAI] ${st.day} — ${st.title}`, marginX + 2.5, cursorY + 4.5);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7.2);
      doc.setTextColor(...COLOR_DARK);
      const delivLines = doc.splitTextToSize(`Hasil Kerja: ${st.deliverable}`, contentWidth - 5);
      doc.text(delivLines.slice(0, 2), marginX + 2.5, cursorY + 8.8);

      doc.setFont('courier', 'normal');
      doc.setFontSize(6.8);
      doc.setTextColor(...COLOR_INDIGO);
      doc.text(`File: ${st.sqlOrGoFiles.join(', ')}`, marginX + 2.5, cursorY + 14.8);

      cursorY += 18;
    });
    cursorY += 3;
  });

  // ==========================================================================
  // BAB 3: DIAGRAM ERD VISUAL & PENJELASAN 11 TABEL DATABASE (BAHASA INDONESIA)
  // ==========================================================================
  doc.addPage();
  cursorY = 16;
  drawChapterHeader(
    'Bab 3 — Diagram ERD (Entity Relationship Diagram) & Kamus 11 Tabel Database',
    'Gambar Bagan Hubungan Antar-Tabel & Arti Setiap Kolom (Nama Tabel & Field Bahasa Indonesia)',
    'Memetakan 11 tabel milik BE-1 beserta 4 tabel batas milik BE-2 menggunakan nama Bahasa Indonesia yang mudah dimengerti.'
  );

  // GAMBAR BAGAN VISUAL ERD (DI-DRAW LANGSUNG KE KANVAS PDF)
  doc.setFillColor(...COLOR_CREAM);
  doc.setDrawColor(...COLOR_FOREST);
  doc.roundedRect(marginX, cursorY, contentWidth, 108, 2, 2, 'FD');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(8.5);
  doc.setTextColor(...COLOR_FOREST);
  doc.text('GAMBAR BAGAN VISUAL ERD: HUBUNGAN TABEL INDUK destinasi_wisata KE SELURUH TABEL BE-1 & BE-2', marginX + 4, cursorY + 5.5);

  const drawErdBox = (
    x: number,
    y: number,
    w: number,
    h: number,
    title: string,
    sub: string,
    fields: string[],
    isCenter: boolean,
    isBe2: boolean
  ) => {
    doc.setFillColor(255, 255, 255);
    doc.setDrawColor(...(isBe2 ? COLOR_CORAL : isCenter ? COLOR_FOREST : COLOR_EMERALD));
    doc.roundedRect(x, y, w, h, 1.2, 1.2, 'FD');

    doc.setFillColor(...(isBe2 ? COLOR_CORAL : isCenter ? COLOR_FOREST : COLOR_SAGE));
    doc.rect(x, y, w, 5.5, 'F');

    doc.setFont('courier', 'bold');
    doc.setFontSize(6.8);
    doc.setTextColor(...(isBe2 || isCenter ? ([255, 255, 255] as [number, number, number]) : COLOR_FOREST));
    doc.text(title, x + 1.5, y + 3.8);

    doc.setFont('helvetica', 'italic');
    doc.setFontSize(5.8);
    doc.setTextColor(...COLOR_MUTED);
    doc.text(sub, x + 1.5, y + 8.5);

    doc.setFont('courier', 'normal');
    doc.setFontSize(5.8);
    doc.setTextColor(...COLOR_DARK);
    fields.forEach((f, idx) => {
      doc.text(f, x + 1.5, y + 12 + idx * 3.1);
    });
  };

  const baseY = cursorY + 9;
  const centerX = marginX + 63;
  const centerY = baseY + 28;
  const centerW = 56;
  const centerH = 32;

  // Garis penghubung dari tengah ke kiri, kanan, atas, bawah
  doc.setDrawColor(...COLOR_FOREST);
  doc.setLineWidth(0.35);

  // Kiri (Minggu 1 & 2)
  const leftBoxes = [
    { y: baseY + 1, title: 'indikator_medan', sub: '1:1 Kondisi Jalan & Sinyal', f: ['PK id_indikator_medan', 'FK id_destinasi', '   bisa_masuk_mobil', '   kualitas_sinyal_hp'] },
    { y: baseY + 25, title: 'tips_lokal_adat', sub: '1:N Tips & Etika Nagari', f: ['PK id_tips', 'FK id_destinasi', '   judul_tips', '   wajib_dibaca'] },
    { y: baseY + 49, title: 'tarif_resmi_perda', sub: '1:N Harga Resmi Perda', f: ['PK id_tarif', 'FK id_destinasi', '   nama_komponen_biaya', '   harga_resmi_rupiah'] },
    { y: baseY + 73, title: 'peta_mikro_kawasan', sub: '1:1 Peta Jalan Kaki', f: ['PK id_peta_mikro', 'FK id_destinasi', '   poligon_batas_kawasan', '   garis_rute_jalan_kaki'] },
  ];

  leftBoxes.forEach((lb) => {
    doc.line(marginX + 49, lb.y + 10, centerX, centerY + 15);
    drawErdBox(marginX + 3, lb.y, 46, 21, lb.title, lb.sub, lb.f, false, false);
  });

  // Atas & Bawah Tengah (360 & Shunlu)
  doc.line(centerX + 28, baseY + 21, centerX + 28, centerY);
  drawErdBox(
    centerX,
    baseY + 1,
    56,
    20,
    'adegan_panorama_360 -> titik_pin_360',
    '1:N Foto Keliling 360° & 4 Jenis Titik Pin',
    ['PK id_adegan_360 | FK id_destinasi', 'PK id_pin_360    | jenis_pin (4 pin)', '   url_gambar_360 | posisi_atas_bawah'],
    false,
    false
  );

  doc.line(centerX + 28, centerY + centerH, centerX + 28, baseY + 67);
  drawErdBox(
    centerX,
    baseY + 67,
    56,
    27,
    'Batas Kerja Sama ke 4 Tabel BE-2',
    'Meminjam id_destinasi & Tiket JWT',
    [
      '• pengguna (JWT -> id_pengguna_pelapor)',
      '• ruang_grup_dan_voting (FK id_destinasi)',
      '• pesanan_pemandu_escrow (FK id_destinasi)',
      '• paspor_digital_nagari (FK kode_plang_qr)',
    ],
    false,
    true
  );

  // Kanan (Minggu 2 & 3)
  const rightX = marginX + 133;
  const rightBoxes = [
    { y: baseY + 1, title: 'tempat_mampir_searah', sub: '1:N Mampir Rute (+X mnt)', f: ['PK id_tempat_mampir', 'FK id_destinasi', '   tambahan_waktu_belok_menit', '   titik_koordinat_gps'] },
    { y: baseY + 25, title: 'laporan_pungli', sub: '1:N Aduan & Kuorum >=3', f: ['PK id_laporan_pungli', 'FK id_destinasi', '   apakah_anonim', '   status_tindak_lanjut'] },
    { y: baseY + 49, title: 'peringkat_kunjungan_gps', sub: '1:1 Skor Jujur GPS (Gaode)', f: ['PK id_peringkat', 'FK id_destinasi', '   rata_rata_lama_betah_menit', '   skor_total_perilaku'] },
    { y: baseY + 73, title: 'peringatan_bahaya_dan_sos', sub: 'Jalur Ekstrem & Kamus Minang', f: ['PK id_bahaya_atau_sos', '   kode_koridor_ekstrem', '   saran_jalur_alternatif', '+ kamus_minang_dan_agenda'] },
  ];

  rightBoxes.forEach((rb) => {
    doc.line(centerX + centerW, centerY + 15, rightX, rb.y + 10);
    drawErdBox(rightX, rb.y, 46, 21, rb.title, rb.sub, rb.f, false, false);
  });

  // Kotak Induk di Tengah
  drawErdBox(
    centerX,
    centerY,
    centerW,
    centerH,
    'destinasi_wisata (INDUK)',
    'Tabel #01 BE-1 · 20 Wisata Sumbar',
    [
      'PK id_destinasi (VARCHAR 36)',
      'UK kode_url_slug & kode_plang_qr',
      '   nama_wisata & kabupaten_kota',
      '   titik_koordinat_gps (PostGIS)',
      '   tingkat_keramaian (sepi/ramai)',
      '   estimasi_biaya_rupiah',
    ],
    true,
    false
  );

  cursorY += 113;

  // Rincian Setiap Tabel & Kolomnya (Bahasa Indonesia)
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9.5);
  doc.setTextColor(...COLOR_DARK);
  doc.text('Kamus Lengkap 11 Tabel BE-1 + 4 Tabel Batas BE-2 (Beserta Arti Setiap Field/Kolom):', marginX, cursorY);
  cursorY += 4;

  ERD_ENTITIES_BE1_AND_BOUNDARY.forEach((ent) => {
    const boxH = 14 + ent.columns.length * 4.5;
    ensureSpace(boxH + 4);

    const isBe2 = ent.owner === 'BE-2';
    doc.setFillColor(255, 255, 255);
    doc.setDrawColor(...(isBe2 ? COLOR_CORAL : COLOR_FOREST));
    doc.roundedRect(marginX, cursorY, contentWidth, boxH, 1.5, 1.5, 'FD');

    doc.setFillColor(...(isBe2 ? COLOR_CORAL : COLOR_FOREST));
    doc.rect(marginX, cursorY, contentWidth, 6.5, 'F');

    doc.setFont('courier', 'bold');
    doc.setFontSize(8.2);
    doc.setTextColor(255, 255, 255);
    doc.text(`${ent.tableNumberLabel} — Nama Tabel: ${ent.tableName} (${ent.sprint})`, marginX + 2.5, cursorY + 4.5);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.3);
    doc.setTextColor(...COLOR_DARK);
    const descLine = doc.splitTextToSize(`Fungsi Tabel: ${ent.description}`, contentWidth - 5);
    doc.text(descLine.slice(0, 2), marginX + 2.5, cursorY + 10);

    let rowY = cursorY + 15.5;
    ent.columns.forEach((col, cIdx) => {
      if (cIdx % 2 === 0) {
        doc.setFillColor(...COLOR_CREAM);
        doc.rect(marginX + 1, rowY - 3.1, contentWidth - 2, 4.3, 'F');
      }
      doc.setFont('courier', 'bold');
      doc.setFontSize(6.8);
      doc.setTextColor(...(col.keyType === 'PK' ? COLOR_ORANGE : col.keyType === 'FK' ? COLOR_INDIGO : COLOR_FOREST));
      doc.text(`[${col.keyType === 'NORMAL' ? 'FIELD' : col.keyType}]`, marginX + 2.5, rowY);

      doc.setFont('courier', 'bold');
      doc.setTextColor(...COLOR_DARK);
      doc.text(col.name, marginX + 19, rowY);

      doc.setFont('courier', 'normal');
      doc.setFontSize(6.4);
      doc.setTextColor(...COLOR_MUTED);
      doc.text(col.dataType, marginX + 68, rowY);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(6.8);
      doc.setTextColor(...COLOR_DARK);
      const colDesc = doc.splitTextToSize(col.description, contentWidth - 102);
      doc.text(colDesc[0] || '', marginX + 100, rowY);

      rowY += 4.4;
    });

    cursorY += boxH + 3.5;
  });

  // ==========================================================================
  // BAB 4: GAMBAR BAGAN CLASS DIAGRAM GO & PENJELASAN BAGIAN KODE
  // ==========================================================================
  doc.addPage();
  cursorY = 16;
  drawChapterHeader(
    'Bab 4 — Class Diagram Visual & Penjelasan Bagian Kode Go (be1_core)',
    'Bagaimana Susunan Kode Go Anda Saling Bekerja Sama dari Pintu Login sampai ke Database?',
    'Menjelaskan 6 komponen utama di dalam folder backend/internal/be1_core/ dengan bahasa yang mudah dimengerti.'
  );

  // GAMBAR BAGAN VISUAL CLASS DIAGRAM
  doc.setFillColor(...COLOR_CREAM);
  doc.setDrawColor(...COLOR_FOREST);
  doc.roundedRect(marginX, cursorY, contentWidth, 64, 2, 2, 'FD');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(8.5);
  doc.setTextColor(...COLOR_FOREST);
  doc.text('GAMBAR BAGAN VISUAL CLASS DIAGRAM GO (ALUR KERJA SAMA ANTAR-BAGIAN KODE BE-1)', marginX + 4, cursorY + 5.5);

  const clsBoxes = [
    { x: marginX + 4, y: cursorY + 10, w: 54, h: 22, name: 'StatelessJWTMiddleware', role: '<<Penjaga Pintu Login>>', note: '+ RequireAuth() / RequireRole()' },
    { x: marginX + 64, y: cursorY + 10, w: 54, h: 22, name: 'TokenBucketRateLimiter', role: '<<Penangkal Spam 429>>', note: '+ AllowRequest() / SanitizeInput()' },
    { x: marginX + 124, y: cursorY + 10, w: 54, h: 22, name: 'InMemoryTTLCache', role: '<<Memori Cepat ETag 304>>', note: '+ Get() / Set() / ServeWithETag()' },
    { x: marginX + 4, y: cursorY + 38, w: 54, h: 22, name: 'HandlerBE1 (Controller)', role: '<<Pelayan 24 Alamat API>>', note: '+ HandleListDestinations() dkk' },
    { x: marginX + 64, y: cursorY + 38, w: 54, h: 22, name: 'RepositoryBE1 (PostGIS)', role: '<<Pengolah Database Peta>>', note: '+ QueryDestinationsSpatial() dkk' },
    { x: marginX + 124, y: cursorY + 38, w: 54, h: 22, name: 'DomainEntitiesBE1', role: '<<Cetakan Data 11 Tabel>>', note: '+ Destination, PanoramaScene, dll' },
  ];

  // Garis penghubung antar class
  doc.setDrawColor(...COLOR_FOREST);
  doc.setLineWidth(0.4);
  doc.line(marginX + 31, cursorY + 32, marginX + 31, cursorY + 38); // Middleware -> Handler
  doc.line(marginX + 91, cursorY + 32, marginX + 45, cursorY + 38); // Limiter -> Handler
  doc.line(marginX + 151, cursorY + 32, marginX + 55, cursorY + 38); // Cache -> Handler
  doc.line(marginX + 58, cursorY + 49, marginX + 64, cursorY + 49); // Handler -> Repo
  doc.line(marginX + 118, cursorY + 49, marginX + 124, cursorY + 49); // Repo -> Domain

  clsBoxes.forEach((cb) => {
    doc.setFillColor(255, 255, 255);
    doc.setDrawColor(...COLOR_FOREST);
    doc.roundedRect(cb.x, cb.y, cb.w, cb.h, 1.2, 1.2, 'FD');

    doc.setFillColor(...COLOR_SAGE);
    doc.rect(cb.x, cb.y, cb.w, 6, 'F');
    doc.setFont('courier', 'bold');
    doc.setFontSize(6.5);
    doc.setTextColor(...COLOR_FOREST);
    doc.text(cb.role, cb.x + 2, cb.y + 4.2);

    doc.setFont('courier', 'bold');
    doc.setFontSize(7.2);
    doc.setTextColor(...COLOR_DARK);
    doc.text(cb.name, cb.x + 2, cb.y + 11);

    doc.setFont('courier', 'normal');
    doc.setFontSize(6.2);
    doc.setTextColor(...COLOR_INDIGO);
    doc.text(cb.note, cb.x + 2, cb.y + 17);
  });

  cursorY += 69;

  // Rincian 6 Class Go
  GO_CLASS_DIAGRAM_NODES.forEach((cls) => {
    const h = 18 + cls.fields.length * 4 + cls.methods.length * 5.5;
    ensureSpace(h + 4);

    doc.setFillColor(255, 255, 255);
    doc.setDrawColor(...COLOR_FOREST);
    doc.roundedRect(marginX, cursorY, contentWidth, h, 1.5, 1.5, 'FD');

    doc.setFillColor(...COLOR_FOREST);
    doc.rect(marginX, cursorY, contentWidth, 6.5, 'F');
    doc.setFont('courier', 'bold');
    doc.setFontSize(8);
    doc.setTextColor(255, 255, 255);
    doc.text(`${cls.className}  |  File: ${cls.sourceFile} (${cls.sprintRange})`, marginX + 2.5, cursorY + 4.5);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.3);
    doc.setTextColor(...COLOR_DARK);
    const cDesc = doc.splitTextToSize(`Tugas Bagian Ini: ${cls.description}`, contentWidth - 5);
    doc.text(cDesc.slice(0, 2), marginX + 2.5, cursorY + 10);

    let y = cursorY + 15.5;
    cls.fields.forEach((fl) => {
      doc.setFont('courier', 'bold');
      doc.setFontSize(6.8);
      doc.setTextColor(...COLOR_INDIGO);
      doc.text(`${fl.visibility} ${fl.name}: ${fl.type}`, marginX + 3, y);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(...COLOR_MUTED);
      doc.text(`(${fl.tagOrNote || ''})`, marginX + 85, y);
      y += 4;
    });

    cls.methods.forEach((mt) => {
      doc.setFont('courier', 'bold');
      doc.setFontSize(6.8);
      doc.setTextColor(...COLOR_FOREST);
      doc.text(`${mt.visibility} ${mt.name}() [${mt.sprintOrigin}]`, marginX + 3, y);
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(6.8);
      doc.setTextColor(...COLOR_DARK);
      const mLine = doc.splitTextToSize(`-> ${mt.description}`, contentWidth - 68);
      doc.text(mLine[0] || '', marginX + 65, y);
      y += 5.2;
    });

    cursorY += h + 3.5;
  });

  // ==========================================================================
  // BAB 5: GAMBAR BAGAN SEQUENCE DIAGRAM (4 CERITA ALUR KERJA SISTEM)
  // ==========================================================================
  doc.addPage();
  cursorY = 16;
  drawChapterHeader(
    'Bab 5 — Sequence Diagram Visual (4 Cerita Alur Kerja Langkah demi Langkah)',
    'Bagaimana Urutan Proses di Balik Layar Saat Fitur Utama Dijalankan?',
    'Menjelaskan 4 skenario terpenting dari Minggu 1 sampai Minggu 4 lengkap dengan bagan alur dan waktu prosesnya.'
  );

  SEQUENCE_SCENARIOS.forEach((seq) => {
    const boxH = 26 + seq.steps.length * 10.5;
    ensureSpace(boxH + 5);

    doc.setFillColor(255, 255, 255);
    doc.setDrawColor(...COLOR_FOREST);
    doc.roundedRect(marginX, cursorY, contentWidth, boxH, 2, 2, 'FD');

    doc.setFillColor(...COLOR_SAGE);
    doc.rect(marginX, cursorY, contentWidth, 11, 'F');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.8);
    doc.setTextColor(...COLOR_FOREST);
    doc.text(`${seq.title} (${seq.sprintBadge})`, marginX + 3, cursorY + 4.8);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.1);
    doc.setTextColor(...COLOR_DARK);
    const sLine = doc.splitTextToSize(seq.summary, contentWidth - 6);
    doc.text(sLine.slice(0, 2), marginX + 3, cursorY + 8.6);

    // Kotak Aktor Partisipan di Atas Lifeline
    const actorW = (contentWidth - 10) / seq.actors.length;
    let actY = cursorY + 13;
    seq.actors.forEach((act, aIdx) => {
      const ax = marginX + 3 + aIdx * (actorW + 1.2);
      doc.setFillColor(...COLOR_FOREST);
      doc.roundedRect(ax, actY, actorW, 7.5, 1, 1, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(6.6);
      doc.setTextColor(255, 255, 255);
      doc.text(`${act.name} [${act.roleBadge}]`, ax + 2, actY + 4.8);
    });

    // Langkah-langkah Sequence
    let stepY = actY + 10;
    seq.steps.forEach((st) => {
      doc.setFillColor(...(st.isHighlight ? COLOR_SAGE : COLOR_CREAM));
      doc.roundedRect(marginX + 3, stepY, contentWidth - 6, 9.2, 1, 1, 'F');

      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7.1);
      doc.setTextColor(...COLOR_FOREST);
      doc.text(
        `Langkah ${st.stepNo}: ${st.fromActor}  --->  ${st.toActor}   (${st.latencyNote})`,
        marginX + 5,
        stepY + 3.8
      );

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(6.8);
      doc.setTextColor(...COLOR_DARK);
      const msgLine = doc.splitTextToSize(
        `${st.message}  |  Hasil: ${st.returnPayload !== '-' ? st.returnPayload : st.protocolOrSql}`,
        contentWidth - 10
      );
      doc.text(msgLine[0] || '', marginX + 5, stepY + 7.6);

      stepY += 10.2;
    });

    cursorY += boxH + 4.5;
  });

  // ==========================================================================
  // BAB 6: GAMBAR BAGAN USE CASE (4 PENGGUNA) & DAFTAR 24 ALAMAT API BE-1
  // ==========================================================================
  doc.addPage();
  cursorY = 16;
  drawChapterHeader(
    'Bab 6 — Use Case Diagram Visual (4 Pengguna) & Katalog Lengkap 24 Alamat API BE-1',
    'Siapa Saja yang Bisa Memakai Fitur di Aplikasi dan Daftar Lengkap 24 Endpoint Minggu 1–4',
    'Memetakan hak akses Wisatawan FE-1, Wisatawan FE-2, Admin Dispar FS-1, serta Petugas Satgas Pungli & BPBD.'
  );

  // GAMBAR BAGAN VISUAL USE CASE (4 AKTOR DI KIRI -> 4 KELOMPOK FITUR DI KANAN)
  doc.setFillColor(...COLOR_CREAM);
  doc.setDrawColor(...COLOR_FOREST);
  doc.roundedRect(marginX, cursorY, contentWidth, 50, 2, 2, 'FD');

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(8.2);
  doc.setTextColor(...COLOR_FOREST);
  doc.text('GAMBAR BAGAN VISUAL USE CASE: PEMETAAN 4 AKTOR PENGGUNA KE 24 FITUR UTAMA BE-1', marginX + 4, cursorY + 5);

  USE_CASE_ACTORS.forEach((act, idx) => {
    const ay = cursorY + 8 + idx * 10;
    doc.setFillColor(255, 255, 255);
    doc.setDrawColor(...COLOR_FOREST);
    doc.roundedRect(marginX + 4, ay, 68, 8.5, 1.2, 1.2, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7);
    doc.setTextColor(...COLOR_FOREST);
    doc.text(act.name, marginX + 6, ay + 3.8);

    doc.setFont('courier', 'normal');
    doc.setFontSize(6);
    doc.setTextColor(...COLOR_MUTED);
    doc.text(act.roleClaim, marginX + 6, ay + 7);

    // Garis panah ke kanan
    doc.line(marginX + 72, ay + 4.2, marginX + 86, ay + 4.2);
  });

  const ucGroups = [
    'Minggu 1 (UC-01..07): Cari 20 Wisata, Info Jalan/Sinyal, Harga Resmi Perda & Admin',
    'Minggu 2 (UC-08..14): Foto Keliling 360° 4-Pin, Mampir Searah (+X mnt) & Lapor Pungli',
    'Minggu 3 (UC-15..21): Peringkat Kunjungan GPS, Bahaya Sitinjau Lauik, SOS & Bahasa Minang',
    'Minggu 4 (UC-22..24): Paket Peta Offline Susah Sinyal, Tes Kecepatan <100ms & Katalog API',
  ];
  ucGroups.forEach((ug, idx) => {
    const uy = cursorY + 8 + idx * 10;
    doc.setFillColor(...COLOR_SAGE);
    doc.setDrawColor(...COLOR_EMERALD);
    doc.roundedRect(marginX + 86, uy, 92, 8.5, 4, 4, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(6.6);
    doc.setTextColor(...COLOR_DARK);
    doc.text(ug, marginX + 89, uy + 5.2);
  });

  cursorY += 55;

  // Tabel Lengkap 24 Endpoint BE-1
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.setTextColor(...COLOR_DARK);
  doc.text('Tabel Lengkap 24 Alamat API (Endpoint) Milik BE-1 dari Minggu 1 sampai Minggu 4:', marginX, cursorY);
  cursorY += 3.5;

  USE_CASE_ITEMS_24.forEach((uc, idx) => {
    ensureSpace(8);
    doc.setFillColor(...(idx % 2 === 0 ? COLOR_CREAM : ([255, 255, 255] as [number, number, number])));
    doc.setDrawColor(...COLOR_BORDER);
    doc.rect(marginX, cursorY, contentWidth, 7.2, 'FD');

    doc.setFont('courier', 'bold');
    doc.setFontSize(6.8);
    doc.setTextColor(...COLOR_FOREST);
    doc.text(`${uc.code} [${uc.sprint}]`, marginX + 2, cursorY + 4.6);

    doc.setFont('courier', 'bold');
    doc.setFontSize(6.8);
    doc.setTextColor(...COLOR_INDIGO);
    doc.text(uc.endpoint, marginX + 31, cursorY + 4.6);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.8);
    doc.setTextColor(...COLOR_DARK);
    doc.text(uc.title, marginX + 95, cursorY + 4.6);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(6.3);
    doc.setTextColor(...COLOR_EMERALD);
    doc.text(uc.slaTarget, marginX + 168, cursorY + 4.6);

    cursorY += 7.2;
  });

  // ==========================================================================
  // BAB 7: GAMBAR BAGAN ARSITEKTUR SISTEM 4 LAPISAN & KESIMPULAN AKHIR
  // ==========================================================================
  ensureSpace(88);
  cursorY += 6;
  drawChapterHeader(
    'Bab 7 — Gambar Bagan Arsitektur Sistem 4 Lapisan & Hasil Tes Otomatis',
    'Gambaran Besar Aliran Data dari Layar HP Pengguna sampai ke Database Peta PostGIS',
    'Merangkum bagaimana ke-4 lapisan sistem bekerja sama menjaga kecepatan di bawah 100 milidetik.'
  );

  const tiers = [
    {
      title: 'LAPISAN 1 — LAYAR APLIKASI PENGGUNA (CLIENT TIER)',
      desc: 'Layar FE-1 (Peta Wisata, Foto 360°, Mampir Searah & Tombol SOS)  |  Layar FE-2 (Cek Harga Resmi, Lapor Pungli Anonim & Kamus Minang)  |  Layar FS-1 (Dashboard Admin Dispar, Satgas Pungli & BPBD)',
      bg: COLOR_CREAM,
    },
    {
      title: 'LAPISAN 2 — PINTU KEAMANAN & PENGHEMAT KUOTA (MIDDLEWARE GO BE-1)',
      desc: '1. Pengecek Tiket Login (Stateless JWT)   -->   2. Penangkal Spam Laporan/SOS (Token Bucket 429)   -->   3. Penyimpan Memori Cepat (Cache ETag 304 < 1.5 ms)',
      bg: COLOR_SAGE,
    },
    {
      title: 'LAPISAN 3 — PEMBAGIAN MESIN BACKEND (ZERO MERGE CONFLICT)',
      desc: 'Mesin Anda BE-1 (backend/internal/be1_core/: 24 API Peta, 360°, Pungli, Gaode, Bahaya & Budaya)   <--->   Mesin Teman BE-2 (Login Akun, Grup Voting, Booking Pemandu & Paspor Stempel)',
      bg: COLOR_CREAM,
    },
    {
      title: 'LAPISAN 4 — DATABASE PETA POSTGRESQL 15 + POSTGIS 3.4',
      desc: '11 Tabel Utama BE-1 (destinasi_wisata s/d kamus_minang_dan_agenda_budaya) + Indeks Pencarian Cepat GIST/GIN/BRIN  |  Terpisah Rapi dari 11 Tabel Milik BE-2',
      bg: COLOR_SAGE,
    },
  ];

  tiers.forEach((tr) => {
    ensureSpace(16);
    doc.setFillColor(...tr.bg);
    doc.setDrawColor(...COLOR_FOREST);
    doc.roundedRect(marginX, cursorY, contentWidth, 13.5, 1.5, 1.5, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7.8);
    doc.setTextColor(...COLOR_FOREST);
    doc.text(tr.title, marginX + 3, cursorY + 4.8);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7);
    doc.setTextColor(...COLOR_DARK);
    const tLines = doc.splitTextToSize(tr.desc, contentWidth - 6);
    doc.text(tLines.slice(0, 2), marginX + 3, cursorY + 9.2);

    cursorY += 15;
  });

  // Penomoran halaman di bagian bawah setiap lembar A4
  const totalPages = doc.getNumberOfPages();
  for (let p = 1; p <= totalPages; p++) {
    doc.setPage(p);
    doc.setDrawColor(...COLOR_BORDER);
    doc.line(marginX, pageHeight - 11, pageWidth - marginX, pageHeight - 11);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.2);
    doc.setTextColor(...COLOR_MUTED);
    doc.text(
      'Rancak.in (WISGO) Sumatera Barat — Dokumentasi Lengkap Backend 1 (BE-1: Minggu 1 s/d Minggu 4)',
      marginX,
      pageHeight - 6.8
    );
    doc.setFont('helvetica', 'bold');
    doc.text(`Halaman ${p} dari ${totalPages}`, pageWidth - marginX - 25, pageHeight - 6.8);
  }

  doc.save('Laporan_Lengkap_BE1_Rancakin_Minggu_1_Sampai_4.pdf');
}
