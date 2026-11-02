/// Error "de la app": su mensaje está pensado para enseñarse tal cual al usuario
/// (por ejemplo "Ese usuario ya existe" o "No tienes permiso para hacer esto").
class ErrorApp implements Exception {
  final String mensaje;
  const ErrorApp(this.mensaje);

  @override
  String toString() => mensaje;
}
