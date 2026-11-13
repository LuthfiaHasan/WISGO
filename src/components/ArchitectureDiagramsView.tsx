import React, { useState } from 'react';
import {
  Database,
  Layers,
  GitBranch,
  Users,
  Cpu,
  Copy,
  Check,
  Download,
  Code2,
  Eye,
  ArrowRight,
  Key,
  Link2,
  ShieldCheck,
  Compass,
  FileDown,
  BookOpen,
} from 'lucide-react';
import {
  ERD_ENTITIES_BE1_AND_BOUNDARY,
  ERD_RELATIONSHIPS,
  GO_CLASS_DIAGRAM_NODES,
  GO_CLASS_RELATIONSHIPS,
  SEQUENCE_SCENARIOS,
  USE_CASE_ACTORS,
  USE_CASE_ITEMS_24,
  MERMAID_ERD_CODE,
  MERMAID_CLASS_DIAGRAM_CODE,
  MERMAID_USECASE_CODE,
  MERMAID_ARCHITECTURE_CODE,
  type DiagramKind,
  type ErdEntityNode,
  type UseCaseItem,
} from '../data/architectureDiagramsData';
import { GO_SPRINT1_CODE_FILES } from '../data/goCodeRepository';
import { GO_SPRINT2_CODE_FILES } from '../data/goCodeSprint2Repository';
import { GO_SPRINT3_CODE_FILES } from '../data/goCodeSprint3Repository';
import { GO_SPRINT4_CODE_FILES } from '../data/goCodeSprint4Repository';
import { generateAndDownloadCompleteBe1Pdf } from '../utils/pdfReportGenerator';
import { PdfReportPreviewModal } from './PdfReportPreviewModal';

export const ArchitectureDiagramsView: React.FC = () => {
  const [activeDiagram, setActiveDiagram] = useState<DiagramKind>('erd');
  const [viewMode, setViewMode] = useState<'visual' | 'mermaid'>('visual');
  const [isPdfPreviewOpen, setIsPdfPreviewOpen] = useState<boolean>(false);

  // Filter state untuk ERD
  const [erdSprintFilter, setErdSprintFilter] = useState<string>('ALL');
  const [selectedErdTableId, setSelectedErdTableId] = useState<string>('tbl-destinations');

  // Filter state untuk Class Diagram
  const [classLayerFilter, setClassLayerFilter] = useState<string>('ALL');

  // State untuk Sequence Diagram
  const [selectedSequenceId, setSelectedSequenceId] = useState<string>(SEQUENCE_SCENARIOS[0].id);

  // Filter state untuk Use Case Diagram
  const [selectedActorId, setSelectedActorId] = useState<string>('ALL');
  const [useCaseSprintFilter, setUseCaseSprintFilter] = useState<string>('ALL');

  // Copy states
  const [copiedMermaid, setCopiedMermaid] = useState<boolean>(false);
  const [copiedSqlDdl, setCopiedSqlDdl] = useState<boolean>(false);

  const selectedSequence =
    SEQUENCE_SCENARIOS.find((s) => s.id === selectedSequenceId) || SEQUENCE_SCENARIOS[0];

  const getActiveMermaidCode = (): string => {
    switch (activeDiagram) {
      case 'erd':
        return MERMAID_ERD_CODE;
      case 'class':
        return MERMAID_CLASS_DIAGRAM_CODE;
      case 'sequence':
        return selectedSequence.mermaidCode;
      case 'usecase':
        return MERMAID_USECASE_CODE;
      case 'architecture':
        return MERMAID_ARCHITECTURE_CODE;
    }
  };

  const getCombinedSqlDdl = (): string => {
    const s1 = GO_SPRINT1_CODE_FILES.find((f) => f.filename.endsWith('.sql'))?.content || '';
    const s2 = GO_SPRINT2_CODE_FILES.find((f) => f.filename.endsWith('.sql'))?.content || '';
    const s3 = GO_SPRINT3_CODE_FILES.find((f) => f.filename.endsWith('.sql'))?.content || '';
    const s4 = GO_SPRINT4_CODE_FILES.find((f) => f.filename.endsWith('.sql'))?.content || '';
    return [
      '-- ============================================================================',
      '-- GABUNGAN LENGKAP SQL TABEL BE-1 (MINGGU 1 S/D MINGGU 4)',
      '-- Mencakup 11 Tabel Utama + Tabel Ringkasan Peringkat + Indeks Pencarian Cepat',
      '-- ============================================================================\n',
      s1,
      '\n',
      s2,
      '\n',
      s3,
      '\n',
      s4,
    ].join('\n');
  };

  const handleCopyMermaid = () => {
    navigator.clipboard.writeText(getActiveMermaidCode());
    setCopiedMermaid(true);
    setTimeout(() => setCopiedMermaid(false), 1800);
  };

  const handleCopyFullSqlDdl = () => {
    navigator.clipboard.writeText(getCombinedSqlDdl());
    setCopiedSqlDdl(true);
    setTimeout(() => setCopiedSqlDdl(false), 1800);
  };

  const handleDownloadFullMarkdownDoc = () => {
    const mdContent = `# Dokumentasi Lengkap Diagram ERD, Class Diagram, Alur & Fitur BE-1
**Proyek**: Rancak.in (WISGO) — Aplikasi Wisata Sumatera Barat  
**Bagian Anda**: Backend 1 (BE-1: Mengurus Peta, Tempat Wisata, Foto 360°, Anti-Pungli & Keamanan Jalan)  
**Cakupan**: Minggu 1 sampai Minggu 4 (11 Tabel Database & 24 Alamat API)

---

## 1. Diagram Tabel Database (ERD — 11 Tabel BE-1 + Hubungan ke BE-2)

\`\`\`mermaid
${MERMAID_ERD_CODE}
\`\`\`

---

## 2. Diagram Bagian Kode Go (Class Diagram \`backend/internal/be1_core\`)

\`\`\`mermaid
${MERMAID_CLASS_DIAGRAM_CODE}
\`\`\`

---

## 3. Cerita Alur Kerja Sistem (Sequence Diagram)

${SEQUENCE_SCENARIOS.map(
  (seq) => `### ${seq.title} (${seq.sprintBadge})
${seq.summary}

\`\`\`mermaid
${seq.mermaidCode}
\`\`\`
`
).join('\n')}

---

## 4. Diagram Pembagian Akses Pengguna (Use Case — 4 Pengguna vs 24 Fitur API)

