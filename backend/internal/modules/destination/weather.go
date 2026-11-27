package destination

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

const defaultWeatherAPIKey = "c7bf87c35fa6413784872827262511"

type weatherAPIResponse struct {
	Location struct {
		Name      string  `json:"name"`
		Region    string  `json:"region"`
		Country   string  `json:"country"`
		Lat       float64 `json:"lat"`
		Lon       float64 `json:"lon"`
		Localtime string  `json:"localtime"`
	} `json:"location"`
	Current struct {
		LastUpdated string  `json:"last_updated"`
		TempC       float64 `json:"temp_c"`
		FeelslikeC  float64 `json:"feelslike_c"`
		Humidity    int     `json:"humidity"`
		WindKph     float64 `json:"wind_kph"`
		UV          float64 `json:"uv"`
		Condition   struct {
			Text string `json:"text"`
			Icon string `json:"icon"`
			Code int    `json:"code"`
		} `json:"condition"`
	} `json:"current"`
	Forecast struct {
		Forecastday []struct {
			Day struct {
				DailyChanceOfRain int `json:"daily_chance_of_rain"`
			} `json:"day"`
			Hour []struct {
				Time         string  `json:"time"`
				TempC        float64 `json:"temp_c"`
				ChanceOfRain int     `json:"chance_of_rain"`
				Condition    struct {
					Text string `json:"text"`
					Code int    `json:"code"`
				} `json:"condition"`
			} `json:"hour"`
		} `json:"forecastday"`
	} `json:"forecast"`
}

type weatherCacheItem struct {
	info      *models.WeatherInfo
	timestamp time.Time
}

var (
	weatherCacheMu sync.RWMutex
	weatherCache   = make(map[string]weatherCacheItem)
	// Timeout untuk pemanggilan WeatherAPI agar non-blocking & responsif
	weatherHTTPClient = &http.Client{Timeout: 3 * time.Second}
)

const weatherCacheTTL = 10 * time.Minute

func getWeatherAPIKey() string {
	if key := strings.TrimSpace(os.Getenv("WEATHER_API_KEY")); key != "" {
		return key
	}
	return defaultWeatherAPIKey
}

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

// MapWeatherAPICodeToCondition menerjemahkan kode cuaca dari WeatherAPI.com ke Bahasa Indonesia & tingkat peringatan
func MapWeatherAPICodeToCondition(code int) (condition string, weatherStatus string, alertNote string) {
	switch code {
	case 1000:
		return "Cerah", "Aman", "Langit cerah, visibilitas sangat baik untuk berwisata."
	case 1003:
		return "Cerah Berawan", "Aman", "Kondisi cuaca baik dan kondusif untuk perjalanan."
	case 1006:
		return "Berawan", "Aman", "Berawan sejuk, jalanan kering dan nyaman dilalui."
	case 1009:
		return "Mendung Tebal", "Waspada", "Awan mendung tebal, siapkan payung atau jas hujan."
	case 1030, 1135, 1147:
		return "Berkabut Tebal", "Waspada", "Kabut mengurangi jarak pandang, nyalakan lampu kabut dan kurangi kecepatan."
	case 1063, 1150, 1153, 1168, 1171:
		return "Gerimis", "Waspada", "Jalanan mulai basah, berhati-hati terhadap tikungan licin."
	case 1180, 1183, 1240:
		return "Hujan Ringan", "Waspada Hujan", "Hujan intensitas ringan, hindari memacu kendaraan kencang."
	case 1186, 1189, 1243:
		return "Hujan Sedang", "Waspada Hujan", "Hujan sedang merata, waspada genangan air dan jalanan licin."
	case 1192, 1195, 1246:
		return "Hujan Lebat", "Siaga Cuaca Ekstrem", "Hujan lebat, waspada potensi longsor tebing dan luapan air hulu."
	case 1087, 1273:
		return "Hujan Badai Petir", "Siaga Cuaca Ekstrem", "Terjadi petir dan angin kencang, jauhi pohon besar dan tebing terjal."
	case 1276, 1279, 1282:
		return "Badai Petir Ekstrem", "Awas Tutup Total", "Bahaya badai ekstrem dan petir intens, segera cari posko evakuasi aman."
	default:
		return "Cerah Berawan", "Aman", "Kondisi cuaca normal."
	}
}

// MapWMOCodeToCondition dipertahankan untuk kompatibilitas kode WMO
func MapWMOCodeToCondition(code int) (condition string, weatherStatus string, alertNote string) {
	return MapWeatherAPICodeToCondition(code)
}

// GetRealtimeWeather mengambil data cuaca langsung dari WeatherAPI.com Live API
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

	apiKey := getWeatherAPIKey()
	apiURL := fmt.Sprintf(
		"https://api.weatherapi.com/v1/forecast.json?key=%s&q=%.4f,%.4f&days=1&aqi=no&alerts=no",
		apiKey, lat, lng,
	)

	resp, err := weatherHTTPClient.Get(apiURL)
	if err == nil && resp.StatusCode == http.StatusOK {
		defer resp.Body.Close()
		var wResp weatherAPIResponse
		if jsonErr := json.NewDecoder(resp.Body).Decode(&wResp); jsonErr == nil {
			cond, wStatus, alert := MapWeatherAPICodeToCondition(wResp.Current.Condition.Code)
			temp := int(math.Round(wResp.Current.TempC))
			wind := int(math.Round(wResp.Current.WindKph))
			rainProb := 20
			if len(wResp.Forecast.Forecastday) > 0 {
				rainProb = wResp.Forecast.Forecastday[0].Day.DailyChanceOfRain
			}

			forecastStr := fmt.Sprintf("Suhu aktual %.1f°C dengan kondisi %s. Kecepatan angin %d km/j.", wResp.Current.TempC, cond, wind)
			nowStr := time.Now().Format("15:04 WIB, 02 Jan 2006")

			info := &models.WeatherInfo{
				CityRegency:     cityRegency,
				TemperatureC:    temp,
				Condition:       cond,
				WeatherStatus:   wStatus,
				HumidityPercent: wResp.Current.Humidity,
				WindSpeedKmh:    wind,
				RainProbability: rainProb,
				Forecast:        forecastStr,
				AlertNote:       alert,
				Source:          "WeatherAPI Live API",
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

	// Fallback ke profil cuaca regional jika koneksi offline / WeatherAPI timeout
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
