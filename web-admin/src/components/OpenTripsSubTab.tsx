import React, { useEffect, useMemo, useState } from 'react';
import {
  Users,
  Search,
  CheckCircle2,
  AlertTriangle,
  Clock,
  MapPin,
  Phone,
  ShieldCheck,
  Building2,
  DollarSign,
  Calendar,
  Compass,
  ArrowRight,
  Eye,
  X,
} from 'lucide-react';
import {
  OpenTripItem,
  OpenTripStatus,
} from '../types/contract';
import {
  fetchOpenTrips,
  updateOpenTripStatus,
} from '../services/api';

interface OpenTripsSubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const OpenTripsSubTab: React.FC<OpenTripsSubTabProps> = ({
  showToast,
}) => {
  const [trips, setTrips] = useState<OpenTripItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedTrip, setSelectedTrip] = useState<OpenTripItem | null>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await fetchOpenTrips();
      setTrips(data);
    } catch {
      showToast('Gagal memuat data pengawasan Open Trip.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleUpdateStatus = async (tripId: string, newStatus: OpenTripStatus) => {
    try {
      const updated = await updateOpenTripStatus(tripId, newStatus);
      setTrips(updated);
      if (selectedTrip?.id === tripId) {
        setSelectedTrip((prev) => (prev ? { ...prev, status: newStatus } : null));
      }
      showToast(`Status trip berhasil diubah menjadi: "${newStatus}"`, 'success');
    } catch {
      showToast('Gagal memperbarui status open trip.', 'error');
    }
  };

  const filteredTrips = useMemo(() => {
    return trips.filter((t) => {
      const q = searchQuery.trim().toLowerCase();
      const matchQuery =
        !q ||
        t.trip_code.toLowerCase().includes(q) ||
        t.title.toLowerCase().includes(q) ||
        t.leader_name.toLowerCase().includes(q) ||
        t.pokdarwis_partner.toLowerCase().includes(q) ||
        t.city_regency.toLowerCase().includes(q) ||
        t.destination_routes.some((r) => r.toLowerCase().includes(q));

      const matchStatus =
        statusFilter === 'all' || t.status === statusFilter;

      return matchQuery && matchStatus;
    });
  }, [trips, searchQuery, statusFilter]);

  const stats = useMemo(() => {
    const total = trips.length;
    const confirmed = trips.filter((t) => t.status === 'Terkonfirmasi & Siaga').length;
    const pending = trips.filter((t) => t.status === 'Menunggu Kuota').length;
    const suspended = trips.filter((t) => t.status === 'Ditangguhkan').length;
    return { total, confirmed, pending, suspended };
  }, [trips]);

  const getStatusBadge = (status: OpenTripStatus) => {
    switch (status) {
      case 'Terkonfirmasi & Siaga':
        return {
          bg: 'bg-[#1E9E5A]/15',
          text: 'text-[#166534]',
          border: 'border-[#1E9E5A]/30',
        };
      case 'Berjalan':
        return {
          bg: 'bg-[#3B82F6]/15',
          text: 'text-[#1D4ED8]',
          border: 'border-[#3B82F6]/30',
        };
      case 'Menunggu Kuota':
        return {
          bg: 'bg-[#F26B4B]/15',
          text: 'text-[#D95637]',
          border: 'border-[#F26B4B]/30',
        };
      case 'Ditangguhkan':
        return {
          bg: 'bg-red-100',
          text: 'text-red-700',
          border: 'border-red-300',
        };
    }
  };

  return (
    <div className="space-y-6">
      {/* 4 Kartu KPI Pengawasan Open Trip */}
      <section
        aria-label="Ringkasan Statistik Pengawasan Open Trip"
        className="grid grid-cols-2 lg:grid-cols-4 gap-4"
      >
        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Total Open Trip Terdata
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.total}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
              Terpantau Satgas
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Rombongan wisatawan nusantara &amp; wisman
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Terkonfirmasi &amp; Siaga
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#1E9E5A]">
              {stats.confirmed}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
              Pokdarwis Ready
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Verifikasi Pokdarwis &amp; transportasi nagari terhubung P2P
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Menunggu Kuota
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#F26B4B]">
              {stats.pending}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
              Cari Barengan
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Tautan share link group invite aktif
          </p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
            Ditangguhkan (Hazard Alert)
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#D95637]">
              {stats.suspended}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-red-100 text-red-700">
              Perlindungan SAR
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">
            Jalur cuaca ekstrem / bencana alam ditahan sementara
          </p>
        </div>
      </section>

      {/* Filter & Baris Pencarian Open Trip */}
      <div className="bg-white p-5 lg:p-6 rounded-3xl border border-[#E4E9DA] shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari kode trip, ketua rombongan, Pokdarwis, atau rute destinasi..."
            className="w-full min-h-[46px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="all">Semua Status Open Trip</option>
            <option value="Terkonfirmasi & Siaga">Terkonfirmasi &amp; Siaga</option>
            <option value="Menunggu Kuota">Menunggu Kuota</option>
            <option value="Berjalan">Berjalan</option>
            <option value="Ditangguhkan">Ditangguhkan</option>
          </select>

          <span className="text-xs text-[#4A5248] hidden sm:inline">
            Menampilkan: <strong>{filteredTrips.length} Rombongan</strong>
          </span>
        </div>
      </div>

      {/* Tabel Pengawasan Open Trip */}
      <div className="bg-white rounded-3xl border border-[#E4E9DA] shadow-sm overflow-hidden">
        <div className="p-5 lg:p-6 border-b border-[#E4E9DA] flex items-center justify-between">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A]">
              Tabel Pengawasan Open Trip &amp; Cari Barengan Wisatawan
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Pantau kepatuhan ketua rombongan, integrasi mitra Pokdarwis, split-bill transparan, serta proteksi keamanan jalur ekstrem.
            </p>
          </div>
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24]">
            Pusat Komando
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-[#F6F3EC] border-b border-[#CFD8BE] text-[#4A5248] font-extrabold uppercase tracking-wider">
                <th className="py-3.5 px-4">Kode Trip</th>
                <th className="py-3.5 px-4 min-w-[200px]">Agenda Trip &amp; Rute Destinasi</th>
                <th className="py-3.5 px-4 min-w-[180px]">Ketua &amp; Pokdarwis</th>
                <th className="py-3.5 px-4 text-center">Keberangkatan</th>
                <th className="py-3.5 px-4 text-center">Kuota Terisi</th>
                <th className="py-3.5 px-4 text-right">Split-Bill / Orang</th>
                <th className="py-3.5 px-4 text-center">Status</th>
                <th className="py-3.5 px-4 text-center min-w-[140px]">Tindakan</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA]">
              {filteredTrips.map((trip) => {
                const statusMeta = getStatusBadge(trip.status);
                const isFull = trip.quota_filled >= trip.quota_max;

                return (
                  <tr key={trip.id} className="hover:bg-[#F6F3EC]/70 transition">
                    {/* Kode Trip */}
                    <td className="py-3.5 px-4 font-mono font-bold text-[#234B24]">
                      {trip.trip_code}
                    </td>

                    {/* Judul & Rute */}
                    <td className="py-3.5 px-4">
                      <div className="font-extrabold text-[#1B1F1A] text-sm">
                        {trip.title}
                      </div>
                      <div className="text-[11px] text-[#4A5248] flex items-center gap-1.5 flex-wrap mt-0.5">
                        <MapPin className="w-3 h-3 text-[#234B24] shrink-0" />
                        <span>{trip.destination_routes.join(' → ')}</span>
                      </div>
                    </td>

                    {/* Ketua & Pokdarwis */}
                    <td className="py-3.5 px-4">
                      <div className="font-bold text-[#1B1F1A]">
                        {trip.leader_name}
                      </div>
                      <div className="text-[11px] text-[#234B24] font-semibold flex items-center gap-1 mt-0.5">
                        <Building2 className="w-3 h-3" />
                        <span>{trip.pokdarwis_partner}</span>
                      </div>
                      <div className="text-[10px] text-[#767676]">
                        {trip.leader_phone}
                      </div>
                    </td>

                    {/* Keberangkatan */}
                    <td className="py-3.5 px-4 text-center">
                      <div className="font-bold text-[#1B1F1A]">
                        {trip.departure_date}
                      </div>
                      <div className="text-[10px] text-[#767676]">
                        {trip.duration_days} Hari
                      </div>
                    </td>

                    {/* Kuota */}
                    <td className="py-3.5 px-4 text-center">
                      <div className="font-bold text-[#1B1F1A]">
                        {trip.quota_filled} / {trip.quota_max} Orang
                      </div>
                      <div className="w-20 mx-auto bg-neutral-200 h-1.5 rounded-full overflow-hidden mt-1">
                        <div
                          className={`h-full rounded-full ${
                            isFull ? 'bg-[#1E9E5A]' : 'bg-[#F26B4B]'
                          }`}
                          style={{
                            width: `${Math.min(
                              100,
                              (trip.quota_filled / trip.quota_max) * 100
                            )}%`,
                          }}
                        />
                      </div>
                    </td>

                    {/* Split-Bill */}
                    <td className="py-3.5 px-4 text-right">
                      <div className="font-mono font-bold text-[#234B24]">
                        Rp {trip.split_bill_idr.toLocaleString('id-ID')}
                      </div>
                      <div className="text-[10px] font-mono text-[#767676]">
                        ≈ MYR {trip.split_bill_myr}
                      </div>
                    </td>

                    {/* Status */}
                    <td className="py-3.5 px-4 text-center">
                      <span
                        className={`inline-block px-2.5 py-1 rounded-full text-[10px] font-bold border ${statusMeta.bg} ${statusMeta.text} ${statusMeta.border}`}
                      >
                        {trip.status}
                      </span>
                    </td>

                    {/* Tindakan */}
                    <td className="py-3.5 px-4 text-center">
                      <div className="flex items-center justify-center gap-1.5 flex-wrap">
                        {trip.status !== 'Terkonfirmasi & Siaga' && trip.status !== 'Berjalan' && (
                          <button
                            type="button"
                            onClick={() =>
                              handleUpdateStatus(trip.id, 'Terkonfirmasi & Siaga')
                            }
                            className="px-2.5 py-1 rounded-lg bg-[#1E9E5A] hover:bg-[#166534] text-white text-[10px] font-bold transition shadow-xs"
                          >
                            Verifikasi
                          </button>
                        )}
                        {trip.status !== 'Ditangguhkan' && (
                          <button
                            type="button"
                            onClick={() =>
                              handleUpdateStatus(trip.id, 'Ditangguhkan')
                            }
                            className="px-2.5 py-1 rounded-lg bg-red-100 hover:bg-red-200 text-red-700 text-[10px] font-bold transition"
                          >
                            Tangguhkan
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() => setSelectedTrip(trip)}
                          className="px-2 py-1 rounded-lg bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24] text-[10px] font-bold border border-[#CFD8BE]"
                        >
                          Detail
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Detail Open Trip */}
      {selectedTrip && (
        <div className="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-4">
          <div className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border border-[#CFD8BE] shadow-2xl max-w-lg w-full p-6 space-y-4">
            <div className="flex items-center justify-between border-b border-[#CFD8BE] pb-3">
              <div>
                <span className="text-[10px] font-extrabold uppercase text-[#234B24]">
                  Detail Pengawasan Open Trip
                </span>
                <h4 className="text-lg font-extrabold text-[#1B1F1A]">
                  {selectedTrip.title}
                </h4>
              </div>
              <button
                type="button"
                onClick={() => setSelectedTrip(null)}
                className="w-8 h-8 rounded-full bg-white/50 hover:bg-[#F26B4B] hover:text-white flex items-center justify-center transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3 rounded-xl bg-white border border-[#CFD8BE] space-y-1">
                <span className="font-bold text-[#4A5248]">Rute Destinasi:</span>
                <p className="font-extrabold text-[#234B24]">
                  {selectedTrip.destination_routes.join(' → ')}
                </p>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 rounded-xl bg-white border border-[#CFD8BE]">
                  <span className="text-[#4A5248] font-bold">Ketua Rombongan:</span>
                  <p className="font-extrabold text-[#1B1F1A] mt-0.5">
                    {selectedTrip.leader_name}
                  </p>
                  <p className="text-[11px] text-[#234B24] mt-0.5">
                    {selectedTrip.leader_phone}
                  </p>
                </div>

                <div className="p-3 rounded-xl bg-white border border-[#CFD8BE]">
                  <span className="text-[#4A5248] font-bold">Mitra Pokdarwis:</span>
                  <p className="font-extrabold text-[#1B1F1A] mt-0.5">
                    {selectedTrip.pokdarwis_partner}
                  </p>
                  <p className="text-[11px] text-[#767676] mt-0.5">
                    {selectedTrip.city_regency}
                  </p>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-white border border-[#CFD8BE] flex items-center justify-between">
                <div>
                  <span className="text-[#4A5248] font-bold">Estimasi Split-Bill:</span>
                  <p className="font-mono font-extrabold text-base text-[#234B24]">
                    Rp {selectedTrip.split_bill_idr.toLocaleString('id-ID')}
                  </p>
                </div>
                <div className="text-right">
                  <span className="text-[#4A5248] font-bold">Kuota Terisi:</span>
                  <p className="font-bold text-[#1B1F1A]">
                    {selectedTrip.quota_filled} / {selectedTrip.quota_max} Orang
                  </p>
                </div>
              </div>

              {selectedTrip.notes && (
                <div className="p-3 rounded-xl bg-[#E4E9DA] border border-[#CFD8BE] text-[11px] text-[#1B1F1A]">
                  <strong>Catatan Operasional:</strong> {selectedTrip.notes}
                </div>
              )}
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-[#CFD8BE]">
              <button
                type="button"
                onClick={() => setSelectedTrip(null)}
                className="px-4 py-2 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
