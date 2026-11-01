import 'package:flutter/material.dart';
import '../data/gparc_database.dart';

class ReformScreen extends StatefulWidget {
  const ReformScreen({super.key});
  @override State<ReformScreen> createState()=>_ReformScreenState();
}
class _ReformScreenState extends State<ReformScreen>{
  List<Map<String,Object?>> rows=[];
  bool busy=true;
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    setState(()=>busy=true);
    final data=await GparcDatabase.instance.db.rawQuery('''
      SELECT m.*,s.lib_str,t.lib_typ_mat FROM materiel m
      LEFT JOIN structures s ON s.id_str=m.id_str
      LEFT JOIN type_mat t ON t.id_typ_mat=m.id_typ_mat
      WHERE COALESCE(m.archiv,'N') <> 'O' AND COALESCE(m.statut_mat,'ES') <> 'RF'
      ORDER BY CASE WHEN m.statut_mat='PR' THEN 0 ELSE 1 END,m.num_inv
    ''');
    if(mounted)setState((){rows=data;busy=false;});
  }
  Future<void> _propose(Map<String,Object?> item) async {
    final year=TextEditingController(text:'${DateTime.now().year}');
    final lot=TextEditingController();
    final valid=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Proposer à la réforme'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        Text('Matériel : ${item['num_inv']}'),
        const SizedBox(height:12),
        TextField(controller:year,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Année de réforme *')),
        const SizedBox(height:12),
        TextField(controller:lot,decoration:const InputDecoration(labelText:'Numéro de lot *')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(ctx,year.text.trim().isNotEmpty&&lot.text.trim().isNotEmpty),child:const Text('Valider'))],
    ));
    if(valid!=true)return;
    final today=DateTime.now().toIso8601String().substring(0,10);
    final db=GparcDatabase.instance.db;
    await db.transaction((txn)async{
      await txn.update('materiel',{
        'statut_mat':'PR','etat_reforme':'PROPOSEE','annee_reforme':int.tryParse(year.text.trim()),
        'lot_reforme':lot.text.trim(),'date_proposition_reforme':today,'dat_mod':DateTime.now().toIso8601String(),
      },where:'id_mat=?',whereArgs:[item['id_mat']]);
      await txn.insert('historique_reforme',{
        'id_mat':item['id_mat'],'etat_reforme':'PROPOSEE','date_evenement':today,
        'motif_reforme':'Proposition de réforme – lot ${lot.text.trim()}','ancien_etat_reforme':item['etat_reforme']??'AUCUNE',
      });
    });
    year.dispose();lot.dispose();await load();
  }
  Future<void> _finalize(Map<String,Object?> item) async {
    final year=TextEditingController(text:'${DateTime.now().year}');
    final valid=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Confirmer la réforme'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        Text('Matériel : ${item['num_inv']}'),
        Text('Lot de proposition : ${item['lot_reforme']??'Non renseigné'}'),
        const SizedBox(height:12),
        TextField(controller:year,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Année de réforme *')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(ctx,year.text.trim().isNotEmpty),child:const Text('Réformer'))],
    ));
    if(valid!=true)return;
    final today=DateTime.now().toIso8601String().substring(0,10);
    final db=GparcDatabase.instance.db;
    await db.transaction((txn)async{
      await txn.update('materiel',{
        'statut_mat':'RF','etat_reforme':'REFORME','annee_reforme':int.tryParse(year.text.trim()),
        'date_reforme':today,'dat_mod':DateTime.now().toIso8601String(),
      },where:'id_mat=?',whereArgs:[item['id_mat']]);
      await txn.insert('historique_reforme',{
        'id_mat':item['id_mat'],'etat_reforme':'REFORME','date_evenement':today,
        'motif_reforme':'Réforme confirmée','ancien_etat_reforme':item['etat_reforme']??'AUCUNE',
      });
    });
    year.dispose();await load();
  }
  @override Widget build(BuildContext context)=>Scaffold(
    body:busy?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:rows.isEmpty?ListView(children:const [SizedBox(height:160),Center(child:Text('Aucun matériel à traiter.'))]):ListView.separated(
      itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),
      itemBuilder:(context,i){
        final item=rows[i];final proposed=item['statut_mat']=='PR';
        return ListTile(
          leading:Icon(proposed?Icons.pending_actions:Icons.devices_other,color:proposed?Colors.orange: null),
          title:Text('${item['num_inv']??''}'),
          subtitle:Text('${item['marque_mat']??''} · ${item['lib_str']??''}\n${proposed?'Proposé · année ${item['annee_reforme']??'—'} · lot ${item['lot_reforme']??'—'}':'En service'}'),
          isThreeLine:true,
          trailing:proposed?PopupMenuButton<String>(onSelected:(v){if(v=='finalize')_finalize(item);if(v=='cancel')_cancelProposal(item);},itemBuilder:(_)=>[const PopupMenuItem(value:'finalize',child:Text('Confirmer la réforme')),const PopupMenuItem(value:'cancel',child:Text('Annuler la proposition'))]):IconButton(tooltip:'Proposer à la réforme',onPressed:()=>_propose(item),icon:const Icon(Icons.playlist_add)),
        );
      },
    )),
  );
  Future<void> _cancelProposal(Map<String,Object?> item) async {
    final today=DateTime.now().toIso8601String().substring(0,10);
    final db=GparcDatabase.instance.db;
    await db.transaction((txn)async{
      await txn.update('materiel',{'statut_mat':'ES','etat_reforme':'AUCUNE','annee_reforme':null,'lot_reforme':null,'date_proposition_reforme':null,'motif_reforme':null,'dat_mod':DateTime.now().toIso8601String()},where:'id_mat=?',whereArgs:[item['id_mat']]);
      await txn.insert('historique_reforme',{'id_mat':item['id_mat'],'etat_reforme':'AUCUNE','date_evenement':today,'motif_reforme':'Proposition de réforme annulée','ancien_etat_reforme':'PROPOSEE'});
    });
    await load();
  }
}
