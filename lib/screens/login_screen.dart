import 'package:flutter/material.dart';

import '../errores.dart';
import '../models/usuario.dart';
import '../services/servicios.dart';
import '../widgets/logo_app.dart';
import 'registro_screen.dart';

// Pantalla de login. Es StatefulWidget porque cambian cosas mientras el usuario
// escribe: el mensaje de error, si se ve la contraseña y si se está comprobando.
class LoginScreen extends StatefulWidget {
  final Servicios servicios;
  // Función que main.dart nos pasa para avisarle de que el login ha ido bien
  final Future<void> Function(Usuario) onAutenticado;

  const LoginScreen({
    super.key,
    required this.servicios,
    required this.onAutenticado,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPassword = false;
  bool _enviando = false;
  String? _error;

  Future<void> _entrar() async {
    final id = _idCtrl.text.trim();
    final pass = _passCtrl.text;
    if (id.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Escribe tu usuario y tu contraseña');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final usuario = await widget.servicios.auth.login(id, pass);
      // main.dart guarda la sesión y cambia a la pantalla principal
      await widget.onAutenticado(usuario);
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroScreen(
          servicios: widget.servicios,
          onAutenticado: widget.onAutenticado,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoApp(),
                  const SizedBox(height: 28),
                  const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pequeños hábitos, grandes cambios.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _idCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Usuario o email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_verPassword,
                    onSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
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
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _entrar,
                      icon: const Icon(Icons.login_rounded),
                      label: Text(_enviando ? 'Entrando...' : 'Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _irARegistro,
                    child: const Text('¿No tienes cuenta? Regístrate'),
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
