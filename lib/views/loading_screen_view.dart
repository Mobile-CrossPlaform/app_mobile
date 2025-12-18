import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../main.dart';
import '../viewmodels/app_bootstrap_viewmodel.dart';

class LoadingScreenView extends StatefulWidget {
  const LoadingScreenView({super.key});

  @override
  State<LoadingScreenView> createState() => _LoadingScreenViewState();
}

class _LoadingScreenViewState extends State<LoadingScreenView> {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    final viewModel = context.read<AppBootstrapViewModel>();
    final success = await viewModel.checkServer();

    if (!mounted) return;

    if (success) {
      _navigateToMainScreen();
    } else {
      _showConnectionErrorDialog();
    }
  }

  void _navigateToMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _showConnectionErrorDialog() {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.wifi_off,
          size: 48,
          color: Colors.orange,
        ),
        title: const Text('Problème de connexion'),
        content: const Text(
          'Impossible de se connecter au serveur.\n\n'
          'Vérifiez votre connexion internet ou que le serveur est bien démarré.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dialogOpen = false;
              _navigateToMainScreen();
            },
            child: const Text('Continuer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _dialogOpen = false;
              _checkConnection();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ).then((_) {
      _dialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppBootstrapViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône de l'application
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Nom de l'application
                Text(
                  'Positions Map',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Sous-titre
                Text(
                  'Découvrez et partagez vos lieux favoris',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Indicateur de chargement
                if (viewModel.isChecking) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Connexion au serveur...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

