import React, { useState, useEffect } from 'react';
import {
  MessageSquare,
  Send,
  Check,
  CheckCheck,
  ShieldCheck,
  ArrowRight,
  RotateCcw,
  Sparkles,
  Phone,
  Store,
  Clock,
  CheckCircle2,
  XCircle,
  HelpCircle,
  Smartphone,
  ExternalLink,
  MapPin,
  Camera,
} from 'lucide-react';
import { Partner } from '../types/contract';
import { processWASimulationAction } from '../services/api';

interface WhatsAppBotSimulatorProps {
  partners: Partner[];
  onPartnerUpdated?: (updated: Partner) => void;
  showToast?: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

interface ChatMessage {
  id: string;
  sender: 'tourist' | 'mitra' | 'system_bot';
  text: string;
  time: string;
  actionType?: 'accept' | 'reject' | 'location';
}

export const WhatsAppBotSimulator: React.FC<WhatsAppBotSimulatorProps> = ({
  partners,
  onPartnerUpdated,
  showToast,
}) => {
  const [selectedPartnerId, setSelectedPartnerId] = useState<string>(
    partners[0]?.id || 'ptr-01'
  );

  const activePartner =
    partners.find((p) => p.id === selectedPartnerId) || partners[0];

  const [touristName, setTouristName] = useState<string>('Siti Rahma (Keluarga Jakarta)');
  const [inquiryStatus, setInquiryStatus] = useState<
    'PENDING' | 'CONFIRMED' | 'REJECTED' | 'LOCATION_SENT'
  >('PENDING');

  // Messages log
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [typedMessage, setTypedMessage] = useState<string>('');
  const [isProcessing, setIsProcessing] = useState<boolean>(false);

  // Initialize or reset chat scenario
  const initChatScenario = () => {
    setInquiryStatus('PENDING');
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    const touristInquiryMsg: ChatMessage = {
      id: `msg-${Date.now()}-1`,
      sender: 'tourist',
      text: `Halo ${activePartner?.name || 'Mitra Nagari'}, saya melihat profil layanan Anda melalui Tur Virtual 360° WISGO di ${activePartner?.destination_name || activePartner?.nagari_name || 'Sumatera Barat'}.\n\nApakah layanan ${activePartner?.category || 'wisata'} tersedia untuk 2 orang besok? Acuan tarif tercantum Rp ${(activePartner?.standard_fee || 50000).toLocaleString('id-ID')} (± RM ${(activePartner?.fee_myr_estimate || 15).toFixed(1)} MYR).\n\nMohon info ketersediaan dan cara pembayaran langsungnya (P2P). Terima kasih!`,
      time: nowTime,
    };

    setMessages([touristInquiryMsg]);
  };

  useEffect(() => {
    initChatScenario();
  }, [selectedPartnerId]);

  // Handle Action 1: Konfirmasi Ketersediaan & Info Pembayaran Langsung
  const handleConfirmAvailability = async () => {
    if (isProcessing) return;
    setIsProcessing(true);
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    const replyMsg: ChatMessage = {
      id: `msg-${Date.now()}-reply`,
      sender: 'mitra',
      text: `Wa'alaikumsalam / Halo Kak ${touristName}! 👋\n\nAlhamdulillah layanan kami di *${activePartner?.nagari_name || 'Nagari'}* TERSEDIA untuk besok.\n\n*Rincian Pembayaran Langsung (P2P):*\n• Tarif Resmi: Rp ${(activePartner?.standard_fee || 50000).toLocaleString('id-ID')}\n• Pembayaran: Bebas pilih QRIS Bank Nagari, Transfer Bank, atau Tunai Langsung saat tiba di lokasi tanpa potongan perantara.\n\nSilakan konfirmasi jika ingin kami pesankan slot kedatangan Kakak!`,
      time: nowTime,
      actionType: 'accept',
    };

    setMessages((prev) => [...prev, replyMsg]);

    try {
      const res = await processWASimulationAction('1', activePartner.id);
      setInquiryStatus('CONFIRMED');

      if (res.updatedPartner && onPartnerUpdated) {
        onPartnerUpdated(res.updatedPartner);
      }
      showToast?.(
        `Konfirmasi ketersediaan & pembayaran P2P terkirim ke wisatawan!`,
        'success'
      );
    } catch {
      showToast?.('Gagal memproses pengiriman balasan.', 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle Action 0: Tolak Pesanan / Slot Penuh
  const handleSlotFull = async () => {
    if (isProcessing) return;
    setIsProcessing(true);
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    const replyMsg: ChatMessage = {
      id: `msg-${Date.now()}-reply`,
      sender: 'mitra',
      text: `Halo Kak ${touristName}, mohon maaf untuk jadwal besok slot layanan kami di ${activePartner?.name} sudah penuh karena reservasi rombongan sebelumnya.\n\nApakah Kakak berkenan dijadwalkan ulang untuk lusa atau kami sambungkan ke mitra binaan Pokdarwis lain di nagari ini?`,
      time: nowTime,
      actionType: 'reject',
    };

    setMessages((prev) => [...prev, replyMsg]);

    try {
      const res = await processWASimulationAction('0', activePartner.id);
      setInquiryStatus('REJECTED');

      if (res.updatedPartner && onPartnerUpdated) {
        onPartnerUpdated(res.updatedPartner);
      }
      showToast?.(
        `Pemberitahuan slot penuh terkirim dengan ramah.`,
        'info'
      );
    } catch {
      showToast?.('Gagal memproses balasan penolakan.', 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle Action: Kirim Titik Temu Google Maps
  const handleSendLocation = () => {
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    const locationMsg: ChatMessage = {
      id: `msg-${Date.now()}-loc`,
      sender: 'mitra',
      text: `📍 *Titik Temu / Lokasi Langsung di Nagari:*\nhttps://maps.google.com/?q=${encodeURIComponent(
        (activePartner?.name || '') + ' ' + (activePartner?.nagari_name || '')
      )}\n\nPatokan: Masuk gerbang Nagari ${activePartner?.nagari_name}, plang resmi Pokdarwis berlogo WISGO. Jika butuh panduan jalan hubungi telepon saya: +${activePartner?.whatsapp}.`,
      time: nowTime,
      actionType: 'location',
    };

    setMessages((prev) => [...prev, locationMsg]);
    setInquiryStatus('LOCATION_SENT');
    showToast?.('Titik temu Google Maps berhasil dikirim ke chat!', 'info');
  };

  // Handle custom text input
  const handleSendCustomText = (e: React.FormEvent) => {
    e.preventDefault();
    if (!typedMessage.trim() || isProcessing) return;

    const trimmed = typedMessage.trim();
    if (trimmed === '1') {
      handleConfirmAvailability();
    } else if (trimmed === '0') {
      handleSlotFull();
    } else {
      const nowTime = new Date().toLocaleTimeString('id-ID', {
        hour: '2-digit',
        minute: '2-digit',
      });
      const userMsg: ChatMessage = {
        id: `msg-${Date.now()}`,
        sender: 'mitra',
        text: trimmed,
        time: nowTime,
      };
      setMessages((prev) => [...prev, userMsg]);
    }
    setTypedMessage('');
  };

  const cleanWaNumber = (activePartner?.whatsapp || '6281234567890').replace(/\D/g, '');
  const realWaUrl = `https://wa.me/${cleanWaNumber}?text=${encodeURIComponent(
    `Halo ${activePartner?.name}, saya melihat informasi layanan Anda di WISGO 360°. Apakah layanan ini tersedia?`
  )}`;

  return (
    <div className="space-y-6">
      {/* Header Halaman Simulator */}
      <header className="bg-white rounded-2xl p-6 lg:p-7 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)]">
        <div className="flex flex-col gap-5">
          {/* Baris 1: Judul Halaman & Penjelasan Eksekutif */}
          <div className="flex items-start gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#075E54] text-white flex items-center justify-center shadow-sm shrink-0 mt-0.5">
              <MessageSquare className="w-6 h-6" aria-hidden="true" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                  Simulator Interaksi WA Mitra (Direct P2P)
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  Leads Langsung 360° · Tanpa Escrow
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1 max-w-3xl leading-relaxed">
                Mendemokan alur wisatawan menemukan Pin 360° UMKM Nagari di WISGO, lalu sistem membuka obrolan langsung (P2P) ke WhatsApp mitra dengan pesan otomatis terisi. Pembayaran ditransaksikan langsung via QRIS Nagari atau Tunai tanpa perantara.
              </p>
            </div>
          </div>

          {/* Baris 2: Pemilih Mitra Simulasi */}
          <div className="pt-4 border-t border-[#234B24]/10 flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2 text-xs text-[#4A5248]">
              <span>Kanal Simulasi:</span>
              <strong className="text-[#075E54]">WhatsApp Official Sandbox (+62 {cleanWaNumber})</strong>
            </div>

            <div className="flex items-center gap-2.5">
              <label htmlFor="sim-partner-select" className="text-xs font-bold text-[#1B1F1A] whitespace-nowrap">
                Pilih Akun Mitra UMKM:
              </label>
              <select
                id="sim-partner-select"
                value={selectedPartnerId}
                onChange={(e) => setSelectedPartnerId(e.target.value)}
                className="px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] focus:outline-none focus:ring-2 focus:ring-[#234B24]"
              >
                {partners.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name} ({p.category}) · {p.nagari_name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </header>

      {/* Main Grid: WhatsApp Phone Mockup (Kiri) + Control Dashboard (Kanan) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* WhatsApp Phone Mockup Container (Col 7) */}
        <div className="lg:col-span-7 bg-[#EFEAE2] rounded-[32px] border-4 border-[#234B24] shadow-xl overflow-hidden flex flex-col h-[700px]">
          {/* Top WA Header */}
          <div className="bg-[#075E54] text-white px-4 py-3 flex items-center justify-between shrink-0 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#128C7E] flex items-center justify-center text-white font-extrabold text-sm border-2 border-white/20 shrink-0">
                {activePartner?.name.slice(0, 1) || 'W'}
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="font-bold text-sm truncate max-w-[200px]">
                    {activePartner?.name}
                  </span>
                  <ShieldCheck className="w-3.5 h-3.5 text-[#25D366] shrink-0" aria-hidden="true" />
                </div>
                <div className="text-[11px] text-[#A7F3D0] flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-[#25D366]" />
                  <span>Online · Mitra Resmi WISGO {activePartner?.nagari_name}</span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={initChatScenario}
                title="Muat Ulang Skenario Pesan Baru"
                className="p-2 rounded-xl bg-white/10 hover:bg-white/20 text-white transition text-xs font-bold flex items-center gap-1"
              >
                <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
                <span className="hidden sm:inline">Reset Skenario</span>
              </button>
            </div>
          </div>

          {/* Chat Messages Body */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3.5">
            {/* Direct P2P Notice Bubble */}
            <div className="flex justify-center">
              <div className="bg-[#FFEECD] text-[#854D0E] text-[10px] font-bold px-3 py-1.5 rounded-lg shadow-2xs border border-[#FDE047]/60 flex items-center gap-1.5 max-w-sm text-center">
                <ShieldCheck className="w-3.5 h-3.5 shrink-0 text-[#CA8A04]" aria-hidden="true" />
                <span>Pesan ini terhubung langsung (P2P) ke WhatsApp resmi mitra nagari. Bebas komisi perantara.</span>
              </div>
            </div>

            {/* Message Stream */}
            {messages.map((msg) => {
              const isMitra = msg.sender === 'mitra';

              return (
                <div
                  key={msg.id}
                  className={`flex ${isMitra ? 'justify-end' : 'justify-start'}`}
                >
                  <div
                    className={`max-w-[85%] sm:max-w-[78%] rounded-2xl p-3.5 shadow-sm text-xs leading-relaxed ${
                      isMitra
                        ? 'bg-[#D9FDD3] text-[#111B21] rounded-tr-xs'
                        : 'bg-white text-[#111B21] rounded-tl-xs border border-[#234B24]/10'
                    }`}
                  >
                    {!isMitra && (
                      <div className="text-[10px] font-bold text-[#075E54] mb-1 flex items-center gap-1">
                        <Smartphone className="w-3 h-3" />
                        <span>{touristName} (via Pin Studio 360°)</span>
                      </div>
                    )}

                    <div className="whitespace-pre-line font-normal">
                      {msg.text}
                    </div>

                    <div className="mt-1.5 flex items-center justify-end gap-1 text-[10px] text-[#667781]">
                      <span>{msg.time}</span>
                      {isMitra && <CheckCheck className="w-3.5 h-3.5 text-[#53BDEB]" aria-hidden="true" />}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Quick Reply Bar (Interactive Buttons) */}
          <div className="p-3 bg-[#F0F2F5] border-t border-[#D1D7DB] flex flex-wrap items-center gap-2">
            <span className="text-[11px] font-bold text-[#54656F] mr-1">
              Aksi Cepat Pengelola:
            </span>

            <button
              type="button"
              onClick={handleConfirmAvailability}
              disabled={isProcessing}
              className="px-3.5 py-1.5 rounded-full bg-[#128C7E] hover:bg-[#075E54] text-white font-bold text-xs flex items-center gap-1.5 shadow-xs transition disabled:opacity-50"
            >
              <Check className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Balas Ketersediaan &amp; QRIS Nagari</span>
            </button>

            <button
              type="button"
              onClick={handleSlotFull}
              disabled={isProcessing}
              className="px-3.5 py-1.5 rounded-full bg-[#EA4335] hover:bg-[#C5221F] text-white font-bold text-xs flex items-center gap-1.5 shadow-xs transition disabled:opacity-50"
            >
              <XCircle className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Balas Slot Penuh</span>
            </button>

            <button
              type="button"
              onClick={handleSendLocation}
              disabled={isProcessing}
              className="px-3.5 py-1.5 rounded-full bg-[#234B24] hover:bg-[#1B3B1C] text-white font-bold text-xs flex items-center gap-1.5 shadow-xs transition disabled:opacity-50"
            >
              <MapPin className="w-3.5 h-3.5 text-[#A7F3D0]" aria-hidden="true" />
              <span>Kirim Titik Temu Maps</span>
            </button>
          </div>

          {/* Bottom Chat Input Form */}
          <form
            onSubmit={handleSendCustomText}
            className="bg-[#F0F2F5] px-3 pb-3 flex items-center gap-2 shrink-0"
          >
            <input
              type="text"
              value={typedMessage}
              onChange={(e) => setTypedMessage(e.target.value)}
              placeholder="Ketik pesan balasan mitra atau '1' untuk terima..."
              className="flex-1 px-4 py-2 rounded-full bg-white border border-[#D1D7DB] text-xs text-[#111B21] focus:outline-none focus:ring-2 focus:ring-[#128C7E]"
            />
            <button
              type="submit"
              disabled={!typedMessage.trim() || isProcessing}
              aria-label="Kirim Pesan WhatsApp"
              className="w-9 h-9 rounded-full bg-[#128C7E] hover:bg-[#075E54] text-white flex items-center justify-center shrink-0 shadow-sm transition disabled:opacity-50"
            >
              <Send className="w-4 h-4" aria-hidden="true" />
            </button>
          </form>
        </div>

        {/* Dashboard Informasi Direct P2P & Metrik Leads (Col 5) */}
        <div className="lg:col-span-5 space-y-5">
          {/* Kartu Status Interaksi Saat Ini */}
          <div className="bg-white rounded-2xl p-6 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)]">
            <h3 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
              <span>Status Interaksi &amp; Profil Kontak Langsung (P2P)</span>
            </h3>

            <div className="mt-4 p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-3">
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Mitra UMKM:</span>
                <span className="font-extrabold text-[#234B24]">{activePartner?.name}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Kategori / Nagari:</span>
                <span className="font-semibold text-[#1B1F1A]">
                  {activePartner?.category} · {activePartner?.nagari_name}
                </span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Nomor WhatsApp Resmi:</span>
                <span className="font-mono font-bold text-[#075E54]">+{activePartner?.whatsapp}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Acuan Tarif Langsung:</span>
                <span className="font-extrabold text-[#234B24]">
                  Rp {(activePartner?.standard_fee || 50000).toLocaleString('id-ID')}
                  <span className="text-[10px] text-[#767676] font-normal ml-1">
                    (± RM {(activePartner?.fee_myr_estimate || 15).toFixed(1)} MYR)
                  </span>
                </span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Total Interaksi (Leads WA):</span>
                <span className="font-extrabold text-[#1B1F1A]">
                  {(activePartner?.wa_click_count || 140).toLocaleString('id-ID')} Klik
                </span>
              </div>
              <div className="pt-2 border-t border-[#CFD8BE]">
                <span className="text-[10px] font-bold text-[#4A5248] block mb-1.5">
                  Saluran Pembayaran Langsung (Direct P2P):
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {(activePartner?.direct_payment_methods || [
                    'QRIS Bank Nagari',
                    'Transfer Bank',
                    'Tunai Langsung',
                  ]).map((method) => (
                    <span
                      key={method}
                      className="px-2.5 py-0.5 rounded-full bg-white border border-[#234B24]/20 text-[#234B24] font-bold text-[10px]"
                    >
                      ✓ {method}
                    </span>
                  ))}
                </div>
              </div>
            </div>

            {/* Tombol Buka Web WhatsApp Asli */}
            <div className="mt-4">
              <a
                href={realWaUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full min-h-[44px] px-4 py-2.5 rounded-xl bg-[#25D366] hover:bg-[#1EBE5D] text-white font-extrabold text-xs inline-flex items-center justify-center gap-2 shadow-sm transition"
              >
                <MessageSquare className="w-4 h-4" />
                <span>Buka Langsung di Web WhatsApp (wa.me)</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>

          {/* Integrasi Titik Pin 360° */}
          <div className="bg-white rounded-2xl p-6 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)]">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Camera className="w-4 h-4 text-[#1D4ED8]" aria-hidden="true" />
                <span>Integrasi Titik Pin 360° Mitra</span>
              </h3>
              <span className="text-[11px] font-bold text-[#1D4ED8]">
                {activePartner?.has_360_pin ? 'Aktif Terhubung' : 'Standby'}
              </span>
            </div>

            <div className="p-3.5 rounded-xl bg-[#BFDBFE]/20 border border-[#93C5FD] text-xs space-y-1.5">
              <div className="font-bold text-[#1B1F1A]">
                {activePartner?.destination_name || 'Destinasi Terdaftar'}
              </div>
              <div className="text-[11px] text-[#4A5248]">
                Spot: Pitch {activePartner?.pitch || -15}°, Yaw {activePartner?.yaw || 45}°
              </div>
              <p className="text-[10px] text-[#4A5248] pt-1">
                Ketika wisatawan menjelajahi panorama 360°, mengetuk Pin UMKM akan memicu link WhatsApp ini secara otomatis.
              </p>
            </div>
          </div>

          {/* Panduan Otoritas Dinas Pariwisata */}
          <div className="bg-[#234B24] text-[#F6F3EC] rounded-2xl p-5 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)]">
            <h4 className="text-xs font-extrabold uppercase tracking-wider text-[#A7F3D0] flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Prinsip Direct P2P Tanpa Perantara Escrow</span>
            </h4>
            <ol className="mt-2.5 space-y-1.5 text-xs text-[#E4E9DA]/90 list-decimal list-inside leading-relaxed">
              <li>Pilih mitra UMKM dari menu dropdown di atas.</li>
              <li>Pesan pertama mencerminkan format otomatis saat wisatawan mengklik Pin 360°.</li>
              <li>Gunakan tombol <strong>"Balas Ketersediaan &amp; QRIS Nagari"</strong> untuk konfirmasi langsung.</li>
              <li>Wisatawan membayar mandiri tanpa perantara rekening bersama maupun potongan biaya platform.</li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
};
