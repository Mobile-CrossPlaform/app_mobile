import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/loading_screen_view.dart';
import 'views/map_view.dart';
import 'views/positions_list_view.dart';
import 'views/my_positions_view.dart';
import 'viewmodels/app_bootstrap_viewmodel.dart';
import 'viewmodels/positions_viewmodel.dart';
import 'viewmodels/my_positions_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppBootstrapViewModel()),
        ChangeNotifierProvider(create: (_) => PositionsViewModel()),
        ChangeNotifierProvider(create: (_) => MyPositionsViewModel()),
      ],
      child: MaterialApp(
        title: 'Positions Map',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoadingScreenView(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _pages = [
    const MapView(),
    const PositionsListView(),
    const MyPositionsView(),
  ];

  final List<String> _titles = ['Carte', 'Positions', 'Mes Positions'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex != 0
          ? AppBar(
              title: Text(_titles[_currentIndex]),
              centerTitle: true,
              elevation: 0,
            )
          : null,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _previousIndex = _currentIndex;
          setState(() {
            _currentIndex = index;
          });

          // Recharger les données quand on revient sur la carte
          if (index == 0 && _previousIndex != 0) {
            context.read<PositionsViewModel>().loadPositions();
          }
          // Recharger les données quand on revient sur la liste
          if (index == 1 && _previousIndex != 1) {
            context.read<PositionsViewModel>().loadPositions();
          }
          // Recharger mes positions quand on revient sur l'onglet
          if (index == 2 && _previousIndex != 2) {
            context.read<MyPositionsViewModel>().loadMyPositions();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Liste',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Mes positions',
          ),
        ],
      ),
    );
  }
}
