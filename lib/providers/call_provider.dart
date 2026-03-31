import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/call_record.dart';
import '../services/native_call_service.dart';
import '../services/ai_pipeline_service.dart';
import '../services/tts_service.dart';
import '../models/app_settings.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class CallProvider extends ChangeNotifier {
  String _callState = 'idle';
  String _currentCallerNumber = '';
  bool _isAutoAnswerEnabled = false;
  bool _isRecording = false;
  bool _isAutoProcessing = false;
  final List<CallRecord> _callHistory = [];
  final List<PipelineEvent> _pipelineEvents = [];
  StreamSubscription? _callEventSubscription;
  StreamSubscription? _pipelineSubscription;
  Timer? _recordingTimer;
  AppSettings? _currentSettings;

  final AIPipelineService _pipeline = AIPipelineService();
  DateTime? _callStartTime;

  // Getters
  String get callState => _callState;
  String get currentCallerNumber => _currentCallerNumber;
  bool get isAutoAnswerEnabled => _isAutoAnswerEnabled;
  bool get isRecording => _isRecording;
  bool get isAutoProcessing => _isAutoProcessing;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);
  List<PipelineEvent> get pipelineEvents => List.unmodifiable(_pipelineEvents);
  bool get isInCall => _callState == 'active' || _callState == 'ringing';
  bool get isPipelineProcessing => _pipeline.isProcessing;
  bool get isPipelineReady => _pipeline.isInitialized;

  /// Duration of each recording chunk in seconds
  static const int _recordingChunkSeconds = 5;

  /// Initialize call event listener
  void initialize() {
    _callEventSubscription?.cancel();
    _callEventSubscription = NativeCallService.callEvents.listen(_handleCallEvent);

    _pipelineSubscription?.cancel();
    _pipelineSubscription = _pipeline.events.listen(_handlePipelineEvent);
  }

  /// Update pipeline settings
  void updateSettings(AppSettings settings) {
    _currentSettings = settings;
    _pipeline.updateSettings(settings);
    debugPrint('Pipeline settings updated - isInitialized: ${_pipeline.isInitialized}');
    notifyListeners();
  }

  /// Handle native call events
  void _handleCallEvent(Map<String, dynamic> event) {
    final eventType = event['event'] as String?;
    debugPrint('Call event: $eventType - $event');

    switch (eventType) {
      case 'incomingCall':
        _callState = 'ringing';
        _currentCallerNumber = event['number'] ?? 'Unknown';
        notifyListeners();
        break;

      case 'callStateChanged':
        final prevState = _callState;
        _callState = event['state'] ?? 'idle';
        _currentCallerNumber = event['number'] ?? _currentCallerNumber;

        if (_callState == 'active' && prevState != 'active') {
          _callStartTime = DateTime.now();
          _pipeline.resetConversation();
          _pipelineEvents.clear();
          // Start automatic AI processing loop
          _startAutoProcessingLoop();
        }

        if (_callState == 'disconnected') {
          _stopAutoProcessingLoop();
          _onCallEnded();
        }
        notifyListeners();
        break;

      case 'callAutoAnswered':
        _callState = 'active';
        _currentCallerNumber = event['number'] ?? _currentCallerNumber;
        _callStartTime = DateTime.now();
        _pipeline.resetConversation();
        _pipelineEvents.clear();
        _startAutoProcessingLoop();
        notifyListeners();
        break;

      case 'callRemoved':
        _stopAutoProcessingLoop();
        _onCallEnded();
        notifyListeners();
        break;

      case 'audioPlaybackComplete':
        debugPrint('Audio playback complete - starting next recording chunk');
        // Start next recording cycle after playback completes
        if (_callState == 'active' && _isAutoProcessing) {
          _startRecordingChunk();
        }
        notifyListeners();
        break;
    }
  }

  /// Start the automatic AI processing loop
  void _startAutoProcessingLoop() {
    if (_isAutoProcessing) return;
    
    // If pipeline not initialized but we have cached settings, try to re-init
    if (!_pipeline.isInitialized) {
      if (_currentSettings != null) {
        debugPrint('Pipeline not initialized - re-initializing from cached settings');
        _pipeline.updateSettings(_currentSettings!);
      }
    }
    
    if (!_pipeline.isInitialized) {
      debugPrint('Pipeline not initialized - cannot start auto processing');
      _pipelineEvents.add(PipelineEvent(
        stage: PipelineStage.error,
        message: 'يرجى إعداد مفاتيح API وتشغيل الخدمة أولاً',
      ));
      notifyListeners();
      return;
    }

    _isAutoProcessing = true;
    debugPrint('Starting automatic AI processing loop');

    // Play greeting first, then start listen/process loop
    _playGreetingThenListen();

    notifyListeners();
  }

  /// Play the greeting message via TTS first, then start listening
  Future<void> _playGreetingThenListen() async {
    if (_currentSettings == null) {
      // No greeting configured, start listening directly
      await Future.delayed(const Duration(seconds: 1));
      if (_callState == 'active' && _isAutoProcessing) _startRecordingChunk();
      return;
    }

    final greetingText = _currentSettings!.greetingMessage;
    if (greetingText.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      if (_callState == 'active' && _isAutoProcessing) _startRecordingChunk();
      return;
    }

    try {
      debugPrint('Auto: Synthesizing greeting: $greetingText');
      final tts = TTSService(_currentSettings!);
      final audioPath = await tts.synthesize(greetingText);
      debugPrint('Auto: Playing greeting audio');
      await NativeCallService.playAudioToCall(audioPath);
      // Next chunk will start after audioPlaybackComplete event
    } catch (e) {
      debugPrint('Greeting error: $e - starting listen loop anyway');
      await Future.delayed(const Duration(seconds: 1));
      if (_callState == 'active' && _isAutoProcessing) _startRecordingChunk();
    }
  }

  /// Stop the automatic processing loop
  void _stopAutoProcessingLoop() {
    _isAutoProcessing = false;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    debugPrint('Auto AI processing loop stopped');
  }

  /// Record a chunk then process it through the AI pipeline
  Future<void> _startRecordingChunk() async {
    if (!_isAutoProcessing || _callState != 'active') return;
    if (_isRecording || _pipeline.isProcessing) {
      debugPrint('Skipping chunk - already recording or processing');
      return;
    }

    try {
      // Generate recording path
      final dir = await getTemporaryDirectory();
      final recordingsDir = Directory('${dir.path}/call_recordings');
      if (!recordingsDir.existsSync()) {
        recordingsDir.createSync(recursive: true);
      }
      final filePath = '${recordingsDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      debugPrint('Auto: Starting recording chunk → $filePath');
      await NativeCallService.startRecording(filePath);
      _isRecording = true;
      notifyListeners();

      // Record for the configured chunk duration
      _recordingTimer = Timer(const Duration(seconds: _recordingChunkSeconds), () async {
        if (!_isAutoProcessing || _callState != 'active') {
          // Call ended during recording
          await NativeCallService.stopRecording();
          _isRecording = false;
          notifyListeners();
          return;
        }

        // Stop recording
        debugPrint('Auto: Stopping recording chunk');
        final recordedPath = await NativeCallService.stopRecording();
        _isRecording = false;
        notifyListeners();

        if (recordedPath != null && recordedPath.isNotEmpty) {
          // Process through AI pipeline (STT → LLM → TTS → Play)
          debugPrint('Auto: Processing chunk through AI pipeline: $recordedPath');
          await processAudio(recordedPath);
          // Next chunk starts after audioPlaybackComplete event
          // (handled in _handleCallEvent case 'audioPlaybackComplete')
          // But if pipeline had no speech detected, start next chunk now
          if (_isAutoProcessing && _callState == 'active' && !_pipeline.isProcessing) {
            final lastEvent = _pipelineEvents.isNotEmpty ? _pipelineEvents.last : null;
            if (lastEvent?.stage == PipelineStage.error) {
              // Error or no speech - try again after 1s
              await Future.delayed(const Duration(seconds: 1));
              _startRecordingChunk();
            }
          }
        } else {
          // No file recorded, retry after delay
          debugPrint('Auto: No recording file, retrying in 2s');
          await Future.delayed(const Duration(seconds: 2));
          if (_isAutoProcessing && _callState == 'active') {
            _startRecordingChunk();
          }
        }
      });
    } catch (e) {
      debugPrint('Auto processing error: $e');
      _isRecording = false;
      notifyListeners();
      // Retry after error
      await Future.delayed(const Duration(seconds: 2));
      if (_isAutoProcessing && _callState == 'active') {
        _startRecordingChunk();
      }
    }
  }

  /// Handle pipeline events
  void _handlePipelineEvent(PipelineEvent event) {
    _pipelineEvents.add(event);
    notifyListeners();
  }

  /// Process recorded audio through AI pipeline
  Future<PipelineResult> processAudio(String audioFilePath) async {
    final result = await _pipeline.processAudioChunk(audioFilePath);
    notifyListeners();
    return result;
  }

  /// Answer current call
  Future<void> answerCall() async {
    await NativeCallService.answerCall();
    _callState = 'active';
    _callStartTime = DateTime.now();
    notifyListeners();
  }

  /// Reject current call
  Future<void> rejectCall() async {
    await NativeCallService.rejectCall();
    _callState = 'idle';
    notifyListeners();
  }

  /// End current call
  Future<void> endCall() async {
    _stopAutoProcessingLoop();
    await NativeCallService.endCall();
    _onCallEnded();
  }

  /// Start recording (manual)
  Future<void> startRecording(String outputPath) async {
    await NativeCallService.startRecording(outputPath);
    _isRecording = true;
    notifyListeners();
  }

  /// Stop recording (manual)
  Future<String?> stopRecording() async {
    final path = await NativeCallService.stopRecording();
    _isRecording = false;
    notifyListeners();
    return path;
  }

  /// Toggle auto answer
  Future<void> toggleAutoAnswer(bool enabled) async {
    _isAutoAnswerEnabled = enabled;
    await NativeCallService.setAutoAnswer(enabled);
    notifyListeners();
  }

  /// Called when a call ends
  void _onCallEnded() {
    final duration = _callStartTime != null
        ? DateTime.now().difference(_callStartTime!)
        : Duration.zero;

    if (_currentCallerNumber.isNotEmpty && _callStartTime != null) {
      String? transcription;
      String? aiResponse;

      for (final event in _pipelineEvents) {
        if (event.stage == PipelineStage.sttComplete) {
          transcription = '${transcription ?? ''}${event.message}\n';
        } else if (event.stage == PipelineStage.llmComplete) {
          aiResponse = '${aiResponse ?? ''}${event.message}\n';
        }
      }

      _callHistory.insert(0, CallRecord(
        id: const Uuid().v4(),
        phoneNumber: _currentCallerNumber,
        timestamp: _callStartTime!,
        duration: duration,
        direction: CallDirection.incoming,
        status: _pipelineEvents.isNotEmpty ? CallStatus.aiHandled : CallStatus.answered,
        transcription: transcription?.trim(),
        aiResponse: aiResponse?.trim(),
      ));
    }

    _callState = 'idle';
    _currentCallerNumber = '';
    _callStartTime = null;
    _isRecording = false;
    _isAutoProcessing = false;
    _pipelineEvents.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _callEventSubscription?.cancel();
    _pipelineSubscription?.cancel();
    _pipeline.dispose();
    super.dispose();
  }
}
