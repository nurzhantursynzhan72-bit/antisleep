/// HTTP сұраулары кезінде туындайтын қателер түрлері.
enum ApiErrorType {
  /// Интернет / серверге байланыс жоқ (SocketException, ClientException).
  noInternet,

  /// Сервер белгіленген уақытта жауап бермеді (TimeoutException).
  timeout,

  /// Сервер 5xx қатесін қайтарды.
  server,

  /// 404 — ресурс табылмады.
  notFound,

  /// 400 / 422 — жіберілген деректер қате.
  badRequest,

  /// Жауаптағы JSON-ды оқу мүмкін болмады (FormatException).
  parsing,

  /// Басқа күтілмеген қате.
  unknown,
}

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;

  const ApiException(this.type, this.message, {this.statusCode});

  /// HTTP статус кодынан қате жасау.
  factory ApiException.fromStatus(int statusCode, [String? serverMessage]) {
    if (statusCode == 404) {
      return ApiException(
        ApiErrorType.notFound,
        serverMessage ?? 'Сұралған дерек серверде табылмады (404).',
        statusCode: statusCode,
      );
    }
    if (statusCode == 400 || statusCode == 422) {
      return ApiException(
        ApiErrorType.badRequest,
        serverMessage ?? 'Жіберілген деректер қате ($statusCode).',
        statusCode: statusCode,
      );
    }
    if (statusCode >= 500) {
      return ApiException(
        ApiErrorType.server,
        'Сервер қатесі ($statusCode). Кейінірек қайталап көріңіз.',
        statusCode: statusCode,
      );
    }
    return ApiException(
      ApiErrorType.unknown,
      serverMessage ?? 'Күтілмеген жауап ($statusCode).',
      statusCode: statusCode,
    );
  }

  /// Пайдаланушыға көрсетілетін қысқа тақырып.
  String get title {
    switch (type) {
      case ApiErrorType.noInternet:
        return 'Интернет байланысы жоқ';
      case ApiErrorType.timeout:
        return 'Сервер жауап бермеді';
      case ApiErrorType.server:
        return 'Сервер қатесі';
      case ApiErrorType.notFound:
        return 'Табылмады';
      case ApiErrorType.badRequest:
        return 'Деректер қате';
      case ApiErrorType.parsing:
        return 'Деректерді оқу қатесі';
      case ApiErrorType.unknown:
        return 'Белгісіз қате';
    }
  }

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}

