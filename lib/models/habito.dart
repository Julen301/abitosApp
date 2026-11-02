import 'dart:convert';

// Modelo Habito: una fila de la tabla "habitos".
// Ahora cada hábito pertenece a un usuario (usuarioId) y el id lo genera SQLite.
class Habito {
  final int? id; // null mientras no esté guardado en la BD
  int usuarioId; // dueño del hábito
  String nombre;
  int color;
  List<String> fechasCompletadas;

  // Solo para listados del administrador (viene de un JOIN, no es columna)
  String? propietario;

  Habito({
    this.id,
    required this.usuarioId,
    required this.nombre,
    required this.color,
    List<String>? fechasCompletadas,
  }) : fechasCompletadas = fechasCompletadas ?? [];

  static String claveFecha(DateTime d) =>
      // padLeft() rellena con ceros a la izquierda, para que el mes en vez de 3 sea 03
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // completadoHoy convierte la fecha de hoy en texto y mira si está en la lista
  bool get completadoHoy => fechasCompletadas.contains(claveFecha(DateTime.now()));

  // totalCompletados es simplemente cuántas fechas hay
  int get totalCompletados => fechasCompletadas.length;

  int get rachaActual {
    final set = fechasCompletadas.toSet();
    var dia = DateTime.now();
    // si hoy aún no está hecho empezamos a contar desde ayer,
    // así la racha no se pierde mientras el día no ha acabado
    if (!set.contains(claveFecha(dia))) {
      dia = DateTime(dia.year, dia.month, dia.day - 1);
    }
    var racha = 0;
    while (set.contains(claveFecha(dia))) {
      racha++;
      dia = DateTime(dia.year, dia.month, dia.day - 1);
    }
    return racha;
  }

  void alternarHoy() {
    final hoy = claveFecha(DateTime.now());
    if (fechasCompletadas.contains(hoy)) {
      fechasCompletadas.remove(hoy);
    } else {
      fechasCompletadas.add(hoy);
    }
  }

  // Objeto -> fila de la BD. Las fechas se guardan como texto JSON: ["2026-10-21", ...]
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'usuario_id': usuarioId,
        'nombre': nombre,
        'color': color,
        'fechas_completadas': jsonEncode(fechasCompletadas),
      };

  // Fila de la BD -> objeto
  factory Habito.fromMap(Map<String, Object?> m) {
    final h = Habito(
      id: m['id'] as int,
      usuarioId: m['usuario_id'] as int,
      nombre: m['nombre'] as String,
      color: m['color'] as int,
      fechasCompletadas: List<String>.from(
          jsonDecode(m['fechas_completadas'] as String? ?? '[]') as List),
    );
    h.propietario = m['propietario'] as String?;
    return h;
  }
}
