import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ChatService {
  // ✅ Key is injected at build time via --dart-define
  // Never hardcode the key here
  static const String _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model  = 'llama-3.1-8b-instant';

  static String _buildContext({
    required SensorData sensor,
    required List<String> cropNames,
    required String farmName,
    required String city,
    required bool isTamil,
  }) {
    final cropList = cropNames.isEmpty ? 'Not specified' : cropNames.join(', ');
    final lang = isTamil
        ? 'முதலில் தமிழில் பதில் சொல்லுங்கள். பயனர் ஆங்கிலத்தில் கேட்டால் ஆங்கிலத்திலும் பதில் சொல்லலாம். சுருக்கமாக மற்றும் நடைமுறை ரீதியாக பதில் சொல்லுங்கள்.'
        : 'Respond in English. Keep answers short and practical for a farmer.';

    return '''
You are AgroSmart AI, a friendly and knowledgeable farm assistant for farmers in Tamil Nadu, India.

You have real-time access to this farmer's data:
- Farm name: $farmName
- Location: $city
- Temperature: ${sensor.temperature.toStringAsFixed(1)}°C
- Humidity: ${sensor.humidity.toStringAsFixed(0)}%
- Soil moisture: ${sensor.soilMoisture.toStringAsFixed(0)}% ${sensor.soilMoisture < 40 ? '⚠️ LOW — irrigation needed' : '✅ normal'}
- Active crops: $cropList
- Sensor mode: Simulated (demo)

Your responsibilities:
- Answer questions about irrigation, crop health, soil, weather, and farming practices
- Always reference the actual sensor readings when giving advice
- If soil moisture is below 40%, recommend irrigation
- If temperature is above 33°C, warn about heat stress
- Keep answers concise — 2 to 4 sentences max — farmers are busy
- Be warm and encouraging, like a knowledgeable neighbour
- Never give generic advice — always tie it to the sensor data

$lang''';
  }

  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
    required SensorData sensor,
    required List<String> cropNames,
    required String farmName,
    required String city,
    required bool isTamil,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('No API key — build with --dart-define=GROQ_API_KEY=your_key');
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _buildContext(
          sensor: sensor,
          cropNames: cropNames,
          farmName: farmName,
          city: city,
          isTamil: isTamil,
        ),
      },
      ...history.map((m) => {
        'role': m.role,
        'content': m.content,
      }),
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': 512,
        'temperature': 0.7,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List;
      if (choices.isEmpty) throw Exception('No response from Groq');
      return choices[0]['message']['content'] as String;
    } else {
      final error = jsonDecode(response.body);
      final msg = error['error']?['message'] ?? response.body;
      throw Exception('Groq error ${response.statusCode}: $msg');
    }
  }
}