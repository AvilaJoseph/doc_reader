/// Rutas de la app. Navega siempre con estas constantes, nunca con
/// cadenas sueltas.
abstract final class AppRoutes {
  static const library = '/library';
  static const highlights = '/highlights';
  static const settings = '/settings';
  static const readerPattern = '/reader/:id';

  static String reader(String documentId) => '/reader/$documentId';
}
