import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';

// Pantalla de ajustes: tema, tamaño de letra, ocultar completados y borrar datos.
class AjustesScreen extends StatefulWidget {
  final PreferenciasService service;
  // Avisa a main.dart de que cambió un ajuste para que redibuje la app
  final VoidCallback onAjustesCambiados;
  // Pide a main.dart que borre todo y vuelva a la bienvenida
  final Future<void> Function() onBorrarDatos;

  const AjustesScreen({
    super.key,
    required this.service,
    required this.onAjustesCambiados,
    required this.onBorrarDatos,
  });

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  late bool _oscuro;
  late bool _ocultar;
  late double _tamano;

  @override
  void initState() {
    super.initState();
    // Partimos de los valores guardados
    _oscuro = widget.service.temaOscuro;
    _ocultar = widget.service.ocultarCompletados;
    _tamano = widget.service.tamanoLetra;
  }

  // Pide confirmación y, si el usuario acepta, borra todos los datos
  Future<void> _confirmarBorrado() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar todos los datos'),
        content: const Text(
          'Se eliminarán hábitos, estadísticas y ajustes. '
              'La app quedará como recién instalada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (ok != true) return; // si cancela, no hacemos nada

    // main.dart borra las preferencias y vuelve a cargar (saldrá la bienvenida)
    await widget.onBorrarDatos();
    if (!mounted) return;
    // Cerramos esta pantalla y volvemos a la primera de la pila
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // Interruptor del tema claro/oscuro
          SwitchListTile(
            title: const Text('Tema oscuro'),
            value: _oscuro,
            onChanged: (v) async {
              setState(() => _oscuro = v);
              // PERSISTENCIA: guardamos el bool
              await widget.service.guardarTemaOscuro(v);
              widget.onAjustesCambiados(); // main.dart cambia el tema
            },
          ),

          // Control deslizante del tamaño de letra
          ListTile(
            title: Text('Tamaño de letra: ${_tamano.round()}'),
            subtitle: Slider(
              min: 12,
              max: 24,
              divisions: 12,
              value: _tamano,
              label: _tamano.round().toString(),
              // Mientras se arrastra solo actualizamos el número en pantalla
              onChanged: (v) => setState(() => _tamano = v),
              // Al soltar guardamos el double (así no escribimos en cada movimiento)
              onChangeEnd: (v) async {
                await widget.service.guardarTamanoLetra(v);
                widget.onAjustesCambiados();
              },
            ),
          ),

          // Interruptor para ocultar los hábitos ya hechos hoy
          SwitchListTile(
            title: const Text('Ocultar hábitos completados hoy'),
            value: _ocultar,
            onChanged: (v) async {
              setState(() => _ocultar = v);
              await widget.service.guardarOcultarCompletados(v);
              widget.onAjustesCambiados();
            },
          ),

          const Divider(),

          // Botón rojo para borrar todo
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Borrar datos'),
              onPressed: _confirmarBorrado,
            ),
          ),
        ],
      ),
    );
  }
}