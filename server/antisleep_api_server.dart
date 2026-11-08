// AntiSleep Cloud API — Практикалық жұмыс №5 үшін жергілікті REST сервер.
//
// Іске қосу (жоба папкасында):
//   dart run server/antisleep_api_server.dart
//
// Сервер http://localhost:8080 адресінде жұмыс істейді.
// Деректер server/routes_db.json файлында сақталады.
//
// Тест параметрлері (кез келген сұрауға):
//   ?delay=15000  — жауапты 15 секундқа кешіктіру (timeout тексеру)
//   ?fail=500     — 500 Internal Server Error қайтару

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const int port = 8080;
final File dbFile = File('server/routes_db.json');

List<Map<String, dynamic>> routes = [];
final Set<WebSocket> _activeSockets = {};
Timer? _broadcastTimer;

void _startBroadcastLoop() {
  _broadcastTimer?.cancel();
  _broadcastTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
    if (_activeSockets.isEmpty) return;
    final notices = [
      'Трассада қатты жел мен тұман күтілуде. Жылдамдықты 70 км/сағ асырмаңыз.',
      'Қауіпсіздік ережесі: әр 2 сағат үздіксіз көлік жүргізгеннен кейін 15 минут тынығыңыз.',
      'Түнгі көру режимі қосылды. Диспетчерлік мониторинг қалыпты режимде.',
      'Алдыңғы 10 шақырымда жол жөндеу жұмыстары жүріп жатыр.',
    ];
    final note = notices[timer.tick % notices.length];
    final broadcastMsg = jsonEncode({
      'type': 'traffic_broadcast',
      'level': 'info',
      'message': '📢 Диспетчер: $note',
      'timestamp': DateTime.now().toIso8601String(),
    });
    for (final ws in _activeSockets) {
      try {
        ws.add(broadcastMsg);
      } catch (_) {}
    }
  });
}

Future<void> main() async {
  await _loadDb();
  _startBroadcastLoop();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('==============================================');
  stdout.writeln(' AntiSleep Cloud API & WebSocket Server іске қосылды');
  stdout.writeln(' REST: http://localhost:$port/api/routes');
  stdout.writeln(' WebSocket: ws://localhost:$port/ws/telemetry');
  stdout.writeln(' Бағыттар саны: ${routes.length}');
  stdout.writeln(' Тоқтату: Ctrl+C');
  stdout.writeln('==============================================');

  await for (final req in server) {
    unawaited(_handle(req));
  }
}

Future<void> _handle(HttpRequest req) async {
  final res = req.response;
  _cors(res);
  final started = DateTime.now();

  try {
    if (req.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      return;
    }

    // WebSocket Upgrade: нақты уақыттағы телеметрия мен диспетчерлік байланыс (Практикалық №7)
    if (WebSocketTransformer.isUpgradeRequest(req) || req.uri.path.startsWith('/ws')) {
      final socket = await WebSocketTransformer.upgrade(req);
      _handleWebSocket(socket);
      return;
    }

    // --- Тест режимдері ---
    final delay = int.tryParse(req.uri.queryParameters['delay'] ?? '');
    if (delay != null && delay > 0) {
      await Future.delayed(Duration(milliseconds: delay));
    }
    final fail = int.tryParse(req.uri.queryParameters['fail'] ?? '');
    if (fail != null && fail >= 400) {
      return _json(res, fail, {'error': 'Тест режимі: жасанды сервер қатесі'});
    }

    final seg = req.uri.pathSegments;
    if (seg.isEmpty || seg.first != 'api') {
      return _json(res, 404, {'error': 'Endpoint табылмады'});
    }

    // GET /api/health
    if (seg.length == 2 && seg[1] == 'health' && req.method == 'GET') {
      return _json(res, 200, {
        'status': 'ok',
        'time': DateTime.now().toIso8601String(),
        'routes': routes.length,
      });
    }

    if (seg.length >= 2 && seg[1] == 'routes') {
      final id = seg.length >= 3 ? seg[2] : null;

      if (id == null) {
        switch (req.method) {
          case 'GET':
            return _getAll(req, res);
          case 'POST':
            return await _create(req, res);
        }
      } else {
        switch (req.method) {
          case 'GET':
            return _getOne(res, id);
          case 'PUT':
            return await _update(req, res, id, replace: true);
          case 'PATCH':
            return await _update(req, res, id, replace: false);
          case 'DELETE':
            return await _delete(res, id);
        }
      }
      return _json(res, 405, {'error': '${req.method} әдісіне рұқсат жоқ'});
    }

    return _json(res, 404, {'error': 'Endpoint табылмады'});
  } catch (e) {
    _json(res, 500, {'error': 'Ішкі сервер қатесі: $e'});
  } finally {
    final ms = DateTime.now().difference(started).inMilliseconds;
    stdout.writeln(
        '${req.method.padRight(6)} ${req.uri}  →  ${res.statusCode}  (${ms}ms)');
    await res.close();
  }
}

