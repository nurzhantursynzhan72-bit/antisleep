import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/route_model.dart';
import '../models/session_model.dart';
import '../models/alert_event_model.dart';
import '../models/emergency_contact_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // In-memory fallback for Web platform where SQLite native FFI is unavailable
  final List<RouteModel> _webRoutes = [];
  final List<SessionModel> _webSessions = [];
  final List<AlertEventModel> _webAlerts = [];
  UserModel? _webUser;
  VehicleModel? _webVehicle;
  EmergencyContactModel? _webContact;
  bool _webInitialized = false;

  DatabaseService._init() {
    if (kIsWeb) {
      _initWebData();
    }
  }

  void _initWebData() {
    if (_webInitialized) return;
    _webInitialized = true;
    _webUser = UserModel.current();
    _webVehicle = VehicleModel(
      id: 'veh-001',
      userId: _webUser!.id,
      brand: 'Toyota',
      model: 'Camry 70',
      plateNumber: '02 KZ 777 AAA',
      year: 2022,
      isDefault: true,
    );
    _webContact = EmergencyContactModel(
      id: 'sos-001',
      userId: _webUser!.id,
      name: 'Айгүл Жұмабаева',
      phone: '+7 (777) 987-65-43',
      relationship: 'Жұбайы',
      isPrimary: true,
    );

    final now = DateTime.now();
    _webRoutes.addAll([
      RouteModel(
        id: 'route-001',
        title: 'Алматы — Қонаев тасжолы',
        distanceKm: 75.0,
        avgDurationMinutes: 70,
        riskLevel: 'Төмен (Жарықтандырылған)',
        isFavorite: true,
        notes: 'Сапасы жоғары бетон жол, түнгі шамдар орнатылған.',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      RouteModel(
        id: 'route-002',
        title: 'Астана — Бурабай тасжолы',
        distanceKm: 260.0,
        avgDurationMinutes: 165,
        riskLevel: 'Орташа (Түнгі учаскелер)',
        isFavorite: true,
        notes: 'Жоғары жылдамдықты автобан, демалыс орындары бар.',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      RouteModel(
        id: 'route-003',
        title: 'Батыс Еуропа — Батыс Қытай (Шымкент-Тараз)',
        distanceKm: 180.0,
        avgDurationMinutes: 135,
        riskLevel: 'Қатерлі (Монотонды ұзақ жол)',
        isFavorite: false,
        notes: 'Ұзақ түзу жол, жүргізушілердің көзі ілініп кету қаупі жоғары.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      RouteModel(
        id: 'route-004',
        title: 'Алматы — Бішкек трассасы',
        distanceKm: 235.0,
        avgDurationMinutes: 210,
        riskLevel: 'Орташа (Көлік тығыздығы жоғары)',
        isFavorite: false,
        notes: 'Ауыр жүк көліктері көп жүретін трасса.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      RouteModel(
        id: 'route-005',
        title: 'Қарағанды — Балқаш тасжолы',
        distanceKm: 380.0,
        avgDurationMinutes: 260,
        riskLevel: 'Қатерлі (Шаршау қаупі жоғары)',
        isFavorite: true,
        notes: 'Далалы аймақ, түнгі жел және жолдың монотондығы ұйқы шақырады.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    _webSessions.addAll(SessionModel.getSampleHistory());
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('antisleep_ai.db');
    return _database!;
  }

  // Cross-platform setup for Windows / Linux / macOS / Unit tests
  static void setupFfiIfNeeded() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDB(String filePath) async {
    setupFfiIfNeeded();

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final dbPath = await databaseFactory.getDatabasesPath();
      path = join(dbPath, filePath);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        vehicle_model TEXT NOT NULL,
        plate_number TEXT NOT NULL,
        total_safe_hours REAL NOT NULL,
        total_trips INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Vehicles Table
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        plate_number TEXT NOT NULL,
        year INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 3. Routes Table
    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        distance_km REAL NOT NULL,
        avg_duration_minutes INTEGER NOT NULL,
        risk_level TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Sessions Table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        vehicle_id TEXT NOT NULL,
        route_id TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        drowsiness_alerts INTEGER NOT NULL,
        yawns_detected INTEGER NOT NULL,
        safety_score REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id),
        FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE SET NULL
      )
    ''');

    // 5. Alert Events Table
    await db.execute('''
      CREATE TABLE alert_events (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        alert_type TEXT NOT NULL,
        ear_value REAL NOT NULL,
        is_resolved INTEGER NOT NULL DEFAULT 1,
        action_taken TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // 6. Emergency Contacts Table
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        relationship TEXT NOT NULL,
        is_primary INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final user = UserModel.current();
    await db.insert('users', user.toMap());

    final vehicle = VehicleModel(
      id: 'veh-001',
      userId: user.id,
      brand: 'Toyota',
      model: 'Camry 70',
      plateNumber: '02 KZ 777 AAA',
      year: 2022,
      isDefault: true,
    );
    await db.insert('vehicles', vehicle.toMap());

    final contact = EmergencyContactModel(
      id: 'sos-001',
      userId: user.id,
      name: 'Айгүл Жұмабаева',
      phone: '+7 (777) 987-65-43',
      relationship: 'Жұбайы',
      isPrimary: true,
    );
    await db.insert('emergency_contacts', contact.toMap());

    final now = DateTime.now();
    final initialRoutes = [
      RouteModel(
        id: 'route-001',
        title: 'Алматы — Қонаев тасжолы',
        distanceKm: 75.0,
        avgDurationMinutes: 70,
        riskLevel: 'Төмен (Жарықтандырылған)',
        isFavorite: true,
        notes: 'Сапасы жоғары бетон жол, түнгі шамдар орнатылған.',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      RouteModel(
        id: 'route-002',
        title: 'Астана — Бурабай тасжолы',
        distanceKm: 260.0,
        avgDurationMinutes: 165,
        riskLevel: 'Орташа (Түнгі учаскелер)',
        isFavorite: true,
        notes: 'Жоғары жылдамдықты автобан, демалыс орындары бар.',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      RouteModel(
        id: 'route-003',
        title: 'Батыс Еуропа — Батыс Қытай (Шымкент-Тараз)',
        distanceKm: 180.0,
        avgDurationMinutes: 135,
        riskLevel: 'Қатерлі (Монотонды ұзақ жол)',
        isFavorite: false,
        notes: 'Ұзақ түзу жол, жүргізушілердің көзі ілініп кету қаупі жоғары.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      RouteModel(
        id: 'route-004',
        title: 'Алматы — Бішкек трассасы',
        distanceKm: 235.0,
        avgDurationMinutes: 210,
        riskLevel: 'Орташа (Көлік тығыздығы жоғары)',
        isFavorite: false,
        notes: 'Ауыр жүк көліктері көп жүретін трасса.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      RouteModel(
        id: 'route-005',
        title: 'Қарағанды — Балқаш тасжолы',
        distanceKm: 380.0,
        avgDurationMinutes: 260,
        riskLevel: 'Қатерлі (Шаршау қаупі жоғары)',
        isFavorite: true,
        notes: 'Далалы аймақ, түнгі жел және жолдың монотондығы ұйқы шақырады.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    for (final r in initialRoutes) {
      await db.insert('routes', r.toMap());
    }

    final initialSessions = SessionModel.getSampleHistory();
    for (final s in initialSessions) {
      await db.insert('sessions', s.toMap());
    }

    final alert1 = AlertEventModel(
      id: 'alert-001',
      sessionId: 'sess-002',
      timestamp: now.subtract(const Duration(days: 1, hours: 2, minutes: 40)),
      alertType: 'yawn',
      earValue: 0.22,
      actionTaken: 'Аудио ескерту берілді',
    );
    final alert2 = AlertEventModel(
      id: 'alert-002',
      sessionId: 'sess-003',
      timestamp: now.subtract(const Duration(days: 2, hours: 4, minutes: 15)),
      alertType: 'microsleep',
      earValue: 0.14,
      actionTaken: 'Төтенше сирена ойнатылды, жүргізуші оянды',
    );
    await db.insert('alert_events', alert1.toMap());
    await db.insert('alert_events', alert2.toMap());
  }

  // ==========================================
  // ROUTE CRUD + SEARCH + FILTER + SORT
  // ==========================================

  /// CREATE: Жаңа бағыт қосу
  Future<int> insertRoute(RouteModel route) async {
    if (kIsWeb) {
      _webRoutes.removeWhere((r) => r.id == route.id);
      _webRoutes.insert(0, route);
      return 1;
    }

    final db = await database;
    try {
      return await db!.insert(
        'routes',
        route.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error inserting route: $e');
      rethrow;
    }
  }

  /// READ: Барлық бағыттарды оқу, іздеу, сүзгілеу және кемінде екі параметр бойынша сұрыптау
  Future<List<RouteModel>> getRoutes({
    String query = '',
    bool onlyFavorites = false,
    String? riskFilter,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    if (kIsWeb) {
      var result = List<RouteModel>.from(_webRoutes);

      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        result = result
            .where((r) =>
                r.title.toLowerCase().contains(q) ||
                r.riskLevel.toLowerCase().contains(q) ||
                r.notes.toLowerCase().contains(q))
            .toList();
      }

      if (onlyFavorites) {
        result = result.where((r) => r.isFavorite).toList();
      }

      if (riskFilter != null && riskFilter.isNotEmpty && riskFilter != 'Барлығы') {
        result = result.where((r) => r.riskLevel.contains(riskFilter)).toList();
      }

      result.sort((a, b) {
        int comp = 0;
        if (sortBy == 'distance_km') {
          comp = a.distanceKm.compareTo(b.distanceKm);
        } else if (sortBy == 'avg_duration_minutes') {
          comp = a.avgDurationMinutes.compareTo(b.avgDurationMinutes);
        } else if (sortBy == 'title') {
          comp = a.title.compareTo(b.title);
        } else {
          comp = a.createdAt.compareTo(b.createdAt);
        }
        return ascending ? comp : -comp;
      });

      return result;
    }

    final db = await database;
    try {
      final List<String> whereClauses = [];
      final List<dynamic> whereArgs = [];

      if (query.trim().isNotEmpty) {
        whereClauses.add('(title LIKE ? OR risk_level LIKE ? OR notes LIKE ?)');
        final searchArg = '%${query.trim()}%';
        whereArgs.addAll([searchArg, searchArg, searchArg]);
      }

      if (onlyFavorites) {
        whereClauses.add('is_favorite = 1');
      }

      if (riskFilter != null && riskFilter.isNotEmpty && riskFilter != 'Барлығы') {
        whereClauses.add('risk_level LIKE ?');
        whereArgs.add('%$riskFilter%');
      }

      final String? whereString =
          whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
      final String orderDirection = ascending ? 'ASC' : 'DESC';
      final String orderBy = '$sortBy $orderDirection';

      final List<Map<String, dynamic>> maps = await db!.query(
        'routes',
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: orderBy,
      );

      return maps.map((map) => RouteModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching routes: $e');
      return [];
    }
  }

  /// READ: Жалғыз бағытты ID бойынша алу
  Future<RouteModel?> getRouteById(String id) async {
    if (kIsWeb) {
      final matches = _webRoutes.where((r) => r.id == id);
      return matches.isNotEmpty ? matches.first : null;
    }

    final db = await database;
    try {
      final maps = await db!.query(
        'routes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return RouteModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting route by id: $e');
      return null;
    }
  }

  /// UPDATE: Бар бағытты өзгерту
  Future<int> updateRoute(RouteModel route) async {
    if (kIsWeb) {
      final index = _webRoutes.indexWhere((r) => r.id == route.id);
      if (index != -1) {
        _webRoutes[index] = route;
        return 1;
      }
      return 0;
    }

    final db = await database;
    try {
      return await db!.update(
        'routes',
        route.toMap(),
        where: 'id = ?',
        whereArgs: [route.id],
      );
    } catch (e) {
      debugPrint('Error updating route: $e');
      rethrow;
    }
  }

  /// UPDATE FAVORITE: Таңдаулы күйін ауыстыру
  Future<bool> toggleFavoriteRoute(String id) async {
    if (kIsWeb) {
      final route = await getRouteById(id);
      if (route == null) return false;
      final newStatus = !route.isFavorite;
      await updateRoute(route.copyWith(isFavorite: newStatus));
      return newStatus;
    }

    final db = await database;
    try {
      final route = await getRouteById(id);
      if (route == null) return false;

      final newStatus = !route.isFavorite;
      await db!.update(
        'routes',
        {'is_favorite': newStatus ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      return newStatus;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  /// DELETE: Бағытты өшіру
  Future<int> deleteRoute(String id) async {
    if (kIsWeb) {
      _webRoutes.removeWhere((r) => r.id == id);
      return 1;
    }

    final db = await database;
    try {
      return await db!.delete(
        'routes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting route: $e');
      rethrow;
    }
  }

  // ==========================================
  // SESSION CRUD + FILTER + SORT
  // ==========================================

  Future<int> insertSession(SessionModel session) async {
    if (kIsWeb) {
      _webSessions.removeWhere((s) => s.id == session.id);
      _webSessions.insert(0, session);
      return 1;
    }

    final db = await database;
    try {
      return await db!.insert(
        'sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error inserting session: $e');
      rethrow;
    }
  }

  Future<List<SessionModel>> getSessions({
    String? statusFilter,
    bool onlyWithAlerts = false,
    String sortBy = 'start_time',
    bool ascending = false,
  }) async {
    if (kIsWeb) {
      var result = List<SessionModel>.from(_webSessions);

      if (statusFilter != null && statusFilter != 'Барлығы') {
        result = result.where((s) => s.status == statusFilter).toList();
      }

      if (onlyWithAlerts) {
        result = result.where((s) => s.drowsinessAlerts > 0).toList();
      }

      result.sort((a, b) {
        int comp = 0;
        if (sortBy == 'safety_score') {
          comp = a.safetyScore.compareTo(b.safetyScore);
        } else if (sortBy == 'duration_seconds') {
          comp = a.duration.inSeconds.compareTo(b.duration.inSeconds);
        } else {
          comp = a.startTime.compareTo(b.startTime);
        }
        return ascending ? comp : -comp;
      });

      return result;
    }

    final db = await database;
    try {
      final List<String> whereClauses = [];
      final List<dynamic> whereArgs = [];

      if (statusFilter != null && statusFilter != 'Барлығы') {
        whereClauses.add('status = ?');
        whereArgs.add(statusFilter);
      }

      if (onlyWithAlerts) {
        whereClauses.add('drowsiness_alerts > 0');
      }

      final String? whereString =
          whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
      final String orderDirection = ascending ? 'ASC' : 'DESC';
      final String orderBy = '$sortBy $orderDirection';

      final List<Map<String, dynamic>> maps = await db!.query(
        'sessions',
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: orderBy,
      );

      return maps.map((map) => SessionModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }

  Future<int> deleteSession(String id) async {
    if (kIsWeb) {
      _webSessions.removeWhere((s) => s.id == id);
      return 1;
    }

    final db = await database;
    try {
      return await db!.delete(
        'sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }

  // ==========================================
  // VEHICLE & EMERGENCY CONTACT & USER
  // ==========================================

  Future<UserModel?> getUser(String id) async {
    if (kIsWeb) {
      return _webUser ?? UserModel.current();
    }

    final db = await database;
    try {
      final maps = await db!.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<int> updateUser(UserModel user) async {
    if (kIsWeb) {
      _webUser = user;
      return 1;
    }

    final db = await database;
    try {
      return await db!.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<VehicleModel?> getDefaultVehicle(String userId) async {
    if (kIsWeb) {
      return _webVehicle;
    }

    final db = await database;
    try {
      final maps = await db!.query(
        'vehicles',
        where: 'user_id = ? AND is_default = 1',
        whereArgs: [userId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return VehicleModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching default vehicle: $e');
      return null;
    }
  }

  Future<int> saveVehicle(VehicleModel vehicle) async {
    if (kIsWeb) {
      _webVehicle = vehicle;
      return 1;
    }

    final db = await database;
    try {
      return await db!.insert(
        'vehicles',
        vehicle.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving vehicle: $e');
      rethrow;
    }
  }

  Future<EmergencyContactModel?> getPrimaryEmergencyContact(String userId) async {
    if (kIsWeb) {
      return _webContact;
    }

    final db = await database;
    try {
      final maps = await db!.query(
        'emergency_contacts',
        where: 'user_id = ? AND is_primary = 1',
        whereArgs: [userId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return EmergencyContactModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching contact: $e');
      return null;
    }
  }

  Future<int> saveEmergencyContact(EmergencyContactModel contact) async {
    if (kIsWeb) {
      _webContact = contact;
      return 1;
    }

    final db = await database;
    try {
      return await db!.insert(
        'emergency_contacts',
        contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving contact: $e');
      rethrow;
    }
  }

  // ==========================================
  // ALERT EVENTS
  // ==========================================

  Future<int> insertAlertEvent(AlertEventModel event) async {
    if (kIsWeb) {
      _webAlerts.add(event);
      return 1;
    }

    final db = await database;
    try {
      return await db!.insert('alert_events', event.toMap());
    } catch (e) {
      debugPrint('Error inserting alert event: $e');
      rethrow;
    }
  }

  Future<List<AlertEventModel>> getAlertsForSession(String sessionId) async {
    if (kIsWeb) {
      return _webAlerts.where((a) => a.sessionId == sessionId).toList();
    }

    final db = await database;
    try {
      final maps = await db!.query(
        'alert_events',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'timestamp ASC',
      );
      return maps.map((m) => AlertEventModel.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return [];
    }
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
