import React, { useRef, useState } from 'react';
import {
  Music,
  Trash2,
  RefreshCw,
  Volume2,
  CheckCircle2,
  AlertCircle,
} from 'lucide-react';
import { formatByteSize } from '../utils/imageOptimizer';

interface AudioDropzoneProps {
  label: string;
  value?: string;
  onChange: (audioDataUrl: string, fileName?: string) => void;
  onClear?: () => void;
  helperText?: string;
}

export const AudioDropzone: React.FC<AudioDropzoneProps> = ({
  label,
  value,
  onChange,
  onClear,
  helperText,
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [fileName, setFileName] = useState<string>('');
  const [fileSize, setFileSize] = useState<number>(0);
  const [errorMsg, setErrorMsg] = useState<string>('');
  const [isPlaying, setIsPlaying] = useState(false);

  const handleFile = (file: File) => {
    setErrorMsg('');
    if (!file.type.startsWith('audio/')) {
      setErrorMsg('File harus berformat audio (.mp3, .wav, .ogg, .m4a).');
      return;
    }

    if (file.size > 8 * 1024 * 1024) {
      setErrorMsg('Ukuran file audio maksimal 8 MB.');
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      const dataUrl = e.target?.result as string;
      setFileName(file.name);
      setFileSize(file.size);
      onChange(dataUrl, file.name);
    };
    reader.onerror = () => {
      setErrorMsg('Gagal membaca file audio.');
    };
    reader.readAsDataURL(file);
  };

  const handleClear = () => {
    setFileName('');
    setFileSize(0);
    setErrorMsg('');
    if (fileInputRef.current) fileInputRef.current.value = '';
    if (onClear) onClear();
    else onChange('');
  };

  const hasAudio = Boolean(value);

  return (
    <div className="space-y-1.5 w-full">
      <div className="flex items-center justify-between">
        <label className="text-xs font-bold text-[#1B1F1A]">{label}</label>
        <span className="text-[10px] text-[#767676]">Audio MP3 / WAV</span>
      </div>

      <input
        ref={fileInputRef}
        type="file"
        accept="audio/mp3,audio/wav,audio/ogg,audio/mpeg,audio/m4a"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) handleFile(file);
        }}
        className="hidden"
      />

      {hasAudio ? (
        <div className="p-3.5 rounded-2xl bg-[#C7D2FE]/25 border border-[#A5B4FC] flex items-center justify-between gap-3 text-xs">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-9 h-9 rounded-xl bg-[#4F46E5] text-white flex items-center justify-center shrink-0 shadow-xs">
              <Volume2 className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <div className="font-extrabold text-[#1B1F1A] truncate">
                {fileName || 'File Audio Latar Aktif'}
              </div>
              <div className="text-[11px] text-[#4F46E5] flex items-center gap-1.5">
                <CheckCircle2 className="w-3 h-3 text-[#4F46E5]" />
                <span>
                  {fileSize > 0 ? formatByteSize(fileSize) : 'Audio Terunggah'} · Siap Diputar
                </span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            {/* Audio player preview */}
            <audio
              controls
              src={value}
              className="h-8 max-w-[160px] sm:max-w-[200px]"
            />
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="p-2 rounded-lg bg-white hover:bg-gray-100 text-[#4F46E5] border border-[#A5B4FC]"
              title="Ganti audio"
            >
              <RefreshCw className="w-3.5 h-3.5" />
            </button>
            <button
              type="button"
              onClick={handleClear}
              className="p-2 rounded-lg bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637]"
              title="Hapus audio"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      ) : (
        <div
          onClick={() => fileInputRef.current?.click()}
          className="p-4 rounded-xl border border-dashed border-[#CFD8BE] bg-[#F6F3EC]/60 hover:bg-[#E4E9DA]/40 cursor-pointer flex items-center justify-between gap-2"
        >
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-[#E4E9DA] text-[#234B24] flex items-center justify-center">
              <Music className="w-4 h-4" />
            </div>
            <div>
              <p className="text-xs font-bold text-[#1B1F1A]">
                Pilih File Audio dari Komputer
              </p>
              <p className="text-[10px] text-[#767676]">
                {helperText || 'Format MP3/WAV untuk narasi Minang atau ambient alam'}
              </p>
            </div>
          </div>
          <span className="text-xs font-bold text-[#234B24] px-3 py-1 rounded-lg bg-white border border-[#CFD8BE]">
            Pilih Audio
          </span>
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
