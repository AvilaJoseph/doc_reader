import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_typography.dart';
import 'package:doc_reader/core/ui.dart';

/// Radios y espaciados compartidos.
abstract final class AppRadii {
  static const double card = 6;
  static const double sheet = 28;
  static const double pill = 999;
  static const double field = 16;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Margen lateral de las pantallas.
  static const double page = 20;

  /// Espacio reservado al final de las listas para la píldora flotante.
  static const double bottomPillClearance = 112;
}

abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceMuted: AppColors.lightSurfaceMuted,
    ink: AppColors.lightInk,
    inkMuted: AppColors.lightInkMuted,
    line: AppColors.lightLine,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceMuted,
    ink: AppColors.darkInk,
    inkMuted: AppColors.darkInkMuted,
    line: AppColors.darkLine,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceMuted,
    required Color ink,
    required Color inkMuted,
    required Color line,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.kindText,
          brightness: brightness,
        ).copyWith(
          primary: ink,
          onPrimary: background,
          secondary: inkMuted,
          surface: background,
          onSurface: ink,
          onSurfaceVariant: inkMuted,
          surfaceContainerLowest: background,
          surfaceContainerLow: surface,
          surfaceContainer: surface,
          surfaceContainerHigh: surfaceMuted,
          surfaceContainerHighest: surfaceMuted,
          outline: inkMuted,
          outlineVariant: line,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
    );
    final textTheme = AppTypography.uiTextTheme(base.textTheme)
        .apply(bodyColor: ink, displayColor: ink);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: ink,
        side: BorderSide(color: line),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(color: ink),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: background),
        checkmarkColor: background,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        hintStyle: textTheme.bodyLarge?.copyWith(color: inkMuted),
        prefixIconColor: inkMuted,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide.none,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.pill,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.pillInk,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: background,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: line),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: ink,
          selectedForegroundColor: background,
          side: BorderSide(color: line),
          textStyle: textTheme.labelLarge,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ink,
        inactiveTrackColor: line,
        thumbColor: ink,
        overlayColor: ink.withValues(alpha: 0.08),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkMuted,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: inkMuted),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: ink,
        linearTrackColor: line,
      ),
    );
  }
}
