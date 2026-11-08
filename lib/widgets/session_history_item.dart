import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../utils/app_colors.dart';

class SessionHistoryItem extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;

  const SessionHistoryItem({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy, HH:mm');
    final formattedDate = dateFormat.format(session.startTime);

    Color scoreColor;
    Color scoreBg;
    if (session.safetyScore >= 90) {
      scoreColor = AppColors.success;
      scoreBg = const Color(0xFFECFDF5);
    } else if (session.safetyScore >= 75) {
      scoreColor = AppColors.warning;
      scoreBg = const Color(0xFFFFFBEB);
    } else {
      scoreColor = AppColors.danger;
      scoreBg = const Color(0xFFFEF2F2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сапар (${session.duration.inHours} сағ ${session.duration.inMinutes.remainder(60)} мин)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            session.drowsinessAlerts == 0
                                ? Icons.verified_user_rounded
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: session.drowsinessAlerts == 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            session.drowsinessAlerts == 0
                                ? 'Дабыл орын алмады'
                                : '${session.drowsinessAlerts} рет ұйқы дабылы',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: session.drowsinessAlerts == 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${session.safetyScore.toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        session.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
