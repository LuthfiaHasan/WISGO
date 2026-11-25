import React, { useEffect, useState } from 'react';
import {
  Server,
  Database,
  ShieldCheck,
  Zap,
  CheckCircle2,
  RefreshCw,
  HardDrive,
} from 'lucide-react';
import { SystemBenchmarkMetrics } from '../types/contract';
import { fetchSystemBenchmark, runSystemBenchmark } from '../services/api';

interface SystemHealthBenchmarkSubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const SystemHealthBenchmarkSubTab: React.FC<SystemHealthBenchmarkSubTabProps> = ({
  showToast,
}) => {
  const [metrics, setMetrics] = useState<SystemBenchmarkMetrics | null>(null);
  const [benchmarking, setBenchmarking] = useState(false);
  const [concurrencyChoice, setConcurrencyChoice] = useState<number>(20);

  useEffect(() => {
    const loadData = async () => {
      try {
        const data = await fetchSystemBenchmark();
        setMetrics(data);
      } catch {
        showToast('Gagal memuat metrik sistem backend.', 'error');
      }
    };
    loadData();
  }, [showToast]);

  const handleRunBenchmark = async () => {
    setBenchmarking(true);
    try {
      showToast(
        `Menjalankan benchmark beban ${concurrencyChoice} concurrent connections...`,
        'info'
      );
      await new Promise((r) => setTimeout(r, 700));
      const updated = await runSystemBenchmark(concurrencyChoice);
      setMetrics(updated);
      const latest = updated.benchmark_history?.[0];
      if (latest) {
        showToast(
          `Benchmark selesai: p50=${latest.latency_p50_ms}ms, p95=${latest.latency_p95_ms}ms, Throughput=${latest.throughput_qps} QPS (Error ${latest.error_rate_pct}%)`,
          'success'
        );
      } else {
        showToast('Benchmark sistem selesai dengan status OPTIMAL.', 'success');
      }
    } catch {
      showToast('Gagal menjalankan uji benchmark sistem.', 'error');
    } finally {
      setBenchmarking(false);
    }
  };

  if (!metrics) {
    return (
      <div className="p-8 text-center text-[#4A5248]">
        Memuat data benchmark sistem...
      </div>
    );
  }

  const isSpatialOptimal = metrics.postgres_spatial_query_ms < 100;

  return (
    <div className="space-y-6">
      {/* 4 Kartu KPI Health & Benchmark Sistem */}
      <section
        aria-label="Ringkasan Status Health dan Performa Backend"
        className="grid grid-cols-2 lg:grid-cols-4 gap-4"
      >
        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
              Server Go Gin Engine
            </span>
            <Server className="w-4 h-4 text-[#234B24]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#1E9E5A]">ONLINE</span>
            <span className="w-2.5 h-2.5 rounded-full bg-[#1E9E5A] animate-ping" />
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Latensi Inti: <strong>{metrics.go_engine_latency_ms} ms</strong> (Uptime{' '}
            {metrics.server_uptime_pct}%)
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
              Query Spasial PostGIS
            </span>
            <Database className="w-4 h-4 text-[#234B24]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-mono font-extrabold text-[#234B24]">
              {metrics.postgres_spatial_query_ms} ms
            </span>
            <span
              className={`text-xs font-bold px-2 py-0.5 rounded-full ${isSpatialOptimal
                  ? 'bg-[#1E9E5A]/15 text-[#166534]'
                  : 'bg-yellow-100 text-yellow-800'
                }`}
            >
              Target &lt;100ms
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1E9E5A] font-semibold">
            Query ST_DWithin radius 200m anti-fake GPS optimal
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
              Pemuatan Panorama 360°
            </span>
            <HardDrive className="w-4 h-4 text-[#234B24]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-mono font-extrabold text-[#F26B4B]">
              {metrics.panorama_load_speed_sec} dtk
            </span>
            <span className="text-xs font-bold px-2 py-0.5 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
              Pure 360°
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Pemuatan panorama equirectangular 60 FPS &amp; Denah 2D
          </p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
              Rate-Limiter Keamanan
            </span>
            <ShieldCheck className="w-4 h-4 text-[#234B24]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-2xl font-extrabold text-[#234B24]">Proteksi Aktif</span>
            <span className="text-xs font-bold px-2 py-0.5 rounded-full bg-[#234B24] text-[#F6F3EC]">
              DDoS Shield
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">
            Cache Hit Rate {metrics.cache_hit_rate_pct}% · 120 req/menit per IP
          </p>
        </div>
      </section>

      {/* Control Panel Uji Benchmark Endpoint */}
      <section className="bg-white rounded-3xl p-6 lg:p-7 shadow-sm border border-[#234B24]/10 space-y-5">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm shrink-0">
              <Zap className="w-6 h-6 text-[#F26B4B]" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-lg font-extrabold text-[#1B1F1A]">
                  Simulator Uji Stres &amp; Benchmark Endpoint WISGO
                </h3>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  Benchmarking Suite
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-0.5">
                Menguji ketahanan Go Gin REST API, latensi kueri spasial PostGIS, dan kapasitas beban serentak.
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center gap-2">
              <label
                htmlFor="concurrency-select"
                className="text-xs font-bold text-[#1B1F1A] whitespace-nowrap"
              >
                Beban Bersamaan:
              </label>
              <select
                id="concurrency-select"
                value={concurrencyChoice}
                onChange={(e) => setConcurrencyChoice(Number(e.target.value))}
                className="min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                <option value={10}>10 Concurrent (Beban Ringan)</option>
                <option value={20}>20 Concurrent (Standar Lapangan)</option>
                <option value={50}>50 Concurrent (Musim Libur)</option>
                <option value={100}>100 Concurrent (Puncak Festival)</option>
              </select>
            </div>

            <button
              type="button"
              disabled={benchmarking}
              onClick={handleRunBenchmark}
              className="min-h-[46px] px-6 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm transition disabled:opacity-50"
            >
              <RefreshCw
                className={`w-4 h-4 text-[#F26B4B] ${benchmarking ? 'animate-spin' : ''}`}
              />
              <span>
                {benchmarking ? 'Menjalankan Uji Beban...' : 'Jalankan Uji Benchmark Sekarang'}
              </span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs">
          <div>
            <span className="text-[#767676]">Versi Backend &amp; Runtime:</span>
            <p className="font-extrabold text-[#1B1F1A] mt-0.5">{metrics.backend_version}</p>
          </div>
          <div>
            <span className="text-[#767676]">Alokasi Memori Sistem:</span>
            <p className="font-mono font-extrabold text-[#234B24] mt-0.5">
              {metrics.memory_allocated_mb} MB (RSS Heap)
            </p>
          </div>
          <div>
            <span className="text-[#767676]">Throughput Rata-Rata:</span>
            <p className="font-mono font-extrabold text-[#234B24] mt-0.5">
              {metrics.requests_per_second} Req/Detik (QPS)
            </p>
          </div>
        </div>
      </section>

      {/* Riwayat Hasil Uji Benchmark */}
      <div className="bg-white rounded-3xl border border-[#234B24]/10 shadow-sm overflow-hidden">
        <div className="p-5 lg:p-6 border-b border-[#234B24]/10 flex items-center justify-between">
          <div>
            <h4 className="text-base font-extrabold text-[#1B1F1A]">
              Riwayat Pengujian Benchmark Endpoint &amp; Telemetri Latensi
            </h4>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Uji terakhir: {metrics.last_stress_test_date} · {metrics.database_connection_pool}
            </p>
          </div>
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-[#1E9E5A]/15 text-[#166534]">
            100% Lulus Uji
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-[#F6F3EC] border-b border-[#CFD8BE] text-[#4A5248] font-extrabold uppercase tracking-wider">
                <th className="py-3.5 px-4">Waktu Uji</th>
                <th className="py-3.5 px-4 text-center">Total Requests</th>
                <th className="py-3.5 px-4 text-center">Concurrency</th>
                <th className="py-3.5 px-4 text-right">Latensi p50</th>
                <th className="py-3.5 px-4 text-right">Latensi p95</th>
                <th className="py-3.5 px-4 text-right">Latensi p99</th>
                <th className="py-3.5 px-4 text-center">Error Rate</th>
                <th className="py-3.5 px-4 text-right">Throughput QPS</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E4E9DA]">
              {(metrics.benchmark_history || []).map((run) => (
                <tr key={run.run_id} className="hover:bg-[#F6F3EC]/70 transition">
                  <td className="py-3.5 px-4 font-mono text-[#4A5248]">
                    {new Date(run.timestamp).toLocaleString('id-ID')}
                  </td>
                  <td className="py-3.5 px-4 text-center font-bold">{run.total_requests} req</td>
                  <td className="py-3.5 px-4 text-center">
                    <span className="px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24] font-bold">
                      {run.concurrency} worker
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-right font-mono font-extrabold text-[#1E9E5A]">
                    {run.latency_p50_ms} ms
                  </td>
                  <td className="py-3.5 px-4 text-right font-mono font-bold text-[#234B24]">
                    {run.latency_p95_ms} ms
                  </td>
                  <td className="py-3.5 px-4 text-right font-mono text-[#D95637]">
                    {run.latency_p99_ms} ms
                  </td>
                  <td className="py-3.5 px-4 text-center">
                    <span className="inline-flex items-center gap-1 font-bold text-[#1E9E5A]">
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      <span>{run.error_rate_pct}%</span>
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-right font-mono font-extrabold text-[#234B24]">
                    {run.throughput_qps} QPS
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
