import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../logic/rules.dart';
import '../models/local_date.dart';
import '../models/records.dart';
import 'journey_repository.dart';

class SqliteJourneyRepository implements JourneyRepository {
  SqliteJourneyRepository(this._database);

  final Database _database;

  static Future<SqliteJourneyRepository> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final database = await openDatabase(
      p.join(directory.path, 'weight_slide.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE journeys (
            id TEXT PRIMARY KEY,
            start_date TEXT NOT NULL,
            starting_weight_kg REAL NOT NULL,
            weekly_target_kg REAL NOT NULL,
            active_level INTEGER NOT NULL,
            is_active INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            baseline_json TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE readings (
            id TEXT PRIMARY KEY,
            journey_id TEXT NOT NULL,
            local_date TEXT NOT NULL,
            kg REAL NOT NULL,
            recorded_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE crossings (
            id TEXT PRIMARY KEY,
            journey_id TEXT NOT NULL,
            line_number INTEGER NOT NULL,
            direction TEXT NOT NULL,
            evaluated_at TEXT NOT NULL,
            evaluation_date TEXT NOT NULL,
            moving_average REAL NOT NULL,
            line_value REAL NOT NULL,
            resulting_level INTEGER NOT NULL,
            sequence INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX readings_journey ON readings (journey_id, recorded_at)',
        );
        await db.execute(
          'CREATE INDEX crossings_journey ON crossings (journey_id, sequence)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Migrations must keep existing rows. Version 1 has nothing to apply.
      },
    );
    await _seedRules(database);
    return SqliteJourneyRepository(database);
  }

  static Future<void> _seedRules(Database database) async {
    for (var index = 0; index < defaultRuleTexts.length; index++) {
      await database.insert('settings', {
        'key': 'rule_${index + 1}',
        'value': defaultRuleTexts[index],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  @override
  Future<Journey?> activeJourney() async {
    final rows = await _database.query(
      'journeys',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _journeyFromRow(rows.first);
  }

  @override
  Future<List<Journey>> allJourneys() async {
    final rows = await _database.query('journeys', orderBy: 'created_at DESC');
    return [for (final row in rows) _journeyFromRow(row)];
  }

  @override
  Future<Journey> getJourney(String id) async {
    final rows = await _database.query(
      'journeys',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Unknown journey $id');
    }
    return _journeyFromRow(rows.first);
  }

  @override
  Future<void> insertJourney(Journey journey) async {
    await _database.insert('journeys', _journeyToRow(journey));
  }

  @override
  Future<void> saveJourney(
    Journey journey, {
    List<CrossingEvent> newCrossings = const [],
  }) async {
    await _database.transaction((txn) async {
      await txn.update(
        'journeys',
        _journeyToRow(journey),
        where: 'id = ?',
        whereArgs: [journey.id],
      );
      for (final crossing in newCrossings) {
        await txn.insert('crossings', {
          'id': crossing.id,
          'journey_id': crossing.journeyId,
          'line_number': crossing.lineNumber,
          'direction': crossing.direction.name,
          'evaluated_at': crossing.evaluatedAt.toIso8601String(),
          'evaluation_date': crossing.evaluationDate.toIso(),
          'moving_average': crossing.movingAverageKg,
          'line_value': crossing.lineValueKg,
          'resulting_level': crossing.resultingLevel,
          'sequence': crossing.sequence,
        });
      }
    });
  }

  @override
  Future<List<WeightReading>> readingsFor(String journeyId) async {
    final rows = await _database.query(
      'readings',
      where: 'journey_id = ?',
      whereArgs: [journeyId],
      orderBy: 'recorded_at ASC, id ASC',
    );
    return [
      for (final row in rows)
        WeightReading(
          id: row['id']! as String,
          journeyId: row['journey_id']! as String,
          date: LocalDate.parse(row['local_date']! as String),
          kg: (row['kg']! as num).toDouble(),
          recordedAt: DateTime.parse(row['recorded_at']! as String),
        ),
    ];
  }

  @override
  Future<void> insertReading(WeightReading reading) async {
    await _database.insert('readings', {
      'id': reading.id,
      'journey_id': reading.journeyId,
      'local_date': reading.date.toIso(),
      'kg': reading.kg,
      'recorded_at': reading.recordedAt.toIso8601String(),
    });
  }

  @override
  Future<List<CrossingEvent>> crossingsFor(String journeyId) async {
    final rows = await _database.query(
      'crossings',
      where: 'journey_id = ?',
      whereArgs: [journeyId],
      orderBy: 'sequence ASC',
    );
    return [
      for (final row in rows)
        CrossingEvent(
          id: row['id']! as String,
          journeyId: row['journey_id']! as String,
          lineNumber: row['line_number']! as int,
          direction: CrossingDirection.values.byName(
            row['direction']! as String,
          ),
          evaluatedAt: DateTime.parse(row['evaluated_at']! as String),
          evaluationDate: LocalDate.parse(row['evaluation_date']! as String),
          movingAverageKg: (row['moving_average']! as num).toDouble(),
          lineValueKg: (row['line_value']! as num).toDouble(),
          resultingLevel: row['resulting_level']! as int,
          sequence: row['sequence']! as int,
        ),
    ];
  }

  @override
  Future<List<String>> rules() async {
    final rows = await _database.query('settings', orderBy: 'key ASC');
    final values = <String, String>{};
    for (final row in rows) {
      values[row['key']! as String] = row['value']! as String;
    }
    return [
      for (var index = 1; index <= 5; index++)
        values['rule_$index'] ?? defaultRuleTexts[index - 1],
    ];
  }

  @override
  Future<void> saveRules(List<String> rules) async {
    await _database.transaction((txn) async {
      for (var index = 0; index < rules.length; index++) {
        await txn.insert('settings', {
          'key': 'rule_${index + 1}',
          'value': rules[index],
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Map<String, Object?> _journeyToRow(Journey journey) {
    return {
      'id': journey.id,
      'start_date': journey.startDate.toIso(),
      'starting_weight_kg': journey.startingWeightKg,
      'weekly_target_kg': journey.weeklyTargetKg,
      'active_level': journey.activeLevel,
      'is_active': journey.isActive ? 1 : 0,
      'created_at': journey.createdAt.toIso8601String(),
      'baseline_json': jsonEncode(journey.baseline.toJson()),
    };
  }

  Journey _journeyFromRow(Map<String, Object?> row) {
    final baseline = jsonDecode(row['baseline_json']! as String);
    return Journey(
      id: row['id']! as String,
      startDate: LocalDate.parse(row['start_date']! as String),
      startingWeightKg: (row['starting_weight_kg']! as num).toDouble(),
      weeklyTargetKg: (row['weekly_target_kg']! as num).toDouble(),
      activeLevel: row['active_level']! as int,
      isActive: (row['is_active']! as int) == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      baseline: TrendSnapshot.fromJson(
        Map<String, dynamic>.from(baseline as Map),
      ),
    );
  }
}
