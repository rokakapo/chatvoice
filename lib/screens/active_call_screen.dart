import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/call_provider.dart';
import '../services/ai_pipeline_service.dart';
import '../services/native_call_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/pulse_widget.dart';

class ActiveCallScreen extends StatefulWidget {
  const ActiveCallScreen({super.key});
  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1A10), Color(0xFF0A0E21), Color(0xFF0A0E21)],
          ),
        ),
        child: SafeArea(
          child: Consumer<CallProvider>(
            builder: (context, callProvider, _) {
              return Column(
                children: [
                  const SizedBox(height: 40),
                  // Caller info
                  PulseWidget(
                    color: AppTheme.successColor,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.activeCallGradient,
                        boxShadow: [BoxShadow(color: AppTheme.successColor.withValues(alpha: 0.3), blurRadius: 30)],
                      ),
                      child: const Icon(Icons.call_rounded, color: Colors.white, size: 48),
                    ),
                  ).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms),
                  const SizedBox(height: 24),
                  Text(callProvider.currentCallerNumber.isEmpty ? 'مكالمة واردة' : callProvider.currentCallerNumber,
                    style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_getStateText(callProvider.callState),
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                  ),
                  const SizedBox(height: 32),
                  // Pipeline events
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildPipelineLog(callProvider),
                    ),
                  ),
                  // Call actions
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (callProvider.callState == 'ringing') ...[
                          _callButton(Icons.call_rounded, 'رد', AppTheme.successColor, () => callProvider.answerCall()),
                          _callButton(Icons.call_end_rounded, 'رفض', AppTheme.errorColor, () => callProvider.rejectCall()),
                        ] else ...[
                          _callButton(
                            callProvider.isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
                            callProvider.isRecording ? 'إيقاف' : 'تسجيل',
                            callProvider.isRecording ? AppTheme.warningColor : AppTheme.primaryColor,
                            () => _toggleRecording(callProvider),
                          ),
                          _callButton(Icons.call_end_rounded, 'إنهاء', AppTheme.errorColor, () {
                            callProvider.endCall();
                            Navigator.pop(context);
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineLog(CallProvider provider) {
    if (provider.pipelineEvents.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.psychology_rounded, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('في انتظار المعالجة...', style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 4),
          Text('سجل ثم أوقف التسجيل لمعالجة الصوت', style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: provider.pipelineEvents.length,
      itemBuilder: (context, index) {
        final event = provider.pipelineEvents[index];
        return _buildEventItem(event).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
      },
    );
  }

  Widget _buildEventItem(PipelineEvent event) {
    Color color; IconData icon;
    switch (event.stage) {
      case PipelineStage.stt: case PipelineStage.sttComplete:
        color = AppTheme.infoColor; icon = Icons.mic_rounded; break;
      case PipelineStage.llm: case PipelineStage.llmComplete:
        color = AppTheme.primaryColor; icon = Icons.psychology_rounded; break;
      case PipelineStage.tts: case PipelineStage.ttsComplete:
        color = AppTheme.secondaryColor; icon = Icons.record_voice_over_rounded; break;
      case PipelineStage.playing: case PipelineStage.completed:
        color = AppTheme.successColor; icon = Icons.volume_up_rounded; break;
      case PipelineStage.error:
        color = AppTheme.errorColor; icon = Icons.error_rounded; break;
      default:
        color = AppTheme.textSecondary; icon = Icons.info_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(event.message, style: GoogleFonts.cairo(fontSize: 13, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _callButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)]),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  String _getStateText(String state) {
    switch (state) {
      case 'ringing': return '📞 مكالمة واردة...';
      case 'active': return '🟢 مكالمة نشطة';
      case 'holding': return '⏸️ في الانتظار';
      default: return state;
    }
  }

  void _toggleRecording(CallProvider callProvider) async {
    if (callProvider.isRecording) {
      final path = await callProvider.stopRecording();
      if (path != null) {
        await callProvider.processAudio(path);
      }
    } else {
      final recordingDir = await NativeCallService.getRecordingPath();
      final fileName = 'call_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await callProvider.startRecording('$recordingDir/$fileName');
    }
  }
}
