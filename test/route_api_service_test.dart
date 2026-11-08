import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:antisleep_ai/models/route_model.dart';
import 'package:antisleep_ai/services/api_exception.dart';
import 'package:antisleep_ai/services/route_api_service.dart';

/// Практикалық жұмыс №5 — HTTP операцияларын жеке тексеру (MockClient).
void main() {
  const base = 'http://test.local/api';

  Map<String, dynamic> routeJson(String id, {bool fav = false}) => {
        'id': id,
        'title': 'Алматы — Қонаев',
        'distanceKm': 75,
        'avgDurationMinutes': 70,
        'riskLevel': 'Төмен',
        'isFavorite': fav,
        'notes': '',
        'createdAt': '2026-11-01T10:00:00.000',
      };

  http.Response jsonRes(Object body, int status) => http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  RouteApiService serviceWith(MockClientHandler handler,
          {Duration timeout = const Duration(seconds: 2)}) =>
      RouteApiService(
          client: MockClient(handler), baseUrl: base, timeout: timeout);

  group('JSON → Dart Model', () {
    test('RouteModel.fromJson / toJson', () {
      final r = RouteModel.fromJson(routeJson('r1', fav: true));
      expect(r.id, 'r1');
      expect(r.distanceKm, 75.0);
      expect(r.isFavorite, isTrue);
      expect(r.toJson(includeId: false).containsKey('id'), isFalse);
    });

    test('id жоқ JSON → FormatException', () {
      expect(() => RouteModel.fromJson({'title': 'x'}),
          throwsA(isA<FormatException>()));
    });
  });

  group('CRUD сұраулары', () {
    test('GET /routes — тізімді алады', () async {
      final api = serviceWith((req) async {
        expect(req.method, 'GET');
        expect(req.url.toString(), '$base/routes');
        return jsonRes([routeJson('r1'), routeJson('r2')], 200);
      });
      final list = await api.fetchRoutes();
      expect(list.length, 2);
      expect(list.first.title, 'Алматы — Қонаев');
    });

    test('POST /routes — 201 және сервер берген ID', () async {
      final api = serviceWith((req) async {
        expect(req.method, 'POST');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body.containsKey('id'), isFalse);
        return jsonRes({...body, 'id': 'route-new'}, 201);
      });
      final created = await api.createRoute(
          RouteModel.fromJson(routeJson('tmp')).copyWith(id: ''));
      expect(created.id, 'route-new');
    });

    test('PUT /routes/{id} — толық жаңарту', () async {
      final api = serviceWith((req) async {
        expect(req.method, 'PUT');
        expect(req.url.path, '/api/routes/r1');
        return jsonRes(jsonDecode(req.body) as Object, 200);
      });
      final r = RouteModel.fromJson(routeJson('r1')).copyWith(title: 'Жаңа атау');
      final updated = await api.updateRoute(r);
      expect(updated.title, 'Жаңа атау');
    });

    test('PATCH /routes/{id} — тек isFavorite', () async {
      final api = serviceWith((req) async {
        expect(req.method, 'PATCH');
        expect(jsonDecode(req.body), {'isFavorite': true});
        return jsonRes(routeJson('r1', fav: true), 200);
      });
      final patched = await api.patchRoute('r1', {'isFavorite': true});
      expect(patched.isFavorite, isTrue);
    });

    test('DELETE /routes/{id} — 204', () async {
      var called = false;
      final api = serviceWith((req) async {
        expect(req.method, 'DELETE');
        called = true;
        return http.Response('', 204);
      });
      await api.deleteRoute('r1');
      expect(called, isTrue);
    });
  });

  group('Қателерді өңдеу', () {
    test('500 → ApiErrorType.server', () async {
      final api = serviceWith((_) async => jsonRes({'error': 'x'}, 500));
      expect(
        api.fetchRoutes(),
        throwsA(isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.server)),
      );
    });

    test('404 → ApiErrorType.notFound', () async {
      final api = serviceWith((_) async => jsonRes({'error': 'жоқ'}, 404));
      expect(
        api.fetchRoute('x'),
        throwsA(isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.notFound)),
      );
    });

    test('Интернет жоқ (SocketException) → noInternet', () async {
      final api = serviceWith(
          (_) async => throw const SocketException('Network is unreachable'));
      expect(
        api.fetchRoutes(),
        throwsA(isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.noInternet)),
      );
    });

    test('ClientException (web) → noInternet', () async {
      final api =
          serviceWith((_) async => throw http.ClientException('XMLHttpRequest error'));
      expect(
        api.fetchRoutes(),
        throwsA(isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.noInternet)),
      );
    });

    test('Сервер ұзақ жауап берсе → timeout', () async {
      final api = serviceWith(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 300));
          return jsonRes([], 200);
        },
        timeout: const Duration(milliseconds: 50),
      );
      expect(
        api.fetchRoutes(),
        throwsA(isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.timeout)),
      );
    });

    test('Қате JSON → parsing', () async {
      final api = serviceWith((_) async => http.Response('<html>', 200));
      expect(
        api.fetchRoutes(),
        throwsA(isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.parsing)),
      );
    });
  });
}

