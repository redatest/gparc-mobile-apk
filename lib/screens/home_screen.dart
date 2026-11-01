import 'package:flutter/material.dart';
import '../data/gparc_database.dart';
import 'equipment_screen.dart';
import 'faults_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  Map<String,Object?> stats = {};
  bool loading = true;
  @override
  void initState() { super.initState(); refresh(); }
  Future<void> refresh() async {
    try { final value = await GparcDatabase.instance.dashboard(); if (mounted) setState(() { stats=value; loading=false; }); }
    catch (_) { if (mounted) setState(() => loading=false); }
  }
  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(stats:stats, loading:loading, onRefresh:refresh, onOpenEquipment:()=>setState(()=>index=1)),
      const EquipmentScreen(),
      const FaultsScreen(),
      SettingsScreen(onImported:refresh),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('GParc Mobile'), actions:[IconButton(tooltip:'Actualiser',onPressed:refresh,icon:const Icon(Icons.refresh))]),
      body: pages[index],
      bottomNavigationBar: NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:const [
        NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Accueil'),
        NavigationDestination(icon:Icon(Icons.devices),label:'Parc'),
        NavigationDestination(icon:Icon(Icons.build_outlined),label:'Pannes'),
        NavigationDestination(icon:Icon(Icons.storage),label:'Base'),
      ]),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.stats,required this.loading,required this.onRefresh,required this.onOpenEquipment});
  final Map<String,Object?> stats; final bool loading; final VoidCallback onRefresh; final VoidCallback onOpenEquipment;
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child:CircularProgressIndicator());
    final total=stats['total']??0;
    return RefreshIndicator(onRefresh:() async=>onRefresh(),child:ListView(padding:const EdgeInsets.all(16),children:[
      Text('Vue d’ensemble',style:Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height:16),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.65,crossAxisSpacing:12,mainAxisSpacing:12,children:[
        _Kpi(label:'Matériels',value:total,icon:Icons.devices),
        _Kpi(label:'En service',value:stats['active']??0,icon:Icons.check_circle_outline),
        _Kpi(label:'Pannes actives',value:stats['faults']??0,icon:Icons.build_circle_outlined),
        _Kpi(label:'À réformer',value:stats['proposed']??0,icon:Icons.pending_actions),
        _Kpi(label:'Réformés',value:stats['reformed']??0,icon:Icons.archive_outlined),
      ]),
      const SizedBox(height:20),
      Card(child:ListTile(leading:const Icon(Icons.devices),title:const Text('Consulter le parc'),subtitle:const Text('Recherche par inventaire, série ou caractéristiques'),trailing:const Icon(Icons.chevron_right),onTap:onOpenEquipment)),
      const Card(child:ListTile(leading:Icon(Icons.offline_bolt),title:Text('Mode hors ligne'),subtitle:Text('Les données sont stockées localement sur cet appareil.'))),
    ]));
  }
}
class _Kpi extends StatelessWidget {
  const _Kpi({required this.label,required this.value,required this.icon});
  final String label; final Object value; final IconData icon;
  @override
  Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(icon,color:Theme.of(context).colorScheme.primary),Text('$value',style:Theme.of(context).textTheme.headlineMedium),Text(label,style:Theme.of(context).textTheme.bodyMedium)])));
}
