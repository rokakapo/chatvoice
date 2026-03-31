import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/call_provider.dart';
import '../providers/settings_provider.dart';
import '../services/native_call_service.dart';
import '../services/ai_pipeline_service.dart';
import '../models/call_record.dart';
import '../widgets/glass_card.dart';
import '../widgets/pulse_widget.dart';
import '../widgets/status_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF0D1232),
              Color(0xFF0A0E21),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildMainStatusCard(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildPipelineStatus(),
                const SizedBox(height: 20),
                _buildRecentActivity(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ChatVoice AI',
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
            const SizedBox(height: 4),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return Text(
                  settings.isConfigured ? 'مساعد الرد الذكي' : '⚠️ يرجى إعداد مفاتيح API',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: settings.isConfigured 
                        ? AppTheme.textSecondary 
                        : AppTheme.warningColor,
                  ),
                ).animate().fadeIn(delay: 200.ms);
              },
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.headset_mic_rounded,
            color: AppTheme.primaryColor,
            size: 28,
          ),
        ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Widget _buildMainStatusCard() {
    return Consumer2<AppProvider, CallProvider>(
      builder: (context, appProvider, callProvider, _) {
        final bool isActive = appProvider.isServiceRunning;
        final bool inCall = callProvider.isInCall;

        return GlassCard(
          gradient: inCall
              ? AppTheme.activeCallGradient
              : isActive
                  ? AppTheme.primaryGradient
                  : AppTheme.cardGradient,
          borderColor: inCall
              ? AppTheme.successColor.withValues(alpha: 0.5)
              : isActive
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
          child: Column(
            children: [
              // Status Icon with pulse
              if (inCall)
                PulseWidget(
                  color: AppTheme.successColor,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successColor.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive ? AppTheme.primaryGradient : null,
                    color: isActive ? null : AppTheme.cardColorLight,
                  ),
                  child: Icon(
                    isActive ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms),

              const SizedBox(height: 16),

              // Status text
              Text(
                inCall
                    ? 'مكالمة نشطة'
                    : isActive
                        ? 'في انتظار المكالمات...'
                        : 'الخدمة متوقفة',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              if (inCall) ...[
                const SizedBox(height: 8),
                Text(
                  callProvider.currentCallerNumber,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                StatusIndicator(
                  status: callProvider.callState,
                ),
              ],

              const SizedBox(height: 8),
              Text(
                appProvider.statusMessage,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Main action button
              if (!inCall)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _toggleService(context, appProvider, callProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppTheme.errorColor.withValues(alpha: 0.8)
                          : AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'إيقاف الخدمة' : 'تشغيل الخدمة',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              if (inCall) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildCallActionButton(
                        icon: Icons.call_end_rounded,
                        label: 'إنهاء',
                        color: AppTheme.errorColor,
                        onTap: () => callProvider.endCall(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCallActionButton(
                        icon: callProvider.isRecording 
                            ? Icons.stop_rounded 
                            : Icons.fiber_manual_record_rounded,
                        label: callProvider.isRecording ? 'إيقاف التسجيل' : 'تسجيل',
                        color: callProvider.isRecording 
                            ? AppTheme.warningColor 
                            : AppTheme.primaryColor,
                        onTap: () => _toggleRecording(callProvider),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Consumer2<CallProvider, SettingsProvider>(
      builder: (context, callProvider, settingsProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.phone_callback_rounded,
                    label: 'رد تلقائي',
                    value: callProvider.isAutoAnswerEnabled,
                    color: AppTheme.secondaryColor,
                    onToggle: (v) => callProvider.toggleAutoAnswer(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.shield_rounded,
                    label: 'تعيين كافتراضي',
                    color: AppTheme.primaryColor,
                    onTap: () => _requestDefaultDialer(),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    bool? value,
    VoidCallback? onTap,
    ValueChanged<bool>? onToggle,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (value != null)
            Switch(
              value: value,
              onChanged: onToggle,
              activeThumbColor: color,
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'تفعيل',
                  style: GoogleFonts.cairo(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<CallProvider>(
      builder: (context, callProvider, _) {
        final totalCalls = callProvider.callHistory.length;
        final aiHandled = callProvider.callHistory
            .where((c) => c.status == CallStatus.aiHandled)
            .length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.call_received_rounded,
                label: 'إجمالي المكالمات',
                value: '$totalCalls',
                color: AppTheme.infoColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.smart_toy_rounded,
                label: 'رد الذكاء الاصطناعي',
                value: '$aiHandled',
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStatus() {
    return Consumer<CallProvider>(
      builder: (context, callProvider, _) {
        if (!callProvider.isInCall && callProvider.pipelineEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معالجة الذكاء الاصطناعي',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _buildPipelineStep(
                    'تحويل الصوت إلى نص',
                    Icons.mic_rounded,
                    AppTheme.infoColor,
                    _getStageStatus(callProvider, PipelineStage.stt, PipelineStage.sttComplete),
                  ),
                  _buildDivider(),
                  _buildPipelineStep(
                    'معالجة الذكاء الاصطناعي',
                    Icons.psychology_rounded,
                    AppTheme.primaryColor,
                    _getStageStatus(callProvider, PipelineStage.llm, PipelineStage.llmComplete),
                  ),
                  _buildDivider(),
                  _buildPipelineStep(
                    'تحويل النص إلى صوت',
                    Icons.record_voice_over_rounded,
                    AppTheme.secondaryColor,
                    _getStageStatus(callProvider, PipelineStage.tts, PipelineStage.ttsComplete),
                  ),
                  _buildDivider(),
                  _buildPipelineStep(
                    'إرسال الرد',
                    Icons.volume_up_rounded,
                    AppTheme.successColor,
                    _getStageStatus(callProvider, PipelineStage.playing, PipelineStage.completed),
                  ),
                  if (callProvider.pipelineEvents.any((e) => e.stage == PipelineStage.error)) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              callProvider.pipelineEvents.firstWhere((e) => e.stage == PipelineStage.error).message,
                              style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (callProvider.pipelineEvents.any((e) => e.stage == PipelineStage.sttComplete)) ...[
                    const SizedBox(height: 16),
                    _buildMessageBubble(
                      'نص المتصل (تفويض الصوت):',
                      callProvider.pipelineEvents.lastWhere((e) => e.stage == PipelineStage.sttComplete).message,
                      Icons.person_rounded,
                      AppTheme.infoColor,
                    ),
                  ],
                  if (callProvider.pipelineEvents.any((e) => e.stage == PipelineStage.llmComplete)) ...[
                    const SizedBox(height: 8),
                    _buildMessageBubble(
                      'رد الذكاء الاصطناعي:',
                      callProvider.pipelineEvents.lastWhere((e) => e.stage == PipelineStage.llmComplete).message,
                      Icons.psychology_rounded,
                      AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 800.ms);
      },
    );
  }

  Widget _buildMessageBubble(String title, String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, height: 1.4)),
        ],
      ),
    );
  }

  String _getStageStatus(CallProvider provider, PipelineStage processing, PipelineStage complete) {
    final events = provider.pipelineEvents;
    if (events.any((e) => e.stage == complete)) return 'complete';
    if (events.any((e) => e.stage == PipelineStage.error)) return 'error'; // Priority to error
    if (events.any((e) => e.stage == processing)) return 'processing';
    return 'pending';
  }

  Widget _buildPipelineStep(String label, IconData icon, Color color, String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'complete':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'processing':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'error':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error_rounded;
        break;
      default:
        statusColor = AppTheme.textMuted;
        statusIcon = Icons.circle_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.05),
      height: 1,
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<CallProvider>(
      builder: (context, callProvider, _) {
        if (callProvider.callHistory.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'النشاط الأخير',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: AppTheme.textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا يوجد نشاط بعد',
                        style: GoogleFonts.cairo(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ستظهر المكالمات هنا عند بدء الخدمة',
                        style: GoogleFonts.cairo(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 900.ms);
        }

        final recentCalls = callProvider.callHistory.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'النشاط الأخير',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/call-log');
                  },
                  child: Text(
                    'عرض الكل',
                    style: GoogleFonts.cairo(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentCalls.map((call) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: call.status == CallStatus.aiHandled
                            ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                            : AppTheme.infoColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        call.status == CallStatus.aiHandled
                            ? Icons.smart_toy_rounded
                            : Icons.call_received_rounded,
                        color: call.status == CallStatus.aiHandled
                            ? AppTheme.secondaryColor
                            : AppTheme.infoColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.phoneNumber,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${call.duration.inMinutes}:${(call.duration.inSeconds % 60).toString().padLeft(2, '0')} دقيقة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(call.timestamp),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ).animate().fadeIn(delay: 900.ms);
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  Future<void> _toggleService(BuildContext context, AppProvider appProvider, CallProvider callProvider) async {
    if (appProvider.isServiceRunning) {
      appProvider.setServiceRunning(false);
      await callProvider.toggleAutoAnswer(false);
    } else {
      // Check permissions first
      final hasPermissions = await appProvider.checkPermissions();
      if (!hasPermissions) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'يرجى منح الصلاحيات المطلوبة',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;
      final settings = context.read<SettingsProvider>();
      if (!settings.isConfigured) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يرجى إعداد مفاتيح API أولاً', style: GoogleFonts.cairo()),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'الإعدادات',
                textColor: Colors.white,
                onPressed: () {
                  if (context.mounted) Navigator.pushNamed(context, '/settings');
                },
              ),
            ),
          );
        }
        return;
      }

      appProvider.setServiceRunning(true);
      callProvider.updateSettings(settings.settings);

      // Set as default dialer
      await NativeCallService.setDefaultDialer();
    }
  }

  void _requestDefaultDialer() async {
    await NativeCallService.setDefaultDialer();
  }

  void _toggleRecording(CallProvider callProvider) async {
    if (callProvider.isRecording) {
      final path = await callProvider.stopRecording();
      if (path != null) {
        // Process the recorded audio through AI pipeline
        await callProvider.processAudio(path);
      }
    } else {
      final recordingDir = await NativeCallService.getRecordingPath();
      final fileName = 'call_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await callProvider.startRecording('$recordingDir/$fileName');
    }
  }
}

