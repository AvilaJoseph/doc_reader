import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/circle_icon_button.dart';
import 'package:doc_reader/l10n/l10n.dart';

/// Barra de búsqueda que sustituye a la barra superior del lector.
///
/// Escribir busca al momento; Intro o las flechas saltan entre resultados.
class ReaderSearchBar extends StatelessWidget {
  const new({
    required this.controller,
    required this.background,
    required this.foreground,
    required this.muted,
    required this.onChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    super.key,
    this.current,
    this.total = 0,
    this.searching = false,
  });

  final TextEditingController controller;
  final Color background;
  final Color foreground;
  final Color muted;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  /// Resultado actual (desde 0) y total de resultados.
  final int? current;
  final int total;

  /// Si la búsqueda aún recorre el documento (PDF grandes).
  final bool searching;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final buttonBackground = foreground.withValues(alpha: 0.06);
    final hasQuery = controller.text.trim().isNotEmpty;
    final status = !hasQuery
        ? null
        : total == 0
        ? (searching ? null : l10n.readerSearchNone)
        : l10n.readerSearchCount((current ?? 0) + 1, total);

    return ColoredBox(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              CircleIconButton(
                icon: Icons.close_rounded,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                background: buttonBackground,
                foreground: foreground,
                onPressed: onClose,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: textTheme.bodyLarge?.copyWith(color: foreground),
                  cursorColor: foreground,
                  decoration: InputDecoration(
                    hintText: l10n.readerSearchHint,
                    hintStyle: textTheme.bodyLarge?.copyWith(color: muted),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    suffixIcon: searching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: muted,
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onNext(),
                ),
              ),
              if (status != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    status,
                    style: textTheme.labelMedium?.copyWith(color: muted),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                tooltip: l10n.readerSearchPrevious,
                color: foreground,
                onPressed: total > 0 ? onPrevious : null,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                tooltip: l10n.readerSearchNext,
                color: foreground,
                onPressed: total > 0 ? onNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
