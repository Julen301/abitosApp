import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../errores.dart';
import '../models/estadistica.dart';
import '../models/usuario.dart';
import '../services/servicios.dart';
import '../widgets/confirmar_dialog.dart';
import '../widgets/estadistica_form_dialog.dart';

// Pestaña "Estadísticas" del panel de admin: CRUD de la tabla "estadisticas".
// Nota: las filas de hábitos se recalculan solas cuando un usuario marca o
// desmarca ese hábito, así que un valor editado a mano se sobrescribe entonces.
class AdminEstadisticasTab extends StatefulWidget {
  final Servicios servicios;
  final Usuario usuario; // el administrador

  const AdminEstadisticasTab({
    super.key,
    required this.servicios,
    required this.usuario,
  });

  @override
  State<AdminEstadisticasTab> createState() => _AdminEstadisticasTabState();
}

class _AdminEstadisticasTabState extends State<AdminEstadisticasTab> {
  static final DateFormat _formato = DateFormat('dd/MM/yyyy HH:mm');
  List<Estadistica>? _filas; // null mientras carga

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // READ: todas las filas de todos los usuarios
  Future<void> _cargar() async {
    try {
      final f = await widget.servicios.estadisticas.listar(widget.usuario);
      if (!mounted) return;
      setState(() => _filas = f);
    } on ErrorApp catch (e) {
      _aviso(e.mensaje);
    }
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    try {
      await accion();
      await _cargar();
    } on ErrorApp catch (e) {
      _aviso(e.mensaje);
    }
  }

  // CREATE
  Future<void> _crear() async {
    final s = widget.servicios;
    final usuarios = await s.usuarios.listar(widget.usuario);
    final habitos = await s.habitos.listar(widget.usuario);
    if (!mounted) return;
    final nueva = await mostrarFormularioEstadistica(
      context,
      usuarios: usuarios,
      habitos: habitos,
    );
    if (nueva == null) return;
    await _ejecutar(() => s.estadisticas.crear(widget.usuario, nueva));
  }

  // UPDATE
  Future<void> _editar(Estadistica e) async {
    final s = widget.servicios;
    final usuarios = await s.usuarios.listar(widget.usuario);
    final habitos = await s.habitos.listar(widget.usuario);
    if (!mounted) return;
    final editada = await mostrarFormularioEstadistica(
      context,
      usuarios: usuarios,
      habitos: habitos,
      existente: e,
    );
    if (editada == null) return;
    await _ejecutar(() => s.estadisticas.actualizar(widget.usuario, editada));
  }

  // DELETE
  Future<void> _borrar(Estadistica e) async {
    final ok = await confirmar(
      context,
      titulo: 'Borrar estadística',
      texto: '¿Seguro que quieres borrar esta fila de estadísticas?',
    );
    if (!ok) return;
    await _ejecutar(
        () => widget.servicios.estadisticas.eliminar(widget.usuario, e.id!));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filas = _filas;

    return Scaffold(
      floatingActionButton: filas == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _crear,
              icon: const Icon(Icons.add),
              label: const Text('Nueva estadística'),
            ),
      body: filas == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: filas.length,
                  itemBuilder: (_, i) {
                    final e = filas[i];
                    final ultima = e.ultimaApertura == null
                        ? '-'
                        : _formato.format(e.ultimaApertura!);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: e.esDeApp
                              ? scheme.tertiaryContainer
                              : Color(e.habitoColor ?? 0xFF9E9E9E),
                          child: Icon(
                            e.esDeApp ? Icons.login_rounded : Icons.local_fire_department,
                            color: e.esDeApp ? scheme.onTertiaryContainer : Colors.white,
                          ),
                        ),
                        title: Text(
                          e.esDeApp
                              ? 'App · @${e.usuarioNombre}'
                              : '${e.habitoNombre} · @${e.usuarioNombre}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          e.esDeApp
                              ? 'Aperturas: ${e.numAperturas}\nÚltima apertura: $ultima'
                              : 'Racha: ${e.rachaActual} días\nTotal completados: ${e.totalCompletados} días',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editar(e),
                            ),
                            IconButton(
                              tooltip: 'Borrar',
                              icon: Icon(Icons.delete_outline, color: scheme.error),
                              onPressed: () => _borrar(e),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
