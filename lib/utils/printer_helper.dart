import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

class PrinterHelper {
  static final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  static Future<List<BluetoothDevice>> getDevices() async {
    return await _printer.getBondedDevices();
  }

  static Future<bool> connect(BluetoothDevice device) async {
    try {
      await _printer.connect(device);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> disconnect() async {
    await _printer.disconnect();
  }

  static Future<bool> isConnected() async {
    return await _printer.isConnected ?? false;
  }

  static Future<void> printEntryTicket({
    required Map<String, dynamic> entry,
    required Map<String, String> settings,
  }) async {
    final connected = await isConnected();
    if (!connected) return;

    final businessName = settings['business_name'] ?? 'Cleversync Parking';
    final address1 = settings['address1'] ?? '';
    final address2 = settings['address2'] ?? '';
    final phone = settings['phone'] ?? '';
    final footer1 = settings['footer1'] ?? 'Key and other belongings are at owner\'s risk';
    final footer2 = settings['footer2'] ?? '';

    _printer.printNewLine();
    _printer.printCustom(businessName, 3, 1); // size 3, center
    if (address1.isNotEmpty) _printer.printCustom(address1, 1, 1);
    if (address2.isNotEmpty) _printer.printCustom(address2, 1, 1);
    if (phone.isNotEmpty) _printer.printCustom(phone, 1, 1);
    _printer.printNewLine();
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printCustom('ENTRY TICKET', 2, 1);
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printNewLine();

    _printer.printCustom('Token: #${entry['token']}', 2, 1);
    _printer.printNewLine();

    _printer.printLeftRight('Vehicle:', entry['vehicle_number'] ?? '', 1);
    if ((entry['owner_name'] ?? '').isNotEmpty) {
      _printer.printLeftRight('Name:', entry['owner_name'] ?? '', 1);
    }
    if ((entry['mobile'] ?? '').isNotEmpty) {
      _printer.printLeftRight('Mobile:', entry['mobile'] ?? '', 1);
    }
    if ((entry['vehicle_type'] ?? '').isNotEmpty) {
      _printer.printLeftRight('Type:', entry['vehicle_type'] ?? '', 1);
    }

    final entryTime = DateTime.parse(entry['entry_time']);
    _printer.printLeftRight('Date:', DateFormat('dd/MM/yyyy').format(entryTime), 1);
    _printer.printLeftRight('Time:', DateFormat('hh:mm a').format(entryTime), 1);

    _printer.printNewLine();
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printCustom('KEEP THIS SLIP SAFE', 1, 1);
    _printer.printCustom('Present at exit', 1, 1);
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printNewLine();

    if (footer1.isNotEmpty) _printer.printCustom(footer1, 1, 1);
    if (footer2.isNotEmpty) _printer.printCustom(footer2, 1, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.paperCut();
  }

  static Future<void> printExitTicket({
    required Map<String, dynamic> entry,
    required Map<String, String> settings,
  }) async {
    final connected = await isConnected();
    if (!connected) return;

    final businessName = settings['business_name'] ?? 'Cleversync Parking';
    final address1 = settings['address1'] ?? '';
    final address2 = settings['address2'] ?? '';
    final phone = settings['phone'] ?? '';
    final footer1 = settings['footer1'] ?? '';
    final footer2 = settings['footer2'] ?? '';
    final upiId = settings['upi_id'] ?? '';

    _printer.printNewLine();
    _printer.printCustom(businessName, 3, 1);
    if (address1.isNotEmpty) _printer.printCustom(address1, 1, 1);
    if (address2.isNotEmpty) _printer.printCustom(address2, 1, 1);
    if (phone.isNotEmpty) _printer.printCustom(phone, 1, 1);
    _printer.printNewLine();
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printCustom('EXIT RECEIPT', 2, 1);
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printNewLine();

    _printer.printLeftRight('Token:', '#${entry['token']}', 1);
    _printer.printLeftRight('Vehicle:', entry['vehicle_number'] ?? '', 1);
    if ((entry['owner_name'] ?? '').isNotEmpty) {
      _printer.printLeftRight('Name:', entry['owner_name'] ?? '', 1);
    }

    final entryTime = DateTime.parse(entry['entry_time']);
    final exitTime = DateTime.parse(entry['exit_time']);
    _printer.printLeftRight('Entry:', DateFormat('dd/MM hh:mm a').format(entryTime), 1);
    _printer.printLeftRight('Exit:', DateFormat('dd/MM hh:mm a').format(exitTime), 1);

    final durationMin = entry['duration_minutes'] as int? ?? 0;
    final hours = durationMin ~/ 60;
    final mins = durationMin % 60;
    final durationStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    _printer.printLeftRight('Duration:', durationStr, 1);

    _printer.printNewLine();
    _printer.printCustom('--------------------------------', 1, 1);
    final fee = entry['fee'] ?? 0;
    _printer.printCustom('TOTAL: Rs. ${fee.toStringAsFixed(0)}', 2, 1);
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printNewLine();

    if (upiId.isNotEmpty) {
      _printer.printCustom('Pay via UPI:', 1, 1);
      _printer.printCustom(upiId, 2, 1);
      _printer.printNewLine();
    }

    if (footer1.isNotEmpty) _printer.printCustom(footer1, 1, 1);
    if (footer2.isNotEmpty) _printer.printCustom(footer2, 1, 1);
    _printer.printCustom('Thank you! Visit again.', 1, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.paperCut();
  }

  static Future<void> printMemberCard({
    required Map<String, dynamic> member,
    required Map<String, String> settings,
  }) async {
    final connected = await isConnected();
    if (!connected) return;

    final businessName = settings['business_name'] ?? 'Cleversync Parking';

    _printer.printNewLine();
    _printer.printCustom(businessName, 3, 1);
    _printer.printCustom('PARKING PASS', 2, 1);
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printNewLine();

    _printer.printLeftRight('Name:', member['name'] ?? '', 1);
    _printer.printLeftRight('Vehicle:', member['vehicle_number'] ?? '', 1);
    if ((member['employee_id'] ?? '').isNotEmpty) {
      _printer.printLeftRight('Emp ID:', member['employee_id'] ?? '', 1);
    }
    _printer.printLeftRight('Pass:', member['pass_type'] ?? '', 1);

    final startDate = member['start_date'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(member['start_date']))
        : '';
    final expiryDate = member['expiry_date'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(member['expiry_date']))
        : '';

    _printer.printLeftRight('Valid From:', startDate, 1);
    _printer.printLeftRight('Valid Till:', expiryDate, 1);
    _printer.printLeftRight('Amount:', 'Rs. ${member['amount'] ?? 0}', 1);

    _printer.printNewLine();
    _printer.printCustom('--------------------------------', 1, 1);
    _printer.printCustom('Authorised Pass', 1, 1);
    _printer.printNewLine();
    _printer.printNewLine();
    _printer.paperCut();
  }
}
