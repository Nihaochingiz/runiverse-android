import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class RunEntry {
  const RunEntry({
    this.id,
    required this.date,
    required this.distanceKm,
    required this.durationMinutes,
    this.note = '',
  });
  final int? id;
  final DateTime date;
  final double distanceKm;
  final int durationMinutes;
  final String note;
  double get pace => distanceKm == 0 ? 0 : durationMinutes / distanceKm;
  Map<String, Object?> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'distance_km': distanceKm,
    'duration_minutes': durationMinutes,
    'note': note,
  };
  factory RunEntry.fromMap(Map<String, Object?> map) => RunEntry(
    id: map['id'] as int,
    date: DateTime.parse(map['date'] as String),
    distanceKm: (map['distance_km'] as num).toDouble(),
    durationMinutes: map['duration_minutes'] as int,
    note: map['note'] as String,
  );
}

class Reward {
  const Reward({
    this.id,
    required this.title,
    required this.costKm,
    this.redeemed = false,
  });
  final int? id;
  final String title;
  final double costKm;
  final bool redeemed;
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'cost_km': costKm,
    'redeemed': redeemed ? 1 : 0,
  };
  factory Reward.fromMap(Map<String, Object?> map) => Reward(
    id: map['id'] as int,
    title: map['title'] as String,
    costKm: (map['cost_km'] as num).toDouble(),
    redeemed: map['redeemed'] == 1,
  );
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      join(root, 'runiverse.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE runs(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, distance_km REAL NOT NULL, duration_minutes INTEGER NOT NULL, note TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE rewards(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, cost_km REAL NOT NULL, redeemed INTEGER NOT NULL DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.insert('settings', {'key': 'game_enabled', 'value': 'true'});
        await db.insert('settings', {'key': 'spend_km', 'value': 'false'});
      },
    );
    return _database!;
  }

  Future<List<RunEntry>> getRuns() async => (await (await database).query(
    'runs',
    orderBy: 'date DESC',
  )).map(RunEntry.fromMap).toList();
  Future<void> addRun(RunEntry run) async =>
      (await database).insert('runs', run.toMap()..remove('id'));
  Future<void> deleteRun(int id) async =>
      (await database).delete('runs', where: 'id = ?', whereArgs: [id]);
  Future<List<Reward>> getRewards() async => (await (await database).query(
    'rewards',
    orderBy: 'redeemed, cost_km',
  )).map(Reward.fromMap).toList();
  Future<void> addReward(Reward reward) async =>
      (await database).insert('rewards', reward.toMap()..remove('id'));
  Future<void> redeemReward(int id) async => (await database).update(
    'rewards',
    {'redeemed': 1},
    where: 'id = ?',
    whereArgs: [id],
  );
  Future<void> deleteReward(int id) async =>
      (await database).delete('rewards', where: 'id = ?', whereArgs: [id]);
  Future<bool> getSetting(String key, {required bool fallback}) async {
    final rows = await (await database).query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? fallback : rows.first['value'] == 'true';
  }

  Future<void> setSetting(String key, bool value) async =>
      (await database).insert('settings', {
        'key': key,
        'value': value.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
}
