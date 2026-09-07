import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/offline_pos_service.dart';
import '../../../services/offline_sync_manager.dart';

class OfflineSalesScreen extends StatefulWidget {
  const OfflineSalesScreen({super.key});

  @override
  State<OfflineSalesScreen> createState() => _OfflineSalesScreenState();
}

class _OfflineSalesScreenState extends State<OfflineSalesScreen> with SingleTickerProviderStateMixin {
  static const bgColor    = Color(0xFF0C1F3F);
  static const cardColor  = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue   = Color(0xFF8FAADC);

  bool loading = true;
  bool online = true;
  bool catalogFresh = true;
  double hoursLeft = 12;
  int pendingSyncCount = 0;

  List<Map<String, dynamic>> categories = [];
  TabController? _tabController;

  // cart: product_id -> {product, quantity, discount_type, discount_value}
  final Map<int, Map<String, dynamic>> cart = {};

  StreamSubscription<OfflineSyncStatus>? _syncSub;

  @override
  void initState() {
    super.initState();
    _loadEverything();

    // Reflect background syncs (triggered by OfflineSyncManager on
    // reconnect) live in this screen — refresh menu/pending count and
    // let the cashier know what happened.
    _syncSub = OfflineSyncManager().statusStream.listen((status) {
      if (!mounted) return;
      _refreshStatusAndMenu();

      if (status.summary.synced > 0 || status.summary.hasFailures) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync: ${status.summary.message}"),
            backgroundColor: status.summary.hasFailures ? Colors.orange : Colors.green,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    setState(() => loading = true);

    online = await OfflinePosService.isOnline();
    catalogFresh = await OfflinePosService.isCatalogFresh();
    hoursLeft = await OfflinePosService.hoursUntilCatalogExpires();
    pendingSyncCount = await OfflinePosService.getPendingSyncCount();

    // If online and the catalog is missing/stale, refresh it before
    // showing anything — this is also what makes the "goes stale after
    // 12hrs, comes back the moment data turns on" behavior work: the
    // instant this screen opens with connectivity, it tops the cache up.
    if (online && !catalogFresh) {
      final refreshed = await OfflinePosService.refreshCatalogFromServer();
      if (refreshed) {
        catalogFresh = true;
        hoursLeft = await OfflinePosService.hoursUntilCatalogExpires();
      }
    }

    final menu = await OfflinePosService.getOfflineMenu();

    _tabController?.dispose();
    _tabController = menu.isEmpty ? null : TabController(length: menu.length, vsync: this);

    if (!mounted) return;
    setState(() {
      categories = menu;
      loading = false;
    });
  }

  Future<void> _refreshStatusAndMenu() async {
    online = await OfflinePosService.isOnline();
    catalogFresh = await OfflinePosService.isCatalogFresh();
    hoursLeft = await OfflinePosService.hoursUntilCatalogExpires();
    pendingSyncCount = await OfflinePosService.getPendingSyncCount();

    final menu = await OfflinePosService.getOfflineMenu();
    if (!mounted) return;
    setState(() => categories = menu);
  }

  void _addToCart(Map<String, dynamic> product) {
    final id = product['id'] as int;
    setState(() {
      if (cart.containsKey(id)) {
        cart[id]!['quantity'] = (cart[id]!['quantity'] as int) + 1;
      } else {
        cart[id] = {
          'product': product,
          'quantity': 1,
          'discount_type': 'none',
          'discount_value': 0.0,
        };
      }
    });
  }

  void _changeQuantity(int productId, int delta) {
    setState(() {
      final entry = cart[productId];
      if (entry == null) return;
      final newQty = (entry['quantity'] as int) + delta;
      if (newQty <= 0) {
        cart.remove(productId);
      } else {
        entry['quantity'] = newQty;
      }
    });
  }

  double get cartTotal {
    double total = 0;
    for (final entry in cart.values) {
      final product = entry['product'];
      final price = (product['price'] as num).toDouble();
      final qty = entry['quantity'] as int;
      double lineTotal = price * qty;

      final discountType = entry['discount_type'];
      final discountValue = (entry['discount_value'] as num).toDouble();
      if (discountType == 'percentage') {
        lineTotal -= (discountValue / 100) * lineTotal;
      } else if (discountType == 'flat') {
        lineTotal -= discountValue;
      }
      total += lineTotal < 0 ? 0 : lineTotal;
    }
    return total;
  }

  String _fmtMoney(num v) =>
      "₦${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";

  Future<void> _openCheckout() async {
    if (cart.isEmpty) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String paymentMethod = 'cash';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Checkout (Offline)",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text("This sale will sync automatically once you're back online.",
                      style: TextStyle(color: softBlue, fontSize: 12)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Customer name (optional)"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Customer phone (optional)"),
                  ),
                  const SizedBox(height: 14),

                  const Text("Payment Method", style: TextStyle(color: softBlue, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['cash', 'card', 'transfer'].map((method) {
                      final selected = paymentMethod == method;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(method[0].toUpperCase() + method.substring(1)),
                          selected: selected,
                          onSelected: (_) => setSheetState(() => paymentMethod = method),
                          selectedColor: accentBlue,
                          backgroundColor: bgColor,
                          labelStyle: TextStyle(color: selected ? Colors.white : softBlue),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total", style: TextStyle(color: softBlue, fontSize: 14)),
                      Text(_fmtMoney(cartTotal),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await OfflinePosService.createOfflineSale(
                          customerName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                          customerPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          paymentMethod: paymentMethod,
                          products: cart.values.map((e) => {
                                'product_id': e['product']['id'],
                                'quantity': e['quantity'],
                                'discount_type': e['discount_type'],
                                'discount_value': e['discount_value'],
                              }).toList(),
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context, result.success);

                        if (!result.success) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(result.message), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Confirm Offline Sale", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() => cart.clear());
      await _refreshStatusAndMenu();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sale saved offline — will sync when online."), backgroundColor: Colors.green),
      );
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: bgColor,
      hintText: hint,
      hintStyle: TextStyle(color: softBlue, fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        title: const Text("Offline Sales",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.sync_rounded, color: Colors.white),
                onPressed: () async {
                  final result = await OfflineSyncManager().syncNow();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: result.success ? Colors.green : Colors.orange,
                    ),
                  );
                  await _refreshStatusAndMenu();
                },
              ),
              if (pendingSyncCount > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text("$pendingSyncCount",
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: accentBlue,
                labelColor: Colors.white,
                unselectedLabelColor: softBlue,
                tabs: categories.map((c) => Tab(text: c['name'] ?? '')).toList(),
              )
            : null,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentBlue))
          : Column(
              children: [
                _buildStatusBanner(),
                Expanded(
                  child: categories.isEmpty
                      ? _buildEmptyState()
                      : TabBarView(
                          controller: _tabController,
                          children: categories.map((cat) => _buildProductGrid(cat)).toList(),
                        ),
                ),
                if (cart.isNotEmpty) _buildCartBar(),
              ],
            ),
    );
  }

