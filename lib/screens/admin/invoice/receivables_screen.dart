import 'package:flutter/material.dart';
import '../../../services/invoice_service.dart';

class ReceivablesScreen extends StatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  State<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends State<ReceivablesScreen> {
  Map<String, dynamic>? data;
  bool loading = false;
  String searchQuery = '';

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReceivables();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchReceivables({bool refresh = false}) async {
    setState(() => loading = true);
    final result = await InvoiceService.getReceivables(refresh: refresh);
    setState(() {
      data = result;
      loading = false;
    });
  }

  List get customers {
    final all = data?['customers'] ?? [];
    if (searchQuery.isEmpty) return all;
    return all.where((c) {
      final name = (c['customer']?['name'] ?? '').toString().toLowerCase();
      final phone = (c['customer']?['phone'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || phone.contains(searchQuery);
    }).toList();
  }

  double get totalReceivable =>
      double.tryParse(data?['total_receivable']?.toString() ?? '0') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Receivables", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchReceivables(refresh: true),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => fetchReceivables(refresh: true),
              child: CustomScrollView(
                slivers: [
                  // Total receivables card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Receivables",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "₦${_fmt(totalReceivable)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${customers.length} customer${customers.length == 1 ? '' : 's'} owing",
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Search customer name or phone...",
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                  ),

                  // Results count
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Text(
                        "${customers.length} record${customers.length == 1 ? '' : 's'}",
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ),

                  // Customer list
                  customers.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isEmpty
                                      ? "No receivables found."
                                      : "No customer matches your search.",
                                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final c = customers[index];
                                return _CustomerReceivableCard(customer: c);
                              },
                              childCount: customers.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  String _fmt(double value) {
    return value.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}


// ─── Customer Receivable Card ─────────────────────────────────────────────────

class _CustomerReceivableCard extends StatefulWidget {
  final Map customer;
  const _CustomerReceivableCard({required this.customer});

  @override
  State<_CustomerReceivableCard> createState() => _CustomerReceivableCardState();
}

class _CustomerReceivableCardState extends State<_CustomerReceivableCard> {
  bool expanded = false;

  String _fmt(dynamic value) {
    final d = double.tryParse(value?.toString() ?? '0') ?? 0;
    return d.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final customerInfo = c['customer'] ?? {};
    final shopInfo = c['shop'] ?? {};
    final totalOwing = double.tryParse(c['total_owing']?.toString() ?? '0') ?? 0;
    final isOwing = totalOwing > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOwing ? Colors.red.shade100 : Colors.green.shade100,
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
                  backgroundColor: isOwing ? Colors.red.shade50 : Colors.green.shade50,
                  child: Text(
                    (customerInfo['name'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      color: isOwing ? Colors.red : Colors.green,
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
                      Text(
                        customerInfo['name'] ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      if ((customerInfo['phone'] ?? '').toString().isNotEmpty)
                        Text(
                          customerInfo['phone'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      if ((shopInfo['name'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "Shop: ${shopInfo['name']}",
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Money chips row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip("Invoice: ₦${_fmt(c['total_invoice'])}", Colors.blue.shade50, Colors.blue),
                          _chip("Paid: ₦${_fmt(c['total_paid'])}", Colors.green.shade50, Colors.green),
                          _chip(
                            isOwing ? "Owes: ₦${_fmt(c['total_owing'])}" : "Not owing",
                            isOwing ? Colors.red.shade50 : Colors.green.shade50,
                            isOwing ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expand toggle
                GestureDetector(
                  onTap: () => setState(() => expanded = !expanded),
                  child: Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Expanded goods list
          if (expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            _GoodsList(customer: c),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: text, fontWeight: FontWeight.w500)),
    );
  }
}


// ─── Goods List (expanded section) ───────────────────────────────────────────

class _GoodsList extends StatefulWidget {
  final Map customer;
  const _GoodsList({required this.customer});

  @override
  State<_GoodsList> createState() => _GoodsListState();
}

class _GoodsListState extends State<_GoodsList> {
  Map<String, dynamic>? invoiceData;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    setState(() => loading = true);

    // search invoices for this customer using their name
    final name = widget.customer['customer']?['name'] ?? '';
    final result = await InvoiceService.searchInvoice(name);

    setState(() {
      invoiceData = result;
      loading = false;
    });
  }

  List _mergeGoods(List invoices) {
    final Map<String, int> merged = {};
    for (final inv in invoices) {
      final goods = inv['goods'] ?? [];
      for (final item in goods) {
        final name = item['name'] ?? 'Item';
        final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        merged[name] = (merged[name] ?? 0) + qty;
      }
    }
    return merged.entries.map((e) => {'name': e.key, 'qty': e.value}).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final invoices = invoiceData?['invoices'] ?? [];
    final goods = _mergeGoods(invoices);

    if (goods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No goods found.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Goods purchased:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...goods.map((g) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        g['name'],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      "x${g['qty']}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}