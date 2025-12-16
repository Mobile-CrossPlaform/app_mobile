/// Exceptions personnalisées de l'application
///
/// Ces exceptions permettent une gestion d'erreurs typée et structurée,
/// facilitant le debugging et l'affichage de messages utilisateur appropriés.
library;

/// Exception de base pour l'application
/// 
/// Toutes les exceptions personnalisées héritent de cette classe.
abstract class AppException implements Exception {
  /// Message d'erreur descriptif
  final String message;

  /// Erreur originale (pour le debugging)
  final dynamic originalError;

  /// Trace de la pile d'appels
  final StackTrace? stackTrace;

  const AppException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => message;
}

/// Exception réseau
/// 
/// Levée lors de problèmes de connexion (pas d'internet, timeout, etc.)
class NetworkException extends AppException {
  const NetworkException([
    String message = 'Erreur de connexion réseau',
    dynamic error,
    StackTrace? stackTrace,
  ]) : super(message, error, stackTrace);
}

/// Exception API
/// 
/// Levée lors d'erreurs retournées par le serveur (4xx, 5xx)
class ApiException extends AppException {
  /// Code de statut HTTP
  final int? statusCode;

  /// Corps de la réponse d'erreur
  final String? responseBody;

  const ApiException(
    String message, {
    this.statusCode,
    this.responseBody,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);

  @override
  String toString() {
    if (statusCode != null) {
      return '$message (Code: $statusCode)';
    }
    return message;
  }
}

/// Exception de parsing
/// 
/// Levée lors d'erreurs de désérialisation JSON ou de format de données
class ParseException extends AppException {
  /// Données qui ont causé l'erreur
  final dynamic invalidData;

  const ParseException([
    String message = 'Erreur de parsing des données',
    dynamic error,
    StackTrace? stackTrace,
    this.invalidData,
  ]) : super(message, error, stackTrace);
}

/// Exception de localisation
/// 
/// Levée lors de problèmes de géolocalisation (permissions, service désactivé)
class LocationException extends AppException {
  /// Type d'erreur de localisation
  final LocationErrorType? errorType;

  const LocationException([
    String message = 'Erreur de localisation',
    dynamic error,
    StackTrace? stackTrace,
    this.errorType,
  ]) : super(message, error, stackTrace);
}

/// Types d'erreurs de localisation
enum LocationErrorType {
  /// Permission refusée
  permissionDenied,

  /// Permission refusée définitivement
  permissionDeniedForever,

  /// Service de localisation désactivé
  serviceDisabled,

  /// Timeout lors de la récupération de la position
  timeout,

  /// Erreur inconnue
  unknown,
}

/// Exception de validation
/// 
/// Levée lors d'erreurs de validation de formulaire ou de données
class ValidationException extends AppException {
  /// Champ concerné par l'erreur
  final String? field;

  const ValidationException(
    String message, {
    this.field,
    dynamic error,
    StackTrace? stackTrace,
  }) : super(message, error, stackTrace);
}

/// Exception de stockage
/// 
/// Levée lors d'erreurs de lecture/écriture de données locales
class StorageException extends AppException {
  const StorageException([
    String message = 'Erreur de stockage local',
    dynamic error,
    StackTrace? stackTrace,
  ]) : super(message, error, stackTrace);
}
