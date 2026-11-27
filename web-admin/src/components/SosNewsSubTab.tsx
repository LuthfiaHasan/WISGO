import React, { useMemo, useState } from 'react';
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
  X,
} from 'lucide-react';
import { SosNewsCategory, SosNewsItem, SosNewsSeverity } from '../types/contract';
import { SosNewsRepo } from '../services/dbRepository';

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

export const SosNewsSubTab: React.FC<SosNewsSubTabProps> = ({
  newsList,
  onChangeNews,
  showToast,
}) => {
  const [search, setSearch] = useState('');
  const [catFilter, setCatFilter] = useState<'ALL' | SosNewsCategory>('ALL');
  const [editing, setEditing] = useState<SosNewsItem | null>(null);
  const [isNew, setIsNew] = useState(false);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return newsList.filter((item) => {
      const matchCat = catFilter === 'ALL' || item.category === catFilter;
      const matchQ =
        !q ||
        item.title.toLowerCase().includes(q) ||
        item.region.toLowerCase().includes(q) ||
        item.summary.toLowerCase().includes(q) ||
        item.source.toLowerCase().includes(q);
      return matchCat && matchQ;
    });
  }, [newsList, search, catFilter]);

  const openNew = () => {
    setIsNew(true);
    setEditing({
      id: `news-${Date.now()}`,
      category: 'Akses Wisata',
      severity: 'INFO WISATA',
      title: '',
      region: 'Sumatera Barat',
      summary: '',
      advice: '',
      source: 'Dinas Pariwisata Provinsi Sumbar',
      is_published: true,
      published_at: new Date().toISOString(),
    });
  };

  const openEdit = (item: SosNewsItem) => {
    setIsNew(false);
    setEditing({ ...item });
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editing || !editing.title.trim() || !editing.summary.trim()) {
      showToast('Judul dan ringkasan berita wajib diisi.', 'warning');
      return;
    }
    const updated = SosNewsRepo.save({
      ...editing,
      title: editing.title.trim(),
      region: editing.region.trim() || 'Sumatera Barat',
      summary: editing.summary.trim(),
      advice: editing.advice.trim(),
      source: editing.source.trim() || 'Dinas Pariwisata Provinsi Sumbar',
      published_at: isNew ? new Date().toISOString() : editing.published_at,
    });
    onChangeNews(updated);
    showToast(
      isNew ? 'Berita Wisata & Bencana berhasil diterbitkan.' : 'Berita berhasil diperbarui.',
      'success'
    );
    setEditing(null);
  };

  const handleDelete = (item: SosNewsItem) => {
    if (!window.confirm(`Hapus berita "${item.title}"?`)) return;
    onChangeNews(SosNewsRepo.delete(item.id));
    showToast('Berita dihapus.', 'info');
  };

  const handleToggle = (item: SosNewsItem) => {
    onChangeNews(SosNewsRepo.togglePublish(item.id));
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

  return (
    <section className="space-y-4">
      <div className="bg-white rounded-2xl p-5 border border-[#234B24]/10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
            <Newspaper className="w-4 h-4 text-[#234B24]" />
            <span>Berita Wisata &amp; Bencana Sumbar</span>
          </h2>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Tampil langsung pada halaman Siaga SOS aplikasi Mobile untuk memberi informasi resmi BMKG, PVMBG, BPBD, dan Dispar.
          </p>
        </div>
        <button
          type="button"
          onClick={openNew}
          className="h-10 px-4 rounded-xl bg-[#234B24] hover:bg-[#1a391b] text-white text-xs font-bold inline-flex items-center gap-2 shrink-0"
        >
          <Plus className="w-4 h-4" />
          <span>Terbitkan Berita Baru</span>
        </button>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Cari judul, wilayah, atau sumber berita..."
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
        {filtered.map((item) => (
          <article
            key={item.id}
            className={`bg-white rounded-2xl p-5 border transition ${
              item.is_published ? 'border-[#234B24]/12' : 'border-dashed border-gray-300 opacity-75'
            }`}
          >
            <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3">
              <div className="space-y-1.5 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold border ${severityBadge(
                      item.severity
                    )}`}
                  >
                    {item.severity}
                  </span>
                  <span className="text-[11px] font-bold text-[#234B24]">{item.category}</span>
                  <span className="text-[11px] text-[#767676] inline-flex items-center gap-1">
                    <MapPin className="w-3 h-3" /> {item.region}
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
                    <span>Imbauan: {item.advice}</span>
                  </p>
                )}
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
              </div>

              <div className="flex items-center gap-1.5 shrink-0">
                <button
                  type="button"
                  onClick={() => handleToggle(item)}
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
                  onClick={() => handleDelete(item)}
                  title="Hapus Berita"
                  className="p-2 rounded-xl border border-red-200 hover:bg-red-50 text-red-600"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          </article>
        ))}
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
                {isNew ? 'Terbitkan Berita Wisata & Bencana' : 'Ubah Berita Wisata & Bencana'}
              </h3>
              <button type="button" onClick={() => setEditing(null)}>
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 space-y-3 overflow-y-auto text-xs bg-[#F6F3EC]">
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
                  placeholder="Contoh: Status Aktivitas Gunung Marapi Level II..."
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
                  <label className="block font-bold mb-1">Sumber Resmi *</label>
                  <input
                    type="text"
                    required
                    value={editing.source}
                    onChange={(e) => setEditing({ ...editing, source: e.target.value })}
                    placeholder="Contoh: BMKG / PVMBG / BPBD Sumbar"
                    className="w-full h-10 px-3 rounded-xl bg-white border border-[#CFD8BE]"
                  />
                </div>
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
                Simpan Berita
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  );
};
