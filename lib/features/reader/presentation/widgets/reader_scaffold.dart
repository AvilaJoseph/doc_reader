import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_top_bar.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estructura común de los visores: barra superior, contenido y una
/// píldora flotante opcional abajo que se oculta al leer. Incluye siempre
/// el botón de bloqueo de giro.
class ReaderScaffold extends ConsumerWidget {
  const new({
    required this.title,
    required this.body,
    required this.background,
    required this.foreground,
    required this.muted,
    super.key,
    this.subtitle,
    this.bottomPill,
    this.pillVisible = true,
    this.onMore,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? bottomPill;
  final bool pillVisible;
  final Color background;
  final Color foreground;
  final Color muted;
  final VoidCallback? onMore;

  /// Botones extra del visor, a la izquierda del bloqueo de giro.
  final List<ReaderBarAction> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(
      settingsControllerProvider.select((s) => s.lockRotation),
    );
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          ReaderTopBar(
            title: title,
            subtitle: subtitle,
            background: background,
            foreground: foreground,
            muted: muted,
            onMore: onMore,
            actions: [
              ...actions,
              ReaderBarAction(
                icon: locked
                    ? Icons.screen_lock_rotation_rounded
                    : Icons.screen_rotation_rounded,
                tooltip: locked
                    ? l10n.readerUnlockRotation
                    : l10n.readerLockRotation,
                active: locked,
                onPressed: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setLockRotation(enabled: !locked),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: body),
                if (bottomPill != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AnimatedSlide(
                          offset: pillVisible
                              ? Offset.zero
                              : const Offset(0, 1.6),
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          child: Center(child: bottomPill),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
