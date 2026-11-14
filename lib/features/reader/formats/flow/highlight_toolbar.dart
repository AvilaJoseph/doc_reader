import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/l10n/l10n.dart';

/// Barra flotante sobre la selección: colores de subrayado y copiar.
class HighlightToolbar extends StatelessWidget {
  const new({
    required this.anchors,
    required this.onColor,
    required this.onCopy,
    super.key,
    this.onRemove,
  });

  final TextSelectionToolbarAnchors anchors;
  final ValueChanged<int> onColor;
  final VoidCallback onCopy;

  /// Solo se muestra si la selección toca un subrayado existente.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      toolbarBuilder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.pill,
          borderRadius: BorderRadius.circular(AppRadii.field),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: child,
        ),
      ),
      children: [
        for (final (index, color) in AppColors.highlights.indexed)
          _ColorDot(
            color: color,
            label: l10n.highlightColor(index + 1),
            onTap: () => onColor(index),
          ),
        const _Separator(),
        _ToolbarIcon(
          icon: Icons.copy_rounded,
          label: l10n.highlightCopy,
          onTap: onCopy,
        ),
        if (onRemove != null)
          _ToolbarIcon(
            icon: Icons.format_color_reset_outlined,
            label: l10n.highlightRemove,
            onTap: onRemove!,
          ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const new({required this.color, required this.label, required this.onTap});

  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: const SizedBox.square(dimension: 20),
          ),
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, size: 19, color: AppColors.pillInk),
    );
  }
}

class _Separator extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
    child: SizedBox(
      width: 1,
      height: 18,
      child: ColoredBox(color: AppColors.pillSelected),
    ),
  );
}
