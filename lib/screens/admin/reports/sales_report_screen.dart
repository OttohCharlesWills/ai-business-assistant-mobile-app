import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../../../services/sales_report_service.dart';
import '../../../services/shop_service.dart';
import '../../../widgets/app_loader.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  static const bgColor    = Color(0xFF0C1F3F);
  static const cardColor  = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue   = Color(0xFF8FAADC);

  bool loading = false;
  bool downloading = false;
  Map<String, dynamic>? reportData;

  List shops = [];
  dynamic selectedShop;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchShops();
    fetchReport();
  }

  // Shops now come from ShopService directly, independent of the report
  // response — the report's own 'shops' field can be empty (paywall lock,
  // owner_id mismatch, etc.) without breaking this dropdown.
  Future<void> fetchShops() async {
    final data = await ShopService.getShops(refresh: true);
    if (!mounted) return;
    setState(() => shops = data);
  }

  Future<void> fetchReport() async {
    setState(() => loading = true);

    final res = await SalesReportService.getSalesReport(
      startDate: startDate != null ? _fmtDate(startDate!) : null,
      endDate: endDate != null ? _fmtDate(endDate!) : null,
      shopId: selectedShop,
    );

    if (res['status'] == true) {
      setState(() => reportData = res['data']);
    }

    setState(() => loading = false);
  }

  // Uses the service's authenticated byte-fetch (Bearer token attached)
  // instead of launching the URL in an external browser — that route sits
  // behind auth:sanctum and url_launcher can't attach the auth header,
  // so it would always 401 before ever reaching the PDF.
  Future<void> downloadPdf() async {
    setState(() => downloading = true);

    final bytes = await SalesReportService.downloadSalesReportPdf(
      startDate: startDate != null ? _fmtDate(startDate!) : null,
      endDate: endDate != null ? _fmtDate(endDate!) : null,
      shopId: selectedShop,
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
      final file = File('${dir.path}/sales_report.pdf');
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

  Future<void> pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: accentBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) startDate = picked;
        else endDate = picked;
      });
    }
  }

  String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _fmtMoney(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    return "₦${d.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";
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
        title: const Text("Sales Report",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchReport,
          ),
        ],
      ),
      body: loading
          ? const FullScreenLoader(message: "Loading sales report...")
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // FILTERS
                  _sectionTitle("Filters"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _datePicker("Start Date", startDate, () => pickDate(isStart: true))),
                      const SizedBox(width: 8),
                      Expanded(child: _datePicker("End Date", endDate, () => pickDate(isStart: false))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _shopDropdown(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: fetchReport,
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

                  if (data == null)
                    const Center(child: Text("No data", style: TextStyle(color: softBlue)))
                  else ...[

                    // SUMMARY CARDS
                    _sectionTitle("Summary"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statCard("Total Sales", _fmtMoney(data['total_sales']), Colors.green, Icons.payments_rounded),
                        const SizedBox(width: 10),
                        _statCard("Transactions", "${data['total_transactions'] ?? 0}", accentBlue, Icons.receipt_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _statCard(
                      "Top Product",
                      // API returns 'top_products' (a list), not a single
                      // 'top_product' field — take the first entry.
                      (data['top_products'] as List? ?? []).isNotEmpty
                          ? ((data['top_products'] as List).first['product_name']?.toString() ?? 'N/A')
                          : 'N/A',
                      const Color(0xFFF57C00),
                      Icons.star_rounded,
                    ),

                    const SizedBox(height: 20),

                    // TOP PRODUCTS TABLE
                    _sectionTitle("Top Selling Products"),
                    const SizedBox(height: 8),
                    _tableCard(
                      headers: ["#", "Product", "Qty Sold"],
                      rows: (data['top_products'] as List? ?? [])
                          .asMap()
                          .entries
                          .map<List<String>>((e) {
                        final i = e.key;
                        final p = e.value;

                        return [
                          (i + 1).toString(),
                          p['product_name']?.toString() ?? '-',
                          p['total_sold']?.toString() ?? '0',
                        ];
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // DAILY CHART placeholder
                    _sectionTitle("Daily Sales Trend"),
                    const SizedBox(height: 8),
                    _dailyTrend(data['sales_by_day'] as List? ?? []),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCard({required List<String> headers, required List<List<String>> rows}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: headers
                  .map((h) => Expanded(
                        child: Text(h,
                            style: const TextStyle(color: softBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ),
          Divider(height: 1, color: accentBlue.withOpacity(0.2)),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No data", style: TextStyle(color: softBlue)),
            )
          else
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: row
                        .map((cell) => Expanded(
                              child: Text(cell,
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                            ))
                        .toList(),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _dailyTrend(List days) {
    if (days.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
        child: const Center(child: Text("No trend data", style: TextStyle(color: softBlue))),
      );
    }
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: days.map((d) {
          final total = double.tryParse(d['total']?.toString() ?? '0') ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(d['date']?.toString() ?? '',
                      style: const TextStyle(color: softBlue, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: total > 0 ? (total / 1000000).clamp(0, 1) : 0,
                    backgroundColor: accentBlue.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_fmtMoney(total),
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: softBlue, size: 16),
            const SizedBox(width: 8),
            Text(
              value != null ? _fmtDate(value) : label,
              style: TextStyle(
                color: value != null ? Colors.white : softBlue,
                fontSize: 13,
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