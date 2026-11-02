import 'package:sqflite/sqflite.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Web: SQLite compilado a WebAssembly. Requiere haber ejecutado una vez
//   dart run sqflite_common_ffi_web:setup
// para copiar sqlite3.wasm y sqflite_sw.js a la carpeta web/.
DatabaseFactory obtenerDatabaseFactory() => databaseFactoryFfiWeb;
