import 'dart:async';

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/empty_state.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_actions.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/application/document_providers.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_block_view.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_scaffold.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_states.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/features/settings/presentation/reading_controls.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lector de documentos de texto (Word, TXT, Markdown) con tipografía
/// serif, ambientes de lectura y subrayados.
class FlowReaderScreen extends ConsumerStatefulWidget {
  const new({
    required this.document,
    required this.onMore,
    super.key,
    this.initialBlock,
  });

  final LibraryDocument document;
  final VoidCallback onMore;

  /// Bloque al que saltar al abrir (p. ej. desde un subrayado).
  final int? initialBlock;

  @override
  ConsumerState<FlowReaderScreen> createState() => _FlowReaderScreenState();
}

class _FlowReaderScreenState extends ConsumerState<FlowReaderScreen> {
  final _scroll = ScrollController();
  Timer? _saveTimer;
  double _progress = 0;

  /// Estado que cambia al hacer scroll: va en notifiers para redibujar solo
  /// el porcentaje y la píldora, nunca la lista de párrafos.
  final _percent = ValueNotifier('0 %');
  final _pillVisible = ValueNotifier(true);
  bool _restored = false;
  late final LibraryController _library;

  @override
  void initState() {
    super.initState();
    // Se guarda aquí porque `ref` no se puede usar dentro de dispose().
    _library = ref.read(libraryControllerProvider.notifier);
    _progress = widget.document.progress;
    _percent.value = _format(_progress);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveNow();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _percent.dispose();
    _pillVisible.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scroll.position;
    if (!position.hasContentDimensions) return;
    final max = position.maxScrollExtent;
    final next = max <= 0 ? 1.0 : (position.pixels / max).clamp(0.0, 1.0);
    _progress = next;
    _percent.value = _format(next);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  static String _format(double progress) => '${(progress * 100).round()} %';

  void _saveNow() {
    if (!_restored) return;
    unawaited(
      _library.saveProgress(
        widget.document.id,
        progress: _progress,
        position: _progress,
      ),
    );
  }

  /// Vuelve a la posición guardada. Como la lista es perezosa, la altura
  /// total se estima; se reajusta un par de frames hasta estabilizarse.
  void _restorePosition(int blockCount, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final block = widget.initialBlock;
      final target = block != null && blockCount > 0
          ? (block / blockCount).clamp(0.0, 1.0)
          : widget.document.position.clamp(0.0, 1.0);
      if (target > 0) {
        _scroll.jumpTo(target * _scroll.position.maxScrollExtent);
      }
      if (attempt < 3 && target > 0) {
        _restorePosition(blockCount, attempt + 1);
      } else {
        _restored = true;
      }
    });
  }

  bool _onUserScroll(UserScrollNotification notification) {
    final visible = switch (notification.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _pillVisible.value,
    };
    _pillVisible.value = visible;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = settings.readingTheme;
    final flow = ref.watch(flowDocumentProvider(widget.document.id));

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: AppColors.selection,
          selectionHandleColor: AppColors.selectionHandle,
          cursorColor: AppColors.selectionHandle,
        ),
      ),
      child: ReaderScaffold(
        title: widget.document.title,
        liveSubtitle: _percent,
        background: theme.background,
        foreground: theme.ink,
        muted: theme.muted,
        onMore: widget.onMore,
        pillVisible: _pillVisible,
        bottomPill: FloatingPill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PillButton(
                icon: Icons.text_fields_rounded,
                label: context.l10n.readerAppearance,
                onPressed: () => showReadingSettingsSheet(context),
              ),
              PillButton(
                icon: switch (theme.next.brightness) {
                  Brightness.dark => Icons.dark_mode_outlined,
                  Brightness.light => Icons.light_mode_outlined,
                },
                tooltip: context.l10n.readerAmbience,
                onPressed: () => ref
                    .read(settingsControllerProvider.notifier)
                    .setReadingTheme(theme.next),
              ),
            ],
          ),
        ),
        body: switch (flow) {
          AsyncData(:final value) => _content(
            value,
            FlowReadingStyle(
              theme: theme,
              fontSize: settings.fontSize,
              lineHeight: settings.lineHeight,
            ),
          ),
          AsyncError(:final error) => ReaderError(
            error: error,
            onRetry: () =>
                ref.invalidate(flowDocumentProvider(widget.document.id)),
          ),
          _ => ReaderLoading(color: theme.muted),
        },
      ),
    );
  }

  Widget _content(FlowDocument flow, FlowReadingStyle style) {
    if (flow.isEmpty) {
      _restored = true;
      return EmptyState(
        icon: Icons.notes_rounded,
        title: context.l10n.readerEmpty,
      );
    }
    if (!_restored) _restorePosition(flow.blocks.length);

    final highlights = ref.watch(
      documentHighlightsProvider(widget.document.id),
    );
    final annotations = AnnotationActions(
      context: context,
      ref: ref,
      documentId: widget.document.id,
      documentTitle: widget.document.title,
    );
    final actions = FlowAnnotationActions(
      onMark: (draft, color, style) => annotations.mark([draft], color, style),
      onNote: (draft) => unawaited(annotations.note([draft])),
      onRemove: (draft) => annotations.remove([draft]),
      onCopy: annotations.copy,
      onShare: annotations.share,
    );
    // Columna de lectura de ~680 px como máximo, centrada en tablets.
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > 680 + AppSpacing.lg * 2
        ? (width - 680) / 2
        : AppSpacing.lg;

    return NotificationListener<UserScrollNotification>(
      onNotification: _onUserScroll,
      child: Scrollbar(
        controller: _scroll,
        child: ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
            horizontal,
            AppSpacing.md,
            horizontal,
            AppSpacing.bottomPillClearance +
                MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: flow.blocks.length,
          itemBuilder: (context, index) {
            final block = flow.blocks[index];
            return FlowBlockView(
              block: block,
              blockIndex: index,
              style: style,
              highlights: highlights[index] ?? const [],
              actions: actions,
            );
          },
        ),
      ),
    );
  }
}
