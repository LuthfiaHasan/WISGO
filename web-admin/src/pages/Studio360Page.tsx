import React, { useEffect, useId, useMemo, useRef, useState } from 'react';
import {
  Camera,
  CheckCircle2,
  Compass,
  Crosshair,
  Edit3,
  ExternalLink,
  Layers,
  Map,
  Maximize2,
  Minimize2,
  Plus,
  RotateCcw,
  Save,
  Trash2,
  X,
  ZoomIn,
  ZoomOut,
} from 'lucide-react';
import {
  DenahPoint,
  DenahPointCategory,
  Destination,
  PanoramaScene,
  Partner,
} from '../types/contract';
import {
  deleteDestinationDenahPoint,
  deleteDestinationScene,
  saveDestinationDenahPoint,
  saveDestinationScene,
} from '../services/api';
import { DENAH_POINT_CATEGORIES, getDenahSvgPath } from '../data/mockDestinations';
import { ImageDropzone } from '../components/ImageDropzone';

interface Studio360PageProps {
  destinations: Destination[];
  partners?: Partner[];
  onUpdateDestinations: (updated: Destination[]) => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  initialDestId?: string;
  initialTab?: 'panorama' | 'denah';
  onNavigateToPartner?: (partnerId?: string) => void;
}

const FALLBACK_PANORAMA = '/assets/synced/panorama_sumbar_default.jpg';

const DENAH_META: Record<
  DenahPointCategory,
  { label: string; color: string; bg: string; border: string }
> = {
  PARKIR: {
    label: 'Area Parkir',
    color: '#1D4ED8',
    bg: '#EFF6FF',
    border: '#93C5FD',
  },
  UMKM: {
    label: 'Mitra UMKM',
    color: '#C2410C',
    bg: '#FFF7ED',
    border: '#FDBA74',
  },
  TOILET: {
    label: 'Toilet Umum',
    color: '#0F766E',
    bg: '#F0FDFA',
    border: '#99F6E4',
  },
  MUSHOLLA: {
    label: 'Musholla / Surau',
    color: '#166534',
    bg: '#F0FDF4',
    border: '#86EFAC',
  },
  LOKET: {
    label: 'Loket Resmi Perda',
    color: '#6D28D9',
    bg: '#F5F3FF',
    border: '#C4B5FD',
  },
};

