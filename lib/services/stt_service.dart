import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

/// Speech-to-Text Service - Converts audio to text
class STTService {
  final AppSettings settings;

  STTService(this.settings);

  /// Transcribe audio file to text
  Future<String> transcribe(String audioFilePath) async {
    switch (settings.sttProvider) {
      case 'openai_whisper':
        return _transcribeWithWhisper(audioFilePath);
      case 'groq':
        return _transcribeWithGroq(audioFilePath);
      case 'custom':
        return _transcribeWithCustom(audioFilePath);
      default:
        return _transcribeWithWhisper(audioFilePath);
    }
  }

  /// OpenAI Whisper transcription
  Future<String> _transcribeWithWhisper(String audioFilePath) async {
    try {
      final apiKey = settings.sttApiKey.isNotEmpty ? settings.sttApiKey : settings.llmApiKey;
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(settings.sttApiUrl),
      );

      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['model'] = settings.sttModel;
      request.fields['language'] = settings.language;
      request.fields['response_format'] = 'json';

      final file = await http.MultipartFile.fromPath('file', audioFilePath);
      request.files.add(file);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['text'] ?? '';
      } else {
        debugPrint('STT Error: ${response.statusCode} - ${response.body}');
        throw Exception('STT failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('STT Exception: $e');
      rethrow;
    }
  }

  /// Groq Whisper transcription
  Future<String> _transcribeWithGroq(String audioFilePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );

      final apiKey = settings.sttApiKey.isNotEmpty ? settings.sttApiKey : settings.llmApiKey;
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['model'] = settings.sttModel.isNotEmpty ? settings.sttModel : 'whisper-large-v3-turbo';
      request.fields['language'] = settings.language;
      request.fields['response_format'] = 'json';
      request.fields['temperature'] = '0'; // High accuracy

      final file = await http.MultipartFile.fromPath('file', audioFilePath);
      request.files.add(file);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['text'] ?? '';
      } else {
        throw Exception('Groq STT failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Groq STT Exception: $e');
      rethrow;
    }
  }

  /// Custom API transcription
  Future<String> _transcribeWithCustom(String audioFilePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(settings.sttApiUrl),
      );

      if (settings.sttApiKey.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${settings.sttApiKey}';
      }
      request.fields['model'] = settings.sttModel;
      request.fields['language'] = settings.language;

      final file = await http.MultipartFile.fromPath('file', audioFilePath);
      request.files.add(file);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['text'] ?? data['transcription'] ?? '';
      } else {
        throw Exception('Custom STT failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Custom STT Exception: $e');
      rethrow;
    }
  }
}
