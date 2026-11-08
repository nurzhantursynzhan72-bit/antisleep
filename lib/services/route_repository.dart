import '../models/route_model.dart';
import 'database_service.dart';

abstract class IRouteRepository {
  Future<List<RouteModel>> getAllRoutes({
    String query = '',
    bool onlyFavorites = false,
    String? riskFilter,
    String sortBy = 'created_at',
    bool ascending = false,
  });
  Future<RouteModel?> getRouteById(String id);
  Future<void> addRoute(RouteModel route);
  Future<void> updateRoute(RouteModel route);
  Future<bool> toggleFavorite(String id);
  Future<void> deleteRoute(String id);
}

class RouteRepository implements IRouteRepository {
  final DatabaseService _dbService;

  RouteRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  @override
  Future<List<RouteModel>> getAllRoutes({
    String query = '',
    bool onlyFavorites = false,
    String? riskFilter,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    return await _dbService.getRoutes(
      query: query,
      onlyFavorites: onlyFavorites,
      riskFilter: riskFilter,
      sortBy: sortBy,
      ascending: ascending,
    );
  }

  @override
  Future<RouteModel?> getRouteById(String id) async {
    return await _dbService.getRouteById(id);
  }

  @override
  Future<void> addRoute(RouteModel route) async {
    await _dbService.insertRoute(route);
  }

  @override
  Future<void> updateRoute(RouteModel route) async {
    await _dbService.updateRoute(route);
  }

  @override
  Future<bool> toggleFavorite(String id) async {
    return await _dbService.toggleFavoriteRoute(id);
  }

  @override
  Future<void> deleteRoute(String id) async {
    await _dbService.deleteRoute(id);
  }
}

