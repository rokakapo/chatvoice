import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

/// LLM Service - Processes text and generates responses
class LLMService {
  final AppSettings settings;
  final List<Map<String, String>> _conversationHistory = [];

  /// Maximum number of messages to keep in history to avoid exceeding context window
  static const int _maxHistoryMessages = 10;

  LLMService(this.settings);

  /// Reset conversation history
  void resetConversation() {
    _conversationHistory.clear();
  }

  /// Trim conversation history to prevent exceeding API context limits
  void _trimHistory() {
    while (_conversationHistory.length > _maxHistoryMessages) {
      _conversationHistory.removeAt(0);
    }
  }

  /// Generate a response from the LLM
  Future<String> generateResponse(String userMessage) async {
    switch (settings.llmProvider) {
      case 'openai':
        return _generateWithOpenAI(userMessage);
      case 'groq':
        return _generateWithGroq(userMessage);
      case 'custom':
        return _generateWithCustom(userMessage);
      default:
        return _generateWithOpenAI(userMessage);
    }
  }

  /// OpenAI chat completion
  Future<String> _generateWithOpenAI(String userMessage) async {
    try {
      _conversationHistory.add({'role': 'user', 'content': userMessage});
      _trimHistory();

      final messages = [
        {'role': 'system', 'content': settings.systemPrompt},
        ..._conversationHistory,
      ];

      final response = await http.post(
        Uri.parse(settings.llmApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.llmApiKey}',
        },
        body: json.encode({
          'model': settings.llmModel,
          'messages': messages,
          'temperature': settings.temperature,
          'max_tokens': settings.maxTokens,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        _conversationHistory.add({'role': 'assistant', 'content': assistantMessage});
        return assistantMessage.trim();
      } else {
        debugPrint('LLM Error: ${response.statusCode} - ${response.body}');
        _conversationHistory.removeLast(); // Remove failed user message
        throw Exception('LLM failed: ${response.statusCode}');
      }
    } catch (e) {
      // Remove the user message if it's still the last entry (failed request)
      if (_conversationHistory.isNotEmpty && 
          _conversationHistory.last['role'] == 'user' &&
          _conversationHistory.last['content'] == userMessage) {
        _conversationHistory.removeLast();
      }
      debugPrint('LLM Exception: $e');
      rethrow;
    }
  }

  /// Groq chat completion
  Future<String> _generateWithGroq(String userMessage) async {
    try {
      _conversationHistory.add({'role': 'user', 'content': userMessage});
      _trimHistory();

      final messages = [
        {'role': 'system', 'content': settings.systemPrompt},
        ..._conversationHistory,
      ];

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.llmApiKey}',
        },
        body: json.encode({
          'model': settings.llmModel == 'llama-3.1-70b-versatile' || settings.llmModel.isEmpty ? 'llama-3.3-70b-versatile' : settings.llmModel,
          'messages': messages,
          'temperature': settings.temperature,
          'max_completion_tokens': settings.maxTokens,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        _conversationHistory.add({'role': 'assistant', 'content': assistantMessage});
        return assistantMessage.trim();
      } else {
        _conversationHistory.removeLast(); // Remove failed user message
        throw Exception('Groq LLM failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (_conversationHistory.isNotEmpty && 
          _conversationHistory.last['role'] == 'user' &&
          _conversationHistory.last['content'] == userMessage) {
        _conversationHistory.removeLast();
      }
      debugPrint('Groq LLM Exception: $e');
      rethrow;
    }
  }

  /// Custom API completion
  Future<String> _generateWithCustom(String userMessage) async {
    try {
      _conversationHistory.add({'role': 'user', 'content': userMessage});
      _trimHistory();

      final messages = [
        {'role': 'system', 'content': settings.systemPrompt},
        ..._conversationHistory,
      ];

      final response = await http.post(
        Uri.parse(settings.llmApiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (settings.llmApiKey.isNotEmpty)
            'Authorization': 'Bearer ${settings.llmApiKey}',
        },
        body: json.encode({
          'model': settings.llmModel,
          'messages': messages,
          'temperature': settings.temperature,
          'max_tokens': settings.maxTokens,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        _conversationHistory.add({'role': 'assistant', 'content': assistantMessage});
        return assistantMessage.trim();
      } else {
        _conversationHistory.removeLast(); // Remove failed user message
        throw Exception('Custom LLM failed: ${response.statusCode}');
      }
    } catch (e) {
      if (_conversationHistory.isNotEmpty && 
          _conversationHistory.last['role'] == 'user' &&
          _conversationHistory.last['content'] == userMessage) {
        _conversationHistory.removeLast();
      }
      debugPrint('Custom LLM Exception: $e');
      rethrow;
    }
  }
}
