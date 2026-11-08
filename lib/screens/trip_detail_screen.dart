import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';

class TripDetailScreen extends StatelessWidget {
  final SessionModel session;

  const TripDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final minutes = session.duration.inMinutes.remainder(60);
    final hours = session.duration.inHours;
    final durationStr = '$hours с $minutes мин';

    final Color statusColor = session.status == 'Қауіпсіз'
        ? AppColors.success
        : (session.status == 'Орташа' ? AppColors.warning : AppColors.danger);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Сапар қорытындысы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Сапар есебі бөлісуге дайындалды')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: session.safetyScore / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.borderLight,
                            valueColor: AlwaysStoppedAnimation(statusColor),
                          ),
                        ),
                        Text(
                          '${session.safetyScore.toInt()}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              session.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Қауіпсіздік рейтингі',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ұзақтығы: $durationStr',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Телеметрия және көрсеткіштер',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 4 Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.timer_outlined,
                      label: 'Жалпы сапар',
                      value: durationStr,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.notification_important_rounded,
                      label: 'Қауіп дабылы',
                      value: '${session.drowsinessAlerts} рет',
                      color: session.drowsinessAlerts > 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.face_rounded,
                      label: 'Есінеу саны',
                      value: '${session.yawnsDetected} рет',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.remove_red_eye_outlined,
                      label: 'Орташа EAR',
                      value: '0.31 (Норма)',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Сапар барысындағы назар деңгейі',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Simulated Alertness Timeline Chart Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Көз ашықтығы динамикасы (EAR)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Орташа 96%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bar chart visualizer
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildChartBar(0.9, '10m', AppColors.primary),
                        _buildChartBar(0.85, '20m', AppColors.primary),
                        _buildChartBar(0.95, '30m', AppColors.primary),
                        _buildChartBar(
                            session.drowsinessAlerts > 0 ? 0.35 : 0.88,
                            '40m',
                            session.drowsinessAlerts > 0
                                ? AppColors.danger
                                : AppColors.primary),
                        _buildChartBar(0.92, '50m', AppColors.primary),
                        _buildChartBar(0.86, '1h', AppColors.primary),
                        _buildChartBar(0.91, '1h15m', AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Қалыпты деңгей',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Қауіпті нүкте',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: 'PDF есепті жүктеп алу',
                icon: Icons.picture_as_pdf_rounded,
                isOutlined: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text('Сапар есебі PDF форматында сақталды!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(double heightFraction, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 90 * heightFraction,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
