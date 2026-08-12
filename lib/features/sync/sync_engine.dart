import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityState { online, offline, syncing }

class SyncState {
  final ConnectivityState connectivity;
  final int pendingCount;
  final DateTime? lastSyncedAt;

  const SyncState({
    required this.connectivity,
    required this.pendingCount,
    this.lastSyncedAt,
  });

  bool get isOnline => connectivity == ConnectivityState.online;
  bool get isOffline => connectivity == ConnectivityState.offline;
  bool get isSyncing => connectivity == ConnectivityState.syncing;
}

class SyncEngineNotifier extends StateNotifier<SyncState> {
  Timer? _syncTimer;

  SyncEngineNotifier()
      : super(SyncState(
          connectivity: ConnectivityState.online,
          pendingCount: 0,
          lastSyncedAt: DateTime.now(),
        )) {
    // Start periodic background sync worker check every 15 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) => triggerSync());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void toggleAirplaneMode(bool offline) {
    if (offline) {
      state = SyncState(
        connectivity: ConnectivityState.offline,
        pendingCount: state.pendingCount,
        lastSyncedAt: state.lastSyncedAt,
      );
    } else {
      state = SyncState(
        connectivity: ConnectivityState.online,
        pendingCount: state.pendingCount,
        lastSyncedAt: state.lastSyncedAt,
      );
      triggerSync(); // Auto-sync on reconnect
    }
  }

  void recordLocalWrite() {
    state = SyncState(
      connectivity: state.connectivity,
      pendingCount: state.pendingCount + 1,
      lastSyncedAt: state.lastSyncedAt,
    );
    if (state.isOnline) {
      triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (state.isOffline || state.pendingCount == 0) return;

    state = SyncState(
      connectivity: ConnectivityState.syncing,
      pendingCount: state.pendingCount,
      lastSyncedAt: state.lastSyncedAt,
    );

    // Simulate REST API POST /sync/push payload & GET /sync/pull
    await Future.delayed(const Duration(milliseconds: 800));

    state = SyncState(
      connectivity: ConnectivityState.online,
      pendingCount: 0,
      lastSyncedAt: DateTime.now(),
    );
  }
}

final syncEngineProvider = StateNotifierProvider<SyncEngineNotifier, SyncState>((ref) {
  return SyncEngineNotifier();
});
