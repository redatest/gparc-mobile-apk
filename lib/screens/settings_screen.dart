import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/gparc_database.dart';

class SettingsScreen extends StatefulWidget { const SettingsScreen({super.key,required this.onImported}); final VoidCallback onImported; @override State<SettingsScreen> createState()=>_SettingsScreenState(); }
class _SettingsScreenState extends State<SettingsScreen>{
  bool busy=false;
  Future<void> importDb() async {
    setState(()=>busy=true);
    try{final path=await GparcDatabase.instance.importDatabase();if(path!=null){widget.onImported();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Base SQLite importée. Une sauvegarde précédente a été conservée si elle existait.')));}}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Échec de l’import : $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> exportDb() async {final path=await GparcDatabase.instance.databasePath();await Share.shareXFiles([XFile(path)],text:'Sauvegarde de la base GParc SQLite');}
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    Text('Base de données locale',style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:12),
    Card(child:ListTile(leading:const Icon(Icons.file_open),title:const Text('Importer une base Gparc (.db)'),subtitle:const Text('Remplace la base locale après conservation d’une copie de sécurité.'),trailing:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator()):const Icon(Icons.chevron_right),onTap:busy?null:importDb)),
    Card(child:ListTile(leading:const Icon(Icons.ios_share),title:const Text('Exporter / partager la base'),subtitle:const Text('Partager une copie du fichier SQLite local.'),trailing:const Icon(Icons.chevron_right),onTap:exportDb)),
    const SizedBox(height:20),
    const Card(child:ListTile(leading:Icon(Icons.wifi_off),title:Text('Fonctionnement hors ligne'),subtitle:Text('Aucun compte, serveur ou accès réseau requis.'))),
    const Card(child:ListTile(leading:Icon(Icons.security),title:Text('Données locales'),subtitle:Text('La base reste dans le stockage privé de l’application. Exportez régulièrement une sauvegarde.'))),
    const SizedBox(height:20),
    const Text('GParc Mobile · Version 1.0.0 (portage initial)',textAlign:TextAlign.center),
  ]);
}
