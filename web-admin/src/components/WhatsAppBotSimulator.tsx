import React, { useState, useEffect } from 'react';
import {
  MessageSquare,
  Send,
  Check,
  CheckCheck,
  QrCode,
  ShieldCheck,
  DollarSign,
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
} from 'lucide-react';
import { Partner, EscrowTransaction } from '../types/contract';
import { processWASimulationAction } from '../services/api';

interface WhatsAppBotSimulatorProps {
  partners: Partner[];
  onPartnerUpdated?: (updated: Partner) => void;
  showToast?: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

interface ChatMessage {
  id: string;
  sender: 'system_bot' | 'mitra';
  text: string;
  time: string;
  isStatusChange?: boolean;
  qrCode?: string;
  actionType?: 'accept' | 'reject' | 'redeem';
}

export const WhatsAppBotSimulator: React.FC<WhatsAppBotSimulatorProps> = ({
  partners,
  onPartnerUpdated,
  showToast,
}) => {
  const [selectedPartnerId, setSelectedPartnerId] = useState<string>(
    partners[0]?.id || 'partner-001'
  );

  const activePartner =
    partners.find((p) => p.id === selectedPartnerId) || partners[0];

  // Active Transaction for Simulation
  const [activeBookingCode, setActiveBookingCode] = useState<string>('WISGO-HARAU-892');
  const [touristName, setTouristName] = useState<string>('Siti Rahma (Keluarga Jakarta)');
  const [bookingAmount, setBookingAmount] = useState<number>(350000);
  const [orderStatus, setOrderStatus] = useState<
    'PENDING' | 'ESCROW_LOCKED' | 'REJECTED' | 'REDEEMED'
  >('PENDING');

  // Messages log
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [typedMessage, setTypedMessage] = useState<string>('');
  const [isProcessing, setIsProcessing] = useState<boolean>(false);

  // Initialize or reset chat scenario
  const initChatScenario = (bookingCode = 'WISGO-HARAU-892') => {
    setActiveBookingCode(bookingCode);
    setOrderStatus('PENDING');
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    const initMsg: ChatMessage = {
      id: `msg-${Date.now()}-1`,
      sender: 'system_bot',
      text: `🔔 *NOTIFIKASI PESANAN WISATAWAN (WISGO ESCROW)*\n----------------------------------------\n*Kode Booking:* ${bookingCode}\n*Pemesan:* ${touristName}\n*Layanan:* ${activePartner?.name || 'Mitra Nagari'}\n*Tanggal Layanan:* 25 Desember 2026\n*Total Tagihan:* Rp ${bookingAmount.toLocaleString('id-ID')} (MYR ~98)\n*Status Dana:* Tertahan Aman di Rekening Bersama Escrow WISGO Sumbar\n----------------------------------------\nKetik/Tekan *1* untuk MENERIMA pesanan.\nKetik/Tekan *0* untuk MENOLAK pesanan.`,
      time: nowTime,
    };

    setMessages([initMsg]);
  };

  useEffect(() => {
    initChatScenario(`WISGO-${Math.floor(100 + Math.random() * 900)}`);
  }, [selectedPartnerId]);

  // Handle Action 1: Terima Pesanan
  const handleAcceptOrder = async () => {
    if (orderStatus !== 'PENDING') return;
    setIsProcessing(true);
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    // Mitra sends '1'
    const replyMsg: ChatMessage = {
      id: `msg-${Date.now()}-reply`,
      sender: 'mitra',
      text: '1',
      time: nowTime,
    };

    setMessages((prev) => [...prev, replyMsg]);

    try {
      const res = await processWASimulationAction('1', activeBookingCode);
      setOrderStatus('ESCROW_LOCKED');

      const botConfirmMsg: ChatMessage = {
        id: `msg-${Date.now()}-bot-accept`,
        sender: 'system_bot',
        text: `✅ *PESANAN DITERIMA & DIKONFIRMASI!*\n\nDana senilai *Rp ${bookingAmount.toLocaleString('id-ID')}* telah dikunci di Rekening Escrow Resmi Pemerintah Provinsi Sumatera Barat.\n\nE-Ticket & Barcode Kedatangan telah diterbitkan untuk ${touristName}.\n\n*Petunjuk Mitra:* Saat wisatawan tiba di lokasi, scan QR E-Ticket wisatawan untuk mencairkan dana langsung ke rekening nagari Anda.`,
        time: nowTime,
        qrCode: res.qr_code_ticket,
        actionType: 'accept',
      };

      setMessages((prev) => [...prev, botConfirmMsg]);
      if (res.updatedPartner && onPartnerUpdated) {
        onPartnerUpdated(res.updatedPartner);
      }
      showToast?.(
        `Pesanan ${activeBookingCode} DITERIMA. Dana terkunci di Escrow WISGO!`,
        'success'
      );
    } catch {
      showToast?.('Gagal memproses konfirmasi pesanan.', 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle Action 0: Tolak Pesanan
  const handleRejectOrder = async () => {
    if (orderStatus !== 'PENDING') return;
    setIsProcessing(true);
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    // Mitra sends '0'
    const replyMsg: ChatMessage = {
      id: `msg-${Date.now()}-reply`,
      sender: 'mitra',
      text: '0',
      time: nowTime,
    };

    setMessages((prev) => [...prev, replyMsg]);

    try {
      const res = await processWASimulationAction('0', activeBookingCode);
      setOrderStatus('REJECTED');

      const botRejectMsg: ChatMessage = {
        id: `msg-${Date.now()}-bot-reject`,
        sender: 'system_bot',
        text: `❌ *PESANAN DITOLAK*\n\nAnda telah menolak pesanan *${activeBookingCode}*. Dana simulasi senilai *Rp ${bookingAmount.toLocaleString('id-ID')}* telah dikembalikan 100% ke saldo wisatawan tanpa potongan.`,
        time: nowTime,
        actionType: 'reject',
      };

      setMessages((prev) => [...prev, botRejectMsg]);
      if (res.updatedPartner && onPartnerUpdated) {
        onPartnerUpdated(res.updatedPartner);
      }
      showToast?.(
        `Pesanan ${activeBookingCode} DITOLAK. Dana dikembalikan ke wisatawan.`,
        'info'
      );
    } catch {
      showToast?.('Gagal memproses penolakan pesanan.', 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle Scan QR: Pencairan Escrow
  const handleScanQREticket = async () => {
    if (orderStatus !== 'ESCROW_LOCKED') return;
    setIsProcessing(true);
    const nowTime = new Date().toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    try {
      const res = await processWASimulationAction('scan', activeBookingCode);
      setOrderStatus('REDEEMED');

      const botRedeemMsg: ChatMessage = {
        id: `msg-${Date.now()}-bot-redeem`,
        sender: 'system_bot',
        text: `🎉 *SCAN QR E-TICKET BERHASIL!*\n\nWisatawan telah divalidasi hadir di lokasi ${activePartner?.nagari_name || 'Nagari'}.\n\nDana senilai *Rp ${bookingAmount.toLocaleString('id-ID')}* telah sukses *DICAIRKAN* dari Rekening Escrow ke Rekening Bank Nagari mitra: *${activePartner?.owner_name || activePartner?.name}*.\n\n_Terima kasih telah memberikan pelayanan terbaik bagi pariwisata Ranah Minang!_`,
        time: nowTime,
        actionType: 'redeem',
      };

      setMessages((prev) => [...prev, botRedeemMsg]);
      if (res.updatedPartner && onPartnerUpdated) {
        onPartnerUpdated(res.updatedPartner);
      }
      showToast?.(
        `QR E-Ticket ${activeBookingCode} berhasil divalidasi. Dana Cair ke Nagari!`,
        'success'
      );
    } catch {
      showToast?.('Gagal memproses pencairan dana escrow.', 'error');
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle custom text input
  const handleSendCustomText = (e: React.FormEvent) => {
    e.preventDefault();
    if (!typedMessage.trim() || isProcessing) return;

    const trimmed = typedMessage.trim();
    if (trimmed === '1') {
      handleAcceptOrder();
    } else if (trimmed === '0') {
      handleRejectOrder();
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
      setMessages((prev) => [
        ...prev,
        userMsg,
        {
          id: `msg-${Date.now()}-help`,
          sender: 'system_bot',
          text: '💡 *Panduan Bot WISGO Sumbar:* Balas *1* untuk menerima pesanan atau *0* untuk menolak pesanan.',
          time: nowTime,
        },
      ]);
    }
    setTypedMessage('');
  };

  return (
    <div className="space-y-6">
      {/* Header Halaman Simulator */}
      <header className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA]">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#075E54] text-white flex items-center justify-center shadow-sm shrink-0">
              <MessageSquare className="w-6 h-6" aria-hidden="true" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                  Simulator Bot WhatsApp Mitra &amp; Pencairan Escrow
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  Simulasi 2-Arah Live
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1">
                Menguji alur interaksi pesan instan WhatsApp UMKM Nagari: penerimaan order wisatawan, penguncian dana di Rekening Bersama Escrow, dan pencairan instan via scan QR code E-Ticket.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <label htmlFor="sim-partner-select" className="text-xs font-bold text-[#4A5248] whitespace-nowrap">
              Pilih Mitra:
            </label>
            <select
              id="sim-partner-select"
              value={selectedPartnerId}
              onChange={(e) => setSelectedPartnerId(e.target.value)}
              className="px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] focus:outline-none focus:ring-2 focus:ring-[#234B24]"
            >
              {partners.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name} ({p.category})
                </option>
              ))}
            </select>
          </div>
        </div>
      </header>

      {/* Main Grid: WhatsApp Phone Mockup (Kiri) + Control Dashboard (Kanan) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* WhatsApp Phone Mockup Container (Col 7) */}
        <div className="lg:col-span-7 bg-[#EFEAE2] rounded-[32px] border-4 border-[#234B24] shadow-xl overflow-hidden flex flex-col h-[680px]">
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
                  <span>Online · Bot Otomatis WISGO Nagari</span>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => initChatScenario(`WISGO-${Math.floor(100 + Math.random() * 900)}`)}
                title="Muat Ulang Skenario Pesanan Baru"
                className="p-2 rounded-xl bg-white/10 hover:bg-white/20 text-white transition text-xs font-bold flex items-center gap-1"
              >
                <RotateCcw className="w-3.5 h-3.5" aria-hidden="true" />
                <span className="hidden sm:inline">Reset Skenario</span>
              </button>
            </div>
          </div>

          {/* Chat Messages Body */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3.5">
            {/* Security Notice Bubble */}
            <div className="flex justify-center">
              <div className="bg-[#FFEECD] text-[#854D0E] text-[10px] font-bold px-3 py-1.5 rounded-lg shadow-2xs border border-[#FDE047]/60 flex items-center gap-1.5 max-w-sm text-center">
                <ShieldCheck className="w-3.5 h-3.5 shrink-0 text-[#CA8A04]" aria-hidden="true" />
                <span>Pesan ini terenkripsi sistem transaksi aman Escrow Dinas Pariwisata Prov. Sumbar.</span>
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
                    className={`max-w-[85%] sm:max-w-[75%] rounded-2xl p-3.5 shadow-sm text-xs leading-relaxed ${
                      isMitra
                        ? 'bg-[#D9FDD3] text-[#111B21] rounded-tr-xs'
                        : 'bg-white text-[#111B21] rounded-tl-xs border border-[#E4E9DA]'
                    }`}
                  >
                    <div className="whitespace-pre-line font-normal">
                      {msg.text}
                    </div>

                    {/* QR Code Preview in message */}
                    {msg.qrCode && (
                      <div className="mt-3 p-3 rounded-xl bg-[#F6F3EC] border border-[#234B24]/30 flex flex-col items-center justify-center text-center">
                        <QrCode className="w-20 h-20 text-[#234B24]" aria-hidden="true" />
                        <span className="mt-1 font-mono text-[11px] font-extrabold text-[#234B24]">
                          {msg.qrCode}
                        </span>
                        <span className="text-[10px] text-[#4A5248]">
                          E-Ticket Resmi Wisatawan (Tunjukkan ke Mitra)
                        </span>
                      </div>
                    )}

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
              Aksi Cepat:
            </span>

            {orderStatus === 'PENDING' && (
              <>
                <button
                  type="button"
                  onClick={handleAcceptOrder}
                  disabled={isProcessing}
                  className="px-3.5 py-1.5 rounded-full bg-[#128C7E] hover:bg-[#075E54] text-white font-bold text-xs flex items-center gap-1.5 shadow-xs transition disabled:opacity-50"
                >
                  <Check className="w-3.5 h-3.5" aria-hidden="true" />
                  <span>Balas 1 (Terima Pesanan)</span>
                </button>
                <button
                  type="button"
                  onClick={handleRejectOrder}
                  disabled={isProcessing}
                  className="px-3.5 py-1.5 rounded-full bg-[#EA4335] hover:bg-[#C5221F] text-white font-bold text-xs flex items-center gap-1.5 shadow-xs transition disabled:opacity-50"
                >
                  <XCircle className="w-3.5 h-3.5" aria-hidden="true" />
                  <span>Balas 0 (Tolak Pesanan)</span>
                </button>
              </>
            )}

            {orderStatus === 'ESCROW_LOCKED' && (
              <button
                type="button"
                onClick={handleScanQREticket}
                disabled={isProcessing}
                className="px-4 py-2 rounded-full bg-[#234B24] hover:bg-[#1B3B1C] text-white font-extrabold text-xs flex items-center gap-2 shadow-sm transition animate-bounce"
              >
                <QrCode className="w-4 h-4 text-[#A7F3D0]" aria-hidden="true" />
                <span>Simulasi Scan QR E-Ticket (Cairkan Escrow)</span>
              </button>
            )}

            {orderStatus === 'REDEEMED' && (
              <span className="px-3 py-1 rounded-full bg-[#DCFCE7] text-[#166534] text-xs font-bold flex items-center gap-1.5 border border-[#86EFAC]">
                <CheckCircle2 className="w-3.5 h-3.5" aria-hidden="true" />
                <span>Escrow Telah Dicairkan ke Rekening Nagari</span>
              </span>
            )}

            {orderStatus === 'REJECTED' && (
              <span className="px-3 py-1 rounded-full bg-[#FEE2E2] text-[#991B1B] text-xs font-bold flex items-center gap-1.5 border border-[#FCA5A5]">
                <XCircle className="w-3.5 h-3.5" aria-hidden="true" />
                <span>Pesanan Ditolak &amp; Dana Dikembalikan</span>
              </span>
            )}
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
              placeholder="Ketik '1' untuk terima, '0' untuk tolak..."
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

        {/* Dashboard Informasi Escrow & Metrik Real-Time (Col 5) */}
        <div className="lg:col-span-5 space-y-5">
          {/* Kartu Status Alur Saat Ini */}
          <div className="bg-white rounded-[24px] p-6 shadow-sm border border-[#E4E9DA]">
            <h3 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
              <span>Status Alur Transaksi Escrow Saat Ini</span>
            </h3>

            <div className="mt-4 p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] space-y-2.5">
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Kode Booking:</span>
                <span className="font-mono font-extrabold text-[#234B24]">{activeBookingCode}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Wisatawan:</span>
                <span className="font-semibold text-[#1B1F1A]">{touristName}</span>
              </div>
              <div className="flex justify-between items-center text-xs">
                <span className="font-bold text-[#4A5248]">Nominal Escrow:</span>
                <span className="font-extrabold text-[#234B24]">Rp {bookingAmount.toLocaleString('id-ID')}</span>
              </div>
              <div className="flex justify-between items-center text-xs pt-2 border-t border-[#CFD8BE]">
                <span className="font-bold text-[#4A5248]">Status Transaksi:</span>
                <span
                  className={`px-2.5 py-0.5 rounded-full text-[11px] font-extrabold ${
                    orderStatus === 'PENDING'
                      ? 'bg-[#FEF08A] text-[#854D0E]'
                      : orderStatus === 'ESCROW_LOCKED'
                      ? 'bg-[#DBEAFE] text-[#1D4ED8]'
                      : orderStatus === 'REDEEMED'
                      ? 'bg-[#DCFCE7] text-[#166534]'
                      : 'bg-[#FEE2E2] text-[#991B1B]'
                  }`}
                >
                  {orderStatus === 'PENDING'
                    ? 'Menunggu Konfirmasi WA'
                    : orderStatus === 'ESCROW_LOCKED'
                    ? 'Dana Tertahan di Escrow'
                    : orderStatus === 'REDEEMED'
                    ? 'Cair ke Rekening Mitra Nagari'
                    : 'Pesanan Dibatalkan'}
                </span>
              </div>
            </div>
          </div>

          {/* Buku Besar Escrow Mitra Aktif */}
          <div className="bg-white rounded-[24px] p-6 shadow-sm border border-[#E4E9DA]">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                <Store className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                <span>Buku Besar Escrow: {activePartner?.name}</span>
              </h3>
              <span className="text-[11px] font-bold text-[#1E9E5A]">
                {activePartner?.ledger?.length || 0} Transaksi
              </span>
            </div>

            <div className="space-y-2 max-h-[300px] overflow-y-auto pr-1">
              {activePartner?.ledger && activePartner.ledger.length > 0 ? (
                activePartner.ledger.map((tx) => (
                  <div
                    key={tx.id}
                    className="p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs flex items-center justify-between"
                  >
                    <div>
                      <div className="font-bold text-[#1B1F1A] flex items-center gap-1.5">
                        <span>{tx.tourist_name}</span>
                        <span className="font-mono text-[10px] text-[#4A5248]">({tx.booking_code})</span>
                      </div>
                      <div className="text-[11px] text-[#4A5248] mt-0.5">
                        {tx.service_date} · Rp {tx.amount.toLocaleString('id-ID')}
                      </div>
                    </div>

                    <span
                      className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        tx.status === 'REDEEMED'
                          ? 'bg-[#DCFCE7] text-[#166534]'
                          : tx.status === 'READY_PAYOUT'
                          ? 'bg-[#FEF08A] text-[#854D0E]'
                          : 'bg-[#DBEAFE] text-[#1D4ED8]'
                      }`}
                    >
                      {tx.status === 'REDEEMED'
                        ? 'Cair'
                        : tx.status === 'READY_PAYOUT'
                        ? 'Siap Cair'
                        : 'Ditahan'}
                    </span>
                  </div>
                ))
              ) : (
                <div className="p-4 text-center text-xs text-[#767676]">
                  Belum ada riwayat transaksi pada mitra ini.
                </div>
              )}
            </div>
          </div>

          {/* Petunjuk Pengujian Penguji / Demo Panel */}
          <div className="bg-[#234B24] text-[#F6F3EC] rounded-[24px] p-5 shadow-sm border border-[#1E9E5A]">
            <h4 className="text-xs font-extrabold uppercase tracking-wider text-[#A7F3D0] flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5" aria-hidden="true" />
              <span>Skenario Pengujian Alur Escrow End-to-End</span>
            </h4>
            <ol className="mt-2.5 space-y-1.5 text-xs text-[#E4E9DA]/90 list-decimal list-inside leading-relaxed">
              <li>Pilih salah satu Mitra UMKM Nagari dari dropdown di atas.</li>
              <li>Klik tombol <strong>"Balas 1 (Terima Pesanan)"</strong> di layar WhatsApp simulator.</li>
              <li>Perhatikan bot menerbitkan E-Ticket QR dan dana terkunci di Escrow.</li>
              <li>Klik tombol <strong>"Simulasi Scan QR E-Ticket"</strong> saat wisatawan tiba di lokasi.</li>
              <li>Perhatikan status berubah menjadi <strong>"Cair ke Nagari"</strong> secara real-time.</li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
};
