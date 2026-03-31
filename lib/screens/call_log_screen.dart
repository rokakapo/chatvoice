import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/call_provider.dart';
import '../models/call_record.dart';
import '../widgets/glass_card.dart';

class CallLogScreen extends StatelessWidget {
  const CallLogScreen({super.key});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('سجل المكالمات', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('جميع المكالمات المعالجة', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
                  ]),
                ]).animate().fadeIn(duration: 500.ms),
              ),
              Expanded(
                child: Consumer<CallProvider>(
                  builder: (context, callProvider, _) {
                    if (callProvider.callHistory.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_missed_rounded, color: AppTheme.textMuted, size: 64),
                            const SizedBox(height: 16),
                            Text('لا توجد مكالمات بعد', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),
                            Text('ستظهر المكالمات هنا عند الرد عليها', style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textMuted)),
                          ],
                        ).animate().fadeIn(delay: 300.ms),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: callProvider.callHistory.length,
                      itemBuilder: (context, index) {
                        final call = callProvider.callHistory[index];
                        return _buildCallItem(context, call, index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallItem(BuildContext context, CallRecord call, int index) {
    final isAI = call.status == CallStatus.aiHandled;
    final color = isAI ? AppTheme.secondaryColor : AppTheme.infoColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(isAI ? Icons.smart_toy_rounded : Icons.call_received_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(call.phoneNumber, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('${call.duration.inMinutes}:${(call.duration.inSeconds % 60).toString().padLeft(2, '0')}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(isAI ? 'رد ذكي' : 'مُجاب', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  ),
                ]),
              ])),
              Text(_formatDate(call.timestamp), style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
            ]),
            if (call.transcription != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.backgroundColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.hearing_rounded, size: 14, color: AppTheme.infoColor),
                    const SizedBox(width: 6),
                    Text('ما قاله المتصل:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.infoColor)),
                  ]),
                  const SizedBox(height: 4),
                  Text(call.transcription!, style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ],
            if (call.aiResponse != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.smart_toy_rounded, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text('رد الذكاء الاصطناعي:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                  ]),
                  const SizedBox(height: 4),
                  Text(call.aiResponse!, style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.05);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return '${dt.day}/${dt.month}';
  }
}
