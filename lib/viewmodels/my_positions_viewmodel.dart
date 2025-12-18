import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
import '../models/position_model.dart';
import '../services/services.dart';

/// ViewModel pour la gestion de mes positions
///
/// Ce ViewModel gère:
/// - Le nom d'utilisateur
/// - Le CRUD des positions de l'utilisateur
/// - La sélection d'images
class MyPositionsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final ImageService _imageService = ImageService();

  // État
  List<PositionModel> _positions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _username;
  File? _selectedImage;
  LatLng? _userPosition;

  // Getters
  List<PositionModel> get positions => _positions;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isCreating => _isSaving; // Alias pour compatibilité
  String? get error => _error;
  String? get username => _username;
  bool get hasUsername => _username != null && _username!.isNotEmpty;
  File? get selectedImage => _selectedImage;
  LatLng? get userPosition => _userPosition;

  /// Charge le nom d'utilisateur depuis les préférences
  Future<void> loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString(StorageKeys.username);
      notifyListeners();

      if (hasUsername) {
        await loadMyPositions();
      }
    } catch (e) {
      debugPrint('Erreur chargement username: $e');
    }
  }

  /// Sauvegarde le nom d'utilisateur
  Future<void> saveUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.username, username);
      _username = username;
      notifyListeners();
      await loadMyPositions();
    } catch (e) {
      _error = 'Erreur lors de la sauvegarde du nom';
      notifyListeners();
    }
  }

  /// Charge mes positions
  Future<void> loadMyPositions() async {
    if (!hasUsername) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _positions = await _apiService.getMyPositions(_username!);
    } catch (e) {
      _error = e.toString();
      _positions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une nouvelle position
  Future<bool> createPosition({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    if (!hasUsername) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final position = PositionModel(
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        authorId: _username!,
        createdAt: DateTime.now(),
      );

      await _apiService.createPosition(position, imageFile: _selectedImage);
      _selectedImage = null;
      await loadMyPositions();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Met à jour une position
  Future<bool> updatePosition({
    required String id,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    String? existingImageUrl,
    String? existingLocalImagePath,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Trouver la position existante pour préserver createdAt
      final existingPosition = _positions.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Position non trouvée'),
      );

      final position = PositionModel(
        id: id,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageUrl: existingImageUrl,
        localImagePath: existingLocalImagePath,
        authorId: _username!,
        createdAt: existingPosition.createdAt, // Préserver la date de création
        updatedAt: DateTime.now(),
      );

      await _apiService.updatePosition(position, imageFile: _selectedImage);
      _selectedImage = null;
      await loadMyPositions();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Supprime une position
  Future<bool> deletePosition(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deletePosition(id);
      await loadMyPositions();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Affiche le dialogue de sélection d'image
  Future<void> showImagePicker(BuildContext context) async {
    final file = await _imageService.showImageSourceDialog(context);
    if (file != null) {
      _selectedImage = file;
      notifyListeners();
    }
  }

  /// Efface l'image sélectionnée
  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  /// Récupère la position GPS de l'utilisateur
  Future<void> getUserLocation() async {
    try {
      _userPosition = await _locationService.getCurrentLocation();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur localisation: $e');
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
