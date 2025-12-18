import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/position_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/image_service.dart';

class MyPositionsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final ImageService _imageService = ImageService();

  // ID de l'utilisateur courant
  String _currentUserId = '';
  bool _isUsernameSet = false;

  List<PositionModel> _myPositions = [];
  LatLng? _userPosition;
  bool _isLoading = false;
  String? _error;

  // Pour la création/modification d'une position
  File? _selectedImage;
  bool _isSaving = false;

  // Getters
  List<PositionModel> get myPositions => _myPositions;
  LatLng? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedImage => _selectedImage;
  bool get isSaving => _isSaving;

  /// @deprecated Utiliser isSaving à la place
  bool get isCreating => _isSaving;
  String get currentUserId => _currentUserId;
  bool get isUsernameSet => _isUsernameSet;

  // Initialisation
  Future<void> init() async {
    await _loadUsername();
    if (_isUsernameSet) {
      await Future.wait([loadMyPositions(), getUserLocation()]);
    } else {
      await getUserLocation();
    }
  }

  // Charger le nom d'utilisateur depuis les préférences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(StorageKeys.username);
    if (username != null && username.isNotEmpty) {
      _currentUserId = username;
      _isUsernameSet = true;
    } else {
      _isUsernameSet = false;
    }
    notifyListeners();
  }

  // Enregistrer le nom d'utilisateur
  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.username, username);
    _currentUserId = username;
    _isUsernameSet = true;
    notifyListeners();
    // Charger les positions après avoir défini le username
    await loadMyPositions();
  }

  // Charger mes positions
  Future<void> loadMyPositions() async {
    if (!_isUsernameSet) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myPositions = await _apiService.getMyPositions(_currentUserId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtenir la position de l'utilisateur
  Future<void> getUserLocation() async {
    _userPosition = await _locationService.getCurrentPosition();
    notifyListeners();
  }

  // Sélectionner une image depuis la galerie
  Future<void> pickImageFromGallery() async {
    _selectedImage = await _imageService.pickImageFromGallery();
    notifyListeners();
  }

  // Prendre une photo
  Future<void> takePhoto() async {
    _selectedImage = await _imageService.takePhoto();
    notifyListeners();
  }

  // Afficher le dialog de sélection d'image
  Future<void> showImagePicker(BuildContext context) async {
    await showModalBottomSheet<File?>(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await takePhoto();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Supprimer l\'image',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    clearSelectedImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Supprimer l'image sélectionnée
  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Créer une nouvelle position
  Future<bool> createPosition({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final newPosition = PositionModel(
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        authorId: currentUserId,
        createdAt: DateTime.now(),
      );

      final createdPosition = await _apiService.createPosition(
        newPosition,
        _selectedImage,
      );
      _myPositions.insert(0, createdPosition);
      _selectedImage = null;

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Modifier une position existante
  Future<bool> updatePosition({
    required int id,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    String? existingImageUrl,
    String? existingLocalImagePath,
    DateTime? originalCreatedAt,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Récupérer la position originale pour conserver createdAt
      final originalPosition = _myPositions.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Position non trouvée'),
      );

      final updatedPosition = PositionModel(
        id: id,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageUrl: existingImageUrl,
        localImagePath: existingLocalImagePath,
        authorId: _currentUserId,
        createdAt: originalCreatedAt ?? originalPosition.createdAt,
      );

      final result = await _apiService.updatePosition(
        updatedPosition,
        _selectedImage,
      );

      // Mettre à jour la position dans la liste locale
      final index = _myPositions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _myPositions[index] = result;
      }
      _selectedImage = null;

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Supprimer une position
  Future<bool> deletePosition(int id) async {
    try {
      await _apiService.deletePosition(id);
      _myPositions.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
