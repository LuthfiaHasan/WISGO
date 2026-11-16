import React from 'react';
import {
  Compass,
  QrCode,
  Camera,
  Radio,
  Store,
  BarChart3,
  LogOut,
  CheckCircle2,
  Database,
  ExternalLink,
  Users,
} from 'lucide-react';
import { AdminAuthResponse } from '../types/contract';

export type AdminMenuKey =
  | 'destinations'
  | 'tariffs_qr'
  | 'cms_360'
  | 'command_center'
  | 'saber_pungli' // alias to command_center
  | 'wa_simulator'
  | 'dispar_analytics';

interface SidebarProps {
  activeMenu: AdminMenuKey;
  onSelectMenu: (menu: AdminMenuKey) => void;
  session: AdminAuthResponse;
  backendOnline: boolean;
  totalDestinations: number;
  totalTariffs: number;
  openPungliCount?: number;
  openSosCount?: number;
  onOpenPublicQR?: () => void;
  onOpenGroupInvite?: () => void;
  onLogout: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeMenu,
  onSelectMenu,
  session,
  backendOnline,
  totalDestinations,
  totalTariffs,
  openPungliCount = 2,
  openSosCount = 2,
  onOpenPublicQR,
  onOpenGroupInvite,
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
      sublabel: 'Kurasi Panorama & Titik Interaktif',
      icon: <Camera className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'command_center',
      label: 'Pusat Komando Pungli & SOS SAR',
      sublabel: 'Penindakan Saber Pungli & Siaga SAR',
      badge: totalEmergencyAlerts > 0 ? `${totalEmergencyAlerts} Siaga` : 'Terkendali',
      badgeColor: totalEmergencyAlerts > 0 ? 'bg-[#F26B4B] text-white' : 'bg-[#1E9E5A] text-white',
      icon: <Radio className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'wa_simulator',
      label: 'Monitoring Mitra & Escrow',
      sublabel: 'UMKM Nagari & Konfirmasi Pesanan',
      icon: <Store className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
    {
      key: 'dispar_analytics',
      label: 'Analitik Eksekutif Dispar',
      sublabel: 'Kunjungan & Ekonomi 19 Kab/Kota',
      icon: <BarChart3 className="w-5 h-5 shrink-0" aria-hidden="true" />,
    },
  ];

  return (
    <aside
      aria-label="Navigasi Utama Pusat Komando Terpadu Rancak.in"
      className="w-full lg:w-80 bg-[#234B24] text-[#F6F3EC] flex flex-col justify-between shrink-0 lg:min-h-screen border-b lg:border-b-0 lg:border-r border-[#1B3B1C] no-print"
    >
      <div>
        {/* Identitas Resmi Instansi */}
        <div className="p-6 border-b border-white/10">
          <div className="flex items-center gap-3.5">
            <div className="w-11 h-11 rounded-2xl bg-[#F26B4B] flex items-center justify-center text-white font-extrabold text-lg shadow-md shrink-0">
              R
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-extrabold text-lg tracking-tight text-[#F6F3EC] truncate">
                  Rancak.in Sumbar
                </span>
              </div>
              <p className="text-xs text-[#E4E9DA]/85 truncate">
                Pusat Komando Dinas Pariwisata Sumbar
              </p>
            </div>
          </div>

          {/* Indikator Status Sistem */}
          <div className="mt-4 px-3.5 py-2.5 rounded-xl bg-black/20 border border-white/10 flex items-center gap-2.5 text-xs">
            <Database
              className="w-4 h-4 text-[#1E9E5A] shrink-0"
              aria-hidden="true"
            />
            <div className="min-w-0 flex-1">
              <div className="font-semibold text-[#F6F3EC] truncate">
                {backendOnline
                  ? 'Status Sistem: Terhubung (Database Utama)'
                  : 'Status Sistem: Mode Lokal Aktif (Sinkronisasi Otomatis)'}
              </div>
            </div>
          </div>
        </div>

        {/* Menu Navigasi Operasional */}
        <nav aria-label="Menu Operasional Pusat Komando" className="p-4">
          <p className="px-3 mb-2.5 text-[11px] font-bold uppercase tracking-wider text-[#E4E9DA]/70">
            Menu Otoritas Terpadu
          </p>
          <ul className="space-y-1.5">
            {navItems.map((item) => {
              const isActive = currentKey === item.key;
              return (
                <li key={item.key}>
                  <button
                    type="button"
                    aria-current={isActive ? 'page' : undefined}
                    onClick={() => onSelectMenu(item.key)}
                    className={`w-full text-left px-3.5 py-3 rounded-2xl transition-all flex items-center justify-between min-h-[50px] ${
                      isActive
                        ? 'bg-[#F6F3EC] text-[#1B1F1A] font-bold shadow-sm border-l-4 border-[#F26B4B]'
                        : 'text-[#F6F3EC]/90 hover:bg-white/10 font-medium'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <span
                        className={
                          isActive ? 'text-[#234B24]' : 'text-[#E4E9DA]'
                        }
                      >
                        {item.icon}
                      </span>
                      <div className="truncate">
                        <div className="text-sm leading-tight truncate">
                          {item.label}
                        </div>
                        <div
                          className={`text-[11px] truncate mt-0.5 ${
                            isActive ? 'text-[#4A5248]' : 'text-[#E4E9DA]/70'
                          }`}
                        >
                          {item.sublabel}
                        </div>
                      </div>
                    </div>

                    {item.badge && (
                      <span
                        className={`ml-2 text-[11px] font-bold px-2.5 py-0.5 rounded-full shrink-0 ${
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
          <div className="mt-6 pt-4 border-t border-white/10">
            <p className="px-3 mb-2 text-[11px] font-bold uppercase tracking-wider text-[#A7F3D0]">
              Pratinjau Web Publik Wisatawan
            </p>
            <div className="space-y-1.5">
              {onOpenPublicQR && (
                <button
                  type="button"
                  onClick={onOpenPublicQR}
                  className="w-full text-left px-3.5 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-xs font-semibold text-[#F6F3EC] flex items-center justify-between transition"
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
                  className="w-full text-left px-3.5 py-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-xs font-semibold text-[#F6F3EC] flex items-center justify-between transition"
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
      <div className="p-4 border-t border-white/10 bg-black/15">
        <div className="p-3.5 rounded-2xl bg-white/5 border border-white/10 mb-3">
          <div className="flex items-center gap-2 text-xs font-bold text-[#A7F3D0]">
            <CheckCircle2
              className="w-4 h-4 text-[#1E9E5A] shrink-0"
              aria-hidden="true"
            />
            <span>Pusat Komando Terpadu</span>
          </div>
          <p className="text-sm font-bold text-[#F6F3EC] mt-1 truncate">
            {session.user.full_name || 'Administrator Utama'}
          </p>
          <p className="text-xs text-[#E4E9DA]/80 truncate">
            {session.user.agency || 'Dinas Pariwisata Provinsi Sumatera Barat'}
          </p>
          <p className="text-[11px] text-[#E4E9DA]/70 truncate mt-0.5">
            {session.user.email}
          </p>
        </div>

        <button
          type="button"
          onClick={onLogout}
          className="w-full min-h-[48px] px-4 py-2.5 rounded-pill bg-[#F26B4B] hover:bg-[#D95637] text-white font-bold text-sm flex items-center justify-center gap-2 transition shadow-sm"
        >
          <LogOut className="w-4 h-4" aria-hidden="true" />
          Keluar dari Pusat Komando
        </button>
      </div>
    </aside>
  );
};
