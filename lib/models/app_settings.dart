class AppSettings {
  // STT Settings
  String sttProvider; // 'openai_whisper', 'google', 'custom'
  String sttApiKey;
  String sttApiUrl;
  String sttModel;
  
  // LLM Settings
  String llmProvider; // 'openai', 'groq', 'custom'
  String llmApiKey;
  String llmApiUrl;
  String llmModel;
  String systemPrompt;
  double temperature;
  int maxTokens;
  
  // TTS Settings
  String ttsProvider; // 'openai', 'elevenlabs', 'custom'
  String ttsApiKey;
  String ttsApiUrl;
  String ttsModel;
  String ttsVoice;
  double ttsSpeed;
  
  // Call Settings
  bool autoAnswer;
  int autoAnswerDelay; // seconds
  bool recordCalls;
  String language;
  
  // Greeting
  String greetingMessage;

  AppSettings({
    this.sttProvider = 'groq',
    this.sttApiKey = '',
    this.sttApiUrl = 'https://api.groq.com/openai/v1/audio/transcriptions',
    this.sttModel = 'whisper-large-v3-turbo',
    this.llmProvider = 'groq',
    this.llmApiKey = '',
    this.llmApiUrl = 'https://api.groq.com/openai/v1/chat/completions',
    this.llmModel = 'llama-3.3-70b-versatile',
    this.systemPrompt = 'أنت مساعد ذكي للرد على المكالمات الهاتفية. رد بشكل مهذب ومختصر باللغة العربية. اسأل عن سبب الاتصال وقدم المساعدة المطلوبة.',
    this.temperature = 0.7,
    this.maxTokens = 150,
    this.ttsProvider = 'groq',
    this.ttsApiKey = '',
    this.ttsApiUrl = 'https://api.groq.com/openai/v1/audio/speech',
    this.ttsModel = 'canopylabs/orpheus-arabic-saudi',
    this.ttsVoice = 'fahad',
    this.ttsSpeed = 1.0,
    this.autoAnswer = false,
    this.autoAnswerDelay = 3,
    this.recordCalls = true,
    this.language = 'ar',
    this.greetingMessage = 'مرحباً، كيف يمكنني مساعدتك؟',
  });

  Map<String, dynamic> toJson() => {
    'sttProvider': sttProvider,
    'sttApiKey': sttApiKey,
    'sttApiUrl': sttApiUrl,
    'sttModel': sttModel,
    'llmProvider': llmProvider,
    'llmApiKey': llmApiKey,
    'llmApiUrl': llmApiUrl,
    'llmModel': llmModel,
    'systemPrompt': systemPrompt,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'ttsProvider': ttsProvider,
    'ttsApiKey': ttsApiKey,
    'ttsApiUrl': ttsApiUrl,
    'ttsModel': ttsModel,
    'ttsVoice': ttsVoice,
    'ttsSpeed': ttsSpeed,
    'autoAnswer': autoAnswer,
    'autoAnswerDelay': autoAnswerDelay,
    'recordCalls': recordCalls,
    'language': language,
    'greetingMessage': greetingMessage,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    sttProvider: json['sttProvider'] ?? 'groq',
    sttApiKey: json['sttApiKey'] ?? '',
    sttApiUrl: json['sttApiUrl'] ?? 'https://api.groq.com/openai/v1/audio/transcriptions',
    sttModel: json['sttModel'] ?? 'whisper-large-v3-turbo',
    llmProvider: json['llmProvider'] ?? 'groq',
    llmApiKey: json['llmApiKey'] ?? '',
    llmApiUrl: json['llmApiUrl'] ?? 'https://api.groq.com/openai/v1/chat/completions',
    llmModel: json['llmModel'] ?? 'llama-3.3-70b-versatile',
    systemPrompt: json['systemPrompt'] ?? 'أنت مساعد ذكي للرد على المكالمات الهاتفية.',
    temperature: (json['temperature'] ?? 0.7).toDouble(),
    maxTokens: json['maxTokens'] ?? 150,
    ttsProvider: json['ttsProvider'] ?? 'groq',
    ttsApiKey: json['ttsApiKey'] ?? '',
    ttsApiUrl: json['ttsApiUrl'] ?? 'https://api.groq.com/openai/v1/audio/speech',
    ttsModel: json['ttsModel'] ?? 'canopylabs/orpheus-arabic-saudi',
    ttsVoice: json['ttsVoice'] ?? 'fahad',
    ttsSpeed: (json['ttsSpeed'] ?? 1.0).toDouble(),
    autoAnswer: json['autoAnswer'] ?? false,
    autoAnswerDelay: json['autoAnswerDelay'] ?? 3,
    recordCalls: json['recordCalls'] ?? true,
    language: json['language'] ?? 'ar',
    greetingMessage: json['greetingMessage'] ?? 'مرحباً، كيف يمكنني مساعدتك؟',
  );
}
