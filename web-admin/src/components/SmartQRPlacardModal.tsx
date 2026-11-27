import React, { useEffect, useMemo, useRef } from 'react';
import {
  CheckCircle2,
  CloudSun,
  MapPin,
  Printer,
  QrCode,
  Receipt,
  ShieldAlert,
  X,
} from 'lucide-react';
import { Destination } from '../types/contract';
import { toDestinationSlug } from '../data/mockDestinations';

interface SmartQRPlacardProps {
  destination: Destination;
  onClose?: () => void;
  isModal?: boolean;
}

function generateQRMatrix(seedText: string): boolean[][] {
  const size = 21;
  const matrix: boolean[][] = Array.from({ length: size }, () => Array(size).fill(false));

  const drawFinder = (rowOffset: number, colOffset: number) => {
    for (let r = 0; r < 7; r++) {
      for (let c = 0; c < 7; c++) {
        const isBorder = r === 0 || r === 6 || c === 0 || c === 6;
        const isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
        matrix[rowOffset + r][colOffset + c] = isBorder || isInner;
      }
    }
  };

  drawFinder(0, 0);
  drawFinder(0, size - 7);
  drawFinder(size - 7, 0);

  for (let i = 8; i < size - 8; i++) {
    matrix[6][i] = i % 2 === 0;
    matrix[i][6] = i % 2 === 0;
  }

  let hash = 2166136261;
  for (let i = 0; i < seedText.length; i++) {
    hash ^= seedText.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }

  for (let r = 0; r < size; r++) {
    for (let c = 0; c < size; c++) {
      const inTopLeft = r < 8 && c < 8;
      const inTopRight = r < 8 && c >= size - 8;
      const inBottomLeft = r >= size - 8 && c < 8;
      const isTiming = r === 6 || c === 6;
      if (inTopLeft || inTopRight || inBottomLeft || isTiming) continue;

      hash ^= (r * 31 + c * 17) & 0xff;
      hash = Math.imul(hash, 16777619);
      matrix[r][c] = Math.abs(hash) % 10 < 5;
    }
  }

  return matrix;
}

