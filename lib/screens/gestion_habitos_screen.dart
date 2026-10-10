import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../services/preferencias_service.dart';
import '../widgets/habito_form_dialog.dart';

// Pantalla para crear, editar y borrar hábitos.
class GestionHabitosScreen extends StatefulWidget {
  final PreferenciasService service;

  const GestionHabitosScreen({super.key, required this.service});

  @override
  State<GestionHabitosScreen> createState() => _GestionHabitosScreenState();
}

class _GestionHabitosScreenState extends State<GestionHabitosScreen> {
  List<Habito>? _habitos; // null mientras carga

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Lee los hábitos guardados
  Future<void> _cargar() async {
    final h = await widget.service.cargarHabitos();
    if (!mounted) return;
    setState(() => _habitos = h);
  }

  // PERSISTENCIA: guarda la lista completa tras cada cambio
  Future<void> _guardar() => widget.service.guardarHabitos(_habitos!);

  // CREAR: abrimos el formulario vacío y, si devuelve un hábito, lo añadimos
  Future<void> _crear() async {
    final nuevo = await mostrarFormularioHabito(context);
    if (nuevo == null) return; // el usuario canceló
    setState(() => _habitos!.add(nuevo));
    await _guardar();
  }

  // EDITAR: abrimos el formulario con los datos del hábito
  Future<void> _editar(Habito h) async {
    final editado = await mostrarFormularioHabito(context, existente: h);
    if (editado == null) return;
    setState(() {
      // Buscamos la posición del hábito por su id y lo sustituimos
      final i = _habitos!.indexWhere((x) => x.id == h.id);
      _habitos![i] = editado;
    });
    await _guardar();
  }

  // BORRAR: pedimos confirmación antes de eliminar
  Future<void> _borrar(Habito h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar hábito'),
        content: Text('¿Seguro que quieres borrar "${h.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok != true) return; // si no confirma, no hacemos nada
    setState(() => _habitos!.removeWhere((x) => x.id == h.id));
    await _guardar();
  }

  @override
  Widget build(BuildContext context) {
    final habitos = _habitos;
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar hábitos')),
      // El botón + solo aparece cuando ya han cargado los datos
      floatingActionButton: habitos == null
          ? null
          : FloatingActionButton(
        onPressed: _crear,
        child: const Icon(Icons.add),
      ),
      body: habitos == null
          ? const Center(child: CircularProgressIndicator())
          : habitos.isEmpty
          ? const Center(child: Text('No hay hábitos. Pulsa + para crear uno.'))
          : ListView.builder(
        itemCount: habitos.length,
        itemBuilder: (_, i) {
          final h = habitos[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(h.color),
              radius: 12,
            ),
            title: Text(h.nombre),
            // Dos iconos a la derecha: editar y borrar
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editar(h),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _borrar(h),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}