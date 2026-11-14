import 'dart:io';

import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_scaffold.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_states.dart';

/// Visor de imágenes: ajustada a la pantalla, con pellizco para ampliar y
/// doble toque para alternar entre ajustada y ×2.5.
class ImageReaderScreen extends StatefulWidget {
  const new({required this.document, required this.onMore, super.key});

  final LibraryDocument document;
  final VoidCallback onMore;

  @override
  State<ImageReaderScreen> createState() => _ImageReaderScreenState();
}

class _ImageReaderScreenState extends State<ImageReaderScreen> {
  final _transform = TransformationController();
  TapDownDetails? _doubleTap;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    final at = _doubleTap?.localPosition ?? Offset.zero;
    const scale = 2.5;
    _transform.value = zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(
              -at.dx * (scale - 1),
              -at.dy * (scale - 1),
              0,
              1,
            )
            ..scaleByDouble(scale, scale, 1, 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget error(BuildContext _, Object error, StackTrace? _) =>
        ReaderError(error: error);
    final image = switch (widget.document.source) {
      FileSource(:final path) => Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: error,
      ),
      AssetSource(:final assetPath) => Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: error,
      ),
    };
    return ReaderScaffold(
      title: widget.document.title,
      background: scheme.surfaceContainerHigh,
      foreground: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      onMore: widget.onMore,
      body: GestureDetector(
        onDoubleTapDown: (details) => _doubleTap = details,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _transform,
          maxScale: 8,
          child: SizedBox.expand(child: image),
        ),
      ),
    );
  }
}
