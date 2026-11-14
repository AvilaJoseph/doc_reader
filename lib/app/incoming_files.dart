import 'dart:async';

import 'package:doc_reader/app/router.dart';
import 'package:doc_reader/app/routes.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/data/open_with_channel.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre los documentos que llegan desde otras apps ("Abrir con…" o
/// "Compartir"): los añade a la biblioteca y salta directo al lector.
class IncomingFiles extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<IncomingFiles> createState() => _IncomingFilesState();
}

class _IncomingFilesState extends ConsumerState<IncomingFiles> {
  StreamSubscription<IncomingFile>? _subscription;

  @override
  void initState() {
    super.initState();
    final channel = ref.read(openWithChannelProvider);
    _subscription = channel.files.listen(_open);
    unawaited(
      channel.takeInitialFile().then((file) {
        if (file != null) unawaited(_open(file));
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _open(IncomingFile file) async {
    final library = ref.read(libraryControllerProvider.notifier);
    final router = ref.read(routerProvider);
    await ref.read(libraryControllerProvider.future);
    final result = await library.import([file.toCandidate()]);
    await file.discard();
    if (!mounted) return;

    if (result.added.isNotEmpty) {
      unawaited(router.push(AppRoutes.reader(result.added.first.id)));
      return;
    }
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          result.unsupported.isNotEmpty
              ? l10n.importUnsupported(file.name)
              : l10n.importFailed(file.name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
