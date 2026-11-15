import 'dart:async';

import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/settings/application/app_lock.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tapa la app con una pantalla de bloqueo mientras [appLockProvider]
/// esté bloqueado, y pide la huella sola al abrir o al volver.
class AppLockGate extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLockController _lock;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lock = ref.read(appLockProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: () => _lock.onHidden(DateTime.now()),
      onShow: () {
        _lock.onResumed(DateTime.now());
        if (ref.read(appLockProvider)) _unlock();
      },
    );
    if (ref.read(appLockProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _unlock() {
    if (!mounted) return;
    unawaited(_lock.unlock(context.l10n.lockReason));
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(excluding: locked, child: widget.child),
        if (locked) Positioned.fill(child: _LockScreen(onUnlock: _unlock)),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const new({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.lockTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: Text(l10n.lockUnlock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
