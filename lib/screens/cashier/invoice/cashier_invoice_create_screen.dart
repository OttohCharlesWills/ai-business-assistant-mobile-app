import 'package:flutter/material.dart';
import '../../../services/cashier_invoice_service.dart';

double parsePrice(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class CashierInvoiceCreateScreen extends StatefulWidget {
  const CashierInvoiceCreateScreen({super.key});

  @override
  State<CashierInvoiceCreateScreen> createState() => _CashierInvoiceCreateScreenState();
}

class _CashierInvoiceCreateScreenState extends State<CashierInvoiceCreateScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool saving = false;

  List customers = [];
  List shops = [];
  List products = [];

  dynamic selectedCustomerId;
  dynamic selectedShopId;

  // Each row: {'productId': dynamic, 'quantity': int}
  final List<Map<String, dynamic>> _goodsRows = [
    {'productId': null, 'quantity': 1}
  ];

  final discountController = TextEditingController(text: '0');
  final taxController = TextEditingController(text: '0');
  String paymentType = 'full';
  final amountPaidController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    fetchCreateData();
    discountController.addListener(() => setState(() {}));
    taxController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    discountController.dispose();
    taxController.dispose();
    amountPaidController.dispose();
    super.dispose();
  }

  Future<void> fetchCreateData() async {
    setState(() => loading = true);
    final response = await CashierInvoiceService.getCreateData();
    if (!mounted) return;
    if (response['status'] == true) {
      final data = response['data'] ?? {};
      setState(() {
        customers = data['customers'] ?? [];
        shops = data['shops'] ?? [];
        products = data['products'] ?? [];
        loading = false;
      });
    } else {
      setState(() => loading = false);
      _showSnack(_extractMessage(response['message']) ?? 'Failed to load invoice data', isError: true);
    }
  }

  dynamic get _selectedCustomer {
    if (selectedCustomerId == null) return null;
    return customers.firstWhere((c) => c['id'] == selectedCustomerId, orElse: () => null);
  }

  List get _shopProducts {
    if (selectedShopId == null) return [];
    return products.where((p) => p['shop_id'] == selectedShopId).toList();
  }

  dynamic _productById(dynamic id) {
    if (id == null) return null;
    return products.firstWhere((p) => p['id'] == id, orElse: () => null);
  }

  double get _rowTotal {
    double sum = 0;
    for (final row in _goodsRows) {
      final product = _productById(row['productId']);
      if (product == null) continue;
      sum += parsePrice(product['price']) * (row['quantity'] as int);
    }
    return sum;
  }

  double get _finalTotal {
    final discount = double.tryParse(discountController.text) ?? 0;
    final tax = double.tryParse(taxController.text) ?? 0;
    final total = _rowTotal - discount + tax;
    return total < 0 ? 0 : total;
  }

  double get _amountPaid {
    if (paymentType == 'full') return _finalTotal;
    return double.tryParse(amountPaidController.text) ?? 0;
  }

  double get _balance => (_finalTotal - _amountPaid).clamp(0, double.infinity);

  void _addRow() {
    setState(() => _goodsRows.add({'productId': null, 'quantity': 1}));
  }

  void _removeRow(int index) {
    if (_goodsRows.length <= 1) return;
    setState(() => _goodsRows.removeAt(index));
  }

  void _onShopChanged(dynamic shopId) {
    setState(() {
      selectedShopId = shopId;
      // Clear product selections that don't belong to the new shop
      for (final row in _goodsRows) {
        final product = _productById(row['productId']);
        if (product == null || product['shop_id'] != shopId) {
          row['productId'] = null;
        }
      }
    });
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
    if (selectedCustomerId == null) {
      _showSnack('Please select a customer', isError: true);
      return;
    }
    if (selectedShopId == null) {
      _showSnack('Please select a shop', isError: true);
      return;
    }

    final goods = <Map<String, dynamic>>[];
    for (final row in _goodsRows) {
      final product = _productById(row['productId']);
      if (product == null) continue;
      final qty = row['quantity'] as int;
      final price = parsePrice(product['price']);
      goods.add({
        'product_id': product['id'],
        'quantity': qty,
        'total_price': price * qty,
      });
    }

    if (goods.isEmpty) {
      _showSnack('Please add at least one product', isError: true);
      return;
    }

    setState(() => saving = true);

    final response = await CashierInvoiceService.createInvoice(
      customerId: selectedCustomerId,
      shopId: selectedShopId,
      goods: goods,
      total: _finalTotal,
      paymentType: paymentType,
      amountPaid: _amountPaid,
      balance: _balance,
      discount: double.tryParse(discountController.text) ?? 0,
      tax: double.tryParse(taxController.text) ?? 0,
    );

    if (!mounted) return;
    setState(() => saving = false);

    if (response['status'] == true) {
      Navigator.pop(context, true);
    } else {
      _showSnack(_extractMessage(response['message']) ?? 'Failed to create invoice', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = _selectedCustomer;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Create Invoice",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _sectionLabel("Customer"),
                _dropdownField<dynamic>(
                  value: selectedCustomerId,
                  hint: "Choose customer",
                  items: customers
                      .map<DropdownMenuItem<dynamic>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? '')))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCustomerId = v),
                ),
                if (customer != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow("Email", customer['email']),
                        _infoRow("Phone", customer['phone']),
                        _infoRow("Company", customer['company']),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                _sectionLabel("Shop"),
                _dropdownField<dynamic>(
                  value: selectedShopId,
                  hint: "Choose shop",
                  items: shops
                      .map<DropdownMenuItem<dynamic>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'] ?? '')))
                      .toList(),
                  onChanged: _onShopChanged,
                ),
                const SizedBox(height: 20),

                _sectionLabel("Products"),
                ..._goodsRows.asMap().entries.map((entry) => _buildGoodsRow(entry.key, entry.value)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: selectedShopId == null ? null : _addRow,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentColor.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, color: subtitleColor, size: 18),
                  label: const Text("Add Product", style: TextStyle(color: subtitleColor)),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: _labeledField("Discount (\u20a6)", discountController)),
                    const SizedBox(width: 12),
                    Expanded(child: _labeledField("Tax (\u20a6)", taxController)),
                  ],
                ),
                const SizedBox(height: 16),

                _totalsCard(),
                const SizedBox(height: 20),

                _sectionLabel("Payment Type"),
                Row(
                  children: [
                    Expanded(
                      child: _paymentTypeChip("Full Payment", 'full'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _paymentTypeChip("Part Payment", 'part'),
                    ),
                  ],
                ),

                if (paymentType == 'part') ...[
                  const SizedBox(height: 16),
                  _labeledField("Amount Paid (\u20a6)", amountPaidController, onChanged: (_) => setState(() {})),
                ],

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Balance", style: TextStyle(color: subtitleColor)),
                      Text(
                        "\u20a6${_balance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _balance > 0 ? Colors.redAccent : Colors.greenAccent,
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
                        : const Text("Create Invoice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      );

  Widget _infoRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text("$label: ", style: const TextStyle(color: subtitleColor, fontSize: 13)),
            Expanded(child: Text((value ?? '-').toString(), style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
      );

  Widget _dropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: cardColor,
        isExpanded: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: subtitleColor, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController controller, {void Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: subtitleColor, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentTypeChip(String label, String value) {
    final selected = paymentType == value;
    return GestureDetector(
      onTap: () => setState(() {
        paymentType = value;
        if (value == 'full') amountPaidController.text = _finalTotal.toStringAsFixed(2);
        if (value == 'part') amountPaidController.text = '0';
      }),
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

  Widget _totalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Final Total", style: TextStyle(color: subtitleColor)),
          Text(
            "\u20a6${_finalTotal.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGoodsRow(int index, Map<String, dynamic> row) {
    final product = _productById(row['productId']);
    final price = product != null ? parsePrice(product['price']) : 0.0;
    final qty = row['quantity'] as int;
    final total = price * qty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<dynamic>(
                  value: row['productId'],
                  dropdownColor: cardColor,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: selectedShopId == null ? "Select shop first" : "Choose product",
                    hintStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                    border: InputBorder.none,
                  ),
                  items: _shopProducts
                      .map<DropdownMenuItem<dynamic>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name'] ?? '')))
                      .toList(),
                  onChanged: selectedShopId == null ? null : (v) => setState(() => row['productId'] = v),
                ),
              ),
              IconButton(
                onPressed: () => _removeRow(index),
                icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Qty: ", style: TextStyle(color: subtitleColor, fontSize: 13)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: subtitleColor, size: 18),
                    onPressed: () {
                      if (qty > 1) setState(() => row['quantity'] = qty - 1);
                    },
                  ),
                  Text('$qty', style: const TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: subtitleColor, size: 18),
                    onPressed: () => setState(() => row['quantity'] = qty + 1),
                  ),
                ],
              ),
              Text(
                "\u20a6${price.toStringAsFixed(2)} × $qty = \u20a6${total.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}