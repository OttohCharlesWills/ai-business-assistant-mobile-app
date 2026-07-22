import 'package:flutter/material.dart';
import '../../../services/invoice_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map invoice;

  const PaymentScreen({super.key, required this.invoice});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountPaidCtrl = TextEditingController();

  String paymentType = 'part';
  double newBalance = 0;
  bool loading = false;

  double get remainingBalance =>
      double.tryParse(widget.invoice['balance']?.toString() ?? '0') ?? 0;

  double get totalInvoice =>
      double.tryParse(widget.invoice['total']?.toString() ?? '0') ?? 0;

  double get alreadyPaid =>
      double.tryParse(widget.invoice['amount_paid']?.toString() ?? '0') ?? 0;

  @override
  void initState() {
    super.initState();

    // default payment type based on balance
    paymentType = remainingBalance <= 0 ? 'full' : 'part';

    // pre-fill with remaining balance (like web)
    amountPaidCtrl.text = remainingBalance.toStringAsFixed(2);
    newBalance = 0;

    amountPaidCtrl.addListener(_calculateNewBalance);
  }

  @override
  void dispose() {
    amountPaidCtrl.dispose();
    super.dispose();
  }

  void _calculateNewBalance() {
    final paid = double.tryParse(amountPaidCtrl.text) ?? 0;
    setState(() => newBalance = remainingBalance - paid);
  }

  String _fmt(double value) {
    return value.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    final paid = double.tryParse(amountPaidCtrl.text) ?? 0;

    if (paid > remainingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment exceeds remaining balance"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final res = await InvoiceService.updatePayment(
      invoiceId: widget.invoice['id'],
      amountPaid: paid,
      paymentType: paymentType,
    );

    setState(() => loading = false);

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // return true so parent can refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final customerName = inv['customer']?['name'] ?? 'N/A';
    final shopName = inv['shop']?['name'] ?? 'N/A';
    final invoiceNumber = inv['invoice_number'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Update Payment",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invoice $invoiceNumber",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      shopName,
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary row
              Row(
                children: [
                  Expanded(child: _summaryTile("Total Invoice", "₦${_fmt(totalInvoice)}", Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryTile("Amount Paid", "₦${_fmt(alreadyPaid)}", Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryTile("Balance", "₦${_fmt(remainingBalance)}", Colors.red)),
                ],
              ),

              const SizedBox(height: 24),

              // Payment type
              _label("Payment Type"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: paymentType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'full', child: Text("Full Payment")),
                      DropdownMenuItem(value: 'part', child: Text("Part Payment")),
                    ],
                    onChanged: (v) => setState(() => paymentType = v!),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Amount to pay
              _label("Payment Amount"),
              TextFormField(
                controller: amountPaidCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeco("Enter amount"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return "Enter a valid amount";
                  if (val > remainingBalance) return "Cannot exceed balance of ₦${_fmt(remainingBalance)}";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // New balance (calculated, readonly)
              _label("New Balance After Payment"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: newBalance <= 0 ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: newBalance <= 0 ? Colors.green.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      newBalance <= 0 ? Icons.check_circle_outline : Icons.info_outline,
                      color: newBalance <= 0 ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      newBalance <= 0 ? "Fully paid ✓" : "₦${_fmt(newBalance)} remaining",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: newBalance <= 0 ? Colors.green : Colors.orange.shade800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Payment",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Back button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Back", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      );

  Widget _summaryTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}