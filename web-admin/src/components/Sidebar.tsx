import React, { useState } from 'react';
import {
  Compass,
  QrCode,
  Camera,
  Radio,
  Store,
  BarChart3,
  LogOut,
  Trophy,
  Globe,
  PanelLeftClose,
  PanelLeftOpen,
  X,
  ExternalLink,
} from 'lucide-react';
import { AdminAuthResponse } from '../types/contract';

export type AdminMenuKey =
  | 'destinations'
  | 'tariffs_qr'
  | 'cms_360'
  | 'challenges'
  | 'command_center'
  | 'partners'
  | 'dispar_analytics';

interface SidebarProps {
  activeMenu: AdminMenuKey;
  onSelectMenu: (menu: AdminMenuKey) => void;
  session: AdminAuthResponse;
  backendOnline: boolean;
  totalDestinations: number;
  totalTariffs: number;
  totalPartnersAndTrips?: number;
  activeEmergencyCount?: number;
  onOpenLandingPage?: () => void;
  onOpenPublicQR?: () => void;
  onLogout: () => void;
  isMobileOpen?: boolean;
  onCloseMobile?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeMenu,
  onSelectMenu,
  session,
  backendOnline,
  totalDestinations,
  totalTariffs,
  totalPartnersAndTrips = 8,
  activeEmergencyCount = 0,
  onOpenLandingPage,
  onOpenPublicQR,
  onLogout,
  isMobileOpen = false,
  onCloseMobile,
}) => {
  const [isCollapsed, setIsCollapsed] = useState<boolean>(() => {
    try {
      return localStorage.getItem('wisgo_sidebar_collapsed') === 'true';
    } catch {
      return false;
    }
  });

  const toggleCollapse = () => {
    setIsCollapsed((prev) => {
      const next = !prev;
      try {
        localStorage.setItem('wisgo_sidebar_collapsed', String(next));
      } catch {
        // ignore
      }
      return next;
    });
  };

  const navItems: Array<{
    key: AdminMenuKey;
    label: string;
    badge?: string;
    badgeColor?: string;
    icon: React.ReactNode;
  }> = [
      {
        key: 'destinations',
        label: 'Destinasi',
        badge: `${totalDestinations}`,
        icon: <Compass className="w-4 h-4 shrink-0" aria-hidden="true" />,
      },
      {
        key: 'tariffs_qr',
        label: 'Tarif & QR',
        badge: `${totalTariffs}`,
        icon: <QrCode className="w-4 h-4 shrink-0" aria-hidden="true" />,
      },
      {
        key: 'cms_360',
        label: 'Panorama 360°',
        icon: <Camera className="w-4 h-4 shrink-0" aria-hidden="true" />,
      },
      {
        key: 'challenges',
        label: 'Challenge',
        icon: <Trophy className="w-4 h-4 shrink-0" aria-hidden="true" />,
      },
      {
        key: 'command_center',
        label: 'Komando SOS',
        badge: activeEmergencyCount > 0 ? `${activeEmergencyCount}` : undefined,
        badgeColor: 'bg-[#F26B4B] text-white',
        icon: <Radio className="w-4 h-4 shrink-0" aria-hidden="true" />,
      },
      {
        key: 'partners',
        label: 'UMKM & Trip Go',
        badge: `${totalPartnersAndTrips}`,
        icon: <Store className="w-4 h-4 shrink-0" aria-hidden="true" />,
      },
      {
        key: 'dispar_analytics',
        label: 'Analitik',
        icon: <BarChart3 className="w-4 h-4 shrink-0" aria-hidden="true" />,
      },
    ];

  const handleItemClick = (key: AdminMenuKey) => {
    onSelectMenu(key);
    onCloseMobile?.();
  };

  const renderNavList = (collapsed: boolean) => (
    <ul className="space-y-1">
      {navItems.map((item) => {
        const isActive = activeMenu === item.key;
        return (
          <li key={item.key} className="relative group">
            <button
              type="button"
              aria-current={isActive ? 'page' : undefined}
              onClick={() => handleItemClick(item.key)}
              className={`w-full text-left rounded-xl transition-all duration-150 flex items-center min-h-[40px] text-xs font-semibold ${collapsed
                  ? 'justify-center p-2.5'
                  : 'justify-between px-3 py-2.5 gap-2.5'
                } ${isActive
                  ? 'bg-[#F6F3EC] text-[#234B24] font-bold shadow-sm'
                  : 'text-white/80 hover:text-white hover:bg-white/8'
                }`}
            >
              <div
                className={`flex items-center min-w-0 ${collapsed ? 'justify-center' : 'gap-2.5 flex-1'
                  }`}
              >
                <span
                  className={`shrink-0 transition-colors ${isActive ? 'text-[#234B24]' : 'text-white/70'
                    }`}
                >
                  {item.icon}
                </span>
                {!collapsed && (
                  <span className="truncate whitespace-nowrap">{item.label}</span>
                )}
              </div>

              {!collapsed && item.badge && (
                <span
                  className={`text-[10.5px] font-extrabold px-1.5 py-0.5 rounded-md shrink-0 whitespace-nowrap leading-none ${item.badgeColor
                      ? item.badgeColor
                      : isActive
                        ? 'bg-[#234B24]/10 text-[#234B24]'
                        : 'bg-white/10 text-white/90'
                    }`}
                >
                  {item.badge}
                </span>
              )}

              {collapsed && item.badge && (
                <span
                  className={`absolute top-2 right-2 w-2 h-2 rounded-full ${item.badgeColor ? 'bg-[#F26B4B]' : 'bg-[#A7F3D0]'
                    }`}
                />
              )}
            </button>

            {collapsed && (
              <div
                role="tooltip"
                className="opacity-0 group-hover:opacity-100 pointer-events-none fixed ml-14 left-0 z-50 px-2.5 py-1 rounded-md bg-[#1B1F1A] text-white text-[11px] font-bold whitespace-nowrap shadow-lg transition-opacity duration-150"
              >
                {item.label}
                {item.badge ? ` (${item.badge})` : ''}
              </div>
            )}
          </li>
        );
      })}
    </ul>
  );

  return (
    <>
      <aside
        aria-label="Navigasi Utama WISGO Admin"
        className={`hidden lg:flex flex-col justify-between shrink-0 h-screen sticky top-0 z-30 bg-[#234B24] text-[#F6F3EC] border-r border-black/10 no-print transition-all duration-200 select-none ${isCollapsed ? 'w-[72px]' : 'w-60'
          }`}
      >
        <div className="flex flex-col min-h-0 flex-1">
          <div
            className={`border-b border-white/8 shrink-0 flex items-center justify-between transition-all duration-200 ${isCollapsed ? 'p-3 flex-col gap-2' : 'p-4'
              }`}
          >
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-xl bg-[#F6F3EC] p-1.5 flex items-center justify-center shrink-0 shadow-sm">
                <img
                  src="/assets/synced/logo_icon.png"
                  alt="WISGO"
                  onError={(e) => {
                    (e.target as HTMLImageElement).src = '/logo_icon.png';
                  }}
                  className="w-full h-full object-contain"
                />
              </div>
              {!isCollapsed && (
                <div className="min-w-0 flex-1">
                  <span className="font-extrabold text-sm tracking-tight text-white block truncate leading-none">
                    WISGO
                  </span>
                  <span className="text-[10px] text-white/60 font-semibold tracking-wider uppercase block mt-0.5">
                    Admin Portal
                  </span>
                </div>
              )}
            </div>

            <button
              type="button"
              onClick={toggleCollapse}
              title={isCollapsed ? 'Buka Sidebar' : 'Lipat Sidebar'}
              className="p-1.5 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition-colors shrink-0"
              aria-label={isCollapsed ? 'Buka navigasi sidebar' : 'Lipat navigasi sidebar'}
            >
              {isCollapsed ? (
                <PanelLeftOpen className="w-4 h-4" />
              ) : (
                <PanelLeftClose className="w-4 h-4" />
              )}
            </button>
          </div>

          <nav
            aria-label="Menu Utama"
            className="flex-1 overflow-y-auto sidebar-scroll p-3 space-y-3"
          >
            {renderNavList(isCollapsed)}

            <div className="pt-3 border-t border-white/8 space-y-1">
              {onOpenLandingPage && (
                <button
                  type="button"
                  onClick={onOpenLandingPage}
                  title="Buka Beranda Publik"
                  className={`w-full text-left rounded-xl text-white/70 hover:text-white hover:bg-white/8 transition-all flex items-center min-h-[36px] text-xs font-semibold ${isCollapsed ? 'justify-center p-2' : 'px-3 py-2 gap-2.5'
                    }`}
                >
                  <Globe className="w-4 h-4 shrink-0 text-[#A7F3D0]" />
                  {!isCollapsed && <span className="truncate">Beranda Publik</span>}
                </button>
              )}
              {onOpenPublicQR && (
                <button
                  type="button"
                  onClick={onOpenPublicQR}
                  title="Lihat Plang Smart QR"
                  className={`w-full text-left rounded-xl text-white/70 hover:text-white hover:bg-white/8 transition-all flex items-center min-h-[36px] text-xs font-semibold ${isCollapsed ? 'justify-center p-2' : 'px-3 py-2 gap-2.5'
                    }`}
                >
                  <QrCode className="w-4 h-4 shrink-0 text-[#F26B4B]" />
                  {!isCollapsed && <span className="truncate">Smart QR (/qr)</span>}
                </button>
              )}
            </div>
          </nav>
        </div>

        <div className="p-3 border-t border-white/8 bg-black/10 shrink-0">
          {!isCollapsed ? (
            <div className="flex items-center justify-between gap-2">
              <div className="min-w-0 flex-1">
                <span className="text-xs font-bold text-white block truncate leading-none">
                  {session.user.full_name || 'Admin Otoritas'}
                </span>
                <span className="text-[10px] text-white/50 block truncate mt-1">
                  {backendOnline ? 'Online' : 'Sinkron Lokal V3'}
                </span>
              </div>
              <button
                type="button"
                onClick={onLogout}
                title="Keluar"
                className="p-2 rounded-lg text-white/70 hover:text-white hover:bg-[#F26B4B] transition-colors shrink-0"
                aria-label="Keluar dari akun admin"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <div className="flex justify-center">
              <button
                type="button"
                onClick={onLogout}
                title="Keluar"
                className="p-2 rounded-lg text-white/70 hover:text-white hover:bg-[#F26B4B] transition-colors"
                aria-label="Keluar dari akun admin"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          )}
        </div>
      </aside>

      {isMobileOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Menu Navigasi Mobile"
          className="fixed inset-0 z-50 lg:hidden"
        >
          <div
            className="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
            onClick={onCloseMobile}
            aria-hidden="true"
          />

          <aside className="fixed inset-y-0 left-0 w-72 max-w-[85vw] bg-[#234B24] text-[#F6F3EC] shadow-2xl flex flex-col justify-between z-10">
            <div className="flex flex-col min-h-0 flex-1">
              <div className="p-4 border-b border-white/8 flex items-center justify-between shrink-0">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-xl bg-[#F6F3EC] p-1.5 flex items-center justify-center shrink-0 shadow-sm">
                    <img
                      src="/assets/synced/logo_icon.png"
                      alt="WISGO"
                      onError={(e) => {
                        (e.target as HTMLImageElement).src = '/logo_icon.png';
                      }}
                      className="w-full h-full object-contain"
                    />
                  </div>
                  <div>
                    <span className="font-extrabold text-sm tracking-tight text-white block leading-none">
                      WISGO Sumbar
                    </span>
                    <span className="text-[10px] text-white/60 font-semibold tracking-wider uppercase block mt-0.5">
                      Pusat Komando
                    </span>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={onCloseMobile}
                  className="p-1.5 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition-colors"
                  aria-label="Tutup menu navigasi"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <nav className="flex-1 overflow-y-auto p-3 space-y-3">
                {renderNavList(false)}

                <div className="pt-3 border-t border-white/8 space-y-1">
                  {onOpenLandingPage && (
                    <button
                      type="button"
                      onClick={() => {
                        onOpenLandingPage();
                        onCloseMobile?.();
                      }}
                      className="w-full text-left px-3 py-2.5 rounded-xl text-white/80 hover:text-white hover:bg-white/8 text-xs font-semibold flex items-center justify-between"
                    >
                      <span className="flex items-center gap-2.5">
                        <Globe className="w-4 h-4 text-[#A7F3D0]" />
                        <span>Beranda Publik</span>
                      </span>
                      <ExternalLink className="w-3.5 h-3.5 text-white/50" />
                    </button>
                  )}
                  {onOpenPublicQR && (
                    <button
                      type="button"
                      onClick={() => {
                        onOpenPublicQR();
                        onCloseMobile?.();
                      }}
                      className="w-full text-left px-3 py-2.5 rounded-xl text-white/80 hover:text-white hover:bg-white/8 text-xs font-semibold flex items-center justify-between"
                    >
                      <span className="flex items-center gap-2.5">
                        <QrCode className="w-4 h-4 text-[#F26B4B]" />
                        <span>Smart QR (/qr)</span>
                      </span>
                      <ExternalLink className="w-3.5 h-3.5 text-white/50" />
                    </button>
                  )}
                </div>
              </nav>
            </div>

            <div className="p-4 border-t border-white/8 bg-black/10 shrink-0 flex items-center justify-between gap-3">
              <div className="min-w-0 flex-1">
                <span className="text-xs font-bold text-white block truncate leading-none">
                  {session.user.full_name || 'Admin Otoritas'}
                </span>
                <span className="text-[10px] text-white/60 block truncate mt-1">
                  {session.user.email}
                </span>
              </div>
              <button
                type="button"
                onClick={() => {
                  onLogout();
                  onCloseMobile?.();
                }}
                className="p-2 rounded-lg bg-[#F26B4B] hover:bg-[#D95637] text-white text-xs font-bold flex items-center gap-1.5 transition-colors"
                title="Keluar"
              >
                <LogOut className="w-4 h-4" />
                <span>Keluar</span>
              </button>
            </div>
          </aside>
        </div>
      )}
    </>
  );
};
