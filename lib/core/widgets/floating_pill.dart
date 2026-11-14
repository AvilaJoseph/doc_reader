import 'dart:ui';

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';

/// Contenedor flotante oscuro con forma de píldora y desenfoque de fondo.
///
/// Base de la navegación principal y de las barras del lector.
class FloatingPill extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(5),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ColoredBox(
            color: AppColors.pill.withValues(alpha: 0.92),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Elemento de [FloatingPill]: icono + etiqueta opcional, con fondo al
/// estar seleccionado.
class PillButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.onPressed,
    super.key,
    this.label,
    this.selected = false,
    this.vertical = false,
    this.tooltip,
  });

  final IconData icon;
  final String? label;
  final bool selected;

  /// Icono encima del texto (navegación) o al lado (acciones).
  final bool vertical;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.pillInk : AppColors.pillInkMuted;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: vertical ? 10.5 : 13,
    );
    final iconWidget = Icon(icon, size: vertical ? 21 : 19, color: color);
    final content = label == null
        ? iconWidget
        : vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 3),
              Text(label!, style: textStyle),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(width: 6),
              Text(label!, style: textStyle),
            ],
          );

    final button = Semantics(
      button: true,
      selected: selected,
      label: label == null ? tooltip : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
            padding: EdgeInsets.symmetric(
              horizontal: vertical ? 18 : 14,
              vertical: vertical ? 7 : 10,
            ),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: selected ? AppColors.pillSelected : Colors.transparent,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: content),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
