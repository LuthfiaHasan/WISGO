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
  CheckCircle2,
  Store,
} from 'lucide-react';
import { Destination } from '../types/contract';

interface PublicLandingPageProps {
  destinations: Destination[];
  onNavigateToLogin: () => void;
  onNavigateToQR: (destination?: Destination) => void;
}

export const PublicLandingPage: React.FC<PublicLandingPageProps> = ({
  destinations,
  onNavigateToLogin,
  onNavigateToQR,
}) => {
  const sampleDest = destinations[0];

  const scrollToSection = (id: string) => {
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="min-h-screen bg-[#F9F7F2] text-[#143D2B] font-sans antialiased selection:bg-[#143D2B]/15 selection:text-[#143D2B] overflow-x-hidden">
      {/* 1. NAVBAR */}
      <nav
        aria-label="Navigasi Utama Publik WISGO"
        className="sticky top-0 z-40 bg-[#F9F7F2]/90 backdrop-blur-md border-b border-[#143D2B]/10 transition-colors"
      >
        <div className="max-w-6xl mx-auto px-6 h-18 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3 shrink-0">
            <div className="w-9 h-9 rounded-xl bg-[#143D2B] flex items-center justify-center p-1.5 shadow-sm">
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
              UMKM &amp; Trip Go
            </button>
            <button
              type="button"
              onClick={() => scrollToSection('sos-jalur')}
              className="hover:text-[#143D2B] transition-colors"
            >
              Siaga SOS
            </button>
          </div>

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
              onClick={() => onNavigateToQR(sampleDest)}
              className="px-4 py-2 rounded-xl bg-[#143D2B] text-white hover:bg-[#0E2E20] text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
            >
              <QrCode className="w-3.5 h-3.5" />
              <span>Coba Smart QR</span>
            </button>
          </div>
        </div>
      </nav>

      {/* 2. HERO SECTION */}
      <section className="py-20 lg:py-28 relative">
        <div className="max-w-6xl mx-auto px-6">
          <div className="max-w-3xl mx-auto text-center space-y-6">
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B]">
              <span className="w-2 h-2 rounded-full bg-[#143D2B] animate-pulse" />
              <span>Dinas Pariwisata Provinsi Sumatera Barat</span>
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-[#143D2B] leading-[1.12]">
              Wisata Ranah Minang. Aman, Transparan, Tanpa Pungli.
            </h1>

            <p className="text-sm sm:text-base text-[#143D2B]/80 max-w-2xl mx-auto leading-relaxed">
              4 indikator medan nyata, cuaca live Open-Meteo, tarif resmi Perda, Panorama 360° &amp; Denah 2D, Trip Go, serta Siaga SOS 19 Kab/Kota Sumatera Barat.
            </p>

            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
              <button
                type="button"
                onClick={() => scrollToSection('fitur')}
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-[#143D2B] hover:bg-[#0E2E20] text-white text-xs font-extrabold shadow-sm transition-all flex items-center justify-center gap-2"
              >
                <span>Jelajah Fitur WISGO</span>
                <ArrowRight className="w-4 h-4" />
              </button>
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl bg-white hover:bg-[#F9F7F2] text-[#143D2B] border border-[#143D2B]/20 text-xs font-extrabold shadow-sm transition-all flex items-center justify-center gap-2"
              >
                <span>Portal Command Center</span>
                <ExternalLink className="w-3.5 h-3.5 opacity-60" />
              </button>
            </div>
          </div>

          {/* Snapshot Kartu Destinasi Live */}
          <div className="mt-14 max-w-4xl mx-auto">
            <div className="bg-white rounded-3xl p-6 lg:p-8 border border-stone-200/80 shadow-[0_8px_32px_rgba(20,61,43,0.06)]">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-stone-200/60">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-2xl bg-[#143D2B]/10 text-[#143D2B] flex items-center justify-center font-extrabold text-sm">
                    01
                  </div>
                  <div>
                    <h2 className="text-base font-extrabold text-[#143D2B]">
                      {sampleDest?.name || 'Lembah Harau & Sarasah Bunta'}
                    </h2>
                    <p className="text-xs text-stone-500 flex items-center gap-1 mt-0.5">
                      <MapPin className="w-3 h-3 text-[#F26B4B]" />
                      <span>
                        {sampleDest?.city_regency || 'Kab. Lima Puluh Kota'} ·{' '}
                        {sampleDest?.category || 'Alam & Geopark'}
                      </span>
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-2 self-start sm:self-center">
                  <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B] text-white">
                    Perda Terverifikasi
                  </span>
                  <span className="px-3 py-1 rounded-full text-xs font-extrabold bg-[#F26B4B]/15 text-[#D95637]">
                    {sampleDest?.ticket_price_summary || 'Rp 15.000 / orang'}
                  </span>
                </div>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-6 text-left">
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">
                    Akses Kendaraan
                  </span>
                  <span className="text-xs font-extrabold text-[#143D2B] mt-0.5 block">
                    {sampleDest?.medan_indicator?.vehicle_access || 'Mobil OK'}
                  </span>
                </div>
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">
                    Tingkat Trekking
                  </span>
                  <span className="text-xs font-extrabold text-[#143D2B] mt-0.5 block">
                    {sampleDest?.medan_indicator?.trekking_level || 'Mudah (Datar)'}
                  </span>
                </div>
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">
                    Cuaca Live
                  </span>
                  <span className="text-xs font-extrabold text-[#143D2B] mt-0.5 block">
                    {sampleDest?.weather?.temperature_c ?? 26}°C ·{' '}
                    {sampleDest?.weather?.condition || 'Cerah Berawan'}
                  </span>
                </div>
                <div className="p-3.5 rounded-xl bg-[#F9F7F2] border border-stone-200/60">
                  <span className="text-[10px] font-bold text-stone-500 uppercase block">
                    Plang Smart QR
                  </span>
                  <span className="text-xs font-extrabold text-[#1E9E5A] mt-0.5 block">
                    {sampleDest?.qr_placard_code || 'Aktif di Loket'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 3. BENTO 6 FITUR INTI */}
      <section id="fitur" className="py-20 bg-white/60 border-y border-stone-200/60">
        <div className="max-w-6xl mx-auto px-6">
          <div className="max-w-2xl mx-auto text-center space-y-3 mb-14">
            <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B] inline-block">
              Pilar Layanan
            </span>
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#143D2B]">
              Enam Fitur Perlindungan Wisatawan
            </h2>
            <p className="text-xs sm:text-sm text-stone-600">
              Sinkron penuh antara aplikasi mobile wisatawan dan Pusat Komando Dinas Pariwisata Sumbar.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-sm hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Compass className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">
                  4 Indikator Medan &amp; Cuaca Live
                </h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Cek akses kendaraan, tingkat trekking, fasilitas resmi, kebutuhan pemandu, serta pantauan cuaca Open-Meteo real-time.
                </p>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-sm hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <QrCode className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">Smart QR Tarif Perda</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Scan plang di lokasi untuk memeriksa tarif resmi Perda dan melaporkan indikasi pungli langsung ke Satgas.
                </p>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-sm hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Camera className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">
                  Panorama 360° &amp; Denah Kawasan 2D
                </h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Tinjau lanskap nyata lewat Panorama 360° bersih dan temukan Parkir, UMKM, Toilet, Musholla, serta Loket pada Denah 2D.
                </p>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-sm hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <MessageSquare className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">Direct P2P UMKM</h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Pesan langsung ke WhatsApp pengelola nagari + QRIS Bank Nagari dengan 0% potongan komisi platform.
                </p>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-sm hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Trophy className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">
                  Trip Go &amp; Jejak WISGO
                </h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Ikut Trip Go penyelenggara terverifikasi, kumpulkan stempel Paspor Minang, dan naik 5 level petualang.
                </p>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-stone-200/70 shadow-sm hover:border-[#143D2B]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                <Radio className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#143D2B]">
                  Siaga SOS &amp; 4 Jalur Ekstrem
                </h3>
                <p className="text-xs text-stone-600 leading-relaxed">
                  Hotline bebas pulsa 112/115, 6 instansi darurat resmi Sumbar, sirene &amp; senter SOS fisik, serta pantauan 4 jalur ekstrem.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 4. HIGHLIGHT SPLIT SECTION */}
      <section id="smart-qr" className="py-20">
        <div className="max-w-6xl mx-auto px-6 space-y-24">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
            <div className="lg:col-span-6 space-y-6">
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B] inline-block">
                Saber Pungli Terpadu
              </span>
              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#143D2B] leading-snug">
                Tarif Resmi Tanpa Getok Harga
              </h2>
              <p className="text-xs sm:text-sm text-stone-600 leading-relaxed">
                Plang fisik bersertifikat di gerbang retribusi nagari untuk kepastian biaya masuk, parkir, sewa perahu/bendi, dan jasa pemandu.
              </p>

              <div className="space-y-3 pt-2">
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#143D2B] font-semibold">
                    <strong>Perda Resmi:</strong> 4 kategori tarif terstandar dan transparan.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#143D2B] font-semibold">
                    <strong>Tanpa Aplikasi:</strong> Cukup scan kamera HP langsung buka rincian tarif &amp; cuaca.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#143D2B] font-semibold">
                    <strong>Hotline Siaga 112 / 115:</strong> Laporkan pungli langsung ke Satgas Saber Pungli Sumbar.
                  </p>
                </div>
              </div>

              <div className="pt-2">
                <button
                  type="button"
                  onClick={() => onNavigateToQR(sampleDest)}
                  className="px-5 py-2.5 rounded-xl bg-[#143D2B] hover:bg-[#0E2E20] text-white text-xs font-bold shadow-sm transition-all flex items-center gap-2"
                >
                  <span>Lihat Contoh Plang Smart QR</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

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

                <div className="space-y-2 text-xs">
                  <div className="flex justify-between items-center p-2 rounded-lg bg-[#F9F7F2]">
                    <span className="text-stone-600 font-medium">Tiket Masuk Dewasa</span>
                    <strong className="text-[#143D2B] font-bold">Rp 15.000 / org</strong>
                  </div>
                  <div className="flex justify-between items-center p-2 rounded-lg bg-[#F9F7F2]">
                    <span className="text-stone-600 font-medium">Parkir Kendaraan Roda 4</span>
                    <strong className="text-[#143D2B] font-bold">Rp 5.000 / unit</strong>
                  </div>
                  <div className="flex justify-between items-center p-2 rounded-lg bg-[#F9F7F2]">
                    <span className="text-stone-600 font-medium">Jasa Pemandu Pokdarwis</span>
                    <strong className="text-[#143D2B] font-bold">Rp 150.000 / grup</strong>
                  </div>
                </div>

                <div className="pt-2 flex items-center justify-between text-[11px] text-stone-500 border-t border-stone-200/60">
                  <span>
                    Hotline Darurat: <strong>112 / 115</strong>
                  </span>
                  <span className="text-[#D95637] font-bold">Anti-Getok Harga</span>
                </div>
              </div>
            </div>
          </div>

          {/* Blok B — UMKM 0% Potongan vs Trip Go Escrow Aman */}
          <div id="umkm-trip" className="space-y-8 pt-6">
            <div className="max-w-xl text-left space-y-2">
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#143D2B]/8 text-[#143D2B] inline-block">
                Model Transaksi
              </span>
              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#143D2B]">
                Ekosistem Transparan Dua Jalur
              </h2>
              <p className="text-xs sm:text-sm text-stone-600">
                Pemberdayaan UMKM warga nagari dipisahkan tegas dari transaksi Escrow Trip Go.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-white rounded-2xl p-6 sm:p-7 border border-stone-200/80 shadow-sm space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#143D2B]/8 text-[#143D2B] flex items-center justify-center shrink-0">
                    <Store className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-[#143D2B]">
                      Kemitraan UMKM Nagari
                    </h3>
                    <span className="text-xs text-stone-500 font-semibold block">
                      Direct P2P WhatsApp (5 Kategori)
                    </span>
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
                      <strong>Terpetakan di Denah 2D:</strong> Temukan kios UMKM langsung dari Denah Kawasan 2D.
                    </p>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-2xl p-6 sm:p-7 border border-stone-200/80 shadow-sm space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#F26B4B]/10 text-[#F26B4B] flex items-center justify-center shrink-0">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-[#143D2B]">
                      Paket Trip Go Resmi
                    </h3>
                    <span className="text-xs text-stone-500 font-semibold block">
                      Rekening Escrow &amp; Forum Chat In-App
                    </span>
                  </div>
                </div>

                <div className="space-y-2.5 pt-2 text-xs">
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#143D2B] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>1 Destinasi Terarah:</strong> Fokus satu lokasi dengan kategori otomatis dari 5 kategori master.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#143D2B] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>Verifikasi 7 Poin Penyelenggara:</strong> Wajib lolos pemeriksaan e-KTP, SK Pokdarwis &amp; sertifikasi HPI.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <span className="text-[#143D2B] font-bold">✓</span>
                    <p className="text-stone-700 leading-relaxed">
                      <strong>Smart Trip Planner &amp; Chat:</strong> Checklist, jobdesk, itinerary, serta ruang diskusi rombongan.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 5. CTA BANNER & FOOTER */}
      <section id="sos-jalur" className="py-16">
        <div className="max-w-6xl mx-auto px-6">
          <div className="bg-[#143D2B] text-white rounded-3xl p-10 lg:p-14 text-center space-y-6 shadow-xl">
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

          <footer className="mt-14 pt-8 border-t border-stone-200/80 flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-stone-500">
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

            <div className="flex flex-wrap items-center justify-center gap-6 font-semibold">
              <button
                type="button"
                onClick={() => onNavigateToQR(sampleDest)}
                className="hover:text-[#143D2B] transition-colors"
              >
                Plang Smart QR
              </button>
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="hover:text-[#143D2B] transition-colors"
              >
                Portal Admin
              </button>
              <a href="tel:112" className="text-[#D95637] font-bold hover:underline">
                Kontak Darurat 112
              </a>
            </div>

            <p className="text-[11px] text-stone-400">
              &copy; 2026 Pemerintah Provinsi Sumatera Barat.
            </p>
          </footer>
        </div>
      </section>
    </div>
  );
};
