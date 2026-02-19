import 'package:flutter/material.dart';
import '../utils/database_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _vehicleTypes = [];
  Map<String, String> _settings = {};
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;

  List<Map<String, dynamic>> get entries => _entries;
  List<Map<String, dynamic>> get members => _members;
  List<Map<String, dynamic>> get vehicleTypes => _vehicleTypes;
  Map<String, String> get settings => _settings;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;

  String get businessName => _settings['business_name'] ?? 'Cleversync Parking';

  // Currently parked count
  int get currentlyParked => _entries.where((e) => e['status'] == 'parked').length;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      loadEntries(),
      loadMembers(),
      loadVehicleTypes(),
      loadSettings(),
    ]);
    await loadDashboardStats();
    _isLoading = false;
    notifyListeners();
  }

  // ===== ENTRIES =====
  Future<void> loadEntries({String? status, String? dateFrom, String? dateTo, String? search}) async {
    _entries = await _db.getEntries(
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
      search: search,
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> registerEntry({
    required String vehicleNumber,
    String? ownerName,
    String? mobile,
    String? model,
    String? remark,
    String? vehicleType,
    String paymentStatus = 'due',
    String? paymentMethod,
    double amountPaid = 0,
  }) async {
    final now = DateTime.now();
    final tokenNum = await _db.getNextTokenNumber();
    final token = tokenNum.toString().padLeft(4, '0');
    final id = _uuid.v4();

    final entry = {
      'id': id,
      'token': token,
      'vehicle_number': vehicleNumber.toUpperCase(),
      'owner_name': ownerName ?? '',
      'mobile': mobile ?? '',
      'model': model ?? '',
      'remark': remark ?? '',
      'vehicle_type': vehicleType ?? 'Two Wheeler',
      'payment_status': paymentStatus,
      'payment_method': paymentMethod ?? '',
      'amount_paid': amountPaid,
      'entry_time': now.toIso8601String(),
      'status': 'parked',
      'created_at': now.toIso8601String(),
    };

    await _db.insertEntry(entry);
    await loadEntries();
    return entry;
  }

  Future<Map<String, dynamic>?> findActiveEntry(String vehicleOrToken) async {
    return await _db.findActiveEntry(vehicleOrToken);
  }

  Future<Map<String, dynamic>> processExit(String entryId) async {
    final db = DatabaseHelper.instance;
    final entries = await db.getEntries();
    final entry = entries.firstWhere((e) => e['id'] == entryId);

    final entryTime = DateTime.parse(entry['entry_time']);
    final now = DateTime.now();
    final durationMinutes = now.difference(entryTime).inMinutes;
    final vehicleTypeId = _getVehicleTypeId(entry['vehicle_type']);
    final fee = await db.calculateFee(vehicleTypeId, durationMinutes);

    final updates = {
      'exit_time': now.toIso8601String(),
      'duration_minutes': durationMinutes,
      'fee': fee,
      'status': 'exited',
      'payment_status': 'paid',
    };

    await db.updateEntry(entryId, updates);
    await loadEntries();
    await loadDashboardStats();

    return {...entry, ...updates};
  }

  String _getVehicleTypeId(String? vehicleTypeName) {
    final vt = _vehicleTypes.firstWhere(
      (v) => v['name'] == vehicleTypeName,
      orElse: () => {'id': 'vt_two_wheeler'},
    );
    return vt['id'];
  }

  // ===== MEMBERS =====
  Future<void> loadMembers({String? search}) async {
    _members = await _db.getMembers(search: search);
    notifyListeners();
  }

  Future<void> addMember(Map<String, dynamic> memberData) async {
    final now = DateTime.now();
    final member = {
      'id': _uuid.v4(),
      ...memberData,
      'vehicle_number': (memberData['vehicle_number'] ?? '').toString().toUpperCase(),
      'created_at': now.toIso8601String(),
    };
    await _db.insertMember(member);
    await loadMembers();
  }

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    await _db.updateMember(id, data);
    await loadMembers();
  }

  Future<void> deleteMember(String id) async {
    await _db.deleteMember(id);
    await loadMembers();
  }

  Future<Map<String, dynamic>?> getMemberByVehicle(String vehicleNumber) async {
    return await _db.getMemberByVehicle(vehicleNumber);
  }

  bool isMemberExpired(Map<String, dynamic> member) {
    final expiry = member['expiry_date'];
    if (expiry == null) return false;
    return DateTime.parse(expiry).isBefore(DateTime.now());
  }

  // ===== VEHICLE TYPES =====
  Future<void> loadVehicleTypes() async {
    _vehicleTypes = await _db.getVehicleTypes();
    notifyListeners();
  }

  Future<void> addVehicleType(String name, double area, int capacity) async {
    await _db.insertVehicleType({
      'id': _uuid.v4(),
      'name': name,
      'area': area,
      'capacity': capacity,
      'created_at': DateTime.now().toIso8601String(),
    });
    await loadVehicleTypes();
  }

  Future<void> updateVehicleType(String id, String name, double area, int capacity) async {
    await _db.updateVehicleType(id, {'name': name, 'area': area, 'capacity': capacity});
    await loadVehicleTypes();
  }

  Future<void> deleteVehicleType(String id) async {
    await _db.deleteVehicleType(id);
    await loadVehicleTypes();
  }

  Future<List<Map<String, dynamic>>> getRatesForType(String vehicleTypeId) async {
    return await _db.getRatesForType(vehicleTypeId);
  }

  Future<void> upsertRate(Map<String, dynamic> rate) async {
    await _db.upsertRate(rate);
  }

  Future<void> deleteRate(String id) async {
    await _db.deleteRate(id);
  }

  // ===== SETTINGS =====
  Future<void> loadSettings() async {
    _settings = await _db.getAllSettings();
    notifyListeners();
  }

  Future<void> saveSettings(Map<String, String> newSettings) async {
    await _db.saveAllSettings(newSettings);
    _settings = {..._settings, ...newSettings};
    notifyListeners();
  }

  // ===== ANALYTICS =====
  Future<void> loadDashboardStats({String? period}) async {
    final now = DateTime.now();
    String dateFrom, dateTo;

    switch (period) {
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        dateFrom = DateFormat('yyyy-MM-dd').format(yesterday) + ' 00:00:00';
        dateTo = DateFormat('yyyy-MM-dd').format(yesterday) + ' 23:59:59';
        break;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        dateFrom = DateFormat('yyyy-MM-dd').format(weekStart) + ' 00:00:00';
        dateTo = DateFormat('yyyy-MM-dd').format(now) + ' 23:59:59';
        break;
      case 'month':
        dateFrom = DateFormat('yyyy-MM-01').format(now) + ' 00:00:00';
        dateTo = DateFormat('yyyy-MM-dd').format(now) + ' 23:59:59';
        break;
      default: // today
        dateFrom = DateFormat('yyyy-MM-dd').format(now) + ' 00:00:00';
        dateTo = DateFormat('yyyy-MM-dd').format(now) + ' 23:59:59';
    }

    _dashboardStats = await _db.getDashboardStats(dateFrom, dateTo);
    notifyListeners();
  }

  // ===== HELPERS =====
  String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String formatDateTime(String? isoString) {
    if (isoString == null) return '-';
    final dt = DateTime.parse(isoString);
    return DateFormat('dd/MM/yy hh:mm a').format(dt);
  }

  String formatCurrency(dynamic amount) {
    if (amount == null) return 'Rs. 0';
    return 'Rs. ${(amount as num).toStringAsFixed(0)}';
  }
}
