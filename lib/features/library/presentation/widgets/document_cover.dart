import 'dart:io';

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/theme/app_typography.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension DocumentKindStyle on DocumentKind {
  Color get accent => switch (this) {
    DocumentKind.pdf => AppColors.kindPdf,
    DocumentKind.word => AppColors.kindWord,
    DocumentKind.spreadsheet => AppColors.kindSheet,
    DocumentKind.text => AppColors.kindText,
    DocumentKind.image => AppColors.kindImage,
    DocumentKind.presentation => AppColors.kindSlides,
  };

  IconData get icon => switch (this) {
    DocumentKind.pdf => Icons.picture_as_pdf_outlined,
    DocumentKind.word => Icons.article_outlined,
    DocumentKind.spreadsheet => Icons.table_chart_outlined,
    DocumentKind.text => Icons.notes_rounded,
    DocumentKind.image => Icons.image_outlined,
    DocumentKind.presentation => Icons.slideshow_outlined,
  };
}

/// Portada de un documento con proporción de libro.
///
/// Los PDF muestran su primera página; el resto, una portada tipográfica
/// generada a partir del título.
class DocumentCover extends StatelessWidget {
  const new({required this.document, super.key});

  static const double aspectRatio = 0.7;

  final LibraryDocument document;

  @override
  Widget build(BuildContext context) {
    final generated = GeneratedCover(document: document);
    final child = switch (document.kind) {
      DocumentKind.pdf => _PdfFirstPage(
        document: document,
        fallback: generated,
      ),
      DocumentKind.image => _ImageThumb(
        document: document,
        fallback: generated,
      ),
      _ => generated,
    };
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              // Sombra de lomo, como en un libro físico.
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x22000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primera página del PDF desde la caché de miniaturas; mientras se genera
/// (solo la primera vez) se ve la portada tipográfica.
class _PdfFirstPage extends ConsumerWidget {
  const new({required this.document, required this.fallback});

  final LibraryDocument document;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = ref
        .watch(pdfCoverProvider((document.id, document.source)))
        .value;
    if (cover == null) return fallback;
    return ColoredBox(
      color: Colors.white,
      child: Image.memory(
        cover,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// La propia imagen, decodificada pequeña para la tarjeta.
class _ImageThumb extends StatelessWidget {
  const new({required this.document, required this.fallback});

  final LibraryDocument document;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    const width = 360;
    Widget error(BuildContext _, Object _, StackTrace? _) => fallback;
    return switch (document.source) {
      FileSource(:final path) => Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: width,
        errorBuilder: error,
      ),
      AssetSource(:final assetPath) => Image.asset(
        assetPath,
        fit: BoxFit.cover,
        cacheWidth: width,
        errorBuilder: error,
      ),
    };
  }
}

/// Portada tipográfica: papel cálido, título en serif y acento por tipo.
class GeneratedCover extends StatelessWidget {
  const new({required this.document, super.key});

  final LibraryDocument document;

  @override
  Widget build(BuildContext context) {
    final accent = document.kind.accent;
    final paper = Color.lerp(AppColors.coverPaper, accent, 0.05)!;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Padding(
            padding: EdgeInsets.fromLTRB(w * 0.12, w * 0.12, w * 0.1, w * 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.extension.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: accent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                    fontSize: (w * 0.065).clamp(8, 12),
                  ),
                ),
                const Spacer(),
                Text(
                  document.title,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.serifDisplay(
                    TextStyle(
                      color: AppColors.coverInk,
                      fontSize: (w * 0.12).clamp(13, 24),
                      height: 1.12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    SizedBox(
                      width: w * 0.18,
                      height: 2,
                      child: ColoredBox(color: accent),
                    ),
                    const Spacer(),
                    Icon(
                      document.kind.icon,
                      size: (w * 0.11).clamp(12, 20),
                      color: accent.withValues(alpha: 0.75),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
