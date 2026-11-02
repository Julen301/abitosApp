import 'package:sqflite/sqflite.dart';

import '../errores.dart';
import '../models/estadistica.dart';
import '../models/habito.dart';
import '../models/usuario.dart';
import 'db_helper.dart';

// CRUD de la tabla "habitos".
// Reglas de permisos (se comprueban aquí, no solo en la pantalla):
//  - Usuario normal: solo ve, crea, modifica y borra SUS hábitos.
//  - Administrador: puede hacerlo con los de cualquier usuario.
// Cada vez que cambia un hábito se actualiza su fila en "estadisticas".
class HabitoRepository {
  Future<Database> get _db => DbHelper.instancia.db;

  void _exigirDueno(Usuario actor, int usuarioIdDelHabito) {
    if (!actor.esAdmin && actor.id != usuarioIdDelHabito) {
      throw const ErrorApp('Ese hábito no es tuyo');
    }
  }

  // ---------- READ ----------

  /// Un usuario normal siempre recibe SOLO los suyos (aunque pida otra cosa).
  /// Un admin recibe todos, o solo los de [deUsuarioId] si lo indica.
  Future<List<Habito>> listar(Usuario actor, {int? deUsuarioId}) async {
    final db = await _db;
    final filtroId = actor.esAdmin ? deUsuarioId : actor.id;
    final r = await db.rawQuery('''
      SELECT h.*, u.usuario AS propietario
      FROM habitos h
      JOIN usuarios u ON u.id = h.usuario_id
      ${filtroId == null ? '' : 'WHERE h.usuario_id = ?'}
      ORDER BY h.id
    ''', filtroId == null ? null : [filtroId]);
    return r.map(Habito.fromMap).toList();
  }

  Future<Habito?> _porId(DatabaseExecutor db, int id) async {
    final r = await db.rawQuery('''
      SELECT h.*, u.usuario AS propietario
      FROM habitos h
      JOIN usuarios u ON u.id = h.usuario_id
      WHERE h.id = ?
    ''', [id]);
    return r.isEmpty ? null : Habito.fromMap(r.first);
  }

  // ---------- CREATE ----------

  Future<int> crear(Usuario actor, Habito h) async {
    _exigirDueno(actor, h.usuarioId);
    final db = await _db;
    return db.transaction((txn) async {
      final id = await txn.insert('habitos', h.toMap());
      await _sincronizarEstadistica(
        txn,
        Habito(
          id: id,
          usuarioId: h.usuarioId,
          nombre: h.nombre,
          color: h.color,
          fechasCompletadas: h.fechasCompletadas,
        ),
      );
      return id;
    });
  }

  // ---------- UPDATE ----------

  Future<void> actualizar(Usuario actor, Habito h) async {
    if (h.id == null) throw const ErrorApp('Hábito sin identificador');
    final db = await _db;
    await db.transaction((txn) async {
      final actual = await _porId(txn, h.id!);
      if (actual == null) throw const ErrorApp('El hábito ya no existe');
      _exigirDueno(actor, actual.usuarioId);
      // Un usuario normal no puede regalarle el hábito a otra persona
      if (!actor.esAdmin && h.usuarioId != actual.usuarioId) {
        throw const ErrorApp('No puedes cambiar el propietario del hábito');
      }
      await txn.update('habitos', h.toMap(), where: 'id = ?', whereArgs: [h.id]);
      await _sincronizarEstadistica(txn, h);
    });
  }

  /// Marca/desmarca el hábito como hecho hoy y lo guarda.
  Future<void> alternarHoy(Usuario actor, Habito h) async {
    h.alternarHoy();
    await actualizar(actor, h);
  }

  // ---------- DELETE ----------

  Future<void> eliminar(Usuario actor, Habito h) async {
    if (h.id == null) return;
    final db = await _db;
    await db.transaction((txn) async {
      final actual = await _porId(txn, h.id!);
      if (actual == null) return; // ya estaba borrado
      _exigirDueno(actor, actual.usuarioId);
      await txn.delete('estadisticas',
          where: 'habito_id = ?', whereArgs: [h.id]);
      await txn.delete('habitos', where: 'id = ?', whereArgs: [h.id]);
    });
  }

  /// Borra TODOS los hábitos de un usuario (y sus estadísticas de hábito).
  /// Se conserva su cuenta y su fila de aperturas de la app.
  Future<void> borrarDeUsuario(Usuario actor, int usuarioId) async {
    _exigirDueno(actor, usuarioId);
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('estadisticas',
          where: 'usuario_id = ? AND habito_id IS NOT NULL',
          whereArgs: [usuarioId]);
      await txn.delete('habitos', where: 'usuario_id = ?', whereArgs: [usuarioId]);
    });
  }

  // ---------- Estadísticas del hábito ----------

  /// Deja la fila de estadísticas del hábito al día (racha y total).
  /// Si todavía no existía, la crea.
  Future<void> _sincronizarEstadistica(DatabaseExecutor db, Habito h) async {
    final valores = <String, Object?>{
      'usuario_id': h.usuarioId,
      'racha_actual': h.rachaActual,
      'total_completados': h.totalCompletados,
    };
    final filas = await db.update('estadisticas', valores,
        where: 'habito_id = ?', whereArgs: [h.id]);
    if (filas == 0) {
      await db.insert(
        'estadisticas',
        Estadistica(
          usuarioId: h.usuarioId,
          habitoId: h.id,
          rachaActual: h.rachaActual,
          totalCompletados: h.totalCompletados,
        ).toMap(),
      );
    }
  }
}
