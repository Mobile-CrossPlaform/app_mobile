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
    super.message = 'Erreur de connexion réseau',
    super.error,
  ]);
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
    super.message = 'Erreur de format des données',
    super.error,
  ]);
}

/// Exception liée à la localisation
class LocationException extends AppException {
  const LocationException([
    super.message = 'Erreur de géolocalisation',
    super.error,
  ]);
}

/// Exception liée aux permissions
class PermissionException extends AppException {
  const PermissionException([
    super.message = 'Permission refusée',
    super.error,
  ]);
}

/// Exception de validation
class ValidationException extends AppException {
  const ValidationException(super.message);
}