  Widget _buildStatusBanner() {
    if (!catalogFresh) {
      return Container(
        width: double.infinity,
        color: Colors.red.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                online
                    ? "Catalog expired — refreshing..."
                    : "Offline catalog expired. Connect to the internet to refresh before selling.",
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (!online) {
      return Container(
        width: double.infinity,
        color: Colors.orange.withOpacity(0.15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "You're offline. Catalog valid for another ${hoursLeft.toStringAsFixed(1)}h.",
                style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (pendingSyncCount > 0)
              Text("$pendingSyncCount pending",
                  style: const TextStyle(color: Colors.orange, fontSize: 11)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: softBlue, size: 48),
            const SizedBox(height: 12),
            Text(
              online
                  ? "No products cached yet."
                  : "No offline catalog available. Connect to the internet once to download products for offline selling.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: softBlue, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (online)
              ElevatedButton(
                onPressed: _loadEverything,
                style: ElevatedButton.styleFrom(backgroundColor: accentBlue, foregroundColor: Colors.white),
                child: const Text("Download Catalog"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(Map<String, dynamic> category) {
    final products = (category['products'] as List?) ?? [];

    if (products.isEmpty) {
      return const Center(child: Text("No products in this category", style: TextStyle(color: softBlue)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index] as Map<String, dynamic>;
        final stock = (product['stock_quantity'] as num?)?.toDouble() ?? 0;
        final inCart = cart[product['id']];

        return GestureDetector(
          onTap: catalogFresh ? () => _addToCart(product) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: inCart != null ? Border.all(color: accentBlue, width: 1.5) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(_fmtMoney((product['price'] as num?) ?? 0),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                Text("Stock: ${stock.toStringAsFixed(0)}",
                    style: TextStyle(color: stock <= 0 ? Colors.red : softBlue, fontSize: 11)),
                if (inCart != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _qtyButton(Icons.remove_rounded, () => _changeQuantity(product['id'], -1)),
                        Text("${inCart['quantity']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        _qtyButton(Icons.add_rounded, () => _changeQuantity(product['id'], 1)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: accentBlue, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  Widget _buildCartBar() {
    final itemCount = cart.values.fold<int>(0, (sum, e) => sum + (e['quantity'] as int));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$itemCount item${itemCount == 1 ? '' : 's'}", style: TextStyle(color: softBlue, fontSize: 11)),
                Text(_fmtMoney(cartTotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Checkout", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}