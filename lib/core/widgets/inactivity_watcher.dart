import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_provider.dart';
import '../theme/app_colors.dart';

/// Wraps authenticated application routes and automatically logs out user
/// after a period of user inactivity (e.g. 15 minutes).
class InactivityWatcher extends ConsumerStatefulWidget {
  final Widget child;
  final Duration timeout;

  const InactivityWatcher({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 15),
  });

  @override
  ConsumerState<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends ConsumerState<InactivityWatcher> {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    final userSession = ref.read(authProvider);
    if (userSession != null) {
      _idleTimer = Timer(widget.timeout, _handleTimeout);
    }
  }

  void _handleTimeout() {
    final userSession = ref.read(authProvider);
    if (userSession != null && mounted) {
      ref.read(authProvider.notifier).logout();
      
      // Use root scaffold messenger if available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Logged out automatically due to inactivity for security reasons.'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth changes to restart timer upon login
    ref.listen<UserSession?>(authProvider, (prev, next) {
      if (next != null) {
        _resetTimer();
      } else {
        _idleTimer?.cancel();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerHover: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
