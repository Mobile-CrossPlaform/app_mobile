import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/position_model.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configuration
  final String _baseUrl = ApiConfig.apiUrl;
  final Duration _timeout = Duration(seconds: ApiConfig.timeoutSeconds);

  // Mode mock pour les tests
  bool _useMockData = false;

  /// Active ou désactive le mode mock (utile pour les tests)
  void setMockMode(bool enabled) => _useMockData = enabled;

  Future<List<PositionModel>> getAllPositions() async {
    if (_useMockData) {
      return _getMockPositions();
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/positions'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return _parsePositionsList(response.body);
      } else {
        throw ApiException.fromStatusCode(response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Impossible de contacter le serveur', e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion: $e', e);
    }
  }

  Future<List<PositionModel>> getMyPositions(String authorId) async {
    if (_useMockData) {
      return _getMockPositions().where((p) => p.authorId == authorId).toList();
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/positions?author=$authorId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return _parsePositionsList(response.body);
      } else {
        throw ApiException.fromStatusCode(response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Impossible de contacter le serveur', e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion: $e', e);
    }
  }

  /// Parse une réponse JSON en liste de positions
  /// Gère les deux formats : liste directe ou objet avec clé 'data'
  List<PositionModel> _parsePositionsList(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      final List<dynamic> data;

      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>;
      } else {
        throw const ParseException('Format de réponse invalide');
      }

      return data.map((json) => PositionModel.fromJson(json)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException('Erreur lors du parsing des données', e);
    }
  }

  /// Parse une réponse JSON en position unique
  PositionModel _parsePosition(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      final positionData = decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      return PositionModel.fromJson(positionData);
    } catch (e) {
      throw ParseException('Erreur lors du parsing de la position', e);
    }
  }

  Future<PositionModel> createPosition(
    PositionModel position,
    File? imageFile,
  ) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return position.copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        localImagePath: imageFile?.path,
      );
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/positions'),
      );

      _addPositionFields(request, position);

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return _parsePosition(response.body);
      } else {
        throw ApiException(
          'Erreur lors de la création de la position',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Impossible de contacter le serveur', e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion: $e', e);
    }
  }

  Future<PositionModel> updatePosition(
    PositionModel position,
    File? imageFile,
  ) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return position.copyWith(
        localImagePath: imageFile?.path ?? position.localImagePath,
      );
    }

    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$_baseUrl/positions/${position.id}'),
      );

      _addPositionFields(request, position);

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parsePosition(response.body);
      } else {
        throw ApiException(
          'Erreur lors de la modification de la position',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Impossible de contacter le serveur', e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion: $e', e);
    }
  }

  /// Ajoute les champs de position à une requête multipart
  void _addPositionFields(
    http.MultipartRequest request,
    PositionModel position,
  ) {
    request.fields['name'] = position.title;
    request.fields['description'] = position.description;
    request.fields['lat'] = position.latitude.toStringAsFixed(15);
    request.fields['lng'] = position.longitude.toStringAsFixed(15);
    request.fields['author'] = position.authorId;
  }

  Future<void> deletePosition(int id) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/positions/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'Erreur lors de la suppression',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Impossible de contacter le serveur', e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion: $e', e);
    }
  }

  List<PositionModel> _getMockPositions() {
    return [
      PositionModel(
        id: 1,
        title: 'Tour Eiffel',
        description:
            'Monument emblématique de Paris, la Dame de Fer offre une vue imprenable sur la ville.',
        latitude: 48.8584,
        longitude: 2.2945,
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg/800px-Tour_Eiffel_Wikimedia_Commons_%28cropped%29.jpg',
        authorId: 'user_123',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PositionModel(
        id: 2,
        title: 'Notre-Dame de Paris',
        description:
            'Cathédrale gothique historique située sur l\'île de la Cité.',
        latitude: 48.8530,
        longitude: 2.3499,
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Notre-Dame_de_Paris%2C_4_October_2017.jpg/800px-Notre-Dame_de_Paris%2C_4_October_2017.jpg',
        authorId: 'user_123',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      PositionModel(
        id: 3,
        title: 'Musée du Louvre',
        description:
            'Le plus grand musée d\'art du monde, abritant la Joconde.',
        latitude: 48.8606,
        longitude: 2.3376,
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Louvre_Museum_Wikimedia_Commons.jpg/800px-Louvre_Museum_Wikimedia_Commons.jpg',
        authorId: 'other_user',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PositionModel(
        id: 4,
        title: 'Arc de Triomphe',
        description: 'Monument national situé sur la place de l\'Étoile.',
        latitude: 48.8738,
        longitude: 2.2950,
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/7/79/Arc_de_Triomphe%2C_Paris_21_October_2010.jpg/800px-Arc_de_Triomphe%2C_Paris_21_October_2010.jpg',
        authorId: 'user_123',
        createdAt: DateTime.now(),
      ),
      PositionModel(
        id: 5,
        title: 'Sacré-Cœur',
        description: 'Basilique sur la butte Montmartre avec vue panoramique.',
        latitude: 48.8867,
        longitude: 2.3431,
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Le_sacre_coeur.jpg/800px-Le_sacre_coeur.jpg',
        authorId: 'other_user',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      PositionModel(
        id: 6,
        title: 'Place Bellecour',
        description: 'Plus grande place piétonne d\'Europe située à Lyon.',
        latitude: 45.7578,
        longitude: 4.8320,
        authorId: 'user_123',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PositionModel(
        id: 7,
        title: 'Basilique de Fourvière',
        description: 'Basilique dominant Lyon depuis la colline de Fourvière.',
        latitude: 45.7623,
        longitude: 4.8225,
        authorId: 'other_user',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }
}
