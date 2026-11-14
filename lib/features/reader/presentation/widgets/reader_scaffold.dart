import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_top_bar.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
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
    this.liveSubtitle,
    this.bottomPill,
    this.pillVisible,
    this.onMore,
    this.actions = const [],
    this.searchBar,
  });

  final String title;
  final String? subtitle;

  /// Subtítulo que cambia a menudo (p. ej. % leído). Solo se redibuja el
  /// texto, no el visor entero.
  final ValueListenable<String>? liveSubtitle;
  final Widget body;
  final Widget? bottomPill;

  /// Muestra u oculta la píldora sin reconstruir el contenido.
  final ValueListenable<bool>? pillVisible;
  final Color background;
  final Color foreground;
  final Color muted;
  final VoidCallback? onMore;

  /// Botones extra del visor, a la izquierda del bloqueo de giro.
  final List<ReaderBarAction> actions;

  /// Si no es null, sustituye a la barra superior (modo búsqueda).
  final Widget? searchBar;

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
          if (searchBar case final bar?)
            bar
          else
            ReaderTopBar(
              title: title,
              subtitle: subtitle,
              liveSubtitle: liveSubtitle,
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
                        child: RepaintBoundary(
                          child: _PillSlot(
                            visible: pillVisible,
                            child: Center(child: bottomPill),
                          ),
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

/// Desliza la píldora fuera de la pantalla al bajar leyendo.
class _PillSlot extends StatelessWidget {
  const new({required this.visible, required this.child});

  final ValueListenable<bool>? visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final listenable = visible;
    if (listenable == null) return child;
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      child: child,
      builder: (context, visible, child) => AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.6),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}
