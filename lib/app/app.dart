import 'package:doc_reader/app/app_lock_gate.dart';
import 'package:doc_reader/app/incoming_files.dart';
import 'package:doc_reader/app/router.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => AppLockGate(
        child: IncomingFiles(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
