/**
 * Helper Parser & Formatter Koordinat PostGIS 3.4 Geography Point (WGS84)
 * Format standar: "SRID=4326;POINT(longitude latitude)" atau "POINT(longitude latitude)"
 */

export interface LatLng {
  latitude: number;
  longitude: number;
}

/**
 * Format latitude & longitude menjadi PostGIS WKT Point
 */
export function formatPointGeog(latitude: number, longitude: number): string {
  return `SRID=4326;POINT(${longitude.toFixed(6)} ${latitude.toFixed(6)})`;
}

/**
 * Parse PostGIS WKT Point string menjadi { latitude, longitude }
 */
export function parsePointGeog(geog: string | null | undefined): LatLng | null {
  if (!geog || typeof geog !== 'string') return null;

  // Tangani format SRID=4326;POINT(lng lat) atau POINT(lng lat)
  const pointMatch = geog.match(/POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)/i);
  if (!pointMatch) return null;

  const longitude = parseFloat(pointMatch[1]);
  const latitude = parseFloat(pointMatch[2]);

  if (isNaN(latitude) || isNaN(longitude)) return null;

  return { latitude, longitude };
}

/**
 * Format string display untuk UI: "-0.949240, 100.354270"
 */
export function formatLatLngDisplay(latitude?: number, longitude?: number): string {
  if (typeof latitude !== 'number' || typeof longitude !== 'number') return '-';
  return `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
}
