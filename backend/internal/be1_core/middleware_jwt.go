package be1_core

import (
	"encoding/json"
	"net/http"
	"strings"
)

// Preset Token JWT Bersama untuk Pengujian Sprint 1 (BE-1, BE-2, FE-1, FE-2, FS-1)
// Menggunakan secret default dari internal/config: "wisgo-rancak-in-secret-key-2026"
const (
	TokenAdminDispar = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLWFkbWluLWRpc3Bhci0wMSIsIm5hbWUiOiJBZG1pbiBEaXNwYXIgU3VtYmFyIChGUy0xKSIsInJvbGUiOiJhZG1pbl9kaXNwYXIifQ.rancakin_sig_admin"
	TokenPokdarwis   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXBva2Rhcndpcy0wMSIsIm5hbWUiOiJVZGEgWnVsIChQb2tkYXJ3aXMgTmFnYXJpKSIsInJvbGUiOiJwb2tkYXJ3aXMifQ.rancakin_sig_pokdarwis"
	TokenTourist     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLXRvdXJpc3QtMDEiLCJuYW1lIjoiUml6a3kgUHJhdGFtYSAoV2lzYXRhd2FuKSIsInJvbGUiOiJ0b3VyaXN0In0.rancakin_sig_tourist"
)

var validTokenRoles = map[string]string{
	TokenAdminDispar: "admin_dispar",
	TokenPokdarwis:   "pokdarwis",
	TokenTourist:     "tourist",
}

// RequireRoles memproteksi endpoint CMS Admin milik BE-1 (POST/PUT/DELETE /api/v1/destinations)
// secara stateless tanpa menyentuh tabel users milik BE-2.
func RequireRoles(next http.HandlerFunc, allowedRoles ...string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			w.WriteHeader(http.StatusUnauthorized)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  "error",
				"code":    "UNAUTHORIZED_MISSING_TOKEN",
				"message": "Header Authorization Bearer token wajib disertakan untuk operasi Admin CMS.",
			})
			return
		}

		token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		role, exists := validTokenRoles[token]
		if !exists {
			w.WriteHeader(http.StatusUnauthorized)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  "error",
				"code":    "UNAUTHORIZED_INVALID_TOKEN",
				"message": "Token JWT tidak valid atau tidak dikenali oleh server WISGO.",
			})
			return
		}

		allowed := false
		for _, allowedRole := range allowedRoles {
			if role == allowedRole {
				allowed = true
				break
			}
		}

		if !allowed {
			w.WriteHeader(http.StatusForbidden)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":         "error",
				"code":           "FORBIDDEN_INSUFFICIENT_ROLE",
				"message":        "Akses ditolak: Role Anda tidak memiliki izin untuk mengubah data destinasi CMS.",
				"current_role":   role,
				"required_roles": allowedRoles,
			})
			return
		}

		next(w, r)
	}
}
