import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/empty_state.dart';
import 'package:doc_reader/l10n/l10n.dart';

class ReaderLoading extends StatelessWidget {
  const new({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: 28,
      child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
    ),
  );
}

/// Error de carga con mensaje según el tipo de fallo.
class ReaderError extends StatelessWidget {
  const new({required this.error, super.key, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, message) = switch (error) {
      DocumentNotFoundException() => (
        Icons.link_off_rounded,
        l10n.readerErrorMissing,
      ),
      UnsupportedFormatException() => (
        Icons.block_rounded,
        l10n.readerErrorUnsupported,
      ),
      _ => (Icons.error_outline_rounded, l10n.readerError),
    };
    return EmptyState(
      icon: icon,
      title: message,
      actions: [
        if (onRetry != null)
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
