import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/core.dart';
import '../models/position_model.dart';
import '../viewmodels/viewmodels.dart';
import '../widgets/widgets.dart';
import '../utils/utils.dart';
import 'add_position_view.dart';
import 'edit_position_view.dart';

/// Vue des positions de l'utilisateur avec CRUD
class MyPositionsView extends StatefulWidget {
  const MyPositionsView({super.key});

  @override
  State<MyPositionsView> createState() => _MyPositionsViewState();
}

class _MyPositionsViewState extends State<MyPositionsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyPositionsViewModel>().loadMyPositions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyPositionsViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          children: [
            // En-tête utilisateur
            _buildUserHeader(viewModel),

            // Liste ou état
            Expanded(
              child: _buildContent(viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserHeader(MyPositionsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              viewModel.username.isNotEmpty ? viewModel.username[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.username.isEmpty ? 'Utilisateur' : viewModel.username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${viewModel.myPositions.length} position(s)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditUsernameDialog(viewModel),
            tooltip: 'Modifier le nom',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MyPositionsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingWidget(message: 'Chargement de vos positions...');
    }

    if (viewModel.errorMessage != null) {
      return ErrorStateWidget(
        message: viewModel.errorMessage!,
        onRetry: viewModel.loadMyPositions,
      );
    }

    if (viewModel.myPositions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.add_location_alt,
        title: 'Aucune position',
        subtitle: 'Ajoutez votre première position avec le bouton +',
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadMyPositions,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: viewModel.myPositions.length,
        itemBuilder: (context, index) {
          final position = viewModel.myPositions[index];
          return _MyPositionCard(
            position: position,
            onEdit: () => _navigateToEdit(position),
            onDelete: () => _confirmDelete(viewModel, position),
          );
        },
      ),
    );
  }

  void _showEditUsernameDialog(MyPositionsViewModel viewModel) {
    final controller = TextEditingController(text: viewModel.username);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom d\'utilisateur',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.setUsername(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(PositionModel position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPositionView(position: position),
      ),
    );
  }

  void _confirmDelete(MyPositionsViewModel viewModel, PositionModel position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Voulez-vous supprimer "${position.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              viewModel.deletePosition(position.id!);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MyPositionCard extends StatelessWidget {
  final PositionModel position;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyPositionCard({
    required this.position,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Image
            PositionImage(
              imagePath: position.image,
              width: 60,
              height: 60,
              borderRadius: AppSizes.cardBorderRadius,
            ),
            const SizedBox(width: AppSpacing.md),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    DateFormatter.smart(position.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Actions
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
