import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/core.dart';
import '../models/position_model.dart';
import '../viewmodels/viewmodels.dart';
import '../widgets/widgets.dart';
import '../utils/utils.dart';

/// Liste des positions avec recherche
class PositionsListView extends StatefulWidget {
  const PositionsListView({super.key});

  @override
  State<PositionsListView> createState() => _PositionsListViewState();
}

class _PositionsListViewState extends State<PositionsListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PositionsViewModel>().loadPositions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PositionsViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Rechercher par titre ou utilisateur...',
                onChanged: viewModel.setSearchQuery,
                onClear: () => viewModel.setSearchQuery(''),
                elevated: false,
              ),
            ),

            // Liste ou état
            Expanded(
              child: _buildContent(viewModel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(PositionsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingWidget(message: 'Chargement des positions...');
    }

    if (viewModel.errorMessage != null) {
      return ErrorStateWidget(
        message: viewModel.errorMessage!,
        onRetry: viewModel.loadPositions,
      );
    }

    if (viewModel.filteredPositions.isEmpty) {
      return EmptyStateWidget(
        icon: viewModel.searchQuery.isEmpty ? Icons.location_off : Icons.search_off,
        title: viewModel.searchQuery.isEmpty
            ? 'Aucune position'
            : 'Aucun résultat',
        subtitle: viewModel.searchQuery.isEmpty
            ? 'Les positions apparaîtront ici'
            : 'Essayez une autre recherche',
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadPositions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: viewModel.filteredPositions.length,
        itemBuilder: (context, index) {
          final position = viewModel.filteredPositions[index];
          return _PositionCard(position: position);
        },
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final PositionModel position;

  const _PositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Image
              PositionImage(
                imagePath: position.image,
                width: 70,
                height: 70,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          position.username,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            DateFormatter.smart(position.createdAt),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
                child: PositionImage(
                  imagePath: position.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Titre
              Text(
                position.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Utilisateur
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.username,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        DateFormatter.full(position.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              if (position.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(position.description!),
              ],

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              // Coordonnées
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.location_on),
                ),
                title: const Text('Coordonnées'),
                subtitle: Text(
                  'Lat: ${position.latitude.toStringAsFixed(6)}\n'
                  'Lng: ${position.longitude.toStringAsFixed(6)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
