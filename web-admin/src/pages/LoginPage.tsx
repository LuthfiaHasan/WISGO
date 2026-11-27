import React, { useEffect, useRef, useState } from 'react';
import {
  Eye,
  EyeOff,
  Lock,
  UserCheck,
  AlertCircle,
  Building2,
  ArrowLeft,
  MapPin,
} from 'lucide-react';
import { AdminAuthResponse } from '../types/contract';
import { loginAdminGoogle, loginAdminJWT } from '../services/api';

interface LoginPageProps {
  onLoginSuccess: (session: AdminAuthResponse) => void;
  onBackToLanding?: () => void;
  backendOnline: boolean;
}

const SUMBAR_SLIDES = [
  {
    src: '/assets/scenery/harau.jpg',
    title: 'Lembah Harau',
    location: 'Kab. Lima Puluh Kota',
  },
  {
    src: '/assets/scenery/pagaruyung.jpg',
    title: 'Istano Basa Pagaruyung',
    location: 'Kab. Tanah Datar',
  },
  {
    src: '/assets/scenery/mandeh.jpg',
    title: 'Kawasan Bahari Mandeh',
    location: 'Kab. Pesisir Selatan',
  },
  {
    src: '/assets/scenery/jam_gadang.jpg',
    title: 'Jam Gadang',
    location: 'Kota Bukittinggi',
  },
  {
    src: '/assets/scenery/maninjau.jpg',
    title: 'Danau Maninjau',
    location: 'Kab. Agam',
  },
  {
    src: '/assets/scenery/pariangan.jpg',
    title: 'Nagari Tuo Pariangan',
    location: 'Kab. Tanah Datar',
  },
] as const;

