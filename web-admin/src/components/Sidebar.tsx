import React from 'react';
import {
  Compass,
  QrCode,
  Camera,
  Radio,
  Store,
  MessageSquare,
  BarChart3,
  LogOut,
  CheckCircle2,
  Database,
  ExternalLink,
  Users,
  Monitor,
  Trophy,
} from 'lucide-react';
import { AdminAuthResponse } from '../types/contract';

export type AdminMenuKey =
  | 'destinations'
  | 'tariffs_qr'
  | 'cms_360'
  | 'challenges'
  | 'command_center'
  | 'saber_pungli' // alias to command_center
  | 'partners'
  | 'wa_simulator'
  | 'dispar_analytics';

interface SidebarProps {
  activeMenu: AdminMenuKey;
  onSelectMenu: (menu: AdminMenuKey) => void;
  session: AdminAuthResponse;
  backendOnline: boolean;
  totalDestinations: number;
  totalTariffs: number;
  totalPartners?: number;
  openPungliCount?: number;
  openSosCount?: number;
  onOpenPublicQR?: () => void;
  onOpenGroupInvite?: () => void;
  onOpenSystemBenchmark?: () => void;
  isShowcaseMode?: boolean;
  onToggleShowcaseMode?: () => void;
  onLogout: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeMenu,
  onSelectMenu,
  session,
  backendOnline,
  totalDestinations,
  totalTariffs,
  totalPartners = 5,
  openPungliCount = 2,
  openSosCount = 2,
  onOpenPublicQR,
  onOpenGroupInvite,
  onOpenSystemBenchmark,
  isShowcaseMode = false,
  onToggleShowcaseMode,
  onLogout,
}) => {
  const currentKey =
    activeMenu === 'saber_pungli' ? 'command_center' : activeMenu;

  const totalEmergencyAlerts = openPungliCount + openSosCount;

  const navItems: Array<{
    key: AdminMenuKey;
    label: string;
    sublabel: string;
    badge?: string;
    badgeColor?: string;
    icon: React.ReactNode;
  }> = [
    {
      key: 'destinations',
      label: 'Manajemen Destinasi & Medan',
      sublabel: 'Direktori & 5 Indikator Medan',
      badge: `${totalDestinations} Lokasi`,
      icon: <Compass className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'tariffs_qr',
      label: 'Standar Tarif Perda & QR',
      sublabel: 'Fair-Price Barometer & Plang QR',
      badge: `${totalTariffs} Tarif`,
      icon: <QrCode className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'cms_360',
      label: 'Studio Virtual 360°',
      sublabel: 'Kurasi Panorama & 4 Hotspot Pin',
      icon: <Camera className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'challenges',
      label: 'Gamifikasi Challenge Wisata',
      sublabel: 'Checklist Tempat & Hadiah',
      badge: 'Ceklis',
      icon: <Trophy className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'command_center',
      label: 'Pusat Komando Pungli & SOS',
      sublabel: 'Penindakan Saber & Siaga SAR',
      badge: totalEmergencyAlerts > 0 ? `${totalEmergencyAlerts} Siaga` : 'Terkendali',
      badgeColor: totalEmergencyAlerts > 0 ? 'bg-[#F26B4B] text-white' : 'bg-[#1E9E5A] text-white',
      icon: <Radio className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'partners',
      label: 'Direktori & Verifikasi Mitra UMKM',
      sublabel: '5 Kategori UMKM & Kontak WA P2P',
      badge: `${totalPartners} Mitra`,
      icon: <Store className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'wa_simulator',
      label: 'Simulator Interaksi WA Mitra',
      sublabel: 'Chat Langsung P2P & Leads 360°',
      icon: <MessageSquare className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'dispar_analytics',
      label: 'Analitik Eksekutif Dispar',
      sublabel: 'Heatmap 19 Kab/Kota & Cetak PDF',
      icon: <BarChart3 className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
  ];

  return (
    <aside
      aria-label="Navigasi Utama Pusat Komando Terpadu WISGO"
      className="w-72 lg:w-80 shrink-0 h-screen sticky top-0 overflow-y-auto sidebar-scroll flex flex-col justify-between z-30 bg-[#234B24] text-[#F6F3EC] border-b lg:border-b-0 lg:border-r border-[#1B3B1C] no-print shadow-md"
    >
      <div>
        {/* Identitas Resmi Instansi */}
        <div className="p-4 lg:p-5 border-b border-white/10 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#F26B4B] flex items-center justify-center text-white font-extrabold text-lg shadow-md shrink-0">
              W
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-lg tracking-tight text-[#F6F3EC] truncate">
                  WISGO Sumbar
                </span>
              </div>
              <p className="text-[11px] text-[#E4E9DA]/85 truncate">
                Pusat Komando Dinas Pariwisata Sumbar
              </p>
            </div>
          </div>

          {/* Indikator Status Sistem */}
          <button
            type="button"
            onClick={onOpenSystemBenchmark}
            title="Klik untuk membuka Health & Benchmark Sistem"
            className="mt-3.5 w-full text-left px-3 py-2 rounded-xl bg-black/20 hover:bg-black/35 border border-white/10 hover:border-white/25 flex items-center gap-2 text-xs transition cursor-pointer group"
          >
            <Database
              className="w-4 h-4 text-[#1E9E5A] shrink-0 group-hover:scale-110 transition"
              aria-hidden="true"
            />
            <div className="min-w-0 flex-1">
              <div className="font-semibold text-[#F6F3EC] text-[11px] leading-tight flex items-center justify-between">
                <span>
                  {backendOnline
                    ? 'Status: Terhubung Database'
                    : 'Status: Mode Lokal Aktif'}
                </span>
                <span className="text-[10px] text-[#A7F3D0] opacity-80 group-hover:opacity-100 group-hover:underline">Health &rsaquo;</span>
              </div>
            </div>
          </button>
        </div>

        {/* Menu Navigasi Operasional */}
        <nav aria-label="Menu Operasional Pusat Komando" className="p-2.5 lg:p-3">
          <p className="px-3 mb-2 text-[10.5px] font-bold uppercase tracking-wider text-[#E4E9DA]/70">
            Menu Otoritas Terpadu
          </p>
          <ul className="space-y-1">
            {navItems.map((item) => {
              const isActive = currentKey === item.key;
              return (
                <li key={item.key}>
                  <button
                    type="button"
                    aria-current={isActive ? 'page' : undefined}
                    onClick={() => onSelectMenu(item.key)}
                    className={`w-full text-left px-3 py-2 rounded-xl transition-all flex items-center justify-between min-h-[46px] gap-2 ${
                      isActive
                        ? 'bg-[#F6F3EC] text-[#1B1F1A] font-bold shadow-sm border-l-4 border-[#F26B4B]'
                        : 'text-[#F6F3EC]/90 hover:bg-white/10 font-medium'
                    }`}
                  >
                    <div className="flex items-center gap-2.5 min-w-0 flex-1">
                      <span
                        className={`shrink-0 ${
                          isActive ? 'text-[#234B24]' : 'text-[#E4E9DA]'
                        }`}
                      >
                        {item.icon}
                      </span>
                      <div className="min-w-0 flex-1">
                        <div className="text-[13.5px] font-semibold leading-snug truncate">
                          {item.label}
                        </div>
                        <div
                          className={`text-[11px] leading-tight truncate mt-0.5 ${
                            isActive ? 'text-[#4A5248]' : 'text-[#E4E9DA]/70'
                          }`}
                        >
                          {item.sublabel}
                        </div>
                      </div>
                    </div>

                    {item.badge && (
                      <span
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full shrink-0 whitespace-nowrap ${
                          item.badgeColor
                            ? item.badgeColor
                            : isActive
                            ? 'bg-[#234B24] text-[#F6F3EC]'
                            : 'bg-white/15 text-[#F6F3EC]'
                        }`}
                      >
                        {item.badge}
                      </span>
                    )}
                  </button>
                </li>
              );
            })}
          </ul>

          {/* Pratinjau Halaman Web Publik Instan (FS1-M2-04) */}
          <div className="mt-4 pt-3 border-t border-white/10">
            <p className="px-3 mb-1.5 text-[10.5px] font-bold uppercase tracking-wider text-[#A7F3D0]">
              Pratinjau Web Publik Wisatawan
            </p>
            <div className="space-y-1">
              {onOpenPublicQR && (
                <button
                  type="button"
                  onClick={onOpenPublicQR}
                  className="w-full text-left px-3 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-xs font-semibold text-[#F6F3EC] flex items-center justify-between transition min-h-[38px]"
                >
                  <span className="flex items-center gap-2 truncate">
                    <QrCode className="w-4 h-4 text-[#F26B4B] shrink-0" aria-hidden="true" />
                    <span className="truncate">Web Plang Smart QR (/qr)</span>
                  </span>
                  <ExternalLink className="w-3.5 h-3.5 text-[#E4E9DA]/70 shrink-0" aria-hidden="true" />
                </button>
              )}
              {onOpenGroupInvite && (
                <button
                  type="button"
                  onClick={onOpenGroupInvite}
                  className="w-full text-left px-3 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-xs font-semibold text-[#F6F3EC] flex items-center justify-between transition min-h-[38px]"
                >
                  <span className="flex items-center gap-2 truncate">
                    <Users className="w-4 h-4 text-[#A7F3D0] shrink-0" aria-hidden="true" />
                    <span className="truncate">Web Group Invite (/join)</span>
                  </span>
                  <ExternalLink className="w-3.5 h-3.5 text-[#E4E9DA]/70 shrink-0" aria-hidden="true" />
                </button>
              )}
            </div>
          </div>
        </nav>
      </div>

      {/* Profil Pejabat Aktif Single Admin & Tombol Keluar */}
      <div className="p-3.5 border-t border-white/10 bg-black/15">
        {onToggleShowcaseMode && (
          <button
            type="button"
            onClick={onToggleShowcaseMode}
            className={`w-full px-3 py-2 rounded-xl text-xs font-bold flex items-center justify-between transition mb-2.5 ${
              isShowcaseMode
                ? 'bg-[#F26B4B] text-white shadow-md'
                : 'bg-white/10 hover:bg-white/15 text-[#A7F3D0] border border-white/15'
            }`}
          >
            <span className="flex items-center gap-2 truncate">
              <Monitor className="w-4 h-4 text-white shrink-0" aria-hidden="true" />
              <span>{isShowcaseMode ? 'Tutup Showcase' : 'Showcase 1 Layar'}</span>
            </span>
            <span className="px-2 py-0.5 rounded text-[10px] bg-black/25">Live</span>
          </button>
        )}

        <div className="p-3 rounded-xl bg-white/5 border border-white/10 mb-2.5">
          <div className="flex items-center gap-2 text-xs font-bold text-[#A7F3D0]">
            <CheckCircle2
              className="w-4 h-4 text-[#1E9E5A] shrink-0"
              aria-hidden="true"
            />
            <span>Pusat Komando Terpadu</span>
          </div>
          <p className="text-xs font-bold text-[#F6F3EC] mt-0.5 truncate">
            {session.user.full_name || 'Administrator Utama'}
          </p>
          <p className="text-[11px] text-[#E4E9DA]/80 truncate">
            {session.user.agency || 'Dinas Pariwisata Provinsi Sumatera Barat'}
          </p>
        </div>

        <button
          type="button"
          onClick={onLogout}
          className="w-full min-h-[42px] px-4 py-2 rounded-pill bg-[#F26B4B] hover:bg-[#D95637] text-white font-bold text-xs flex items-center justify-center gap-2 transition shadow-sm"
        >
          <LogOut className="w-4 h-4" aria-hidden="true" />
          <span>Keluar dari Pusat Komando</span>
        </button>
      </div>
    </aside>
  );
};

