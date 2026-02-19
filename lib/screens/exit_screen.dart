import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/printer_helper.dart';

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

  Future<void> _find() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() => _error = 'Enter reg/token number');
      return;
    }
    setState(() { _isLoading = true; _error = null; _foundEntry = null; });

    final provider = context.read<AppProvider>();
    final entry = await provider.findActiveEntry(_searchController.text.trim());

    setState(() {
      _isLoading = false;
      _foundEntry = entry;
      if (entry == null) _error = 'No active parking found for: ${_searchController.text.trim().toUpperCase()}';
    });
  }

  Future<void> _processExit() async {
    if (_foundEntry == null) return;

    // Security checklist
    bool bikeVerified = false;
    bool keyVerified = false;
    bool idVerified = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.security, color: AppTheme.danger),
              SizedBox(width: 8),
              Text('Security Verification', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('All checks are mandatory before releasing vehicle:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: bikeVerified,
                onChanged: (v) => setS(() => bikeVerified = v!),
                title: const Text('Bike number on vehicle matches record', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.success,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: keyVerified,
                onChanged: (v) => setS(() => keyVerified = v!),
                title: const Text('Rider demonstrated working key (bike started)', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.success,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: idVerified,
                onChanged: (v) => setS(() => idVerified = v!),
                title: const Text('Rider identity verified (token matched)', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.success,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: (!bikeVerified || !keyVerified || !idVerified) ? null : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: bikeVerified && keyVerified && idVerified ? AppTheme.danger : Colors.grey),
              child: const Text('Release Vehicle'),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        setState(() => _isLoading = true);
        final provider = context.read<AppProvider>();
        final exitEntry = await provider.processExit(_foundEntry!['id']);

        if (_printEnabled) {
          await PrinterHelper.printExitTicket(entry: exitEntry, settings: provider.settings);
        }

        if (mounted) {
          setState(() { _isLoading = false; _foundEntry = null; });
          _searchController.clear();
          _showExitReceipt(exitEntry);
        }
      }
    });
  }

  void _showExitReceipt(Map<String, dynamic> entry) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success),
            SizedBox(width: 8),
            Text('Exit Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row('Token', '#${entry['token']}'),
            _Row('Vehicle', entry['vehicle_number']),
            _Row('Duration', provider.formatDuration(entry['duration_minutes'] ?? 0)),
            const Divider(),
            _Row('Fee', provider.formatCurrency(entry['fee']),
                valueStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.success)),
            if ((provider.settings['upi_id'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.divider), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    const Text('Pay via UPI', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(provider.settings['upi_id'] ?? '', style: const TextStyle(fontFamily: 'monospace', color: AppTheme.primary)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Out'), leading: Navigator.canPop(context) ? const BackButton() : null),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Setup
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Allow local search'),
                  Switch(value: _allowLocalSearch, onChanged: (v) => setState(() => _allowLocalSearch = v), activeColor: AppTheme.primary),
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
                  const Text('Enter reg/token number *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _searchController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter reg/token number',
                      hintStyle: TextStyle(color: _error != null ? AppTheme.danger : null),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _error != null ? AppTheme.danger : AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _error != null ? AppTheme.danger : AppTheme.primary),
                      ),
                      suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
                    ),
                    onSubmitted: (_) => _find(),
                  ),
                  if (_error != null) Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _find,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: _isLoading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Find'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Found entry card
            if (_foundEntry != null) ...[
              const SizedBox(height: 16),
              _FoundEntryCard(entry: _foundEntry!, onExit: _processExit),
            ],
          ],
        ),
      ),
    );
  }
}

class _FoundEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onExit;
  const _FoundEntryCard({required this.entry, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final entryTime = DateTime.parse(entry['entry_time']);
    final duration = DateTime.now().difference(entryTime);
    final durationMin = duration.inMinutes;
    final fee = 10.0 * ((durationMin / (24 * 60)).ceil().clamp(1, 999));

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
                child: Text('#${entry['token']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.entryCardBg, borderRadius: BorderRadius.circular(20)),
                child: const Text('ACTIVE', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 20),
          _Row('Vehicle', entry['vehicle_number'] ?? ''),
          if ((entry['owner_name'] ?? '').isNotEmpty) _Row('Name', entry['owner_name']),
          if ((entry['mobile'] ?? '').isNotEmpty) _Row('Mobile', entry['mobile']),
          if ((entry['vehicle_type'] ?? '').isNotEmpty) _Row('Type', entry['vehicle_type']),
          _Row('Entry', provider.formatDateTime(entry['entry_time'])),
          _Row('Duration', provider.formatDuration(durationMin)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Fee', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Rs. ${fee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.success)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onExit,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Process Exit & Print Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _Row(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
