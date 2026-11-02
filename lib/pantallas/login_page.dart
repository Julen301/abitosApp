import 'package:flutter/material.dart';

import '../errores.dart';
import '../modelos/usuario.dart';
import '../servicios/servicios.dart';
import '../widgets/logo_app.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';
import 'registro_page.dart';

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
                  CampoTextoApp(etiqueta: 'Usuario o email', controller: _idCtrl),
                  const SizedBox(height: 16),
                  CampoTextoApp(
                    etiqueta: 'Contraseña',
                    controller: _passCtrl,
                    obscureText: true,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 28),
                  BotonPrincipal(
                    texto: _enviando ? 'Entrando...' : 'Entrar',
                    onPressed: _enviando ? () {} : _entrar,
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
