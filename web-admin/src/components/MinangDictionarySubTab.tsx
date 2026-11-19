import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Volume2,
  VolumeX,
  Play,
  Pause,
  Plus,
  Search,
  Edit3,
  Trash2,
  BookOpen,
  Sparkles,
  ShoppingBag,
  HeartHandshake,
  Compass,
  Utensils,
  AlertTriangle,
  X,
  CheckCircle2,
} from 'lucide-react';
import {
  MinangAudioPhrase,
  MinangPhraseCategory,
} from '../types/contract';
import {
  deleteMinangPhrase,
  fetchMinangPhrases,
  saveMinangPhrase,
} from '../services/api';

interface MinangDictionarySubTabProps {
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  onOpenCreateExternal?: boolean;
}

const PHRASE_CATEGORIES: MinangPhraseCategory[] = [
  'Belanja & Menawar',
  'Salam & Sapaan',
  'Arah & Navigasi',
  'Kuliner',
  'Darurat & Bantuan',
];

export const MinangDictionarySubTab: React.FC<MinangDictionarySubTabProps> = ({
  showToast,
}) => {
  const [phrases, setPhrases] = useState<MinangAudioPhrase[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  // Audio Playback State
  const [currentlyPlayingId, setCurrentlyPlayingId] = useState<string | null>(null);
  const activeAudioRef = useRef<HTMLAudioElement | null>(null);

  // Modal Editor & Delete Dialog State
  const [editingPhrase, setEditingPhrase] = useState<MinangAudioPhrase | null>(null);
  const [isNewPhrase, setIsNewPhrase] = useState(false);
  const [deletingPhrase, setDeletingPhrase] = useState<MinangAudioPhrase | null>(null);

  const editorDialogRef = useRef<HTMLDialogElement>(null);
  const deleteDialogRef = useRef<HTMLDialogElement>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await fetchMinangPhrases();
      setPhrases(data);
    } catch {
      showToast('Gagal memuat kamus saku audio Minang.', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    return () => {
      if (activeAudioRef.current) {
        activeAudioRef.current.pause();
      }
    };
  }, []);

  useEffect(() => {
    const dialog = editorDialogRef.current;
    if (!dialog) return;
    if (editingPhrase && !dialog.open) {
      dialog.showModal();
    } else if (!editingPhrase && dialog.open) {
      dialog.close();
    }
  }, [editingPhrase]);

  useEffect(() => {
    const dialog = deleteDialogRef.current;
    if (!dialog) return;
    if (deletingPhrase && !dialog.open) {
      dialog.showModal();
    } else if (!deletingPhrase && dialog.open) {
      dialog.close();
    }
  }, [deletingPhrase]);

  // Audio Player Handler (Text-to-Speech)
  const handleTogglePlayAudio = (phrase: MinangAudioPhrase) => {
    // If clicking on currently playing
    if (currentlyPlayingId === phrase.id) {
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
      }
      setCurrentlyPlayingId(null);
      return;
    }

    // Stop existing audio / TTS
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }

    const textToSpeak = phrase.voice_text || phrase.phrase || phrase.minang_text || '';
    if (!textToSpeak.trim()) {
      showToast('Tidak ada teks untuk diucapkan.', 'warning');
      return;
    }

    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(textToSpeak);
      utterance.lang = 'id-ID';
      utterance.rate = 0.9;
      utterance.pitch = 1.05;

      setCurrentlyPlayingId(phrase.id);
      utterance.onend = () => {
        setCurrentlyPlayingId(null);
      };
      utterance.onerror = () => {
        setCurrentlyPlayingId(null);
      };
      window.speechSynthesis.speak(utterance);
    } else {
      showToast('Perangkat/browser tidak mendukung Text-to-Speech (Web Speech API).', 'warning');
    }
  };

  const handleOpenAdd = () => {
    setIsNewPhrase(true);
    setEditingPhrase({
      id: `phr-${Date.now()}`,
      category_id: 'cat-phr-belanja',
      indonesian_text: '',
      minang_text: '',
      phonetic_guide: '',
      voice_text: '',
      dialect_note: 'Agam / Bukittinggi',
      usage_context_tip: 'Gunakan saat bertransaksi di pasar',
      politeness_level: 'Sopan',
      phrase: '',
      pronunciation: '',
      meaning_id: '',
      meaning_en: '',
      category: 'Belanja & Menawar',
      audio_url: '',
      notes: '',
      updated_at: new Date().toISOString(),
    });
  };

  const handleOpenEdit = (phrase: MinangAudioPhrase) => {
    setIsNewPhrase(false);
    setEditingPhrase({ ...phrase });
  };

  const handleSaveSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPhrase) return;
    const phraseText = (editingPhrase.phrase || editingPhrase.minang_text || '').trim();
    const meaningText = (editingPhrase.meaning_id || editingPhrase.indonesian_text || '').trim();

    if (!phraseText || !meaningText) {
      showToast('Frasa Minang dan Arti Indonesia wajib diisi.', 'warning');
      return;
    }

    const phoneticText = (editingPhrase.phonetic_guide || editingPhrase.pronunciation || phraseText).trim();
    const voiceText = (editingPhrase.voice_text || phraseText).trim();
    const dialectNote = (editingPhrase.dialect_note || 'Dialek Agam & Bukittinggi').trim();
    const politeness = editingPhrase.politeness_level || 'Sopan';
    const contextTip = (editingPhrase.usage_context_tip || editingPhrase.notes || '-').trim();

    try {
      const updated = await saveMinangPhrase({
        ...editingPhrase,
        phrase: phraseText,
        minang_text: phraseText,
        meaning_id: meaningText,
        indonesian_text: meaningText,
        phonetic_guide: phoneticText,
        pronunciation: phoneticText,
        voice_text: voiceText,
        dialect_note: dialectNote,
        politeness_level: politeness,
        usage_context_tip: contextTip,
        notes: contextTip,
        audio_url: '', // Murni Text-to-Speech (TTS)
        updated_at: new Date().toISOString(),
      });
      setPhrases(updated);
      setEditingPhrase(null);
      showToast(
        isNewPhrase
          ? `Frasa "${phraseText}" berhasil ditambahkan ke kamus TTS.`
          : `Perubahan frasa "${phraseText}" berhasil disimpan.`,
        'success'
      );
    } catch {
      showToast('Gagal menyimpan frasa ke database.', 'error');
    }
  };

  const handleConfirmDelete = async () => {
    if (!deletingPhrase) return;
    try {
      const updated = await deleteMinangPhrase(deletingPhrase.id);
      setPhrases(updated);
      showToast(`Frasa "${deletingPhrase.phrase || deletingPhrase.minang_text}" berhasil dihapus.`, 'info');
    } catch {
      showToast('Gagal menghapus frasa.', 'error');
    } finally {
      setDeletingPhrase(null);
    }
  };

  const filteredPhrases = useMemo(() => {
    return phrases.filter((p) => {
      const q = searchQuery.trim().toLowerCase();
      const pPhrase = p.phrase || p.minang_text || '';
      const pMeaningId = p.meaning_id || p.indonesian_text || '';
      const pMeaningEn = p.meaning_en || '';
      const pPron = p.pronunciation || p.phonetic_guide || '';

      const matchQuery =
        !q ||
        pPhrase.toLowerCase().includes(q) ||
        pMeaningId.toLowerCase().includes(q) ||
        pMeaningEn.toLowerCase().includes(q) ||
        pPron.toLowerCase().includes(q) ||
        (p.notes && p.notes.toLowerCase().includes(q));

      const matchCat =
        selectedCategory === 'all' || p.category === selectedCategory;

      return matchQuery && matchCat;
    });
  }, [phrases, searchQuery, selectedCategory]);

  const stats = useMemo(() => {
    const total = phrases.length;
    const shopping = phrases.filter((p) => p.category === 'Belanja & Menawar').length;
    const greetings = phrases.filter((p) => p.category === 'Salam & Sapaan').length;
    const food = phrases.filter((p) => p.category === 'Kuliner').length;
    const withTts = phrases.filter((p) => Boolean(p.voice_text || p.phrase || p.minang_text)).length;
    return { total, shopping, greetings, food, withTts };
  }, [phrases]);

  const getCategoryBadge = (cat: MinangPhraseCategory) => {
    switch (cat) {
      case 'Belanja & Menawar':
        return {
          bg: 'bg-[#F26B4B]/15',
          text: 'text-[#D95637]',
          icon: <ShoppingBag className="w-3.5 h-3.5" />,
        };
      case 'Salam & Sapaan':
        return {
          bg: 'bg-[#1E9E5A]/15',
          text: 'text-[#166534]',
          icon: <HeartHandshake className="w-3.5 h-3.5" />,
        };
      case 'Arah & Navigasi':
        return {
          bg: 'bg-[#3B82F6]/15',
          text: 'text-[#1D4ED8]',
          icon: <Compass className="w-3.5 h-3.5" />,
        };
      case 'Kuliner':
        return {
          bg: 'bg-[#F59E0B]/15',
          text: 'text-[#B45309]',
          icon: <Utensils className="w-3.5 h-3.5" />,
        };
      case 'Darurat & Bantuan':
        return {
          bg: 'bg-red-100',
          text: 'text-red-700',
          icon: <AlertTriangle className="w-3.5 h-3.5" />,
        };
      default:
        return {
          bg: 'bg-emerald-100',
          text: 'text-[#234B24]',
          icon: <HeartHandshake className="w-3.5 h-3.5" />,
        };
    }
  };

  return (
    <div className="space-y-6">
      {/* 4 Kartu KPI Ringkasan Kamus Audio */}
      <section
        aria-label="Ringkasan Statistik Kamus Audio Minang"
        className="grid grid-cols-2 lg:grid-cols-4 gap-4"
      >
        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Total Frasa Terdaftar
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.total}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#1E9E5A]/15 text-[#1E9E5A]">
              Kamus Resmi
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            {stats.total} frasa 100% didukung Text-to-Speech (TTS)
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Belanja &amp; Tawar-Menawar
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#F26B4B]">
              {stats.shopping}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#F26B4B]/15 text-[#D95637]">
              Pasar Tradisional
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Pedoman santun transaksi di Pasar Ateh &amp; sentra UMKM
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border border-[#E4E9DA] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#4A5248]">
            Salam &amp; Etika Adat
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.greetings}
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#234B24]/15 text-[#234B24]">
              Adat Basandi Syarak
            </span>
          </div>
          <p className="mt-1 text-xs text-[#4A5248]">
            Kearifan lokal menyapa pemuka adat dan tetua nagari
          </p>
        </div>

        <div className="bg-[#E4E9DA] p-5 rounded-3xl border border-[#CFD8BE] shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-[#234B24]">
            Kuliner &amp; Navigasi
          </div>
          <div className="mt-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-[#234B24]">
              {stats.food} Frasa
            </span>
            <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-[#234B24] text-[#F6F3EC]">
              Wisata Lapangan
            </span>
          </div>
          <p className="mt-1 text-xs text-[#1B1F1A]">
            Pemesanan Rumah Makan Padang &amp; arah musala terdekat
          </p>
        </div>
      </section>

      {/* Filter & Pencarian Frasa */}
      <div className="bg-white p-5 lg:p-6 rounded-3xl border border-[#E4E9DA] shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#767676]" />
          <input
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Cari frasa Minang, arti Indonesia, Inggris, atau pelafalan..."
            className="w-full min-h-[46px] pl-10 pr-4 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
          />
        </div>

        <div className="flex flex-wrap items-center gap-2.5">
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="min-h-[46px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="all">Semua Kategori Percakapan</option>
            {PHRASE_CATEGORIES.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
          </select>

          <button
            type="button"
            onClick={handleOpenAdd}
            className="min-h-[46px] px-5 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-2 shadow-sm transition"
          >
            <Plus className="w-4 h-4 text-[#F26B4B]" />
            <span>Tambah Frasa Baru</span>
          </button>
        </div>
      </div>

      {/* Daftar / Tabel Kamus Audio Minang */}
      <div className="bg-white rounded-3xl border border-[#E4E9DA] shadow-sm overflow-hidden">
        <div className="p-5 lg:p-6 border-b border-[#E4E9DA] flex items-center justify-between">
          <div>
            <h3 className="text-base font-extrabold text-[#1B1F1A]">
              Koleksi Frasa Bahasa Minang Wisatawan ({filteredPhrases.length} Frasa)
            </h3>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Dilengkapi audio penutur lokal Minang agar wisatawan dapat belajar melafalkan secara fasih dan santun.
            </p>
          </div>
          <span className="text-xs font-bold px-3 py-1 rounded-full bg-[#E4E9DA] text-[#234B24]">
            Audio Studio Dispar
          </span>
        </div>

        {filteredPhrases.length === 0 ? (
          <div className="p-12 text-center text-[#4A5248] space-y-2">
            <BookOpen className="w-10 h-10 text-[#234B24]/40 mx-auto" />
            <p className="text-sm font-bold text-[#1B1F1A]">
              Tidak ada frasa yang sesuai kriteria pencarian.
            </p>
            <p className="text-xs">
              Ubah kata kunci pencarian atau klik "+ Tambah Frasa Baru" untuk menginput kosakata baru.
            </p>
          </div>
        ) : (
          <div className="divide-y divide-[#E4E9DA]">
            {filteredPhrases.map((phrase) => {
              const meta = getCategoryBadge(phrase.category || 'Belanja & Menawar');
              const isPlaying = currentlyPlayingId === phrase.id;

              return (
                <div
                  key={phrase.id}
                  className="p-5 lg:p-6 hover:bg-[#F6F3EC]/50 transition flex flex-col lg:flex-row lg:items-center justify-between gap-4"
                >
                  <div className="flex items-start gap-4 flex-1 min-w-0">
                    {/* Tombol Play Audio Suara */}
                    <button
                      type="button"
                      aria-label={isPlaying ? 'Hentikan pemutaran audio' : 'Putar audio pelafalan frasa'}
                      onClick={() => handleTogglePlayAudio(phrase)}
                      className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 shadow-sm transition ${
                        isPlaying
                          ? 'bg-[#F26B4B] text-white animate-pulse'
                          : 'bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC]'
                      }`}
                    >
                      {isPlaying ? (
                        <Pause className="w-5 h-5" />
                      ) : (
                        <Play className="w-5 h-5 ml-0.5" />
                      )}
                    </button>

                    <div className="min-w-0 flex-1 space-y-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="text-base lg:text-lg font-extrabold text-[#1B1F1A]">
                          &ldquo;{phrase.phrase}&rdquo;
                        </span>
                        <span
                          className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold ${meta.bg} ${meta.text}`}
                        >
                          {meta.icon}
                          <span>{phrase.category}</span>
                        </span>
                        <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-[#1E9E5A]/15 text-[#166534] inline-flex items-center gap-1">
                          <Volume2 className="w-3 h-3 text-[#166534]" />
                          <span>Text-to-Speech (TTS)</span>
                        </span>
                      </div>

                      <div className="text-xs text-[#234B24] font-semibold italic flex flex-wrap items-center gap-2">
                        <span>Cara Baca: {phrase.pronunciation || phrase.phonetic_guide || phrase.phrase}</span>
                        {phrase.voice_text && phrase.voice_text !== phrase.phrase && (
                          <span className="text-[11px] text-[#4A5248] font-normal not-italic bg-white px-2 py-0.5 rounded border border-[#CFD8BE]">
                            Skrip TTS: &ldquo;{phrase.voice_text}&rdquo;
                          </span>
                        )}
                      </div>

                      <div className="flex flex-wrap items-center gap-2 text-[11px] text-[#4A5248]">
                        {phrase.dialect_note && (
                          <span className="px-2 py-0.5 rounded bg-white border border-[#CFD8BE] font-medium">
                            {phrase.dialect_note}
                          </span>
                        )}
                        {phrase.politeness_level && (
                          <span className="px-2 py-0.5 rounded bg-[#234B24]/10 text-[#234B24] font-bold">
                            Tingkat: {phrase.politeness_level}
                          </span>
                        )}
                      </div>

                      <div className="text-xs text-[#1B1F1A]">
                        <strong>Arti (ID):</strong> {phrase.meaning_id}
                        {phrase.meaning_en && (
                          <span className="text-[#4A5248] ml-2">
                            • <em>(EN: {phrase.meaning_en})</em>
                          </span>
                        )}
                      </div>

                      {phrase.notes && (
                        <p className="text-[11px] text-[#4A5248] bg-[#F6F3EC] p-2.5 rounded-xl border border-[#CFD8BE]/60">
                          <strong>Konteks Budaya:</strong> {phrase.notes}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Tombol Aksi */}
                  <div className="flex items-center gap-2 self-end lg:self-center shrink-0">
                    <button
                      type="button"
                      onClick={() => handleOpenEdit(phrase)}
                      className="min-h-[40px] px-3.5 py-2 rounded-xl bg-white border border-[#CFD8BE] hover:bg-[#E4E9DA] text-xs font-bold text-[#1B1F1A] inline-flex items-center gap-1.5 shadow-xs transition"
                    >
                      <Edit3 className="w-3.5 h-3.5 text-[#234B24]" />
                      <span>Edit</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setDeletingPhrase(phrase)}
                      className="min-h-[40px] px-3.5 py-2 rounded-xl bg-white border border-[#F26B4B]/30 hover:bg-[#F26B4B]/10 text-xs font-bold text-[#D95637] inline-flex items-center gap-1.5 shadow-xs transition"
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

      {/* =====================================================================
          MODAL TAMBAH & EDIT FRASA AUDIO MINANG
         ===================================================================== */}
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
            {/* Header Modal */}
            <div className="shrink-0 bg-[#234B24] text-[#F6F3EC] px-6 py-5 flex items-center justify-between">
              <div>
                <span className="text-[11px] font-extrabold uppercase tracking-wider text-[#A7F3D0]">
                  Kamus Saku Audio Minang ({editingPhrase.id})
                </span>
                <h2
                  id="phrase-modal-title"
                  className="text-xl font-extrabold text-[#F6F3EC] mt-0.5"
                >
                  {isNewPhrase
                    ? 'Tambah Frasa Audio Minang Baru'
                    : `Perbarui Frasa: "${editingPhrase.phrase}"`}
                </h2>
              </div>
              <button
                type="button"
                aria-label="Tutup form frasa"
                onClick={() => setEditingPhrase(null)}
                className="w-10 h-10 rounded-full bg-white/10 hover:bg-[#F26B4B] text-white flex items-center justify-center transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Isi Form */}
            <div className="flex-1 min-h-0 overflow-y-auto p-6 space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Frasa Bahasa Minang *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Contoh: Bara ko ciek, Da?"
                    value={editingPhrase.phrase}
                    onChange={(e) =>
                      setEditingPhrase({ ...editingPhrase, phrase: e.target.value })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Cara Baca / Fonetik *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Contoh: Ba-ra ko ci-ek, Da?"
                    value={editingPhrase.pronunciation}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        pronunciation: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-semibold"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Arti Bahasa Indonesia *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Contoh: Berapa harganya ini satu, Bang?"
                    value={editingPhrase.meaning_id}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        meaning_id: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Arti Bahasa Inggris (Opsional)
                  </label>
                  <input
                    type="text"
                    placeholder="Contoh: How much is one piece, Brother?"
                    value={editingPhrase.meaning_en || ''}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        meaning_en: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Kategori Percakapan *
                  </label>
                  <select
                    value={editingPhrase.category}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        category: e.target.value as MinangPhraseCategory,
                        category_id: `cat-mp-${e.target.value.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                  >
                    {PHRASE_CATEGORIES.map((cat) => (
                      <option key={cat} value={cat}>
                        {cat}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Catatan Dialek Daerah *
                  </label>
                  <input
                    type="text"
                    placeholder="Contoh: Agam / Bukittinggi / Padang"
                    value={editingPhrase.dialect_note || ''}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        dialect_note: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm"
                  />
                </div>

                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-[#1B1F1A]">
                    Tingkat Kesopanan *
                  </label>
                  <select
                    value={editingPhrase.politeness_level || 'Sopan'}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        politeness_level: e.target.value,
                      })
                    }
                    className="min-h-[46px] px-4 py-2 rounded-xl bg-white border border-[#767676] text-sm font-bold"
                  >
                    <option value="Sopan">Sopan (Sehari-hari / Pedagang)</option>
                    <option value="Halus / Adat">Halus / Adat (Tetua & Pemuka Nagari)</option>
                    <option value="Biasa">Biasa / Akrab (Teman Sebaya)</option>
                  </select>
                </div>
              </div>

              {/* SECTION TEXT-TO-SPEECH (TTS) */}
              <div className="p-4 rounded-2xl bg-white border border-[#CFD8BE] space-y-3 shadow-xs">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-[#E4E9DA] pb-3">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-xl bg-[#234B24]/10 text-[#234B24] flex items-center justify-center shrink-0">
                      <Volume2 className="w-4 h-4" />
                    </div>
                    <div>
                      <h4 className="text-xs font-extrabold text-[#234B24] uppercase tracking-wider">
                        Sintesis Suara Text-To-Speech (TTS)
                      </h4>
                      <p className="text-[11px] text-[#4A5248]">
                        Suara pelafalan dihasilkan otomatis dari skrip teks (Web Speech API). Tanpa perlu upload rekaman file audio.
                      </p>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => {
                      const textToTest =
                        editingPhrase.voice_text ||
                        editingPhrase.phrase ||
                        editingPhrase.minang_text;
                      if (!textToTest || !textToTest.trim()) {
                        showToast(
                          'Ketik frasa atau teks suara terlebih dahulu untuk uji coba TTS.',
                          'warning'
                        );
                        return;
                      }
                      if ('speechSynthesis' in window) {
                        window.speechSynthesis.cancel();
                        const utterance = new SpeechSynthesisUtterance(textToTest);
                        utterance.lang = 'id-ID';
                        utterance.rate = 0.9;
                        utterance.pitch = 1.05;
                        window.speechSynthesis.speak(utterance);
                        showToast(`Memutar pelafalan TTS: "${textToTest}"`, 'info');
                      } else {
                        showToast(
                          'Browser tidak mendukung Web Speech API.',
                          'warning'
                        );
                      }
                    }}
                    className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1.5 transition shadow-xs shrink-0 self-start sm:self-auto"
                  >
                    <Volume2 className="w-3.5 h-3.5 text-[#A7F3D0]" />
                    <span>Uji Dengar Suara TTS</span>
                  </button>
                </div>

                <div className="flex flex-col gap-1">
                  <label className="text-[11px] font-bold text-[#1B1F1A]">
                    Teks Skrip Suara TTS (<code className="font-mono text-[#234B24]">voice_text</code>) *
                  </label>
                  <input
                    type="text"
                    placeholder="Contoh: Bara ko ciek, Da?"
                    value={editingPhrase.voice_text || ''}
                    onChange={(e) =>
                      setEditingPhrase({
                        ...editingPhrase,
                        voice_text: e.target.value,
                      })
                    }
                    className="min-h-[42px] px-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                  />
                  <span className="text-[10px] text-[#4A5248]">
                    Teks ini dilafalkan oleh mesin Text-to-Speech pada aplikasi wisatawan. Jika dikosongkan, otomatis menggunakan Frasa Bahasa Minang.
                  </span>
                </div>
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold text-[#1B1F1A]">
                  Catatan Konteks Budaya &amp; Etika Adat (<code className="font-mono text-[#234B24]">usage_context_tip</code>)
                </label>
                <textarea
                  rows={2}
                  placeholder="Contoh: Diucapkan saat tawar-menawar di pasar tradisional dengan intonasi ramah..."
                  value={editingPhrase.usage_context_tip || editingPhrase.notes || ''}
                  onChange={(e) =>
                    setEditingPhrase({
                      ...editingPhrase,
                      usage_context_tip: e.target.value,
                      notes: e.target.value,
                    })
                  }
                  className="p-3.5 rounded-xl bg-white border border-[#767676] text-xs"
                />
              </div>
            </div>

            {/* Footer Modal */}
            <div className="shrink-0 border-t border-[#234B24]/15 bg-white px-6 py-4 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setEditingPhrase(null)}
                className="min-h-[44px] px-5 rounded-pill bg-[#F6F3EC] border border-[#767676] text-xs font-bold text-[#1B1F1A] hover:bg-[#E4E9DA] transition"
              >
                Batal
              </button>
              <button
                type="submit"
                className="min-h-[44px] px-6 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold shadow-md transition"
              >
                {isNewPhrase ? 'Simpan Frasa Baru' : 'Simpan Perubahan'}
              </button>
            </div>
          </form>
        )}
      </dialog>

      {/* Dialog Konfirmasi Hapus */}
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
              <h3 id="delete-phrase-title" className="text-lg font-extrabold text-[#1B1F1A]">
                Hapus Frasa dari Kamus?
              </h3>
              <p className="text-xs text-[#4A5248] mt-1">
                Apakah Anda yakin ingin menghapus frasa &ldquo;{deletingPhrase.phrase}&rdquo;? Rekaman audio yang terhubung juga akan dihapus.
              </p>
            </div>
            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setDeletingPhrase(null)}
                className="min-h-[42px] px-4 rounded-xl bg-white border border-[#CFD8BE] text-xs font-bold"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={handleConfirmDelete}
                className="min-h-[42px] px-5 rounded-xl bg-[#D95637] text-white text-xs font-bold shadow-sm"
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
