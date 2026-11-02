import 'auth_service.dart';
import 'estadistica_repository.dart';
import 'habito_repository.dart';
import 'preferencias_service.dart';
import 'usuario_repository.dart';

// Un único objeto con todos los servicios de la app. Se crea en main.dart
// y se pasa a las pantallas, así no hace falta pasarles 5 parámetros sueltos.
class Servicios {
  final PreferenciasService prefs = PreferenciasService();
  final UsuarioRepository usuarios = UsuarioRepository();
  final HabitoRepository habitos = HabitoRepository();
  final EstadisticaRepository estadisticas = EstadisticaRepository();
  late final AuthService auth = AuthService(usuarios);
}
