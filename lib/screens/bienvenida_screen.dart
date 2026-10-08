import 'package:flutter/material.dart';

import '../services/preferencias_service.dart';

// Pantalla de bienvenida: solo sale la primera vez.
// Es StatefulWidget porque el texto de error cambia mientras el usuario escribe.
class BienvenidaScreen extends StatefulWidget {
  // El servicio lo recibimos de main.dart para guardar los datos
  final PreferenciasService service;
  // Función que main.dart nos pasa para avisarle de que ya hemos terminado
  final Future<void> Function() onTerminar;

  const BienvenidaScreen({
    super.key,
    required this.service,
    required this.onTerminar,
  });

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  // Los controllers sirven para leer lo que el usuario escribe en cada campo
  final _nombreCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController(text: '5'); // 5 por defecto

  // Si es null no hay error; si tiene texto, se muestra en rojo
  String? _error;

  // Se ejecuta al pulsar el botón "Empezar"
  Future<void> _empezar() async {
    final nombre = _nombreCtrl.text.trim(); // trim quita espacios sobrantes
    // tryParse devuelve null si el texto no es un número válido
    final objetivo = int.tryParse(_objetivoCtrl.text.trim());

    // Validamos: nombre no vacío y objetivo número mayor que 0
    if (nombre.isEmpty || objetivo == null || objetivo < 1) {
      setState(() => _error = 'Escribe tu nombre y un objetivo mayor que 0');
      return; // paramos aquí, no guardamos nada
    }

    // PERSISTENCIA: guardamos nombre, objetivo y marcamos que ya vimos la bienvenida
    await widget.service.guardarBienvenida(nombre, objetivo);

    // Avisamos a main.dart para que cambie a la pantalla principal
    await widget.onTerminar();
  }

  // Liberamos los controllers cuando la pantalla se destruye
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _objetivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // SingleChildScrollView evita errores cuando sale el teclado
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.check_circle_outline, size: 80),
              const SizedBox(height: 16),
              const Text(
                '¡Bienvenido a HabitosApp!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // Campo del nombre
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tu nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo del objetivo, solo acepta teclado numérico
              TextField(
                controller: _objetivoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Objetivo diario de hábitos',
                  border: OutlineInputBorder(),
                ),
              ),

              // Si hay error, lo mostramos en rojo
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _empezar,
                  child: const Text('Empezar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

