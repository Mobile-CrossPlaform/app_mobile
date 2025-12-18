import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/core.dart';
import '../models/position_model.dart';
import '../viewmodels/viewmodels.dart';
import '../widgets/widgets.dart';

/// Vue principale de la carte avec les positions
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
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
        return Stack(
          children: [
            // Carte
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(MapConfig.defaultLatitude, MapConfig.defaultLongitude),
                initialZoom: MapConfig.defaultZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.dev_mobile',
                ),
                MarkerLayer(
                  markers: viewModel.filteredPositions.map((position) {
                    return Marker(
                      point: LatLng(position.latitude, position.longitude),
                      width: AppSizes.markerSize,
                      height: AppSizes.markerSize,
                      child: GestureDetector(
                        onTap: () => _showPositionDetails(context, position),
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: AppSizes.markerSize,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Barre de recherche
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: SearchBarWidget(
                controller: _searchController,
                hintText: 'Rechercher une position...',
                onChanged: viewModel.setSearchQuery,
                onClear: () => viewModel.setSearchQuery(''),
              ),
            ),

            // Indicateur de chargement
            if (viewModel.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: LoadingWidget(message: 'Chargement des positions...'),
                ),
              ),

            // Message d'erreur
            if (viewModel.errorMessage != null)
              Positioned(
                bottom: 100,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Card(
                  color: Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(viewModel.errorMessage!)),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: viewModel.loadPositions,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPositionDetails(BuildContext context, PositionModel position) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PositionImage(
                  imagePath: position.image,
                  width: 80,
                  height: 80,
                  borderRadius: AppSizes.cardBorderRadius,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Par ${position.username}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            if (position.description?.isNotEmpty ?? false) ...[
              Text(position.description!),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(
                    LatLng(position.latitude, position.longitude),
                    15,
                  );
                },
                child: const Text('Centrer sur la carte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
