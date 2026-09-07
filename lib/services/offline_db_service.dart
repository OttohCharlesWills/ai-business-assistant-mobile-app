import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Manages the on-device SQLite database used for offline selling.
///
/// Responsibilities:
///  1. `local_categories` + `local_products` — a cached copy of the POS
///     catalog (same shape as CashierDashboardService.getHome()) so the
///     offline sales screen can render the same category-tab UI without
///     internet. Refreshed from the server whenever online, and always
///     after a successful sync.
///  2. `pending_sales` / `pending_sale_items` — the offline sale queue.
///     Each sale gets a device-generated client_sale_id (UUID) used as the
///     idempotency key on the server, so a retried sync can never create
///     duplicate PurchaseItem rows.
class OfflineDbService {
  static final OfflineDbService _instance = OfflineDbService._internal();
  factory OfflineDbService() => _instance;
  OfflineDbService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'bloommonie_offline.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_categories (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              shop_id INTEGER,
              cached_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE local_categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        shop_id INTEGER,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        cost_price REAL,
        stock_quantity REAL NOT NULL,
        stock_limit REAL,
        shop_id INTEGER,
        category_id INTEGER,
        stock_unit TEXT,
        unit_size REAL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_sales (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_sale_id TEXT NOT NULL UNIQUE,
        sold_at TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        payment_method TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        sync_attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pending_sale_local_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        discount_type TEXT NOT NULL DEFAULT 'none',
        discount_value REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (pending_sale_local_id) REFERENCES pending_sales (local_id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_pending_sales_synced ON pending_sales (synced)',
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // CATALOG CACHE (categories + products)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final c in categories) {
      batch.insert(
        'local_categories',
        {
          'id': c['id'],
          'name': c['name'],
          'shop_id': c['shop_id'],
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLocalCategories({int? shopId}) async {
    final db = await database;
    if (shopId != null) {
      return db.query('local_categories', where: 'shop_id = ?', whereArgs: [shopId], orderBy: 'name');
    }
    return db.query('local_categories', orderBy: 'name');
  }

  /// Replaces the local product cache with fresh data from the server.
  /// Call this whenever the app is online and fetches the POS catalog
  /// normally, and always after a successful sync (server stock is the
  /// source of truth once synced).
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final p in products) {
      batch.insert(
        'local_products',
        {
          'id': p['id'],
          'name': p['name'],
          'price': double.tryParse(p['price']?.toString() ?? '0') ?? 0,
          'cost_price': double.tryParse(p['cost_price']?.toString() ?? '0') ?? 0,
          'stock_quantity': double.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0,
          'stock_limit': double.tryParse(p['stock_limit']?.toString() ?? '0') ?? 0,
          'shop_id': p['shop_id'],
          'category_id': p['category_id'],
          'stock_unit': p['stock_unit'],
          'unit_size': double.tryParse(p['unit_size']?.toString() ?? '0'),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLocalProducts({int? shopId, int? categoryId}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (shopId != null) {
      where.add('shop_id = ?');
      args.add(shopId);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }

    return db.query(
      'local_products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name',
    );
  }

  /// Rebuilds the whole local catalog (categories + products) from a
  /// getHome()-shaped response in one go — used for both the initial
  /// online cache warm-up and the post-sync stock refresh.
  Future<void> replaceCatalog({
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> products,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('local_categories');
      await txn.delete('local_products');
    });
    await cacheCategories(categories);
    await cacheProducts(products);
  }

  /// Optimistically decrements local stock the moment an offline sale
  /// happens, so the cashier immediately sees accurate remaining stock
  /// without waiting for a sync. Allowed to go negative — same rule as
  /// the server: never block a sale for stock reasons while offline.
  Future<void> decrementLocalStock(int productId, int quantity) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE local_products SET stock_quantity = stock_quantity - ? WHERE id = ?',
      [quantity, productId],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // PENDING SALES QUEUE
  // ─────────────────────────────────────────────────────────────────────

  /// Records an offline sale locally and decrements local stock for each
  /// item. Returns the generated client_sale_id.
  Future<String> queueOfflineSale({
    required String clientSaleId,
    required DateTime soldAt,
    String? customerName,
    String? customerPhone,
    required String paymentMethod,
    required List<Map<String, dynamic>> items, // {product_id, product_name, quantity, unit_price, discount_type, discount_value}
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      final localId = await txn.insert('pending_sales', {
        'client_sale_id': clientSaleId,
        'sold_at': soldAt.toIso8601String(),
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'payment_method': paymentMethod,
        'synced': 0,
        'sync_attempts': 0,
      });

      for (final item in items) {
        await txn.insert('pending_sale_items', {
          'pending_sale_local_id': localId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'discount_type': item['discount_type'] ?? 'none',
          'discount_value': item['discount_value'] ?? 0,
        });

        await txn.rawUpdate(
          'UPDATE local_products SET stock_quantity = stock_quantity - ? WHERE id = ?',
          [item['quantity'], item['product_id']],
        );
      }
    });

    return clientSaleId;
  }

  /// All sales not yet successfully synced, with their line items attached.
  Future<List<Map<String, dynamic>>> getUnsyncedSales() async {
    final db = await database;
    final sales = await db.query('pending_sales', where: 'synced = 0', orderBy: 'sold_at ASC');

    final List<Map<String, dynamic>> result = [];
    for (final sale in sales) {
      final items = await db.query(
        'pending_sale_items',
        where: 'pending_sale_local_id = ?',
        whereArgs: [sale['local_id']],
      );
      result.add({...sale, 'items': items});
    }
    return result;
  }

  /// Count of sales still waiting to sync — handy for a badge in the UI.
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM pending_sales WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSaleSynced(String clientSaleId) async {
    final db = await database;
    await db.update(
      'pending_sales',
      {'synced': 1, 'last_error': null},
      where: 'client_sale_id = ?',
      whereArgs: [clientSaleId],
    );
  }

  Future<void> markSaleFailed(String clientSaleId, String error) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_sales SET sync_attempts = sync_attempts + 1, last_error = ? WHERE client_sale_id = ?',
      [error, clientSaleId],
    );
  }

  /// Deletes synced sales older than a cutoff, to keep the local DB from
  /// growing forever. Called automatically after every sync batch.
  Future<void> pruneSyncedSales({int keepDays = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: keepDays)).toIso8601String();
    await db.delete(
      'pending_sales',
      where: 'synced = 1 AND sold_at < ?',
      whereArgs: [cutoff],
    );
  }
}