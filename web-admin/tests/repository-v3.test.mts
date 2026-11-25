import test from 'node:test';
import assert from 'node:assert/strict';

// In-memory localStorage mock before importing repositories
const store = new Map<string, string>();
(globalThis as Record<string, unknown>).localStorage = {
  getItem: (k: string) => (store.has(k) ? store.get(k)! : null),
  setItem: (k: string, v: string) => {
    store.set(k, String(v));
  },
  removeItem: (k: string) => {
    store.delete(k);
  },
  clear: () => {
    store.clear();
  },
  get length() {
    return store.size;
  },
  key: (idx: number) => Array.from(store.keys())[idx] ?? null,
};

// Seed legacy v2.1.0 + split-brain keys before loading dbRepository
store.set('wisgo_v2_db_version', '2.1.0');
store.set('wisgo_dispar_destinations_v2', JSON.stringify([{ id: 'legacy-1', category: 'Alam & Tebing', is_blank_spot: true }]));
store.set('wisgo_checklist_challenges', JSON.stringify([{ id: 'legacy-chl' }]));
store.set('wisgo_tourist_ugc_submissions', JSON.stringify([{ id: 'legacy-ugc' }]));

const repoMod = await import('../src/services/dbRepository.ts');
const destMod = await import('../src/data/mockDestinations.ts');
const dbSeedMod = await import('../src/data/mockDatabaseV2.ts');

test('1. V3 migration wipes legacy keys and seeds clean v3.0.0 data without Blank Spot', () => {
  assert.equal(store.get('wisgo_v2_db_version'), '3.0.0');
  assert.equal(store.get('wisgo_dispar_destinations_v2'), undefined);
  assert.equal(store.get('wisgo_checklist_challenges'), undefined);
  assert.equal(store.get('wisgo_tourist_ugc_submissions'), undefined);

  const destinations = repoMod.DestinationsRepo.getAll();
  assert.ok(destinations.length >= 20, 'Should seed at least 20 destinations');
  for (const d of destinations) {
    assert.equal((d as Record<string, unknown>).is_blank_spot, undefined, `${d.id} must not have is_blank_spot`);
    assert.equal(
      (d.medan_indicator as Record<string, unknown> | undefined)?.cellular_signal,
      undefined,
      `${d.id} medan_indicator must not have cellular_signal`
    );
  }
});

test('2. All 5 Master Categories, Lubuk Hitam (CHL-LBH-10), and fixed Kab. Solok exist in DestinationsRepo', () => {
  const destinations = repoMod.DestinationsRepo.getAll();
  const categories = new Set(destinations.map((d: { category?: string }) => d.category));
  for (const expected of ['Alam & Geopark', 'Budaya & Nagari', 'Hidden Gem', 'Religi', 'Kuliner']) {
    assert.ok(categories.has(expected), `Missing master category: ${expected}`);
  }
  assert.ok(
    destinations.some((d: { name: string }) => d.name.toLowerCase().includes('lubuk hitam')),
    'Missing Air Terjun Lubuk Hitam (CHL-LBH-10)'
  );
  const singkarak = destinations.find((d: { id: string }) => d.id === 'dest-007');
  assert.ok(singkarak, 'dest-007 should exist');
  assert.equal(singkarak.city_regency, 'Kab. Solok');
});

test('3. DestinationsRepo joins weather from WeatherMonitoringRepo, honors override, and syncs tips/aturan_destinasi', () => {
  const list = repoMod.DestinationsRepo.getAll();
  const first = list[0];
  assert.ok(first.weather && typeof first.weather.temperature_c === 'number', 'Destination must include joined weather');
  assert.ok(Array.isArray(first.tips) && first.tips.length > 0, 'Destination tips must be populated');
  assert.deepEqual(first.tips, first.aturan_destinasi, 'tips and aturan_destinasi must stay in sync');

  const updatedTips = [
    { id: 'tip-test-1', destination_id: first.id, title: 'Etika', content: 'Jaga kebersihan sungai.', is_important: true },
  ];
  repoMod.DestinationsRepo.save({
    ...first,
    weather_status: 'Waspada Hujan Lebat',
    tips: updatedTips,
  });
  const reloaded = repoMod.DestinationsRepo.getById(first.id);
  assert.equal(reloaded?.weather_status, 'Waspada Hujan Lebat');
  assert.equal(reloaded?.aturan_destinasi?.[0]?.content, 'Jaga kebersihan sungai.');
});

test('4. Partner category normalization maps legacy strings to 5 canonical FE-2 categories', () => {
  assert.equal(destMod.normalizePartnerCategory('Homestay Rumah Gadang'), 'Penginapan');
  assert.equal(destMod.normalizePartnerCategory('Kapal & Transportasi'), 'Transportasi');
  assert.equal(destMod.normalizePartnerCategory('Pemandu Pokdarwis'), 'Atraksi');
  assert.equal(destMod.normalizePartnerCategory('Sewa Baju Adat'), 'Pakaian Adat');
  assert.equal(destMod.normalizePartnerCategory('Kuliner Halal'), 'Kuliner');
  const partners = repoMod.PartnersRepo.getAll();
  assert.ok(partners.length >= 5);
  for (const p of partners) {
    assert.ok(
      ['Penginapan', 'Transportasi', 'Atraksi', 'Pakaian Adat', 'Kuliner'].includes(p.category),
      `Non-canonical partner category: ${p.category}`
    );
  }
});

