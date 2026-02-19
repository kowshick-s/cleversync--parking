import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class ParkedVehiclesScreen extends StatefulWidget {
  const ParkedVehiclesScreen({super.key});

  @override
  State<ParkedVehiclesScreen> createState() => _ParkedVehiclesScreenState();
}

class _ParkedVehiclesScreenState extends State<ParkedVehiclesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadEntries(status: 'parked');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final parked = provider.entries.where((e) => e['status'] == 'parked').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Parked Vehicles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by registration number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (v) => context.read<AppProvider>().loadEntries(status: 'parked', search: v),
            ),
          ),
          Expanded(
            child: parked.isEmpty
                ? const Center(child: Text('No vehicles currently parked', style: TextStyle(color: AppTheme.textHint)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: parked.length,
                    itemBuilder: (_, i) {
                      final e = parked[i];
                      final duration = DateTime.now().difference(DateTime.parse(e['entry_time']));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryLight,
                            child: Text('#${e['token']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          title: Text(e['vehicle_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          subtitle: Text('${e['owner_name'] ?? ''} • ${e['vehicle_type'] ?? ''}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.entryCardBg, borderRadius: BorderRadius.circular(10)),
                                child: const Text('PARKED', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),
                              Text(provider.formatDuration(duration.inMinutes), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                Text('${parked.length} vehicles parked', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
