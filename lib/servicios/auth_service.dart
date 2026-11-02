import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../errores.dart';
import '../modelos/usuario.dart';
import 'usuario_repository.dart';

// Registro, login y contraseñas.
// La contraseña NUNCA se guarda en claro: se guarda "salt$hash", donde
//  - salt = texto aleatorio distinto para cada usuario
//  - hash = SHA-256 de "salt:contraseña"
class AuthService {
  final UsuarioRepository _usuarios;

  AuthService(this._usuarios);

  static final RegExp _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // ---------- Contraseñas ----------

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _nuevoSalt() {
    final azar = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => azar.nextInt(256)));
  }

  /// Convierte una contraseña en el texto que se guarda en la BD.
  String cifrar(String password) {
    final salt = _nuevoSalt();
    return '$salt\$${_hash(password, salt)}';
  }

  bool _verificar(String password, String guardada) {
    final partes = guardada.split('\$');
    if (partes.length != 2) return false;
    return _hash(password, partes[0]) == partes[1];
  }

  // ---------- Validaciones (también las usa el formulario del admin) ----------

  static void validarDatos({
    required String usuario,
    required String nombre,
    required String apellidos,
    required String email,
  }) {
    if (usuario.trim().length < 3) {
      throw const ErrorApp('El usuario debe tener al menos 3 caracteres');
    }
    if (usuario.contains(RegExp(r'\s'))) {
      throw const ErrorApp('El usuario no puede tener espacios');
    }
    if (nombre.trim().isEmpty) throw const ErrorApp('Escribe el nombre');
    if (apellidos.trim().isEmpty) throw const ErrorApp('Escribe los apellidos');
    if (!_regexEmail.hasMatch(email.trim())) {
      throw const ErrorApp('El email no es válido');
    }
  }

  static void validarPassword(String password) {
    if (password.length < 6) {
      throw const ErrorApp('La contraseña debe tener al menos 6 caracteres');
    }
  }

  // ---------- Registro y login ----------

  /// Crea una cuenta nueva. El PRIMER usuario que se registra en la app
  /// es administrador; los siguientes son usuarios normales
  /// (el admin puede cambiar roles desde su panel).
  Future<Usuario> registrar({
    required String usuario,
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
  }) async {
    validarDatos(
        usuario: usuario, nombre: nombre, apellidos: apellidos, email: email);
    validarPassword(password);

    final esPrimero = await _usuarios.contar() == 0;
    final nuevo = Usuario(
      usuario: usuario.trim(),
      nombre: nombre.trim(),
      apellidos: apellidos.trim(),
      email: email.trim(),
      contrasena: cifrar(password),
      rol: esPrimero ? Usuario.rolAdmin : Usuario.rolUsuario,
    );
    final id = await _usuarios.insertar(nuevo);
    return (await _usuarios.porId(id))!;
  }

  /// [identificador] puede ser el nombre de usuario o el email.
  Future<Usuario> login(String identificador, String password) async {
    final u = await _usuarios.porUsuarioOEmail(identificador);
    if (u == null || !_verificar(password, u.contrasena)) {
      // Mismo mensaje en los dos casos para no revelar qué usuarios existen
      throw const ErrorApp('Usuario o contraseña incorrectos');
    }
    return u;
  }
}
