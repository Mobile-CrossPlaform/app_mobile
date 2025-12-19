class TagModel {
  final int? id;
  final bool isOrgin;
  final bool isLevel;
  final bool isPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TagModel({
    this.id,
    required this.isOrgin,
    required this.isLevel,
    required this.isPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Fallback categories when the backend returns no Tag rows yet.
  static List<TagModel> fallbackCategories() {
    final now = DateTime.now();
    return [
      TagModel(
        id: null,
        isOrgin: true,
        isLevel: false,
        isPrice: false,
        createdAt: now,
        updatedAt: now,
      ),
      TagModel(
        id: null,
        isOrgin: false,
        isLevel: true,
        isPrice: false,
        createdAt: now,
        updatedAt: now,
      ),
      TagModel(
        id: null,
        isOrgin: false,
        isLevel: false,
        isPrice: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Returns the human-readable category name based on which boolean is true
  String get categoryName {
    if (isOrgin) return 'Origine';
    if (isLevel) return 'Niveau';
    if (isPrice) return 'Prix';
    return 'Unknown';
  }

  /// Returns the category key (for filtering)
  String get categoryKey {
    // Keep these aligned with backend field names / likely position.tags values
    if (isOrgin) return 'isOrgin';
    if (isLevel) return 'isLevel';
    if (isPrice) return 'isPrice';
    return 'unknown';
  }

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'],
      isOrgin: json['isOrgin'] ?? false,
      isLevel: json['isLevel'] ?? false,
      isPrice: json['isPrice'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'isOrgin': isOrgin,
      'isLevel': isLevel,
      'isPrice': isPrice,
    };
  }

  TagModel copyWith({
    int? id,
    bool? isOrgin,
    bool? isLevel,
    bool? isPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TagModel(
      id: id ?? this.id,
      isOrgin: isOrgin ?? this.isOrgin,
      isLevel: isLevel ?? this.isLevel,
      isPrice: isPrice ?? this.isPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TagModel(id: $id, category: $categoryName)';
  }
}

