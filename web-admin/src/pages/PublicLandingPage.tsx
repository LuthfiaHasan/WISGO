import React from 'react';
import {
  Compass,
  QrCode,
  Camera,
  Trophy,
  Radio,
  ArrowRight,
  ShieldCheck,
  MapPin,
  ExternalLink,
  CheckCircle2,
  Users,
  Ticket,
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
    <div className="min-h-screen bg-[#F6F3EC] text-[#234B24] font-sans antialiased selection:bg-[#234B24]/15 selection:text-[#234B24] overflow-x-hidden">
      {/* 1. STICKY HEADER PUBLIK */}
      <nav
        aria-label="Navigasi Utama Publik WISGO"
        className="sticky top-0 z-40 h-16 bg-[#F6F3EC]/85 backdrop-blur-md border-b border-[#234B24]/10 transition-colors flex items-center"
      >
        <div className="w-full max-w-6xl mx-auto px-4 sm:px-6 flex items-center justify-between gap-4">
          <div className="flex items-center gap-2.5 shrink-0">
            <div className="w-9 h-9 rounded-xl bg-white border border-[#234B24]/15 flex items-center justify-center p-1.5 shadow-sm">
              <img
                src="/assets/synced/logo_icon.png"
                alt="Logo Resmi WISGO"
                className="w-full h-full object-contain"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = '/logo_icon.png';
                }}
              />
            </div>
            <div className="flex flex-col">
              <span className="font-extrabold text-base tracking-tight text-[#234B24] leading-none">
                WISGO Sumbar
              </span>
              <span className="text-[10px] font-semibold text-[#5A655A] tracking-wider uppercase mt-0.5">
                Portal Pariwisata Resmi
              </span>
            </div>
          </div>

          <div className="hidden md:flex items-center gap-7 text-xs font-bold text-[#234B24]/80">
            <button
              type="button"
              onClick={() => scrollToSection('fitur')}
              className="hover:text-[#234B24] transition-colors"
            >
              Fitur
            </button>
            <button
              type="button"
              onClick={() => scrollToSection('smart-qr')}
              className="hover:text-[#234B24] transition-colors"
            >
              Smart QR
            </button>
            <button
              type="button"
              onClick={() => scrollToSection('trip-go')}
              className="hover:text-[#234B24] transition-colors"
            >
              Trip Go
            </button>
            <button
              type="button"
              onClick={() => scrollToSection('sos-jalur')}
              className="hover:text-[#234B24] transition-colors"
            >
              Siaga SOS
            </button>
          </div>

          <div className="flex items-center gap-2 sm:gap-3 shrink-0">
            <button
              type="button"
              onClick={onNavigateToLogin}
              className="px-3 py-2 text-xs font-bold text-[#234B24] hover:text-[#1B3B1C] transition-colors"
            >
              Portal Admin
            </button>
            <button
              type="button"
              onClick={() => onNavigateToQR(sampleDest)}
              className="px-3.5 sm:px-4 py-2 rounded-xl bg-[#234B24] text-white hover:bg-[#1B3B1C] text-xs font-bold shadow-sm transition-all flex items-center gap-1.5"
            >
              <QrCode className="w-3.5 h-3.5" />
              <span>Coba Smart QR</span>
            </button>
          </div>
        </div>
      </nav>

      {/* 2. HERO SECTION */}
      <section className="py-14 sm:py-20 lg:py-24 relative">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-12 items-center">
            <div className="lg:col-span-6 space-y-6 text-left">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-bold bg-[#234B24]/10 text-[#234B24]">
                <span className="w-2 h-2 rounded-full bg-[#1E9E5A] animate-pulse" />
                <span>Dinas Pariwisata Provinsi Sumatera Barat</span>
              </div>

              <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-[#1B1F1A] leading-[1.12]">
                Wisata Ranah Minang.{' '}
                <span className="text-[#234B24]">Aman, Transparan, Tanpa Pungli.</span>
              </h1>

              <p className="text-sm sm:text-base text-[#4A5248] leading-relaxed max-w-xl">
                4 indikator medan nyata, cuaca live Open-Meteo, tarif resmi Perda via Smart QR, Panorama 360° murni, Trip Go terverifikasi, serta Siaga SOS 19 Kab/Kota Sumatera Barat.
              </p>

              <div className="pt-1 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
                <button
                  type="button"
                  onClick={() => scrollToSection('fitur')}
                  className="px-6 py-3.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-extrabold shadow-sm transition-all flex items-center justify-center gap-2"
                >
                  <span>Jelajah Fitur WISGO</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={onNavigateToLogin}
                  className="px-6 py-3.5 rounded-xl bg-white hover:bg-[#F6F3EC] text-[#234B24] border border-[#234B24]/20 text-xs font-extrabold shadow-sm transition-all flex items-center justify-center gap-2"
                >
                  <span>Portal Command Center</span>
                  <ExternalLink className="w-3.5 h-3.5 opacity-60" />
                </button>
              </div>
            </div>

            {/* Live Destination Showcase Card dengan Foto Asli Sumbar */}
            <div className="lg:col-span-6">
              <div className="bg-white rounded-3xl overflow-hidden border border-[#234B24]/10 shadow-[0_12px_36px_rgba(35,75,36,0.08)]">
                <div className="relative h-56 sm:h-64 w-full overflow-hidden">
                  <img
                    src="/assets/scenery/harau.jpg"
                    alt={sampleDest?.name || 'Lembah Harau Sumatera Barat'}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-[#163017]/90 via-[#163017]/25 to-transparent" />
                  <div className="absolute top-4 left-4 right-4 flex items-center justify-between gap-2">
                    <span className="px-3 py-1 rounded-full text-[11px] font-bold bg-[#234B24]/90 text-white backdrop-blur-sm">
                      Perda Terverifikasi
                    </span>
                    <span className="px-3 py-1 rounded-full text-[11px] font-extrabold bg-white/95 text-[#234B24] shadow-sm">
                      {sampleDest?.ticket_price_summary || 'Rp 15.000 / orang'}
                    </span>
                  </div>
                  <div className="absolute bottom-4 left-5 right-5 text-white">
                    <h2 className="text-lg sm:text-xl font-extrabold leading-tight">
                      {sampleDest?.name || 'Lembah Harau & Sarasah Bunta'}
                    </h2>
                    <p className="text-xs text-white/85 flex items-center gap-1.5 mt-1">
                      <MapPin className="w-3.5 h-3.5 text-[#A7F3D0] shrink-0" />
                      <span>
                        {sampleDest?.city_regency || 'Kab. Lima Puluh Kota'} ·{' '}
                        {sampleDest?.category || 'Alam & Geopark'}
                      </span>
                    </p>
                  </div>
                </div>

                <div className="p-5 grid grid-cols-2 gap-3 text-left">
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10">
                    <span className="text-[10px] font-bold text-[#5A655A] uppercase block">
                      Akses Kendaraan
                    </span>
                    <span className="text-xs font-extrabold text-[#234B24] mt-0.5 block">
                      {sampleDest?.medan_indicator?.vehicle_access || 'Mobil OK'}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10">
                    <span className="text-[10px] font-bold text-[#5A655A] uppercase block">
                      Tingkat Trekking
                    </span>
                    <span className="text-xs font-extrabold text-[#234B24] mt-0.5 block">
                      {sampleDest?.medan_indicator?.trekking_level || 'Mudah (Datar)'}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10">
                    <span className="text-[10px] font-bold text-[#5A655A] uppercase block">
                      Cuaca Live
                    </span>
                    <span className="text-xs font-extrabold text-[#234B24] mt-0.5 block">
                      {sampleDest?.weather?.temperature_c ?? 26}°C ·{' '}
                      {sampleDest?.weather?.condition || 'Cerah Berawan'}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10">
                    <span className="text-[10px] font-bold text-[#5A655A] uppercase block">
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
        </div>
      </section>

      {/* 3. BENTO 6 FITUR INTI (100% SELARAS MOBILE TERBARU) */}
      <section id="fitur" className="py-16 sm:py-20 bg-white border-y border-[#234B24]/10">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="max-w-2xl mx-auto text-center space-y-3 mb-12">
            <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#234B24]/10 text-[#234B24] inline-block">
              Pilar Layanan
            </span>
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#1B1F1A]">
              Enam Fitur Utama Ekosistem WISGO
            </h2>
            <p className="text-xs sm:text-sm text-[#5A655A]">
              Satu alur data antara aplikasi mobile wisatawan dan Pusat Komando Dinas Pariwisata Sumbar.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            <div className="bg-[#F6F3EC]/60 rounded-2xl p-6 border border-[#234B24]/10 hover:border-[#234B24]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0">
                <Compass className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                  4 Indikator Medan &amp; Cuaca Live
                </h3>
                <p className="text-xs text-[#4A5248] leading-relaxed">
                  Cek akses kendaraan, tingkat trekking, fasilitas resmi, kebutuhan pemandu, serta pantauan cuaca Open-Meteo real-time.
                </p>
              </div>
            </div>

            <div className="bg-[#F6F3EC]/60 rounded-2xl p-6 border border-[#234B24]/10 hover:border-[#234B24]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0">
                <QrCode className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#1B1F1A]">Smart QR Tarif Perda</h3>
                <p className="text-xs text-[#4A5248] leading-relaxed">
                  Scan plang di lokasi untuk memeriksa tarif resmi Perda dan melaporkan indikasi pungli langsung ke Satgas.
                </p>
              </div>
            </div>

            <div className="bg-[#F6F3EC]/60 rounded-2xl p-6 border border-[#234B24]/10 hover:border-[#234B24]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0">
                <Camera className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                  Panorama 360° Murni
                </h3>
                <p className="text-xs text-[#4A5248] leading-relaxed">
                  Tinjau lanskap nyata sudut Aerial &amp; Ground lewat penampil Panorama 360° bersih tanpa distraksi pin sebelum berangkat.
                </p>
              </div>
            </div>

            <div className="bg-[#F6F3EC]/60 rounded-2xl p-6 border border-[#234B24]/10 hover:border-[#234B24]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0">
                <Users className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#1B1F1A]">Trip Go &amp; Escrow Aman</h3>
                <p className="text-xs text-[#4A5248] leading-relaxed">
                  Open trip resmi 1 destinasi dengan verifikasi 5-langkah penyelenggara, e-Tiket Boarding Pass, dan Grup Chat In-App.
                </p>
              </div>
            </div>

            <div className="bg-[#F6F3EC]/60 rounded-2xl p-6 border border-[#234B24]/10 hover:border-[#234B24]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0">
                <Trophy className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                  Jejak WISGO &amp; Paspor Minang
                </h3>
                <p className="text-xs text-[#4A5248] leading-relaxed">
                  Kumpulkan 10 stempel GPS Paspor Digital Minang untuk meraih E-Sertifikat Gubernur dan naik 5 level petualang.
                </p>
              </div>
            </div>

            <div className="bg-[#F6F3EC]/60 rounded-2xl p-6 border border-[#234B24]/10 hover:border-[#234B24]/30 transition-all flex flex-col justify-between space-y-4">
              <div className="w-10 h-10 rounded-xl bg-[#234B24] text-white flex items-center justify-center shrink-0">
                <Radio className="w-5 h-5" />
              </div>
              <div className="space-y-1.5">
                <h3 className="text-sm font-extrabold text-[#1B1F1A]">
                  Siaga SOS &amp; 4 Jalur Ekstrem
                </h3>
                <p className="text-xs text-[#4A5248] leading-relaxed">
                  Hotline bebas pulsa 112/115, 6 instansi darurat resmi Sumbar, sirene &amp; senter SOS fisik, serta pantauan 4 jalur ekstrem.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 4. HIGHLIGHT SPLIT SECTION */}
      <section id="smart-qr" className="py-16 sm:py-20">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 space-y-20">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
            <div className="lg:col-span-6 space-y-5">
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#234B24]/10 text-[#234B24] inline-block">
                Saber Pungli Terpadu
              </span>
              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#1B1F1A] leading-snug">
                Tarif Resmi Tanpa Getok Harga
              </h2>
              <p className="text-xs sm:text-sm text-[#4A5248] leading-relaxed">
                Plang fisik bersertifikat di gerbang retribusi nagari untuk kepastian biaya masuk, parkir, sewa perahu/bendi, dan jasa pemandu.
              </p>

              <div className="space-y-3 pt-1">
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#1B1F1A] font-semibold">
                    <strong>Perda Resmi:</strong> 4 kategori tarif terstandar dan transparan.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#1B1F1A] font-semibold">
                    <strong>Tanpa Aplikasi:</strong> Cukup scan kamera HP langsung buka rincian tarif &amp; cuaca.
                  </p>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                  <p className="text-xs text-[#1B1F1A] font-semibold">
                    <strong>Hotline Siaga 112 / 115:</strong> Laporkan pungli langsung ke Satgas Saber Pungli Sumbar.
                  </p>
                </div>
              </div>

              <div className="pt-2">
                <button
                  type="button"
                  onClick={() => onNavigateToQR(sampleDest)}
                  className="px-5 py-2.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-white text-xs font-bold shadow-sm transition-all inline-flex items-center gap-2"
                >
                  <span>Lihat Contoh Plang Smart QR</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

            <div className="lg:col-span-6">
              <div className="bg-white rounded-3xl p-6 sm:p-7 border border-[#234B24]/10 shadow-[0_8px_32px_rgba(35,75,36,0.06)] space-y-4">
                <div className="flex items-center justify-between pb-3 border-b border-[#234B24]/10">
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-xl bg-[#234B24] text-white flex items-center justify-center">
                      <QrCode className="w-4 h-4" />
                    </div>
                    <div>
                      <span className="text-[10px] font-bold text-[#5A655A] uppercase block leading-none">
                        Plang Fisik Lapangan
                      </span>
                      <strong className="text-xs font-extrabold text-[#234B24]">
                        Smart QR Barometer Perda
                      </strong>
                    </div>
                  </div>
                  <span className="text-[10px] font-extrabold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
                    Terverifikasi Pemprov
                  </span>
                </div>

                <div className="space-y-2 text-xs">
                  <div className="flex justify-between items-center p-2.5 rounded-xl bg-[#F6F3EC]">
                    <span className="text-[#4A5248] font-medium">Tiket Masuk Dewasa</span>
                    <strong className="text-[#234B24] font-bold">Rp 15.000 / org</strong>
                  </div>
                  <div className="flex justify-between items-center p-2.5 rounded-xl bg-[#F6F3EC]">
                    <span className="text-[#4A5248] font-medium">Parkir Kendaraan Roda 4</span>
                    <strong className="text-[#234B24] font-bold">Rp 5.000 / unit</strong>
                  </div>
                  <div className="flex justify-between items-center p-2.5 rounded-xl bg-[#F6F3EC]">
                    <span className="text-[#4A5248] font-medium">Jasa Pemandu Pokdarwis</span>
                    <strong className="text-[#234B24] font-bold">Rp 150.000 / grup</strong>
                  </div>
                </div>

                <div className="pt-2 flex items-center justify-between text-[11px] text-[#5A655A] border-t border-[#234B24]/10">
                  <span>
                    Hotline Darurat: <strong className="text-[#1B1F1A]">112 / 115</strong>
                  </span>
                  <span className="text-[#D95637] font-bold">Anti-Getok Harga</span>
                </div>
              </div>
            </div>
          </div>

          {/* Blok B — Trip Go Resmi & Escrow */}
          <div id="trip-go" className="space-y-8 pt-4">
            <div className="max-w-xl text-left space-y-2">
              <span className="px-3 py-1 rounded-full text-xs font-bold bg-[#234B24]/10 text-[#234B24] inline-block">
                Trip Go Resmi WISGO
              </span>
              <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-[#1B1F1A]">
                Open Trip Terverifikasi &amp; Escrow Aman
              </h2>
              <p className="text-xs sm:text-sm text-[#4A5248]">
                Seluruh perjalanan grup Trip Go diawasi langsung oleh Dinas Pariwisata dari pengajuan hingga keberangkatan.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-white rounded-2xl p-6 sm:p-7 border border-[#234B24]/10 shadow-sm space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#234B24]/10 text-[#234B24] flex items-center justify-center shrink-0">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-[#1B1F1A]">
                      Verifikasi 5-Langkah Penyelenggara
                    </h3>
                    <span className="text-xs text-[#5A655A] font-semibold block">
                      Standar Keselamatan &amp; Rekening Escrow
                    </span>
                  </div>
                </div>

                <div className="space-y-2.5 pt-1 text-xs">
                  <div className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                    <p className="text-[#4A5248] leading-relaxed">
                      <strong>1 Destinasi Terarah:</strong> Fokus satu lokasi resmi dengan titik kumpul otomatis Google Maps &amp; SOP perjalanan.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                    <p className="text-[#4A5248] leading-relaxed">
                      <strong>Seleksi Jalur Hard &amp; e-KTP:</strong> Verifikasi identitas penyelenggara, pengalaman pemandu, dan lisensi resmi untuk jalur ekstrem.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-[#1E9E5A] shrink-0 mt-0.5" />
                    <p className="text-[#4A5248] leading-relaxed">
                      <strong>Escrow Terlindungi:</strong> Dana peserta aman tersimpan di rekening Escrow WISGO hingga perjalanan terkonfirmasi.
                    </p>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-2xl p-6 sm:p-7 border border-[#234B24]/10 shadow-sm space-y-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-[#F26B4B]/15 text-[#D95637] flex items-center justify-center shrink-0">
                    <Ticket className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-[#1B1F1A]">
                      e-Tiket Boarding Pass &amp; Kesiapan 3-Tahap
                    </h3>
                    <span className="text-xs text-[#5A655A] font-semibold block">
                      Koordinasi 100% In-App Tanpa WhatsApp
                    </span>
                  </div>
                </div>

                <div className="space-y-2.5 pt-1 text-xs">
                  <div className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-[#234B24] shrink-0 mt-0.5" />
                    <p className="text-[#4A5248] leading-relaxed">
                      <strong>e-Tiket Otomatis:</strong> Setiap pembayaran lunas langsung menerbitkan kode Boarding Pass digital resmi.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-[#234B24] shrink-0 mt-0.5" />
                    <p className="text-[#4A5248] leading-relaxed">
                      <strong>Alur Kesiapan Berjenjang:</strong> Pemantauan transparan dari Persiapan → Daftar Peserta Final → Finalisasi Keberangkatan.
                    </p>
                  </div>
                  <div className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-[#234B24] shrink-0 mt-0.5" />
                    <p className="text-[#4A5248] leading-relaxed">
                      <strong>Smart Planner &amp; Grup Chat:</strong> Checklist perlengkapan, rincian Include/Exclude, dan ruang diskusi rombongan.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 5. CTA BANNER & FOOTER */}
      <section id="sos-jalur" className="py-14 sm:py-16">
        <div className="max-w-6xl mx-auto px-4 sm:px-6">
          <div className="bg-[#234B24] text-white rounded-3xl p-8 sm:p-12 lg:p-14 text-center space-y-5 shadow-xl relative overflow-hidden">
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full text-xs font-semibold bg-white/10 text-white/95">
              <span className="w-2 h-2 rounded-full bg-[#1E9E5A]" />
              <span>Pusat Komando Terpadu</span>
            </div>

            <h2 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold tracking-tight text-white max-w-2xl mx-auto leading-tight">
              Terintegrasi untuk Dinas Pariwisata, Saber Pungli &amp; Tim SAR.
            </h2>

            <p className="text-xs sm:text-sm text-white/80 max-w-xl mx-auto leading-relaxed">
              Sistem operasional pariwisata terpadu di seluruh 19 Kabupaten dan Kota Provinsi Sumatera Barat.
            </p>

            <div className="pt-2">
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="px-6 py-3.5 rounded-xl bg-white hover:bg-[#F6F3EC] text-[#234B24] text-xs font-extrabold shadow-sm transition-all inline-flex items-center gap-2"
              >
                <span>Masuk Dashboard Admin</span>
                <ArrowRight className="w-4 h-4 text-[#234B24]" />
              </button>
            </div>
          </div>

          <footer className="mt-12 pt-8 border-t border-[#234B24]/15 flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-[#5A655A]">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-white border border-[#234B24]/15 p-1 flex items-center justify-center shadow-sm">
                <img
                  src="/assets/synced/logo_icon.png"
                  alt="Logo Resmi WISGO"
                  className="w-full h-full object-contain"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = '/logo_icon.png';
                  }}
                />
              </div>
              <span className="font-extrabold text-[#234B24]">WISGO Sumbar</span>
            </div>

            <div className="flex flex-wrap items-center justify-center gap-6 font-semibold">
              <button
                type="button"
                onClick={() => onNavigateToQR(sampleDest)}
                className="hover:text-[#234B24] transition-colors"
              >
                Plang Smart QR
              </button>
              <button
                type="button"
                onClick={onNavigateToLogin}
                className="hover:text-[#234B24] transition-colors"
              >
                Portal Admin
              </button>
              <a href="tel:112" className="text-[#D95637] font-bold hover:underline">
                Kontak Darurat 112
              </a>
            </div>

            <p className="text-[11px] text-[#767676]">
              &copy; 2026 Pemerintah Provinsi Sumatera Barat.
            </p>
          </footer>
        </div>
      </section>
    </div>
  );
};
