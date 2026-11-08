import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/realtime_message_model.dart';
import '../providers/realtime_provider.dart';
import '../services/realtime_telemetry_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_logger.dart';

/// Практикалық жұмыс №7: Нақты уақыттағы WebSocket байланысы,
/// диспетчерлік мониторинг және логтар экраны.
class RealtimeHubScreen extends StatefulWidget {
  final bool autoConnect;
  const RealtimeHubScreen({super.key, this.autoConnect = true});

  @override
  State<RealtimeHubScreen> createState() => _RealtimeHubScreenState();
}

class _RealtimeHubScreenState extends State<RealtimeHubScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoConnect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rt = context.read<RealtimeProvider>();
        if (!rt.isConnected && !rt.isConnecting) {
          rt.connect();
        }
      });
    }
  }

  Color _statusColor(RealtimeConnectionStatus status) {
    switch (status) {
      case RealtimeConnectionStatus.connected:
        return AppColors.success;
      case RealtimeConnectionStatus.connecting:
      case RealtimeConnectionStatus.reconnecting:
        return AppColors.warning;
      case RealtimeConnectionStatus.disconnected:
      case RealtimeConnectionStatus.error:
        return AppColors.danger;
    }
  }

  String _statusTitle(RealtimeConnectionStatus status) {
    switch (status) {
      case RealtimeConnectionStatus.connected:
        return 'Байланыс орнатылды (Realtime Live)';
      case RealtimeConnectionStatus.connecting:
        return 'Серверге қосылуда...';
      case RealtimeConnectionStatus.reconnecting:
        return 'Байланысты қалпына келтіруде (Reconnecting)...';
      case RealtimeConnectionStatus.disconnected:
        return 'Байланыс үзілді (Offline)';
      case RealtimeConnectionStatus.error:
        return 'Сервер қатесі (Connection Error)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rt = context.watch<RealtimeProvider>();
    final statusColor = _statusColor(rt.status);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Realtime Диспетчерлік орталық', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text('WebSocket · Live-Data Telemetry Stream', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Жүйелік логтарды көру (Task 13)',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => _showLogsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Connection Status Banner (Tasks 7, 8, 9)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusTitle(rt.status),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rt.isConnected
                        ? 'Сервермен нақты уақыттағы екіжақты WebSocket байланысы белсенді.'
                        : 'Сервер өшірулі немесе байланыс үзілді. Авто-қайта қосылу белсенді.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  // Connection control buttons
                  Row(
                    children: [
                      if (!rt.isConnected)
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: () => rt.connect(),
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Қайта қосылу'),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                            onPressed: () => rt.simulateConnectionDrop(),
                            icon: const Icon(Icons.link_off_rounded, size: 16),
                            label: const Text('Байланысты үзу (Тест)'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Metrics Counter Bar (Tasks 5, 6)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricStat('Жіберілді (Tx)', '${rt.packetsSent} пакет', Icons.upload_rounded, AppColors.primary),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _buildMetricStat('Қабылданды (Rx)', '${rt.packetsReceived} пакет', Icons.download_rounded, AppColors.success),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _buildMetricStat('Хабарламалар', '${rt.messages.length}', Icons.chat_bubble_outline_rounded, AppColors.cyanAccent),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Quick Action Telemetry Buttons (Tasks 5)
            Text(
              'Деректерді нақты уақытта жіберу (Task 5)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: rt.isConnected
                        ? () {
                            rt.sendTelemetry(ear: 0.29, eyeOpenness: 0.95, isDrowsy: false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Қалыпты телеметрия жіберілді (EAR: 0.29)'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Қалыпты күй'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: rt.isConnected
                        ? () {
                            rt.sendTelemetry(ear: 0.17, eyeOpenness: 0.35, isDrowsy: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.warning,
                                content: Text('Ұйқы қаупі телеметриясы жіберілді!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: const Text('Ұйқы қаупі'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onPressed: rt.isConnected ? () => rt.sendSos() : null,
                  child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 4. Live Received Messages List (Task 6)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Серверден келген Live хабарламалар (Task 6)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${rt.messages.length} жазба',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (rt.messages.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 40, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'Әзірге хабарламалар жоқ.\nСерверге қосылып, телеметрия жіберіп көріңіз.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rt.messages.length,
                itemBuilder: (context, index) {
                  final msg = rt.messages[index];
                  return _buildMessageCard(msg);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMessageCard(RealtimeMessage msg) {
    Color cardColor = AppColors.surface;
    Color iconColor = AppColors.primary;
    IconData icon = Icons.info_outline_rounded;

    if (msg.level == 'danger' || msg.level == 'emergency') {
      cardColor = AppColors.danger.withValues(alpha: 0.08);
      iconColor = AppColors.danger;
      icon = Icons.warning_rounded;
    } else if (msg.level == 'warning') {
      cardColor = AppColors.warning.withValues(alpha: 0.08);
      iconColor = AppColors.warning;
      icon = Icons.report_problem_rounded;
    } else if (msg.type == 'connected') {
      iconColor = AppColors.success;
      icon = Icons.check_circle_rounded;
    }

    final time = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}:${msg.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      msg.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  msg.message.isNotEmpty ? msg.message : msg.raw.toString(),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) {
          final logs = AppLogger.getRecentLogs(limit: 60);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Қосымшаның жүйелік логтары (Task 13)',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () {
                        AppLogger.clear();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, idx) {
                      final log = logs[logs.length - 1 - idx];
                      Color c = AppColors.textPrimary;
                      if (log.level == LogLevel.error) c = AppColors.danger;
                      if (log.level == LogLevel.warning) c = AppColors.warning;
                      if (log.level == LogLevel.info) c = AppColors.primary;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          log.toString(),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: c),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
