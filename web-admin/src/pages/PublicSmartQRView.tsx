import React, { useState, useId } from 'react';
import {
  ShieldAlert,
  LifeBuoy,
  Compass,
  MapPin,
  CheckCircle2,
  AlertTriangle,
  QrCode,
  Building2,
  ChevronLeft,
  Send,
  Battery,
  Wifi,
  Phone,
  FileText,
  DollarSign,
  AlertCircle,
  ExternalLink,
  Info,
} from 'lucide-react';
import {
  Destination,
  PungliCategoryType,
  PungliReport,
  SosEmergencyTicket,
} from '../types/contract';
import { submitPungliReport, submitSosEmergency } from '../services/api';
import { ImageDropzone } from '../components/ImageDropzone';

interface PublicSmartQRViewProps {
  destination: Destination;
  onBackToAdmin?: () => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const PublicSmartQRView: React.FC<PublicSmartQRViewProps> = ({
  destination,
  onBackToAdmin,
  showToast,
}) => {
  const reporterNameId = useId();
  const reporterPhoneId = useId();
  const reporterCatId = useId();
  const reporterAmountId = useId();
  const reporterDescId = useId();

  const sosNameId = useId();
  const sosPhoneId = useId();
  const sosNotesId = useId();

  // Tab on Mobile Web View
  const [activeSection, setActiveSection] = useState<'tariffs' | 'medan' | 'report' | 'sos'>(
    'tariffs'
  );

  // Form Lapor Pungli State
  const [reportName, setReportName] = useState('');
  const [reportPhone, setReportPhone] = useState('');
  const [reportCategory, setReportCategory] = useState<PungliCategoryType>('Parkir Liar');
  const [reportAmount, setReportAmount] = useState<number>(20000);
  const [reportDesc, setReportDesc] = useState('');
  const [reportPhoto, setReportPhoto] = useState<string>('');
  const [submittingReport, setSubmittingReport] = useState(false);
  const [reportSuccess, setReportSuccess] = useState(false);

  // Form SOS State
  const [sosName, setSosName] = useState('');
  const [sosPhone, setSosPhone] = useState('');
  const [sosNotes, setSosNotes] = useState('');
  const [submittingSos, setSubmittingSos] = useState(false);
  const [sosSuccess, setSosSuccess] = useState(false);

  // Submit Pungli Report
  const handleSubmitReport = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reportName.trim() || !reportPhone.trim()) {
      showToast('Nama dan nomor kontak WhatsApp wajib diisi.', 'warning');
      return;
    }

