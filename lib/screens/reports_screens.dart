import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

// ===================== REPORTS SCREEN =====================
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'today';
  String _statusFilter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final now = DateTime.now();
    String? from, to;

    switch (_period) {
      case 'today':
        from = '${now.toIso8601String().substring(0, 10)} 00:00:00';
        to = '${now.toIso8601String().substring(0, 10)} 23:59:59';
        break;
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        from = '${y.toIso8601String().substring(0, 10)} 00:00:00';
        to = '${y.toIso8601String().substring(0, 10)} 23:59:59';
        break;
      case 'week':
        from = '${now.subtract(Duration(days: now.weekday - 1)).toIso8601String().substring(0, 10)} 00:00:00';
        to = '${now.toIso8601String().substring(0, 10)} 23:59:59';
        break;
      case 'month':
        from = '${now.year}-${now.month.toString().padLeft(2, '0')}-01 00:00:00';
        to = '${now.toIso8601String().substring(0, 10)} 23:59:59';
        break;
    }

    context.read<AppProvider>().loadEntries(
      status: _statusFilter == 'all' ? null : _statusFilter,
      dateFrom: from,
      dateTo: to,
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = provider.entries;
    final totalAmount = entries.where((e) => e['status'] == 'exited').fold<double>(0, (s, e) => s + ((e['fee'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(12, 50, 12, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by registration number',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                suffixIcon: const Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white24,
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['today', 'yesterday', 'week', 'month'].map((p) {
                      final labels = {'today': 'Today', 'yesterday': 'Yesterday', 'week': 'This Week', 'month': 'This Month'};
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(labels[p]!),
                          selected: _period == p,
                          onSelected: (_) { setState(() => _period = p); _load(); },
                          selectedColor: AppTheme.primaryLight,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      {'key': 'all', 'label': 'All'},
                      {'key': 'parked', 'label': 'Parked'},
                      {'key': 'exited', 'label': 'Exit'},
                    ].map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f['label']!),
                        selected: _statusFilter == f['key'],
                        onSelected: (_) { setState(() => _statusFilter = f['key']!); _load(); },
                        selectedColor: AppTheme.primaryLight,
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.local_parking, size: 60, color: AppTheme.accent), Text('Data is not available', style: TextStyle(color: AppTheme.textHint))],
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final isParked = e['status'] == 'parked';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isParked ? AppTheme.entryCardBg : AppTheme.exitCardBg,
                            child: Text('#${e['token']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isParked ? AppTheme.success : AppTheme.danger)),
                          ),
                          title: Text(e['vehicle_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(provider.formatDateTime(e['entry_time'])),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isParked) Text('Rs. ${(e['fee'] as num?)?.toStringAsFixed(0) ?? 0}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isParked ? AppTheme.entryCardBg : AppTheme.exitCardBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(isParked ? 'PARKED' : 'EXITED',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isParked ? AppTheme.success : AppTheme.danger)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                Text('Records: ${entries.length}', style: const TextStyle(color: AppTheme.primary)),
                Text('Amount: Rs.${totalAmount.toStringAsFixed(1)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== PASS REPORTS SCREEN =====================
class PassReportsScreen extends StatelessWidget {
  const PassReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final members = provider.members;
    final totalRevenue = members.fold<double>(0, (s, m) => s + ((m['amount'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Pass Reports')),
      body: Column(
        children: [
          Expanded(
            child: members.isEmpty
                ? const Center(child: Text('No pass records found', style: TextStyle(color: AppTheme.textHint)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      final isExpired = provider.isMemberExpired(m);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${m['vehicle_number']} • ${m['pass_type'] ?? ''}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rs. ${m['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                              Text(isExpired ? 'Expired' : 'Active',
                                  style: TextStyle(color: isExpired ? AppTheme.danger : AppTheme.success, fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                Text('${members.length} members', style: const TextStyle(color: AppTheme.primary)),
                Text('Rs.${totalRevenue.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== DASHBOARD SCREEN =====================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _period = 'today';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final stats = provider.dashboardStats;
    final entryStats = stats['entries'] as Map? ?? {};
    final vehicleTypes = provider.vehicleTypes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadDashboardStats(period: _period)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in [{'key': 'today', 'label': 'Today'}, {'key': 'yesterday', 'label': 'Yesterday'}, {'key': 'week', 'label': 'This Week'}, {'key': 'month', 'label': 'This Month'}])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p['label']!),
                        selected: _period == p['key'],
                        onSelected: (_) { setState(() => _period = p['key']!); provider.loadDashboardStats(period: p['key']); },
                        selectedColor: AppTheme.primaryLight,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionLabel('Today'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard('Check-In\n(Normal)', '${entryStats['total_entries'] ?? 0}'),
                  _StatCard('Check-Out\n(Normal)', '${entryStats['total_exits'] ?? 0}'),
                  _StatCard('Revenue', 'Rs.${(entryStats['total_revenue'] as num?)?.toStringAsFixed(0) ?? 0}'),
                  _StatCard('Collected', 'Rs.${(entryStats['collected_revenue'] as num?)?.toStringAsFixed(0) ?? 0}'),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _SectionLabel('Vehicle Wise'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: vehicleTypes.map((vt) => _StatCard(
                  vt['name'],
                  '${provider.currentlyParked}/${vt['capacity']}',
                )).toList(),
              ),
            ),

            const SizedBox(height: 16),
            _SectionLabel('Parking Space'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard('Total Space', '${vehicleTypes.fold<double>(0, (s, vt) => s + ((vt['area'] as num?)?.toDouble() ?? 0))} sq.ft'),
                  _StatCard('Parked Space', '${(provider.currentlyParked * 40)} sq.ft'),
                  _StatCard('Available', 'Space'),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pie_chart, size: 60, color: AppTheme.primary),
                    Text('Parked / Available chart', style: TextStyle(color: AppTheme.textHint)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary));
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

// ===================== ANALYTICS SCREEN =====================
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'today';
  bool _showRecords = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = provider.entries;

    final parked = entries.where((e) => e['status'] == 'parked').toList();
    final exited = entries.where((e) => e['status'] == 'exited').toList();
    final totalRevenue = exited.fold<double>(0, (s, e) => s + ((e['fee'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadDashboardStats(period: _period))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in [{'k': 'today', 'l': 'Today'}, {'k': 'yesterday', 'l': 'Yesterday'}, {'k': 'week', 'l': 'This Week'}, {'k': 'month', 'l': 'This Month'}])
                    Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                      label: Text(p['l']!),
                      selected: _period == p['k'],
                      onSelected: (_) => setState(() => _period = p['k']!),
                      selectedColor: AppTheme.primaryLight,
                    )),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _AnalyticsSection('Summary by Parked Vehicles', parked.length, 0),
            const SizedBox(height: 12),
            _AnalyticsSection('Advance Collection (Parked+Exited)', entries.length, totalRevenue),
            const SizedBox(height: 12),
            _AnalyticsSection('Summary by Exited Vehicles', exited.length, totalRevenue),
            const SizedBox(height: 12),

            const Text('Summary by Vehicle Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...provider.vehicleTypes.map((vt) {
              final vtEntries = exited.where((e) => e['vehicle_type'] == vt['name']).toList();
              final vtRevenue = vtEntries.fold<double>(0, (s, e) => s + ((e['fee'] as num?)?.toDouble() ?? 0));
              return _AnalyticsSection(vt['name'], vtEntries.length, vtRevenue);
            }),

            const SizedBox(height: 16),
            Row(
              children: [
                Radio<bool>(value: true, groupValue: _showRecords, onChanged: (v) => setState(() => _showRecords = v!), activeColor: AppTheme.primary),
                const Text('Show Records'),
                const SizedBox(width: 20),
                Radio<bool>(value: false, groupValue: _showRecords, onChanged: (v) => setState(() => _showRecords = v!), activeColor: AppTheme.primary),
                const Text('Show Earning'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  final String title;
  final int qty;
  final double amount;
  const _AnalyticsSection(this.title, this.qty, this.amount);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Divider(height: 12),
        Row(
          children: [
            const SizedBox(width: 30, child: Text('#', style: TextStyle(color: AppTheme.textHint))),
            const Expanded(child: Text('Qty', style: TextStyle(color: AppTheme.textHint))),
            const Text('Amount', style: TextStyle(color: AppTheme.textHint)),
          ],
        ),
        const Divider(height: 8),
        Row(
          children: [
            const SizedBox(width: 30, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold))),
            Text('Rs. ${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
          ],
        ),
      ],
    ),
  );
}

// ===================== EARNING REPORT SCREEN =====================
class EarningReportScreen extends StatefulWidget {
  const EarningReportScreen({super.key});
  @override
  State<EarningReportScreen> createState() => _EarningReportScreenState();
}

class _EarningReportScreenState extends State<EarningReportScreen> {
  String _period = 'today';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final now = DateTime.now();
    String from, to;
    switch (_period) {
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        from = '${y.toIso8601String().substring(0, 10)} 00:00:00';
        to = '${y.toIso8601String().substring(0, 10)} 23:59:59';
        break;
      case 'week':
        from = '${now.subtract(Duration(days: now.weekday - 1)).toIso8601String().substring(0, 10)} 00:00:00';
        to = '${now.toIso8601String().substring(0, 10)} 23:59:59';
        break;
      case 'month':
        from = '${now.year}-${now.month.toString().padLeft(2, '0')}-01 00:00:00';
        to = '${now.toIso8601String().substring(0, 10)} 23:59:59';
        break;
      default:
        from = '${now.toIso8601String().substring(0, 10)} 00:00:00';
        to = '${now.toIso8601String().substring(0, 10)} 23:59:59';
    }
    context.read<AppProvider>().loadEntries(status: 'exited', dateFrom: from, dateTo: to);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final exited = provider.entries.where((e) => e['status'] == 'exited').toList();
    final totalRevenue = exited.fold<double>(0, (s, e) => s + ((e['fee'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earning Report'),
        actions: [IconButton(icon: const Icon(Icons.download), onPressed: () {})],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in [{'k': 'today', 'l': 'Today'}, {'k': 'yesterday', 'l': 'Yesterday'}, {'k': 'week', 'l': 'This Week'}, {'k': 'month', 'l': 'This Month'}])
                    Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                      label: Text(p['l']!),
                      selected: _period == p['k'],
                      onSelected: (_) { setState(() => _period = p['k']!); _load(); },
                      selectedColor: AppTheme.primaryLight,
                    )),
                ],
              ),
            ),
          ),

          if (totalRevenue > 0) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF2E7D32)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Earning', style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('Rs. ${totalRevenue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          Expanded(
            child: exited.isEmpty
                ? const Center(child: Text('No data available', style: TextStyle(color: AppTheme.textHint)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: exited.length,
                    itemBuilder: (_, i) {
                      final e = exited[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.entryCardBg,
                            child: Text('#${e['token']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                          ),
                          title: Text(e['vehicle_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(provider.formatDateTime(e['exit_time'])),
                          trailing: Text('Rs. ${(e['fee'] as num?)?.toStringAsFixed(0) ?? 0}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 16)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
