import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Servicio del sistema para "Traducir", "Definir"… sobre un texto.
///
/// En Android son las acciones `PROCESS_TEXT` de las apps instaladas
/// (Google Traductor, diccionarios…): no añade peso ni necesita red
/// propia. En otras plataformas la lista queda vacía.
final processTextServiceProvider = Provider<ProcessTextService>(
  (ref) => DefaultProcessTextService(),
);

/// Acciones de texto disponibles, consultadas una vez por sesión.
final textLookupActionsProvider = FutureProvider<List<ProcessTextAction>>((
  ref,
) async {
  try {
    return await ref.watch(processTextServiceProvider).queryTextActions();
  } on Object {
    return const [];
  }
});
