package partner

// PartnerFilterQuery parameter pencarian dan filter katalog mitra nagari
type PartnerFilterQuery struct {
	Category   string `form:"category"`
	SpicyLevel *int   `form:"spicy_level"` // 0-5 khusus kuliner
	Nagari     string `form:"nagari"`
}

