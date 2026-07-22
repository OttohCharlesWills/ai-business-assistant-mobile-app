import 'package:flutter/material.dart';
import '../../../services/sales_service.dart';
import '../../../services/shop_service.dart';

class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends State<AdminSalesScreen> {

  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  List sales = [];
  List shops = [];
  bool loading = true;

  final searchController = TextEditingController();
  String selectedDate = DateTime.now().toIso8601String().split('T')[0];
  String? selectedShopId;

  @override
  void initState() {
    super.initState();
    fetchSalesPage();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSalesPage() async {
    setState(() => loading = true);

    final result = await SalesService.getSalesPage(date: selectedDate);

    setState(() {
      sales = result['sales'];
      shops = result['shops'];
      loading = false;
    });
  }

  Future<void> filterSales() async {
    setState(() => loading = true);

    final result = await SalesService.getSales(
      date: selectedDate,
      search: searchController.text.trim(),
      shopId: selectedShopId,
    );

    setState(() {
      sales = result['sales'];
      loading = false;
    });
  }

  Future<void> confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Delete Sale",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to delete this sale record? This cannot be undone.",
                style: TextStyle(
                  color: softBlue,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: accentBlue.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel",
                          style: TextStyle(color: softBlue)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final res = await SalesService.deleteSale(id);
      if (!mounted) return;
      if (res['status'] == true || res['success'] == true) {
        filterSales();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sale deleted"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _viewSaleDetail(Map sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: softBlue.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sale Details",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow("Product",
                sale['product']?['name'] ?? 'N/A'),
            _detailRow("Category",
                sale['product']?['category']?['name'] ?? 'N/A'),
            _detailRow("Shop", sale['shop']?['name'] ?? 'N/A'),
            _detailRow("Quantity", "${sale['quantity']}"),
            _detailRow("Total Price",
                "₦${_formatMoney(sale['total_price'])}"),
            _detailRow("Discount",
                "₦${_formatMoney(sale['discount'] ?? 0)}"),
            _detailRow("Sale Type", sale['sale_type'] ?? 'N/A'),
            _detailRow("Cashier",
                sale['cashier']?['name'] ?? 'N/A'),
            _detailRow("Date", _formatDate(sale['created_at'])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  confirmDelete(sale['id']);
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white),
                label: const Text("Delete Sale",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: softBlue, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatMoney(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  double get grandTotal {
    return sales.fold(0.0, (sum, sale) {
      return sum + (double.tryParse(sale['total_price'].toString()) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Daily Sales",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: filterSales,
          ),
        ],
      ),

      body: Column(
        children: [

          // FILTERS SECTION
          Container(
            padding: const EdgeInsets.all(16),
            color: cardColor,
            child: Column(
              children: [

                // SEARCH
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => filterSales(),
                    decoration: const InputDecoration(
                      hintText: "Search product name...",
                      hintStyle: TextStyle(color: softBlue, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: softBlue),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    // DATE PICKER
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: accentBlue,
                                    surface: cardColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked
                                  .toIso8601String()
                                  .split('T')[0];
                            });
                            filterSales();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: softBlue, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                selectedDate,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // SHOP FILTER
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedShopId,
                            dropdownColor: bgColor,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            hint: const Text("All Shops",
                                style: TextStyle(
                                    color: softBlue, fontSize: 13)),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("All Shops",
                                    style: TextStyle(color: softBlue)),
                              ),
                              ...shops.map<DropdownMenuItem<String>>(
                                (shop) => DropdownMenuItem(
                                  value: shop['id'].toString(),
                                  child: Text(shop['name'],
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => selectedShopId = val);
                              filterSales();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // GRAND TOTAL BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            color: accentBlue.withOpacity(0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Sales",
                  style: TextStyle(
                    color: softBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "₦${_formatMoney(grandTotal)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // SALES LIST
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: accentBlue),
                  )
                : sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: accentBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 40,
                                color: softBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No sales found",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Try a different date or search term",
                              style: TextStyle(
                                  color: softBlue, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: filterSales,
                        color: accentBlue,
                        backgroundColor: cardColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sales.length,
                          itemBuilder: (context, index) {
                            final sale = sales[index];
                            return GestureDetector(
                              onTap: () => _viewSaleDetail(sale),
                              child: Container(
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [

                                    // NUMBER BADGE
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: accentBlue
                                            .withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: const TextStyle(
                                            color: softBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // PRODUCT INFO
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sale['product']?['name'] ??
                                                'N/A',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.store_rounded,
                                                size: 12,
                                                color: softBlue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                sale['shop']?['name'] ??
                                                    'N/A',
                                                style: const TextStyle(
                                                  color: softBlue,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                Icons.person_rounded,
                                                size: 12,
                                                color: softBlue,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                sale['cashier']
                                                            ?['name'] ??
                                                        'N/A',
                                                style: const TextStyle(
                                                  color: softBlue,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(
                                                sale['created_at']),
                                            style: const TextStyle(
                                              color: softBlue,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // PRICE + QTY
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₦${_formatMoney(sale['total_price'])}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3),
                                          decoration: BoxDecoration(
                                            color: accentBlue
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "Qty: ${sale['quantity']}",
                                            style: const TextStyle(
                                              color: softBlue,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: softBlue,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}