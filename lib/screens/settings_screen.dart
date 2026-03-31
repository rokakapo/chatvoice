import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>().settings;
    _controllers = {
      'llmKey': TextEditingController(text: s.llmApiKey),
      'llmUrl': TextEditingController(text: s.llmApiUrl),
      'llmModel': TextEditingController(text: s.llmModel),
      'sttKey': TextEditingController(text: s.sttApiKey),
      'sttUrl': TextEditingController(text: s.sttApiUrl),
      'sttModel': TextEditingController(text: s.sttModel),
      'ttsKey': TextEditingController(text: s.ttsApiKey),
      'ttsUrl': TextEditingController(text: s.ttsApiUrl),
      'ttsModel': TextEditingController(text: s.ttsModel),
      'ttsVoice': TextEditingController(text: s.ttsVoice),
      'prompt': TextEditingController(text: s.systemPrompt),
      'greeting': TextEditingController(text: s.greetingMessage),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF0D1232), Color(0xFF0A0E21)],
          ),
        ),
        child: SafeArea(
          child: Consumer<SettingsProvider>(
            builder: (context, sp, _) {
              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _configStatus(sp),
                  const SizedBox(height: 20),
                  _section('نموذج المعالجة (LLM)', Icons.psychology_rounded, AppTheme.primaryColor, [
                    _dropdown('المزود', sp.settings.llmProvider, {'openai':'OpenAI','groq':'Groq','custom':'مخصص'}, (v) => sp.setLlmProvider(v!)),
                    _field('llmKey', 'مفتاح API', 'sk-...', true, (v) => sp.setLlmApiKey(v)),
                    _field('llmUrl', 'رابط API', 'https://api.openai.com/v1/chat/completions', false, (v) => sp.setLlmApiUrl(v)),
                    _field('llmModel', 'الموديل', 'gpt-4o-mini', false, (v) => sp.setLlmModel(v)),
                    _slider('درجة الحرارة', sp.settings.temperature, 0, 2, 20, '', (v) => sp.setTemperature(v)),
                    _slider('الحد الأقصى للتوكنات', sp.settings.maxTokens.toDouble(), 50, 1000, 19, ' توكن', (v) => sp.setMaxTokens(v.toInt())),
                  ]),
                  const SizedBox(height: 14),
                  _section('تحويل الصوت لنص (STT)', Icons.mic_rounded, AppTheme.infoColor, [
                    _dropdown('المزود', sp.settings.sttProvider, {'openai_whisper':'OpenAI Whisper','groq':'Groq Whisper','custom':'مخصص'}, (v) => sp.setSttProvider(v!)),
                    _field('sttKey', 'مفتاح API (اختياري)', 'يستخدم مفتاح LLM إن كان فارغاً', true, (v) => sp.setSttApiKey(v)),
                    _field('sttUrl', 'رابط API', '', false, (v) => sp.setSttApiUrl(v)),
                    _field('sttModel', 'الموديل', 'whisper-1', false, (v) => sp.setSttModel(v)),
                    _dropdown('اللغة', sp.settings.language, {'ar':'العربية','en':'English','fr':'Français'}, (v) => sp.setLanguage(v!)),
                  ]),
                  const SizedBox(height: 14),
                  _section('تحويل النص لصوت (TTS)', Icons.record_voice_over_rounded, AppTheme.secondaryColor, [
                    _dropdown('المزود', sp.settings.ttsProvider, {'openai':'OpenAI TTS','groq':'Groq TTS','elevenlabs':'ElevenLabs','custom':'مخصص'}, (v) => sp.setTtsProvider(v!)),
                    _field('ttsKey', 'مفتاح API (اختياري)', '', true, (v) => sp.setTtsApiKey(v)),
                    _field('ttsUrl', 'رابط API', '', false, (v) => sp.setTtsApiUrl(v)),
                    _field('ttsModel', 'الموديل', 'tts-1', false, (v) => sp.setTtsModel(v)),
                    _field('ttsVoice', 'الصوت', 'alloy, echo, nova, shimmer', false, (v) => sp.setTtsVoice(v)),
                    _slider('سرعة الصوت', sp.settings.ttsSpeed, 0.25, 4, 15, 'x', (v) => sp.setTtsSpeed(v)),
                  ]),
                  const SizedBox(height: 14),
                  _section('إعدادات المكالمات', Icons.call_rounded, AppTheme.accentColor, [
                    _switchTile('الرد التلقائي', 'الرد على المكالمات تلقائياً', sp.settings.autoAnswer, (v) => sp.setAutoAnswer(v)),
                    if (sp.settings.autoAnswer)
                      _slider('تأخير الرد', sp.settings.autoAnswerDelay.toDouble(), 1, 10, 9, ' ثانية', (v) => sp.setAutoAnswerDelay(v.toInt())),
                    _switchTile('تسجيل المكالمات', 'حفظ تسجيلات المكالمات', sp.settings.recordCalls, (v) => sp.setRecordCalls(v)),
                  ]),
                  const SizedBox(height: 14),
                  _section('البرومبت والتحية', Icons.edit_note_rounded, AppTheme.warningColor, [
                    _field('prompt', 'System Prompt', 'أدخل تعليمات الذكاء الاصطناعي...', false, (v) => sp.setSystemPrompt(v), lines: 4),
                    _field('greeting', 'رسالة الترحيب', 'مرحباً، كيف يمكنني مساعدتك؟', false, (v) => sp.setGreetingMessage(v), lines: 2),
                  ]),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(children: [
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2))),
      child: const Icon(Icons.settings_rounded, color: AppTheme.primaryColor, size: 24),
    ),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('الإعدادات', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
      Text('إعداد نماذج الذكاء الاصطناعي', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
    ]),
  ]).animate().fadeIn(duration: 500.ms);

  Widget _configStatus(SettingsProvider p) {
    final ok = p.isConfigured;
    return GlassCard(
      borderColor: (ok ? AppTheme.successColor : AppTheme.warningColor).withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (ok ? AppTheme.successColor : AppTheme.warningColor).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(ok ? Icons.check_circle_rounded : Icons.warning_rounded, color: ok ? AppTheme.successColor : AppTheme.warningColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ok ? 'التطبيق مُهيأ ✓' : 'يرجى إعداد مفاتيح API', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(p.configSummary, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
      ]),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) {
    return GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(top: 8),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
          title: Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          iconColor: AppTheme.textSecondary, collapsedIconColor: AppTheme.textSecondary,
          children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _field(String key, String label, String hint, bool obscure, ValueChanged<String> onChanged, {int lines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: _controllers[key], obscureText: obscure, maxLines: lines,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14), onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 13),
          filled: true, fillColor: AppTheme.backgroundColor.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _dropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppTheme.backgroundColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: AppTheme.cardColor,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary),
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: onChanged,
        )),
      ),
    ]);
  }

  Widget _slider(String label, double value, double min, double max, int div, String suffix, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
        Text('${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$suffix', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
      ]),
      Slider(value: value, min: min, max: max, divisions: div, activeColor: AppTheme.primaryColor, inactiveColor: AppTheme.textMuted.withValues(alpha: 0.2), onChanged: onChanged),
    ]);
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
      ])),
      Switch(value: value, onChanged: onChanged),
    ]);
  }
}
