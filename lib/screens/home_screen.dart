import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'entry_screen.dart';
import 'exit_screen.dart';
import 'members_screen.dart';
import 'parking_pass_screen.dart';
import 'parked_vehicles_screen.dart';
import 'reports_screens.dart';
import 'setup_screens.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const EntryScreen(),
    const ExitScreen(),
    const MembersScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.login_outlined), activeIcon: Icon(Icons.login), label: 'Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.logout_outlined), activeIcon: Icon(Icons.logout), label: 'Exit'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showDrawer(context),
        ),
        title: Text(provider.businessName, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Currently\nParked', value: '${provider.currentlyParked}'),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _StatItem(label: 'Today\nEntries', value: '${provider.dashboardStats['entries']?['total_entries'] ?? 0}'),
                  Container(width: 1, height: 40, color: Colors.white30),
                  _StatItem(label: 'Today\nRevenue', value: 'Rs.${provider.dashboardStats['entries']?['total_revenue']?.toStringAsFixed(0) ?? 0}'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _SectionTitle('Parking Entry & Exit'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _MenuCard(icon: Icons.directions_car, label: 'Entry', bg: AppTheme.entryCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryScreen()))),
                _MenuCard(icon: Icons.exit_to_app, label: 'Exit', bg: AppTheme.exitCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExitScreen()))),
                _MenuCard(icon: Icons.card_membership, label: 'Pass\nMembers', bg: AppTheme.entryCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersScreen()))),
                _MenuCard(icon: Icons.confirmation_num, label: 'Parking\nPass', bg: AppTheme.passCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParkingPassScreen()))),
              ],
            ),

            const SizedBox(height: 20),
            _SectionTitle('Reports & Analysis'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _MenuCard(icon: Icons.local_parking, label: 'Parked\nVehicles', bg: AppTheme.entryCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParkedVehiclesScreen()))),
                _MenuCard(icon: Icons.receipt_long, label: 'Reports', bg: AppTheme.exitCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                _MenuCard(icon: Icons.card_travel, label: 'Pass\nReports', bg: AppTheme.reportsCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassReportsScreen()))),
                _MenuCard(icon: Icons.dashboard, label: 'Dashboard', bg: AppTheme.dashCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()))),
                _MenuCard(icon: Icons.analytics, label: 'Analytics', bg: const Color(0xFFEDE7F6),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                _MenuCard(icon: Icons.attach_money, label: 'Earning\nReport', bg: AppTheme.entryCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningReportScreen()))),
              ],
            ),

            const SizedBox(height: 20),
            _SectionTitle('Setup'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _MenuCard(icon: Icons.two_wheeler, label: 'Vehicles', bg: AppTheme.reportsCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleTypesScreen()))),
                _MenuCard(icon: Icons.price_change, label: 'Rates\nChart', bg: AppTheme.dashCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RatesScreen()))),
                _MenuCard(icon: Icons.receipt, label: 'Receipt\nSetup', bg: AppTheme.entryCardBg,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.read<AppProvider>().businessName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bluetooth, color: AppTheme.primary),
              title: const Text('Bluetooth Printer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.primary),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.danger),
              title: const Text('Logout', style: TextStyle(color: AppTheme.danger)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', false);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.label, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppTheme.textSecondary),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ],
      ),
    ),
  );
}
