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
        // Transición corta (fundido + leve subida): abrir se siente
        // inmediato y sigue orientando de dónde viene el documento.
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: _fadeThrough,
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

Widget _fadeThrough(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
