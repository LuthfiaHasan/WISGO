import React, { useRef, useState } from 'react';
import {
  ShieldCheck,
  Eye,
  EyeOff,
  Lock,
  KeyRound,
  UserCheck,
  AlertCircle,
  CheckCircle2,
  Building2,
  Radio,
  ArrowLeft,
} from 'lucide-react';
import { AdminAuthResponse } from '../types/contract';
import { loginAdminGoogle, loginAdminJWT } from '../services/api';

interface LoginPageProps {
  onLoginSuccess: (session: AdminAuthResponse) => void;
  onBackToLanding?: () => void;
  backendOnline: boolean;
}

export const LoginPage: React.FC<LoginPageProps> = ({
  onLoginSuccess,
  onBackToLanding,
  backendOnline,
}) => {
  const [email, setEmail] = useState('admin.komando@sumbarprov.go.id');
  const [password, setPassword] = useState('KomandoWISGO2026');
  const [showPassword, setShowPassword] = useState(false);

  const [emailTouched, setEmailTouched] = useState(false);
  const [passwordTouched, setPasswordTouched] = useState(false);
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [formError, setFormError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const emailRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);

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

  return (
    <div className="min-h-[100dvh] bg-[#F6F3EC] text-[#1B1F1A] flex flex-col lg:flex-row font-sans">
      {/* Panel Identitas Resmi Dinas Pariwisata Sumatera Barat */}
      <section className="lg:w-5/12 bg-[#234B24] text-[#F6F3EC] p-6 sm:p-8 lg:p-10 flex flex-col justify-between shrink-0 relative overflow-hidden">
        <div>
          <div className="flex items-center gap-3 mb-6">
            <div className="h-10 w-10 rounded-xl bg-white/10 p-1.5 flex items-center justify-center border border-white/20 shrink-0">
              <img src="/logo_icon.png" alt="WISGO" className="w-full h-full object-contain" />
            </div>
            <span className="font-extrabold text-xl tracking-tight text-[#F6F3EC]">
              WISGO Sumbar
            </span>
          </div>

          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 text-[#A7F3D0] text-[11px] font-semibold tracking-wide">
            <Building2 className="w-3.5 h-3.5 text-[#1E9E5A]" aria-hidden="true" />
            <span>PEMERINTAH PROVINSI SUMATERA BARAT</span>
          </div>

          <h1 className="mt-4 text-2xl lg:text-3xl font-extrabold leading-tight tracking-tight text-[#F6F3EC]">
            Pusat Komando Wisata Sumatera Barat
          </h1>
          <p className="mt-3 text-xs lg:text-sm text-[#F6F3EC]/80 leading-relaxed max-w-md">
            Portal otoritas terpadu Dinas Pariwisata: manajemen destinasi, tarif resmi Perda, tur 360°, dan siaga komando SOS di 19 Kabupaten/Kota.
          </p>
        </div>

        <div className="mt-6 pt-5 border-t border-white/10 flex items-center justify-between text-xs text-[#F6F3EC]/70">
          <span className="inline-flex items-center gap-2 font-medium">
            <span className="w-2 h-2 rounded-full bg-[#1E9E5A] animate-pulse" />
            <span>{backendOnline ? 'Sistem Online' : 'Mode Lokal Aktif'}</span>
          </span>
          <span>&copy; 2026 Dispar Sumbar</span>
        </div>
      </section>

      {/* Panel Formulir Otentikasi Otoritas */}
      <main className="flex-1 flex items-center justify-center p-4 sm:p-6 lg:p-8">
        <div className="w-full max-w-md bg-white rounded-2xl p-6 sm:p-8 shadow-[0_2px_12px_rgba(35,75,36,0.05)] border border-[#234B24]/10">
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
              className="text-xl font-extrabold text-[#1B1F1A]"
            >
              Otentikasi Administrator
            </h2>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Pusat Komando Terpadu Dispar Sumbar
            </p>
          </div>

          {/* Akses Cepat Ringkas 1 Baris */}
          <div className="mb-5 flex items-center justify-between p-2.5 rounded-xl bg-[#F6F3EC] border border-[#234B24]/10">
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
            <div className="flex flex-col items-start gap-1">
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
                className="w-full h-11 px-3.5 rounded-xl bg-[#F6F3EC] border border-[#234B24]/15 text-sm text-[#1B1F1A] font-medium focus:outline-hidden focus:ring-2 focus:ring-[#234B24]"
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
            <div className="flex flex-col items-start gap-1">
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
                className="w-full h-11 px-3.5 rounded-xl bg-[#F6F3EC] border border-[#234B24]/15 text-sm text-[#1B1F1A] font-medium focus:outline-hidden focus:ring-2 focus:ring-[#234B24]"
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
              className="w-full h-11 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] disabled:opacity-60 text-[#F6F3EC] font-bold text-xs flex items-center justify-center gap-2 shadow-xs transition"
            >
              <Lock className="w-3.5 h-3.5" aria-hidden="true" />
              <span>
                {submitting
                  ? 'Mengotentikasi...'
                  : 'Masuk sebagai Administrator'}
              </span>
            </button>

            {/* Pemisah Alternatif Login */}
            <div className="relative my-3 flex items-center justify-center">
              <div className="w-full border-t border-[#234B24]/10" />
              <span className="absolute bg-white px-2.5 text-[10px] font-bold text-[#767676] uppercase">
                atau
              </span>
            </div>

            {/* Tombol Login Menggunakan Akun Google */}
            <button
              type="button"
              disabled={submitting}
              onClick={handleGoogleLogin}
              className="w-full h-11 rounded-xl bg-white hover:bg-[#F6F3EC] border border-[#234B24]/20 text-[#1B1F1A] font-bold text-xs flex items-center justify-center gap-2.5 shadow-2xs transition"
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
        </div>
      </main>
    </div>
  );
};
