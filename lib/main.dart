import 'package:flutter/material.dart';
import 'services/preferencias_service.dart';
import 'screens/bienvenida_screen.dart';
import 'screens/principal_screen.dart';

void main() {
  runApp(const HabitosApp());
}

class HabitosApp extends StatefulWidget {
  const HabitosApp({super.key});

  @override
  State<HabitosApp> createState() => _HabitosAppState();

}

class _HabitosAppState extends State<HabitosApp>{
  //_service es la unica instancia del servicio se la pasaremos a las pantallas para que todas usen la misma
  final PreferenciasService _service = PreferenciasService();

  //_cargando empieza en true al arrancar todavia no hemos leido nada
  //_primeraVez, _osuro, _tamanoLetra guardan lo leido y cambiarlos redibuja la app
  bool _cargando = true;
  bool _primeraVez = true;
  bool _oscuro = false;
  double _tamanoLetra = PreferenciasService.tamanoLetraPorDefecto;

  //initState se ejecuta una vex añ crearse eñ witjet ahi lanzamos la carga
  //_cargar hace en orden abrir shared_preferences init y suma 1 al contador
  //de apertura y leer los datos cada pasa espera al anterior con await
  @override
  void initState(){
    super.initState();
    _cargar();
  }

  //registrrApertura es un parameto aocional con valor por defecto true
  Future<void> _cargar({bool registrarApertura = true}) async{
    await _service.init();
    if (registrarApertura) await _service.registrarApertura();
    //if !mounted return comprueba queel witjet sigue en pantalla tras la espera
    //si no setstate dria error
    if(!mounted) return;
    //setsate avisa a flutter de que cambaron datos y que redibuje todo lo que
    //cambie el aspecto va dentro y aqui pasmos _cargando a false asi
    //desaparece el indicardo de carga
    setState(() {
      _primeraVez = _service.esPrimeraVez;
      _leerAjustes();
      _cargando = false;
    });
  }

  void _leerAjustes(){
    _oscuro = _service.temaOscuro;
    _tamanoLetra = _service.tamanoLetra;
  }

  //_recargar se llamara desde la pantalla de bienvenida caundo el usuario termine
  //vuelva a leer todo y como bienedia_vista ya esta en true la app pasa a la parincipal
  //no cuanta apertura porque es la misma sescion
  Future<void> _recargar() async{
    setState(() => _cargando = true);
    await _cargar(registrarApertura: false);
  }

  //_borrardatos se llamara desde ajustas borrar todo y vuelva a cargar esPrimeraVez
  //es true otra vez y sale a la bienvenida como recien instalada
  Future<void> _borrarDatos() async{
    await _service.borrarTodo();
    setState(() => _cargando = true);
    await _cargar();
  }

  @override
  Widget build(BuildContext context){
    Widget home;
    if(_cargando){
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    }else if(_primeraVez){
      home = BienvenidaScreen(service: _service, onTerminar: _recargar);
    }else{
      home = PrincipalScreen(
        service: _service,
        onAjustesCambiados: () => setState(_leerAjustes),
        onBorrarDatos: _borrarDatos,
      );
    }
    return MaterialApp(
      title: 'HabitosApp',
      debugShowCheckedModeBanner: false,
      themeMode: _oscuro ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_tamanoLetra / 16)),
        child: child!,
      ),
      home: home,
    );
  }
}



