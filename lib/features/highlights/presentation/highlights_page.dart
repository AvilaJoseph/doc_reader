import 'dart:async';

import 'package:collection/collection.dart';
import 'package:doc_reader/app/routes.dart';
import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/theme/app_typography.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/empty_state.dart';
import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Todos los subrayados, agrupados por documento.
class HighlightsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final highlights = ref.watch(highlightsControllerProvider).value ?? [];
    final docs = ref.watch(libraryControllerProvider).value ?? [];
    final titles = {for (final d in docs) d.id: d.title};

    // Solo subrayados de documentos que siguen en la biblioteca.
    final groups = groupBy(
      highlights
          .where((h) => titles.containsKey(h.documentId))
          .sorted((a, b) => b.createdAt.compareTo(a.createdAt)),
      (h) => h.documentId,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.xl,
                AppSpacing.page,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.highlightsTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            if (groups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.bottomPillClearance,
                  ),
                  child: EmptyState(
                    icon: Icons.border_color_outlined,
                    title: l10n.highlightsEmptyTitle,
                    body: l10n.highlightsEmptyBody,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.bottomPillClearance,
                ),
                sliver: SliverList.list(
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.lg,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          titles[entry.key]!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      for (final h in entry.value)
                        _HighlightTile(
                          key: ValueKey(h.id),
                          highlight: h,
                          onTap: () => unawaited(
                            context.push(AppRoutes.reader(h.documentId)),
                          ),
                          onDismissed: () => _delete(context, ref, h),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, Highlight h) {
    final controller = ref.read(highlightsControllerProvider.notifier);
    unawaited(controller.remove(h.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.highlightDeleted),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => unawaited(controller.restore(h)),
          ),
        ),
      );
  }
}

class _HighlightTile extends StatelessWidget {
  const new({
    required this.highlight,
    required this.onTap,
    required this.onDismissed,
    super.key,
  });

  final Highlight highlight;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors
        .highlights[highlight.colorIndex % AppColors.highlights.length];
    return Dismissible(
      key: ValueKey(highlight.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.field),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.field),
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                      child: Text(
                        highlight.text,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.reading(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
