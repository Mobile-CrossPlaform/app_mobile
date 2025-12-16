import 'package:flutter/material.dart';
import 'core/core.dart';

void main() {
  runApp(const MyApp());
}

/// Version 2: Architecture de Base
/// 
/// Cette version ajoute:
/// - Structure de dossiers MVVM
/// - Constantes centralisées
/// - Exceptions typées
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}
