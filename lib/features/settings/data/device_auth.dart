import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Huella, cara o PIN del propio móvil. Interfaz para poder simularla en
/// tests.
abstract interface class DeviceAuth {
  /// Si el móvil tiene algún bloqueo (huella, cara o PIN) configurado.
  Future<bool> isSupported();

  /// Pide desbloquear; `true` si la persona lo consigue.
  Future<bool> authenticate(String reason);
}

class LocalDeviceAuth implements DeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // Permite el PIN del móvil si la huella falla: nunca deja fuera.
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