export const LoginPage: React.FC<LoginPageProps> = ({
  onLoginSuccess,
  onBackToLanding,
  backendOnline,
}) => {
  const [email, setEmail] = useState('admin.komando@sumbarprov.go.id');
  const [password, setPassword] = useState('KomandoWISGO2026');
  const [showPassword, setShowPassword] = useState(false);
  const [activeSlide, setActiveSlide] = useState(0);

  const [emailTouched, setEmailTouched] = useState(false);
  const [passwordTouched, setPasswordTouched] = useState(false);
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [formError, setFormError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const emailRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);

  // Auto-rotating crossfade slideshow every 4.5 seconds
  useEffect(() => {
    const timer = window.setInterval(() => {
      setActiveSlide((prev) => (prev + 1) % SUMBAR_SLIDES.length);
    }, 4500);
    return () => window.clearInterval(timer);
  }, []);

  const validateEmailField = (val: string): string => {
    if (!val.trim()) return 'Alamat email kedinasan wajib diisi.';
    if (!val.includes('@') || !val.includes('.')) {
      return 'Masukkan format email kedinasan yang valid (contoh: admin.komando@sumbarprov.go.id).';
    }
    return '';
  };

  const validatePasswordField = (val: string): string => {
    if (!val) return 'Kata sandi wajib diisi.';
    if (val.length < 6) return 'Kata sandi minimal terdiri dari 6 karakter.';
    return '';
  };

  const handleQuickAuthorityAccess = async () => {
    const targetEmail = 'admin.komando@sumbarprov.go.id';
    const targetPass = 'KomandoWISGO2026';
    setEmail(targetEmail);
    setPassword(targetPass);
    setEmailError('');
    setPasswordError('');
    setFormError('');
    setSubmitting(true);
    try {
      const session = await loginAdminJWT({
        email: targetEmail,
        password: targetPass,
        role: 'admin_dispar',
      });
      onLoginSuccess(session);
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : 'Gagal masuk ke Pusat Komando Terpadu.'
      );
    } finally {
      setSubmitting(false);
    }
  };

  const handleGoogleLogin = async () => {
    setSubmitting(true);
    setFormError('');
    try {
      const googleSession = await loginAdminGoogle();
      onLoginSuccess(googleSession);
    } catch {
      setFormError('Gagal mengotentikasi akun Google.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormError('');

    const eErr = validateEmailField(email);
    const pErr = validatePasswordField(password);
    setEmailError(eErr);
    setPasswordError(pErr);

    if (eErr) {
      emailRef.current?.focus();
      return;
    }
    if (pErr) {
      passwordRef.current?.focus();
      return;
    }

    setSubmitting(true);
    try {
      const session = await loginAdminJWT({
        email,
        password,
        role: 'admin_dispar',
      });
      onLoginSuccess(session);
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : 'Gagal masuk ke Pusat Komando Terpadu.'
      );
    } finally {
      setSubmitting(false);
    }
  };

  const currentSlide = SUMBAR_SLIDES[activeSlide];

  return (
    <div className="min-h-[100dvh] bg-[#F6F3EC] text-[#1B1F1A] flex flex-col lg:flex-row font-sans">
      {/* Panel Kiri: Galeri Pemandangan Sumatera Barat + Crossfade Slideshow + Logo Resmi WISGO */}
      <section className="relative lg:w-[52%] min-h-[270px] sm:min-h-[320px] lg:min-h-[100dvh] bg-[#234B24] text-[#F6F3EC] overflow-hidden flex flex-col justify-between p-6 sm:p-8 lg:p-10 shrink-0">
        {/* Auto-Rotating Crossfade Background Slides */}
        <div className="absolute inset-0 z-0" aria-hidden="true">
          {SUMBAR_SLIDES.map((slide, idx) => {
            const isActive = idx === activeSlide;
            return (
              <img
                key={slide.src}
                src={slide.src}
                alt={slide.title}
                loading={idx === 0 ? 'eager' : 'lazy'}
                className={`absolute inset-0 w-full h-full object-cover transition-all duration-1000 ease-in-out ${
                  isActive ? 'opacity-100 scale-100' : 'opacity-0 scale-105'
                }`}
              />
            );
          })}
          {/* Subtle Forest Green Gradient Overlay for High-Contrast Typography */}
          <div className="absolute inset-0 bg-gradient-to-t from-[#163017]/95 via-[#234B24]/50 to-[#163017]/55" />
        </div>

        {/* Top Brand Identity */}
        <div className="relative z-10 flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="h-11 w-11 rounded-2xl bg-white/95 p-1.5 flex items-center justify-center shadow-md border border-white/40 shrink-0">
              <img
                src="/assets/synced/logo_icon.png"
                alt="Logo Resmi WISGO"
                onError={(e) => {
                  (e.target as HTMLImageElement).src = '/logo_icon.png';
                }}
                className="w-full h-full object-contain"
              />
            </div>
            <div>
              <span className="font-extrabold text-lg sm:text-xl tracking-tight text-white block leading-none">
                WISGO Sumbar
              </span>
              <span className="text-[10px] font-semibold text-white/80 tracking-wider uppercase block mt-1">
                Portal Otoritas Pariwisata
              </span>
            </div>
          </div>

          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-black/30 backdrop-blur-sm border border-white/15 text-[11px] font-semibold text-white/95">
            <span
              className={`w-2 h-2 rounded-full ${
                backendOnline ? 'bg-[#1E9E5A] animate-pulse' : 'bg-[#F59E0B]'
              }`}
            />
            <span>{backendOnline ? 'Sistem Online' : 'Mode Lokal V3'}</span>
          </span>
        </div>

        {/* Bottom Caption, Headline & Slide Indicators */}
        <div className="relative z-10 mt-10 lg:mt-auto space-y-5">
          <div className="space-y-2.5 max-w-lg">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/15 backdrop-blur-sm border border-white/15 text-[#E4F7EC] text-[11px] font-semibold tracking-wide">
              <Building2 className="w-3.5 h-3.5 text-[#A7F3D0]" aria-hidden="true" />
              <span>DINAS PARIWISATA PROVINSI SUMATERA BARAT</span>
            </div>

            <h1 className="text-2xl sm:text-3xl lg:text-4xl font-extrabold leading-tight tracking-tight text-white drop-shadow-sm">
              Pusat Komando Wisata Sumatera Barat
            </h1>
            <p className="text-xs sm:text-sm text-white/85 leading-relaxed max-w-md hidden sm:block">
              Kelola destinasi 19 Kab/Kota, tarif resmi Perda, Panorama 360°, verifikasi Trip Go, dan Siaga SOS dalam satu ekosistem terpadu.
            </p>
          </div>

          <div className="pt-4 border-t border-white/15 flex flex-wrap items-center justify-between gap-3">
            <div className="inline-flex items-center gap-2 text-xs text-white/90 font-medium">
              <MapPin className="w-3.5 h-3.5 text-[#A7F3D0] shrink-0" aria-hidden="true" />
              <span className="font-bold">{currentSlide.title}</span>
              <span className="text-white/60">·</span>
              <span className="text-white/80">{currentSlide.location}</span>
            </div>

            <div className="flex items-center gap-1.5" role="tablist" aria-label="Pilih pemandangan Sumatera Barat">
              {SUMBAR_SLIDES.map((slide, idx) => (
                <button
                  key={slide.src}
                  type="button"
                  role="tab"
                  aria-selected={idx === activeSlide}
                  aria-label={`Tampilkan ${slide.title}`}
                  onClick={() => setActiveSlide(idx)}
                  className={`h-1.5 rounded-full transition-all duration-300 ${
                    idx === activeSlide
                      ? 'w-6 bg-white'
                      : 'w-1.5 bg-white/40 hover:bg-white/70'
                  }`}
                />
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Panel Kanan: Form Otentikasi Ultra-Clean & Proporsional */}
      <main className="flex-1 flex items-center justify-center p-5 sm:p-8 lg:p-10">
        <div className="w-full max-w-[420px] bg-white rounded-3xl p-6 sm:p-8 shadow-[0_8px_30px_rgba(35,75,36,0.06)] border border-[#234B24]/10">
          {onBackToLanding && (
            <button
              type="button"
              onClick={onBackToLanding}
              className="mb-4 text-xs font-semibold text-[#234B24] hover:text-[#1B3B1C] inline-flex items-center gap-1.5 transition group"
            >
              <ArrowLeft className="w-3.5 h-3.5 group-hover:-translate-x-0.5 transition-transform" />
              <span>Kembali ke Beranda Publik</span>
            </button>
          )}

          <div className="mb-5">
            <h2
              id="login-heading"
              className="text-xl font-extrabold text-[#1B1F1A] tracking-tight"
            >
              Masuk Portal Admin
            </h2>
            <p className="text-xs text-[#5A655A] mt-1">
              Otentikasi akun resmi Dinas Pariwisata Sumatera Barat
            </p>
          </div>

          {/* Akses Cepat Ringkas */}
          <div className="mb-5 flex items-center justify-between px-3 py-2.5 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10">
            <div className="flex items-center gap-2 text-xs font-medium text-[#4A5248]">
              <UserCheck className="w-4 h-4 text-[#234B24]" />
              <span>Mode Pengujian</span>
            </div>
            <button
              type="button"
              disabled={submitting}
              onClick={handleQuickAuthorityAccess}
              className="text-xs font-bold text-[#234B24] hover:underline hover:text-[#1B3B1C]"
            >
              Masuk Cepat (Demo)
            </button>
          </div>

          <form
            method="post"
            action="/api/v1/auth/admin-login"
            aria-labelledby="login-heading"
            onSubmit={handleSubmit}
            noValidate
            className="space-y-4"
          >
            {/* Input Email Dinas */}
            <div className="flex flex-col items-start gap-1.5">
              <label
                htmlFor="admin-email"
                className="text-xs font-bold text-[#1B1F1A]"
              >
                Alamat Email Kedinasan
              </label>
              <input
                ref={emailRef}
                id="admin-email"
                name="email"
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value);
                  if (emailError) setEmailError('');
                }}
                onBlur={() => {
                  if (emailTouched) {
                    setEmailError(validateEmailField(email));
                  }
                }}
                onInput={() => setEmailTouched(true)}
                autoComplete="username"
                autoCorrect="off"
                autoCapitalize="none"
                spellCheck={false}
                enterKeyHint="next"
                required
                aria-invalid={emailError ? 'true' : 'false'}
                className="w-full h-11 px-3.5 rounded-xl bg-[#F6F3EC] border border-[#234B24]/15 text-sm text-[#1B1F1A] font-medium focus:outline-none focus:ring-2 focus:ring-[#234B24]"
              />
              {emailError && (
                <p
                  role="status"
                  aria-live="polite"
                  className="text-xs font-semibold text-[#D95637] flex items-center gap-1 mt-0.5"
                >
                  <AlertCircle className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
                  <span>{emailError}</span>
                </p>
              )}
            </div>

            {/* Input Kata Sandi */}
            <div className="flex flex-col items-start gap-1.5">
              <div className="w-full flex items-center justify-between">
                <label
                  htmlFor="admin-password"
                  className="text-xs font-bold text-[#1B1F1A]"
                >
                  Kata Sandi Otoritas
                </label>
                <button
                  id="toggle-password"
                  type="button"
                  aria-pressed={showPassword}
                  onClick={() => setShowPassword((prev) => !prev)}
                  className="inline-flex items-center gap-1 text-[11px] font-bold text-[#234B24] hover:underline"
                >
                  {showPassword ? (
                    <>
                      <EyeOff className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>Sembunyikan</span>
                    </>
                  ) : (
                    <>
                      <Eye className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>Tampilkan</span>
                    </>
                  )}
                </button>
              </div>

              <input
                ref={passwordRef}
                id="admin-password"
                name="password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  if (passwordError) setPasswordError('');
                }}
                onBlur={() => {
                  if (passwordTouched) {
                    setPasswordError(validatePasswordField(password));
                  }
                }}
                onInput={() => setPasswordTouched(true)}
                autoComplete="current-password"
                minLength={6}
                enterKeyHint="done"
                required
                aria-invalid={passwordError ? 'true' : 'false'}
                className="w-full h-11 px-3.5 rounded-xl bg-[#F6F3EC] border border-[#234B24]/15 text-sm text-[#1B1F1A] font-medium focus:outline-none focus:ring-2 focus:ring-[#234B24]"
              />
              {passwordError && (
                <p
                  role="status"
                  aria-live="polite"
                  className="text-xs font-semibold text-[#D95637] flex items-center gap-1 mt-0.5"
                >
                  <AlertCircle className="w-3.5 h-3.5 shrink-0" aria-hidden="true" />
                  <span>{passwordError}</span>
                </p>
              )}
            </div>

            {formError && (
              <div
                role="status"
                aria-live="polite"
                className="p-3 rounded-xl bg-[#F26B4B]/15 border border-[#F26B4B] text-xs font-bold text-[#1B1F1A] flex items-center gap-2"
              >
                <AlertCircle className="w-4 h-4 text-[#F26B4B] shrink-0" aria-hidden="true" />
                <span>{formError}</span>
              </div>
            )}

            {/* Tombol Masuk Utama */}
            <button
              type="submit"
              disabled={submitting}
              className="w-full h-11 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] disabled:opacity-60 text-[#F6F3EC] font-bold text-xs flex items-center justify-center gap-2 shadow-sm transition"
            >
              <Lock className="w-3.5 h-3.5" aria-hidden="true" />
              <span>
                {submitting ? 'Mengotentikasi...' : 'Masuk sebagai Administrator'}
              </span>
            </button>

            {/* Pemisah Alternatif Login */}
            <div className="relative my-2 flex items-center justify-center">
              <div className="w-full border-t border-[#234B24]/10" />
              <span className="absolute bg-white px-2.5 text-[10px] font-bold text-[#767676] uppercase">
                atau
              </span>
            </div>

            {/* Tombol Login Google */}
            <button
              type="button"
              disabled={submitting}
              onClick={handleGoogleLogin}
              className="w-full h-11 rounded-xl bg-white hover:bg-[#F6F3EC] border border-[#234B24]/20 text-[#1B1F1A] font-bold text-xs flex items-center justify-center gap-2.5 shadow-sm transition"
            >
              <img
                src="/assets/synced/google_logo.png"
                alt="Google"
                className="w-4 h-4 object-contain"
                onError={(e) => {
                  (e.target as HTMLImageElement).src =
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg';
                }}
              />
              <span>Masuk dengan Akun Google</span>
            </button>
          </form>

          <p className="mt-5 text-center text-[11px] text-[#767676]">
            &copy; 2026 Dinas Pariwisata Provinsi Sumatera Barat
          </p>
        </div>
      </main>
    </div>
  );
};
