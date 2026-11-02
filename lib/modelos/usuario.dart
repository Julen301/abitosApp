// Modelo Usuario: una fila de la tabla "usuarios".
class Usuario {
  static const String rolAdmin = 'administrador';
  static const String rolUsuario = 'usuario';

  final int? id; // null mientras no esté guardado (lo genera SQLite)
  String usuario;
  String nombre;
  String apellidos;
  String email;
  String contrasena; // NUNCA en claro: "salt$hash" (ver AuthService)
  final DateTime fechaCreacion;
  String rol; // 'administrador' o 'usuario'

  Usuario({
    this.id,
    required this.usuario,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.contrasena,
    DateTime? fechaCreacion,
    this.rol = rolUsuario,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  bool get esAdmin => rol == rolAdmin;

  String get nombreCompleto => '$nombre $apellidos'.trim();

  /// Copia los datos editables de otro usuario (para refrescar al usuario
  /// que tiene la sesión abierta cuando el admin se edita a sí mismo).
  void copiarDe(Usuario o) {
    usuario = o.usuario;
    nombre = o.nombre;
    apellidos = o.apellidos;
    email = o.email;
    contrasena = o.contrasena;
    rol = o.rol;
  }

  // Objeto -> fila de la BD (las columnas no llevan tildes ni ñ)
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'usuario': usuario,
        'nombre': nombre,
        'apellidos': apellidos,
        'email': email,
        'contrasena': contrasena,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'rol': rol,
      };

  // Fila de la BD -> objeto
  factory Usuario.fromMap(Map<String, Object?> m) => Usuario(
        id: m['id'] as int,
        usuario: m['usuario'] as String,
        nombre: m['nombre'] as String,
        apellidos: m['apellidos'] as String,
        email: m['email'] as String,
        contrasena: m['contrasena'] as String,
        fechaCreacion: DateTime.tryParse(m['fecha_creacion'] as String? ?? ''),
        rol: m['rol'] as String,
      );
}
