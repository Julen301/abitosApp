import 'package:sqflite/sqflite.dart';

import '../errores.dart';
import '../modelos/estadistica.dart';
import '../modelos/usuario.dart';
import 'db_helper.dart';

// CRUD de la tabla "usuarios".
// Las operaciones de gestión (listar, crear, actualizar, eliminar) exigen que
// quien las pide ("actor") sea administrador: el permiso se comprueba AQUÍ,
// no solo en la pantalla.
class UsuarioRepository {
  Future<Database> get _db => DbHelper.instancia.db;

  void _exigirAdmin(Usuario actor) {
    if (!actor.esAdmin) {
      throw const ErrorApp('Solo un administrador puede hacer esto');
    }
  }

  // ---------- Lecturas que usa el login / arranque (sin actor) ----------

  Future<int> contar() async {
    final db = await _db;
    final r = await db.rawQuery('SELECT COUNT(*) AS n FROM usuarios');
    return (r.first['n'] as num).toInt();
  }

  Future<Usuario?> porId(int id) async {
    final db = await _db;
    final r =
        await db.query('usuarios', where: 'id = ?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Usuario.fromMap(r.first);
  }

  /// Busca por nombre de usuario O por email (sin distinguir mayúsculas).
  Future<Usuario?> porUsuarioOEmail(String texto) async {
    final db = await _db;
    final t = texto.trim().toLowerCase();
    final r = await db.query(
      'usuarios',
      where: 'LOWER(usuario) = ? OR LOWER(email) = ?',
      whereArgs: [t, t],
      limit: 1,
    );
    return r.isEmpty ? null : Usuario.fromMap(r.first);
  }

  // ---------- CREATE ----------

  /// Inserta el usuario y, a la vez, su fila de estadísticas de la app
  /// (aperturas). Lo usa el registro (sin actor) y el panel de admin.
  Future<int> insertar(Usuario u) async {
    final db = await _db;
    return db.transaction((txn) async {
      await _comprobarUnicos(txn, u);
      final id = await txn.insert('usuarios', u.toMap());
      await txn.insert('estadisticas', Estadistica(usuarioId: id).toMap());
      return id;
    });
  }

  Future<int> crear(Usuario actor, Usuario nuevo) async {
    _exigirAdmin(actor);
    return insertar(nuevo);
  }

  // ---------- READ ----------

  Future<List<Usuario>> listar(Usuario actor) async {
    _exigirAdmin(actor);
    final db = await _db;
    final r = await db.query('usuarios', orderBy: 'id');
    return r.map(Usuario.fromMap).toList();
  }

  // ---------- UPDATE ----------

  Future<void> actualizar(Usuario actor, Usuario u) async {
    _exigirAdmin(actor);
    if (u.id == null) throw const ErrorApp('Usuario sin identificador');
    final db = await _db;
    await db.transaction((txn) async {
      await _comprobarUnicos(txn, u);
      final r = await txn.query('usuarios',
          where: 'id = ?', whereArgs: [u.id], limit: 1);
      if (r.isEmpty) throw const ErrorApp('El usuario ya no existe');
      final antes = Usuario.fromMap(r.first);
      // Si le quitamos el rol de administrador, tiene que quedar otro admin
      if (antes.esAdmin && !u.esAdmin) {
        await _exigirOtroAdmin(txn, u.id!);
      }
      await txn.update('usuarios', u.toMap(),
          where: 'id = ?', whereArgs: [u.id]);
    });
  }

  // ---------- DELETE ----------

  Future<void> eliminar(Usuario actor, int id) async {
    _exigirAdmin(actor);
    if (actor.id == id) {
      throw const ErrorApp('No puedes eliminar tu propio usuario');
    }
    final db = await _db;
    await db.transaction((txn) async {
      // Borramos lo suyo primero (las claves foráneas también lo harían en cascada)
      await txn.delete('estadisticas', where: 'usuario_id = ?', whereArgs: [id]);
      await txn.delete('habitos', where: 'usuario_id = ?', whereArgs: [id]);
      await txn.delete('usuarios', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ---------- Validaciones internas ----------

  Future<void> _comprobarUnicos(DatabaseExecutor db, Usuario u) async {
    final idActual = u.id ?? -1; // -1: al crear no hay que excluir a nadie
    final porUsuario = await db.query(
      'usuarios',
      where: 'LOWER(usuario) = ? AND id != ?',
      whereArgs: [u.usuario.toLowerCase(), idActual],
      limit: 1,
    );
    if (porUsuario.isNotEmpty) {
      throw const ErrorApp('Ese nombre de usuario ya existe');
    }
    final porEmail = await db.query(
      'usuarios',
      where: 'LOWER(email) = ? AND id != ?',
      whereArgs: [u.email.toLowerCase(), idActual],
      limit: 1,
    );
    if (porEmail.isNotEmpty) {
      throw const ErrorApp('Ese email ya está registrado');
    }
  }

  Future<void> _exigirOtroAdmin(DatabaseExecutor db, int idExcluido) async {
    final r = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM usuarios WHERE rol = 'administrador' AND id != ?",
      [idExcluido],
    );
    if ((r.first['n'] as num).toInt() == 0) {
      throw const ErrorApp('Tiene que quedar al menos un administrador');
    }
  }
}
