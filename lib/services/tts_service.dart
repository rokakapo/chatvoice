import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';

/// Text-to-Speech Service - Converts text to audio
class TTSService {
  final AppSettings settings;

  TTSService(this.settings);

  /// Convert text to audio file and return the file path
  Future<String> synthesize(String text) async {
    switch (settings.ttsProvider) {
      case 'openai':
        return _synthesizeWithOpenAI(text);
      case 'groq':
        return _synthesizeWithGroq(text);
      case 'elevenlabs':
        return _synthesizeWithElevenLabs(text);
      case 'custom':
        return _synthesizeWithCustom(text);
      default:
        return _synthesizeWithOpenAI(text);
    }
  }

  /// Get temp directory for audio files
  Future<String> _getTempPath({String ext = 'mp3'}) async {
    final dir = await getTemporaryDirectory();
    final audioDir = Directory('${dir.path}/tts_output');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    return '${audioDir.path}/response_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  /// OpenAI TTS
  Future<String> _synthesizeWithOpenAI(String text) async {
    try {
      final apiKey = settings.ttsApiKey.isNotEmpty ? settings.ttsApiKey : settings.llmApiKey;
      
      final response = await http.post(
        Uri.parse(settings.ttsApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': settings.ttsModel,
          'input': text,
          'voice': settings.ttsVoice,
          'speed': settings.ttsSpeed,
          'response_format': 'mp3',
        }),
      );

      if (response.statusCode == 200) {
        final outputPath = await _getTempPath();
        final file = File(outputPath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('TTS audio saved to: $outputPath');
        return outputPath;
      } else {
        debugPrint('TTS Error: ${response.statusCode} - ${response.body}');
        throw Exception('TTS failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('TTS Exception: $e');
      rethrow;
    }
  }

  /// Groq TTS
  Future<String> _synthesizeWithGroq(String text) async {
    try {
      final apiKey = settings.ttsApiKey.isNotEmpty ? settings.ttsApiKey : settings.llmApiKey;
      
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/audio/speech'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': settings.ttsModel.isNotEmpty ? settings.ttsModel : 'canopylabs/orpheus-arabic-saudi',
          'voice': settings.ttsVoice.isNotEmpty ? settings.ttsVoice : 'fahad',
          'input': text,
          'response_format': 'wav',
        }),
      );

      if (response.statusCode == 200) {
        final outputPath = await _getTempPath(ext: 'wav');
        final file = File(outputPath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Groq TTS audio saved to: $outputPath');
        return outputPath;
      } else {
        throw Exception('Groq TTS failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Groq TTS Exception: $e');
      rethrow;
    }
  }

  /// ElevenLabs TTS
  Future<String> _synthesizeWithElevenLabs(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/${settings.ttsVoice}'),
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': settings.ttsApiKey,
        },
        body: json.encode({
          'text': text,
          'model_id': settings.ttsModel.isNotEmpty ? settings.ttsModel : 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        }),
      );

      if (response.statusCode == 200) {
        final outputPath = await _getTempPath();
        final file = File(outputPath);
        await file.writeAsBytes(response.bodyBytes);
        return outputPath;
      } else {
        throw Exception('ElevenLabs TTS failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ElevenLabs TTS Exception: $e');
      rethrow;
    }
  }

  /// Custom API TTS
  Future<String> _synthesizeWithCustom(String text) async {
    try {
      final response = await http.post(
        Uri.parse(settings.ttsApiUrl),
        headers: {
          'Content-Type': 'application/json',
          if (settings.ttsApiKey.isNotEmpty)
            'Authorization': 'Bearer ${settings.ttsApiKey}',
        },
        body: json.encode({
          'text': text,
          'model': settings.ttsModel,
          'voice': settings.ttsVoice,
          'speed': settings.ttsSpeed,
        }),
      );

      if (response.statusCode == 200) {
        final outputPath = await _getTempPath();
        final file = File(outputPath);
        await file.writeAsBytes(response.bodyBytes);
        return outputPath;
      } else {
        throw Exception('Custom TTS failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Custom TTS Exception: $e');
      rethrow;
    }
  }
}
