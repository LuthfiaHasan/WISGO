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
  const [email, setEmail] = useState('kadispar@sumbarprov.go.id');
  const [password, setPassword] = useState('RancakMinang2026');
  const [role, setRole] = useState<'admin_dispar' | 'satgas_pungli'>(
    'admin_dispar'
  );
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
      return 'Masukkan format email kedinasan yang valid (contoh: kadispar@sumbarprov.go.id).';
    }
    return '';
  };

  const validatePasswordField = (val: string): string => {
    if (!val) return 'Kata sandi wajib diisi.';
    if (val.length < 6) return 'Kata sandi minimal terdiri dari 6 karakter.';
    return '';
  };

  const handleQuickAuthorityAccess = async (
    targetEmail: string,
    targetPass: string,
    targetRole: 'admin_dispar' | 'satgas_pungli'
  ) => {
    setEmail(targetEmail);
    setPassword(targetPass);
    setRole(targetRole);
    setEmailError('');
    setPasswordError('');
    setFormError('');
    setSubmitting(true);
    try {
      const session = await loginAdminJWT({
        email: targetEmail,
        password: targetPass,
        role: targetRole,
      });
      onLoginSuccess(session);
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : 'Gagal masuk ke portal eksekutif.'
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
      const session = await loginAdminJWT({ email, password, role });
      onLoginSuccess(session);
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : 'Gagal masuk ke portal eksekutif.'
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
            Sistem Kendali Ekosistem Wisata Pintar Rancak.in
          </h1>
          <p className="mt-4 text-sm lg:text-base text-[#E4E9DA]/90 leading-relaxed">
            Portal manajemen terpadu untuk pengelolaan direktori destinasi
            unggulan, pemetaan 5 indikator kesiapan medan lapangan, penetapan
            standar tarif resmi Perda, Plang Smart QR, serta pengawasan Satgas
            Saber Pungli di 19 Kabupaten/Kota Sumatera Barat.
          </p>
        </div>

        <div className="my-8 space-y-3.5">
          <div className="p-4 rounded-2xl bg-black/20 border border-white/10">
            <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-[#A7F3D0]">
              <ShieldCheck className="w-4 h-4 text-[#1E9E5A]" aria-hidden="true" />
              <span>Tata Kelola Terintegrasi 19 Kabupaten/Kota</span>
            </div>
            <p className="mt-1.5 text-xs text-[#E4E9DA]/90 leading-relaxed">
              Seluruh perubahan informasi kesiapan medan, regulasi tarif resmi
              Perda/Nagari, dan pengumuman kawasan blank spot tersinkronisasi
              langsung dengan layanan informasi wisatawan dan Plang Smart QR di
              lapangan.
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
          &copy; 2026 Dinas Pariwisata Provinsi Sumatera Barat · Portal
          Administrasi Resmi Rancak.in
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
                Otentikasi Pejabat &amp; Operator
              </h2>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Masuk menggunakan akun kedinasan resmi Pemerintah Provinsi
                Sumatera Barat
              </p>
            </div>
          </div>

          {/* Akses Cepat Otoritas */}
          <div className="mb-6 p-4 rounded-2xl bg-[#E4E9DA]/65 border border-[#CFD8BE]">
            <div className="flex items-center gap-2 text-xs font-bold text-[#234B24] mb-2.5">
              <UserCheck className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>Akses Cepat Otoritas (Mode Pengujian Internal)</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              <button
                type="button"
                onClick={() =>
                  handleQuickAuthorityAccess(
                    'kadispar@sumbarprov.go.id',
                    'RancakMinang2026',
                    'admin_dispar'
                  )
                }
                className="min-h-[44px] text-xs font-bold px-3.5 py-2 rounded-xl bg-[#234B24] text-[#F6F3EC] hover:bg-[#1B3B1C] transition shadow-sm text-center"
              >
                Masuk sebagai Kadispar Sumbar
              </button>
              <button
                type="button"
                onClick={() =>
                  handleQuickAuthorityAccess(
                    'satgas.pungli@sumbarprov.go.id',
                    'SaberPungli2026',
                    'satgas_pungli'
                  )
                }
                className="min-h-[44px] text-xs font-bold px-3.5 py-2 rounded-xl bg-[#F26B4B] text-white hover:bg-[#D95637] transition shadow-sm text-center"
              >
                Masuk sebagai Satgas Saber Pungli
              </button>
            </div>
          </div>

          <form
            method="post"
            action="/api/v1/auth/admin-login"
            aria-labelledby="login-heading"
            onSubmit={handleSubmit}
            noValidate
          >
            {/* Pilihan Unit Otoritas */}
            <fieldset className="mb-5 p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
              <legend className="text-xs font-bold text-[#1B1F1A] px-1.5">
                Unit Kerja / Otoritas Penugasan <span aria-hidden="true">*</span>
              </legend>
              <div className="mt-2 grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="flex items-center gap-2.5">
                  <input
                    type="radio"
                    id="role-dispar"
                    name="role"
                    value="admin_dispar"
                    checked={role === 'admin_dispar'}
                    onChange={() => setRole('admin_dispar')}
                    className="w-4 h-4 accent-[#234B24]"
                  />
                  <label
                    htmlFor="role-dispar"
                    className="text-xs font-semibold text-[#1B1F1A] cursor-pointer"
                  >
                    Dinas Pariwisata Prov. Sumbar
                  </label>
                </div>
                <div className="flex items-center gap-2.5">
                  <input
                    type="radio"
                    id="role-satgas"
                    name="role"
                    value="satgas_pungli"
                    checked={role === 'satgas_pungli'}
                    onChange={() => setRole('satgas_pungli')}
                    className="w-4 h-4 accent-[#234B24]"
                  />
                  <label
                    htmlFor="role-satgas"
                    className="text-xs font-semibold text-[#1B1F1A] cursor-pointer"
                  >
                    Satgas Saber Pungli Pariwisata
                  </label>
                </div>
              </div>
            </fieldset>

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
                Gunakan email resmi berdomain @sumbarprov.go.id
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
                onInput={() => setPasswordTouched(true)}
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
                Minimal 6 karakter. Sesi diamankan dengan enkripsi Bearer Token.
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
                  ? 'Memverifikasi Kredensial Otoritas...'
                  : 'Masuk ke Portal Eksekutif Dispar'}
              </span>
            </button>
          </form>
        </div>
      </main>
    </div>
  );
};
