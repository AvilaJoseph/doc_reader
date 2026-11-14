import 'package:flutter/foundation.dart';

/// Dónde están los bytes de un documento.
@immutable
sealed class DocumentSource {
  const new();

  /// Serializa a un URI de texto: `file:///…` o `asset:assets/…`.
  String encode();

  static DocumentSource decode(String value) {
    if (value.startsWith(AssetSource.scheme)) {
      return AssetSource(value.substring(AssetSource.scheme.length));
    }
    return FileSource(Uri.parse(value).toFilePath());
  }
}

/// Archivo copiado al almacenamiento privado de la app.
final class FileSource extends DocumentSource {
  const new(this.path);

  final String path;

  @override
  String encode() => Uri.file(path).toString();

  @override
  bool operator ==(Object other) => other is FileSource && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

/// Documento de ejemplo empaquetado con la app.
final class AssetSource extends DocumentSource {
  const new(this.assetPath);

  static const scheme = 'asset:';

  final String assetPath;

  @override
  String encode() => '$scheme$assetPath';

  @override
  bool operator ==(Object other) =>
      other is AssetSource && other.assetPath == assetPath;

  @override
  int get hashCode => assetPath.hashCode;
}
