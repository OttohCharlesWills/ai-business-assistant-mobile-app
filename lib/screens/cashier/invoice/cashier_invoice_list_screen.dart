import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/cashier_invoice_service.dart';
import 'cashier_invoice_create_screen.dart';
import 'cashier_invoice_edit_payment_screen.dart';

class CashierInvoiceListScreen extends StatefulWidget {
  const CashierInvoiceListScreen({super.key});

  @override
  State<CashierInvoiceListScreen> createState() => _CashierInvoiceListScreenState();
}

class _CashierInvoiceListScreenState extends State<CashierInvoiceListScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  List invoices = [];
  int totalInvoices = 0;
  int owingCount = 0;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchInvoices() async {
    setState(() => loading = true);
    final response = await CashierInvoiceService.getInvoices();
    if (!mounted) return;
    if (response['status'] == true) {
      final data = response['data'] ?? {};
      setState(() {
        invoices = data['all_invoices'] ?? [];
        totalInvoices = data['total_invoices'] ?? invoices.length;
        owingCount = (data['owing_invoices'] as List? ?? []).length;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().isEmpty) {
        fetchInvoices();
        return;
      }
      setState(() => loading = true);
      final response = await CashierInvoiceService.searchInvoices(value.trim());
      if (!mounted) return;
      if (response['status'] == true) {
        final data = response['data'] ?? {};
        setState(() {
          invoices = data['invoices'] ?? [];
          totalInvoices = data['total_invoices'] ?? invoices.length;
          owingCount = (data['owing_invoices'] as List? ?? []).length;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    });
  }

  String formatMoney(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return "\u20a6${number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    )}";
  }

  Future<void> _markPaid(int id) async {
    final response = await CashierInvoiceService.markPaid(id);
    if (!mounted) return;
    if (response['status'] == true) {
      fetchInvoices();
      _showSnack('Invoice marked as paid');
    } else {
      _showSnack(_extractMessage(response['message']) ?? 'Failed to mark as paid', isError: true);
    }
  }

  void _showPreview(Map invoice) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invoice['invoice_number'] ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _previewRow("Customer", invoice['customer']?['name']),
              _previewRow("Shop", invoice['shop']?['name']),
              _previewRow("Total", formatMoney(invoice['total'])),
              _previewRow("Amount Paid", formatMoney(invoice['amount_paid'])),
              _previewRow("Balance", formatMoney(invoice['balance'])),
              _previewRow("Payment Type", invoice['payment_type']),
              _previewRow("Status", invoice['payment_status']),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: accentColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: subtitleColor, fontSize: 13)),
            Text((value ?? '-').toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String? _extractMessage(dynamic message) {
    if (message == null) return null;
    if (message is String) return message;
    if (message is Map) {
      return message.values.expand((v) => v is List ? v : [v]).join(', ');
    }
    return message.toString();
  }

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : accentColor,
        duration: const Duration(seconds: 2),
      ),
    );
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
          "Invoices",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchInvoices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CashierInvoiceCreateScreen()),
          );
          if (created == true) fetchInvoices();
        },
        backgroundColor: accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Invoice", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // STAT CARDS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _statCard(Icons.people_alt_rounded, "Owing", "$owingCount", Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(Icons.receipt_long_rounded, "Total Invoices", "$totalInvoices", accentColor),
                ),
              ],
            ),
          ),

          // SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search customer name or phone...',
                hintStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: subtitleColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: subtitleColor),
                        onPressed: () {
                          _searchController.clear();
                          fetchInvoices();
                        },
                      )
                    : null,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: accentColor))
                : invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.receipt_long_outlined, size: 48, color: subtitleColor),
                            ),
                            const SizedBox(height: 20),
                            const Text("No invoices found", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            const Text("Tap + New Invoice to create one", style: TextStyle(color: subtitleColor, fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchInvoices,
                        color: accentColor,
                        backgroundColor: cardColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = invoices[index];
                            final balance = double.tryParse(invoice['balance'].toString()) ?? 0;
                            final isPaid = invoice['payment_status'] == 'paid';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              invoice['customer']?['name'] ?? 'Unknown',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                            ),
                                            Text(
                                              invoice['invoice_number'] ?? '',
                                              style: const TextStyle(color: subtitleColor, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPaid ? Colors.green.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          (invoice['payment_status'] ?? '').toString().toUpperCase(),
                                          style: TextStyle(
                                            color: isPaid ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _miniStat("Total", formatMoney(invoice['total'])),
                                      _miniStat("Paid", formatMoney(invoice['amount_paid'])),
                                      _miniStat("Balance", formatMoney(invoice['balance']), highlight: balance > 0),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: accentColor.withOpacity(0.4)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => _showPreview(invoice),
                                          child: const Text("Preview", style: TextStyle(color: subtitleColor, fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: accentColor.withOpacity(0.4)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: balance <= 0
                                              ? null
                                              : () async {
                                                  final updated = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => CashierInvoiceEditPaymentScreen(invoiceId: invoice['id']),
                                                    ),
                                                  );
                                                  if (updated == true) fetchInvoices();
                                                },
                                          child: const Text("Edit", style: TextStyle(color: subtitleColor, fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade600,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: balance <= 0 ? null : () => _markPaid(invoice['id']),
                                          child: const Text("Mark Paid", style: TextStyle(color: Colors.white, fontSize: 12)),
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
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: subtitleColor, fontSize: 10)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.redAccent : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}