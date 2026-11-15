import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/features/settings/data/device_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceAuthProvider = Provider<DeviceAuth>((ref) => LocalDeviceAuth());

/// Si el móvil admite el bloqueo (para mostrar u ocultar la opción).
final appLockSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(deviceAuthProvider).isSupported(),
);

/// Estado del bloqueo de la app: `true` mientras está bloqueada.
final appLockProvider = NotifierProvider<AppLockController, bool>(
  AppLockController.new,
);

class AppLockController extends Notifier<bool> {
  /// Tiempo fuera de la app antes de volver a pedir la huella: así no
  /// molesta al cambiar un momento a otra app.
  static const grace = Duration(seconds: 30);

  DateTime? _leftAt;
  bool _authenticating = false;

  bool get _enabled =>
      ref.read(settingsControllerProvider.select((s) => s.appLock));

  @override
  bool build() => ref.read(settingsControllerProvider.select((s) => s.appLock));

  /// La app pasa a segundo plano.
  void onHidden(DateTime now) {
    if (!_authenticating) _leftAt ??= now;
  }

  /// La app vuelve: se bloquea si estuvo fuera más de [grace].
  void onResumed(DateTime now) {
    final left = _leftAt;
    _leftAt = null;
    if (_enabled && left != null && now.difference(left) >= grace) {
      state = true;
    }
  }

  /// Pide la huella y desbloquea si se consigue.
  Future<bool> unlock(String reason) async {
    if (_authenticating) return false;
    _authenticating = true;
    try {
      final ok = await ref.read(deviceAuthProvider).authenticate(reason);
      if (ok) state = false;
      return ok;
    } finally {
      _authenticating = false;
      _leftAt = null;
    }
  }

  /// Activa o desactiva el bloqueo; activarlo exige desbloquear una vez
  /// para comprobar que funciona.
  Future<bool> setEnabled({
    required bool enabled,
    required String reason,
  }) async {
    final settings = ref.read(settingsControllerProvider.notifier);
    if (!enabled) {
      settings.setAppLock(enabled: false);
      state = false;
      return true;
    }
    _authenticating = true;
    try {
      final ok = await ref.read(deviceAuthProvider).authenticate(reason);
      if (ok) settings.setAppLock(enabled: true);
      return ok;
    } finally {
      _authenticating = false;
      _leftAt = null;
    }
  }
}
