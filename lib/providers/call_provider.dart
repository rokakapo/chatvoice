import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/call_record.dart';
import '../services/native_call_service.dart';
import '../services/ai_pipeline_service.dart';
import '../models/app_settings.dart';
import 'package:uuid/uuid.dart';

class CallProvider extends ChangeNotifier {
  String _callState = 'idle';
  String _currentCallerNumber = '';
  bool _isAutoAnswerEnabled = false;
  bool _isRecording = false;
  final List<CallRecord> _callHistory = [];
  final List<PipelineEvent> _pipelineEvents = [];
  StreamSubscription? _callEventSubscription;
  StreamSubscription? _pipelineSubscription;
  
  final AIPipelineService _pipeline = AIPipelineService();
  DateTime? _callStartTime;

  // Getters
  String get callState => _callState;
  String get currentCallerNumber => _currentCallerNumber;
  bool get isAutoAnswerEnabled => _isAutoAnswerEnabled;
  bool get isRecording => _isRecording;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);
  List<PipelineEvent> get pipelineEvents => List.unmodifiable(_pipelineEvents);
  bool get isInCall => _callState == 'active' || _callState == 'ringing';
  bool get isPipelineProcessing => _pipeline.isProcessing;

  /// Initialize call event listener
  void initialize() {
    _callEventSubscription?.cancel();
    _callEventSubscription = NativeCallService.callEvents.listen(_handleCallEvent);
    
    _pipelineSubscription?.cancel();
    _pipelineSubscription = _pipeline.events.listen(_handlePipelineEvent);
  }

  /// Update pipeline settings
  void updateSettings(AppSettings settings) {
    _pipeline.updateSettings(settings);
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
        _callState = event['state'] ?? 'idle';
        _currentCallerNumber = event['number'] ?? _currentCallerNumber;
        
        if (_callState == 'active') {
          _callStartTime = DateTime.now();
          _pipeline.resetConversation();
          _pipelineEvents.clear();
        }
        
        if (_callState == 'disconnected') {
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
        notifyListeners();
        break;

      case 'callRemoved':
        _onCallEnded();
        notifyListeners();
        break;

      case 'audioPlaybackComplete':
        debugPrint('Audio playback complete');
        notifyListeners();
        break;
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
    await NativeCallService.endCall();
    _onCallEnded();
  }

  /// Start recording
  Future<void> startRecording(String outputPath) async {
    await NativeCallService.startRecording(outputPath);
    _isRecording = true;
    notifyListeners();
  }

  /// Stop recording
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
      // Get transcription and AI response from pipeline events
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
    _pipelineEvents.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _pipelineSubscription?.cancel();
    _pipeline.dispose();
    super.dispose();
  }
}
