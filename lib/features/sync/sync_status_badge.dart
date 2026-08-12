import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'sync_engine.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncEngineProvider);

    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (syncState.isSyncing) {
      bg = AppColors.info.withOpacity(0.12);
      fg = AppColors.info;
      label = 'Syncing ${syncState.pendingCount} items...';
      icon = Icons.sync;
    } else if (syncState.isOffline) {
      bg = AppColors.warning.withOpacity(0.12);
      fg = AppColors.warning;
      label = 'Offline Mode (${syncState.pendingCount} unsynced)';
      icon = Icons.cloud_off;
    } else {
      bg = AppColors.success.withOpacity(0.12);
      fg = AppColors.success;
      label = syncState.pendingCount > 0 ? '${syncState.pendingCount} Pending Sync' : 'Synced (SQLite -> REST)';
      icon = Icons.cloud_done;
    }

    return GestureDetector(
      onTap: () {
        ref.read(syncEngineProvider.notifier).toggleAirplaneMode(!syncState.isOffline);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
