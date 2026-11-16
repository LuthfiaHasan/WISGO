import React, { useEffect, useRef, useState, useId } from 'react';
import {
  Camera,
  Layers,
  Plus,
  Trash2,
  Edit3,
  Compass,
  BookOpen,
  Volume2,
  ShoppingBag,
  ExternalLink,
  Info,
  CheckCircle2,
  Eye,
  Crosshair,
  Sparkles,
  ArrowRight,
  Music,
  MapPin,
  X,
  Save,
  ZoomIn,
  ZoomOut,
  Maximize2,
  Minimize2,
  RotateCcw,
  Navigation,
  Store,
  VolumeX,
} from 'lucide-react';
import {
  Destination,
  HotspotPin,
  HotspotPinCategory,
  PanoramaScene,
} from '../types/contract';
import {
  deleteDestinationScene,
  deleteSceneHotspot,
  saveDestinationScene,
  saveSceneHotspot,
} from '../services/api';
import { ImageDropzone } from '../components/ImageDropzone';
import { AudioDropzone } from '../components/AudioDropzone';

interface Studio360PageProps {
  destinations: Destination[];
  onUpdateDestinations: (updated: Destination[]) => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
  initialDestId?: string;
  initialSceneId?: string;
  initialHighlightPinId?: string;
  onNavigateToPartner?: (partnerId?: string) => void;
}

