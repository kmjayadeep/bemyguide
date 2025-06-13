import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlaceSuggestion {
  final String name;
  final String description;
  final String category;
  final double? distanceKm;
  final String? websiteUrl;
  final double? latitude;
  final double? longitude;

  PlaceSuggestion({
    required this.name,
    required this.description,
    required this.category,
    this.distanceKm,
    this.websiteUrl,
    this.latitude,
    this.longitude,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      distanceKm:
          json['distance_km'] != null
              ? (json['distance_km'] as num).toDouble()
              : null,
      websiteUrl: json['website_url'] as String?,
      latitude:
          json['latitude'] != null
              ? (json['latitude'] as num).toDouble()
              : null,
      longitude:
          json['longitude'] != null
              ? (json['longitude'] as num).toDouble()
              : null,
    );
  }
}

class ApiService {
  // Get base URL from environment variables
  static String get _baseUrl =>
      dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8787';

  static String? _jwtToken;
  static String? _deviceId;

  /// Get or generate a unique device ID
  static Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');

    if (_deviceId == null) {
      // Generate a unique device ID
      final deviceInfo = DeviceInfoPlugin();
      String identifier = '';

      try {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          identifier = '${androidInfo.id}-${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          identifier = '${iosInfo.identifierForVendor}-${iosInfo.model}';
        } else {
          identifier = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
        }
      } catch (e) {
        identifier = 'unknown-${DateTime.now().millisecondsSinceEpoch}';
      }

      _deviceId = identifier;

      await prefs.setString('device_id', _deviceId!);
    }

    return _deviceId!;
  }

  /// Get or refresh JWT token
  static Future<String> _getJwtToken() async {
    if (_jwtToken != null) {
      // TODO: Check if token is still valid (not expired)
      return _jwtToken!;
    }

    final deviceId = await _getDeviceId();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/anonymous'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          _jwtToken = data['token'];

          // Store token in SharedPreferences for persistence
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', _jwtToken!);

          return _jwtToken!;
        } else {
          throw Exception(
            'Authentication failed: ${data['error'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Authentication failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
  }

  /// Get recommendations from the backend API
  static Future<List<PlaceSuggestion>> getRecommendations(
    String query,
    double latitude,
    double longitude,
  ) async {
    try {
      final token = await _getJwtToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/recommendations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'query': query,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> suggestionsJson = data['data'];
          return suggestionsJson
              .map((json) => PlaceSuggestion.fromJson(json))
              .toList();
        } else {
          throw Exception('API error: ${data['error'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 401) {
        // Token expired, clear it and retry once
        _jwtToken = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');

        // Retry the request with a new token
        return getRecommendations(query, latitude, longitude);
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        final data = jsonDecode(response.body);
        throw Exception(
          'Rate limit exceeded: ${data['error'] ?? 'Too many requests'}',
        );
      } else {
        final data = jsonDecode(response.body);
        throw Exception(
          'API error (${response.statusCode}): ${data['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e.toString().contains('Rate limit exceeded')) {
        rethrow; // Keep rate limit errors as is
      }
      throw Exception('Failed to get recommendations: $e');
    }
  }

  /// Initialize the API service (load saved token)
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwt_token');
    _deviceId = prefs.getString('device_id');
  }

  /// Clear authentication data (for logout or reset)
  static Future<void> clearAuth() async {
    _jwtToken = null;
    _deviceId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('device_id');
  }
}
