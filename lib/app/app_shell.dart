import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

/// Marco de las pestañas principales con la navegación en píldora flotante.
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.auto_stories_outlined, Icons.auto_stories, l10n.navLibrary),
      (Icons.border_color_outlined, Icons.border_color, l10n.navHighlights),
      (Icons.tune_outlined, Icons.tune, l10n.navSettings),
    ];
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (index, (icon, selectedIcon, label))
                        in items.indexed)
                      PillButton(
                        vertical: true,
                        icon: index == navigationShell.currentIndex
                            ? selectedIcon
                            : icon,
                        label: label,
                        selected: index == navigationShell.currentIndex,
                        onPressed: () => navigationShell.goBranch(
                          index,
                          initialLocation:
                              index == navigationShell.currentIndex,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
