import 'package:flutter/material.dart';

import '../errores.dart';
import '../modelos/usuario.dart';
import '../servicios/servicios.dart';
import '../widgets/confirmar_dialog.dart';

// Pantalla de ajustes: cuenta, tema, tamaño de letra, objetivo diario,
// ocultar completados y borrado de datos.
// Los ajustes siguen guardándose en SharedPreferences.
class AjustesScreen extends StatefulWidget {
  final Servicios servicios;
  final Usuario usuario;
  // Avisa a main.dart de que cambió un ajuste para que redibuje la app
  final VoidCallback onAjustesCambiados;
  // Pide a main.dart que cierre la sesión (vuelve al login)
  final Future<void> Function() onCerrarSesion;
  // Pide a main.dart que vacíe toda la BD (solo admin) y vuelva al registro
  final Future<void> Function() onBorrarTodo;

  const AjustesScreen({
    super.key,
    required this.servicios,
    required this.usuario,
    required this.onAjustesCambiados,
    required this.onCerrarSesion,
    required this.onBorrarTodo,
  });

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  late bool _oscuro;
  late bool _ocultar;
  late double _tamano;
  late double _objetivo;

  @override
  void initState() {
    super.initState();
    final p = widget.servicios.prefs;
    // Partimos de los valores guardados
    _oscuro = p.temaOscuro;
    _ocultar = p.ocultarCompletados;
    _tamano = p.tamanoLetra;
    _objetivo = p.objetivoDiario(widget.usuario.id!).toDouble();
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cerrarSesion() async {
    await widget.onCerrarSesion();
    if (!mounted) return;
    // Cerramos esta pantalla y volvemos a la primera de la pila
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // Borra los hábitos del usuario (su cuenta se queda)
  Future<void> _borrarMisHabitos() async {
    final ok = await confirmar(
      context,
      titulo: 'Borrar mis hábitos',
      texto: 'Se eliminarán todos tus hábitos y sus estadísticas. '
          'Tu cuenta se conserva.',
      textoBoton: 'Borrar hábitos',
    );
    if (!ok) return;
    try {
      await widget.servicios.habitos
          .borrarDeUsuario(widget.usuario, widget.usuario.id!);
      _aviso('Hábitos eliminados');
    } on ErrorApp catch (e) {
      _aviso(e.mensaje);
    }
  }

  // Solo admin: vacía toda la base de datos
  Future<void> _borrarTodo() async {
    final ok = await confirmar(
      context,
      titulo: 'Borrar toda la base de datos',
      texto: 'Se eliminarán TODOS los usuarios, hábitos y estadísticas, '
          'y los ajustes. La app quedará como recién instalada.',
      textoBoton: 'Borrar todo',
    );
    if (!ok) return;
    // main.dart vacía la BD y las preferencias y vuelve al registro
    await widget.onBorrarTodo();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // Tarjeta redondeada que agrupa varios ajustes
  Widget _tarjeta(List<Widget> hijos) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(children: hijos),
    );
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final u = widget.usuario;
    final p = widget.servicios.prefs;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _titulo('Cuenta'),
              _tarjeta([
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      u.nombre.isEmpty ? '?' : u.nombre[0].toUpperCase(),
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(u.nombreCompleto),
                  subtitle: Text(
                      '@${u.usuario} · ${u.esAdmin ? 'Administrador' : 'Usuario'}\n${u.email}'),
                  isThreeLine: true,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Cerrar sesión'),
                  onTap: _cerrarSesion,
                ),
              ]),
              const SizedBox(height: 24),
              _titulo('Apariencia'),
              _tarjeta([
                // Interruptor del tema claro/oscuro
                SwitchListTile(
                  secondary: Icon(_oscuro
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded),
                  title: const Text('Tema oscuro'),
                  value: _oscuro,
                  onChanged: (v) async {
                    setState(() => _oscuro = v);
                    // PERSISTENCIA: guardamos el bool
                    await p.guardarTemaOscuro(v);
                    widget.onAjustesCambiados(); // main.dart cambia el tema
                  },
                ),
                const Divider(height: 1),
                // Control deslizante del tamaño de letra
                ListTile(
                  leading: const Icon(Icons.text_fields_rounded),
                  title: Text('Tamaño de letra: ${_tamano.round()}'),
                  subtitle: Slider(
                    min: 12,
                    max: 24,
                    divisions: 12,
                    value: _tamano,
                    label: _tamano.round().toString(),
                    // Mientras se arrastra solo actualizamos el número en pantalla
                    onChanged: (v) => setState(() => _tamano = v),
                    // Al soltar guardamos el double (así no escribimos en cada movimiento)
                    onChangeEnd: (v) async {
                      await p.guardarTamanoLetra(v);
                      widget.onAjustesCambiados();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _titulo('Hábitos'),
              _tarjeta([
                // Interruptor para ocultar los hábitos ya hechos hoy
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Ocultar hábitos completados hoy'),
                  value: _ocultar,
                  onChanged: (v) async {
                    setState(() => _ocultar = v);
                    await p.guardarOcultarCompletados(v);
                    widget.onAjustesCambiados();
                  },
                ),
                const Divider(height: 1),
                // Objetivo diario (uno por usuario)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text('Objetivo diario: ${_objetivo.round()} hábitos'),
                  subtitle: Slider(
                    min: 1,
                    max: 20,
                    divisions: 19,
                    value: _objetivo,
                    label: _objetivo.round().toString(),
                    onChanged: (v) => setState(() => _objetivo = v),
                    onChangeEnd: (v) =>
                        p.guardarObjetivoDiario(u.id!, v.round()),
                  ),
                ),
              ]),
              const SizedBox(height: 32),
              // Botones rojos de borrado
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Borrar mis hábitos'),
                  onPressed: _borrarMisHabitos,
                ),
              ),
              if (u.esAdmin) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Borrar toda la base de datos'),
                    onPressed: _borrarTodo,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
