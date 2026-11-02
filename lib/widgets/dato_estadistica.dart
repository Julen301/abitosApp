import 'package:flutter/material.dart';

/// Muestra una etiqueta, un valor y un icono con el mismo diseño.
class DatoEstadistica extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;
  final Color color;

  const DatoEstadistica({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.color = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: color, size: 21),
        const SizedBox(width: 8),
        Expanded(child: Text(etiqueta)),
        Text(valor, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
