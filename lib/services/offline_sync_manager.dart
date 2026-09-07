import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_pos_service.dart';
import 'offline_sales_sync_service.dart';

/// Watches device connectivity and automatically:
///  - syncs any queued offline sales the moment internet comes back
///  - refreshes the local product catalog right after (server is source
///    of truth post-sync)
///  - keeps the catalog topped up periodically while online, so the 12hr
///    freshness clock rarely actually runs out during normal use — it's
///    mainly a safety net for a device that's been offline a long time
///
/// Wire this up once, near app startup (e.g. in the same place
/// ConnectivityWrapper is mounted) — call `OfflineSyncManager().start()`
/// once and forget it. Call `.dispose()` if you ever tear that part of
/// the widget tree down.
class OfflineSyncManager {
  static final OfflineSyncManager _instance = OfflineSyncManager._internal();
  factory OfflineSyncManager() => _instance;
  OfflineSyncManager._internal();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicRefreshTimer;
  bool _started = false;
  bool _syncInProgress = false;

  final _statusController = StreamController<OfflineSyncStatus>.broadcast();

  /// Listen to this for UI feedback (e.g. a toast/snackbar or badge
  /// update) whenever a background sync runs.
  Stream<OfflineSyncStatus> get statusStream => _statusController.stream;

  void start() {
    if (_started) return;
    _started = true;

    // Fire once on startup — covers the case where the app opens already
    // online after being offline for a while.
    _tryAutoSyncAndRefresh();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _tryAutoSyncAndRefresh();
      }
    });

    // Safety net: every 2 hours while the app is alive, if online and the
    // catalog is getting stale, top it up — keeps the 12hr TTL from ever
    // being the reason offline selling breaks during a normal work day.
    _periodicRefreshTimer = Timer.periodic(const Duration(hours: 2), (_) async {
      final online = await OfflinePosService.isOnline();
      if (!online) return;

      final fresh = await OfflinePosService.isCatalogFresh();
      if (!fresh) {
        await OfflinePosService.refreshCatalogFromServer();
      }
    });
  }

  Future<void> _tryAutoSyncAndRefresh() async {
    if (_syncInProgress) return;
    _syncInProgress = true;

    try {
      final pendingBefore = await OfflinePosService.getPendingSyncCount();

      if (pendingBefore > 0) {
        final summary = await OfflineSalesSyncService.syncPendingSales();
        _statusController.add(OfflineSyncStatus(
          triggeredBy: 'reconnect',
          summary: summary,
        ));
      } else {
        // Nothing to sync, but still worth refreshing the catalog if it's
        // gone stale while offline.
        final fresh = await OfflinePosService.isCatalogFresh();
        if (!fresh) {
          await OfflinePosService.refreshCatalogFromServer();
        }
      }
    } finally {
      _syncInProgress = false;
    }
  }

  /// Manual trigger for a "Sync Now" button in the UI.
  Future<SyncTriggerResult> syncNow() async {
    final online = await OfflinePosService.isOnline();
    if (!online) {
      return SyncTriggerResult(success: false, message: "No internet connection.");
    }

    final summary = await OfflineSalesSyncService.syncPendingSales();
    _statusController.add(OfflineSyncStatus(triggeredBy: 'manual', summary: summary));

    return SyncTriggerResult(
      success: !summary.hasFailures,
      message: summary.message,
    );
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicRefreshTimer?.cancel();
    _statusController.close();
    _started = false;
  }
}

class OfflineSyncStatus {
  final String triggeredBy; // 'reconnect' | 'manual'
  final SyncSummary summary;
  OfflineSyncStatus({required this.triggeredBy, required this.summary});
}

class SyncTriggerResult {
  final bool success;
  final String message;
  SyncTriggerResult({required this.success, required this.message});
}