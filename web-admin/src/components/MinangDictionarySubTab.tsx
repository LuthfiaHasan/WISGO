import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  AlertTriangle,
  BookOpen,
  Compass,
  Edit3,
  HeartHandshake,
  Pause,
  Play,
  Plus,
  Search,
  ShoppingBag,
  Trash2,
  Utensils,
  Volume2,
  X,
} from 'lucide-react';
import {
  MinangPhrase,
  MinangPhraseCategory,
  MinangPolitenessLevel,
} from '../types/contract';
import { MinangPhrasesRepo } from '../services/dbRepository';

interface MinangDictionarySubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const PHRASE_CATEGORIES: MinangPhraseCategory[] = [
  'Kuliner',
  'Pasar & Belanja',
  'Sapaan Nagari',
  'Arah & Navigasi',
];

const KATO_NAN_AMPEK_LEVELS: { value: MinangPolitenessLevel; label: string }[] = [
  { value: 'Kato Mandaki', label: 'Kato Mandaki (Kepada yang lebih tua / Tetua)' },
  { value: 'Kato Mandata', label: 'Kato Mandata (Kepada sebaya / Pedagang)' },
  { value: 'Kato Manurun', label: 'Kato Manurun (Kepada yang lebih muda)' },
  { value: 'Kato Malereang', label: 'Kato Malereang (Kiasan halus / Penuh hormat)' },
];

