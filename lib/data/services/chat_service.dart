import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ChatMessage {
  final String role;     // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class ChatService {
  // ✅ Proxy URL — Groq key lives on Render server, never in this file
  // Replace with your actual Render URL after deploying the proxy
  static const String _proxyUrl =
      'https://agrosmart-proxy.onrender.com/';

  // Build system prompt with live farm context
  static String _buildContext({
    required SensorData sensor,
    required List<String> cropNames,
    required String farmName,
    required String city,
    required bool isTamil,
  }) {
    final cropList =
        cropNames.isEmpty ? 'Not specified' : cropNames.join(', ');

    final lang = isTamil
        ? 'முதலில் தமிழில் பதில் சொல்லுங்கள். '
          'பயனர் ஆங்கிலத்தில் கேட்டால் ஆங்கிலத்திலும் பதில் சொல்லலாம். '
          'சுருக்கமாக மற்றும் நடைமுறை ரீதியாக பதில் சொல்லுங்கள்.'
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
    // Build messages in OpenAI format (Groq uses the same format)
    final messages = <Map<String, String>>[
      // System prompt with live farm context
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
      // Full conversation history for multi-turn memory
      ...history.map((m) => {
        'role': m.role,       // 'user' or 'assistant'
        'content': m.content,
      }),
      // Current user message
      {
        'role': 'user',
        'content': userMessage,
      },
    ];

    // ✅ Call our proxy — no API key needed here
    // The proxy adds the Authorization header server-side
    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': messages,
        'max_tokens': 512,
        'temperature': 0.7,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List;
      if (choices.isEmpty) throw Exception('No response from AI');
      return choices[0]['message']['content'] as String;
    } else {
      final error = jsonDecode(response.body);
      final msg   = error['error']?['message'] ?? response.body;
      throw Exception('AI error ${response.statusCode}: $msg');
    }
  }
}