class CallRecord {
  final String id;
  final String phoneNumber;
  final DateTime timestamp;
  final Duration duration;
  final CallDirection direction;
  final CallStatus status;
  final String? transcription;
  final String? aiResponse;
  final String? recordingPath;

  CallRecord({
    required this.id,
    required this.phoneNumber,
    required this.timestamp,
    required this.duration,
    required this.direction,
    required this.status,
    this.transcription,
    this.aiResponse,
    this.recordingPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'phoneNumber': phoneNumber,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inSeconds,
    'direction': direction.name,
    'status': status.name,
    'transcription': transcription,
    'aiResponse': aiResponse,
    'recordingPath': recordingPath,
  };

  factory CallRecord.fromJson(Map<String, dynamic> json) => CallRecord(
    id: json['id'],
    phoneNumber: json['phoneNumber'],
    timestamp: DateTime.parse(json['timestamp']),
    duration: Duration(seconds: json['duration']),
    direction: CallDirection.values.byName(json['direction']),
    status: CallStatus.values.byName(json['status']),
    transcription: json['transcription'],
    aiResponse: json['aiResponse'],
    recordingPath: json['recordingPath'],
  );
}

enum CallDirection {
  incoming,
  outgoing,
}

enum CallStatus {
  answered,
  missed,
  rejected,
  aiHandled,
}
