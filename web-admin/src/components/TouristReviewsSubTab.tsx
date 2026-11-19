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
} from 'lucide-react';
import { TouristReview, Destination } from '../types/contract';

interface TouristReviewsSubTabProps {
  destinations: Destination[];
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

const STORAGE_KEY_REVIEWS = 'wisgo_tourist_reviews';

// Seed Initial Reviews
const INITIAL_REVIEWS: TouristReview[] = [
  {
    id: 'rev-01',
    tourist_name: 'Aditya Pratama',
    destination_id: 'harau',
    destination_name: 'Lembah Harau',
    rating: 5,
    comment:
      'Pemandangan tebing granitnya luar biasa megah seperti Yosemite di Amerika! Udara sejuk dan warga nagarinya sangat ramah. Plang tarif perdanya jelas sekali jadi bebas pungli.',
    created_at: '2026-11-16T10:15:00Z',
    is_hidden: false,
  },
  {
    id: 'rev-02',
    tourist_name: 'Rina Anggraini',
    destination_id: 'pagaruyung',
    destination_name: 'Istano Basa Pagaruyung',
    rating: 5,
    comment:
      'Sangat terkesan dengan arsitektur Rumah Gadang terbesar di dunia. Bisa sewa pakaian adat Minangkabau lengkap dengan suntiang. Sangat edukatif untuk anak-anak!',
    created_at: '2026-11-15T14:30:00Z',
    is_hidden: false,
  },
  {
    id: 'rev-03',
    tourist_name: 'Bambang Wijaya',
    destination_id: 'mandeh',
    destination_name: 'Kawasan Wisata Bahari Mandeh',
    rating: 4,
    comment:
      'Air lautnya sangat tenang seperti danau, spot snorkeling di Pulau Sironjong Ketek mantap karangnya. Saran saya sediakan lebih banyak tempat sampah di dermaga.',
    created_at: '2026-11-14T11:00:00Z',
    is_hidden: false,
  },
  {
    id: 'rev-04',
    tourist_name: 'Akun Promo Liar',
    destination_id: 'harau',
    destination_name: 'Lembah Harau',
    rating: 1,
    comment:
      'KLIK LINK SLOT GACOR WWW.JUDI-ONLINE-TERBAIK.XYZ PASTI MENANG 100 JUTA SEKARANG JUGA HUBUNGI WA 08999999999 !!!',
    created_at: '2026-11-16T18:40:00Z',
    is_hidden: true,
    admin_moderation_reason: 'Spam tautan ilegal / judi online yang dilarang UU ITE.',
  },
  {
    id: 'rev-05',
    tourist_name: 'Siti Nurhaliza',
    destination_id: 'danau-kembar',
    destination_name: 'Danau Diatas & Danau Dibawah',
    rating: 5,
    comment:
      'Kebun teh Alahan Panjang dingin sekali suasananya, kabut turun pelan-pelan. Cocok untuk healing sejenak dari hiruk pikuk kota. Petik stroberi juga seru!',
    created_at: '2026-11-13T16:20:00Z',
    is_hidden: false,
  },
  {
    id: 'rev-06',
    tourist_name: 'Dedi Kurniawan',
    destination_id: 'sianok',
    destination_name: 'Ngarai Sianok & Taruko',
    rating: 4,
    comment:
      'Pemandangan tebing curam dan sungai Batang Sianok sangat menenangkan. Mampir ngopi di Cafe Taruko sambil dengar gemericik air dan suara monyet ekor panjang.',
    created_at: '2026-11-12T09:15:00Z',
    is_hidden: false,
  },
  {
    id: 'rev-07',
    tourist_name: 'Farhan Maulana',
    destination_id: 'kelok-9',
    destination_name: 'Kelok 9 Skywalk',
    rating: 5,
    comment:
      'Mahakarya jembatan layang di tengah cagar alam yang sangat estetik. Jagung bakar dan teh telurnya nikmat banget di santap sore-sore.',
    created_at: '2026-11-11T17:00:00Z',
    is_hidden: false,
  },
];

export const TouristReviewsSubTab: React.FC<TouristReviewsSubTabProps> = ({
  destinations,
  showToast,
}) => {
  const [reviews, setReviews] = useState<TouristReview[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY_REVIEWS);
      return saved ? JSON.parse(saved) : INITIAL_REVIEWS;
    } catch {
      return INITIAL_REVIEWS;
    }
  });

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY_REVIEWS, JSON.stringify(reviews));
    } catch (e) {
      console.warn('Gagal menyimpan ulasan ke localStorage:', e);
    }
  }, [reviews]);

  // Search & Filter
  const [searchTerm, setSearchTerm] = useState('');
  const [ratingFilter, setRatingFilter] = useState<'ALL' | number>('ALL');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'VISIBLE' | 'HIDDEN'>('ALL');
  const [destFilter, setDestFilter] = useState<string>('ALL');

  // Toggle Takedown / Sembunyikan Ulasan
  const handleToggleHide = (rev: TouristReview) => {
    const nextHidden = !rev.is_hidden;
    const reason = nextHidden
      ? window.prompt(
          'Tuliskan alasan takedown/penyembunyian ulasan ini (misal: Bahasa kasar/spam/hoaks):',
          'Melanggar pedoman etika komunitas pariwisata Sumatera Barat.'
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
    showToast(
      nextHidden
        ? `Ulasan dari "${rev.tourist_name}" berhasil di-takedown dari aplikasi publik.`
        : `Ulasan dari "${rev.tourist_name}" telah dipulihkan dan ditampilkan kembali.`,
      nextHidden ? 'warning' : 'success'
    );
  };

  // Hapus Ulasan Permanen
  const handleDeleteReview = (id: string) => {
    if (!window.confirm('Hapus ulasan ini secara permanen?')) return;
    setReviews(reviews.filter((r) => r.id !== id));
    showToast('Ulasan berhasil dihapus permanen.', 'info');
  };

  // Filtered Reviews
  const filtered = reviews.filter((rev) => {
    const tName = rev.tourist_name || rev.user_name || '';
    const tComment = rev.comment || rev.review_comment || '';
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
      (statusFilter === 'HIDDEN' && rev.is_hidden);

    const matchesDest =
      destFilter === 'ALL' || rev.destination_name === destFilter;

    return matchesSearch && matchesRating && matchesStatus && matchesDest;
  });

  // Metrik Ringkasan
  const totalReviews = reviews.length;
  const visibleCount = reviews.filter((r) => !r.is_hidden).length;
  const hiddenCount = reviews.filter((r) => r.is_hidden).length;
  const avgRating =
    visibleCount > 0
      ? (
          reviews
            .filter((r) => !r.is_hidden)
            .reduce((sum, r) => sum + r.rating, 0) / visibleCount
        ).toFixed(1)
      : '5.0';

  return (
    <div className="space-y-6">
      {/* 4 Kartu Metrik Ulasan */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
          <span className="text-[11px] font-extrabold text-[#234B24] uppercase tracking-wider">
            Total Ulasan Masuk
          </span>
          <div className="text-2xl font-black text-[#1B1F1A] mt-1">
            {totalReviews} Komentar
          </div>
          <p className="text-[11px] text-[#4A5248] mt-0.5">
            Dari wisatawan aplikasi WISGO
          </p>
        </div>

        <div className="p-4 rounded-2xl bg-[#CCFBF1]/60 border border-[#99F6E4]">
          <span className="text-[11px] font-extrabold text-[#0D9488] uppercase tracking-wider">
            Ulasan Aktif Publik
          </span>
          <div className="text-2xl font-black text-[#0D9488] mt-1">
            {visibleCount} Tayang
          </div>
          <p className="text-[11px] text-[#0F766E] mt-0.5">
            Dapat dibaca oleh seluruh wisatawan
          </p>
        </div>

        <div className="p-4 rounded-2xl bg-[#FEE2E2]/60 border border-[#FCA5A5]">
          <span className="text-[11px] font-extrabold text-[#DC2626] uppercase tracking-wider">
            Di-Takedown (Sembunyi)
          </span>
          <div className="text-2xl font-black text-[#DC2626] mt-1">
            {hiddenCount} Dimoderasi
          </div>
          <p className="text-[11px] text-[#B91C1C] mt-0.5">
            Spam, kata kasar, atau iklan terlarang
          </p>
        </div>

        <div className="p-4 rounded-2xl bg-[#FEF08A]/60 border border-[#FACC15]">
          <span className="text-[11px] font-extrabold text-[#854D0E] uppercase tracking-wider">
            Kepuasan Rata-Rata
          </span>
          <div className="text-2xl font-black text-[#854D0E] mt-1 flex items-center gap-1.5">
            <Star className="w-5 h-5 fill-amber-500 text-amber-500" />
            <span>{avgRating} / 5.0</span>
          </div>
          <p className="text-[11px] text-[#A16207] mt-0.5">
            Indeks sentimen positif wisatawan
          </p>
        </div>
      </div>

      {/* Filter & Action Bar */}
      <div className="bg-white rounded-2xl p-4 border border-[#E4E9DA] flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex items-center gap-2 flex-wrap flex-1">
          <div className="relative min-w-[220px] flex-1 max-w-xs">
            <Search className="w-3.5 h-3.5 text-[#767676] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Cari pengulas atau kata kunci..."
              className="w-full min-h-[40px] pl-9 pr-3.5 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as any)}
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="ALL">Semua Moderasi</option>
            <option value="VISIBLE">Tayang Publik ({visibleCount})</option>
            <option value="HIDDEN">Disembunyikan ({hiddenCount})</option>
          </select>

          <select
            value={ratingFilter}
            onChange={(e) =>
              setRatingFilter(e.target.value === 'ALL' ? 'ALL' : Number(e.target.value))
            }
            className="min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
          >
            <option value="ALL">Semua Rating (1-5★)</option>
            <option value={5}>⭐⭐⭐⭐⭐ (5 Bintang)</option>
            <option value={4}>⭐⭐⭐⭐ (4 Bintang)</option>
            <option value={3}>⭐⭐⭐ (3 Bintang)</option>
            <option value={2}>⭐⭐ (2 Bintang)</option>
            <option value={1}>⭐ (1 Bintang)</option>
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
      </div>

      {/* Daftar Kartu Moderasi Ulasan */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="bg-white rounded-2xl p-10 text-center border border-[#E4E9DA] text-[#767676]">
            Tidak ada ulasan wisatawan yang sesuai filter pencarian.
          </div>
        ) : (
          filtered.map((rev) => (
            <div
              key={rev.id}
              className={`p-5 rounded-2xl border transition ${
                rev.is_hidden
                  ? 'bg-red-50/60 border-red-200'
                  : 'bg-white hover:border-[#234B24] border-[#E4E9DA]'
              }`}
            >
              <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3">
                <div className="space-y-1.5 flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-extrabold text-sm text-[#1B1F1A]">
                      {rev.tourist_name}
                    </span>
                    <span className="text-[11px] text-[#767676] flex items-center gap-1">
                      <MapPin className="w-3 h-3 text-[#234B24]" />
                      <strong>{rev.destination_name}</strong>
                    </span>
                    <span className="text-[10px] text-[#767676]">
                      • {rev.created_at ? new Date(rev.created_at).toLocaleDateString('id-ID', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      }) : '-'}
                    </span>
                  </div>

                  {/* Bintang Rating */}
                  <div className="flex items-center gap-1">
                    {[1, 2, 3, 4, 5].map((star) => (
                      <Star
                        key={star}
                        className={`w-3.5 h-3.5 ${
                          star <= rev.rating
                            ? 'fill-amber-400 text-amber-400'
                            : 'text-gray-300'
                        }`}
                      />
                    ))}
                    <span className="text-[11px] font-bold text-[#4A5248] ml-1">
                      {rev.rating}.0 / 5.0
                    </span>
                  </div>

                  {/* Isi Komentar */}
                  <p
                    className={`text-xs mt-2 leading-relaxed ${
                      rev.is_hidden
                        ? 'text-gray-400 italic line-through'
                        : 'text-[#1B1F1A]'
                    }`}
                  >
                    &ldquo;{rev.comment}&rdquo;
                  </p>

                  {/* Alert Jika Di-takedown */}
                  {rev.is_hidden && (
                    <div className="mt-2.5 p-2.5 rounded-xl bg-red-100/70 border border-red-200 text-[11px] text-red-800 flex items-start gap-1.5">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0 mt-0.5 text-red-600" />
                      <div>
                        <strong>Ulasan Disembunyikan (Takedown):</strong>{' '}
                        {rev.admin_moderation_reason || 'Melanggar aturan komunitas.'}
                      </div>
                    </div>
                  )}
                </div>

                {/* Tombol Aksi Moderasi Admin */}
                <div className="flex sm:flex-col items-center sm:items-end justify-between gap-2 shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-black/5">
                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                      rev.is_hidden
                        ? 'bg-red-100 text-red-700'
                        : 'bg-[#CCFBF1] text-[#0D9488]'
                    }`}
                  >
                    {rev.is_hidden ? '● Disembunyikan' : '● Tayang Publik'}
                  </span>

                  <div className="flex items-center gap-1.5 mt-1">
                    <button
                      type="button"
                      onClick={() => handleToggleHide(rev)}
                      className={`min-h-[34px] px-3 rounded-lg text-xs font-bold inline-flex items-center gap-1.5 transition ${
                        rev.is_hidden
                          ? 'bg-[#234B24] hover:bg-[#1B3B1C] text-white'
                          : 'bg-red-100 hover:bg-red-200 text-red-700'
                      }`}
                    >
                      {rev.is_hidden ? (
                        <>
                          <Eye className="w-3.5 h-3.5" />
                          <span>Pulihkan</span>
                        </>
                      ) : (
                        <>
                          <Ban className="w-3.5 h-3.5" />
                          <span>Takedown</span>
                        </>
                      )}
                    </button>

                    <button
                      type="button"
                      onClick={() => handleDeleteReview(rev.id)}
                      className="w-8 h-8 rounded-lg text-[#767676] hover:text-red-600 hover:bg-red-50 flex items-center justify-center transition"
                      title="Hapus Ulasan Permanen"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
