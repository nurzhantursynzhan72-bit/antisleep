import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/realtime_provider.dart';
import 'services/database_service.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    DatabaseService.setupFfiIfNeeded();
    await DatabaseService.instance.database;
  } catch (e) {
    debugPrint('Database startup info: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initSession()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => RealtimeProvider()),
      ],
      child: const AntiSleepAIApp(),
    ),
  );
}

class AntiSleepAIApp extends StatelessWidget {
  const AntiSleepAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AntiSleep AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
