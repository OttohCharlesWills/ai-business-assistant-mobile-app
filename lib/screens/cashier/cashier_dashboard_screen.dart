import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/cashier_dashboard_service.dart';
import '../../widgets/cashier_side_nav.dart';

// Laravel returns decimal columns (like price) as STRINGS in JSON
// unless the model casts them — this handles both String and num safely.
double parsePrice(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool _loading = true;
  List<dynamic> _categories = [];
  dynamic _selectedCategoryId;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;

  final List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHome() async {
    setState(() => _loading = true);
    final data = await CashierDashboardService.getHome();
    if (!mounted) return;
    if (data['success'] == true) {
      final categories = List<dynamic>.from(data['categories'] ?? []);
      setState(() {
        _categories = categories;
        _selectedCategoryId = categories.isNotEmpty ? categories.first['id'] : null;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _showSnack(_extractMessage(data['message']) ?? 'Failed to load dashboard', isError: true);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final data = await CashierDashboardService.searchProductSuggestions(value.trim());
      if (!mounted) return;

      // Real response shape: {status: true, data: [...] or single object}
      List<dynamic> results = [];
      if (data is Map && data['status'] == true) {
        final inner = data['data'];
        if (inner is List) {
          results = inner;
        } else if (inner is Map && inner.isNotEmpty) {
          results = [inner];
        }
      }

      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  List<dynamic> get _visibleProducts {
    if (_searchController.text.trim().isNotEmpty) return _searchResults;
    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => null,
    );
    if (category == null) return [];
    return List<dynamic>.from(category['products'] ?? []);
  }

  int get _cartItemCount => _cart.fold(0, (sum, item) => sum + (item['quantity'] as int));

  double _cartLineTotal(Map<String, dynamic> item) {
    final price = parsePrice(item['product']['price']);
    final qty = item['quantity'] as int;
    final subtotal = price * qty;
    double discount = 0;
    if (item['discount_type'] == 'percentage') {
      discount = subtotal * (item['discount_value'] as num) / 100;
    } else if (item['discount_type'] == 'flat') {
      discount = (item['discount_value'] as num).toDouble();
    }
    final total = subtotal - discount;
    return total < 0 ? 0 : total;
  }

  double get _cartTotal => _cart.fold(0.0, (sum, item) => sum + _cartLineTotal(item));

  void _addToCart(Map<String, dynamic> product, int quantity, String discountType, double discountValue) {
    final stock = product['stock_quantity'] is num ? (product['stock_quantity'] as num).toInt() : null;
    final existingIndex = _cart.indexWhere((item) => item['product']['id'] == product['id']);

    if (existingIndex != -1) {
      final newQty = (_cart[existingIndex]['quantity'] as int) + quantity;
      if (stock != null && newQty > stock) {
        _showSnack('Only $stock in stock', isError: true);
        return;
      }
      setState(() {
        _cart[existingIndex]['quantity'] = newQty;
        _cart[existingIndex]['discount_type'] = discountType;
        _cart[existingIndex]['discount_value'] = discountValue;
      });
    } else {
      if (stock != null && quantity > stock) {
        _showSnack('Only $stock in stock', isError: true);
        return;
      }
      setState(() {
        _cart.add({
          'product': product,
          'quantity': quantity,
          'discount_type': discountType,
          'discount_value': discountValue,
        });
      });
    }
    _showSnack('${product['name']} added to cart');
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Stock X",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                onPressed: _cart.isEmpty ? null : _showCartSheet,
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_cartItemCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const CashierSideNav(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : RefreshIndicator(
              color: accentColor,
              backgroundColor: cardColor,
              onRefresh: _loadHome,
              child: Column(
                children: [
                  _buildSearchBar(),
                  if (_searchController.text.trim().isEmpty) _buildCategoryTabs(),
                  Expanded(child: _buildProductGrid()),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search or scan product...',
          hintStyle: const TextStyle(color: subtitleColor),
          prefixIcon: const Icon(Icons.search, color: subtitleColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: subtitleColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                )
              : null,
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category['id'] == _selectedCategoryId;
          return ChoiceChip(
            label: Text(category['name'] ?? ''),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategoryId = category['id']),
            selectedColor: accentColor,
            backgroundColor: cardColor,
            labelStyle: TextStyle(color: isSelected ? Colors.white : subtitleColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    final products = _visibleProducts;

    if (products.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().isNotEmpty ? 'No products found' : 'No products in this category',
          style: const TextStyle(color: subtitleColor),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = Map<String, dynamic>.from(products[index]);
        return _ProductCard(
          product: product,
          onTap: () => _showAddToCartSheet(product),
        );
      },
    );
  }

  void _showAddToCartSheet(Map<String, dynamic> product) {
    int quantity = 1;
    String discountType = 'none';
    final discountController = TextEditingController(text: '0');
    final stock = product['stock_quantity'] is num ? (product['stock_quantity'] as num).toInt() : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final price = parsePrice(product['price']);
            final discountValue = double.tryParse(discountController.text) ?? 0;
            double lineTotal = price * quantity;
            if (discountType == 'percentage') {
              lineTotal -= lineTotal * discountValue / 100;
            } else if (discountType == 'flat') {
              lineTotal -= discountValue;
            }
            if (lineTotal < 0) lineTotal = 0;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '\u20a6${price.toStringAsFixed(2)}${stock != null ? '  •  $stock in stock' : ''}',
                    style: const TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity', style: TextStyle(color: Colors.white)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: subtitleColor),
                            onPressed: () {
                              if (quantity > 1) setSheetState(() => quantity--);
                            },
                          ),
                          Text('$quantity', style: const TextStyle(color: Colors.white, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: subtitleColor),
                            onPressed: () {
                              if (stock == null || quantity < stock) {
                                setSheetState(() => quantity++);
                              } else {
                                _showSnack('Only $stock in stock', isError: true);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: discountType,
                          dropdownColor: cardColor,
                          style: const TextStyle(color: Colors.white),
                          decoration: _sheetFieldDecoration('Discount'),
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('None')),
                            DropdownMenuItem(value: 'percentage', child: Text('Percentage %')),
                            DropdownMenuItem(value: 'flat', child: Text('Flat \u20a6')),
                          ],
                          onChanged: (value) => setSheetState(() => discountType = value ?? 'none'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: discountController,
                          enabled: discountType != 'none',
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _sheetFieldDecoration('Value'),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Line total', style: TextStyle(color: subtitleColor)),
                      Text('\u20a6${lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _addToCart(product, quantity, discountType, double.tryParse(discountController.text) ?? 0);
                      },
                      child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _sheetFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: subtitleColor, fontSize: 12),
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  void _showCartSheet() {
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    String paymentMethod = 'cash';
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> completeSale() async {
              if (_cart.isEmpty) return;
              setSheetState(() => submitting = true);

              final products = _cart
                  .map((item) => {
                        'product_id': item['product']['id'],
                        'quantity': item['quantity'],
                        'discount_type': item['discount_type'],
                        'discount_value': item['discount_value'],
                      })
                  .toList();

              final result = await CashierDashboardService.createSale(
                customerName: customerNameController.text.trim().isEmpty ? null : customerNameController.text.trim(),
                customerPhone: customerPhoneController.text.trim().isEmpty ? null : customerPhoneController.text.trim(),
                products: products,
                paymentMethod: paymentMethod,
              );

              setSheetState(() => submitting = false);

              if (result['success'] == true) {
                if (!mounted) return;
                Navigator.pop(sheetContext);
                setState(() => _cart.clear());
                _showSaleCompleteDialog(result);
              } else {
                _showSnack(_extractMessage(result['message']) ?? 'Sale failed', isError: true);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cart', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._cart.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['product']['name'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['quantity']} × \u20a6${parsePrice(item['product']['price']).toStringAsFixed(2)}',
                                      style: const TextStyle(color: subtitleColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text('\u20a6${_cartLineTotal(item).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                onPressed: () {
                                  _removeFromCart(index);
                                  setSheetState(() {});
                                  if (_cart.isEmpty) Navigator.pop(sheetContext);
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: subtitleColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('\u20a6${_cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: customerNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _sheetFieldDecoration('Customer name (optional)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: customerPhoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: _sheetFieldDecoration('Customer phone (optional)'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        dropdownColor: cardColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: _sheetFieldDecoration('Payment method'),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'card', child: Text('Card')),
                          DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                        ],
                        onChanged: (value) => setSheetState(() => paymentMethod = value ?? 'cash'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: submitting ? null : completeSale,
                          child: submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Complete Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSaleCompleteDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Sale Complete', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Transaction ID: ${result['txn_id'] ?? '-'}',
          style: const TextStyle(color: subtitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stock = product['stock_quantity'] is num ? (product['stock_quantity'] as num).toInt() : null;
    final outOfStock = stock != null && stock <= 0;

    return InkWell(
      onTap: outOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: outOfStock ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2847),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F5DA8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF8FAADC)),
              ),
              const Spacer(),
              Text(
                product['name'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '\u20a6${parsePrice(product['price']).toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF8FAADC), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              if (stock != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    outOfStock ? 'Out of stock' : '$stock in stock',
                    style: TextStyle(
                      color: outOfStock ? Colors.redAccent : const Color(0xFF8FAADC).withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}