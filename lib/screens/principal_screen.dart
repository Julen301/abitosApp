import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../services/preferencias_service.dart';
import '../widgets/habito_tile.dart';
import 'ajustes_screen.dart';
import 'estadisticas_screen.dart';
import 'gestion_habitos_screen.dart';

// Pantalla principal: saluda, muestra el progreso del día y la lista de hábitos.
class PrincipalScreen extends StatefulWidget {
  final PreferenciasService service;
  // Estas dos funciones se las pasamos a Ajustes
  final VoidCallback onAjustesCambiados;
  final Future<void> Function() onBorrarDatos;

  const PrincipalScreen({
    super.key,
    required this.service,
    required this.onAjustesCambiados,
    required this.onBorrarDatos,
  });

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  // Es null mientras se cargan los datos; así sabemos cuándo enseñar la rueda de carga
  List<Habito>? _habitos;
  bool _ocultar = false; // ajuste de ocultar los completados

  // initState se ejecuta una vez al abrir la pantalla
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Lee los hábitos y el ajuste desde SharedPreferences
  Future<void> _cargar() async {
    final habitos = await widget.service.cargarHabitos();
    // Si la pantalla ya no existe tras esperar, no hacemos nada
    if (!mounted) return;
    setState(() {
      _habitos = habitos;
      _ocultar = widget.service.ocultarCompletados;
    });
  }

  // Marca o desmarca un hábito y lo guarda al momento
  Future<void> _alternar(Habito h) async {
    h.alternarHoy();
    // PERSISTENCIA: guardamos la lista entera con los cambios
    await widget.service.guardarHabitos(_habitos!);
    if (!mounted) return;
    setState(() {}); // redibuja la pantalla
  }

  // Abre otra pantalla y, al volver, recarga los datos por si han cambiado
  Future<void> _ir(Widget pantalla) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitosApp'),
        actions: [
          // Botón para gestionar hábitos
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () => _ir(GestionHabitosScreen(service: widget.service)),
          ),
          // Botón de estadísticas
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _ir(EstadisticasScreen(service: widget.service)),
          ),
          // Botón de ajustes
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _ir(AjustesScreen(
              service: widget.service,
              onAjustesCambiados: widget.onAjustesCambiados,
              onBorrarDatos: widget.onBorrarDatos,
            )),
          ),
        ],
      ),
      // Si todavía no hay datos, mostramos el indicador de carga
      body: _habitos == null
          ? const Center(child: CircularProgressIndicator())
          : _contenido(_habitos!),
    );
  }

  // Parte de la pantalla cuando los datos ya están cargados
  Widget _contenido(List<Habito> habitos) {
    final objetivo = widget.service.objetivoDiario;
    // Contamos cuántos hábitos están hechos hoy
    final hechos = habitos.where((h) => h.completadoHoy).length;
    // Si el ajuste está activado, quitamos de la lista los ya hechos
    final visibles =
    _ocultar ? habitos.where((h) => !h.completadoHoy).toList() : habitos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Hola, ${widget.service.nombre} 👋',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Progreso del día, por ejemplo "2 de 5 hábitos"
        Text('$hechos de $objetivo hábitos'),
        const SizedBox(height: 8),
        // La barra va de 0 a 1; con clamp evitamos pasarnos de 1
        LinearProgressIndicator(
          value: (hechos / objetivo).clamp(0.0, 1.0).toDouble(),
          minHeight: 8,
        ),
        const SizedBox(height: 16),

        // Mensaje si no hay nada que mostrar
        if (visibles.isEmpty)
          Text(
            habitos.isEmpty
                ? 'Aún no tienes hábitos. Crea uno con el icono de arriba.'
                : '¡Todo hecho por hoy! 🎉',
            textAlign: TextAlign.center,
          ),

        // Un HabitoTile por cada hábito visible
        for (final h in visibles)
          HabitoTile(habito: h, onChanged: (_) => _alternar(h)),
      ],
    );
  }
}