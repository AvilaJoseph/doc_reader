import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/utils/formatters.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/library/presentation/widgets/document_cover.dart';
import 'package:doc_reader/l10n/l10n.dart';

/// Tarjeta de la cuadrícula: portada, título, tipo y estado de lectura.
class DocumentCard extends StatelessWidget {
  const new({
    required this.document,
    required this.onTap,
    required this.onMore,
    super.key,
  });

  final LibraryDocument document;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final l10n = context.l10n;
    final kindLabel = switch (document.kind) {
      DocumentKind.pdf => l10n.kindPdf,
      DocumentKind.word => l10n.kindWord,
      DocumentKind.spreadsheet => l10n.kindSpreadsheet,
      DocumentKind.text => l10n.kindText,
    };
    final size = formatFileSize(document.sizeBytes);
    final status = document.isFinished
        ? l10n.documentFinished
        : document.isStarted
        ? l10n.documentProgress((document.progress * 100).round())
        : l10n.documentNotStarted;

    return Semantics(
      button: true,
      label: document.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onMore,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DocumentCover(document: document),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              size.isEmpty ? kindLabel : '$kindLabel · $size',
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 22,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    tooltip: l10n.moreOptions,
                    onPressed: onMore,
                    icon: Icon(Icons.more_horiz_rounded, color: muted),
                  ),
                ),
              ],
            ),
            if (document.isStarted && !document.isFinished)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: document.progress,
                    minHeight: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta para añadir documentos, con borde discontinuo.
class AddDocumentCard extends StatelessWidget {
  const new({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      label: context.l10n.addDocument,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: DocumentCover.aspectRatio,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: theme.colorScheme.outline.withValues(alpha: 0.6),
                ),
                child: Center(
                  child: Icon(Icons.add_rounded, size: 34, color: muted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(context.l10n.addDocument, style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              context.l10n.addDocumentHint,
              maxLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  new({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadii.card),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
