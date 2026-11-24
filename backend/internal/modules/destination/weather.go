package destination

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

type openMeteoResponse struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Elevation float64 `json:"elevation"`
	Current   struct {
		Time             string  `json:"time"`
		Temperature2m    float64 `json:"temperature_2m"`
		RelativeHumidity int     `json:"relative_humidity_2m"`
		WeatherCode      int     `json:"weather_code"`
		WindSpeed10m     float64 `json:"wind_speed_10m"`
	} `json:"current"`
	Hourly struct {
		Time                     []string `json:"time"`
		PrecipitationProbability []int    `json:"precipitation_probability"`
	} `json:"hourly"`
}

type weatherCacheItem struct {
	info      *models.WeatherInfo
	timestamp time.Time
}

var (
	weatherCacheMu sync.RWMutex
	weatherCache   = make(map[string]weatherCacheItem)
	// Timeout untuk pemanggilan Open-Meteo API agar non-blocking & responsif
	openMeteoClient = &http.Client{Timeout: 3 * time.Second}
)

const weatherCacheTTL = 10 * time.Minute

// GetCoordsForCity memetakan koordinat acuan kota/kabupaten di Sumatera Barat
func GetCoordsForCity(cityRegency string) (float64, float64) {
	c := strings.ToLower(strings.TrimSpace(cityRegency))
	switch {
	case strings.Contains(c, "padang panjang"):
		return -0.4638, 100.3989
	case strings.Contains(c, "tanah datar") || strings.Contains(c, "pagaruyung") || strings.Contains(c, "batusangkar"):
		return -0.4632, 100.3986
	case strings.Contains(c, "bukittinggi"):
		return -0.3051, 100.3692
	case strings.Contains(c, "agam") || strings.Contains(c, "maninjau") || strings.Contains(c, "lawang"):
		return -0.3055, 100.1989
	case strings.Contains(c, "lima puluh kota") || strings.Contains(c, "payakumbuh") || strings.Contains(c, "harau"):
		return -0.1023, 100.6728
	case strings.Contains(c, "pesisir selatan") || strings.Contains(c, "mandeh") || strings.Contains(c, "tarusan"):
		return -1.2015, 100.4220
	case strings.Contains(c, "solok"):
		return -0.7978, 100.6555
	case strings.Contains(c, "pariaman"):
		return -0.6812, 100.3915
	case strings.Contains(c, "sijunjung") || strings.Contains(c, "silokek"):
		return -0.6420, 100.9942
	case strings.Contains(c, "sawahlunto"):
		return -0.6784, 100.7788
	case strings.Contains(c, "mentawai"):
		return -1.9902, 99.5898
	case strings.Contains(c, "pasaman"):
		return 0.3845, 100.0465
	case strings.Contains(c, "dharmasraya"):
		return -0.9882, 101.3789
	default:
		// Kota Padang
		return -0.9471, 100.4172
	}
}

// MapWMOCodeToCondition menerjemahkan WMO Weather Interpretation Codes dari Open-Meteo
func MapWMOCodeToCondition(code int) (condition string, weatherStatus string, alertNote string) {
	switch code {
	case 0:
		return "Cerah", "Aman", "Langit cerah, visibilitas sangat baik untuk berwisata."
	case 1:
		return "Cerah Berawan", "Aman", "Kondisi cuaca baik dan kondusif untuk perjalanan."
	case 2:
		return "Berawan", "Aman", "Berawan sejuk, jalanan kering dan nyaman dilalui."
	case 3:
		return "Mendung Tebal", "Waspada", "Awan mendung tebal, siapkan payung atau jas hujan."
	case 45, 48:
		return "Berkabut Tebal", "Waspada", "Kabut mengurangi jarak pandang, nyalakan lampu kabut dan kurangi kecepatan."
	case 51, 53, 55:
		return "Gerimis", "Waspada", "Jalanan mulai basah, berhati-hati terhadap tikungan licin."
	case 56, 57:
		return "Gerimis Dingin", "Waspada", "Suhu udara dingin dan aspal basah."
	case 61:
		return "Hujan Ringan", "Waspada Hujan", "Hujan intensitas ringan, hindari memacu kendaraan kencang."
	case 63:
		return "Hujan Sedang", "Waspada Hujan", "Hujan sedang merata, waspada genangan air dan jalanan licin."
	case 65:
		return "Hujan Lebat", "Siaga Cuaca Ekstrem", "Hujan lebat, waspada potensi longsor tebing dan luapan air hulu."
	case 80, 81:
		return "Hujan Guyur Lokal", "Waspada Hujan", "Hujan lebat sesaat, berteduhlah di rest area terdekat."
	case 82:
		return "Hujan Sangat Lebat", "Awas Tutup Total", "Curah hujan ekstrem, tunda perjalanan melewati lereng rawan longsor."
	case 95:
		return "Hujan Badai Petir", "Siaga Cuaca Ekstrem", "Terjadi petir dan angin kencang, jauhi pohon besar dan tebing terjal."
	case 96, 99:
		return "Badai Petir Ekstrem", "Awas Tutup Total", "Bahaya badai ekstrem dan petir intens, segera cari posko evakuasi aman."
	default:
		return "Cerah Berawan", "Aman", "Kondisi cuaca normal."
	}
}

