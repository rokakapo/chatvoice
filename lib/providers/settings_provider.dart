import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  static const String _settingsKey = 'app_settings';

  /// Load settings from shared preferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_settingsKey);
      if (jsonStr != null) {
        _settings = AppSettings.fromJson(json.decode(jsonStr));
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _settings = AppSettings();
    }
    notifyListeners();
  }

  /// Save settings to shared preferences
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, json.encode(_settings.toJson()));
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Update settings
  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    saveSettings();
  }

  // Individual setters for convenience
  void setSttProvider(String value) { _settings.sttProvider = value; saveSettings(); }
  void setSttApiKey(String value) { _settings.sttApiKey = value; saveSettings(); }
  void setSttApiUrl(String value) { _settings.sttApiUrl = value; saveSettings(); }
  void setSttModel(String value) { _settings.sttModel = value; saveSettings(); }
  
  void setLlmProvider(String value) { _settings.llmProvider = value; saveSettings(); }
  void setLlmApiKey(String value) { _settings.llmApiKey = value; saveSettings(); }
  void setLlmApiUrl(String value) { _settings.llmApiUrl = value; saveSettings(); }
  void setLlmModel(String value) { _settings.llmModel = value; saveSettings(); }
  void setSystemPrompt(String value) { _settings.systemPrompt = value; saveSettings(); }
  void setTemperature(double value) { _settings.temperature = value; saveSettings(); }
  void setMaxTokens(int value) { _settings.maxTokens = value; saveSettings(); }
  
  void setTtsProvider(String value) { _settings.ttsProvider = value; saveSettings(); }
  void setTtsApiKey(String value) { _settings.ttsApiKey = value; saveSettings(); }
  void setTtsApiUrl(String value) { _settings.ttsApiUrl = value; saveSettings(); }
  void setTtsModel(String value) { _settings.ttsModel = value; saveSettings(); }
  void setTtsVoice(String value) { _settings.ttsVoice = value; saveSettings(); }
  void setTtsSpeed(double value) { _settings.ttsSpeed = value; saveSettings(); }
  
  void setAutoAnswer(bool value) { _settings.autoAnswer = value; saveSettings(); }
  void setAutoAnswerDelay(int value) { _settings.autoAnswerDelay = value; saveSettings(); }
  void setRecordCalls(bool value) { _settings.recordCalls = value; saveSettings(); }
  void setLanguage(String value) { _settings.language = value; saveSettings(); }
  void setGreetingMessage(String value) { _settings.greetingMessage = value; saveSettings(); }

  /// Check if essential settings are configured
  bool get isConfigured {
    return _settings.llmApiKey.isNotEmpty;
  }

  /// Get a summary of current configuration
  String get configSummary {
    if (!isConfigured) return 'غير مُهيأ - يرجى إدخال مفاتيح API';
    return 'STT: ${_settings.sttProvider} | LLM: ${_settings.llmProvider} (${_settings.llmModel}) | TTS: ${_settings.ttsProvider}';
  }
}
