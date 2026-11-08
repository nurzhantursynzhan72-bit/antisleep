import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:antisleep_ai/services/database_service.dart';

/// Нағыз antisleep_ai.db файлын жасайды (DB Browser for SQLite-та ашу үшін).
/// Іске қосу: flutter test test/create_db_file_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Create antisleep_ai.db file', () async {
    final db = await DatabaseService.instance.database;
    expect(db, isNotNull);
    // ignore: avoid_print
    print('\n=== ДЕРЕКҚОР ФАЙЛЫ: ${db!.path} ===\n');
    await db.close();
  });
}

