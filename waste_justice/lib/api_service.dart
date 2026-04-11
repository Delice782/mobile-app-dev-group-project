import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'offline_storage.dart';

class ApiService {
  static Future<String?> _token() async {
    final creds = OfflineStorageService.getUserCredentials();
    return creds?['token']?.toString();
  }

  static Map<String, dynamic> _decodeJsonResponse(http.Response res) {
    final raw = res.body.trim();
    if (raw.isEmpty) {
      throw Exception(
        'Empty server response (HTTP ${res.statusCode}). Check API path and server logs.',
      );
    }
    final lower = raw.toLowerCase();
    if (raw.startsWith('<') ||
        lower.contains('<!doctype') ||
        lower.contains('<html')) {
      throw Exception(
        'Server error (HTTP ${res.statusCode}): the site returned HTML instead of JSON. '
        'Deploy the latest API files (especially response.php, submit_collection.php, '
        'upload_collection_photo.php) and ensure api/uploads/collections exists and is writable.',
      );
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object');
      }
      return decoded;
    } on FormatException catch (e) {
      final preview = raw.length > 240 ? '${raw.substring(0, 240)}…' : raw;
      throw Exception(
        'Invalid JSON from server (HTTP ${res.statusCode}): $e. Body: $preview',
      );
    }
  }

  static Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final res = await http.get(Uri.parse(url), headers: headers);
    final body = _decodeJsonResponse(res);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Request failed');
    }
    return body;
  }

  static Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) async {
    final res = await http.post(
      Uri.parse(url),
      headers: headers ?? {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
    final body = _decodeJsonResponse(res);
    if (body['success'] != true) {
      final msg = body['message'] ?? 'Request failed';
      if (body['errors'] != null) {
        throw Exception('$msg: ${body['errors']}');
      }
      throw Exception(msg);
    }
    return body;
  }

  static Future<List<Map<String, dynamic>>> getPricing() async {
    final body = await _get(ApiConfig.pricing('get_prices.php'));
    final List pricing = body['data']?['pricing'] ?? [];
    return pricing.cast<Map<String, dynamic>>();
  }

  /// All plastic types from `PlasticType` table; optional per-kg price for selected aggregator (web parity).
  static Future<List<Map<String, dynamic>>> getPlasticTypes({
    int? aggregatorId,
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Please login first.');
    final q = aggregatorId != null && aggregatorId > 0
        ? '?aggregatorID=$aggregatorId'
        : '';
    final body = await _get(
      '${ApiConfig.waste('get_plastic_types.php')}$q',
      headers: {'Authorization': 'Bearer $token'},
    );
    final List list = body['data']?['plasticTypes'] ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getCollections() async {
    final token = await _token();
    if (token == null) throw Exception('Please login first.');
    final body = await _get(
      ApiConfig.waste('get_collections.php'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return body['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getEarnings() async {
    final token = await _token();
    if (token == null) throw Exception('Please login first.');
    final body = await _get(
      ApiConfig.payments('get_earnings.php'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return body['data'] as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getNearestAggregators({
    required double latitude,
    required double longitude,
    int? plasticTypeId,
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Please login first.');
    final query = StringBuffer(
      '${ApiConfig.aggregators('get_nearest.php')}?latitude=$latitude&longitude=$longitude',
    );
    if (plasticTypeId != null) {
      query.write('&plasticTypeID=$plasticTypeId');
    }
    final body = await _get(
      query.toString(),
      headers: {'Authorization': 'Bearer $token'},
    );
    final List items = body['data']?['aggregators'] ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  /// Multipart upload; returns server-relative path for `submit_collection.php` `photoPath`.
  static Future<String> uploadCollectionPhoto(File file) async {
    final token = await _token();
    if (token == null) throw Exception('Please login first.');
    final uri = Uri.parse(ApiConfig.waste('upload_collection_photo.php'));
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('photo', file.path),
    );
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _decodeJsonResponse(res);
    final path = body['data']?['photoPath']?.toString() ?? '';
    if (path.isEmpty) {
      throw Exception('Upload did not return a photo path');
    }
    return path;
  }

  static Future<Map<String, dynamic>> submitCollection({
    required int plasticTypeId,
    required double weight,
    required double latitude,
    required double longitude,
    String location = '',
    String notes = '',
    String photoPath = '',
    int? aggregatorId,
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Please login first.');
    final payload = <String, dynamic>{
      'plasticTypeID': plasticTypeId,
      'weight': weight,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'notes': notes,
      'photoPath': photoPath,
    };
    if (aggregatorId != null && aggregatorId > 0) {
      payload['aggregatorID'] = aggregatorId;
    }
    final body = await _post(
      ApiConfig.waste('submit_collection.php'),
      payload,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return body['data'] as Map<String, dynamic>;
  }
}
