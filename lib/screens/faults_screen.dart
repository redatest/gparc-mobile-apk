import 'package:flutter/material.dart';
import '../data/gparc_database.dart';
import 'fault_form_screen.dart';

class FaultsScreen extends StatefulWidget {
  const FaultsScreen({super.key});
  @override
  State<FaultsScreen> createState() => _FaultsScreenState();
}

class _FaultsScreenState extends State<FaultsScreen> {
  List<Map<String,Object?>> rows = [];
  bool busy = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => busy = true);
    final data = await GparcDatabase.instance.db.rawQuery('''
      SELECT p.*, m.num_inv AS inv_materiel, m.marque_mat, s.lib_str
      FROM panne p
      LEFT JOIN materiel m ON m.id_mat=p.id_mat
      LEFT JOIN structures s ON s.id_str=p.id_str
      WHERE COALESCE(p.archiv,'N') <> 'O'
      ORDER BY p.dat_pan DESC, p.id_pan DESC
    ''');
    if (mounted) setState(() { rows = data; busy = false; });
  }

  Future<void> _changeStatus(Map<String,Object?> fault, String status) async {
    final db = GparcDatabase.instance.db;
    final today = DateTime.now().toIso8601String().substring(0,10);
    await db.transaction((txn) async {
      final current = await txn.query('materiel', columns:['etat_reforme'], where:'id_mat=?', whereArgs:[fault['id_mat']], limit:1);
      final updates = <String,Object?>{'eta_pan':status};
      if (status == 'ER' || status == 'RP' || status == 'IR') updates['dat_env_rep'] = fault['dat_env_rep'] ?? today;
      if (status == 'RP' || status == 'IR') updates['dat_ret_rep'] = today;
      await txn.update('panne', updates, where:'id_pan=?', whereArgs:[fault['id_pan']]);
      final physical = switch(status) {'EP' => 'PANNE', 'ER' => 'PANNE', 'RP' => 'BON', 'IR' => 'IRREPARABLE', _ => 'PANNE'};
      final materialUpdates = <String,Object?>{'etat_mat':physical,'dat_mod':DateTime.now().toIso8601String()};
      if (status == 'RP' && current.isNotEmpty && current.first['etat_reforme'] == 'PROPOSEE') {
        materialUpdates.addAll({
          'statut_mat':'ES','etat_reforme':'AUCUNE','motif_reforme':null,
          'date_proposition_reforme':null,'date_validation_reforme':null,'date_reforme':null,
          'annee_reforme':null,'lot_reforme':null,'decision_reforme':null,'pv_reforme':null,
        });
        await txn.insert('historique_reforme', {
          'id_mat':fault['id_mat'],'etat_reforme':'AUCUNE','date_evenement':today,
          'motif_reforme':'Proposition annulée après réparation','ancien_etat_reforme':'PROPOSEE',
        });
      }
      await txn.update('materiel', materialUpdates, where:'id_mat=?', whereArgs:[fault['id_mat']]);
    });
    await load();
  }

  Future<void> _openDetails(Map<String,Object?> fault) async {
    await showDialog<void>(context:context,builder:(dialogContext)=>AlertDialog(
      title:Text('Panne – ${fault['inv_materiel'] ?? fault['num_inv'] ?? ''}'),
      content:SingleChildScrollView(child:Text([
        'Diagnostic : ${fault['diag_pan'] ?? ''}',
        'Date : ${fault['dat_pan'] ?? ''}',
        'Statut : ${_statusLabel(fault['eta_pan'])}',
        'Technicien : ${fault['technicien'] ?? ''}',
        'Observations : ${fault['obs_rep'] ?? ''}',
        'Pièces remplacées : ${fault['pieces_remplacees'] ?? ''}',
      ].join('\n'))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Fermer')),
        PopupMenuButton<String>(
          tooltip:'Changer le statut',
          onSelected:(value) async {Navigator.pop(dialogContext);await _changeStatus(fault,value);},
          itemBuilder:(_)=>const [
            PopupMenuItem(value:'EP',child:Text('En panne')),
            PopupMenuItem(value:'ER',child:Text('En réparation')),
            PopupMenuItem(value:'RP',child:Text('Réparé')),
            PopupMenuItem(value:'IR',child:Text('Irréparable')),
          ],
          child:const Padding(padding:EdgeInsets.all(8),child:Text('Traiter')),
        ),
      ],
    ));
  }

  String _statusLabel(Object? code) => switch(code) {
    'EP'=>'En panne','ER'=>'En réparation','RP'=>'Réparé','IR'=>'Irréparable',_=>'Inconnu'
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton:FloatingActionButton.extended(
      onPressed:() async {
        final created=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>const FaultFormScreen()));
        if(created==true) await load();
      },
      icon:const Icon(Icons.add),label:const Text('Déclarer'),
    ),
    body:busy ? const Center(child:CircularProgressIndicator())
      : rows.isEmpty ? const Center(child:Text('Aucune panne enregistrée.'))
      : RefreshIndicator(
        onRefresh:load,
        child:ListView.separated(
          itemCount:rows.length,
          separatorBuilder:(_,__)=>const Divider(height:1),
          itemBuilder:(context,i){
            final fault=rows[i];
            return ListTile(
              leading:const Icon(Icons.build_circle_outlined),
              title:Text('${fault['inv_materiel'] ?? fault['num_inv'] ?? 'Matériel'}'),
              subtitle:Text('${fault['diag_pan'] ?? 'Diagnostic non renseigné'}\n${fault['dat_pan'] ?? ''} · ${_statusLabel(fault['eta_pan'])}'),
              isThreeLine:true,
              trailing:const Icon(Icons.chevron_right),
              onTap:()=>_openDetails(fault),
            );
          },
        ),
      ),
  );
}
