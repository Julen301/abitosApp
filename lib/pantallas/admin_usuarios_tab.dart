 import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../errores.dart';
import '../modelos/usuario.dart';
import '../servicios/servicios.dart';
import '../widgets/confirmar_dialog.dart';
import '../widgets/usuario_form_dialog.dart';

// Pestaña "Usuarios" del panel de admin: CRUD de la tabla "usuarios".
class AdminUsuariosTab extends StatefulWidget {
  final Servicios servicios;
  final Usuario usuario; // el administrador que usa la app

  const AdminUsuariosTab({
    super.key,
    required this.servicios,
    required this.usuario,
  });

  @override
  State<AdminUsuariosTab> createState() => _AdminUsuariosTabState();
}

class _AdminUsuariosTabState extends State<AdminUsuariosTab> {
  List<Usuario>? _usuarios; // null mientras carga

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // READ
  Future<void> _cargar() async {
    try {
      final lista = await widget.servicios.usuarios.listar(widget.usuario);
      if (!mounted) return;
      setState(() => _usuarios = lista);
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
    final nuevo =
        await mostrarFormularioUsuario(context, auth: widget.servicios.auth);
    if (nuevo == null) return;
    await _ejecutar(
        () => widget.servicios.usuarios.crear(widget.usuario, nuevo));
  }

  // UPDATE
  Future<void> _editar(Usuario u) async {
    final esYo = u.id == widget.usuario.id;
    final editado = await mostrarFormularioUsuario(
      context,
      auth: widget.servicios.auth,
      existente: u,
      esYo: esYo,
    );
    if (editado == null) return;
    await _ejecutar(() async {
      await widget.servicios.usuarios.actualizar(widget.usuario, editado);
      // Si el admin se ha editado a sí mismo, refrescamos sus datos en memoria
      if (esYo) widget.usuario.copiarDe(editado);
    });
  }

  // DELETE
  Future<void> _borrar(Usuario u) async {
    final ok = await confirmar(
      context,
      titulo: 'Borrar usuario',
      texto: '¿Seguro que quieres borrar a "${u.usuario}"? '
          'También se borrarán sus hábitos y sus estadísticas.',
    );
    if (!ok) return;
    await _ejecutar(
        () => widget.servicios.usuarios.eliminar(widget.usuario, u.id!));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lista = _usuarios;
    final formato = DateFormat('dd/MM/yyyy');

    return Scaffold(
      floatingActionButton: lista == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _crear,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Nuevo usuario'),
            ),
      body: lista == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final u = lista[i];
                    final esYo = u.id == widget.usuario.id;
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
                          backgroundColor: u.esAdmin
                              ? scheme.primary
                              : scheme.secondaryContainer,
                          child: Icon(
                            u.esAdmin
                                ? Icons.admin_panel_settings_rounded
                                : Icons.person_rounded,
                            color: u.esAdmin
                                ? scheme.onPrimary
                                : scheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          '${u.nombreCompleto}${esYo ? ' (tú)' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '@${u.usuario} · ${u.esAdmin ? 'Administrador' : 'Usuario'}\n'
                          '${u.email}\n'
                          'Creado el ${formato.format(u.fechaCreacion)}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editar(u),
                            ),
                            // No te puedes borrar a ti mismo
                            IconButton(
                              tooltip: 'Borrar',
                              icon: Icon(Icons.delete_outline,
                                  color: esYo ? null : scheme.error),
                              onPressed: esYo ? null : () => _borrar(u),
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
