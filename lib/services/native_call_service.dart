import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeCallService {
  static const MethodChannel _methodChannel = MethodChannel('com.chatvoice/call_control');
  static const EventChannel _eventChannel = EventChannel('com.chatvoice/call_events');

  static Stream<Map<String, dynamic>>? _callEventStream;

  /// Get the call events stream
  static Stream<Map<String, dynamic>> get callEvents {
    _callEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _callEventStream!;
  }

  /// Request call handling permissions
  static Future<bool> requestCallPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestCallPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting permissions: ${e.message}');
      return false;
    }
  }

  /// Set app as default dialer
  static Future<bool> setDefaultDialer() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('setDefaultDialer');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error setting default dialer: ${e.message}');
      return false;
    }
  }

  /// Request call screening role
  static Future<bool> requestCallScreeningRole() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestCallScreeningRole');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting screening role: ${e.message}');
      return false;
    }
  }

  /// Check if app is default dialer
  static Future<bool> isDefaultDialer() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isDefaultDialer');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking default dialer: ${e.message}');
      return false;
    }
  }

  /// Answer the current call
  static Future<bool> answerCall() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('answerCall');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error answering call: ${e.message}');
      return false;
    }
  }

  /// Reject the current call
  static Future<bool> rejectCall() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('rejectCall');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error rejecting call: ${e.message}');
      return false;
    }
  }

  /// End the current call
  static Future<bool> endCall() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('endCall');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error ending call: ${e.message}');
      return false;
    }
  }

  /// Play audio file to the call
  static Future<bool> playAudioToCall(String audioPath) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'playAudioToCall',
        {'audioPath': audioPath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error playing audio: ${e.message}');
      return false;
    }
  }

  /// Start recording the call
  static Future<bool> startRecording(String outputPath) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'startRecording',
        {'outputPath': outputPath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error starting recording: ${e.message}');
      return false;
    }
  }

  /// Stop recording and return the file path
  static Future<String?> stopRecording() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('stopRecording');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error stopping recording: ${e.message}');
      return null;
    }
  }

  /// Get current call state
  static Future<String> getCallState() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('getCallState');
      return result ?? 'idle';
    } on PlatformException catch (e) {
      debugPrint('Error getting call state: ${e.message}');
      return 'idle';
    }
  }

  /// Set auto answer mode
  static Future<bool> setAutoAnswer(bool enabled) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'setAutoAnswer',
        {'enabled': enabled},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error setting auto answer: ${e.message}');
      return false;
    }
  }

  /// Get recording directory path
  static Future<String> getRecordingPath() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('getRecordingPath');
      return result ?? '';
    } on PlatformException catch (e) {
      debugPrint('Error getting recording path: ${e.message}');
      return '';
    }
  }
}
