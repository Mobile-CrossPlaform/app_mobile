import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/core.dart';
import '../models/position_model.dart';

/// Service de communication avec l'API
///
/// Ce service gère toutes les opérations CRUD sur les positions.
/// Il utilise le pattern Singleton pour garantir une seule instance.
class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Mode mock pour les tests
  static bool _useMockData = false;

  /// Active/désactive le mode mock
  static void setMockMode(bool useMock) {
    _useMockData = useMock;
  }

  final String _baseUrl = '${ApiConfig.fullApiUrl}/positions';

  /// Récupère toutes les positions
  Future<List<PositionModel>> getPositions() async {
    if (_useMockData) return _getMockPositions();

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return _parsePositionsList(response.body);
      } else {
        throw ApiException(
          'Erreur lors de la récupération des positions',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw NetworkException('Impossible de se connecter au serveur', e);
    } on http.ClientException catch (e) {
      throw NetworkException('Erreur de connexion', e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur inattendue: $e', e);
    }
  }

  /// Récupère les positions d'un auteur
  Future<List<PositionModel>> getMyPositions(String authorId) async {
    if (_useMockData) {
      return _getMockPositions().where((p) => p.authorId == authorId).toList();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?author=$authorId'),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        return _parsePositionsList(response.body);
      } else {
        throw ApiException(
          'Erreur lors de la récupération',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion', e);
    }
  }

  /// Crée une nouvelle position
  Future<PositionModel> createPosition(PositionModel position, {File? imageFile}) async {
    if (_useMockData) {
      return position.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      _addPositionFields(request, position);

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send()
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parsePosition(response.body);
      } else {
        throw ApiException('Erreur lors de la création', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion', e);
    }
  }

  /// Met à jour une position existante
  Future<PositionModel> updatePosition(PositionModel position, {File? imageFile}) async {
    if (_useMockData) return position;

    try {
      final request = http.MultipartRequest('PATCH', Uri.parse('$_baseUrl/${position.id}'));
      _addPositionFields(request, position);

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send()
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return _parsePosition(response.body);
      } else {
        throw ApiException('Erreur lors de la mise à jour', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion', e);
    }
  }

  /// Supprime une position
  Future<void> deletePosition(String id) async {
    if (_useMockData) return;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Erreur lors de la suppression', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erreur de connexion', e);
    }
  }

  // --- Méthodes privées ---

  List<PositionModel> _parsePositionsList(String body) {
    try {
      final decoded = json.decode(body);
      final List<dynamic> data;

      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>;
      } else {
        throw const ParseException('Format de réponse invalide');
      }

      return data.map((item) => PositionModel.fromJson(item)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException('Erreur de parsing: $e', e);
    }
  }

  PositionModel _parsePosition(String body) {
    try {
      final decoded = json.decode(body);
      final Map<String, dynamic> data;

      if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as Map<String, dynamic>;
      } else if (decoded is Map) {
        data = decoded as Map<String, dynamic>;
      } else {
        throw const ParseException('Format de réponse invalide');
      }

      return PositionModel.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException('Erreur de parsing: $e', e);
    }
  }

  void _addPositionFields(http.MultipartRequest request, PositionModel position) {
    request.fields['name'] = position.title;
    request.fields['description'] = position.description;
    request.fields['lat'] = position.latitude.toStringAsFixed(15);
    request.fields['lng'] = position.longitude.toStringAsFixed(15);
    request.fields['author'] = position.authorId;
  }

  List<PositionModel> _getMockPositions() {
    return [
      PositionModel(
        id: '1',
        title: 'Tour Eiffel',
        description: 'Monument emblématique de Paris',
        latitude: 48.8584,
        longitude: 2.2945,
        authorId: 'demo',
        createdAt: DateTime.now(),
      ),
      PositionModel(
        id: '2',
        title: 'Notre-Dame',
        description: 'Cathédrale gothique',
        latitude: 48.8530,
        longitude: 2.3499,
        authorId: 'demo',
        createdAt: DateTime.now(),
      ),
    ];
  }
}
