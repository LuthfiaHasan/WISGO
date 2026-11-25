// ============================================================================
// UTILITAS KOMPRESI & OPTIMASI GAMBAR SISI KLIEN (HTML5 CANVAS)
// Mencegah QuotaExceededError di localStorage & mempercepat render Web Admin
// ============================================================================

export interface ImageOptimizationResult {
  dataUrl: string;
  width: number;
  height: number;
  originalSize: number;
  compressedSize: number;
  aspectRatio: number;
  isEquirectangular: boolean; // true jika rasio mendekati 2:1 (~1.90 s.d 2.10)
  fileName: string;
  mimeType: string;
}

export interface CompressOptions {
  maxWidth?: number;
  maxHeight?: number;
  quality?: number; // 0.1 s.d 1.0
  format?: 'image/webp' | 'image/jpeg';
  forceEquirectangularCrop?: boolean;
}

/**
 * Kompres file gambar dari device pengguna menggunakan HTML5 Canvas
 */
export async function optimizeImageFile(
  file: File,
  options: CompressOptions = {}
): Promise<ImageOptimizationResult> {
  const {
    maxWidth = 1600,
    maxHeight = 1200,
    quality = 0.82,
    format = 'image/webp',
  } = options;

  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (readerEvent) => {
      const img = new Image();

      img.onload = () => {
        let width = img.naturalWidth || img.width;
        let height = img.naturalHeight || img.height;
        const aspectRatio = width / Math.max(1, height);
        // Equirectangular 360 standar memiliki rasio 2:1 (toleransi 1.85 s.d 2.15)
        const isEquirectangular = aspectRatio >= 1.85 && aspectRatio <= 2.15;

        // Hitung skala resolusi dengan batas maksimum
        let targetWidth = width;
        let targetHeight = height;

        if (targetWidth > maxWidth) {
          targetHeight = Math.round((targetHeight * maxWidth) / targetWidth);
          targetWidth = maxWidth;
        }

        if (targetHeight > maxHeight) {
          targetWidth = Math.round((targetWidth * maxHeight) / targetHeight);
          targetHeight = maxHeight;
        }

        const canvas = document.createElement('canvas');
        canvas.width = targetWidth;
        canvas.height = targetHeight;

        const ctx = canvas.getContext('2d');
        if (!ctx) {
          reject(new Error('Gagal menginisialisasi konteks HTML5 Canvas 2D.'));
          return;
        }

        // Gambar ulang dengan interpolasi halus
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(img, 0, 0, targetWidth, targetHeight);

        // Ekspor data URL (fallback ke JPEG jika browser tidak mendukung WebP canvas export)
        let outputMime = format;
        let dataUrl = canvas.toDataURL(outputMime, quality);

        // Cek jika browser mengabaikan webp dan menghasilkan png
        if (format === 'image/webp' && !dataUrl.startsWith('data:image/webp')) {
          outputMime = 'image/jpeg';
          dataUrl = canvas.toDataURL('image/jpeg', quality);
        }

        // Hitung perkiraan ukuran byte dari Base64
        const head = dataUrl.indexOf(',') + 1;
        const base64Len = dataUrl.length - head;
        const compressedSize = Math.round((base64Len * 3) / 4);

        resolve({
          dataUrl,
          width: targetWidth,
          height: targetHeight,
          originalSize: file.size,
          compressedSize,
          aspectRatio,
          isEquirectangular,
          fileName: file.name,
          mimeType: outputMime,
        });
      };

      img.onerror = () => {
        reject(new Error('File yang dipilih bukan merupakan format gambar valid.'));
      };

      img.src = readerEvent.target?.result as string;
    };

    reader.onerror = () => {
      reject(new Error('Gagal membaca file dari device lokal.'));
    };

    reader.readAsDataURL(file);
  });
}

/**
 * Format ukuran byte menjadi label yang ramah pengguna (KB / MB)
 */
export function formatByteSize(bytes: number): string {
  if (!bytes || bytes <= 0) return '0 KB';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

/**
 * Helper penyimpanan localStorage yang aman dari QuotaExceededError
 */
export function safeSetLocalStorage(key: string, value: string): boolean {
  try {
    localStorage.setItem(key, value);
    return true;
  } catch (err: unknown) {
    // QuotaExceededError handler
    console.warn(`Penyimpanan localStorage penuh saat menulis kunci: ${key}. Melakukan pembersihan cache lama...`);
    try {
      // Bersihkan kunci-kunci sementara lama jika ada
      const tempKeys = ['rancakin_cache_temp', 'rancakin_preview_temp'];
      for (const tk of tempKeys) {
        localStorage.removeItem(tk);
      }
      localStorage.setItem(key, value);
      return true;
    } catch {
      console.error('Penyimpanan browser tetap tidak mencukupi untuk menyimpan data ini.');
      return false;
    }
  }
}
