// Modelo Estadistica: una fila de la tabla "estadisticas".
//
// Hay DOS tipos de fila:
//  - habitoId == null  -> estadística de la APP para ese usuario
//                         (veces que ha abierto la app + fecha/hora de la última apertura)
//  - habitoId != null  -> estadística de un HÁBITO
//                         (racha actual + total de días completados)
class Estadistica {
  final int? id;
  int usuarioId;
  int? habitoId;
  int rachaActual;
  int totalCompletados;
  int numAperturas;
  DateTime? ultimaApertura;

  // Solo para mostrar (vienen de un JOIN, no son columnas de la tabla)
  String? usuarioNombre;
  String? habitoNombre;
  int? habitoColor;

  Estadistica({
    this.id,
    required this.usuarioId,
    this.habitoId,
    this.rachaActual = 0,
    this.totalCompletados = 0,
    this.numAperturas = 0,
    this.ultimaApertura,
  });

  bool get esDeApp => habitoId == null;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'usuario_id': usuarioId,
        'habito_id': habitoId,
        'racha_actual': rachaActual,
        'total_completados': totalCompletados,
        'num_aperturas': numAperturas,
        'ultima_apertura': ultimaApertura?.toIso8601String(),
      };

  factory Estadistica.fromMap(Map<String, Object?> m) {
    final ultima = m['ultima_apertura'] as String?;
    final e = Estadistica(
      id: m['id'] as int,
      usuarioId: m['usuario_id'] as int,
      habitoId: m['habito_id'] as int?,
      rachaActual: m['racha_actual'] as int,
      totalCompletados: m['total_completados'] as int,
      numAperturas: m['num_aperturas'] as int,
      ultimaApertura: ultima == null ? null : DateTime.tryParse(ultima),
    );
    e.usuarioNombre = m['usuario_nombre'] as String?;
    e.habitoNombre = m['habito_nombre'] as String?;
    e.habitoColor = m['habito_color'] as int?;
    return e;
  }
}
