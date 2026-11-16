import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Receipt,
  QrCode,
  Plus,
  Edit3,
  Trash2,
  MapPin,
  ShieldCheck,
  CheckCircle2,
  Printer,
  X,
} from 'lucide-react';
import {
  Destination,
  OfficialTariff,
  TariffCategoryType,
} from '../types/contract';
import {
  TARIFF_CATEGORIES,
  toDestinationSlug,
} from '../data/mockDestinations';
import { SmartQRPlacardView } from '../components/SmartQRPlacardModal';

interface TariffsAndQRPageProps {
  destinations: Destination[];
  selectedDestinationId: string;
  onSelectDestinationId: (id: string) => void;
  onSaveDestination: (updated: Destination, toastMsg: string) => void;
}

const UNIT_OPTIONS = [
  'per orang',
  'per kendaraan',
  'per unit',
  'per jam',
  'per kapal',
  'per malam',
  'per putaran',
  'per rombongan',
  'per set',
  'per kunjungan',
] as const;

export const TariffsAndQRPage: React.FC<TariffsAndQRPageProps> = ({
  destinations,
  selectedDestinationId,
  onSelectDestinationId,
  onSaveDestination,
}) => {
  const activeDestination = useMemo(() => {
    return (
      destinations.find((d) => d.id === selectedDestinationId) ||
      destinations[0]
    );
  }, [destinations, selectedDestinationId]);

  const [editingTariff, setEditingTariff] = useState<OfficialTariff | null>(
    null
  );
  const [isNewTariff, setIsNewTariff] = useState(false);
  const [tariffToDelete, setTariffToDelete] = useState<OfficialTariff | null>(
    null
  );

  const editDialogRef = useRef<HTMLDialogElement>(null);
  const deleteDialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = editDialogRef.current;
    if (!dialog) return;
    if (editingTariff && !dialog.open) {
      dialog.showModal();
    } else if (!editingTariff && dialog.open) {
      dialog.close();
    }
  }, [editingTariff]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (tariffToDelete && !dialog.open) {
      dialog.showModal();
    } else if (!tariffToDelete && dialog.open) {
      dialog.close();
    }
  }, [tariffToDelete]);

  if (!activeDestination) {
    return (
      <div className="p-8">
        <p className="text-sm text-[#4A5248]">
          Belum ada destinasi yang terdaftar.
        </p>
      </div>
    );
  }

  const tariffs = activeDestination.tariffs || [];

  const formatRupiah = (amount: number) => {
    if (amount === 0) return 'Gratis (Rp 0)';
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const handleOpenAddTariff = () => {
    const nextIdx = tariffs.length + 1;
    setIsNewTariff(true);
    setEditingTariff({
      id: `trf-${activeDestination.id}-${Date.now()}-${nextIdx}`,
      destination_id: activeDestination.id,
      item_name: '',
      category: 'Tiket Masuk',
      price: 15000,
      fair_price_min: 15000,
      fair_price_max: 20000,
      unit: 'per orang',
      regulation_ref:
        tariffs[0]?.regulation_ref ||
        `Perda ${activeDestination.city_regency} Tahun 2024`,
    });
  };

  const handleOpenEditTariff = (trf: OfficialTariff) => {
    setIsNewTariff(false);
    setEditingTariff({
      ...trf,
      category: trf.category || 'Tiket Masuk',
      fair_price_min: trf.fair_price_min ?? trf.price,
      fair_price_max: trf.fair_price_max ?? trf.price,
    });
  };

  const handleSaveTariffSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingTariff) return;

    const updatedTariffs = isNewTariff
      ? [...tariffs, editingTariff]
      : tariffs.map((t) => (t.id === editingTariff.id ? editingTariff : t));

    const primaryTicket = updatedTariffs[0];
    const ticketSummary = primaryTicket
      ? `${formatRupiah(primaryTicket.price)} / ${primaryTicket.unit.replace(
          'per ',
          ''
        )}`
      : activeDestination.ticket_price_summary;

    const updatedDestination: Destination = {
      ...activeDestination,
      tariffs: updatedTariffs,
      ticket_price_summary: ticketSummary,
      updated_at: new Date().toISOString(),
    };

    onSaveDestination(
      updatedDestination,
      isNewTariff
        ? `Komponen tarif "${editingTariff.item_name}" berhasil ditambahkan ke ${activeDestination.name}.`
        : `Komponen tarif "${editingTariff.item_name}" berhasil diperbarui.`
    );
    setEditingTariff(null);
  };

  const handleConfirmDeleteTariff = () => {
    if (!tariffToDelete) return;
    const updatedTariffs = tariffs.filter((t) => t.id !== tariffToDelete.id);
    const updatedDestination: Destination = {
      ...activeDestination,
      tariffs: updatedTariffs,
      updated_at: new Date().toISOString(),
    };
    onSaveDestination(
      updatedDestination,
      `Komponen tarif "${tariffToDelete.item_name}" telah dihapus dari daftar resmi.`
    );
    setTariffToDelete(null);
  };

  const slug =
    activeDestination.slug || toDestinationSlug(activeDestination.name);

  return (
    <div className="p-6 lg:p-8 space-y-8">
      {/* Header Halaman */}
      <header className="no-print flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24] text-xs font-bold">
            <ShieldCheck
              className="w-3.5 h-3.5 text-[#1E9E5A]"
              aria-hidden="true"
            />
            <span>STANDAR TARIF RESMI PERDA &amp; PLANG SMART QR</span>
          </div>
          <h1 className="mt-2 text-2xl lg:text-3xl font-extrabold text-[#1B1F1A]">
            Pengelolaan Fair-Price Barometer &amp; Plang QR Kawasan
          </h1>
          <p className="text-sm text-[#4A5248] mt-0.5">
            Tetapkan standar tarif resmi Peraturan Daerah / Nagari, batas harga
            wajar, dan cetak plang fisik Smart QR anti-pungli.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <button
            type="button"
            onClick={() => window.print()}
            className="min-h-[48px] px-5 py-2.5 rounded-pill bg-white border border-[#CFD8BE] hover:bg-[#E4E9DA]/60 text-[#1B1F1A] font-bold text-xs inline-flex items-center gap-2 transition shadow-sm"
          >
            <Printer className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
            <span>Cetak Plang QR Destinasi Ini</span>
          </button>

          <button
            type="button"
            onClick={handleOpenAddTariff}
            className="h-[52px] px-6 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-sm inline-flex items-center gap-2 shadow-sm transition"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
            <span>Tambah Komponen Tarif Resmi</span>
          </button>
        </div>
      </header>

      {/* Pemilih Destinasi & Ringkasan Identitas QR */}
      <section
        aria-label="Pemilih Destinasi Pengelolaan Tarif"
        className="no-print bg-white p-6 rounded-3xl border border-[#E4E9DA] shadow-sm grid grid-cols-1 lg:grid-cols-12 gap-6 items-center"
      >
        <div className="lg:col-span-6 flex flex-col gap-1.5">
          <label
            htmlFor="select-tariff-destination"
            className="text-xs font-extrabold uppercase tracking-wider text-[#234B24]"
          >
            Pilih Destinasi Wisata Sumatera Barat
          </label>
          <select
            id="select-tariff-destination"
            value={activeDestination.id}
            onChange={(e) => onSelectDestinationId(e.target.value)}
            className="w-full min-h-[50px] px-4 py-2.5 rounded-2xl bg-[#F6F3EC] border border-[#767676] text-base font-bold text-[#1B1F1A]"
          >
            {destinations.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name} — {d.city_regency} ({d.tariffs?.length || 0} item
                tarif)
              </option>
            ))}
          </select>
        </div>

        <div className="lg:col-span-6 flex flex-wrap items-center justify-between gap-4 p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
          <div className="flex items-center gap-3">
            <img
              src={activeDestination.cover_image}
              alt=""
              className="w-14 h-14 rounded-2xl object-cover bg-[#E4E9DA] shrink-0"
            />
            <div>
              <div className="flex items-center gap-1.5 text-xs font-bold text-[#234B24]">
                <MapPin
                  className="w-3.5 h-3.5 text-[#F26B4B]"
                  aria-hidden="true"
                />
                <span>{activeDestination.city_regency}</span>
              </div>
              <div className="text-base font-extrabold text-[#1B1F1A]">
                {activeDestination.name}
              </div>
              <div className="text-xs text-[#4A5248] font-mono">
                Tautan Plang QR: <strong>/qr/{slug}</strong>
              </div>
            </div>
          </div>

          <div className="text-right">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A] text-xs font-bold">
              <CheckCircle2 className="w-3.5 h-3.5" aria-hidden="true" />
              {tariffs.length} Komponen Tarif Aktif
            </span>
          </div>
        </div>
      </section>

      {/* Tabel CRUD Tarif Resmi Perda / Fair-Price Barometer */}
      <section
        aria-labelledby="tariff-table-heading"
        className="no-print bg-white rounded-3xl border border-[#E4E9DA] shadow-sm overflow-hidden"
      >
        <div className="px-6 py-4 bg-[#234B24] text-[#F6F3EC] flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <Receipt className="w-5 h-5 text-[#F26B4B]" aria-hidden="true" />
            <div>
              <h2
                id="tariff-table-heading"
                className="text-sm font-extrabold uppercase tracking-wider"
              >
                Daftar Komponen Tarif Resmi &amp; Fair-Price Barometer —{' '}
                {activeDestination.name}
              </h2>
            </div>
          </div>
          <span className="text-xs text-[#E4E9DA]">
            Data otomatis ditampilkan pada Plang Smart QR &amp; aplikasi
            wisatawan
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm border-collapse">
            <thead className="bg-[#E4E9DA]/60 text-[#1B1F1A] text-xs uppercase border-b border-[#CFD8BE]">
              <tr>
                <th scope="col" className="py-3.5 px-5 font-bold">
                  Nama Komponen Layanan
                </th>
                <th scope="col" className="py-3.5 px-5 font-bold">
                  Kategori Tarif
                </th>
                <th scope="col" className="py-3.5 px-5 font-bold">
                  Harga Resmi (IDR)
                </th>
                <th scope="col" className="py-3.5 px-5 font-bold">
                  Batas Harga Wajar (Min–Max)
                </th>
                <th scope="col" className="py-3.5 px-5 font-bold">
                  Satuan
                </th>
                <th scope="col" className="py-3.5 px-5 font-bold">
                  Nomor Referensi Perda / SK Nagari
                </th>
                <th scope="col" className="py-3.5 px-5 font-bold text-right">
                  Tindakan
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA]">
              {tariffs.length > 0 ? (
                tariffs.map((trf) => (
                  <tr
                    key={trf.id}
                    className="hover:bg-[#FAF8F3] transition-colors"
                  >
                    <th
                      scope="row"
                      className="py-4 px-5 font-extrabold text-[#1B1F1A]"
                    >
                      {trf.item_name}
                    </th>
                    <td className="py-4 px-5">
                      <span className="inline-block px-3 py-1 rounded-full text-xs font-bold bg-[#F6F3EC] border border-[#CFD8BE] text-[#234B24]">
                        {trf.category || 'Tiket Masuk'}
                      </span>
                    </td>
                    <td className="py-4 px-5 font-extrabold text-[#234B24]">
                      {formatRupiah(trf.price)}
                    </td>
                    <td className="py-4 px-5 font-semibold text-[#1B1F1A]">
                      {trf.fair_price_min !== undefined &&
                      trf.fair_price_max !== undefined
                        ? `${formatRupiah(trf.fair_price_min)} – ${formatRupiah(
                            trf.fair_price_max
                          )}`
                        : formatRupiah(trf.price)}
                    </td>
                    <td className="py-4 px-5 text-xs font-semibold text-[#4A5248]">
                      {trf.unit}
                    </td>
                    <td className="py-4 px-5 text-xs font-semibold text-[#1B1F1A]">
                      {trf.regulation_ref}
                    </td>
                    <td className="py-4 px-5 text-right whitespace-nowrap">
                      <div className="inline-flex items-center gap-2">
                        <button
                          type="button"
                          onClick={() => handleOpenEditTariff(trf)}
                          className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] hover:bg-[#234B24] hover:text-white text-[#234B24] border border-[#234B24]/30 text-xs font-bold inline-flex items-center gap-1.5 transition"
                        >
                          <Edit3 className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Ubah</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => setTariffToDelete(trf)}
                          className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F26B4B]/10 hover:bg-[#F26B4B] hover:text-white text-[#D95637] border border-[#F26B4B]/30 text-xs font-bold inline-flex items-center gap-1.5 transition"
                        >
                          <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                          <span>Hapus</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td
                    colSpan={7}
                    className="py-8 px-6 text-center text-sm text-[#4A5248]"
                  >
                    Belum ada komponen tarif resmi yang terdaftar untuk
                    destinasi ini. Klik tombol{' '}
                    <strong>+ Tambah Komponen Tarif Resmi</strong> di kanan
                    atas.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* Pratinjau Plang Fisik Smart QR Siap Cetak */}
      <section aria-label="Pratinjau Plang Fisik Smart QR">
        <div className="no-print mb-3 flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
          <QrCode className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
          <span>
            Pratinjau Plang Fisik Smart QR Resmi ({activeDestination.name})
          </span>
        </div>
        <SmartQRPlacardView destination={activeDestination} isModal={false} />
      </section>

      {/* Dialog Tambah / Edit Komponen Tarif */}
      <dialog
        ref={editDialogRef}
        aria-labelledby="tariff-modal-title"
        onClose={() => setEditingTariff(null)}
        className="w-full max-w-xl rounded-[28px] p-0 bg-transparent"
      >
        {editingTariff && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] p-6 lg:p-8 rounded-[28px] border border-[#CFD8BE] shadow-xl">
            <div className="flex items-center justify-between pb-4 border-b border-[#CFD8BE]">
              <div>
                <span className="text-xs font-bold uppercase text-[#234B24]">
                  Standar Tarif Perda — {activeDestination.name}
                </span>
                <h3
                  id="tariff-modal-title"
                  className="text-xl font-extrabold text-[#1B1F1A]"
                >
                  {isNewTariff
                    ? 'Tambah Komponen Tarif Resmi'
                    : 'Perbarui Komponen Tarif Resmi'}
                </h3>
              </div>
              <button
                type="button"
                aria-label="Tutup formulir tarif"
                onClick={() => setEditingTariff(null)}
                className="w-10 h-10 rounded-full bg-white border border-[#CFD8BE] flex items-center justify-center hover:bg-[#F26B4B] hover:text-white transition"
              >
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <form onSubmit={handleSaveTariffSubmit} className="mt-5 space-y-4">
              <div className="flex flex-col gap-1">
                <label
                  htmlFor="tariff-item-name"
                  className="text-xs font-bold text-[#1B1F1A]"
                >
                  Nama Item / Komponen Layanan *
                </label>
                <input
                  id="tariff-item-name"
                  type="text"
                  required
                  autoFocus
                  placeholder="Contoh: Tiket Masuk Dewasa / Parkir Mobil Resmi / Sewa Bendi"
                  value={editingTariff.item_name}
                  onChange={(e) =>
                    setEditingTariff({
                      ...editingTariff,
                      item_name: e.target.value,
                    })
                  }
                  className="min-h-[48px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1">
                  <label
                    htmlFor="tariff-category"
                    className="text-xs font-bold text-[#1B1F1A]"
                  >
                    Kategori Komponen *
                  </label>
                  <select
                    id="tariff-category"
                    value={editingTariff.category || 'Tiket Masuk'}
                    onChange={(e) =>
                      setEditingTariff({
                        ...editingTariff,
                        category: e.target.value as TariffCategoryType,
                      })
                    }
                    className="min-h-[48px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                  >
                    {TARIFF_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-col gap-1">
                  <label
                    htmlFor="tariff-unit"
                    className="text-xs font-bold text-[#1B1F1A]"
                  >
                    Satuan Pengenaan Tarif *
                  </label>
                  <select
                    id="tariff-unit"
                    value={editingTariff.unit}
                    onChange={(e) =>
                      setEditingTariff({
                        ...editingTariff,
                        unit: e.target.value,
                      })
                    }
                    className="min-h-[48px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                  >
                    {UNIT_OPTIONS.map((u) => (
                      <option key={u} value={u}>
                        {u}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="flex flex-col gap-1">
                  <label
                    htmlFor="tariff-price"
                    className="text-xs font-bold text-[#1B1F1A]"
                  >
                    Harga Resmi (IDR) *
                  </label>
                  <input
                    id="tariff-price"
                    type="number"
                    min={0}
                    step={500}
                    required
                    value={editingTariff.price}
                    onChange={(e) => {
                      const val = Number(e.target.value);
                      setEditingTariff({
                        ...editingTariff,
                        price: val,
                      });
                    }}
                    className="min-h-[48px] px-3.5 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-extrabold text-[#234B24]"
                  />
                </div>

                <div className="flex flex-col gap-1">
                  <label
                    htmlFor="tariff-min"
                    className="text-xs font-bold text-[#1B1F1A]"
                  >
                    Batas Wajar Min (IDR)
                  </label>
                  <input
                    id="tariff-min"
                    type="number"
                    min={0}
                    step={500}
                    value={editingTariff.fair_price_min ?? editingTariff.price}
                    onChange={(e) =>
                      setEditingTariff({
                        ...editingTariff,
                        fair_price_min: Number(e.target.value),
                      })
                    }
                    className="min-h-[48px] px-3.5 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                  />
                </div>

                <div className="flex flex-col gap-1">
                  <label
                    htmlFor="tariff-max"
                    className="text-xs font-bold text-[#1B1F1A]"
                  >
                    Batas Wajar Maks (IDR)
                  </label>
                  <input
                    id="tariff-max"
                    type="number"
                    min={0}
                    step={500}
                    value={editingTariff.fair_price_max ?? editingTariff.price}
                    onChange={(e) =>
                      setEditingTariff({
                        ...editingTariff,
                        fair_price_max: Number(e.target.value),
                      })
                    }
                    className="min-h-[48px] px-3.5 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                  />
                </div>
              </div>

              <div className="flex flex-col gap-1">
                <label
                  htmlFor="tariff-reg-ref"
                  className="text-xs font-bold text-[#1B1F1A]"
                >
                  Nomor Referensi Perda / Peraturan Nagari *
                </label>
                <input
                  id="tariff-reg-ref"
                  type="text"
                  required
                  placeholder="Contoh: Perwako Bukittinggi No. 12/2024"
                  value={editingTariff.regulation_ref}
                  onChange={(e) =>
                    setEditingTariff({
                      ...editingTariff,
                      regulation_ref: e.target.value,
                    })
                  }
                  className="min-h-[48px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-medium"
                />
              </div>

              <div className="pt-4 flex items-center justify-end gap-3 border-t border-[#CFD8BE]">
                <button
                  type="button"
                  onClick={() => setEditingTariff(null)}
                  className="min-h-[48px] px-5 rounded-pill bg-white border border-[#767676] text-xs font-bold text-[#1B1F1A]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="h-[52px] px-7 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-sm font-bold shadow-sm transition"
                >
                  Simpan Komponen Tarif
                </button>
              </div>
            </form>
          </div>
        )}
      </dialog>

      {/* Dialog Konfirmasi Hapus Komponen Tarif */}
      <dialog
        ref={deleteDialogRef}
        aria-labelledby="delete-tariff-title"
        onClose={() => setTariffToDelete(null)}
        className="w-full max-w-md rounded-[28px] p-0 bg-transparent"
      >
        {tariffToDelete && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] p-6 rounded-[28px] border border-[#CFD8BE] shadow-xl">
            <h3
              id="delete-tariff-title"
              className="text-lg font-extrabold text-[#1B1F1A]"
            >
              Hapus Komponen Tarif Resmi?
            </h3>
            <p className="mt-2 text-xs text-[#4A5248] leading-relaxed">
              Anda akan menghapus komponen tarif{' '}
              <strong className="text-[#1B1F1A]">
                {tariffToDelete.item_name}
              </strong>{' '}
              ({formatRupiah(tariffToDelete.price)}) dari destinasi{' '}
              <strong>{activeDestination.name}</strong>.
            </p>
            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                type="button"
                autoFocus
                onClick={() => setTariffToDelete(null)}
                className="min-h-[44px] px-5 rounded-pill bg-white border border-[#767676] text-xs font-bold text-[#1B1F1A]"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmDeleteTariff}
                className="min-h-[44px] px-5 rounded-pill bg-[#F26B4B] hover:bg-[#D95637] text-white text-xs font-bold shadow-sm transition"
              >
                Ya, Hapus Tarif
              </button>
            </div>
          </div>
        )}
      </dialog>
    </div>
  );
};

