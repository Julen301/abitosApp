import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habito.dart';

// Todas las claves de SharedPreferences en un único sitio (nada de strings sueltos).
class ClavesPrefs {
  static const bienvenidaVista = 'bienvenida_vista'; // bool
  static const nombre = 'nombre_usuario'; // String
  static const objetivoDiario = 'objetivo_diario'; // int
  static const numAperturas = 'num_aperturas'; // int
  static const ultimaApertura = 'ultima_apertura'; // String (ISO 8601)
  static const temaOscuro = 'tema_oscuro'; // bool
  static const ocultarCompletados = 'ocultar_completados'; // bool
  static const tamanoLetra = 'tamano_letra'; // double
  static const habitos = 'habitos'; // List<String> (cada elemento = un JSON)
}

// Capa de servicio: ÚNICO punto de acceso a SharedPreferences.
// Las pantallas nunca usan shared_preferences directamente.
class PreferenciasService {
  static const double tamanoLetraPorDefecto = 16;
  static const int objetivoPorDefecto = 5;

  // dice esta variable la rellenare mas tarde pero antes de usarla
  // el _ delante la hace privada solo se usa dentro de esta clase
  late SharedPreferences _prefs;

  Future<void> init() async {
    // es asincrono tarda un poco en abrir el almacenamiento por eso es future y se espera con await
    _prefs = await SharedPreferences.getInstance();
  }

  // Cada tipo tiene su getX y su setX: getString/setString, getInt/setInt, getBool/setBool.
  // esPrimeraVez es lo contrario de "bienvenida vista", de ahí el !
  // Si la clave no existe (primera ejecución) getBool devuelve null, y con ?? false lo controlamos.
  bool get esPrimeraVez =>
      !(_prefs.getBool(ClavesPrefs.bienvenidaVista) ?? false);

  String get nombre => _prefs.getString(ClavesPrefs.nombre) ?? '';

  int get objetivoDiario =>
      _prefs.getInt(ClavesPrefs.objetivoDiario) ?? objetivoPorDefecto;

  // guardarBienvenida guarda el nombre, el objetivo y marca que la bienvenida ya se vio.
  // La próxima vez, esPrimeraVez será false y la app irá directa a la principal.
  Future<void> guardarBienvenida(String nombre, int objetivo) async {
    await _prefs.setString(ClavesPrefs.nombre, nombre);
    await _prefs.setInt(ClavesPrefs.objetivoDiario, objetivo);
    await _prefs.setBool(ClavesPrefs.bienvenidaVista, true);
  }

  int get numAperturas => _prefs.getInt(ClavesPrefs.numAperturas) ?? 0;

  // La fecha se guarda como String ISO 8601 porque shared_preferences no guarda DateTime.
  // Al leerla la convertimos de nuevo; devuelve null si nunca se ha guardado.
  DateTime? get ultimaApertura {
    final s = _prefs.getString(ClavesPrefs.ultimaApertura);
    return s == null ? null : DateTime.tryParse(s);
  }

  // Suma 1 al contador de aperturas y guarda la fecha y hora de ahora.
  Future<void> registrarApertura() async {
    await _prefs.setInt(ClavesPrefs.numAperturas, numAperturas + 1);
    await _prefs.setString(
        ClavesPrefs.ultimaApertura, DateTime.now().toIso8601String());
  }

  // Ajustes: tema (bool), ocultar completados (bool) y tamaño de letra (double).
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

  // Se lee la List<String>; cada elemento se decodifica con jsonDecode (texto -> Map)
  // y se convierte en Habito con fromJson.
  // Si es null (primera ejecución) devolvemos una lista vacía.
  Future<List<Habito>> cargarHabitos() async {
    final lista = _prefs.getStringList(ClavesPrefs.habitos);
    if (lista == null) return [];
    return lista
        .map((s) => Habito.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // Cada hábito se serializa con jsonEncode (objeto -> Map -> texto)
  // y se guarda la lista de textos con setStringList.
  Future<void> guardarHabitos(List<Habito> habitos) async {
    final lista = habitos.map((h) => jsonEncode(h.toJson())).toList();
    await _prefs.setStringList(ClavesPrefs.habitos, lista);
  }

  // clear() elimina todas las claves, así que esPrimeraVez vuelve a ser true
  // y la app muestra la bienvenida como recién instalada.
  Future<void> borrarTodo() async {
    await _prefs.clear();
  }
}