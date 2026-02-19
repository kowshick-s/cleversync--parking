// members_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/printer_helper.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppProvider>().loadMembers());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
        actions: [
          TextButton.icon(
            onPressed: () => _showAddMemberSheet(context),
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            label: const Text('Add New', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name/type/reg/dates',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {}),
                    if (_searchController.text.isNotEmpty)
                      IconButton(icon: const Icon(Icons.close), onPressed: () {
                        _searchController.clear();
                        context.read<AppProvider>().loadMembers();
                      }),
                  ],
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: AppTheme.divider)),
              ),
              onChanged: (v) => context.read<AppProvider>().loadMembers(search: v),
            ),
          ),
          Expanded(
            child: provider.members.isEmpty
                ? const Center(child: Text('No members found', style: TextStyle(color: AppTheme.textHint)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: provider.members.length,
                    itemBuilder: (_, i) {
                      final member = provider.members[i];
                      final isExpired = provider.isMemberExpired(member);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: false,
                            onChanged: (_) {},
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          title: Text(member['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(member['vehicle_number'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(isExpired ? 'Expired' : 'Active',
                                      style: TextStyle(color: isExpired ? AppTheme.danger : AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text('Rs. ${member['amount'] ?? 0}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(6)),
                                child: const Text('P Entry', style: TextStyle(color: AppTheme.primary, fontSize: 11)),
                              ),
                            ],
                          ),
                          onTap: () => _showMemberDetail(context, member),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddMemberForm(),
    );
  }

  void _showMemberDetail(BuildContext context, Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _InfoRow('Vehicle', member['vehicle_number'] ?? ''),
            _InfoRow('Pass Type', member['pass_type'] ?? ''),
            _InfoRow('Valid Till', member['expiry_date'] != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(member['expiry_date']))
                : '-'),
            _InfoRow('Amount', 'Rs. ${member['amount'] ?? 0}'),
            _InfoRow('Payment', member['payment_status'] ?? ''),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await PrinterHelper.printMemberCard(
                        member: member,
                        settings: context.read<AppProvider>().settings,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print Card'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<AppProvider>().deleteMember(member['id']);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 90, child: Text('$label:', style: const TextStyle(color: AppTheme.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _AddMemberForm extends StatefulWidget {
  const _AddMemberForm();

  @override
  State<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<_AddMemberForm> {
  final _vehicleCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _empCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _paymentMethod = 'CASH';
  String _paymentStatus = 'PAID';
  String? _vehicleType;
  String? _passType;
  DateTime? _startDate;
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final vehicleTypes = provider.vehicleTypes.map((v) => v['name'] as String).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _field('Vehicle Number *', _vehicleCtrl, caps: true),
            _field('Name *', _nameCtrl),
            _field('Employee ID', _empCtrl),
            _field('Mobile Number', _mobileCtrl, keyboard: TextInputType.phone),
            _field('Amount *', _amountCtrl, keyboard: TextInputType.number),
            const SizedBox(height: 10),
            Text('Choose Payment Method', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            Wrap(spacing: 8, children: ['CASH', 'UPI', 'CARD', 'OTHER'].map((m) => ChoiceChip(
              label: Text(m, style: TextStyle(fontSize: 12)),
              selected: _paymentMethod == m,
              onSelected: (_) => setState(() => _paymentMethod = m),
              selectedColor: AppTheme.primaryLight,
            )).toList()),
            const SizedBox(height: 10),
            Text('Choose Payment Status', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            Wrap(spacing: 8, children: ['PAID', 'PENDING', 'PARTIAL'].map((s) => ChoiceChip(
              label: Text(s, style: TextStyle(fontSize: 12)),
              selected: _paymentStatus == s,
              onSelected: (_) => setState(() => _paymentStatus = s),
              selectedColor: AppTheme.primaryLight,
            )).toList()),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _vehicleType,
              hint: const Text('Vehicle Type'),
              items: vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _vehicleType = v),
              decoration: const InputDecoration(labelText: 'Vehicle Type'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _passType,
              hint: const Text('Pass Type'),
              items: ['Monthly', 'Quarterly', 'Half-Yearly', 'Annual']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _passType = v),
              decoration: const InputDecoration(labelText: 'Pass Type'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ListTile(
                  title: const Text('First Date', style: TextStyle(fontSize: 13)),
                  subtitle: Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Choose',
                      style: TextStyle(color: AppTheme.primary)),
                  trailing: const Icon(Icons.calendar_today, color: AppTheme.primary, size: 18),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (d != null) setState(() => _startDate = d);
                  },
                )),
                Expanded(child: ListTile(
                  title: const Text('Expiry date', style: TextStyle(fontSize: 13)),
                  subtitle: Text(_expiryDate != null ? DateFormat('dd/MM/yyyy').format(_expiryDate!) : 'Choose',
                      style: TextStyle(color: AppTheme.primary)),
                  trailing: const Icon(Icons.calendar_today, color: AppTheme.primary, size: 18),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime(2020), lastDate: DateTime(2035));
                    if (d != null) setState(() => _expiryDate = d);
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_vehicleCtrl.text.isEmpty || _nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fill required fields'), backgroundColor: AppTheme.danger),
                    );
                    return;
                  }
                  await provider.addMember({
                    'vehicle_number': _vehicleCtrl.text.trim(),
                    'name': _nameCtrl.text.trim(),
                    'employee_id': _empCtrl.text.trim(),
                    'mobile': _mobileCtrl.text.trim(),
                    'amount': double.tryParse(_amountCtrl.text) ?? 0,
                    'payment_method': _paymentMethod,
                    'payment_status': _paymentStatus.toLowerCase(),
                    'vehicle_type': _vehicleType ?? 'Two Wheeler',
                    'pass_type': _passType ?? 'Monthly',
                    'start_date': _startDate?.toIso8601String(),
                    'expiry_date': _expiryDate?.toIso8601String(),
                    'status': 'active',
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save Member'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, bool caps = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.words,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
