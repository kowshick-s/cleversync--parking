import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class ExitScreen extends StatefulWidget {
  const ExitScreen({super.key});

  @override
  State<ExitScreen> createState() => _ExitScreenState();
}

class _ExitScreenState extends State<ExitScreen> {
  final _searchController = TextEditingController();
  bool _printEnabled = true;
  bool _allowLocalSearch = true;
  bool _isLoading = false;
  bool _showQuickSetup = false;
  Map<String, dynamic>? _foundEntry;
  String? _error;
  double? _previewFee;
  String _paymentMethod = 'CASH';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() => _error = 'Enter reg/token number');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _foundEntry = null;
      _previewFee = null;
    });

    final provider = context.read<AppProvider>();
    final entry = await provider.findActiveEntry(_searchController.text.trim());

    if (entry != null) {
      // Calculate preview fee
      final entryTime = DateTime.parse(entry['entry_time']);
      final fee = await provider.calculatePreviewFee(
        entry['vehicle_type'] ?? 'Two Wheeler',
        entryTime,
      );
      setState(() {
        _foundEntry = entry;
        _previewFee = fee;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = 'No active parking found for: ${_searchController.text.trim().toUpperCase()}';
      });
    }
  }

  Future<void> _processExit() async {
    if (_foundEntry == null) return;

    // Security checklist dialog
    bool bikeVerified = false;
    bool keyVerified = false;
    bool idVerified = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.security, color: AppTheme.danger),
            SizedBox(width: 8),
            Text('Security Check', style: TextStyle(fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Complete all checks before releasing vehicle:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: bikeVerified,
                onChanged: (v) => setS(() => bikeVerified = v!),
                title: const Text('Bike number matches record', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.success,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: keyVerified,
                onChanged: (v) => setS(() => keyVerified = v!),
                title: const Text('Rider started bike with key', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.success,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: idVerified,
                onChanged: (v) => setS(() => idVerified = v!),
                title: const Text('Identity / token verified', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.success,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              // Payment method selection
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: ['CASH', 'UPI', 'CARD', 'OTHER'].map((m) => ChoiceChip(
                  label: Text(m, style: const TextStyle(fontSize: 12)),
                  selected: _paymentMethod == m,
                  onSelected: (_) => setS(() => _paymentMethod = m),
                  selectedColor: AppTheme.primaryLight,
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (bikeVerified && keyVerified && idVerified)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (bikeVerified && keyVerified && idVerified)
                    ? AppTheme.danger
                    : Colors.grey,
              ),
              child: const Text('Release Vehicle'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final provider = context.read<AppProvider>();

      final exitEntry = await provider.processExit(
        _foundEntry!['id'],
        paymentMethod: _paymentMethod,
        paymentStatus: 'paid',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _foundEntry = null;
          _previewFee = null;
        });
        _searchController.clear();
        _showExitReceipt(exitEntry);
      }
    }
  }

  void _showExitReceipt(Map<String, dynamic> entry) {
    final provider = context.read<AppProvider>();
    final fee = (entry['fee'] as num?)?.toDouble() ?? 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: AppTheme.success, size: 28),
          SizedBox(width: 8),
          Text('Exit Complete!'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row('Token', '#${entry['token']}'),
            _Row('Vehicle', entry['vehicle_number'] ?? ''),
            _Row('Entry', provider.formatDateTime(entry['entry_time'])),
            _Row('Exit', provider.formatDateTime(entry['exit_time'])),
            _Row('Duration', provider.formatDuration(entry['duration_minutes'] ?? 0)),
            _Row('Payment', _paymentMethod),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Fee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Rs. ${fee.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.success)),
              ],
            ),
            if ((provider.settings['upi_id'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.primaryLight,
                ),
                child: Column(children: [
                  const Text('Pay via UPI', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(provider.settings['upi_id'] ?? '',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Out'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Setup
            GestureDetector(
              onTap: () => setState(() => _showQuickSetup = !_showQuickSetup),
              child: Row(children: [
                Text('Quick Setup',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(_showQuickSetup ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.primary),
              ]),
            ),

            if (_showQuickSetup) ...[
              const SizedBox(height: 10),
              _ToggleRow('Do you want to print?', _printEnabled,
                  (v) => setState(() => _printEnabled = v)),
              _ToggleRow('Allow local search', _allowLocalSearch,
                  (v) => setState(() => _allowLocalSearch = v)),
            ],

            const SizedBox(height: 16),

            // Search card
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
                  const Text('Enter reg/token number *',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter reg/token number',
                      errorText: _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _error != null ? AppTheme.danger : AppTheme.divider),
                      ),
                      suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
                    ),
                    onSubmitted: (_) => _find(),
                  ),

                  const SizedBox(height: 12),

                  // Vehicle Type
                  Row(children: [
                    const Text('Vehicle Type :', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.divider),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text('Choose', style: TextStyle(color: AppTheme.textHint)),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
                      Row(children: [
                        const Icon(Icons.calendar_month, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 4),
                        Text(DateFormatter.today(), style: const TextStyle(color: AppTheme.primary)),
                      ]),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Scan + Find buttons
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.barcode_reader, size: 18),
                        label: const Text('Scan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _find,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Find'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Found entry card
            if (_foundEntry != null) ...[
              const SizedBox(height: 16),
              _FoundEntryCard(
                entry: _foundEntry!,
                previewFee: _previewFee ?? 0,
                onExit: _processExit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
    ],
  );
}

class _FoundEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final double previewFee;
  final VoidCallback onExit;
  const _FoundEntryCard({required this.entry, required this.previewFee, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final entryTime = DateTime.parse(entry['entry_time']);
    final durationMin = DateTime.now().difference(entryTime).inMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Text('#${entry['token']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.entryCardBg, borderRadius: BorderRadius.circular(20)),
              child: const Text('PARKED',
                  style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ]),
          const Divider(height: 20),
          _Row('Vehicle', entry['vehicle_number'] ?? ''),
          if ((entry['owner_name'] ?? '').isNotEmpty) _Row('Name', entry['owner_name']),
          if ((entry['mobile'] ?? '').isNotEmpty) _Row('Mobile', entry['mobile']),
          if ((entry['vehicle_type'] ?? '').isNotEmpty) _Row('Type', entry['vehicle_type']),
          _Row('Entry Time', provider.formatDateTime(entry['entry_time'])),
          _Row('Duration', provider.formatDuration(durationMin)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fee', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text('Rs. ${previewFee.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.success)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Checkout & Generate Receipt',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 80, child: Text('$label:', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}

class DateFormatter {
  static String today() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}
