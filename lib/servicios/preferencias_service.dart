import 'package:shared_preferences/shared_preferences.dart';

// Todas las claves de SharedPreferences en un único sitio (nada de strings sueltos).
// Ahora SharedPreferences solo guarda cosas ligeras del dispositivo:
// la sesión abierta y los ajustes. Los datos (usuarios, hábitos, estadísticas)
// viven en la base de datos SQLite.
class ClavesPrefs {
  static const sesionUsuarioId = 'sesion_usuario_id'; // int
  static const temaOscuro = 'tema_oscuro'; // bool
  static const ocultarCompletados = 'ocultar_completados'; // bool
  static const tamanoLetra = 'tamano_letra'; // double
  static const objetivoPrefijo = 'objetivo_diario_'; // + id del usuario (int)
}

// Capa de servicio: ÚNICO punto de acceso a SharedPreferences.
class PreferenciasService {
  static const double tamanoLetraPorDefecto = 16;
  static const int objetivoPorDefecto = 5;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Sesión: qué usuario tiene la sesión abierta en este dispositivo ----
  int? get usuarioSesion => _prefs.getInt(ClavesPrefs.sesionUsuarioId);

  Future<void> guardarSesion(int usuarioId) =>
      _prefs.setInt(ClavesPrefs.sesionUsuarioId, usuarioId);

  Future<void> cerrarSesion() => _prefs.remove(ClavesPrefs.sesionUsuarioId);

  // ---- Ajustes de la app: tema (bool), ocultar completados (bool), letra (double) ----
  bool get temaOscuro => _prefs.getBool(ClavesPrefs.temaOscuro) ?? false;
  bool get ocultarCompletados =>
      _prefs.getBool(ClavesPrefs.ocultarCompletados) ?? false;
  double get tamanoLetra =>
      _prefs.getDouble(ClavesPrefs.tamanoLetra) ?? tamanoLetraPorDefecto;

  Future<void> guardarTemaOscuro(bool v) =>
      _prefs.setBool(ClavesPrefs.temaOscuro, v);
  Future<void> guardarOcultarCompletados(bool v) =>
      _prefs.setBool(ClavesPrefs.ocultarCompletados, v);
  Future<void> guardarTamanoLetra(double v) =>
      _prefs.setDouble(ClavesPrefs.tamanoLetra, v);

  // ---- Objetivo diario: uno por usuario ----
  int objetivoDiario(int usuarioId) =>
      _prefs.getInt('${ClavesPrefs.objetivoPrefijo}$usuarioId') ??
      objetivoPorDefecto;

  Future<void> guardarObjetivoDiario(int usuarioId, int v) =>
      _prefs.setInt('${ClavesPrefs.objetivoPrefijo}$usuarioId', v);

  // clear() elimina todas las claves (sesión y ajustes)
  Future<void> borrarTodo() async {
    await _prefs.clear();
  }
}
