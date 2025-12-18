import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// ViewModel pour la vérification de la connexion au serveur au démarrage
class AppBootstrapViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isChecking = false;
  bool _hasConnection = false;
  String? _lastErrorMessage;

  // Getters
  bool get isChecking => _isChecking;
  bool get hasConnection => _hasConnection;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Vérifie si le serveur est accessible
  /// Retourne true si la connexion est établie, false sinon
  Future<bool> checkServer() async {
    _isChecking = true;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      // Tenter de récupérer les positions pour vérifier la connexion
      await _apiService.getAllPositions();
      _hasConnection = true;
      return true;
    } catch (e) {
      _hasConnection = false;
      _lastErrorMessage = 'Impossible de se connecter au serveur';
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }
}