export const Studio360Page: React.FC<Studio360PageProps> = ({
  destinations,
  partners = [],
  onUpdateDestinations,
  showToast,
  initialDestId,
  initialTab = 'panorama',
  onNavigateToPartner,
}) => {
  const destSelectId = useId();
  const [activeTab, setActiveTab] = useState<'panorama' | 'denah'>(initialTab);
  const [selectedDestId, setSelectedDestId] = useState<string>(
    initialDestId || destinations[0]?.id || 'dest-001'
  );

  useEffect(() => {
    if (initialDestId) setSelectedDestId(initialDestId);
  }, [initialDestId]);

  useEffect(() => {
    if (initialTab) setActiveTab(initialTab);
  }, [initialTab]);

  const selectedDestination = useMemo(
    () => destinations.find((d) => d.id === selectedDestId) || destinations[0],
    [destinations, selectedDestId]
  );

  const currentScenes: PanoramaScene[] = selectedDestination?.scenes_360 || [];
  const currentDenahPoints: DenahPoint[] = selectedDestination?.denah_points || [];

  const [selectedSceneId, setSelectedSceneId] = useState<string>(currentScenes[0]?.id || '');

  useEffect(() => {
    if (!currentScenes.some((s) => s.id === selectedSceneId)) {
      setSelectedSceneId(currentScenes[0]?.id || '');
    }
  }, [selectedDestId, currentScenes, selectedSceneId]);

  const activeScene =
    currentScenes.find((s) => s.id === selectedSceneId) || currentScenes[0];

  // ============================================================================
  // STATE TAB 1: PURE PANORAMA 360° VIEWER
  // ============================================================================
  const [cameraYaw, setCameraYaw] = useState<number>(activeScene?.initial_yaw || 0);
  const [cameraPitch, setCameraPitch] = useState<number>(activeScene?.initial_pitch || 0);
  const [zoomLevel, setZoomLevel] = useState<number>(1.0);
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);

  const canvasContainerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const isDraggingRef = useRef(false);
  const lastMousePosRef = useRef({ x: 0, y: 0 });

  // Scene CRUD Modal
  const [isSceneModalOpen, setIsSceneModalOpen] = useState(false);
  const [editingScene, setEditingScene] = useState<PanoramaScene | null>(null);
  const [sceneTitle, setSceneTitle] = useState('');
  const [sceneType, setSceneType] = useState<'aerial' | 'ground'>('aerial');
  const [sceneUrl, setSceneUrl] = useState('');
  const [scenePitch, setScenePitch] = useState(0);
  const [sceneYaw, setSceneYaw] = useState(0);

  useEffect(() => {
    if (activeScene) {
      setCameraYaw(activeScene.initial_yaw || 0);
      setCameraPitch(activeScene.initial_pitch || 0);
      setZoomLevel(1.0);
    }
  }, [activeScene?.id]);

  // Render Pure Panorama onto HTML5 Canvas (Zero Floating Pins)
  useEffect(() => {
    if (activeTab !== 'panorama') return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let cancelled = false;
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onerror = () => {
      if (!img.src.endsWith(FALLBACK_PANORAMA)) {
        img.src = FALLBACK_PANORAMA;
      }
    };
    img.src = activeScene?.panorama_url || FALLBACK_PANORAMA;

    const drawFrame = () => {
      if (cancelled) return;
      const width = canvas.width;
      const height = canvas.height;
      ctx.clearRect(0, 0, width, height);

      if (img.complete && img.naturalWidth > 0) {
        const fovX = 95 / Math.max(0.6, zoomLevel);
        const fovY = fovX * (height / width);
        const normYaw = ((cameraYaw % 360) + 360) % 360;
        const normPitch = Math.max(-65, Math.min(65, cameraPitch));

        const srcXDeg = normYaw - fovX / 2;
        const srcYDeg = Math.max(0, Math.min(180 - fovY, 90 - normPitch - fovY / 2));

        const srcX = (srcXDeg / 360) * img.naturalWidth;
        const srcY = (srcYDeg / 180) * img.naturalHeight;
        const srcW = (fovX / 360) * img.naturalWidth;
        const srcH = (fovY / 180) * img.naturalHeight;

        if (srcXDeg < 0) {
          const leftDeg = -srcXDeg;
          const leftW = (leftDeg / fovX) * width;
          const src1X = ((360 - leftDeg) / 360) * img.naturalWidth;
          const src1W = (leftDeg / 360) * img.naturalWidth;
          ctx.drawImage(img, src1X, srcY, src1W, srcH, 0, 0, leftW, height);

          const rightDeg = fovX - leftDeg;
          const rightW = width - leftW;
          const src2W = (rightDeg / 360) * img.naturalWidth;
          ctx.drawImage(img, 0, srcY, src2W, srcH, leftW, 0, rightW, height);
        } else if (srcXDeg + fovX > 360) {
          const rightSpan = 360 - srcXDeg;
          const w1 = (rightSpan / fovX) * width;
          const src1W = (rightSpan / 360) * img.naturalWidth;
          ctx.drawImage(img, srcX, srcY, src1W, srcH, 0, 0, w1, height);

          const wrapSpan = fovX - rightSpan;
          const w2 = width - w1;
          const src2W = (wrapSpan / 360) * img.naturalWidth;
          ctx.drawImage(img, 0, srcY, src2W, srcH, w1, 0, w2, height);
        } else {
          ctx.drawImage(img, srcX, srcY, srcW, srcH, 0, 0, width, height);
        }
      }
    };

    img.onload = drawFrame;
    drawFrame();
    return () => {
      cancelled = true;
    };
  }, [activeTab, activeScene?.panorama_url, cameraYaw, cameraPitch, zoomLevel]);

  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    isDraggingRef.current = true;
    lastMousePosRef.current = { x: e.clientX, y: e.clientY };
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDraggingRef.current) return;
    const dx = e.clientX - lastMousePosRef.current.x;
    const dy = e.clientY - lastMousePosRef.current.y;
    lastMousePosRef.current = { x: e.clientX, y: e.clientY };
    const sensitivity = 0.25 / zoomLevel;

    setCameraYaw((prev) => {
      const next = prev - dx * sensitivity;
      return ((((next + 180) % 360) + 360) % 360) - 180;
    });
    setCameraPitch((prev) => Math.max(-65, Math.min(65, prev + dy * sensitivity)));
  };

  const handleMouseUp = () => {
    isDraggingRef.current = false;
  };

  const handleSaveDefaultCamera = async () => {
    if (!selectedDestination || !activeScene) return;
    const updated = await saveDestinationScene(selectedDestination.id, {
      ...activeScene,
      initial_yaw: Math.round(cameraYaw),
      initial_pitch: Math.round(cameraPitch),
    });
    onUpdateDestinations(updated);
    showToast(
      `Sudut pandang default tersimpan: Yaw ${Math.round(cameraYaw)}°, Pitch ${Math.round(cameraPitch)}°.`,
      'success'
    );
  };

  const handleSaveSceneSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDestination) return;
    if (!sceneTitle.trim()) {
      showToast('Judul scene panorama wajib diisi.', 'warning');
      return;
    }

    const nextScene: PanoramaScene = {
      id: editingScene ? editingScene.id : `scn-${Date.now().toString(36)}`,
      destination_id: selectedDestination.id,
      title: sceneTitle.trim(),
      scene_type: sceneType,
      view_mode: 'photo_panorama',
      image_resolution: '4K Equirectangular Panorama',
      panorama_url: sceneUrl.trim() || FALLBACK_PANORAMA,
      upload_format: 'equirectangular',
      initial_pitch: Number(scenePitch),
      initial_yaw: Number(sceneYaw),
      is_default_scene: editingScene ? editingScene.is_default_scene : currentScenes.length === 0,
      created_at: editingScene?.created_at || new Date().toISOString(),
    };

    const updated = await saveDestinationScene(selectedDestination.id, nextScene);
    onUpdateDestinations(updated);
    setSelectedSceneId(nextScene.id);
    setIsSceneModalOpen(false);
    showToast(
      editingScene
        ? `Scene "${nextScene.title}" berhasil diperbarui.`
        : `Scene Pure Panorama 360° "${nextScene.title}" berhasil ditambahkan.`,
      'success'
    );
  };

  const handleDeleteScene = async (scene: PanoramaScene) => {
    if (!selectedDestination) return;
    if (!window.confirm(`Hapus scene panorama "${scene.title}"?`)) return;
    const updated = await deleteDestinationScene(selectedDestination.id, scene.id);
    onUpdateDestinations(updated);
    showToast(`Scene "${scene.title}" berhasil dihapus.`, 'info');
  };

  // ============================================================================
  // STATE TAB 2: EDITOR DENAH KAWASAN 2D (PARKIR, UMKM, TOILET, MUSHOLLA, LOKET)
  // ============================================================================
  const [denahFilter, setDenahFilter] = useState<'ALL' | DenahPointCategory>('ALL');
  const [selectedDenahPoint, setSelectedDenahPoint] = useState<DenahPoint | null>(null);
  const [isPlacingDenah, setIsPlacingDenah] = useState(false);

  const [isDenahModalOpen, setIsDenahModalOpen] = useState(false);
  const [editingDenah, setEditingDenah] = useState<DenahPoint | null>(null);
  const [denahCategory, setDenahCategory] = useState<DenahPointCategory>('UMKM');
  const [denahTitle, setDenahTitle] = useState('');
  const [denahDesc, setDenahDesc] = useState('');
  const [denahX, setDenahX] = useState(50);
  const [denahY, setDenahY] = useState(50);
  const [denahPartnerId, setDenahPartnerId] = useState('');

  const filteredDenahPoints = useMemo(
    () =>
      denahFilter === 'ALL'
        ? currentDenahPoints
        : currentDenahPoints.filter((p) => p.category === denahFilter),
    [currentDenahPoints, denahFilter]
  );

  const handleMapClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!isPlacingDenah) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const xPct = Math.round(((e.clientX - rect.left) / rect.width) * 100);
    const yPct = Math.round(((e.clientY - rect.top) / rect.height) * 100);
    setEditingDenah(null);
    setDenahCategory('UMKM');
    setDenahTitle('');
    setDenahDesc('');
    setDenahX(Math.max(4, Math.min(96, xPct)));
    setDenahY(Math.max(4, Math.min(96, yPct)));
    setDenahPartnerId('');
    setIsPlacingDenah(false);
    setIsDenahModalOpen(true);
    showToast(`Koordinat Denah 2D dipilih: X ${xPct}%, Y ${yPct}%.`, 'info');
  };

  const handleOpenEditDenah = (pt: DenahPoint) => {
    setEditingDenah(pt);
    setDenahCategory(pt.category);
    setDenahTitle(pt.title);
    setDenahDesc(pt.description);
    setDenahX(pt.x);
    setDenahY(pt.y);
    setDenahPartnerId(pt.partner_id || '');
    setIsDenahModalOpen(true);
  };

  const handleSaveDenahSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDestination || !denahTitle.trim()) {
      showToast('Nama titik fasilitas Denah 2D wajib diisi.', 'warning');
      return;
    }

    const nextPoint: DenahPoint = {
      id: editingDenah ? editingDenah.id : `dnh-${Date.now().toString(36)}`,
      destination_id: selectedDestination.id,
      category: denahCategory,
      title: denahTitle.trim(),
      description: denahDesc.trim() || `${DENAH_META[denahCategory].label} resmi kawasan.`,
      x: Number(denahX),
      y: Number(denahY),
      partner_id: denahCategory === 'UMKM' && denahPartnerId ? denahPartnerId : undefined,
    };

    const updated = await saveDestinationDenahPoint(selectedDestination.id, nextPoint);
    onUpdateDestinations(updated);
    setSelectedDenahPoint(nextPoint);
    setIsDenahModalOpen(false);
    showToast(
      editingDenah
        ? `Titik Denah 2D "${nextPoint.title}" diperbarui.`
        : `Titik Denah 2D "${nextPoint.title}" (${nextPoint.category}) ditambahkan.`,
      'success'
    );
  };

  const handleDeleteDenah = async (pt: DenahPoint) => {
    if (!window.confirm(`Hapus titik "${pt.title}" dari Denah Kawasan 2D?`)) return;
    const updated = await deleteDestinationDenahPoint(pt.id);
    onUpdateDestinations(updated);
    if (selectedDenahPoint?.id === pt.id) setSelectedDenahPoint(null);
    showToast(`Titik Denah 2D "${pt.title}" dihapus.`, 'info');
  };

  return (
    <div className="space-y-6">
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            Panorama 360° &amp; Editor Denah Kawasan 2D
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Tab 1: Pure Panorama 360° bersih (Aerial &amp; Ground) · Tab 2: Denah Fasilitas 2D (Parkir, UMKM, Toilet, Musholla, Loket).
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          <label htmlFor={destSelectId} className="text-xs font-bold text-[#1B1F1A] hidden sm:inline">
            Destinasi:
          </label>
          <select
            id={destSelectId}
            value={selectedDestId}
            onChange={(e) => {
              setSelectedDestId(e.target.value);
              setSelectedDenahPoint(null);
            }}
            className="h-10 px-3 py-1.5 rounded-xl bg-white border border-[#234B24]/15 text-xs font-bold text-[#1B1F1A] shadow-2xs"
          >
            {destinations.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name} ({d.scenes_360?.length || 0} Scene · {d.denah_points?.length || 0} Denah)
              </option>
            ))}
          </select>
        </div>
      </header>

      {/* 2-Tab Switcher */}
      <nav
        aria-label="Mode Studio Panorama & Denah"
        className="flex gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-2xs w-fit"
      >
        <button
          type="button"
          onClick={() => setActiveTab('panorama')}
          className={`h-9 px-4 rounded-lg text-xs font-bold flex items-center gap-2 transition ${
            activeTab === 'panorama'
              ? 'bg-[#234B24] text-white shadow-xs'
              : 'text-[#4A5248] hover:bg-[#234B24]/5'
          }`}
        >
          <Camera className="w-3.5 h-3.5" />
          <span>Panorama 360° (Pure View)</span>
          <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-white/20">
            {currentScenes.length}
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('denah')}
          className={`h-9 px-4 rounded-lg text-xs font-bold flex items-center gap-2 transition ${
            activeTab === 'denah'
              ? 'bg-[#234B24] text-white shadow-xs'
              : 'text-[#4A5248] hover:bg-[#234B24]/5'
          }`}
        >
          <Map className="w-3.5 h-3.5" />
          <span>Editor Denah Kawasan 2D</span>
          <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-white/20">
            {currentDenahPoints.length}
          </span>
        </button>
      </nav>

      {/* ==================================================================== */}
      {/* TAB 1: PURE PANORAMA 360°                                            */}
      {/* ==================================================================== */}
      {activeTab === 'panorama' && (
        <div className="space-y-5">
          {/* Scene Switcher Bar */}
          <div className="bg-white p-3.5 rounded-2xl border border-[#234B24]/10 flex flex-wrap items-center justify-between gap-3">
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-xs font-bold text-[#4A5248] flex items-center gap-1.5 mr-1">
                <Layers className="w-4 h-4 text-[#234B24]" /> Scene 360°:
              </span>
              {currentScenes.length === 0 ? (
                <span className="text-xs text-[#767676] italic">
                  Menggunakan panorama bawaan Sumbar (belum ada scene kustom)
                </span>
              ) : (
                currentScenes.map((scene) => {
                  const isActive = activeScene?.id === scene.id;
                  return (
                    <div key={scene.id} className="inline-flex items-center gap-1">
                      <button
                        type="button"
                        onClick={() => setSelectedSceneId(scene.id)}
                        className={`px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                          isActive
                            ? 'bg-[#234B24] text-white'
                            : 'bg-[#F6F3EC] text-[#1B1F1A] hover:bg-[#E4E9DA]'
                        }`}
                      >
                        <span className="px-1.5 py-0.5 rounded text-[9px] font-extrabold uppercase bg-black/15">
                          {scene.scene_type === 'aerial' ? 'Panorama Luas' : 'Sudut Dekat'}
                        </span>
                        <span>{scene.title}</span>
                      </button>
                      {isActive && (
                        <>
                          <button
                            type="button"
                            onClick={() => {
                              setEditingScene(scene);
                              setSceneTitle(scene.title);
                              setSceneType(scene.scene_type);
                              setSceneUrl(scene.panorama_url);
                              setScenePitch(scene.initial_pitch);
                              setSceneYaw(scene.initial_yaw);
                              setIsSceneModalOpen(true);
                            }}
                            title="Edit Scene"
                            className="p-1.5 rounded-lg bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24]"
                          >
                            <Edit3 className="w-3.5 h-3.5" />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleDeleteScene(scene)}
                            title="Hapus Scene"
                            className="p-1.5 rounded-lg bg-red-50 hover:bg-red-100 text-red-700"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </>
                      )}
                    </div>
                  );
                })
              )}
            </div>

            <button
              type="button"
              onClick={() => {
                setEditingScene(null);
                setSceneTitle('');
                setSceneType('aerial');
                setSceneUrl('');
                setScenePitch(0);
                setSceneYaw(0);
                setIsSceneModalOpen(true);
              }}
              className="h-9 px-3.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs inline-flex items-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Tambah Scene 360°</span>
            </button>
          </div>

          {/* Pure Panorama Canvas */}
          <div
            ref={canvasContainerRef}
            className={`relative bg-[#1B1F1A] rounded-3xl overflow-hidden border-2 border-[#234B24]/20 shadow-xl ${
              isFullscreen ? 'fixed inset-4 z-50' : 'h-[480px]'
            }`}
          >
            <canvas
              ref={canvasRef}
              width={1280}
              height={640}
              onMouseDown={handleMouseDown}
              onMouseMove={handleMouseMove}
              onMouseUp={handleMouseUp}
              onMouseLeave={handleMouseUp}
              className="w-full h-full object-cover cursor-grab active:cursor-grabbing select-none"
            />

            {/* Top HUD */}
            <div className="absolute top-4 left-4 right-4 flex flex-wrap items-center justify-between gap-2 pointer-events-none">
              <div className="bg-black/65 backdrop-blur-md text-white px-4 py-2 rounded-2xl border border-white/15 pointer-events-auto">
                <div className="text-[10px] font-bold uppercase tracking-wider text-[#A7F3D0]">
                  Pure Panorama 360° · {activeScene?.scene_type === 'ground' ? 'Sudut Dekat (Ground)' : 'Panorama Luas (Aerial)'}
                </div>
                <div className="text-sm font-extrabold">
                  {activeScene?.title || `${selectedDestination?.name} — Panorama Bawaan`}
                </div>
              </div>

              <div className="flex items-center gap-2 pointer-events-auto">
                <div className="bg-black/65 backdrop-blur-md text-white px-3 py-2 rounded-xl border border-white/15 text-[11px] font-mono">
                  Yaw: <strong>{Math.round(cameraYaw)}°</strong> · Pitch:{' '}
                  <strong>{Math.round(cameraPitch)}°</strong> · Zoom:{' '}
                  <strong>{zoomLevel.toFixed(1)}x</strong>
                </div>
                {activeScene && (
                  <button
                    type="button"
                    onClick={handleSaveDefaultCamera}
                    className="px-3.5 py-2 rounded-xl bg-[#1E9E5A] hover:bg-[#178248] text-white text-xs font-bold inline-flex items-center gap-1.5 shadow-md"
                  >
                    <Save className="w-3.5 h-3.5" />
                    <span>Simpan Sudut Pandang Default</span>
                  </button>
                )}
              </div>
            </div>

            {/* Bottom Controls */}
            <div className="absolute bottom-4 left-4 right-4 flex items-center justify-between pointer-events-none">
              <div className="bg-black/65 backdrop-blur-md text-white/90 px-3.5 py-2 rounded-xl text-[11px] font-medium pointer-events-auto flex items-center gap-2">
                <Compass className="w-4 h-4 text-[#A7F3D0]" />
                <span>Geser layar untuk melihat sekeliling 360° tanpa gangguan pin mengambang.</span>
              </div>

              <div className="flex items-center gap-1.5 bg-black/65 backdrop-blur-md p-1.5 rounded-2xl border border-white/15 pointer-events-auto">
                <button
                  type="button"
                  onClick={() => setZoomLevel((z) => Math.max(0.8, Number((z - 0.2).toFixed(1))))}
                  aria-label="Perkecil zoom"
                  className="p-2 rounded-xl text-white hover:bg-white/15"
                >
                  <ZoomOut className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setZoomLevel((z) => Math.min(2.2, Number((z + 0.2).toFixed(1))))}
                  aria-label="Perbesar zoom"
                  className="p-2 rounded-xl text-white hover:bg-white/15"
                >
                  <ZoomIn className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setCameraYaw(activeScene?.initial_yaw || 0);
                    setCameraPitch(activeScene?.initial_pitch || 0);
                    setZoomLevel(1.0);
                  }}
                  aria-label="Reset sudut pandang"
                  className="p-2 rounded-xl text-white hover:bg-white/15"
                >
                  <RotateCcw className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setIsFullscreen((f) => !f)}
                  aria-label="Layar penuh"
                  className="p-2 rounded-xl text-white hover:bg-white/15"
                >
                  {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* TAB 2: EDITOR DENAH KAWASAN 2D                                       */}
      {/* ==================================================================== */}
      {activeTab === 'denah' && (
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">
          {/* Interactive 2D Map Board */}
          <div className="xl:col-span-8 space-y-4">
            <div className="bg-white p-4 rounded-2xl border border-[#234B24]/10 flex flex-wrap items-center justify-between gap-3">
              <div className="flex flex-wrap items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => setDenahFilter('ALL')}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold border ${
                    denahFilter === 'ALL'
                      ? 'bg-[#234B24] text-white border-[#234B24]'
                      : 'bg-[#F6F3EC] text-[#4A5248] border-[#CFD8BE]'
                  }`}
                >
                  Semua ({currentDenahPoints.length})
                </button>
                {DENAH_POINT_CATEGORIES.map((cat) => (
                  <button
                    key={cat}
                    type="button"
                    onClick={() => setDenahFilter(cat)}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold border inline-flex items-center gap-1.5 ${
                      denahFilter === cat
                        ? 'bg-[#234B24] text-white border-[#234B24]'
                        : 'bg-[#F6F3EC] text-[#4A5248] border-[#CFD8BE]'
                    }`}
                  >
                    <img src={getDenahSvgPath(cat)} alt="" className="w-4 h-4" />
                    <span>{cat}</span>
                  </button>
                ))}
              </div>

              <button
                type="button"
                onClick={() => setIsPlacingDenah((v) => !v)}
                className={`min-h-[38px] px-4 py-1.5 rounded-xl text-xs font-bold inline-flex items-center gap-1.5 transition ${
                  isPlacingDenah
                    ? 'bg-[#F26B4B] text-white animate-pulse'
                    : 'bg-[#234B24] hover:bg-[#1B3B1C] text-white'
                }`}
              >
                <Crosshair className="w-3.5 h-3.5" />
                <span>
                  {isPlacingDenah
                    ? 'Klik Pada Denah Untuk Menaruh Titik...'
                    : 'Tambah Titik di Denah 2D'}
                </span>
              </button>
            </div>

            <div
              onClick={handleMapClick}
              className={`relative h-[460px] rounded-3xl overflow-hidden border-2 shadow-lg select-none ${
                isPlacingDenah
                  ? 'border-[#F26B4B] cursor-crosshair'
                  : 'border-[#234B24]/20'
              }`}
              style={{
                backgroundColor: '#E8EFE2',
                backgroundImage:
                  'linear-gradient(to right, rgba(35,75,36,0.08) 1px, transparent 1px), linear-gradient(to bottom, rgba(35,75,36,0.08) 1px, transparent 1px)',
                backgroundSize: '40px 40px',
              }}
            >
              {/* Soft destination visual backdrop */}
              {selectedDestination?.cover_image && (
                <img
                  src={selectedDestination.cover_image}
                  alt=""
                  className="absolute inset-0 w-full h-full object-cover opacity-20 pointer-events-none"
                />
              )}

              {/* Map Compass & Legend */}
              <div className="absolute top-4 left-4 bg-white/95 backdrop-blur-xs px-3.5 py-2 rounded-2xl border border-[#CFD8BE] shadow-xs pointer-events-none">
                <div className="text-[10px] font-extrabold uppercase tracking-wider text-[#234B24]">
                  Denah Kawasan 2D (Koordinat 0–100%)
                </div>
                <div className="text-xs font-extrabold text-[#1B1F1A]">
                  {selectedDestination?.name}
                </div>
              </div>

              {/* Placed Denah Markers */}
              {filteredDenahPoints.map((pt) => {
                const isSelected = selectedDenahPoint?.id === pt.id;
                const meta = DENAH_META[pt.category];
                return (
                  <button
                    key={pt.id}
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      setSelectedDenahPoint(pt);
                    }}
                    style={{ left: `${pt.x}%`, top: `${pt.y}%` }}
                    className={`absolute -translate-x-1/2 -translate-y-1/2 group flex flex-col items-center transition-transform ${
                      isSelected ? 'scale-110 z-20' : 'hover:scale-105 z-10'
                    }`}
                  >
                    <div
                      className={`w-10 h-10 rounded-full bg-white shadow-md flex items-center justify-center border-2 ${
                        isSelected ? 'ring-4 ring-[#F26B4B]/40' : ''
                      }`}
                      style={{ borderColor: meta.color }}
                    >
                      <img src={getDenahSvgPath(pt.category)} alt={pt.category} className="w-6 h-6" />
                    </div>
                    <span className="mt-1 px-2 py-0.5 rounded-lg bg-[#1B1F1A]/85 text-white text-[10px] font-bold whitespace-nowrap shadow-xs">
                      {pt.title.length > 22 ? `${pt.title.slice(0, 20)}..` : pt.title}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Right Panel: Selected Point & Full List */}
          <div className="xl:col-span-4 space-y-4">
            {selectedDenahPoint && (
              <div className="bg-white p-5 rounded-3xl border-2 border-[#234B24]/25 shadow-sm space-y-3">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-2.5">
                    <img
                      src={getDenahSvgPath(selectedDenahPoint.category)}
                      alt=""
                      className="w-9 h-9 shrink-0"
                    />
                    <div>
                      <span
                        className="px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase"
                        style={{
                          backgroundColor: DENAH_META[selectedDenahPoint.category].bg,
                          color: DENAH_META[selectedDenahPoint.category].color,
                        }}
                      >
                        {selectedDenahPoint.category}
                      </span>
                      <h3 className="text-sm font-extrabold text-[#1B1F1A] mt-0.5">
                        {selectedDenahPoint.title}
                      </h3>
                    </div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setSelectedDenahPoint(null)}
                    className="p-1 text-[#767676] hover:text-[#1B1F1A]"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>

                <p className="text-xs text-[#4A5248]">{selectedDenahPoint.description}</p>
                <div className="text-[11px] font-mono text-[#234B24] bg-[#F6F3EC] px-3 py-1.5 rounded-xl">
                  Posisi Denah: X = {selectedDenahPoint.x}% · Y = {selectedDenahPoint.y}%
                </div>

                {selectedDenahPoint.partner_id && onNavigateToPartner && (
                  <button
                    type="button"
                    onClick={() => onNavigateToPartner(selectedDenahPoint.partner_id)}
                    className="w-full py-2 px-3 rounded-xl bg-[#F26B4B]/15 text-[#D95637] hover:bg-[#F26B4B] hover:text-white text-xs font-bold inline-flex items-center justify-center gap-1.5 transition"
                  >
                    <ExternalLink className="w-3.5 h-3.5" />
                    <span>Buka Profil Mitra UMKM Terhubung</span>
                  </button>
                )}

                <div className="flex items-center gap-2 pt-2 border-t border-[#E4E9DA]">
                  <button
                    type="button"
                    onClick={() => handleOpenEditDenah(selectedDenahPoint)}
                    className="flex-1 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold inline-flex items-center justify-center gap-1"
                  >
                    <Edit3 className="w-3.5 h-3.5" /> Edit Titik
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDeleteDenah(selectedDenahPoint)}
                    className="py-2 px-3 rounded-xl bg-red-50 text-red-700 text-xs font-bold inline-flex items-center gap-1"
                  >
                    <Trash2 className="w-3.5 h-3.5" /> Hapus
                  </button>
                </div>
              </div>
            )}

            <div className="bg-white p-5 rounded-3xl border border-[#234B24]/10 shadow-sm space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="text-xs font-extrabold uppercase tracking-wider text-[#234B24]">
                  Daftar Titik Denah 2D ({filteredDenahPoints.length})
                </h3>
                <button
                  type="button"
                  onClick={() => {
                    setEditingDenah(null);
                    setDenahCategory('PARKIR');
                    setDenahTitle('');
                    setDenahDesc('');
                    setDenahX(50);
                    setDenahY(50);
                    setDenahPartnerId('');
                    setIsDenahModalOpen(true);
                  }}
                  className="text-xs font-bold text-[#234B24] hover:underline inline-flex items-center gap-1"
                >
                  <Plus className="w-3.5 h-3.5" /> Manual
                </button>
              </div>

              {filteredDenahPoints.length === 0 ? (
                <p className="text-xs text-[#767676] text-center py-6">
                  Belum ada titik fasilitas di denah kawasan ini.
                </p>
              ) : (
                <div className="space-y-2 max-h-[340px] overflow-y-auto pr-1">
                  {filteredDenahPoints.map((pt) => (
                    <div
                      key={pt.id}
                      onClick={() => setSelectedDenahPoint(pt)}
                      className={`p-3 rounded-2xl border cursor-pointer flex items-center justify-between gap-2 transition ${
                        selectedDenahPoint?.id === pt.id
                          ? 'bg-[#E4E9DA]/60 border-[#234B24]'
                          : 'bg-[#F6F3EC]/60 border-[#CFD8BE] hover:bg-[#F6F3EC]'
                      }`}
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        <img src={getDenahSvgPath(pt.category)} alt="" className="w-7 h-7 shrink-0" />
                        <div className="min-w-0">
                          <div className="text-xs font-extrabold text-[#1B1F1A] truncate">
                            {pt.title}
                          </div>
                          <div className="text-[10px] text-[#4A5248]">
                            {pt.category} · ({pt.x}%, {pt.y}%)
                          </div>
                        </div>
                      </div>
                      <CheckCircle2
                        className={`w-4 h-4 shrink-0 ${
                          selectedDenahPoint?.id === pt.id ? 'text-[#234B24]' : 'text-transparent'
                        }`}
                      />
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* MODAL TAMBAH/EDIT SCENE 360° */}
      {isSceneModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <form
            onSubmit={handleSaveSceneSubmit}
            className="bg-white rounded-[28px] w-full max-w-lg p-6 shadow-2xl border border-[#234B24]/15 space-y-4 max-h-[90vh] overflow-y-auto"
          >
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA]">
              <h3 className="text-base font-extrabold text-[#1B1F1A]">
                {editingScene ? 'Edit Scene Panorama 360°' : 'Tambah Scene Pure Panorama 360°'}
              </h3>
              <button
                type="button"
                onClick={() => setIsSceneModalOpen(false)}
                className="p-1.5 rounded-full hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div>
              <label className="block text-xs font-bold mb-1">Judul Scene Panorama *</label>
              <input
                type="text"
                required
                value={sceneTitle}
                onChange={(e) => setSceneTitle(e.target.value)}
                placeholder="Contoh: Panorama Luas Tebing Granit Harau"
                className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
              />
            </div>

            <div>
              <label className="block text-xs font-bold mb-1">Sudut Pengambilan</label>
              <select
                value={sceneType}
                onChange={(e) => setSceneType(e.target.value as 'aerial' | 'ground')}
                className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
              >
                <option value="aerial">Panorama Luas (Aerial / Drone)</option>
                <option value="ground">Sudut Dekat (Ground View)</option>
              </select>
            </div>

            <ImageDropzone
              label="Foto Panorama Equirectangular 360°"
              value={sceneUrl}
              onChange={setSceneUrl}
              onClear={() => setSceneUrl('')}
              helperText="Kosongkan untuk menggunakan panorama bawaan Sumbar."
            />

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold mb-1">Initial Yaw (°)</label>
                <input
                  type="number"
                  value={sceneYaw}
                  onChange={(e) => setSceneYaw(Number(e.target.value))}
                  className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                />
              </div>
              <div>
                <label className="block text-xs font-bold mb-1">Initial Pitch (°)</label>
                <input
                  type="number"
                  value={scenePitch}
                  onChange={(e) => setScenePitch(Number(e.target.value))}
                  className="w-full min-h-[40px] px-3 py-1.5 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                />
              </div>
            </div>

            <div className="pt-3 border-t border-[#E4E9DA] flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setIsSceneModalOpen(false)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan Scene 360°
              </button>
            </div>
          </form>
        </div>
      )}

      {/* MODAL TAMBAH/EDIT TITIK DENAH 2D */}
      {isDenahModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <form
            onSubmit={handleSaveDenahSubmit}
            className="bg-white rounded-[28px] w-full max-w-lg p-6 shadow-2xl border border-[#234B24]/15 space-y-4"
          >
            <div className="flex items-center justify-between pb-3 border-b border-[#E4E9DA]">
              <h3 className="text-base font-extrabold text-[#1B1F1A]">
                {editingDenah ? 'Edit Titik Denah 2D' : 'Tambah Titik Denah Kawasan 2D'}
              </h3>
              <button
                type="button"
                onClick={() => setIsDenahModalOpen(false)}
                className="p-1.5 rounded-full hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold mb-1">Kategori Denah *</label>
                <select
                  value={denahCategory}
                  onChange={(e) => setDenahCategory(e.target.value as DenahPointCategory)}
                  className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                >
                  {DENAH_POINT_CATEGORIES.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat} — {DENAH_META[cat].label}
                    </option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-xs font-bold mb-1">X (%)</label>
                  <input
                    type="number"
                    min={2}
                    max={98}
                    value={denahX}
                    onChange={(e) => setDenahX(Number(e.target.value))}
                    className="w-full min-h-[42px] px-2.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold mb-1">Y (%)</label>
                  <input
                    type="number"
                    min={2}
                    max={98}
                    value={denahY}
                    onChange={(e) => setDenahY(Number(e.target.value))}
                    className="w-full min-h-[42px] px-2.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono"
                  />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold mb-1">Nama Titik Fasilitas / UMKM *</label>
              <input
                type="text"
                required
                value={denahTitle}
                onChange={(e) => setDenahTitle(e.target.value)}
                placeholder="Contoh: Loket Retribusi Resmi / Kedai Kawa Mak Etek"
                className="w-full min-h-[42px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
              />
            </div>

            {denahCategory === 'UMKM' && partners.length > 0 && (
              <div>
                <label className="block text-xs font-bold mb-1">
                  Hubungkan ke Mitra UMKM Resmi (Opsional)
                </label>
                <select
                  value={denahPartnerId}
                  onChange={(e) => {
                    setDenahPartnerId(e.target.value);
                    const matched = partners.find((p) => p.id === e.target.value);
                    if (matched && !denahTitle) setDenahTitle(matched.name);
                  }}
                  className="w-full min-h-[42px] px-3 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold"
                >
                  <option value="">-- Tidak dihubungkan --</option>
                  {partners.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name} ({p.category})
                    </option>
                  ))}
                </select>
              </div>
            )}

            <div>
              <label className="block text-xs font-bold mb-1">Deskripsi Singkat</label>
              <textarea
                rows={2}
                value={denahDesc}
                onChange={(e) => setDenahDesc(e.target.value)}
                className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs"
              />
            </div>

            <div className="pt-3 border-t border-[#E4E9DA] flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setIsDenahModalOpen(false)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248]"
              >
                Batal
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-[#234B24] text-white text-xs font-bold"
              >
                Simpan Titik Denah 2D
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
