import 'package:flutter/material.dart';
import '../data/gparc_database.dart';
import 'fault_form_screen.dart';

class FaultsScreen extends StatefulWidget { const FaultsScreen({super.key}); @override State<FaultsScreen> createState()=>_FaultsScreenState(); }
class _FaultsScreenState extends State<FaultsScreen>{
  List<Map<String,Object?>> rows=[];bool busy=true;
  @override void initState(){super.initState();load();}
  Future<void> load() async {setState(()=>busy=true);final data=await GparcDatabase.instance.db.rawQuery('''SELECT p.*,m.num_inv AS inv_materiel,m.marque_mat,s.lib_str FROM panne p LEFT JOIN materiel m ON m.id_mat=p.id_mat LEFT JOIN structures s ON s.id_str=p.id_str WHERE COALESCE(p.archiv,'N') <> 'O' ORDER BY p.dat_pan DESC,p.id_pan DESC''');if(mounted)setState(()=>rows=data,busy=false);}
  @override Widget build(BuildContext context)=>Scaffold(floatingActionButton:FloatingActionButton.extended(onPressed:() async {final created=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>const FaultFormScreen()));if(created==true)await load();},icon:const Icon(Icons.add),label:const Text('Déclarer')),body:busy?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('Aucune panne enregistrée.')):RefreshIndicator(onRefresh:load,child:ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,i){final p=rows[i];return ListTile(leading:const Icon(Icons.build_circle_outlined),title:Text('${p['inv_materiel']??p['num_inv']??'Matériel'}'),subtitle:Text('${p['diag_pan']??'Diagnostic non renseigné'}\n${p['dat_pan']??''} · ${p['eta_pan']??''}'),isThreeLine:true,trailing:const Icon(Icons.chevron_right),onTap:()=>showDialog(context:context,builder:(_)=>AlertDialog(title:Text('Panne – ${p['inv_materiel']??''}'),content:Text(['Diagnostic : ${p['diag_pan']??''}','Date : ${p['dat_pan']??''}','Statut : ${p['eta_pan']??''}','Technicien : ${p['technicien']??''}','Réparateur : ${p['id_lieu_rep']??''}','Observations : ${p['obs_rep']??''}'].join('\n')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Fermer'))]))); }));}
}
