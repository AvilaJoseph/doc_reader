import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_top_bar.dart';

/// Estructura común de los visores: barra superior, contenido y una
/// píldora flotante opcional abajo que se oculta al leer.
class ReaderScaffold extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    required this.background,
    required this.foreground,
    required this.muted,
    super.key,
    this.subtitle,
    this.bottomPill,
    this.pillVisible = true,
    this.onMore,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? bottomPill;
  final bool pillVisible;
  final Color background;
  final Color foreground;
  final Color muted;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          ReaderTopBar(
            title: title,
            subtitle: subtitle,
            background: background,
            foreground: foreground,
            muted: muted,
            onMore: onMore,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: body),
                if (bottomPill != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AnimatedSlide(
                          offset: pillVisible
                              ? Offset.zero
                              : const Offset(0, 1.6),
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          child: Center(child: bottomPill),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
