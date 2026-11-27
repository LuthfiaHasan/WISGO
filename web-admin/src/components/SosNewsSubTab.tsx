import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Newspaper,
  Plus,
  Edit3,
  Trash2,
  Eye,
  EyeOff,
  Search,
  MapPin,
  ShieldAlert,
  ExternalLink,
  RefreshCw,
  Globe,
  X,
} from 'lucide-react';
import { SosNewsCategory, SosNewsItem, SosNewsSeverity } from '../types/contract';
import { SosNewsRepo } from '../services/dbRepository';
import {
  deleteSosNewsWithBridge,
  fetchSosNewsWithBridge,
  saveSosNewsWithBridge,
} from '../services/api';

interface SosNewsSubTabProps {
  newsList: SosNewsItem[];
  onChangeNews: (updated: SosNewsItem[]) => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const CATEGORIES: SosNewsCategory[] = [
  'Bencana & Vulkanologi',
  'Cuaca & Bahari',
  'Akses Wisata',
  'Info Jalur & Bencana',
];

const SEVERITIES: SosNewsSeverity[] = ['INFO WISATA', 'WASPADA', 'SIAGA HUJAN', 'DARURAT'];

type PortalFilterType = 'ALL' | 'sumbarkita.id' | 'sumbar.antaranews.com' | 'official';

const PORTAL_PRESETS = [
  {
    domain: 'sumbarkita.id',
    label: 'Sumbarkita.id (Portal Berita Sumbar)',
    defaultSource: 'Sumbarkita.id • Redaksi Kebencanaan Sumbar',
    defaultUrl: 'https://sumbarkita.id/',
  },
  {
    domain: 'sumbar.antaranews.com',
    label: 'ANTARA Sumbar (sumbar.antaranews.com)',
    defaultSource: 'ANTARA Sumbar (sumbar.antaranews.com)',
    defaultUrl: 'https://sumbar.antaranews.com/',
  },
  {
    domain: 'dispar.sumbarprov.go.id',
    label: 'Resmi Dispar / BMKG / BPBD Sumbar',
    defaultSource: 'BPBD & Dinas Pariwisata Provinsi Sumbar',
    defaultUrl: 'https://sumbarprov.go.id/',
  },
] as const;

function resolvePortalDomain(item: SosNewsItem): string {
  if (item.portal_domain) return item.portal_domain;
  const combined = `${item.source} ${item.source_url || ''}`.toLowerCase();
  if (combined.includes('sumbarkita')) return 'sumbarkita.id';
  if (combined.includes('antara')) return 'sumbar.antaranews.com';
  return 'dispar.sumbarprov.go.id';
}

export const SosNewsSubTab: React.FC<SosNewsSubTabProps> = ({
  newsList,
  onChangeNews,
  showToast,
}) => {
  const [search, setSearch] = useState('');
  const [catFilter, setCatFilter] = useState<'ALL' | SosNewsCategory>('ALL');
  const [portalFilter, setPortalFilter] = useState<PortalFilterType>('ALL');
  const [editing, setEditing] = useState<SosNewsItem | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [isSyncingPortals, setIsSyncingPortals] = useState(false);
  const [backendOnline, setBackendOnline] = useState(false);

  const syncNewsFromBackend = useCallback(
    async (refreshLiveRSS = false) => {
      setIsSyncingPortals(true);
      try {
        const res = await fetchSosNewsWithBridge(refreshLiveRSS);
        onChangeNews(res.news);
        setBackendOnline(res.online);
        if (refreshLiveRSS) {
          showToast(
            res.online
              ? `Berhasil menyinkronkan berita Sumatera Barat dari sumbarkita.id & sumbar.antaranews.com (${res.news.length} berita aktif).`
              : 'Menampilkan berita terkurasi sumbarkita.id & sumbar.antaranews.com dari penyimpanan lokal V3.',
            'success'
          );
        }
      } finally {
        setIsSyncingPortals(false);
      }
    },
    [onChangeNews, showToast]
  );

  useEffect(() => {
    void syncNewsFromBackend(false);
  }, [syncNewsFromBackend]);

  const sumbarkitaCount = useMemo(
    () => newsList.filter((n) => resolvePortalDomain(n) === 'sumbarkita.id').length,
    [newsList]
  );
  const antaraCount = useMemo(
    () => newsList.filter((n) => resolvePortalDomain(n) === 'sumbar.antaranews.com').length,
    [newsList]
  );

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return newsList.filter((item) => {
      const domain = resolvePortalDomain(item);
      const matchPortal =
        portalFilter === 'ALL' ||
        (portalFilter === 'official'
          ? domain !== 'sumbarkita.id' && domain !== 'sumbar.antaranews.com'
          : domain === portalFilter);
      const matchCat = catFilter === 'ALL' || item.category === catFilter;
      const matchQ =
        !q ||
        item.title.toLowerCase().includes(q) ||
        item.region.toLowerCase().includes(q) ||
        item.summary.toLowerCase().includes(q) ||
        item.source.toLowerCase().includes(q) ||
        domain.toLowerCase().includes(q);
      return matchPortal && matchCat && matchQ;
    });
  }, [newsList, search, catFilter, portalFilter]);

  const openNew = (defaultPortal: 'sumbarkita.id' | 'sumbar.antaranews.com' = 'sumbarkita.id') => {
    const preset =
      PORTAL_PRESETS.find((p) => p.domain === defaultPortal) || PORTAL_PRESETS[0];
    setIsNew(true);
    setEditing({
      id: `news-${Date.now()}`,
      category: 'Info Jalur & Bencana',
      severity: 'WASPADA',
      title: '',
      region: 'Sumatera Barat',
      summary: '',
      advice: '',
      source: preset.defaultSource,
      portal_domain: preset.domain,
      source_url: preset.defaultUrl,
      is_published: true,
      published_at: new Date().toISOString(),
    });
  };

  const openEdit = (item: SosNewsItem) => {
    setIsNew(false);
    setEditing({
      ...item,
      portal_domain: resolvePortalDomain(item),
    });
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editing || !editing.title.trim() || !editing.summary.trim()) {
      showToast('Judul dan ringkasan berita wajib diisi.', 'warning');
      return;
    }
    const domain = resolvePortalDomain(editing);
    const normalizedItem: SosNewsItem = {
      ...editing,
      title: editing.title.trim(),
      region: editing.region.trim() || 'Sumatera Barat',
      summary: editing.summary.trim(),
      advice: editing.advice.trim(),
      source: editing.source.trim() || 'Sumbarkita.id • Redaksi Kebencanaan Sumbar',
      portal_domain: domain,
      source_url:
        editing.source_url?.trim() ||
        (domain === 'sumbar.antaranews.com'
          ? 'https://sumbar.antaranews.com/'
          : 'https://sumbarkita.id/'),
      published_at: isNew ? new Date().toISOString() : editing.published_at,
    };

    const { news: updated, syncedRemote } = await saveSosNewsWithBridge(normalizedItem);
    onChangeNews(updated);
    if (syncedRemote) setBackendOnline(true);
    showToast(
      isNew
        ? `Berita (${domain}) berhasil diterbitkan ke aplikasi Mobile.`
        : 'Berita Wisata & Bencana Sumbar berhasil diperbarui.',
      'success'
    );
    setEditing(null);
  };

  const handleDelete = async (item: SosNewsItem) => {
    if (!window.confirm(`Hapus berita "${item.title}"?`)) return;
    const { news: updated } = await deleteSosNewsWithBridge(item.id);
    onChangeNews(updated);
    showToast('Berita dihapus.', 'info');
  };

  const handleToggle = async (item: SosNewsItem) => {
    const toggled = SosNewsRepo.togglePublish(item.id);
    onChangeNews(toggled);
    const target = toggled.find((n) => n.id === item.id);
    if (target) {
      await saveSosNewsWithBridge(target);
    }
    showToast(
      item.is_published ? 'Berita diarsipkan dari aplikasi Mobile.' : 'Berita ditayangkan kembali.',
      'info'
    );
  };

  const severityBadge = (sev: SosNewsSeverity) => {
    if (sev === 'DARURAT') return 'bg-red-100 text-red-700 border-red-200';
    if (sev === 'WASPADA') return 'bg-amber-100 text-amber-800 border-amber-200';
    if (sev === 'SIAGA HUJAN') return 'bg-sky-100 text-sky-800 border-sky-200';
    return 'bg-[#E4E9DA] text-[#234B24] border-[#CFD8BE]';
  };

  const portalBadge = (item: SosNewsItem) => {
    const domain = resolvePortalDomain(item);
    if (domain === 'sumbarkita.id') {
      return (
        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black bg-emerald-950 text-emerald-100 border border-emerald-700 inline-flex items-center gap-1">
          <Globe className="w-3 h-3 text-emerald-300" />
          sumbarkita.id
        </span>
      );
    }
    if (domain === 'sumbar.antaranews.com') {
      return (
        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black bg-red-900 text-white border border-red-700 inline-flex items-center gap-1">
          <Globe className="w-3 h-3 text-amber-200" />
          sumbar.antaranews.com
        </span>
      );
    }
    return (
      <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#F6F3EC] text-[#234B24] border border-[#CFD8BE] inline-flex items-center gap-1">
        <Globe className="w-3 h-3" />
        BMKG / BPBD / Dispar
      </span>
    );
  };

  return (
    <section className="space-y-4">
      <div className="bg-white rounded-2xl p-5 border border-[#234B24]/10 flex flex-col lg:flex-row lg:items-center justify-between gap-4 shadow-sm">
        <div className="space-y-1">
          <div className="flex items-center gap-2 flex-wrap">
            <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <Newspaper className="w-4 h-4 text-[#234B24]" />
              <span>Berita Wisata &amp; Bencana Sumatera Barat</span>
            </h2>
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-emerald-50 text-emerald-900 border border-emerald-300">
              sumbarkita.id ({sumbarkitaCount})
            </span>
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-red-50 text-red-900 border border-red-200">
              sumbar.antaranews.com ({antaraCount})
            </span>
            {backendOnline && (
              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-sky-50 text-sky-800 border border-sky-200">
                Live Endpoint BE-1 Aktif
              </span>
            )}
          </div>
          <p className="text-xs text-[#4A5248]">
            Agregasi berita resmi kebencanaan, jalur lintas, dan info wisata dari{' '}
            <strong className="text-[#234B24]">sumbarkita.id</strong> &amp;{' '}
            <strong className="text-red-800">sumbar.antaranews.com</strong> yang tayang langsung di layar{' '}
            <code className="font-mono font-bold">hazard_sos_screen.dart</code> aplikasi Mobile.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={() => void syncNewsFromBackend(true)}
            disabled={isSyncingPortals}
            className="h-10 px-3.5 rounded-xl bg-[#F6F3EC] hover:bg-[#E4E9DA] border border-[#CFD8BE] text-[#234B24] text-xs font-bold inline-flex items-center gap-1.5 transition"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isSyncingPortals ? 'animate-spin' : ''}`} />
            <span>Tarik RSS Sumbarkita &amp; Antara</span>
          </button>
          <button
            type="button"
            onClick={() => openNew('sumbarkita.id')}
            className="h-10 px-4 rounded-xl bg-[#234B24] hover:bg-[#1a391b] text-white text-xs font-bold inline-flex items-center gap-2 shrink-0"
          >
            <Plus className="w-4 h-4" />
            <span>Terbitkan Berita Baru</span>
          </button>
        </div>
      </div>

      {/* FILTER PORTAL BERITA SUMBAR (sumbarkita.id & sumbar.antaranews.com) */}
      <div className="flex flex-wrap items-center gap-2">
        <button
          type="button"
          onClick={() => setPortalFilter('ALL')}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-bold border transition ${
            portalFilter === 'ALL'
              ? 'bg-[#234B24] text-white border-[#234B24]'
              : 'bg-white text-[#4A5248] border-[#CFD8BE] hover:bg-[#F6F3EC]'
          }`}
        >
          Semua Sumber ({newsList.length})
        </button>
        <button
          type="button"
          onClick={() => setPortalFilter('sumbarkita.id')}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-bold border transition inline-flex items-center gap-1.5 ${
            portalFilter === 'sumbarkita.id'
              ? 'bg-emerald-950 text-white border-emerald-950'
              : 'bg-white text-emerald-950 border-emerald-300 hover:bg-emerald-50'
          }`}
        >
          <Globe className="w-3.5 h-3.5" />
          <span>Sumbarkita.id ({sumbarkitaCount})</span>
        </button>
        <button
          type="button"
          onClick={() => setPortalFilter('sumbar.antaranews.com')}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-bold border transition inline-flex items-center gap-1.5 ${
            portalFilter === 'sumbar.antaranews.com'
              ? 'bg-red-900 text-white border-red-900'
              : 'bg-white text-red-900 border-red-200 hover:bg-red-50'
          }`}
        >
          <Globe className="w-3.5 h-3.5" />
          <span>ANTARA Sumbar • sumbar.antaranews.com ({antaraCount})</span>
        </button>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Cari judul, wilayah (Marapi, Lembah Anai, Sitinjau, Mandeh), sumbarkita.id, atau antaranews..."
            className="w-full h-10 pl-9 pr-3 rounded-xl bg-white border border-[#CFD8BE] text-xs"
          />
        </div>
        <select
          value={catFilter}
          onChange={(e) => setCatFilter(e.target.value as 'ALL' | SosNewsCategory)}
          className="h-10 px-3 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
        >
          <option value="ALL">Semua Kategori ({newsList.length})</option>
          {CATEGORIES.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-1 gap-3">
        {filtered.map((item) => {
          const domain = resolvePortalDomain(item);
          const articleUrl =
            item.source_url ||
            (domain === 'sumbar.antaranews.com'
              ? 'https://sumbar.antaranews.com/'
              : 'https://sumbarkita.id/');

          return (
            <article
              key={item.id}
              className={`bg-white rounded-2xl p-5 border transition ${
                item.is_published ? 'border-[#234B24]/12' : 'border-dashed border-gray-300 opacity-75'
              }`}
            >
              <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3">
                <div className="space-y-1.5 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    {portalBadge(item)}
                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold border ${severityBadge(
                        item.severity
                      )}`}
                    >
                      {item.severity}
                    </span>
                    <span className="text-[11px] font-bold text-[#234B24]">{item.category}</span>
                    <span className="text-[11px] text-[#767676] inline-flex items-center gap-1">
                      <MapPin className="w-3 h-3 text-[#F26B4B]" /> {item.region}
                    </span>
                    {!item.is_published && (
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-gray-100 text-gray-600">
                        Diarsipkan
                      </span>
                    )}
                  </div>
                  <h3 className="text-sm font-extrabold text-[#1B1F1A]">{item.title}</h3>
                  <p className="text-xs text-[#4A5248] leading-relaxed">{item.summary}</p>
                  {item.advice && (
                    <p className="text-xs text-[#234B24] font-semibold flex items-start gap-1.5 pt-1">
                      <ShieldAlert className="w-3.5 h-3.5 shrink-0 mt-0.5 text-[#F26B4B]" />
                      <span>Imbauan Wisatawan: {item.advice}</span>
                    </p>
                  )}
                  <div className="flex flex-wrap items-center justify-between gap-2 pt-1">
                    <p className="text-[11px] text-[#767676]">
                      Sumber: <strong>{item.source}</strong> ·{' '}
                      {new Date(item.published_at).toLocaleString('id-ID', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </p>
                    <a
                      href={articleUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-[11px] font-extrabold text-[#234B24] hover:underline inline-flex items-center gap-1"
                    >
                      <span>Baca di {domain}</span>
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <button
                    type="button"
                    onClick={() => void handleToggle(item)}
                    title={item.is_published ? 'Arsipkan' : 'Tayangkan'}
                    className="p-2 rounded-xl border border-[#CFD8BE] hover:bg-[#F6F3EC] text-[#234B24]"
                  >
                    {item.is_published ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                  <button
                    type="button"
                    onClick={() => openEdit(item)}
                    title="Ubah Berita"
                    className="p-2 rounded-xl border border-[#CFD8BE] hover:bg-[#F6F3EC] text-[#234B24]"
                  >
                    <Edit3 className="w-4 h-4" />
                  </button>
                  <button
                    type="button"
                    onClick={() => void handleDelete(item)}
                    title="Hapus Berita"
                    className="p-2 rounded-xl border border-red-200 hover:bg-red-50 text-red-600"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </article>
          );
        })}
        {filtered.length === 0 && (
          <div className="bg-white rounded-2xl p-8 border border-[#CFD8BE] text-center text-xs text-[#4A5248]">
            Belum ada berita yang sesuai filter.
          </div>
        )}
      </div>

      {editing && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60"
        >
          <form
            onSubmit={handleSave}
            className="bg-white rounded-[28px] w-full max-w-lg max-h-[90vh] flex flex-col overflow-hidden shadow-2xl"
          >
            <div className="px-6 py-4 bg-[#234B24] text-white flex items-center justify-between">
              <h3 className="text-sm font-extrabold">
                {isNew ? 'Terbitkan Berita Wisata & Bencana Sumbar' : 'Ubah Berita Wisata & Bencana'}
              </h3>
              <button type="button" onClick={() => setEditing(null)}>
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 space-y-3 overflow-y-auto text-xs bg-[#F6F3EC]">
              <div>
                <label className="block font-bold mb-1">Portal Berita Resmi Sumatera Barat *</label>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                  {PORTAL_PRESETS.map((preset) => {
                    const active = resolvePortalDomain(editing) === preset.domain;
                    return (
                      <button
                        key={preset.domain}
                        type="button"
                        onClick={() =>
                          setEditing({
                            ...editing,
                            portal_domain: preset.domain,
                            source: preset.defaultSource,
                            source_url: editing.source_url || preset.defaultUrl,
                          })
                        }
                        className={`p-2.5 rounded-xl border text-left font-bold transition ${
                          active
                            ? 'bg-[#234B24] text-white border-[#234B24]'
                            : 'bg-white text-[#1B1F1A] border-[#CFD8BE]'
                        }`}
                      >
                        <div className="text-[11px] font-extrabold">{preset.domain}</div>
                        <div className={`text-[10px] ${active ? 'text-white/80' : 'text-[#767676]'}`}>
                          {preset.label.split(' (')[0]}
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold mb-1">Kategori *</label>
                  <select
                    value={editing.category}
                    onChange={(e) =>
                      setEditing({ ...editing, category: e.target.value as SosNewsCategory })
                    }
                    className="w-full h-10 px-3 rounded-xl bg-white border border-[#CFD8BE] font-semibold"
                  >
                    {CATEGORIES.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block font-bold mb-1">Tingkat Siaga *</label>
                  <select
                    value={editing.severity}
                    onChange={(e) =>
                      setEditing({ ...editing, severity: e.target.value as SosNewsSeverity })
                    }
                    className="w-full h-10 px-3 rounded-xl bg-white border border-[#CFD8BE] font-semibold"
                  >
                    {SEVERITIES.map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block font-bold mb-1">Judul Berita *</label>
                <input
                  type="text"
                  required
                  value={editing.title}
                  onChange={(e) => setEditing({ ...editing, title: e.target.value })}
                  placeholder="Contoh: PVMBG: Gunung Marapi Sumbar Masih Berstatus Waspada Level II..."
                  className="w-full h-10 px-3 rounded-xl bg-white border border-[#CFD8BE]"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold mb-1">Wilayah Terdampak *</label>
                  <input
                    type="text"
                    required
                    value={editing.region}
                    onChange={(e) => setEditing({ ...editing, region: e.target.value })}
                    placeholder="Contoh: Kab. Agam & Tanah Datar"
                    className="w-full h-10 px-3 rounded-xl bg-white border border-[#CFD8BE]"
                  />
                </div>
                <div>
                  <label className="block font-bold mb-1">Label Sumber Redaksi *</label>
                  <input
                    type="text"
                    required
                    value={editing.source}
                    onChange={(e) => setEditing({ ...editing, source: e.target.value })}
                    placeholder="Contoh: Sumbarkita.id / ANTARA Sumbar"
                    className="w-full h-10 px-3 rounded-xl bg-white border border-[#CFD8BE]"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold mb-1">
                  URL Artikel Berita (sumbarkita.id / sumbar.antaranews.com)
                </label>
                <input
                  type="url"
                  value={editing.source_url || ''}
                  onChange={(e) => setEditing({ ...editing, source_url: e.target.value })}
                  placeholder="https://sumbarkita.id/... atau https://sumbar.antaranews.com/..."
                  className="w-full h-10 px-3 rounded-xl bg-white border border-[#CFD8BE] font-mono text-[11px]"
                />
              </div>

              <div>
                <label className="block font-bold mb-1">Ringkasan Informasi *</label>
                <textarea
                  rows={3}
                  required
                  value={editing.summary}
                  onChange={(e) => setEditing({ ...editing, summary: e.target.value })}
                  className="w-full p-3 rounded-xl bg-white border border-[#CFD8BE]"
                />
              </div>

              <div>
                <label className="block font-bold mb-1">Imbauan Keselamatan Wisatawan</label>
                <textarea
                  rows={2}
                  value={editing.advice}
                  onChange={(e) => setEditing({ ...editing, advice: e.target.value })}
                  className="w-full p-3 rounded-xl bg-white border border-[#CFD8BE]"
                />
              </div>
            </div>
            <div className="px-6 py-4 bg-white border-t border-[#CFD8BE] flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setEditing(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan &amp; Tayangkan Berita
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  );
};
