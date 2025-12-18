import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/position_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class PositionsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  List<PositionModel> _positions = [];
  List<PositionModel> _filteredPositions = [];
  LatLng? _userPosition;
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;

  // Getters
  List<PositionModel> get positions =>
      _filteredPositions.isEmpty && _searchQuery.isEmpty
      ? _positions
      : _filteredPositions;
  List<PositionModel> get allPositions => _positions;
  List<PositionModel> get filteredPositions => _filteredPositions;
  LatLng? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get error => _error;

  // Initialisation
  Future<void> init() async {
    await Future.wait([loadPositions(), getUserLocation()]);
  }

  // Charger toutes les positions
  Future<void> loadPositions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _positions = await _apiService.getAllPositions();
      _applySearch();
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

  // Recherche
  void search(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredPositions = [];
    } else {
      final queryLower = _searchQuery.toLowerCase();
      _filteredPositions = _positions.where((position) {
        return position.title.toLowerCase().contains(queryLower) ||
            position.description.toLowerCase().contains(queryLower);
      }).toList();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredPositions = [];
    notifyListeners();
  }

  // Centrer sur une position
  PositionModel? getPositionById(int id) {
    try {
      return _positions.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
