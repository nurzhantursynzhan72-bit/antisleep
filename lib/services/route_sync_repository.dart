import '../models/route_model.dart';
import 'api_exception.dart';
import 'database_service.dart';
import 'route_api_service.dart';

/// Сервер деректерін локалды SQLite дерекқорымен байланыстырады.
///
/// * GET сәтті болса — серверден келген бағыттар локалды кэшке жазылады.
/// * Интернет жоқ / timeout болса — локалды кэштегі деректер қайтарылады.
/// * POST / PUT / PATCH / DELETE сәтті болса — сол өзгеріс локалды
///   дерекқорға да енгізіледі.
class RouteSyncRepository {
  final RouteApiService api;
  final DatabaseService _db;

  RouteSyncRepository({RouteApiService? api, DatabaseService? db})
      : api = api ?? RouteApiService(),
        _db = db ?? DatabaseService.instance;

  /// Серверден оқу, сәтсіз болса — кэштен.
  Future<SyncResult> loadRoutes({String query = ''}) async {
    try {
      final remote = await api.fetchRoutes(query: query);
      await _cacheAll(remote);
      return SyncResult(routes: remote, fromCache: false);
    } on ApiException catch (e) {
      final canUseCache = e.type == ApiErrorType.noInternet ||
          e.type == ApiErrorType.timeout;
      if (!canUseCache) rethrow;

      final local = await _db.getRoutes(query: query);
      if (local.isEmpty) rethrow;
      return SyncResult(routes: local, fromCache: true, error: e);
    }
  }

  Future<RouteModel> create(RouteModel draft) async {
    final created = await api.createRoute(draft);
    await _db.insertRoute(created);
    return created;
  }

  Future<RouteModel> update(RouteModel route) async {
    final updated = await api.updateRoute(route);
    await _db.insertRoute(updated); // REPLACE — бар болса жаңартады
    return updated;
  }

  Future<RouteModel> setFavorite(String id, bool isFavorite) async {
    final patched = await api.patchRoute(id, {'isFavorite': isFavorite});
    await _db.insertRoute(patched);
    return patched;
  }

  Future<void> delete(String id) async {
    await api.deleteRoute(id);
    await _db.deleteRoute(id);
  }

  Future<void> _cacheAll(List<RouteModel> routes) async {
    for (final r in routes) {
      try {
        await _db.insertRoute(r);
      } catch (_) {
        // Кэшке жазылмаса да, сервер деректері көрсетіле береді.
      }
    }
  }
}

class SyncResult {
  final List<RouteModel> routes;
  final bool fromCache;
  final ApiException? error;

  const SyncResult({
    required this.routes,
    required this.fromCache,
    this.error,
  });
}

