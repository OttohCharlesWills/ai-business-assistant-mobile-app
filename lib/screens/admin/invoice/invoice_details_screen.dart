import 'package:flutter/material.dart';
import '../../../services/invoice_service.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {

  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  bool loading = true;
  Map<String, dynamic>? invoice;

  @override
  void initState() {
    super.initState();
    loadInvoice();
  }

  Future<void> loadInvoice() async {
    setState(() => loading = true);
    final data = await InvoiceService.getInvoice(widget.invoiceId);
    setState(() {
      invoice = data;
      loading = false;
    });
  }

  String _formatMoney(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return "₦${number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    )}";
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  bool get isPaid => invoice?['payment_status'] == 'paid';
  bool get isOwing => invoice?['payment_status'] == 'owing';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          loading
              ? "Invoice"
              : "#${invoice?['invoice_number'] ?? ''}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: loadInvoice,
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: accentBlue))
          : invoice == null
              ? const Center(
                  child: Text(
                    "Invoice not found",
                    style: TextStyle(color: softBlue),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // HEADER CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "INVOICE",
                                      style: TextStyle(
                                        color: softBlue,
                                        fontSize: 12,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "#${invoice!['invoice_number']}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // STATUS BADGE
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isPaid
                                          ? Colors.green.withOpacity(0.4)
                                          : Colors.redAccent.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isPaid ? "Fully Paid" : "Owing",
                                    style: TextStyle(
                                      color: isPaid
                                          ? Colors.green
                                          : Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // SALES MAN
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    color: softBlue, size: 16),
                                const SizedBox(width: 6),
                                const Text(
                                  "Sales Man: ",
                                  style: TextStyle(
                                      color: softBlue, fontSize: 13),
                                ),
                                Text(
                                  invoice!['user']?['name'] ?? 'N/A',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // DATE
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: softBlue, size: 16),
                                const SizedBox(width: 6),
                                const Text(
                                  "Date: ",
                                  style: TextStyle(
                                      color: softBlue, fontSize: 13),
                                ),
                                Text(
                                  _formatDate(invoice!['invoice_date']),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // BILLED TO
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "BILLED TO",
                              style: TextStyle(
                                color: softBlue,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              invoice!['customer']?['name'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoice!['customer']?['email'] ?? '',
                              style: const TextStyle(
                                  color: softBlue, fontSize: 13),
                            ),
                            Text(
                              invoice!['customer']?['phone'] ?? '',
                              style: const TextStyle(
                                  color: softBlue, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // AMOUNT SUMMARY
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: accentBlue.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            _summaryRow("Total Amount",
                                _formatMoney(invoice!['total']),
                                isBold: true, isLarge: true),
                            const SizedBox(height: 8),
                            _summaryRow("Amount Paid",
                                _formatMoney(invoice!['amount_paid'])),
                            const SizedBox(height: 8),
                            _summaryRow("Discount",
                                _formatMoney(invoice!['discount'] ?? 0)),
                            const SizedBox(height: 8),
                            _summaryRow("Tax",
                                _formatMoney(invoice!['tax'] ?? 0)),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white24),
                            ),
                            _summaryRow(
                              "Balance",
                              _formatMoney(invoice!['balance'] ?? 0),
                              isBold: true,
                              valueColor: isOwing
                                  ? Colors.redAccent
                                  : Colors.green,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // GOODS LIST
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ITEMS",
                              style: TextStyle(
                                color: softBlue,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // TABLE HEADER
                            Row(
                              children: const [
                                Expanded(
                                    flex: 3,
                                    child: Text("Product",
                                        style: TextStyle(
                                            color: softBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                                Expanded(
                                    child: Text("Qty",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: softBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                                Expanded(
                                    flex: 2,
                                    child: Text("Total",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            color: softBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                              ],
                            ),

                            const Divider(color: Colors.white12),

                            // GOODS ROWS
                            ...(() {
                              final goods = invoice!['goods'];
                              if (goods == null) return <Widget>[];

                              List goodsList = goods is List
                                  ? goods
                                  : (goods is String
                                      ? []
                                      : []);

                              return goodsList.map<Widget>((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          item['name'] ??
                                              'Product #${item['product_id']}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "${item['quantity']}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: softBlue,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatMoney(
                                              item['total_price'] ?? 0),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();
                            })(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // SHOP INFO
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.store_rounded,
                                color: softBlue, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text("Shop",
                                    style: TextStyle(
                                        color: softBlue, fontSize: 12)),
                                Text(
                                  invoice!['shop']?['name'] ?? 'N/A',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // DOWNLOAD PDF BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A2E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final url = InvoiceService.downloadInvoice(
                                widget.invoiceId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Download URL: $url"),
                                backgroundColor: accentBlue,
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white),
                          label: const Text(
                            "Download PDF",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: softBlue, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: isLarge ? 20 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}