import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlaceSuggestion {
  final String name;
  final String description;
  final String category;
  final double distanceKm;
  final String? websiteUrl;
  final double? latitude;
  final double? longitude;

  PlaceSuggestion({
    required this.name,
    required this.description,
    required this.category,
    required this.distanceKm,
    this.websiteUrl,
    this.latitude,
    this.longitude,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
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

class AiService {
  static String get _baseUrl => dotenv.env['CLOUDFLARE_AI_URL'] ?? '';
  static String get _token => dotenv.env['CLOUDFLARE_AI_TOKEN'] ?? '';

  static Future<List<PlaceSuggestion>> generateResponse(
    String userQuery,
    double userLatitude,
    double userLongitude,
  ) async {
    if (_baseUrl.isEmpty || _token.isEmpty) {
      throw Exception(
        'Cloudflare AI credentials not configured. Please check your .env file and ensure CLOUDFLARE_AI_URL and CLOUDFLARE_AI_TOKEN are set.',
      );
    }

    try {
      final String currentTime = DateTime.now().toString();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a local guide assistant named \'bemyguide\'. Your task is to find relevant places for the user based on their query and location. The current time is $currentTime. ALWAYS respond with a valid JSON object containing a single key \'suggestions\' which is an array of places. Each place must have the following keys: \'name\', \'description\', \'category\', \'distance_km\', \'website_url\', \'latitude\', and \'longitude\'. The \'description\' should be a concise, one-sentence summary. The \'distance_km\' should be the approximate distance in kilometers from the user\'s location to the suggested place. If you cannot find a website, set \'website_url\' to null. If you cannot find the exact coordinates, set \'latitude\' and \'longitude\' to null. The \'category\' should be one of: \'Park\', \'Restaurant\', \'Museum\', \'Activity\', \'Landmark\', \'Shopping\', \'Other\'. Do not include any text outside of the JSON object.',
            },
            {
              'role': 'user',
              'content':
                  'User query: \'$userQuery\'. My current location is latitude $userLatitude and longitude $userLongitude.',
            },
          ],
          'max_tokens': 800,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response structures from Cloudflare AI
        String aiResponseText = '';
        if (data['result'] != null && data['result']['response'] != null) {
          aiResponseText = data['result']['response'];
        } else if (data['choices'] != null && data['choices'].isNotEmpty) {
          aiResponseText = data['choices'][0]['message']['content'];
        } else if (data['result'] != null) {
          aiResponseText = data['result'].toString();
        } else {
          throw Exception('Unexpected response format from AI service');
        }

        // Parse the JSON response from AI
        try {
          final jsonResponse = jsonDecode(aiResponseText);
          if (jsonResponse['suggestions'] != null) {
            final List<dynamic> suggestionsJson = jsonResponse['suggestions'];
            return suggestionsJson
                .map((json) => PlaceSuggestion.fromJson(json))
                .toList();
          } else {
            throw Exception('No suggestions found in AI response');
          }
        } catch (e) {
          throw Exception(
            'Failed to parse AI response as JSON: $e\nResponse: $aiResponseText',
          );
        }
      } else {
        throw Exception(
          'Failed to get response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with AI service: $e');
    }
  }
}
