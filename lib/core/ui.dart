/// Punto único de importación de la capa de UI de Flutter.
///
/// Flutter 3.47 movió Material al paquete `material_ui`, pero casi todo el
/// ecosistema (go_router, pdfrx, google_fonts…) sigue usando
/// `package:flutter/material.dart`. Ambos definen tipos distintos, así que
/// mezclarlos rompe temas y localizaciones. Toda la app importa este archivo
/// en lugar de Material directamente: cuando el ecosistema migre, solo hay
/// que cambiar esta línea.
library;

// La librería está marcada como obsoleta, pero es la que comparte tipos
// con el resto del ecosistema (ver arriba).
// ignore: deprecated_member_use
export 'package:flutter/material.dart';