export const Studio360Page: React.FC<Studio360PageProps> = ({
  destinations,
  onUpdateDestinations,
  showToast,
  initialDestId,
  initialSceneId,
  initialHighlightPinId,
  onNavigateToPartner,
}) => {
  const destSelectId = useId();
  const sceneTitleId = useId();
  const sceneTypeId = useId();
  const sceneInitPitchId = useId();
  const sceneInitYawId = useId();

  const pinCatId = useId();
  const pinTitleId = useId();
  const pinDescId = useId();
  const pinPitchId = useId();
  const pinYawId = useId();
  const pinTargetSceneId = useId();
  const pinAudioUrlId = useId();
  const pinPartnerNameId = useId();
  const pinPartnerFeeId = useId();

  // Selected Destination
  const [selectedDestId, setSelectedDestId] = useState<string>(
    initialDestId || destinations[0]?.id || 'dest-001'
  );

  const selectedDestination =
    destinations.find((d) => d.id === selectedDestId) || destinations[0];

  const currentScenes: PanoramaScene[] =
    selectedDestination?.scenes_360 || [];

  // Selected Scene
  const [selectedSceneId, setSelectedSceneId] = useState<string>(
    initialSceneId || currentScenes[0]?.id || ''
  );

  const activeScene =
    currentScenes.find((s) => s.id === selectedSceneId) || currentScenes[0];

  // Viewer Camera State
  const [cameraYaw, setCameraYaw] = useState<number>(
    activeScene?.initial_yaw || 0
  );
  const [cameraPitch, setCameraPitch] = useState<number>(
    activeScene?.initial_pitch || 0
  );
  const [zoomLevel, setZoomLevel] = useState<number>(1.0); // 0.8x s.d 2.2x
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const [interactionMode, setInteractionMode] = useState<'explore' | 'pin_picker'>(
    'explore'
  );
  const [isSceneTransitioning, setIsSceneTransitioning] = useState<boolean>(false);
  const [isAudioMuted, setIsAudioMuted] = useState<boolean>(false);

  // Selected Pin for detailed popup/preview
  const [selectedPin, setSelectedPin] = useState<HotspotPin | null>(null);
  const [highlightPinId, setHighlightPinId] = useState<string | null>(
    initialHighlightPinId || null
  );

  // Canvas Ref & Dragging state
  const canvasContainerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const isDraggingRef = useRef(false);
  const lastMousePosRef = useRef({ x: 0, y: 0 });
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Modals
  const [isSceneModalOpen, setIsSceneModalOpen] = useState(false);
  const [editingScene, setEditingScene] = useState<PanoramaScene | null>(null);

  const [isPinModalOpen, setIsPinModalOpen] = useState(false);
  const [editingPin, setEditingPin] = useState<HotspotPin | null>(null);

  // Form states for Scene Modal (Upload dari Device)
  const [sceneFormTitle, setSceneFormTitle] = useState('');
  const [sceneFormType, setSceneFormType] = useState<'aerial' | 'ground'>('aerial');
  const [sceneFormPanoUrl, setSceneFormPanoUrl] = useState('');
  const [sceneFormAudioUrl, setSceneFormAudioUrl] = useState('');
  const [sceneFormPitch, setSceneFormPitch] = useState(0);
  const [sceneFormYaw, setSceneFormYaw] = useState(0);

  // Form states for Pin Modal
  const [pinFormCategory, setPinFormCategory] =
    useState<HotspotPinCategory>('info_adat');
  const [pinFormTitle, setPinFormTitle] = useState('');
  const [pinFormDesc, setPinFormDesc] = useState('');
  const [pinFormPitch, setPinFormPitch] = useState(0);
  const [pinFormYaw, setPinFormYaw] = useState(0);
  const [pinFormTargetScene, setPinFormTargetScene] = useState('');
  const [pinFormAudioUrl, setPinFormAudioUrl] = useState('');
  const [pinFormPartnerName, setPinFormPartnerName] = useState('');
  const [pinFormPartnerFee, setPinFormPartnerFee] = useState<number>(0);

  // Filter Pin List
  const [pinCategoryFilter, setPinCategoryFilter] = useState<string>('all');

  // Sync initial props if changed
  useEffect(() => {
    if (initialDestId && initialDestId !== selectedDestId) {
      setSelectedDestId(initialDestId);
    }
    if (initialSceneId && initialSceneId !== selectedSceneId) {
      setSelectedSceneId(initialSceneId);
    }
    if (initialHighlightPinId) {
      setHighlightPinId(initialHighlightPinId);
      const dest = destinations.find((d) => d.id === (initialDestId || selectedDestId));
      const targetPin = dest?.scenes_360
        ?.flatMap((s) => s.hotspots || [])
        .find((h) => h.id === initialHighlightPinId);
      if (targetPin) {
        setSelectedPin(targetPin);
        setCameraYaw(targetPin.yaw);
        setCameraPitch(targetPin.pitch);
      }
    }
  }, [initialDestId, initialSceneId, initialHighlightPinId]);

  // Update camera on active scene switch
  useEffect(() => {
    if (activeScene) {
      setCameraYaw(activeScene.initial_yaw || 0);
      setCameraPitch(activeScene.initial_pitch || 0);
      setZoomLevel(1.0);
    }
  }, [selectedSceneId]);

  // Ambient audio control
  useEffect(() => {
    if (audioRef.current) {
      if (activeScene?.ambient_audio_url && !isAudioMuted) {
        audioRef.current.play().catch(() => {
          // Autoplay policy fallback
        });
      } else {
        audioRef.current.pause();
      }
    }
  }, [activeScene?.ambient_audio_url, isAudioMuted]);

  // Render Panorama & Pins onto HTML5 Canvas
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !activeScene?.panorama_url) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.src = activeScene.panorama_url;

    let animId: number;

    const render = () => {
      const width = canvas.width;
      const height = canvas.height;

      ctx.clearRect(0, 0, width, height);

      if (img.complete && img.naturalWidth > 0) {
        // FOV calculations based on zoom
        const fovX = 90 / Math.max(0.5, zoomLevel);
        const fovY = fovX * (height / width);

        // Normalize cameraYaw into [0, 360)
        const normYaw = ((cameraYaw % 360) + 360) % 360;
        const normPitch = Math.max(-80, Math.min(80, cameraPitch));

        // Source slice in equirectangular image (0 to 360 deg = 0 to img.width)
        const srcXDeg = normYaw - fovX / 2;
        const srcYDeg = 90 - normPitch - fovY / 2;

        const srcX = (srcXDeg / 360) * img.naturalWidth;
        const srcY = (srcYDeg / 180) * img.naturalHeight;
        const srcW = (fovX / 360) * img.naturalWidth;
        const srcH = (fovY / 180) * img.naturalHeight;

        // Handle wrap-around horizontally
        if (srcXDeg < 0) {
          // Part 1: right end of image
          const leftDeg = -srcXDeg;
          const leftW = (leftDeg / fovX) * width;
          const src1X = ((360 - leftDeg) / 360) * img.naturalWidth;
          const src1W = (leftDeg / 360) * img.naturalWidth;

          ctx.drawImage(img, src1X, srcY, src1W, srcH, 0, 0, leftW, height);

          // Part 2: start from 0
          const rightDeg = fovX - leftDeg;
          const rightW = width - leftW;
          const src2W = (rightDeg / 360) * img.naturalWidth;

          ctx.drawImage(img, 0, srcY, src2W, srcH, leftW, 0, rightW, height);
        } else if (srcXDeg + fovX > 360) {
          // Part 1: up to 360
          const rightSpan = 360 - srcXDeg;
          const w1 = (rightSpan / fovX) * width;
          const src1W = (rightSpan / 360) * img.naturalWidth;

          ctx.drawImage(img, srcX, srcY, src1W, srcH, 0, 0, w1, height);

          // Part 2: wrap from left
          const wrapSpan = fovX - rightSpan;
          const w2 = width - w1;
          const src2W = (wrapSpan / 360) * img.naturalWidth;

          ctx.drawImage(img, 0, srcY, src2W, srcH, w1, 0, w2, height);
        } else {
          ctx.drawImage(img, srcX, srcY, srcW, srcH, 0, 0, width, height);
        }

        // Render Hotspot Pins inside the active FOV
        const hotspots = activeScene.hotspots || [];
        for (const pin of hotspots) {
          // Delta angle from cameraYaw
          let deltaYaw = pin.yaw - cameraYaw;
          deltaYaw = ((((deltaYaw + 180) % 360) + 360) % 360) - 180;

          const deltaPitch = pin.pitch - cameraPitch;

          // Check if within visible FOV
          if (Math.abs(deltaYaw) <= fovX / 2 && Math.abs(deltaPitch) <= fovY / 2) {
            const screenX = (deltaYaw / (fovX / 2)) * (width / 2) + width / 2;
            const screenY = (-deltaPitch / (fovY / 2)) * (height / 2) + height / 2;

            const isSelected = selectedPin?.id === pin.id;
            const isHighlighted = highlightPinId === pin.id;

            // Draw pin marker on canvas
            ctx.save();
            ctx.translate(screenX, screenY);

            // Pulsating glow ring
            const pulse = Math.sin(Date.now() / 250) * 4;
            ctx.beginPath();
            ctx.arc(0, 0, 16 + (isHighlighted ? pulse + 4 : 0), 0, Math.PI * 2);
            ctx.fillStyle =
              pin.category === 'info_adat'
                ? 'rgba(234, 179, 8, 0.4)'
                : pin.category === 'navigasi'
                ? 'rgba(59, 130, 246, 0.4)'
                : pin.category === 'audio_budaya'
                ? 'rgba(99, 102, 241, 0.4)'
                : 'rgba(242, 107, 75, 0.45)';
            ctx.fill();

            // Pin base circle
            ctx.beginPath();
            ctx.arc(0, 0, 14, 0, Math.PI * 2);
            ctx.fillStyle =
              pin.category === 'info_adat'
                ? '#CA8A04'
                : pin.category === 'navigasi'
                ? '#1D4ED8'
                : pin.category === 'audio_budaya'
                ? '#4F46E5'
                : '#F26B4B';
            ctx.fill();
            ctx.lineWidth = isSelected || isHighlighted ? 3 : 2;
            ctx.strokeStyle = '#FFFFFF';
            ctx.stroke();

            // Label text banner below pin
            ctx.fillStyle = 'rgba(0, 0, 0, 0.75)';
            ctx.roundRect(-50, 18, 100, 20, 6);
            ctx.fill();
            ctx.fillStyle = '#FFFFFF';
            ctx.font = 'bold 9px sans-serif';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            const shortTitle =
              pin.title.length > 14 ? pin.title.slice(0, 12) + '..' : pin.title;
            ctx.fillText(shortTitle, 0, 28);

            ctx.restore();
          }
        }
      }

      animId = requestAnimationFrame(render);
    };

    img.onload = () => {
      render();
    };

    return () => {
      cancelAnimationFrame(animId);
    };
  }, [
    activeScene?.panorama_url,
    activeScene?.hotspots,
    cameraYaw,
    cameraPitch,
    zoomLevel,
    selectedPin,
    highlightPinId,
  ]);

  // Handle Dragging / Panning on Canvas
  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (interactionMode === 'pin_picker') {
      // In pin picker mode, click determines coordinates
      handleCanvasClickToPlacePin(e);
      return;
    }

    isDraggingRef.current = true;
    lastMousePosRef.current = { x: e.clientX, y: e.clientY };
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDraggingRef.current || interactionMode !== 'explore') return;

    const deltaX = e.clientX - lastMousePosRef.current.x;
    const deltaY = e.clientY - lastMousePosRef.current.y;
    lastMousePosRef.current = { x: e.clientX, y: e.clientY };

    const sensitivity = 0.25 / zoomLevel;

    setCameraYaw((prev) => {
      const next = prev - deltaX * sensitivity;
      return ((((next + 180) % 360) + 360) % 360) - 180;
    });

    setCameraPitch((prev) => {
      const next = prev + deltaY * sensitivity;
      return Math.max(-80, Math.min(80, next));
    });
  };

  const handleMouseUp = () => {
    isDraggingRef.current = false;
  };

  // Convert click in pin_picker mode to Spherical Yaw & Pitch
  const handleCanvasClickToPlacePin = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const rect = canvas.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const clickY = e.clientY - rect.top;

    const width = canvas.width;
    const height = canvas.height;

    const fovX = 90 / Math.max(0.5, zoomLevel);
    const fovY = fovX * (height / width);

    // Calculate delta from center
    const xRatio = (clickX - width / 2) / (width / 2); // -1 to 1
    const yRatio = (clickY - height / 2) / (height / 2); // -1 to 1

    const clickYawDelta = xRatio * (fovX / 2);
    const clickPitchDelta = -yRatio * (fovY / 2);

    let pickedYaw = Math.round(cameraYaw + clickYawDelta);
    pickedYaw = ((((pickedYaw + 180) % 360) + 360) % 360) - 180;

    const pickedPitch = Math.round(
      Math.max(-80, Math.min(80, cameraPitch + clickPitchDelta))
    );

    setPinFormPitch(pickedPitch);
    setPinFormYaw(pickedYaw);
    setPinFormCategory('info_adat');
    setPinFormTitle('');
    setPinFormDesc('');
    setPinFormTargetScene('');
    setPinFormAudioUrl('');
    setPinFormPartnerName('');
    setPinFormPartnerFee(0);
    setEditingPin(null);
    setIsPinModalOpen(true);
    setInteractionMode('explore'); // switch back to explore
    showToast(
      `Titik koordinat dipilih: Yaw ${pickedYaw}°, Pitch ${pickedPitch}°.`,
      'info'
    );
  };

  // Handle Canvas Click to Select Existing Pin in Explore Mode
  const handleCanvasClickInExplore = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (interactionMode !== 'explore') return;

    const canvas = canvasRef.current;
    if (!canvas || !activeScene?.hotspots) return;

    const rect = canvas.getBoundingClientRect();
    const clickX = (e.clientX - rect.left) * (canvas.width / rect.width);
    const clickY = (e.clientY - rect.top) * (canvas.height / rect.height);

    const fovX = 90 / Math.max(0.5, zoomLevel);
    const fovY = fovX * (canvas.height / canvas.width);

    for (const pin of activeScene.hotspots) {
      let deltaYaw = pin.yaw - cameraYaw;
      deltaYaw = ((((deltaYaw + 180) % 360) + 360) % 360) - 180;
      const deltaPitch = pin.pitch - cameraPitch;

      if (Math.abs(deltaYaw) <= fovX / 2 && Math.abs(deltaPitch) <= fovY / 2) {
        const screenX = (deltaYaw / (fovX / 2)) * (canvas.width / 2) + canvas.width / 2;
        const screenY = (-deltaPitch / (fovY / 2)) * (canvas.height / 2) + canvas.height / 2;

        const dist = Math.hypot(clickX - screenX, clickY - screenY);
        if (dist <= 24) {
          setSelectedPin(pin);
          // If navigation pin, ask or allow leap
          return;
        }
      }
    }
  };

  // Handle Leap to target scene
  const handleTransitionToScene = (targetSceneId: string) => {
    setIsSceneTransitioning(true);
    showToast('Melompat ke scene panorama tujuan...', 'info');

    setTimeout(() => {
      setSelectedSceneId(targetSceneId);
      const nextScene = currentScenes.find((s) => s.id === targetSceneId);
      if (nextScene) {
        setCameraYaw(nextScene.initial_yaw || 0);
        setCameraPitch(nextScene.initial_pitch || 0);
      }
      setSelectedPin(null);
      setIsSceneTransitioning(false);
    }, 450);
  };

  // Save Scene
  const handleSaveScene = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDestination) return;

    if (!sceneFormTitle.trim() || !sceneFormPanoUrl.trim()) {
      showToast('Judul scene dan file gambar panorama wajib diisi.', 'warning');
      return;
    }

    const newScene: PanoramaScene = {
      id: editingScene ? editingScene.id : `scene-${Date.now().toString(36)}`,
      destination_id: selectedDestination.id,
      title: sceneFormTitle.trim(),
      type: sceneFormType,
      panorama_url: sceneFormPanoUrl.trim(),
      ambient_audio_url: sceneFormAudioUrl.trim() || undefined,
      initial_pitch: sceneFormPitch,
      initial_yaw: sceneFormYaw,
      hotspots: editingScene ? editingScene.hotspots : [],
    };

    const updatedDestinations = await saveDestinationScene(
      selectedDestination.id,
      newScene,
      destinations
    );

    onUpdateDestinations(updatedDestinations);
    setSelectedSceneId(newScene.id);
    setIsSceneModalOpen(false);
    showToast(
      editingScene
        ? 'Data scene panorama berhasil diperbarui.'
        : 'Scene panorama 360° baru berhasil ditambahkan.',
      'success'
    );
  };

  // Save Pin
  const handleSavePin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDestination || !activeScene) return;

    if (!pinFormTitle.trim()) {
      showToast('Judul pin hotspot wajib diisi.', 'warning');
      return;
    }

    const newPin: HotspotPin = {
      id: editingPin ? editingPin.id : `pin-${Date.now().toString(36)}`,
      scene_id: activeScene.id,
      category: pinFormCategory,
      title: pinFormTitle.trim(),
      description: pinFormDesc.trim(),
      pitch: pinFormPitch,
      yaw: pinFormYaw,
      target_scene_id:
        pinFormCategory === 'navigasi' ? pinFormTargetScene : undefined,
      audio_url:
        pinFormCategory === 'audio_budaya' ? pinFormAudioUrl : undefined,
      partner_name:
        pinFormCategory === 'mitra_umkm' ? pinFormPartnerName : undefined,
      partner_fee:
        pinFormCategory === 'mitra_umkm' ? pinFormPartnerFee : undefined,
    };

    const updatedDestinations = await saveSceneHotspot(
      selectedDestination.id,
      activeScene.id,
      newPin,
      destinations
    );

    onUpdateDestinations(updatedDestinations);
    setIsPinModalOpen(false);
    setSelectedPin(newPin);
    showToast(
      editingPin
        ? 'Pin hotspot berhasil diperbarui.'
        : 'Pin hotspot baru berhasil ditempelkan ke panorama 360°.',
      'success'
    );
  };

  const handleDeletePin = async (pinId: string) => {
    if (!selectedDestination || !activeScene) return;
    if (!window.confirm('Hapus pin hotspot ini dari scene?')) return;

    const updated = await deleteSceneHotspot(
      selectedDestination.id,
      activeScene.id,
      pinId,
      destinations
    );
    onUpdateDestinations(updated);
    if (selectedPin?.id === pinId) setSelectedPin(null);
    showToast('Pin hotspot berhasil dihapus.', 'info');
  };

  const handleDeleteScene = async (sceneId: string) => {
    if (!selectedDestination) return;
    if (!window.confirm('Hapus scene panorama 360° ini beserta seluruh pin?')) return;

    const updated = await deleteDestinationScene(
      selectedDestination.id,
      sceneId,
      destinations
    );
    onUpdateDestinations(updated);
    const remaining =
      updated.find((d) => d.id === selectedDestination.id)?.scenes_360 || [];
    setSelectedSceneId(remaining[0]?.id || '');
    showToast('Scene panorama berhasil dihapus.', 'info');
  };

  const getCategoryMeta = (cat: HotspotPinCategory) => {
    switch (cat) {
      case 'info_adat':
        return {
          label: 'Info Adat & Sejarah',
          color: '#CA8A04',
          bg: '#FEF08A',
          icon: <BookOpen className="w-4 h-4" />,
        };
      case 'navigasi':
        return {
          label: 'Navigasi Pindah Scene',
          color: '#1D4ED8',
          bg: '#BFDBFE',
          icon: <Compass className="w-4 h-4" />,
        };
      case 'audio_budaya':
        return {
          label: 'Audio Narasi Budaya',
          color: '#4F46E5',
          bg: '#C7D2FE',
          icon: <Volume2 className="w-4 h-4" />,
        };
      case 'mitra_umkm':
        return {
          label: 'Mitra UMKM Nagari',
          color: '#C2410C',
          bg: '#FFEDD5',
          icon: <ShoppingBag className="w-4 h-4" />,
        };
    }
  };

  const sceneHotspots = activeScene?.hotspots || [];
  const filteredHotspots =
    pinCategoryFilter === 'all'
      ? sceneHotspots
      : sceneHotspots.filter((h) => h.category === pinCategoryFilter);

  return (
    <div className="space-y-6">
      {/* Audio Ambient Player Element */}
      {activeScene?.ambient_audio_url && (
        <audio
          ref={audioRef}
          src={activeScene.ambient_audio_url}
          loop
          className="hidden"
        />
      )}

      {/* Header Halaman */}
      <header className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA]">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm shrink-0">
              <Camera className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                  Studio Virtual 360° &amp; Visual 4-Pin Editor
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  60 FPS Panorama Viewer
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1">
                Jelajahi panorama 360° dengan wrap-around mulus, tilt vertikal, zoom, dan tempelkan 4 pin interaktif (Info Adat, Navigasi Aerial-to-Ground, Audio Budaya, dan Pin Mitra UMKM Nagari).
              </p>
            </div>
          </div>

          {/* Pemilih Destinasi & Tambah Scene */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
            <div className="flex items-center gap-2">
              <label
                htmlFor={destSelectId}
                className="text-xs font-bold text-[#1B1F1A] shrink-0"
              >
                Destinasi:
              </label>
              <select
                id={destSelectId}
                value={selectedDestId}
                onChange={(e) => {
                  setSelectedDestId(e.target.value);
                  const dest = destinations.find((d) => d.id === e.target.value);
                  const firstScene = dest?.scenes_360?.[0];
                  setSelectedSceneId(firstScene?.id || '');
                  setSelectedPin(null);
                }}
                className="min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
              >
                {destinations.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name} ({d.scenes_360?.length || 0} Scene 360°)
                  </option>
                ))}
              </select>
            </div>

            <button
              type="button"
              onClick={() => {
                setEditingScene(null);
                setSceneFormTitle('');
                setSceneFormType('aerial');
                setSceneFormPanoUrl('');
                setSceneFormAudioUrl('');
                setSceneFormPitch(0);
                setSceneFormYaw(0);
                setIsSceneModalOpen(true);
              }}
              className="min-h-[44px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center justify-center gap-2 shadow-sm transition"
            >
              <Plus className="w-4 h-4" />
              <span>Tambah Scene 360°</span>
            </button>
          </div>
        </div>

        {/* Tab Manajemen Scene */}
        <div className="mt-6 pt-5 border-t border-[#E4E9DA] flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-bold text-[#4A5248] mr-1 flex items-center gap-1.5">
              <Layers className="w-4 h-4 text-[#234B24]" />
              <span>Scene Aktif:</span>
            </span>
            {currentScenes.length === 0 ? (
              <span className="text-xs italic text-[#767676]">
                Belum ada scene 360°. Silakan unggah panorama pertama.
              </span>
            ) : (
              currentScenes.map((scene) => {
                const isActive = scene.id === activeScene?.id;
                return (
                  <button
                    key={scene.id}
                    type="button"
                    onClick={() => {
                      setSelectedSceneId(scene.id);
                      setSelectedPin(null);
                    }}
                    className={`min-h-[40px] px-3.5 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
                      isActive
                        ? 'bg-[#234B24] text-[#F6F3EC] shadow-sm'
                        : 'bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#1B1F1A] border border-[#CFD8BE]'
                    }`}
                  >
                    <span
                      className={`w-2 h-2 rounded-full ${
                        scene.type === 'aerial' ? 'bg-[#3B82F6]' : 'bg-[#10B981]'
                      }`}
                    />
                    <span>{scene.title}</span>
                    <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-white/20">
                      {scene.hotspots?.length || 0} Pin
                    </span>
                  </button>
                );
              })
            )}
          </div>

          {activeScene && (
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => {
                  setEditingScene(activeScene);
                  setSceneFormTitle(activeScene.title);
                  setSceneFormType(activeScene.type);
                  setSceneFormPanoUrl(activeScene.panorama_url);
                  setSceneFormAudioUrl(activeScene.ambient_audio_url || '');
                  setSceneFormPitch(activeScene.initial_pitch);
                  setSceneFormYaw(activeScene.initial_yaw);
                  setIsSceneModalOpen(true);
                }}
                className="min-h-[38px] px-3 py-1.5 rounded-lg bg-[#E4E9DA] hover:bg-[#D5DFC9] text-[#234B24] font-bold text-xs flex items-center gap-1.5"
              >
                <Edit3 className="w-3.5 h-3.5" />
                <span>Edit Scene</span>
              </button>
              <button
                type="button"
                onClick={() => handleDeleteScene(activeScene.id)}
                className="min-h-[38px] px-3 py-1.5 rounded-lg bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637] font-bold text-xs flex items-center gap-1.5"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>Hapus</span>
              </button>
            </div>
          )}
        </div>
      </header>

      {/* Main Content: Interactive Canvas & Pin List */}
      {activeScene ? (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Kolom Kiri: Kanvas 360° Interaktif (8 Kolom) */}
          <section
            ref={canvasContainerRef}
            className={`lg:col-span-8 bg-white rounded-[24px] p-5 lg:p-6 shadow-sm border border-[#E4E9DA] space-y-4 ${
              isFullscreen ? 'fixed inset-0 z-50 rounded-none p-6 overflow-hidden' : ''
            }`}
          >
            {/* Top Bar Kanvas: Info & Mode Switcher */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Eye className="w-4 h-4 text-[#234B24]" />
                  <span>{activeScene.title}</span>
                </h2>
                <p className="text-xs text-[#4A5248]">
                  {interactionMode === 'explore'
                    ? 'Tarik/geser kanvas untuk memutar sudut pandang 360° (Yaw & Pitch).'
                    : 'Klik langsung pada titik kanvas untuk menempelkan pin hotspot baru.'}
                </p>
              </div>

              {/* Mode Switcher Pill */}
              <div className="flex items-center p-1 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] shrink-0 self-start sm:self-center">
                <button
                  type="button"
                  onClick={() => setInteractionMode('explore')}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
                    interactionMode === 'explore'
                      ? 'bg-[#234B24] text-[#F6F3EC] shadow-xs'
                      : 'text-[#4A5248] hover:text-[#1B1F1A]'
                  }`}
                >
                  <Navigation className="w-3.5 h-3.5" />
                  <span>Mode Jelajah Kamera</span>
                </button>
                <button
                  type="button"
                  onClick={() => setInteractionMode('pin_picker')}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
                    interactionMode === 'pin_picker'
                      ? 'bg-[#F26B4B] text-white shadow-xs'
                      : 'text-[#4A5248] hover:text-[#1B1F1A]'
                  }`}
                >
                  <Crosshair className="w-3.5 h-3.5" />
                  <span>Mode Tempel Pin</span>
                </button>
              </div>
            </div>

            {/* Viewport Kanvas Panorama */}
            <div
              className={`relative w-full aspect-[2/1] rounded-2xl overflow-hidden bg-black select-none border-2 shadow-inner transition-opacity duration-300 ${
                interactionMode === 'pin_picker'
                  ? 'cursor-crosshair border-[#F26B4B]'
                  : 'cursor-grab active:cursor-grabbing border-[#234B24]/40'
              } ${isSceneTransitioning ? 'opacity-0 scale-95' : 'opacity-100 scale-100'}`}
            >
              <canvas
                ref={canvasRef}
                width={1280}
                height={640}
                onMouseDown={handleMouseDown}
                onMouseMove={handleMouseMove}
                onMouseUp={handleMouseUp}
                onClick={handleCanvasClickInExplore}
                className="w-full h-full block"
              />

              {/* HUD: Kompas & Koordinat Real-time */}
              <div className="absolute top-3 left-3 px-3 py-1.5 rounded-xl bg-black/70 backdrop-blur-xs text-white text-[11px] font-mono flex items-center gap-2 pointer-events-none">
                <Compass className="w-3.5 h-3.5 text-[#A7F3D0] animate-spin" />
                <span>
                  Yaw: <strong>{Math.round(cameraYaw)}°</strong> · Pitch:{' '}
                  <strong>{Math.round(cameraPitch)}°</strong> · Zoom:{' '}
                  <strong>{zoomLevel.toFixed(1)}x</strong>
                </span>
              </div>

              {/* HUD: Kontrol Zoom, Reset, Audio, Fullscreen */}
              <div className="absolute top-3 right-3 flex items-center gap-1.5">
                {activeScene.ambient_audio_url && (
                  <button
                    type="button"
                    onClick={() => setIsAudioMuted(!isAudioMuted)}
                    className="p-2 rounded-xl bg-black/70 hover:bg-black/90 text-white shadow-md backdrop-blur-xs"
                    title={isAudioMuted ? 'Nyalakan Audio' : 'Matikan Audio'}
                  >
                    {isAudioMuted ? (
                      <VolumeX className="w-4 h-4 text-[#D95637]" />
                    ) : (
                      <Volume2 className="w-4 h-4 text-[#A7F3D0]" />
                    )}
                  </button>
                )}

                <button
                  type="button"
                  onClick={() => setZoomLevel((z) => Math.min(2.2, z + 0.2))}
                  className="p-2 rounded-xl bg-black/70 hover:bg-black/90 text-white shadow-md backdrop-blur-xs"
                  title="Perbesar (Zoom In)"
                >
                  <ZoomIn className="w-4 h-4" />
                </button>

                <button
                  type="button"
                  onClick={() => setZoomLevel((z) => Math.max(0.8, z - 0.2))}
                  className="p-2 rounded-xl bg-black/70 hover:bg-black/90 text-white shadow-md backdrop-blur-xs"
                  title="Perkecil (Zoom Out)"
                >
                  <ZoomOut className="w-4 h-4" />
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setCameraYaw(activeScene.initial_yaw || 0);
                    setCameraPitch(activeScene.initial_pitch || 0);
                    setZoomLevel(1.0);
                  }}
                  className="p-2 rounded-xl bg-black/70 hover:bg-black/90 text-white shadow-md backdrop-blur-xs"
                  title="Atur Ulang Sudut Pandang"
                >
                  <RotateCcw className="w-4 h-4" />
                </button>

                <button
                  type="button"
                  onClick={() => setIsFullscreen(!isFullscreen)}
                  className="p-2 rounded-xl bg-black/70 hover:bg-black/90 text-white shadow-md backdrop-blur-xs"
                  title="Layar Penuh"
                >
                  {isFullscreen ? (
                    <Minimize2 className="w-4 h-4" />
                  ) : (
                    <Maximize2 className="w-4 h-4" />
                  )}
                </button>
              </div>

              {/* Status Banner Bottom Canvas */}
              <div className="absolute bottom-3 left-3 right-3 flex items-center justify-between pointer-events-none">
                <span className="px-2.5 py-1 rounded-lg bg-black/60 text-white text-[10px] font-bold backdrop-blur-xs">
                  {interactionMode === 'pin_picker'
                    ? '🎯 Klik pada panorama untuk menaruh pin'
                    : '🔍 Geser mouse untuk memutar 360°'}
                </span>

                <span className="px-2.5 py-1 rounded-lg bg-black/60 text-[#A7F3D0] text-[10px] font-bold backdrop-blur-xs">
                  {sceneHotspots.length} Pin Aktif di Scene
                </span>
              </div>
            </div>

            {/* Popup Card Pin Terpilih */}
            {selectedPin && (
              <div className="p-4 rounded-2xl bg-[#E4E9DA]/80 border border-[#CFD8BE] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xs">
                <div className="flex items-start gap-3 min-w-0">
                  <div
                    style={{
                      backgroundColor: getCategoryMeta(selectedPin.category).bg,
                      color: getCategoryMeta(selectedPin.category).color,
                    }}
                    className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 border border-current shadow-xs"
                  >
                    {getCategoryMeta(selectedPin.category).icon}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-white text-[#234B24]">
                        {getCategoryMeta(selectedPin.category).label}
                      </span>
                      <span className="text-[11px] text-[#4A5248] font-mono">
                        Yaw: {selectedPin.yaw}° · Pitch: {selectedPin.pitch}°
                      </span>
                    </div>

                    <h3 className="text-sm font-extrabold text-[#1B1F1A] mt-1 truncate">
                      {selectedPin.title}
                    </h3>
                    <p className="text-xs text-[#4A5248] line-clamp-2 mt-0.5">
                      {selectedPin.description || 'Tidak ada deskripsi rinci.'}
                    </p>

                    {/* Jika Pin Navigasi Pindah Scene */}
                    {selectedPin.category === 'navigasi' &&
                      selectedPin.target_scene_id && (
                        <div className="mt-2">
                          <button
                            type="button"
                            onClick={() =>
                              handleTransitionToScene(selectedPin.target_scene_id!)
                            }
                            className="min-h-[36px] px-3.5 py-1.5 rounded-xl bg-[#1D4ED8] hover:bg-[#1E40AF] text-white text-xs font-bold inline-flex items-center gap-1.5 shadow-sm transition"
                          >
                            <span>Melompat ke Scene Tujuan</span>
                            <ArrowRight className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      )}

                    {/* Jika Pin Audio Budaya */}
                    {selectedPin.category === 'audio_budaya' &&
                      selectedPin.audio_url && (
                        <div className="mt-2 flex items-center gap-2">
                          <audio
                            controls
                            src={selectedPin.audio_url}
                            className="h-8 max-w-[220px]"
                          />
                        </div>
                      )}

                    {/* Jika Pin Mitra UMKM */}
                    {selectedPin.category === 'mitra_umkm' && (
                      <div className="mt-2 flex flex-wrap items-center gap-3">
                        <span className="text-xs font-bold text-[#F26B4B]">
                          Mitra: {selectedPin.partner_name || 'Mitra Nagari'} (Rp{' '}
                          {(selectedPin.partner_fee || 0).toLocaleString('id-ID')})
                        </span>
                        {onNavigateToPartner && (
                          <button
                            type="button"
                            onClick={() => onNavigateToPartner()}
                            className="min-h-[32px] px-3 py-1 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1 shadow-xs"
                          >
                            <Store className="w-3.5 h-3.5" />
                            <span>Lihat Detail Mitra &amp; Escrow</span>
                          </button>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0 self-end sm:self-center">
                  <button
                    type="button"
                    onClick={() => {
                      setEditingPin(selectedPin);
                      setPinFormCategory(selectedPin.category);
                      setPinFormTitle(selectedPin.title);
                      setPinFormDesc(selectedPin.description || '');
                      setPinFormPitch(selectedPin.pitch);
                      setPinFormYaw(selectedPin.yaw);
                      setPinFormTargetScene(selectedPin.target_scene_id || '');
                      setPinFormAudioUrl(selectedPin.audio_url || '');
                      setPinFormPartnerName(selectedPin.partner_name || '');
                      setPinFormPartnerFee(selectedPin.partner_fee || 0);
                      setIsPinModalOpen(true);
                    }}
                    className="p-2 rounded-lg bg-white hover:bg-gray-100 text-[#234B24] border border-[#CFD8BE]"
                    title="Edit Pin"
                  >
                    <Edit3 className="w-4 h-4" />
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDeletePin(selectedPin.id)}
                    className="p-2 rounded-lg bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637]"
                    title="Hapus Pin"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPin(null)}
                    className="p-2 rounded-lg text-[#767676] hover:bg-black/5"
                    title="Tutup Popup"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </section>

          {/* Kolom Kanan: Daftar Pin & Manajemen (4 Kolom) */}
          <aside className="lg:col-span-4 bg-white rounded-[24px] p-5 lg:p-6 shadow-sm border border-[#E4E9DA] space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-[#F26B4B]" />
                  <span>Daftar Pin Hotspot ({sceneHotspots.length})</span>
                </h2>
                <p className="text-[11px] text-[#4A5248]">
                  4 kategori titik interaktif
                </p>
              </div>

              <button
                type="button"
                onClick={() => setInteractionMode('pin_picker')}
                className="min-h-[36px] px-3 py-1 rounded-lg bg-[#F26B4B] hover:bg-[#D95637] text-white font-bold text-xs flex items-center gap-1 shadow-xs"
              >
                <Crosshair className="w-3.5 h-3.5" />
                <span>+ Tempel Pin</span>
              </button>
            </div>

            {/* Filter Kategori */}
            <div className="flex flex-wrap gap-1.5">
              {[
                { id: 'all', label: 'Semua' },
                { id: 'info_adat', label: 'Adat' },
                { id: 'navigasi', label: 'Navigasi' },
                { id: 'audio_budaya', label: 'Audio' },
                { id: 'mitra_umkm', label: 'Mitra' },
              ].map((f) => (
                <button
                  key={f.id}
                  type="button"
                  onClick={() => setPinCategoryFilter(f.id)}
                  className={`px-2.5 py-1 rounded-lg text-[11px] font-bold transition ${
                    pinCategoryFilter === f.id
                      ? 'bg-[#234B24] text-[#F6F3EC]'
                      : 'bg-[#F6F3EC] text-[#4A5248] hover:bg-[#E4E9DA]'
                  }`}
                >
                  {f.label}
                </button>
              ))}
            </div>

            {/* List Pin */}
            <div className="space-y-2.5 max-h-[500px] overflow-y-auto pr-1">
              {filteredHotspots.length === 0 ? (
                <div className="p-6 text-center rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
                  <Crosshair className="w-8 h-8 text-[#767676] mx-auto mb-2" />
                  <p className="text-xs font-bold text-[#1B1F1A]">
                    Belum ada pin untuk kategori ini
                  </p>
                  <p className="text-[11px] text-[#4A5248] mt-1">
                    Aktifkan &quot;Mode Tempel Pin&quot; dan klik pada kanvas.
                  </p>
                </div>
              ) : (
                filteredHotspots.map((pin) => {
                  const meta = getCategoryMeta(pin.category);
                  const isSelected = selectedPin?.id === pin.id;

                  return (
                    <div
                      key={pin.id}
                      onClick={() => {
                        setSelectedPin(pin);
                        // Rotate camera to face pin
                        setCameraYaw(pin.yaw);
                        setCameraPitch(pin.pitch);
                      }}
                      className={`p-3.5 rounded-2xl border transition cursor-pointer ${
                        isSelected
                          ? 'bg-[#E4E9DA] border-[#234B24] shadow-sm'
                          : 'bg-[#F6F3EC]/70 hover:bg-[#E4E9DA]/50 border-[#CFD8BE]'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-center gap-2">
                          <span
                            style={{
                              backgroundColor: meta.bg,
                              color: meta.color,
                            }}
                            className="p-1 rounded-md"
                          >
                            {meta.icon}
                          </span>
                          <span className="text-[11px] font-bold text-[#234B24]">
                            {meta.label}
                          </span>
                        </div>
                        <span className="text-[10px] text-[#767676] font-mono">
                          Y:{pin.yaw}° P:{pin.pitch}°
                        </span>
                      </div>

                      <h3 className="text-xs font-extrabold text-[#1B1F1A] mt-2 line-clamp-1">
                        {pin.title}
                      </h3>

                      {pin.partner_name && (
                        <div className="mt-1 text-[10px] font-bold text-[#C2410C]">
                          Mitra: {pin.partner_name}
                        </div>
                      )}

                      <div className="mt-2.5 pt-2 border-t border-black/5 flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setEditingPin(pin);
                            setPinFormCategory(pin.category);
                            setPinFormTitle(pin.title);
                            setPinFormDesc(pin.description || '');
                            setPinFormPitch(pin.pitch);
                            setPinFormYaw(pin.yaw);
                            setPinFormTargetScene(pin.target_scene_id || '');
                            setPinFormAudioUrl(pin.audio_url || '');
                            setPinFormPartnerName(pin.partner_name || '');
                            setPinFormPartnerFee(pin.partner_fee || 0);
                            setIsPinModalOpen(true);
                          }}
                          className="px-2.5 py-1 rounded-md text-[11px] font-bold bg-white text-[#234B24] border border-[#CFD8BE]"
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDeletePin(pin.id);
                          }}
                          className="px-2.5 py-1 rounded-md text-[11px] font-bold text-[#D95637] hover:bg-[#F26B4B]/15"
                        >
                          Hapus
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </aside>
        </div>
      ) : (
        <div className="bg-white rounded-[24px] p-12 text-center shadow-sm border border-[#E4E9DA]">
          <Camera className="w-12 h-12 text-[#234B24] mx-auto mb-3" />
          <h2 className="text-lg font-extrabold text-[#1B1F1A]">
            Belum Ada Scene Panorama 360° untuk {selectedDestination?.name}
          </h2>
          <p className="text-xs text-[#4A5248] max-w-md mx-auto mt-1 mb-5">
            Unggah file foto panorama 360° dari device untuk mulai merancang tur imersif.
          </p>
          <button
            type="button"
            onClick={() => {
              setEditingScene(null);
              setSceneFormTitle('');
              setSceneFormType('aerial');
              setSceneFormPanoUrl('');
              setSceneFormAudioUrl('');
              setIsSceneModalOpen(true);
            }}
            className="min-h-[48px] px-6 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-sm inline-flex items-center gap-2 shadow-md"
          >
            <Plus className="w-4 h-4" />
            <span>Unggah Panorama 360° Baru dari Device</span>
          </button>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL TAMBAH / EDIT SCENE PANORAMA (UPLOAD FILE DARI DEVICE)         */}
      {/* ==================================================================== */}
      {isSceneModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-xs">
                  <Camera className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {editingScene ? 'Edit Scene Panorama 360°' : 'Tambah Scene Panorama 360°'}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Destinasi: {selectedDestination?.name}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsSceneModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveScene} className="mt-5 space-y-4">
              {/* Upload Foto Panorama 360 dari Device */}
              <div>
                <ImageDropzone
                  label="File Foto Panorama Equirectangular 360° (Upload dari Device)"
                  value={sceneFormPanoUrl}
                  onChange={(dataUrl) => setSceneFormPanoUrl(dataUrl)}
                  onClear={() => setSceneFormPanoUrl('')}
                  isPanorama={true}
                  maxDimension={2560}
                  quality={0.82}
                  helperText="Pilih foto panorama dari komputer. Format ideal equirectangular 2:1 (misal 2048×1024 atau 2560×1280 px). Otomatis dikompresi ringan."
                  required={true}
                />
              </div>

              <div>
                <label
                  htmlFor={sceneTitleId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Judul Scene Panorama <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  id={sceneTitleId}
                  type="text"
                  value={sceneFormTitle}
                  onChange={(e) => setSceneFormTitle(e.target.value)}
                  placeholder="Contoh: Tinjauan Udara Aerial Tebing Sarasah Bunta (150m)"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div>
                <label
                  htmlFor={sceneTypeId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Tipe Scene (Aerial / Ground) <span className="text-[#F26B4B]">*</span>
                </label>
                <select
                  id={sceneTypeId}
                  value={sceneFormType}
                  onChange={(e) =>
                    setSceneFormType(e.target.value as 'aerial' | 'ground')
                  }
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="aerial">Aerial (Drone Lanskap Udara)</option>
                  <option value="ground">Ground (Pelataran Permukaan Bumi)</option>
                </select>
              </div>

              {/* Upload File Audio Latar dari Device */}
              <div>
                <AudioDropzone
                  label="File Audio Suasana Latar / Spatial Ambient (Upload dari Device, Opsional)"
                  value={sceneFormAudioUrl}
                  onChange={(audioDataUrl) => setSceneFormAudioUrl(audioDataUrl)}
                  onClear={() => setSceneFormAudioUrl('')}
                  helperText="Pilih file MP3/WAV gemuruh air terjun, angin lembah, atau suasana alam dari komputer."
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label
                    htmlFor={sceneInitPitchId}
                    className="block text-xs font-bold text-[#1B1F1A] mb-1"
                  >
                    Sudut Awal Pitch (-80° s.d 80°)
                  </label>
                  <input
                    id={sceneInitPitchId}
                    type="number"
                    min={-80}
                    max={80}
                    value={sceneFormPitch}
                    onChange={(e) => setSceneFormPitch(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>
                <div>
                  <label
                    htmlFor={sceneInitYawId}
                    className="block text-xs font-bold text-[#1B1F1A] mb-1"
                  >
                    Sudut Awal Yaw (-180° s.d 180°)
                  </label>
                  <input
                    id={sceneInitYawId}
                    type="number"
                    min={-180}
                    max={180}
                    value={sceneFormYaw}
                    onChange={(e) => setSceneFormYaw(Number(e.target.value))}
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>
              </div>

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#E4E9DA]">
                <button
                  type="button"
                  onClick={() => setIsSceneModalOpen(false)}
                  className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold flex items-center gap-2 shadow-sm"
                >
                  <Save className="w-4 h-4" />
                  <span>Simpan Scene Panorama</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ==================================================================== */}
      {/* MODAL TAMBAH / EDIT HOTSPOT PIN                                      */}
      {/* ==================================================================== */}
      {isPinModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shadow-xs">
                  <Sparkles className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-[#1B1F1A]">
                    {editingPin ? 'Edit Pin Hotspot' : 'Tambah Pin Hotspot Baru'}
                  </h3>
                  <p className="text-[11px] text-[#4A5248]">
                    Scene: {activeScene?.title}
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsPinModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#767676] hover:bg-gray-100"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSavePin} className="mt-5 space-y-4">
              <div>
                <label
                  htmlFor={pinCatId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Kategori Pin Hotspot <span className="text-[#F26B4B]">*</span>
                </label>
                <select
                  id={pinCatId}
                  value={pinFormCategory}
                  onChange={(e) =>
                    setPinFormCategory(e.target.value as HotspotPinCategory)
                  }
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="info_adat">
                    Info Adat &amp; Sejarah (Kuning Emas)
                  </option>
                  <option value="navigasi">
                    Navigasi Pindah Scene (Biru Langit)
                  </option>
                  <option value="audio_budaya">
                    Audio Narasi Budaya / Minang (Ungu Indigo)
                  </option>
                  <option value="mitra_umkm">
                    Katalog Mitra UMKM Nagari (Koral Oranye)
                  </option>
                </select>
              </div>

              <div>
                <label
                  htmlFor={pinTitleId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Judul Pin Hotspot <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  id={pinTitleId}
                  type="text"
                  value={pinFormTitle}
                  onChange={(e) => setPinFormTitle(e.target.value)}
                  placeholder="Contoh: Formasi Batuan Granit Geopark Harau"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div>
                <label
                  htmlFor={pinDescId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Deskripsi / Narasi Edukasi
                </label>
                <textarea
                  id={pinDescId}
                  rows={3}
                  value={pinFormDesc}
                  onChange={(e) => setPinFormDesc(e.target.value)}
                  placeholder="Tuliskan cerita sejarah, filosofi adat Minangkabau..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              {/* Navigasi Target Scene */}
              {pinFormCategory === 'navigasi' && (
                <div className="p-3.5 rounded-xl bg-[#BFDBFE]/30 border border-[#93C5FD]">
                  <label
                    htmlFor={pinTargetSceneId}
                    className="block text-xs font-bold text-[#1D4ED8] mb-1"
                  >
                    Target Scene Pindah Tujuan <span className="text-[#F26B4B]">*</span>
                  </label>
                  <select
                    id={pinTargetSceneId}
                    value={pinFormTargetScene}
                    onChange={(e) => setPinFormTargetScene(e.target.value)}
                    required
                    className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#93C5FD] text-xs font-bold text-[#1B1F1A]"
                  >
                    <option value="">Pilih Scene Tujuan...</option>
                    {currentScenes
                      .filter((s) => s.id !== activeScene?.id)
                      .map((s) => (
                        <option key={s.id} value={s.id}>
                          {s.title} ({s.type})
                        </option>
                      ))}
                  </select>
                </div>
              )}

              {/* Audio Budaya Upload dari Device */}
              {pinFormCategory === 'audio_budaya' && (
                <div>
                  <AudioDropzone
                    label="File Audio Instrumen / Narasi Budaya Minang (Upload dari Device)"
                    value={pinFormAudioUrl}
                    onChange={(audioDataUrl) => setPinFormAudioUrl(audioDataUrl)}
                    onClear={() => setPinFormAudioUrl('')}
                    helperText="Pilih file rekaman instrumen saluang, rabab, atau narasi petuah adat dari komputer."
                  />
                </div>
              )}

              {/* Mitra UMKM */}
              {pinFormCategory === 'mitra_umkm' && (
                <div className="p-3.5 rounded-xl bg-[#FFEDD5]/40 border border-[#FDBA74] space-y-2.5">
                  <div>
                    <label
                      htmlFor={pinPartnerNameId}
                      className="block text-xs font-bold text-[#C2410C] mb-1"
                    >
                      Nama Mitra UMKM Nagari
                    </label>
                    <input
                      id={pinPartnerNameId}
                      type="text"
                      value={pinFormPartnerName}
                      onChange={(e) => setPinFormPartnerName(e.target.value)}
                      placeholder="Contoh: Pondok Kawa Sarasah Harau"
                      className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#FDBA74] text-xs font-medium text-[#1B1F1A]"
                    />
                  </div>
                  <div>
                    <label
                      htmlFor={pinPartnerFeeId}
                      className="block text-xs font-bold text-[#C2410C] mb-1"
                    >
                      Tarif / Biaya Standar (IDR)
                    </label>
                    <input
                      id={pinPartnerFeeId}
                      type="number"
                      min={0}
                      step={1000}
                      value={pinFormPartnerFee}
                      onChange={(e) =>
                        setPinFormPartnerFee(Number(e.target.value))
                      }
                      className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#FDBA74] text-xs font-medium text-[#1B1F1A]"
                    />
                  </div>
                </div>
              )}

              {/* Koordinat Posisi */}
              <div className="grid grid-cols-2 gap-3 pt-1">
                <div>
                  <label
                    htmlFor={pinPitchId}
                    className="block text-xs font-bold text-[#1B1F1A] mb-1"
                  >
                    Koordinat Pitch (-80° s.d 80°)
                  </label>
                  <input
                    id={pinPitchId}
                    type="number"
                    min={-80}
                    max={80}
                    value={pinFormPitch}
                    onChange={(e) => setPinFormPitch(Number(e.target.value))}
                    required
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold text-[#1B1F1A]"
                  />
                </div>
                <div>
                  <label
                    htmlFor={pinYawId}
                    className="block text-xs font-bold text-[#1B1F1A] mb-1"
                  >
                    Koordinat Yaw (-180° s.d 180°)
                  </label>
                  <input
                    id={pinYawId}
                    type="number"
                    min={-180}
                    max={180}
                    value={pinFormYaw}
                    onChange={(e) => setPinFormYaw(Number(e.target.value))}
                    required
                    className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-mono font-bold text-[#1B1F1A]"
                  />
                </div>
              </div>

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#E4E9DA]">
                <button
                  type="button"
                  onClick={() => setIsPinModalOpen(false)}
                  className="min-h-[44px] px-4 py-2 rounded-xl text-xs font-bold text-[#4A5248] hover:bg-[#F6F3EC]"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="min-h-[44px] px-5 py-2 rounded-xl bg-[#F26B4B] hover:bg-[#D95637] text-white text-xs font-bold flex items-center gap-2 shadow-sm"
                >
                  <Save className="w-4 h-4" />
                  <span>Simpan Pin Hotspot</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
