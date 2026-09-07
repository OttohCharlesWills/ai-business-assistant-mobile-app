import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../../../services/stock_report_service.dart';
import '../../../services/shop_service.dart';
import '../../../widgets/app_loader.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  static const bgColor    = Color(0xFF0C1F3F);
  static const cardColor  = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue   = Color(0xFF8FAADC);

  bool loading = false;
  bool downloading = false;
  bool locked = false;
  String? lockMessage;
  Map<String, dynamic>? reportData;

  List shops = [];
  List products = [];
  dynamic selectedShop;
  final searchCtrl = TextEditingController();
  int currentPage = 1;
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    fetchShops();
    fetchReport();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // Shops now come from ShopService directly, independent of the report
  // response — this report can also return locked:true with no data at all,
  // which used to leave the dropdown permanently empty.
  Future<void> fetchShops() async {
    final data = await ShopService.getShops(refresh: true);
    if (!mounted) return;
    setState(() => shops = data);
  }

  Future<void> fetchReport({int page = 1}) async {
    setState(() => loading = true);

    final res = await StockReportService.getStockReport(
      shopId: selectedShop,
      search: searchCtrl.text.trim().isEmpty ? null : searchCtrl.text.trim(),
      page: page,
    );

    if (res['status'] == true) {
      if (res['locked'] == true) {
        setState(() {
          locked = true;
          lockMessage = res['message'];
          reportData = null;
        });
      } else {
        final data = res['data'];
        setState(() {
          locked = false;
          reportData   = data;
          currentPage  = data['products']?['current_page'] ?? 1;
          lastPage     = data['products']?['last_page'] ?? 1;
          products     = data['products']?['data'] ?? [];
        });
      }
    }

    setState(() => loading = false);
  }

  // Uses the service's authenticated byte-fetch instead of url_launcher —
  // this route sits behind auth:sanctum and needs a Bearer token, which
  // url_launcher has no way to attach.
  Future<void> downloadPdf() async {
    setState(() => downloading = true);

    final bytes = await StockReportService.downloadStockReportPdf(
      shopId: selectedShop,
      search: searchCtrl.text.trim().isEmpty ? null : searchCtrl.text.trim(),
    );

    if (!mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download PDF"), backgroundColor: Colors.red),
      );
      setState(() => downloading = false);
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/stock_inventory_report.pdf');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open PDF: $e"), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = reportData;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Stock Report",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => fetchReport(),
          ),
        ],
      ),
      body: loading
          ? const FullScreenLoader(message: "Loading stock report...")
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // SEARCH + SHOP FILTER
                  _sectionTitle("Filters"),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search product name...",
                        hintStyle: TextStyle(color: softBlue, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: softBlue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => fetchReport(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _shopDropdown(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => fetchReport(),
                          icon: const Icon(Icons.filter_alt_rounded, size: 16),
                          label: const Text("Apply Filter"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: downloading ? null : downloadPdf,
                          icon: downloading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.download_rounded, size: 16),
                          label: const Text("Download PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (locked)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.lock_rounded, color: Colors.orange, size: 40),
                          ),
                          const SizedBox(height: 14),
                          const Text("PREMIUM FEATURE", style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text("Stock Report Locked", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            lockMessage ?? "This feature is not included in your current plan.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: softBlue, fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    )
                  else if (data == null)
                    const Center(child: Text("No data", style: TextStyle(color: softBlue)))
                  else ...[

                    // SUMMARY CARDS
                    _sectionTitle("Summary"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statCard("Total Products", "${data['total_products'] ?? 0}", accentBlue, Icons.inventory_2_rounded),
                        const SizedBox(width: 10),
                        _statCard("Low Stock Items", "${data['low_stock_count'] ?? 0}", Colors.red, Icons.warning_amber_rounded),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // STOCK TABLE
                    _sectionTitle("Stock Breakdown"),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: const [
                                Expanded(flex: 3, child: Text("Product", style: TextStyle(color: softBlue, fontSize: 11, fontWeight: FontWeight.w600))),
                                Expanded(flex: 2, child: Text("Shop", style: TextStyle(color: softBlue, fontSize: 11, fontWeight: FontWeight.w600))),
                                Expanded(flex: 1, child: Text("Stock", style: TextStyle(color: softBlue, fontSize: 11, fontWeight: FontWeight.w600))),
                                Expanded(flex: 1, child: Text("Status", style: TextStyle(color: softBlue, fontSize: 11, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: accentBlue.withOpacity(0.2)),
                          if (products.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text("No products found", style: TextStyle(color: softBlue)),
                            )
                          else
                            ...products.map((p) {
                              final remaining = double.tryParse(p['remaining_stock']?.toString() ?? '0') ?? 0;
                              final limit     = double.tryParse(p['stock_limit']?.toString() ?? '0') ?? 0;
                              final isLow     = remaining <= limit;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(p['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(p['shop']?['name'] ?? '-', style: const TextStyle(color: softBlue, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 1, child: Text("$remaining", style: const TextStyle(color: Colors.white, fontSize: 12))),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isLow ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isLow ? "Low" : "OK",
                                          style: TextStyle(
                                            color: isLow ? Colors.red : Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),

                    // PAGINATION
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: currentPage > 1 ? () => fetchReport(page: currentPage - 1) : null,
                          icon: const Icon(Icons.chevron_left_rounded, color: softBlue),
                        ),
                        Text(
                          "Page $currentPage of $lastPage",
                          style: const TextStyle(color: softBlue, fontSize: 13),
                        ),
                        IconButton(
                          onPressed: currentPage < lastPage ? () => fetchReport(page: currentPage + 1) : null,
                          icon: const Icon(Icons.chevron_right_rounded, color: softBlue),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16));

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: selectedShop,
          isExpanded: true,
          dropdownColor: cardColor,
          hint: const Text("All Shops", style: TextStyle(color: softBlue, fontSize: 13)),
          items: [
            const DropdownMenuItem(value: null, child: Text("All Shops", style: TextStyle(color: Colors.white))),
            ...shops.map((s) => DropdownMenuItem(
                  value: s['id'],
                  child: Text(s['name'] ?? '', style: const TextStyle(color: Colors.white)),
                )),
          ],
          onChanged: (v) => setState(() => selectedShop = v),
        ),
      ),
    );
  }
}