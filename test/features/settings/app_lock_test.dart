import 'package:doc_reader/app/app_lock_gate.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/settings/application/app_lock.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/features/settings/data/device_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

class _FakeAuth implements DeviceAuth {
  bool succeed = true;
  int calls = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return succeed;
  }
}

void main() {
  late _FakeAuth auth;

  setUp(() => auth = _FakeAuth());

  Future<ProviderContainer> container({bool enabled = false}) =>
      createContainer(
        prefs: {'settings.appLock': enabled},
        overrides: [deviceAuthProvider.overrideWithValue(auth)],
      );

  test('activar exige desbloquear una vez', () async {
    final c = await container();
    final lock = c.read(appLockProvider.notifier);

    auth.succeed = false;
    expect(await lock.setEnabled(enabled: true, reason: 'r'), isFalse);
    expect(c.read(settingsControllerProvider).appLock, isFalse);

    auth.succeed = true;
    expect(await lock.setEnabled(enabled: true, reason: 'r'), isTrue);
    expect(c.read(settingsControllerProvider).appLock, isTrue);
  });

  test('arranca bloqueada y se desbloquea con la huella', () async {
    final c = await container(enabled: true);
    expect(c.read(appLockProvider), isTrue);
    auth.succeed = false;
    await c.read(appLockProvider.notifier).unlock('r');
    expect(c.read(appLockProvider), isTrue);
    auth.succeed = true;
    await c.read(appLockProvider.notifier).unlock('r');
    expect(c.read(appLockProvider), isFalse);
  });

  test('solo vuelve a bloquear tras un rato fuera', () async {
    final c = await container(enabled: true);
    final lock = c.read(appLockProvider.notifier);
    await lock.unlock('r');
    final t = DateTime(2026);

    lock
      ..onHidden(t)
      ..onResumed(t.add(const Duration(seconds: 5)));
    expect(c.read(appLockProvider), isFalse);

    lock
      ..onHidden(t)
      ..onResumed(t.add(AppLockController.grace));
    expect(c.read(appLockProvider), isTrue);
  });

  test('sin bloqueo activado nunca bloquea', () async {
    final c = await container();
    final lock = c.read(appLockProvider.notifier);
    final t = DateTime(2026);
    lock
      ..onHidden(t)
      ..onResumed(t.add(const Duration(hours: 1)));
    expect(c.read(appLockProvider), isFalse);
  });

  testWidgets('tapa la app y pide la huella al abrir', (tester) async {
    final c = await container(enabled: true);
    auth.succeed = false;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: localizedApp(const AppLockGate(child: Text('secreto'))),
      ),
    );
    await tester.pump();
    expect(find.text('Folio está bloqueado'), findsOneWidget);
    expect(auth.calls, 1);

    auth.succeed = true;
    await tester.tap(find.text('Desbloquear'));
    await tester.pump();
    expect(find.text('Folio está bloqueado'), findsNothing);
    expect(find.text('secreto'), findsOneWidget);
  });
}
