import 'package:flutter/material.dart';
import '../../../services/cashier_invoice_service.dart';

class CashierInvoiceEditPaymentScreen extends StatefulWidget {
  final int invoiceId;
  const CashierInvoiceEditPaymentScreen({super.key, required this.invoiceId});

  @override
  State<CashierInvoiceEditPaymentScreen> createState() => _CashierInvoiceEditPaymentScreenState();
}

class _CashierInvoiceEditPaymentScreenState extends State<CashierInvoiceEditPaymentScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool saving = false;
  Map<String, dynamic>? invoice;

  String paymentType = 'part';
  final amountPaidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInvoice();
  }

  @override
  void dispose() {
    amountPaidController.dispose();
    super.dispose();
  }

  Future<void> fetchInvoice() async {
    setState(() => loading = true);
    final response = await CashierInvoiceService.getInvoice(widget.invoiceId);
    if (!mounted) return;
    if (response['status'] == true) {
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final balance = double.tryParse(data['balance'].toString()) ?? 0;
      setState(() {
        invoice = data;
        paymentType = balance <= 0 ? 'full' : 'part';
        amountPaidController.text = balance.toStringAsFixed(2);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      _showSnack(_extractMessage(response['message']) ?? 'Failed to load invoice', isError: true);
    }
  }

  double get _remainingBalance => double.tryParse(invoice?['balance']?.toString() ?? '0') ?? 0;

  double get _newBalance {
    final paid = double.tryParse(amountPaidController.text) ?? 0;
    final result = _remainingBalance - paid;
    return result < 0 ? 0 : result;
  }

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

  Future<void> _submit() async {
    final amountPaid = double.tryParse(amountPaidController.text);
    if (amountPaid == null || amountPaid <= 0) {
      _showSnack('Please enter a valid payment amount', isError: true);
      return;
    }
    if (amountPaid > _remainingBalance) {
      _showSnack('Payment exceeds remaining balance', isError: true);
      return;
    }

    setState(() => saving = true);

    final response = await CashierInvoiceService.addPayment(
      invoiceId: widget.invoiceId,
      amountPaid: amountPaid,
      paymentType: paymentType,
    );

    if (!mounted) return;
    setState(() => saving = false);

    if (response['status'] == true) {
      Navigator.pop(context, true);
    } else {
      _showSnack(_extractMessage(response['message']) ?? 'Failed to update payment', isError: true);
    }
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
        title: Text(
          invoice != null ? "Invoice ${invoice!['invoice_number']}" : "Edit Payment",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : invoice == null
              ? const Center(child: Text("Invoice not found", style: TextStyle(color: subtitleColor)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _readonlyField("Customer", invoice!['customer']?['name']),
                    const SizedBox(height: 12),
                    _readonlyField("Shop", invoice!['shop']?['name']),
                    const SizedBox(height: 12),
                    _readonlyField("Total Invoice Amount", "\u20a6${double.tryParse(invoice!['total'].toString())?.toStringAsFixed(2) ?? '0.00'}"),
                    const SizedBox(height: 12),
                    _readonlyField("Amount Already Paid", "\u20a6${double.tryParse(invoice!['amount_paid'].toString())?.toStringAsFixed(2) ?? '0.00'}"),
                    const SizedBox(height: 12),
                    _readonlyField("Remaining Balance", "\u20a6${_remainingBalance.toStringAsFixed(2)}"),
                    const SizedBox(height: 20),

                    const Text("Payment Type", style: TextStyle(color: subtitleColor, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _paymentTypeChip("Full Payment", 'full')),
                        const SizedBox(width: 10),
                        Expanded(child: _paymentTypeChip("Part Payment", 'part')),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text("Payment Amount", style: TextStyle(color: subtitleColor, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: amountPaidController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("New Balance", style: TextStyle(color: subtitleColor)),
                          Text(
                            "\u20a6${_newBalance.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: _newBalance > 0 ? Colors.redAccent : Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: saving ? null : _submit,
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Update Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _readonlyField(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: subtitleColor, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: Text((value ?? '-').toString(), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _paymentTypeChip(String label, String value) {
    final selected = paymentType == value;
    return GestureDetector(
      onTap: () => setState(() => paymentType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accentColor : cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : subtitleColor, fontWeight: FontWeight.w600)),
      ),
    );
  }
}