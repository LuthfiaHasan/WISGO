package spatial

import (
	"encoding/xml"
	"fmt"
	"html"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/LuthfiaHasan/WISGO/backend/internal/models"
)

// SeedSumbarPortalNews menyediakan Berita Wisata & Bencana Sumatera Barat terkurasi
// dari portal berita resmi Sumatera Barat: sumbarkita.id dan sumbar.antaranews.com
func SeedSumbarPortalNews() []models.SosNewsItem {
	return []models.SosNewsItem{
		{
			ID:           "news-sk-marapi-01",
			Category:     "Bencana & Vulkanologi",
			Severity:     "WASPADA",
			Title:        "PVMBG: Gunung Marapi Sumbar Masih Berstatus Waspada Level II, Wisatawan Dilarang Masuk Radius 3 Km",
			Region:       "Kab. Agam & Kab. Tanah Datar",
			Summary:      "Laporan Sumbarkita.id mencatat Pos Pengamatan Gunung Api (PGA) Marapi di Bukittinggi masih merekam aktivitas hembusan vulkanik. Masyarakat dan wisatawan di sekitar lereng Agam serta Tanah Datar diimbau mematuhi batas radius 3 kilometer dari Kawah Verbeek dan menyiapkan masker.",
			Advice:       "Destinasi Jam Gadang, Ngarai Sianok, dan Istano Basa Pagaruyung berada di luar zona bahaya dan tetap aman dikunjungi.",
			Source:       "Sumbarkita.id • Redaksi Kebencanaan Sumbar",
			PortalDomain: "sumbarkita.id",
			SourceURL:    "https://sumbarkita.id/tag/gunung-marapi/",
			Author:       "Redaksi Sumbarkita",
			Tags:         []string{"Gunung Marapi", "PVMBG", "Agam", "Tanah Datar", "Mitigasi"},
			IsPublished:  true,
			PublishedAt:  "2026-11-26T09:15:00Z",
		},
		{
			ID:           "news-antara-anai-02",
			Category:     "Info Jalur & Bencana",
			Severity:     "SIAGA HUJAN",
			Title:        "BPBD dan Balai Jalan Nasional Pantau Ketat Jalur Lembah Anai Padang–Bukittinggi Saat Hujan Deras",
			Region:       "Kab. Tanah Datar & Padang Pariaman",
			Summary:      "ANTARA Sumbar melaporkan petugas gabungan bersiaga di koridor jalan nasional Lembah Anai menyusul tingginya intensitas curah hujan di hulu Sungai Batang Anai. Pengendara wisata tujuan Bukittinggi diminta memperhatikan rambu peringatan dini.",
			Advice:       "Jika debit air Sungai Batang Anai meningkat tajam atau hujan ekstrem, gunakan jalur alternatif Sicincin – Malalak – Bukittinggi.",
			Source:       "ANTARA Sumbar (sumbar.antaranews.com)",
			PortalDomain: "sumbar.antaranews.com",
			SourceURL:    "https://sumbar.antaranews.com/berita-terkini",
			Author:       "LKBN ANTARA Biro Sumatera Barat",
			Tags:         []string{"Lembah Anai", "Jalur Lintas", "BPBD Sumbar", "Padang-Bukittinggi"},
			IsPublished:  true,
			PublishedAt:  "2026-11-26T08:40:00Z",
		},
		{
			ID:           "news-sk-sitinjau-03",
			Category:     "Info Jalur & Bencana",
			Severity:     "WASPADA",
			Title:        "Kabut Tebal dan Hujan Guyur Tanjakan Ekstrem Sitinjau Lauik Padang–Solok, Pengendara Diminta Jaga Jarak",
			Region:       "Kota Padang & Kab. Solok",
			Summary:      "Pantauan Sumbarkita.id di koridor Panorama 1 dan Panorama 2 Sitinjau Lauik menunjukkan jarak pandang berkurang hingga 30 meter saat hujan sore. Posko PKJR bersama TRC BPBD tetap bersiaga mengatur kelancaran kendaraan wisata menuju Danau Kembar dan Alahan Panjang.",
			Advice:       "Pastikan pengereman kendaraan prima, nyalakan lampu kabut, dan jaga jarak aman minimal 25 meter di belakang truk bermuatan.",
			Source:       "Sumbarkita.id • Info Lintas Sumbar",
			PortalDomain: "sumbarkita.id",
			SourceURL:    "https://sumbarkita.id/tag/sitinjau-lauik/",
			Author:       "Tim Liputan Padang",
			Tags:         []string{"Sitinjau Lauik", "Kabut Tebal", "Padang-Solok", "Keselamatan Jalan"},
			IsPublished:  true,
			PublishedAt:  "2026-11-26T08:05:00Z",
		},
		{
			ID:           "news-antara-mandeh-04",
			Category:     "Cuaca & Bahari",
			Severity:     "INFO WISATA",
			Title:        "BMKG Maritim Teluk Bayur: Gelombang Perairan Wisata Bahari Mandeh dan Pulau Angso Duo Kondusif",
			Region:       "Kab. Pesisir Selatan & Kota Pariaman",
			Summary:      "Berdasarkan rilis BMKG yang dikutip ANTARA Sumbar, tinggi gelombang di perairan Teluk Mandeh, Carocok Painan, hingga Pantai Gandoriah Pariaman berkisar 0,5 hingga 1,25 meter pada pagi hingga siang hari sehingga aman untuk aktivitas island hopping.",
			Advice:       "Wisatawan wajib mengenakan jaket pelampung (life jacket) berstandar keselamatan dan kembali ke dermaga sebelum pukul 16.30 WIB.",
			Source:       "ANTARA Sumbar (sumbar.antaranews.com)",
			PortalDomain: "sumbar.antaranews.com",
			SourceURL:    "https://sumbar.antaranews.com/pariwisata",
			Author:       "ANTARA Sumbar • Desk Maritim",
			Tags:         []string{"BMKG", "Kawasan Mandeh", "Pesisir Selatan", "Wisata Bahari"},
			IsPublished:  true,
			PublishedAt:  "2026-11-26T07:30:00Z",
		},
		{
			ID:           "news-sk-harau-05",
			Category:     "Akses Wisata",
			Severity:     "SIAGA HUJAN",
			Title:        "Dispar & Pokdarwis Imbau Pengunjung Air Terjun Lembah Harau dan Lubuk Hitam Waspadai Perubahan Debit Air",
			Region:       "Kab. Lima Puluh Kota & Bungus Kota Padang",
			Summary:      "Sumbarkita.id memberitakan pengelola ekowisata Lembah Harau, Air Terjun Nyarai, dan Lubuk Hitam (Cindakir) meningkatkan pengawasan hulu sungai pada musim penghujan guna mencegah risiko kepala air (banjir kiriman hulu).",
			Advice:       "Segera naik ke tepian apabila air terjun berubah keruh kecokelatan atau terdengar suara gemuruh dari atas tebing.",
			Source:       "Sumbarkita.id • Pariwisata & Nagari",
			PortalDomain: "sumbarkita.id",
			SourceURL:    "https://sumbarkita.id/tag/lembah-harau/",
			Author:       "Koresponden Luhak Limopuluah",
			Tags:         []string{"Lembah Harau", "Lubuk Hitam", "Air Terjun", "Pokdarwis"},
			IsPublished:  true,
			PublishedAt:  "2026-11-26T06:45:00Z",
		},
		{
			ID:           "news-antara-kelok44-06",
			Category:     "Akses Wisata",
			Severity:     "WASPADA",
			Title:        "Mitigasi Jalur Wisata Kelok 44 Danau Maninjau, Dishub dan BPBD Agam Siagakan Pos Pantau Tikungan",
			Region:       "Kab. Agam (Matur – Maninjau)",
			Summary:      "ANTARA Sumbar memberitakan kesiapsiagaan petugas di sepanjang 44 tikungan tajam penghubung Bukittinggi–Matur menuju kaldera Danau Maninjau dan Puncak Lawang untuk memastikan keamanan bus dan kendaraan wisatawan.",
			Advice:       "Gunakan gigi rendah saat menuruni Kelok 44, bunyikan klakson pada tikungan buta, dan hindari memberi makan kera liar di bahu jalan.",
			Source:       "ANTARA Sumbar (sumbar.antaranews.com)",
			PortalDomain: "sumbar.antaranews.com",
			SourceURL:    "https://sumbar.antaranews.com/daerah",
			Author:       "ANTARA Sumbar • Biro Agam",
			Tags:         []string{"Kelok 44", "Danau Maninjau", "Kabupaten Agam", "Jalur Wisata"},
			IsPublished:  true,
			PublishedAt:  "2026-11-26T05:50:00Z",
		},
		{
			ID:           "news-sk-mentawai-07",
			Category:     "Cuaca & Bahari",
			Severity:     "WASPADA",
			Title:        "Peringatan Dini BMKG: Waspada Angin Kencang dan Gelombang Tinggi di Perairan Barat Kepulauan Mentawai",
			Region:       "Kab. Kepulauan Mentawai",
			Summary:      "Sumbarkita.id mengabarkan prakirawan BMKG Minangkabau mengeluarkan peringatan dini potensi gelombang 2,0–2,5 meter di perairan barat Sipora dan Siberut. Kapal cepat Padang–Mentawai tetap beroperasi sesuai jadwal dengan pengawasan ketat KSOP.",
			Advice:       "Peselancar (surfer) dan wisatawan bahari tujuan Mentawai disarankan memantau jadwal kapal cepat Mentawai Fast secara berkala.",
			Source:       "Sumbarkita.id • Cuaca & Kebencanaan",
			PortalDomain: "sumbarkita.id",
			SourceURL:    "https://sumbarkita.id/tag/bmkg-sumbar/",
			Author:       "Redaksi Sumbarkita",
			Tags:         []string{"BMKG Sumbar", "Mentawai", "Gelombang Laut", "Cuaca Ekstrem"},
			IsPublished:  true,
			PublishedAt:  "2026-11-25T16:20:00Z",
		},
		{
			ID:           "news-antara-geopark-08",
			Category:     "Akses Wisata",
			Severity:     "INFO WISATA",
			Title:        "Pemprov Sumbar Perkuat Standar Mitigasi Bencana dan Plang QR Resmi di 20 Destinasi Unggulan Ranah Minang",
			Region:       "Provinsi Sumatera Barat (19 Kab/Kota)",
			Summary:      "ANTARA Sumbar menyoroti langkah Dinas Pariwisata Provinsi Sumatera Barat bersama BPBD yang mengintegrasikan informasi jalur rawan bencana, cuaca real-time, dan transparansi tarif Perda bebas pungli untuk kenyamanan wisatawan nusantara maupun Malaysia.",
			Advice:       "Gunakan fitur Pindai Plang Smart QR dan pantau halaman Darurat SOS & Info Bencana sebelum memulai perjalanan lintas kabupaten.",
			Source:       "ANTARA Sumbar (sumbar.antaranews.com)",
			PortalDomain: "sumbar.antaranews.com",
			SourceURL:    "https://sumbar.antaranews.com/",
			Author:       "LKBN ANTARA Sumbar",
			Tags:         []string{"Dispar Sumbar", "Wisata Aman", "Geopark Sumbar", "Bebas Pungli"},
			IsPublished:  true,
			PublishedAt:  "2026-11-25T13:10:00Z",
		},
	}
}

