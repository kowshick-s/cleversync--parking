import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/printer_helper.dart';
import 'package:uuid/uuid.dart';

// ===================== VEHICLE TYPES SCREEN =====================
class VehicleTypesScreen extends StatelessWidget {
  const VehicleTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Types'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            label: const Text('Add New', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.vehicleTypes.isEmpty
                ? const Center(child: Text('No vehicle types found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.vehicleTypes.length,
                    itemBuilder: (_, i) {
                      final vt = provider.vehicleTypes[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(vt['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Area: ${vt['area']} Sq.Ft', style: const TextStyle(color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              Text('Capacity: ${vt['capacity']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.warning),
                                onPressed: () => _showEditDialog(context, vt),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.danger),
                                onPressed: () => _confirmDelete(context, vt),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primary,
            child: Text(
              'Total Parking Area: ${context.watch<AppProvider>().vehicleTypes.fold<double>(0, (s, vt) => s + ((vt['area'] as num?)?.toDouble() ?? 0))} Sq.Ft',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) => _showVehicleTypeDialog(context, null);

  void _showEditDialog(BuildContext context, Map<String, dynamic> vt) => _showVehicleTypeDialog(context, vt);

  void _showVehicleTypeDialog(BuildContext context, Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final areaCtrl = TextEditingController(text: existing?['area']?.toString() ?? '0');
    final capacityCtrl = TextEditingController(text: existing?['capacity']?.toString() ?? '0');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Vehicle Type' : 'Add Vehicle Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: areaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Area (Sq.Ft)')),
            const SizedBox(height: 10),
            TextField(controller: capacityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<AppProvider>();
              if (isEdit) {
                await provider.updateVehicleType(existing['id'], nameCtrl.text, double.tryParse(areaCtrl.text) ?? 0, int.tryParse(capacityCtrl.text) ?? 0);
              } else {
                await provider.addVehicleType(nameCtrl.text, double.tryParse(areaCtrl.text) ?? 0, int.tryParse(capacityCtrl.text) ?? 0);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> vt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle Type'),
        content: Text('Delete "${vt['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { context.read<AppProvider>().deleteVehicleType(vt['id']); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ===================== RATES SCREEN =====================
class RatesScreen extends StatelessWidget {
  const RatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Vehicle Rates')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.vehicleTypes.length,
        itemBuilder: (_, i) {
          final vt = provider.vehicleTypes[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(vt['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('1 Slot'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SetRateScreen(vehicleType: vt))),
            ),
          );
        },
      ),
    );
  }
}

// ===================== SET RATE SCREEN =====================
class SetRateScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleType;
  const SetRateScreen({super.key, required this.vehicleType});

  @override
  State<SetRateScreen> createState() => _SetRateScreenState();
}

class _SetRateScreenState extends State<SetRateScreen> {
  List<Map<String, dynamic>> _rates = [];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final rates = await context.read<AppProvider>().getRatesForType(widget.vehicleType['id']);
    setState(() => _rates = rates.map((r) => Map<String, dynamic>.from(r)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Rate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Slots: ${_rates.length}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _addSlot,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Slot'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._rates.asMap().entries.map((entry) {
              final i = entry.key;
              final rate = entry.value;
              final amountCtrl = TextEditingController(text: rate['amount']?.toString() ?? '10');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Slot- ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              decoration: const InputDecoration(hintText: 'Hour', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _RateRow('Start Time:', '${rate['start_hour']}'),
                      _RateRow('End Time:', '${rate['end_hour']}'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount:'),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                              onChanged: (v) => rate['amount'] = double.tryParse(v) ?? 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteRate(rate['id']),
                              icon: const Icon(Icons.delete, color: AppTheme.danger),
                              label: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _updateRate(rate),
                              icon: const Icon(Icons.check, color: AppTheme.primary),
                              label: const Text('Update', style: TextStyle(color: AppTheme.primary)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primary)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _addSlot() async {
    const uuid = Uuid();
    final newRate = {
      'id': uuid.v4(),
      'vehicle_type_id': widget.vehicleType['id'],
      'slot_number': _rates.length + 1,
      'start_hour': 0,
      'end_hour': 24,
      'amount': 10.0,
    };
    await context.read<AppProvider>().upsertRate(newRate);
    _loadRates();
  }

  void _updateRate(Map<String, dynamic> rate) async {
    await context.read<AppProvider>().upsertRate(rate);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rate updated!'), backgroundColor: AppTheme.success),
    );
  }

  void _deleteRate(String id) async {
    await context.read<AppProvider>().deleteRate(id);
    _loadRates();
  }
}

class _RateRow extends StatelessWidget {
  final String label, value;
  const _RateRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

// ===================== SETTINGS SCREEN =====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controllers = <String, TextEditingController>{};
  bool _allowAmountEdit = false;
  bool _allowLocalSearch = true;
  bool _loaded = false;

  final _fields = [
    {'key': 'business_name', 'label': 'Please enter business name (H1)'},
    {'key': 'address1', 'label': 'Please enter address line 1 (H2)'},
    {'key': 'address2', 'label': 'Please enter address line 2 (H3)'},
    {'key': 'phone', 'label': 'Please enter heading 4'},
    {'key': 'heading5', 'label': 'Please enter heading 5'},
    {'key': 'heading6', 'label': 'Please enter heading 6'},
    {'key': 'footer1', 'label': 'Enter Footer 1'},
    {'key': 'footer2', 'label': 'Enter Footer 2'},
    {'key': 'location_identity', 'label': 'Enter Location Identity'},
    {'key': 'upi_id', 'label': 'UPI ID (for payment)'},
    {'key': 'gst_percent', 'label': 'Enter GST %'},
    {'key': 'max_recent_entries', 'label': 'Enter max items in recent entries (Default 10)'},
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _controllers[f['key']!] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<AppProvider>();
    await provider.loadSettings();
    final settings = provider.settings;
    for (final f in _fields) {
      _controllers[f['key']!]?.text = settings[f['key']] ?? '';
    }
    setState(() {
      _allowAmountEdit = settings['allow_amount_edit'] == 'true';
      _allowLocalSearch = settings['allow_local_search'] != 'false';
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final newSettings = <String, String>{};
    for (final f in _fields) {
      newSettings[f['key']!] = _controllers[f['key']!]?.text ?? '';
    }
    newSettings['allow_amount_edit'] = _allowAmountEdit.toString();
    newSettings['allow_local_search'] = _allowLocalSearch.toString();
    await context.read<AppProvider>().saveSettings(newSettings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences'), leading: Navigator.canPop(context) ? const BackButton() : null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Print Receipt Setting', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              height: 120,
              width: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                    Text('Logo Image', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            const Text('Receipt Header & Footer', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            ..._fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['label']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: _controllers[f['key']!]),
                ],
              ),
            )),

            const Divider(height: 24),
            const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            SwitchListTile(
              value: _allowAmountEdit,
              onChanged: (v) => setState(() => _allowAmountEdit = v),
              title: const Text('Allow Amount Edit In Checkout'),
              activeColor: AppTheme.primary,
            ),
            SwitchListTile(
              value: _allowLocalSearch,
              onChanged: (v) => setState(() => _allowLocalSearch = v),
              title: const Text('Allow local search'),
              activeColor: AppTheme.primary,
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('Save')),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ===================== PRINTER SCREEN =====================
class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});
  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connected;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await PrinterHelper.getDevices();
      setState(() { _devices = devices; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Printer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_connected != null) Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.entryCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_connected, color: AppTheme.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Connected: ${_connected!.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success))),
                  TextButton(
                    onPressed: () async { await PrinterHelper.disconnect(); setState(() => _connected = null); },
                    child: const Text('Disconnect', style: TextStyle(color: AppTheme.danger)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Paired Devices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _loadDevices,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading) const Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty) const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No paired Bluetooth devices found.\nPair your thermal printer in Android settings first.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textHint)),
            ))
            else Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (_, i) {
                  final device = _devices[i];
                  final isConnected = _connected?.address == device.address;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.print, color: isConnected ? AppTheme.success : AppTheme.textHint),
                      title: Text(device.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(device.address ?? ''),
                      trailing: isConnected
                          ? const Text('Connected', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600))
                          : ElevatedButton(
                              onPressed: () async {
                                final ok = await PrinterHelper.connect(device);
                                if (ok) setState(() => _connected = device);
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              child: const Text('Connect'),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