// ==========================================
// Handlers
// ==========================================

void _getAll(HttpRequest req, HttpResponse res) {
  final q = (req.uri.queryParameters['q'] ?? '').toLowerCase();
  var result = routes;
  if (q.isNotEmpty) {
    result = routes
        .where((r) =>
            (r['title'] as String).toLowerCase().contains(q) ||
            (r['riskLevel'] as String).toLowerCase().contains(q))
        .toList();
  }
  result.sort((a, b) =>
      (b['createdAt'] as String).compareTo(a['createdAt'] as String));
  _json(res, 200, result);
}

void _getOne(HttpResponse res, String id) {
  final r = _find(id);
  if (r == null) return _json(res, 404, {'error': 'Бағыт табылмады: $id'});
  _json(res, 200, r);
}

Future<void> _create(HttpRequest req, HttpResponse res) async {
  final body = await _readBody(req);
  final error = _validate(body, requireAll: true);
  if (error != null) return _json(res, 400, {'error': error});

  final route = <String, dynamic>{
    'id': 'route-${DateTime.now().millisecondsSinceEpoch}',
    'title': (body!['title'] as String).trim(),
    'distanceKm': (body['distanceKm'] as num).toDouble(),
    'avgDurationMinutes': (body['avgDurationMinutes'] as num).toInt(),
    'riskLevel': body['riskLevel'] ?? 'Төмен',
    'isFavorite': body['isFavorite'] ?? false,
    'notes': body['notes'] ?? '',
    'createdAt': DateTime.now().toIso8601String(),
  };
  routes.add(route);
  await _saveDb();
  _json(res, 201, route);
}

Future<void> _update(HttpRequest req, HttpResponse res, String id,
    {required bool replace}) async {
  final existing = _find(id);
  if (existing == null) {
    return _json(res, 404, {'error': 'Бағыт табылмады: $id'});
  }
  final body = await _readBody(req);
  final error = _validate(body, requireAll: replace);
  if (error != null) return _json(res, 400, {'error': error});

  const allowed = [
    'title',
    'distanceKm',
    'avgDurationMinutes',
    'riskLevel',
    'isFavorite',
    'notes',
  ];
  if (replace) {
    // PUT — барлық өрістер ауыстырылады
    existing
      ..['title'] = body!['title']
      ..['distanceKm'] = (body['distanceKm'] as num).toDouble()
      ..['avgDurationMinutes'] = (body['avgDurationMinutes'] as num).toInt()
      ..['riskLevel'] = body['riskLevel'] ?? 'Төмен'
      ..['isFavorite'] = body['isFavorite'] ?? false
      ..['notes'] = body['notes'] ?? '';
  } else {
    // PATCH — тек жіберілген өрістер
    for (final key in allowed) {
      if (body!.containsKey(key)) existing[key] = body[key];
    }
  }
  existing['updatedAt'] = DateTime.now().toIso8601String();
  await _saveDb();
  _json(res, 200, existing);
}

Future<void> _delete(HttpResponse res, String id) async {
  final before = routes.length;
  routes.removeWhere((r) => r['id'] == id);
  if (routes.length == before) {
    return _json(res, 404, {'error': 'Бағыт табылмады: $id'});
  }
  await _saveDb();
  res.statusCode = HttpStatus.noContent; // 204
}

// ==========================================
// Helpers
// ==========================================

Map<String, dynamic>? _find(String id) {
  for (final r in routes) {
    if (r['id'] == id) return r;
  }
  return null;
}

String? _validate(Map<String, dynamic>? body, {required bool requireAll}) {
  if (body == null) return 'Сұрау денесі JSON объект болуы керек';
  if (requireAll || body.containsKey('title')) {
    final t = body['title'];
    if (t is! String || t.trim().isEmpty) return '"title" өрісі міндетті';
  }
  if (requireAll || body.containsKey('distanceKm')) {
    final d = body['distanceKm'];
    if (d is! num || d <= 0) return '"distanceKm" оң сан болуы керек';
  }
  if (requireAll || body.containsKey('avgDurationMinutes')) {
    final m = body['avgDurationMinutes'];
    if (m is! num || m <= 0) return '"avgDurationMinutes" оң сан болуы керек';
  }
  if (body.containsKey('isFavorite') && body['isFavorite'] is! bool) {
    return '"isFavorite" true/false болуы керек';
  }
  return null;
}

Future<Map<String, dynamic>?> _readBody(HttpRequest req) async {
  try {
    final text = await utf8.decodeStream(req);
    final data = jsonDecode(text);
    return data is Map<String, dynamic> ? data : null;
  } catch (_) {
    return null;
  }
}

void _json(HttpResponse res, int status, Object data) {
  res.statusCode = status;
  res.headers.contentType = ContentType.json;
  res.write(jsonEncode(data));
}