type rssFeedXML struct {
	Channel struct {
		Items []struct {
			Title       string `xml:"title"`
			Link        string `xml:"link"`
			Description string `xml:"description"`
			PubDate     string `xml:"pubDate"`
		} `xml:"item"`
	} `xml:"channel"`
}

var htmlTagRegex = regexp.MustCompile(`<[^>]*>`)

func cleanRSSHTML(raw string) string {
	noTags := htmlTagRegex.ReplaceAllString(raw, " ")
	unescaped := html.UnescapeString(noTags)
	fields := strings.Fields(unescaped)
	return strings.Join(fields, " ")
}

func classifySumbarArticle(title, desc string) (category, severity, region, advice string, relevant bool) {
	combined := strings.ToLower(title + " " + desc)

	// Kata kunci relevansi wisata & kebencanaan Sumatera Barat
	keywords := []string{
		"marapi", "longsor", "banjir", "gempa", "cuaca", "hujan", "bmkg", "bpbd",
		"wisata", "pantai", "danau", "lembah anai", "sitinjau", "kelok", "harau",
		"mandeh", "mentawai", "bukittinggi", "padang", "agam", "tanah datar",
		"pesisir selatan", "solok", "pariaman", "sawahlunto", "maninjau", "singkarak",
		"jalan", "jalur", "gunung", "air terjun", "geopark", "nagari",
	}
	for _, kw := range keywords {
		if strings.Contains(combined, kw) {
			relevant = true
			break
		}
	}
	if !relevant {
		return "", "", "", "", false
	}

	// Klasifikasi Wilayah Sumbar
	region = "Sumatera Barat"
	regionMap := []struct {
		key  string
		name string
	}{
		{"marapi", "Kab. Agam & Tanah Datar"},
		{"bukittinggi", "Kota Bukittinggi"},
		{"agam", "Kab. Agam"},
		{"tanah datar", "Kab. Tanah Datar"},
		{"lembah anai", "Kab. Tanah Datar & Padang Pariaman"},
		{"sitinjau", "Kota Padang & Kab. Solok"},
		{"harau", "Kab. Lima Puluh Kota"},
		{"lima puluh kota", "Kab. Lima Puluh Kota"},
		{"payakumbuh", "Kota Payakumbuh"},
		{"mandeh", "Kab. Pesisir Selatan"},
		{"pesisir selatan", "Kab. Pesisir Selatan"},
		{"mentawai", "Kab. Kepulauan Mentawai"},
		{"pariaman", "Kota Pariaman & Padang Pariaman"},
		{"solok", "Kab. Solok"},
		{"sawahlunto", "Kota Sawahlunto"},
		{"padang panjang", "Kota Padang Panjang"},
		{"padang", "Kota Padang"},
	}
	for _, rm := range regionMap {
		if strings.Contains(combined, rm.key) {
			region = rm.name
			break
		}
	}

	// Klasifikasi Kategori & Tingkat Siaga
	switch {
	case strings.Contains(combined, "marapi") || strings.Contains(combined, "erupsi") || strings.Contains(combined, "gempa") || strings.Contains(combined, "vulkan"):
		category = "Bencana & Vulkanologi"
		severity = "WASPADA"
		advice = "Patuhi radius aman yang ditetapkan PVMBG/BPBD Sumbar dan selalu siapkan masker pelindung."
	case strings.Contains(combined, "longsor") || strings.Contains(combined, "banjir") || strings.Contains(combined, "sitinjau") || strings.Contains(combined, "lembah anai") || strings.Contains(combined, "jalan putus"):
		category = "Info Jalur & Bencana"
		if strings.Contains(combined, "tutup") || strings.Contains(combined, "darurat") || strings.Contains(combined, "galodo") {
			severity = "DARURAT"
		} else {
			severity = "SIAGA HUJAN"
		}
		advice = "Pantau arahan petugas BPBD & Satlantas di lapangan serta siapkan rute alternatif sebelum melintas."
	case strings.Contains(combined, "cuaca") || strings.Contains(combined, "bmkg") || strings.Contains(combined, "gelombang") || strings.Contains(combined, "hujan") || strings.Contains(combined, "pantai") || strings.Contains(combined, "bahari"):
		category = "Cuaca & Bahari"
		if strings.Contains(combined, "ekstrem") || strings.Contains(combined, "lebat") || strings.Contains(combined, "tinggi") {
			severity = "SIAGA HUJAN"
		} else {
			severity = "INFO WISATA"
		}
		advice = "Periksa prakiraan cuaca real-time di aplikasi WISGO dan utamakan keselamatan selama berwisata."
	default:
		category = "Akses Wisata"
		severity = "INFO WISATA"
		advice = "Nikmati wisata Sumatera Barat dengan mematuhi aturan adat nagari dan menjaga kebersihan lingkungan."
	}

	return category, severity, region, advice, true
}

