import 'package:flutter/material.dart';
import '../../../services/cashier_invoice_service.dart';
import '../../../widgets/app_loader.dart';

class CashierInvoiceReceivablesScreen extends StatefulWidget {
  const CashierInvoiceReceivablesScreen({super.key});

  @override
  State<CashierInvoiceReceivablesScreen> createState() =>
      _CashierInvoiceReceivablesScreenState();
}

class _CashierInvoiceReceivablesScreenState
    extends State<CashierInvoiceReceivablesScreen> {
  static const bgColor    = Color(0xFF0C1F3F);
  static const cardColor  = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue   = Color(0xFF8FAADC);

  bool loading = false;
  List customers = [];
  double totalReceivable = 0;
  final searchCtrl = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchReceivables();
    searchCtrl.addListener(() {
      setState(() => searchQuery = searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchReceivables() async {
    setState(() => loading = true);

    final res = await CashierInvoiceService.getReceivables();

    if (res['status'] == true) {
      final data = res['data'];
      setState(() {
        customers       = data['customers'] ?? [];
        totalReceivable = double.tryParse(
                data['total_receivable']?.toString() ?? '0') ??
            0;
      });
    }

    setState(() => loading = false);
  }

  List get filtered {
    if (searchQuery.isEmpty) return customers;
    return customers.where((c) {
      final name  = (c['customer']?['name'] ?? '').toString().toLowerCase();
      final phone = (c['customer']?['phone'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || phone.contains(searchQuery);
    }).toList();
  }

  String _fmt(dynamic value) {
    final d = double.tryParse(value?.toString() ?? '0') ?? 0;
    return d.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  // Merge all goods from all invoices for a customer
  List _mergeGoods(List invoices) {
    final Map<String, int> merged = {};
    for (final inv in invoices) {
      final goods = inv['goods'] ?? [];
      for (final item in goods) {
        final name = item['name']?.toString() ?? 'Item';
        final qty  = int.tryParse(
                item['quantity']?.toString() ??
                item['qty']?.toString() ?? '1') ??
            1;
        merged[name] = (merged[name] ?? 0) + qty;
      }
    }
    return merged.entries.map((e) => {'name': e.key, 'qty': e.value}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Receivables",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchReceivables,
          ),
        ],
      ),
      body: loading
          ? const FullScreenLoader(message: "Loading receivables...")
          : RefreshIndicator(
              onRefresh: fetchReceivables,
              color: accentBlue,
              backgroundColor: cardColor,
              child: CustomScrollView(
                slivers: [

                  // Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Search customer name or phone...",
                            hintStyle: TextStyle(color: softBlue, fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded, color: softBlue),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Count
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        "${filtered.length} record${filtered.length == 1 ? '' : 's'}",
                        style: const TextStyle(color: softBlue, fontSize: 13),
                      ),
                    ),
                  ),

                  // List
                  filtered.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
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
                                    Icons.receipt_long_outlined,
                                    size: 40,
                                    color: softBlue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No receivables found",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _CustomerCard(
                                customer: filtered[index],
                                fmt: _fmt,
                                mergeGoods: _mergeGoods,
                              ),
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}


// ─── Customer Card ────────────────────────────────────────────────────────────

class _CustomerCard extends StatefulWidget {
  final Map customer;
  final String Function(dynamic) fmt;
  final List Function(List) mergeGoods;

  const _CustomerCard({
    required this.customer,
    required this.fmt,
    required this.mergeGoods,
  });

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _expanded = false;

  static const cardColor  = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue   = Color(0xFF8FAADC);

  @override
  Widget build(BuildContext context) {
    final c            = widget.customer;
    final customerInfo = c['customer'] ?? {};
    final totalOwing   = double.tryParse(c['total_owing']?.toString() ?? '0') ?? 0;
    final isOwing      = totalOwing > 0;

    // Get shop name from latest invoice
    final invoices     = (c['invoices'] ?? []) as List;
    final shopName     = invoices.isNotEmpty
        ? (invoices.last['shop']?['name'] ?? 'N/A')
        : 'N/A';

    // Merge goods from all invoices
    final goods = widget.mergeGoods(invoices);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwing
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [

          // Main row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Avatar
                CircleAvatar(
                  backgroundColor: isOwing
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  child: Text(
                    (customerInfo['name'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      color: isOwing ? Colors.redAccent : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Name
                      Text(
                        customerInfo['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),

                      // Phone
                      if ((customerInfo['phone'] ?? '').toString().isNotEmpty)
                        Text(
                          customerInfo['phone'],
                          style: const TextStyle(color: softBlue, fontSize: 12),
                        ),

                      // Shop
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          "Shop: $shopName",
                          style: TextStyle(
                            color: softBlue.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Money row
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(),
                          1: FlexColumnWidth(),
                          2: FlexColumnWidth(),
                        },
                        children: [
                          TableRow(
                            children: [
                              _tableLabel("Total Invoice"),
                              _tableLabel("Amount Paid"),
                              _tableLabel("Balance", color: Colors.redAccent),
                            ],
                          ),
                          TableRow(
                            children: [
                              _tableValue("₦${widget.fmt(c['total_invoice'])}", Colors.white),
                              _tableValue("₦${widget.fmt(c['total_paid'])}", Colors.green),
                              _tableValue(
                                isOwing
                                    ? "₦${widget.fmt(c['total_owing'])}"
                                    : "Not owing",
                                isOwing ? Colors.redAccent : Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: softBlue,
                  ),
                ),
              ],
            ),
          ),

          // Expanded goods section
          if (_expanded) ...[
            Divider(height: 1, color: accentBlue.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Goods Purchased:",
                    style: TextStyle(
                      color: softBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (goods.isEmpty)
                    const Text(
                      "No goods found",
                      style: TextStyle(color: softBlue, fontSize: 12),
                    )
                  else
                    ...goods.map((g) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 5, color: softBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  g['name'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                "x${g['qty']}",
                                style: TextStyle(
                                  color: softBlue.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tableLabel(String text, {Color color = softBlue}) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: TextStyle(color: color, fontSize: 10),
        ),
      );

  Widget _tableValue(String text, Color color) => Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}