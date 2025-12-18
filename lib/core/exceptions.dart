/// Exceptions personnalisées de l'application
library;

/// Exception de base de l'application
sealed class AppException implements Exception {
  final String message;
  final dynamic originalError;

  const AppException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Exception liée au réseau
class NetworkException extends AppException {
  const NetworkException([
    String message = 'Erreur de connexion réseau',
    dynamic error,
  ]) : super(message, error);
}

/// Exception liée à l'API
class ApiException extends AppException {
  final int? statusCode;

  const ApiException(String message, {this.statusCode, dynamic originalError})
    : super(message, originalError);

  factory ApiException.fromStatusCode(int statusCode) {
    final message = switch (statusCode) {
      400 => 'Requête invalide',
      401 => 'Non autorisé',
      403 => 'Accès refusé',
      404 => 'Ressource non trouvée',
      500 => 'Erreur serveur interne',
      502 => 'Passerelle incorrecte',
      503 => 'Service temporairement indisponible',
      _ => 'Erreur serveur ($statusCode)',
    };
    return ApiException(message, statusCode: statusCode);
  }
}

/// Exception liée au parsing des données
class ParseException extends AppException {
  const ParseException([
    String message = 'Erreur de format des données',
    dynamic error,
  ]) : super(message, error);
}

/// Exception liée à la localisation
class LocationException extends AppException {
  const LocationException([
    String message = 'Erreur de géolocalisation',
    dynamic error,
  ]) : super(message, error);
}

/// Exception liée aux permissions
class PermissionException extends AppException {
  const PermissionException([
    String message = 'Permission refusée',
    dynamic error,
  ]) : super(message, error);
}

/// Exception de validation
class ValidationException extends AppException {
  const ValidationException(super.message);
}
