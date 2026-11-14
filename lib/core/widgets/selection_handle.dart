import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/ui.dart';

/// Asa de selección al estilo Android: una gota pequeña cuya punta toca el
/// inicio (o el final) del texto seleccionado.
class SelectionHandle extends StatelessWidget {
  const new({required this.isStart, super.key, this.color});

  /// Tamaño de la gota en píxeles lógicos.
  static const double size = 22;

  /// true: asa de inicio (punta arriba a la derecha); false: de final.
  final bool isStart;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DropPainter(
          isStart: isStart,
          color: color ?? AppColors.selectionHandle,
        ),
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  const new({required this.isStart, required this.color});

  final bool isStart;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    // Círculo con la esquina superior (del lado del texto) en punta.
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: isStart ? Radius.circular(r) : Radius.zero,
      topRight: isStart ? Radius.zero : Radius.circular(r),
      bottomLeft: Radius.circular(r),
      bottomRight: Radius.circular(r),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DropPainter oldDelegate) =>
      oldDelegate.isStart != isStart || oldDelegate.color != color;
}