\`\`\`mermaid
${MERMAID_USECASE_CODE}
\`\`\`

---

## 5. Gambaran Besar Cara Kerja Sistem (Arsitektur)

\`\`\`mermaid
${MERMAID_ARCHITECTURE_CODE}
\`\`\`
`;

    const blob = new Blob([mdContent], { type: 'text/markdown;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'WISGO_BE1_ERD_Class_UML_Architecture_Minggu1_4.md';
    a.click();
    URL.revokeObjectURL(url);
  };

  const filteredErdEntities = ERD_ENTITIES_BE1_AND_BOUNDARY.filter((ent) => {
    if (erdSprintFilter === 'ALL') return true;
    return ent.sprint === erdSprintFilter;
  });

  const selectedErdEntity: ErdEntityNode =
    ERD_ENTITIES_BE1_AND_BOUNDARY.find((e) => e.id === selectedErdTableId) ||
    ERD_ENTITIES_BE1_AND_BOUNDARY[0];

  const selectedEntityRelations = ERD_RELATIONSHIPS.filter(
    (rel) =>
      rel.fromTable === selectedErdEntity.tableName || rel.toTable === selectedErdEntity.tableName
  );

  const filteredClasses = GO_CLASS_DIAGRAM_NODES.filter((cls) => {
    if (classLayerFilter === 'ALL') return true;
    return cls.layer === classLayerFilter;
  });

  const filteredUseCases = USE_CASE_ITEMS_24.filter((uc) => {
    const matchActor =
      selectedActorId === 'ALL' ||
      uc.actors.includes(selectedActorId as UseCaseItem['actors'][number]);
    const matchSprint = useCaseSprintFilter === 'ALL' || uc.sprint === useCaseSprintFilter;
    return matchActor && matchSprint;
  });

  return (
    <div className="space-y-6">
      {/* ====================================================================
          HEADER STUDIO DIAGRAM & TOMBOL SALIN
          ==================================================================== */}
      <section className="bg-white border border-[#E2DFD7] rounded-xl p-6">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-5 border-b border-[#E2DFD7]">
          <div>
            <div className="text-xs text-[#5A625A]">
              Rangkuman Visual Minggu 1 s/d Minggu 4 · Bahasa penjelasan santai & mudah dipahami, nama tabel tetap asli
            </div>
            <h2 className="text-xl font-bold text-[#1B1F1A] mt-0.5">
              06. Studio Diagram: ERD Database, Class Diagram Go, Alur Kerja (Sequence) & Use Case
            </h2>
            <p className="text-xs text-[#5A625A] mt-1 leading-relaxed max-w-3xl">
              Halaman ini memvisualisasikan seluruh pekerjaan Anda sebagai <strong>BE-1</strong> di folder{' '}
              <code className="font-mono text-[#234B24]">backend/internal/be1_core/</code>: mulai dari hubungan antar{' '}
              <strong>11 tabel database</strong>, susunan kode Go, cerita alur fitur, hingga siapa saja yang memakai{' '}
              <strong>24 alamat API</strong>.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 shrink-0">
            <button
              onClick={() => generateAndDownloadCompleteBe1Pdf()}
              className="px-4 py-2 text-xs font-bold text-white bg-[#E85D1A] rounded-lg hover:bg-[#d14e10] shadow-sm transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <FileDown className="w-4 h-4" />
              Download PDF Lengkap (Minggu 1–4)
            </button>

            <button
              onClick={() => setIsPdfPreviewOpen(true)}
              className="px-3.5 py-2 text-xs font-semibold text-white bg-[#234B24] rounded-lg hover:bg-[#1a381b] transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <BookOpen className="w-3.5 h-3.5" />
              Pratinjau Dokumen PDF (A4)
            </button>

            <button
              onClick={handleCopyMermaid}
              className="px-3.5 py-2 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              {copiedMermaid ? (
                <Check className="w-3.5 h-3.5 text-[#1E9E5A]" />
              ) : (
                <Copy className="w-3.5 h-3.5" />
              )}
              {copiedMermaid ? 'Kode Diagram Tersalin!' : 'Salin Kode Mermaid'}
            </button>

            <button
              onClick={handleCopyFullSqlDdl}
              className="px-3.5 py-2 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              {copiedSqlDdl ? (
                <Check className="w-3.5 h-3.5 text-[#1E9E5A]" />
              ) : (
                <Database className="w-3.5 h-3.5" />
              )}
              {copiedSqlDdl ? 'SQL Tersalin!' : 'Salin Semua SQL Tabel'}
            </button>

            <button
              onClick={handleDownloadFullMarkdownDoc}
              className="px-3.5 py-2 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <Download className="w-3.5 h-3.5" />
              Unduh .md
            </button>
          </div>
        </div>

        {/* BANNER UNDUH DOKUMEN PDF LENGKAP MINGGU 1 S/D MINGGU 4 */}
        <div className="mt-4 p-4 rounded-xl bg-[#E4E9DA]/70 border border-[#1E9E5A]/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="space-y-0.5">
            <div className="text-xs font-bold text-[#234B24] flex items-center gap-2">
              <span className="px-2 py-0.5 rounded bg-[#234B24] text-white font-mono text-[10px]">
                BARU • SIAP CETAK A4
              </span>
              <span>
                Dokumen Laporan Lengkap PDF (Minggu 1 sampai Minggu 4 + 5 Diagram Visual + 24 API)
              </span>
            </div>
            <p className="text-xs text-[#5A625A]">
              Berisi rangkuman kerja 20 hari, gambar bagan ERD & nama tabel/kolom Bahasa Indonesia,
              Class Diagram Go, 4 Sequence Diagram, Use Case, dan Arsitektur 4 Lapisan dengan bahasa
              yang santai dan mudah dipahami.
            </p>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={() => setIsPdfPreviewOpen(true)}
              className="px-3.5 py-2 text-xs font-semibold text-[#234B24] bg-white border border-[#234B24]/30 rounded-lg hover:bg-[#F6F3EC] transition-colors flex items-center gap-1.5 cursor-pointer"
            >
              <Eye className="w-3.5 h-3.5" />
              Lihat Pratinjau A4
            </button>
            <button
              onClick={() => generateAndDownloadCompleteBe1Pdf()}
              className="px-4 py-2 text-xs font-bold text-white bg-[#E85D1A] rounded-lg hover:bg-[#d14e10] transition-colors flex items-center gap-1.5 cursor-pointer shadow-sm"
            >
              <FileDown className="w-3.5 h-3.5" />
              Unduh File .PDF Sekali Klik
            </button>
          </div>
        </div>

        {/* PEMILIH 5 JENIS DIAGRAM & MODE TAMPILAN */}
        <div className="mt-5 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
          <div className="flex flex-wrap items-center gap-2">
            <button
              onClick={() => setActiveDiagram('erd')}
              className={`px-3.5 py-2 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 cursor-pointer ${
                activeDiagram === 'erd'
                  ? 'bg-[#234B24] text-white'
                  : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
              }`}
            >
              <Database className="w-3.5 h-3.5" />
              1. ERD (11 Tabel BE-1 + Batas BE-2)
            </button>

            <button
              onClick={() => setActiveDiagram('class')}
              className={`px-3.5 py-2 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 cursor-pointer ${
                activeDiagram === 'class'
                  ? 'bg-[#234B24] text-white'
                  : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
              }`}
            >
              <Layers className="w-3.5 h-3.5" />
              2. Class Diagram (Bagian Kode Go)
            </button>

            <button
              onClick={() => setActiveDiagram('sequence')}
              className={`px-3.5 py-2 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 cursor-pointer ${
                activeDiagram === 'sequence'
                  ? 'bg-[#234B24] text-white'
                  : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
              }`}
            >
              <GitBranch className="w-3.5 h-3.5" />
              3. Sequence Diagram (4 Cerita Alur)
            </button>

            <button
              onClick={() => setActiveDiagram('usecase')}
              className={`px-3.5 py-2 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 cursor-pointer ${
                activeDiagram === 'usecase'
                  ? 'bg-[#234B24] text-white'
                  : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
              }`}
            >
              <Users className="w-3.5 h-3.5" />
              4. Use Case (Siapa Pakai Fitur Apa)
            </button>

            <button
              onClick={() => setActiveDiagram('architecture')}
              className={`px-3.5 py-2 text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 cursor-pointer ${
                activeDiagram === 'architecture'
                  ? 'bg-[#234B24] text-white'
                  : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
              }`}
            >
              <Cpu className="w-3.5 h-3.5" />
              5. Gambaran Besar Sistem (Arsitektur)
            </button>
          </div>

          <div className="flex items-center gap-1.5 p-1 bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg self-start">
            <button
              onClick={() => setViewMode('visual')}
              className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-colors flex items-center gap-1.5 cursor-pointer ${
                viewMode === 'visual' ? 'bg-[#234B24] text-white' : 'text-[#5A625A] hover:text-[#1B1F1A]'
              }`}
            >
              <Eye className="w-3.5 h-3.5" />
              Lihat Gambar Interaktif
            </button>
            <button
              onClick={() => setViewMode('mermaid')}
              className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-colors flex items-center gap-1.5 cursor-pointer ${
                viewMode === 'mermaid' ? 'bg-[#234B24] text-white' : 'text-[#5A625A] hover:text-[#1B1F1A]'
              }`}
            >
              <Code2 className="w-3.5 h-3.5" />
              Lihat Kode Mermaid & SQL
            </button>
          </div>
        </div>
      </section>

      {/* ====================================================================
          MODE KODE MERMAID.JS & SQL DDL SIAP SALIN
          ==================================================================== */}
      {viewMode === 'mermaid' && (
        <section className="bg-white border border-[#E2DFD7] rounded-xl p-6 space-y-5">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-[#E2DFD7]">
            <div>
              <div className="text-xs font-semibold text-[#234B24]">
                Bisa langsung di-copy ke GitHub README, Notion, Mermaid Live Editor, atau Draw.io (Arrange → Insert → Mermaid)
              </div>
              <h3 className="text-base font-bold text-[#1B1F1A] mt-0.5">
                Kode Sumber Diagram ({activeDiagram.toUpperCase()})
              </h3>
            </div>
            <button
              onClick={handleCopyMermaid}
              className="px-4 py-2 text-xs font-semibold text-white bg-[#234B24] rounded-lg hover:bg-[#1a381b] transition-colors flex items-center gap-1.5 cursor-pointer self-start"
            >
              {copiedMermaid ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
              {copiedMermaid ? 'Berhasil Disalin!' : 'Salin Kode Mermaid Ini'}
            </button>
          </div>

          <pre className="p-5 text-xs font-mono bg-[#1B1F1A] text-[#F6F3EC] rounded-xl overflow-x-auto leading-relaxed max-h-[560px]">
            {getActiveMermaidCode()}
          </pre>

          <div className="pt-4 border-t border-[#E2DFD7]">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-3">
              <div>
                <div className="text-xs font-semibold text-[#5A625A]">
                  Kumpulan Perintah Pembuatan Tabel Database (Minggu 1 sampai Minggu 4)
                </div>
                <h4 className="text-sm font-bold text-[#1B1F1A]">
                  Gabungan Lengkap SQL untuk 11 Tabel BE-1 (PostgreSQL + PostGIS)
                </h4>
              </div>
              <button
                onClick={handleCopyFullSqlDdl}
                className="px-3.5 py-2 text-xs font-semibold text-[#1B1F1A] bg-[#F6F3EC] border border-[#D5D0C5] rounded-lg hover:bg-[#E4E9DA] transition-colors flex items-center gap-1.5 cursor-pointer self-start"
              >
                {copiedSqlDdl ? (
                  <Check className="w-3.5 h-3.5 text-[#1E9E5A]" />
                ) : (
                  <Copy className="w-3.5 h-3.5" />
                )}
                {copiedSqlDdl ? 'SQL Tersalin!' : 'Salin Semua SQL Ini'}
              </button>
            </div>
            <pre className="p-5 text-xs font-mono bg-[#1B1F1A] text-[#E4E9DA] rounded-xl overflow-x-auto leading-relaxed max-h-[420px]">
              {getCombinedSqlDdl()}
            </pre>
          </div>
        </section>
      )}

      {/* ====================================================================
          DIAGRAM 1: KANVAS VISUAL INTERAKTIF ERD (11 TABEL BE-1 + BATAS BE-2)
          ==================================================================== */}
      {viewMode === 'visual' && activeDiagram === 'erd' && (
        <div className="space-y-6">
          {/* Filter Sprint ERD */}
          <section className="bg-white border border-[#E2DFD7] rounded-xl p-5 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div>
              <div className="text-xs text-[#5A625A]">
                Klik salah satu kotak tabel di bawah untuk membaca arti setiap kolom dan melihat tabel itu nyambung ke mana saja
              </div>
              <div className="text-sm font-bold text-[#1B1F1A] mt-0.5">
                Saring Tabel Berdasarkan Minggu Pengerjaan
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-1.5">
              {[
                { id: 'ALL', label: 'Semua Tabel (11 BE-1 + 4 BE-2)' },
                { id: 'Minggu 1', label: 'Minggu 1 (4 Tabel Dasar Wisata)' },
                { id: 'Minggu 2', label: 'Minggu 2 (5 Tabel 360°, Mampir & Pungli)' },
                { id: 'Minggu 3', label: 'Minggu 3 (Ranking GPS, Bahaya & Budaya)' },
                { id: 'Boundary BE-2', label: 'Tabel Milik BE-2 yang Nyambung ke Kita' },
              ].map((flt) => (
                <button
                  key={flt.id}
                  onClick={() => setErdSprintFilter(flt.id)}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors cursor-pointer ${
                    erdSprintFilter === flt.id
                      ? 'bg-[#234B24] text-white'
                      : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
                  }`}
                >
                  {flt.label}
                </button>
              ))}
            </div>
          </section>

          {/* Grid Kanvas ERD */}
          <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
            <div className="xl:col-span-8 grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredErdEntities.map((ent) => {
                const isSelected = ent.id === selectedErdEntity.id;
                const isBE2 = ent.owner === 'BE-2';
                return (
                  <div
                    key={ent.id}
                    onClick={() => setSelectedErdTableId(ent.id)}
                    className={`rounded-xl border transition-all cursor-pointer overflow-hidden ${
                      isSelected
                        ? 'bg-white border-2 border-[#234B24] shadow-sm'
                        : isBE2
                        ? 'bg-[#F6F3EC]/80 border-dashed border-[#F26B4B] hover:bg-white'
                        : 'bg-white border-[#E2DFD7] hover:border-[#234B24]'
                    }`}
                  >
                    {/* Header Tabel ERD */}
                    <div
                      className={`px-4 py-3 border-b flex items-center justify-between gap-2 ${
                        isBE2
                          ? 'bg-[#F26B4B]/10 border-[#F26B4B]/30'
                          : isSelected
                          ? 'bg-[#234B24] text-white border-[#234B24]'
                          : 'bg-[#E4E9DA] border-[#D2DAC3]'
                      }`}
                    >
                      <div>
                        <div
                          className={`text-[11px] font-mono ${
                            isSelected && !isBE2 ? 'text-[#E4E9DA]' : 'text-[#5A625A]'
                          }`}
                        >
                          {ent.tableNumberLabel} · {ent.sprint} · {ent.moduleGroup}
                        </div>
                        <div
                          className={`font-mono text-sm font-bold mt-0.5 ${
                            isSelected && !isBE2
                              ? 'text-white'
                              : isBE2
                              ? 'text-[#F26B4B]'
                              : 'text-[#1B1F1A]'
                          }`}
                        >
                          {ent.tableName}
                        </div>
                      </div>
                      <span
                        className={`text-[11px] font-mono font-bold px-2 py-0.5 rounded ${
                          isBE2
                            ? 'bg-[#F26B4B] text-white'
                            : isSelected
                            ? 'bg-[#1E9E5A] text-white'
                            : 'bg-white text-[#234B24]'
                        }`}
                      >
                        {ent.owner}
                      </span>
                    </div>

                    {/* Daftar Kolom Utama di Kartu ERD */}
                    <div className="p-4 space-y-1.5">
                      <div className="text-[11px] font-mono text-[#234B24] pb-1.5 mb-1.5 border-b border-[#F6F3EC] flex items-center justify-between">
                        <span>Tipe Data Peta: {ent.spatialGeometry}</span>
                        <span>{ent.columns.length} Kolom</span>
                      </div>

                      {ent.columns.slice(0, 7).map((col) => (
                        <div
                          key={col.name}
                          className="flex items-center justify-between gap-2 text-xs py-0.5"
                        >
                          <div className="flex items-center gap-1.5 min-w-0">
                            <span
                              className={`font-mono text-[10px] font-bold w-12 shrink-0 ${
                                col.keyType === 'PK'
                                  ? 'text-[#E85D1A]'
                                  : col.keyType === 'FK'
                                  ? 'text-[#5B6AE8]'
                                  : col.keyType === 'SPATIAL'
                                  ? 'text-[#1E9E5A]'
                                  : 'text-[#5A625A]'
                              }`}
                            >
                              {col.keyType === 'NORMAL' ? 'kolom' : col.keyType}
                            </span>
                            <span className="font-mono font-semibold text-[#1B1F1A] truncate">
                              {col.name}
                            </span>
                          </div>
                          <span className="font-mono text-[11px] text-[#5A625A] shrink-0">
                            {col.dataType}
                          </span>
                        </div>
                      ))}

                      {ent.columns.length > 7 && (
                        <div className="text-[11px] text-[#234B24] font-semibold pt-1">
                          + {ent.columns.length - 7} kolom lainnya (Klik kotak ini untuk baca semua)
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Panel Kanan: Penjelasan Detail Tabel yang Sedang Diklik */}
            <div className="xl:col-span-4 bg-white border border-[#E2DFD7] rounded-xl p-5 sticky top-20 space-y-4">
              <div className="pb-3 border-b border-[#E2DFD7]">
                <div className="text-xs text-[#5A625A]">
                  Penjelasan Tabel yang Dipilih · {selectedErdEntity.tableNumberLabel} ({selectedErdEntity.sprint})
                </div>
                <h3 className="font-mono text-lg font-bold text-[#234B24] mt-0.5">
                  {selectedErdEntity.tableName}
                </h3>
                <p className="text-xs text-[#5A625A] mt-1 leading-relaxed">
                  {selectedErdEntity.description}
                </p>
              </div>

              {/* Indeks Pencarian Cepat */}
              <div className="bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg p-3">
                <div className="text-[11px] font-bold text-[#1B1F1A] mb-1.5 flex items-center gap-1.5">
                  <Compass className="w-3.5 h-3.5 text-[#234B24]" />
                  <span>Indeks Penguat Kecepatan (Supaya Pencarian &lt;100ms):</span>
                </div>
                <ul className="space-y-1 font-mono text-[11px] text-[#234B24]">
                  {selectedErdEntity.indexes.map((idx) => (
                    <li key={idx}>• {idx}</li>
                  ))}
                </ul>
              </div>

              {/* Tabel Detail Seluruh Kolom */}
              <div>
                <div className="text-xs font-bold text-[#1B1F1A] mb-2">
                  Arti Setiap Kolom di Tabel Ini ({selectedErdEntity.columns.length} Kolom):
                </div>
                <div className="max-h-72 overflow-y-auto divide-y divide-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                  {selectedErdEntity.columns.map((col) => (
                    <div key={col.name} className="p-2.5 text-xs hover:bg-[#F6F3EC]/50">
                      <div className="flex items-center justify-between gap-2">
                        <span className="font-mono font-bold text-[#1B1F1A]">
                          {col.name}{' '}
                          {col.keyType !== 'NORMAL' && (
                            <span className="text-[10px] font-mono text-[#E85D1A]">
                              [{col.keyType}]
                            </span>
                          )}
                        </span>
                        <span className="font-mono text-[11px] text-[#5B6AE8]">{col.dataType}</span>
                      </div>
                      {col.references && (
                        <div className="font-mono text-[11px] text-[#1E9E5A] mt-0.5">
                          ↳ Nyambung ke: {col.references}
                        </div>
                      )}
                      <div className="text-[11px] text-[#5A625A] mt-0.5">{col.description}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Relasi Masuk & Keluar pada Tabel Ini */}
              <div>
                <div className="text-xs font-bold text-[#1B1F1A] mb-2 flex items-center gap-1.5">
                  <Link2 className="w-3.5 h-3.5 text-[#234B24]" />
                  <span>Tabel Ini Nyambung ke Mana Saja? ({selectedEntityRelations.length} Hubungan):</span>
                </div>
                <div className="space-y-2">
                  {selectedEntityRelations.map((rel) => (
                    <div
                      key={rel.id}
                      className={`p-2.5 rounded-lg border text-xs ${
                        rel.isCrossBoundary
                          ? 'bg-[#F26B4B]/10 border-[#F26B4B]/40'
                          : 'bg-[#E4E9DA]/50 border-[#D2DAC3]'
                      }`}
                    >
                      <div className="flex items-center justify-between font-mono text-[11px] font-bold text-[#1B1F1A]">
                        <span>{rel.fromTable}</span>
                        <span className="text-[#234B24]">{rel.cardinality}</span>
                        <span>{rel.toTable}</span>
                      </div>
                      <div className="text-[11px] text-[#5A625A] mt-1">{rel.relationLabel}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Tabel Ringkasan Seluruh Hubungan Antar-Tabel */}
          <section className="bg-white border border-[#E2DFD7] rounded-xl p-6">
            <div className="pb-4 border-b border-[#E2DFD7]">
              <div className="text-xs text-[#5A625A]">
                 Keterangan: <strong>1:1</strong> artinya Satu-ke-Satu · <strong>1:N</strong> artinya Satu-ke-Banyak (misal 1 Tempat Wisata punya Banyak Tips)
              </div>
              <h3 className="text-base font-bold text-[#1B1F1A] mt-0.5">
                Daftar Lengkap Hubungan Antar-Tabel (Minggu 1 – Minggu 4 & Kerja Sama BE-2)
              </h3>
            </div>
            <div className="mt-4 overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="border-b border-[#E2DFD7] text-[11px] font-semibold text-[#5A625A]">
                    <th className="py-2.5 px-3">Tabel Utama</th>
                    <th className="py-2.5 px-3">Jenis Hubungan</th>
                    <th className="py-2.5 px-3">Tabel Pasangannya</th>
                    <th className="py-2.5 px-3">Kolom Penghubung (PK → FK)</th>
                    <th className="py-2.5 px-3">Minggu</th>
                    <th className="py-2.5 px-3">Penjelasan Singkat</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E2DFD7]">
                  {ERD_RELATIONSHIPS.map((rel) => (
                    <tr
                      key={rel.id}
                      className={rel.isCrossBoundary ? 'bg-[#F26B4B]/5' : 'hover:bg-[#F6F3EC]/60'}
                    >
                      <td className="py-2.5 px-3 font-mono font-bold text-[#1B1F1A]">
                        {rel.fromTable}
                      </td>
                      <td className="py-2.5 px-3 font-mono font-bold text-[#234B24]">
                        {rel.cardinality}
                      </td>
                      <td className="py-2.5 px-3 font-mono font-bold text-[#1B1F1A]">
                        {rel.toTable}
                      </td>
                      <td className="py-2.5 px-3 font-mono text-[11px] text-[#5B6AE8]">
                        {rel.fromColumn} → {rel.toColumn}
                      </td>
                      <td className="py-2.5 px-3 text-[11px] text-[#5A625A]">{rel.sprint}</td>
                      <td className="py-2.5 px-3 text-[#1B1F1A]">{rel.relationLabel}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      {/* ====================================================================
          DIAGRAM 2: KANVAS VISUAL CLASS DIAGRAM GO
          ==================================================================== */}
      {viewMode === 'visual' && activeDiagram === 'class' && (
        <div className="space-y-6">
          <section className="bg-white border border-[#E2DFD7] rounded-xl p-5 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div>
              <div className="text-xs text-[#5A625A]">
                Lokasi Kode: <code className="font-mono text-[#234B24]">backend/internal/be1_core</code> · Tanda{' '}
                <strong>(+)</strong> artinya bisa dipanggil dari luar, tanda <strong>(-)</strong> artinya khusus dipakai di dalam file itu sendiri
              </div>
              <div className="text-sm font-bold text-[#1B1F1A] mt-0.5">
                Saring Bagian Kode Go Berdasarkan Tugasnya
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-1.5">
              {[
                { id: 'ALL', label: 'Semua Bagian Kode (6 Komponen)' },
                { id: 'middleware', label: '1. Penjaga Login & Anti-Spam' },
                { id: 'handler', label: '2. Pelayan API & Memori Cepat (Cache)' },
                { id: 'repository', label: '3. Pengolah Database & Peta' },
                { id: 'domain', label: '4. Cetakan Data 11 Tabel (Struct)' },
              ].map((lyr) => (
                <button
                  key={lyr.id}
                  onClick={() => setClassLayerFilter(lyr.id)}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-colors cursor-pointer ${
                    classLayerFilter === lyr.id
                      ? 'bg-[#234B24] text-white'
                      : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
                  }`}
                >
                  {lyr.label}
                </button>
              ))}
            </div>
          </section>

          {/* Grid Kartu UML Class */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {filteredClasses.map((cls) => (
              <div
                key={cls.id}
                className="bg-white border-2 border-[#234B24] rounded-xl overflow-hidden flex flex-col"
              >
                {/* UML Class Header Compartment */}
                <div className="bg-[#E4E9DA] border-b-2 border-[#234B24] px-5 py-3.5 text-center">
                  <div className="font-mono text-[11px] font-semibold text-[#234B24]">
                    {cls.stereotype}
                  </div>
                  <div className="font-mono text-base font-bold text-[#1B1F1A] mt-0.5">
                    {cls.className}
                  </div>
                  <div className="text-[11px] font-mono text-[#5A625A] mt-0.5">
                    {cls.sourceFile} · {cls.sprintRange}
                  </div>
                </div>

                {/* Deskripsi Singkat Tanggung Jawab Class */}
                <div className="px-5 py-2.5 bg-[#F6F3EC] border-b border-[#E2DFD7] text-xs text-[#5A625A]">
                  {cls.description}
                </div>

                {/* UML Attributes / Fields Compartment */}
                <div className="px-5 py-3.5 border-b-2 border-[#234B24] space-y-1.5">
                  <div className="text-[11px] font-bold uppercase tracking-wider text-[#5A625A]">
                    Variabel / Isi Data di Dalamnya (Fields)
                  </div>
                  {cls.fields.map((fld) => (
                    <div
                      key={fld.name}
                      className="flex items-baseline justify-between gap-2 font-mono text-xs"
                    >
                      <div>
                        <span
                          className={`font-bold mr-1.5 ${
                            fld.visibility === '+' ? 'text-[#1E9E5A]' : 'text-[#E85D1A]'
                          }`}
                        >
                          {fld.visibility}
                        </span>
                        <span className="font-semibold text-[#1B1F1A]">{fld.name}</span>
                        <span className="text-[#5B6AE8]"> : {fld.type}</span>
                      </div>
                      {fld.tagOrNote && (
                        <span className="text-[11px] font-sans text-[#5A625A] shrink-0">
                          {fld.tagOrNote}
                        </span>
                      )}
                    </div>
                  ))}
                </div>

                {/* UML Operations / Methods Compartment */}
                <div className="px-5 py-3.5 space-y-2.5 flex-1">
                  <div className="text-[11px] font-bold uppercase tracking-wider text-[#5A625A]">
                    Fungsi / Tugas yang Bisa Dijalankan (Methods)
                  </div>
                  {cls.methods.map((mth) => (
                    <div key={mth.name} className="border-b border-[#F6F3EC] last:border-b-0 pb-2">
                      <div className="flex items-baseline justify-between gap-2 font-mono text-xs">
                        <div>
                          <span className="font-bold text-[#1E9E5A] mr-1.5">{mth.visibility}</span>
                          <span className="font-bold text-[#234B24]">{mth.name}</span>
                          <span className="text-[#5A625A]">({mth.params})</span>
                          <span className="text-[#5B6AE8]"> : {mth.returnType}</span>
                        </div>
                        <span className="font-mono text-[10px] font-bold text-[#E85D1A] shrink-0">
                          [{mth.sprintOrigin}]
                        </span>
                      </div>
                      <div className="text-[11px] text-[#5A625A] mt-0.5 pl-4">{mth.description}</div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>

          {/* Hubungan Antar-Class */}
          <section className="bg-white border border-[#E2DFD7] rounded-xl p-6">
            <h3 className="text-base font-bold text-[#1B1F1A] pb-3 border-b border-[#E2DFD7]">
              Bagaimana Bagian-Bagian Kode Go Ini Saling Bekerja Sama?
            </h3>
            <div className="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {GO_CLASS_RELATIONSHIPS.map((rel) => (
                <div key={rel.id} className="p-3.5 bg-[#F6F3EC] border border-[#E2DFD7] rounded-lg">
                  <div className="text-[11px] font-mono font-bold text-[#234B24]">
                    {rel.relationType}
                  </div>
                  <div className="font-mono text-xs font-bold text-[#1B1F1A] mt-1 flex items-center gap-1.5">
                    <span>{rel.fromClass}</span>
                    <ArrowRight className="w-3.5 h-3.5 text-[#234B24] shrink-0" />
                    <span>{rel.toClass}</span>
                  </div>
                  <div className="text-xs text-[#5A625A] mt-1">{rel.label}</div>
                </div>
              ))}
            </div>
          </section>
        </div>
      )}

      {/* ====================================================================
          DIAGRAM 3: KANVAS VISUAL SEQUENCE DIAGRAM (4 CERITA ALUR)
          ==================================================================== */}
      {viewMode === 'visual' && activeDiagram === 'sequence' && (
        <div className="space-y-6">
          {/* Pemilih 4 Skenario Sequence */}
          <section className="bg-white border border-[#E2DFD7] rounded-xl p-5">
            <div className="text-xs text-[#5A625A] mb-2">
              Pilih salah satu cerita alur di bawah ini untuk melihat urutan langkah dari awal sampai selesai:
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {SEQUENCE_SCENARIOS.map((seq) => {
                const isSelected = seq.id === selectedSequence.id;
                return (
                  <button
                    key={seq.id}
                    onClick={() => setSelectedSequenceId(seq.id)}
                    className={`p-3.5 rounded-xl border text-left transition-colors cursor-pointer ${
                      isSelected
                        ? 'bg-[#E4E9DA] border-2 border-[#234B24]'
                        : 'bg-[#F6F3EC]/70 border-[#E2DFD7] hover:bg-[#F6F3EC]'
                    }`}
                  >
                    <div className="text-[11px] font-mono font-bold text-[#234B24]">
                      {seq.sprintBadge}
                    </div>
                    <div className="text-sm font-bold text-[#1B1F1A] mt-0.5">{seq.title}</div>
                  </button>
                );
              })}
            </div>
          </section>

          {/* Kanvas Visual Lifeline & Step-by-Step Sequence */}
          <section className="bg-white border border-[#E2DFD7] rounded-xl p-6 space-y-6">
            <div className="pb-4 border-b border-[#E2DFD7]">
              <div className="text-xs font-mono font-semibold text-[#234B24]">
                {selectedSequence.sprintBadge}
              </div>
              <h3 className="text-lg font-bold text-[#1B1F1A] mt-0.5">{selectedSequence.title}</h3>
              <p className="text-xs text-[#5A625A] mt-1">{selectedSequence.summary}</p>
            </div>

            {/* Baris Partisipan / Lifeline Header */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {selectedSequence.actors.map((act) => (
                <div
                  key={act.id}
                  className="p-3 bg-[#E4E9DA] border-2 border-[#234B24] rounded-lg text-center"
                >
                  <div className="font-mono text-[11px] text-[#234B24] font-semibold">
                    {act.roleBadge}
                  </div>
                  <div className="text-xs font-bold text-[#1B1F1A] mt-0.5">{act.name}</div>
                </div>
              ))}
            </div>

            {/* Urutan Langkah Sequence */}
            <div className="space-y-3">
              {selectedSequence.steps.map((st) => (
                <div
                  key={st.stepNo}
                  className={`p-4 rounded-xl border transition-colors ${
                    st.isHighlight
                      ? 'bg-[#E4E9DA]/60 border-[#234B24]'
                      : 'bg-[#F6F3EC]/70 border-[#E2DFD7]'
                  }`}
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <div className="flex items-center gap-2 text-xs">
                      <span className="w-6 h-6 rounded-full bg-[#234B24] text-white font-mono text-xs font-bold flex items-center justify-center shrink-0">
                        {st.stepNo}
                      </span>
                      <span className="font-bold text-[#1B1F1A]">{st.fromActor}</span>
                      <ArrowRight className="w-3.5 h-3.5 text-[#234B24] shrink-0" />
                      <span className="font-bold text-[#234B24]">{st.toActor}</span>
                    </div>
                    <span className="font-mono text-[11px] font-bold text-[#E85D1A]">
                      Waktu: {st.latencyNote}
                    </span>
                  </div>

                  <div className="mt-2 pl-8 space-y-1">
                    <div className="text-xs font-bold text-[#1B1F1A]">{st.message}</div>
                    <div className="font-mono text-[11px] text-[#5B6AE8]">
                      Proses di Balik Layar: {st.protocolOrSql}
                    </div>
                    {st.returnPayload !== '-' && (
                      <div className="text-xs text-[#1E9E5A] font-medium">
                        ↳ Hasilnya: {st.returnPayload}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>
      )}

      {/* ====================================================================
          DIAGRAM 4: KANVAS VISUAL USE CASE DIAGRAM (SIAPA PAKAI FITUR APA)
          ==================================================================== */}
      {viewMode === 'visual' && activeDiagram === 'usecase' && (
        <div className="space-y-6">
          <section className="bg-white border border-[#E2DFD7] rounded-xl p-6">
            <div className="pb-4 border-b border-[#E2DFD7] flex flex-col lg:flex-row lg:items-center justify-between gap-4">
              <div>
                <div className="text-xs text-[#5A625A]">
                  Klik pada salah satu jenis pengguna di bawah ini untuk melihat fitur / alamat API mana saja yang bisa mereka pakai
                </div>
                <h3 className="text-base font-bold text-[#1B1F1A] mt-0.5">
                  Pembagian Hak Akses 4 Pengguna terhadap 24 Fitur BE-1 (Minggu 1 – Minggu 4)
                </h3>
              </div>

              <div className="flex flex-wrap items-center gap-1.5">
                {['ALL', 'Minggu 1', 'Minggu 2', 'Minggu 3', 'Minggu 4'].map((sp) => (
                  <button
                    key={sp}
                    onClick={() => setUseCaseSprintFilter(sp)}
                    className={`px-3 py-1.5 text-xs font-semibold rounded-lg cursor-pointer ${
                      useCaseSprintFilter === sp
                        ? 'bg-[#234B24] text-white'
                        : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
                    }`}
                  >
                    {sp === 'ALL' ? 'Semua Minggu (24 Fitur)' : sp}
                  </button>
                ))}
              </div>
            </div>

            {/* 4 Kartu Aktor */}
            <div className="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
              <button
                onClick={() => setSelectedActorId('ALL')}
                className={`p-3.5 rounded-xl border text-left transition-colors cursor-pointer ${
                  selectedActorId === 'ALL'
                    ? 'bg-[#234B24] text-white border-[#234B24]'
                    : 'bg-[#F6F3EC] text-[#1B1F1A] border-[#E2DFD7]'
                }`}
              >
                <div className="text-xs font-bold">Tampilkan Semua Pengguna</div>
                <div
                  className={`text-[11px] mt-1 ${
                    selectedActorId === 'ALL' ? 'text-[#E4E9DA]' : 'text-[#5A625A]'
                  }`}
                >
                  Lihat seluruh 24 fitur API dari Minggu 1 sampai Minggu 4
                </div>
              </button>

              {USE_CASE_ACTORS.map((actor) => {
                const isSelected = selectedActorId === actor.id;
                return (
                  <button
                    key={actor.id}
                    onClick={() => setSelectedActorId(actor.id)}
                    className={`p-3.5 rounded-xl border text-left transition-colors cursor-pointer ${
                      isSelected
                        ? 'bg-[#E4E9DA] border-2 border-[#234B24]'
                        : 'bg-white border-[#E2DFD7] hover:bg-[#F6F3EC]'
                    }`}
                  >
                    <div className="font-mono text-[11px] font-bold text-[#234B24]">
                      {actor.roleClaim}
                    </div>
                    <div className="text-xs font-bold text-[#1B1F1A] mt-0.5">{actor.name}</div>
                    <p className="text-[11px] text-[#5A625A] mt-1 line-clamp-2">
                      {actor.description}
                    </p>
                  </button>
                );
              })}
            </div>

            {/* Daftar Oval / Kartu Use Case 24 Endpoint */}
            <div className="mt-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
              {filteredUseCases.map((uc) => (
                <div
                  key={uc.id}
                  className="p-4 bg-[#F6F3EC]/70 border border-[#D5D0C5] rounded-2xl flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between gap-2 text-[11px] font-mono">
                      <span className="font-bold text-[#234B24]">
                        {uc.code} · {uc.sprint}
                      </span>
                      <span className="text-[#1E9E5A] font-semibold">Kecepatan {uc.slaTarget}</span>
                    </div>
                    <div className="text-sm font-bold text-[#1B1F1A] mt-1">{uc.title}</div>
                    <div className="font-mono text-xs text-[#5B6AE8] mt-1">{uc.endpoint}</div>
                  </div>

                  <div className="mt-3 pt-2.5 border-t border-[#E2DFD7] flex items-center justify-between gap-2 text-[11px] text-[#5A625A]">
                    <span className="flex items-center gap-1">
                      <Key className="w-3 h-3 text-[#234B24]" />
                      {uc.authRequirement}
                    </span>
                    <span className="font-semibold text-[#1B1F1A]">
                      Dipakai {uc.actors.length} Jenis Pengguna
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>
      )}

      {/* ====================================================================
          DIAGRAM 5: GAMBARAN BESAR CARA KERJA SISTEM (ARSITEKTUR)
          ==================================================================== */}
      {viewMode === 'visual' && activeDiagram === 'architecture' && (
        <section className="bg-white border border-[#E2DFD7] rounded-xl p-6 space-y-6">
          <div className="pb-4 border-b border-[#E2DFD7]">
            <div className="text-xs text-[#5A625A]">
              Gambaran Besar Aliran Data · Dari Layar HP Pengguna sampai ke Database Peta PostGIS
            </div>
            <h3 className="text-lg font-bold text-[#1B1F1A] mt-0.5">
              4 Lapisan Sistem Rancak.in: Layar Aplikasi, Pintu Keamanan & Cache, Mesin Backend (BE-1 vs BE-2), dan Database
            </h3>
          </div>

          <div className="space-y-4">
            {/* LAPISAN 1: LAYAR APLIKASI */}
            <div className="p-5 bg-[#F6F3EC] border border-[#D5D0C5] rounded-xl">
              <div className="text-xs font-mono font-bold text-[#234B24] mb-3">
                LAPISAN 1 — LAYAR APLIKASI YANG DILIHAT PENGGUNA (DIKERJAKAN TIM FRONTEND & FULLSTACK)
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-white p-4 rounded-lg border border-[#E2DFD7]">
                  <div className="font-mono text-xs font-bold text-[#234B24]">
                    Layar FE-1 (Pencarian Wisata, Peta & 360°)
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1">
                    Dipakai wisatawan untuk mencari tempat wisata, melihat kondisi jalan/sinyal HP, memutar foto 360°, mencari tempat mampir searah, cek bahaya jalur ekstrem, dan menekan tombol SOS.
                  </p>
                </div>
                <div className="bg-white p-4 rounded-lg border border-[#E2DFD7]">
                  <div className="font-mono text-xs font-bold text-[#1E9E5A]">
                    Layar FE-2 (Cek Harga Resmi, Lapor Pungli & Budaya)
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1">
                    Dipakai wisatawan untuk mengecek harga tiket/parkir resmi Perda, scan kode QR di lokasi, mengirim laporan pungli secara anonim, dan belajar bahasa Minang bersuara.
                  </p>
                </div>
                <div className="bg-white p-4 rounded-lg border border-[#E2DFD7]">
                  <div className="font-mono text-xs font-bold text-[#5B6AE8]">
                    Layar FS-1 (Dashboard Admin Dispar, Satgas & BPBD)
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1">
                    Dipakai petugas resmi untuk menambah wisata baru, mengubah harga Perda, mengunggah foto 360°, menindak laporan pungli, dan menyalakan alarm bencana jalan.
                  </p>
                </div>
              </div>
            </div>

            {/* LAPISAN 2: PINTU KEAMANAN & MEMORI CEPAT */}
            <div className="p-5 bg-[#E4E9DA] border-2 border-[#234B24] rounded-xl">
              <div className="text-xs font-mono font-bold text-[#234B24] mb-3 flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4" />
                <span>LAPISAN 2 — PINTU PENJAGA KEAMANAN & PENGHEMAT KUOTA (BUATAN ANDA DI BE-1)</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-white p-3.5 rounded-lg border border-[#D2DAC3]">
                  <div className="font-mono text-xs font-bold text-[#1B1F1A]">
                    1. Pengecek Tiket Login (Stateless JWT)
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1">
                    Mengecek apakah pengguna sudah login dan apa jabatannya (<code className="font-mono">admin_dispar</code>, <code className="font-mono">satgas_pungli</code>, atau <code className="font-mono">petugas_bpbd</code>) tanpa perlu mengganggu database milik BE-2.
                  </p>
                </div>
                <div className="bg-white p-3.5 rounded-lg border border-[#D2DAC3]">
                  <div className="font-mono text-xs font-bold text-[#1B1F1A]">
                    2. Penangkal Spam (Token Bucket Rate-Limiter)
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1">
                    Menolak otomatis (<code className="font-mono">HTTP 429</code>) jika ada orang iseng yang mengirim laporan pungli palsu atau menekan tombol SOS berkali-kali dalam waktu singkat.
                  </p>
                </div>
                <div className="bg-white p-3.5 rounded-lg border border-[#D2DAC3]">
                  <div className="font-mono text-xs font-bold text-[#1B1F1A]">
                    3. Memori Cepat (In-Memory Cache + ETag)
                  </div>
                  <p className="text-xs text-[#5A625A] mt-1">
                    Menyimpan data foto 360° dan rute di memori RAM. Kalau datanya belum berubah, HP pengguna tidak perlu download ulang (<code className="font-mono">HTTP 304</code> dalam &lt; 1.5 ms).
                  </p>
                </div>
              </div>
            </div>

            {/* LAPISAN 3: PEMBAGIAN MESIN BACKEND */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
              <div className="lg:col-span-8 p-5 bg-white border-2 border-[#234B24] rounded-xl">
                <div className="text-xs font-mono font-bold text-[#234B24] mb-2">
                  LAPISAN 3A — MESIN BACKEND MILIK ANDA: BE-1 (24 ALAMAT API AKTIF)
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  <div className="p-3 bg-[#F6F3EC] rounded-lg">
                    <div className="font-bold text-[#1B1F1A]">Minggu 1 (Data Dasar & Peta)</div>
                    <div className="text-[#5A625A] mt-0.5">
                      Pencarian wisata terdekat, info kondisi jalan/sinyal HP, tips sopan santun adat, harga resmi Perda, dan kelola data Admin.
                    </div>
                  </div>
                  <div className="p-3 bg-[#F6F3EC] rounded-lg">
                    <div className="font-bold text-[#1B1F1A]">Minggu 2 (Foto 360°, Mampir & Pungli)</div>
                    <div className="text-[#5A625A] mt-0.5">
                      Tur keliling 360° dengan 4 jenis pin, tempat mampir searah (+X menit), peta jalan kaki dalam lokasi, dan aduan pungli.
                    </div>
                  </div>
                  <div className="p-3 bg-[#F6F3EC] rounded-lg">
                    <div className="font-bold text-[#1B1F1A]">Minggu 3 (Ranking GPS, Bahaya & Budaya)</div>
                    <div className="text-[#5A625A] mt-0.5">
                      Urutan wisata terfavorit dari kunjungan GPS, peringatan jalur ekstrem Sitinjau Lauik, tombol SOS, dan kamus suara Minang.
                    </div>
                  </div>
                  <div className="p-3 bg-[#F6F3EC] rounded-lg">
                    <div className="font-bold text-[#1B1F1A]">Minggu 4 (Peta Offline & Tes Kecepatan)</div>
                    <div className="text-[#5A625A] mt-0.5">
                      Paket peta offline untuk daerah susah sinyal, alat tes kecepatan server (&lt;100ms), dan daftar lengkap 24 alamat API.
                    </div>
                  </div>
                </div>
              </div>

              <div className="lg:col-span-4 p-5 bg-[#F6F3EC] border border-dashed border-[#F26B4B] rounded-xl">
                <div className="text-xs font-mono font-bold text-[#F26B4B] mb-2">
                  LAPISAN 3B — MESIN TEMAN SETIM: BE-2 (SOSIAL & PEMBAYARAN)
                </div>
                <p className="text-xs text-[#5A625A] leading-relaxed">
                  Dikerjakan terpisah di folder <code className="font-mono">backend/internal/be2_social/</code> supaya tidak pernah bentrok saat gabung kode (merge):
                </p>
                <ul className="mt-2 space-y-1.5 text-xs text-[#1B1F1A] font-mono">
                  <li>• Login Akun & Pembuatan Tiket JWT</li>
                  <li>• Ruang Diskusi & Voting Grup Liburan</li>
                  <li>• Pesan Pemandu Lokal & Pembayaran</li>
                  <li>• Koleksi Stempel Paspor Digital Nagari</li>
                </ul>
              </div>
            </div>

            {/* LAPISAN 4: DATABASE */}
            <div className="p-5 bg-[#1B1F1A] text-[#F6F3EC] rounded-xl">
              <div className="text-xs font-mono font-bold text-[#1E9E5A] mb-2">
                LAPISAN 4 — PENYIMPANAN DATABASE PETA (POSTGRESQL + POSTGIS)
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
                <div className="p-3 bg-white/5 rounded-lg border border-white/10">
                  <div className="font-mono font-bold text-[#E4E9DA]">
                    11 Tabel Milik BE-1
                  </div>
                  <p className="text-[#A8B0A8] mt-1">
                    Menyimpan seluruh data 20 tempat wisata Sumatera Barat, titik koordinat peta, foto 360°, tempat mampir, dan laporan pungli.
                  </p>
                </div>
                <div className="p-3 bg-white/5 rounded-lg border border-white/10">
                  <div className="font-mono font-bold text-[#E4E9DA]">
                    Indeks Pencarian Peta Super Cepat
                  </div>
                  <p className="text-[#A8B0A8] mt-1">
                    Membuat perhitungan jarak GPS dan pencarian nama wisata selesai dalam hitungan belasan milidetik (jauh di bawah batas 100ms).
                  </p>
                </div>
                <div className="p-3 bg-white/5 rounded-lg border border-white/10">
                  <div className="font-mono font-bold text-[#E4E9DA]">
                    Pembagian Adil: 11 Tabel BE-1 & 11 Tabel BE-2
                  </div>
                  <p className="text-[#A8B0A8] mt-1">
                    Setiap anggota backend punya tabel masing-masing yang jelas sehingga pekerjaan rapi dan tidak saling menimpa.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>
      )}

      <PdfReportPreviewModal
        isOpen={isPdfPreviewOpen}
        onClose={() => setIsPdfPreviewOpen(false)}
      />
    </div>
  );
};