test('5. Auto-category for Trip Go resolves accurately into 5 Master Categories', () => {
  assert.equal(destMod.determineCategoryForDestination('Lembah Harau'), 'Alam & Geopark');
  assert.equal(destMod.determineCategoryForDestination('Istano Basa Pagaruyung'), 'Budaya & Nagari');
  assert.equal(destMod.determineCategoryForDestination('Air Terjun Nyarai'), 'Hidden Gem');
  assert.equal(destMod.determineCategoryForDestination('Masjid Raya Sumatera Barat'), 'Religi');
  assert.equal(destMod.determineCategoryForDestination('Los Lambuang Nasi Kapau'), 'Kuliner');
  assert.equal(destMod.getCategorySvgPath('Alam & Geopark'), '/assets/synced/cat_alam_geopark.svg');
  assert.equal(destMod.getDenahSvgPath('UMKM'), '/assets/synced/denah_umkm.svg');
});

test('6. DenahPointsRepo supports CRUD for 5 canonical 2D map categories', () => {
  const before = repoMod.DenahPointsRepo.getByDestinationId('dest-001');
  assert.ok(before.length > 0, 'dest-001 should have seeded Denah 2D points');
  repoMod.DenahPointsRepo.save({
    id: 'dnh-test-99',
    destination_id: 'dest-001',
    category: 'UMKM',
    title: 'Kedai Kawa Uji',
    description: 'Test UMKM point',
    x: 42,
    y: 58,
  });
  assert.ok(repoMod.DenahPointsRepo.getByDestinationId('dest-001').some((p: { id: string }) => p.id === 'dnh-test-99'));
  repoMod.DenahPointsRepo.delete('dnh-test-99');
  assert.ok(!repoMod.DenahPointsRepo.getByDestinationId('dest-001').some((p: { id: string }) => p.id === 'dnh-test-99'));
});

test('7. Emergency contacts (6 real Sumbar), Hazard alerts (4 corridors), Pungli statuses, and Weather broadcast sync', () => {
  const contacts = repoMod.EmergencyContactsRepo.getAll();
  assert.equal(contacts.length, 6);
  assert.ok(contacts.some((c: { agency_name: string; phone_number: string }) => c.agency_name === 'BPBD Sumatera Barat' && c.phone_number === '(0751) 890721'));
  assert.ok(contacts.some((c: { agency_name: string; phone_number: string }) => c.agency_name === 'Damkar Bukittinggi' && c.phone_number === '085355157883'));

  const hazards = repoMod.HazardAlertsRepo.getAll();
  assert.equal(hazards.length, 4);
  for (const h of hazards) {
    assert.ok(['Normal', 'Waspada', 'Siaga', 'Awas Tutup Total'].includes(h.severity), `Invalid severity: ${h.severity}`);
  }

  const pungli = repoMod.PungliReportsRepo.getAll();
  for (const r of pungli) {
    assert.ok(['Masuk', 'Diverifikasi', 'Ditindaklanjuti', 'Selesai'].includes(r.status), `Invalid pungli status: ${r.status}`);
  }

  const weatherItems = repoMod.WeatherMonitoringRepo.getAll();
  const afterBroadcast = repoMod.WeatherMonitoringRepo.broadcastHazardAlert(weatherItems[0]);
  assert.ok(afterBroadcast.length >= 5, 'Broadcasting weather must persist into HazardAlertsRepo');
});

test('8. Adventurer level calculation matches FE-2 thresholds and Jejak WISGO drops sports km metric', () => {
  assert.deepEqual(destMod.calculateAdventurerLevel(0), { level: 1, name: 'Beginner' });
  assert.deepEqual(destMod.calculateAdventurerLevel(300), { level: 2, name: 'Explorer' });
  assert.deepEqual(destMod.calculateAdventurerLevel(700), { level: 3, name: 'Adventurer' });
  assert.deepEqual(destMod.calculateAdventurerLevel(1200), { level: 4, name: 'Trailblazer' });
  assert.deepEqual(destMod.calculateAdventurerLevel(2000), { level: 5, name: 'Wanderer' });

  const profiles = repoMod.UserProfilesRepo.getAll();
  assert.ok(profiles.length > 0);
  for (const p of profiles) {
    assert.equal((p as Record<string, unknown>).total_distance_km, undefined, 'Jejak WISGO must not contain total_distance_km');
    assert.ok(typeof p.visited_count === 'number', 'Jejak WISGO must track visited_count');
  }

  const levels = repoMod.AdventurerLevelsRepo.getAll();
  for (const lvl of levels) {
    assert.ok(!lvl.perk_description.includes('Geode'), 'Must fix Geode typo to Gaode');
  }
});

test('9. Heatmap codes unique (PPJ & PDP), Group Rooms valid, and System Benchmark complete', () => {
  const codes = dbSeedMod.SEED_REGENCY_HEATMAP.map((r: { code: string }) => r.code);
  assert.equal(new Set(codes).size, codes.length, 'Regency heatmap codes must be unique');
  assert.ok(codes.includes('PPJ') && codes.includes('PDP'));

  assert.ok(destMod.INITIAL_GROUP_ROOMS['WISGO-MINANG-88'], 'WISGO-MINANG-88 room must exist');
  assert.ok(destMod.INITIAL_GROUP_ROOMS['WISGO-HARAU-07'], 'WISGO-HARAU-07 room must exist');
  assert.ok(destMod.INITIAL_GROUP_ROOMS['WISGO-MANDEH-12'], 'WISGO-MANDEH-12 room must exist');

  const bm = destMod.INITIAL_SYSTEM_BENCHMARK;
  assert.equal(typeof bm.go_engine_latency_ms, 'number');
  assert.equal(typeof bm.postgres_spatial_query_ms, 'number');
  assert.equal(typeof bm.requests_per_second, 'number');
  assert.ok(Array.isArray(bm.benchmark_history) && bm.benchmark_history.length > 0);
});
