package middleware

import (
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/LuthfiaHasan/WISGO/backend/internal/common"
)

// ClientBucket menyimpan kuota token bucket per IP/Device
type ClientBucket struct {
	Tokens     int
	LastRefill time.Time
}

// TokenBucketRateLimiter melindungi endpoint sensitif terhadap spam request
type TokenBucketRateLimiter struct {
	mu           sync.Mutex
	buckets      map[string]*ClientBucket
	maxBurst     int
	refillWindow time.Duration
	blockedCount int
}

// NewTokenBucketRateLimiter membuat rate limiter baru
func NewTokenBucketRateLimiter(maxBurst int, refillWindow time.Duration) *TokenBucketRateLimiter {
	return &TokenBucketRateLimiter{
		buckets:      make(map[string]*ClientBucket),
		maxBurst:     maxBurst,
		refillWindow: refillWindow,
	}
}

// Protect adalah alias RateLimit untuk kompatibilitas handler
func (rl *TokenBucketRateLimiter) Protect(endpointScope string) gin.HandlerFunc {
	return rl.RateLimit(endpointScope)
}

// RateLimit Gin middleware pembungkus dengan proteksi Token Bucket
func (rl *TokenBucketRateLimiter) RateLimit(endpointScope string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "SAMEORIGIN")
		c.Header("X-RateLimit-Limit", fmt.Sprintf("%d", rl.maxBurst))

		// Mode simulasi eksplisit untuk automated test & QA
		if strings.EqualFold(c.GetHeader("X-Simulate-RateLimit"), "burst") ||
			strings.EqualFold(c.Query("simulate_ratelimit"), "true") {
			rl.mu.Lock()
			rl.blockedCount++
			rl.mu.Unlock()

			c.Header("X-RateLimit-Remaining", "0")
			c.Header("Retry-After", "60")
			common.Error(c, http.StatusTooManyRequests, fmt.Sprintf("Terlalu banyak permintaan ke endpoint %s dalam waktu singkat (Anti-Spam Token Bucket). Silakan coba lagi dalam 60 detik.", endpointScope), gin.H{
				"code":                "RATE_LIMIT_EXCEEDED",
				"scope":               endpointScope,
				"retry_after_seconds": 60,
			})
			c.Abort()
			return
		}

		clientIP := c.ClientIP()
		if clientIP == "" {
			clientIP = "127.0.0.1"
		}
		clientKey := fmt.Sprintf("%s:%s", endpointScope, clientIP)
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

			c.Header("X-RateLimit-Remaining", "0")
			c.Header("Retry-After", "60")
			common.Error(c, http.StatusTooManyRequests, "Batas frekuensi pengiriman laporan/sinyal terlampaui. Tunggu 60 detik.", gin.H{
				"code":                "RATE_LIMIT_EXCEEDED",
				"scope":               endpointScope,
				"retry_after_seconds": 60,
			})
			c.Abort()
			return
		}

		bucket.Tokens--
		remaining := bucket.Tokens
		rl.mu.Unlock()

		c.Header("X-RateLimit-Remaining", fmt.Sprintf("%d", remaining))
		c.Next()
	}
}

// Stats mengembalikan statistik operasional rate limiter
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
