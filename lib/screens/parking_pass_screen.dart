// parking_pass_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'entry_screen.dart';
import 'exit_screen.dart';
import 'members_screen.dart';

class ParkingPassScreen extends StatefulWidget {
  const ParkingPassScreen({super.key});
  @override
  State<ParkingPassScreen> createState() => _ParkingPassScreenState();
}

class _ParkingPassScreenState extends State<ParkingPassScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Pass'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.login, size: 18), text: 'Entry Ticket'),
            Tab(icon: Icon(Icons.logout, size: 18), text: 'Exit Ticket'),
            Tab(icon: Icon(Icons.people, size: 18), text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          const EntryScreen(),
          const ExitScreen(),
          const MembersScreen(),
        ],
      ),
    );
  }
}
