import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/servicios.dart';
import 'admin_estadisticas_tab.dart';
import 'admin_usuarios_tab.dart';
import 'gestion_habitos_screen.dart';

// Panel del administrador: una pestaña por tabla de la base de datos.
// Cada pestaña es un CRUD completo (crear, leer, actualizar, borrar).
class AdminScreen extends StatefulWidget {
  final Servicios servicios;
  final Usuario usuario; // el administrador

  const AdminScreen({super.key, required this.servicios, required this.usuario});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _indiceAnterior = 0;
  // Cada vez que cambiamos de pestaña subimos la versión: las pestañas llevan
  // una Key con ese número, así Flutter las vuelve a crear y recargan la BD
  // (por ejemplo, tras borrar un usuario desaparecen sus hábitos de la otra pestaña).
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return; // esperamos a que termine la animación
      if (_tabs.index == _indiceAnterior) return;
      _indiceAnterior = _tabs.index;
      setState(() => _version++);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administrador'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.group_rounded), text: 'Usuarios'),
            Tab(icon: Icon(Icons.checklist_rounded), text: 'Hábitos'),
            Tab(icon: Icon(Icons.insights_rounded), text: 'Estadísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          AdminUsuariosTab(
            key: ValueKey('usuarios$_version'),
            servicios: widget.servicios,
            usuario: widget.usuario,
          ),
          // Reutilizamos la pantalla de hábitos en modo "ver todos"
          GestionHabitosScreen(
            key: ValueKey('habitos$_version'),
            servicios: widget.servicios,
            usuario: widget.usuario,
            verTodos: true,
            conAppBar: false,
          ),
          AdminEstadisticasTab(
            key: ValueKey('estadisticas$_version'),
            servicios: widget.servicios,
            usuario: widget.usuario,
          ),
        ],
      ),
    );
  }
}
