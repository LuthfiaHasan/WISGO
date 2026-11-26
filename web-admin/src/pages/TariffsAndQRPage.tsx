import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  CheckCircle2,
  Edit3,
  MapPin,
  Plus,
  Printer,
  QrCode,
  Receipt,
  Trash2,
  X,
} from 'lucide-react';
import { Destination, OfficialTariff, TariffCategoryType } from '../types/contract';
import {
  TARIFF_CATEGORIES,
  normalizeTariffCategory,
  tariffCategoryToId,
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
  'per paket',
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
  const activeDestination = useMemo(
    () => destinations.find((d) => d.id === selectedDestinationId) || destinations[0],
    [destinations, selectedDestinationId]
  );

  const [editingTariff, setEditingTariff] = useState<OfficialTariff | null>(null);
  const [isNewTariff, setIsNewTariff] = useState(false);
  const [tariffToDelete, setTariffToDelete] = useState<OfficialTariff | null>(null);

  const editDialogRef = useRef<HTMLDialogElement>(null);
  const deleteDialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = editDialogRef.current;
    if (!dialog) return;
    if (editingTariff && !dialog.open) dialog.showModal();
    else if (!editingTariff && dialog.open) dialog.close();
  }, [editingTariff]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (tariffToDelete && !dialog.open) dialog.showModal();
    else if (!tariffToDelete && dialog.open) dialog.close();
  }, [tariffToDelete]);

  if (!activeDestination) {
    return (
      <div className="p-8">
        <p className="text-sm text-[#4A5248]">Belum ada destinasi terdaftar.</p>
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
    setIsNewTariff(true);
    setEditingTariff({
      id: `trf-${activeDestination.id}-${Date.now()}`,
      destination_id: activeDestination.id,
      category_id: 'cat-trf-tiket',
      category: 'Tiket Masuk',
      item_name: '',
      price: 15000,
      fair_price_min: 15000,
      fair_price_max: 20000,
      unit: 'per orang',
      regulation_ref:
        tariffs[0]?.regulation_ref || `Perda ${activeDestination.city_regency} Tahun 2024`,
    });
  };

  const handleOpenEditTariff = (trf: OfficialTariff) => {
    setIsNewTariff(false);
    const cat = normalizeTariffCategory(trf.category);
    setEditingTariff({
      ...trf,
      category: cat,
      category_id: tariffCategoryToId(cat),
      fair_price_min: trf.fair_price_min ?? trf.price,
      fair_price_max: trf.fair_price_max ?? trf.price,
    });
  };

  const handleSaveTariffSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingTariff) return;

    const normalizedCat = normalizeTariffCategory(editingTariff.category);
    const cleanTariff: OfficialTariff = {
      ...editingTariff,
      category: normalizedCat,
      category_id: tariffCategoryToId(normalizedCat),
    };

    const updatedTariffs = isNewTariff
      ? [...tariffs, cleanTariff]
      : tariffs.map((t) => (t.id === cleanTariff.id ? cleanTariff : t));

    const primaryTicket = updatedTariffs[0];
    const updatedDestination: Destination = {
      ...activeDestination,
      tariffs: updatedTariffs,
      official_tariffs: updatedTariffs,
      estimated_cost: primaryTicket ? primaryTicket.price : activeDestination.estimated_cost,
      ticket_price_summary: primaryTicket
        ? `${formatRupiah(primaryTicket.price)} / ${primaryTicket.unit.replace('per ', '')}`
        : activeDestination.ticket_price_summary,
      updated_at: new Date().toISOString(),
    };

    onSaveDestination(
      updatedDestination,
      isNewTariff
        ? `Komponen tarif "${cleanTariff.item_name}" berhasil ditambahkan ke ${activeDestination.name}.`
        : `Komponen tarif "${cleanTariff.item_name}" berhasil diperbarui.`
    );
    setEditingTariff(null);
  };

  const handleConfirmDeleteTariff = () => {
    if (!tariffToDelete) return;
    const updatedTariffs = tariffs.filter((t) => t.id !== tariffToDelete.id);
    onSaveDestination(
      {
        ...activeDestination,
        tariffs: updatedTariffs,
        official_tariffs: updatedTariffs,
        updated_at: new Date().toISOString(),
      },
      `Komponen tarif "${tariffToDelete.item_name}" dihapus dari daftar resmi.`
    );
    setTariffToDelete(null);
  };

  const slug = activeDestination.slug || toDestinationSlug(activeDestination.name);

  return (
    <div className="p-6 lg:p-8 space-y-8">
      <header className="no-print flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            Tarif Resmi Perda &amp; Smart QR
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Standar tarif resmi Perda/Nagari, barometer harga wajar, dan cetak plang Smart QR anti-pungli.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          <button
            type="button"
            onClick={() => window.print()}
            className="min-h-[40px] px-3.5 py-2 rounded-xl bg-white border border-[#234B24]/15 hover:bg-[#F6F3EC] text-[#1B1F1A] font-bold text-xs inline-flex items-center gap-2"
          >
            <Printer className="w-3.5 h-3.5 text-[#234B24]" />
            <span>Cetak Plang QR</span>
          </button>
          <button
            type="button"
            onClick={handleOpenAddTariff}
            className="min-h-[40px] px-4 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs inline-flex items-center gap-2"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Tambah Tarif</span>
          </button>
        </div>
      </header>

      <section className="no-print bg-white p-6 rounded-2xl border border-[#234B24]/8 shadow-sm grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
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
                {d.name} — {d.city_regency} ({d.tariffs?.length || 0} item tarif)
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
                <MapPin className="w-3.5 h-3.5 text-[#F26B4B]" />
                <span>{activeDestination.city_regency}</span>
              </div>
              <div className="text-base font-extrabold text-[#1B1F1A]">{activeDestination.name}</div>
              <div className="text-xs text-[#4A5248] font-mono">
                Plang: <strong>{activeDestination.qr_placard_code || activeDestination.id.toUpperCase()}</strong> · /qr/{slug}
              </div>
            </div>
          </div>

          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A] text-xs font-bold">
            <CheckCircle2 className="w-3.5 h-3.5" />
            {tariffs.length} Komponen Tarif Aktif
          </span>
        </div>
      </section>

      <section className="no-print bg-white rounded-2xl border border-[#234B24]/8 shadow-sm overflow-hidden">
        <div className="px-6 py-4 bg-[#F6F3EC]/80 border-b border-[#234B24]/10 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <Receipt className="w-5 h-5 text-[#F26B4B]" />
            <h2 className="text-sm font-extrabold uppercase tracking-wider text-[#234B24]">
              Daftar Komponen Tarif Resmi &amp; Fair-Price Barometer — {activeDestination.name}
            </h2>
          </div>
          <span className="text-xs text-[#4A5248]">
            Otomatis sinkron ke Plang Smart QR &amp; aplikasi wisatawan
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm border-collapse">
            <thead className="bg-[#F6F3EC]/50 text-[#4A5248] text-xs uppercase border-b border-[#234B24]/8">
              <tr>
                <th className="py-3.5 px-5 font-bold">Nama Komponen</th>
                <th className="py-3.5 px-5 font-bold">Kategori Tarif</th>
                <th className="py-3.5 px-5 font-bold">Harga Resmi</th>
                <th className="py-3.5 px-5 font-bold">Batas Harga Wajar</th>
                <th className="py-3.5 px-5 font-bold">Satuan</th>
                <th className="py-3.5 px-5 font-bold">Referensi Perda</th>
                <th className="py-3.5 px-5 font-bold text-right">Tindakan</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA]">
              {tariffs.length > 0 ? (
                tariffs.map((trf) => (
                  <tr key={trf.id} className="hover:bg-[#FAF8F3]">
                    <th scope="row" className="py-4 px-5 font-extrabold text-[#1B1F1A]">
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
                      {trf.fair_price_min !== undefined && trf.fair_price_max !== undefined
                        ? `${formatRupiah(trf.fair_price_min)} – ${formatRupiah(trf.fair_price_max)}`
                        : formatRupiah(trf.price)}
                    </td>
                    <td className="py-4 px-5 text-xs font-semibold text-[#4A5248]">{trf.unit}</td>
                    <td className="py-4 px-5 text-xs font-semibold text-[#1B1F1A]">
                      {trf.regulation_ref}
                    </td>
                    <td className="py-4 px-5 text-right whitespace-nowrap">
                      <div className="inline-flex items-center gap-2">
                        <button
                          type="button"
                          onClick={() => handleOpenEditTariff(trf)}
                          className="min-h-[38px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] hover:bg-[#234B24] hover:text-white text-[#234B24] border border-[#234B24]/30 text-xs font-bold inline-flex items-center gap-1.5"
                        >
                          <Edit3 className="w-3.5 h-3.5" /> Ubah
                        </button>
                        <button
                          type="button"
                          onClick={() => setTariffToDelete(trf)}
                          className="min-h-[38px] px-3 py-1.5 rounded-xl bg-[#F26B4B]/10 hover:bg-[#F26B4B] hover:text-white text-[#D95637] border border-[#F26B4B]/30 text-xs font-bold inline-flex items-center gap-1.5"
                        >
                          <Trash2 className="w-3.5 h-3.5" /> Hapus
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="py-8 px-6 text-center text-sm text-[#4A5248]">
                    Belum ada komponen tarif terdaftar. Klik <strong>+ Tambah Tarif</strong>.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      <section aria-label="Pratinjau Plang Fisik Smart QR">
        <div className="no-print mb-3 flex items-center gap-2 text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
          <QrCode className="w-4 h-4 text-[#F26B4B]" />
          <span>Pratinjau Plang Fisik Smart QR Resmi ({activeDestination.name})</span>
        </div>
        <SmartQRPlacardView destination={activeDestination} isModal={false} />
      </section>

      <dialog
        ref={editDialogRef}
        aria-labelledby="tariff-modal-title"
        onClose={() => setEditingTariff(null)}
        className="w-full max-w-xl rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {editingTariff && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] p-6 lg:p-8 rounded-[28px] border border-[#CFD8BE] shadow-xl">
            <div className="flex items-center justify-between pb-4 border-b border-[#CFD8BE]">
              <div>
                <span className="text-xs font-bold uppercase text-[#234B24]">
                  Standar Tarif Perda — {activeDestination.name}
                </span>
                <h3 id="tariff-modal-title" className="text-xl font-extrabold">
                  {isNewTariff ? 'Tambah Komponen Tarif Resmi' : 'Perbarui Komponen Tarif'}
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setEditingTariff(null)}
                className="w-10 h-10 rounded-full bg-white border border-[#CFD8BE] flex items-center justify-center"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveTariffSubmit} className="mt-5 space-y-4">
              <div className="flex flex-col gap-1">
                <label className="text-xs font-bold">Nama Item / Komponen Layanan *</label>
                <input
                  type="text"
                  required
                  value={editingTariff.item_name}
                  onChange={(e) =>
                    setEditingTariff({ ...editingTariff, item_name: e.target.value })
                  }
                  placeholder="Contoh: Tiket Masuk Kawasan Dewasa / Parkir Mobil"
                  className="min-h-[46px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-bold">Kategori Komponen *</label>
                  <select
                    value={normalizeTariffCategory(editingTariff.category)}
                    onChange={(e) => {
                      const cat = e.target.value as TariffCategoryType;
                      setEditingTariff({
                        ...editingTariff,
                        category: cat,
                        category_id: tariffCategoryToId(cat),
                      });
                    }}
                    className="min-h-[46px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                  >
                    {TARIFF_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-col gap-1">
                  <label className="text-xs font-bold">Satuan Pengenaan *</label>
                  <select
                    value={editingTariff.unit}
                    onChange={(e) => setEditingTariff({ ...editingTariff, unit: e.target.value })}
                    className="min-h-[46px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
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
                  <label className="text-xs font-bold">Harga Resmi (IDR) *</label>
                  <input
                    type="number"
                    min={0}
                    step={500}
                    required
                    value={editingTariff.price}
                    onChange={(e) =>
                      setEditingTariff({ ...editingTariff, price: Number(e.target.value) })
                    }
                    className="min-h-[46px] px-3.5 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-extrabold text-[#234B24]"
                  />
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-bold">Batas Wajar Min</label>
                  <input
                    type="number"
                    min={0}
                    step={500}
                    value={editingTariff.fair_price_min ?? editingTariff.price}
                    onChange={(e) =>
                      setEditingTariff({ ...editingTariff, fair_price_min: Number(e.target.value) })
                    }
                    className="min-h-[46px] px-3.5 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                  />
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-bold">Batas Wajar Maks</label>
                  <input
                    type="number"
                    min={0}
                    step={500}
                    value={editingTariff.fair_price_max ?? editingTariff.price}
                    onChange={(e) =>
                      setEditingTariff({ ...editingTariff, fair_price_max: Number(e.target.value) })
                    }
                    className="min-h-[46px] px-3.5 py-2 rounded-2xl bg-white border border-[#767676] text-sm font-semibold"
                  />
                </div>
              </div>

              <div className="flex flex-col gap-1">
                <label className="text-xs font-bold">Nomor Referensi Perda / SK Nagari *</label>
                <input
                  type="text"
                  required
                  value={editingTariff.regulation_ref}
                  onChange={(e) =>
                    setEditingTariff({ ...editingTariff, regulation_ref: e.target.value })
                  }
                  className="min-h-[46px] px-4 py-2 rounded-2xl bg-white border border-[#767676] text-sm"
                />
              </div>

              <div className="pt-4 flex items-center justify-end gap-3 border-t border-[#CFD8BE]">
                <button
                  type="button"
                  onClick={() => setEditingTariff(null)}
                  className="min-h-[44px] px-5 rounded-pill bg-white border border-[#767676] text-xs font-bold"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="h-[48px] px-7 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-sm font-bold"
                >
                  Simpan Komponen Tarif
                </button>
              </div>
            </form>
          </div>
        )}
      </dialog>

      <dialog
        ref={deleteDialogRef}
        aria-labelledby="delete-tariff-title"
        onClose={() => setTariffToDelete(null)}
        className="w-full max-w-md rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {tariffToDelete && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] p-6 rounded-[28px] border border-[#CFD8BE] shadow-xl">
            <h3 id="delete-tariff-title" className="text-lg font-extrabold">
              Hapus Komponen Tarif Resmi?
            </h3>
            <p className="mt-2 text-xs text-[#4A5248] leading-relaxed">
              Komponen <strong>{tariffToDelete.item_name}</strong> ({formatRupiah(tariffToDelete.price)}) akan dihapus dari {activeDestination.name}.
            </p>
            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                type="button"
                autoFocus
                onClick={() => setTariffToDelete(null)}
                className="min-h-[42px] px-5 rounded-pill bg-white border border-[#767676] text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmDeleteTariff}
                className="min-h-[42px] px-5 rounded-pill bg-[#F26B4B] text-white text-xs font-bold"
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
