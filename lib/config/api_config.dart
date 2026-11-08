import 'package:flutter/foundation.dart';

/// REST API баптаулары (Практикалық жұмыс №5).
///
/// Сервер: `dart run server/antisleep_api_server.dart` (порт 8080).
class ApiConfig {
  ApiConfig._();

  static const int port = 8080;

  /// Платформаға байланысты сервер адресі.
  /// Android эмуляторында компьютердің localhost-ы — 10.0.2.2.
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port/api';
    }
    return 'http://localhost:$port/api';
  }

  /// Сервер осы уақыт ішінде жауап бермесе — timeout қатесі.
  static const Duration requestTimeout = Duration(seconds: 8);

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };
}

/// Қателерді көрсету үшін серверге жіберілетін тест режимдері.
enum ApiSimulation {
  none,

  /// Сервер 15 секунд кешігеді → timeout.
  slow,

  /// Сервер 500 Internal Server Error қайтарады.
  serverError,
}

