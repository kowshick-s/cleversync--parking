import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('cleversync_parking.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parking_entries (
        id TEXT PRIMARY KEY,
        token TEXT,
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
        duration_minutes INTEGER DEFAULT 0,
        fee REAL DEFAULT 0,
        status TEXT DEFAULT 'parked',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        vehicle_number TEXT,
        name TEXT,
        employee_id TEXT,
        mobile TEXT,
        amount REAL DEFAULT 0,
        payment_method TEXT,
        payment_status TEXT,
        vehicle_type TEXT,
        pass_type TEXT,
        start_date TEXT,
        expiry_date TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicle_types (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        area REAL DEFAULT 0,
        capacity INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE rates (
        id TEXT PRIMARY KEY,
        vehicle_type_id TEXT,
        slot_number INTEGER DEFAULT 1,
        start_hour INTEGER DEFAULT 0,
        end_hour INTEGER DEFAULT 24,
        amount REAL DEFAULT 10,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Default vehicle types
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
      'area': 20.0,
      'capacity': 50,
      'created_at': now,
    });
    await db.insert('vehicle_types', {
      'id': 'vt_car',
      'name': 'Car',
      'area': 80.0,
      'capacity': 50,
      'created_at': now,
    });

    // Default rates - Rs.10 per 24 hours
    await db.insert('rates', {
      'id': 'rate_two_wheeler_1',
      'vehicle_type_id': 'vt_two_wheeler',
      'slot_number': 1,
      'start_hour': 0,
      'end_hour': 24,
      'amount': 10.0,
      'created_at': now,
    });
    await db.insert('rates', {
      'id': 'rate_cycle_1',
      'vehicle_type_id': 'vt_cycle',
      'slot_number': 1,
      'start_hour': 0,
      'end_hour': 24,
      'amount': 5.0,
      'created_at': now,
    });
    await db.insert('rates', {
      'id': 'rate_car_1',
      'vehicle_type_id': 'vt_car',
      'slot_number': 1,
      'start_hour': 0,
      'end_hour': 24,
      'amount': 20.0,
      'created_at': now,
    });

    // Default settings
    final defaults = {
      'business_name': 'Cleversync Parking',
      'address1': '',
      'address2': '',
      'phone': '',
      'upi_id': '',
      'footer1': 'Key and other belongings are at owner\'s risk',
      'footer2': '',
      'gst_percent': '0',
      'max_recent_entries': '10',
      'allow_amount_edit': 'false',
      'allow_local_search': 'true',
      'show_token_field': 'false',
      'default_printer': 'disabled',
      'print_barcode': 'true',
    };
    for (final entry in defaults.entries) {
      await db.insert('settings', {'key': entry.key, 'value': entry.value});
    }
  }

  // ===== ENTRIES =====
  Future<void> insertEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('parking_entries', entry,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getEntries({
    String? status,
    String? dateFrom,
    String? dateTo,
    String? search,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }
    if (dateFrom != null) {
      conditions.add('entry_time >= ?');
      args.add(dateFrom);
    }
    if (dateTo != null) {
      conditions.add('entry_time <= ?');
      args.add(dateTo);
    }
    if (search != null && search.isNotEmpty) {
      conditions.add('(vehicle_number LIKE ? OR token LIKE ? OR owner_name LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    return await db.query('parking_entries',
        where: where, whereArgs: args.isEmpty ? null : args,
        orderBy: 'entry_time DESC');
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

  Future<void> updateEntry(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('parking_entries', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getNextTokenNumber() async {
    final db = await database;
    final today = DateTime.now();
    final todayStart = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM parking_entries WHERE entry_time >= ?",
        ['$todayStart 00:00:00']);
    final count = (result.first['count'] as int?) ?? 0;
    return (count + 1) % 10000;
  }

  // ===== FEE CALCULATION =====
  // This is the KEY fix - properly calculates fee based on duration
  Future<double> calculateFee(String vehicleTypeId, int durationMinutes) async {
    final db = await database;

    // Get rates for this vehicle type
    final rates = await db.query(
      'rates',
      where: 'vehicle_type_id = ?',
      whereArgs: [vehicleTypeId],
      orderBy: 'slot_number ASC',
    );

    if (rates.isEmpty) {
      // Default: Rs.10 per 24 hours
      final days = (durationMinutes / (24 * 60)).ceil();
      return days * 10.0;
    }

    // Use first rate slot - amount per 24 hours
    final ratePerDay = (rates.first['amount'] as num?)?.toDouble() ?? 10.0;
    
    // Calculate: minimum 1 day, then ceil for partial days
    if (durationMinutes <= 0) return ratePerDay;
    
    final durationHours = durationMinutes / 60.0;
    final days = (durationHours / 24).ceil();
    final totalFee = days * ratePerDay;
    
    return totalFee < ratePerDay ? ratePerDay : totalFee;
  }

  // ===== MEMBERS =====
  Future<void> insertMember(Map<String, dynamic> member) async {
    final db = await database;
    await db.insert('members', member, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMembers({String? search}) async {
    final db = await database;
    if (search != null && search.isNotEmpty) {
      return await db.query('members',
          where: 'name LIKE ? OR vehicle_number LIKE ? OR mobile LIKE ?',
          whereArgs: ['%$search%', '%$search%', '%$search%'],
          orderBy: 'created_at DESC');
    }
    return await db.query('members', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getMemberByVehicle(String vehicleNumber) async {
    final db = await database;
    final results = await db.query('members',
        where: 'vehicle_number = ?',
        whereArgs: [vehicleNumber.toUpperCase()],
        limit: 1);
    return results.isEmpty ? null : results.first;
  }

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('members', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMember(String id) async {
    final db = await database;
    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  // ===== VEHICLE TYPES =====
  Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    final db = await database;
    return await db.query('vehicle_types', orderBy: 'name ASC');
  }

  Future<void> insertVehicleType(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('vehicle_types', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateVehicleType(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('vehicle_types', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVehicleType(String id) async {
    final db = await database;
    await db.delete('vehicle_types', where: 'id = ?', whereArgs: [id]);
  }

  // ===== RATES =====
  Future<List<Map<String, dynamic>>> getRatesForType(String vehicleTypeId) async {
    final db = await database;
    return await db.query('rates',
        where: 'vehicle_type_id = ?',
        whereArgs: [vehicleTypeId],
        orderBy: 'slot_number ASC');
  }

  Future<void> upsertRate(Map<String, dynamic> rate) async {
    final db = await database;
    await db.insert('rates', rate, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRate(String id) async {
    final db = await database;
    await db.delete('rates', where: 'id = ?', whereArgs: [id]);
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

  Future<void> saveAllSettings(Map<String, String> settings) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in settings.entries) {
      batch.insert('settings', {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ===== DASHBOARD STATS =====
  Future<Map<String, dynamic>> getDashboardStats(String dateFrom, String dateTo) async {
    final db = await database;

    // Today's entries count
    final entriesResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN status = 'parked' THEN 1 ELSE 0 END) as currently_parked,
        SUM(CASE WHEN status = 'exited' THEN 1 ELSE 0 END) as total_exits,
        COALESCE(SUM(CASE WHEN status = 'exited' THEN fee ELSE 0 END), 0) as total_revenue,
        COALESCE(SUM(fee), 0) as total_collected
      FROM parking_entries
      WHERE entry_time >= ? AND entry_time <= ?
    ''', [dateFrom, dateTo]);

    // Vehicle type breakdown
    final vtResult = await db.rawQuery('''
      SELECT vehicle_type,
        COUNT(*) as count,
        SUM(CASE WHEN status = 'parked' THEN 1 ELSE 0 END) as parked,
        COALESCE(SUM(fee), 0) as revenue
      FROM parking_entries
      WHERE entry_time >= ? AND entry_time <= ?
      GROUP BY vehicle_type
    ''', [dateFrom, dateTo]);

    // Member stats
    final memberResult = await db.rawQuery('''
      SELECT COUNT(*) as total_members,
        SUM(amount) as total_pass_revenue
      FROM members
    ''');

    return {
      'entries': entriesResult.isNotEmpty ? Map<String, dynamic>.from(entriesResult.first) : {},
      'vehicle_breakdown': vtResult,
      'members': memberResult.isNotEmpty ? Map<String, dynamic>.from(memberResult.first) : {},
    };
  }
}
