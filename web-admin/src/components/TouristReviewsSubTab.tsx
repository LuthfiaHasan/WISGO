import React, { useState } from 'react';
import {
  AlertTriangle,
  Bookmark,
  Calendar,
  CheckCircle2,
  Eye,
  EyeOff,
  FileText,
  MapPin,
  Search,
  ShieldCheck,
  SlidersHorizontal,
  Star,
  ThumbsUp,
  Trash2,
} from 'lucide-react';
import { Destination, DestinationReview } from '../types/contract';
import { DestinationReviewsRepo } from '../services/dbRepository';

interface TouristReviewsSubTabProps {
  destinations: Destination[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const GROUND_CONDITION_TAGS = [
  'Debit Air Pas',
  'Jalur Aman & Kering',
  'Jalur Licin / Berlumpur',
  'Cuaca Cerah Sejuk',
  'Pengunjung Padat',
  'Parkiran Longgar',
  'Tiket Sesuai Perda',
  'Waspada Pungli',
] as const;

export const TouristReviewsSubTab: React.FC<TouristReviewsSubTabProps> = ({
  destinations,
  showToast,
}) => {
  const [reviews, setReviews] = useState<DestinationReview[]>(() =>
    DestinationReviewsRepo.getAll()
  );
  const [minCharLimit, setMinCharLimit] = useState<number>(() =>
    DestinationReviewsRepo.getMinCharacterLimit()
  );
  const [tempMinChar, setTempMinChar] = useState<number>(minCharLimit);
  const [isSettingOpen, setIsSettingOpen] = useState(false);

  const [searchTerm, setSearchTerm] = useState('');
  const [ratingFilter, setRatingFilter] = useState<'ALL' | '5' | '4' | '3_BELOW'>('ALL');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'VISIBLE' | 'HIDDEN' | 'IMPORTANT'>('ALL');
  const [destFilter, setDestFilter] = useState<string>('ALL');
  const [tagFilter, setTagFilter] = useState<string>('ALL');

  const handleSaveMinChar = (limit: number) => {
    const val = Math.max(10, Math.min(500, limit));
    setMinCharLimit(val);
    setTempMinChar(val);
    DestinationReviewsRepo.setMinCharacterLimit(val);
    setIsSettingOpen(false);
    showToast(`Batas minimal karakter laporan ditetapkan: ${val} karakter.`, 'success');
  };

  const handleToggleImportant = (rev: DestinationReview) => {
    const updated = DestinationReviewsRepo.toggleImportant(rev.id);
    setReviews(updated);
    const item = updated.find((r) => r.id === rev.id);
    showToast(
      item?.is_important
        ? 'Laporan lapangan ditandai sebagai "Info Penting" untuk wisatawan.'
        : 'Tanda "Info Penting" dilepas dari laporan lapangan.',
      'info'
    );
  };

  const handleToggleHide = (rev: DestinationReview) => {
    const nextHidden = !rev.is_hidden;
    const reason = nextHidden
      ? window.prompt(
        'Tuliskan alasan penyembunyian laporan ini:',
        'Tidak memenuhi standar etika informasi lapangan WISGO.'
      )
      : undefined;
    if (nextHidden && reason === null) return;

    const updatedItem: DestinationReview = {
      ...rev,
      is_hidden: nextHidden,
      admin_moderation_reason: nextHidden
        ? reason || 'Disembunyikan oleh Administrator WISGO'
        : undefined,
    };
    const updated = DestinationReviewsRepo.save(updatedItem);
    setReviews(updated);
    showToast(
      nextHidden
        ? `Laporan dari "${rev.user_name}" disembunyikan dari aplikasi.`
        : `Laporan dari "${rev.user_name}" dipulihkan dan tampil di aplikasi.`,
      nextHidden ? 'warning' : 'success'
    );
  };

  const handleDeleteReview = (id: string) => {
    if (!window.confirm('Hapus laporan kondisi lapangan ini secara permanen?')) return;
    const updated = DestinationReviewsRepo.deleteWithNotice(id, 'Dihapus permanen oleh Admin');
    setReviews(updated);
    showToast('Laporan berhasil dihapus permanen.', 'info');
  };

  const filtered = reviews.filter((rev) => {
    const text = rev.review_comment || rev.raw_text || '';
    const q = searchTerm.trim().toLowerCase();
    const matchesSearch =
      !q ||
      rev.user_name.toLowerCase().includes(q) ||
      text.toLowerCase().includes(q) ||
      rev.destination_name.toLowerCase().includes(q);

    const matchesRating =
      ratingFilter === 'ALL' ||
      (ratingFilter === '5' && rev.rating === 5) ||
      (ratingFilter === '4' && rev.rating === 4) ||
      (ratingFilter === '3_BELOW' && rev.rating <= 3);

    const matchesStatus =
      statusFilter === 'ALL' ||
      (statusFilter === 'VISIBLE' && !rev.is_hidden) ||
      (statusFilter === 'HIDDEN' && rev.is_hidden) ||
      (statusFilter === 'IMPORTANT' && rev.is_important);

    const matchesDest = destFilter === 'ALL' || rev.destination_id === destFilter;
    const matchesTag = tagFilter === 'ALL' || (rev.tags || []).includes(tagFilter);

    return matchesSearch && matchesRating && matchesStatus && matchesDest && matchesTag;
  });

  const totalReviews = reviews.length;
  const visibleCount = reviews.filter((r) => !r.is_hidden).length;
  const hiddenCount = reviews.filter((r) => r.is_hidden).length;
  const importantCount = reviews.filter((r) => r.is_important).length;
  const validCharCount = reviews.filter(
    (r) => (r.review_comment || r.raw_text || '').length >= minCharLimit
  ).length;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <span className="text-[11px] font-extrabold text-[#234B24] uppercase tracking-wider">
            Total Laporan Lapangan
          </span>
          <div className="text-2xl font-black text-[#1B1F1A] mt-1">{totalReviews} Laporan</div>
          <p className="text-[11px] text-[#4A5248] mt-0.5">Teks manual bebas &amp; tag kondisi riil</p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <span className="text-[11px] font-extrabold text-[#0D9488] uppercase tracking-wider">
            Laporan Tayang Publik
          </span>
          <div className="text-2xl font-black text-[#0D9488] mt-1">{visibleCount} Tayang</div>
          <p className="text-[11px] text-[#0F766E] mt-0.5">
            {validCharCount} memenuhi syarat min. {minCharLimit} karakter
          </p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <span className="text-[11px] font-extrabold text-[#B45309] uppercase tracking-wider">
            Ditandai Info Penting
          </span>
          <div className="text-2xl font-black text-[#B45309] mt-1 flex items-center gap-1.5">
            <Bookmark className="w-5 h-5 fill-amber-500 text-amber-500" />
            <span>{importantCount} Catatan</span>
          </div>
          <p className="text-[11px] text-[#92400E] mt-0.5">Kondisi jalur/cuaca kritis di lokasi</p>
        </div>

        <div className="p-4 sm:p-5 rounded-2xl bg-white border border-[#234B24]/10 shadow-xs">
          <span className="text-[11px] font-extrabold text-[#DC2626] uppercase tracking-wider">
            Disembunyikan (Takedown)
          </span>
          <div className="text-2xl font-black text-[#DC2626] mt-1">{hiddenCount} Laporan</div>
          <p className="text-[11px] text-[#B91C1C] mt-0.5">Spam, ujaran kasar, atau fiktif</p>
        </div>
      </div>

      <div className="bg-[#234B24]/5 border border-[#234B24]/20 rounded-2xl p-4 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-start gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shrink-0">
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
              Selaras dengan validasi aplikasi mobile (default 30 karakter) + 8 tag kondisi lapangan.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {!isSettingOpen ? (
            <button
              type="button"
              onClick={() => setIsSettingOpen(true)}
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-white hover:bg-[#F6F3EC] text-[#234B24] border border-[#234B24]/20 shadow-xs"
            >
              Ubah Batas Karakter
            </button>
          ) : (
            <div className="flex items-center gap-2 bg-white p-1.5 rounded-xl border border-[#234B24]/30">
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
                className="px-3 py-1 bg-[#234B24] text-white text-xs font-bold rounded"
              >
                Simpan
              </button>
              <button
                type="button"
                onClick={() => {
                  setTempMinChar(minCharLimit);
                  setIsSettingOpen(false);
                }}
                className="px-2 py-1 text-xs text-[#767676]"
              >
                Batal
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white rounded-2xl p-4 border border-[#234B24]/10 space-y-3">
        <div className="flex flex-wrap items-center gap-2">
          <div className="relative min-w-[200px] flex-1">
            <Search className="w-3.5 h-3.5 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Cari pengulas, kondisi jalan, atau kata kunci..."
              className="w-full min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium"
            />
          </div>

          <select
            value={destFilter}
            onChange={(e) => setDestFilter(e.target.value)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
          >
            <option value="ALL">Semua Destinasi</option>
            {destinations.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </select>

          <select
            value={ratingFilter}
            onChange={(e) => setRatingFilter(e.target.value as 'ALL' | '5' | '4' | '3_BELOW')}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
          >
            <option value="ALL">Semua Rating</option>
            <option value="5">★ 5 Bintang</option>
            <option value="4">★ 4 Bintang</option>
            <option value="3_BELOW">★ ≤ 3 Bintang</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) =>
              setStatusFilter(e.target.value as 'ALL' | 'VISIBLE' | 'HIDDEN' | 'IMPORTANT')
            }
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
          >
            <option value="ALL">Semua Status ({totalReviews})</option>
            <option value="VISIBLE">Tayang Publik ({visibleCount})</option>
            <option value="IMPORTANT">Info Penting ({importantCount})</option>
            <option value="HIDDEN">Disembunyikan ({hiddenCount})</option>
          </select>
        </div>

        {/* 8 Tag Kondisi Lapangan Mobile */}
        <div className="flex flex-wrap items-center gap-1.5 pt-2 border-t border-[#234B24]/10">
          <button
            type="button"
            onClick={() => setTagFilter('ALL')}
            className={`px-2.5 py-1 rounded-full text-[10px] font-bold border ${tagFilter === 'ALL'
                ? 'bg-[#234B24] text-white border-[#234B24]'
                : 'bg-[#F6F3EC] text-[#4A5248] border-[#CFD8BE]'
              }`}
          >
            Semua Tag Kondisi
          </button>
          {GROUND_CONDITION_TAGS.map((tag) => (
            <button
              key={tag}
              type="button"
              onClick={() => setTagFilter(tagFilter === tag ? 'ALL' : tag)}
              className={`px-2.5 py-1 rounded-full text-[10px] font-bold border ${tagFilter === tag
                  ? 'bg-[#234B24] text-white border-[#234B24]'
                  : 'bg-[#F6F3EC] text-[#4A5248] border-[#CFD8BE]'
                }`}
            >
              #{tag}
            </button>
          ))}
        </div>
      </div>

      {/* Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {filtered.length === 0 ? (
          <div className="col-span-full bg-white rounded-2xl p-12 text-center border border-[#234B24]/10">
            <FileText className="w-12 h-12 text-[#234B24]/30 mx-auto mb-3" />
            <h4 className="text-base font-extrabold text-[#234B24]">Tidak Ada Laporan Cocok</h4>
            <p className="text-xs text-[#767676] mt-1">
              Ubah filter destinasi, rating, atau tag kondisi lapangan.
            </p>
          </div>
        ) : (
          filtered.map((rev) => {
            const content = rev.review_comment || rev.raw_text || '';
            const charCount = content.length;
            const isLengthValid = charCount >= minCharLimit;

            return (
              <div
                key={rev.id}
                className={`bg-white rounded-2xl p-5 border transition flex flex-col justify-between ${rev.is_hidden
                    ? 'border-red-200 bg-red-50/20 opacity-80'
                    : rev.is_important
                      ? 'border-amber-300 ring-2 ring-amber-400/20 bg-amber-50/10'
                      : 'border-[#234B24]/10 hover:border-[#234B24]/40'
                  }`}
              >
                <div>
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-sm font-extrabold text-[#234B24]">{rev.user_name}</span>
                        {rev.author_badge && (
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-[#234B24]/10 text-[#234B24]">
                            {rev.author_badge}
                          </span>
                        )}
                        {rev.is_gps_verified && (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-extrabold bg-[#1E9E5A]/15 text-[#166534]">
                            <ShieldCheck className="w-3 h-3" /> GPS Terverifikasi
                          </span>
                        )}
                        {rev.is_important && (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-black bg-amber-500 text-white">
                            <Bookmark className="w-3 h-3 fill-white" /> INFO PENTING
                          </span>
                        )}
                      </div>
                      <div className="flex items-center gap-2 mt-1 text-xs text-[#767676]">
                        <span className="flex items-center gap-1 font-semibold text-[#4A5248]">
                          <MapPin className="w-3.5 h-3.5 text-[#F26B4B]" />
                          {rev.destination_name}
                        </span>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <Calendar className="w-3 h-3" />
                          {new Date(rev.visited_at || rev.created_at).toLocaleDateString('id-ID', {
                            day: 'numeric',
                            month: 'short',
                            year: 'numeric',
                          })}
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-0.5 shrink-0 bg-amber-50 px-2 py-1 rounded-lg border border-amber-200">
                      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                      <span className="text-xs font-black text-amber-900">{rev.rating}.0</span>
                    </div>
                  </div>

                  <div className="mt-3 p-3.5 rounded-xl bg-[#F6F3EC]/70 border border-[#234B24]/10">
                    <p className="text-xs leading-relaxed text-[#1B1F1A] font-medium">
                      &ldquo;{content}&rdquo;
                    </p>
                  </div>

                  {rev.tags?.length > 0 && (
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

                  {rev.is_hidden && rev.admin_moderation_reason && (
                    <div className="mt-2.5 p-2.5 rounded-xl bg-red-50 border border-red-200 text-[11px] text-red-800 flex items-start gap-2">
                      <AlertTriangle className="w-3.5 h-3.5 text-red-600 shrink-0 mt-0.5" />
                      <span>
                        <strong>Alasan Moderasi:</strong> {rev.admin_moderation_reason}
                      </span>
                    </div>
                  )}

                  <div className="mt-2.5 flex items-center justify-between text-[11px]">
                    <span
                      className={`inline-flex items-center gap-1 font-bold ${isLengthValid ? 'text-[#166534]' : 'text-amber-700'
                        }`}
                    >
                      <CheckCircle2 className="w-3 h-3" />
                      {charCount} Karakter ({isLengthValid ? `Valid ≥ ${minCharLimit}` : `< ${minCharLimit}`})
                    </span>
                    <span className="inline-flex items-center gap-1 font-bold text-[#234B24]">
                      <ThumbsUp className="w-3 h-3 text-[#1E9E5A]" />
                      {rev.helpful_count} Terbantu
                    </span>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-[#234B24]/10 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => handleToggleImportant(rev)}
                      className={`min-h-[36px] px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 ${rev.is_important
                          ? 'bg-amber-100 text-amber-900'
                          : 'bg-white text-[#4A5248] border border-[#CFD8BE]'
                        }`}
                    >
                      <Bookmark className="w-3.5 h-3.5" />
                      <span>{rev.is_important ? 'Lepas Penting' : 'Info Penting'}</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => handleToggleHide(rev)}
                      className={`min-h-[36px] px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 ${rev.is_hidden
                          ? 'bg-[#1E9E5A]/15 text-[#166534]'
                          : 'bg-white text-red-700 border border-red-200'
                        }`}
                    >
                      {rev.is_hidden ? <Eye className="w-3.5 h-3.5" /> : <EyeOff className="w-3.5 h-3.5" />}
                      <span>{rev.is_hidden ? 'Tampilkan' : 'Sembunyikan'}</span>
                    </button>
                  </div>
                  <button
                    type="button"
                    onClick={() => handleDeleteReview(rev.id)}
                    title="Hapus Permanen"
                    className="w-8 h-8 rounded-xl text-[#767676] hover:text-red-700 hover:bg-red-50 flex items-center justify-center"
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
