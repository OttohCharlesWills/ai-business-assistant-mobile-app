import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../../../services/profit_report_service.dart';
import '../../../services/shop_service.dart';
import '../../../widgets/app_loader.dart';

class ProfitReportScreen extends StatefulWidget {
  const ProfitReportScreen({super.key});

  @override
  State<ProfitReportScreen> createState() => _ProfitReportScreenState();
}

class _ProfitReportScreenState extends State<ProfitReportScreen> {
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
  // response.
  Future<void> fetchShops() async {
    final data = await ShopService.getShops(refresh: true);
    if (!mounted) return;
    setState(() => shops = data);
  }

  Future<void> fetchReport() async {
    setState(() => loading = true);

    final res = await ProfitReportService.getProfitLoss(
      startDate: startDate != null ? _fmtDate(startDate!) : null,
      endDate: endDate != null ? _fmtDate(endDate!) : null,
      shopId: selectedShop,
    );

    if (res['status'] == true) {
      setState(() => reportData = res['data']);
    }

    setState(() => loading = false);
  }

  // Uses the service's authenticated byte-fetch instead of url_launcher —
  // this route sits behind auth:sanctum and needs a Bearer token, which
  // url_launcher has no way to attach.
  Future<void> downloadPdf() async {
    setState(() => downloading = true);

    final bytes = await ProfitReportService.downloadGoodsProfitPdf(
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
      final file = File('${dir.path}/goods_profit_report.pdf');
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

  double _num(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

  // The API only returns raw 'sales' rows (each purchase item with its
  // product relation loaded) — it never pre-aggregates a 'goods_by_profit'
  // field. That grouping only existed in the Blade view's @php block. This
  // replicates the same grouping in Dart: group sales by product name, sum
  // quantity/revenue/cost, then derive profit.
  List<Map<String, dynamic>> _goodsByProfit(List sales) {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final sale in sales) {
      final name = sale['product']?['name']?.toString() ?? 'Unknown';
      final qty = (sale['quantity'] as num?)?.toInt() ?? 0;
      final revenue = _num(sale['total_price']) - _num(sale['discount_value']);
      final cost = _num(sale['product']?['cost_price']) * qty;

      grouped.putIfAbsent(name, () => {'product': name, 'quantity': 0, 'revenue': 0.0, 'cost': 0.0});
      grouped[name]!['quantity'] += qty;
      grouped[name]!['revenue'] += revenue;
      grouped[name]!['cost'] += cost;
    }

    return grouped.values.map((item) {
      item['profit'] = item['revenue'] - item['cost'];
      return item;
    }).toList();
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
        title: const Text("Profit & Loss",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchReport,
          ),
        ],
      ),
      body: loading
          ? const FullScreenLoader(message: "Loading profit report...")
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
                        _statCard("Total Revenue", _fmtMoney(data['total_revenue']), Colors.green, Icons.trending_up_rounded),
                        const SizedBox(width: 10),
                        _statCard("Cost of Goods", _fmtMoney(data['total_cost']), Colors.red, Icons.shopping_cart_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statCard("Gross Profit", _fmtMoney(data['gross_profit']), Colors.teal, Icons.account_balance_rounded),
                        const SizedBox(width: 10),
                        _statCard("Total Expenses", _fmtMoney(data['total_expenses']), Colors.orange, Icons.money_off_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statCard(
                          "Net Profit / Loss",
                          _fmtMoney(data['net_profit']),
                          (double.tryParse(data['net_profit']?.toString() ?? '0') ?? 0) >= 0
                              ? Colors.green
                              : Colors.red,
                          Icons.equalizer_rounded,
                        ),
                        const SizedBox(width: 10),
                        _statCard("Profit Margin", "${data['profit_margin'] ?? 0}%", accentBlue, Icons.percent_rounded),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // INSIGHTS
                    _sectionTitle("Insights"),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          _insightRow("Best Day", data['best_day']?['date'] ?? '-',
                              _fmtMoney(data['best_day']?['profit']), Colors.green),
                          const SizedBox(height: 8),
                          _insightRow("Worst Day", data['worst_day']?['date'] ?? '-',
                              _fmtMoney(data['worst_day']?['profit']), Colors.red),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // GOODS TABLE
                    _sectionTitle("Goods That Made Profit"),
                    const SizedBox(height: 8),
                    _tableCard(
                      headers: ["Product", "Qty", "Revenue", "Cost", "Profit"],
                      rows: _goodsByProfit(data['sales'] as List? ?? [])
                          .map<List<String>>((g) {
                        return [
                          g['product']?.toString() ?? '-',
                          g['quantity']?.toString() ?? '0',
                          _fmtMoney(g['revenue']),
                          _fmtMoney(g['cost']),
                          _fmtMoney(g['profit']),
                        ];
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _insightRow(String label, String date, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 4, height: 36,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: softBlue, fontSize: 11)),
              Text("$date  •  $value",
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
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
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: headers
                  .map((h) => Expanded(
                        child: Text(h,
                            style: const TextStyle(color: softBlue, fontSize: 11, fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: row
                        .map((cell) => Expanded(
                              child: Text(cell,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                  ),
                )),
        ],
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
              style: TextStyle(color: value != null ? Colors.white : softBlue, fontSize: 13),
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