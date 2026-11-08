import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:antisleep_ai/services/database_service.dart';
import 'package:antisleep_ai/services/route_repository.dart';
import 'package:antisleep_ai/models/route_model.dart';
import 'package:antisleep_ai/models/session_model.dart';
import 'package:antisleep_ai/models/alert_event_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseService dbService;
  late RouteRepository routeRepo;

  setUp(() async {
    dbService = DatabaseService.instance;
    routeRepo = RouteRepository(dbService: dbService);
  });

  tearDownAll(() async {
    await dbService.close();
  });

  group('AntiSleep AI SQLite Database Tests', () {
    test('1. Database Initialization & Seed Data verification', () async {
      final db = await dbService.database;
      expect(db, isNotNull);
      expect(db!.isOpen, isTrue);

      final routes = await routeRepo.getAllRoutes();
      expect(routes.length, greaterThanOrEqualTo(5));

      final sessions = await dbService.getSessions();
      expect(sessions.length, greaterThanOrEqualTo(3));

      final user = await dbService.getUser('usr-789');
      expect(user, isNotNull);
      expect(user!.fullName, 'Арман Жұмабаев');

      final vehicle = await dbService.getDefaultVehicle('usr-789');
      expect(vehicle, isNotNull);
      expect(vehicle!.plateNumber, '02 KZ 777 AAA');

      final contact = await dbService.getPrimaryEmergencyContact('usr-789');
      expect(contact, isNotNull);
      expect(contact!.relationship, 'Жұбайы');
    });

    test('2. CRUD: CREATE - Insert new route', () async {
      final newRoute = RouteModel(
        id: 'test-route-100',
        title: 'Шымкент — Түркістан рухани жолы',
        distanceKm: 165.0,
        avgDurationMinutes: 110,
        riskLevel: 'Төмен (Жарықтандырылған)',
        isFavorite: false,
        notes: 'Жаңа 4 жолақты тасжол',
        createdAt: DateTime.now(),
      );

      await routeRepo.addRoute(newRoute);

      final fetched = await routeRepo.getRouteById('test-route-100');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Шымкент — Түркістан рухани жолы');
      expect(fetched.distanceKm, 165.0);
    });

    test('3. CRUD: READ - Query all routes and single route', () async {
      final allRoutes = await routeRepo.getAllRoutes();
      expect(allRoutes.any((r) => r.id == 'test-route-100'), isTrue);

      final route = await routeRepo.getRouteById('route-001');
      expect(route, isNotNull);
      expect(route!.title, contains('Қонаев'));
    });

    test('4. CRUD: UPDATE - Update route properties', () async {
      final existing = await routeRepo.getRouteById('test-route-100');
      expect(existing, isNotNull);

      final updated = existing!.copyWith(
        title: 'Шымкент — Түркістан (Жаңартылған)',
        distanceKm: 170.0,
        riskLevel: 'Орташа',
      );
      await routeRepo.updateRoute(updated);

      final verified = await routeRepo.getRouteById('test-route-100');
      expect(verified!.title, 'Шымкент — Түркістан (Жаңартылған)');
      expect(verified.distanceKm, 170.0);
      expect(verified.riskLevel, 'Орташа');
    });

    test('5. FAVORITES - Toggle favorite status', () async {
      final initial = await routeRepo.getRouteById('test-route-100');
      expect(initial!.isFavorite, isFalse);

      // Toggle to True
      final fav1 = await routeRepo.toggleFavorite('test-route-100');
      expect(fav1, isTrue);

      final checked1 = await routeRepo.getRouteById('test-route-100');
      expect(checked1!.isFavorite, isTrue);

      // Filter by favorites only
      final onlyFavs = await routeRepo.getAllRoutes(onlyFavorites: true);
      expect(onlyFavs.any((r) => r.id == 'test-route-100'), isTrue);

      // Toggle back to False
      final fav2 = await routeRepo.toggleFavorite('test-route-100');
      expect(fav2, isFalse);

      final checked2 = await routeRepo.getRouteById('test-route-100');
      expect(checked2!.isFavorite, isFalse);
    });

    test('6. CRUD: DELETE - Delete route and verify non-existence', () async {
      await routeRepo.deleteRoute('test-route-100');
      final deleted = await routeRepo.getRouteById('test-route-100');
      expect(deleted, isNull);
    });

    test('7. SEARCH - Search by name or risk level', () async {
      final searchResult1 = await routeRepo.getAllRoutes(query: 'Бурабай');
      expect(searchResult1.length, 1);
      expect(searchResult1.first.title, contains('Бурабай'));

      final searchResult2 = await routeRepo.getAllRoutes(query: 'Қатерлі');
      expect(searchResult2.isNotEmpty, isTrue);
      for (final r in searchResult2) {
        expect(
          r.riskLevel.contains('Қатерлі') ||
              r.title.contains('Қатерлі') ||
              r.notes.contains('Қатерлі'),
          isTrue,
        );
      }
    });

    test('8. FILTER - Filter by risk category', () async {
      final lowRisk = await routeRepo.getAllRoutes(riskFilter: 'Төмен');
      expect(lowRisk.isNotEmpty, isTrue);
      for (final r in lowRisk) {
        expect(r.riskLevel, contains('Төмен'));
      }
    });

    test('9. SORTING - Sort by distance ascending and descending', () async {
      final ascRoutes = await routeRepo.getAllRoutes(
        sortBy: 'distance_km',
        ascending: true,
      );
      for (int i = 0; i < ascRoutes.length - 1; i++) {
        expect(ascRoutes[i].distanceKm <= ascRoutes[i + 1].distanceKm, isTrue);
      }

      final descRoutes = await routeRepo.getAllRoutes(
        sortBy: 'distance_km',
        ascending: false,
      );
      for (int i = 0; i < descRoutes.length - 1; i++) {
        expect(
            descRoutes[i].distanceKm >= descRoutes[i + 1].distanceKm, isTrue);
      }
    });

    test('10. RELATIONS & SESSION LOGS: Insert session and alert events',
        () async {
      final newSession = SessionModel(
        id: 'sess-test-999',
        userId: 'usr-789',
        vehicleId: 'veh-001',
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now(),
        duration: const Duration(hours: 2),
        drowsinessAlerts: 1,
        yawnsDetected: 4,
        safetyScore: 88.0,
        status: 'Орташа',
        notes: 'Сынақ сапары',
      );

      await dbService.insertSession(newSession);

      final alert = AlertEventModel(
        id: 'alert-test-999',
        sessionId: 'sess-test-999',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        alertType: 'microsleep',
        earValue: 0.15,
        actionTaken: 'Дабыл ойнатылды',
      );
      await dbService.insertAlertEvent(alert);

      final sessionAlerts =
          await dbService.getAlertsForSession('sess-test-999');
      expect(sessionAlerts.length, 1);
      expect(sessionAlerts.first.alertType, 'microsleep');

      // Clean up session
      await dbService.deleteSession('sess-test-999');
      final checkedSession = await dbService.getSessions();
      expect(checkedSession.any((s) => s.id == 'sess-test-999'), isFalse);
    });
  });
}
