import React from 'react';
import {
  Compass,
  QrCode,
  Camera,
  MessageSquare,
  Trophy,
  Radio,
  ArrowRight,
  ShieldCheck,
  MapPin,
  ExternalLink,
  ChevronRight,
  CheckCircle2,
  PhoneCall,
  Store,
  Layers,
} from 'lucide-react';
import { Destination } from '../types/contract';

interface PublicLandingPageProps {
  destinations: Destination[];
  onNavigateToLogin: () => void;
  onNavigateToQR: (destination?: Destination) => void;
  onNavigateToJoin: () => void;
}

export const PublicLandingPage: React.FC<PublicLandingPageProps> = ({
  destinations,
  onNavigateToLogin,
  onNavigateToQR,
  onNavigateToJoin,
}) => {
  const sampleDest = destinations[0] || {
    id: 'dest-001',
    name: 'Lembah Harau & Batang Tabik',
    city_regency: 'Kabupaten Lima Puluh Kota',
    category: 'Air Terjun & Lembah',
    slug: 'lembah-harau',
    ticket_price_summary: 'Rp 15.000 / orang',
  };

  const scrollToSection = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="min-h-screen bg-[#F9F7F2] text-[#143D2B] font-sans antialiased selection:bg-[#143D2B]/15 selection:text-[#143D2B] overflow-x-hidden">
      {/* ==================================================================== */}
      {/* 1. NAVBAR MINIMALIS (1 Baris, Sticky)                                */}
      {/* ==================================================================== */}
      <nav
        aria-label="Navigasi Utama Publik WISGO"
        className="sticky top-0 z-40 bg-[#F9F7F2]/90 backdrop-blur-md border-b border-[#143D2B]/10 transition-colors"
      >
        <div className="max-w-6xl mx-auto px-6 h-18 flex items-center justify-between gap-4">
          {/* Kiri: Logo + WISGO Sumbar */}
          <div className="flex items-center gap-3 shrink-0">
            <div className="w-9 h-9 rounded-xl bg-[#143D2B] flex items-center justify-center p-1.5 shadow-xs">
              <img
                src="/assets/synced/logo_icon.png"
                alt="Logo WISGO"
                className="w-full h-full object-contain brightness-0 invert"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = '/logo_icon.png';
                }}
              />
            </div>
            <div className="flex flex-col">
              <span className="font-extrabold text-base tracking-tight text-[#143D2B] leading-none">
                WISGO Sumbar
              </span>
              <span className="text-[10px] font-semibold text-[#143D2B]/70 tracking-wider uppercase mt-0.5">
                Portal Pariwisata Resmi
              </span>
            </div>
          </div>

          {/* Tengah: 4 Link Saja */}
          <div className="hidden md:flex items-center gap-8 text-xs font-bold text-[#143D2B]/80">
            <button
              type="button"
              onClick={() => scrollToSection('fitur')}
              className="hover:text-[#143D2B] transition-colors"
            >
              Fitur
            </button>
            <button
              type="button"
              onClick={() => scrollToSection('smart-qr')}
              className="hover:text-[#143D2B] transition-colors"
            >
              Smart QR
            </button>
            <button
              type="button"
              onClick={() => scrollToSection('umkm-trip')}
              className="hover:text-[#143D2B] transition-colors"
            >
              UMKM
            </button>
            <button
              type="button"
              onClick={() => scrollToSection('sos-jalur')}
              className="hover:text-[#143D2B] transition-colors"
            >
              Siaga SOS
            </button>
          </div>

          {/* Kanan: Portal Admin + Coba Smart QR */}
          <div className="flex items-center gap-3 shrink-0">
            <button
              type="button"
              onClick={onNavigateToLogin}
              className="px-3.5 py-2 text-xs font-bold text-[#143D2B] hover:text-[#143D2B]/70 transition-colors"
            >
              Portal Admin
            </button>
            <button
              type="button"
              onClick={() => onNavigateToQR(sampleDest as any)}
              className="px-4 py-2 rounded-xl bg-[#143D2B] text-white hover:bg-[#0E2E20] text-xs font-bold shadow-xs transition-all flex items-center gap-1.5"
            >
              <QrCode className="w-3.5 h-3.5" />
              <span>Coba Smart QR</span>
            </button>
          </div>
        </div>
      </nav>

      {/* ==================================================================== */}
      {/* 2. HERO SECTION (Clean & Lega)                                       */}
      {/* ==================================================================== */}
      <section className="py-20 lg:py-28 relative">
        <div className="max-w-6xl mx-auto px-6">
          <div className="max-w-3xl mx-auto text-center space-y-6">
            {/* 1 Badge Kecil */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B]">
              <span className="w-2 h-2 rounded-full bg-[#143D2B] animate-pulse" />
              <span>Dinas Pariwisata Provinsi Sumatera Barat</span>
            </div>

            {/* Headline: Maksimal 6-8 kata */}
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-[#143D2B] leading-[1.12]">
              Wisata Ranah Minang. Aman, Transparan, Tanpa Pungli.
            </h1>

            {/* Subheadline: 1 baris pendek */}
            <p className="text-sm sm:text-base text-[#143D2B]/80 max-w-2xl mx-auto leading-relaxed">
              Panduan medan nyata, tarif resmi Perda, tur 360°, dan siaga SOS untuk 19 Kab/Kota Sumatera Barat.
            </p>

            {/* 2 Tombol CTA */}
            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
              <button
                type="button"
                onClick={() => scrollToSection('fitur')}
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-[#143D2B] hover:bg-[#0E2E20] text-white text-xs font-extrabold shadow-sm transition-all flex items-center justify-center gap-2"
              >
                <span>Jelajah Destinasi</span>
                <ArrowRight className="w-4 h-4" />
              </button>
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-white hover:bg-[#F9F7F2] text-[#143D2B] border border-[#143D2B]/20 text-xs font-extrabold shadow-xs transition-all flex items-center justify-center gap-2"
              >
                <span>Portal Command Center</span>
                <ExternalLink className="w-3.5 h-3.5 opacity-60" />
              </button>
            </div>
          </div>

          {/* 1 Preview Mockup Bersih (Bukan bertumpuk) */}
          <div className="mt-14 max-w-4xl mx-auto">
            <div className="bg-white rounded-3xl p-6 lg:p-8 border border-stone-200/80 shadow-[0_8px_32px_rgba(20,61,43,0.06)]">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-stone-200/60">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-2xl bg-[#143D2B]/10 text-[#143D2B] flex items-center justify-center font-extrabold text-sm">
                    01
                  </div>
                  <div>
                    <h2 className="text-base font-extrabold text-[#143D2B]">
                      {sampleDest.name}
                    </h2>
                    <p className="text-xs text-stone-500 flex items-center gap-1 mt-0.5">
                      <MapPin className="w-3 h-3 text-[#F26B4B]" />
                      <span>{sampleDest.city_regency}</span>
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-2 self-start sm:self-center">
                  <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B] text-white">
                    Perda Terverifikasi
                  </span>
                  <span className="px-3 py-1 rounded-full text-xs font-extrabold bg-[#F26B4B]/15 text-[#D95637]">
                    {sampleDest.ticket_price_summary || 'Rp 15.000'}
                  </span>
                </div>
              </div>

              {/* 4 Indikator Snapshot Ramping */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-6 text-left">
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">Akses Jalan</span>
                  <span className="text-xs font-extrabold text-[#143D2B] mt-0.5 block">Mobil &amp; Bus OK</span>
                </div>
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">Trekking</span>
                  <span className="text-xs font-extrabold text-[#143D2B] mt-0.5 block">Landai &amp; Santai</span>
                </div>
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">Sinyal 4G</span>
                  <span className="text-xs font-extrabold text-[#143D2B] mt-0.5 block">Stabil Kuat</span>
                </div>
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">Plang QR</span>
                  <span className="text-xs font-extrabold text-[#1E9E5A] mt-0.5 block">Aktif di Loket</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ==================================================================== */}
      {/* 3. BENTO FITUR INTI (Grid 3 Kolom x 2 Baris — Super Ringkas)          */}
      {/* ==================================================================== */}
      <section id="fitur" className="py-20 bg-white/60 border-y border-stone-200/60">
        <div className="max-w-6xl mx-auto px-6">
          <div className="max-w-2xl mx-auto text-center space-y-3 mb-14">
            {/* 1 Badge Kecil */}
            <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B] inline-block">
              Pilar Layanan
            </span>
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#143D2B]">
              Enam Fitur Perlindungan Wisatawan
            </h2>
            <p className="text-xs sm:text-sm text-stone-600">
              Standar transparansi dan keselamatan terpadu ranah Minang.
            </p>
          </div>

          {/* Grid 3x2: Kartu Putih Bersih */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {/* Kartu 1 */}
            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-xs hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Compass className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">5 Indikator Medan</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Cek akses jalan, trekking, sinyal blank spot, dan fasilitas sebelum berangkat.
                </p>
              </div>
            </div>

            {/* Kartu 2 */}
            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-xs hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <QrCode className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">Smart QR Tarif Perda</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Scan plang di lokasi untuk melihat harga resmi tanpa instal aplikasi.
                </p>
              </div>
            </div>

            {/* Kartu 3 */}
            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-xs hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Camera className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">Panorama 360°</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Tinjau kondisi nyata destinasi dan pin fasilitas secara virtual.
                </p>
              </div>
            </div>

            {/* Kartu 4 */}
            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-xs hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <MessageSquare className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">Direct P2P UMKM</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Pesan langsung ke WhatsApp warga + QRIS Bank Nagari, 0% potongan.
                </p>
              </div>
            </div>

            {/* Kartu 5 */}
            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-xs hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Trophy className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">Open Trip &amp; Level</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Ikut trip penyelenggara terverifikasi, kumpulkan XP, dan naik 5 level.
                </p>
              </div>
            </div>

            {/* Kartu 6 */}
            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-xs hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Radio className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">Siaga SOS &amp; Jalur Rawan</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Akses darurat online/offline serta pantauan cuaca dan 5 jalur ekstrem.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ==================================================================== */}
      {/* 4. HIGHLIGHT SPLIT SECTION (2 Blok Bergantian yang Lega)              */}
      {/* ==================================================================== */}
      <section id="smart-qr" className="py-20">
        <div className="max-w-6xl mx-auto px-6 space-y-24">
          {/* Blok A — Smart QR Anti-Pungli */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
            {/* Kiri: 1 Judul + 3 Poin Singkat */}
            <div className="lg:col-span-6 space-y-6">
              {/* 1 Badge Kecil */}
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B] inline-block">
                Saber Pungli Terpadu
              </span>

              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#143D2B] leading-snug">
                Tarif Resmi Tanpa Getok Harga
              </h2>

              <p className="text-xs sm:text-sm text-stone-600 leading-relaxed">
                Plang fisik bersertifikat di gerbang retribusi nagari untuk kepastian biaya.
              </p>

              {/* 3 Poin Singkat */}
              <div className="space-y-3 pt-2">
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#143D2B] font-semibold">
                    <strong className="text-[#143D2B]">Perda Resmi:</strong> Harga tiket, parkir, dan sewa wahana terstandar.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#143D2B] font-semibold">
                    <strong className="text-[#143D2B]">Tanpa Aplikasi:</strong> Cukup scan kamera HP langsung buka rincian.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#143D2B] font-semibold">
                    <strong className="text-[#143D2B]">Hotline Siaga:</strong> Laporkan pungli langsung ke satgas kepolisian.
                  </p>
                </div>
              </div>

              <div className="pt-2">
                <button
                  type="button"
                  onClick={() => onNavigateToQR(sampleDest as any)}
                  className="px-5 py-2.5 rounded-xl bg-[#143D2B] hover:bg-[#0E2E20] text-white text-xs font-bold shadow-xs transition-all flex items-center gap-2"
                >
                  <span>Lihat Contoh Plang QR</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

            {/* Kanan: 1 Mockup Kartu Plang Smart QR yang Bersih & Elegan */}
            <div className="lg:col-span-6">
              <div className="bg-white rounded-3xl p-6 sm:p-7 border border-stone-200/80 shadow-[0_8px_32px_rgba(20,61,43,0.06)] space-y-4">
                <div className="flex items-center justify-between pb-3 border-b border-stone-200/60">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-xl bg-[#143D2B] text-white flex items-center justify-center p-1">
                      <QrCode className="w-4 h-4" />
                    </div>
                    <div>
                      <span className="text-[10px] font-bold text-stone-500 uppercase block leading-none">
                        Plang Fisik Lapangan
                      </span>
                      <strong className="text-xs font-extrabold text-[#143D2B]">
                        Smart QR Barometer Perda
                      </strong>
                    </div>
                  </div>
                  <span className="text-[10px] font-extrabold px-2.5 py-0.5 rounded-md bg-[#1E9E5A]/10 text-[#166534]">
                    Terverifikasi Pemprov
                  </span>
                </div>

                {/* Mini Tabel Tarif */}
                <div className="space-y-2 text-xs">
                  <div className="flex justify-between items-center p-2 rounded-lg bg-[#F9F7F2]">
                    <span className="text-stone-600 font-medium">Tiket Masuk Dewasa</span>
                    <strong className="text-[#143D2B] font-bold">Rp 15.000 / org</strong>
                  </div>
                  <div className="flex justify-between items-center p-2 rounded-lg bg-[#F9F7F2]">
                    <span className="text-stone-600 font-medium">Parkir Roda 4 (Mobil)</span>
                    <strong className="text-[#143D2B] font-bold">Rp 5.000 / unit</strong>
                  </div>
                  <div className="flex justify-between items-center p-2 rounded-lg bg-[#F9F7F2]">
                    <span className="text-stone-600 font-medium">Sanitasi &amp; Toilet Bersih</span>
                    <strong className="text-[#143D2B] font-bold">Rp 2.000 / pakai</strong>
                  </div>
                </div>

                <div className="pt-2 flex items-center justify-between text-[11px] text-stone-500 border-t border-stone-200/60">
                  <span>Hotline Saber Pungli: <strong>112 / 115</strong></span>
                  <span className="text-[#D95637] font-bold">Anti-Getok Harga</span>
                </div>
              </div>
            </div>
          </div>

          {/* Blok B — UMKM 0% Potongan vs Open Trip Aman */}
          <div id="umkm-trip" className="space-y-8 pt-6">
            <div className="max-w-xl text-left space-y-2">
              {/* 1 Badge Kecil */}
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B] inline-block">
                Model Transaksi
              </span>
              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#143D2B]">
                Ekosistem Transparan Dua Jalur
              </h2>
              <p className="text-xs sm:text-sm text-stone-600">
                Pemberdayaan warga nagari dipisahkan tegas dari transaksi perjalanan kelompok.
              </p>
            </div>

            {/* 2 Kartu Perbandingan Super Simpel (3 Bullet Pendek Masing-Masing) */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Kartu 1: Mitra UMKM */}
              <div className="bg-white rounded-2xl p-6 sm:p-7 border border-stone-200/80 shadow-xs space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                    <Store className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-[#143D2B]">Kemitraan UMKM Nagari</h3>
                    <span className="text-xs text-stone-500 font-semibold block">Direct P2P WhatsApp</span>
                  </div>
                </div>

                <div className="space-y-2.5 pt-2 text-xs">
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#1E9E5A] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>0% Potongan Platform:</strong> Seluruh hasil penjualan utuh milik warga lokal.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#1E9E5A] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>QRIS Bank Nagari:</strong> Pembayaran langsung ke rekening mitra tanpa escrow.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#1E9E5A] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>Chat Langsung:</strong> Hubungi WhatsApp warga dari penelusuran Pin 360°.
                    </p>
                  </div>
                </div>
              </div>

              {/* Kartu 2: Open Trip */}
              <div className="bg-white rounded-2xl p-6 sm:p-7 border border-stone-200/80 shadow-xs space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#F26B4B]/10 text-[#F26B4B] flex items-center justify-center shrink-0">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-[#143D2B]">Paket Open Trip Resmi</h3>
                    <span className="text-xs text-stone-500 font-semibold block">Transaksi Sistem Terverifikasi</span>
                  </div>
                </div>

                <div className="space-y-2.5 pt-2 text-xs">
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#143D2B] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>1 Destinasi Terarah:</strong> Fokus satu titik dengan kategori otomatis.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#143D2B] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>Verifikasi Penyelenggara:</strong> Wajib lolos pemeriksaan SK dan sertifikasi HPI.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#143D2B] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>Meeting Point G-Maps:</strong> Lokasi kumpul terintegrasi peta navigasi digital.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ==================================================================== */}
      {/* 5. CTA BANNER GELAP (#143D2B) & FOOTER RINGKAS                       */}
      {/* ==================================================================== */}
      <section id="sos-jalur" className="py-16">
        <div className="max-w-6xl mx-auto px-6">
          {/* Banner Gelap (#143D2B) */}
          <div className="bg-[#143D2B] text-white rounded-3xl p-10 lg:p-14 text-center space-y-6 shadow-xl">
            {/* 1 Badge Kecil */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full text-xs font-semibold bg-white/10 text-white/90">
              <span className="w-2 h-2 rounded-full bg-[#1E9E5A]" />
              <span>Pusat Komando Terpadu</span>
            </div>

            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold tracking-tight text-white max-w-2xl mx-auto leading-tight">
              Terintegrasi untuk Dinas Pariwisata, Saber Pungli &amp; Tim SAR.
            </h2>

            <p className="text-xs sm:text-sm text-white/80 max-w-xl mx-auto leading-relaxed">
              Sistem operasional terpadu 19 Kabupaten dan Kota di Sumatera Barat.
            </p>

            <div className="pt-2">
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="px-6 py-3.5 rounded-xl bg-white hover:bg-[#F9F7F2] text-[#143D2B] text-xs font-extrabold shadow-sm transition-all inline-flex items-center gap-2"
              >
                <span>Masuk Dashboard Admin</span>
                <ArrowRight className="w-4 h-4 text-[#143D2B]" />
              </button>
            </div>
          </div>

          {/* Footer 1 Baris / Ringkas */}
          <footer className="mt-14 pt-8 border-t border-stone-200/80 flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-stone-500">
            {/* Logo + WISGO */}
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 rounded-lg bg-[#143D2B] p-1 flex items-center justify-center">
                <img
                  src="/assets/synced/logo_icon.png"
                  alt="WISGO"
                  className="w-full h-full object-contain brightness-0 invert"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = '/logo_icon.png';
                  }}
                />
              </div>
              <span className="font-extrabold text-[#143D2B]">WISGO Sumbar</span>
            </div>

            {/* 4 Tautan Utama */}
            <div className="flex flex-wrap items-center justify-center gap-6 font-semibold">
              <button
                type="button"
                onClick={() => onNavigateToQR(sampleDest as any)}
                className="hover:text-[#143D2B] transition-colors"
              >
                Plang Smart QR
              </button>
              <button
                type="button"
                onClick={onNavigateToJoin}
                className="hover:text-[#143D2B] transition-colors"
              >
                Grup Petualang
              </button>
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="hover:text-[#143D2B] transition-colors"
              >
                Portal Admin
              </button>
              <a
                href="tel:112"
                className="text-[#D95637] font-bold hover:underline"
              >
                Kontak Darurat 112
              </a>
            </div>

            {/* Copyright */}
            <p className="text-[11px] text-stone-400">
              &copy; 2026 Pemerintah Provinsi Sumatera Barat.
            </p>
          </footer>
        </div>
      </section>
    </div>
  );
};
