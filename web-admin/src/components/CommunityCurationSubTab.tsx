import React, { useEffect, useMemo, useState } from 'react';
import {
  Compass,
  CheckCircle2,
  XCircle,
  Eye,
  EyeOff,
  Search,
  Filter,
  MapPin,
  Building2,
  Sparkles,
  ShieldCheck,
  AlertTriangle,
  Bell,
  Send,
} from 'lucide-react';
import {
  CommunityHiddenGemSubmission,
  ModerationStatus,
} from '../types/contract';
import {
  fetchCommunitySubmissions,
  updateCommunitySubmission,
  broadcastSystemNotification,
} from '../services/api';

interface CommunityCurationSubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const CommunityCurationSubTab: React.FC<CommunityCurationSubTabProps> = ({
  showToast,
}) => {
  const [submissions, setSubmissions] = useState<CommunityHiddenGemSubmission[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await fetchCommunitySubmissions();
      setSubmissions(data);
    } catch {
      showToast('Gagal memuat usulan destinasi komunitas.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleUpdateStatus = async (
    id: string,
    status: ModerationStatus,
    notes?: string
  ) => {
    try {
      const updated = await updateCommunitySubmission(id, {
        status,
        reviewer_notes: notes || (status === 'APPROVED' ? 'Disetujui oleh Administrator Utama Dispar.' : 'Ditolak karena belum memenuhi standar keselamatan.'),
      });
      setSubmissions(updated);

      if (status === 'APPROVED') {
        const approvedSub = submissions.find((s) => s.id === id);
        if (approvedSub) {
          try {
            await broadcastSystemNotification({
              title: `Destinasi Komunitas Baru: ${approvedSub.title}`,
              message: `Usulan dari Pokdarwis ${approvedSub.pokdarwis_name} (${approvedSub.city_regency}) resmi disetujui & terbit di direktori wisata Sumbar!`,
              type: 'INPUT_WISATA_DISETUJUI',
              target: 'Semua Wisatawan',
              ref_id: approvedSub.id,
            });
          } catch (notifErr) {
            console.error('Failed to broadcast notification:', notifErr);
          }
        }
      }

      showToast(
        status === 'APPROVED'
          ? 'Usulan tempat wisata disetujui, diterbitkan & disiarkan ke wisatawan!'
          : 'Usulan tempat wisata ditolak.',
        status === 'APPROVED' ? 'success' : 'info'
      );
    } catch {
      showToast('Gagal memperbarui status usulan.', 'error');
    }
  };

  const handleBroadcastSubmission = async (sub: CommunityHiddenGemSubmission) => {
    try {
      await broadcastSystemNotification({
        title: `Rekomendasi Hidden Gem: ${sub.title}`,
        message: `Jelajahi keindahan tersembunyi di ${sub.city_regency} yang telah diverifikasi Dinas Pariwisata Sumbar bersama Pokdarwis ${sub.pokdarwis_name}!`,
        type: 'INPUT_WISATA_DISETUJUI',
        target: 'Semua Wisatawan',
        ref_id: sub.id,
      });
      showToast(`Notifikasi usulan "${sub.title}" berhasil disiarkan ke seluruh wisatawan!`, 'success');
    } catch {
      showToast('Gagal menyiarkan notifikasi tempat wisata.', 'error');
    }
  };

  const handleToggleMasking = async (id: string, currentMasked: boolean) => {
    try {
      const updated = await updateCommunitySubmission(id, {
        is_masked: !currentMasked,
      });
      setSubmissions(updated);
      showToast(
        !currentMasked
          ? 'Proteksi Masking Koordinat DIAKTIFKAN. Wisatawan wajib didampingi Pokdarwis.'
          : 'Proteksi Masking Koordinat DINONAKTIFKAN. Koordinat GPS publik terbuka.',
        'info'
      );
    } catch {
      showToast('Gagal mengubah sakelar masking koordinat.', 'error');
    }
  };

  const filteredSubmissions = useMemo(() => {
    return submissions.filter((s) => {
      const q = searchQuery.trim().toLowerCase();
      const matchQuery =
        !q ||
        (s.title || s.name || '').toLowerCase().includes(q) ||
        (s.pokdarwis_name || s.submitter_name || '').toLowerCase().includes(q) ||
        (s.city_regency || '').toLowerCase().includes(q) ||
        (s.description || '').toLowerCase().includes(q);

      const matchStatus =
        statusFilter === 'all' || s.status === statusFilter;

      return matchQuery && matchStatus;
    });
  }, [submissions, searchQuery, statusFilter]);

  const stats = useMemo(() => {
    const total = submissions.length;
    const pending = submissions.filter((s) => s.status === 'PENDING').length;
    const approved = submissions.filter((s) => s.status === 'APPROVED').length;
    const masked = submissions.filter((s) => s.is_masked).length;
    return { total, pending, approved, masked };
  }, [submissions]);

  return (
    <div className="space-y-6">
      {/* 4 Kartu KPI Kurasi Komunitas */}
      <section
        aria-label="Ringkasan Statistik Meja Kurasi Destinasi Komunitas"
        className="grid grid-cols-2 lg:grid-cols-4 gap-4"
      >
        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Total Usulan Komunitas
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.total}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
              Crowdsourced
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Usulan tempat baru dari penjelajah &amp; Pokdarwis
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Menunggu Verifikasi
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#F26B4B]">
              {stats.pending}
            </span>
            <span className="w-2.5 h-2.5 rounded-full bg-[#F26B4B] animate-ping" />
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Memerlukan persetujuan Admin Dispar
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Disetujui &amp; Terbit
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#1E9E5A]">
              {stats.approved}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
              Terverifikasi
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Telah masuk ke direktori resmi Sumbar
          </p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
            Masking Lokasi Sensitif
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.masked} Tempat
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#234B24] text-[#F6F3EC]">
              Cagar Budaya
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">
            Koordinat GPS dikaburkan demi kelestarian alam
          </p>
        </div>
      </section>

      {/* Filter & Baris Pencarian Usulan */}
      <div className="bg-white p-5 lg:p-6 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari nama tempat, pengusul Pokdarwis, atau wilayah..."
            className="w-full min-h-[46px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="all">Semua Status Moderasi</option>
            <option value="PENDING">Menunggu Verifikasi (Pending)</option>
            <option value="APPROVED">Disetujui &amp; Terbit (Approved)</option>
            <option value="REJECTED">Ditolak (Rejected)</option>
          </select>
        </div>
      </div>

      {/* Daftar Usulan Tempat Wisata Komunitas */}
      <div className="bg-white rounded-3xl border border-[#234B24]/10 shadow-sm overflow-hidden">
        <div className="p-5 lg:p-6 border-b border-[#234B24]/10 flex items-center justify-between">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A]">
              Meja Kurasi &amp; Verifikasi Usulan Destinasi Komunitas
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Lindungi ekosistem alam dan cagar adat dengan sakelar masking koordinat presisi sebelum diterbitkan ke aplikasi wisatawan.
            </p>
          </div>
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24]">
            Filter Anti-Kerusakan Alam
          </span>
        </div>

        {filteredSubmissions.length === 0 ? (
          <div className="p-12 text-center text-[#4A5248] space-y-2">
            <Compass className="w-10 h-10 text-[#234B24]/40 mx-auto" />
            <p className="text-sm font-bold text-[#1B1F1A]">
              Tidak ada usulan yang sesuai filter pencarian.
            </p>
          </div>
        ) : (
          <div className="divide-y divide-[#E4E9DA]">
            {filteredSubmissions.map((sub) => {
              return (
                <div
                  key={sub.id}
                  className="p-5 lg:p-6 hover:bg-[#F6F3EC]/50 transition flex flex-col lg:flex-row lg:items-center justify-between gap-5"
                >
                  <div className="space-y-2 flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="text-base font-extrabold text-[#1B1F1A]">
                        {sub.title}
                      </span>
                      <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#E4E9DA] text-[#234B24]">
                        {sub.category}
                      </span>
                      <span
                        className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                          sub.status === 'APPROVED'
                            ? 'bg-[#1E9E5A]/15 text-[#166534]'
                            : sub.status === 'REJECTED'
                            ? 'bg-red-100 text-red-700'
                            : 'bg-[#F26B4B]/15 text-[#D95637]'
                        }`}
                      >
                        {sub.status === 'APPROVED'
                          ? 'Disetujui'
                          : sub.status === 'REJECTED'
                          ? 'Ditolak'
                          : 'Menunggu Verifikasi'}
                      </span>
                    </div>

                    <div className="text-xs text-[#4A5248] flex items-center gap-3 flex-wrap">
                      <span className="flex items-center gap-1 font-bold text-[#234B24]">
                        <Building2 className="w-3.5 h-3.5" />
                        <span>Pengusul: {sub.pokdarwis_name}</span>
                      </span>
                      <span>•</span>
                      <span className="flex items-center gap-1">
                        <MapPin className="w-3.5 h-3.5" />
                        <span>{sub.city_regency}</span>
                      </span>
                      <span>•</span>
                      <span className="font-mono text-[11px]">
                        GPS: {(sub.latitude ?? -0.9492).toFixed(4)}, {(sub.longitude ?? 100.3543).toFixed(4)}
                      </span>
                    </div>

                    <p className="text-xs text-[#4A5248] bg-[#F6F3EC] p-3 rounded-2xl border border-[#CFD8BE]/50">
                      {sub.description}
                    </p>

                    {sub.reviewer_notes && (
                      <p className="text-[11px] text-[#234B24] font-semibold">
                        <strong>Catatan Reviewer:</strong> {sub.reviewer_notes}
                      </p>
                    )}
                  </div>

                  {/* Kontrol Masking & Persetujuan */}
                  <div className="flex flex-col sm:flex-row lg:flex-col items-start sm:items-center lg:items-end gap-3 shrink-0">
                    {/* Sakelar Masking Lokasi Sensitif */}
                    <button
                      type="button"
                      onClick={() => handleToggleMasking(sub.id, !!(sub.is_masked ?? sub.is_sensitive))}
                      className={`px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-2 border transition shadow-xs ${
                        (sub.is_masked ?? sub.is_sensitive)
                          ? 'bg-[#E4E9DA] text-[#234B24] border-[#234B24]/30'
                          : 'bg-white text-[#767676] border-[#CFD8BE]'
                      }`}
                    >
                      {(sub.is_masked ?? sub.is_sensitive) ? (
                        <>
                          <EyeOff className="w-4 h-4 text-[#234B24]" />
                          <span>Masking Aktif (Wajib Pemandu)</span>
                        </>
                      ) : (
                        <>
                          <Eye className="w-4 h-4 text-[#767676]" />
                          <span>Koordinat Publik Terbuka</span>
                        </>
                      )}
                    </button>

                    {/* Tombol Setujui / Tolak / Siarkan */}
                    <div className="flex flex-wrap items-center gap-2">
                      {sub.status === 'APPROVED' && (
                        <button
                          type="button"
                          onClick={() => handleBroadcastSubmission(sub)}
                          className="min-h-[40px] px-3.5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B1F1A] text-white text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
                          title="Siarkan Notifikasi ke Semua Wisatawan"
                        >
                          <Bell className="w-3.5 h-3.5" />
                          <span>Siarkan Notifikasi</span>
                        </button>
                      )}
                      {sub.status !== 'APPROVED' && (
                        <button
                          type="button"
                          onClick={() => handleUpdateStatus(sub.id, 'APPROVED')}
                          className="min-h-[40px] px-4 py-2 rounded-xl bg-[#1E9E5A] hover:bg-[#166534] text-white text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
                        >
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          <span>Setujui Usulan</span>
                        </button>
                      )}
                      {sub.status !== 'REJECTED' && (
                        <button
                          type="button"
                          onClick={() => handleUpdateStatus(sub.id, 'REJECTED')}
                          className="min-h-[40px] px-4 py-2 rounded-xl bg-white hover:bg-red-50 text-red-700 border border-red-200 text-xs font-bold flex items-center gap-1.5 transition"
                        >
                          <XCircle className="w-3.5 h-3.5" />
                          <span>Tolak</span>
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
