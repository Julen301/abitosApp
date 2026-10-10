import 'package:flutter/material.dart';
// intl es un paquete para trabajar con fechas, números e idiomas.
// Aquí solo usamos DateFormat para enseñar la fecha de la última apertura
// de forma legible (dd/MM/yyyy HH:mm) en vez del texto ISO que guardamos.
import 'package:intl/intl.dart';

import '../models/habito.dart';
import '../services/preferencias_service.dart';

// Pantalla de estadísticas: aperturas de la app y datos de cada hábito.
class EstadisticasScreen extends StatefulWidget {
  final PreferenciasService service;

  const EstadisticasScreen({super.key, required this.service});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  List<Habito>? _habitos; // null mientras carga

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Lee los hábitos guardados en SharedPreferences
  Future<void> _cargar() async {
    final h = await widget.service.cargarHabitos();
    if (!mounted) return;
    setState(() => _habitos = h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: _habitos == null
          ? const Center(child: CircularProgressIndicator())
          : _contenido(_habitos!),
    );
  }

  Widget _contenido(List<Habito> habitos) {
    // La última apertura puede ser null si nunca se guardó
    final ultima = widget.service.ultimaApertura;
    final textoUltima =
    ultima == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(ultima);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta con los datos generales de la app
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Veces que se ha abierto la app'),
                trailing: Text('${widget.service.numAperturas}'),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Última apertura'),
                trailing: Text(textoUltima),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Por hábito',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (habitos.isEmpty) const Text('Todavía no hay hábitos.'),

        // Una tarjeta por hábito con su racha y su total
        for (final h in habitos)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(h.color),
                radius: 12,
              ),
              title: Text(h.nombre),
              subtitle: Text(
                'Racha actual: ${h.rachaActual} días\n'
                    'Total completados: ${h.totalCompletados} días',
              ),
              isThreeLine: true,
            ),
          ),
      ],
    );
  }
}