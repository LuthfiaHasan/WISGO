import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../fair_price/data/models/fair_price_tariff_model.dart';

class QuickBookingItem {
  final String id;
  final String category; // 'Penginapan' | 'Transportasi' | 'Atraksi' | 'Pakaian Adat' | 'Kuliner'
  final String name;
  final String provider;
  final int price;
  final String unit;
  final IconData icon;
  final String description;

  const QuickBookingItem({
    required this.id,
    required this.category,
    required this.name,
    required this.provider,
    required this.price,
    required this.unit,
    required this.icon,
    required this.description,
  });
}

const List<QuickBookingItem> kOfficial5CategoryCatalog = [
  // 1. PENGINAPAN
  QuickBookingItem(
    id: 'stay-1',
    category: 'Penginapan',
    name: 'Homestay Rumah Gadang Kayu Asli',
    provider: 'Pokdarwis Nagari Cindakir',
    price: 175000,
    unit: 'malam/kamar',
    icon: Icons.holiday_village_rounded,
    description: 'Kamar bernuansa etnik Minang tradisional, sarapan pangek masin & teh talua.',
  ),
  QuickBookingItem(
    id: 'stay-2',
    category: 'Penginapan',
    name: 'Glamping Tepi Sungai Lembah Harau',
    provider: 'Kelompok Sadar Wisata Harau',
    price: 250000,
    unit: 'tenda/malam',
    icon: Icons.cabin_rounded,
    description: 'Tenda tebal tahan air dengan kasur busa empuk, api unggun & pemandangan tebing.',
  ),

  // 2. TRANSPORTASI
  QuickBookingItem(
    id: 'trans-1',
    category: 'Transportasi',
    name: 'Sewa Motor Matic Nagari + 2 Helm SNI',
    provider: 'Rental Pemuda Nagari Bungus',
    price: 75000,
    unit: 'hari',
    icon: Icons.two_wheeler_rounded,
    description: 'Motor sehat siap tanjakan terawat, bahan bakar awal terisi, helm bersih.',
  ),
  QuickBookingItem(
    id: 'trans-2',
    category: 'Transportasi',
    name: 'Shuttle Wisata Avanza Antar-Jemput',
    provider: 'Koperasi Angkutan Nagari',
    price: 280000,
    unit: 'trip rombongan',
    icon: Icons.directions_car_rounded,
    description: 'Mobil ber-AC kapasitas 6 orang, supir ramah warga lokal nagari.',
  ),

  // 3. ATRAKSI
  QuickBookingItem(
    id: 'atrak-1',
    category: 'Atraksi',
    name: 'Tiket Masuk Resmi Pokdarwis + Asuransi',
    provider: 'Dinas Pariwisata & Nagari',
    price: 10000,
    unit: 'orang',
    icon: Icons.confirmation_number_rounded,
    description: 'Karcis resmi retribusi nagari sesuai Perda, termasuk asuransi Jasa Raharja.',
  ),
  QuickBookingItem(
    id: 'atrak-2',
    category: 'Atraksi',
    name: 'Pemandu Trekking & Wisata Air Terjun',
    provider: 'HPI (Himpunan Pramuwisata Nagari)',
    price: 85000,
    unit: 'grup (maks 5 org)',
    icon: Icons.hiking_rounded,
    description: 'Pemandu bersertifikasi, membawa kotak P3K dan mengenalkan flora lokal.',
  ),

  // 4. PAKAIAN ADAT
  QuickBookingItem(
    id: 'adat-1',
    category: 'Pakaian Adat',
    name: 'Sewa Busana Lengkap Bundo Kanduang',
    provider: 'Sanggar Seni Rang Mudo',
    price: 65000,
    unit: 'set/pemakaian',
    icon: Icons.checkroom_rounded,
    description: 'Baju kuruang basiba beludru, tingkuluak tanduak, salendang & aksesoris asli.',
  ),
  QuickBookingItem(
    id: 'adat-2',
    category: 'Pakaian Adat',
    name: 'Sewa Busana Marapulai Minang Tradisional',
    provider: 'Sanggar Seni Nagari',
    price: 65000,
    unit: 'set/pemakaian',
    icon: Icons.accessibility_new_rounded,
    description: 'Destar saluak songket, baju gadang hitam beludru sulam ameh, sarawa & cawek.',
  ),

  // 5. KULINER
  QuickBookingItem(
    id: 'kulin-1',
    category: 'Kuliner',
    name: 'Paket Nasi Kapau Sambalado Cangkuak',
    provider: 'Warung UMKM Mak Etek',
    price: 25000,
    unit: 'porsi komplit',
    icon: Icons.restaurant_rounded,
    description: 'Nasi hangat, gulai tambusu, rendang daging sapi, dabu-dabu lokal & lalapan.',
  ),
  QuickBookingItem(
    id: 'kulin-2',
    category: 'Kuliner',
    name: 'Kelapa Muda Murni Segar & Gorengan Panas',
    provider: 'Kedai Pokdarwis Cindakir',
    price: 15000,
    unit: 'paket santai',
    icon: Icons.local_drink_rounded,
    description: '1 butir kelapa muda utuh dipotong langsung + 4 gorengan pisang/bakwan hangat.',
  ),
];

