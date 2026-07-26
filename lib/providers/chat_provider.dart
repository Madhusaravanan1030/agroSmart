import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/chat_service.dart';
import '../data/models/sensor_data.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isTamil = false;
  bool get isTamil => _isTamil;

  String _farmName = 'My Farm';
  String _city     = 'Chennai';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _farmName = prefs.getString('farmName') ?? 'My Farm';
    _city     = prefs.getString('city')     ?? 'Chennai';
    _isTamil  = prefs.getBool('isTamil')    ?? false;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String text,
    required SensorData sensor,
    required List<String> cropNames,
  }) async {
    if (text.trim().isEmpty) return;

    // Add user message immediately so UI feels instant
    final userMsg = ChatMessage(
      role: 'user',          // Groq uses 'user'
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    _messages     = [..._messages, userMsg];
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _service.sendMessage(
        history:     _messages.sublist(0, _messages.length - 1),
        userMessage: text.trim(),
        sensor:      sensor,
        cropNames:   cropNames,
        farmName:    _farmName,
        city:        _city,
        isTamil:     _isTamil,
      );

      final assistantMsg = ChatMessage(
        role: 'assistant',   // ✅ Groq uses 'assistant'
        content: reply,
        timestamp: DateTime.now(),
      );
      _messages = [..._messages, assistantMsg];
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('429')) {
        _errorMessage =
            'Too many messages — wait 30 seconds and try again\n'
            'அதிக கோரிக்கைகள் — 30 விநாடி காத்திருந்து மீண்டும் முயற்சிக்கவும்';
      } else if (msg.contains('401') || msg.contains('invalid_api_key')) {
        _errorMessage =
            'Invalid API key — check your Groq key in chat_service.dart';
      } else if (msg.contains('404')) {
        _errorMessage =
            'Model not found — check the model name in chat_service.dart';
      } else {
        _errorMessage =
            'Could not reach AI — check your internet connection';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages     = [];
    _errorMessage = null;
    notifyListeners();
  }
}