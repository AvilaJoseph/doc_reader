import 'package:doc_reader/core/ui.dart';

/// Botón redondo discreto (volver, más opciones…).
class CircleIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: background ?? scheme.surfaceContainerHigh,
        foregroundColor: foreground ?? scheme.onSurface,
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
      ),
    );
  }
}
