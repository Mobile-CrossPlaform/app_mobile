import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/position_model.dart';
import '../viewmodels/my_positions_viewmodel.dart';
import '../widgets/widgets.dart';
import 'add_position_view.dart';
import 'edit_position_view.dart';

class MyPositionsView extends StatefulWidget {
  const MyPositionsView({super.key});

  @override
  State<MyPositionsView> createState() => _MyPositionsViewState();
}

class _MyPositionsViewState extends State<MyPositionsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<MyPositionsViewModel>();
      await viewModel.init();

      // Demander le nom d'utilisateur si non défini
      if (!viewModel.isUsernameSet && mounted) {
        _showUsernameDialog();
      }
    });
  }

  void _showUsernameDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bienvenue !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Veuillez entrer votre nom d\'utilisateur pour commencer à ajouter vos positions.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                hintText: 'Entrez votre nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final username = controller.text.trim();
              if (username.isNotEmpty) {
                Navigator.pop(context);
                await context.read<MyPositionsViewModel>().setUsername(
                  username,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un nom d\'utilisateur'),
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyPositionsViewModel>(
      builder: (context, viewModel, child) {
        // Si le username n'est pas défini, afficher un message
        if (!viewModel.isUsernameSet) {
          return Scaffold(
            body: EmptyStateWidget(
              icon: Icons.person_outline,
              title: 'Configuration requise',
              subtitle: 'Veuillez définir votre nom d\'utilisateur',
              action: ElevatedButton(
                onPressed: _showUsernameDialog,
                child: const Text('Définir mon nom'),
              ),
            ),
          );
        }

        return Scaffold(
          body: _buildContent(viewModel),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddPosition(context),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Nouvelle position'),
          ),
        );
      },
    );
  }

  Widget _buildContent(MyPositionsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingWidget();
    }

    if (viewModel.error != null) {
      return ErrorStateWidget(
        message: viewModel.error,
        onRetry: viewModel.loadMyPositions,
      );
    }

    if (viewModel.myPositions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.add_location,
        title: 'Vous n\'avez pas encore de positions',
        subtitle: 'Appuyez sur le bouton + pour en ajouter une',
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadMyPositions,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: viewModel.myPositions.length,
        itemBuilder: (context, index) {
          final position = viewModel.myPositions[index];
          return _buildPositionCard(position, viewModel);
        },
      ),
    );
  }

  Widget _buildPositionCard(
    PositionModel position,
    MyPositionsViewModel viewModel,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image - utiliser le widget PositionImage
          PositionImage(
            imageUrl: position.fullImageUrl,
            localImagePath: position.localImagePath,
            height: position.hasImage ? AppSizes.cardImageHeight : 100,
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        position.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () =>
                          _navigateToEditPosition(context, position),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _confirmDelete(context, position, viewModel),
                    ),
                  ],
                ),
                Text(
                  position.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatDate(position.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PositionModel position,
    MyPositionsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la position'),
        content: Text('Voulez-vous vraiment supprimer "${position.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (position.id != null) {
                final success = await viewModel.deletePosition(position.id!);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Position supprimée')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPosition(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPositionView()),
    ).then((_) {
      // Recharger les positions après ajout
      Provider.of<MyPositionsViewModel>(
        context,
        listen: false,
      ).loadMyPositions();
    });
  }

  void _navigateToEditPosition(BuildContext context, PositionModel position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPositionView(position: position),
      ),
    ).then((_) {
      // Recharger les positions après modification
      Provider.of<MyPositionsViewModel>(
        context,
        listen: false,
      ).loadMyPositions();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
