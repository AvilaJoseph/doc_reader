import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/l10n/l10n.dart';

/// Hoja para dibujar una firma con el dedo. Devuelve un PNG recortado y
/// con fondo transparente, o `null` si se cancela.
///
/// Si ya hay una firma guardada ([saved]), se ofrece usarla de un toque.
Future<Uint8List?> showSignaturePad(BuildContext context, {Uint8List? saved}) =>
    showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SignaturePad(saved: saved),
    );

class _SignaturePad extends StatefulWidget {
  const new({this.saved});

  final Uint8List? saved;

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final _strokes = <List<Offset>>[];

  static const _strokeWidth = 3.0;

  Future<void> _done() async {
    final points = [for (final s in _strokes) ...s];
    if (points.isEmpty) return;
    var bounds = Rect.fromPoints(points.first, points.first);
    for (final p in points) {
      bounds = bounds.expandToInclude(Rect.fromPoints(p, p));
    }
    bounds = bounds.inflate(_strokeWidth * 2);

    // Se dibuja a 3x para que la firma se vea nítida al ampliar el PDF.
    const scale = 3.0;
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top)
      ..drawPath(_path(), _paint);
    final image = await recorder.endRecording().toImage(
      (bounds.width * scale).ceil(),
      (bounds.height * scale).ceil(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (!mounted || png == null) return;
    Navigator.of(context).pop(png.buffer.asUint8List());
  }

  Path _path() {
    final path = Path();
    for (final stroke in _strokes) {
      path.moveTo(stroke.first.dx, stroke.first.dy);
      if (stroke.length == 1) {
        path.lineTo(stroke.first.dx + 0.1, stroke.first.dy);
      }
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path;
  }

  static final _paint = Paint()
    ..color = AppColors.signatureInk
    ..style = PaintingStyle.stroke
    ..strokeWidth = _strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final saved = widget.saved;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.signDraw, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (saved != null) ...[
              Material(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.field),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.field),
                  onTap: () => Navigator.of(context).pop(saved),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 120,
                          child: ColoredBox(
                            color: Colors.white,
                            child: Image.memory(saved, fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(l10n.signUseSaved)),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            DecoratedBox(
              // Papel blanco: la firma se ve igual que quedará en el PDF.
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.field),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.field),
                child: SizedBox(
                  height: 200,
                  child: GestureDetector(
                    onPanStart: (d) =>
                        setState(() => _strokes.add([d.localPosition])),
                    onPanUpdate: (d) =>
                        setState(() => _strokes.last.add(d.localPosition)),
                    child: CustomPaint(
                      painter: _StrokesPainter(
                        _path(),
                        _paint,
                        baseline: scheme.outlineVariant,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: _strokes.isEmpty
                      ? null
                      : () => setState(_strokes.clear),
                  child: Text(l10n.signClear),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _strokes.isEmpty ? null : _done,
                  child: Text(l10n.signUse),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  const new(this.path, this.strokePaint, {required this.baseline});

  final Path path;
  final Paint strokePaint;

  /// Línea guía sobre la que firmar (no forma parte de la firma).
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.72;
    canvas
      ..drawLine(
        Offset(24, y),
        Offset(size.width - 24, y),
        Paint()
          ..color = baseline
          ..strokeWidth = 1.5,
      )
      ..drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => true;
}