export const MinangDictionarySubTab: React.FC<MinangDictionarySubTabProps> = ({
  showToast,
}) => {
  const [phrases, setPhrases] = useState<MinangPhrase[]>(() => MinangPhrasesRepo.getAll());
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [currentlyPlayingId, setCurrentlyPlayingId] = useState<string | null>(null);

  const [editingPhrase, setEditingPhrase] = useState<MinangPhrase | null>(null);
  const [isNewPhrase, setIsNewPhrase] = useState(false);
  const [deletingPhrase, setDeletingPhrase] = useState<MinangPhrase | null>(null);

  const editorDialogRef = useRef<HTMLDialogElement>(null);
  const deleteDialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    return () => {
      if ('speechSynthesis' in window) window.speechSynthesis.cancel();
    };
  }, []);

  useEffect(() => {
    const dialog = editorDialogRef.current;
    if (!dialog) return;
    if (editingPhrase && !dialog.open) dialog.showModal();
    else if (!editingPhrase && dialog.open) dialog.close();
  }, [editingPhrase]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (deletingPhrase && !dialog.open) dialog.showModal();
    else if (!deletingPhrase && dialog.open) dialog.close();
  }, [deletingPhrase]);

  const handleTogglePlayAudio = (phrase: MinangPhrase) => {
    if (currentlyPlayingId === phrase.id) {
      if ('speechSynthesis' in window) window.speechSynthesis.cancel();
      setCurrentlyPlayingId(null);
      return;
    }
    if ('speechSynthesis' in window) window.speechSynthesis.cancel();

    const textToSpeak = phrase.voice_text || phrase.minang_text;
    if (!textToSpeak.trim()) {
      showToast('Teks suara TTS masih kosong.', 'warning');
      return;
    }
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(textToSpeak);
      utterance.lang = 'id-ID';
      utterance.rate = 0.9;
      utterance.pitch = 1.05;
      setCurrentlyPlayingId(phrase.id);
      utterance.onend = () => setCurrentlyPlayingId(null);
      utterance.onerror = () => setCurrentlyPlayingId(null);
      window.speechSynthesis.speak(utterance);
    } else {
      showToast('Browser tidak mendukung Web Speech API (TTS).', 'warning');
    }
  };

  const handleOpenAdd = () => {
    setIsNewPhrase(true);
    setEditingPhrase({
      id: `phr-${Date.now()}`,
      category_id: 'cat-mp-pasar',
      category: 'Pasar & Belanja',
      indonesian_text: '',
      english_text: '',
      minang_text: '',
      phonetic_guide: '',
      voice_text: '',
      dialect_note: 'Umum Sumatera Barat',
      usage_context_tip: '',
      politeness_level: 'Kato Mandata',
    });
  };

  const handleSaveSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPhrase) return;
    if (!editingPhrase.minang_text.trim() || !editingPhrase.indonesian_text.trim()) {
      showToast('Frasa Minang dan Arti Indonesia wajib diisi.', 'warning');
      return;
    }
    const updated = MinangPhrasesRepo.save({
      ...editingPhrase,
      minang_text: editingPhrase.minang_text.trim(),
      indonesian_text: editingPhrase.indonesian_text.trim(),
      phonetic_guide: (editingPhrase.phonetic_guide || editingPhrase.minang_text).trim(),
      voice_text: (editingPhrase.voice_text || editingPhrase.minang_text).trim(),
      dialect_note: (editingPhrase.dialect_note || 'Umum Sumatera Barat').trim(),
      usage_context_tip: (editingPhrase.usage_context_tip || '-').trim(),
    });
    setPhrases(updated);
    setEditingPhrase(null);
    showToast(
      isNewPhrase
        ? `Frasa "${editingPhrase.minang_text}" berhasil ditambahkan ke Kamus Audio TTS.`
        : `Perubahan frasa "${editingPhrase.minang_text}" berhasil disimpan.`,
      'success'
    );
  };

  const handleConfirmDelete = () => {
    if (!deletingPhrase) return;
    const updated = MinangPhrasesRepo.delete(deletingPhrase.id);
    setPhrases(updated);
    showToast(`Frasa "${deletingPhrase.minang_text}" berhasil dihapus dari kamus.`, 'info');
    setDeletingPhrase(null);
  };

  const filteredPhrases = useMemo(() => {
    return phrases.filter((p) => {
      const q = searchQuery.trim().toLowerCase();
      const matchQuery =
        !q ||
        p.minang_text.toLowerCase().includes(q) ||
        p.indonesian_text.toLowerCase().includes(q) ||
        (p.english_text || '').toLowerCase().includes(q) ||
        p.phonetic_guide.toLowerCase().includes(q) ||
        p.usage_context_tip.toLowerCase().includes(q);
      const matchCat = selectedCategory === 'all' || p.category === selectedCategory;
      return matchQuery && matchCat;
    });
  }, [phrases, searchQuery, selectedCategory]);

  const stats = useMemo(() => {
    const total = phrases.length;
    const shopping = phrases.filter((p) => p.category === 'Pasar & Belanja').length;
    const greetings = phrases.filter((p) => p.category === 'Sapaan Nagari').length;
    const foodAndNav = phrases.filter(
      (p) => p.category === 'Kuliner' || p.category === 'Arah & Navigasi'
    ).length;
    return { total, shopping, greetings, foodAndNav };
  }, [phrases]);

  const getCategoryBadge = (cat: MinangPhraseCategory) => {
    switch (cat) {
      case 'Pasar & Belanja':
        return { bg: 'bg-[#F26B4B]/15', text: 'text-[#D95637]', icon: <ShoppingBag className="w-3.5 h-3.5" /> };
      case 'Sapaan Nagari':
        return { bg: 'bg-[#1E9E5A]/15', text: 'text-[#166534]', icon: <HeartHandshake className="w-3.5 h-3.5" /> };
      case 'Arah & Navigasi':
        return { bg: 'bg-[#3B82F6]/15', text: 'text-[#1D4ED8]', icon: <Compass className="w-3.5 h-3.5" /> };
      case 'Kuliner':
      default:
        return { bg: 'bg-[#F59E0B]/15', text: 'text-[#B45309]', icon: <Utensils className="w-3.5 h-3.5" /> };
    }
  };

  return (
    <div className="space-y-6">
      <section className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Total Frasa Terdaftar
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">{stats.total}</span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
              Kato Nan Ampek
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">100% didukung pelafalan Text-to-Speech (TTS)</p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Pasar &amp; Belanja
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#F26B4B]">{stats.shopping}</span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
              Hari Pakan
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">Pedoman santun tawar-menawar di pasar &amp; nagari</p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Sapaan Nagari
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">{stats.greetings}</span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#234B24]/15 text-[#234B24]">
              Etika Adat
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">Kato Mandaki &amp; sapaan kepada tetua adat</p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
            Kuliner &amp; Navigasi
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">{stats.foodAndNav} Frasa</span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#234B24] text-[#F6F3EC]">
              Wisata Lapangan
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">Pemesanan RM Padang &amp; petunjuk arah surau</p>
        </div>
      </section>

      <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari frasa Minang, arti Indonesia, Inggris, atau fonetik..."
            className="w-full min-h-[46px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
          >
            <option value="all">Semua 4 Kategori FE-1</option>
            {PHRASE_CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>

          <button
            type="button"
            onClick={handleOpenAdd}
            className="min-h-[46px] px-5 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Tambah Frasa Baru</span>
          </button>
        </div>
      </div>

      <div className="bg-white rounded-3xl border border-[#234B24]/10 shadow-sm overflow-hidden">
        <div className="p-5 lg:p-6 border-b border-[#234B24]/10 flex items-center justify-between">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A]">
              Kamus Saku Audio Minang ({filteredPhrases.length} Frasa)
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Sinkron dengan AudioCultureScreen aplikasi mobile WISGO — pelafalan TTS instan.
            </p>
          </div>
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24]">
            TTS Studio Dispar
          </span>
        </div>

        {filteredPhrases.length === 0 ? (
          <div className="p-12 text-center text-[#4A5248] space-y-2">
            <BookOpen className="w-10 h-10 text-[#234B24]/40 mx-auto" />
            <p className="text-sm font-bold text-[#1B1F1A]">Tidak ada frasa cocok.</p>
          </div>
        ) : (
          <div className="divide-y divide-[#E4E9DA]">
            {filteredPhrases.map((phrase) => {
              const meta = getCategoryBadge(phrase.category);
              const isPlaying = currentlyPlayingId === phrase.id;

              return (
                <div
                  key={phrase.id}
                  className="p-5 lg:p-6 hover:bg-[#F6F3EC]/50 transition flex flex-col lg:flex-row lg:items-center justify-between gap-4"
                >
                  <div className="flex items-start gap-4 flex-1 min-w-0">
                    <button
                      type="button"
                      aria-label={isPlaying ? 'Hentikan TTS' : 'Putar pelafalan TTS'}
                      onClick={() => handleTogglePlayAudio(phrase)}
                      className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 shadow-sm transition ${isPlaying
                          ? 'bg-[#F26B4B] text-white animate-pulse'
                          : 'bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC]'
                        }`}
                    >
                      {isPlaying ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5 ml-0.5" />}
                    </button>

                    <div className="min-w-0 flex-1 space-y-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-base lg:text-lg font-extrabold text-[#1B1F1A]">
                          &ldquo;{phrase.minang_text}&rdquo;
                        </span>
                        <span
                          className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold ${meta.bg} ${meta.text}`}
                        >
                          {meta.icon}
                          <span>{phrase.category}</span>
                        </span>
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-[#234B24]/10 text-[#234B24]">
                          {phrase.politeness_level}
                        </span>
                      </div>

                      <div className="text-xs text-[#234B24] font-semibold italic">
                        Fonetik: {phrase.phonetic_guide} · <span className="not-italic text-[#4A5248]">{phrase.dialect_note}</span>
                      </div>

                      <div className="text-xs text-[#1B1F1A]">
                        <strong>Arti (ID):</strong> {phrase.indonesian_text}
                        {phrase.english_text && (
                          <span className="text-[#4A5248] ml-2">
                            • <em>(EN: {phrase.english_text})</em>
                          </span>
                        )}
                      </div>

                      {phrase.usage_context_tip && (
                        <p className="text-[11px] text-[#4A5248] bg-[#F6F3EC] p-2.5 rounded-xl border border-[#CFD8BE]/60">
                          <strong>Konteks Budaya:</strong> {phrase.usage_context_tip}
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-2 self-end lg:self-center shrink-0">
                    <button
                      type="button"
                      onClick={() => {
                        setIsNewPhrase(false);
                        setEditingPhrase({ ...phrase });
                      }}
                      className="min-h-[40px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] hover:bg-[#E4E9DA] text-xs font-bold inline-flex items-center gap-1.5"
                    >
                      <Edit3 className="w-3.5 h-3.5 text-[#234B24]" />
                      <span>Edit</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setDeletingPhrase(phrase)}
                      className="min-h-[40px] px-3.5 py-2 rounded-xl bg-white border border-[#F26B4B]/30 hover:bg-[#F26B4B]/10 text-xs font-bold text-[#D95637] inline-flex items-center gap-1.5"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>Hapus</span>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Editor Dialog */}
      <dialog
        ref={editorDialogRef}
        aria-labelledby="phrase-modal-title"
        onClose={() => setEditingPhrase(null)}
        className="w-full max-w-2xl rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {editingPhrase && (
          <form
            onSubmit={handleSaveSubmit}
            className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border border-[#CFD8BE] shadow-2xl overflow-hidden max-h-[90vh] flex flex-col"
          >
            <div className="shrink-0 bg-[#234B24] text-[#F6F3EC] px-6 py-5 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#A7F3D0]">
                  Kamus Saku Audio Minang · Kato Nan Ampek
                </span>
                <h2 id="phrase-modal-title" className="text-xl font-extrabold mt-0.5">
                  {isNewPhrase ? 'Tambah Frasa Minang Baru' : `Edit: "${editingPhrase.minang_text}"`}
                </h2>
              </div>
              <button
                type="button"
                onClick={() => setEditingPhrase(null)}
                className="w-10 h-10 rounded-full bg-white/10 hover:bg-[#F26B4B] text-white flex items-center justify-center"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex-1 min-h-0 overflow-y-auto p-6 space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Frasa Bahasa Minang *</label>
                  <input
                    type="text"
                    required
                    value={editingPhrase.minang_text}
                    onChange={(e) =>
                      setEditingPhrase({ ...editingPhrase, minang_text: e.target.value })
                    }
                    className="min-h-[44px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Panduan Fonetik *</label>
                  <input
                    type="text"
                    required
                    value={editingPhrase.phonetic_guide}
                    onChange={(e) =>
                      setEditingPhrase({ ...editingPhrase, phonetic_guide: e.target.value })
                    }
                    className="min-h-[44px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Arti Bahasa Indonesia *</label>
                  <input
                    type="text"
                    required
                    value={editingPhrase.indonesian_text}
                    onChange={(e) =>
                      setEditingPhrase({ ...editingPhrase, indonesian_text: e.target.value })
                    }
                    className="min-h-[44px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Arti Bahasa Inggris (Opsional)</label>
                  <input
                    type="text"
                    value={editingPhrase.english_text || ''}
                    onChange={(e) =>
                      setEditingPhrase({ ...editingPhrase, english_text: e.target.value })
                    }
                    className="min-h-[44px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Kategori *</label>
                  <select
                    value={editingPhrase.category}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        category: e.target.value as MinangPhraseCategory,
                      })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-xs font-bold"
                  >
                    {PHRASE_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Dialek</label>
                  <input
                    type="text"
                    value={editingPhrase.dialect_note}
                    onChange={(e) =>
                      setEditingPhrase({ ...editingPhrase, dialect_note: e.target.value })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-xs"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold">Kato Nan Ampek *</label>
                  <select
                    value={editingPhrase.politeness_level}
                    onChange={(e) =>
                      setEditingPhrase({ ...editingPhrase, politeness_level: e.target.value })
                    }
                    className="min-h-[44px] px-3 py-2 rounded-xl bg-white border border-[#767676] text-xs font-bold"
                  >
                    {KATO_NAN_AMPEK_LEVELS.map((lvl) => (
                      <option key={lvl.value} value={lvl.value}>
                        {lvl.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="p-4 rounded-2xl bg-white border border-[#CFD8BE] space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-extrabold text-[#234B24] flex items-center gap-1.5">
                    <Volume2 className="w-4 h-4" /> Skrip Pelafalan TTS (voice_text)
                  </span>
                  <button
                    type="button"
                    onClick={() => handleTogglePlayAudio(editingPhrase)}
                    className="px-3 py-1.5 rounded-xl bg-[#234B24] text-white text-xs font-bold"
                  >
                    Uji Dengar TTS
                  </button>
                </div>
                <input
                  type="text"
                  value={editingPhrase.voice_text}
                  onChange={(e) =>
                    setEditingPhrase({ ...editingPhrase, voice_text: e.target.value })
                  }
                  placeholder="Kosongkan untuk otomatis memakai Frasa Bahasa Minang"
                  className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold">Catatan Konteks Budaya</label>
                <textarea
                  rows={2}
                  value={editingPhrase.usage_context_tip}
                  onChange={(e) =>
                    setEditingPhrase({ ...editingPhrase, usage_context_tip: e.target.value })
                  }
                  className="p-3 rounded-xl bg-white border border-[#767676] text-xs"
                />
              </div>
            </div>

            <div className="shrink-0 border-t border-[#234B24]/15 bg-white px-6 py-4 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setEditingPhrase(null)}
                className="min-h-[42px] px-5 rounded-pill bg-[#F6F3EC] border border-[#767676] text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="submit"
                className="min-h-[42px] px-6 rounded-pill bg-[#234B24] text-[#F6F3EC] text-xs font-bold"
              >
                {isNewPhrase ? 'Simpan Frasa Baru' : 'Simpan Perubahan'}
              </button>
            </div>
          </form>
        )}
      </dialog>

      <dialog
        ref={deleteDialogRef}
        aria-labelledby="delete-phrase-title"
        onClose={() => setDeletingPhrase(null)}
        className="w-full max-w-md rounded-[28px] p-0 bg-transparent backdrop:bg-black/60"
      >
        {deletingPhrase && (
          <div className="bg-[#F6F3EC] text-[#1B1F1A] rounded-[28px] border border-[#CFD8BE] shadow-2xl p-6 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-[#F26B4B]/20 text-[#D95637] flex items-center justify-center">
              <AlertTriangle className="w-6 h-6" />
            </div>
            <div>
              <h3 id="delete-phrase-title" className="text-lg font-extrabold">
                Hapus Frasa dari Kamus?
              </h3>
              <p className="text-xs text-[#4A5248] mt-1">
                Frasa &ldquo;{deletingPhrase.minang_text}&rdquo; beserta skrip pelafalan TTS-nya akan dihapus dari Kamus Saku Audio Minang.
              </p>
            </div>
            <div className="flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setDeletingPhrase(null)}
                className="min-h-[40px] px-4 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmDelete}
                className="min-h-[40px] px-5 rounded-xl bg-[#D95637] text-white text-xs font-bold"
              >
                Ya, Hapus Frasa
              </button>
            </div>
          </div>
        )}
      </dialog>
    </div>
  );
};