// GetRealtimeWeather mengambil data cuaca langsung dari Open-Meteo Live API
// Dilengkapi cache memori 10 menit dan fallback lokal jika offline/gagal.
func GetRealtimeWeather(lat, lng float64, cityRegency string) *models.WeatherInfo {
	if lat == 0 && lng == 0 {
		lat, lng = GetCoordsForCity(cityRegency)
	}

	cacheKey := fmt.Sprintf("%.2f,%.2f", lat, lng)
	weatherCacheMu.RLock()
	cached, ok := weatherCache[cacheKey]
	weatherCacheMu.RUnlock()

	if ok && time.Since(cached.timestamp) < weatherCacheTTL {
		return cached.info
	}

	// Panggil Open-Meteo Live API
	apiURL := fmt.Sprintf(
		"https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&hourly=precipitation_probability&timezone=Asia%%2FJakarta",
		lat, lng,
	)

	resp, err := openMeteoClient.Get(apiURL)
	if err == nil && resp.StatusCode == http.StatusOK {
		defer resp.Body.Close()
		var omResp openMeteoResponse
		if jsonErr := json.NewDecoder(resp.Body).Decode(&omResp); jsonErr == nil {
			cond, wStatus, alert := MapWMOCodeToCondition(omResp.Current.WeatherCode)
			temp := int(math.Round(omResp.Current.Temperature2m))
			wind := int(math.Round(omResp.Current.WindSpeed10m))
			rainProb := 20
			if len(omResp.Hourly.PrecipitationProbability) > 0 {
				rainProb = omResp.Hourly.PrecipitationProbability[0]
			}

			forecastStr := fmt.Sprintf("Suhu aktual %.1f°C dengan kondisi %s. Kecepatan angin %d km/j.", omResp.Current.Temperature2m, cond, wind)
			nowStr := time.Now().Format("15:04 WIB, 02 Jan 2006")

			info := &models.WeatherInfo{
				CityRegency:     cityRegency,
				TemperatureC:    temp,
				Condition:       cond,
				WeatherStatus:   wStatus,
				HumidityPercent: omResp.Current.RelativeHumidity,
				WindSpeedKmh:    wind,
				RainProbability: rainProb,
				Forecast:        forecastStr,
				AlertNote:       alert,
				Source:          "Open-Meteo Live API",
				LastUpdated:     nowStr,
			}

			weatherCacheMu.Lock()
			weatherCache[cacheKey] = weatherCacheItem{
				info:      info,
				timestamp: time.Now(),
			}
			weatherCacheMu.Unlock()

			return info
		}
	}

	// Fallback ke profil cuaca regional jika koneksi offline / Open-Meteo timeout
	return GetRegionalFallbackWeather(cityRegency)
}

// GetRealtimeWeatherForCity pembungkus untuk kompatibilitas mundur
func GetRealtimeWeatherForCity(cityRegency string) *models.WeatherInfo {
	return GetRealtimeWeather(0, 0, cityRegency)
}

