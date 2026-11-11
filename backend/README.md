# Rancak.in Backend API (Go Gin + PostgreSQL / PostGIS)

Backend service untuk **Ekosistem Wisata Pintar Sumatera Barat (Rancak.in)**.

## Pembagian Kerja Backend (Zero Merge Conflict)
- **BE-1 (Core & Spasial)**:
  - Direktori: `internal/be1_core/`
  - Tanggung Jawab: CRUD Destinasi, 4 Statistik & 5 Indikator Medan, Tur 360 & 4 Pin, Spasial Koridor Rute *Shunlu* (+X mnt detour), Peta Mikro, TSP Optimizer, Gaode Guide Ranking, Lapor Pungli, Alert Jalur Ekstrem (Sitinjau Lauik, dll), & SOS GPS.
- **BE-2 (Grup, Mitra, Escrow & Gamifikasi)**:
  - Direktori: `internal/be2_group/`
  - Tanggung Jawab: Auth OTP 4 Kotak, Itinerary 7 Hari, Auto-Itinerary Generator, Private Group Room & Live Voting, Split-Bill, Group Live Radar, Katalog 5 Mitra Nagari, Engine Quick Booking & Ledger Escrow (QRIS & DuitNow MYR), Simulator Bot WA (1=Terima / 0=Tolak), Validasi GPS ≤200m (Anti-Fake GPS), & Generator Sertifikat Gubernur.

## Menjalankan Server
```bash
cd backend
go run cmd/api/main.go
```
Endpoint Health Check: `http://localhost:8080/health`
Prefix API: `http://localhost:8080/api/v1/...`

