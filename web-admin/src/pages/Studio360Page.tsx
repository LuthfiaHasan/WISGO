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
  MessageSquare,
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

  // Form states for Pin Modal (Tata Ruang / Fasilitas Fisik 360°)
  const [pinFormCategory, setPinFormCategory] =
    useState<HotspotPinCategory>('fasilitas_umum');
  const [pinFormTitle, setPinFormTitle] = useState('');
  const [pinFormDesc, setPinFormDesc] = useState('');
  const [pinFormPitch, setPinFormPitch] = useState(0);
  const [pinFormYaw, setPinFormYaw] = useState(0);
  const [pinFormTargetScene, setPinFormTargetScene] = useState('');
  const [pinFormAudioUrl, setPinFormAudioUrl] = useState('');
  const [pinFormPartnerName, setPinFormPartnerName] = useState('');
  const [pinFormPartnerFee, setPinFormPartnerFee] = useState<number>(0);
  const [pinFormWhatsapp, setPinFormWhatsapp] = useState('');
  const [pinFormFacilitySubtype, setPinFormFacilitySubtype] = useState('Toilet Bersih & Sanitasi');
  const [pinFormOperatingHours, setPinFormOperatingHours] = useState('08:00 - 17:00 WIB');

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
              pin.category === 'fasilitas_umum'
                ? 'rgba(13, 148, 136, 0.45)'
                : pin.category === 'mitra_umkm'
                ? 'rgba(242, 107, 75, 0.45)'
                : pin.category === 'loket_info' || pin.category === 'info_adat'
                ? 'rgba(217, 119, 6, 0.45)'
                : pin.category === 'navigasi_arah' || pin.category === 'navigasi'
                ? 'rgba(37, 99, 235, 0.45)'
                : 'rgba(99, 102, 241, 0.45)';
            ctx.fill();

            // Pin base circle
            ctx.beginPath();
            ctx.arc(0, 0, 14, 0, Math.PI * 2);
            ctx.fillStyle =
              pin.category === 'fasilitas_umum'
                ? '#0D9488'
                : pin.category === 'mitra_umkm'
                ? '#F26B4B'
                : pin.category === 'loket_info' || pin.category === 'info_adat'
                ? '#D97706'
                : pin.category === 'navigasi_arah' || pin.category === 'navigasi'
                ? '#2563EB'
                : '#7C3AED';
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
    setPinFormCategory('fasilitas_umum');
    setPinFormTitle('');
    setPinFormDesc('');
    setPinFormTargetScene('');
    setPinFormAudioUrl('');
    setPinFormPartnerName('');
    setPinFormPartnerFee(0);
    setPinFormWhatsapp('');
    setPinFormFacilitySubtype('Toilet Bersih & Sanitasi');
    setPinFormOperatingHours('08:00 - 17:00 WIB');
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
      scene_type: sceneFormType,
      type: sceneFormType,
      panorama_url: sceneFormPanoUrl.trim(),
      upload_format: 'equirectangular',
      spatial_audio_url: sceneFormAudioUrl.trim() || '',
      ambient_audio_url: sceneFormAudioUrl.trim() || undefined,
      initial_pitch: sceneFormPitch,
      initial_yaw: sceneFormYaw,
      is_default_scene: editingScene ? editingScene.is_default_scene || false : false,
      created_at: editingScene?.created_at || new Date().toISOString(),
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

  // Save Pin (Tata Ruang & Fasilitas Fisik 360°)
  const handleSavePin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDestination || !activeScene) return;

    if (!pinFormTitle.trim()) {
      showToast('Judul pin fasilitas / penanda tata ruang wajib diisi.', 'warning');
      return;
    }

    if (pinFormCategory === 'mitra_umkm' && !pinFormWhatsapp.trim()) {
      showToast('Nomor WhatsApp Mitra wajib diisi agar wisatawan dapat terhubung ke chat.', 'warning');
      return;
    }

    const colorTokenMap: Record<string, string> = {
      fasilitas_umum: 'teal',
      mitra_umkm: 'coral',
      loket_info: 'amber',
      navigasi_arah: 'blue',
      info_adat: 'amber',
      navigasi: 'blue',
      audio_budaya: 'teal',
    };

    let targetRef = '';
    if (pinFormCategory === 'mitra_umkm' && pinFormWhatsapp.trim()) {
      targetRef = pinFormWhatsapp.trim().startsWith('http')
        ? pinFormWhatsapp.trim()
        : `https://wa.me/${pinFormWhatsapp.trim().replace(/[^0-9]/g, '')}`;
    } else if (pinFormCategory === 'navigasi_arah' || pinFormCategory === 'navigasi') {
      targetRef = pinFormTargetScene || '';
    }

    const newPin: HotspotPin = {
      id: editingPin ? editingPin.id : `pin-${Date.now().toString(36)}`,
      scene_id: activeScene.id,
      pin_type: pinFormCategory,
      color_token: colorTokenMap[pinFormCategory] || 'teal',
      pitch: pinFormPitch,
      yaw: pinFormYaw,
      title: pinFormTitle.trim(),
      target_ref: targetRef,
      voice_text: pinFormAudioUrl ? pinFormAudioUrl.trim() : '',
      description: pinFormDesc.trim(),
      created_at: editingPin?.created_at || new Date().toISOString(),

      category: pinFormCategory,
      target_scene_id:
        pinFormCategory === 'navigasi_arah' || pinFormCategory === 'navigasi'
          ? pinFormTargetScene
          : undefined,
      audio_url:
        pinFormCategory === 'audio_budaya' ? pinFormAudioUrl : undefined,
      partner_name:
        pinFormCategory === 'mitra_umkm' ? pinFormPartnerName : undefined,
      partner_fee:
        pinFormCategory === 'mitra_umkm' ? pinFormPartnerFee : undefined,
      whatsapp_number:
        pinFormCategory === 'mitra_umkm' ? pinFormWhatsapp.trim() : undefined,
      facility_subtype:
        pinFormCategory === 'fasilitas_umum' ? pinFormFacilitySubtype : undefined,
      operating_hours:
        pinFormCategory === 'loket_info' ? pinFormOperatingHours : undefined,
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
      case 'fasilitas_umum':
        return {
          label: 'Fasilitas Umum (Toilet/Parkir/Musala)',
          color: '#166534',
          bg: '#DCFCE7',
          pinSvg: '/assets/synced/pin_fasilitas_umum.svg',
          icon: <MapPin className="w-4 h-4" />,
        };
      case 'mitra_umkm':
        return {
          label: 'Mitra UMKM / Jasa (Chat WA)',
          color: '#C2410C',
          bg: '#FFEDD5',
          pinSvg: '/assets/synced/pin_mitra_umkm.svg',
          icon: <ShoppingBag className="w-4 h-4" />,
        };
      case 'loket_info':
      case 'info_adat':
        return {
          label: 'Loket & Info Resmi (Posko)',
          color: '#1D4ED8',
          bg: '#DBEAFE',
          pinSvg: '/assets/synced/pin_loket_info.svg',
          icon: <BookOpen className="w-4 h-4" />,
        };
      case 'navigasi_arah':
      case 'navigasi':
        return {
          label: 'Navigasi Arah (Pindah Scene)',
          color: '#234B24',
          bg: '#E4E9DA',
          pinSvg: '/assets/synced/pin_navigasi_arah.svg',
          icon: <Compass className="w-4 h-4" />,
        };
      case 'audio_budaya':
      default:
        return {
          label: 'Audio Narasi Budaya',
          color: '#234B24',
          bg: '#E4E9DA',
          pinSvg: '/assets/synced/pin_navigasi_arah.svg',
          icon: <Volume2 className="w-4 h-4" />,
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
      <header className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
            Studio Panorama 360°
          </h1>
          <p className="text-xs text-[#4A5248] mt-0.5">
            Foto panorama equirectangular, kondisi nyata destinasi, dan 4 kategori pin fasilitas.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2.5 shrink-0">
          <div className="flex items-center gap-2">
            <label
              htmlFor={destSelectId}
              className="text-xs font-bold text-[#1B1F1A] shrink-0 hidden sm:inline"
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
              className="h-9 px-3 py-1 rounded-xl bg-white border border-[#234B24]/15 text-xs font-bold text-[#1B1F1A] shadow-2xs focus:outline-hidden focus:ring-1 focus:ring-[#234B24]"
            >
              {destinations.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.name} ({d.scenes_360?.length || 0} Scene)
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
            className="h-9 px-3.5 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center gap-1.5 shadow-xs transition"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>Tambah Scene</span>
          </button>
        </div>
      </header>

      {/* Tab Navigasi Scene Aktif */}
      <nav
        aria-label="Scene Panorama"
        className="flex overflow-x-auto no-scrollbar whitespace-nowrap shrink-0 gap-2 p-1.5 bg-white rounded-xl border border-[#234B24]/10 shadow-2xs"
      >
        <span className="text-xs font-bold text-[#4A5248] px-2 py-1.5 flex items-center gap-1.5 shrink-0">
          <Layers className="w-3.5 h-3.5 text-[#234B24]" />
          <span>Scene:</span>
        </span>
        {currentScenes.length === 0 ? (
          <span className="text-xs italic text-[#767676] px-2 py-1.5">
            Belum ada scene 360°. Silakan tambah scene.
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
                className={`h-9 px-3.5 rounded-lg text-xs font-bold transition flex items-center gap-2 ${
                  isActive
                    ? 'bg-[#234B24] text-[#F6F3EC] shadow-xs'
                    : 'text-[#4A5248] hover:text-[#234B24] hover:bg-[#234B24]/5'
                }`}
              >
                <span>{scene.title}</span>
                <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-bold ${
                  isActive ? 'bg-white/20 text-white' : 'bg-[#234B24]/10 text-[#234B24]'
                }`}>
                  {scene.hotspots?.length || 0} Pin
                </span>
              </button>
            );
          })
        )}
        {activeScene && (
          <div className="flex items-center gap-1.5 ml-auto shrink-0">
            <button
              type="button"
              onClick={() => {
                setEditingScene(activeScene);
                setSceneFormTitle(activeScene.title);
                setSceneFormType(((activeScene.scene_type || activeScene.type || 'ground') as 'aerial' | 'ground'));
                setSceneFormPanoUrl(activeScene.panorama_url);
                setSceneFormAudioUrl(activeScene.spatial_audio_url || activeScene.ambient_audio_url || '');
                setSceneFormPitch(activeScene.initial_pitch);
                setSceneFormYaw(activeScene.initial_yaw);
                setIsSceneModalOpen(true);
              }}
              className="h-9 px-3 rounded-lg bg-[#F6F3EC] hover:bg-[#E4E9DA] text-[#234B24] font-bold text-xs flex items-center gap-1.5 border border-[#234B24]/10"
            >
              <Edit3 className="w-3.5 h-3.5" />
              <span>Edit Scene</span>
            </button>
            <button
              type="button"
              onClick={() => handleDeleteScene(activeScene.id)}
              className="h-9 px-2.5 rounded-lg bg-[#F26B4B]/10 hover:bg-[#F26B4B]/20 text-[#D95637] font-bold text-xs flex items-center gap-1.5"
              title="Hapus Scene"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Hapus</span>
            </button>
          </div>
        )}
      </nav>

      {/* Main Content: Interactive Canvas & Pin List */}
      {activeScene ? (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Kolom Kiri: Kanvas 360° Interaktif (8 Kolom) */}
          <section
            ref={canvasContainerRef}
            className={`lg:col-span-8 bg-white rounded-2xl p-5 lg:p-6 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] space-y-4 ${
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
                  <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center shrink-0 border border-[#234B24]/10 shadow-xs">
                    <img
                      src={getCategoryMeta(selectedPin.pin_type || selectedPin.category || 'fasilitas_umum').pinSvg}
                      alt=""
                      className="w-7 h-8 object-contain"
                    />
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-white text-[#234B24]">
                        {getCategoryMeta(selectedPin.pin_type || selectedPin.category || 'fasilitas_umum').label}
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
                    {(selectedPin.category === 'navigasi_arah' || selectedPin.category === 'navigasi') &&
                      selectedPin.target_scene_id && (
                        <div className="mt-2">
                          <button
                            type="button"
                            onClick={() =>
                              handleTransitionToScene(selectedPin.target_scene_id!)
                            }
                            className="min-h-[36px] px-3.5 py-1.5 rounded-xl bg-[#2563EB] hover:bg-[#1D4ED8] text-white text-xs font-bold inline-flex items-center gap-1.5 shadow-sm transition"
                          >
                            <span>Melompat ke Scene Tujuan</span>
                            <ArrowRight className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      )}

                    {/* Jika Pin Fasilitas Umum */}
                    {selectedPin.category === 'fasilitas_umum' && (
                      <div className="mt-2 flex items-center gap-2">
                        <span className="text-xs font-bold text-[#0D9488] bg-[#CCFBF1] px-2.5 py-1 rounded-lg flex items-center gap-1">
                          <MapPin className="w-3 h-3" />
                          <span>Fasilitas: {selectedPin.facility_subtype || 'Toilet, Parkir, Musala'}</span>
                        </span>
                      </div>
                    )}

                    {/* Jika Pin Loket & Info Resmi */}
                    {(selectedPin.category === 'loket_info' || selectedPin.category === 'info_adat') && (
                      <div className="mt-2 flex items-center gap-2">
                        <span className="text-xs font-bold text-[#D97706] bg-[#FEF08A] px-2.5 py-1 rounded-lg flex items-center gap-1">
                          <Info className="w-3 h-3" />
                          <span>Posko Resmi · Jam: {selectedPin.operating_hours || '08:00 - 17:00 WIB'}</span>
                        </span>
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
                      <div className="mt-2 flex flex-wrap items-center gap-2.5">
                        <span className="text-xs font-bold text-[#F26B4B]">
                          Mitra: {selectedPin.partner_name || 'Mitra Nagari'} (Rp{' '}
                          {(selectedPin.partner_fee || 0).toLocaleString('id-ID')})
                        </span>
                        {selectedPin.whatsapp_number && (
                          <a
                            href={`https://wa.me/${selectedPin.whatsapp_number.replace(/\D/g, '')}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="min-h-[32px] px-3 py-1 rounded-lg bg-[#128C7E] hover:bg-[#075E54] text-white text-xs font-bold inline-flex items-center gap-1.5 shadow-xs transition"
                          >
                            <MessageSquare className="w-3.5 h-3.5" />
                            <span>Chat WA Mitra ({selectedPin.whatsapp_number})</span>
                          </a>
                        )}
                        {onNavigateToPartner && (
                          <button
                            type="button"
                            onClick={() => onNavigateToPartner()}
                            className="min-h-[32px] px-3 py-1 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] text-xs font-bold inline-flex items-center gap-1 shadow-xs"
                          >
                            <Store className="w-3.5 h-3.5" />
                            <span>Direktori Mitra</span>
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
                      setPinFormCategory(selectedPin.pin_type || selectedPin.category || 'fasilitas_umum');
                      setPinFormTitle(selectedPin.title);
                      setPinFormDesc(selectedPin.description || '');
                      setPinFormPitch(selectedPin.pitch);
                      setPinFormYaw(selectedPin.yaw);
                      setPinFormTargetScene(selectedPin.target_scene_id || '');
                      setPinFormAudioUrl(selectedPin.audio_url || '');
                      setPinFormPartnerName(selectedPin.partner_name || '');
                      setPinFormPartnerFee(selectedPin.partner_fee || 0);
                      setPinFormWhatsapp(selectedPin.whatsapp_number || '');
                      setPinFormFacilitySubtype(selectedPin.facility_subtype || 'Toilet Bersih & Sanitasi');
                      setPinFormOperatingHours(selectedPin.operating_hours || '08:00 - 17:00 WIB');
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
          <aside className="lg:col-span-4 bg-white rounded-2xl p-5 lg:p-6 border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)] space-y-4">
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
                <span>Tempel Pin</span>
              </button>
            </div>

            {/* Filter Kategori Fasilitas */}
            <div className="flex flex-wrap gap-1.5">
              {[
                { id: 'all', label: 'Semua' },
                { id: 'fasilitas_umum', label: 'Fasilitas' },
                { id: 'mitra_umkm', label: 'Mitra WA' },
                { id: 'loket_info', label: 'Loket & Info' },
                { id: 'navigasi_arah', label: 'Navigasi' },
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
                  const meta = getCategoryMeta(pin.pin_type || pin.category || 'fasilitas_umum');
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
                          <img
                            src={meta.pinSvg}
                            alt=""
                            className="w-5 h-6 object-contain shrink-0"
                          />
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
                            setPinFormCategory(pin.pin_type || pin.category || 'fasilitas_umum');
                            setPinFormTitle(pin.title);
                            setPinFormDesc(pin.description || '');
                            setPinFormPitch(pin.pitch);
                            setPinFormYaw(pin.yaw);
                            setPinFormTargetScene(pin.target_scene_id || '');
                            setPinFormAudioUrl(pin.audio_url || '');
                            setPinFormPartnerName(pin.partner_name || '');
                            setPinFormPartnerFee(pin.partner_fee || 0);
                            setPinFormWhatsapp(pin.whatsapp_number || '');
                            setPinFormFacilitySubtype(pin.facility_subtype || 'Toilet Bersih & Sanitasi');
                            setPinFormOperatingHours(pin.operating_hours || '08:00 - 17:00 WIB');
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
        <div className="bg-white rounded-2xl p-12 text-center border border-[#234B24]/8 shadow-[0_4px_24px_rgba(35,75,36,0.04)]">
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
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#234B24]/10">
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

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10">
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
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#234B24]/10 max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#234B24]/10">
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
                  Kategori Penanda Fasilitas Fisik <span className="text-[#F26B4B]">*</span>
                </label>
                <select
                  id={pinCatId}
                  value={pinFormCategory}
                  onChange={(e) =>
                    setPinFormCategory(e.target.value as HotspotPinCategory)
                  }
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A]"
                >
                  <option value="fasilitas_umum">
                    1. Fasilitas Umum (Toilet, Parkir, Musala)
                  </option>
                  <option value="mitra_umkm">
                    2. Mitra UMKM / Jasa (Wajib Nomor WA Chat)
                  </option>
                  <option value="loket_info">
                    3. Loket &amp; Info Resmi (Posko Pengelola)
                  </option>
                  <option value="navigasi_arah">
                    4. Navigasi Arah (Pindah Scene Panorama)
                  </option>
                </select>
              </div>

              <div>
                <label
                  htmlFor={pinTitleId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Judul Fasilitas / Penanda Fisik <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  id={pinTitleId}
                  type="text"
                  value={pinFormTitle}
                  onChange={(e) => setPinFormTitle(e.target.value)}
                  placeholder="Contoh: Toilet Bersih & Musala Rest Area Harau"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div>
                <label
                  htmlFor={pinDescId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  Keterangan Fasilitas / Petunjuk Lokasi
                </label>
                <textarea
                  id={pinDescId}
                  rows={2}
                  value={pinFormDesc}
                  onChange={(e) => setPinFormDesc(e.target.value)}
                  placeholder="Deskripsi fasilitas, arah pintu masuk, kondisi kebersihan..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              {/* Sub-form Kategori: Fasilitas Umum */}
              {pinFormCategory === 'fasilitas_umum' && (
                <div className="p-3.5 rounded-xl bg-[#CCFBF1]/50 border border-[#99F6E4] space-y-2">
                  <label
                    htmlFor="pin-facility-subtype"
                    className="block text-xs font-bold text-[#0D9488]"
                  >
                    Jenis Fasilitas Umum <span className="text-[#F26B4B]">*</span>
                  </label>
                  <select
                    id="pin-facility-subtype"
                    value={pinFormFacilitySubtype}
                    onChange={(e) => setPinFormFacilitySubtype(e.target.value)}
                    className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#99F6E4] text-xs font-bold text-[#1B1F1A]"
                  >
                    <option value="Toilet Bersih & Sanitasi">Toilet Bersih &amp; Sanitasi</option>
                    <option value="Area Parkir Resmi (Motor & Mobil)">Area Parkir Resmi (Motor &amp; Mobil)</option>
                    <option value="Musala / Tempat Ibadah Salat">Musala / Tempat Ibadah Salat</option>
                    <option value="Posko P3K / Medis Darurat">Posko P3K / Medis Darurat</option>
                    <option value="Area Kuliner & Gazebo Istirahat">Area Kuliner &amp; Gazebo Istirahat</option>
                    <option value="Tempat Sampah & Sanitasi Lingkungan">Tempat Sampah &amp; Sanitasi Lingkungan</option>
                  </select>
                </div>
              )}

              {/* Sub-form Kategori: Mitra UMKM (WAJIB NOMOR WHATSAPP) */}
              {pinFormCategory === 'mitra_umkm' && (
                <div className="p-3.5 rounded-xl bg-[#FFEDD5]/50 border border-[#FDBA74] space-y-2.5">
                  <div>
                    <label
                      htmlFor={pinPartnerNameId}
                      className="block text-xs font-bold text-[#C2410C] mb-1"
                    >
                      Nama Mitra UMKM / Usaha Jasa <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id={pinPartnerNameId}
                      type="text"
                      value={pinFormPartnerName}
                      onChange={(e) => setPinFormPartnerName(e.target.value)}
                      placeholder="Contoh: Pondok Kawa Sarasah Harau"
                      required
                      className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#FDBA74] text-xs font-medium text-[#1B1F1A]"
                    />
                  </div>
                  <div>
                    <label
                      htmlFor="pin-partner-whatsapp"
                      className="block text-xs font-bold text-[#C2410C] mb-1"
                    >
                      Nomor WhatsApp Aktif Mitra <span className="text-[#F26B4B]">*</span>
                    </label>
                    <input
                      id="pin-partner-whatsapp"
                      type="tel"
                      value={pinFormWhatsapp}
                      onChange={(e) => setPinFormWhatsapp(e.target.value)}
                      placeholder="081234567890 (Wisatawan klik pin langsung chat WA)"
                      required
                      className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#FDBA74] text-xs font-mono font-bold text-[#1B1F1A]"
                    />
                    <p className="text-[10px] text-[#9A3412] mt-0.5">
                      Wajib diisi: Pin ini akan langsung membuka chat WhatsApp dengan mitra ketika diklik di peta 360°.
                    </p>
                  </div>
                  <div>
                    <label
                      htmlFor={pinPartnerFeeId}
                      className="block text-xs font-bold text-[#C2410C] mb-1"
                    >
                      Estimasi Tarif / Jasa Layanan (IDR)
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

              {/* Sub-form Kategori: Loket & Info Posko */}
              {(pinFormCategory === 'loket_info' || pinFormCategory === 'info_adat') && (
                <div className="p-3.5 rounded-xl bg-[#FEF08A]/40 border border-[#FACC15] space-y-2">
                  <label
                    htmlFor="pin-operating-hours"
                    className="block text-xs font-bold text-[#854D0E] mb-1"
                  >
                    Jam Operasional Loket / Posko Pengelola
                  </label>
                  <input
                    id="pin-operating-hours"
                    type="text"
                    value={pinFormOperatingHours}
                    onChange={(e) => setPinFormOperatingHours(e.target.value)}
                    placeholder="Contoh: 08:00 - 17:00 WIB (Setiap Hari)"
                    className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#FACC15] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>
              )}

              {/* Sub-form Kategori: Navigasi Pindah Scene */}
              {(pinFormCategory === 'navigasi_arah' || pinFormCategory === 'navigasi') && (
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

              <div className="pt-4 flex items-center justify-end gap-2.5 border-t border-[#234B24]/10">
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
