import 'package:sqflite/sqflite.dart';

import 'db_factory.dart';

// Abre la base de datos SQLite (una sola vez) y crea las 3 tablas.
class DbHelper {
  DbHelper._();
  static final DbHelper instancia = DbHelper._(); // patrón singleton

  static const String _nombreBd = 'habitos_app.db';

  // Guardamos el Future (no la BD) para que, si dos pantallas piden la BD
  // a la vez, la base de datos solo se abra UNA vez.
  Future<Database>? _abriendo;

  Future<Database> get db => _abriendo ??= _abrir();

  Future<Database> _abrir() {
    return obtenerDatabaseFactory().openDatabase(
      _nombreBd,
      options: OpenDatabaseOptions(
        version: 1,
        // Activa las claves foráneas (en SQLite vienen desactivadas por defecto)
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _crearTablas,
      ),
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    // TABLA 1: usuarios
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        rol TEXT NOT NULL CHECK (rol IN ('administrador', 'usuario'))
      )
    ''');

    // TABLA 2: habitos (cada hábito es de un usuario)
    // fechas_completadas guarda una lista JSON de fechas: ["2026-10-21","2026-10-22"]
    await db.execute('''
      CREATE TABLE habitos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        color INTEGER NOT NULL,
        fechas_completadas TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
      )
    ''');

    // TABLA 3: estadisticas
    //  - habito_id NULL     -> fila de la app (num_aperturas, ultima_apertura)
    //  - habito_id NO NULL  -> fila de un hábito (racha_actual, total_completados)
    await db.execute('''
      CREATE TABLE estadisticas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        habito_id INTEGER,
        racha_actual INTEGER NOT NULL DEFAULT 0,
        total_completados INTEGER NOT NULL DEFAULT 0,
        num_aperturas INTEGER NOT NULL DEFAULT 0,
        ultima_apertura TEXT,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
        FOREIGN KEY (habito_id) REFERENCES habitos (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Vacía las 3 tablas (la app queda como recién instalada).
  Future<void> borrarTodo() async {
    final base = await db;
    await base.transaction((txn) async {
      await txn.delete('estadisticas');
      await txn.delete('habitos');
      await txn.delete('usuarios');
      // reinicia los contadores autoincrementales (los ids vuelven a empezar en 1)
      await txn.execute('DELETE FROM sqlite_sequence');
    });
  }
}
