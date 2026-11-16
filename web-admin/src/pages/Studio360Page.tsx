import React, { useState, useId } from 'react';
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

interface Studio360PageProps {
  destinations: Destination[];
  onUpdateDestinations: (updated: Destination[]) => void;
  showToast: (message: string, type?: 'success' | 'info' | 'warning' | 'error') => void;
}

export const Studio360Page: React.FC<Studio360PageProps> = ({
  destinations,
  onUpdateDestinations,
  showToast,
}) => {
  const destSelectId = useId();
  const sceneTitleId = useId();
  const sceneTypeId = useId();
  const scenePanoUrlId = useId();
  const sceneAudioUrlId = useId();
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
    destinations[0]?.id || 'dest-001'
  );

  const selectedDestination =
    destinations.find((d) => d.id === selectedDestId) || destinations[0];

  const currentScenes: PanoramaScene[] =
    selectedDestination?.scenes_360 || [];

  // Selected Scene
  const [selectedSceneId, setSelectedSceneId] = useState<string>(
    currentScenes[0]?.id || ''
  );

  const activeScene =
    currentScenes.find((s) => s.id === selectedSceneId) || currentScenes[0];

  // Visual Canvas Click coordinate
  const [clickedCoord, setClickedCoord] = useState<{
    pitch: number;
    yaw: number;
    xPercent: number;
    yPercent: number;
  } | null>(null);

  // Selected Pin for detailed popup/preview
  const [selectedPin, setSelectedPin] = useState<HotspotPin | null>(null);

  // Modals
  const [isSceneModalOpen, setIsSceneModalOpen] = useState(false);
  const [editingScene, setEditingScene] = useState<PanoramaScene | null>(null);

  const [isPinModalOpen, setIsPinModalOpen] = useState(false);
  const [editingPin, setEditingPin] = useState<HotspotPin | null>(null);

  // Form states for Scene Modal
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

  // Handle Canvas Click to calculate Pitch & Yaw
  const handleCanvasClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    const xRatio = Math.max(0, Math.min(1, x / rect.width));
    const yRatio = Math.max(0, Math.min(1, y / rect.height));

    // Yaw: -180 deg to +180 deg
    const yaw = Math.round(xRatio * 360 - 180);
    // Pitch: +90 deg (top) to -90 deg (bottom)
    const pitch = Math.round((0.5 - yRatio) * 180);

    const xPercent = Math.round(xRatio * 100);
    const yPercent = Math.round(yRatio * 100);

    setClickedCoord({ pitch, yaw, xPercent, yPercent });
  };

  // Open Add Pin with prefilled coordinates
  const handleOpenAddPinFromCanvas = () => {
    if (!activeScene) {
      showToast('Pilih atau buat scene terlebih dahulu.', 'warning');
      return;
    }
    setEditingPin(null);
    setPinFormCategory('info_adat');
    setPinFormTitle('');
    setPinFormDesc('');
    setPinFormPitch(clickedCoord ? clickedCoord.pitch : 0);
    setPinFormYaw(clickedCoord ? clickedCoord.yaw : 0);
    setPinFormTargetScene('');
    setPinFormAudioUrl('');
    setPinFormPartnerName('');
    setPinFormPartnerFee(0);
    setIsPinModalOpen(true);
  };

  const handleOpenEditPin = (pin: HotspotPin) => {
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
  };

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
    setClickedCoord(null);
    setSelectedPin(newPin);
    showToast(
      editingPin
        ? 'Pin hotspot berhasil diperbarui.'
        : 'Pin hotspot baru berhasil ditempel ke panorama 360°.',
      'success'
    );
  };

  const handleDeletePin = async (pinId: string) => {
    if (!selectedDestination || !activeScene) return;
    if (
      !window.confirm('Apakah Anda yakin ingin menghapus pin hotspot ini dari scene?')
    ) {
      return;
    }

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

  // Scene CRUD
  const handleOpenAddScene = () => {
    setEditingScene(null);
    setSceneFormTitle('');
    setSceneFormType('aerial');
    setSceneFormPanoUrl('');
    setSceneFormAudioUrl('');
    setSceneFormPitch(0);
    setSceneFormYaw(0);
    setIsSceneModalOpen(true);
  };

  const handleOpenEditScene = (scene: PanoramaScene) => {
    setEditingScene(scene);
    setSceneFormTitle(scene.title);
    setSceneFormType(scene.type);
    setSceneFormPanoUrl(scene.panorama_url);
    setSceneFormAudioUrl(scene.ambient_audio_url || '');
    setSceneFormPitch(scene.initial_pitch);
    setSceneFormYaw(scene.initial_yaw);
    setIsSceneModalOpen(true);
  };

  const handleSaveScene = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDestination) return;

    if (!sceneFormTitle.trim() || !sceneFormPanoUrl.trim()) {
      showToast('Judul scene dan URL gambar panorama wajib diisi.', 'warning');
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

  const handleDeleteScene = async (sceneId: string) => {
    if (!selectedDestination) return;
    if (
      !window.confirm(
        'Apakah Anda yakin ingin menghapus seluruh scene panorama 360° ini beserta seluruh pin di dalamnya?'
      )
    ) {
      return;
    }

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

  // Helper styles & icons for categories
  const getCategoryMeta = (cat: HotspotPinCategory) => {
    switch (cat) {
      case 'info_adat':
        return {
          label: 'Info Adat & Sejarah',
          color: '#CA8A04',
          bg: '#FEF08A',
          border: '#EAB308',
          icon: <BookOpen className="w-3.5 h-3.5" aria-hidden="true" />,
        };
      case 'navigasi':
        return {
          label: 'Navigasi Pindah Scene',
          color: '#1D4ED8',
          bg: '#BFDBFE',
          border: '#3B82F6',
          icon: <Compass className="w-3.5 h-3.5" aria-hidden="true" />,
        };
      case 'audio_budaya':
        return {
          label: 'Audio Narasi Budaya',
          color: '#4F46E5',
          bg: '#C7D2FE',
          border: '#6366F1',
          icon: <Volume2 className="w-3.5 h-3.5" aria-hidden="true" />,
        };
      case 'mitra_umkm':
        return {
          label: 'Mitra UMKM Nagari',
          color: '#C2410C',
          bg: '#FFEDD5',
          border: '#F26B4B',
          icon: <ShoppingBag className="w-3.5 h-3.5" aria-hidden="true" />,
        };
      default:
        return {
          label: 'Titik Informasi',
          color: '#234B24',
          bg: '#E4E9DA',
          border: '#234B24',
          icon: <Info className="w-3.5 h-3.5" aria-hidden="true" />,
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
      {/* Header Halaman */}
      <header className="bg-white rounded-[24px] p-6 lg:p-7 shadow-sm border border-[#E4E9DA]">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-sm shrink-0">
              <Camera className="w-6 h-6" aria-hidden="true" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl lg:text-2xl font-extrabold text-[#1B1F1A]">
                  Studio Virtual 360° &amp; Visual 4-Pin Editor
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#E4E9DA] text-[#234B24]">
                  Tur Imersif Nagari
                </span>
              </div>
              <p className="text-xs text-[#4A5248] mt-1">
                Kelola scene panorama aerial-to-ground dan tempelkan 4 kategori pin interaktif (Info Adat, Navigasi Pindah Scene, Audio Budaya, Mitra UMKM) langsung di atas kanvas visual.
              </p>
            </div>
          </div>

          {/* Pemilih Destinasi */}
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
                  setClickedCoord(null);
                  setSelectedPin(null);
                }}
                className="min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-bold text-[#1B1F1A] focus:outline-none focus:ring-2 focus:ring-[#234B24]"
              >
                {destinations.map((d) => {
                  const count = d.scenes_360?.length || 0;
                  return (
                    <option key={d.id} value={d.id}>
                      {d.name} ({count} Scene 360°)
                    </option>
                  );
                })}
              </select>
            </div>

            <button
              type="button"
              onClick={handleOpenAddScene}
              className="min-h-[44px] px-4 py-2 rounded-xl bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center justify-center gap-2 shadow-sm transition"
            >
              <Plus className="w-4 h-4" aria-hidden="true" />
              <span>Tambah Scene 360°</span>
            </button>
          </div>
        </div>

        {/* Tab Manajemen Scene untuk Destinasi Terpilih */}
        <div className="mt-6 pt-5 border-t border-[#E4E9DA] flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-bold text-[#4A5248] mr-1 flex items-center gap-1.5">
              <Layers className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
              <span>Daftar Scene:</span>
            </span>
            {currentScenes.length === 0 ? (
              <span className="text-xs italic text-[#767676]">
                Belum ada scene 360° untuk destinasi ini. Klik &quot;Tambah Scene 360°&quot;.
              </span>
            ) : (
              currentScenes.map((scene) => {
                const isActive = scene.id === activeScene?.id;
                const pinCount = scene.hotspots?.length || 0;
                return (
                  <button
                    key={scene.id}
                    type="button"
                    onClick={() => {
                      setSelectedSceneId(scene.id);
                      setClickedCoord(null);
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
                    <span
                      className={`text-[10px] px-1.5 py-0.5 rounded-full ${
                        isActive
                          ? 'bg-white/20 text-[#F6F3EC]'
                          : 'bg-[#E4E9DA] text-[#4A5248]'
                      }`}
                    >
                      {pinCount} Pin
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
                onClick={() => handleOpenEditScene(activeScene)}
                className="min-h-[38px] px-3 py-1.5 rounded-lg bg-[#E4E9DA] hover:bg-[#D5DFC9] text-[#234B24] font-bold text-xs flex items-center gap-1.5 transition"
              >
                <Edit3 className="w-3.5 h-3.5" aria-hidden="true" />
                <span>Edit Info Scene</span>
              </button>
              <button
                type="button"
                onClick={() => handleDeleteScene(activeScene.id)}
                className="min-h-[38px] px-3 py-1.5 rounded-lg bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637] font-bold text-xs flex items-center gap-1.5 transition"
              >
                <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                <span>Hapus Scene</span>
              </button>
            </div>
          )}
        </div>
      </header>

      {/* Main Content: Visual Canvas & Hotspot Pins Editor */}
      {activeScene ? (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Sisi Kiri: Visual Panorama Canvas Editor (8 Kolom) */}
          <section className="lg:col-span-8 bg-white rounded-[24px] p-5 lg:p-6 shadow-sm border border-[#E4E9DA] space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
              <div>
                <h2 className="text-base font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Eye className="w-4 h-4 text-[#234B24]" aria-hidden="true" />
                  <span>Kanvas Visual Panorama: {activeScene.title}</span>
                </h2>
                <p className="text-xs text-[#4A5248]">
                  Klik di area mana saja pada foto panorama untuk menentukan koordinat Pitch dan Yaw penempatan pin baru.
                </p>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-[#E4E9DA] text-[#234B24]">
                  Tipe: {activeScene.type === 'aerial' ? 'Aerial Drone View' : 'Ground Level'}
                </span>
                {activeScene.ambient_audio_url && (
                  <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-[#C7D2FE] text-[#4F46E5] flex items-center gap-1">
                    <Music className="w-3 h-3" aria-hidden="true" />
                    <span>Audio Aktif</span>
                  </span>
                )}
              </div>
            </div>

            {/* Kanvas Interaktif */}
            <div
              className="relative w-full aspect-[2/1] rounded-2xl overflow-hidden bg-black/90 cursor-crosshair border-2 border-[#234B24]/40 shadow-inner select-none group"
              onClick={handleCanvasClick}
              role="region"
              aria-label="Kanvas Interaktif Panorama 360"
            >
              {/* Gambar Panorama Equirectangular */}
              <img
                src={activeScene.panorama_url}
                alt={activeScene.title}
                className="w-full h-full object-cover transition-opacity duration-300"
              />

              {/* Grid Garis Bantu Visual Equirectangular */}
              <div
                className="absolute inset-0 pointer-events-none opacity-25 grid grid-cols-12 grid-rows-6 border border-white/20"
                aria-hidden="true"
              >
                {Array.from({ length: 72 }).map((_, i) => (
                  <div key={i} className="border-r border-b border-white/20" />
                ))}
              </div>

              {/* Tanda Sumbu Pitch = 0 (Khatulistiwa Pandangan) */}
              <div
                className="absolute left-0 right-0 top-1/2 -translate-y-1/2 border-t border-dashed border-[#F26B4B]/60 pointer-events-none"
                aria-hidden="true"
              >
                <span className="absolute left-2 -top-4 text-[9px] font-bold text-white bg-black/60 px-1.5 py-0.5 rounded">
                  Pitch 0° (Horizon)
                </span>
              </div>

              {/* Render Semua Hotspot Pins yang ada di scene */}
              {sceneHotspots.map((pin) => {
                const meta = getCategoryMeta(pin.category);
                // Hitung posisi persen dari Pitch (-90 s.d 90) & Yaw (-180 s.d 180)
                const leftPercent = ((pin.yaw + 180) / 360) * 100;
                const topPercent = ((90 - pin.pitch) / 180) * 100;
                const isSelected = selectedPin?.id === pin.id;

                return (
                  <button
                    key={pin.id}
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      setSelectedPin(pin);
                    }}
                    style={{
                      left: `${leftPercent}%`,
                      top: `${topPercent}%`,
                      backgroundColor: meta.color,
                    }}
                    className={`absolute -translate-x-1/2 -translate-y-1/2 w-8 h-8 rounded-full text-white shadow-lg flex items-center justify-center transition-all transform hover:scale-125 focus:outline-none focus:ring-4 focus:ring-white ${
                      isSelected
                        ? 'ring-4 ring-white scale-125 z-30 animate-bounce'
                        : 'z-20 hover:z-30'
                    }`}
                    title={`${pin.title} (${meta.label})`}
                    aria-label={`Pin: ${pin.title}`}
                  >
                    {meta.icon}
                  </button>
                );
              })}

              {/* Indikator Crosshair Hasil Klik Pengguna */}
              {clickedCoord && (
                <div
                  style={{
                    left: `${clickedCoord.xPercent}%`,
                    top: `${clickedCoord.yPercent}%`,
                  }}
                  className="absolute -translate-x-1/2 -translate-y-1/2 pointer-events-none z-40 flex items-center justify-center"
                >
                  <div className="w-10 h-10 rounded-full border-2 border-[#F26B4B] animate-ping" />
                  <div className="absolute w-5 h-5 rounded-full bg-[#F26B4B] text-white flex items-center justify-center shadow-md">
                    <Crosshair className="w-3.5 h-3.5" aria-hidden="true" />
                  </div>
                  <div className="absolute top-7 left-1/2 -translate-x-1/2 bg-black/85 text-white text-[10px] font-bold px-2 py-0.5 rounded shadow whitespace-nowrap">
                    P: {clickedCoord.pitch}° | Y: {clickedCoord.yaw}°
                  </div>
                </div>
              )}
            </div>

            {/* Bilah Aksi Koordinat Klik */}
            <div className="p-4 rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shrink-0">
                  <Crosshair className="w-5 h-5" aria-hidden="true" />
                </div>
                <div>
                  <div className="text-xs font-extrabold text-[#1B1F1A]">
                    {clickedCoord ? (
                      <span>
                        Titik Dipilih — Pitch:{' '}
                        <strong className="text-[#F26B4B]">
                          {clickedCoord.pitch}°
                        </strong>{' '}
                        | Yaw:{' '}
                        <strong className="text-[#234B24]">
                          {clickedCoord.yaw}°
                        </strong>
                      </span>
                    ) : (
                      <span>Klik di atas kanvas panorama untuk menaruh pin</span>
                    )}
                  </div>
                  <p className="text-[11px] text-[#4A5248]">
                    Koordinat sudut bola equirectangular otomatis dikonversi ke derajat navigasi.
                  </p>
                </div>
              </div>

              <button
                type="button"
                onClick={handleOpenAddPinFromCanvas}
                disabled={!clickedCoord}
                className="min-h-[44px] px-4 py-2 rounded-xl bg-[#F26B4B] hover:bg-[#D95637] disabled:opacity-50 text-white font-bold text-xs flex items-center justify-center gap-2 shadow-sm transition"
              >
                <Plus className="w-4 h-4" aria-hidden="true" />
                <span>Tempel Pin di Titik Ini</span>
              </button>
            </div>

            {/* Kartu Pratinjau Pin Terpilih */}
            {selectedPin && (
              <div className="p-4 rounded-2xl bg-[#E4E9DA]/70 border border-[#CFD8BE] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                <div className="flex items-start gap-3 min-w-0">
                  <div
                    style={{
                      backgroundColor: getCategoryMeta(selectedPin.category).bg,
                      color: getCategoryMeta(selectedPin.category).color,
                    }}
                    className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 border border-current"
                  >
                    {getCategoryMeta(selectedPin.category).icon}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-[11px] font-bold px-2 py-0.5 rounded-full bg-white text-[#234B24]">
                        {getCategoryMeta(selectedPin.category).label}
                      </span>
                      <span className="text-[11px] text-[#4A5248]">
                        Pitch: {selectedPin.pitch}° · Yaw: {selectedPin.yaw}°
                      </span>
                    </div>
                    <h3 className="text-sm font-extrabold text-[#1B1F1A] mt-1 truncate">
                      {selectedPin.title}
                    </h3>
                    <p className="text-xs text-[#4A5248] line-clamp-2 mt-0.5">
                      {selectedPin.description || 'Tidak ada deskripsi rinci.'}
                    </p>
                    {selectedPin.partner_name && (
                      <div className="text-xs font-bold text-[#F26B4B] mt-1">
                        Mitra: {selectedPin.partner_name} · Tarif: Rp{' '}
                        {(selectedPin.partner_fee || 0).toLocaleString('id-ID')}
                      </div>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-2 shrink-0 self-end sm:self-center">
                  <button
                    type="button"
                    onClick={() => handleOpenEditPin(selectedPin)}
                    className="min-h-[38px] px-3 py-1.5 rounded-lg bg-white hover:bg-gray-50 text-[#1B1F1A] font-bold text-xs flex items-center gap-1 border border-[#CFD8BE] shadow-xs"
                  >
                    <Edit3 className="w-3.5 h-3.5 text-[#234B24]" aria-hidden="true" />
                    <span>Edit</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDeletePin(selectedPin.id)}
                    className="min-h-[38px] px-3 py-1.5 rounded-lg bg-[#F26B4B]/15 hover:bg-[#F26B4B]/25 text-[#D95637] font-bold text-xs flex items-center gap-1"
                  >
                    <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>Hapus</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPin(null)}
                    className="min-h-[38px] p-2 rounded-lg text-[#767676] hover:bg-black/5"
                    aria-label="Tutup pratinjau pin"
                  >
                    <X className="w-4 h-4" aria-hidden="true" />
                  </button>
                </div>
              </div>
            )}
          </section>

          {/* Sisi Kanan: Daftar 4 Kategori Hotspot Pin & Manajemen (4 Kolom) */}
          <aside className="lg:col-span-4 bg-white rounded-[24px] p-5 lg:p-6 shadow-sm border border-[#E4E9DA] space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-sm font-extrabold text-[#1B1F1A] flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-[#F26B4B]" aria-hidden="true" />
                  <span>Daftar Pin Hotspot ({sceneHotspots.length})</span>
                </h2>
                <p className="text-[11px] text-[#4A5248]">
                  4 kategori pin interaktif dalam scene ini
                </p>
              </div>

              <button
                type="button"
                onClick={() => {
                  setClickedCoord(null);
                  handleOpenAddPinFromCanvas();
                }}
                className="min-h-[36px] px-3 py-1 rounded-lg bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-xs flex items-center gap-1 shadow-xs"
              >
                <Plus className="w-3.5 h-3.5" aria-hidden="true" />
                <span>+ Pin</span>
              </button>
            </div>

            {/* Filter Kategori Pin */}
            <div className="flex flex-wrap gap-1.5">
              {[
                { id: 'all', label: 'Semua' },
                { id: 'info_adat', label: 'Info Adat' },
                { id: 'navigasi', label: 'Navigasi' },
                { id: 'audio_budaya', label: 'Audio' },
                { id: 'mitra_umkm', label: 'Mitra UMKM' },
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

            {/* Daftar Pin Card */}
            <div className="space-y-2.5 max-h-[520px] overflow-y-auto pr-1">
              {filteredHotspots.length === 0 ? (
                <div className="p-6 text-center rounded-2xl bg-[#F6F3EC] border border-[#CFD8BE]">
                  <Crosshair className="w-8 h-8 text-[#767676] mx-auto mb-2" aria-hidden="true" />
                  <p className="text-xs font-bold text-[#1B1F1A]">
                    Belum ada pin untuk kategori ini
                  </p>
                  <p className="text-[11px] text-[#4A5248] mt-1">
                    Klik di atas kanvas panorama untuk menaruh pin baru.
                  </p>
                </div>
              ) : (
                filteredHotspots.map((pin) => {
                  const meta = getCategoryMeta(pin.category);
                  const isSelected = selectedPin?.id === pin.id;

                  return (
                    <div
                      key={pin.id}
                      onClick={() => setSelectedPin(pin)}
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
                          P:{pin.pitch}° Y:{pin.yaw}°
                        </span>
                      </div>

                      <h3 className="text-xs font-extrabold text-[#1B1F1A] mt-2 line-clamp-1">
                        {pin.title}
                      </h3>
                      {pin.description && (
                        <p className="text-[11px] text-[#4A5248] line-clamp-2 mt-0.5">
                          {pin.description}
                        </p>
                      )}

                      {pin.target_scene_id && (
                        <div className="mt-2 text-[10px] font-bold text-[#1D4ED8] flex items-center gap-1">
                          <ArrowRight className="w-3 h-3" aria-hidden="true" />
                          <span>Menuju Scene: {pin.target_scene_id}</span>
                        </div>
                      )}

                      {pin.partner_name && (
                        <div className="mt-2 text-[10px] font-bold text-[#C2410C]">
                          Mitra: {pin.partner_name} (Rp{' '}
                          {(pin.partner_fee || 0).toLocaleString('id-ID')})
                        </div>
                      )}

                      <div className="mt-2.5 pt-2 border-t border-black/5 flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleOpenEditPin(pin);
                          }}
                          className="px-2.5 py-1 rounded-md text-[11px] font-bold bg-white text-[#234B24] hover:bg-gray-100 border border-[#CFD8BE]"
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
          <Camera className="w-12 h-12 text-[#234B24] mx-auto mb-3" aria-hidden="true" />
          <h2 className="text-lg font-extrabold text-[#1B1F1A]">
            Belum Ada Scene Panorama 360° untuk {selectedDestination?.name}
          </h2>
          <p className="text-xs text-[#4A5248] max-w-md mx-auto mt-1 mb-5">
            Tambahkan scene panorama aerial atau ground level pertama untuk mulai menempelkan titik-titik pin interaktif budaya Minang.
          </p>
          <button
            type="button"
            onClick={handleOpenAddScene}
            className="min-h-[48px] px-6 py-2.5 rounded-pill bg-[#234B24] hover:bg-[#1B3B1C] text-[#F6F3EC] font-bold text-sm inline-flex items-center gap-2 shadow-md"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            <span>Tambah Scene Panorama 360° Baru</span>
          </button>
        </div>
      )}

      {/* Modal Tambah/Edit Scene Panorama */}
      {isSceneModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="scene-modal-title"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#234B24] text-[#F6F3EC] flex items-center justify-center shadow-xs">
                  <Camera className="w-5 h-5" aria-hidden="true" />
                </div>
                <div>
                  <h3
                    id="scene-modal-title"
                    className="text-base font-extrabold text-[#1B1F1A]"
                  >
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
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <form onSubmit={handleSaveScene} className="mt-5 space-y-4">
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

              <div>
                <label
                  htmlFor={scenePanoUrlId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  URL Gambar Panorama Equirectangular 360° <span className="text-[#F26B4B]">*</span>
                </label>
                <input
                  id={scenePanoUrlId}
                  type="url"
                  value={sceneFormPanoUrl}
                  onChange={(e) => setSceneFormPanoUrl(e.target.value)}
                  placeholder="https://images.unsplash.com/... atau URL CDN"
                  required
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div>
                <label
                  htmlFor={sceneAudioUrlId}
                  className="block text-xs font-bold text-[#1B1F1A] mb-1"
                >
                  URL Audio Suasana Latar (Spatial Ambient Audio, Opsional)
                </label>
                <input
                  id={sceneAudioUrlId}
                  type="url"
                  value={sceneFormAudioUrl}
                  onChange={(e) => setSceneFormAudioUrl(e.target.value)}
                  placeholder="https://cdn.rancak.in/audio/ambient_nature.mp3"
                  className="w-full min-h-[44px] px-3.5 py-2 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label
                    htmlFor={sceneInitPitchId}
                    className="block text-xs font-bold text-[#1B1F1A] mb-1"
                  >
                    Sudut Awal Pitch (-90° s.d 90°)
                  </label>
                  <input
                    id={sceneInitPitchId}
                    type="number"
                    min={-90}
                    max={90}
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

              <div className="pt-4 flex items-center justify-end gap-2.5">
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
                  <Save className="w-4 h-4" aria-hidden="true" />
                  <span>Simpan Scene Panorama</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Tambah/Edit Hotspot Pin */}
      {isPinModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="pin-modal-title"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs"
        >
          <div className="bg-white rounded-[28px] w-full max-w-lg p-6 lg:p-7 shadow-2xl border border-[#E4E9DA] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-[#E4E9DA]">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-[#F26B4B] text-white flex items-center justify-center shadow-xs">
                  <Sparkles className="w-5 h-5" aria-hidden="true" />
                </div>
                <div>
                  <h3
                    id="pin-modal-title"
                    className="text-base font-extrabold text-[#1B1F1A]"
                  >
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
                <X className="w-5 h-5" aria-hidden="true" />
              </button>
            </div>

            <form onSubmit={handleSavePin} className="mt-5 space-y-4">
              {/* Kategori Pin */}
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
                    Info Adat &amp; Sejarah (Warna Kuning Emas)
                  </option>
                  <option value="navigasi">
                    Navigasi Pindah Scene (Warna Biru Langit)
                  </option>
                  <option value="audio_budaya">
                    Audio Narasi Budaya / Minang (Warna Ungu Indigo)
                  </option>
                  <option value="mitra_umkm">
                    Katalog Mitra UMKM Nagari (Warna Koral Oranye)
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
                  placeholder="Tuliskan cerita sejarah, filosofi adat Minangkabau, atau panduan singkat..."
                  className="w-full p-3 rounded-xl bg-[#F6F3EC] border border-[#CFD8BE] text-xs font-medium text-[#1B1F1A]"
                />
              </div>

              {/* Bidang Khusus per Kategori */}
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

              {pinFormCategory === 'audio_budaya' && (
                <div className="p-3.5 rounded-xl bg-[#C7D2FE]/30 border border-[#A5B4FC]">
                  <label
                    htmlFor={pinAudioUrlId}
                    className="block text-xs font-bold text-[#4F46E5] mb-1"
                  >
                    URL Audio Budaya / Minang (MP3/WAV)
                  </label>
                  <input
                    id={pinAudioUrlId}
                    type="url"
                    value={pinFormAudioUrl}
                    onChange={(e) => setPinFormAudioUrl(e.target.value)}
                    placeholder="https://cdn.rancak.in/audio/saluang_minang.mp3"
                    className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#A5B4FC] text-xs font-medium text-[#1B1F1A]"
                  />
                </div>
              )}

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
                      placeholder="Contoh: Pondok Kawa Pokdarwis Sarasah"
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
                      placeholder="15000"
                      className="w-full min-h-[40px] px-3 py-1.5 rounded-lg bg-white border border-[#FDBA74] text-xs font-medium text-[#1B1F1A]"
                    />
                  </div>
                </div>
              )}

              {/* Koordinat Posisi Pitch & Yaw */}
              <div className="grid grid-cols-2 gap-3 pt-1">
                <div>
                  <label
                    htmlFor={pinPitchId}
                    className="block text-xs font-bold text-[#1B1F1A] mb-1"
                  >
                    Koordinat Pitch (-90° s.d 90°)
                  </label>
                  <input
                    id={pinPitchId}
                    type="number"
                    min={-90}
                    max={90}
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
                  <Save className="w-4 h-4" aria-hidden="true" />
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
