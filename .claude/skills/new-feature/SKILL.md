---
name: new-feature
description: Crear una funcionalidad nueva en Folio siguiendo la arquitectura feature-first (domain/data/application/presentation), Riverpod 3, go_router, l10n y tests.
---

# Nueva funcionalidad

1. Lee `CLAUDE.md` y `docs/ARCHITECTURE.md`. Decide si encaja en una
   feature existente (`library`, `reader`, `highlights`, `settings`) o
   necesita `lib/features/<nombre>/`.
2. **domain/**: modelos inmutables (`@immutable`, `copyWith`, `==`,
   `toJson/fromJson` si se guardan) e interfaces de repositorio.
3. **data/**: implementación del repositorio. Claves de SharedPreferences
   versionadas (`<feature>.<cosa>.v1`).
4. **application/**: providers. Repositorio como `Provider` (para poder
   sobreescribirlo), estado con `Notifier`/`AsyncNotifier`. Métodos con
   nombre de verbo (`add`, `remove`, `setX`), nunca setters.
5. **presentation/**: importa Material solo con
   `package:doc_reader/core/ui.dart`; textos con `context.l10n`; colores y
   medidas del tema (`AppSpacing`, `AppRadii`, `colorScheme`). Reutiliza
   `FloatingPill`, `CircleIconButton`, `EmptyState`, `FilterPill`.
6. **Rutas**: constante en `lib/app/routes.dart` y `GoRoute` en
   `lib/app/router.dart`. Si es una pestaña principal, añade una rama al
   `StatefulShellRoute` y un elemento a `AppShell`.
7. **l10n**: claves en `app_es.arb` (plantilla) y `app_en.arb`; luego
   `flutter gen-l10n` (o `flutter pub get`).
8. **Tests**: controller con `createContainer()`; widgets con
   `localizedApp()` (`test/helpers/test_app.dart`).
9. Cierra con `dart format lib test && dart fix --apply && flutter analyze &&
   flutter test`, y revisa la UI con la skill `check-ui`.
