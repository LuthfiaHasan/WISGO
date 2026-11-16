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
} from 'lucide-react';
import { AdminAuthResponse } from '../types/contract';
import { loginAdminJWT } from '../services/api';

interface LoginPageProps {
  onLoginSuccess: (session: AdminAuthResponse) => void;
  backendOnline: boolean;
}

export const LoginPage: React.FC<LoginPageProps> = ({
  onLoginSuccess,
  backendOnline,
}) => {
  const [email, setEmail] = useState('admin.komando@sumbarprov.go.id');
  const [password, setPassword] = useState('KomandoRancak2026');
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
    const targetPass = 'KomandoRancak2026';
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
        role: 'admin_utama',
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
        role: 'admin_utama',
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
    <div className="min-h-screen bg-[#F6F3EC] text-[#1B1F1A] flex flex-col lg:flex-row">
      {/* Panel Identitas Resmi Dinas Pariwisata Sumatera Barat */}
      <section className="lg:w-5/12 bg-[#234B24] text-[#F6F3EC] p-8 lg:p-12 flex flex-col justify-between relative overflow-hidden">
        <div>
          <div className="inline-flex items-center gap-2.5 px-4 py-1.5 rounded-full bg-white/10 border border-white/15 text-xs font-bold tracking-wide">
            <Building2 className="w-4 h-4 text-[#1E9E5A]" aria-hidden="true" />
            <span>PEMERINTAH PROVINSI SUMATERA BARAT</span>
          </div>

          <h1 className="mt-6 text-3xl lg:text-4xl font-extrabold leading-tight tracking-tight">
            Pusat Komando Terpadu Rancak.in
          </h1>
          <p className="mt-4 text-sm lg:text-base text-[#E4E9DA]/90 leading-relaxed">
            Portal otoritas terpadu Dinas Pariwisata Provinsi Sumatera Barat:
            Manajemen Destinasi &amp; 5 Indikator Medan, Standar Tarif Resmi Perda &amp; Smart QR,
            Studio Virtual 360°, Penindakan Aduan Pungli Satgas Saber Pungli, serta Koordinasi Siaga Darurat SOS Tim SAR di 19 Kabupaten/Kota.
          </p>
        </div>

        <div className="my-8 space-y-3.5">
          <div className="p-4 rounded-2xl bg-black/20 border border-white/10">
            <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-[#A7F3D0]">
              <ShieldCheck className="w-4 h-4 text-[#1E9E5A]" aria-hidden="true" />
              <span>Otoritas Komando Tunggal Terintegrasi</span>
            </div>
            <p className="mt-1.5 text-xs text-[#E4E9DA]/90 leading-relaxed">
              Seluruh kendali destinasi, tarif resmi Perda, tur virtual 360°,
              laporan pelanggaran pungli dari wisatawan, dan sinyal darurat SOS terpusat
              di bawah kendali Administrator Utama dengan enkripsi sesi resmi.
            </p>
          </div>

          <div className="flex items-center justify-between px-4 py-3.5 rounded-2xl bg-white/10 border border-white/15 text-xs">
            <span className="flex items-center gap-2 font-semibold text-[#F6F3EC]">
              <CheckCircle2
                className="w-4 h-4 text-[#1E9E5A] shrink-0"
                aria-hidden="true"
              />
              <span>
                {backendOnline
                  ? 'Status Sistem: Terhubung (Database Utama)'
                  : 'Status Sistem: Mode Lokal Aktif (Sinkronisasi Otomatis)'}
              </span>
            </span>
            <span className="inline-flex items-center gap-1.5 font-bold text-[#A7F3D0]">
              <span className="w-2 h-2 rounded-full bg-[#1E9E5A]" />
              Siap Operasional
            </span>
          </div>
        </div>

        <p className="text-xs text-[#E4E9DA]/75">
          &copy; 2026 Dinas Pariwisata Provinsi Sumatera Barat · Portal Pusat Komando Resmi Rancak.in
        </p>
      </section>

      {/* Panel Formulir Otentikasi Otoritas */}
      <main className="flex-1 flex items-center justify-center p-6 lg:p-12">
        <div className="w-full max-w-lg bg-white rounded-[28px] p-7 lg:p-10 shadow-md border border-[#E4E9DA]">
          <div className="flex items-center gap-3.5 mb-6">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm">
              <KeyRound className="w-6 h-6" aria-hidden="true" />
            </div>
            <div>
              <h2
                id="login-heading"
                className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]"
              >
                Otentikasi Administrator Utama
              </h2>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Pusat Komando Terpadu Dispar, Penindakan Pungli &amp; Siaga SAR Sumbar
              </p>
            </div>
          </div>

          {/* Akses Cepat Otoritas Tunggal */}
          <div className="mb-6 p-4 rounded-2xl bg-[#E4E9DA]/65 border border-[#CFD8BE]">
            <div className="flex items-center gap-2 text-xs font-bold text-[#234B24] mb-2.5">
              <UserCheck className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>Akses Cepat Otoritas (Mode Pengujian Internal)</span>
            </div>
            <button
              type="button"
              disabled={submitting}
              onClick={handleQuickAuthorityAccess}
              className="w-full min-h-[48px] text-xs font-bold px-4 py-2.5 rounded-xl bg-[#234B24] text-[#F6F3EC] hover:bg-[#1B3B1C] transition shadow-sm flex items-center justify-center gap-2 text-center"
            >
              <Radio className="w-4 h-4 text-[#A7F3D0] shrink-0" aria-hidden="true" />
              <span>Masuk sebagai Administrator Utama (Pusat Komando Dispar, Penindakan Pungli &amp; Siaga SAR)</span>
            </button>
          </div>

          <form
            method="post"
            action="/api/v1/auth/admin-login"
            aria-labelledby="login-heading"
            onSubmit={handleSubmit}
            noValidate
          >
            {/* Input Email Dinas */}
            <div className="mb-5 flex flex-col items-start gap-1.5">
              <label
                htmlFor="admin-email"
                className="text-xs font-bold text-[#1B1F1A]"
              >
                Alamat Email Kedinasan{' '}
                <span aria-hidden="true" className="text-[#F26B4B]">
                  *
                </span>
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
                aria-describedby={emailError ? 'email-error' : 'email-help'}
                className="w-full min-h-[48px] px-4 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#767676] text-base text-[#1B1F1A] font-medium"
              />
              <span id="email-help" className="text-[11px] text-[#4A5248]">
                Akun resmi Administrator Utama berdomain @sumbarprov.go.id
              </span>
              {emailError && (
                <p
                  id="email-error"
                  role="status"
                  aria-live="polite"
                  className="text-xs font-semibold text-[#D95637] flex items-center gap-1 mt-0.5"
                >
                  <AlertCircle
                    className="w-3.5 h-3.5 shrink-0"
                    aria-hidden="true"
                  />
                  <span>{emailError}</span>
                </p>
              )}
            </div>

            {/* Input Kata Sandi */}
            <div className="mb-6 flex flex-col items-start gap-1.5">
              <div className="w-full flex items-center justify-between">
                <label
                  htmlFor="admin-password"
                  className="text-xs font-bold text-[#1B1F1A]"
                >
                  Kata Sandi Otoritas{' '}
                  <span aria-hidden="true" className="text-[#F26B4B]">
                    *
                  </span>
                </label>
                <button
                  id="toggle-password"
                  type="button"
                  aria-pressed={showPassword}
                  aria-label={
                    showPassword
                      ? 'Sembunyikan kata sandi'
                      : 'Tampilkan kata sandi'
                  }
                  aria-describedby="toggle-warning"
                  onClick={() => setShowPassword((prev) => !prev)}
                  className="inline-flex items-center gap-1 text-xs font-bold text-[#234B24] px-2.5 py-1 rounded-lg hover:bg-[#E4E9DA]/60 min-h-[44px]"
                >
                  {showPassword ? (
                    <>
                      <EyeOff className="w-4 h-4" aria-hidden="true" />
                      <span>Sembunyikan</span>
                    </>
                  ) : (
                    <>
                      <Eye className="w-4 h-4" aria-hidden="true" />
                      <span>Tampilkan</span>
                    </>
                  )}
                </button>
                <span id="toggle-warning" className="visually-hidden">
                  Peringatan: tombol ini akan menampilkan kata sandi Anda di
                  layar.
                </span>
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
                onInput={() => setEmailTouched(true)}
                autoComplete="current-password"
                minLength={6}
                enterKeyHint="done"
                required
                aria-invalid={passwordError ? 'true' : 'false'}
                aria-describedby={
                  passwordError ? 'password-error' : 'password-constraints'
                }
                className="w-full min-h-[48px] px-4 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#767676] text-base text-[#1B1F1A] font-medium"
              />
              <span
                id="password-constraints"
                className="text-[11px] text-[#4A5248]"
              >
                Minimal 6 karakter. Sesi terpusat dilindungi enkripsi JWT Bearer Token.
              </span>
              {passwordError && (
                <p
                  id="password-error"
                  role="status"
                  aria-live="polite"
                  className="text-xs font-semibold text-[#D95637] flex items-center gap-1 mt-0.5"
                >
                  <AlertCircle
                    className="w-3.5 h-3.5 shrink-0"
                    aria-hidden="true"
                  />
                  <span>{passwordError}</span>
                </p>
              )}
            </div>

            {formError && (
              <div
                role="status"
                aria-live="polite"
                className="mb-4 p-3.5 rounded-2xl bg-[#F26B4B]/15 border border-[#F26B4B] text-xs font-bold text-[#1B1F1A] flex items-center gap-2"
              >
                <AlertCircle
                  className="w-4 h-4 text-[#F26B4B] shrink-0"
                  aria-hidden="true"
                />
                <span>{formError}</span>
              </div>
            )}

            {/* Tombol Utama Kapsul 52px */}
            <button
              type="submit"
              disabled={submitting}
              className="w-full h-[52px] rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] disabled:opacity-60 text-[#F6F3EC] font-bold text-sm flex items-center justify-center gap-2 shadow-md transition"
            >
              <Lock className="w-4 h-4" aria-hidden="true" />
              <span>
                {submitting
                  ? 'Mengotentikasi Administrator Utama...'
                  : 'Masuk sebagai Administrator Utama'}
              </span>
            </button>
          </form>
        </div>
      </main>
    </div>
  );
};
