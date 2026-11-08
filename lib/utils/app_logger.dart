import 'package:flutter/foundation.dart';

/// Лог деңгейлері
enum LogLevel { debug, info, warning, error }

/// Жеке лог жазбасы
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() {
    final prefix = switch (level) {
      LogLevel.debug => '🔍 [DEBUG]',
      LogLevel.info => 'ℹ️ [INFO]',
      LogLevel.warning => '⚠️ [WARN]',
      LogLevel.error => '❌ [ERROR]',
    };
    return '$formattedTime $prefix [$tag] $message ${error != null ? "($error)" : ""}';
  }
}

/// Қосымшадағы маңызды әрекеттер мен қателерді тіркейтін логгер.
/// (Практикалық жұмыс №7: 13-тапсырма)
class AppLogger {
  AppLogger._();

  static final List<LogEntry> _logs = [];
  static const int _maxLogs = 200;

  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void debug(String message, {String tag = 'App'}) {
    _add(LogLevel.debug, tag, message);
  }

  static void info(String message, {String tag = 'App'}) {
    _add(LogLevel.info, tag, message);
  }

  static void warning(String message, {String tag = 'App', Object? error}) {
    _add(LogLevel.warning, tag, message, error);
  }

  static void error(String message, {String tag = 'App', Object? error, StackTrace? stackTrace}) {
    _add(LogLevel.error, tag, message, error);
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static void _add(LogLevel level, String tag, String message, [Object? error]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
    );

    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  static List<LogEntry> getRecentLogs({int limit = 50}) {
    if (_logs.length <= limit) return List.from(_logs);
    return _logs.sublist(_logs.length - limit);
  }

  static void clear() {
    _logs.clear();
  }
}

