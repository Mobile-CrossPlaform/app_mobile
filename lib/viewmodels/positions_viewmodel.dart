import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/position_model.dart';
import '../services/services.dart';

/// ViewModel pour la gestion des positions (toutes)
///
/// Ce ViewModel gère:
/// - Le chargement des positions depuis l'API
/// - La recherche/filtrage des positions
/// - La position de l'utilisateur
class PositionsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  // État
  List<PositionModel> _positions = [];
  List<PositionModel> _allPositions = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  LatLng? _userPosition;

  // Getters
  List<PositionModel> get positions => _positions;
  List<PositionModel> get filteredPositions => _positions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  LatLng? get userPosition => _userPosition;
  bool get hasError => _error != null;
  bool get isEmpty => _positions.isEmpty && !_isLoading;

  /// Initialise le ViewModel
  Future<void> init() async {
    await getUserLocation();
    await loadPositions();
  }

  /// Charge toutes les positions
  Future<void> loadPositions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allPositions = await _apiService.getPositions();
      _applySearch();
    } catch (e) {
      _error = e.toString();
      _positions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère la position de l'utilisateur
  Future<void> getUserLocation() async {
    try {
      _userPosition = await _locationService.getCurrentLocation();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur localisation: $e');
      // Ne pas bloquer si la localisation échoue
    }
  }

  /// Effectue une recherche
  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Efface la recherche
  void clearSearch() {
    _searchQuery = '';
    _positions = List.from(_allPositions);
    notifyListeners();
  }

  /// Applique le filtre de recherche
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _positions = List.from(_allPositions);
    } else {
      final query = _searchQuery.toLowerCase();
      _positions = _allPositions.where((p) =>
        p.title.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query) ||
        p.authorId.toLowerCase().contains(query)
      ).toList();
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
