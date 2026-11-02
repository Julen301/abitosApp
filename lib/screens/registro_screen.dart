import 'package:flutter/material.dart';

import '../errores.dart';
import '../models/usuario.dart';
import '../services/servicios.dart';
import '../widgets/logo_app.dart';

// Pantalla de registro. Sale en dos casos:
//  - primeraVez = true: la BD no tiene ningún usuario (primera vez que se abre
//    la app). Esta cuenta será la de administrador.
//  - primeraVez = false: el usuario pulsó "Regístrate" desde el login.
class RegistroScreen extends StatefulWidget {
  final Servicios servicios;
  final Future<void> Function(Usuario) onAutenticado;
  final bool primeraVez;

  const RegistroScreen({
    super.key,
    required this.servicios,
    required this.onAutenticado,
    this.primeraVez = false,
  });

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _usuarioCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _verPassword = false;
  bool _enviando = false;
  String? _error;

  Future<void> _registrar() async {
    if (_passCtrl.text != _pass2Ctrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final usuario = await widget.servicios.auth.registrar(
        usuario: _usuarioCtrl.text,
        nombre: _nombreCtrl.text,
        apellidos: _apellidosCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      // Guardamos la función antes de cerrar la pantalla
      final avisar = widget.onAutenticado;
      // Si estamos encima del login lo cerramos; si somos la pantalla raíz no hay nada que cerrar
      if (Navigator.canPop(context)) Navigator.pop(context);
      await avisar(usuario);
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Si venimos del login, AppBar con flecha para volver
      appBar: widget.primeraVez ? null : AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.primeraVez) ...[
                    const LogoApp(tamano: 96),
                    const SizedBox(height: 20),
                    const Text(
                      '¡Bienvenido a HabitosApp!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings_rounded,
                              color: scheme.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Es la primera vez que se abre la app: crea tu cuenta. '
                              'Será la de administrador.',
                              style: TextStyle(color: scheme.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  TextField(
                    controller: _usuarioCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _apellidosCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_verPassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Contraseña (mínimo 6 caracteres)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_verPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _verPassword = !_verPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _pass2Ctrl,
                    obscureText: !_verPassword,
                    onSubmitted: (_) => _registrar(),
                    decoration: const InputDecoration(
                      labelText: 'Repite la contraseña',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _registrar,
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: Text(_enviando ? 'Creando cuenta...' : 'Crear cuenta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