void _cors(HttpResponse res) {
  res.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type, Accept');
}

Future<void> _loadDb() async {
  if (await dbFile.exists()) {
    try {
      final data = jsonDecode(await dbFile.readAsString()) as List;
      routes = data.cast<Map<String, dynamic>>();
      return;
    } catch (_) {
      stdout.writeln('routes_db.json оқылмады — бастапқы деректер жүктеледі');
    }
  }
  routes = _seed();
  await _saveDb();
}

Future<void> _saveDb() async {
  await dbFile.parent.create(recursive: true);
  await dbFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(routes));
}

List<Map<String, dynamic>> _seed() {
  final now = DateTime.now();
  String daysAgo(int d) => now.subtract(Duration(days: d)).toIso8601String();
  return [
    {
      'id': 'cloud-001',
      'title': 'Алматы — Талдықорған тасжолы',
      'distanceKm': 270.0,
      'avgDurationMinutes': 210,
      'riskLevel': 'Орташа (Тау асуы)',
      'isFavorite': true,
      'notes': 'Қапшағай маңында жел қатты, түнде абай болыңыз.',
      'createdAt': daysAgo(6),
    },
    {
      'id': 'cloud-002',
      'title': 'Астана — Қарағанды автобаны',
      'distanceKm': 215.0,
      'avgDurationMinutes': 140,
      'riskLevel': 'Қатерлі (Монотонды жол)',
      'isFavorite': false,
      'notes': 'Түзу, бірсарынды жол — ұйқы басу қаупі жоғары.',
      'createdAt': daysAgo(4),
    },
    {
      'id': 'cloud-003',
      'title': 'Шымкент — Түркістан',
      'distanceKm': 165.0,
      'avgDurationMinutes': 120,
      'riskLevel': 'Төмен (Жаңа жол)',
      'isFavorite': false,
      'notes': 'Жаңа төрт жолақты трасса, жанармай бекеттері көп.',
      'createdAt': daysAgo(2),
    },
    {
      'id': 'cloud-004',
      'title': 'Ақтөбе — Орал',
      'distanceKm': 470.0,
      'avgDurationMinutes': 330,
      'riskLevel': 'Қатерлі (Ұзақ дала жолы)',
      'isFavorite': true,
      'notes': 'Әр 2 сағат сайын тынығу ұсынылады.',
      'createdAt': daysAgo(1),
    },
  ];
}

void _handleWebSocket(WebSocket socket) {
  _activeSockets.add(socket);
  stdout.writeln('⚡ [WebSocket] Жаңа клиент қосылды. Белсенді: ${_activeSockets.length}');

  socket.add(jsonEncode({
    'type': 'connected',
    'level': 'success',
    'message': 'AntiSleep Realtime Диспетчерлік орталығына қосылдыңыз',
    'serverTime': DateTime.now().toIso8601String(),
  }));

  socket.listen(
    (data) {
      try {
        final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
        final type = msg['type'] ?? 'telemetry';

        if (type == 'telemetry') {
          final ear = (msg['ear'] as num?)?.toDouble() ?? 0.30;
          final isDrowsy = (msg['drowsy'] as bool?) ?? false;
          final speed = (msg['speed'] as num?)?.toDouble() ?? 0.0;

          socket.add(jsonEncode({
            'type': 'telemetry_ack',
            'status': isDrowsy ? 'warning' : 'ok',
            'ear': ear,
            'speed': speed,
            'receivedAt': DateTime.now().toIso8601String(),
          }));

          if (isDrowsy) {
            socket.add(jsonEncode({
              'type': 'dispatcher_alert',
              'level': 'danger',
              'message': '⚠️ Диспетчер дабылы: Ұйқы қаупі анықталды! Жылдамдықты азайтып, жақын жерге тоқтаңыз.',
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }
        } else if (type == 'sos') {
          socket.add(jsonEncode({
            'type': 'dispatcher_alert',
            'level': 'emergency',
            'message': '🚨 ШҰҒЫЛ SOS: Диспетчер дабылды қабылдады! Көмек бригадасы шақырылды.',
            'timestamp': DateTime.now().toIso8601String(),
          }));
        } else if (type == 'ping') {
          socket.add(jsonEncode({
            'type': 'pong',
            'timestamp': DateTime.now().toIso8601String(),
          }));
        }
      } catch (e) {
        socket.add(jsonEncode({'type': 'error', 'message': 'Қате дерек форматы: $e'}));
      }
    },
    onDone: () {
      _activeSockets.remove(socket);
      stdout.writeln('🔌 [WebSocket] Клиент ажыратылды. Қалды: ${_activeSockets.length}');
    },
    onError: (err) {
      _activeSockets.remove(socket);
      stdout.writeln('❌ [WebSocket] Байланыс қатесі: $err');
    },
  );
}
