import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/position_model.dart';
import '../viewmodels/positions_viewmodel.dart';
import '../widgets/widgets.dart';

class PositionsListView extends StatefulWidget {
  final Function(PositionModel)? onPositionTap;

  const PositionsListView({super.key, this.onPositionTap});

  @override
  State<PositionsListView> createState() => _PositionsListViewState();
}

class _PositionsListViewState extends State<PositionsListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PositionsViewModel>().init();
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
      builder: (context, viewModel, child) {
        return Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Rechercher une position...',
                elevated: false,
                onChanged: viewModel.search,
                onClear: viewModel.clearSearch,
              ),
            ),

            // Contenu
            Expanded(child: _buildContent(viewModel)),
          ],
        );
      },
    );
  }

  Widget _buildContent(PositionsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingWidget();
    }

    if (viewModel.error != null) {
      return ErrorStateWidget(
        message: viewModel.error,
        onRetry: viewModel.loadPositions,
      );
    }

    final positions = viewModel.positions;

    if (positions.isEmpty) {
      return EmptyStateWidget(
        icon: viewModel.searchQuery.isNotEmpty
            ? Icons.search_off
            : Icons.location_off,
        title: viewModel.searchQuery.isNotEmpty
            ? 'Aucun résultat pour "${viewModel.searchQuery}"'
            : 'Aucune position disponible',
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadPositions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final position = positions[index];
          return _buildPositionCard(position);
        },
      ),
    );
  }

  Widget _buildPositionCard(PositionModel position) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onPositionTap?.call(position),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - Utiliser le widget PositionImage
            PositionImage(
              imageUrl: position.fullImageUrl,
              localImagePath: position.localImagePath,
              height: position.hasImage ? AppSizes.cardImageHeight : 100,
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    position.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
