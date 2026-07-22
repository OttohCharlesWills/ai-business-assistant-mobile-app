import 'package:flutter/material.dart';
import '../../../services/invoice_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {

  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  bool loading = true;
  bool submitting = false;

  List customers = [];
  List shops = [];
  List allProducts = [];

  int? selectedCustomerId;
  int? selectedShopId;
  String? selectedCustomerEmail;
  String? selectedCustomerPhone;
  String? selectedCustomerCompany;

  String paymentType = 'full';
  double discount = 0;
  double tax = 0;
  double amountPaid = 0;

  // PRODUCT ROWS
  List<Map<String, dynamic>> productRows = [
    {'product_id': null, 'quantity': 1, 'price': 0.0, 'total': 0.0}
  ];

  @override
  void initState() {
    super.initState();
    loadCreateData();
  }

  Future<void> loadCreateData() async {
    setState(() => loading = true);
    final data = await InvoiceService.getCreateData(refresh: true);
    if (data != null) {
      setState(() {
        customers = data['customers'] ?? [];
        shops = data['shops'] ?? [];
        allProducts = data['products'] ?? [];
      });
    }
    setState(() => loading = false);
  }

  List get filteredProducts {
    if (selectedShopId == null) return [];
    return allProducts
        .where((p) => p['shop_id'] == selectedShopId)
        .toList();
  }

  double get subtotal {
    return productRows.fold(0.0, (sum, row) => sum + (row['total'] as double));
  }

  double get finalTotal => subtotal - discount + tax;

  double get balance {
    if (paymentType == 'full') return 0;
    return finalTotal - amountPaid;
  }

  void _onProductSelected(int rowIndex, int? productId) {
    if (productId == null) return;
    final product = allProducts.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => {},
    );
    setState(() {
      productRows[rowIndex]['product_id'] = productId;
      productRows[rowIndex]['price'] =
          double.tryParse(product['price'].toString()) ?? 0.0;
      productRows[rowIndex]['total'] =
          productRows[rowIndex]['price'] *
              productRows[rowIndex]['quantity'];
    });
  }

  void _onQuantityChanged(int rowIndex, int qty) {
    setState(() {
      productRows[rowIndex]['quantity'] = qty;
      productRows[rowIndex]['total'] =
          productRows[rowIndex]['price'] * qty;
    });
  }

  void _addProductRow() {
    setState(() {
      productRows.add(
          {'product_id': null, 'quantity': 1, 'price': 0.0, 'total': 0.0});
    });
  }

  void _removeProductRow(int index) {
    if (productRows.length == 1) return;
    setState(() => productRows.removeAt(index));
  }

  List<Map<String, dynamic>> get goodsPayload {
    final List<Map<String, dynamic>> goods = [];
    for (final row in productRows) {
      if (row['product_id'] == null) continue;
      final itemTotal = row['total'] as double;
      final itemDiscount = subtotal > 0
          ? (itemTotal / subtotal) * discount
          : 0.0;
      goods.add({
        'product_id': row['product_id'],
        'quantity': row['quantity'],
        'total_price': itemTotal - itemDiscount,
      });
    }
    return goods;
  }

  Future<void> _submitInvoice() async {
    if (selectedCustomerId == null) {
      _showSnack("Please select a customer", Colors.orange);
      return;
    }
    if (selectedShopId == null) {
      _showSnack("Please select a shop", Colors.orange);
      return;
    }
    if (goodsPayload.isEmpty) {
      _showSnack("Please add at least one product", Colors.orange);
      return;
    }

    setState(() => submitting = true);

    final res = await InvoiceService.createInvoice(
      customerId: selectedCustomerId!,
      shopId: selectedShopId!,
      goods: goodsPayload,
      total: finalTotal,
      paymentType: paymentType,
      amountPaid: paymentType == 'full' ? finalTotal : amountPaid,
      balance: balance,
      discount: discount,
      tax: tax,
    );

    setState(() => submitting = false);

    if (!mounted) return;

    if (res['status'] == true) {
      _showSnack("Invoice created successfully 🎉", accentBlue);
      Navigator.pop(context, true);
    } else {
      _showSnack(res['message'] ?? "Something went wrong", Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
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
        title: const Text(
          "Create Invoice",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: accentBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // CUSTOMER
                  _sectionTitle("Select Customer"),
                  const SizedBox(height: 8),
                  _dropdown<int>(
                    hint: "-- Choose Customer --",
                    value: selectedCustomerId,
                    items: customers.map<DropdownMenuItem<int>>((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name'],
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final customer = customers.firstWhere(
                          (c) => c['id'] == val,
                          orElse: () => {});
                      setState(() {
                        selectedCustomerId = val;
                        selectedCustomerEmail = customer['email'];
                        selectedCustomerPhone = customer['phone'];
                        selectedCustomerCompany = customer['company'];
                      });
                    },
                  ),

                  // CUSTOMER INFO
                  if (selectedCustomerId != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _infoRow("Email",
                              selectedCustomerEmail ?? '-'),
                          _infoRow("Phone",
                              selectedCustomerPhone ?? '-'),
                          _infoRow("Company",
                              selectedCustomerCompany ?? '-'),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // SHOP
                  _sectionTitle("Select Shop"),
                  const SizedBox(height: 8),
                  _dropdown<int>(
                    hint: "-- Choose Shop --",
                    value: selectedShopId,
                    items: shops.map<DropdownMenuItem<int>>((s) {
                      return DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text(s['name'],
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedShopId = val;
                        // RESET PRODUCT ROWS
                        productRows = [
                          {
                            'product_id': null,
                            'quantity': 1,
                            'price': 0.0,
                            'total': 0.0
                          }
                        ];
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  // PRODUCTS
                  _sectionTitle("Add Products"),
                  const SizedBox(height: 8),

                  ...List.generate(productRows.length, (index) {
                    final row = productRows[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          // PRODUCT DROPDOWN
                          DropdownButtonFormField<int>(
                            value: row['product_id'],
                            dropdownColor: bgColor,
                            style: const TextStyle(color: Colors.white),
                            hint: const Text("-- Choose Product --",
                                style: TextStyle(color: softBlue)),
                            decoration: _inputDec(),
                            items: filteredProducts
                                .map<DropdownMenuItem<int>>((p) {
                              return DropdownMenuItem<int>(
                                value: p['id'],
                                child: Text(p['name'],
                                    style: const TextStyle(
                                        color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: selectedShopId == null
                                ? null
                                : (val) => _onProductSelected(index, val),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              // QUANTITY
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      row['quantity'].toString(),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      color: Colors.white),
                                  decoration: _inputDec(hint: "Qty"),
                                  onChanged: (val) {
                                    final qty =
                                        int.tryParse(val) ?? 1;
                                    _onQuantityChanged(index, qty);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),

                              // PRICE
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "₦${row['price'].toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        color: softBlue, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // TOTAL
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "₦${row['total'].toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // REMOVE
                              GestureDetector(
                                onTap: () =>
                                    _removeProductRow(index),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  // ADD PRODUCT BUTTON
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: accentBlue.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _addProductRow,
                    icon: const Icon(Icons.add_rounded, color: softBlue),
                    label: const Text("Add Product",
                        style: TextStyle(color: softBlue)),
                  ),

                  const SizedBox(height: 18),

                  // DISCOUNT + TAX
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Discount"),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: '0',
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white),
                              decoration:
                                  _inputDec(hint: "0.00", prefix: "₦"),
                              onChanged: (val) => setState(() =>
                                  discount =
                                      double.tryParse(val) ?? 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Tax"),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: '0',
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white),
                              decoration:
                                  _inputDec(hint: "0.00", prefix: "₦"),
                              onChanged: (val) => setState(
                                  () => tax = double.tryParse(val) ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // FINAL TOTAL
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Final Total",
                            style: TextStyle(
                                color: softBlue, fontSize: 14)),
                        Text(
                          "₦${finalTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // PAYMENT TYPE
                  _sectionTitle("Payment Type"),
                  const SizedBox(height: 8),
                  _dropdown<String>(
                    hint: "Select Payment Type",
                    value: paymentType,
                    items: const [
                      DropdownMenuItem(
                        value: 'full',
                        child: Text("Full Payment",
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'part',
                        child: Text("Part Payment",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => paymentType = val!),
                  ),

                  // AMOUNT PAID (only for part payment)
                  if (paymentType == 'part') ...[
                    const SizedBox(height: 18),
                    _sectionTitle("Amount Paid"),
                    const SizedBox(height: 8),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _inputDec(hint: "0.00", prefix: "₦"),
                      onChanged: (val) => setState(
                          () => amountPaid = double.tryParse(val) ?? 0),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // BALANCE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: balance > 0
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: balance > 0
                            ? Colors.redAccent.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Balance",
                            style: TextStyle(
                                color: softBlue, fontSize: 14)),
                        Text(
                          "₦${balance.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: balance > 0
                                ? Colors.redAccent
                                : Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // SUBMIT
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: submitting ? null : _submitInvoice,
                      child: submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Create Invoice",
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

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(color: softBlue, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: bgColor,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: softBlue)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  InputDecoration _inputDec({String? hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: softBlue, fontSize: 14),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}