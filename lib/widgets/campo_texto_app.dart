import 'package:flutter/material.dart';

/// Campo de texto común. El controlador y su ciclo de vida pertenecen a la pantalla.
class CampoTextoApp extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final bool obscureText;

  const CampoTextoApp({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: etiqueta),
    );
  }
}
