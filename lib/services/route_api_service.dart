import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException, HttpException;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/route_model.dart';
import 'api_exception.dart';

/// AntiSleep Cloud REST API-мен жұмыс істейтін сервис.
///
/// | Әдіс   | Endpoint            | Операция                    |
/// |--------|---------------------|-----------------------------|
/// | GET    | /api/health         | Сервер жұмысын тексеру      |
/// | GET    | /api/routes         | Барлық бағыттарды алу       |
/// | GET    | /api/routes/{id}    | Бір бағытты алу             |
/// | POST   | /api/routes         | Жаңа бағыт қосу             |
/// | PUT    | /api/routes/{id}    | Бағытты толық өзгерту       |
/// | PATCH  | /api/routes/{id}    | Бағытты ішінара өзгерту     |
/// | DELETE | /api/routes/{id}    | Бағытты өшіру               |
class RouteApiService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  /// Қателерді демонстрациялау үшін тест режимі.
  ApiSimulation simulation = ApiSimulation.none;

  RouteApiService({
    http.Client? client,
    String? baseUrl,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _timeout = timeout ?? ApiConfig.requestTimeout;

  Uri _uri(String path, [Map<String, String>? query]) {
    final params = <String, String>{...?query};
    switch (simulation) {
      case ApiSimulation.slow:
        params['delay'] = '15000';
        break;
      case ApiSimulation.serverError:
        params['fail'] = '500';
        break;
      case ApiSimulation.none:
        break;
    }
    final uri = Uri.parse('$_baseUrl$path');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  // ==========================================
  // CRUD
  // ==========================================

  /// GET /health — сервер қолжетімді ме?
  Future<bool> checkHealth() async {
    try {
      final res = await _send(() => _client.get(_uri('/health')));
      return res.statusCode == 200;
    } on ApiException {
      return false;
    }
  }

  /// GET /routes — бағыттар тізімі.
  Future<List<RouteModel>> fetchRoutes({String query = ''}) async {
    final res = await _send(() => _client.get(
          _uri('/routes', query.trim().isEmpty ? null : {'q': query.trim()}),
          headers: ApiConfig.jsonHeaders,
        ));
    final body = _decode(res);
    if (body is! List) {
      throw const ApiException(
          ApiErrorType.parsing, 'Сервер тізім (JSON array) қайтармады.');
    }
    try {
      return body
          .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException(ApiErrorType.parsing, 'JSON → RouteModel қатесі: $e');
    }
  }

  /// GET /routes/{id} — бір бағыт.
  Future<RouteModel> fetchRoute(String id) async {
    final res = await _send(() => _client.get(
          _uri('/routes/$id'),
          headers: ApiConfig.jsonHeaders,
        ));
    return _parseRoute(_decode(res));
  }

  /// POST /routes — жаңа бағыт жасау. Сервер берген ID-мен қайтарады.
  Future<RouteModel> createRoute(RouteModel route) async {
    final res = await _send(() => _client.post(
          _uri('/routes'),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode(route.toJson(includeId: false)),
        ));
    return _parseRoute(_decode(res));
  }

  /// PUT /routes/{id} — бағытты толық ауыстыру.
  Future<RouteModel> updateRoute(RouteModel route) async {
    final res = await _send(() => _client.put(
          _uri('/routes/${route.id}'),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode(route.toJson()),
        ));
    return _parseRoute(_decode(res));
  }

  /// PATCH /routes/{id} — тек көрсетілген өрістерді өзгерту.
  Future<RouteModel> patchRoute(String id, Map<String, dynamic> fields) async {
    final res = await _send(() => _client.patch(
          _uri('/routes/$id'),
          headers: ApiConfig.jsonHeaders,
          body: jsonEncode(fields),
        ));
    return _parseRoute(_decode(res));
  }

  /// DELETE /routes/{id} — бағытты өшіру.
  Future<void> deleteRoute(String id) async {
    await _send(() => _client.delete(
          _uri('/routes/$id'),
          headers: ApiConfig.jsonHeaders,
        ));
  }

  void dispose() => _client.close();

  // ==========================================
  // Ортақ өңдеу: timeout, exception, статус коды
  // ==========================================

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        ApiErrorType.timeout,
        'Сервер ${_timeout.inSeconds} секунд ішінде жауап бермеді.',
      );
    } on SocketException {
      throw const ApiException(
        ApiErrorType.noInternet,
        'Серверге қосылу мүмкін емес. Интернетті немесе серверді тексеріңіз.',
      );
    } on HttpException catch (e) {
      throw ApiException(ApiErrorType.noInternet, 'Байланыс үзілді: ${e.message}');
    } on http.ClientException catch (e) {
      // Web платформасында желі қатесі осы түрде келеді.
      throw ApiException(
        ApiErrorType.noInternet,
        'Серверге қосылу мүмкін емес (${e.message}).',
      );
    } catch (e) {
      throw ApiException(ApiErrorType.unknown, 'Күтілмеген қате: $e');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res;
    }
    throw ApiException.fromStatus(res.statusCode, _serverMessage(res));
  }

  dynamic _decode(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw const ApiException(
          ApiErrorType.parsing, 'Сервер жауабы дұрыс JSON емес.');
    }
  }

  RouteModel _parseRoute(dynamic body) {
    if (body is! Map<String, dynamic>) {
      throw const ApiException(
          ApiErrorType.parsing, 'Сервер объект (JSON object) қайтармады.');
    }
    try {
      return RouteModel.fromJson(body);
    } catch (e) {
      throw ApiException(ApiErrorType.parsing, 'JSON → RouteModel қатесі: $e');
    }
  }

  String? _serverMessage(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['error'] is String) return body['error'] as String;
    } catch (_) {}
    return null;
  }
}

