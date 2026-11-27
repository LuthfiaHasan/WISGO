import React from 'react';
import { Compass } from 'lucide-react';
import { Destination } from '../types/contract';
import { OpenTripsSubTab } from '../components/OpenTripsSubTab';

interface TripGoPageProps {
  destinations: Destination[];
  onShowToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  onTripsChanged?: () => void;
}

export const TripGoPage: React.FC<TripGoPageProps> = ({
  destinations,
  onShowToast,
  onTripsChanged,
}) => {
  return (
    <div className="space-y-6 pb-8">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <span className="inline-flex items-center gap-1.5 rounded-full bg-[#234B24]/10 px-3 py-1 text-[11px] font-semibold tracking-wide text-[#234B24]">
            <Compass className="h-3.5 w-3.5" />
            MODUL RESMI TRIP GO • SINKRON MOBILE
          </span>
          <h1 className="mt-2 font-display text-2xl font-bold tracking-tight text-[#1E241E] sm:text-3xl">
            Manajemen Trip Go & Escrow
          </h1>
          <p className="mt-1 text-sm text-[#5A655A]">
            Verifikasi pengajuan 5-langkah penyelenggara, kesiapan keberangkatan 3-tahap, e-Tiket Boarding Pass, dan Escrow terverifikasi.
          </p>
        </div>
      </div>

      <OpenTripsSubTab
        destinations={destinations}
        showToast={onShowToast}
        onTripsChanged={onTripsChanged}
      />
    </div>
  );
};
