import 'dart:async';

import 'package:doc_reader/app/routes.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/circle_icon_button.dart';
import 'package:doc_reader/core/widgets/empty_state.dart';
import 'package:doc_reader/core/widgets/filter_pill.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/application/library_filter.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/library/presentation/import_documents.dart';
import 'package:doc_reader/features/library/presentation/widgets/document_actions_sheet.dart';
import 'package:doc_reader/features/library/presentation/widgets/document_card.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pantalla principal: cuadrícula de documentos con búsqueda y filtros.
class LibraryPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    final hasDocuments = library.value?.isNotEmpty ?? false;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: switch (library) {
          AsyncData() when !hasDocuments => const _EmptyLibrary(),
          AsyncData() => const _LibraryContent(),
          AsyncError() => EmptyState(
            icon: Icons.error_outline_rounded,
            title: context.l10n.readerError,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _LibraryContent extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final docs = ref.watch(filteredLibraryProvider).value ?? const [];
    final isFiltering =
        ref.watch(librarySearchProvider).isNotEmpty ||
        ref.watch(libraryKindFilterProvider) != null ||
        ref.watch(libraryFavoritesOnlyProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = (width / 180).floor().clamp(2, 6);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.libraryTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const _SortButton(),
                const SizedBox(width: AppSpacing.sm),
                CircleIconButton(
                  icon: Icons.add_rounded,
                  tooltip: l10n.addDocument,
                  onPressed: () => pickAndImportDocuments(context, ref),
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(child: _SearchField()),
        ),
        const SliverToBoxAdapter(child: _KindFilterChips()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.bottomPillClearance,
          ),
          sliver: docs.isEmpty && isFiltering
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: l10n.libraryNoResults,
                    ),
                  ),
                )
              : SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.md + 2,
                    // Portada (0.7) + tres líneas de texto.
                    childAspectRatio: 0.5,
                  ),
                  itemCount: docs.length + (isFiltering ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (!isFiltering && index == 0) {
                      return AddDocumentCard(
                        onTap: () => pickAndImportDocuments(context, ref),
                      );
                    }
                    final doc = docs[index - (isFiltering ? 0 : 1)];
                    return DocumentCard(
                      key: ValueKey(doc.id),
                      document: doc,
                      onTap: () => _open(context, doc),
                      onMore: () => showDocumentActions(
                        context,
                        ref,
                        doc,
                        onOpen: () => _open(context, doc),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _open(BuildContext context, LibraryDocument doc) =>
      unawaited(context.push(AppRoutes.reader(doc.id)));
}

class _SearchField extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final _text = TextEditingController(
    text: ref.read(librarySearchProvider),
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      textInputAction: TextInputAction.search,
      onChanged: (value) =>
          ref.read(librarySearchProvider.notifier).query = value,
      decoration: InputDecoration(
        hintText: context.l10n.librarySearchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ListenableBuilder(
          listenable: _text,
          builder: (context, _) => _text.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _text.clear();
                    ref.read(librarySearchProvider.notifier).query = '';
                  },
                ),
        ),
      ),
    );
  }
}

class _KindFilterChips extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(libraryKindFilterProvider);
    final favorites = ref.watch(libraryFavoritesOnlyProvider);
    final notifier = ref.read(libraryKindFilterProvider.notifier);
    final favoritesNotifier = ref.read(libraryFavoritesOnlyProvider.notifier);
    // null = Todos; la segunda entrada es Favoritos; el resto, tipos.
    final options = <(DocumentKind?, String)>[
      (null, l10n.filterAll),
      (null, l10n.filterFavorites),
      (DocumentKind.pdf, l10n.kindPdf),
      (DocumentKind.word, l10n.kindWord),
      (DocumentKind.spreadsheet, l10n.kindSpreadsheet),
      (DocumentKind.text, l10n.kindText),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (kind, label) = options[index];
          final isFavorites = index == 1;
          return FilterPill(
            label: label,
            selected: isFavorites ? favorites : !favorites && kind == selected,
            onTap: () {
              favoritesNotifier.enabled = isFavorites;
              notifier.kind = kind;
            },
          );
        },
      ),
    );
  }
}

class _EmptyLibrary extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.bottomPillClearance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xl,
              AppSpacing.page,
              0,
            ),
            child: Text(
              l10n.libraryTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.auto_stories_outlined,
              title: l10n.libraryEmptyTitle,
              body: l10n.libraryEmptyBody,
              actions: [
                FilledButton.icon(
                  onPressed: () => pickAndImportDocuments(context, ref),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(l10n.libraryOpenFile),
                ),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(libraryControllerProvider.notifier).addSamples(),
                  child: Text(l10n.libraryTrySamples),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de orden: un menú corto con las cuatro opciones.
class _SortButton extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(librarySortProvider);
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<LibrarySort>(
      tooltip: l10n.librarySort,
      initialValue: current,
      onSelected: ref.read(librarySortProvider.notifier).select,
      itemBuilder: (context) => [
        for (final (sort, label) in [
          (LibrarySort.recent, l10n.librarySortRecent),
          (LibrarySort.title, l10n.librarySortTitle),
          (LibrarySort.added, l10n.librarySortAdded),
          (LibrarySort.progress, l10n.librarySortProgress),
        ])
          CheckedPopupMenuItem(
            value: sort,
            checked: sort == current,
            child: Text(label),
          ),
      ],
      child: SizedBox.square(
        dimension: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sort_rounded, size: 20),
        ),
      ),
    );
  }
}
