import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/exceptions.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;

  /// Vérifie et demande les permissions de localisation
  Future<bool> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Permission de localisation refusée');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Permission de localisation désactivée définitivement');
      await Geolocator.openLocationSettings();
      return false;
    }

    return true;
  }

  /// Vérifie si les services de localisation sont activés
  Future<bool> _checkLocationService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Les services de localisation sont désactivés');
    }
    return serviceEnabled;
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<LatLng?> getCurrentPosition() async {
    try {
      if (!await _checkAndRequestPermission()) {
        return null;
      }

      if (!await _checkLocationService()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Erreur de géolocalisation: $e');
      return null;
    }
  }

  /// Obtient la position actuelle ou lance une exception
  Future<LatLng> getCurrentPositionOrThrow() async {
    final position = await getCurrentPosition();
    if (position == null) {
      throw const LocationException('Impossible d\'obtenir la position');
    }
    return position;
  }

  /// Démarre l'écoute des changements de position
  void startListening(
    void Function(LatLng) onPositionChanged, {
    int distanceFilter = 10,
  }) {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: distanceFilter,
          ),
        ).listen(
          (Position position) {
            onPositionChanged(LatLng(position.latitude, position.longitude));
          },
          onError: (error) {
            debugPrint('Erreur du stream de position: $error');
          },
        );
  }

  /// Arrête l'écoute des changements de position
  void stopListening() {
    _positionStream?.cancel();
    _positionStream = null;
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

  void dispose() {
    stopListening();
  }
}
