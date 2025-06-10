import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static String get _baseUrl => dotenv.env['CLOUDFLARE_AI_URL'] ?? '';
  static String get _token => dotenv.env['CLOUDFLARE_AI_TOKEN'] ?? '';

  static Future<String> generateResponse(String userQuery) async {
    if (_baseUrl.isEmpty || _token.isEmpty) {
      throw Exception('Cloudflare AI credentials not configured');
    }

    try {
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
                  'You are BeMyGuide, a helpful AI-powered local guide assistant. '
                  'Help users find nearby attractions, restaurants, and activities. '
                  'Provide practical, location-aware suggestions and be conversational and friendly. '
                  'If location-specific information is requested but no location is provided, '
                  'ask the user to specify their location or enable location services.',
            },
            {'role': 'user', 'content': userQuery},
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response structures from Cloudflare AI
        if (data['result'] != null && data['result']['response'] != null) {
          return data['result']['response'];
        } else if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        } else if (data['result'] != null) {
          return data['result'].toString();
        } else {
          return 'I received a response but couldn\'t parse it properly. Please try again.';
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
