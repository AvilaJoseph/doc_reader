/// Errores de dominio que la UI sabe presentar al usuario.
sealed class AppException implements Exception {
  const new(this.message);

  /// Mensaje técnico (para logs). La UI usa textos localizados.
  final String message;

  @override
  String toString() => 'AppException: $message';
}

/// El archivo existe pero su contenido no se pudo interpretar.
final class DocumentParseException extends AppException {
  const new(super.message);
}

/// El tipo de archivo todavía no está soportado.
final class UnsupportedFormatException extends AppException {
  const new(super.message);
}

/// El archivo ya no está disponible (borrado, permisos revocados…).
final class DocumentNotFoundException extends AppException {
  const new(super.message);
}
