import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/position_model.dart';
import '../models/tag_model.dart';
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

  // Tag state
  List<TagModel> _tags = [];
  Set<String> _selectedTags = {};

  // Getters
  List<PositionModel> get positions =>
      _filteredPositions.isEmpty && _searchQuery.isEmpty && _selectedTags.isEmpty
      ? _positions
      : _filteredPositions;
  List<PositionModel> get allPositions => _positions;
  List<PositionModel> get filteredPositions => _filteredPositions;
  LatLng? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get error => _error;
  List<TagModel> get tags => _tags;
  List<TagModel> get tagFilters =>
      _tags.isNotEmpty ? _tags : TagModel.fallbackCategories();
  Set<String> get selectedTags => _selectedTags;

  /// Extracts unique tag values from all positions (for filter chips)
  List<String> get availableTags {
    final tagSet = <String>{};
    for (final position in _positions) {
      if (position.tags != null) {
        tagSet.addAll(position.tags!);
      }
    }
    final sorted = tagSet.toList()..sort();
    return sorted;
  }

  // Initialisation
  Future<void> init() async {
    await Future.wait([loadPositions(), getUserLocation(), loadTags()]);
  }

  // Charger toutes les positions
  Future<void> loadPositions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _positions = await _apiService.getAllPositions();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger tous les tags
  Future<void> loadTags() async {
    try {
      _tags = await _apiService.getAllTags();
      notifyListeners();
    } catch (e) {
      // Silently fail for tags - not critical
      debugPrint('Failed to load tags: $e');
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
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty && _selectedTags.isEmpty) {
      _filteredPositions = [];
      return;
    }

    List<PositionModel> result = _positions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      result = result.where((position) {
        return position.title.toLowerCase().contains(queryLower) ||
            position.description.toLowerCase().contains(queryLower);
      }).toList();
    }

    // Apply tag filter
    if (_selectedTags.isNotEmpty) {
      result = result.where((position) {
        if (position.tags == null || position.tags!.isEmpty) return false;
        // Position must have at least one of the selected tags
        return position.tags!.any((tag) => _selectedTags.contains(tag.toLowerCase()));
      }).toList();
    }

    _filteredPositions = result;
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Tag filtering
  void toggleTag(String tagKey) {
    final key = tagKey.toLowerCase();
    if (_selectedTags.contains(key)) {
      _selectedTags.remove(key);
    } else {
      _selectedTags.add(key);
    }
    _applyFilters();
    notifyListeners();
  }

  void clearTagFilters() {
    _selectedTags.clear();
    _applyFilters();
    notifyListeners();
  }

  bool isTagSelected(String tagKey) {
    return _selectedTags.contains(tagKey.toLowerCase());
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
