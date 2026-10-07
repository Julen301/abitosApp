import 'package:flutter/material.dart';
import 'services/preferencias_service.dart';

void main() {
  runApp(const HabitosApp());
}

class HabitosApp extends StatefulWidget {
  const HabitosApp({super.key});

  @override
  State<HabitosApp> createState() => _HabitosAppState();
}