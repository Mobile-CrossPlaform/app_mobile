import '../core/constants.dart';

/// Modèle représentant une position géographique
///
/// Ce modèle contient toutes les informations d'un lieu enregistré:
/// - Identifiant unique
/// - Titre et description
/// - Coordonnées GPS (latitude, longitude)
/// - Image (URL distante ou chemin local)
/// - Auteur et dates de création/modification
class PositionModel {
  /// Identifiant unique de la position
  final String? id;

  /// Titre/nom de la position
  final String title;

  /// Description détaillée du lieu
  final String description;

  /// Latitude GPS
  final double latitude;

  /// Longitude GPS
  final double longitude;

  /// URL de l'image sur le serveur
  final String? imageUrl;

  /// Chemin local de l'image (pour le mode hors ligne)
  final String? localImagePath;

  /// Identifiant de l'auteur
  final String authorId;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime? updatedAt;

  const PositionModel({
    this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.localImagePath,
    required this.authorId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Vérifie si la position a une image (locale ou distante)
  bool get hasImage =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (localImagePath != null && localImagePath!.isNotEmpty);

  /// Retourne l'URL complète de l'image (avec le domaine du serveur)
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;
    return '${ApiConfig.baseUrl}$imageUrl';
  }

  /// Parse sécurisé d'un double depuis différents types
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Crée une instance depuis un JSON de l'API
  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id']?.toString(),
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      latitude: _parseDouble(json['lat'] ?? json['latitude'], 0.0),
      longitude: _parseDouble(json['lng'] ?? json['longitude'], 0.0),
      imageUrl: json['imageUri'] ?? json['imageUrl'],
      localImagePath: null, // Les images locales ne viennent pas de l'API
      authorId: json['author'] ?? json['authorId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// Convertit l'instance en JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': title,
      'description': description,
      'lat': latitude,
      'lng': longitude,
      if (imageUrl != null) 'imageUri': imageUrl,
      'author': authorId,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Crée une copie avec des valeurs modifiées
  PositionModel copyWith({
    String? id,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? localImagePath,
    String? authorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PositionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PositionModel(id: $id, title: $title, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
