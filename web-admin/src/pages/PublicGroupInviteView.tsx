import React, { useEffect, useState } from 'react';
import {
  Users,
  Calendar,
  Compass,
  CheckCircle2,
  ChevronLeft,
  ThumbsUp,
  MapPin,
  ExternalLink,
  Sparkles,
  Award,
  ArrowRight,
  ShieldCheck,
} from 'lucide-react';
import { GroupRoomPreview } from '../types/contract';
import { fetchGroupRoom, voteGroupItem } from '../services/api';

interface PublicGroupInviteViewProps {
  groupCode?: string;
  onBackToAdmin?: () => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const PublicGroupInviteView: React.FC<PublicGroupInviteViewProps> = ({
  groupCode = 'RANCAK-MINANG-88',
  onBackToAdmin,
  showToast,
}) => {
  const [group, setGroup] = useState<GroupRoomPreview | null>(null);
  const [loading, setLoading] = useState(true);
  const [votedItems, setVotedItems] = useState<Record<string, boolean>>({});

  useEffect(() => {
    const loadGroup = async () => {
      setLoading(true);
      try {
        const data = await fetchGroupRoom(groupCode);
        setGroup(data);
      } catch {
        showToast('Gagal memuat ruang grup perjalanan.', 'error');
      } finally {
        setLoading(false);
      }
    };
    loadGroup();
  }, [groupCode]);

  const handleVote = async (itemId: string) => {
    if (votedItems[itemId]) {
      showToast('Anda sudah memberikan suara untuk pilihan ini.', 'info');
      return;
    }

    try {
      const updated = await voteGroupItem(groupCode, itemId);
      if (updated) {
        setGroup(updated);
        setVotedItems((prev) => ({ ...prev, [itemId]: true }));
        showToast('Suara Anda berhasil dicatat ke polling grup!', 'success');
      }
    } catch {
      showToast('Gagal memberikan suara.', 'error');
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
            Pratinjau Web Group Invite: /join/{groupCode}
          </span>
        </div>
      )}

      {/* Mobile-First Frame Container */}
      <main className="w-full max-w-md bg-white shadow-xl min-h-screen border-x border-[#E4E9DA] flex flex-col justify-between">
        <div>
          {/* Header Undangan Rombongan */}
          <header className="bg-[#234B24] text-[#F6F3EC] p-6 relative overflow-hidden">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 border border-white/15 text-[10px] font-bold text-[#A7F3D0] mb-3">
              <Users className="w-3.5 h-3.5 text-[#1E9E5A]" aria-hidden="true" />
              <span>UNDANGAN PERJALANAN ROMBONGAN</span>
            </div>

            <div className="font-mono text-[11px] text-[#F26B4B] font-bold tracking-wider">
              KODE GRUP: {group?.group_code || groupCode}
            </div>

            <h1 className="mt-1 text-xl font-extrabold leading-tight tracking-tight">
              {group?.group_name || 'Eksplorasi Ranah Minang 7 Hari'}
            </h1>

            <div className="mt-4 pt-3 border-t border-white/10 flex items-center justify-between text-xs text-[#E4E9DA]/90">
              <div className="flex items-center gap-1.5">
                <Calendar className="w-3.5 h-3.5 text-[#F26B4B]" aria-hidden="true" />
                <span>{group?.trip_dates || '20 - 27 Desember 2026'}</span>
              </div>
              <div className="font-bold text-[#A7F3D0]">
                {group?.member_count || 6} Anggota Tergabung
              </div>
            </div>

            <div className="mt-2 text-xs text-[#E4E9DA]/80">
              Ketua Rombongan:{' '}
              <span className="font-bold text-white">
                {group?.leader_name || 'Farhan Bahar'}
              </span>
            </div>
          </header>

          <div className="p-5 space-y-6">
            {/* Rencana Destinasi yang Akan Dikunjungi */}
            <section className="space-y-3">
              <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Compass className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                <span>Rencana 5 Destinasi Unggulan</span>
              </h2>

              <div className="space-y-2">
                {group?.destinations_summary.map((destName, idx) => (
                  <div
                    key={idx}
                    className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-center gap-3"
                  >
                    <div className="w-6 h-6 rounded-lg bg-[#234B24] text-white text-xs font-bold flex items-center justify-center shrink-0">
                      {idx + 1}
                    </div>
                    <span className="text-xs font-bold text-[#1B1F1A]">
                      {destName}
                    </span>
                  </div>
                ))}
              </div>
            </section>

            {/* Polling / Voting Destinasi Interaktif */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
                  <span>Polling Pilihan Aktivitas &amp; Penginapan</span>
                </h2>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                  Live Voting
                </span>
              </div>
              <p className="text-[11px] text-[#4A5248]">
                Berikan suara Anda untuk menentukan aktivitas bersama rombongan secara demokratis.
              </p>

              <div className="space-y-2.5">
                {group?.voting_items.map((item) => {
                  const hasVoted = votedItems[item.id];

                  return (
                    <div
                      key={item.id}
                      className="p-3.5 rounded-2xl bg-white border-2 border-[#CFD8BE] hover:border-[#234B24] transition shadow-xs flex items-center justify-between gap-3"
                    >
                      <div className="min-w-0 flex-1">
                        <span className="text-[10px] font-bold text-[#234B24] uppercase tracking-wide">
                          {item.category}
                        </span>
                        <h3 className="text-xs font-extrabold text-[#1B1F1A] mt-0.5 leading-snug">
                          {item.title}
                        </h3>
                        <div className="mt-1 flex items-center gap-2 text-[11px] text-[#4A5248]">
                          <span className="font-bold text-[#234B24]">
                            {item.votes_count} Suara
                          </span>
                          {item.is_winner && (
                            <span className="text-[10px] font-extrabold text-[#CA8A04] flex items-center gap-0.5">
                              <Award className="w-3 h-3" aria-hidden="true" />
                              <span>Pilihan Terbanyak</span>
                            </span>
                          )}
                        </div>
                      </div>

                      <button
                        type="button"
                        onClick={() => handleVote(item.id)}
                        disabled={hasVoted}
                        className={`min-h-[40px] px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 shrink-0 transition ${
                          hasVoted
                            ? 'bg-[#DCFCE7] text-[#166534] border border-[#86EFAC]'
                            : 'bg-[#F26B4B] hover:bg-[#D95637] text-white shadow-xs'
                        }`}
                      >
                        <ThumbsUp className="w-3.5 h-3.5" aria-hidden="true" />
                        <span>{hasVoted ? 'Sudah Vote' : 'Vote'}</span>
                      </button>
                    </div>
                  );
                })}
              </div>
            </section>

            {/* Edukasi Keamanan Escrow Nagari */}
            <div className="p-3.5 rounded-2xl bg-[#E4E9DA]/70 border border-[#CFD8BE] flex items-start gap-3">
              <ShieldCheck className="w-5 h-5 text-[#234B24] shrink-0 mt-0.5" aria-hidden="true" />
              <div className="text-xs text-[#1B1F1A]">
                <span className="font-bold text-[#234B24]">
                  Perlindungan Dana Bersama:
                </span>{' '}
                Seluruh pemesanan akomodasi Homestay dan Kapal rombongan dilindungi rekening penampung resmi Escrow Rancak.in Sumbar.
              </div>
            </div>
          </div>
        </div>

        {/* Footer CTA Kapsul 52px */}
        <footer className="p-5 bg-[#F6F3EC] border-t border-[#CFD8BE] space-y-2.5">
          <button
            type="button"
            onClick={() => {
              showToast(
                'Membuka aplikasi mobile Rancak.in untuk bergabung ke grup...',
                'info'
              );
            }}
            className="w-full h-[52px] rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-sm font-extrabold flex items-center justify-center gap-2 shadow-md transition"
          >
            <Users className="w-4 h-4 text-[#A7F3D0]" aria-hidden="true" />
            <span>Gabung &amp; Buka di Aplikasi Rancak.in</span>
          </button>

          <p className="text-center text-[10px] text-[#767676]">
            Dinas Pariwisata Provinsi Sumatera Barat · Rancak.in Mobile Ekosistem
          </p>
        </footer>
      </main>
    </div>
  );
};
