import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
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
            onPressed: () => _showVehicleTypeDialog(context, null),
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
                              IconButton(icon: const Icon(Icons.edit, color: AppTheme.warning), onPressed: () => _showVehicleTypeDialog(context, vt)),
                              IconButton(icon: const Icon(Icons.delete, color: AppTheme.danger), onPressed: () => _confirmDelete(context, vt)),
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
                      Text('Slot- ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                      _RateRow('Start Time:', '${rate['start_hour']}'),
                      _RateRow('End Time:', '${rate['end_hour']}'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount (Rs):'),
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rate updated!'), backgroundColor: AppTheme.success));
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
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    ]),
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
    {'key': 'business_name', 'label': 'Business name'},
    {'key': 'address1', 'label': 'Address line 1'},
    {'key': 'address2', 'label': 'Address line 2'},
    {'key': 'phone', 'label': 'Phone number'},
    {'key': 'upi_id', 'label': 'UPI ID (for payment)'},
    {'key': 'footer1', 'label': 'Footer message 1'},
    {'key': 'footer2', 'label': 'Footer message 2'},
    {'key': 'gst_percent', 'label': 'GST %'},
    {'key': 'max_recent_entries', 'label': 'Max recent entries (Default 10)'},
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!'), backgroundColor: AppTheme.success));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), leading: Navigator.canPop(context) ? const BackButton() : null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ..._fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(controller: _controllers[f['key']!], decoration: InputDecoration(labelText: f['label'])),
            )),
            const Divider(height: 24),
            const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            SwitchListTile(value: _allowAmountEdit, onChanged: (v) => setState(() => _allowAmountEdit = v), title: const Text('Allow Amount Edit In Checkout'), activeColor: AppTheme.primary),
            SwitchListTile(value: _allowLocalSearch, onChanged: (v) => setState(() => _allowLocalSearch = v), title: const Text('Allow local search'), activeColor: AppTheme.primary),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ===================== PRINTER SCREEN =====================
class PrinterScreen extends StatelessWidget {
  const PrinterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Printer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth, size: 80, color: AppTheme.primary),
            const SizedBox(height: 20),
            const Text('Bluetooth Printer Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'To connect your thermal printer:\n\n'
              '1. Turn on your Bluetooth thermal printer\n'
              '2. Go to Android Settings → Bluetooth\n'
              '3. Pair your printer there\n'
              '4. Come back to this app\n'
              '5. The app will automatically use your paired printer when printing receipts',
              style: TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings_bluetooth),
              label: const Text('Open Bluetooth Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
