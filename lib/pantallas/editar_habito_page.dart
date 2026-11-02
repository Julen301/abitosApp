import 'package:flutter/material.dart';

import '../errores.dart';
import '../modelos/habito.dart';
import '../modelos/usuario.dart';
import '../servicios/servicios.dart';
import '../widgets/confirmar_dialog.dart';
import '../widgets/habito_form_dialog.dart';
import '../widgets/tarjeta_habito.dart';

// Pantalla para crear, editar y borrar hábitos (CRUD de la tabla "habitos").
//  - Usuario normal: solo ve y gestiona SUS hábitos.
//  - Administrador con [verTodos] = true (lo usa el panel de admin): ve los hábitos
//    de todos los usuarios y puede crearlos para cualquiera.
//  - [conAppBar] = false cuando se usa dentro de una pestaña del panel de admin.
class GestionHabitosScreen extends StatefulWidget {
  final Servicios servicios;
  final Usuario usuario; // quien tiene la sesión abierta
  final bool verTodos;
  final bool conAppBar;

  const GestionHabitosScreen({
    super.key,
    required this.servicios,
    required this.usuario,
    this.verTodos = false,
    this.conAppBar = true,
  });

  @override
  State<GestionHabitosScreen> createState() => _GestionHabitosScreenState();
}

class _GestionHabitosScreenState extends State<GestionHabitosScreen> {
  List<Habito>? _habitos; // null mientras carga
  List<Usuario> _usuarios = []; // solo se rellena en modo "ver todos"

  bool get _modoAdmin => widget.verTodos && widget.usuario.esAdmin;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // READ: lee los hábitos de la base de datos
  Future<void> _cargar() async {
    final s = widget.servicios;
    final habitos = await s.habitos.listar(
      widget.usuario,
      deUsuarioId: _modoAdmin ? null : widget.usuario.id,
    );
    final usuarios = _modoAdmin ? await s.usuarios.listar(widget.usuario) : <Usuario>[];
    if (!mounted) return;
    setState(() {
      _habitos = habitos;
      _usuarios = usuarios;
    });
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // Ejecuta una operación de la BD, enseña el error si lo hay y recarga la lista
  Future<void> _ejecutar(Future<void> Function() accion) async {
    try {
      await accion();
      await _cargar();
    } on ErrorApp catch (e) {
      _aviso(e.mensaje);
    }
  }

  // CREATE: abrimos el formulario vacío y, si devuelve un hábito, lo insertamos
  Future<void> _crear() async {
    final nuevo = await mostrarFormularioHabito(
      context,
      usuarioIdPorDefecto: widget.usuario.id!,
      usuarios: _modoAdmin ? _usuarios : null,
    );
    if (nuevo == null) return; // el usuario canceló
    await _ejecutar(() => widget.servicios.habitos.crear(widget.usuario, nuevo));
  }

  // UPDATE: abrimos el formulario con los datos del hábito
  Future<void> _editar(Habito h) async {
    final editado = await mostrarFormularioHabito(
      context,
      existente: h,
      usuarioIdPorDefecto: h.usuarioId,
      usuarios: _modoAdmin ? _usuarios : null,
    );
    if (editado == null) return;
    await _ejecutar(
        () => widget.servicios.habitos.actualizar(widget.usuario, editado));
  }

  // DELETE: pedimos confirmación antes de eliminar
  Future<void> _borrar(Habito h) async {
    final ok = await confirmar(
      context,
      titulo: 'Borrar hábito',
      texto: '¿Seguro que quieres borrar "${h.nombre}"? '
          'También se borrarán sus estadísticas.',
    );
    if (!ok) return; // si no confirma, no hacemos nada
    await _ejecutar(() => widget.servicios.habitos.eliminar(widget.usuario, h));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final habitos = _habitos;

    return Scaffold(
      appBar: widget.conAppBar ? AppBar(title: const Text('Gestionar hábitos')) : null,
      // El botón solo aparece cuando ya han cargado los datos
      floatingActionButton: habitos == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _crear,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo hábito'),
            ),
      body: habitos == null
          ? const Center(child: CircularProgressIndicator())
          : habitos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.playlist_add_rounded,
                          size: 80, color: scheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No hay hábitos. Pulsa "Nuevo hábito" para crear uno.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: habitos.length,
                      itemBuilder: (_, i) {
                        final h = habitos[i];
                        return TarjetaHabito(
                          nombre: _modoAdmin
                              ? '${h.nombre} · ${h.propietario ?? h.usuarioId}'
                              : h.nombre,
                          color: Color(h.color),
                          completadoHoy: h.completadoHoy,
                          onCompletar: () => _ejecutar(
                            () => widget.servicios.habitos.alternarHoy(widget.usuario, h),
                          ),
                          onEditar: () => _editar(h),
                          onEliminar: () => _borrar(h),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}
