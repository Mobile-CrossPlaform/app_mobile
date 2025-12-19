import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/position_model.dart';
import '../utils/date_formatter.dart';
import '../viewmodels/positions_viewmodel.dart';
import '../widgets/widgets.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with WidgetsBindingObserver {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchResults = false;
  bool _filtersExpanded = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);

    // Écouter les changements de focus pour afficher/masquer les résultats
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchResults = _searchFocusNode.hasFocus;
      });
    });

    // Initialiser le ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PositionsViewModel>().init();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recharger les données quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      context.read<PositionsViewModel>().loadPositions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PositionsViewModel>(
      builder: (context, viewModel, child) {
        return Stack(
          children: [
            // Carte
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    viewModel.userPosition ?? const LatLng(48.8566, 2.3522),
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev_mobile',
                ),
                // Marqueurs des positions
                MarkerLayer(
                  markers: [
                    // Position de l'utilisateur
                    if (viewModel.userPosition != null)
                      Marker(
                        point: viewModel.userPosition!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    // Positions depuis l'API
                    ...viewModel.positions.map(
                      (position) => Marker(
                        point: LatLng(position.latitude, position.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showPositionDetails(context, position),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Barre de recherche, filtres et résultats
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildSearchBar(viewModel),
                    const SizedBox(height: AppSpacing.sm),
                    // Tag filter UI
                    _buildTagFilters(viewModel),
                    // Liste des résultats de recherche
                    if (_showSearchResults && viewModel.searchQuery.isNotEmpty)
                      _buildSearchResults(viewModel),
                  ],
                ),
              ),
            ),

            // Bouton de rafraîchissement
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'refresh_fab',
                onPressed: viewModel.isLoading
                    ? null
                    : () => viewModel.loadPositions(),
                child: viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
              ),
            ),

            // Bouton de localisation
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'location_fab',
                onPressed: () => _centerOnUser(viewModel),
                child: const Icon(Icons.my_location),
              ),
            ),

            // Indicateur de chargement
            if (viewModel.isLoading)
              const Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(PositionsViewModel viewModel) {
    return SearchBarWidget(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Rechercher une position...',
      onChanged: (value) {
        viewModel.search(value);
        setState(() {
          _showSearchResults = value.isNotEmpty;
        });
      },
      onClear: () {
        viewModel.clearSearch();
        setState(() {
          _showSearchResults = false;
        });
      },
    );
  }

  Widget _buildSearchResults(PositionsViewModel viewModel) {
    final results = viewModel.filteredPositions;

    if (results.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Aucun résultat trouvé',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final position = results[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                child: const Icon(Icons.location_on, color: Colors.red),
              ),
              title: Text(
                position.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                position.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _goToPosition(position),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagFilters(PositionsViewModel viewModel) {
    final tags = viewModel.availableTags;
    final selectedCount = viewModel.selectedTags.length;

    return Card(
      elevation: 4,
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

  void _goToPosition(PositionModel position) {
    // Fermer le clavier et masquer les résultats
    _searchFocusNode.unfocus();
    setState(() {
      _showSearchResults = false;
    });

    // Déplacer la carte vers la position sélectionnée
    final targetPosition = LatLng(position.latitude, position.longitude);
    _mapController.move(targetPosition, MapConfig.focusZoom);

    // Afficher les détails de la position
    Future.delayed(const Duration(milliseconds: 300), () {
      _showPositionDetails(context, position);
    });
  }

  void _centerOnUser(PositionsViewModel viewModel) async {
    await viewModel.getUserLocation();
    if (viewModel.userPosition != null) {
      _mapController.move(viewModel.userPosition!, MapConfig.detailZoom);
    }
  }

  void _showPositionDetails(BuildContext context, PositionModel position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Utiliser le widget PositionImage
                if (position.hasImage)
                  PositionImage(
                    imageUrl: position.fullImageUrl,
                    localImagePath: position.localImagePath,
                    height: AppSizes.detailImageHeight,
                    borderRadius: BorderRadius.circular(
                      AppSizes.cardBorderRadius,
                    ),
                    tags: position.tags,
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  position.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  position.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      DateFormatter.formatDateTime(position.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mapController.move(
                        LatLng(position.latitude, position.longitude),
                        MapConfig.focusZoom,
                      );
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Centrer sur la carte'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
