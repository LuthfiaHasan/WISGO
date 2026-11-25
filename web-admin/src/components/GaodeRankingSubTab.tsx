import React, { useState } from 'react';
import {
  ArrowDown,
  ArrowUp,
  CheckCircle2,
  Minus,
  RefreshCw,
  Sliders,
  Star,
} from 'lucide-react';
import { GaodeBehaviorRanking, GaodeWeightConfig } from '../types/contract';
import { GaodeRankingsRepo } from '../services/dbRepository';

interface GaodeRankingSubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const GaodeRankingSubTab: React.FC<GaodeRankingSubTabProps> = ({
  showToast,
}) => {
  const [rankings, setRankings] = useState<GaodeBehaviorRanking[]>(() =>
    GaodeRankingsRepo.getAll()
  );
  const [weights, setWeights] = useState<GaodeWeightConfig>(() =>
    GaodeRankingsRepo.getWeights()
  );
  const [isCalculating, setIsCalculating] = useState(false);

  const totalWeight =
    weights.satisfaction_weight +
    weights.pungli_free_weight +
    weights.medan_access_weight +
    weights.visit_volume_weight;

  const isWeightValid = totalWeight === 100;

  const handleWeightChange = (key: keyof GaodeWeightConfig, val: number) => {
    setWeights((prev) => ({ ...prev, [key]: val }));
  };

  const handleNormalizeWeights = () => {
    if (totalWeight === 0) return;
    const factor = 100 / totalWeight;
    const sat = Math.round(weights.satisfaction_weight * factor);
    const png = Math.round(weights.pungli_free_weight * factor);
    const med = Math.round(weights.medan_access_weight * factor);
    const vis = Math.max(5, 100 - sat - png - med);
    setWeights({
      satisfaction_weight: sat,
      pungli_free_weight: png,
      medan_access_weight: med,
      visit_volume_weight: vis,
    });
    showToast('Bobot algoritma dinormalisasi otomatis ke 100%.', 'info');
  };

  const handleRecalculate = async () => {
    setIsCalculating(true);
    try {
      await new Promise((resolve) => setTimeout(resolve, 400));
      const updated = GaodeRankingsRepo.recalculate(weights);
      setRankings(updated);
      showToast(
        `Rekalkulasi Gaode Ranking selesai. Peringkat #1: ${updated[0]?.name} (${updated[0]?.calculated_gaode_score} Poin).`,
        'success'
      );
    } finally {
      setIsCalculating(false);
    }
  };

  const getScoreBadge = (score: number) => {
    if (score >= 95) return 'bg-[#1E9E5A] text-white';
    if (score >= 90) return 'bg-[#234B24] text-white';
    if (score >= 85) return 'bg-[#CA8A04] text-white';
    return 'bg-[#F26B4B] text-white';
  };

  return (
    <div className="space-y-6">
      <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-5">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shrink-0">
              <Sliders className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-lg font-extrabold text-[#1B1F1A]">
                  Konfigurasi Bobot Algoritma Perilaku (Gaode Ranking Model)
                </h3>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  Multi-Factor Scoring
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Sesuaikan 4 parameter bobot penentu rekomendasi destinasi berintegritas di aplikasi WISGO.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 self-start lg:self-center">
            <div className="flex items-center gap-2 px-3 py-2 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs">
              <span className="text-[#4A5248]">Total Bobot:</span>
              <strong className={`font-mono text-sm ${isWeightValid ? 'text-[#1E9E5A]' : 'text-[#D95637]'}`}>
                {totalWeight}%
              </strong>
              {isWeightValid ? (
                <CheckCircle2 className="w-4 h-4 text-[#1E9E5A]" />
              ) : (
                <button
                  type="button"
                  onClick={handleNormalizeWeights}
                  className="text-[11px] font-bold text-[#D95637] underline"
                >
                  Normalisasi
                </button>
              )}
            </div>

            <button
              type="button"
              disabled={isCalculating}
              onClick={handleRecalculate}
              className="min-h-[44px] px-5 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 text-[#F26B4B] ${isCalculating ? 'animate-spin' : ''}`} />
              <span>{isCalculating ? 'Menghitung Ulang...' : 'Rekalkulasi Gaode Ranking'}</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-2">
          <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-extrabold text-[#1B1F1A]">1. Kepuasan Wisatawan</span>
              <span className="font-mono font-bold text-[#234B24]">{weights.satisfaction_weight}%</span>
            </div>
            <input
              type="range"
              min={5}
              max={60}
              value={weights.satisfaction_weight}
              onChange={(e) => handleWeightChange('satisfaction_weight', Number(e.target.value))}
              className="w-full accent-[#234B24]"
            />
            <p className="text-[10px] text-[#767676]">Rating ulasan GPS terverifikasi &amp; kenyamanan</p>
          </div>

          <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-extrabold text-[#1B1F1A]">2. Bebas Pungli</span>
              <span className="font-mono font-bold text-[#D95637]">{weights.pungli_free_weight}%</span>
            </div>
            <input
              type="range"
              min={5}
              max={60}
              value={weights.pungli_free_weight}
              onChange={(e) => handleWeightChange('pungli_free_weight', Number(e.target.value))}
              className="w-full accent-[#F26B4B]"
            />
            <p className="text-[10px] text-[#767676]">Kepatuhan tarif resmi Perda &amp; nol aduan pungli</p>
          </div>

          <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-extrabold text-[#1B1F1A]">3. Kesiapan 4 Medan</span>
              <span className="font-mono font-bold text-[#234B24]">{weights.medan_access_weight}%</span>
            </div>
            <input
              type="range"
              min={5}
              max={60}
              value={weights.medan_access_weight}
              onChange={(e) => handleWeightChange('medan_access_weight', Number(e.target.value))}
              className="w-full accent-[#234B24]"
            />
            <p className="text-[10px] text-[#767676]">Akses kendaraan, trekking, fasilitas &amp; pemandu lokal</p>
          </div>

          <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-extrabold text-[#1B1F1A]">4. Volume Kunjungan</span>
              <span className="font-mono font-bold text-[#3B82F6]">{weights.visit_volume_weight}%</span>
            </div>
            <input
              type="range"
              min={5}
              max={60}
              value={weights.visit_volume_weight}
              onChange={(e) => handleWeightChange('visit_volume_weight', Number(e.target.value))}
              className="w-full accent-[#3B82F6]"
            />
            <p className="text-[10px] text-[#767676]">Frekuensi kunjungan mingguan &amp; durasi tinggal</p>
          </div>
        </div>
      </section>

      <div className="bg-white rounded-3xl border border-[#234B24]/10 shadow-sm overflow-hidden">
        <div className="p-5 lg:p-6 border-b border-[#234B24]/10 flex items-center justify-between">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A]">
              Peringkat Resmi Gaode ({rankings.length} Destinasi Unggulan Sumatera Barat)
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Menggunakan 5 Master Kategori dan metrik perilaku nyata wisatawan WISGO.
            </p>
          </div>
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24]">
            Anti-Fake Review
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-[#F6F3EC] border-b border-[#CFD8BE] text-[#4A5248] font-extrabold uppercase tracking-wider">
                <th className="py-3.5 px-4 text-center w-16">Rank</th>
                <th className="py-3.5 px-4 text-center w-14">Tren</th>
                <th className="py-3.5 px-4 min-w-[220px]">Destinasi &amp; Kategori</th>
                <th className="py-3.5 px-4 text-right">Kunjungan / Mgg</th>
                <th className="py-3.5 px-4 text-center">Dwell Time</th>
                <th className="py-3.5 px-4 text-right">Kepuasan</th>
                <th className="py-3.5 px-4 text-right">Bebas Pungli</th>
                <th className="py-3.5 px-4 text-center">Medan</th>
                <th className="py-3.5 px-4 text-right">Skor Gaode</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA]">
              {rankings.map((item) => {
                const rank = item.current_rank;
                const isTop3 = rank <= 3;
                return (
                  <tr key={item.id} className={`hover:bg-[#F6F3EC]/70 ${isTop3 ? 'bg-[#FEFCE8]/40' : ''}`}>
                    <td className="py-3.5 px-4 text-center font-extrabold">
                      <span
                        className={`inline-flex items-center justify-center w-7 h-7 rounded-xl font-extrabold text-xs ${rank === 1
                            ? 'bg-[#EAB308] text-white'
                            : rank === 2
                              ? 'bg-neutral-400 text-white'
                              : rank === 3
                                ? 'bg-[#B45309] text-white'
                                : 'bg-[#F6F3EC] text-[#1B1F1A] border border-[#CFD8BE]'
                          }`}
                      >
                        #{rank}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      {item.trend === 'up' && <ArrowUp className="w-3.5 h-3.5 text-[#1E9E5A] mx-auto" />}
                      {item.trend === 'down' && <ArrowDown className="w-3.5 h-3.5 text-[#D95637] mx-auto" />}
                      {item.trend === 'same' && <Minus className="w-3.5 h-3.5 text-[#767676] mx-auto" />}
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-extrabold text-[#1B1F1A] text-sm">{item.name}</div>
                      <div className="text-[11px] text-[#4A5248] flex items-center gap-2 mt-0.5">
                        <span>{item.city_regency}</span>
                        <span>•</span>
                        <span className="px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24] font-semibold text-[10px]">
                          {item.category}
                        </span>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 text-right font-mono font-bold">
                      {item.weekly_visits.toLocaleString('id-ID')}
                    </td>
                    <td className="py-3.5 px-4 text-center text-[#4A5248]">
                      ± {item.avg_dwell_hours} Jam
                    </td>
                    <td className="py-3.5 px-4 text-right font-mono font-bold text-[#1E9E5A]">
                      {item.satisfaction_rate}%
                    </td>
                    <td className="py-3.5 px-4 text-right font-mono font-bold text-[#234B24]">
                      {item.pungli_free_index}%
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      <span className="inline-flex items-center gap-1 font-bold">
                        <Star className="w-3.5 h-3.5 text-[#EAB308] fill-[#EAB308]" />
                        {item.medan_score}/5
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <span
                        className={`inline-block px-3 py-1 rounded-xl text-xs font-mono font-extrabold ${getScoreBadge(
                          item.calculated_gaode_score
                        )}`}
                      >
                        {item.calculated_gaode_score}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
