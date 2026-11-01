import 'package:flutter/material.dart';
import '../data/gparc_database.dart';

class FaultFormScreen extends StatefulWidget {
  const FaultFormScreen({super.key});
  @override
  State<FaultFormScreen> createState() => _FaultFormScreenState();
}
class _FaultFormScreenState extends State<FaultFormScreen> {
  final _key=GlobalKey<FormState>();
  final _diagnosis=TextEditingController();
  final _technician=TextEditingController(text:'Support DSI');
  final _notes=TextEditingController();
  List<Map<String,Object?>> equipment=[];
  int? materialId;
  bool saving=false;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final data=await GparcDatabase.instance.db.rawQuery("SELECT id_mat,num_inv,marque_mat FROM materiel WHERE COALESCE(archiv,'N')='N' ORDER BY num_inv");
    if(mounted)setState(()=>equipment=data);
  }
  @override void dispose(){_diagnosis.dispose();_technician.dispose();_notes.dispose();super.dispose();}
  Future<void> _save() async {
    if(!_key.currentState!.validate())return;
    setState(()=>saving=true);
    try{
      final db=GparcDatabase.instance.db;
      await db.transaction((txn)async{
        final material=(await txn.query('materiel',where:'id_mat=?',whereArgs:[materialId],limit:1)).first;
        await txn.insert('panne',{
          'id_mat':materialId,'id_str':material['id_str'],'id_typ_mat':material['id_typ_mat'],'id_model_mat':material['id_model_mat'],
          'num_inv':material['num_inv'],'num_ser':material['num_ser'],'dat_pan':DateTime.now().toIso8601String().substring(0,10),
          'diag_pan':_diagnosis.text.trim(),'eta_pan':'EP','tp':'MAT','technicien':_technician.text.trim(),'obs_rep':_notes.text.trim(),
        });
        await txn.update('materiel',{'etat_mat':'PANNE','dat_mod':DateTime.now().toIso8601String()},where:'id_mat=?',whereArgs:[materialId]);
      });
      if(mounted)Navigator.pop(context,true);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Enregistrement impossible : $e')));}
    finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Déclarer une panne')),
    body:Form(key:_key,child:ListView(padding:const EdgeInsets.all(16),children:[
      DropdownButtonFormField<int>(value:materialId,decoration:const InputDecoration(labelText:'Matériel *'),items:equipment.map((m)=>DropdownMenuItem(value:m['id_mat'] as int,child:Text('${m['num_inv']} · ${m['marque_mat']??''}'))).toList(),onChanged:(v)=>setState(()=>materialId=v),validator:(v)=>v==null?'Sélectionner un matériel':null),
      const SizedBox(height:12),
      TextFormField(controller:_diagnosis,maxLines:3,decoration:const InputDecoration(labelText:'Diagnostic / anomalie *'),validator:(v)=>v==null||v.trim().isEmpty?'Champ obligatoire':null),
      const SizedBox(height:12),
      TextFormField(controller:_technician,decoration:const InputDecoration(labelText:'Technicien')),
      const SizedBox(height:12),
      TextFormField(controller:_notes,maxLines:3,decoration:const InputDecoration(labelText:'Observation')),
      const SizedBox(height:24),
      FilledButton.icon(onPressed:saving?null:_save,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save),label:const Text('Enregistrer la panne')),
    ])),
  );
}
