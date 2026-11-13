import React, { useState } from 'react';
import {
  FileDown,
  X,
  BookOpen,
  Database,
  Layers,
  GitBranch,
  Users,
  Cpu,
  CheckCircle2,
  Printer,
  Calendar,
} from 'lucide-react';
import {
  ERD_ENTITIES_BE1_AND_BOUNDARY,
  GO_CLASS_DIAGRAM_NODES,
  SEQUENCE_SCENARIOS,
  USE_CASE_ACTORS,
  USE_CASE_ITEMS_24,
} from '../data/architectureDiagramsData';
import { SPRINT_1_DAILY_STEPS, ROLE_BOUNDARY_MATRIX } from '../data/sprint1ArchitectureData';
import { SPRINT_2_DAILY_STEPS } from '../data/sprint2Data';
import { SPRINT_3_DAILY_STEPS } from '../data/sprint3Data';
import { SPRINT_4_DAILY_STEPS } from '../data/sprint4Data';
import { generateAndDownloadCompleteBe1Pdf } from '../utils/pdfReportGenerator';

interface PdfReportPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const ARCHITECTURE_4_LAYERS_SUMMARY = [
  {
    layerId: 'layer-1',
    layerName: 'Lapisan 1: Aplikasi Pengguna (Frontend Web & Mobile)',
    subtitle: 'FE-1, FE-2, dan FS-1',
    nodes: [
      {
        title: 'FE-1 (Halaman Utama & Peta)',
        techStack: 'React / Next.js + Mapbox / Leaflet',
        description:
          'Menampilkan daftar wisata Sumatera Barat, filter kondisi jalan/sinyal, tombol SOS darurat, dan paket data offline.',
      },
      {
        title: 'FE-2 (Navigasi 360° & Anti-Pungli)',
        techStack: 'Pannellum 360° + Form Laporan Bukti',
        description:
          'Menampilkan tur virtual 360 derajat, titik mampir searah (Shunlu), tabel tarif resmi perda, dan laporan pungli.',
      },
      {
        title: 'FS-1 (Dashboard Admin Dispar)',
        techStack: 'React Admin CMS + Statistik Real-Time',
        description:
          'Mengelola data tempat wisata, memverifikasi laporan pungli, menyiarkan peringatan bencana BPBD, dan memantau kecepatan server.',
      },
    ],
  },
  {
    layerId: 'layer-2',
    layerName: 'Lapisan 2: Gerbang Keamanan & Pengatur Lalu Lintas (Middleware BE-1)',
    subtitle: 'Stateless JWT, RBAC, Cache & Anti-Spam',
    nodes: [
      {
        title: 'Pemeriksa Token Login (JWT & RBAC)',
        techStack: 'middleware_jwt.go',
        description:
          'Mengecek apakah pengunjung biasa, petugas Pokdarwis, Satgas Pungli, atau Admin Dispar tanpa membebani database.',
      },
      {
        title: 'Penyimpanan Cepat Sementara (In-Memory Cache)',
        techStack: 'cache_ratelimit_sprint4.go',
        description:
          'Menyimpan hasil pencarian populer di memori RAM supaya waktu tunggu di bawah 25 milidetik.',
      },
      {
        title: 'Penangkal Spam Otomatis (Rate Limiter)',
        techStack: 'Token Bucket per IP & User',
        description:
          'Mencegah orang iseng mengirim ratusan laporan pungli atau sinyal SOS palsu secara beruntun.',
      },
    ],
  },
  {
    layerId: 'layer-3',
    layerName: 'Lapisan 3: Otak Pemrosesan Utama Backend 1 (Go 1.22 Core)',
    subtitle: 'backend/internal/be1_core/',
    nodes: [
      {
        title: 'Pengatur 24 Alamat API (Handlers)',
        techStack: 'handlers.go + sprint2/3/4_handlers.go',
        description:
          'Menerima permintaan dari HP/Web, memvalidasi input, dan mengembalikan jawaban JSON yang rapi.',
      },
      {
        title: 'Penghitung Jarak & Rute (PostGIS Repository)',
        techStack: 'repository_postgis.go',
        description:
          'Menghitung jarak GPS wisatawan ke tempat wisata terdekat dan mencari tempat mampir yang searah jalan.',
      },
      {
        title: 'Jembatan Aman ke BE-2 (Zero Merge Conflict)',
        techStack: 'Kontrak JSON & JWT Bersama',
        description:
          'Bekerja berdampingan dengan BE-2 (AI Rencana Jalan & Dompet Patungan) tanpa saling menimpa file kode.',
      },
    ],
  },
  {
    layerId: 'layer-4',
    layerName: 'Lapisan 4: Penyimpanan Data & Peta Geografis (Database)',
    subtitle: 'PostgreSQL 16 + Ekstensi PostGIS',
    nodes: [
      {
        title: '11 Tabel Utama Milik BE-1',
        techStack: 'destinasi_wisata s/d kamus_minang',
        description:
          'Menyimpan seluruh data wisata, kondisi jalan, tarif perda, foto 360°, laporan pungli, peringkat GPS, dan SOS.',
      },
      {
        title: '4 Tabel Batas Milik BE-2',
        techStack: 'pengguna, komunitas, rencana_perjalanan',
        description:
          'Tabel milik BE-2 yang terhubung lewat nomor ID tempat wisata (id_destinasi) dan token pengguna.',
      },
      {
        title: 'Indeks Pencarian Cepat (GIST & B-Tree)',
        techStack: 'migrations_sprint1..4.sql',
        description:
          'Membuat pencarian titik koordinat GPS dan pengurutan peringkat wisata tetap ngebut meski datanya ribuan.',
      },
    ],
  },
];