// GetRegionalFallbackWeather profil cuaca cadangan jika server/offline
func GetRegionalFallbackWeather(cityRegency string) *models.WeatherInfo {
	nowStr := time.Now().Format("15:04 WIB, 02 Jan 2006")
	c := strings.ToLower(strings.TrimSpace(cityRegency))

	switch {
	case strings.Contains(c, "padang panjang") || strings.Contains(c, "tanah datar"):
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    24,
			Condition:       "Hujan Sedang di Hulu",
			WeatherStatus:   "Waspada Hujan",
			HumidityPercent: 88,
			WindSpeedKmh:    16,
			RainProbability: 75,
			Forecast:        "Hujan intensitas sedang hingga lebat di sekitar lereng Gunung Marapi & Singgalang.",
			AlertNote:       "Waspada peningkatan debit air terjun dan aliran sungai Batang Anai.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	case strings.Contains(c, "bukittinggi") || strings.Contains(c, "agam"):
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    23,
			Condition:       "Berawan Sejuk",
			WeatherStatus:   "Aman",
			HumidityPercent: 82,
			WindSpeedKmh:    11,
			RainProbability: 35,
			Forecast:        "Suhu sejuk 22-24°C, potensi kabut tipis menjelang sore hari di perbukitan.",
			AlertNote:       "Kondisi jalanan kering lancar, visibilitas baik.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	case strings.Contains(c, "lima puluh kota") || strings.Contains(c, "payakumbuh"):
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    26,
			Condition:       "Cerah Berawan di Lembah",
			WeatherStatus:   "Aman",
			HumidityPercent: 78,
			WindSpeedKmh:    12,
			RainProbability: 25,
			Forecast:        "Cerah berawan sepanjang siang hari, ideal untuk aktivitas luar ruangan dan panjat tebing.",
			AlertNote:       "Sinar UV sedang, disarankan memakai pelindung kepala di area tebing terbuka.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	case strings.Contains(c, "pesisir selatan") || strings.Contains(c, "mandeh"):
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    31,
			Condition:       "Cerah Bahari Berangin",
			WeatherStatus:   "Aman",
			HumidityPercent: 72,
			WindSpeedKmh:    18,
			RainProbability: 15,
			Forecast:        "Cerah berangin pantai, tinggi gelombang perairan teluk 0.3 - 0.6 meter (Tenang).",
			AlertNote:       "Sangat aman untuk penyeberangan perahu wisata dan snorkeling.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	case strings.Contains(c, "solok"):
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    22,
			Condition:       "Sejuk Pegunungan & Kabut Tipis",
			WeatherStatus:   "Aman",
			HumidityPercent: 85,
			WindSpeedKmh:    14,
			RainProbability: 40,
			Forecast:        "Suhu dataran tinggi sejuk 20-23°C, kabut tipis di sekeliling Danau Kembar.",
			AlertNote:       "Aspal tanjakan lembab, jaga kecepatan kendaraan di bawah 40 km/jam.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	case strings.Contains(c, "pariaman") || strings.Contains(c, "padang pariaman"):
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    29,
			Condition:       "Cerah Tropis Pesisir",
			WeatherStatus:   "Aman",
			HumidityPercent: 76,
			WindSpeedKmh:    15,
			RainProbability: 20,
			Forecast:        "Cerah bersahabat sepanjang hari, angin pesisir sepoi-sepoi.",
			AlertNote:       "Kondisi lalu lintas dan rute wisata aman lancar.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	case strings.Contains(c, "sawahlunto") || strings.Contains(c, "sijunjung"):
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    28,
			Condition:       "Cerah Berawan Lembah",
			WeatherStatus:   "Aman",
			HumidityPercent: 74,
			WindSpeedKmh:    10,
			RainProbability: 20,
			Forecast:        "Cerah hangat berawan, kelembapan stabil.",
			AlertNote:       "Kondisi cagar budaya dan akses jalan terbuka lancar.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	default: // Kota Padang & Default Sumbar
		return &models.WeatherInfo{
			CityRegency:     cityRegency,
			TemperatureC:    30,
			Condition:       "Cerah Berawan",
			WeatherStatus:   "Aman",
			HumidityPercent: 78,
			WindSpeedKmh:    14,
			RainProbability: 25,
			Forecast:        "Cerah berawan hingga sore hari, potensi gerimis lokal pada malam hari.",
			AlertNote:       "Kondisi perkotaan dan pantai normal aman.",
			Source:          "Regional Fallback Engine",
			LastUpdated:     nowStr,
		}
	}
}
