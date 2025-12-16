/// Constantes globales de l'application
/// 
/// Ce fichier centralise toutes les valeurs constantes pour éviter
/// les "magic numbers" et faciliter la maintenance.
library;

/// Configuration du serveur API
class ApiConfig {
  ApiConfig._();

  /// URL de base pour l'émulateur Android (10.0.2.2 pointe vers localhost)
  static const String baseUrl = 'http://10.0.2.2:3000';

  /// Chemin de l'API
  static const String apiPath = '/api';

  /// URL complète de l'API
  static String get fullApiUrl => '$baseUrl$apiPath';

  /// Timeout des requêtes HTTP en secondes
  static const int timeoutSeconds = 30;
}

/// Constantes d'espacement de l'interface utilisateur
class AppSpacing {
  AppSpacing._();

  /// Espacement extra-petit (4)
  static const double xs = 4.0;

  /// Espacement petit (8)
  static const double sm = 8.0;

  /// Espacement moyen (12)
  static const double md = 12.0;

  /// Espacement normal (16)
  static const double lg = 16.0;

  /// Espacement grand (24)
  static const double xl = 24.0;

  /// Espacement extra-grand (32)
  static const double xxl = 32.0;
}

/// Constantes pour les dimensions des composants
class AppSizes {
  AppSizes._();

  /// Rayon de bordure des cartes
  static const double cardBorderRadius = 12.0;

  /// Rayon de bordure des boutons
  static const double buttonBorderRadius = 8.0;

  /// Hauteur des images dans les cartes
  static const double cardImageHeight = 150.0;

  /// Hauteur des images dans les détails
  static const double detailImageHeight = 200.0;

  /// Hauteur de la mini-carte
  static const double mapSectionHeight = 250.0;

  /// Taille des marqueurs
  static const double markerSize = 40.0;

  /// Taille des icônes dans les marqueurs
  static const double markerIconSize = 24.0;

  /// Hauteur des boutons principaux
  static const double buttonHeight = 50.0;
}

/// Constantes pour la carte
class MapConfig {
  MapConfig._();

  /// Position par défaut (Paris)
  static const double defaultLatitude = 48.8566;
  static const double defaultLongitude = 2.3522;

  /// Zoom par défaut
  static const double defaultZoom = 12.0;

  /// Zoom détaillé
  static const double detailZoom = 15.0;

  /// Zoom focus
  static const double focusZoom = 16.0;

  /// URL des tuiles OpenStreetMap
  static const String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Package name pour les tuiles
  static const String userAgentPackageName = 'dev_mobile';
}

/// Clés pour le stockage local
class StorageKeys {
  StorageKeys._();

  /// Clé pour le nom d'utilisateur
  static const String username = 'username';
}

/// Configuration des images
class ImageConfig {
  ImageConfig._();

  /// Largeur maximale
  static const double maxWidth = 1920;

  /// Hauteur maximale
  static const double maxHeight = 1080;

  /// Qualité de compression
  static const int quality = 85;
}
