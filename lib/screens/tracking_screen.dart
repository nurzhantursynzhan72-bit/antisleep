import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../models/alert_event_model.dart';
import '../models/session_model.dart';
import '../providers/camera_provider.dart';
import '../services/ai_detection_service.dart';
import '../services/database_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import 'alarm_screen.dart';
import 'trip_detail_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  final AIDetectionService _aiService = AIDetectionService();
  StreamSubscription<AIDetectionMetrics>? _metricsSubscription;
  AIDetectionMetrics? _latestMetrics;

  late AnimationController _alarmPulseController;
  late Animation<double> _alarmFlash;

  @override
  void initState() {
    super.initState();
    _alarmPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    _alarmFlash = Tween<double>(begin: 0.1, end: 0.85).animate(_alarmPulseController);

    // Камера рұқсатын сұрау (Практикалық №6: Task 13)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cam = context.read<CameraProvider>();
      if (cam.permissionState == CameraPermissionState.initial) {
        cam.requestCameraPermission();
      }
    });

    _aiService.startTracking();
    _metricsSubscription = _aiService.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _latestMetrics = metrics;
        });
      }
    });
  }

  @override
  void dispose() {
    _metricsSubscription?.cancel();
    _aiService.stopTracking();
    _alarmPulseController.dispose();
    super.dispose();
  }

  void _stopAndFinish() async {
    _aiService.stopTracking();
    final dur = _latestMetrics?.activeDuration ?? const Duration(minutes: 35);
    final alertCount = _latestMetrics?.alarmCount ?? 0;
    final sessionId = 'sess-${DateTime.now().millisecondsSinceEpoch}';
    final finalSession = SessionModel(
      id: sessionId,
      userId: 'usr-789',
      vehicleId: 'veh-001',
      startTime: DateTime.now().subtract(dur),
      endTime: DateTime.now(),
      duration: dur,
      drowsinessAlerts: alertCount,
      yawnsDetected: alertCount > 0 ? 3 : 1,
      safetyScore: alertCount > 0 ? 84.0 : 96.0,
      status: alertCount > 0 ? 'Орташа' : 'Қауіпсіз',
      notes: 'AntiSleep AI автоматты жазылған сапар',
    );

    try {
      await DatabaseService.instance.insertSession(finalSession);
      if (alertCount > 0) {
        await DatabaseService.instance.insertAlertEvent(
          AlertEventModel(
            id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
            sessionId: sessionId,
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
            alertType: 'microsleep',
            earValue: 0.16,
            actionTaken: 'Төтенше сирена ойнатылды',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving tracking session to DB: $e');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TripDetailScreen(session: finalSession),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlarm = _latestMetrics?.isAlarmActive ?? false;
    final duration = _latestMetrics?.activeDuration ?? Duration.zero;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final formattedTime = '${duration.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';

    final ear = _latestMetrics?.earRatio ?? 0.31;
    final eyePercent = ((_latestMetrics?.eyeOpenness ?? 0.95) * 100).toInt();

    final camera = context.watch<CameraProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Feed / AI Face Mesh Overlay
          if (camera.cameraController != null &&
              camera.cameraController!.value.isInitialized &&
              !camera.isSimulationMode)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: camera.cameraController!.value.previewSize?.height ?? 1,
                  height: camera.cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(camera.cameraController!),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

          // Face Alignment & Eye Point HUD Overlay
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Face alignment target guide oval
                Container(
                  width: 250,
                  height: 330,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(160),
                    border: Border.all(
                      color: isAlarm
                          ? AppColors.danger
                          : AppColors.primary.withValues(alpha: 0.8),
                      width: 2.5,
                    ),
                  ),
                ),

                // Center Face icon simulation
                Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 140,
                  color: isAlarm
                      ? AppColors.danger.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
                ),

                // Target crosshairs
                Positioned(
                  top: 130,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildEyePoint(isAlarm ? 'Жабық' : 'Ашық', isAlarm),
                      const SizedBox(width: 50),
                      _buildEyePoint(isAlarm ? 'Жабық' : 'Ашық', isAlarm),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Red emergency flash overlay when alarm is active
          if (isAlarm)
            AnimatedBuilder(
              animation: _alarmFlash,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: AppColors.danger.withValues(alpha: _alarmFlash.value * 0.4),
                );
              },
            ),

          // Safe Top HUD Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAlarm
                          ? AppColors.danger
                          : Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAlarm ? Colors.white : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isAlarm ? Colors.white : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAlarm ? 'ҚАУІП: ҰЙҚЫ ДАБЫЛЫ' : 'AI БАҚЫЛАУДА',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Duration Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Camera Permission Tester Icon (Task 15)
                  IconButton(
                    tooltip: 'Камера рұқсатын тексеру (Task 15)',
                    icon: Icon(
                      camera.isPermissionGranted
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      color: camera.isPermissionGranted
                          ? AppColors.success
                          : AppColors.danger,
                      size: 24,
                    ),
                    onPressed: () => _showCameraPermissionDialog(context, camera),
                  ),
                ],
              ),
            ),
          ),

          // ⚠️ Permission Denied UI Overlay (Task 15)
          if (camera.isPermissionDenied)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.90),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.danger, width: 2),
                      ),
                      child: const Icon(
                        Icons.videocam_off_rounded,
                        size: 60,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Камераға рұқсат берілмеді',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'AntiSleep AI жүргізушінің шаршауын және көздің жұмылуын бақылау үшін камераға рұқсатты қажет етеді.\nҚұрылғыдан рұқсат беріңіз немесе симуляциялық сынақ режимін қосыңыз.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    CustomButton(
                      text: 'Камера рұқсатын сұрау',
                      onPressed: () => camera.requestCameraPermission(),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Сынақ режимін қосу (Симуляция)',
                      isOutlined: true,
                      onPressed: () => camera.simulatePermissionGranted(),
                    ),
                  ],
                ),
              ),
            ),

          // Prominent Alarm Banner (when sleepy)
          if (isAlarm)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ОЯНЫҢЫЗ!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.danger,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Көзіңіздің ұзақ жұмылуы анықталды. Қауіпсіз жерге тоқтап, демалыңыз!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'ОЯНДЫМ / ДАБЫЛДЫ ТОҚТАТУ',
                      backgroundColor: AppColors.danger,
                      onPressed: () {
                        _aiService.dismissAlarm();
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Control Panel
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real-time Telemetry Dashboard Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCol('Көз ашылуы', '$eyePercent%', AppColors.primary),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _buildMetricCol('EAR қатынасы', ear.toStringAsFixed(2),
                          ear < 0.22 ? AppColors.danger : AppColors.success),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _buildMetricCol(
                          'Дабыл саны', '${_latestMetrics?.alarmCount ?? 0}', AppColors.danger),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    // Test simulate button
                    Expanded(
                      flex: 4,
                      child: CustomButton(
                        text: 'Сынақ (Ұйқыны ойнату)',
                        height: 48,
                        backgroundColor: const Color(0xFF1E293B),
                        textColor: Colors.white,
                        icon: Icons.science_rounded,
                        onPressed: () {
                          _aiService.simulateDrowsiness();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AlarmScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Stop tracking button
                    Expanded(
                      flex: 3,
                      child: CustomButton(
                        text: 'Сапарды тоқтату',
                        height: 48,
                        backgroundColor: AppColors.danger,
                        textColor: Colors.white,
                        onPressed: _stopAndFinish,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEyePoint(String status, bool isAlarm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlarm ? AppColors.danger : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showCameraPermissionDialog(BuildContext context, CameraProvider camera) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Камера және рұқсат баптаулары',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Практикалық жұмыс №6 (15-тапсырма): рұқсат берілген және берілмеген жағдайларды тексеру:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.success),
              title: const Text('Рұқсат берілген күй (Granted)'),
              subtitle: const Text('Камера видеоағыны / AI Face Mesh қосылады'),
              trailing: camera.isPermissionGranted
                  ? const Icon(Icons.radio_button_checked, color: AppColors.primary)
                  : const Icon(Icons.radio_button_off),
              onTap: () {
                camera.simulatePermissionGranted();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_rounded, color: AppColors.danger),
              title: const Text('Рұқсат берілмеген күй (Denied)'),
              subtitle: const Text('Қате туралы хабарлама мен рұқсат сұрау баннері шығады'),
              trailing: camera.isPermissionDenied
                  ? const Icon(Icons.radio_button_checked, color: AppColors.danger)
                  : const Icon(Icons.radio_button_off),
              onTap: () {
                camera.simulatePermissionDenied();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
              title: const Text('Құрылғыдан рұқсатты нақты сұрау'),
              subtitle: const Text('availableCameras() және жүйелік сұрау'),
              onTap: () {
                Navigator.pop(ctx);
                camera.requestCameraPermission();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
