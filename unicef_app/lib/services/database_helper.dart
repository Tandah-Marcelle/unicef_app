import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/family.dart';
import '../models/evaluation.dart';
import '../models/group_session.dart';
import '../models/alert.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('commobi_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = join(await getDatabasesPath(), filePath);
    return await openDatabase(path, version: 6, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE families (
      id TEXT NOT NULL PRIMARY KEY, householdName TEXT NOT NULL, childCount INTEGER NOT NULL,
      status TEXT NOT NULL, neighborhood TEXT NOT NULL, lastVisitDate TEXT NOT NULL,
      isSynced INTEGER NOT NULL, photoProofPaths TEXT, phoneNumber TEXT,
      vulnerabilityStatus TEXT, latitude REAL, longitude REAL,
      region TEXT, department TEXT, arrondissement TEXT,
      createdAt TEXT NOT NULL DEFAULT (date('now')))''');

    await db.execute('''CREATE TABLE evaluations (
      id TEXT NOT NULL PRIMARY KEY, familyId TEXT NOT NULL,
      hasBirthCertificate INTEGER NOT NULL, hasChildrenWithDisabilities INTEGER NOT NULL,
      bestInterestUnderstood INTEGER NOT NULL, vaccinationsUpToDate INTEGER NOT NULL,
      exclusiveBreastfeeding INTEGER NOT NULL, bedNetsUsed INTEGER NOT NULL,
      handwashingWithSoap INTEGER NOT NULL, practicesBudgeting INTEGER NOT NULL,
      corporalPunishmentUsed INTEGER NOT NULL, positiveReinforcementUsed INTEGER NOT NULL,
      visitNotes TEXT NOT NULL, visitDate TEXT NOT NULL, isSynced INTEGER NOT NULL,
      photoProofPaths TEXT,
      FOREIGN KEY (familyId) REFERENCES families (id) ON DELETE CASCADE)''');

    await db.execute('''CREATE TABLE group_sessions (
      id TEXT NOT NULL PRIMARY KEY, sessionDate TEXT NOT NULL, location TEXT NOT NULL,
      menAttendance INTEGER NOT NULL, womenAttendance INTEGER NOT NULL,
      topicCovered TEXT NOT NULL, isSynced INTEGER NOT NULL,
      photoProofPaths TEXT, latitude REAL, longitude REAL)''');

    await db.execute('''CREATE TABLE alerts (
      id TEXT NOT NULL PRIMARY KEY, riskCategory TEXT NOT NULL,
      anonymizedDescription TEXT NOT NULL, isRedPriority INTEGER NOT NULL,
      incidentDate TEXT NOT NULL, isSynced INTEGER NOT NULL,
      latitude REAL, longitude REAL)''');

    await db.execute('''CREATE TABLE user_profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT, fullName TEXT NOT NULL,
      role TEXT NOT NULL, facilitatorId TEXT NOT NULL, region TEXT NOT NULL,
      district TEXT NOT NULL, profileImagePath TEXT)''');

    await db.insert('user_profile', {
      'fullName': 'Marie Nguemo', 'role': 'Senior Field Facilitator',
      'facilitatorId': 'MINPROFF-2024-0042', 'region': 'Extrême-Nord',
      'district': 'Mora', 'profileImagePath': null,
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: add photo proof paths + user_profile table
    if (oldVersion < 2) {
      for (final sql in [
        'ALTER TABLE families ADD COLUMN photoProofPaths TEXT',
        'ALTER TABLE families ADD COLUMN phoneNumber TEXT',
        'ALTER TABLE families ADD COLUMN vulnerabilityStatus TEXT',
        'ALTER TABLE evaluations ADD COLUMN photoProofPaths TEXT',
        'ALTER TABLE group_sessions ADD COLUMN photoProofPaths TEXT',
      ]) { try { await db.execute(sql); } catch (_) {} }

      await db.execute('''CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT, fullName TEXT NOT NULL,
        role TEXT NOT NULL, facilitatorId TEXT NOT NULL, region TEXT NOT NULL,
        district TEXT NOT NULL, profileImagePath TEXT)''');

      final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM user_profile')) ?? 0;
      if (c == 0) {
        await db.insert('user_profile', {
          'fullName': 'Marie Nguemo', 'role': 'Senior Field Facilitator',
          'facilitatorId': 'MINPROFF-2024-0042', 'region': 'Extrême-Nord',
          'district': 'Mora', 'profileImagePath': null,
        });
      }
    }

    // v2 → v3: add GPS columns
    if (oldVersion < 3) {
      for (final sql in [
        'ALTER TABLE families ADD COLUMN latitude REAL',
        'ALTER TABLE families ADD COLUMN longitude REAL',
        'ALTER TABLE group_sessions ADD COLUMN latitude REAL',
        'ALTER TABLE group_sessions ADD COLUMN longitude REAL',
        'ALTER TABLE alerts ADD COLUMN latitude REAL',
        'ALTER TABLE alerts ADD COLUMN longitude REAL',
      ]) { try { await db.execute(sql); } catch (_) {} }
    }

    // v3 → v4: ensure phoneNumber, vulnerabilityStatus and GPS columns exist
    // (catches devices that had v1 schema and skipped the v2 migration partially,
    //  or any install that went straight from v1 to v3)
    if (oldVersion < 4) {
      for (final sql in [
        'ALTER TABLE families ADD COLUMN phoneNumber TEXT',
        'ALTER TABLE families ADD COLUMN vulnerabilityStatus TEXT',
        'ALTER TABLE families ADD COLUMN photoProofPaths TEXT',
        'ALTER TABLE families ADD COLUMN latitude REAL',
        'ALTER TABLE families ADD COLUMN longitude REAL',
        'ALTER TABLE evaluations ADD COLUMN photoProofPaths TEXT',
        'ALTER TABLE group_sessions ADD COLUMN photoProofPaths TEXT',
        'ALTER TABLE group_sessions ADD COLUMN latitude REAL',
        'ALTER TABLE group_sessions ADD COLUMN longitude REAL',
        'ALTER TABLE alerts ADD COLUMN latitude REAL',
        'ALTER TABLE alerts ADD COLUMN longitude REAL',
      ]) { try { await db.execute(sql); } catch (_) {} }

      // Ensure user_profile exists
      await db.execute('''CREATE TABLE IF NOT EXISTS user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT, fullName TEXT NOT NULL,
        role TEXT NOT NULL, facilitatorId TEXT NOT NULL, region TEXT NOT NULL,
        district TEXT NOT NULL, profileImagePath TEXT)''');

      final c = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM user_profile')) ?? 0;
      if (c == 0) {
        await db.insert('user_profile', {
          'fullName': 'Marie Nguemo', 'role': 'Senior Field Facilitator',
          'facilitatorId': 'MINPROFF-2024-0042', 'region': 'Extrême-Nord',
          'district': 'Mora', 'profileImagePath': null,
        });
      }
    }

    // v4 → v5: admin hierarchy + createdAt on families
    if (oldVersion < 5) {
      for (final sql in [
        'ALTER TABLE families ADD COLUMN region TEXT',
        'ALTER TABLE families ADD COLUMN department TEXT',
        'ALTER TABLE families ADD COLUMN arrondissement TEXT',
        "ALTER TABLE families ADD COLUMN createdAt TEXT NOT NULL DEFAULT (date('now'))",
      ]) { try { await db.execute(sql); } catch (_) {} }
    }

    // v5 → v6: ensure createdAt exists (fixes devices where v5 migration silently failed)
    if (oldVersion < 6) {
      for (final sql in [
        'ALTER TABLE families ADD COLUMN region TEXT',
        'ALTER TABLE families ADD COLUMN department TEXT',
        'ALTER TABLE families ADD COLUMN arrondissement TEXT',
        "ALTER TABLE families ADD COLUMN createdAt TEXT NOT NULL DEFAULT (date('now'))",
      ]) { try { await db.execute(sql); } catch (_) {} }
    }
  }

  String _ph(List items) => items.map((_) => '?').join(',');

  // ── Families ──────────────────────────────────────────────────────────────
  Future<void> insertFamily(Family f) async {
    final db = await instance.database;
    await db.insert('families', f.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Family>> getAllFamilies() async {
    final db = await instance.database;
    final rows = await db.query('families', orderBy: 'householdName ASC');
    return rows.map(Family.fromMap).toList();
  }

  Future<List<Family>> getUnsyncedFamilies() async {
    final db = await instance.database;
    final rows = await db.query('families', where: 'isSynced = 0');
    return rows.map(Family.fromMap).toList();
  }

  Future<void> markFamiliesAsSynced(List<String> ids) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE families SET isSynced=1 WHERE id IN (${_ph(ids)})', ids);
  }

  // ── Evaluations ───────────────────────────────────────────────────────────
  Future<void> insertEvaluation(Evaluation e) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('evaluations', e.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.rawUpdate('UPDATE families SET lastVisitDate=?,isSynced=0 WHERE id=?',
          [e.visitDate, e.familyId]);
    });
  }

  Future<List<Evaluation>> getEvaluationsForFamily(String fid) async {
    final db = await instance.database;
    final rows = await db.query('evaluations',
        where: 'familyId=?', whereArgs: [fid], orderBy: 'visitDate DESC');
    return rows.map(Evaluation.fromMap).toList();
  }

  Future<List<Evaluation>> getUnsyncedEvaluations() async {
    final db = await instance.database;
    final rows = await db.query('evaluations', where: 'isSynced=0');
    return rows.map(Evaluation.fromMap).toList();
  }

  Future<void> markEvaluationsAsSynced(List<String> ids) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE evaluations SET isSynced=1 WHERE id IN (${_ph(ids)})', ids);
  }

  // ── Group Sessions ────────────────────────────────────────────────────────
  Future<void> insertGroupSession(GroupSession s) async {
    final db = await instance.database;
    await db.insert('group_sessions', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<GroupSession>> getAllGroupSessions() async {
    final db = await instance.database;
    final rows = await db.query('group_sessions', orderBy: 'sessionDate DESC');
    return rows.map(GroupSession.fromMap).toList();
  }

  Future<List<GroupSession>> getUnsyncedGroupSessions() async {
    final db = await instance.database;
    final rows = await db.query('group_sessions', where: 'isSynced=0');
    return rows.map(GroupSession.fromMap).toList();
  }

  Future<void> markGroupSessionsAsSynced(List<String> ids) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE group_sessions SET isSynced=1 WHERE id IN (${_ph(ids)})', ids);
  }

  // ── Alerts ────────────────────────────────────────────────────────────────
  Future<void> insertAlert(Alert a) async {
    final db = await instance.database;
    await db.insert('alerts', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Alert>> getAllAlerts() async {
    final db = await instance.database;
    final rows = await db.query('alerts', orderBy: 'incidentDate DESC');
    return rows.map(Alert.fromMap).toList();
  }

  Future<List<Alert>> getUnsyncedAlerts() async {
    final db = await instance.database;
    final rows = await db.query('alerts', where: 'isSynced=0');
    return rows.map(Alert.fromMap).toList();
  }

  Future<void> markAlertsAsSynced(List<String> ids) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE alerts SET isSynced=1 WHERE id IN (${_ph(ids)})', ids);
  }

  // ── User Profile ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await instance.database;
    final maps = await db.query('user_profile', limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> updateUserProfileImage(String? path) async {
    final db = await instance.database;
    await db.update('user_profile', {'profileImagePath': path});
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update('user_profile', data);
  }

  // ── Bulk upserts (server pull) ─────────────────────────────────────────────
  Future<void> _upsertBatch(String table, List<Map<String, dynamic>> maps) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final m in maps) {
      batch.insert(table, m, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Merges server-pulled families into the local DB (upsert by id).
  Future<void> upsertFamilies(List<Family> items) =>
      _upsertBatch('families', items.map((e) => e.toMap()).toList());

  /// Merges server-pulled evaluations (does not touch families' visit dates).
  Future<void> upsertEvaluations(List<Evaluation> items) =>
      _upsertBatch('evaluations', items.map((e) => e.toMap()).toList());

  /// Merges server-pulled GSP sessions.
  Future<void> upsertGroupSessions(List<GroupSession> items) =>
      _upsertBatch('group_sessions', items.map((e) => e.toMap()).toList());

  /// Merges server-pulled safeguarding alerts.
  Future<void> upsertAlerts(List<Alert> items) =>
      _upsertBatch('alerts', items.map((e) => e.toMap()).toList());

  // ── Counts ────────────────────────────────────────────────────────────────
  Future<int> getUnsyncedCount() async {
    final db = await instance.database;
    int total = 0;
    for (final t in ['families', 'evaluations', 'group_sessions', 'alerts']) {
      total += Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $t WHERE isSynced=0')) ??
          0;
    }
    return total;
  }

  Future close() async => (await instance.database).close();
}
