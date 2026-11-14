import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/features/settings/domain/app_settings.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controles de lectura (tamaño, interlineado y ambiente). Se usan en la
/// hoja del lector y en Ajustes.
class ReadingControls extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: textTheme.labelLarge?.copyWith(color: muted)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        label(l10n.readerTextSize),
        Row(
          children: [
            Text('A', style: textTheme.bodySmall),
            Expanded(
              child: Slider(
                value: settings.fontSize,
                min: AppSettings.minFontSize,
                max: AppSettings.maxFontSize,
                divisions: (AppSettings.maxFontSize - AppSettings.minFontSize)
                    .round(),
                label: settings.fontSize.round().toString(),
                onChanged: controller.setFontSize,
              ),
            ),
            Text('A', style: textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        label(l10n.readerLineHeight),
        Row(
          children: [
            Icon(Icons.density_small_rounded, size: 18, color: muted),
            Expanded(
              child: Slider(
                value: settings.lineHeight,
                min: AppSettings.minLineHeight,
                max: AppSettings.maxLineHeight,
                divisions: 9,
                label: settings.lineHeight.toStringAsFixed(1),
                onChanged: controller.setLineHeight,
              ),
            ),
            Icon(Icons.density_large_rounded, size: 18, color: muted),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        label(l10n.readerAmbience),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final theme in ReadingTheme.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _AmbienceSwatch(
                    theme: theme,
                    label: switch (theme) {
                      ReadingTheme.paper => l10n.readingThemePaper,
                      ReadingTheme.sepia => l10n.readingThemeSepia,
                      ReadingTheme.night => l10n.readingThemeNight,
                    },
                    selected: settings.readingTheme == theme,
                    onTap: () => controller.setReadingTheme(theme),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AmbienceSwatch extends StatelessWidget {
  const new({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ReadingTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  color: theme.ink,
                  fontSize: 18,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: theme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre los controles de lectura en una hoja inferior.
Future<void> showReadingSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.readerAppearance,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            const ReadingControls(),
          ],
        ),
      ),
    ),
  );
}
