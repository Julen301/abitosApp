import 'package:flutter/material.dart';

import '../models/habito.dart';

// Colores entre los que se puede elegir (guardados como int, igual que en el modelo)
const List<int> paletaColores = [
  0xFFE53935, // rojo
  0xFFFB8C00, // naranja
  0xFFFDD835, // amarillo
  0xFF43A047, // verde
  0xFF1E88E5, // azul
  0xFF8E24AA, // morado
  0xFF00ACC1, // turquesa
  0xFF6D4C41, // marrón
];

// Función para abrir el formulario desde otras pantallas.
// Devuelve el hábito creado/editado, o null si se cancela.
Future<Habito?> mostrarFormularioHabito(BuildContext context,
    {Habito? existente}) {
  return showDialog<Habito>(
    context: context,
    builder: (_) => HabitoFormDialog(existente: existente),
  );
}

// Formulario para crear o editar un hábito.
// Si "existente" es null estamos creando; si no, estamos editando.
class HabitoFormDialog extends StatefulWidget {
  final Habito? existente;

  const HabitoFormDialog({super.key, this.existente});

  @override
  State<HabitoFormDialog> createState() => _HabitoFormDialogState();
}

class _HabitoFormDialogState extends State<HabitoFormDialog> {
  late final TextEditingController _nombreCtrl;
  late int _color; // color elegido en este momento
  String? _error;

  @override
  void initState() {
    super.initState();
    // Si editamos, rellenamos con los datos que ya tenía; si no, vacío y primer color
    _nombreCtrl = TextEditingController(text: widget.existente?.nombre ?? '');
    _color = widget.existente?.color ?? paletaColores.first;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe un nombre');
      return;
    }

    final e = widget.existente;
    // Cerramos el diálogo devolviendo el hábito nuevo o editado
    Navigator.pop(
      context,
      Habito(
        // Si es nuevo, el id son los microsegundos actuales (único para cada hábito).
        // Si editamos, mantenemos el id que ya tenía.
        id: e?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        nombre: nombre,
        color: _color,
        // Al editar conservamos las fechas ya completadas
        fechasCompletadas: e?.fechasCompletadas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existente == null ? 'Nuevo hábito' : 'Editar hábito'),
      content: Column(
        mainAxisSize: MainAxisSize.min, // el diálogo ocupa solo lo necesario
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nombreCtrl,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Nombre', errorText: _error),
          ),
          const SizedBox(height: 16),
          const Text('Color'),
          const SizedBox(height: 8),
          // Wrap coloca los círculos en filas y salta de línea si no caben
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in paletaColores)
                GestureDetector(
                  onTap: () => setState(() => _color = c), // elegir color
                  child: CircleAvatar(
                    backgroundColor: Color(c),
                    radius: 16,
                    // El elegido muestra un tick
                    child: _color == c
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // cancelar devuelve null
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}