    setSubmittingReport(true);
    try {
      // Find official amount matching the category if possible
      const matchedTariff = destination.tariffs?.find((t) =>
        t.category?.toLowerCase().includes(reportCategory.toLowerCase().slice(0, 4))
      );
      const officialAmt = matchedTariff ? matchedTariff.price : 5000;

      await submitPungliReport({
        destination_id: destination.id,
        destination_name: destination.name,
        kab_kota: destination.city_regency,
        reporter_name: reportName.trim(),
        reporter_phone: reportPhone.trim(),
        category: reportCategory,
        reported_amount: reportAmount,
        official_amount: officialAmt,
        description: reportDesc.trim() || 'Laporan pungutan tidak sesuai Perda di lokasi destinasi.',
        photo_url:
          reportPhoto ||
          'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=600&q=80',
        lat: destination.latitude,
        lng: destination.longitude,
        status: 'Laporan Baru',
      });

      setReportSuccess(true);
      showToast(
        'Laporan aduan berhasil dikirim langsung ke Pusat Komando Saber Pungli.',
        'success'
      );
    } catch {
      showToast('Gagal mengirim aduan.', 'error');
    } finally {
      setSubmittingReport(false);
    }
  };

  // Submit SOS Emergency Signal
  const handleSubmitSos = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!sosName.trim() || !sosPhone.trim()) {
      showToast('Nama dan nomor darurat wajib diisi.', 'warning');
      return;
    }

    setSubmittingSos(true);
    try {
      await submitSosEmergency({
        tourist_name: sosName.trim(),
        tourist_phone: sosPhone.trim(),
        destination_name: destination.name,
        kab_kota: destination.city_regency,
        lat: destination.latitude,
        lng: destination.longitude,
        battery_level: 45,
        signal_status: destination.is_blank_spot
          ? 'Satelit Mesh (Zero-Signal Seluler)'
          : '4G Aktif',
        medical_notes:
          sosNotes.trim() || 'Sinyal darurat aktif dari wisatawan di lokasi destinasi.',
        status: 'Sinyal SOS Masuk',
      });

      setSosSuccess(true);
      showToast(
        'Sinyal Darurat SOS GPS berhasil dikirim ke Pusat Komando & Siaga SAR!',
        'success'
      );
    } catch {
      showToast('Gagal mengirim sinyal darurat SOS.', 'error');
    } finally {
      setSubmittingSos(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F6F3EC] text-[#1B1F1A] flex flex-col items-center justify-start pb-12">
      {/* Top Banner Navigation (For Admin Preview Mode) */}
      {onBackToAdmin && (
        <div className="w-full bg-[#234B24] text-[#F6F3EC] px-4 py-2.5 flex items-center justify-between shadow-sm sticky top-0 z-40">
          <button
            type="button"
            onClick={onBackToAdmin}
            className="flex items-center gap-1.5 text-xs font-bold text-[#A7F3D0] hover:text-white"
          >
            <ChevronLeft className="w-4 h-4" aria-hidden="true" />
            <span>Kembali ke Pusat Komando Admin</span>
          </button>
          <span className="text-[11px] font-mono text-[#E4E9DA]/80">
            Pratinjau Web Publik Smart QR: /qr/{destination.slug || 'destinasi'}
          </span>
        </div>
      )}

      {/* Mobile-First Frame Container */}
      <main className="w-full max-w-md bg-white shadow-xl min-h-screen border-x border-[#E4E9DA] flex flex-col">
        {/* Header Plang Smart QR Resmi */}
        <header className="bg-[#234B24] text-[#F6F3EC] p-5 relative overflow-hidden">
          <div className="flex items-center justify-between mb-3">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 border border-white/15 text-[10px] font-bold text-[#A7F3D0]">
              <Building2 className="w-3 h-3 text-[#1E9E5A]" aria-hidden="true" />
              <span>PEMPROV SUMATERA BARAT</span>
            </div>
            <span className="text-[10px] font-mono text-[#E4E9DA]/80 flex items-center gap-1">
              <QrCode className="w-3.5 h-3.5 text-[#F26B4B]" aria-hidden="true" />
              <span>Plang Smart QR Terverifikasi</span>
            </span>
          </div>

          <h1 className="text-xl font-extrabold leading-tight tracking-tight">
            {destination.name}
          </h1>
          <p className="text-xs text-[#E4E9DA]/90 flex items-center gap-1 mt-1">
            <MapPin className="w-3.5 h-3.5 text-[#F26B4B] shrink-0" aria-hidden="true" />
            <span>{destination.city_regency} · {destination.category}</span>
          </p>

          {/* Barometer Badges */}
          <div className="mt-4 flex items-center gap-2">
            <span className="px-2.5 py-1 rounded-lg bg-black/20 text-[11px] font-bold text-white border border-white/10">
              Tiket: {destination.ticket_price_summary || 'Resmi Perda'}
            </span>
            {destination.is_blank_spot && (
              <span className="px-2.5 py-1 rounded-lg bg-[#F26B4B] text-[11px] font-bold text-white shadow-xs">
                Kawasan Blank Spot
              </span>
            )}
          </div>
        </header>

        {/* Gambar Destinasi */}
        <div className="w-full aspect-[16/9] bg-black/10 overflow-hidden relative">
          <img
            src={destination.cover_image}
            alt={destination.name}
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent flex items-end p-4">
            <p className="text-xs text-white/95 line-clamp-2 leading-relaxed">
              {destination.description}
            </p>
          </div>
        </div>

        {/* Tab Navigasi Publik */}
        <nav
          aria-label="Navigasi Halaman Smart QR"
          className="grid grid-cols-4 bg-[#F6F3EC] border-b border-[#CFD8BE] text-xs font-bold text-center"
        >
          <button
            type="button"
            onClick={() => setActiveSection('tariffs')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'tariffs'
                ? 'border-[#234B24] text-[#234B24] bg-white font-extrabold'
                : 'border-transparent text-[#4A5248] hover:text-[#1B1F1A]'
            }`}
          >
            Tarif Perda
          </button>
          <button
            type="button"
            onClick={() => setActiveSection('medan')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'medan'
                ? 'border-[#234B24] text-[#234B24] bg-white font-extrabold'
                : 'border-transparent text-[#4A5248] hover:text-[#1B1F1A]'
            }`}
          >
            Medan
          </button>
          <button
            type="button"
            onClick={() => setActiveSection('report')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'report'
                ? 'border-[#F26B4B] text-[#D95637] bg-white font-extrabold'
                : 'border-transparent text-[#4A5248] hover:text-[#1B1F1A]'
            }`}
          >
            Lapor Pungli
          </button>
          <button
            type="button"
            onClick={() => setActiveSection('sos')}
            className={`py-3 transition border-b-2 ${
              activeSection === 'sos'
                ? 'border-[#D95637] text-[#D95637] bg-[#F26B4B]/10 font-extrabold'
                : 'border-transparent text-[#D95637] hover:text-black'
            }`}
          >
            SOS SAR
          </button>
        </nav>

        {/* Konten Tab */}
        <div className="p-5 flex-1 space-y-5">
          {/* TAB 1: STANDAR TARIF RESMI PERDA */}
          {activeSection === 'tariffs' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-1.5">
                  <DollarSign className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                  <span>Fair-Price Barometer (Standar Tarif Perda)</span>
                </h2>
              </div>
              <p className="text-[11px] text-[#4A5248] leading-relaxed">
                Ketahui tarif resmi berlandaskan Peraturan Daerah / SK Nagari. Jangan membayar melebihi rentang harga wajar di bawah ini.
              </p>

              <div className="space-y-2.5">
                {destination.tariffs && destination.tariffs.length > 0 ? (
                  destination.tariffs.map((t) => (
                    <div
                      key={t.id}
                      className="p-3.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-start justify-between gap-2"
                    >
                      <div>
                        <div className="text-[10px] font-bold text-[#234B24] uppercase tracking-wider">
                          {t.category}
                        </div>
                        <div className="text-xs font-extrabold text-[#1B1F1A] mt-0.5">
                          {t.item_name}
                        </div>
                        <div className="text-[10px] text-[#767676] mt-0.5">
                          {t.regulation_ref || 'Perda Resmi Sumbar'}
                        </div>
                      </div>

                      <div className="text-right shrink-0">
                        <div className="text-xs font-extrabold text-[#234B24]">
                          Rp {t.price.toLocaleString('id-ID')}
                        </div>
                        <div className="text-[10px] text-[#4A5248]">
                          {t.unit}
                        </div>
                        {t.fair_price_max && t.fair_price_max > t.price && (
                          <div className="text-[9px] text-[#D95637] font-semibold">
                            Wajar maks: Rp {t.fair_price_max.toLocaleString('id-ID')}
                          </div>
                        )}
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="p-4 rounded-xl bg-[#F6F3EC] text-center text-xs text-[#767676]">
                    Belum ada tarif terdaftar. Area publik bebas retribusi.
                  </div>
                )}
              </div>

              {/* Edukasi Adat & Etika */}
              {destination.tips && destination.tips.length > 0 && (
                <div className="p-4 rounded-2xl bg-[#E4E9DA]/80 border border-[#CFD8BE] space-y-2">
                  <div className="text-xs font-bold text-[#234B24] flex items-center gap-1.5">
                    <Info className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                    <span>Tips Menjaga Tempat Ini (Etika &amp; Adat Minang)</span>
                  </div>
                  <ul className="text-xs text-[#1B1F1A] space-y-1.5 pl-4 list-disc">
                    {destination.tips.map((tip) => (
                      <li
                        key={tip.id}
                        className={tip.is_important ? 'font-bold text-[#D95637]' : ''}
                      >
                        {tip.content}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}

          {/* TAB 2: 5 INDIKATOR KESIAPAN MEDAN */}
          {activeSection === 'medan' && (
            <div className="space-y-4">
              <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-1.5">
                <Compass className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                <span>5 Indikator Kesiapan Medan Lapangan</span>
              </h2>
              <p className="text-[11px] text-[#4A5248]">
                Informasi objektif kondisi jalan, sinyal seluler, dan kebutuhan fisik sebelum menjelajah.
              </p>

              {destination.medan_indicator ? (
                <div className="space-y-2.5">
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">Akses Kendaraan</span>
                    <span className="font-extrabold text-[#234B24]">
                      {destination.medan_indicator.vehicle_access}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">Tingkat Trekking</span>
                    <span className="font-extrabold text-[#234B24]">
                      {destination.medan_indicator.trekking_level}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">Kualitas Sinyal Seluler</span>
                    <span
                      className={`font-extrabold ${
                        destination.is_blank_spot
                          ? 'text-[#D95637]'
                          : 'text-[#234B24]'
                      }`}
                    >
                      {destination.medan_indicator.cellular_signal}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">Fasilitas Resmi</span>
                    <span className="font-extrabold text-[#234B24]">
                      {destination.medan_indicator.facilities}
                    </span>
                  </div>
                  <div className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center justify-between text-xs">
                    <span className="font-bold text-[#4A5248]">Kebutuhan Pemandu Lokal</span>
                    <span className="font-extrabold text-[#234B24]">
                      {destination.medan_indicator.guide_need}
                    </span>
                  </div>

                  {destination.medan_indicator.readiness_notes && (
                    <div className="p-3.5 rounded-xl bg-white border border-[#CFD8BE] text-xs text-[#4A5248] italic">
                      &quot;{destination.medan_indicator.readiness_notes}&quot;
                    </div>
                  )}
                </div>
              ) : (
                <div className="p-4 rounded-xl bg-[#F6F3EC] text-xs text-[#767676] text-center">
                  Data indikator medan sedang diperbarui oleh petugas lapangan Dispar.
                </div>
              )}
            </div>
          )}

          {/* TAB 3: FORM CEPAT LAPOR PUNGLI */}
          {activeSection === 'report' && (
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-5 h-5 text-[#F26B4B]" aria-hidden="true" />
                <h2 className="text-sm font-extrabold text-[#1B1F1A]">
                  Form Cepat Lapor Pungli &amp; Pelanggaran Tarif
                </h2>
              </div>
              <p className="text-[11px] text-[#4A5248]">
                Laporkan oknum yang memungut tarif di luar ketentuan Perda. Laporan diteruskan langsung ke Satgas Saber Pungli Sumbar.
              </p>

              {reportSuccess ? (
                <div className="p-5 rounded-2xl bg-[#DCFCE7] border border-[#86EFAC] text-center space-y-2">
                  <CheckCircle2 className="w-8 h-8 text-[#16A34A] mx-auto" aria-hidden="true" />
                  <h3 className="text-sm font-extrabold text-[#166534]">
                    Laporan Anda Telah Diterima Satgas!
                  </h3>
                  <p className="text-xs text-[#166534]/90">
                    Tiket laporan telah diterbitkan dan langsung muncul di Pusat Komando Dispar &amp; Saber Pungli untuk segera diverifikasi dan ditindak.
                  </p>
                  <button
                    type="button"
                    onClick={() => {
                      setReportSuccess(false);
                      setReportDesc('');
                    }}
                    className="mt-2 min-h-[38px] px-4 py-1.5 rounded-lg bg-[#234B24] text-[#F6F3EC] text-xs font-bold"
                  >
                    Kirim Laporan Lain
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmitReport} className="space-y-3">
                  <div>
                    <label
                      htmlFor={reporterNameId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Nama Lengkap Anda <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id={reporterNameId}
                      type="text"
                      value={reportName}
                      onChange={(e) => setReportName(e.target.value)}
                      placeholder="Contoh: Rahmat Hidayat"
                      required
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A] font-medium"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor={reporterPhoneId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Nomor WhatsApp Aktif <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id={reporterPhoneId}
                      type="tel"
                      value={reportPhone}
                      onChange={(e) => setReportPhone(e.target.value)}
                      placeholder="0812xxxxxxxx"
                      required
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A] font-medium"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor={reporterCatId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Kategori Pelanggaran
                    </label>
                    <select
                      id={reporterCatId}
                      value={reportCategory}
                      onChange={(e) =>
                        setReportCategory(e.target.value as PungliCategoryType)
                      }
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                    >
                      <option value="Parkir Liar">Parkir Liar (Tanpa Karcis / Di Atas Tarif)</option>
                      <option value="Tiket Di Atas Perda">Tiket Masuk Di Atas Perda</option>
                      <option value="Pemaksaan Pemandu/Kapal">Pemaksaan Sewa Kapal / Pemandu</option>
                      <option value="Fasilitas Rusak">Fasilitas Toilet / Pos Rusak</option>
                    </select>
                  </div>

                  <div>
                    <label
                      htmlFor={reporterAmountId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Nominal yang Diminta Oknum (IDR)
                    </label>
                    <input
                      id={reporterAmountId}
                      type="number"
                      min={0}
                      step={1000}
                      value={reportAmount}
                      onChange={(e) => setReportAmount(Number(e.target.value))}
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold text-[#D95637]"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor={reporterDescId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Kronologi Kejadian &amp; Lokasi Rinci
                    </label>
                    <textarea
                      id={reporterDescId}
                      rows={3}
                      value={reportDesc}
                      onChange={(e) => setReportDesc(e.target.value)}
                      placeholder="Jelaskan titik pos, ciri-ciri oknum, atau nomor lambung kendaraan/kapal..."
                      className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A] font-medium"
                    />
                  </div>

                  <div>
                    <ImageDropzone
                      label="Unggah Bukti Foto Karcis / Lokasi (Opsional)"
                      value={reportPhoto}
                      onChange={(dataUrl) => setReportPhoto(dataUrl)}
                      onClear={() => setReportPhoto('')}
                      helperText="Ambil foto dari kamera atau pilih file galeri HP Anda. Otomatis dikompresi ringan."
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={submittingReport}
                    className="w-full h-[52px] rounded-pill bg-[#F26B4B] hover:bg-[#D95637] text-white text-xs font-bold flex items-center justify-center gap-2 shadow-md transition"
                  >
                    <Send className="w-4 h-4" aria-hidden="true" />
                    <span>
                      {submittingReport
                        ? 'Mengirim Laporan ke Saber Pungli...'
                        : 'Kirim Laporan ke Satgas Saber Pungli'}
                    </span>
                  </button>
                </form>
              )}
            </div>
          )}

          {/* TAB 4: TOMBOL DARURAT SIAGA SOS GPS */}
          {activeSection === 'sos' && (
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <LifeBuoy className="w-5 h-5 text-[#F26B4B]" aria-hidden="true" />
                <h2 className="text-sm font-extrabold text-[#D95637]">
                  Sinyal Darurat SOS GPS Wisatawan
                </h2>
              </div>
              <p className="text-[11px] text-[#4A5248]">
                Gunakan tombol darurat ini jika Anda tersesat, mengalami cedera fisik di medan berat, atau membutuhkan evakuasi darurat Tim SAR &amp; BPBD.
              </p>

              {sosSuccess ? (
                <div className="p-5 rounded-2xl bg-[#DCFCE7] border-2 border-[#16A34A] text-center space-y-2">
                  <CheckCircle2 className="w-10 h-10 text-[#16A34A] mx-auto" aria-hidden="true" />
                  <h3 className="text-sm font-extrabold text-[#166534]">
                    SINYAL SOS BERHASIL DIKIRIM!
                  </h3>
                  <p className="text-xs text-[#166534] leading-relaxed">
                    Pusat Komando Dinas Pariwisata dan Pos Basarnas wilayah terdekat telah menerima titik GPS dan telemetri Anda. Tetap berada di tempat aman.
                  </p>
                </div>
              ) : (
                <form onSubmit={handleSubmitSos} className="space-y-3.5">
                  <div className="p-3.5 rounded-xl bg-[#FEF08A]/40 border border-[#FDE047] text-xs">
                    <span className="font-bold text-[#854D0E]">
                      Titik Koordinat GPS Otomatis:{' '}
                    </span>
                    <span className="font-mono text-[#234B24] font-bold">
                      {destination.latitude}, {destination.longitude}
                    </span>
                  </div>

                  <div>
                    <label
                      htmlFor={sosNameId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Nama Wisatawan / Ketua Rombongan <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id={sosNameId}
                      type="text"
                      value={sosName}
                      onChange={(e) => setSosName(e.target.value)}
                      placeholder="Nama lengkap..."
                      required
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A] font-medium"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor={sosPhoneId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Nomor HP / WhatsApp Aktif <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id={sosPhoneId}
                      type="tel"
                      value={sosPhone}
                      onChange={(e) => setSosPhone(e.target.value)}
                      placeholder="08xxxxxxxxxx"
                      required
                      className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A] font-medium"
                    />
                  </div>

                  <div>
                    <label
                      htmlFor={sosNotesId}
                      className="block text-xs font-bold text-[#1B1F1A] mb-1"
                    >
                      Kondisi Medis / Situasi Darurat
                    </label>
                    <textarea
                      id={sosNotesId}
                      rows={2}
                      value={sosNotes}
                      onChange={(e) => setSosNotes(e.target.value)}
                      placeholder="Misal: 1 orang terkilir bebatuan, butuh tandu evakuasi..."
                      className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs text-[#1B1F1A] font-medium"
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={submittingSos}
                    className="w-full h-[52px] rounded-pill bg-[#DC2626] hover:bg-[#B91C1C] text-white text-xs font-extrabold flex items-center justify-center gap-2 shadow-lg transition animate-pulse"
                  >
                    <LifeBuoy className="w-5 h-5 text-white" aria-hidden="true" />
                    <span>
                      {submittingSos
                        ? 'Memancarkan Sinyal Darurat ke SAR...'
                        : 'PANCARKAN SINYAL DARURAT SOS GPS'}
                    </span>
                  </button>
                </form>
              )}
            </div>
          )}
        </div>

        {/* Footer Identitas Resmi */}
        <footer className="p-4 bg-[#F6F3EC] border-t border-[#CFD8BE] text-center text-[10px] text-[#4A5248]">
          <p className="font-semibold text-[#234B24]">
            Rancak.in — Dinas Pariwisata Provinsi Sumatera Barat
          </p>
          <p className="mt-0.5">
            Layanan Informasi Publik &amp; Siaga Wisatawan 19 Kab/Kota
          </p>
        </footer>
      </main>
    </div>
  );
};
