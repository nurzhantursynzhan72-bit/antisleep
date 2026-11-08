import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/route_model.dart';
import '../services/api_exception.dart';
import '../services/route_sync_repository.dart';

/// Сұрау күйлері: Loading → Success / Error.
enum RequestStatus { initial, loading, success, error }

/// Бұлттағы бағыттар экранының күйін басқарады.
class CloudRoutesController extends ChangeNotifier {
  final RouteSyncRepository _repo;

  CloudRoutesController({RouteSyncRepository? repository})
      : _repo = repository ?? RouteSyncRepository();

  RequestStatus status = RequestStatus.initial;
  List<RouteModel> routes = [];
  ApiException? error;

  /// Деректер локалды кэштен көрсетіліп тұр (офлайн режим).
  bool fromCache = false;

  /// POST / PUT / PATCH / DELETE орындалып жатыр.
  bool isMutating = false;

  DateTime? lastSync;

  ApiSimulation get simulation => _repo.api.simulation;
  set simulation(ApiSimulation value) {
    _repo.api.simulation = value;
    notifyListeners();
  }

  /// GET — серверден тізімді жүктеу.
  Future<void> loadRoutes() async {
    status = RequestStatus.loading;
    error = null;
    notifyListeners();

    try {
      final result = await _repo.loadRoutes();
      routes = result.routes;
      fromCache = result.fromCache;
      error = result.error;
      if (!fromCache) lastSync = DateTime.now();
      status = RequestStatus.success;
    } on ApiException catch (e) {
      error = e;
      status = RequestStatus.error;
    } catch (e) {
      error = ApiException(ApiErrorType.unknown, e.toString());
      status = RequestStatus.error;
    }
    notifyListeners();
  }

  /// POST — жаңа бағыт.
  Future<RouteModel> addRoute(RouteModel draft) {
    return _mutate(() async {
      final created = await _repo.create(draft);
      routes = [created, ...routes];
      return created;
    });
  }

  /// PUT — бағытты толық жаңарту.
  Future<RouteModel> updateRoute(RouteModel route) {
    return _mutate(() async {
      final updated = await _repo.update(route);
      _replace(updated);
      return updated;
    });
  }

  /// PATCH — тек «Таңдаулы» өрісін ауыстыру.
  Future<RouteModel> toggleFavorite(RouteModel route) {
    return _mutate(() async {
      final patched = await _repo.setFavorite(route.id, !route.isFavorite);
      _replace(patched);
      return patched;
    });
  }

  /// DELETE — бағытты өшіру.
  Future<void> deleteRoute(String id) {
    return _mutate(() async {
      await _repo.delete(id);
      routes = routes.where((r) => r.id != id).toList();
    });
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    isMutating = true;
    notifyListeners();
    try {
      final result = await action();
      return result;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  void _replace(RouteModel updated) {
    routes = [
      for (final r in routes) r.id == updated.id ? updated : r,
    ];
  }

  @override
  void dispose() {
    _repo.api.dispose();
    super.dispose();
  }
}
