import 'package:flutter/material.dart';

/// Representación visual reutilizable de un hábito; no accede a datos externos.
class TarjetaHabito extends StatelessWidget {
  final String nombre;
  final Color color;
  final bool completadoHoy;
  final IconData icono;
  final VoidCallback onCompletar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const TarjetaHabito({
    super.key,
    required this.nombre,
    required this.color,
    required this.completadoHoy,
    this.icono = Icons.check_circle_outline,
    required this.onCompletar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: completadoHoy ? color.withOpacity(0.13) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: completadoHoy ? color : scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: completadoHoy ? 'Marcar como pendiente' : 'Completar hoy',
              onPressed: onCompletar,
              icon: Icon(completadoHoy ? Icons.check_circle : icono, color: color),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: TextStyle(fontWeight: FontWeight.w600,
                    decoration: completadoHoy ? TextDecoration.lineThrough : null)),
                  Text(completadoHoy ? 'Completado hoy' : 'Pendiente',
                    style: TextStyle(fontSize: 12, color: completadoHoy ? color : scheme.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(tooltip: 'Editar', onPressed: onEditar, icon: const Icon(Icons.edit_outlined)),
            IconButton(tooltip: 'Eliminar', onPressed: onEliminar,
              icon: Icon(Icons.delete_outline, color: scheme.error)),
          ],
        ),
      ),
    );
  }
}
