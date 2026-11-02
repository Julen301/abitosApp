import 'package:sqflite/sqflite.dart';

import '../errores.dart';
import '../modelos/estadistica.dart';
import '../modelos/usuario.dart';
import 'db_helper.dart';

// CRUD de la tabla "estadisticas".
//  - Usuario normal: solo LEE las suyas (se actualizan solas al usar la app).
//  - Administrador: lee todas y puede crear, modificar y borrar cualquiera.
class EstadisticaRepository {
  Future<Database> get _db => DbHelper.instancia.db;

  void _exigirAdmin(Usuario actor) {
    if (!actor.esAdmin) {
      throw const ErrorApp('Solo un administrador puede modificar estadísticas');
    }
  }

  // ---------- READ ----------

  Future<List<Estadistica>> listar(Usuario actor, {int? deUsuarioId}) async {
    final db = await _db;
    final filtroId = actor.esAdmin ? deUsuarioId : actor.id;
    final r = await db.rawQuery('''
      SELECT e.*,
             u.usuario AS usuario_nombre,
             h.nombre  AS habito_nombre,
             h.color   AS habito_color
      FROM estadisticas e
      JOIN usuarios u ON u.id = e.usuario_id
      LEFT JOIN habitos h ON h.id = e.habito_id
      ${filtroId == null ? '' : 'WHERE e.usuario_id = ?'}
      ORDER BY e.usuario_id, (e.habito_id IS NOT NULL), e.habito_id
    ''', filtroId == null ? null : [filtroId]);
    return r.map(Estadistica.fromMap).toList();
  }

  // ---------- Aperturas de la app (automático, sin actor) ----------

  /// Suma 1 a las aperturas del usuario y guarda la fecha y hora de ahora.
  Future<void> registrarApertura(int usuarioId) async {
    final db = await _db;
    final ahora = DateTime.now().toIso8601String();
    final filas = await db.rawUpdate(
      'UPDATE estadisticas SET num_aperturas = num_aperturas + 1, '
      'ultima_apertura = ? WHERE usuario_id = ? AND habito_id IS NULL',
      [ahora, usuarioId],
    );
    if (filas == 0) {
      await db.insert(
        'estadisticas',
        Estadistica(
          usuarioId: usuarioId,
          numAperturas: 1,
          ultimaApertura: DateTime.now(),
        ).toMap(),
      );
    }
  }

  // ---------- CREATE ----------

  Future<int> crear(Usuario actor, Estadistica e) async {
    _exigirAdmin(actor);
    final db = await _db;
    await _validar(db, e);
    return db.insert('estadisticas', e.toMap());
  }

  // ---------- UPDATE ----------

  Future<void> actualizar(Usuario actor, Estadistica e) async {
    _exigirAdmin(actor);
    if (e.id == null) throw const ErrorApp('Estadística sin identificador');
    final db = await _db;
    await _validar(db, e);
    await db.update('estadisticas', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  // ---------- DELETE ----------

  Future<void> eliminar(Usuario actor, int id) async {
    _exigirAdmin(actor);
    final db = await _db;
    await db.delete('estadisticas', where: 'id = ?', whereArgs: [id]);
  }

  // El hábito elegido tiene que existir y ser del usuario elegido.
  Future<void> _validar(DatabaseExecutor db, Estadistica e) async {
    if (e.habitoId == null) return;
    final r = await db.query('habitos',
        columns: ['usuario_id'],
        where: 'id = ?',
        whereArgs: [e.habitoId],
        limit: 1);
    if (r.isEmpty) throw const ErrorApp('Ese hábito no existe');
    if (r.first['usuario_id'] != e.usuarioId) {
      throw const ErrorApp('Ese hábito no pertenece al usuario elegido');
    }
  }
}
