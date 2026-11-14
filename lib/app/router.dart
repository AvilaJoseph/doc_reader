import 'package:doc_reader/app/app_shell.dart';
import 'package:doc_reader/app/routes.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/presentation/highlights_page.dart';
import 'package:doc_reader/features/library/presentation/library_page.dart';
import 'package:doc_reader/features/reader/presentation/reader_page.dart';
import 'package:doc_reader/features/settings/presentation/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.library,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.highlights,
                builder: (context, state) => const HighlightsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      // El lector va fuera del shell: pantalla completa, sin navegación.
      GoRoute(
        path: AppRoutes.readerPattern,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: ReaderPage(
            documentId: state.pathParameters['id']!,
            initialLocation: int.tryParse(
              state.uri.queryParameters['at'] ?? '',
            ),
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