export const PdfReportPreviewModal: React.FC<PdfReportPreviewModalProps> = ({
  isOpen,
  onClose,
}) => {
  const [activeChapter, setActiveChapter] = useState<string>('all');
  const [isDownloading, setIsDownloading] = useState(false);

  if (!isOpen) return null;

  const handleDownloadPdf = () => {
    setIsDownloading(true);
    try {
      generateAndDownloadCompleteBe1Pdf();
    } finally {
      setTimeout(() => setIsDownloading(false), 600);
    }
  };

  const all20Days = [
    ...SPRINT_1_DAILY_STEPS.map((d) => ({ ...d, sprintBadge: 'Minggu 1 (Sprint 1)' })),
    ...SPRINT_2_DAILY_STEPS.map((d) => ({ ...d, sprintBadge: 'Minggu 2 (Sprint 2)' })),
    ...SPRINT_3_DAILY_STEPS.map((d) => ({ ...d, sprintBadge: 'Minggu 3 (Sprint 3)' })),
    ...SPRINT_4_DAILY_STEPS.map((d) => ({ ...d, sprintBadge: 'Minggu 4 (Sprint 4)' })),
  ];

  const chapters = [
    { id: 'all', label: 'Semua Bab (Lengkap)' },
    { id: 'bab1', label: 'Bab 1: Ringkasan & Tim' },
    { id: 'bab2', label: 'Bab 2: Minggu 1–4 (20 Hari)' },
    { id: 'bab3', label: 'Bab 3: Diagram ERD (15 Tabel)' },
    { id: 'bab4', label: 'Bab 4: Class Diagram Go' },
    { id: 'bab5', label: 'Bab 5: Sequence Diagram' },
    { id: 'bab6', label: 'Bab 6: Use Case & 24 API' },
    { id: 'bab7', label: 'Bab 7: Arsitektur 4 Lapisan' },
  ];

  const showSection = (id: string) => activeChapter === 'all' || activeChapter === id;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 p-3 sm:p-6 overflow-y-auto">
      <div className="relative w-full max-w-6xl bg-[#F6F3EC] border-2 border-[#234B24] rounded-xl shadow-2xl flex flex-col max-h-[92vh] overflow-hidden">
        {/* Top Modal Action Bar */}
        <div className="bg-[#1B1F1A] text-white px-5 py-4 flex flex-wrap items-center justify-between gap-3 border-b border-[#234B24]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-[#1E9E5A]/20 border border-[#1E9E5A] flex items-center justify-center text-[#1E9E5A]">
              <BookOpen className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[11px] font-mono uppercase tracking-wider px-2 py-0.5 rounded bg-[#E85D1A] text-white font-semibold">
                  PRATINJAU KERTAS A4
                </span>
                <span className="text-xs font-mono text-[#E4E9DA]/80">
                  Laporan_Lengkap_BE1_Rancakin_Minggu_1_Sampai_4.pdf
                </span>
              </div>
              <h2 className="text-base sm:text-lg font-bold text-white mt-0.5">
                Dokumen Lengkap Backend 1 (BE-1) Minggu 1 s/d Minggu 4 — Bahasa Mudah Dipahami
              </h2>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={handleDownloadPdf}
              disabled={isDownloading}
              className="flex items-center gap-2 px-4 py-2.5 rounded-lg bg-[#E85D1A] hover:bg-[#d14e10] text-white font-semibold text-xs sm:text-sm shadow-md transition cursor-pointer"
            >
              <FileDown className="w-4 h-4" />
              {isDownloading ? 'Menyiapkan File PDF...' : 'Unduh File .PDF Sekarang'}
            </button>
            <button
              onClick={() => window.print()}
              className="hidden sm:flex items-center gap-1.5 px-3 py-2.5 rounded-lg bg-[#234B24] hover:bg-[#1E9E5A] text-white text-xs font-medium transition cursor-pointer"
              title="Cetak Halaman"
            >
              <Printer className="w-4 h-4" />
              Cetak
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-lg bg-white/10 hover:bg-white/20 text-white transition cursor-pointer"
              aria-label="Tutup Pratinjau"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Chapter Filter Bar */}
        <div className="bg-[#E4E9DA] px-5 py-2.5 border-b border-[#234B24]/20 flex items-center gap-2 overflow-x-auto">
          <span className="text-xs font-semibold text-[#234B24] shrink-0">Lompat ke Bab:</span>
          {chapters.map((chap) => (
            <button
              key={chap.id}
              onClick={() => setActiveChapter(chap.id)}
              className={`px-3 py-1 rounded-md text-xs font-medium transition shrink-0 cursor-pointer ${
                activeChapter === chap.id
                  ? 'bg-[#234B24] text-white shadow-sm'
                  : 'bg-white text-[#1B1F1A] hover:bg-[#234B24]/10 border border-[#234B24]/20'
              }`}
            >
              {chap.label}
            </button>
          ))}
        </div>

        {/* Scrollable A4 Document Sheets Container */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-8 space-y-8 bg-[#D8DDD0]">
          {/* BAB 1: SAMPUL & RINGKASAN TIM */}
          {showSection('bab1') && (
            <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg border border-[#234B24]/25 overflow-hidden">
              <div className="bg-[#234B24] text-white p-6 sm:p-8 border-b-4 border-[#E85D1A]">
                <div className="text-xs font-mono uppercase tracking-widest text-[#E4E9DA] mb-1">
                  DOKUMEN LENGKAP ARSITEKTUR & LAPORAN KERJA MINGGU 1 – MINGGU 4
                </div>
                <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">
                  RANCAK.IN (WISGO) — BACKEND 1 (CORE & SPASIAL)
                </h1>
                <p className="text-sm text-[#E4E9DA] mt-2 leading-relaxed">
                  Panduan lengkap pengerjaan Minggu 1 sampai Minggu 4 beserta 5 Diagram Visual (ERD,
                  Class Diagram, Sequence Diagram, Use Case, dan Arsitektur Sistem), kamus tabel &
                  kolom Bahasa Indonesia, serta daftar lengkap 24 alamat API dengan bahasa sehari-hari
                  yang santai dan mudah dipahami.
                </p>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-5 pt-4 border-t border-white/20 text-xs">
                  <div>
                    <div className="text-[#E4E9DA]/70">Total Tabel Database</div>
                    <div className="text-base font-bold text-white">11 Tabel BE-1 + 4 BE-2</div>
                  </div>
                  <div>
                    <div className="text-[#E4E9DA]/70">Total Alamat API</div>
                    <div className="text-base font-bold text-white">24 Endpoint Siap Pakai</div>
                  </div>
                  <div>
                    <div className="text-[#E4E9DA]/70">Rentang Pengerjaan</div>
                    <div className="text-base font-bold text-white">Minggu 1 – 4 (Hari 1–20)</div>
                  </div>
                  <div>
                    <div className="text-[#E4E9DA]/70">Status Pengujian</div>
                    <div className="text-base font-bold text-[#8CF0B6]">32/32 Tes Otomatis Lulus</div>
                  </div>
                </div>
              </div>

              <div className="p-6 sm:p-8 space-y-5">
                <div className="flex items-center gap-2 text-[#234B24] font-bold text-base border-b border-[#E4E9DA] pb-2">
                  <Users className="w-5 h-5 text-[#1E9E5A]" />
                  <span>Bab 1 — Pembagian Tugas 5 Anggota Tim Rancak.in (WISGO)</span>
                </div>
                <p className="text-xs sm:text-sm text-gray-700 leading-relaxed">
                  Supaya pekerjaan tidak tumpang tindih, proyek Rancak.in dibagi menjadi 5 peran.
                  Anda bertugas sebagai <strong>BE-1 (Backend 1)</strong> yang mengurus peta wisata,
                  navigasi 360 derajat, tarif resmi perda, laporan pungli, sampai tombol darurat SOS.
                </p>

                <div className="grid grid-cols-1 gap-3">
                  {ROLE_BOUNDARY_MATRIX.map((member) => (
                    <div
                      key={member.roleCode}
                      className={`p-3.5 rounded-lg border ${
                        member.roleCode === 'BE-1'
                          ? 'bg-[#E4E9DA]/60 border-[#1E9E5A] ring-1 ring-[#1E9E5A]'
                          : 'bg-[#F6F3EC]/60 border-gray-200'
                      }`}
                    >
                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <span className="font-bold text-sm text-[#234B24]">
                          [{member.roleCode}] {member.roleName}
                        </span>
                        <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-[#234B24] text-white">
                          {member.routePrefixOrBoundary}
                        </span>
                      </div>
                      <p className="text-xs text-gray-700 mt-1.5">{member.sprint1Focus}</p>
                      <div className="text-[11px] text-[#E85D1A] font-medium mt-1">
                        Aturan Kerja Sama dengan BE-1: {member.interactionRuleForBE1}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* BAB 2: RANGKUMAN MINGGU 1 S/D MINGGU 4 */}
          {showSection('bab2') && (
            <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg border border-[#234B24]/25 p-6 sm:p-8 space-y-5">
              <div className="flex items-center justify-between border-b-2 border-[#234B24] pb-3">
                <div className="flex items-center gap-2.5">
                  <Calendar className="w-5 h-5 text-[#E85D1A]" />
                  <h2 className="text-lg font-bold text-[#234B24]">
                    Bab 2 — Rangkuman Pekerjaan Minggu 1 sampai Minggu 4 (Hari 1–20)
                  </h2>
                </div>
                <span className="text-xs font-mono bg-[#E4E9DA] text-[#234B24] px-2.5 py-1 rounded font-semibold">
                  20 Hari Kerja
                </span>
              </div>

              <p className="text-xs sm:text-sm text-gray-700 leading-relaxed">
                Berikut adalah catatan lengkap apa saja yang dikerjakan oleh BE-1 dari Minggu ke-1
                sampai Minggu ke-4 beserta hasil nyata (deliverable) setiap harinya:
              </p>

              <div className="space-y-3">
                {all20Days.map((item) => (
                  <div
                    key={item.id}
                    className="p-3.5 rounded-lg bg-[#F6F3EC] border border-[#234B24]/20 flex flex-col sm:flex-row sm:items-start justify-between gap-3"
                  >
                    <div className="space-y-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-[#234B24] text-white">
                          {item.sprintBadge} • {item.day}
                        </span>
                        <h3 className="text-sm font-bold text-[#1B1F1A]">{item.title}</h3>
                      </div>
                      <p className="text-xs text-gray-700 leading-relaxed">{item.focus}</p>
                      <div className="text-[11px] font-mono text-[#1E9E5A] font-semibold">
                        Hasil Utama: {item.deliverable}
                      </div>
                    </div>
                    <span className="shrink-0 self-start inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-1 rounded bg-[#1E9E5A]/15 text-[#234B24]">
                      <CheckCircle2 className="w-3.5 h-3.5 text-[#1E9E5A]" />
                      Selesai
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BAB 3: DIAGRAM ERD & KAMUS 15 TABEL BAHASA INDONESIA */}
          {showSection('bab3') && (
            <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg border border-[#234B24]/25 p-6 sm:p-8 space-y-6">
              <div className="flex items-center justify-between border-b-2 border-[#234B24] pb-3">
                <div className="flex items-center gap-2.5">
                  <Database className="w-5 h-5 text-[#1E9E5A]" />
                  <h2 className="text-lg font-bold text-[#234B24]">
                    Bab 3 — Diagram Hubungan Tabel (ERD) & Kamus Kolom Bahasa Indonesia
                  </h2>
                </div>
                <span className="text-xs font-mono bg-[#E4E9DA] text-[#234B24] px-2.5 py-1 rounded font-semibold">
                  11 Tabel BE-1 + 4 Tabel BE-2
                </span>
              </div>

              <p className="text-xs sm:text-sm text-gray-700 leading-relaxed">
                Seluruh nama tabel dan nama kolom (field) di bawah ini sudah menggunakan{' '}
                <strong>Bahasa Indonesia</strong> agar langsung mudah dimengerti fungsinya. Tabel{' '}
                <code className="font-mono bg-[#E4E9DA] px-1.5 py-0.5 rounded text-[#234B24]">
                  destinasi_wisata
                </code>{' '}
                menjadi tabel induk yang dihubungkan oleh 9 tabel anak di BE-1 serta berelasi dengan
                tabel milik BE-2.
              </p>

              {/* Visual Bagan Hubungan ERD */}
              <div className="p-4 rounded-xl bg-[#F6F3EC] border-2 border-[#234B24]/30 space-y-3">
                <div className="text-xs font-bold uppercase tracking-wider text-[#234B24] text-center">
                  Bagan Visual Hubungan Tabel (ERD) — Pusat Data: destinasi_wisata
                </div>
                <div className="p-3 rounded-lg bg-[#234B24] text-white text-center shadow">
                  <div className="text-xs font-mono text-[#8CF0B6]">TABEL INDUK UTAMA (BE-1)</div>
                  <div className="text-base font-bold font-mono">destinasi_wisata</div>
                  <div className="text-[11px] text-[#E4E9DA]">
                    Kunci Utama (PK): id_destinasi • Menyimpan nama wisata, titik GPS, jam buka, dan
                    ringkasan info
                  </div>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-1">
                  {ERD_ENTITIES_BE1_AND_BOUNDARY.filter(
                    (t) => t.tableName !== 'destinasi_wisata'
                  ).map((tbl) => (
                    <div
                      key={tbl.tableName}
                      className={`p-2.5 rounded-lg border text-xs ${
                        tbl.owner === 'BE-1'
                          ? 'bg-white border-[#1E9E5A]'
                          : 'bg-[#EEF0FF] border-[#5B6AE8] border-dashed'
                      }`}
                    >
                      <div className="flex items-center justify-between gap-1">
                        <span className="font-mono font-bold text-[#1B1F1A] truncate">
                          {tbl.tableName}
                        </span>
                        <span
                          className={`text-[10px] font-mono px-1.5 py-0.5 rounded text-white ${
                            tbl.owner === 'BE-1' ? 'bg-[#234B24]' : 'bg-[#5B6AE8]'
                          }`}
                        >
                          {tbl.owner}
                        </span>
                      </div>
                      <div className="text-[11px] text-gray-600 mt-1 line-clamp-2">
                        {tbl.moduleGroup}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Rincian Kolom Setiap Tabel */}
              <div className="space-y-4">
                {ERD_ENTITIES_BE1_AND_BOUNDARY.map((entity, idx) => (
                  <div
                    key={entity.tableName}
                    className="rounded-lg border border-gray-300 overflow-hidden"
                  >
                    <div
                      className={`px-4 py-2.5 text-white flex flex-wrap items-center justify-between gap-2 ${
                        entity.owner === 'BE-1' ? 'bg-[#234B24]' : 'bg-[#5B6AE8]'
                      }`}
                    >
                      <div className="font-mono font-bold text-sm">
                        {idx + 1}. {entity.tableName}{' '}
                        <span className="font-sans font-normal text-xs opacity-90">
                          — {entity.moduleGroup}
                        </span>
                      </div>
                      <span className="text-[11px] font-mono bg-black/25 px-2 py-0.5 rounded">
                        {entity.owner} • {entity.sprint}
                      </span>
                    </div>
                    <div className="p-3.5 bg-[#F6F3EC]/50 text-xs text-gray-700 border-b border-gray-200">
                      <strong>Penjelasan Singkat:</strong> {entity.description}
                    </div>
                    <div className="overflow-x-auto">
                      <table className="w-full text-left border-collapse text-xs">
                        <thead>
                          <tr className="bg-[#E4E9DA] text-[#234B24]">
                            <th className="py-2 px-3 font-semibold border-b border-gray-300">
                              Nama Kolom (Field)
                            </th>
                            <th className="py-2 px-3 font-semibold border-b border-gray-300">
                              Tipe Data
                            </th>
                            <th className="py-2 px-3 font-semibold border-b border-gray-300">
                              Kunci
                            </th>
                            <th className="py-2 px-3 font-semibold border-b border-gray-300">
                              Keterangan Mudah Dipahami
                            </th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200">
                          {entity.columns.map((col) => (
                            <tr key={col.name} className="hover:bg-gray-50">
                              <td className="py-2 px-3 font-mono font-semibold text-[#1B1F1A]">
                                {col.name}
                              </td>
                              <td className="py-2 px-3 font-mono text-gray-600">{col.dataType}</td>
                              <td className="py-2 px-3 font-mono">
                                {col.keyType !== 'NORMAL' ? (
                                  <span className="px-1.5 py-0.5 rounded bg-[#E85D1A]/15 text-[#E85D1A] font-bold">
                                    {col.keyType}
                                  </span>
                                ) : (
                                  '-'
                                )}
                              </td>
                              <td className="py-2 px-3 text-gray-700">{col.description}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BAB 4: CLASS DIAGRAM GO */}
          {showSection('bab4') && (
            <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg border border-[#234B24]/25 p-6 sm:p-8 space-y-5">
              <div className="flex items-center justify-between border-b-2 border-[#234B24] pb-3">
                <div className="flex items-center gap-2.5">
                  <Layers className="w-5 h-5 text-[#1E9E5A]" />
                  <h2 className="text-lg font-bold text-[#234B24]">
                    Bab 4 — Susunan Kode Program Go (Class Diagram BE-1)
                  </h2>
                </div>
                <span className="text-xs font-mono bg-[#E4E9DA] text-[#234B24] px-2.5 py-1 rounded font-semibold">
                  {GO_CLASS_DIAGRAM_NODES.length} Komponen Utama
                </span>
              </div>

              <p className="text-xs sm:text-sm text-gray-700 leading-relaxed">
                Agar kode program rapi dan gampang dirawat, kode Go pada BE-1 dibagi menjadi{' '}
                {GO_CLASS_DIAGRAM_NODES.length} komponen yang saling bekerja sama:
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {GO_CLASS_DIAGRAM_NODES.map((cls) => (
                  <div
                    key={cls.id}
                    className="rounded-lg border border-[#234B24]/30 overflow-hidden bg-[#F6F3EC]/40 flex flex-col"
                  >
                    <div className="bg-[#234B24] text-white px-4 py-2.5 flex items-center justify-between">
                      <span className="font-mono font-bold text-sm">{cls.className}</span>
                      <span className="text-[10px] font-mono bg-white/20 px-2 py-0.5 rounded">
                        {cls.stereotype}
                      </span>
                    </div>
                    <div className="p-4 space-y-3 flex-1">
                      <p className="text-xs text-gray-700">{cls.description}</p>
                      <div>
                        <div className="text-[11px] font-bold uppercase text-[#234B24] mb-1">
                          Isi Data (Fields):
                        </div>
                        <ul className="space-y-1 text-xs font-mono text-gray-700 bg-white p-2.5 rounded border border-gray-200">
                          {cls.fields.map((f, i) => (
                            <li key={i}>
                              {f.visibility} {f.name}: {f.type}
                            </li>
                          ))}
                        </ul>
                      </div>
                      <div>
                        <div className="text-[11px] font-bold uppercase text-[#1E9E5A] mb-1">
                          Fungsi Utama (Methods):
                        </div>
                        <ul className="space-y-1 text-xs font-mono text-[#1B1F1A] bg-white p-2.5 rounded border border-gray-200">
                          {cls.methods.map((m, i) => (
                            <li key={i}>
                              {m.visibility} {m.name}({m.params}) [{m.sprintOrigin}]
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BAB 5: SEQUENCE DIAGRAM (4 CERITA ALUR KERJA) */}
          {showSection('bab5') && (
            <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg border border-[#234B24]/25 p-6 sm:p-8 space-y-5">
              <div className="flex items-center justify-between border-b-2 border-[#234B24] pb-3">
                <div className="flex items-center gap-2.5">
                  <GitBranch className="w-5 h-5 text-[#E85D1A]" />
                  <h2 className="text-lg font-bold text-[#234B24]">
                    Bab 5 — Urutan Langkah Kerja Sistem (Sequence Diagram)
                  </h2>
                </div>
                <span className="text-xs font-mono bg-[#E4E9DA] text-[#234B24] px-2.5 py-1 rounded font-semibold">
                  4 Skenario Minggu 1–4
                </span>
              </div>

              <div className="space-y-5">
                {SEQUENCE_SCENARIOS.map((flow) => (
                  <div
                    key={flow.id}
                    className="rounded-lg border border-[#234B24]/30 overflow-hidden bg-[#F6F3EC]/50"
                  >
                    <div className="bg-[#234B24] text-white px-4 py-3 flex flex-wrap items-center justify-between gap-2">
                      <div>
                        <span className="text-[11px] font-mono text-[#8CF0B6] block">
                          {flow.sprintBadge}
                        </span>
                        <h3 className="text-sm font-bold">{flow.title}</h3>
                      </div>
                    </div>
                    <div className="p-4 space-y-3">
                      <p className="text-xs text-gray-700">{flow.summary}</p>
                      <div className="space-y-2">
                        {flow.steps.map((st) => (
                          <div
                            key={st.stepNo}
                            className="p-3 rounded-lg bg-white border border-gray-200 flex items-start gap-3"
                          >
                            <span className="w-6 h-6 rounded-full bg-[#E85D1A] text-white text-xs font-bold flex items-center justify-center shrink-0 mt-0.5">
                              {st.stepNo}
                            </span>
                            <div className="space-y-1 text-xs flex-1">
                              <div className="flex flex-wrap items-center gap-1.5">
                                <span className="font-bold text-[#234B24]">{st.fromActor}</span>
                                <span className="text-gray-400">➔</span>
                                <span className="font-bold text-[#1E9E5A]">{st.toActor}</span>
                                <span className="font-mono text-[11px] px-2 py-0.5 rounded bg-[#E4E9DA] text-[#1B1F1A]">
                                  {st.message}
                                </span>
                              </div>
                              <p className="text-gray-600">
                                {st.protocolOrSql} — Hasil: {st.returnPayload} ({st.latencyNote})
                              </p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* BAB 6: USE CASE & 24 ALAMAT API */}
          {showSection('bab6') && (
            <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg border border-[#234B24]/25 p-6 sm:p-8 space-y-6">
              <div className="flex items-center justify-between border-b-2 border-[#234B24] pb-3">
                <div className="flex items-center gap-2.5">
                  <Users className="w-5 h-5 text-[#1E9E5A]" />
                  <h2 className="text-lg font-bold text-[#234B24]">
                    Bab 6 — Siapa Bisa Pakai Fitur Apa (Use Case) & Katalog 24 API BE-1
                  </h2>
                </div>
                <span className="text-xs font-mono bg-[#E4E9DA] text-[#234B24] px-2.5 py-1 rounded font-semibold">
                  {USE_CASE_ACTORS.length} Pengguna & 24 API
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {USE_CASE_ACTORS.map((actor) => {
                  const actorUseCases = USE_CASE_ITEMS_24.filter((uc) =>
                    uc.actors.includes(actor.id as (typeof uc.actors)[number])
                  );
                  return (
                    <div
                      key={actor.id}
                      className="p-4 rounded-lg bg-[#F6F3EC] border border-[#234B24]/25 space-y-2.5"
                    >
                      <div>
                        <h3 className="text-sm font-bold text-[#234B24]">{actor.name}</h3>
                        <p className="text-xs text-gray-600">{actor.description}</p>
                      </div>
                      <ul className="space-y-1.5 text-xs">
                        {actorUseCases.map((uc) => (
                          <li
                            key={uc.id}
                            className="p-2 rounded bg-white border border-gray-200 flex flex-col gap-0.5"
                          >
                            <div className="flex items-center justify-between">
                              <span className="font-bold text-[#1B1F1A]">
                                [{uc.code}] {uc.title}
                              </span>
                              <span className="text-[10px] font-mono text-[#1E9E5A] font-semibold">
                                {uc.sprint}
                              </span>
                            </div>
                            <span className="font-mono text-[11px] text-[#E85D1A]">
                              {uc.endpoint}
                            </span>
                            <span className="text-gray-600">
                              Akses: {uc.authRequirement} • Target Kecepatan: {uc.slaTarget}
                            </span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  );
                })}
              </div>

              {/* Tabel 24 API */}
              <div className="space-y-2 pt-2">
                <h3 className="text-sm font-bold text-[#234B24]">
                  Daftar Lengkap 24 Alamat API Backend 1 (Minggu 1 – Minggu 4)
                </h3>
                <div className="overflow-x-auto rounded-lg border border-gray-300">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="bg-[#234B24] text-white">
                        <th className="py-2 px-3">#</th>
                        <th className="py-2 px-3">Metode</th>
                        <th className="py-2 px-3">Alamat URL Endpoint</th>
                        <th className="py-2 px-3">Minggu</th>
                        <th className="py-2 px-3">Kegunaan Singkat</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {USE_CASE_ITEMS_24.map((ep, idx) => {
                        const [methodPart, ...pathParts] = ep.endpoint.split(' ');
                        const pathStr = pathParts.join(' ') || ep.endpoint;
                        return (
                          <tr key={ep.id} className="hover:bg-gray-50">
                            <td className="py-2 px-3 font-mono text-gray-500">{idx + 1}</td>
                            <td className="py-2 px-3 font-mono font-bold">
                              <span
                                className={`px-2 py-0.5 rounded text-[11px] ${
                                  methodPart === 'GET'
                                    ? 'bg-[#1E9E5A]/15 text-[#234B24]'
                                    : 'bg-[#E85D1A]/15 text-[#E85D1A]'
                                }`}
                              >
                                {methodPart}
                              </span>
                            </td>
                            <td className="py-2 px-3 font-mono font-semibold text-[#1B1F1A]">
                              {pathStr}
                            </td>
                            <td className="py-2 px-3 font-mono text-gray-600">{ep.sprint}</td>
                            <td className="py-2 px-3 text-gray-700">{ep.title}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* BAB 7: ARSITEKTUR SISTEM 4 LAPISAN */}
          {showSection('bab7') && (
            <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-lg border border-[#234B24]/25 p-6 sm:p-8 space-y-5">
              <div className="flex items-center justify-between border-b-2 border-[#234B24] pb-3">
                <div className="flex items-center gap-2.5">
                  <Cpu className="w-5 h-5 text-[#1E9E5A]" />
                  <h2 className="text-lg font-bold text-[#234B24]">
                    Bab 7 — Gambaran Besar Arsitektur Sistem 4 Lapisan
                  </h2>
                </div>
                <span className="text-xs font-mono bg-[#E4E9DA] text-[#234B24] px-2.5 py-1 rounded font-semibold">
                  End-to-End Architecture
                </span>
              </div>

              <p className="text-xs sm:text-sm text-gray-700 leading-relaxed">
                Bagan di bawah ini menjelaskan bagaimana aliran data berjalan dari layar HP/Web
                wisatawan sampai tersimpan aman di database PostgreSQL + PostGIS:
              </p>

              <div className="space-y-3">
                {ARCHITECTURE_4_LAYERS_SUMMARY.map((layer) => (
                  <div
                    key={layer.layerId}
                    className="p-4 rounded-xl bg-[#F6F3EC] border-l-4 border-[#234B24] space-y-2"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-bold text-[#234B24]">{layer.layerName}</span>
                      <span className="text-xs font-mono text-gray-600">{layer.subtitle}</span>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-1">
                      {layer.nodes.map((node) => (
                        <div
                          key={node.title}
                          className="p-3 rounded-lg bg-white border border-gray-200 space-y-1"
                        >
                          <div className="text-xs font-bold text-[#1B1F1A]">{node.title}</div>
                          <div className="text-[11px] font-mono text-[#E85D1A]">
                            {node.techStack}
                          </div>
                          <p className="text-xs text-gray-600">{node.description}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
