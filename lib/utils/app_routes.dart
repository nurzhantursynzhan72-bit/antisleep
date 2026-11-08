import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../screens/alarm_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/cloud_routes_screen.dart';
import '../screens/edit_vehicle_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/help_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/realtime_hub_screen.dart';
import '../screens/rest_suggestion_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/trip_detail_screen.dart';
import '../screens/trip_list_screen.dart';
import '../widgets/auth_guard.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot_password';
  static const String home = '/home';
  static const String tracking = '/tracking';
  static const String alarm = '/alarm';
  static const String trips = '/trips';
  static const String tripDetail = '/trip_detail';
  static const String search = '/search';
  static const String editVehicle = '/edit_vehicle';
  static const String restSuggestion = '/rest_suggestion';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String cloudRoutes = '/cloud_routes';
  static const String realtimeHub = '/realtime_hub';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding: (context) => const OnboardingScreen(),
        auth: (context) => const AuthScreen(),
        login: (context) => const AuthScreen(initialIsLogin: true),
        register: (context) => const AuthScreen(initialIsLogin: false),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        home: (context) => const HomeScreen(),
        tracking: (context) => const AuthGuard(child: TrackingScreen()),
        alarm: (context) => const AlarmScreen(),
        trips: (context) => const AuthGuard(child: TripListScreen()),
        search: (context) => const SearchScreen(),
        editVehicle: (context) => const AuthGuard(child: EditVehicleScreen()),
        restSuggestion: (context) => const RestSuggestionScreen(),
        profile: (context) => const AuthGuard(child: ProfileScreen()),
        settings: (context) => const SettingsScreen(),
        help: (context) => const HelpScreen(),
        cloudRoutes: (context) => const CloudRoutesScreen(),
        realtimeHub: (context) => const RealtimeHubScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == tripDetail) {
      final session = settings.arguments as SessionModel? ??
          SessionModel.getSampleHistory().first;
      return MaterialPageRoute(
        builder: (context) => TripDetailScreen(session: session),
        settings: settings,
      );
    }
    return null;
  }
}
