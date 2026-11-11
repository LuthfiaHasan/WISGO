// Export modul fitur Web Admin Rancak.in (FS-1)

export interface DisparAnalyticsSummary {
  totalVisitors: number;
  activeScansToday: number;
  umkmCirculationIdr: number;
  pungliReportsPending: number;
}

export interface SaberPungliTicket {
  id: string;
  destinationName: string;
  reporterName: string;
  photoEvidenceUrl: string;
  status: 'MASUK' | 'DIVERIFIKASI' | 'DITINDAKLANJUTI' | 'SELESAI';
  reportedAt: string;
}

export interface HotspotPinEditor {
  sceneId: string;
  pinType: 'NAVIGASI' | 'AUDIO_BUDAYA' | 'FASILITAS_RESMI' | 'MITRA_NAGARI';
  pitch: number;
  yaw: number;
  title: string;
}