// FetchLivePortalNewsFromRSS menarik berita terbaru langsung dari RSS Sumbarkita.id & ANTARA Sumbar
func FetchLivePortalNewsFromRSS() []models.SosNewsItem {
	feeds := []struct {
		url          string
		sourceLabel  string
		portalDomain string
		idPrefix     string
	}{
		{
			url:          "https://sumbarkita.id/feed/",
			sourceLabel:  "Sumbarkita.id • Portal Berita Sumbar",
			portalDomain: "sumbarkita.id",
			idPrefix:     "live-sk",
		},
		{
			url:          "https://sumbar.antaranews.com/rss/terkini.xml",
			sourceLabel:  "ANTARA Sumbar (sumbar.antaranews.com)",
			portalDomain: "sumbar.antaranews.com",
			idPrefix:     "live-antara",
		},
	}

	client := &http.Client{Timeout: 2500 * time.Millisecond}
	var results []models.SosNewsItem

	for _, f := range feeds {
		req, err := http.NewRequest(http.MethodGet, f.url, nil)
		if err != nil {
			continue
		}
		req.Header.Set("User-Agent", "WISGO-DisparSumbar-NewsAggregator/3.0")

		resp, err := client.Do(req)
		if err != nil {
			continue
		}
		body, err := io.ReadAll(io.LimitReader(resp.Body, 512*1024))
		resp.Body.Close()
		if err != nil || resp.StatusCode != http.StatusOK {
			continue
		}

		var parsed rssFeedXML
		if err := xml.Unmarshal(body, &parsed); err != nil {
			continue
		}

		addedForFeed := 0
		for idx, item := range parsed.Channel.Items {
			if addedForFeed >= 4 {
				break
			}
			cleanTitle := cleanRSSHTML(item.Title)
			cleanDesc := cleanRSSHTML(item.Description)
			if cleanTitle == "" {
				continue
			}
			if len(cleanDesc) > 260 {
				cleanDesc = cleanDesc[:257] + "..."
			}
			if cleanDesc == "" {
				cleanDesc = cleanTitle
			}

			cat, sev, reg, adv, ok := classifySumbarArticle(cleanTitle, cleanDesc)
			if !ok {
				continue
			}

			pubTime := time.Now().Format(time.RFC3339)
			if t, err := time.Parse(time.RFC1123Z, strings.TrimSpace(item.PubDate)); err == nil {
				pubTime = t.Format(time.RFC3339)
			} else if t2, err2 := time.Parse(time.RFC1123, strings.TrimSpace(item.PubDate)); err2 == nil {
				pubTime = t2.Format(time.RFC3339)
			}

			results = append(results, models.SosNewsItem{
				ID:           fmt.Sprintf("%s-%d", f.idPrefix, idx+1),
				Category:     cat,
				Severity:     sev,
				Title:        cleanTitle,
				Region:       reg,
				Summary:      cleanDesc,
				Advice:       adv,
				Source:       f.sourceLabel,
				PortalDomain: f.portalDomain,
				SourceURL:    strings.TrimSpace(item.Link),
				IsPublished:  true,
				PublishedAt:  pubTime,
			})
			addedForFeed++
		}
	}

	return results
}

