import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/printer_helper.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _vehicleController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _remarkController = TextEditingController();

  String? _selectedModel;
  String _paymentStatus = 'due';
  String? _vehicleType;
  bool _printEnabled = true;
  bool _isLoading = false;
  bool _showQuickSetup = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_vehicleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle number is required'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();

    // Check if already parked
    final existing = await provider.findActiveEntry(_vehicleController.text.trim());
    if (existing != null && mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_vehicleController.text.toUpperCase()} is already parked! Token: #${existing['token']}'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final entry = await provider.registerEntry(
      vehicleNumber: _vehicleController.text.trim(),
      ownerName: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      model: _selectedModel,
      remark: _remarkController.text.trim(),
      vehicleType: _vehicleType ?? 'Two Wheeler',
      paymentStatus: _paymentStatus,
    );

    if (_printEnabled) {
      await PrinterHelper.printEntryTicket(entry: entry, settings: provider.settings);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog(entry);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 28),
            SizedBox(width: 8),
            Text('Entry Registered!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Token', '#${entry['token']}', valueStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            _InfoRow('Vehicle', entry['vehicle_number'] ?? ''),
            if ((entry['owner_name'] ?? '').isNotEmpty) _InfoRow('Name', entry['owner_name']),
            _InfoRow('Time', context.read<AppProvider>().formatDateTime(entry['entry_time'])),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _clearForm(); }, child: const Text('New Entry')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  void _clearForm() {
    _vehicleController.clear();
    _nameController.clear();
    _mobileController.clear();
    _remarkController.clear();
    setState(() { _selectedModel = null; _paymentStatus = 'due'; });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vehicleTypes = provider.vehicleTypes.map((vt) => vt['name'] as String).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Setup toggle
            GestureDetector(
              onTap: () => setState(() => _showQuickSetup = !_showQuickSetup),
              child: Row(
                children: [
                  Text('Quick Setup', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  Icon(_showQuickSetup ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.primary),
                ],
              ),
            ),

            if (_showQuickSetup) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Do you want to print?'),
                  Switch(value: _printEnabled, onChanged: (v) => setState(() => _printEnabled = v), activeColor: AppTheme.primary),
                ],
              ),
            ],

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter vehicle number *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _vehicleController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter vehicle number',
                      suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Enter owner name', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Enter owner name')),

                  const SizedBox(height: 14),
                  const Text('Enter owner mobile number', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(hintText: 'Enter owner mobile number', counterText: ''),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('Choose Model :', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedModel,
                          hint: const Text('Choose'),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          items: ['Activa', 'Pulsar', 'Splendor', 'TVS Jupiter', 'Other']
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedModel = v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Text('Enter remark (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _remarkController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Enter remark (Optional)'),
                  ),

                  const SizedBox(height: 14),
                  const Text('Payment', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['due', 'paid', 'partial'].map((s) => ChoiceChip(
                      label: Text(s),
                      selected: _paymentStatus == s,
                      onSelected: (_) => setState(() => _paymentStatus = s),
                      selectedColor: AppTheme.primaryLight,
                    )).toList(),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('Type :', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _vehicleType,
                          hint: const Text('Choose'),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          items: vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _vehicleType = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text('$label:', style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
