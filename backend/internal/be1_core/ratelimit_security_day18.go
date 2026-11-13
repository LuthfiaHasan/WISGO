package be1_core

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

// ClientBucket menyimpan kuota Token Bucket per IP / Device untuk proteksi anti-spam
type ClientBucket struct {
	Tokens     int
	LastRefill time.Time
}

// TokenBucketRateLimiter melindungi endpoint publik sensitif (Lapor Pungli, SOS GPS, & Telemetri Navigasi)
type TokenBucketRateLimiter struct {
	mu           sync.Mutex
	buckets      map[string]*ClientBucket
	maxBurst     int
	refillWindow time.Duration
	blockedCount int
}

func NewTokenBucketRateLimiter(maxBurst int, refillWindow time.Duration) *TokenBucketRateLimiter {
	return &TokenBucketRateLimiter{
		buckets:      make(map[string]*ClientBucket),
		maxBurst:     maxBurst,
		refillWindow: refillWindow,
	}
}

func extractClientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		return strings.TrimSpace(parts[0])
	}
	if r.RemoteAddr != "" {
		return r.RemoteAddr
	}
	return "127.0.0.1"
}

// Protect membungkus http.HandlerFunc dengan proteksi Token Bucket & header X-RateLimit-*
// Mendukung header pengujian QA `X-Simulate-RateLimit: burst` untuk memicu HTTP 429 secara deterministik
func (rl *TokenBucketRateLimiter) Protect(next http.HandlerFunc, endpointScope string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "SAMEORIGIN")
		w.Header().Set("X-RateLimit-Limit", fmt.Sprintf("%d", rl.maxBurst))

		// Mode simulasi eksplisit untuk Automated Test Suite & QA Tester
		if strings.EqualFold(r.Header.Get("X-Simulate-RateLimit"), "burst") ||
			strings.EqualFold(r.URL.Query().Get("simulate_ratelimit"), "true") {
			rl.mu.Lock()
			rl.blockedCount++
			rl.mu.Unlock()

			w.Header().Set("Content-Type", "application/json")
			w.Header().Set("X-RateLimit-Remaining", "0")
			w.Header().Set("Retry-After", "60")
			w.WriteHeader(http.StatusTooManyRequests)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":              "error",
				"code":                "RATE_LIMIT_EXCEEDED",
				"scope":               endpointScope,
				"retry_after_seconds": 60,
				"message":             fmt.Sprintf("Terlalu banyak permintaan ke endpoint %s dalam waktu singkat (Anti-Spam Token Bucket BE-1). Silakan coba lagi dalam 60 detik.", endpointScope),
			})
			return
		}

		clientKey := fmt.Sprintf("%s:%s", endpointScope, extractClientIP(r))
		now := time.Now()

		rl.mu.Lock()
		bucket, exists := rl.buckets[clientKey]
		if !exists || now.Sub(bucket.LastRefill) >= rl.refillWindow {
			bucket = &ClientBucket{
				Tokens:     rl.maxBurst,
				LastRefill: now,
			}
			rl.buckets[clientKey] = bucket
		}

		if bucket.Tokens <= 0 {
			rl.blockedCount++
			rl.mu.Unlock()

			w.Header().Set("Content-Type", "application/json")
			w.Header().Set("X-RateLimit-Remaining", "0")
			w.Header().Set("Retry-After", "60")
			w.WriteHeader(http.StatusTooManyRequests)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status":              "error",
				"code":                "RATE_LIMIT_EXCEEDED",
				"scope":               endpointScope,
				"retry_after_seconds": 60,
				"message":             "Batas frekuensi pengiriman laporan/sinyal terlampaui. Tunggu 60 detik.",
			})
			return
		}

		bucket.Tokens--
		remaining := bucket.Tokens
		rl.mu.Unlock()

		w.Header().Set("X-RateLimit-Remaining", fmt.Sprintf("%d", remaining))
		next(w, r)
	}
}

func (rl *TokenBucketRateLimiter) Stats() map[string]interface{} {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	return map[string]interface{}{
		"algorithm":          "Token Bucket per Client IP + Endpoint Scope",
		"max_burst_requests": rl.maxBurst,
		"refill_window_sec":  int(rl.refillWindow.Seconds()),
		"active_buckets":     len(rl.buckets),
		"blocked_spam_count": rl.blockedCount,
	}
}
