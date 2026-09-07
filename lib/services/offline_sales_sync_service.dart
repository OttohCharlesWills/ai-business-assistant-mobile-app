import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'offline_db_service.dart';
import 'offline_pos_service.dart';

class OfflineSalesSyncService {
  static String get baseUrl => AuthService.baseUrl;
  static final OfflineDbService _localDb = OfflineDbService();

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// Pushes every unsynced offline sale to the server in one batch.
  ///
  /// Per-sale outcomes come back individually — a failure on one sale
  /// (e.g. a product that got deleted) does NOT block the others in the
  /// batch from being marked synced. Only sales that come back with
  /// status "error" stay in the local queue for the next retry.
  static Future<SyncSummary> syncPendingSales() async {
    final pending = await _localDb.getUnsyncedSales();

    if (pending.isEmpty) {
      return SyncSummary(synced: 0, duplicates: 0, failed: 0, refreshedStock: false);
    }

    final payload = {
      "sales": pending.map((sale) {
        return {
          "client_sale_id": sale['client_sale_id'],
          "sold_at": sale['sold_at'],
          "customer_name": sale['customer_name'],
          "customer_phone": sale['customer_phone'],
          "payment_method": sale['payment_method'],
          "products": (sale['items'] as List).map((item) {
            return {
              "product_id": item['product_id'],
              "quantity": item['quantity'],
              "discount_type": item['discount_type'],
              "discount_value": item['discount_value'],
            };
          }).toList(),
        };
      }).toList(),
    };

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/sales/sync"),
        headers: await _headers(),
        body: jsonEncode(payload),
      );

      if (res.statusCode != 200) {
        // Whole request failed (network blip, auth expired mid-sync, etc.)
        // — leave everything in the queue untouched, nothing to mark.
        return SyncSummary(
          synced: 0,
          duplicates: 0,
          failed: pending.length,
          refreshedStock: false,
          error: "Sync request failed (HTTP ${res.statusCode})",
        );
      }

      final body = jsonDecode(res.body);
      final results = (body['results'] as List?) ?? [];

      int synced = 0;
      int duplicates = 0;
      int failed = 0;

      for (final r in results) {
        final clientSaleId = r['client_sale_id'];
        final status = r['status'];

        if (status == 'success') {
          await _localDb.markSaleSynced(clientSaleId);
          synced++;
        } else if (status == 'duplicate') {
          // Already on the server from a previous sync attempt — safe to
          // mark synced locally too, nothing more to do with it.
          await _localDb.markSaleSynced(clientSaleId);
          duplicates++;
        } else {
          await _localDb.markSaleFailed(clientSaleId, r['message']?.toString() ?? 'Unknown error');
          failed++;
        }
      }

      // After syncing, refresh the local catalog cache from the server —
      // this is the reconciliation step. The server is the source of
      // truth once sales are synced, and this corrects any drift from
      // optimistic local decrements (e.g. two devices both sold the same
      // item offline — each device's local cache won't know about the
      // other device's sale until this refresh happens).
      final refreshedStock = await OfflinePosService.refreshCatalogFromServer();

      await _localDb.pruneSyncedSales();

      return SyncSummary(
        synced: synced,
        duplicates: duplicates,
        failed: failed,
        refreshedStock: refreshedStock,
      );

    } catch (e) {
      return SyncSummary(
        synced: 0,
        duplicates: 0,
        failed: pending.length,
        refreshedStock: false,
        error: e.toString(),
      );
    }
  }
}

class SyncSummary {
  final int synced;
  final int duplicates;
  final int failed;
  final bool refreshedStock;
  final String? error;

  SyncSummary({
    required this.synced,
    required this.duplicates,
    required this.failed,
    required this.refreshedStock,
    this.error,
  });

  bool get hasFailures => failed > 0;
  bool get isEmpty => synced == 0 && duplicates == 0 && failed == 0;

  String get message {
    if (error != null) return "Sync failed: $error";
    if (isEmpty) return "Nothing to sync";
    final parts = <String>[];
    if (synced > 0) parts.add("$synced synced");
    if (duplicates > 0) parts.add("$duplicates already synced");
    if (failed > 0) parts.add("$failed failed");
    return parts.join(", ");
  }
}