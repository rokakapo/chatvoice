import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import 'stt_service.dart';
import 'llm_service.dart';
import 'tts_service.dart';
import 'native_call_service.dart';

/// AI Pipeline - Orchestrates STT -> LLM -> TTS flow
class AIPipelineService {
  late STTService _sttService;
  late LLMService _llmService;
  late TTSService _ttsService;
  
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  final StreamController<PipelineEvent> _eventController = StreamController.broadcast();
  Stream<PipelineEvent> get events => _eventController.stream;

  void updateSettings(AppSettings settings) {
    _sttService = STTService(settings);
    _llmService = LLMService(settings);
    _ttsService = TTSService(settings);
  }

  /// Reset conversation for new call
  void resetConversation() {
    _llmService.resetConversation();
  }

  /// Process a recorded audio chunk through the full pipeline:
  /// Audio -> STT -> LLM -> TTS -> Play to call
  Future<PipelineResult> processAudioChunk(String audioFilePath) async {
    if (_isProcessing) {
      debugPrint('Pipeline already processing, skipping...');
      return PipelineResult(
        success: false,
        error: 'Pipeline is already processing',
      );
    }

    _isProcessing = true;
    _eventController.add(PipelineEvent(
      stage: PipelineStage.started,
      message: 'بدء المعالجة...',
    ));

    try {
      // Stage 1: Speech to Text
      _eventController.add(PipelineEvent(
        stage: PipelineStage.stt,
        message: 'تحويل الصوت إلى نص...',
      ));
      
      final transcription = await _sttService.transcribe(audioFilePath);
      debugPrint('Transcription: $transcription');
      
      if (transcription.isEmpty) {
        _isProcessing = false;
        _eventController.add(PipelineEvent(
          stage: PipelineStage.error,
          message: 'لم يتم التعرف على أي كلام',
        ));
        return PipelineResult(
          success: false,
          error: 'No speech detected',
        );
      }

      _eventController.add(PipelineEvent(
        stage: PipelineStage.sttComplete,
        message: transcription,
      ));

      // Stage 2: LLM Processing
      _eventController.add(PipelineEvent(
        stage: PipelineStage.llm,
        message: 'معالجة الرد بالذكاء الاصطناعي...',
      ));

      final aiResponse = await _llmService.generateResponse(transcription);
      debugPrint('AI Response: $aiResponse');

      _eventController.add(PipelineEvent(
        stage: PipelineStage.llmComplete,
        message: aiResponse,
      ));

      // Stage 3: Text to Speech
      _eventController.add(PipelineEvent(
        stage: PipelineStage.tts,
        message: 'تحويل الرد إلى صوت...',
      ));

      final audioOutputPath = await _ttsService.synthesize(aiResponse);
      debugPrint('TTS output: $audioOutputPath');

      _eventController.add(PipelineEvent(
        stage: PipelineStage.ttsComplete,
        message: audioOutputPath,
      ));

      // Stage 4: Play audio to call
      _eventController.add(PipelineEvent(
        stage: PipelineStage.playing,
        message: 'إرسال الرد الصوتي...',
      ));

      await NativeCallService.playAudioToCall(audioOutputPath);

      _eventController.add(PipelineEvent(
        stage: PipelineStage.completed,
        message: 'تم الرد بنجاح',
      ));

      _isProcessing = false;
      return PipelineResult(
        success: true,
        transcription: transcription,
        aiResponse: aiResponse,
        audioPath: audioOutputPath,
      );

    } catch (e) {
      _isProcessing = false;
      _eventController.add(PipelineEvent(
        stage: PipelineStage.error,
        message: 'خطأ: ${e.toString()}',
      ));
      
      return PipelineResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  void dispose() {
    _eventController.close();
  }
}

enum PipelineStage {
  started,
  stt,
  sttComplete,
  llm,
  llmComplete,
  tts,
  ttsComplete,
  playing,
  completed,
  error,
}

class PipelineEvent {
  final PipelineStage stage;
  final String message;
  final DateTime timestamp;

  PipelineEvent({
    required this.stage,
    required this.message,
  }) : timestamp = DateTime.now();
}

class PipelineResult {
  final bool success;
  final String? transcription;
  final String? aiResponse;
  final String? audioPath;
  final String? error;

  PipelineResult({
    required this.success,
    this.transcription,
    this.aiResponse,
    this.audioPath,
    this.error,
  });
}
