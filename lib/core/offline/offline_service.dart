import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class OfflineService {
  static Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/etbp_driver_offline.db';
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE cached_trips (trip_id TEXT PRIMARY KEY, data TEXT, cached_at TEXT)');
      await db.execute('CREATE TABLE cached_manifests (trip_id TEXT PRIMARY KEY, data TEXT, cached_at TEXT)');
      await db.execute('CREATE TABLE action_queue (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, payload TEXT, created_at TEXT, synced INTEGER DEFAULT 0)');
    });
    return _db!;
  }

  Future<void> cacheTripData(String tripId, Map<String, dynamic> data) async {
    final db = await _getDb();
    await db.insert('cached_trips', {'trip_id': tripId, 'data': jsonEncode(data), 'cached_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedTrip(String tripId) async {
    final db = await _getDb();
    final results = await db.query('cached_trips', where: 'trip_id = ?', whereArgs: [tripId]);
    if (results.isEmpty) return null;
    return jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
  }

  Future<void> cacheManifest(String tripId, Map<String, dynamic> data) async {
    final db = await _getDb();
    await db.insert('cached_manifests', {'trip_id': tripId, 'data': jsonEncode(data), 'cached_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedManifest(String tripId) async {
    final db = await _getDb();
    final results = await db.query('cached_manifests', where: 'trip_id = ?', whereArgs: [tripId]);
    if (results.isEmpty) return null;
    return jsonDecode(results.first['data'] as String) as Map<String, dynamic>;
  }

  Future<void> queueAction(String type, Map<String, dynamic> payload) async {
    final db = await _getDb();
    await db.insert('action_queue', {'type': type, 'payload': jsonEncode(payload), 'created_at': DateTime.now().toIso8601String(), 'synced': 0});
    debugPrint('Offline: queued action $type');
  }

  Future<int> pendingActionCount() async {
    final db = await _getDb();
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM action_queue WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> syncQueue(dynamic api) async {
    final db = await _getDb();
    final pending = await db.query('action_queue', where: 'synced = 0', orderBy: 'created_at ASC');
    for (final action in pending) {
      try {
        final type = action['type'] as String;
        final payload = jsonDecode(action['payload'] as String) as Map<String, dynamic>;
        switch (type) {
          case 'status_update':
            await api.patch('/driver/trips/${payload['trip_id']}/status', data: payload['data']);
          case 'checkin':
            await api.post('/driver/trips/${payload['trip_id']}/checkin/${payload['booking_id']}');
          case 'incident':
            await api.post('/driver/trips/${payload['trip_id']}/incidents', data: payload['data']);
        }
        await db.update('action_queue', {'synced': 1}, where: 'id = ?', whereArgs: [action['id']]);
        debugPrint('Offline: synced action ${action['id']}');
      } catch (e) {
        debugPrint('Offline: sync failed: $e');
        break;
      }
    }
  }
}
