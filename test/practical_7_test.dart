import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:antisleep_ai/models/realtime_message_model.dart';
import 'package:antisleep_ai/providers/realtime_provider.dart';
import 'package:antisleep_ai/screens/realtime_hub_screen.dart';
import 'package:antisleep_ai/services/realtime_telemetry_service.dart';
import 'package:antisleep_ai/utils/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppLogger.clear();
  });

  group('Практикалық жұмыс №7: Unit Tests (Tasks 14-15)', () {
    // Тест 1
    test('1. RealtimeMessage JSON десериализациясы және isAlert логикасы', () {
      final ackJson = {
        'type': 'telemetry_ack',
        'status': 'ok',
        'timestamp': '2026-11-08T20:00:00.000',
      };
      final ackMsg = RealtimeMessage.fromJson(ackJson);
      expect(ackMsg.type, 'telemetry_ack');
      expect(ackMsg.isAlert, isFalse);

      final alertJson = {
        'type': 'dispatcher_alert',
        'level': 'danger',
        'message': 'Ұйқы қаупі анықталды!',
        'timestamp': '2026-11-08T20:01:00.000',
      };
      final alertMsg = RealtimeMessage.fromJson(alertJson);
      expect(alertMsg.type, 'dispatcher_alert');
      expect(alertMsg.level, 'danger');
      expect(alertMsg.message, 'Ұйқы қаупі анықталды!');
      expect(alertMsg.isAlert, isTrue);
    });

    // Тест 2
    test('2. DriverTelemetry JSON форматының дұрыстығы (Task 5)', () {
      final now = DateTime.now();
      final telemetry = DriverTelemetry(
        ear: 0.28,
        eyeOpenness: 0.92,
        speed: 90.0,
        isDrowsy: false,
        yawnsDetected: 1,
        safetyScore: 98.0,
        timestamp: now,
      );

      final map = telemetry.toJson();
      expect(map['type'], 'telemetry');
      expect(map['ear'], 0.28);
      expect(map['eyeOpenness'], 0.92);
      expect(map['speed'], 90.0);
      expect(map['drowsy'], isFalse);
      expect(map['safetyScore'], 98.0);
      expect(map['timestamp'], now.toIso8601String());
    });

    // Тест 3
    test('3. AppLogger: әрекеттер мен қателерді тіркеу (Task 13)', () {
      AppLogger.info('Тест ақпараты', tag: 'UnitTest');
      AppLogger.warning('Тест ескертуі', tag: 'UnitTest');
      AppLogger.error('Тест қатесі', tag: 'UnitTest', error: 'NullPointerException');

      final logs = AppLogger.getRecentLogs(limit: 10);
      expect(logs.length, 3);
      expect(logs[0].level, LogLevel.info);
      expect(logs[0].message, 'Тест ақпараты');
      expect(logs[1].level, LogLevel.warning);
      expect(logs[2].level, LogLevel.error);
      expect(logs[2].error, 'NullPointerException');

      AppLogger.clear();
      expect(AppLogger.logs.isEmpty, isTrue);
    });

    // Тест 4
    test('4. RealtimeProvider күйі және телеметрия жіберуді басқару', () {
      final rtProvider = RealtimeProvider();

      expect(rtProvider.packetsSent, 0);
      expect(rtProvider.packetsReceived, 0);
      expect(rtProvider.isStreaming, isFalse);

      // Телеметрия жіберу әрекеті
      rtProvider.sendTelemetry(ear: 0.29, eyeOpenness: 0.95, isDrowsy: false);
      expect(rtProvider.latestSentTelemetry, isNotNull);
      expect(rtProvider.latestSentTelemetry!.ear, 0.29);

      // Диспетчер дабылын тазарту
      rtProvider.dismissDispatcherWarning();
      expect(rtProvider.activeDispatcherWarning, isNull);
    });

    // Тест 5
    test('5. Байланыс үзілген және Offline күйін өңдеу (Tasks 7, 8, 9)', () {
      final rtProvider = RealtimeProvider();
      expect(rtProvider.status, RealtimeConnectionStatus.disconnected);
      expect(rtProvider.isDisconnected, isTrue);
      expect(rtProvider.isConnected, isFalse);

      // Байланыс үзілу симуляциясы
      rtProvider.simulateConnectionDrop();
      expect(rtProvider.isDisconnected, isTrue);
    });

    // Тест 6 (Widget Test)
    testWidgets('6. RealtimeHubScreen: интерфейсте статус пен батырмалардың дұрыс шығуы', (tester) async {
      final rtProvider = RealtimeProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<RealtimeProvider>.value(
            value: rtProvider,
            child: const RealtimeHubScreen(autoConnect: false),
          ),
        ),
      );

      // Тақырып пен баннер тексеру
      expect(find.text('Realtime Диспетчерлік орталық'), findsOneWidget);
      expect(find.textContaining('Байланыс'), findsWidgets);
      expect(find.text('Қалыпты күй'), findsOneWidget);
      expect(find.text('Ұйқы қаупі'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);

      rtProvider.dispose();
    });
  });
}
