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
  bool _filtersExpanded = true;

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

            // Filtres par tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildTagFilters(viewModel),
            ),
            const SizedBox(height: AppSpacing.sm),

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
      final hasFilters = viewModel.searchQuery.isNotEmpty || viewModel.selectedTags.isNotEmpty;
      return EmptyStateWidget(
        icon: hasFilters ? Icons.search_off : Icons.location_off,
        title: hasFilters
            ? 'Aucun résultat trouvé'
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

  Widget _buildTagFilters(PositionsViewModel viewModel) {
    final tags = viewModel.availableTags;
    final selectedCount = viewModel.selectedTags.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Filtres',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (selectedCount > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '($selectedCount)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const Spacer(),
                    if (selectedCount > 0)
                      Tooltip(
                        message: 'Effacer les filtres',
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.clear),
                          onPressed: viewModel.clearTagFilters,
                        ),
                      ),
                    Icon(
                      _filtersExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _filtersExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tag in tags) ...[
                          _buildTagChip(viewModel, tag),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(PositionsViewModel viewModel, String tag) {
    final isSelected = viewModel.isTagSelected(tag);
    final count = _countPositionsForTag(viewModel, tag);
    final displayName = _formatTagName(tag);
    final label = count > 0 ? '$displayName · $count' : displayName;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => viewModel.toggleTag(tag),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
            : Colors.grey.withOpacity(0.25),
      ),
    );
  }

  int _countPositionsForTag(PositionsViewModel viewModel, String tag) {
    final key = tag.toLowerCase();
    return viewModel.allPositions.where((p) {
      final tags = p.tags;
      if (tags == null || tags.isEmpty) return false;
      return tags.any((t) => t.toLowerCase() == key);
    }).length;
  }

  /// Formats a tag key like "fine-dining" to "Fine Dining"
  String _formatTagName(String tag) {
    return tag
        .split('-')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
