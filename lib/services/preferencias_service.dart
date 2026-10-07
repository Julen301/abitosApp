import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abitosapp/models/habito.dart';
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

class PreferenciasService {
  static const double tamanoLetraPorDefecto = 16;
  static const int objetivoPorDefecto = 5;
  //dice esta variable la rellenare mas tarde pero antes de usarla
  //el _ delante la hace privada solo se una dentro de esta clase
  late SharedPreferences _prefs;

  Future<void>init() async{
    //es asincrono tarda un poco en abrir el almacenaminto por eso es future y se espera con await
    _prefs = await SharedPreferences.getInstance();
  }
 //Cada tipo tiene su getX y su setX: getString/setString, getInt/setInt, getBool/setBool.
 //esPrimeraVez es lo contrario de "bienvenida vista", de ahí el !
  bool get esPrimeraVez => !(_prefs.getBool(ClavesPrefs.bienvenidaVista) ?? false);
  String get nombre => _prefs.getString(ClavesPrefs.nombre) ?? '';

  int get objetivoDiario => _prefs.getInt(ClavesPrefs.objetivoDiario) ?? objetivoPorDefecto;
  //guardarBienvenida guarda el nombre, el objetivo y marca que la bienvenida ya se vio. La próxima vez,
  // esPrimeraVez será false y la app irá directa a la principal.
  Future<void> guardarBienvenida(String nombre, int objetivo) async{
    await _prefs.setString(ClavesPrefs.nombre, nombre);
    await _prefs.setInt(ClavesPrefs.objetivoDiario, objetivo);
    await _prefs.setBool(ClavesPrefs.bienvenidaVista, true);
  }

}


