import '../core/constants.dart';

class PositionModel {
  final int? id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? localImagePath;
  final String authorId;
  final DateTime createdAt;

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
  });

  /// Retourne l'URL complète de l'image (avec le serveur)
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    // Si l'URL commence déjà par http, la retourner telle quelle
    if (imageUrl!.startsWith('http')) return imageUrl;
    // Sinon, ajouter le base URL du serveur
    return '${ApiConfig.baseUrl}$imageUrl';
  }

  /// Indique si la position a une image (locale ou distante)
  bool get hasImage => fullImageUrl != null || localImagePath != null;

  /// Crée un PositionModel depuis la réponse JSON de l'API
  /// L'API utilise: name, lat, lng, imageUri, author
  /// Le modèle utilise: title, latitude, longitude, imageUrl, authorId
  factory PositionModel.fromJson(Map<String, dynamic> json) {
    // Extraire l'URL de l'image avec plusieurs clés possibles
    final imageUrl =
        json['imageUri'] ??
        json['imageUrl'] ??
        json['image_url'] ??
        json['image'];

    return PositionModel(
      id: json['id'],
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      latitude: _parseDouble(json['lat'] ?? json['latitude']),
      longitude: _parseDouble(json['lng'] ?? json['longitude']),
      imageUrl: imageUrl,
      // localImagePath est UNIQUEMENT pour les images capturées localement
      localImagePath: json['local_image_path'],
      authorId: json['author'] ?? json['author_id'] ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  /// Parse une valeur en double de manière sécurisée
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parse une date de manière sécurisée
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Convertit en JSON pour l'envoi à l'API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': title,
      'description': description,
      'lat': latitude,
      'lng': longitude,
      if (imageUrl != null) 'imageUri': imageUrl,
      if (localImagePath != null) 'imagePath': localImagePath,
      'author': authorId,
    };
  }

  PositionModel copyWith({
    int? id,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? localImagePath,
    String? authorId,
    DateTime? createdAt,
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PositionModel(id: $id, title: $title, lat: $latitude, lng: $longitude)';
  }
}
