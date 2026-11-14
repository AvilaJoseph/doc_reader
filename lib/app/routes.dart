/// Rutas de la app. Navega siempre con estas constantes, nunca con
/// cadenas sueltas.
abstract final class AppRoutes {
  static const library = '/library';
  static const highlights = '/highlights';
  static const settings = '/settings';
  static const readerPattern = '/reader/:id';

  /// Lector. [at] es la página (PDF) o el bloque (texto) donde abrir.
  static String reader(String documentId, {int? at}) =>
      at == null ? '/reader/$documentId' : '/reader/$documentId?at=$at';
}
