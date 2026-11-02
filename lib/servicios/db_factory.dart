// Elige "cómo se abre SQLite" según la plataforma:
//  - Web (Chrome): sqflite_common_ffi_web (SQLite en WebAssembly, guarda en IndexedDB)
//  - Android / iOS: sqflite normal
//
// Es un import condicional: en web se usa db_factory_web.dart,
// en el resto db_factory_movil.dart. Las dos tienen la misma función
// obtenerDatabaseFactory().
export 'db_factory_movil.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';
