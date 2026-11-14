import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/circle_icon_button.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/foundation.dart';

/// Botón extra de la barra superior (modo noche, bloqueo de giro…).
@immutable
class ReaderBarAction {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Resalta el botón cuando la opción está activada.
  final bool active;
}

/// Barra superior del lector: volver, título con avance y más opciones.
class ReaderTopBar extends StatelessWidget {
  const new({
    required this.title,
    required this.background,
    required this.foreground,
    required this.muted,
    super.key,
    this.subtitle,
    this.liveSubtitle,
    this.onBack,
    this.onMore,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final ValueListenable<String>? liveSubtitle;
  final Color background;
  final Color foreground;
  final Color muted;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final List<ReaderBarAction> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final buttonBackground = foreground.withValues(alpha: 0.06);
    return ColoredBox(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: context.l10n.back,
                background: buttonBackground,
                foreground: foreground,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(color: foreground),
                    ),
                    if (liveSubtitle case final live?)
                      ValueListenableBuilder<String>(
                        valueListenable: live,
                        builder: (context, value, _) => Text(
                          value,
                          style: textTheme.labelSmall?.copyWith(color: muted),
                        ),
                      )
                    else if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.labelSmall?.copyWith(color: muted),
                      ),
                  ],
                ),
              ),
              for (final action in actions) ...[
                const SizedBox(width: AppSpacing.sm),
                CircleIconButton(
                  icon: action.icon,
                  tooltip: action.tooltip,
                  background: action.active
                      ? foreground.withValues(alpha: 0.2)
                      : buttonBackground,
                  foreground: foreground,
                  onPressed: action.onPressed,
                ),
              ],
              if (onMore != null) ...[
                const SizedBox(width: AppSpacing.md),
                CircleIconButton(
                  icon: Icons.more_horiz_rounded,
                  tooltip: context.l10n.moreOptions,
                  background: buttonBackground,
                  foreground: foreground,
                  onPressed: onMore,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
