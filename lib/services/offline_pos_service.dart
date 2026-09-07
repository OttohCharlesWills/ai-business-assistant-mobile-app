import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'cashier_dashboard_service.dart';
import 'offline_db_service.dart';

/// Backs the dedicated offline sales screen. Mirrors
/// CashierDashboardService's shape (getHome-style catalog, createSale)
/// but reads/writes the local SQLite cache instead of the API, so the
/// screen keeps working with zero connectivity.
///
/// Catalog freshness: the cached product list is only trusted for 12
/// hours after the last successful refresh. Past that, offline selling
/// is blocked with a clear message rather than letting a cashier sell
/// against stock numbers that might be half a day stale — the cache
/// "expires" and needs a real internet connection to refresh before
/// offline selling can resume.
///
/// IMPORTANT — response shape assumption: this assumes
/// CashierDashboardService.getHome() returns something like:
/// {
///   "success": true,
///   "categories": [
///     { "id": 1, "name": "Drinks", "shop_id": 3,
///       "products": [ { "id": 12, "name": "...", "price": ..., ... } ] }
///   ]
/// }
/// Confirm the real shape before relying on this in production.
class OfflinePosService {
  static final OfflineDbService _localDb = OfflineDbService();
  static const _uuid = Uuid();

  static const _lastSyncPrefKey = 'offline_catalog_last_synced_at';
  static const _catalogTtlHours = 12;

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ─────────────────────────────────────────────────────────────────────
  // CATALOG FRESHNESS
  // ─────────────────────────────────────────────────────────────────────

