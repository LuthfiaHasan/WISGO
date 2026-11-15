package middleware

import (
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gin-gonic/gin"
)

// CacheEntry menyimpan payload JSON ter-serialisasi beserta ETag dan TTL
type CacheEntry struct {
	Payload   []byte
	ETag      string
	ExpiresAt time.Time
	CreatedAt time.Time
}

// InMemoryTTLCache lapisan caching in-memory ultra-cepat (<5ms)
type InMemoryTTLCache struct {
	mu         sync.RWMutex
	entries    map[string]CacheEntry
	defaultTTL time.Duration
	hitCount   uint64
	missCount  uint64
	flushedAt  time.Time
}

// NewInMemoryTTLCache membuat cache in-memory baru
func NewInMemoryTTLCache(defaultTTL time.Duration) *InMemoryTTLCache {
	return &InMemoryTTLCache{
		entries:    make(map[string]CacheEntry),
		defaultTTL: defaultTTL,
		flushedAt:  time.Now(),
	}
}

func computeETag(payload []byte) string {
	sum := sha1.Sum(payload)
	return fmt.Sprintf(`W/"rancak-be1-%s"`, hex.EncodeToString(sum[:8]))
}

// Get mengambil entri dari cache jika belum kedaluwarsa
func (c *InMemoryTTLCache) Get(key string) (CacheEntry, bool) {
	c.mu.RLock()
	entry, exists := c.entries[key]
	c.mu.RUnlock()

	if !exists || time.Now().After(entry.ExpiresAt) {
		atomic.AddUint64(&c.missCount, 1)
		return CacheEntry{}, false
	}
	atomic.AddUint64(&c.hitCount, 1)
	return entry, true
}

// Set menyimpan respons data ke dalam cache beserta nilai ETag otomatis
func (c *InMemoryTTLCache) Set(key string, data interface{}) (CacheEntry, error) {
	raw, err := json.Marshal(data)
	if err != nil {
		return CacheEntry{}, err
	}
	now := time.Now()
	entry := CacheEntry{
		Payload:   raw,
		ETag:      computeETag(raw),
		ExpiresAt: now.Add(c.defaultTTL),
		CreatedAt: now,
	}
	c.mu.Lock()
	c.entries[key] = entry
	c.mu.Unlock()
	return entry, nil
}

// FlushAll mengosongkan seluruh entri cache
func (c *InMemoryTTLCache) FlushAll() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	removed := len(c.entries)
	c.entries = make(map[string]CacheEntry)
	c.flushedAt = time.Now()
	return removed
}

// Stats mengembalikan statistik performa cache
func (c *InMemoryTTLCache) Stats() map[string]interface{} {
	c.mu.RLock()
	activeKeys := len(c.entries)
	flushedAt := c.flushedAt
	c.mu.RUnlock()

	hits := atomic.LoadUint64(&c.hitCount)
	misses := atomic.LoadUint64(&c.missCount)
	total := hits + misses
	hitRatioPct := 0.0
	if total > 0 {
		hitRatioPct = float64(hits) / float64(total) * 100.0
	}

	return map[string]interface{}{
		"engine":          "Go Native InMemoryTTLCache + HTTP ETag (Zero Redis Dependency)",
		"default_ttl_sec": int(c.defaultTTL.Seconds()),
		"active_keys":     activeKeys,
		"cache_hits":      hits,
		"cache_misses":    misses,
		"hit_ratio_pct":   fmt.Sprintf("%.1f%%", hitRatioPct),
		"last_flushed_at": flushedAt.Format(time.RFC3339),
	}
}

// WriteCachedJSON menulis respon JSON dengan header X-Cache (HIT/MISS), ETag, dan HTTP 304 Not Modified pada Gin
func (c *InMemoryTTLCache) WriteCachedJSON(ctx *gin.Context, cacheKey string, computeFn func() (interface{}, int, error)) {
	ctx.Header("Content-Type", "application/json")
	ctx.Header("Cache-Control", fmt.Sprintf("public, max-age=%d", int(c.defaultTTL.Seconds())))

	if entry, hit := c.Get(cacheKey); hit {
		ctx.Header("X-Cache", "HIT")
		ctx.Header("ETag", entry.ETag)

		if clientETag := ctx.GetHeader("If-None-Match"); clientETag != "" && clientETag == entry.ETag {
			ctx.Status(http.StatusNotModified)
			return
		}

		ctx.Data(http.StatusOK, "application/json", entry.Payload)
		return
	}

	data, statusCode, err := computeFn()
	if err != nil || statusCode >= 400 {
		ctx.Header("X-Cache", "BYPASS")
		ctx.JSON(statusCode, data)
		return
	}

	entry, err := c.Set(cacheKey, data)
	if err != nil {
		ctx.Status(http.StatusInternalServerError)
		return
	}

	ctx.Header("X-Cache", "MISS")
	ctx.Header("ETag", entry.ETag)
	ctx.Data(statusCode, "application/json", entry.Payload)
}
