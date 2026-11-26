import React, { useRef, useState } from 'react';
import {
  UploadCloud,
  CheckCircle2,
  AlertCircle,
  Trash2,
  RefreshCw,
  Eye,
  FileImage,
  Sparkles,
} from 'lucide-react';
import {
  formatByteSize,
  ImageOptimizationResult,
  optimizeImageFile,
} from '../utils/imageOptimizer';

interface ImageDropzoneProps {
  label: string;
  value?: string; // Data URL or existing URL
  onChange: (dataUrl: string, metadata?: ImageOptimizationResult) => void;
  onClear?: () => void;
  isPanorama?: boolean; // Khusus panorama 360 equirectangular 2:1
  maxDimension?: number;
  quality?: number;
  helperText?: string;
  required?: boolean;
}

export const ImageDropzone: React.FC<ImageDropzoneProps> = ({
  label,
  value,
  onChange,
  onClear,
  isPanorama = false,
  maxDimension = isPanorama ? 2560 : 1600,
  quality = isPanorama ? 0.82 : 0.8,
  helperText,
  required = false,
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string>('');
  const [meta, setMeta] = useState<ImageOptimizationResult | null>(null);

  const processFile = async (file: File) => {
    setErrorMsg('');
    if (!file.type.startsWith('image/')) {
      setErrorMsg('File harus berformat gambar (.jpg, .jpeg, .png, .webp).');
      return;
    }

    setIsProcessing(true);
    try {
      const result = await optimizeImageFile(file, {
        maxWidth: maxDimension,
        maxHeight: isPanorama ? Math.round(maxDimension / 2) : maxDimension,
        quality,
        format: 'image/webp',
      });

      setMeta(result);
      onChange(result.dataUrl, result);
    } catch (err: unknown) {
      setErrorMsg(
        err instanceof Error ? err.message : 'Gagal memproses gambar dari device.'
      );
    } finally {
      setIsProcessing(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      processFile(file);
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files?.[0];
    if (file) {
      processFile(file);
    }
  };

  const handleClear = (e: React.MouseEvent) => {
    e.stopPropagation();
    setMeta(null);
    setErrorMsg('');
    if (fileInputRef.current) fileInputRef.current.value = '';
    if (onClear) onClear();
    else onChange('');
  };

  const hasImage = Boolean(value);

  return (
    <div className="space-y-1.5 w-full">
      <div className="flex items-center justify-between">
        <label className="text-xs font-bold text-[#1B1F1A]">
          {label} {required && <span className="text-[#F26B4B]">*</span>}
        </label>
        {isPanorama && (
          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#E4E9DA] text-[#234B24]">
            Rasio Equirectangular 2:1
          </span>
        )}
      </div>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/jpg"
        onChange={handleFileChange}
        className="hidden"
      />

      {hasImage ? (
        /* Preview Card dengan Info Kompresi & Tombol Aksi */
        <div className="p-3.5 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-3">
          <div className="relative w-full aspect-[16/9] sm:aspect-[2/1] rounded-xl overflow-hidden bg-black/10 border border-black/5 shadow-inner">
            <img
              src={value}
              alt="Pratinjau upload"
              className="w-full h-full object-cover"
            />
            {isPanorama && (
              <div className="absolute top-2 left-2 px-2.5 py-1 rounded-lg bg-black/75 text-white text-[10px] font-bold backdrop-blur-sm flex items-center gap-1.5">
                <Sparkles className="w-3 h-3 text-[#A7F3D0]" />
                <span>Tekstur Panorama 360° Aktif</span>
              </div>
            )}
          </div>

          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
            <div className="space-y-0.5">
              {meta ? (
                <>
                  <div className="font-extrabold text-[#1B1F1A] flex items-center gap-1.5 truncate">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#1E9E5A] shrink-0" />
                    <span className="truncate">{meta.fileName}</span>
                  </div>
                  <div className="text-[11px] text-[#4A5248] flex flex-wrap items-center gap-2">
                    <span className="font-mono">{meta.width} × {meta.height} px</span>
                    <span>•</span>
                    <span className="text-[#166534] font-bold">
                      {formatByteSize(meta.compressedSize)} (Hemat{' '}
                      {Math.round(
                        (1 - meta.compressedSize / Math.max(1, meta.originalSize)) * 100
                      )}
                      %)
                    </span>
                  </div>
                  {isPanorama && (
                    <div className="text-[10px] font-bold mt-1">
                      {meta.isEquirectangular ? (
                        <span className="text-[#166534]">
                          ✓ Rasio 2:1 Terdeteksi (Optimal untuk VR/360)
                        </span>
                      ) : (
                        <span className="text-[#D95637]">
                          ⚠ Rasio ({meta.aspectRatio.toFixed(2)}:1) disarankan 2:1 agar tidak terjadi distorsi bola
                        </span>
                      )}
                    </div>
                  )}
                </>
              ) : (
                <div className="text-[11px] text-[#4A5248]">
                  Foto tersimpan dari penyimpanan lokal terkompresi.
                </div>
              )}
            </div>

            <div className="flex items-center gap-2 shrink-0 self-end sm:self-center">
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={isProcessing}
                className="min-h-[38px] px-3.5 py-1.5 rounded-xl bg-white hover:bg-gray-100 text-[#234B24] border border-[#CFD8BE] text-xs font-bold flex items-center gap-1.5 shadow-sm transition"
              >
                <RefreshCw className="w-3.5 h-3.5" />
                <span>Ganti File</span>
              </button>
              <button
                type="button"
                onClick={handleClear}
                className="min-h-[38px] px-3 py-1.5 rounded-xl bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637] text-xs font-bold flex items-center gap-1 transition"
                title="Hapus foto ini"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>Hapus</span>
              </button>
            </div>
          </div>
        </div>
      ) : (
        /* Empty Dropzone Area */
        <div
          onClick={() => fileInputRef.current?.click()}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          className={`p-6 sm:p-8 rounded-2xl border-2 border-dashed transition cursor-pointer text-center flex flex-col items-center justify-center gap-2 ${isDragging
              ? 'border-[#234B24] bg-[#E4E9DA]/50 scale-[1.01]'
              : 'border-[#CFD8BE] bg-[#F6F3EC]/70 hover:bg-[#E4E9DA]/40 hover:border-[#234B24]'
            }`}
        >
          <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm">
            {isProcessing ? (
              <RefreshCw className="w-6 h-6 animate-spin" />
            ) : (
              <UploadCloud className="w-6 h-6" />
            )}
          </div>

          <div className="space-y-0.5">
            <p className="text-xs font-extrabold text-[#1B1F1A]">
              {isProcessing
                ? 'Mengompresi & Mengoptimalkan Gambar...'
                : 'Klik untuk Memilih File atau Tarik & Lepas Foto'}
            </p>
            <p className="text-[11px] text-[#4A5248]">
              Format: JPG, PNG, WEBP (Otomatis dikompresi ringan via HTML5 Canvas)
            </p>
          </div>

          {helperText && (
            <p className="text-[10px] text-[#767676] max-w-sm italic">
              {helperText}
            </p>
          )}
        </div>
      )}

      {errorMsg && (
        <p className="text-xs font-semibold text-[#D95637] flex items-center gap-1 mt-1">
          <AlertCircle className="w-3.5 h-3.5 shrink-0" />
          <span>{errorMsg}</span>
        </p>
      )}
    </div>
  );
};
