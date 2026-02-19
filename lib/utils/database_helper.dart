import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cleversync_parking.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Parking entries table
    await db.execute('''
      CREATE TABLE parking_entries (
        id TEXT PRIMARY KEY,
        token TEXT NOT NULL,
        vehicle_number TEXT NOT NULL,
        owner_name TEXT,
        mobile TEXT,
        model TEXT,
        remark TEXT,
        vehicle_type TEXT,
        payment_status TEXT DEFAULT 'due',
        payment_method TEXT,
        amount_paid REAL DEFAULT 0,
        entry_time TEXT NOT NULL,
        exit_time TEXT,
        duration_minutes INTEGER,
        fee REAL,
        status TEXT DEFAULT 'parked',
        location_id TEXT,
        is_pass_member INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Members / Pass holders table
    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        vehicle_number TEXT NOT NULL,
        employee_id TEXT,
        mobile TEXT,
        vehicle_type TEXT,
        pass_type TEXT,
        amount REAL,
        payment_method TEXT,
        payment_status TEXT DEFAULT 'paid',
        start_date TEXT,
        expiry_date TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT
      )
    ''');

    // Vehicle types table
    await db.execute('''
      CREATE TABLE vehicle_types (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        area REAL DEFAULT 0,
        capacity INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Rates table
    await db.execute('''
      CREATE TABLE rates (
        id TEXT PRIMARY KEY,
        vehicle_type_id TEXT NOT NULL,
        slot_number INTEGER,
        start_hour INTEGER DEFAULT 0,
        end_hour INTEGER DEFAULT 24,
        amount REAL NOT NULL,
        created_at TEXT
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Insert default vehicle types
    final now = DateTime.now().toIso8601String();
    await db.insert('vehicle_types', {
      'id': 'vt_two_wheeler',
      'name': 'Two Wheeler',
      'area': 40.0,
      'capacity': 250,
      'created_at': now,
    });
    await db.insert('vehicle_types', {
      'id': 'vt_cycle',
      'name': 'Cycle',
      'area': 0.0,
      'capacity': 0,
      'created_at': now,
    });

    // Insert default rate
    await db.insert('rates', {
      'id': 'rate_default',
      'vehicle_type_id': 'vt_two_wheeler',
      'slot_number': 1,
      'start_hour': 0,
      'end_hour': 24,
      'amount': 10.0,
      'created_at': now,
    });

    // Insert default settings
    final defaultSettings = {
      'business_name': 'Cleversync Parking',
      'address1': '',
      'address2': '',
      'phone': '',
      'footer1': 'Key and other belongings are at owner\'s risk',
      'footer2': '',
      'upi_id': '',
      'gst_percent': '0',
      'allow_amount_edit': 'false',
      'allow_local_search': 'true',
      'max_recent_entries': '10',
      'location_identity': '',
    };
    for (final entry in defaultSettings.entries) {
      await db.insert('settings', {'key': entry.key, 'value': entry.value});
    }
  }

  // ===== PARKING ENTRIES =====
  Future<String> insertEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('parking_entries', entry);
    return entry['id'];
  }

  Future<List<Map<String, dynamic>>> getEntries({
    String? status,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> args = [];

    if (status != null && status != 'all') {
      where += ' AND status = ?';
      args.add(status);
    }
    if (dateFrom != null) {
      where += ' AND entry_time >= ?';
      args.add(dateFrom);
    }
    if (dateTo != null) {
      where += ' AND entry_time <= ?';
      args.add(dateTo);
    }
    if (search != null && search.isNotEmpty) {
      where += ' AND (vehicle_number LIKE ? OR owner_name LIKE ? OR token LIKE ?)';
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }

    return await db.query(
      'parking_entries',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'entry_time DESC',
    );
  }

  Future<Map<String, dynamic>?> findActiveEntry(String vehicleOrToken) async {
    final db = await database;
    final results = await db.query(
      'parking_entries',
      where: "(vehicle_number = ? OR token = ?) AND status = 'parked'",
      whereArgs: [vehicleOrToken.toUpperCase(), vehicleOrToken],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<int> updateEntry(String id, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update(
      'parking_entries',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getNextTokenNumber() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM parking_entries WHERE DATE(entry_time) = DATE('now', 'localtime')",
    );
    final count = (result.first['cnt'] as int?) ?? 0;
    return count + 1;
  }

  // ===== MEMBERS =====
  Future<String> insertMember(Map<String, dynamic> member) async {
    final db = await database;
    await db.insert('members', member);
    return member['id'];
  }

  Future<List<Map<String, dynamic>>> getMembers({String? search}) async {
    final db = await database;
    if (search != null && search.isNotEmpty) {
      return await db.query(
        'members',
        where: 'name LIKE ? OR vehicle_number LIKE ? OR employee_id LIKE ?',
        whereArgs: ['%$search%', '%$search%', '%$search%'],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query('members', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getMemberByVehicle(String vehicleNumber) async {
    final db = await database;
    final results = await db.query(
      'members',
      where: "vehicle_number = ? AND status = 'active'",
      whereArgs: [vehicleNumber.toUpperCase()],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<int> updateMember(String id, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update('members', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMember(String id) async {
    final db = await database;
    return await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // ===== VEHICLE TYPES =====
  Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    final db = await database;
    return await db.query('vehicle_types', orderBy: 'name ASC');
  }

  Future<String> insertVehicleType(Map<String, dynamic> vt) async {
    final db = await database;
    await db.insert('vehicle_types', vt);
    return vt['id'];
  }

  Future<int> updateVehicleType(String id, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update('vehicle_types', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicleType(String id) async {
    final db = await database;
    return await db.delete('vehicle_types', where: 'id = ?', whereArgs: [id]);
  }

  // ===== RATES =====
  Future<List<Map<String, dynamic>>> getRatesForType(String vehicleTypeId) async {
    final db = await database;
    return await db.query(
      'rates',
      where: 'vehicle_type_id = ?',
      whereArgs: [vehicleTypeId],
      orderBy: 'slot_number ASC',
    );
  }

  Future<double> calculateFee(String vehicleTypeId, int durationMinutes) async {
    final rates = await getRatesForType(vehicleTypeId);
    if (rates.isEmpty) return 10.0;
    final hours = (durationMinutes / 60).ceil();
    for (final rate in rates) {
      final start = rate['start_hour'] as int;
      final end = rate['end_hour'] as int;
      if (hours >= start && hours <= end) {
        return (rate['amount'] as num).toDouble();
      }
    }
    return (rates.last['amount'] as num).toDouble();
  }

  Future<void> upsertRate(Map<String, dynamic> rate) async {
    final db = await database;
    await db.insert('rates', rate, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteRate(String id) async {
    final db = await database;
    return await db.delete('rates', where: 'id = ?', whereArgs: [id]);
  }

  // ===== SETTINGS =====
  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    final map = <String, String>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String? ?? '';
    }
    return map;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveAllSettings(Map<String, String> settings) async {
    for (final entry in settings.entries) {
      await saveSetting(entry.key, entry.value);
    }
  }

  // ===== ANALYTICS =====
  Future<Map<String, dynamic>> getDashboardStats(String dateFrom, String dateTo) async {
    final db = await database;

    final entries = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN status = 'parked' THEN 1 ELSE 0 END) as currently_parked,
        SUM(CASE WHEN status = 'exited' THEN 1 ELSE 0 END) as total_exits,
        SUM(CASE WHEN status = 'exited' THEN fee ELSE 0 END) as total_revenue,
        SUM(CASE WHEN status = 'exited' AND payment_status = 'paid' THEN fee ELSE 0 END) as collected_revenue
      FROM parking_entries
      WHERE entry_time >= ? AND entry_time <= ?
    ''', [dateFrom, dateTo]);

    final memberStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_members,
        SUM(CASE WHEN status = 'active' AND expiry_date >= DATE('now') THEN 1 ELSE 0 END) as active_members,
        SUM(CASE WHEN payment_status = 'paid' THEN amount ELSE 0 END) as member_revenue
      FROM members
      WHERE created_at >= ? AND created_at <= ?
    ''', [dateFrom, dateTo]);

    final vehicleWise = await db.rawQuery('''
      SELECT vehicle_type, COUNT(*) as count, SUM(fee) as revenue
      FROM parking_entries
      WHERE entry_time >= ? AND entry_time <= ? AND status = 'exited'
      GROUP BY vehicle_type
    ''', [dateFrom, dateTo]);

    return {
      'entries': entries.first,
      'members': memberStats.first,
      'vehicleWise': vehicleWise,
    };
  }
}
