import React, { useState, useEffect } from 'react';
import {
  MessageSquare,
  Star,
  Eye,
  EyeOff,
  Search,
  Filter,
  CheckCircle2,
  AlertTriangle,
  Trash2,
  Sparkles,
  MapPin,
  Calendar,
  ThumbsUp,
  ShieldCheck,
  Ban,
  RotateCcw,
  SlidersHorizontal,
  Bookmark,
  AlertCircle,
  FileText,
} from 'lucide-react';
import { TouristReview, Destination } from '../types/contract';
import { DestinationReviewsRepo } from '../services/dbRepository';

interface TouristReviewsSubTabProps {
  destinations: Destination[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const TouristReviewsSubTab: React.FC<TouristReviewsSubTabProps> = ({
  destinations,
  showToast,
}) => {
  const [reviews, setReviews] = useState<TouristReview[]>(() => {
    return DestinationReviewsRepo.getAll();
  });

  const [minCharLimit, setMinCharLimit] = useState<number>(() => {
    return DestinationReviewsRepo.getMinCharacterLimit();
  });

  const [tempMinChar, setTempMinChar] = useState<number>(minCharLimit);
  const [isSettingOpen, setIsSettingOpen] = useState(false);

  // Search & Filter
  const [searchTerm, setSearchTerm] = useState('');
  const [ratingFilter, setRatingFilter] = useState<'ALL' | number>('ALL');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'VISIBLE' | 'HIDDEN' | 'IMPORTANT'>('ALL');
  const [destFilter, setDestFilter] = useState<string>('ALL');

  // Simpan perubahan batas minimal karakter
  const handleSaveMinChar = (limit: number) => {
    const val = Math.max(10, Math.min(500, limit));
    setMinCharLimit(val);
    setTempMinChar(val);
    DestinationReviewsRepo.setMinCharacterLimit(val);
    setIsSettingOpen(false);
    showToast(`Batas minimal karakter laporan ditetapkan: ${val} karakter.`, 'success');
  };

  // Toggle Tandai Info Penting
  const handleToggleImportant = (rev: TouristReview) => {
    const updated = DestinationReviewsRepo.toggleImportant(rev.id);
    setReviews(updated);
    const item = updated.find((r) => r.id === rev.id);
    showToast(
      item?.is_important
        ? `Laporan lapangan ditandai sebagai "Info Penting" untuk wisatawan.`
        : `Tanda "Info Penting" dilepas dari laporan lapangan.`,
      'info'
    );
  };

  // Toggle Sembunyikan / Tampilkan Laporan
  const handleToggleHide = (rev: TouristReview) => {
    const nextHidden = !rev.is_hidden;
    const reason = nextHidden
      ? window.prompt(
          'Tuliskan alasan takedown/penyembunyian laporan ini (misal: Kata kasar/spam/laporan fiktif):',
          'Tidak memenuhi standar etika informasi lapangan WISGO.'
        )
      : undefined;

    if (nextHidden && reason === null) {
      return; // Dibatalkan oleh admin
    }

    const updated = reviews.map((r) =>
      r.id === rev.id
        ? {
            ...r,
            is_hidden: nextHidden,
            admin_moderation_reason: nextHidden
              ? reason || 'Disembunyikan oleh Administrator WISGO'
              : undefined,
          }
        : r
    );

    setReviews(updated);
    DestinationReviewsRepo.save(updated.find((r) => r.id === rev.id)!);
    showToast(
      nextHidden
        ? `Laporan dari "${rev.tourist_name || rev.user_name}" berhasil disembunyikan dari aplikasi.`
        : `Laporan dari "${rev.tourist_name || rev.user_name}" telah dipulihkan dan tampil di aplikasi.`,
      nextHidden ? 'warning' : 'success'
    );
  };

  // Hapus Laporan Permanen
  const handleDeleteReview = (id: string) => {
    if (!window.confirm('Hapus laporan kondisi lapangan ini secara permanen?')) return;
    const updated = DestinationReviewsRepo.deleteWithNotice(id, 'Dihapus permanen oleh Admin');
    setReviews(updated);
    showToast('Laporan berhasil dihapus permanen.', 'info');
  };

  // Filtered Reviews
  const filtered = reviews.filter((rev) => {
    const tName = rev.tourist_name || rev.user_name || '';
    const tComment = rev.raw_text || rev.review_comment || rev.comment || '';
    const dName = rev.destination_name || '';
    const matchesSearch =
      tName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tComment.toLowerCase().includes(searchTerm.toLowerCase()) ||
      dName.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesRating =
      ratingFilter === 'ALL' || rev.rating === ratingFilter;

    const matchesStatus =
      statusFilter === 'ALL' ||
      (statusFilter === 'VISIBLE' && !rev.is_hidden) ||
      (statusFilter === 'HIDDEN' && rev.is_hidden) ||
      (statusFilter === 'IMPORTANT' && rev.is_important);

    const matchesDest =
      destFilter === 'ALL' || rev.destination_name === destFilter;

    return matchesSearch && matchesRating && matchesStatus && matchesDest;
  });

  // Metrik Ringkasan
  const totalReviews = reviews.length;
  const visibleCount = reviews.filter((r) => !r.is_hidden).length;
  const hiddenCount = reviews.filter((r) => r.is_hidden).length;
  const importantCount = reviews.filter((r) => r.is_important).length;
  const validCharCount = reviews.filter((r) => {
    const text = r.raw_text || r.review_comment || r.comment || '';
    return text.length >= minCharLimit;
  }).length;

  return (
    <div className="space-y-6">
      {/* 4 Kartu Metrik Ringkasan */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)]">
          <span className="text-[11px] font-extrabold text-[#234B24] uppercase tracking-wider">
            Total Laporan Lapangan
          </span>
          <div className="text-2xl font-black text-[#1B1F1A] mt-1">
            {totalReviews} Laporan
          </div>
          <p className="text-[11px] text-[#4A5248] mt-0.5">
            Manual bebas tanpa template dari wisatawan
          </p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)]">
          <span className="text-[11px] font-extrabold text-[#0D9488] uppercase tracking-wider">
            Laporan Tayang Publik
          </span>
          <div className="text-2xl font-black text-[#0D9488] mt-1">
            {visibleCount} Tayang
          </div>
          <p className="text-[11px] text-[#0F766E] mt-0.5">
            {validCharCount} memenuhi syarat minimal {minCharLimit} karakter
          </p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)]">
          <span className="text-[11px] font-extrabold text-[#B45309] uppercase tracking-wider">
            Ditandai Info Penting
          </span>
          <div className="text-2xl font-black text-[#B45309] mt-1 flex items-center gap-1.5">
            <Bookmark className="w-5 h-5 fill-amber-500 text-amber-500" />
            <span>{importantCount} Catatan</span>
          </div>
          <p className="text-[11px] text-[#92400E] mt-0.5">
            Kondisi jalur/cuaca kritis di lokasi
          </p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-[0_2px_12px_rgba(35,75,36,0.05)]">
          <span className="text-[11px] font-extrabold text-[#DC2626] uppercase tracking-wider">
            Disembunyikan (Takedown)
          </span>
          <div className="text-2xl font-black text-[#DC2626] mt-1">
            {hiddenCount} Laporan
          </div>
          <p className="text-[11px] text-[#B91C1C] mt-0.5">
            Spam, ujaran kasar, atau fiktif
          </p>
        </div>
      </div>

      {/* Panel Pengaturan Batas Minimal Karakter Admin */}
      <div className="bg-[#234B24]/5 border border-[#234B24]/20 rounded-2xl p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shrink-0 mt-0.5">
            <SlidersHorizontal className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-sm font-extrabold text-[#234B24]">
                Standar Laporan: Batas Minimal Karakter Bebas
              </h3>
              <span className="px-2 py-0.5 rounded-full text-[11px] font-black bg-[#234B24] text-white">
                {minCharLimit} Karakter
              </span>
            </div>
            <p className="text-xs text-[#4A5248] mt-0.5">
              Laporan wisatawan wajib berupa teks manual bebas tanpa template minimal{' '}
              <strong className="text-[#234B24]">{minCharLimit} karakter</strong> agar informatif bagi pengunjung lain.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {!isSettingOpen ? (
            <button
              type="button"
              onClick={() => setIsSettingOpen(true)}
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-white hover:bg-[#F6F3EC] text-[#234B24] border border-[#234B24]/20 shadow-sm transition"
            >
              Ubah Batas Karakter
            </button>
          ) : (
            <div className="flex items-center gap-2 bg-white p-1.5 rounded-xl border border-[#234B24]/30 shadow-sm">
              <span className="text-xs font-bold text-[#4A5248] pl-2">Min:</span>
              <input
                type="number"
                min={10}
                max={250}
                value={tempMinChar}
                onChange={(e) => setTempMinChar(Number(e.target.value))}
                className="w-16 px-2 py-1 text-xs font-black text-[#234B24] bg-[#F6F3EC] rounded border border-[#CFD8BE] text-center"
              />
              <button
                type="button"
                onClick={() => handleSaveMinChar(tempMinChar)}
                className="px-3 py-1 bg-[#234B24] text-white text-xs font-bold rounded hover:bg-[#1B3A1C] transition"
              >
                Simpan
              </button>
              <button
                type="button"
                onClick={() => {
                  setTempMinChar(minCharLimit);
                  setIsSettingOpen(false);
                }}
                className="px-2 py-1 text-xs text-[#767676] hover:text-[#1B1F1A]"
              >
                Batal
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Filter & Action Bar */}
      <div className="bg-white rounded-2xl p-4 border border-[#234B24]/10 flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex items-center gap-2 flex-wrap flex-1">
          <div className="relative min-w-[220px] flex-1 max-w-xs">
            <Search className="w-3.5 h-3.5 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Cari pengulas, kondisi jalan, atau kata kunci..."
              className="w-full min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as any)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="ALL">Semua Status ({totalReviews})</option>
            <option value="VISIBLE">Tayang Publik ({visibleCount})</option>
            <option value="IMPORTANT">Ditandai Info Penting ({importantCount})</option>
            <option value="HIDDEN">Disembunyikan ({hiddenCount})</option>
          </select>

          <select
            value={destFilter}
            onChange={(e) => setDestFilter(e.target.value)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="ALL">Semua Destinasi</option>
            {destinations.map((d) => (
              <option key={d.id} value={d.name}>
                {d.name}
              </option>
            ))}
          </select>
        </div>

        <div className="text-xs font-semibold text-[#4A5248]">
          Menampilkan <strong className="text-[#234B24]">{filtered.length}</strong> laporan lapangan
        </div>
      </div>

      {/* Grid Kartu Laporan Pengalaman & Kondisi Lapangan */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filtered.length === 0 ? (
          <div className="col-span-full bg-white rounded-2xl p-12 text-center border border-[#234B24]/10">
            <FileText className="w-12 h-12 text-[#234B24]/30 mx-auto mb-3" />
            <h4 className="text-base font-extrabold text-[#234B24]">Tidak Ada Laporan yang Cocok</h4>
            <p className="text-xs text-[#767676] max-w-md mx-auto mt-1">
              Tidak ditemukan laporan pengalaman atau kondisi lapangan yang sesuai dengan filter pencarian Anda.
            </p>
          </div>
        ) : (
          filtered.map((rev) => {
            const content = rev.raw_text || rev.review_comment || rev.comment || '';
            const charCount = content.length;
            const isLengthValid = charCount >= minCharLimit;
            const author = rev.tourist_name || rev.user_name || 'Wisatawan WISGO';
            const dateStr = rev.visited_at || rev.created_at;

            return (
              <div
                key={rev.id}
                className={`bg-white rounded-2xl p-5 border transition flex flex-col justify-between ${
                  rev.is_hidden
                    ? 'border-red-200 bg-red-50/20 opacity-80'
                    : rev.is_important
                    ? 'border-amber-300 ring-2 ring-amber-400/20 bg-amber-50/10'
                    : 'border-[#234B24]/10 hover:border-[#234B24]/40 hover:shadow-sm'
                }`}
              >
                <div>
                  {/* Top Bar: Author, Destination, Badges */}
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-sm font-extrabold text-[#234B24]">
                          {author}
                        </span>
                        {rev.author_badge && (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-[#234B24]/10 text-[#234B24] border border-[#234B24]/20">
                            {rev.author_badge}
                          </span>
                        )}
                        {rev.is_gps_verified && (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-[#1E9E5A]/15 text-[#166534]">
                            <ShieldCheck className="w-3 h-3" />
                            GPS Terverifikasi
                          </span>
                        )}
                        {rev.is_important && (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-black bg-amber-500 text-white shadow-xs">
                            <Bookmark className="w-3 h-3 fill-white" />
                            INFO PENTING
                          </span>
                        )}
                        {rev.is_hidden && (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-red-100 text-red-700">
                            Disembunyikan
                          </span>
                        )}
                      </div>

                      <div className="flex items-center gap-2 mt-1 text-xs text-[#767676]">
                        <span className="flex items-center gap-1 font-semibold text-[#4A5248]">
                          <MapPin className="w-3.5 h-3.5 text-[#F26B4B]" />
                          {rev.destination_name || 'Destinasi Sumatera Barat'}
                        </span>
                        {dateStr && (
                          <>
                            <span>•</span>
                            <span className="flex items-center gap-1">
                              <Calendar className="w-3 h-3 text-[#767676]" />
                              {new Date(dateStr).toLocaleDateString('id-ID', {
                                day: 'numeric',
                                month: 'short',
                                year: 'numeric',
                              })}
                            </span>
                          </>
                        )}
                      </div>
                    </div>

                    {/* Rating */}
                    <div className="flex items-center gap-0.5 shrink-0 bg-amber-50 px-2 py-1 rounded-lg border border-amber-200">
                      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                      <span className="text-xs font-black text-amber-900">{rev.rating}.0</span>
                    </div>
                  </div>

                  {/* Isi Teks Laporan Bebas */}
                  <div className="mt-3.5 p-3.5 rounded-xl bg-[#F6F3EC]/70 border border-[#234B24]/10">
                    <p className="text-xs leading-relaxed text-[#1B1F1A] font-medium whitespace-pre-line">
                      "{content}"
                    </p>
                  </div>

                  {/* Tag Kondisi Lapangan */}
                  {rev.tags && rev.tags.length > 0 && (
                    <div className="mt-2.5 flex flex-wrap gap-1.5">
                      {rev.tags.map((tag, idx) => (
                        <span
                          key={idx}
                          className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#F6F3EC] text-[#234B24] border border-[#CFD8BE]"
                        >
                          #{tag}
                        </span>
                      ))}
                    </div>
                  )}

                  {/* Alasan Moderasi jika Disembunyikan */}
                  {rev.is_hidden && rev.admin_moderation_reason && (
                    <div className="mt-2.5 p-2.5 rounded-xl bg-red-50 border border-red-200 text-[11px] text-red-800 flex items-start gap-2">
                      <AlertTriangle className="w-3.5 h-3.5 text-red-600 shrink-0 mt-0.5" />
                      <div>
                        <strong>Alasan Moderasi Admin:</strong> {rev.admin_moderation_reason}
                      </div>
                    </div>
                  )}

                  {/* Indikator Jumlah Karakter & Terbantu */}
                  <div className="mt-2.5 flex items-center justify-between text-[11px]">
                    <span
                      className={`inline-flex items-center gap-1 font-bold ${
                        isLengthValid ? 'text-[#166534]' : 'text-amber-700'
                      }`}
                    >
                      <CheckCircle2 className="w-3 h-3" />
                      {charCount} Karakter {isLengthValid ? `(Valid ≥ ${minCharLimit})` : `(Di bawah min. ${minCharLimit})`}
                    </span>
                    <div className="flex items-center gap-2.5">
                      {rev.helpful_count !== undefined && (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-[#234B24]">
                          <ThumbsUp className="w-3 h-3 text-[#1E9E5A]" />
                          {rev.helpful_count} Terbantu
                        </span>
                      )}
                      <span className="text-[#767676] text-[10px]">Teks Bebas Manual</span>
                    </div>
                  </div>
                </div>

                {/* Bottom Actions Bar */}
                <div className="mt-4 pt-3 border-t border-[#234B24]/10 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => handleToggleImportant(rev)}
                      className={`min-h-[36px] px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                        rev.is_important
                          ? 'bg-amber-100 text-amber-900 hover:bg-amber-200'
                          : 'bg-white hover:bg-amber-50 text-[#4A5248] border border-[#CFD8BE]'
                      }`}
                    >
                      <Bookmark className={`w-3.5 h-3.5 ${rev.is_important ? 'fill-amber-600 text-amber-600' : ''}`} />
                      <span>{rev.is_important ? 'Lepas Info Penting' : 'Tandai Info Penting'}</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => handleToggleHide(rev)}
                      className={`min-h-[36px] px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                        rev.is_hidden
                          ? 'bg-[#1E9E5A]/15 text-[#166534] hover:bg-[#1E9E5A]/25'
                          : 'bg-white hover:bg-red-50 text-red-700 border border-red-200'
                      }`}
                    >
                      {rev.is_hidden ? (
                        <>
                          <Eye className="w-3.5 h-3.5" />
                          <span>Tampilkan di Aplikasi</span>
                        </>
                      ) : (
                        <>
                          <EyeOff className="w-3.5 h-3.5" />
                          <span>Sembunyikan</span>
                        </>
                      )}
                    </button>
                  </div>

                  <button
                    type="button"
                    onClick={() => handleDeleteReview(rev.id)}
                    title="Hapus Permanen"
                    className="w-8 h-8 rounded-xl text-[#767676] hover:text-red-700 hover:bg-red-50 flex items-center justify-center transition"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
