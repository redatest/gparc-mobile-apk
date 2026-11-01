import 'package:flutter/material.dart';
import '../data/gparc_database.dart';
import 'scanner_screen.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});
  @override
  State<EquipmentScreen> createState()=>_EquipmentScreenState();
}
class _EquipmentScreenState extends State<EquipmentScreen> {
  final controller=TextEditingController();
  String filter='all';
  List<Map<String,Object?>> rows=[];
  bool busy=true;
  @override
  void initState(){super.initState();load();}
  @override
  void dispose(){controller.dispose();super.dispose();}
  Future<void> load() async {
    setState(()=>busy=true);
    final q=controller.text.trim();
    final data=q.isEmpty?await GparcDatabase.instance.listEquipment(filter:filter):await GparcDatabase.instance.searchEquipment(q);
    if(mounted)setState(()=>rows=data,busy=false);
  }
  Future<void> scan() async {
    final code=await Navigator.push<String>(context,MaterialPageRoute(builder:(_)=>const ScannerScreen()));
    if(code!=null){controller.text=code;await load();}
  }
  @override
  Widget build(BuildContext context)=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(12,12,12,4),child:Row(children:[
      Expanded(child:TextField(controller:controller,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Inventaire, série, marque…',suffixIcon:Icon(Icons.search)),onChanged:(_)=>load())),
      const SizedBox(width:8),IconButton.filledTonal(onPressed:scan,icon:const Icon(Icons.qr_code_scanner),tooltip:'Scanner'),
    ])),
    Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
      _filterChip('Tous','all'),_filterChip('En service','active'),_filterChip('À réformer','proposed'),_filterChip('Réformés','reform'),
    ]))),
    Expanded(child:busy?const Center(child:CircularProgressIndicator()):rows.isEmpty?const Center(child:Text('Aucun matériel trouvé.')):ListView.separated(itemCount:rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,i){
      final m=rows[i]; final name=[m['marque_mat'],m['lib_typ_mat']].where((x)=>x!=null&&'$x'.isNotEmpty).join(' · ');
      final user=[m['nom_uti'],m['pnom_uti']].where((x)=>x!=null&&'$x'.isNotEmpty).join(' ');
      return ListTile(leading:const CircleAvatar(child:Icon(Icons.computer)),title:Text('${m['num_inv']??'Sans inventaire'}',style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text([name,m['lib_str'],if(user.isNotEmpty)user].where((x)=>x!=null&&'$x'.isNotEmpty).join(' • ')),trailing:Text(_status(m['statut_mat'])),onTap:()=>showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>_EquipmentDetails(item:m)));
    })),
  ]);
  Widget _filterChip(String label,String value)=>Padding(padding:const EdgeInsets.only(right:6),child:ChoiceChip(label:Text(label),selected:filter==value,onSelected:(_){setState(()=>filter=value);load();}));
  String _status(Object? value)=>switch(value){'ES'=>'En service','PR'=>'À réformer','RF'=>'Réformé',_=>'—'};
}
class _EquipmentDetails extends StatelessWidget{
  const _EquipmentDetails({required this.item});final Map<String,Object?> item;
  @override
  Widget build(BuildContext context){
    final entries=<String,Object?>{'N° inventaire':item['num_inv'],'N° série':item['num_ser'],'Marque':item['marque_mat'],'Type':item['lib_typ_mat'],'Structure':item['lib_str'],'Utilisateur':[item['nom_uti'],item['pnom_uti']].where((x)=>x!=null).join(' '),'État':item['etat_mat'],'Statut':item['statut_mat'],'Processeur':item['cpu'],'RAM':item['ram'],'Disque':item['disk'],'Système':item['se'],'Adresse IP':item['ip'],'Observation':item['obs_mat']};
    return SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Fiche matériel',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:12),...entries.entries.where((e)=>e.value!=null&&'${e.value}'.isNotEmpty).map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child(Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:115,child:Text(e.key,style:const TextStyle(fontWeight:FontWeight.w600))),Expanded(child:Text('${e.value}'))])))),const SizedBox(height:12),Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Fermer')))])));
  }
}
