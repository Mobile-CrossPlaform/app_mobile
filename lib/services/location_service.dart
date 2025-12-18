import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/core.dart';

/// Service de géolocalisation
///
/// Ce service gère la récupération de la position GPS de l'utilisateur
/// et la gestion des permissions associées.
class LocationService {
  // Singleton
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Récupère la position actuelle de l'utilisateur
  ///
  /// Gère automatiquement les demandes de permissions.
  /// Retourne null si la position ne peut pas être obtenue.
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const LocationException(
            'Permission de localisation refusée',
            null,
            null,
            LocationErrorType.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Ouvrir les paramètres pour que l'utilisateur puisse activer la permission
        await Geolocator.openLocationSettings();
        throw const LocationException(
          'Permission de localisation désactivée définitivement. '
          'Veuillez l\'activer dans les paramètres.',
          null,
          null,
          LocationErrorType.permissionDeniedForever,
        );
      }

      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationException(
          'Les services de localisation sont désactivés',
          null,
          null,
          LocationErrorType.serviceDisabled,
        );
      }

      // Récupérer la position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException(
        'Erreur lors de la récupération de la position',
        e,
        null,
        LocationErrorType.unknown,
      );
    }
  }

  /// Vérifie si la localisation est disponible
  Future<bool> isLocationAvailable() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      return serviceEnabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse);
    } catch (e) {
      return false;
    }
  }

  /// Calcule la distance entre deux points en mètres
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}