export const SmartQRPlacardView: React.FC<SmartQRPlacardProps> = ({
  destination,
  onClose,
  isModal = false,
}) => {
  const slug = destination.slug || toDestinationSlug(destination.name);
  const qrPath = `/qr/${slug}`;
  const qrMatrix = useMemo(() => generateQRMatrix(qrPath), [qrPath]);

  const formatRupiah = (amount: number) => {
    if (amount === 0) return 'Gratis (Rp 0)';
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const tariffs = destination.tariffs || [];

  return (
    <div
      id="smart-qr-placard-print"
      className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border-2 border-[#234B24] shadow-lg overflow-hidden"
    >
      <div className="no-print bg-[#1B1F1A] text-[#F6F3EC] px-6 py-4 flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2.5">
          <QrCode className="w-5 h-5 text-[#1E9E5A]" aria-hidden="true" />
          <div>
            <span className="text-xs font-extrabold uppercase tracking-wider text-[#A7F3D0]">
              Pratinjau Plang Fisik Resmi WISGO Sumbar
            </span>
            <p className="text-xs text-[#E4E9DA]/80">
              Siap cetak untuk dipasang di loket tiket, gerbang kawasan, dan kantong parkir resmi
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            type="button"
            onClick={() => window.print()}
            className="min-h-[44px] px-5 py-2 rounded-pill bg-[#1E9E5A] hover:bg-[#178248] text-white font-bold text-xs inline-flex items-center gap-2 shadow-sm transition"
          >
            <Printer className="w-4 h-4" aria-hidden="true" />
            <span>Cetak Plang QR (PDF/Print)</span>
          </button>

          {isModal && onClose && (
            <button
              type="button"
              onClick={onClose}
              aria-label="Tutup pratinjau plang QR"
              className="w-10 h-10 rounded-full bg-white/10 hover:bg-[#F26B4B] text-white flex items-center justify-center transition"
            >
              <X className="w-5 h-5" aria-hidden="true" />
            </button>
          )}
        </div>
      </div>

      <div className="bg-[#234B24] text-[#F6F3EC] p-6 lg:p-8 border-b-4 border-[#F26B4B]">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 text-[#A7F3D0] text-[11px] font-extrabold uppercase tracking-wider">
              <CheckCircle2 className="w-3.5 h-3.5 text-[#1E9E5A]" aria-hidden="true" />
              <span>PEMERINTAH PROVINSI SUMATERA BARAT · DINAS PARIWISATA</span>
            </div>
            <h2 className="mt-2.5 text-2xl lg:text-3xl font-extrabold tracking-tight text-[#F6F3EC]">
              {destination.name}
            </h2>
            <div className="mt-1.5 flex flex-wrap items-center gap-3 text-xs text-[#E4E9DA]">
              <span className="inline-flex items-center gap-1 font-bold">
                <MapPin className="w-3.5 h-3.5 text-[#F26B4B]" aria-hidden="true" />
                {destination.city_regency}
              </span>
              <span>•</span>
              <span>Kategori: {destination.category}</span>
              <span>•</span>
              <span>
                GPS: {destination.latitude.toFixed(4)}, {destination.longitude.toFixed(4)}
              </span>
            </div>
          </div>

          <div className="text-left md:text-right shrink-0">
            <div className="inline-block px-4 py-2 rounded-2xl bg-black/25 border border-white/15">
              <div className="text-[10px] font-bold uppercase tracking-widest text-[#E4E9DA]/80">
                Kode Plang Resmi
              </div>
              <div className="text-base font-extrabold text-white font-mono">
                {destination.qr_placard_code || destination.id.toUpperCase()}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="p-6 lg:p-8 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <div className="lg:col-span-4 bg-white p-6 rounded-3xl border-2 border-[#234B24]/20 flex flex-col items-center text-center shadow-sm">
          <div className="text-xs font-extrabold uppercase tracking-wider text-[#234B24] mb-3">
            Pindai Untuk Tarif Perda, Peta Rute &amp; Lapor Pungli
          </div>

          <div className="p-4 bg-white rounded-2xl border-2 border-[#1B1F1A] shadow-inner">
            <svg
              viewBox="0 0 21 21"
              className="w-44 h-44"
              role="img"
              aria-label={`Kode Smart QR untuk ${destination.name} (${qrPath})`}
            >
              <rect width="21" height="21" fill="#FFFFFF" />
              {qrMatrix.map((row, rIdx) =>
                row.map((cell, cIdx) =>
                  cell ? (
                    <rect
                      key={`${rIdx}-${cIdx}`}
                      x={cIdx}
                      y={rIdx}
                      width={1}
                      height={1}
                      fill="#1B1F1A"
                    />
                  ) : null
                )
              )}
            </svg>
          </div>

          <div className="mt-3 px-3.5 py-1.5 rounded-full bg-[#E4E9DA] text-[#234B24] font-mono text-xs font-extrabold">
            wisgo.sumbarprov.go.id{qrPath}
          </div>

          <p className="mt-2.5 text-[11px] text-[#4A5248] leading-relaxed">
            Terbuka instan di browser wisatawan untuk cek tarif resmi Perda, 4 indikator medan, cuaca live, dan check-in Paspor Digital Minang.
          </p>

          {destination.weather && (
            <div className="mt-4 w-full p-3 rounded-2xl bg-sky-50 border border-sky-200 text-xs font-bold text-sky-900 flex items-center justify-center gap-1.5">
              <CloudSun className="w-4 h-4 shrink-0 text-sky-700" aria-hidden="true" />
              <span>
                Cuaca Open-Meteo: {destination.weather.temperature_c}°C · {destination.weather.condition}
              </span>
            </div>
          )}
        </div>

        <div className="lg:col-span-8 space-y-5">
          <div className="bg-white rounded-3xl border border-[#CFD8BE] overflow-hidden shadow-sm">
            <div className="bg-[#E4E9DA] px-5 py-3.5 border-b border-[#CFD8BE] flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Receipt className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                <h3 className="text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
                  Daftar Tarif Resmi Perda / Nagari (Fair-Price Barometer)
                </h3>
              </div>
              <span className="text-[11px] font-bold text-[#1E9E5A]">Terverifikasi Dispar Sumbar</span>
            </div>

            <div className="p-4 overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="border-b border-[#234B24]/10 text-[#4A5248] uppercase">
                    <th className="py-2.5 px-3 font-bold">Komponen Layanan</th>
                    <th className="py-2.5 px-3 font-bold">Kategori</th>
                    <th className="py-2.5 px-3 font-bold">Tarif Resmi</th>
                    <th className="py-2.5 px-3 font-bold">Batas Harga Wajar</th>
                    <th className="py-2.5 px-3 font-bold">Dasar Regulasi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E4E9DA]">
                  {tariffs.length > 0 ? (
                    tariffs.map((trf) => (
                      <tr key={trf.id}>
                        <td className="py-3 px-3 font-bold text-[#1B1F1A]">{trf.item_name}</td>
                        <td className="py-3 px-3 text-[#4A5248]">{trf.category || 'Tiket Masuk'}</td>
                        <td className="py-3 px-3 font-extrabold text-[#234B24]">
                          {formatRupiah(trf.price)}{' '}
                          <span className="font-normal text-[#4A5248]">({trf.unit})</span>
                        </td>
                        <td className="py-3 px-3 font-semibold text-[#1B1F1A]">
                          {trf.fair_price_min !== undefined && trf.fair_price_max !== undefined
                            ? `${formatRupiah(trf.fair_price_min)} – ${formatRupiah(trf.fair_price_max)}`
                            : formatRupiah(trf.price)}
                        </td>
                        <td className="py-3 px-3 text-[#4A5248] font-medium">
                          {trf.regulation_ref}
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={5} className="py-4 px-3 text-center text-[#4A5248]">
                        Belum ada rincian tarif terdaftar untuk destinasi ini.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* 4 Indikator Medan di Plang */}
          {destination.medan_indicator && (
            <div className="bg-white p-4 rounded-2xl border border-[#CFD8BE] grid grid-cols-2 sm:grid-cols-4 gap-2.5 text-center">
              <div className="p-2.5 rounded-xl bg-[#F6F3EC]">
                <div className="text-[10px] font-bold uppercase text-[#4A5248]">Kendaraan</div>
                <div className="text-xs font-extrabold text-[#1B1F1A] mt-0.5">
                  {destination.medan_indicator.vehicle_access}
                </div>
              </div>
              <div className="p-2.5 rounded-xl bg-[#F6F3EC]">
                <div className="text-[10px] font-bold uppercase text-[#4A5248]">Trekking</div>
                <div className="text-xs font-extrabold text-[#1B1F1A] mt-0.5">
                  {destination.medan_indicator.trekking_level}
                </div>
              </div>
              <div className="p-2.5 rounded-xl bg-[#F6F3EC]">
                <div className="text-[10px] font-bold uppercase text-[#4A5248]">Fasilitas</div>
                <div className="text-xs font-extrabold text-[#1B1F1A] mt-0.5">
                  {destination.medan_indicator.facilities}
                </div>
              </div>
              <div className="p-2.5 rounded-xl bg-[#F6F3EC]">
                <div className="text-[10px] font-bold uppercase text-[#4A5248]">Pemandu</div>
                <div className="text-xs font-extrabold text-[#1B1F1A] mt-0.5">
                  {destination.medan_indicator.guide_need}
                </div>
              </div>
            </div>
          )}

          <div className="p-5 rounded-3xl bg-[#F26B4B]/15 border-2 border-[#F26B4B] flex items-start gap-3.5">
            <div className="w-10 h-10 rounded-2xl bg-[#F26B4B] text-white flex items-center justify-center shrink-0">
              <ShieldAlert className="w-5 h-5" aria-hidden="true" />
            </div>
            <div>
              <h4 className="text-xs font-extrabold uppercase tracking-wider text-[#D95637]">
                Peringatan Resmi Satgas Saber Pungli Provinsi Sumatera Barat
              </h4>
              <p className="mt-1 text-xs text-[#1B1F1A] leading-relaxed font-medium">
                Dilarang keras meminta atau memungut biaya di luar ketentuan Peraturan Daerah / Peraturan Nagari yang tertera pada plang ini. Segala bentuk pungutan liar diancam pidana sesuai Pasal 368 KUHP dan UU No. 20 Tahun 2001. Wisatawan dapat melapor secara anonim (foto karcis &amp; GPS) dengan memindai Kode QR.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export const SmartQRPlacardModal: React.FC<{
  destination: Destination | null;
  onClose: () => void;
}> = ({ destination, onClose }) => {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (destination && !dialog.open) dialog.showModal();
    else if (!destination && dialog.open) dialog.close();
  }, [destination]);

  if (!destination) return null;

  return (
    <dialog
      ref={dialogRef}
      aria-label={`Pratinjau Plang Smart QR ${destination.name}`}
      onClose={onClose}
      className="w-full max-w-5xl rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
    >
      <SmartQRPlacardView destination={destination} onClose={onClose} isModal={true} />
    </dialog>
  );
};
