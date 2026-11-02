import 'package:flutter/material.dart';
// intl es un paquete para trabajar con fechas, números e idiomas.
// Aquí solo usamos DateFormat para enseñar la fecha de la última apertura
// de forma legible (dd/MM/yyyy HH:mm) en vez del texto ISO que guardamos.
import 'package:intl/intl.dart';

import '../modelos/estadistica.dart';
import '../modelos/usuario.dart';
import '../servicios/servicios.dart';
import '../widgets/dato_estadistica.dart';

// Pantalla de estadísticas del usuario: lee la tabla "estadisticas"
// (aperturas de la app + racha y total de cada hábito).
class EstadisticasScreen extends StatefulWidget {
  final Servicios servicios;
  final Usuario usuario;

  const EstadisticasScreen({
    super.key,
    required this.servicios,
    required this.usuario,
  });

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  List<Estadistica>? _filas; // null mientras carga

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // Lee de la BD las estadísticas de este usuario
  Future<void> _cargar() async {
    final f = await widget.servicios.estadisticas
        .listar(widget.usuario, deUsuarioId: widget.usuario.id);
    if (!mounted) return;
    setState(() => _filas = f);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: _filas == null
          ? const Center(child: CircularProgressIndicator())
          : _contenido(_filas!),
    );
  }

  // Tarjeta pequeña con icono, valor y etiqueta
  Widget _datoApp(
      {required IconData icono,
      required String valor,
      required String etiqueta,
      required Color color}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _contenido(List<Estadistica> filas) {
    final scheme = Theme.of(context).colorScheme;
    // La fila de la app es la que no tiene hábito; las demás son de hábitos
    final app = filas.where((e) => e.esDeApp).firstOrNull;
    final deHabitos = filas.where((e) => !e.esDeApp).toList();
    // La última apertura puede ser null si nunca se guardó
    final ultima = app?.ultimaApertura;
    final textoUltima =
        ultima == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(ultima);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Dos tarjetas con los datos generales de la app
            Row(
              children: [
                Expanded(
                  child: _datoApp(
                    icono: Icons.login_rounded,
                    valor: '${app?.numAperturas ?? 0}',
                    etiqueta: 'Aperturas de la app',
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datoApp(
                    icono: Icons.schedule_rounded,
                    valor: textoUltima,
                    etiqueta: 'Última apertura',
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Por hábito',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            if (deHabitos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.insights_rounded,
                        size: 64, color: scheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Todavía no hay hábitos.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            // Una tarjeta por hábito con su racha y su total
            for (final e in deHabitos)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.habitoNombre ?? 'Hábito',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      DatoEstadistica(
                        etiqueta: 'Racha actual',
                        valor: '${e.rachaActual} días',
                        icono: Icons.local_fire_department,
                        color: Color(e.habitoColor ?? 0xFF9E9E9E),
                      ),
                      const SizedBox(height: 10),
                      DatoEstadistica(
                        etiqueta: 'Días completados',
                        valor: '${e.totalCompletados} días',
                        icono: Icons.task_alt_rounded,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
