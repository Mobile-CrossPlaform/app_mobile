import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../viewmodels/my_positions_viewmodel.dart';
import '../core/constants.dart';

class AddPositionView extends StatefulWidget {
  const AddPositionView({super.key});

  @override
  State<AddPositionView> createState() => _AddPositionViewState();
}

class _AddPositionViewState extends State<AddPositionView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late MapController _mapController;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<MyPositionsViewModel>();
      await viewModel.getUserLocation();
      if (viewModel.userPosition != null) {
        setState(() {
          _selectedPosition = viewModel.userPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyPositionsViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nouvelle position'),
            actions: [
              if (viewModel.isCreating)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _savePosition(viewModel),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  _buildImageSection(viewModel),
                  const SizedBox(height: AppSpacing.xl),

                  // Titre
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre *',
                      hintText: 'Ex: Tour Eiffel',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Décrivez ce lieu...',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Carte pour sélectionner la position
                  Text(
                    'Position sur la carte *',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Appuyez sur la carte pour définir la position',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildMapSection(viewModel),
                  const SizedBox(height: AppSpacing.sm),

                  // Afficher les coordonnées sélectionnées
                  if (_selectedPosition != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.buttonBorderRadius,
                        ),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Position: ${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.buttonBorderRadius,
                        ),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Veuillez sélectionner une position sur la carte',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // Bouton de sauvegarde
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: viewModel.isCreating
                          ? null
                          : () => _savePosition(viewModel),
                      icon: viewModel.isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        viewModel.isCreating
                            ? 'Enregistrement...'
                            : 'Enregistrer',
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(MyPositionsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo (optionnel)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () => viewModel.showImagePicker(context),
          child: Container(
            height: AppSizes.detailImageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: viewModel.selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius - 2,
                        ),
                        child: Image.file(
                          viewModel.selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: viewModel.clearSelectedImage,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Appuyez pour ajouter une photo',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(MyPositionsViewModel viewModel) {
    final initialCenter =
        _selectedPosition ??
        viewModel.userPosition ??
        const LatLng(MapConfig.defaultLatitude, MapConfig.defaultLongitude);

    return Container(
      height: AppSizes.mapSectionHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: MapConfig.detailZoom - 1,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedPosition = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgentPackageName,
              ),
              MarkerLayer(
                markers: [
                  if (_selectedPosition != null)
                    Marker(
                      point: _selectedPosition!,
                      width: AppSizes.markerSize,
                      height: AppSizes.markerSize,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: AppSizes.markerSize,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Bouton pour centrer sur ma position
          Positioned(
            bottom: AppSpacing.sm,
            right: AppSpacing.sm,
            child: FloatingActionButton.small(
              heroTag: 'center_map',
              onPressed: () async {
                await viewModel.getUserLocation();
                if (viewModel.userPosition != null) {
                  _mapController.move(
                    viewModel.userPosition!,
                    MapConfig.detailZoom,
                  );
                  setState(() {
                    _selectedPosition = viewModel.userPosition;
                  });
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePosition(MyPositionsViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une position sur la carte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await viewModel.createPosition(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.error ?? 'Erreur lors de l\'enregistrement',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