  static Future<DateTime?> getLastCatalogSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_lastSyncPrefKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  static Future<void> _markCatalogSynced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncPrefKey, DateTime.now().toIso8601String());
  }

  /// True if the local catalog was refreshed within the last 12 hours.
  /// False if it's never been synced at all, or the TTL has passed.
  static Future<bool> isCatalogFresh() async {
    final lastSync = await getLastCatalogSyncTime();
    if (lastSync == null) return false;
    return DateTime.now().difference(lastSync).inHours < _catalogTtlHours;
  }

  /// Hours remaining before the cache expires — for showing a countdown
  /// or "catalog valid until X" note in the UI. Returns 0 if already stale.
  static Future<double> hoursUntilCatalogExpires() async {
    final lastSync = await getLastCatalogSyncTime();
    if (lastSync == null) return 0;
    final elapsed = DateTime.now().difference(lastSync).inMinutes / 60.0;
    final remaining = _catalogTtlHours - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  // ─────────────────────────────────────────────────────────────────────
  // CATALOG REFRESH
  // ─────────────────────────────────────────────────────────────────────

  /// Warms/refreshes the local catalog cache from the server and resets
  /// the 12hr freshness clock. Call this whenever online: on app start,
  /// whenever connectivity is regained, and after every successful sync.
  static Future<bool> refreshCatalogFromServer() async {
    try {
      final online = await isOnline();
      if (!online) return false;

      final res = await CashierDashboardService.getHome();

      if (res['success'] != true && res['status'] != true) {
        return false;
      }

      final parsed = _extractCategoriesAndProducts(res);

      await _localDb.replaceCatalog(
        categories: parsed.categories,
        products: parsed.products,
      );

      await _markCatalogSynced();

      return true;
    } catch (_) {
      return false;
    }
  }

  static _ParsedCatalog _extractCategoriesAndProducts(Map<String, dynamic> res) {
    final raw = (res['categories'] as List?) ??
        (res['data']?['categories'] as List?) ??
        [];

    final categories = <Map<String, dynamic>>[];
    final products = <Map<String, dynamic>>[];

    for (final c in raw) {
      categories.add({
        'id': c['id'],
        'name': c['name'],
        'shop_id': c['shop_id'],
      });

      final prods = (c['products'] as List?) ?? [];
      for (final p in prods) {
        products.add({
          'id': p['id'],
          'name': p['name'],
          'price': p['price'],
          'cost_price': p['cost_price'],
          'stock_quantity': p['stock_quantity'],
          'stock_limit': p['stock_limit'],
          'shop_id': p['shop_id'] ?? c['shop_id'],
          'category_id': p['category_id'] ?? c['id'],
          'stock_unit': p['stock_unit'],
          'unit_size': p['unit_size'],
        });
      }
    }

    return _ParsedCatalog(categories: categories, products: products);
  }

  /// Menu for the offline screen: categories with their products attached,
  /// read from the local cache. Works with zero connectivity.
  static Future<List<Map<String, dynamic>>> getOfflineMenu({int? shopId}) async {
    final categories = await _localDb.getLocalCategories(shopId: shopId);
    final products = await _localDb.getLocalProducts(shopId: shopId);

    return categories.map((cat) {
      final catProducts = products.where((p) => p['category_id'] == cat['id']).toList();
      return {
        'id': cat['id'],
        'name': cat['name'],
        'shop_id': cat['shop_id'],
        'products': catProducts,
      };
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────
  // SELLING
  // ─────────────────────────────────────────────────────────────────────

  /// Records a sale on the offline sales screen. Always writes to the
  /// local queue and decrements local stock immediately — never blocks
  /// for insufficient stock, matching the server's sync behavior.
  ///
  /// Blocks the sale (returns success: false) only if the catalog itself
  /// has expired past the 12hr TTL — at that point the cached prices/stock
  /// are considered too stale to sell against, and the device needs to
  /// come online to refresh before selling can resume.
  ///
  /// products: [{ product_id, quantity, discount_type, discount_value }]
  static Future<OfflineSaleResult> createOfflineSale({
    String? customerName,
    String? customerPhone,
    required List<Map<String, dynamic>> products,
    required String paymentMethod,
  }) async {
    final fresh = await isCatalogFresh();
    if (!fresh) {
      return OfflineSaleResult(
        success: false,
        message: "Offline catalog has expired. Connect to the internet briefly to refresh product data before selling offline again.",
      );
    }

    final clientSaleId = _uuid.v4();
    final soldAt = DateTime.now();

    final localProducts = await _localDb.getLocalProducts();
    final productLookup = {for (var p in localProducts) p['id']: p};

    final items = <Map<String, dynamic>>[];
    double totalEstimate = 0;

    for (final item in products) {
      final localProduct = productLookup[item['product_id']];

      if (localProduct == null) {
        return OfflineSaleResult(
          success: false,
          message: "Product not found in offline cache — it may not have been synced before going offline.",
        );
      }

      final quantity = item['quantity'] as int;
      final unitPrice = (localProduct['price'] as num).toDouble();
      final discountType = item['discount_type'] ?? 'none';
      final discountValue = (item['discount_value'] as num?)?.toDouble() ?? 0;

      double lineTotal = unitPrice * quantity;
      if (discountType == 'percentage') {
        lineTotal -= (discountValue / 100) * lineTotal;
      } else if (discountType == 'flat') {
        lineTotal -= discountValue;
      }
      totalEstimate += lineTotal < 0 ? 0 : lineTotal;

      items.add({
        'product_id': localProduct['id'],
        'product_name': localProduct['name'],
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount_type': discountType,
        'discount_value': discountValue,
      });
    }

    await _localDb.queueOfflineSale(
      clientSaleId: clientSaleId,
      soldAt: soldAt,
      customerName: customerName,
      customerPhone: customerPhone,
      paymentMethod: paymentMethod,
      items: items,
    );

    return OfflineSaleResult(
      success: true,
      clientSaleId: clientSaleId,
      estimatedTotal: totalEstimate,
      message: "Sale recorded offline — will sync automatically when back online.",
    );
  }

  static Future<int> getPendingSyncCount() => _localDb.getUnsyncedCount();
}

class _ParsedCatalog {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;
  _ParsedCatalog({required this.categories, required this.products});
}

class OfflineSaleResult {
  final bool success;
  final String? clientSaleId;
  final double? estimatedTotal;
  final String message;

  OfflineSaleResult({
    required this.success,
    this.clientSaleId,
    this.estimatedTotal,
    required this.message,
  });
}