class QuickBookingPanel extends StatefulWidget {
  final SavedDestinationModel place;
  final VoidCallback onClose;
  final Function(int totalAmount, List<Map<String, dynamic>> orderItems) onProceedToPayment;

  const QuickBookingPanel({
    super.key,
    required this.place,
    required this.onClose,
    required this.onProceedToPayment,
  });

  @override
  State<QuickBookingPanel> createState() => _QuickBookingPanelState();
}

class _QuickBookingPanelState extends State<QuickBookingPanel> {
  String _selectedCategory = 'Atraksi';
  final Map<String, int> _cart = {
    'atrak-1': 1, // Default 1 tiket masuk resmi
  };

  final List<String> _categories = [
    'Atraksi',
    'Penginapan',
    'Transportasi',
    'Pakaian Adat',
    'Kuliner',
  ];

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Penginapan':
        return Icons.hotel_rounded;
      case 'Transportasi':
        return Icons.directions_bus_rounded;
      case 'Atraksi':
        return Icons.local_activity_rounded;
      case 'Pakaian Adat':
        return Icons.checkroom_rounded;
      case 'Kuliner':
        return Icons.restaurant_menu_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  int get _totalAmount {
    int sum = 0;
    _cart.forEach((id, qty) {
      final item = kOfficial5CategoryCatalog.firstWhere((it) => it.id == id);
      sum += item.price * qty;
    });
    return sum;
  }

  int get _totalItemsCount {
    int count = 0;
    _cart.forEach((_, qty) => count += qty);
    return count;
  }

  void _updateQuantity(String id, int delta) {
    setState(() {
      final current = _cart[id] ?? 0;
      final updated = current + delta;
      if (updated <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = kOfficial5CategoryCatalog
        .where((item) => item.category == _selectedCategory)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle & Header
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.warmBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.cream),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pemesanan Cepat 360°',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Katalog 5 Kategori Resmi Pokdarwis',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.warmBorder),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.warmBorder),

          // 5 Category Tabs Slider
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.forest : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.forest : AppColors.sageBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(cat),
                          size: 13,
                          color: isSelected ? AppColors.cream : AppColors.forest,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.cream : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Catalog List (Max 2 items per category for compact half-panel)
          SizedBox(
            height: 190,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filteredItems.length,
              itemBuilder: (ctx, idx) {
                final item = filteredItems[idx];
                final qty = _cart[item.id] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: qty > 0 ? AppColors.forest : AppColors.sageBorder,
                      width: qty > 0 ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.sage,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 18, color: AppColors.forest),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${_formatNumber(item.price)} / ${item.unit}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Quantity selector
                      Row(
                        children: [
                          if (qty > 0) ...[
                            GestureDetector(
                              onTap: () => _updateQuantity(item.id, -1),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.creamSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.warmBorder),
                                ),
                                child: const Icon(Icons.remove, size: 14, color: AppColors.ink),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$qty',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          ],
                          GestureDetector(
                            onTap: () => _updateQuantity(item.id, 1),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, size: 14, color: AppColors.cream),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Total & Checkout Action Footer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.warmBorder)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_totalItemsCount Layanan Dipilih',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(_totalAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _totalAmount > 0
                        ? () {
                            final List<Map<String, dynamic>> items = [];
                            _cart.forEach((id, qty) {
                              final item = kOfficial5CategoryCatalog.firstWhere((it) => it.id == id);
                              items.add({
                                'name': item.name,
                                'qty': qty,
                                'price': item.price,
                                'total': item.price * qty,
                              });
                            });
                            widget.onProceedToPayment(_totalAmount, items);
                          }
                        : null,
                    icon: const Icon(Icons.qr_code_rounded, size: 16),
                    label: const Text(
                      'Bayar QRIS / E-Wallet',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.cream,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int val) {
    final s = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}
