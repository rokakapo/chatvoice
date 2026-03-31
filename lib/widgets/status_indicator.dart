import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final String status;

  const StatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'ringing':
        color = AppTheme.warningColor;
        label = 'مكالمة واردة';
        icon = Icons.ring_volume_rounded;
        break;
      case 'active':
        color = AppTheme.successColor;
        label = 'مكالمة نشطة';
        icon = Icons.call_rounded;
        break;
      case 'holding':
        color = AppTheme.infoColor;
        label = 'في الانتظار';
        icon = Icons.pause_circle_rounded;
        break;
      case 'dialing':
        color = AppTheme.primaryColor;
        label = 'جاري الاتصال';
        icon = Icons.phone_forwarded_rounded;
        break;
      case 'disconnected':
        color = AppTheme.errorColor;
        label = 'تم الإنهاء';
        icon = Icons.call_end_rounded;
        break;
      default:
        color = AppTheme.textMuted;
        label = 'غير نشط';
        icon = Icons.phone_disabled_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
