import React, { useEffect, useState } from 'react';
import {
  Users,
  Calendar,
  ChevronLeft,
  ThumbsUp,
  Sparkles,
  Award,
  ShieldCheck,
  Calculator,
  Clock,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import { GroupRoomPreview } from '../types/contract';
import { fetchGroupRoom, voteGroupItem } from '../services/api';

interface PublicGroupInviteViewProps {
  groupCode?: string;
  onBackToAdmin?: () => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const SAMPLE_GROUPS = [
  { code: 'WISGO-MINANG-88', title: 'Trip Go Keluarga Serumpun Ranah Minang' },
  { code: 'WISGO-HARAU-07', title: 'Eksplorasi Geopark Harau & Sarasah Bunta' },
  { code: 'WISGO-MANDEH-12', title: 'Island Hopping & Snorkeling Teluk Mandeh' },
];

const SEVEN_DAY_ITINERARY = [
  {
    day: 1,
    title: 'BIM Padang & Wisata Kuliner Minang',
    desc: 'Penjemputan bandara, kuliner Pantai Padang, check-in penginapan.',
  },
  {
    day: 2,
    title: 'Geopark Lembah Harau & Sarasah Bunta',
    desc: 'Eksplorasi tebing karst Harau dan air terjun Sarasah Bunta.',
  },
  {
    day: 3,
    title: 'Bukittinggi Heritage & Jam Gadang',
    desc: 'Ngarai Sianok, Lobang Jepang, Pasar Atas, kuliner Nasi Kapau.',
  },
  {
    day: 4,
    title: 'Danau Maninjau & Puncak Lawang',
    desc: 'Panorama kaldera Maninjau, Kelok 44, dan kuliner rinuak tepi danau.',
  },
  {
    day: 5,
    title: 'Istano Basa Pagaruyung & Nagari Pariangan',
    desc: 'Foto busana adat Minang dan jelajah Nagari Tuo Pariangan.',
  },
  {
    day: 6,
    title: 'Bahari Mandeh & Island Hopping',
    desc: 'Pulau Sironjong Ketek, snorkeling terumbu karang, ikan bakar Kapo-Kapo.',
  },
  {
    day: 7,
    title: 'Sentra Oleh-oleh Sanjai & Kepulangan',
    desc: 'Keripik sanjai balado, kopi kawa daun, transfer ke Bandara Minangkabau.',
  },
];

export const PublicGroupInviteView: React.FC<PublicGroupInviteViewProps> = ({
  groupCode = 'WISGO-MINANG-88',
  onBackToAdmin,
  showToast,
}) => {
  const [selectedGroupCode, setSelectedGroupCode] = useState<string>(groupCode);
  const [group, setGroup] = useState<GroupRoomPreview | null>(null);
  const [votedItems, setVotedItems] = useState<Record<string, boolean>>({});
  const [estimatedTotalCost] = useState<number>(4800000);
  const [memberCount, setMemberCount] = useState<number>(8);
  const [showItinerary, setShowItinerary] = useState<boolean>(true);

  useEffect(() => {
    const loadGroup = async () => {
      try {
        const data = await fetchGroupRoom(selectedGroupCode);
        setGroup(data);
        if (data?.member_count) {
          setMemberCount(data.member_count);
        }
      } catch {
        showToast('Gagal memuat ruang grup Trip Go.', 'error');
      }
    };
    loadGroup();
  }, [selectedGroupCode, showToast]);

  const handleVote = async (itemId: string) => {
    if (votedItems[itemId]) {
      showToast('Anda sudah memberikan suara untuk pilihan ini.', 'info');
      return;
    }
    try {
      const updated = await voteGroupItem(selectedGroupCode, itemId);
      if (updated) {
        setGroup(updated);
        setVotedItems((prev) => ({ ...prev, [itemId]: true }));
        showToast('Suara Anda berhasil dicatat ke polling Trip Go!', 'success');
      }
    } catch {
      showToast('Gagal memberikan suara.', 'error');
    }
  };

  const costPerPersonIDR = Math.round(estimatedTotalCost / (memberCount || 1));
  const costPerPersonMYR = (costPerPersonIDR / 3300).toFixed(1);

  return (
    <div className="min-h-screen bg-[#F6F3EC] text-[#1B1F1A] flex flex-col items-center justify-start pb-12">
      {onBackToAdmin && (
        <div className="w-full bg-[#234B24] text-[#F6F3EC] px-4 py-2.5 flex flex-wrap items-center justify-between gap-3 shadow-sm sticky top-0 z-40">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onBackToAdmin}
              className="flex items-center gap-1.5 text-xs font-bold text-[#A7F3D0] hover:text-white"
            >
              <ChevronLeft className="w-4 h-4" />
              <span>Kembali ke Portal WISGO</span>
            </button>
            <span className="text-[11px] font-mono text-[#E4E9DA]/80 hidden md:inline">
              /join/{selectedGroupCode}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <label
              htmlFor="group-select-id"
              className="text-xs text-[#A7F3D0] font-bold whitespace-nowrap"
            >
              Pilih Grup Trip Go:
            </label>
            <select
              id="group-select-id"
              value={selectedGroupCode}
              onChange={(e) => setSelectedGroupCode(e.target.value)}
              className="px-3 py-1.5 rounded-xl bg-black/30 border border-white/20 text-xs font-bold text-[#F6F3EC]"
            >
              {SAMPLE_GROUPS.map((g) => (
                <option key={g.code} value={g.code} className="bg-[#234B24] text-white">
                  {g.code} — {g.title}
                </option>
              ))}
            </select>
          </div>
        </div>
      )}

      <main className="w-full max-w-md bg-white shadow-xl min-h-screen border-x border-[#D5E2D7] flex flex-col justify-between font-sans">
        <div>
          <header className="bg-[#193D22] text-[#FAF3E6] p-6 relative overflow-hidden">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 border border-white/15 text-[10px] font-bold text-[#A7F3D0] mb-3">
              <img src="/logo_icon.png" alt="WISGO" className="w-3.5 h-3.5 object-contain" />
              <span>WISGO · UNDANGAN TRIP GO SUMBAR</span>
            </div>

            <div className="font-mono text-[11px] text-[#E65F2B] font-bold tracking-wider">
              KODE TRIP GO: {group?.group_code || selectedGroupCode}
            </div>

            <h1 className="mt-1 text-xl font-extrabold leading-tight tracking-tight">
              {group?.group_name || 'Trip Go Keluarga Serumpun Ranah Minang'}
            </h1>

            <div className="mt-4 pt-3 border-t border-white/10 flex items-center justify-between text-xs text-[#E4E9DA]/90">
              <div className="flex items-center gap-1.5">
                <Calendar className="w-3.5 h-3.5 text-[#F26B4B]" />
                <span>{group?.trip_dates || '28 – 30 November 2026'}</span>
              </div>
              <div className="font-bold text-[#A7F3D0]">{memberCount} Peserta</div>
            </div>

            <div className="mt-2 text-xs text-[#E4E9DA]/80">
              Host Trip Go:{' '}
              <span className="font-bold text-white">
                {group?.leader_name || 'Uda Hendra (Pokdarwis)'}
              </span>
            </div>
          </header>

          <div className="p-5 space-y-6">
            {/* Kalkulator Patungan (Kurs konsisten Rp 3.300 / MYR) */}
            <section className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-xs font-extrabold text-[#234B24] flex items-center gap-1.5 uppercase tracking-wide">
                  <Calculator className="w-4 h-4 text-[#234B24]" />
                  <span>Kalkulator Patungan Trip Go</span>
                </h2>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
                  Escrow Aman
                </span>
              </div>

              <div className="grid grid-cols-2 gap-2 text-xs">
                <div>
                  <span className="text-[10px] text-[#4A5248]">Total Biaya Paket:</span>
                  <div className="font-extrabold text-sm text-[#1B1F1A]">
                    Rp {estimatedTotalCost.toLocaleString('id-ID')}
                  </div>
                </div>
                <div>
                  <span className="text-[10px] text-[#4A5248]">
                    Jumlah Peserta ({memberCount} Org):
                  </span>
                  <div className="flex items-center gap-2 mt-0.5">
                    <button
                      type="button"
                      onClick={() => setMemberCount((prev) => Math.max(2, prev - 1))}
                      className="w-6 h-6 rounded bg-[#234B24] text-white font-bold text-xs flex items-center justify-center"
                    >
                      -
                    </button>
                    <span className="font-bold text-sm">{memberCount}</span>
                    <button
                      type="button"
                      onClick={() => setMemberCount((prev) => Math.min(20, prev + 1))}
                      className="w-6 h-6 rounded bg-[#234B24] text-white font-bold text-xs flex items-center justify-center"
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-white border border-[#CFD8BE] flex items-center justify-between">
                <span className="text-xs font-bold text-[#4A5248]">Estimasi per Orang:</span>
                <div className="text-right">
                  <div className="text-sm font-extrabold text-[#234B24]">
                    Rp {costPerPersonIDR.toLocaleString('id-ID')}
                  </div>
                  <div className="text-[10px] text-[#1E9E5A] font-semibold">
                    ± RM {costPerPersonMYR} MYR (Kurs Rp 3.300)
                  </div>
                </div>
              </div>
            </section>

            {/* Jadwal Perjalanan */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Clock className="w-4 h-4 text-[#234B24]" />
                  <span>Rencana Itinerary Trip Go</span>
                </h2>
                <button
                  type="button"
                  onClick={() => setShowItinerary(!showItinerary)}
                  className="text-xs font-bold text-[#234B24] flex items-center gap-0.5"
                >
                  <span>{showItinerary ? 'Tutup' : 'Lihat'}</span>
                  {showItinerary ? (
                    <ChevronUp className="w-3.5 h-3.5" />
                  ) : (
                    <ChevronDown className="w-3.5 h-3.5" />
                  )}
                </button>
              </div>

              {showItinerary && (
                <div className="space-y-2">
                  {SEVEN_DAY_ITINERARY.map((item) => (
                    <div
                      key={item.day}
                      className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] flex items-start gap-3"
                    >
                      <div className="w-7 h-7 rounded-lg bg-[#234B24] text-white text-xs font-extrabold flex items-center justify-center shrink-0">
                        H{item.day}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="text-xs font-extrabold text-[#1B1F1A]">{item.title}</div>
                        <div className="text-[11px] text-[#4A5248] mt-0.5 leading-snug">
                          {item.desc}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </section>

            {/* Polling Aktivitas */}
            <section className="space-y-3">
              <div className="flex items-center justify-between">
                <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-[#F26B4B]" />
                  <span>Live Voting Aktivitas Trip Go</span>
                </h2>
              </div>

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
                          <span className="font-extrabold text-[#234B24] text-xs">
                            {item.votes_count} Suara
                          </span>
                          {item.is_winner && (
                            <span className="text-[10px] font-extrabold text-[#CA8A04] flex items-center gap-0.5">
                              <Award className="w-3 h-3" />
                              <span>Pilihan Terbanyak</span>
                            </span>
                          )}
                        </div>
                      </div>

                      <button
                        type="button"
                        onClick={() => handleVote(item.id)}
                        disabled={hasVoted}
                        className={`min-h-[40px] px-3.5 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 shrink-0 transition ${hasVoted
                            ? 'bg-[#DCFCE7] text-[#166534] border border-[#86EFAC]'
                            : 'bg-[#F26B4B] hover:bg-[#D95637] text-white shadow-xs'
                          }`}
                      >
                        <ThumbsUp className="w-3.5 h-3.5" />
                        <span>{hasVoted ? 'Tervote' : 'Vote'}</span>
                      </button>
                    </div>
                  );
                })}
              </div>
            </section>

            <div className="p-3.5 rounded-2xl bg-[#E4E9DA]/70 border border-[#CFD8BE] flex items-start gap-3">
              <ShieldCheck className="w-5 h-5 text-[#234B24] shrink-0 mt-0.5" />
              <div className="text-xs text-[#1B1F1A]">
                <span className="font-bold text-[#234B24]">
                  Kemitraan UMKM Direct P2P (0% Komisi) &amp; Escrow Trip Go:
                </span>{' '}
                Dana patungan Trip Go dilindungi rekening penampung WISGO, sedangkan belanja langsung ke UMKM nagari 100% tanpa potongan.
              </div>
            </div>
          </div>
        </div>

        <footer className="p-5 bg-[#F6F3EC] border-t border-[#CFD8BE] space-y-2.5">
          <button
            type="button"
            onClick={() =>
              showToast('Membuka aplikasi mobile WISGO untuk bergabung ke grup Trip Go...', 'info')
            }
            className="w-full h-[52px] rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-sm font-extrabold flex items-center justify-center gap-2 shadow-md transition"
          >
            <Users className="w-4 h-4 text-[#A7F3D0]" />
            <span>Gabung Trip Go di Aplikasi WISGO</span>
          </button>

          <p className="text-center text-[10px] text-[#767676]">
            Dinas Pariwisata Provinsi Sumatera Barat · WISGO Ekosistem Pintar
          </p>
        </footer>
      </main>
    </div>
  );
};
