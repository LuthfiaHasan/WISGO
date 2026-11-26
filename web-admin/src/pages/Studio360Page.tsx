import React, { useEffect, useId, useMemo, useRef, useState } from 'react';
import {
  Camera,
  Compass,
  Edit3,
  Layers,
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
import { Destination, PanoramaScene, Partner } from '../types/contract';
import { deleteDestinationScene, saveDestinationScene } from '../services/api';
import { ImageDropzone } from '../components/ImageDropzone';

interface Studio360PageProps {
  destinations: Destination[];
  partners?: Partner[];
  onUpdateDestinations: (updated: Destination[]) => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  initialDestId?: string;
  initialTab?: 'panorama';
  onNavigateToPartner?: (partnerId?: string) => void;
}

const FALLBACK_PANORAMA = '/assets/synced/panorama_sumbar_default.jpg';

export const Studio360Page: React.FC<Studio360PageProps> = ({
  destinations,
  onUpdateDestinations,
  showToast,
  initialDestId,
}) => {
  const destSelectId = useId();
  const activeTab = 'panorama' as const;
  const [selectedDestId, setSelectedDestId] = useState<string>(
    initialDestId || destinations[0]?.id || 'dest-001'
  );

  useEffect(() => {
    if (initialDestId) setSelectedDestId(initialDestId);
  }, [initialDestId]);

  const selectedDestination = useMemo(
    () => destinations.find((d) => d.id === selectedDestId) || destinations[0],
    [destinations, selectedDestId]
  );

  const currentScenes: PanoramaScene[] = selectedDestination?.scenes_360 || [];

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

  return (
    <div className="space-y-6">
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            Studio Panorama 360° (Bersih Tanpa Pin)
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Kelola foto panorama equirectangular 360° (Aerial &amp; Ground) untuk seluruh destinasi wisata Sumatera Barat.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          <label htmlFor={destSelectId} className="text-xs font-bold text-[#1B1F1A] hidden sm:inline">
            Destinasi:
          </label>
          <select
            id={destSelectId}
            value={selectedDestId}
            onChange={(e) => setSelectedDestId(e.target.value)}
            className="h-10 px-3 py-1.5 rounded-xl bg-white border border-[#234B24]/15 text-xs font-bold text-[#1B1F1A] shadow-sm"
          >
            {destinations.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name} ({d.scenes_360?.length || 0} Scene 360°)
              </option>
            ))}
          </select>
        </div>
      </header>

      {/* ==================================================================== */}
      {/* PURE PANORAMA 360° (BERSIH TANPA PIN)                                */}
      {/* ==================================================================== */}
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
                  {activeScene?.title || `${selectedDestination?.name} � Panorama Bawaan`}
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

      {/* MODAL TAMBAH/EDIT SCENE 360° */}
      {isSceneModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
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

    </div>
  );
};
