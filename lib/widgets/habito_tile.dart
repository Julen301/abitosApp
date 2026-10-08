import 'package:flutter/material.dart';

import '../models/habito.dart';

// Widget de una fila de hábito. No tiene estado propio (StatelessWidget):
// solo dibuja lo que le pasan y avisa cuando se pulsa la casilla.
class HabitoTile extends StatelessWidget {
  final Habito habito;
  final ValueChanged<bool?> onChanged; // función que se ejecuta al marcar/desmarcar

  const HabitoTile({
    super.key,
    required this.habito,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        // La casilla está marcada si el hábito está hecho hoy
        value: habito.completadoHoy,
        onChanged: onChanged,
        // Convertimos el int guardado en un Color de verdad
        activeColor: Color(habito.color),
        // Círculo con el color del hábito a la izquierda
        secondary: CircleAvatar(
          backgroundColor: Color(habito.color),
          radius: 12,
        ),
        title: Text(
          habito.nombre,
          style: TextStyle(
            // Si está hecho, tachamos el texto
            decoration:
            habito.completadoHoy ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}