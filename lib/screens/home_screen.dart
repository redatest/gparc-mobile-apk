import 'package:flutter/material.dart';
import '../data/gparc_database.dart';
import 'equipment_screen.dart';
import 'faults_screen.dart';
import 'settings_screen.dart';
import 'reform_screen.dart';
import 'scanner_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  Map<String, Object?> stats = {};
  bool loading = true;
  String scannedQuery = '';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> _scanFromHome() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (!mounted || code == null || code.isEmpty) return;
    setState(() {
      scannedQuery = code;
      index = 1;
    });
  }

  Future<void> refresh() async {
    try {
      final value = await GparcDatabase.instance.dashboard();
      if (mounted) setState(() { stats = value; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
        stats: stats,
        loading: loading,
        onRefresh: refresh,
        onOpenEquipment: () => setState(() => index = 1),
        onScan: _scanFromHome,
      ),
      EquipmentScreen(
        key: ValueKey('equipment-$scannedQuery'),
        initialQuery: scannedQuery,
      ),
      const FaultsScreen(),
      SettingsScreen(onImported: refresh),
      const ReformScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'gparc inventaire.jpg',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text('GParc Mobile', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (states) => TextStyle(
              fontSize: 9,
              letterSpacing: -0.25,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          iconTheme: const WidgetStatePropertyAll(
            IconThemeData(size: 20),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.devices), selectedIcon: Icon(Icons.devices_rounded), label: 'Parc'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Pannes'),
          NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: 'Base'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Réforme'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Statistiques'),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.stats,
    required this.loading,
    required this.onRefresh,
    required this.onOpenEquipment,
    required this.onScan,
  });

  final Map<String, Object?> stats;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onOpenEquipment;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final total = stats['total'] ?? 0;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF155C78), Color(0xFF258477)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GESTION DU PARC INFORMATIQUE',
                  style: TextStyle(
                    color: Color(0xFFD7EEF0),
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Vue d’ensemble',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Suivi des équipements et des interventions',
                  style: TextStyle(color: Color(0xFFE5F2F3), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _Kpi(label: 'Matériels', value: total, icon: Icons.devices, color: const Color(0xFF247BA0)),
              _Kpi(label: 'En service', value: stats['active'] ?? 0, icon: Icons.check_circle_outline, color: const Color(0xFF258477)),
              _Kpi(label: 'Pannes actives', value: stats['faults'] ?? 0, icon: Icons.build_circle_outlined, color: const Color(0xFFD45B55)),
              _Kpi(label: 'À réformer', value: stats['proposed'] ?? 0, icon: Icons.pending_actions, color: const Color(0xFFE19A38)),
              _Kpi(label: 'Réformés', value: stats['reformed'] ?? 0, icon: Icons.archive_outlined, color: const Color(0xFF7A6AA6)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE2F0F5),
                foregroundColor: Color(0xFF176B87),
                child: Icon(Icons.devices),
              ),
              title: const Text('Consulter le parc', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Recherche par inventaire, série ou caractéristiques'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenEquipment,
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE1F2EC),
                foregroundColor: Color(0xFF258477),
                child: Icon(Icons.qr_code_scanner_rounded),
              ),
              title: const Text('Scanner un équipement', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Lire le code-barres pour retrouver le matériel'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onScan,
            ),
          ),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE1F2EC),
                foregroundColor: Color(0xFF258477),
                child: Icon(Icons.offline_bolt),
              ),
              title: Text('Mode hors ligne', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Les données sont stockées localement sur cet appareil.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final Object value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: 0.13),
                foregroundColor: color,
                child: Icon(icon, size: 19),
              ),
              const SizedBox(height: 5),
              Text(
                '$value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF203746),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF657783),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      );
}
